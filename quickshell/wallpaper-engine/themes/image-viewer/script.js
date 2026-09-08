// Modular Wallpaper Engine - Image Viewer Controller
(function() {
  const imgEl = document.getElementById('wallpaper-image');
  const videoEl = document.getElementById('wallpaper-video');
  const imgWrapper = document.getElementById('wallpaper-image-wrapper');
  const timeOverlay = document.getElementById('time-overlay');
  const vignetteOverlay = document.getElementById('vignette-overlay');
  const scanlinesOverlay = document.getElementById('scanlines-overlay');
  const clockHud = document.getElementById('clock-hud');
  const hudTime = document.getElementById('hud-time');
  const hudDate = document.getElementById('hud-date');

  // Canvases
  const particlesCanvas = document.getElementById('particles-canvas');
  const particlesCtx = particlesCanvas.getContext('2d');
  const weatherCanvas = document.getElementById('weather-canvas');
  const weatherCtx = weatherCanvas.getContext('2d');

  let config = {
    active: '',
    fps: 60,
    effects: {
      particles: { enabled: true, count: 40, speed: 1.0, color: '#7aa2f7', style: 'embers' },
      parallax: { enabled: true, depth: 2.5 },
      time_lighting: { enabled: true, mode: 'auto', preset: 'sunset' },
      weather: { enabled: false, type: 'rain', intensity: 'medium' },
      clock_hud: { enabled: true, position: 'top-right', style: 'cyber', format24h: true, showSeconds: true },
      scanlines: { enabled: false, opacity: 0.25 },
      vignette: { enabled: true, opacity: 0.4 },
      blur: { enabled: false, radius: 0 },
      brightness: 100,
      contrast: 100
    }
  };

  // Resize canvases
  function resize() {
    particlesCanvas.width = window.innerWidth;
    particlesCanvas.height = window.innerHeight;
    weatherCanvas.width = window.innerWidth;
    weatherCanvas.height = window.innerHeight;
  }
  window.addEventListener('resize', resize);
  resize();

  // Mouse Parallax State
  let mouseX = window.innerWidth / 2;
  let mouseY = window.innerHeight / 2;
  let targetX = 0;
  let targetY = 0;
  let currentX = 0;
  let currentY = 0;
  let idleAngle = 0;

  window.addEventListener('mousemove', (e) => {
    mouseX = e.clientX;
    mouseY = e.clientY;
  });

  // Particle System
  let particles = [];
  function createParticles() {
    particles = [];
    const pConf = config.effects.particles;
    if (!pConf || !pConf.enabled) return;
    const count = pConf.count || 40;
    for (let i = 0; i < count; i++) {
      particles.push({
        x: Math.random() * window.innerWidth,
        y: Math.random() * window.innerHeight,
        size: Math.random() * 3 + 1,
        speedX: (Math.random() - 0.5) * (pConf.speed || 1.0),
        speedY: (Math.random() * -1.5 - 0.3) * (pConf.speed || 1.0),
        alpha: Math.random() * 0.7 + 0.3,
        pulseSpeed: Math.random() * 0.03 + 0.01,
        pulseVal: Math.random() * Math.PI
      });
    }
  }

  // Weather System
  let weatherParticles = [];
  function createWeather() {
    weatherParticles = [];
    const wConf = config.effects.weather;
    if (!wConf || !wConf.enabled) return;
    const count = wConf.type === 'rain' ? 120 : (wConf.type === 'snow' ? 80 : 30);
    for (let i = 0; i < count; i++) {
      weatherParticles.push({
        x: Math.random() * window.innerWidth,
        y: Math.random() * window.innerHeight,
        length: Math.random() * 20 + 10,
        speed: Math.random() * 10 + 12,
        size: Math.random() * 2.5 + 1,
        alpha: Math.random() * 0.5 + 0.3
      });
    }
  }

  // Time & Clock Loop
  function updateClock() {
    const now = new Date();
    const cHud = config.effects.clock_hud;
    if (cHud && cHud.enabled) {
      clockHud.style.display = 'flex';
      let hours = now.getHours();
      let minutes = String(now.getMinutes()).padStart(2, '0');
      let seconds = String(now.getSeconds()).padStart(2, '0');
      if (!cHud.format24h) {
        hours = hours % 12 || 12;
      } else {
        hours = String(hours).padStart(2, '0');
      }
      hudTime.textContent = cHud.showSeconds ? `${hours}:${minutes}:${seconds}` : `${hours}:${minutes}`;

      const days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
      const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
      hudDate.textContent = `${days[now.getDay()]}, ${months[now.getMonth()]} ${String(now.getDate()).padStart(2, '0')}`;
    } else {
      clockHud.style.display = 'none';
    }

    // Time Lighting
    const tConf = config.effects.time_lighting;
    if (tConf && tConf.enabled) {
      let phase = tConf.mode === 'auto' ? getAutoTimePhase(now.getHours()) : (tConf.preset || 'day');
      timeOverlay.className = phase;
    } else {
      timeOverlay.className = '';
    }
  }

  function getAutoTimePhase(hour) {
    if (hour >= 5 && hour < 8) return 'dawn';
    if (hour >= 8 && hour < 17) return 'day';
    if (hour >= 17 && hour < 20) return 'sunset';
    return 'night';
  }

  setInterval(updateClock, 1000);

  // Apply Visual Filters & Effects
  function applyEffects() {
    const eff = config.effects;
    if (!eff) return;

    // Filters on wallpaper
    let filterStr = '';
    if (eff.blur && eff.blur.enabled && eff.blur.radius > 0) {
      filterStr += `blur(${eff.blur.radius}px) `;
    }
    if (eff.brightness) {
      filterStr += `brightness(${eff.brightness}%) `;
    }
    if (eff.contrast) {
      filterStr += `contrast(${eff.contrast}%) `;
    }
    imgEl.style.filter = filterStr.trim();
    if (videoEl) videoEl.style.filter = filterStr.trim();

    // Vignette
    if (eff.vignette && eff.vignette.enabled) {
      vignetteOverlay.style.display = 'block';
      vignetteOverlay.style.opacity = eff.vignette.opacity || 0.4;
    } else {
      vignetteOverlay.style.display = 'none';
    }

    // Scanlines
    if (eff.scanlines && eff.scanlines.enabled) {
      scanlinesOverlay.style.display = 'block';
      scanlinesOverlay.style.opacity = eff.scanlines.opacity || 0.25;
    } else {
      scanlinesOverlay.style.display = 'none';
    }

    // HUD position
    if (eff.clock_hud) {
      clockHud.className = `hud-${eff.clock_hud.position || 'top-right'}`;
    }

    createParticles();
    createWeather();
    updateClock();
  }

  // Load Wallpaper Image or Video
  function loadWallpaper(src) {
    if (!src) return;
    if (!src.startsWith('file://') && !src.startsWith('data:') && !src.startsWith('http')) {
      src = 'file://' + src;
    }
    const cleanPath = src.split('?')[0];
    const isVideo = /\.(mp4|webm|mkv|mov|avi)$/i.test(cleanPath);

    if (isVideo) {
      imgEl.classList.remove('loaded');
      imgEl.style.display = 'none';
      if (videoEl) {
        videoEl.src = src;
        videoEl.style.display = 'block';
        videoEl.play().catch(() => {});
        videoEl.classList.add('loaded');
      }
    } else {
      if (videoEl) {
        videoEl.pause();
        videoEl.src = '';
        videoEl.classList.remove('loaded');
        videoEl.style.display = 'none';
      }
      imgEl.style.display = 'block';
      imgEl.classList.remove('loaded');
      const tempImg = new Image();
      tempImg.onload = function() {
        imgEl.src = src;
        imgEl.classList.add('loaded');
      };
      tempImg.onerror = function() {
        imgEl.src = src;
        imgEl.classList.add('loaded');
      };
      tempImg.src = src;
    }
  }

  // Main Render Loop with Dynamic FPS Capping and Fullscreen Pause
  let lastFrameTime = performance.now();
  let lastDeltaTime = performance.now();
  function render(time) {
    requestAnimationFrame(render);

    // Fullscreen auto-pause
    if (window.__isWallpaperObscured && config.pause_fullscreen) return;

    // Dynamic FPS Throttling
    const targetFps = config.fps || 60;
    const frameInterval = 1000 / targetFps;
    const elapsed = time - lastFrameTime;
    if (elapsed < frameInterval) return;
    lastFrameTime = time - (elapsed % frameInterval);

    const delta = (time - lastDeltaTime) / 1000;
    lastDeltaTime = time;

    // Parallax
    const pConf = config.effects.parallax;
    if (pConf && pConf.enabled) {
      const depth = pConf.depth || 2.5;
      const targetRelX = (mouseX / window.innerWidth - 0.5) * depth * 15;
      const targetRelY = (mouseY / window.innerHeight - 0.5) * depth * 15;
      currentX += (targetRelX - currentX) * 0.08;
      currentY += (targetRelY - currentY) * 0.08;
      imgWrapper.style.transform = `translate3d(${currentX}px, ${currentY}px, 0) scale(1.05)`;
    } else {
      // Subtle ambient sway
      idleAngle += delta * 0.5;
      const ambientX = Math.sin(idleAngle) * 4;
      const ambientY = Math.cos(idleAngle * 0.7) * 3;
      imgWrapper.style.transform = `translate3d(${ambientX}px, ${ambientY}px, 0)`;
    }

    // Particles Render
    const partConf = config.effects.particles;
    if (partConf && partConf.enabled && particles.length > 0) {
      particlesCtx.clearRect(0, 0, particlesCanvas.width, particlesCanvas.height);
      const color = partConf.color || '#7aa2f7';
      const style = partConf.style || 'embers';

      for (let p of particles) {
        p.x += p.speedX;
        p.y += p.speedY;
        p.pulseVal += p.pulseSpeed;

        if (p.y < -10) p.y = particlesCanvas.height + 10;
        if (p.x < -10) p.x = particlesCanvas.width + 10;
        if (p.x > particlesCanvas.width + 10) p.x = -10;

        const dynamicAlpha = p.alpha * (0.6 + 0.4 * Math.sin(p.pulseVal));
        particlesCtx.fillStyle = color;
        particlesCtx.globalAlpha = dynamicAlpha;

        if (style === 'dust') {
          particlesCtx.beginPath();
          particlesCtx.arc(p.x, p.y, p.size * 0.7, 0, Math.PI * 2);
          particlesCtx.fill();
        } else if (style === 'nodes') {
          particlesCtx.fillRect(p.x - p.size, p.y - p.size, p.size * 1.5, p.size * 1.5);
        } else {
          // Embers glow
          particlesCtx.shadowBlur = 10;
          particlesCtx.shadowColor = color;
          particlesCtx.beginPath();
          particlesCtx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
          particlesCtx.fill();
          particlesCtx.shadowBlur = 0;
        }
      }
      particlesCtx.globalAlpha = 1.0;
    } else {
      particlesCtx.clearRect(0, 0, particlesCanvas.width, particlesCanvas.height);
    }

    // Weather Render
    const wConf = config.effects.weather;
    if (wConf && wConf.enabled && weatherParticles.length > 0) {
      weatherCtx.clearRect(0, 0, weatherCanvas.width, weatherCanvas.height);
      if (wConf.type === 'rain') {
        weatherCtx.strokeStyle = 'rgba(122, 162, 247, 0.45)';
        weatherCtx.lineWidth = 1.5;
        weatherCtx.beginPath();
        for (let wp of weatherParticles) {
          wp.y += wp.speed;
          wp.x += wp.speed * 0.2;
          if (wp.y > weatherCanvas.height) {
            wp.y = -wp.length;
            wp.x = Math.random() * weatherCanvas.width;
          }
          weatherCtx.moveTo(wp.x, wp.y);
          weatherCtx.lineTo(wp.x + wp.length * 0.2, wp.y + wp.length);
        }
        weatherCtx.stroke();
      } else if (wConf.type === 'snow') {
        weatherCtx.fillStyle = 'rgba(255, 255, 255, 0.7)';
        for (let wp of weatherParticles) {
          wp.y += wp.speed * 0.25;
          wp.x += Math.sin(wp.y * 0.02) * 1.2;
          if (wp.y > weatherCanvas.height) {
            wp.y = -10;
            wp.x = Math.random() * weatherCanvas.width;
          }
          weatherCtx.beginPath();
          weatherCtx.arc(wp.x, wp.y, wp.size, 0, Math.PI * 2);
          weatherCtx.fill();
        }
      }
    } else {
      weatherCtx.clearRect(0, 0, weatherCanvas.width, weatherCanvas.height);
    }
  }

  // Public Bridge API for Python Engine / WebKit evaluate_javascript
  window.__imageViewerUpdateConfig = function(newConfig) {
    if (!newConfig) return;
    if (typeof newConfig === 'string') {
      try { newConfig = JSON.parse(newConfig); } catch(e) { return; }
    }
    config = Object.assign({}, config, newConfig);
    if (newConfig.active && newConfig.active !== imgEl.getAttribute('data-active')) {
      imgEl.setAttribute('data-active', newConfig.active);
      loadWallpaper(newConfig.active);
    }
    applyEffects();
  };
  window.updateWallpaperConfig = window.__imageViewerUpdateConfig;

  window.setWallpaperImage = function(path) {
    if (path) {
      imgEl.setAttribute('data-active', path);
      loadWallpaper(path);
    }
  };

  // Check URL hash on startup
  if (window.location.hash) {
    const rawHash = window.location.hash.substring(1);
    if (rawHash) {
      loadWallpaper(decodeURIComponent(rawHash));
    }
  }

  // Start
  requestAnimationFrame(render);
})();
