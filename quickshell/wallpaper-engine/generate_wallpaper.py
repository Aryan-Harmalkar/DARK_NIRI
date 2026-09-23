import os, base64, io, json
from PIL import Image

img_dir = '/home/aryan/Downloads/straw_hats'
members = ['luffy', 'zoro', 'nami', 'usopp', 'sanji', 'chopper', 'robin', 'franky', 'brook', 'jinbe']

b64_data = {}
for m in members:
    p = os.path.join(img_dir, f'{m}.png')
    im = Image.open(p)
    buf = io.BytesIO()
    im.save(buf, format='WEBP', lossless=True)
    b64 = base64.b64encode(buf.getvalue()).decode('ascii')
    b64_data[m] = f'data:image/webp;base64,{b64}'

crew_meta = [
  {
    'name': 'Luffy',
    'fullName': 'Monkey D. Luffy',
    'epithet': 'Straw Hat',
    'roleTag': 'CAPTAIN',
    'tagColor': '#b91c1c',
    'watermark': 'STRAW HAT',
    'bounty': '3,000,000,000',
    'height': '174cm',
    'birthday': '5/5',
    'bio': 'Captain of the Straw Hat Pirates and Emperor of the Sea, striving to find the One Piece and become the King of the Pirates.'
  },
  {
    'name': 'Zoro',
    'fullName': 'Roronoa Zoro',
    'epithet': 'Pirate Hunter',
    'roleTag': 'SWORDSMAN',
    'tagColor': '#15803d',
    'watermark': 'PIRATE HUNTER',
    'bounty': '1,111,000,000',
    'height': '181cm',
    'birthday': '11/11',
    'bio': 'Master of the Three-Sword Style (Santoryu) who vowed to never lose another duel and become the World\'s Greatest Swordsman.'
  },
  {
    'name': 'Nami',
    'fullName': 'Nami',
    'epithet': 'Cat Burglar',
    'roleTag': 'NAVIGATOR',
    'tagColor': '#ea580c',
    'watermark': 'CAT BURGLAR',
    'bounty': '366,000,000',
    'height': '170cm',
    'birthday': '7/3',
    'bio': 'The crew\'s peerless navigator wielding the weather-controlling Clima-Tact, dreaming of charting a map of the entire world.'
  },
  {
    'name': 'Usopp',
    'fullName': 'Usopp',
    'epithet': 'God Usopp',
    'roleTag': 'SNIPER',
    'tagColor': '#ca8a04',
    'watermark': 'GOD USOPP',
    'bounty': '500,000,000',
    'height': '176cm',
    'birthday': '4/1',
    'bio': 'Sharpshooter of the Straw Hats and ingenious inventor, dreaming of becoming a fearless warrior of the sea.'
  },
  {
    'name': 'Sanji',
    'fullName': 'Sanji',
    'epithet': 'Black Leg',
    'roleTag': 'COOK',
    'tagColor': '#2563eb',
    'watermark': 'BLACK LEG',
    'bounty': '1,032,000,000',
    'height': '180cm',
    'birthday': '3/2',
    'bio': 'Culinary master of the Baratie fighting only with his fiery kicks, searching the seas for the legendary All Blue.'
  },
  {
    'name': 'Chopper',
    'fullName': 'Tony Tony Chopper',
    'epithet': 'Cotton Candy Lover',
    'roleTag': 'DOCTOR',
    'tagColor': '#db2777',
    'watermark': 'COTTON CANDY',
    'bounty': '1,000',
    'height': '90cm',
    'birthday': '12/24',
    'bio': 'Blue-nosed reindeer doctor who ate the Human-Human Fruit, dedicated to creating a panacea capable of curing any illness.'
  },
  {
    'name': 'Robin',
    'fullName': 'Nico Robin',
    'epithet': 'Devil Child',
    'roleTag': 'ARCHAEOLOGIST',
    'tagColor': '#7e22ce',
    'watermark': 'DEVIL CHILD',
    'bounty': '930,000,000',
    'height': '188cm',
    'birthday': '2/6',
    'bio': 'Sole surviving archaeologist of Ohara capable of deciphering ancient Poneglyphs to unveil the truth of the Void Century.'
  },
  {
    'name': 'Franky',
    'fullName': 'Franky',
    'epithet': 'Iron Man',
    'roleTag': 'SHIPWRIGHT',
    'tagColor': '#0891b2',
    'watermark': 'IRON MAN',
    'bounty': '394,000,000',
    'height': '240cm',
    'birthday': '3/9',
    'bio': 'Cola-powered cyborg shipwright of Water 7 who built the Thousand Sunny, ensuring his dream ship traverses all oceans.'
  },
  {
    'name': 'Brook',
    'fullName': 'Brook',
    'epithet': 'Soul King',
    'roleTag': 'MUSICIAN',
    'tagColor': '#475569',
    'watermark': 'SOUL KING',
    'bounty': '383,000,000',
    'height': '277cm',
    'birthday': '4/3',
    'bio': 'Humorous skeleton musician and fencer granted a second life through the Revive-Revive Fruit, journeying to reunite with Laboon.'
  },
  {
    'name': 'Jinbe',
    'fullName': 'Jinbe',
    'epithet': 'Knight of the Sea',
    'roleTag': 'HELMSMAN',
    'tagColor': '#0284c7',
    'watermark': 'KNIGHT OF SEA',
    'bounty': '1,100,000,000',
    'height': '301cm',
    'birthday': '4/2',
    'bio': 'Former Warlord of the Sea and grandmaster of Fish-Man Karate, serving as the crew\'s calm and dependable helmsman.'
  }
]

