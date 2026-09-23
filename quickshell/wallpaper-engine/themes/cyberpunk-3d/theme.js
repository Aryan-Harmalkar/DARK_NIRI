let rainMesh;
let hoverCar;
let neonPlanes = [];

WallpaperEngine.init({
  onInit: (scene, camera, renderer) => {
    // Environment & Fog
    scene.background = new THREE.Color(0x0a0a2a);
    scene.fog = new THREE.FogExp2(0x0a0a2a, 0.015);

    scene.add(new THREE.AmbientLight(0x0a0a2a, 1.0));

    // Foreground Ledge
    const ledgeGeo = new THREE.BoxGeometry(100, 5, 20);
    const ledgeMat = new THREE.MeshStandardMaterial({ color: 0x111122, roughness: 0.1, metalness: 0.8 }); // wet look
    const ledge = new THREE.Mesh(ledgeGeo, ledgeMat);
    ledge.position.set(0, -10, 10);
    scene.add(ledge);

    // Neon Sign (PointLights + Fake Bloom)
    const neonColor = 0xff00ff;
    const neonLight = new THREE.PointLight(neonColor, 2, 50);
    neonLight.position.set(10, 0, 5);
    scene.add(neonLight);

    const signGeo = new THREE.BoxGeometry(8, 2, 1);
    const signMat = new THREE.MeshBasicMaterial({ color: neonColor });
    const sign = new THREE.Mesh(signGeo, signMat);
    sign.position.set(10, 0, 5);
    scene.add(sign);

    // Fake bloom plane
    const bloomGeo = new THREE.PlaneGeometry(16, 8);
    const bloomMat = new THREE.MeshBasicMaterial({ 
      color: neonColor, 
      transparent: true, 
      opacity: 0.4, 
      blending: THREE.AdditiveBlending 
    });
    const bloomPlane = new THREE.Mesh(bloomGeo, bloomMat);
    bloomPlane.position.set(10, 0, 4.9);
    scene.add(bloomPlane);
    neonPlanes.push(bloomPlane);

    // Neon Flicker Anime.js
    anime({
      targets: bloomPlane.material,
      opacity: [1, 0.5, 1, 0.1, 1],
      duration: 1500,
      loop: true,
      easing: 'linear',
      delay: anime.random(0, 1000)
    });

    anime({
      targets: neonLight,
      intensity: [2, 1, 2, 0.2, 2],
      duration: 1500,
      loop: true,
      easing: 'linear',
      delay: anime.random(0, 1000)
    });

    // Midground/Background Buildings (InstancedMesh)
    const bldgCount = 100;
    const bldgGeo = new THREE.BoxGeometry(10, 50, 10);
    const bldgMat = new THREE.MeshBasicMaterial({ color: 0x050510 }); // dark silhouette
    const bldgMesh = new THREE.InstancedMesh(bldgGeo, bldgMat, bldgCount);
    
    const matrix = new THREE.Matrix4();
    const dummy = new THREE.Object3D();
    
    for (let i = 0; i < bldgCount; i++) {
      dummy.position.x = (Math.random() - 0.5) * 200;
      dummy.position.y = (Math.random() - 0.5) * 20 + 5;
      dummy.position.z = -20 - Math.random() * 80;
      
      dummy.scale.x = 0.5 + Math.random() * 1.5;
      dummy.scale.y = 0.5 + Math.random() * 2;
      dummy.scale.z = 0.5 + Math.random() * 1.5;
      
      dummy.updateMatrix();
      bldgMesh.setMatrixAt(i, dummy.matrix);
    }
    scene.add(bldgMesh);

    // Rain System (InstancedMesh of thin lines)
    const rainCount = 2000;
    const dropGeo = new THREE.BoxGeometry(0.1, 2.0, 0.1);
    const dropMat = new THREE.MeshBasicMaterial({ 
      color: 0x00ffff, 
      transparent: true, 
      opacity: 0.6,
      blending: THREE.AdditiveBlending 
    });
    rainMesh = new THREE.InstancedMesh(dropGeo, dropMat, rainCount);
    
    for (let i = 0; i < rainCount; i++) {
      dummy.position.x = (Math.random() - 0.5) * 100;
      dummy.position.y = Math.random() * 100;
      dummy.position.z = (Math.random() - 0.5) * 50;
      dummy.updateMatrix();
      rainMesh.setMatrixAt(i, dummy.matrix);
    }
    rainMesh.instanceMatrix.needsUpdate = true;
    scene.add(rainMesh);
    
    // Store rain data for animation
    rainMesh.userData.positions = new Float32Array(rainCount * 3);
    for (let i = 0; i < rainCount; i++) {
      rainMesh.userData.positions[i*3] = (Math.random() - 0.5) * 100;
      rainMesh.userData.positions[i*3+1] = Math.random() * 100;
      rainMesh.userData.positions[i*3+2] = (Math.random() - 0.5) * 50;
    }

    // Hover Car
    const carGeo = new THREE.BoxGeometry(3, 1, 1.5);
    const carMat = new THREE.MeshBasicMaterial({ color: 0x00ffff });
    hoverCar = new THREE.Mesh(carGeo, carMat);
    hoverCar.position.set(-50, 10, -20);
    scene.add(hoverCar);

    anime({
      targets: hoverCar.position,
      x: [-50, 50],
      duration: 8000,
      easing: 'linear',
      loop: true
    });

    camera.position.set(0, 0, 25);

    // Time update
    window._cyberpunkInterval = setInterval(() => {
      const d = new Date();
      document.getElementById('sys-time').innerText = d.toLocaleTimeString();
    }, 1000);
  },
  
  onRender: (time, delta) => {
    // Animate Rain
    if (rainMesh) {
      const dummy = new THREE.Object3D();
      const pos = rainMesh.userData.positions;
      for (let i = 0; i < pos.length / 3; i++) {
        pos[i*3+1] -= 0.8 * (delta / 16); // fall speed
        if (pos[i*3+1] < -20) {
          pos[i*3+1] = 80 + Math.random() * 20; // reset to top
        }
        
        dummy.position.set(pos[i*3], pos[i*3+1], pos[i*3+2]);
        // slight angle
        dummy.rotation.z = 0.1;
        dummy.updateMatrix();
        rainMesh.setMatrixAt(i, dummy.matrix);
      }
      rainMesh.instanceMatrix.needsUpdate = true;
    }
  },

  onDispose: () => {
    if (window._cyberpunkInterval) clearInterval(window._cyberpunkInterval);
    neonPlanes = [];
    rainMesh = null;
    hoverCar = null;
  }
});
