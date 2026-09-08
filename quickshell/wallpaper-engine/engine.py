#!/usr/bin/env python3
"""
DARK_NIRI HTML/Web Wallpaper Engine
Hardware-accelerated, Wayland layer-shell native background engine.
Powered by GTK4, gtk4-layer-shell, and WebKitGTK 6.0.
Ultra-low RAM & CPU footprint with smart fullscreen pause and dynamic throttling.
"""

import os
import sys
import json
import time
import socket
import signal
import threading
import glob
import subprocess
import gc

# Ensure LD_PRELOAD is active for gtk4-layer-shell
LAYER_SHELL_LIB = "/usr/lib/libgtk4-layer-shell.so"
if not os.environ.get("LD_PRELOAD") or LAYER_SHELL_LIB not in os.environ.get("LD_PRELOAD", ""):
    if os.path.exists(LAYER_SHELL_LIB):
        current_preload = os.environ.get("LD_PRELOAD", "")
        os.environ["LD_PRELOAD"] = f"{LAYER_SHELL_LIB} {current_preload}".strip()
        try:
            os.execv(sys.executable, [sys.executable] + sys.argv)
        except Exception as e:
            print(f"[Engine] Failed to re-exec with LD_PRELOAD: {e}", file=sys.stderr)

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Gtk4LayerShell', '1.0')
gi.require_version('WebKit', '6.0')
from gi.repository import Gtk, Gtk4LayerShell, WebKit, Gdk, GLib

# Configure WebKit default web context for minimal memory overhead
try:
    _ctx = WebKit.WebContext.get_default()
    if hasattr(WebKit, "CacheModel") and hasattr(WebKit.CacheModel, "DOCUMENT_VIEWER"):
        _ctx.set_cache_model(WebKit.CacheModel.DOCUMENT_VIEWER)
except Exception as _e:
    pass

ENGINE_DIR = os.path.dirname(os.path.abspath(__file__))
THEMES_DIR = os.path.join(ENGINE_DIR, "themes")
CONFIG_PATH = os.path.join(ENGINE_DIR, "config.json")
STATE_FILE = os.path.expanduser("~/.config/niri/current_wallpaper")
WALLPAPERS_DIR = os.path.expanduser("~/Pictures/Wallpapers")
SOCKET_PATH = f"/tmp/qs-wallpaper-{os.getuid()}.sock"
FALLBACK_URI = f"file://{os.path.join(THEMES_DIR, 'fallback', 'index.html')}"

DEFAULT_CONFIG = {
    "active": "cyber-city",
    "active_type": "theme",
    "mode": "global", # "global", "per-monitor", "random"
    "monitors": {},
    "fps": 60,
    "quality": "balanced", # "battery_saver", "balanced", "performance"
    "battery_saver": True,
    "pause_fullscreen": True,
    "effects": {
        "particles": {
            "enabled": True,
            "style": "embers",
            "count": 40,
            "speed": 1.0,
            "color": "#7aa2f7"
        },
        "parallax": {
            "enabled": True,
            "depth": 2.5
        },
        "time_lighting": {
            "enabled": True,
            "mode": "auto",
            "preset": "sunset"
        },
        "weather": {
            "enabled": False,
            "type": "rain",
            "intensity": "medium"
        },
        "clock_hud": {
            "enabled": True,
            "style": "cyber",
            "position": "top-right",
            "format24h": True,
            "showSeconds": True
        },
        "scanlines": {
            "enabled": False,
            "opacity": 0.25
        },
        "vignette": {
            "enabled": True,
            "opacity": 0.35
        },
        "blur": {
            "enabled": False,
            "radius": 0
        },
        "brightness": 100,
        "contrast": 100
    }
}

TOP_LEVEL_CONFIG_KEYS = {"fps", "quality", "battery_saver", "pause_fullscreen", "mode", "active", "active_type"}

