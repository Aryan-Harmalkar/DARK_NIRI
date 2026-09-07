# 🎨 How to Customize Your Desktop

Here are simple instructions for the most common customizations.

---

## 1. How to Add Your Own Wallpapers

1. Place your wallpaper images (`.png`, `.jpg`, `.webp`) or video wallpapers (`.mp4`, `.webm`) into:
   ```text
   ~/Pictures/Wallpapers/
   ```
2. Click the **Gear icon** on the top bar -> Open **Wallpaper Gallery**.
3. Your new wallpapers will appear in the gallery automatically with preview thumbnails! Click any image to apply.

---

## 2. How to Change the Terminal App (e.g. to Kitty or Foot)

1. Open `~/DARK_NIRI/niri/config.kdl` in any text editor:
   ```bash
   nano ~/DARK_NIRI/niri/config.kdl
   ```
2. Find line 62:
   ```kdl
   Mod+Return { spawn "alacritty"; }
   ```
3. Change `"alacritty"` to your preferred terminal, like `"kitty"` or `"foot"`.
4. Save the file. Niri reloads automatically!

---

## 3. How to Change Keyboard Shortcuts

1. Open `~/DARK_NIRI/niri/config.kdl`.
2. Scroll to the `binds { ... }` section at the bottom.
3. Edit existing shortcuts or add new ones. For example, to open your web browser with `Super + B`:
   ```kdl
   Mod+B { spawn "firefox"; }
   ```
4. Save the file.

---

## 4. How to Change Window Gaps and Borders

1. Open `~/DARK_NIRI/niri/config.kdl`.
2. Find the `layout { ... }` section:
   - To add gaps back between windows, change `gaps 0` (e.g. `gaps 8` or `gaps 16`).
   - To re-enable or customize borders/focus rings, replace `focus-ring { off }` with:
     ```kdl
     focus-ring {
         width 3
         active-color "#7aa2f7"
         inactive-color "#24283b"
     }
     ```
3. Save the file. Niri reloads automatically!
