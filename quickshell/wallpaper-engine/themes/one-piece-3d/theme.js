const uniforms = {
  time: { value: 0 }
};

const oceanVertexShader = `
  varying vec2 vUv;
  uniform float time;
  void main() {
    vUv = uv;
    vec3 pos = position;
    // Simple wave calculation
    pos.z += sin(pos.x * 0.1 + time * 0.002) * 1.5;
    pos.z += cos(pos.y * 0.1 + time * 0.003) * 1.5;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
  }
`;

const oceanFragmentShader = `
  varying vec2 vUv;
  void main() {
    // Basic anime water color blending
    vec3 baseColor = vec3(0.04, 0.22, 0.33); // 0x0b3954
    vec3 highlightColor = vec3(0.12, 0.45, 0.65);
    
    float mixFactor = sin(vUv.x * 50.0) * cos(vUv.y * 50.0);
    vec3 finalColor = mix(baseColor, highlightColor, smoothstep(0.4, 0.6, mixFactor + 0.5));
    
    gl_FragColor = vec4(finalColor, 1.0);
  }
`;

let shipGroup;
let sunMesh;
let clouds = [];

WallpaperEngine.init({
  onInit: (scene, camera, renderer) => {
    // Lighting
    scene.add(new THREE.AmbientLight(0xff8c42, 0.3));
    
    const dirLight = new THREE.DirectionalLight(0xffd700, 1.5);
    dirLight.position.set(0, 20, -50);
    scene.add(dirLight);
    
    const hemiLight = new THREE.HemisphereLight(0xfb9062, 0x0b3954, 0.5);
    scene.add(hemiLight);

    // Ocean
    const oceanGeo = new THREE.PlaneGeometry(300, 300, 32, 32);
    const oceanMat = new THREE.ShaderMaterial({
      vertexShader: oceanVertexShader,
      fragmentShader: oceanFragmentShader,
      uniforms: uniforms,
      wireframe: false
    });
    const ocean = new THREE.Mesh(oceanGeo, oceanMat);
    ocean.rotation.x = -Math.PI / 2;
    ocean.position.y = -10;
    scene.add(ocean);

    // Sun
    const sunGeo = new THREE.CircleGeometry(20, 32);
    const sunMat = new THREE.MeshBasicMaterial({ color: 0xff4500, fog: false });
    sunMesh = new THREE.Mesh(sunGeo, sunMat);
    sunMesh.position.set(0, 5, -100);
    scene.add(sunMesh);

    // Ship Deck (Foreground)
    shipGroup = new THREE.Group();
    
    const deckGeo = new THREE.BoxGeometry(40, 2, 20);
    const deckMat = new THREE.MeshStandardMaterial({ color: 0x8b4513 });
    const deck = new THREE.Mesh(deckGeo, deckMat);
    deck.position.y = -8;
    deck.position.z = 20;
    shipGroup.add(deck);

    const railingGeo = new THREE.BoxGeometry(40, 3, 1);
    const railing = new THREE.Mesh(railingGeo, deckMat);
    railing.position.y = -6;
    railing.position.z = 10;
    shipGroup.add(railing);
    
    const mastGeo = new THREE.CylinderGeometry(1, 1, 30, 8);
    const mast = new THREE.Mesh(mastGeo, deckMat);
    mast.position.y = 5;
    mast.position.z = 15;
    shipGroup.add(mast);

    scene.add(shipGroup);

    // Clouds
    for(let i = 0; i < 5; i++) {
      const cloudGeo = new THREE.PlaneGeometry(30, 10);
      const cloudMat = new THREE.MeshBasicMaterial({ color: 0xfb9062, transparent: true, opacity: 0.6 });
      const cloud = new THREE.Mesh(cloudGeo, cloudMat);
      cloud.position.set(Math.random() * 100 - 50, Math.random() * 20 + 10, -80);
      scene.add(cloud);
      clouds.push(cloud);

      anime({
        targets: cloud.position,
        x: '+=100',
        duration: 20000 + Math.random() * 10000,
        easing: 'linear',
        loop: true,
        direction: 'normal'
      });
    }

    // Ship Sway
    anime({
      targets: shipGroup.rotation,
      z: [ -0.05, 0.05 ],
      x: [ -0.02, 0.02 ],
      duration: 4000,
      direction: 'alternate',
      easing: 'easeInOutSine',
      loop: true
    });

    camera.position.set(0, 0, 30);
    scene.fog = new THREE.Fog(0xfb9062, 50, 150);

    // Clock
    window._onePieceInterval = setInterval(() => {
      const d = new Date();
      document.getElementById('clock').innerText = d.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
    }, 1000);
  },
  onRender: (time, delta) => {
    uniforms.time.value = time;
    
    clouds.forEach(c => {
      if(c.position.x > 80) c.position.x = -80;
    });
  },
  onDispose: () => {
    if (window._onePieceInterval) clearInterval(window._onePieceInterval);
    clouds = [];
    shipGroup = null;
    sunMesh = null;
  }
});
