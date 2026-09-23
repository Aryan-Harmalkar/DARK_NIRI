# 3D HTML Wallpaper Design Specifications

## Goal
Design visual and UX specifications for two 3D HTML wallpapers using Three.js and Anime.js:
1. A cinematic One Piece-inspired pirate world.
2. An original Anime Cyberpunk 3D wallpaper.

*Constraint:* Highly optimized for laptop GPUs (avoiding expensive post-processing, minimizing draw calls, using baked lighting/shadows where possible).

---

## 1. Cinematic One Piece Pirate World

### Concept
A serene yet dynamic view from the deck of a pirate ship (inspired by the Thousand Sunny) looking out at a vast, stylized ocean and distant islands at sunset.

### Visual Specifications
- **Color Palette:** Warm, cinematic sunset tones. Oranges, deep reds, golden yellows, contrasting with teal/navy ocean waters.
- **Models (Low Poly & Optimized):**
  - **Foreground:** Ship's wooden railing and a mast section (silhouetted or warmly lit).
  - **Background:** Distant jagged rock formations/islands.
  - **Sky:** A large, glowing sunset sun (textured plane or basic sphere with emissive material) and stylized low-poly clouds.
- **Ocean:** A large plane with a custom highly-optimized shader material mimicking stylized anime water (using noise textures for waves instead of heavy geometry displacement).

### Three.js Setup & Lighting
- **Renderer:** `WebGLRenderer` with `powerPreference: "high-performance"`, `antialias: false` (to save GPU cycles on laptops).
- **Lighting Model:**
  - **AmbientLight:** Soft warm orange (`0xff8c42`), low intensity (`0.3`).
  - **DirectionalLight:** Acting as the setting sun. Golden yellow (`0xffd700`), high intensity (`1.5`). Casts shadows only on foreground elements (ship deck).
  - **HemisphereLight:** To simulate sky/ocean light scattering. Sky color (`0xfb9062`), ground color (`0x0b3954`), intensity (`0.5`).
- **Optimization:** Use `MeshBasicMaterial` for distant objects with baked vertex colors. Only foreground objects use `MeshStandardMaterial` for dynamic lighting. Disable shadow maps for the ocean and background islands.

### Anime.js Choreography & Animation
- **Camera Parallax:** Subtle camera sway linked to mouse movement (mouse X/Y mapped to slight rotation and position shifts) to give a sense of depth.
- **Ocean Waves:** Animate the UV offset of the ocean noise texture in the render loop, but use Anime.js to smoothly transition wave speeds based on idle time.
- **Clouds:** Slow, infinite horizontal translation of cloud planes using Anime.js (`loop: true`, `easing: 'linear'`).
- **Ship Sway:** A gentle, continuous rocking motion applied to the camera or ship geometry using a sine wave or Anime.js with a long duration (`duration: 4000`, `direction: 'alternate'`, `easing: 'easeInOutSine'`).

---

## 2. Anime Cyberpunk City Scene

### Concept
A rainy, neon-drenched alleyway or rooftop view in a sprawling cyberpunk metropolis, deeply inspired by 90s anime aesthetics (Akira, Ghost in the Shell).

### Visual Specifications
- **Color Palette:** Deep blacks, dark purples, cyan, and magenta neon highlights.
- **Models (Low Poly & Optimized):**
  - **Foreground:** A wet rooftop ledge with a glowing neon sign (hologram or traditional tube).
  - **Midground:** Silhouettes of blocky skyscrapers with lit window textures.
  - **Background:** Infinite city grid (using a fog effect to hide the draw distance).
- **Effects:** High-speed rain (simple particle system using points or stretched line segments), glowing neon.

### Three.js Setup & Lighting
- **Renderer:** `WebGLRenderer` with `powerPreference: "high-performance"`.
- **Lighting Model:**
  - **AmbientLight:** Very low intensity dark blue (`0x0a0a2a`).
  - **PointLights (Neon):** Strategically placed cyan (`0x00ffff`) and magenta (`0xff00ff`) point lights near signs. *Optimization:* Keep point light count strictly under 4 to avoid multipass render overhead. Use `distance` and `decay` aggressively.
  - **Fog:** `THREE.FogExp2` using a dark purple/black color to blend distant buildings and reduce visible geometry.
- **Optimization:**
  - Instead of expensive bloom post-processing (`EffectComposer`), use **"fake bloom"** by placing slightly larger, additive-blended, transparent planes with blurred glow textures behind neon objects.
  - Use `InstancedMesh` for the rain particles and distant building blocks to reduce draw calls to 1.
  - Reflections on the wet ground achieved via a simple planar reflection or a fake environment map rather than real-time SSR (Screen Space Reflections).

### Anime.js Choreography & Animation
- **Neon Flicker:** Use Anime.js to animate the `opacity` of the fake bloom planes and `intensity` of the PointLights. `keyframes: [{opacity: 1}, {opacity: 0.5}, {opacity: 1}, {opacity: 0.1}, {opacity: 1}]`, `duration: 1500`, `loop: true`, with random delays.
- **Rain System:** Animate the Y-position of the rain InstancedMesh downwards in the render loop, resetting when below the ground.
- **Hover Car (Background):** A low-poly vehicle flying across the background. Anime.js handles the translation across the X-axis: `translateX: [-50, 50]`, `duration: 8000`, `easing: 'linear'`, `loop: true`.
- **Camera Parallax:** Smooth, slight tracking based on mouse movement (focusing heavily on foreground vs background parallax for that dense city feel).
