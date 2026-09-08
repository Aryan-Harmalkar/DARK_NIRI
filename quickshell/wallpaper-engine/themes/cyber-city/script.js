// Cyber City - High Performance Procedural Cyberpunk Wallpaper Engine
(function() {
  const skyCanvas = document.getElementById('sky-canvas');
  const cityCanvas = document.getElementById('city-canvas');
  const trafficCanvas = document.getElementById('traffic-canvas');
  const rainCanvas = document.getElementById('rain-canvas');

  const skyCtx = skyCanvas.getContext('2d');
  const cityCtx = cityCanvas.getContext('2d');
  const trafficCtx = trafficCanvas.getContext('2d');
  const rainCtx = rainCanvas.getContext('2d');

  const hudClock = document.getElementById('hud-clock');
  const hudDate = document.getElementById('hud-date');
  const hudWorkspace = document.getElementById('hud-workspace');
  const telCpu = document.getElementById('tel-cpu');
  const telMem = document.getElementById('tel-mem');
  const telBat = document.getElementById('tel-bat');
  const hudMediaTitle = document.getElementById('hud-media-title');

  let width = window.innerWidth;
  let height = window.innerHeight;

  // Parallax & Mouse
  let mouseX = width / 2;
  let mouseY = height / 2;
  let targetParallaxX = 0;
  let targetParallaxY = 0;
  let currentParallaxX = 0;
  let currentParallaxY = 0;

  window.addEventListener('mousemove', (e) => {
    mouseX = e.clientX;
    mouseY = e.clientY;
    targetParallaxX = (mouseX / width - 0.5) * 40;
    targetParallaxY = (mouseY / height - 0.5) * 20;
  });

  function resize() {
    width = skyCanvas.width = cityCanvas.width = trafficCanvas.width = rainCanvas.width = window.innerWidth;
    height = skyCanvas.height = cityCanvas.height = trafficCanvas.height = rainCanvas.height = window.innerHeight;
    generateCity();
    drawSky();
  }
  window.addEventListener('resize', resize);

  // 1. Sky & Giant Neon Moon
  function drawSky() {
    skyCtx.clearRect(0, 0, width, height);

    // Deep gradient
    const skyGrad = skyCtx.createLinearGradient(0, 0, 0, height);
    skyGrad.addColorStop(0, '#090a12');
    skyGrad.addColorStop(0.5, '#121424');
    skyGrad.addColorStop(0.85, '#1a1b2e');
    skyGrad.addColorStop(1, '#24283b');
    skyCtx.fillStyle = skyGrad;
    skyCtx.fillRect(0, 0, width, height);

    // Distant Stars / Grid horizon
    skyCtx.fillStyle = 'rgba(122, 162, 247, 0.4)';
    for (let i = 0; i < 60; i++) {
      const sx = (Math.sin(i * 99) * 0.5 + 0.5) * width;
      const sy = (Math.cos(i * 33) * 0.5 + 0.5) * (height * 0.6);
      const size = (i % 3 === 0) ? 1.5 : 1.0;
      skyCtx.fillRect(sx, sy, size, size);
    }

    // Distant glowing cyberpunk moon / sun
    const moonX = width * 0.75;
    const moonY = height * 0.28;
    const moonRadius = 65;

    const glowGrad = skyCtx.createRadialGradient(moonX, moonY, 10, moonX, moonY, moonRadius * 2.5);
    glowGrad.addColorStop(0, 'rgba(187, 154, 247, 0.45)');
    glowGrad.addColorStop(0.4, 'rgba(122, 162, 247, 0.15)');
    glowGrad.addColorStop(1, 'transparent');
    skyCtx.fillStyle = glowGrad;
    skyCtx.beginPath();
    skyCtx.arc(moonX, moonY, moonRadius * 2.5, 0, Math.PI * 2);
    skyCtx.fill();

    skyCtx.fillStyle = '#c0caf5';
    skyCtx.shadowColor = '#bb9af7';
    skyCtx.shadowBlur = 24;
    skyCtx.beginPath();
    skyCtx.arc(moonX, moonY, moonRadius, 0, Math.PI * 2);
    skyCtx.fill();
    skyCtx.shadowBlur = 0;
  }

  // 2. Multi-Layered Skyline
  let buildingsLayer1 = [];
  let buildingsLayer2 = [];
  let buildingsLayer3 = [];
  const neonPalette = ['#7aa2f7', '#bb9af7', '#7dcfff', '#f7768e', '#9ece6a'];

  function generateCity() {
    buildingsLayer1 = generateLayer(0.45, 0.25, 60, 110, '#10111a', 0.5);
    buildingsLayer2 = generateLayer(0.65, 0.40, 80, 150, '#161724', 0.8);
    buildingsLayer3 = generateLayer(0.85, 0.55, 100, 180, '#1c1d2e', 1.0);
  }

  function generateLayer(maxHFrac, minHFrac, minW, maxW, color, neonDensity) {
    const list = [];
    let curX = -100;
    while (curX < width + 100) {
      const bWidth = Math.floor(Math.random() * (maxW - minW)) + minW;
      const bHeight = Math.floor(Math.random() * (height * (maxHFrac - minHFrac))) + (height * minHFrac);
      const bY = height - bHeight;

      // Windows grid
      const windows = [];
      const cols = Math.floor(bWidth / 14);
      const rows = Math.floor(bHeight / 20);
      for (let r = 2; r < rows - 1; r++) {
        for (let c = 1; c < cols - 1; c++) {
          if (Math.random() > 0.65) {
            windows.push({
              x: c * 14,
              y: r * 20,
              color: Math.random() > 0.85 ? neonPalette[Math.floor(Math.random() * neonPalette.length)] : 'rgba(192, 202, 245, 0.4)'
            });
          }
        }
      }

      // Neon Billboard or Antenna
      let sign = null;
      if (Math.random() < neonDensity * 0.4) {
        const words = ['NIRI', 'WAYLAND', 'ARCH', 'NEO', 'MATRIX', 'CYBER', 'HYPER'];
        sign = {
          text: words[Math.floor(Math.random() * words.length)],
          color: neonPalette[Math.floor(Math.random() * neonPalette.length)],
          y: bY + 30
        };
      }

      list.push({
        x: curX,
        y: bY,
        w: bWidth,
        h: bHeight,
        color: color,
        windows: windows,
        antenna: Math.random() > 0.5,
        sign: sign
      });
      curX += bWidth - 8;
    }
    return list;
  }

  function renderCity() {
    cityCtx.clearRect(0, 0, width, height);

    // Layer 1 (Far background)
    drawBuildingLayer(cityCtx, buildingsLayer1, currentParallaxX * 0.2, currentParallaxY * 0.1);
    // Layer 2 (Midground)
    drawBuildingLayer(cityCtx, buildingsLayer2, currentParallaxX * 0.5, currentParallaxY * 0.25);
    // Layer 3 (Foreground)
    drawBuildingLayer(cityCtx, buildingsLayer3, currentParallaxX * 0.9, currentParallaxY * 0.5);
  }

  function drawBuildingLayer(ctx, layer, offX, offY) {
    for (let b of layer) {
      const bx = b.x + offX;
      const by = b.y + offY;

      ctx.fillStyle = b.color;
      ctx.fillRect(bx, by, b.w, b.h + 50);

      // Antenna
      if (b.antenna) {
        ctx.strokeStyle = '#24283b';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(bx + b.w / 2, by);
        ctx.lineTo(bx + b.w / 2, by - 35);
        ctx.stroke();

        // Pulsing red beacon
        if (Math.floor(Date.now() / 600) % 2 === 0) {
          ctx.fillStyle = '#f7768e';
          ctx.beginPath();
          ctx.arc(bx + b.w / 2, by - 35, 3, 0, Math.PI * 2);
          ctx.fill();
        }
      }

      // Windows
      for (let w of b.windows) {
        ctx.fillStyle = w.color;
        ctx.fillRect(bx + w.x, by + w.y, 7, 10);
      }

      // Neon Sign
      if (b.sign) {
        ctx.save();
        ctx.fillStyle = b.sign.color;
        ctx.shadowColor = b.sign.color;
        ctx.shadowBlur = 10;
        ctx.font = 'bold 11px monospace';
        ctx.fillText(b.sign.text, bx + 12, by + 30);
        ctx.restore();
      }
    }
  }

  // 3. Flying Hover Traffic (Spinners)
  let vehicles = [];
  function initVehicles() {
    vehicles = [];
    for (let i = 0; i < 16; i++) {
      const dir = Math.random() > 0.5 ? 1 : -1;
      vehicles.push({
        x: Math.random() * width,
        y: height * 0.35 + Math.random() * (height * 0.45),
        speed: (Math.random() * 3 + 2) * dir,
        dir: dir,
        color: dir === 1 ? '#7dcfff' : '#f7768e',
        length: Math.random() * 25 + 20
      });
    }
  }

  function renderTraffic() {
    trafficCtx.clearRect(0, 0, width, height);

    for (let v of vehicles) {
      v.x += v.speed;
      if (v.dir === 1 && v.x > width + 100) v.x = -100;
      if (v.dir === -1 && v.x < -100) v.x = width + 100;

      trafficCtx.save();
      trafficCtx.shadowColor = v.color;
      trafficCtx.shadowBlur = 8;
      trafficCtx.strokeStyle = v.color;
      trafficCtx.lineWidth = 2;

      trafficCtx.beginPath();
      trafficCtx.moveTo(v.x, v.y);
      trafficCtx.lineTo(v.x - (v.length * v.dir), v.y);
      trafficCtx.stroke();

      // Vehicle head
      trafficCtx.fillStyle = '#ffffff';
      trafficCtx.fillRect(v.x - 1, v.y - 1, 3, 3);
      trafficCtx.restore();
    }
  }

  // 4. Cyber Rain
  let raindrops = [];
  function initRain() {
    raindrops = [];
    for (let i = 0; i < 140; i++) {
      raindrops.push({
        x: Math.random() * width,
        y: Math.random() * height,
        speed: Math.random() * 12 + 14,
        len: Math.random() * 18 + 12,
        alpha: Math.random() * 0.4 + 0.2
      });
    }
  }

  function renderRain() {
    rainCtx.clearRect(0, 0, width, height);
    rainCtx.strokeStyle = 'rgba(122, 162, 247, 0.4)';
    rainCtx.lineWidth = 1.2;
    rainCtx.beginPath();

    for (let r of raindrops) {
      r.y += r.speed;
      r.x += r.speed * 0.15;
      if (r.y > height) {
        r.y = -r.len;
        r.x = Math.random() * width;
      }
      rainCtx.moveTo(r.x, r.y);
      rainCtx.lineTo(r.x + r.len * 0.15, r.y + r.len);
    }
    rainCtx.stroke();
  }

  // 5. HUD Telemetry & Desktop Clock
  function updateClock() {
    const now = new Date();
    const h = String(now.getHours()).padStart(2, '0');
    const m = String(now.getMinutes()).padStart(2, '0');
    const s = String(now.getSeconds()).padStart(2, '0');
    hudClock.textContent = `${h}:${m}:${s}`;

    const days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    hudDate.textContent = `${days[now.getDay()]}, ${months[now.getMonth()]} ${String(now.getDate()).padStart(2, '0')}`;
  }

  // 6. Connect to window.wallpaper API if available
  function initDesktopBridge() {
    if (window.wallpaper) {
      if (window.wallpaper.on) {
        window.wallpaper.on('telemetry', (data) => {
          if (data.cpu !== undefined) telCpu.textContent = `CPU: ${data.cpu}%`;
          if (data.memory !== undefined) telMem.textContent = `RAM: ${data.memory}%`;
          if (data.battery !== undefined) telBat.textContent = `BAT: ${data.battery}%`;
        });

        window.wallpaper.on('workspace', (data) => {
          if (data && data.idx) {
            hudWorkspace.textContent = `WORKSPACE: ${data.idx}`;
          }
        });

        window.wallpaper.on('media', (data) => {
          if (data && data.title) {
            hudMediaTitle.textContent = `${data.artist || 'UNKNOWN'} // ${data.title}`;
          } else {
            hudMediaTitle.textContent = 'CYBER_RADIO // STANDBY';
          }
        });
      }
    }
  }

  // Config & Remote Customizer Listener
  let currentConfig = {
    fps: 60,
    pause_fullscreen: true,
    effects: {
      weather: { enabled: true, type: 'rain' },
      clock_hud: { enabled: true },
      parallax: { enabled: true, depth: 2.5 }
    }
  };

  function updateCyberCityConfig(cfg) {
    if (!cfg) return;
    currentConfig = Object.assign({}, currentConfig, cfg);
    const eff = currentConfig.effects || {};

    // Weather toggle
    if (eff.weather && eff.weather.enabled === false) {
      rainCanvas.style.display = 'none';
    } else {
      rainCanvas.style.display = 'block';
    }

    // HUD toggle
    const hudOverlay = document.getElementById('hud-overlay');
    if (hudOverlay) {
      if (eff.clock_hud && eff.clock_hud.enabled === false) {
        hudOverlay.style.display = 'none';
      } else {
        hudOverlay.style.display = 'flex';
      }
    }

    // Parallax depth
    if (eff.parallax && eff.parallax.enabled === false) {
      targetParallaxX = 0;
      targetParallaxY = 0;
    }
  }

  window.addEventListener('wallpaperConfigChanged', (e) => {
    updateCyberCityConfig(e.detail);
  });

  // Main Animation Loop with Dynamic FPS Capping
  let lastLoopTime = performance.now();
  function loop(now) {
    requestAnimationFrame(loop);

    // Fullscreen auto-pause
    if (window.__isWallpaperObscured && currentConfig.pause_fullscreen) return;

    const targetFps = currentConfig.fps || 60;
    const interval = 1000 / targetFps;
    const elapsed = now - lastLoopTime;
    if (elapsed < interval) return;
    lastLoopTime = now - (elapsed % interval);

    // Parallax ease
    const pConf = currentConfig.effects && currentConfig.effects.parallax;
    const pDepth = (pConf && pConf.depth) ? pConf.depth : 2.5;
    currentParallaxX += (targetParallaxX * (pDepth / 2.5) - currentParallaxX) * 0.05;
    currentParallaxY += (targetParallaxY * (pDepth / 2.5) - currentParallaxY) * 0.05;

    renderCity();
    renderTraffic();
    const eff = currentConfig.effects || {};
    if (!eff.weather || eff.weather.enabled !== false) {
      renderRain();
    }
  }

  // Start Theme
  resize();
  initVehicles();
  initRain();
  updateClock();
  setInterval(updateClock, 1000);
  initDesktopBridge();
  requestAnimationFrame(loop);
})();
