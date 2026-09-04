# 🎨 Theming System & Design Tokens

This document details the **Tokyo Night** design tokens, typography, and geometry standards implemented across Dark Niri.

---

## 1. Color Palette Tokens

| Token Name | Hex Value | Usage in Desktop |
| :--- | :--- | :--- |
| `bg-dark` | `#1a1b26` | Main panel background, Rofi background, Mako background |
| `bg-dark-alpha` | `#E61a1b26` | 90% opacity surface for QuickShell top bar & flyout |
| `bg-alt` | `#24283b` | Secondary container surfaces, list item background |
| `border-subtle` | `#292e42` | Dividers, 1px container borders |
| `accent-blue` | `#7aa2f7` | Active selection, primary buttons, focus highlights |
| `accent-cyan` | `#7dcfff` | Secondary highlights, network badges, subtitle text |
| `accent-purple`| `#7c4dff` | Niri active window focus ring |
| `accent-gold` | `#ffc107` | Niri window outer border, warning indicators |
| `fg-primary` | `#c0caf5` | Primary text color |
| `fg-secondary` | `#a9b1d6` | Subtitles, inactive icons, placeholder text |
| `error-red` | `#f7768e` | Recording indicator, power actions, critical alerts |
| `success-green`| `#9ece6a` | Connected indicators, active governors |

---

## 2. Typography & Geometry Tokens

- **Font Family**: `Inter` (UI elements, labels, buttons) and `Inter Bold` (headers, prompts).
- **Icon Font**: `Nerd Font Symbols` (Material / FontAwesome glyphs).
- **Corner Radii**:
  - Windows: 12px
  - Flyout Modals: 12px
  - Buttons / Text Inputs: 8px
  - Pill Badges: 15px (fully pill-shaped)