for cm in crew_meta:
    cm['image'] = b64_data[cm['name'].lower()]

crew_json = json.dumps(crew_meta)
luffy = crew_meta[0]

html = f'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>One Piece: Straw Hat Pirates</title>
  <style>
    *, *::before, *::after {{
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }}

    :root {{
      --bg-base: #f6f3ee;
      --bg-card: rgba(255, 255, 255, 0.88);
      --bg-card-border: rgba(210, 185, 175, 0.55);
      --text-main: #272123;
      --text-muted: #5e5356;
      --text-sub: #948589;
      --accent-maroon: #722f37;
      --accent-gold: #c98b2c;
      --accent-rose: #d4838f;
      --accent-rose-light: #fbeff1;
      --dot-color: rgba(145, 120, 115, 0.22);
      --shadow-card: 0 24px 50px rgba(80, 40, 45, 0.12), 0 4px 14px rgba(0, 0, 0, 0.04);
      --shadow-pill: 0 4px 14px rgba(114, 47, 55, 0.2);
      --transition-smooth: cubic-bezier(0.22, 1, 0.36, 1);
    }}

    body, html {{
      width: 100vw;
      height: 100vh;
      overflow: hidden;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", "Noto Sans", sans-serif;
      background-color: var(--bg-base);
      color: var(--text-main);
      position: relative;
    }}

    .bg-grid {{
      position: absolute;
      inset: 0;
      background-image: radial-gradient(circle, var(--dot-color) 1.5px, transparent 1.5px);
      background-size: 30px 30px;
      z-index: 0;
      pointer-events: none;
    }}

    .bg-ambient-blob {{
      position: absolute;
      border-radius: 50%;
      filter: blur(100px);
      pointer-events: none;
      z-index: 0;
      opacity: 0.55;
    }}
    .blob-1 {{
      top: -120px;
      left: 15%;
      width: 550px;
      height: 550px;
      background: radial-gradient(circle, rgba(235, 175, 150, 0.25) 0%, transparent 70%);
    }}
    .blob-2 {{
      bottom: -150px;
      right: 20%;
      width: 700px;
      height: 700px;
      background: radial-gradient(circle, rgba(212, 131, 143, 0.22) 0%, transparent 70%);
    }}
    .blob-3 {{
      top: 35%;
      right: 5%;
      width: 450px;
      height: 450px;
      background: radial-gradient(circle, rgba(114, 47, 55, 0.1) 0%, transparent 70%);
    }}

    .shape {{
      position: absolute;
      pointer-events: none;
      z-index: 1;
      opacity: 0.45;
    }}
    .shape-diamond {{
      width: 14px;
      height: 14px;
      border: 2px solid var(--accent-rose);
      transform: rotate(45deg);
      animation: floatShape1 7s ease-in-out infinite alternate;
    }}
    .shape-square-solid {{
      width: 10px;
      height: 10px;
      background: var(--accent-maroon);
      transform: rotate(25deg);
      border-radius: 2px;
      animation: floatShape2 8.5s ease-in-out infinite alternate;
    }}
    .shape-cross {{
      width: 16px;
      height: 16px;
      position: absolute;
      animation: floatShape1 9s ease-in-out infinite alternate;
    }}
    .shape-cross::before, .shape-cross::after {{
      content: "";
      position: absolute;
      background: var(--accent-rose);
      border-radius: 1px;
    }}
    .shape-cross::before {{ top: 7px; left: 0; width: 16px; height: 2px; }}
    .shape-cross::after {{ top: 0; left: 7px; width: 2px; height: 16px; }}

    @keyframes floatShape1 {{
      0% {{ transform: translateY(0) rotate(45deg); }}
      100% {{ transform: translateY(-16px) rotate(65deg); }}
    }}
    @keyframes floatShape2 {{
      0% {{ transform: translateY(0) rotate(25deg); }}
      100% {{ transform: translateY(14px) rotate(10deg); }}
    }}

    .watermark-container {{
      position: absolute;
      right: 4%;
      top: 48%;
      transform: translateY(-50%) rotate(-12deg);
      z-index: 1;
      pointer-events: none;
      display: flex;
      flex-direction: column;
      align-items: flex-end;
    }}
    .watermark-text {{
      font-family: Impact, "Arial Black", "Franklin Gothic Medium", sans-serif;
      font-size: clamp(90px, 13vw, 180px);
      line-height: 0.85;
      font-weight: 900;
      color: rgba(114, 47, 55, 0.06);
      letter-spacing: 6px;
      text-transform: uppercase;
      transition: opacity 0.45s var(--transition-smooth), transform 0.5s var(--transition-smooth);
      white-space: nowrap;
    }}
    .watermark-sub {{
      font-family: Impact, "Arial Black", sans-serif;
      font-size: clamp(40px, 6vw, 80px);
      line-height: 0.9;
      font-weight: 900;
      color: rgba(114, 47, 55, 0.04);
      letter-spacing: 4px;
      text-transform: uppercase;
      transition: opacity 0.45s var(--transition-smooth);
    }}

    .top-widgets {{
      position: absolute;
      top: 36px;
      right: 48px;
      display: flex;
      align-items: center;
      gap: 16px;
      z-index: 200;
    }}

    .widget-badge {{
      background: var(--bg-card);
      backdrop-filter: blur(14px);
      -webkit-backdrop-filter: blur(14px);
      border: 1px solid var(--bg-card-border);
      box-shadow: 0 8px 24px rgba(100, 45, 60, 0.08);
      border-radius: 999px;
      display: flex;
      align-items: center;
      padding: 8px 18px;
      gap: 12px;
    }}

    .clock-badge {{
      padding: 8px 18px 8px 12px;
      gap: 12px;
    }}
    .analog-clock {{
      width: 38px;
      height: 38px;
      border-radius: 50%;
      border: 2px solid var(--accent-maroon);
      position: relative;
      background: #ffffff;
      box-shadow: inset 0 2px 5px rgba(0,0,0,0.05);
    }}
    .clock-center-dot {{
      position: absolute;
      width: 4px;
      height: 4px;
      background: var(--accent-maroon);
      border-radius: 50%;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      z-index: 5;
    }}
    .hand {{
      position: absolute;
      bottom: 50%;
      left: 50%;
      transform-origin: bottom center;
      border-radius: 2px;
    }}
    .hand-hour {{
      width: 2.5px;
      height: 10px;
      background: var(--text-main);
      margin-left: -1.25px;
    }}
    .hand-minute {{
      width: 1.5px;
      height: 14px;
      background: var(--text-muted);
      margin-left: -0.75px;
    }}
    .hand-second {{
      width: 1px;
      height: 16px;
      background: var(--accent-maroon);
      margin-left: -0.5px;
    }}
    .clock-digital {{
      display: flex;
      flex-direction: column;
      justify-content: center;
    }}
    .digital-time {{
      font-size: 15px;
      font-weight: 700;
      color: var(--text-main);
      letter-spacing: 0.5px;
      line-height: 1.1;
    }}
    .digital-date {{
      font-size: 10px;
      font-weight: 600;
      color: var(--text-sub);
      text-transform: uppercase;
      letter-spacing: 0.8px;
    }}

    .weather-badge {{
      height: 54px;
    }}
    .weather-icon-svg {{
      width: 28px;
      height: 28px;
      color: var(--accent-gold);
    }}
    .weather-info {{
      display: flex;
      flex-direction: column;
    }}
    .weather-temp {{
      font-size: 15px;
      font-weight: 700;
      color: var(--text-main);
      line-height: 1.1;
    }}
    .weather-desc {{
      font-size: 10px;
      font-weight: 600;
      color: var(--text-sub);
      letter-spacing: 0.5px;
      text-transform: uppercase;
    }}

    .left-panel-container {{
      position: absolute;
      left: 64px;
      top: 50%;
      transform: translateY(-50%);
      width: 450px;
      max-width: calc(100vw - 128px);
      z-index: 1000;
      pointer-events: auto !important;
    }}

    .info-card {{
      background: var(--bg-card);
      backdrop-filter: blur(20px);
      -webkit-backdrop-filter: blur(20px);
      border: 1px solid var(--bg-card-border);
      border-radius: 32px;
      padding: 34px 32px;
      box-shadow: var(--shadow-card);
      display: flex;
      flex-direction: column;
      gap: 18px;
      position: relative;
      z-index: 1001;
      pointer-events: auto !important;
    }}

    .card-nav-row {{
      display: flex;
      align-items: center;
      justify-content: space-between;
    }}
    .char-counter {{
      font-size: 12px;
      font-weight: 800;
      color: var(--accent-maroon);
      letter-spacing: 2px;
      background: var(--accent-rose-light);
      padding: 4px 12px;
      border-radius: 999px;
      border: 1px solid rgba(212, 131, 143, 0.35);
    }}
    .pill-btn-group {{
      display: flex;
      gap: 8px;
      position: relative;
      z-index: 1002;
    }}
    .pill-btn {{
      appearance: none;
      border: none;
      background: #ffffff;
      color: var(--accent-maroon);
      border: 1px solid rgba(114, 47, 55, 0.25);
      border-radius: 999px;
      padding: 8px 18px;
      font-size: 11px;
      font-weight: 800;
      letter-spacing: 1px;
      cursor: pointer !important;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      transition: all 0.2s ease;
      box-shadow: 0 2px 6px rgba(0,0,0,0.04);
      pointer-events: auto !important;
      position: relative;
      z-index: 1003;
    }}
    .pill-btn:hover {{
      background: var(--accent-maroon);
      color: #ffffff;
      border-color: var(--accent-maroon);
      box-shadow: var(--shadow-pill);
      transform: translateY(-2px);
    }}
    .pill-btn:active {{
      transform: translateY(1px);
    }}

    .name-block {{
      display: flex;
      flex-direction: column;
      gap: 2px;
    }}
    .char-name {{
      font-family: Impact, "Arial Black", "Trebuchet MS", sans-serif;
      font-size: 42px;
      font-weight: 900;
      color: var(--text-main);
      text-transform: uppercase;
      letter-spacing: 1.5px;
      line-height: 1;
      transition: opacity 0.35s var(--transition-smooth), transform 0.35s var(--transition-smooth);
    }}
    .char-epithet {{
      font-size: 16px;
      font-weight: 800;
      color: var(--accent-maroon);
      letter-spacing: 1.5px;
      text-transform: uppercase;
      line-height: 1.2;
      transition: opacity 0.35s var(--transition-smooth), transform 0.35s var(--transition-smooth);
    }}

    .char-tag-wrap {{
      display: flex;
      margin-top: -4px;
    }}
    .char-tag {{
      display: inline-block;
      font-size: 10px;
      font-weight: 800;
      letter-spacing: 1.5px;
      text-transform: uppercase;
      padding: 5px 14px;
      border-radius: 999px;
      color: #ffffff;
      background: var(--accent-maroon);
      box-shadow: 0 4px 10px rgba(114, 47, 55, 0.2);
      transition: background-color 0.3s ease, transform 0.3s ease;
    }}

    .card-divider {{
      height: 1px;
      background: linear-gradient(90deg, var(--bg-card-border), transparent);
      width: 100%;
    }}

    .stats-container {{
      display: flex;
      flex-direction: column;
      gap: 8px;
    }}
    .stat-row {{
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 10px 14px;
      background: rgba(255, 255, 255, 0.75);
      border-radius: 12px;
      border: 1px solid rgba(214, 182, 190, 0.35);
      transition: opacity 0.3s var(--transition-smooth);
    }}
    .stat-label {{
      font-size: 11px;
      font-weight: 700;
      color: var(--text-sub);
      text-transform: uppercase;
      letter-spacing: 1px;
    }}
    .stat-value {{
      font-size: 13px;
      font-weight: 800;
      color: var(--text-main);
      letter-spacing: 0.5px;
    }}
    .stat-value.bounty-highlight {{
      color: var(--accent-maroon);
      font-family: Impact, "Arial Black", sans-serif;
      font-size: 16px;
      letter-spacing: 1px;
    }}

    .bio-text {{
      font-size: 13px;
      line-height: 1.6;
      color: var(--text-muted);
      min-height: 52px;
      transition: opacity 0.35s var(--transition-smooth), transform 0.35s var(--transition-smooth);
    }}

    .change-control-box {{
      margin-top: 4px;
      padding-top: 14px;
      border-top: 1px dashed var(--bg-card-border);
      display: flex;
      flex-direction: column;
      gap: 12px;
      position: relative;
      z-index: 1002;
    }}
    .change-header {{
      display: flex;
      align-items: center;
      justify-content: space-between;
    }}
    .change-label {{
      font-size: 10px;
      font-weight: 800;
      color: var(--accent-maroon);
      letter-spacing: 1.5px;
      text-transform: uppercase;
    }}
    .countdown-text {{
      font-size: 11px;
      font-weight: 700;
      color: var(--accent-rose);
      background: var(--accent-rose-light);
      padding: 4px 12px;
      border-radius: 999px;
      letter-spacing: 0.5px;
    }}
    .controls-row {{
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
    }}
    .timer-toggle-btn {{
      appearance: none;
      border: 1px solid var(--accent-maroon);
      background: var(--accent-maroon);
      color: #ffffff;
      padding: 8px 18px;
      border-radius: 999px;
      font-size: 10px;
      font-weight: 800;
      letter-spacing: 1px;
      cursor: pointer !important;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      transition: all 0.2s ease;
      white-space: nowrap;
      pointer-events: auto !important;
      position: relative;
      z-index: 1003;
    }}
    .timer-toggle-btn.paused {{
      background: #ffffff;
      color: var(--accent-maroon);
      border-color: rgba(114, 47, 55, 0.4);
    }}
    .timer-toggle-btn:hover {{
      box-shadow: var(--shadow-pill);
      transform: translateY(-1px);
    }}
    .interval-input-group {{
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 11px;
      font-weight: 600;
      color: var(--text-muted);
    }}
    .interval-input {{
      width: 48px;
      padding: 4px 6px;
      border-radius: 8px;
      border: 1px solid var(--bg-card-border);
      background: #ffffff;
      color: var(--text-main);
      font-weight: 700;
      font-size: 12px;
      text-align: center;
      outline: none;
      transition: border-color 0.2s;
      user-select: auto !important;
      -webkit-user-select: auto !important;
      pointer-events: auto !important;
    }}
    .interval-input:focus {{
      border-color: var(--accent-maroon);
    }}

    .fade-out {{
      opacity: 0 !important;
      transform: translateY(6px);
    }}

    .right-stage {{
      position: absolute;
      right: 0;
      bottom: 0;
      top: 0;
      width: 65vw;
      pointer-events: none;
      display: flex;
      justify-content: center;
      align-items: flex-end;
      z-index: 5;
    }}

    .main-char-wrapper {{
      position: absolute;
      bottom: 0;
      right: 12%;
      height: 90vh;
      max-height: 960px;
      display: flex;
      align-items: flex-end;
      justify-content: center;
      transition: opacity 0.55s var(--transition-smooth), transform 0.55s var(--transition-smooth);
      pointer-events: none;
    }}
    .main-char-wrapper.char-swap-out {{
      opacity: 0;
      transform: translateY(22px) scale(0.97);
    }}

    .main-char-img {{
      height: 100%;
      width: auto;
      max-width: 800px;
      object-fit: contain;
      filter: drop-shadow(0 20px 35px rgba(80, 40, 45, 0.18));
      animation: gentleBreathe 5s ease-in-out infinite alternate;
      transform-origin: bottom center;
      pointer-events: none;
    }}

    @keyframes gentleBreathe {{
      0% {{ transform: translateY(0px); }}
      100% {{ transform: translateY(-10px); }}
    }}

    @media (max-width: 1200px) {{
      .left-panel-container {{ left: 32px; width: 390px; }}
      .main-char-wrapper {{ right: 6%; height: 82vh; }}
      .watermark-text {{ font-size: 110px; }}
      .top-widgets {{ right: 24px; top: 24px; }}
    }}
    @media (max-width: 900px) {{
      .left-panel-container {{ position: relative; left: auto; top: auto; transform: none; margin: 24px auto; width: 92%; }}
      .main-char-wrapper {{ opacity: 0.35; right: 0; }}
      .right-stage {{ width: 100vw; }}
    }}
  </style>