BRIDGE_USER_SCRIPT = """
(function() {
  window.wallpaper = {
    version: "1.2",
    _state: {
      battery: { percentage: 100, charging: false },
      cpu: 0,
      memory: 0,
      time: {},
      workspace: { id: 1, idx: 1 },
      media: { title: "", artist: "", status: "Stopped" },
      monitors: [],
      fullscreen: false
    },
    _listeners: {},
    on: function(event, cb) {
      if (!this._listeners[event]) this._listeners[event] = [];
      this._listeners[event].push(cb);
    },
    off: function(event, cb) {
      if (!this._listeners[event]) return;
      this._listeners[event] = this._listeners[event].filter(function(f) { return f !== cb; });
    },
    _emit: function(event, data) {
      if (this._listeners[event]) {
        this._listeners[event].forEach(function(cb) {
          try { cb(data); } catch(e) {}
        });
      }
    },
    getBattery: function() { return this._state.battery; },
    getTime: function() { return this._state.time; },
    getCpuUsage: function() { return this._state.cpu; },
    getMemoryUsage: function() { return this._state.memory; },
    getActiveWorkspace: function() { return this._state.workspace; },
    getMusic: function() { return this._state.media; },
    getMonitor: function() { return this._state.monitor || "default"; },
    system: {
      battery: function() { return window.wallpaper._state.battery; },
      cpu: function() { return window.wallpaper._state.cpu; },
      memory: function() { return window.wallpaper._state.memory; },
      time: function() { return window.wallpaper._state.time; }
    },
    desktop: {
      workspace: function() { return window.wallpaper._state.workspace; },
      monitors: function() { return window.wallpaper._state.monitors || []; }
    },
    media: {
      player: function() { return window.wallpaper._state.media; },
      albumArt: function() { return window.wallpaper._state.media ? window.wallpaper._state.media.artUrl : ""; }
    }
  };

  // State Updates from Python
  window.__onWallpaperStateUpdate = function(newState) {
    if (!newState) return;
    Object.assign(window.wallpaper._state, newState);
    window.__isWallpaperObscured = !!newState.fullscreen;
    if (newState.battery !== undefined) window.wallpaper._emit('battery', newState.battery);
    if (newState.cpu !== undefined || newState.memory !== undefined) window.wallpaper._emit('telemetry', newState);
    if (newState.workspace !== undefined) window.wallpaper._emit('workspace', newState.workspace);
    if (newState.media !== undefined) window.wallpaper._emit('media', newState.media);
  };

  // Universal Overlay State & Controller
  let uniConfig = null;
  let fxContainer = null;
  let vignetteEl = null;
  let scanlinesEl = null;
  let timeEl = null;
  let hudEl = null;
  let hudTimeEl = null;
  let hudDateEl = null;
  let partCanvas = null;
  let partCtx = null;
  let weatherCanvas = null;
  let weatherCtx = null;

  let particles = [];
  let weatherItems = [];
  let animFrameId = null;
  let lastFrameTime = performance.now();

  function initUniversalEffects() {
    // If page is image-viewer, it already manages its own layers
    if (document.getElementById('wallpaper-image-wrapper')) return;
    if (document.getElementById('__dn_uni_fx__')) return;

    fxContainer = document.createElement('div');
    fxContainer.id = '__dn_uni_fx__';
    fxContainer.style.cssText = 'position:fixed;top:0;left:0;width:100vw;height:100vh;pointer-events:none;z-index:999999;overflow:hidden;';

    // 1. Time overlay
    timeEl = document.createElement('div');
    timeEl.id = '__dn_time_overlay__';
    timeEl.style.cssText = 'position:absolute;top:0;left:0;width:100%;height:100%;pointer-events:none;transition:background 1s ease;';
    fxContainer.appendChild(timeEl);

    // 2. Weather canvas
    weatherCanvas = document.createElement('canvas');
    weatherCanvas.style.cssText = 'position:absolute;top:0;left:0;width:100%;height:100%;pointer-events:none;';
    fxContainer.appendChild(weatherCanvas);
    weatherCtx = weatherCanvas.getContext('2d');

    // 3. Particles canvas
    partCanvas = document.createElement('canvas');
    partCanvas.style.cssText = 'position:absolute;top:0;left:0;width:100%;height:100%;pointer-events:none;';
    fxContainer.appendChild(partCanvas);
    partCtx = partCanvas.getContext('2d');

    // 4. Vignette overlay
    vignetteEl = document.createElement('div');
    vignetteEl.id = '__dn_vignette__';
    vignetteEl.style.cssText = 'position:absolute;top:0;left:0;width:100%;height:100%;pointer-events:none;background:radial-gradient(circle at center, transparent 40%, rgba(0,0,0,0.85) 100%);display:none;';
    fxContainer.appendChild(vignetteEl);

    // 5. Scanlines overlay
    scanlinesEl = document.createElement('div');
    scanlinesEl.id = '__dn_scanlines__';
    scanlinesEl.style.cssText = 'position:absolute;top:0;left:0;width:100%;height:100%;pointer-events:none;background:repeating-linear-gradient(0deg, rgba(0,0,0,0.3) 0px, rgba(0,0,0,0.3) 1px, transparent 1px, transparent 2px);display:none;';
    fxContainer.appendChild(scanlinesEl);

    // 6. Universal HUD Clock (only if theme doesn't already have hud-clock)
    if (!document.getElementById('hud-clock')) {
      hudEl = document.createElement('div');
      hudEl.id = '__dn_clock_hud__';
      hudEl.style.cssText = 'position:absolute;padding:12px 20px;border-radius:12px;background:rgba(22,22,30,0.75);backdrop-filter:blur(8px);border:1px solid rgba(122,162,247,0.35);color:#c0caf5;font-family:sans-serif;display:none;flex-direction:column;align-items:flex-end;box-shadow:0 8px 32px rgba(0,0,0,0.5);';
      hudTimeEl = document.createElement('div');
      hudTimeEl.style.cssText = 'font-size:26px;font-weight:bold;letter-spacing:1px;color:#7aa2f7;text-shadow:0 0 10px rgba(122,162,247,0.5);';
      hudDateEl = document.createElement('div');
      hudDateEl.style.cssText = 'font-size:11px;font-weight:bold;letter-spacing:1.5px;color:#a9b1d6;margin-top:2px;';
      hudEl.appendChild(hudTimeEl);
      hudEl.appendChild(hudDateEl);
      fxContainer.appendChild(hudEl);
    }

    document.body.appendChild(fxContainer);

    function onResize() {
      if (partCanvas) { partCanvas.width = window.innerWidth; partCanvas.height = window.innerHeight; }
      if (weatherCanvas) { weatherCanvas.width = window.innerWidth; weatherCanvas.height = window.innerHeight; }
    }
    window.addEventListener('resize', onResize);
    onResize();

    if (uniConfig) applyUniversalFx(uniConfig);
    requestAnimationFrame(renderUniFx);
  }

  function updateClockTime() {
    if (!hudEl || hudEl.style.display === 'none' || !uniConfig) return;
    const eff = uniConfig.effects || {};
    const cHud = eff.clock_hud || {};
    if (!cHud.enabled) return;

    const now = new Date();
    let hours = now.getHours();
    let minutes = String(now.getMinutes()).padStart(2, '0');
    let seconds = String(now.getSeconds()).padStart(2, '0');
    if (!cHud.format24h) hours = hours % 12 || 12;
    else hours = String(hours).padStart(2, '0');

    if (hudTimeEl) hudTimeEl.textContent = cHud.showSeconds ? `${hours}:${minutes}:${seconds}` : `${hours}:${minutes}`;

    const days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    if (hudDateEl) hudDateEl.textContent = `${days[now.getDay()]}, ${months[now.getMonth()]} ${String(now.getDate()).padStart(2, '0')}`;
  }
  setInterval(updateClockTime, 1000);

  function applyUniversalFx(cfg) {
    uniConfig = cfg;
    const eff = cfg.effects || {};

    // 1. Post-processing filters on documentElement
    let filterStr = '';
    if (eff.blur && eff.blur.enabled && eff.blur.radius > 0) filterStr += `blur(${eff.blur.radius}px) `;
    if (eff.brightness && eff.brightness !== 100) filterStr += `brightness(${eff.brightness}%) `;
    if (eff.contrast && eff.contrast !== 100) filterStr += `contrast(${eff.contrast}%) `;
    document.documentElement.style.filter = filterStr.trim();

    if (!fxContainer) return;

    // 2. Vignette
    if (vignetteEl) {
      if (eff.vignette && eff.vignette.enabled) {
        vignetteEl.style.display = 'block';
        vignetteEl.style.opacity = eff.vignette.opacity || 0.35;
      } else {
        vignetteEl.style.display = 'none';
      }
    }

    // 3. Scanlines
    if (scanlinesEl) {
      if (eff.scanlines && eff.scanlines.enabled) {
        scanlinesEl.style.display = 'block';
        scanlinesEl.style.opacity = eff.scanlines.opacity || 0.25;
      } else {
        scanlinesEl.style.display = 'none';
      }
    }

    // 4. Time Overlay
    if (timeEl) {
      if (eff.time_lighting && eff.time_lighting.enabled) {
        const hour = new Date().getHours();
        let phase = eff.time_lighting.mode === 'auto' ?
          (hour >= 5 && hour < 8 ? 'dawn' : (hour >= 8 && hour < 17 ? 'day' : (hour >= 17 && hour < 20 ? 'sunset' : 'night')))
          : (eff.time_lighting.preset || 'day');

        if (phase === 'dawn') timeEl.style.background = 'rgba(255, 140, 100, 0.12)';
        else if (phase === 'sunset') timeEl.style.background = 'rgba(255, 100, 150, 0.14)';
        else if (phase === 'night') timeEl.style.background = 'rgba(10, 15, 35, 0.35)';
        else timeEl.style.background = 'transparent';
      } else {
        timeEl.style.background = 'transparent';
      }
    }

    // 5. Clock HUD
    if (hudEl) {
      if (eff.clock_hud && eff.clock_hud.enabled) {
        hudEl.style.display = 'flex';
        const pos = eff.clock_hud.position || 'top-right';
        hudEl.style.top = pos === 'center' ? '45%' : '24px';
        hudEl.style.left = pos === 'top-left' ? '24px' : (pos === 'center' ? '50%' : 'auto');
        hudEl.style.right = pos === 'top-right' ? '24px' : 'auto';
        hudEl.style.transform = pos === 'center' ? 'translate(-50%, -50%)' : 'none';
        updateClockTime();
      } else {
        hudEl.style.display = 'none';
      }
    }

    // 6. Particles
    particles = [];
    if (eff.particles && eff.particles.enabled) {
      const count = eff.particles.count || 40;
      const spd = eff.particles.speed || 1.0;
      for (let i = 0; i < count; i++) {
        particles.push({
          x: Math.random() * window.innerWidth,
          y: Math.random() * window.innerHeight,
          size: Math.random() * 3 + 1,
          speedX: (Math.random() - 0.5) * spd,
          speedY: (Math.random() * -1.5 - 0.3) * spd,
          alpha: Math.random() * 0.7 + 0.3
        });
      }
    }

    // 7. Weather
    weatherItems = [];
    if (eff.weather && eff.weather.enabled) {
      const count = eff.weather.type === 'rain' ? 90 : 60;
      for (let i = 0; i < count; i++) {
        weatherItems.push({
          x: Math.random() * window.innerWidth,
          y: Math.random() * window.innerHeight,
          len: Math.random() * 18 + 10,
          speed: Math.random() * 10 + 10,
          size: Math.random() * 2 + 1
        });
      }
    }
  }

  function renderUniFx(now) {
    requestAnimationFrame(renderUniFx);

    // Fullscreen auto-pause
    if (window.__isWallpaperObscured && uniConfig && uniConfig.pause_fullscreen) return;

    // Dynamic FPS Throttling
    const targetFps = (uniConfig && uniConfig.fps) ? uniConfig.fps : 60;
    const interval = 1000 / targetFps;
    const delta = now - lastFrameTime;
    if (delta < interval) return;
    lastFrameTime = now - (delta % interval);

    // Particles render
    if (partCtx && particles.length > 0) {
      partCtx.clearRect(0, 0, partCanvas.width, partCanvas.height);
      const eff = (uniConfig && uniConfig.effects) ? uniConfig.effects : {};
      const pConf = eff.particles || {};
      const color = pConf.color || '#7aa2f7';
      const style = pConf.style || 'embers';

      partCtx.fillStyle = color;
      for (let p of particles) {
        p.x += p.speedX;
        p.y += p.speedY;
        if (p.y < -10) p.y = partCanvas.height + 10;
        if (p.x < -10) p.x = partCanvas.width + 10;
        if (p.x > partCanvas.width + 10) p.x = -10;

        partCtx.globalAlpha = p.alpha;
        if (style === 'nodes') {
          partCtx.fillRect(p.x - p.size, p.y - p.size, p.size * 1.6, p.size * 1.6);
        } else {
          partCtx.beginPath();
          partCtx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
          partCtx.fill();
        }
      }
      partCtx.globalAlpha = 1.0;
    } else if (partCtx) {
      partCtx.clearRect(0, 0, partCanvas.width, partCanvas.height);
    }

    // Weather render
    if (weatherCtx && weatherItems.length > 0) {
      weatherCtx.clearRect(0, 0, weatherCanvas.width, weatherCanvas.height);
      const eff = (uniConfig && uniConfig.effects) ? uniConfig.effects : {};
      const isRain = !(eff.weather && eff.weather.type === 'snow');

      if (isRain) {
        weatherCtx.strokeStyle = 'rgba(122, 162, 247, 0.45)';
        weatherCtx.lineWidth = 1.2;
        weatherCtx.beginPath();
        for (let w of weatherItems) {
          w.y += w.speed;
          w.x += w.speed * 0.15;
          if (w.y > weatherCanvas.height) { w.y = -w.len; w.x = Math.random() * weatherCanvas.width; }
          weatherCtx.moveTo(w.x, w.y);
          weatherCtx.lineTo(w.x + w.len * 0.15, w.y + w.len);
        }
        weatherCtx.stroke();
      } else {
        weatherCtx.fillStyle = 'rgba(255, 255, 255, 0.75)';
        for (let w of weatherItems) {
          w.y += w.speed * 0.3;
          w.x += Math.sin(w.y * 0.02) * 1.0;
          if (w.y > weatherCanvas.height) { w.y = -10; w.x = Math.random() * weatherCanvas.width; }
          weatherCtx.beginPath();
          weatherCtx.arc(w.x, w.y, w.size, 0, Math.PI * 2);
          weatherCtx.fill();
        }
      }
    } else if (weatherCtx) {
      weatherCtx.clearRect(0, 0, weatherCanvas.width, weatherCanvas.height);
    }
  }

  // Global Config Hook for Python evaluate_javascript
  window.updateWallpaperConfig = function(newCfg) {
    if (!newCfg) return;
    if (typeof newCfg === 'string') {
      try { newCfg = JSON.parse(newCfg); } catch(e) { return; }
    }
    uniConfig = newCfg;

    // Dispatch custom event for themes that want to handle their own config
    try {
      window.dispatchEvent(new CustomEvent('wallpaperConfigChanged', { detail: newCfg }));
    } catch(e) {}

    // If page is image viewer and has its own handler, call it
    if (typeof window.__imageViewerUpdateConfig === 'function') {
      window.__imageViewerUpdateConfig(newCfg);
    } else {
      applyUniversalFx(newCfg);
    }
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initUniversalEffects);
  } else {
    initUniversalEffects();
  }
})();
"""

