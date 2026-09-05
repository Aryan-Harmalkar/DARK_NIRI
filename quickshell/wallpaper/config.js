// Interactive Wallpaper System — Configuration
// Tune effect parameters here without modifying QML files

// Crossfade transition
var crossfadeDuration = 800       // ms for wallpaper crossfade
var crossfadeEasing = 3           // Easing.InOutQuad

// Time-of-day overlay
var timeOverlayEnabled = true
var timeUpdateInterval = 60000    // ms (1 minute)
var timeTransitionDuration = 5000 // ms for color shift

// Ambient particles
var particlesEnabled = true
var particleCount = 12
var particleMinSize = 3
var particleMaxSize = 8
var particleMinDuration = 15000   // ms min drift cycle
var particleMaxDuration = 45000   // ms max drift cycle
var particleMinOpacity = 0.06
var particleMaxOpacity = 0.14

// Parallax depth
var parallaxEnabled = true
var parallaxMaxShift = 8          // px max displacement
var parallaxSmoothing = 300       // ms easing duration
var parallaxIdleTimeout = 3000    // ms before settling to center

// Media pulse glow
var mediaPulseEnabled = true
var mediaPulseDuration = 3000     // ms per pulse cycle
var mediaPulseMaxOpacity = 0.12
var mediaCheckInterval = 3000     // ms

// Weather overlay (optional — requires API key)
var weatherEnabled = false
var weatherUpdateInterval = 900000 // ms (15 minutes)
var rainParticleCount = 40
var snowParticleCount = 20

// Tokyo Night palette (reference for effects)
var colorBackground = "#1a1b26"
var colorAccent = "#7aa2f7"
var colorAccentPurple = "#bb9af7"
var colorAccentCyan = "#7dcfff"
var colorAccentGreen = "#9ece6a"
var colorAccentOrange = "#ff9e64"
var colorAccentYellow = "#e0af68"
var colorAccentRed = "#f7768e"
var colorText = "#c0caf5"
var colorSubtle = "#565f89"