</head>
<body>

  <div class="bg-grid"></div>
  <div class="bg-ambient-blob blob-1"></div>
  <div class="bg-ambient-blob blob-2"></div>
  <div class="bg-ambient-blob blob-3"></div>

  <div class="shape shape-diamond" style="top: 15%; left: 38%;"></div>
  <div class="shape shape-square-solid" style="top: 24%; left: 46%;"></div>
  <div class="shape shape-cross" style="top: 70%; left: 35%;"></div>
  <div class="shape shape-diamond" style="bottom: 18%; right: 46%; border-color: var(--accent-maroon);"></div>
  <div class="shape shape-square-solid" style="top: 16%; right: 28%; background: var(--accent-rose);"></div>
  <div class="shape shape-cross" style="bottom: 30%; right: 12%;"></div>

  <div class="watermark-container">
    <div id="watermarkText" class="watermark-text">{luffy['watermark']}</div>
    <div id="watermarkSub" class="watermark-sub">{luffy['fullName'].upper()}</div>
  </div>

  <div class="top-widgets">
    <div class="widget-badge clock-badge">
      <div class="analog-clock">
        <div class="clock-center-dot"></div>
        <div id="handHour" class="hand hand-hour"></div>
        <div id="handMinute" class="hand hand-minute"></div>
        <div id="handSecond" class="hand hand-second"></div>
      </div>
      <div class="clock-digital">
        <span id="digitalTime" class="digital-time">12:00:00</span>
        <span id="digitalDate" class="digital-date">FRI, SEP 18</span>
      </div>
    </div>

    <div class="widget-badge weather-badge">
      <svg class="weather-icon-svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <circle cx="12" cy="12" r="4"></circle>
        <path d="M12 2v2"></path>
        <path d="M12 20v2"></path>
        <path d="m4.93 4.93 1.41 1.41"></path>
        <path d="m17.66 17.66 1.41 1.41"></path>
        <path d="M2 12h2"></path>
        <path d="M20 12h2"></path>
        <path d="m6.34 17.66-1.41 1.41"></path>
        <path d="m19.07 4.93-1.41 1.41"></path>
      </svg>
      <div class="weather-info">
        <span class="weather-temp">28°C</span>
        <span class="weather-desc">GRAND LINE SUNNY</span>
      </div>
    </div>
  </div>

  <div class="left-panel-container">
    <div class="info-card">

      <div class="card-nav-row">
        <span id="charCounter" class="char-counter">01 / 10</span>
        <div class="pill-btn-group">
          <button id="prevBtn" class="pill-btn" onclick="prevMember()" title="Previous Member">◀ PREV</button>
          <button id="nextBtn" class="pill-btn" onclick="nextMember()" title="Next Member">NEXT ▶</button>
        </div>
      </div>

      <div class="name-block">
        <div id="charName" class="char-name">{luffy['name'].upper()}</div>
        <div id="charEpithet" class="char-epithet">{luffy['epithet'].upper()}</div>
      </div>

      <div class="char-tag-wrap">
        <span id="charTag" class="char-tag" style="background-color: {luffy['tagColor']};">{luffy['roleTag']}</span>
      </div>

      <div class="card-divider"></div>

      <div id="statsContainer" class="stats-container">
        <div class="stat-row">
          <span class="stat-label">BOUNTY</span>
          <span class="stat-value bounty-highlight">฿ {luffy['bounty']}</span>
        </div>
        <div class="stat-row">
          <span class="stat-label">HEIGHT</span>
          <span class="stat-value">{luffy['height']}</span>
        </div>
        <div class="stat-row">
          <span class="stat-label">BIRTHDAY</span>
          <span class="stat-value">{luffy['birthday']}</span>
        </div>
      </div>

      <p id="charBio" class="bio-text">{luffy['bio']}</p>

      <div class="change-control-box">
        <div class="change-header">
          <span class="change-label">AUTOPLAY CONTROLS</span>
          <span id="countdownDisplay" class="countdown-text">Next member in 10s</span>
        </div>
        <div class="controls-row">
          <button id="pauseToggleBtn" class="timer-toggle-btn" onclick="togglePause()">
            <span id="pauseBtnIcon">⏸</span>
            <span id="pauseBtnText">PAUSE TIMER</span>
          </button>
          <div class="interval-input-group">
            <span>Every</span>
            <input id="secondsInput" type="number" class="interval-input" min="3" max="120" value="10" onchange="onIntervalChange()" oninput="onIntervalChange()">
            <span>seconds</span>
          </div>
        </div>
      </div>

    </div>
  </div>

  <div class="right-stage">
    <div id="mainCharWrapper" class="main-char-wrapper">
      <img id="mainCharImg" class="main-char-img" src="{luffy['image']}" alt="{luffy['fullName']}">
    </div>
  </div>

  <script>
    const CREW_MEMBERS = {crew_json};

    let currentIndex = 0;
    let intervalSeconds = 10;
    let countdownRemaining = 10;
    let isPaused = false;
    let timerInterval = null;

    const charCounterEl = document.getElementById("charCounter");
    const charNameEl = document.getElementById("charName");
    const charEpithetEl = document.getElementById("charEpithet");
    const charTagEl = document.getElementById("charTag");
    const statsContainerEl = document.getElementById("statsContainer");
    const charBioEl = document.getElementById("charBio");
    const pauseToggleBtn = document.getElementById("pauseToggleBtn");
    const pauseBtnIcon = document.getElementById("pauseBtnIcon");
    const pauseBtnText = document.getElementById("pauseBtnText");
    const secondsInput = document.getElementById("secondsInput");
    const countdownDisplay = document.getElementById("countdownDisplay");
    const watermarkTextEl = document.getElementById("watermarkText");
    const watermarkSubEl = document.getElementById("watermarkSub");
    const mainCharWrapperEl = document.getElementById("mainCharWrapper");
    const mainCharImgEl = document.getElementById("mainCharImg");

    const handHour = document.getElementById("handHour");
    const handMinute = document.getElementById("handMinute");
    const handSecond = document.getElementById("handSecond");
    const digitalTimeEl = document.getElementById("digitalTime");
    const digitalDateEl = document.getElementById("digitalDate");

    function updateCrewMember(index) {{
      currentIndex = (index + CREW_MEMBERS.length) % CREW_MEMBERS.length;
      const member = CREW_MEMBERS[currentIndex];

      const textElements = [charNameEl, charEpithetEl, statsContainerEl, charBioEl, watermarkTextEl, watermarkSubEl];
      textElements.forEach(el => el.classList.add("fade-out"));
      mainCharWrapperEl.classList.add("char-swap-out");

      setTimeout(() => {{
        charCounterEl.textContent = String(currentIndex + 1).padStart(2, '0') + ' / ' + String(CREW_MEMBERS.length).padStart(2, '0');
        charNameEl.textContent = member.name.toUpperCase();
        charEpithetEl.textContent = member.epithet.toUpperCase();
        charTagEl.textContent = member.roleTag;
        charTagEl.style.backgroundColor = member.tagColor;

        statsContainerEl.innerHTML = `
          <div class="stat-row">
            <span class="stat-label">BOUNTY</span>
            <span class="stat-value bounty-highlight">฿ ` + member.bounty + `</span>
          </div>
          <div class="stat-row">
            <span class="stat-label">HEIGHT</span>
            <span class="stat-value">` + member.height + `</span>
          </div>
          <div class="stat-row">
            <span class="stat-label">BIRTHDAY</span>
            <span class="stat-value">` + member.birthday + `</span>
          </div>
        `;

        charBioEl.textContent = member.bio;
        watermarkTextEl.textContent = member.watermark;
        watermarkSubEl.textContent = member.fullName.toUpperCase();
        mainCharImgEl.src = member.image;

        textElements.forEach(el => el.classList.remove("fade-out"));
        mainCharWrapperEl.classList.remove("char-swap-out");
      }}, 260);

      countdownRemaining = intervalSeconds;
      updateCountdownDisplay();
    }}

    function nextMember() {{
      updateCrewMember(currentIndex + 1);
    }}

    function prevMember() {{
      updateCrewMember(currentIndex - 1);
    }}

    function updateCountdownDisplay() {{
      if (isPaused) {{
        countdownDisplay.textContent = "PAUSED";
        countdownDisplay.style.backgroundColor = "rgba(156, 138, 143, 0.15)";
        countdownDisplay.style.color = "var(--text-sub)";
      }} else {{
        countdownDisplay.textContent = 'Next member in ' + countdownRemaining + 's';
        countdownDisplay.style.backgroundColor = "var(--accent-rose-light)";
        countdownDisplay.style.color = "var(--accent-rose)";
      }}
    }}

    function timerTick() {{
      if (isPaused) return;
      countdownRemaining--;
      if (countdownRemaining <= 0) {{
        nextMember();
      }} else {{
        updateCountdownDisplay();
      }}
    }}

    function togglePause() {{
      isPaused = !isPaused;
      if (isPaused) {{
        pauseToggleBtn.classList.add("paused");
        pauseBtnIcon.textContent = "▶";
        pauseBtnText.textContent = "RESUME TIMER";
      }} else {{
        pauseToggleBtn.classList.remove("paused");
        pauseBtnIcon.textContent = "⏸";
        pauseBtnText.textContent = "PAUSE TIMER";
        countdownRemaining = intervalSeconds;
      }}
      updateCountdownDisplay();
    }}

    function onIntervalChange() {{
      const val = parseInt(secondsInput.value, 10);
      if (!isNaN(val) && val >= 3 && val <= 300) {{
        intervalSeconds = val;
        countdownRemaining = intervalSeconds;
        updateCountdownDisplay();
      }}
    }}

    window.nextMember = nextMember;
    window.prevMember = prevMember;
    window.togglePause = togglePause;
    window.onIntervalChange = onIntervalChange;

    const DAYS = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    const MONTHS = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

    function updateClock() {{
      const now = new Date();
      const sec = now.getSeconds();
      const min = now.getMinutes();
      const hour = now.getHours();

      const secDeg = (sec / 60) * 360;
      const minDeg = (min / 60) * 360 + (sec / 60) * 6;
      const hourDeg = ((hour % 12) / 12) * 360 + (min / 60) * 30;

      handSecond.style.transform = 'rotate(' + secDeg + 'deg)';
      handMinute.style.transform = 'rotate(' + minDeg + 'deg)';
      handHour.style.transform = 'rotate(' + hourDeg + 'deg)';

      const hStr = String(hour).padStart(2, '0');
      const mStr = String(min).padStart(2, '0');
      const sStr = String(sec).padStart(2, '0');
      digitalTimeEl.textContent = hStr + ':' + mStr + ':' + sStr;

      const dayName = DAYS[now.getDay()];
      const monthName = MONTHS[now.getMonth()];
      const dayNum = String(now.getDate()).padStart(2, '0');
      digitalDateEl.textContent = dayName + ', ' + monthName + ' ' + dayNum;
    }}

    window.addEventListener("keydown", (e) => {{
      if (e.target.tagName === 'INPUT') return;
      if (e.key === "ArrowLeft") prevMember();
      else if (e.key === "ArrowRight") nextMember();
      else if (e.key === " ") {{
        e.preventDefault();
        togglePause();
      }}
    }});

    updateClock();
    setInterval(updateClock, 1000);
    timerInterval = setInterval(timerTick, 1000);
  </script>
</body>
</html>
'''

targets = [
    '/home/aryan/DARK_NIRI/quickshell/wallpaper-engine/themes/one-piece-crew/index.html',
    '/home/aryan/Downloads/one_piece_wallpaper.html',
    '/home/aryan/DARK_NIRI/quickshell/wallpaper-engine/themes/anime-showcase/index.html'
]

for t in targets:
    with open(t, 'w', encoding='utf-8') as f:
        f.write(html)
    print(f'Successfully wrote {len(html)} bytes to {t}')
print('ALL TARGETS COMPLETED!')
