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