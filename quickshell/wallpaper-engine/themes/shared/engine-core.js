/**
 * THREE.JS + ANIME.JS WALLPAPER ENGINE CORE
 * Shared boilerplate for WebGL wallpapers in the Wayland/Niri ecosystem.
 */

window.WallpaperEngine = (function() {
  let scene, camera, renderer;
  let animationId = null;
  let lastRenderTime = 0;
  let isContextLost = false;

  const CONFIG = {
    targetFPS: 60,
    quality: 'high',
    mouseParallax: true
  };

  let targetMouseX = 0;
  let targetMouseY = 0;

  // Theme Hooks
  let themeHooks = {
    onInit: (scene, camera, renderer) => {},
    onRender: (time, delta) => {},
    onDispose: () => {}
  };

  function init(hooks) {
    if (hooks) themeHooks = { ...themeHooks, ...hooks };

    const container = document.getElementById('container');
    
    scene = new THREE.Scene();
    
    camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000);
    camera.position.z = 50;

    renderer = new THREE.WebGLRenderer({ antialias: false, alpha: true, powerPreference: "high-performance" });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    container.appendChild(renderer.domElement);

    renderer.domElement.addEventListener("webglcontextlost", (event) => {
      event.preventDefault();
      isContextLost = true;
      cancelAnimationFrame(animationId);
      console.warn("WebGL Context Lost!");
    }, false);

    renderer.domElement.addEventListener("webglcontextrestored", () => {
      isContextLost = false;
      console.log("WebGL Context Restored!");
      reinitScene();
      renderLoop(performance.now());
    }, false);

    reinitScene();
    setupBridge();
    setupEvents();
    
    renderLoop(performance.now());
    return { scene, camera, renderer, CONFIG };
  }

  function reinitScene() {
    if (themeHooks.onDispose) themeHooks.onDispose();
    if (window.anime) anime.remove('*');
    
    scene.traverse((object) => {
      if (!object.isMesh) return;
      if (object.geometry) object.geometry.dispose();
      if (object.material) {
        if (Array.isArray(object.material)) object.material.forEach(m => disposeMaterial(m));
        else disposeMaterial(object.material);
      }
    });
    
    while(scene.children.length > 0){ 
      scene.remove(scene.children[0]); 
    }
    themeHooks.onInit(scene, camera, renderer);
  }

  function renderLoop(time) {
    if (isContextLost) return;
    animationId = requestAnimationFrame(renderLoop);

    if (window.__isWallpaperObscured) return;

    const timeSinceLastRender = time - lastRenderTime;
    const frameInterval = 1000 / CONFIG.targetFPS;
    
    if (timeSinceLastRender < frameInterval) return;
    const delta = timeSinceLastRender;
    lastRenderTime = time - (timeSinceLastRender % frameInterval);

    if (CONFIG.mouseParallax && !window.__isWallpaperObscured) {
      camera.position.x += (targetMouseX - camera.position.x) * 0.05;
      camera.position.y += (targetMouseY - camera.position.y) * 0.05;
      camera.lookAt(scene.position);
    }

    themeHooks.onRender(time, delta);
    renderer.render(scene, camera);
  }

  function setupEvents() {
    window.addEventListener('resize', () => {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    });

    document.addEventListener('mousemove', (e) => {
      const mouseX = (e.clientX / window.innerWidth) * 2 - 1;
      const mouseY = -(e.clientY / window.innerHeight) * 2 + 1;
      targetMouseX = mouseX * 2;
      targetMouseY = mouseY * 2;
    });
    
    window.addEventListener("unload", disposeResources);
  }

  function setupBridge() {
    if (!window.wallpaper) return;

    window.wallpaper.on('battery', (data) => {
      if (!data.charging && data.percentage < 30) {
        CONFIG.targetFPS = 30;
        CONFIG.quality = 'battery_saver';
        renderer.setPixelRatio(1);
      } else {
        CONFIG.targetFPS = 60;
        CONFIG.quality = 'high';
        renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
      }
    });

    window.wallpaper.on('telemetry', (data) => {
      // Telemetry hook
    });
  }

  function disposeResources() {
    cancelAnimationFrame(animationId);
    if (window.anime) anime.remove('*');
    
    themeHooks.onDispose();

    if (!scene) return;
    scene.traverse((object) => {
      if (!object.isMesh) return;
      
      if (object.geometry) {
        object.geometry.dispose();
      }
      
      if (object.material) {
        if (Array.isArray(object.material)) {
          object.material.forEach(m => disposeMaterial(m));
        } else {
          disposeMaterial(object.material);
        }
      }
    });

    if (renderer) {
      renderer.dispose();
      renderer.forceContextLoss();
    }
  }

  function disposeMaterial(material) {
    Object.keys(material).forEach(prop => {
      if (!material[prop]) return;
      if (material[prop] !== null && typeof material[prop].dispose === 'function') {
        material[prop].dispose();
      }
    });
    material.dispose();
  }

  return { init, disposeResources };
})();