class WallpaperEngineApp:
    def __init__(self):
        self.app = Gtk.Application(application_id="org.darkniri.wallpaperengine")
        self.app.connect("activate", self.on_activate)
        self.config = self.load_config()
        self.windows = {}  # connector -> { 'win': win, 'view': view, 'url': url }
        self.server_sock = None
        self.server_thread = None
        self.running = True

        # Telemetry Cache
        self.last_cpu_times = None
        self.current_state = {
            "cpu": 0,
            "memory": 0,
            "battery": {"percentage": 100, "charging": False},
            "workspace": {"id": 1, "idx": 1},
            "media": {"title": "", "artist": "", "status": "Stopped"},
            "monitors": [],
            "fullscreen": False
        }

    def load_config(self):
        if os.path.exists(CONFIG_PATH):
            try:
                with open(CONFIG_PATH, 'r') as f:
                    data = json.load(f)
                    cfg = dict(DEFAULT_CONFIG)
                    cfg.update(data)
                    # Clean and merge effects dictionary
                    if "effects" in data and isinstance(data["effects"], dict):
                        merged_effects = dict(DEFAULT_CONFIG["effects"])
                        # Strip any accidental top-level keys inside effects
                        cleaned_effects = {k: v for k, v in data["effects"].items() if k not in TOP_LEVEL_CONFIG_KEYS}
                        merged_effects.update(cleaned_effects)
                        cfg["effects"] = merged_effects
                    return cfg
            except Exception as e:
                print(f"[Engine] Error loading config: {e}", file=sys.stderr)
        return dict(DEFAULT_CONFIG)

    def save_config(self):
        try:
            # Clean duplicate top-level keys out of effects before saving
            if "effects" in self.config and isinstance(self.config["effects"], dict):
                for k in TOP_LEVEL_CONFIG_KEYS:
                    self.config["effects"].pop(k, None)

            with open(CONFIG_PATH, 'w') as f:
                json.dump(self.config, f, indent=2)
            os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
            with open(STATE_FILE, 'w') as f:
                f.write(str(self.config.get("active", "")))
        except Exception as e:
            print(f"[Engine] Error saving config: {e}", file=sys.stderr)

    def on_activate(self, app):
        display = Gdk.Display.get_default()
        monitors = display.get_monitors()
        self.setup_monitors(monitors)
        monitors.connect("items-changed", lambda m, p, r, a: self.setup_monitors(m))
        self.start_ipc_server()
        self.start_telemetry_loop()

    def setup_monitors(self, monitors):
        active_connectors = set()
        for i in range(monitors.get_n_items()):
            mon = monitors.get_item(i)
            conn = mon.get_connector() or f"mon-{i}"
            active_connectors.add(conn)

            if conn not in self.windows:
                self.create_window_for_monitor(mon, conn)

        # Remove disconnected monitors
        for conn in list(self.windows.keys()):
            if conn not in active_connectors:
                info = self.windows.pop(conn)
                try:
                    info['win'].destroy()
                except:
                    pass

    def create_window_for_monitor(self, monitor, connector):
        win = Gtk.ApplicationWindow(application=self.app)
        Gtk4LayerShell.init_for_window(win)
        Gtk4LayerShell.set_layer(win, Gtk4LayerShell.Layer.BACKGROUND)
        Gtk4LayerShell.set_keyboard_mode(win, Gtk4LayerShell.KeyboardMode.NONE)
        Gtk4LayerShell.set_namespace(win, "dark-niri-wallpaper")
        Gtk4LayerShell.set_anchor(win, Gtk4LayerShell.Edge.TOP, True)
        Gtk4LayerShell.set_anchor(win, Gtk4LayerShell.Edge.BOTTOM, True)
        Gtk4LayerShell.set_anchor(win, Gtk4LayerShell.Edge.LEFT, True)
        Gtk4LayerShell.set_anchor(win, Gtk4LayerShell.Edge.RIGHT, True)
        Gtk4LayerShell.set_exclusive_zone(win, -1)
        Gtk4LayerShell.set_monitor(win, monitor)

        view = WebKit.WebView()
        settings = view.get_settings()
        settings.set_enable_javascript(True)
        settings.set_enable_webgl(True)
        settings.set_hardware_acceleration_policy(WebKit.HardwareAccelerationPolicy.ALWAYS)
        settings.set_enable_media(True)
        settings.set_media_playback_allows_inline(True)
        # Minimize caching and enable cross-directory access for local wallpaper pictures
        settings.set_enable_page_cache(False)
        settings.set_enable_offline_web_application_cache(False)
        settings.set_allow_file_access_from_file_urls(True)
        settings.set_allow_universal_access_from_file_urls(True)
        view.set_is_muted(True)

        # Inject Bridge UserScript
        ucm = view.get_user_content_manager()
        script = WebKit.UserScript(
            BRIDGE_USER_SCRIPT,
            WebKit.UserContentInjectedFrames.ALL_FRAMES,
            WebKit.UserScriptInjectionTime.START,
            None, None
        )
        ucm.add_script(script)

        win.set_child(view)
        info = {
            'win': win,
            'view': view,
            'connector': connector,
            'current_url': None
        }
        self.windows[connector] = info

        def on_load(wv, event):
            if event == WebKit.LoadEvent.FINISHED:
                self.apply_effects_to_view(wv)
                self.push_state_to_view(wv)
                # If target is an image/video, pass file to view immediately
                target = self.get_target_for_monitor(connector)
                if target and (os.path.isabs(target) or os.path.exists(target)):
                    file_uri = target if target.startswith("file://") else f"file://{target}"
                    script = f"if (window.setWallpaperImage) window.setWallpaperImage({json.dumps(file_uri)});"
                    wv.evaluate_javascript(script, -1, None, None, None, None, None)

        def on_load_failed(wv, event, failing_uri, error):
            print(f"[Engine] Load failed for {failing_uri}: {error.message}. Using fallback.", file=sys.stderr)
            wv.load_uri(FALLBACK_URI)
            return True

        view.connect("load-changed", on_load)
        view.connect("load-failed", on_load_failed)

        target = self.get_target_for_monitor(connector)
        self.load_target_into_view(info, target)
        win.present()

    def get_target_for_monitor(self, connector):
        mode = self.config.get("mode", "global")
        if mode == "per-monitor":
            mons = self.config.get("monitors", {})
            return mons.get(connector, self.config.get("active", "cyber-city"))
        return self.config.get("active", "cyber-city")

    def get_target_url(self, target):
        if not target:
            target = "cyber-city"

        if target.startswith("color:"):
            hex_col = target.split(":", 1)[1]
            return f"data:text/html,<html><head><style>*{{margin:0;padding:0;overflow:hidden;}}body{{background:{hex_col};width:100vw;height:100vh;}}</style></head><body></body></html>"

        # Check if theme directory
        if not os.path.isabs(target):
            theme_path = os.path.join(THEMES_DIR, target)
            if os.path.isdir(theme_path):
                theme_index = os.path.join(theme_path, "index.html")
                if os.path.exists(theme_index):
                    return f"file://{theme_index}"

        # Otherwise treat as image or video file (auto-wrapped in image-viewer)
        img_viewer_index = os.path.join(THEMES_DIR, "image-viewer", "index.html")
        return f"file://{img_viewer_index}"

    def load_target_into_view(self, info, target):
        view = info['view']
        target_url = self.get_target_url(target)
        info['current_url'] = target_url

        # Check if image-viewer wrapper
        if target_url.startswith("file://") and "image-viewer" in target_url:
            file_uri = target if target.startswith("file://") else f"file://{target}"
            current_uri = view.get_uri() or ""
            if "image-viewer" in current_uri:
                # Already in image-viewer; fast smooth image switch without reloading page!
                script = f"""
                if (window.setWallpaperImage) window.setWallpaperImage({json.dumps(file_uri)});
                if (window.updateWallpaperConfig) window.updateWallpaperConfig({json.dumps(self.config)});
                """
                try:
                    view.evaluate_javascript(script, -1, None, None, None, None, None)
                except Exception:
                    pass
                return
            else:
                # Load with hash
                view.load_uri(f"{target_url}#{file_uri}")
                return

        view.load_uri(target_url)
        gc.collect()

    def apply_effects_to_view(self, view):
        cfg_json = json.dumps(self.config)
        script = f"if (window.updateWallpaperConfig) {{ window.updateWallpaperConfig({cfg_json}); }}"
        try:
            view.evaluate_javascript(script, -1, None, None, None, None, None)
        except Exception:
            pass

    def push_state_to_view(self, view):
        state_json = json.dumps(self.current_state)
        script = f"if (window.__onWallpaperStateUpdate) {{ window.__onWallpaperStateUpdate({state_json}); }}"
        try:
            view.evaluate_javascript(script, -1, None, None, None, None, None)
        except Exception:
            pass

    def broadcast_state(self):
        state_json = json.dumps(self.current_state)
        script = f"if (window.__onWallpaperStateUpdate) {{ window.__onWallpaperStateUpdate({state_json}); }}"
        for conn, info in self.windows.items():
            try:
                info['view'].evaluate_javascript(script, -1, None, None, None, None, None)
            except Exception:
                pass
        return False  # Explicitly return False so idle handlers never repeat

    def apply_all(self):
        for conn, info in self.windows.items():
            target = self.get_target_for_monitor(conn)
            self.load_target_into_view(info, target)
        gc.collect()

    def set_target(self, target, monitor=None):
        if not target:
            return {"status": "error", "message": "Empty target"}

        # Validate existence if file
        if not target.startswith("color:") and not os.path.exists(os.path.join(THEMES_DIR, target)):
            if not os.path.exists(target):
                cand = os.path.join(WALLPAPERS_DIR, target)
                if os.path.exists(cand):
                    target = cand
                else:
                    return {"status": "error", "message": f"File not found: {target}"}

        if monitor and monitor in self.windows:
            self.config["mode"] = "per-monitor"
            if "monitors" not in self.config:
                self.config["monitors"] = {}
            self.config["monitors"][monitor] = target
        else:
            self.config["active"] = target
            if target.startswith("color:"):
                self.config["active_type"] = "color"
            elif not os.path.isabs(target) and os.path.isdir(os.path.join(THEMES_DIR, target)):
                self.config["active_type"] = "theme"
            else:
                self.config["active_type"] = "image"

        self.save_config()
        self.apply_all()
        return {"status": "ok", "active": target, "type": self.config.get("active_type", "theme")}

    def set_effect(self, key_path, value):
        # Convert string representations
        if isinstance(value, str):
            val_lower = value.strip().lower()
            if val_lower == "true": value = True
            elif val_lower == "false": value = False
            else:
                try:
                    if "." in value: value = float(value)
                    else: value = int(value)
                except ValueError:
                    pass

        # Handle top-level keys
        if key_path in TOP_LEVEL_CONFIG_KEYS:
            self.config[key_path] = value
            if "effects" in self.config and isinstance(self.config["effects"], dict):
                self.config["effects"].pop(key_path, None)
        elif key_path.startswith("effects."):
            sub = key_path[len("effects."):]
            keys = sub.split(".")
            d = self.config.setdefault("effects", {})
            for k in keys[:-1]:
                if k not in d or not isinstance(d[k], dict):
                    d[k] = {}
                d = d[k]
            d[keys[-1]] = value
        else:
            keys = key_path.split(".")
            if keys[0] in TOP_LEVEL_CONFIG_KEYS:
                self.config[keys[0]] = value
            else:
                d = self.config.setdefault("effects", {})
                for k in keys[:-1]:
                    if k not in d or not isinstance(d[k], dict):
                        d[k] = {}
                    d = d[k]
                d[keys[-1]] = value

        self.save_config()

        # Update all views immediately
        for conn, info in self.windows.items():
            self.apply_effects_to_view(info['view'])

        return {"status": "ok", "key": key_path, "value": value}

    def set_config(self, new_cfg):
        if isinstance(new_cfg, dict):
            self.config.update(new_cfg)
            self.save_config()
            self.apply_all()
            return {"status": "ok"}
        return {"status": "error", "message": "Config must be object"}

    def get_list(self):
        wallpapers = []

        # 1. HTML Themes
        if os.path.exists(THEMES_DIR):
            for t in sorted(os.listdir(THEMES_DIR)):
                tdir = os.path.join(THEMES_DIR, t)
                if os.path.isdir(tdir) and t != "image-viewer":
                    manifest_path = os.path.join(tdir, "wallpaper.json")
                    meta = {"name": t.replace("-", " ").title(), "description": "Interactive HTML Wallpaper", "type": "theme"}
                    if os.path.exists(manifest_path):
                        try:
                            with open(manifest_path) as mf:
                                meta.update(json.load(mf))
                        except:
                            pass
                    wallpapers.append({
                        "name": meta.get("name", t),
                        "path": t,
                        "thumb": "",
                        "type": "theme",
                        "description": meta.get("description", ""),
                        "interactive": meta.get("interactive", False),
                        "audioReactive": meta.get("audioReactive", False)
                    })

        # 2. Files in ~/Pictures/Wallpapers
        if os.path.exists(WALLPAPERS_DIR):
            for ext in ("*.jpg", "*.jpeg", "*.png", "*.webp", "*.mp4", "*.webm", "*.gif"):
                for p in sorted(glob.glob(os.path.join(WALLPAPERS_DIR, ext))):
                    name = os.path.basename(p)
                    is_vid = name.lower().endswith(('.mp4', '.webm', '.mkv', '.gif'))
                    wallpapers.append({
                        "name": name,
                        "path": p,
                        "thumb": p,
                        "type": "video" if is_vid else "image",
                        "description": "Live Video Wallpaper" if is_vid else "Static Image"
                    })

        return wallpapers

    # Native, Low-Overhead Telemetry Loop (Runs every 2 seconds via GLib timer)
    def start_telemetry_loop(self):
        self.update_telemetry_timer()
        GLib.timeout_add_seconds(2, self.update_telemetry_timer)

    def update_telemetry_timer(self):
        if not self.running:
            return False
        try:
            cpu_pct = self.calc_cpu()
            mem_pct = self.calc_memory()
            bat_info = self.get_battery()
            ws_info = self.get_niri_workspace()
            media_info = self.get_media()
            is_fullscreen = self.check_niri_fullscreen()

            self.current_state = {
                "cpu": cpu_pct,
                "memory": mem_pct,
                "battery": bat_info,
                "workspace": ws_info,
                "media": media_info,
                "monitors": list(self.windows.keys()),
                "fullscreen": is_fullscreen
            }

            self.broadcast_state()
        except Exception:
            pass
        return True

    def check_niri_fullscreen(self):
        if not self.config.get("pause_fullscreen", True):
            return False
        try:
            out = subprocess.check_output(['niri', 'msg', '--json', 'windows'], stderr=subprocess.DEVNULL, timeout=0.3)
            windows = json.loads(out)
            for w in windows:
                if w.get('is_focused') and not w.get('is_floating'):
                    layout = w.get('layout', {})
                    size = layout.get('window_size', [0, 0])
                    # Fullscreen or maximized covering the monitor
                    if size[0] >= 1900 and size[1] >= 1000:
                        return True
        except Exception:
            pass
        return False

    def calc_cpu(self):
        try:
            with open('/proc/stat', 'r') as f:
                fields = [float(x) for x in f.readline().strip().split()[1:8]]
            idle = fields[3]
            total = sum(fields)
            if self.last_cpu_times:
                last_idle, last_total = self.last_cpu_times
                idle_delta = idle - last_idle
                total_delta = total - last_total
                pct = int(round(100.0 * (1.0 - idle_delta / max(1.0, total_delta))))
            else:
                pct = 0
            self.last_cpu_times = (idle, total)
            return max(0, min(100, pct))
        except:
            return 0

    def calc_memory(self):
        try:
            mem = {}
            with open('/proc/meminfo', 'r') as f:
                for line in f:
                    parts = line.split(':')
                    if len(parts) == 2:
                        k = parts[0].strip()
                        v = parts[1].strip().split()[0]
                        mem[k] = float(v)
            total = mem.get('MemTotal', 1)
            avail = mem.get('MemAvailable', total)
            return int(round(((total - avail) / total) * 100.0))
        except:
            return 0

    def get_battery(self):
        try:
            bat_path = glob.glob('/sys/class/power_supply/BAT*')
            if bat_path:
                cap_f = os.path.join(bat_path[0], 'capacity')
                stat_f = os.path.join(bat_path[0], 'status')
                cap = int(open(cap_f).read().strip()) if os.path.exists(cap_f) else 100
                stat = open(stat_f).read().strip() if os.path.exists(stat_f) else "Discharging"
                return {"percentage": cap, "charging": stat.lower() == "charging"}
        except:
            pass
        return {"percentage": 100, "charging": False}

    def get_niri_workspace(self):
        try:
            out = subprocess.check_output(['niri', 'msg', '--json', 'workspaces'], stderr=subprocess.DEVNULL, timeout=0.3)
            workspaces = json.loads(out)
            for w in workspaces:
                if w.get('is_focused') or w.get('is_active'):
                    return {"id": w.get('id', 1), "idx": w.get('idx', 1)}
        except:
            pass
        return {"id": 1, "idx": 1}

    def get_media(self):
        try:
            out = subprocess.check_output([
                'playerctl', 'metadata', '--format',
                '{"title": "{{title}}", "artist": "{{artist}}", "status": "{{status}}", "artUrl": "{{mpris:artUrl}}"}'
            ], stderr=subprocess.DEVNULL, timeout=0.3)
            return json.loads(out.decode().strip())
        except:
            pass
        return {"title": "", "artist": "", "status": "Stopped", "artUrl": ""}

    # IPC Client Handler
    def handle_client(self, conn):
        try:
            data = conn.recv(65536).decode("utf-8")
            if not data:
                return

            try:
                msg = json.loads(data.strip())
            except Exception:
                parts = data.strip().split(maxsplit=1)
                cmd = parts[0] if parts else ""
                arg = parts[1] if len(parts) > 1 else ""
                msg = {"cmd": cmd, "target": arg, "value": arg}

            cmd = msg.get("cmd")
            response = {"status": "unknown_command"}

            event = threading.Event()
            res_box = [response]

            def run_on_gtk():
                try:
                    if cmd == "set":
                        res_box[0] = self.set_target(msg.get("target") or msg.get("value"), msg.get("monitor"))
                    elif cmd == "color":
                        hex_c = msg.get("hex") or msg.get("target") or msg.get("value")
                        if hex_c and not hex_c.startswith("#"):
                            hex_c = f"#{hex_c}"
                        res_box[0] = self.set_target(f"color:{hex_c}", msg.get("monitor"))
                    elif cmd == "set_effect":
                        res_box[0] = self.set_effect(msg.get("key"), msg.get("value"))
                    elif cmd == "set_config":
                        res_box[0] = self.set_config(msg.get("config"))
                    elif cmd == "get_config":
                        res_box[0] = self.config
                    elif cmd == "get":
                        res_box[0] = {"active": self.config.get("active", "")}
                    elif cmd == "list":
                        res_box[0] = self.get_list()
                    elif cmd == "monitors":
                        res_box[0] = {"monitors": list(self.windows.keys()), "mode": self.config.get("mode", "global")}
                    elif cmd == "status":
                        res_box[0] = {
                            "running": True,
                            "pid": os.getpid(),
                            "monitors": list(self.windows.keys()),
                            "active": self.config.get("active", ""),
                            "active_type": self.config.get("active_type", "theme"),
                            "mode": self.config.get("mode", "global"),
                            "quality": self.config.get("quality", "balanced"),
                            "fps": self.config.get("fps", 60),
                            "pause_fullscreen": self.config.get("pause_fullscreen", True),
                            "battery_saver": self.config.get("battery_saver", True),
                            "effects": self.config.get("effects", {})
                        }
                    elif cmd == "reload":
                        self.apply_all()
                        res_box[0] = {"status": "reloaded"}
                    elif cmd == "stop":
                        self.app.quit()
                        res_box[0] = {"status": "stopping"}
                except Exception as ex:
                    res_box[0] = {"status": "error", "error": str(ex)}
                finally:
                    event.set()
                return False

            GLib.idle_add(run_on_gtk)
            event.wait(timeout=5.0)

            if cmd == "get":
                conn.sendall((self.config.get("active", "") + "\n").encode("utf-8"))
            else:
                conn.sendall((json.dumps(res_box[0]) + "\n").encode("utf-8"))
        except Exception:
            pass
        finally:
            try:
                conn.close()
            except:
                pass

    def start_ipc_server(self):
        if os.path.exists(SOCKET_PATH):
            try:
                os.unlink(SOCKET_PATH)
            except:
                pass

        self.server_sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.server_sock.bind(SOCKET_PATH)
        self.server_sock.listen(10)

        def server_loop():
            while self.running:
                try:
                    conn, _ = self.server_sock.accept()
                    threading.Thread(target=self.handle_client, args=(conn,), daemon=True).start()
                except Exception:
                    break

        self.server_thread = threading.Thread(target=server_loop, daemon=True)
        self.server_thread.start()

    def run(self):
        def sig_handler(sig, frame):
            self.running = False
            if os.path.exists(SOCKET_PATH):
                try: os.unlink(SOCKET_PATH)
                except: pass
            self.app.quit()

        signal.signal(signal.SIGINT, sig_handler)
        signal.signal(signal.SIGTERM, sig_handler)
        self.app.run(None)

if __name__ == "__main__":
    app = WallpaperEngineApp()
    app.run()
