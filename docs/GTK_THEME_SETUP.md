# WhiteSur GTK Theme — Complete Installation & Configuration Guide
> Debian 13 (Trixie) + KDE Plasma + X11 | Priorities: Dark mode · macOS fidelity · Performance · Aesthetics

---

## 1. Dependencies

```bash
# Required build dependencies for WhiteSur on Debian 13
sudo apt install -y \
  git \
  sassc \
  libglib2.0-dev-bin \  # for glib-compile-resources (GDM theme)
  imagemagick \          # for background image processing
  optipng                # for PNG optimization
```

> [!NOTE]
> You already have `gtk-3.0`, `gtk-4.0`, and `kde-config-gtk-style` installed. The above are only the *build-time* deps needed by WhiteSur's installer scripts.

---

## 2. Installation

### 2a. Clone the Repository

```bash
cd /tmp
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme
```

### 2b. Run the Installer

```bash
# Recommended command — Dark only, solid (no transparency), macOS Monterey style
./install.sh \
  -c dark \             # Color variant: dark only (skip light)
  -o solid \            # Opacity: solid (better performance, no transparency artifacts)
  -m \                  # macOS Monterey style (updated window controls & styling)
  --round \             # Rounded corners on maximized windows
  --darker \            # Deeper dark variant for higher contrast
  -l \                  # Install libadwaita/GTK4 theme into ~/.config/gtk-4.0/
  -a alt                # Alt window control buttons (closer to macOS traffic lights)
```

> [!CAUTION]
> The `-l` / `--libadwaita` flag **must NOT be run with sudo**. It copies theme files into `~/.config/gtk-4.0/` for your user. The installer will error if you use `sudo` with this flag.

#### All Available `install.sh` Flags

| Flag | Values | Description |
|------|--------|-------------|
| `-c, --color` | `light`, `dark` | Color variant (repeatable). Default: both |
| `-o, --opacity` | `normal`, `solid` | Transparency variant. Default: both |
| `-t, --theme` | `default`, `blue`, `purple`, `pink`, `red`, `orange`, `yellow`, `green`, `grey` | Accent color. Default: `default` (macOS blue-grey) |
| `-s, --scheme` | `standard`, `nord` | Color scheme. Default: `standard` |
| `-a, --alt` | `normal`, `alt`, `all` | Window control button style. `alt` = macOS-like traffic lights |
| `-m, --monterey` | *(no value)* | macOS Monterey style (updated visuals) |
| `-l, --libadwaita` | *(no value)* | Install GTK4/libadwaita theme to `~/.config/gtk-4.0/` |
| `-f, --fixed` | *(no value)* | Fixed accent color (vs adaptive) |
| `--round` | *(no value)* | Rounded corners on maximized windows |
| `--darker` | *(no value)* | Deeper dark color variant |
| `--right` | *(no value)* | Place window buttons on the right side |
| `-HD` | *(no value)* | High Definition sizing (for HiDPI displays) |
| `-N, --nautilus` | `stable`, `normal`, `mojave`, `glassy`, `right` | Nautilus sidebar style (irrelevant for KDE) |
| `-d, --dest` | `DIR` | Custom install directory. Default: `~/.themes/` |
| `-n, --name` | `NAME` | Custom theme name. Default: `WhiteSur` |
| `-r, --remove` | *(no value)* | Uninstall all WhiteSur themes |
| `--dialog` | *(no value)* | Interactive mode with GUI dialogs |

---

## 3. Tweaks (Firefox, Flatpak)

### 3a. Firefox Theme

```bash
# Close Firefox FIRST, then:
./tweaks.sh -f monterey darker
#              ^^^^^^^^^         = Monterey-style toolbar
#                        ^^^^^^  = Darker variant matching your dark GTK theme
```

After install, go to **Firefox → Menu → Customize Toolbar** and move the **New Tab** button to the titlebar area.

**Alternative options:**

| Sub-flag | Effect |
|----------|--------|
| `monterey` | Monterey-style topbar with configurable button counts (`3+3`, `4+4`, etc.) |
| `flat` | Flat round tabs (Monterey alt) |
| `alt` | Alt window button style matching GTK theme |
| `darker` | Darker Firefox variant |
| `nord` | Nord color scheme |
| `adaptive` | Adaptive colors (needs [adaptive-tab-bar-colour](https://addons.mozilla.org/firefox/addon/adaptive-tab-bar-colour/) addon) |

### 3b. Flatpak Integration (if you use Flatpak)

```bash
# Connect dark solid theme to Flatpak apps
./tweaks.sh -F -c dark -o solid
```

---

## 4. Configuration — Applying the Theme

### 4a. GTK2 & GTK3 (via KDE System Settings)

**GUI:**
```
System Settings → Appearance → GNOME/GTK Application Style
  → Select: WhiteSur-Dark-solid-alt  (or WhiteSur-Dark-solid)
```

**CLI equivalent** (if using kwriteconfig):
```bash
# Set GTK theme via gsettings
gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark-solid-alt'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
```

### 4b. GTK4 / libadwaita

The `-l` flag in Step 2 handles this automatically by copying theme CSS into `~/.config/gtk-4.0/`. Verify the config:

```ini
# ~/.config/gtk-4.0/settings.ini — should contain:
[Settings]
gtk-application-prefer-dark-theme=true
gtk-theme-name=WhiteSur-Dark-solid-alt
gtk-icon-theme-name=WhiteSur-dark
gtk-cursor-theme-name=WhiteSur-cursors
gtk-font-name=Inter, 10
```

> [!WARNING]
> The `-l` flag overwrites your `gtk-4.0` directory contents. After running `install.sh -l`, check that your `settings.ini` still has the correct values above. Re-add any missing lines.

### 4c. Kvantum (Qt Apps)

You already have Kvantum installed with WhiteSur theme available:

```bash
# Set Kvantum theme
kvantummanager --set WhiteSur
```

**Or via GUI:** Open `kvantummanager` → Change/Delete Theme → Select `WhiteSur` → Use this theme.

Ensure KDE uses Kvantum as the Qt style:

```bash
# Check current widget style
kreadconfig6 --group "KDE" --key "widgetStyle" --file kdeglobals

# Set to kvantum (if not already)
kwriteconfig6 --group "KDE" --key "widgetStyle" --file kdeglobals "kvantum"
```

### 4d. Icon Theme

```bash
# Clone and install WhiteSur icon theme
cd /tmp
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git
cd WhiteSur-icon-theme
./install.sh -d ~/.icons  # or just ./install.sh
```

Set via KDE:
```
System Settings → Appearance → Icons → WhiteSur-dark
```

Or CLI:
```bash
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark'
# For Plasma:
kwriteconfig6 --group "Icons" --key "Theme" --file kdeglobals "WhiteSur-dark"
```

### 4e. Cursor Theme

```bash
# Clone and install WhiteSur cursors
cd /tmp
git clone https://github.com/vinceliuice/WhiteSur-cursors.git
cd WhiteSur-cursors
./install.sh
```

Set via KDE:
```
System Settings → Appearance → Cursors → WhiteSur-cursors
```

Or CLI:
```bash
gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors'
kwriteconfig6 --group "Mouse" --key "cursorTheme" --file kcminputrc "WhiteSur-cursors"
```

---

## 5. macOS UI Fidelity Tweaks

### 5a. Window Button Layout (Left Side — macOS Style)

```bash
# KDE: Move close/minimize/maximize to the left
kwriteconfig6 --group "org.kde.kdecoration2" --key "ButtonsOnLeft" --file kwinrc "XIA"
kwriteconfig6 --group "org.kde.kdecoration2" --key "ButtonsOnRight" --file kwinrc ""
# Reload KWin
qdbus6 org.kde.KWin /KWin reconfigure
```

**Button codes:** `X` = close, `I` = minimize, `A` = maximize

**GTK apps** — already handled by `settings.ini`:
```ini
gtk-decoration-layout=close,minimize,maximize:
```
The colon (`:`) separates left/right. Everything before it is on the left.

### 5b. Window Decorations — Rounded, Borderless

For optimal macOS look, use **Breeze** window decoration with custom settings:

```
System Settings → Appearance → Window Decorations
  → Breeze → Configure
  → Window border size: No Borders
  → Button size: Normal
```

Or install **WhiteSur KDE decoration** (if available via KDE Store):
```
System Settings → Appearance → Window Decorations → Get New... → Search "WhiteSur"
```

### 5c. Panel / Dock (macOS-style Taskbar)

**Option 1: KDE Panel as Dock** (recommended — no extra deps):
```
Right-click Panel → Enter Edit Mode
  → More Options → Panel Alignment: Center
  → Width: Fit Content
  → Floating Panel: Enabled
  → Panel Height: 48-56px
  → Panel Opacity: Adaptive or Translucent
```

**Option 2: Latte Dock** (closer to macOS Dock, if already installed):
```bash
# Your system may already have this — check docs/PLASMA_DOCK_SETUP.md
latte-dock &
```

### 5d. Global Menu (macOS-style Top Menu Bar)

```
Right-click top panel → Add Widgets → Global Menu
```
This moves application menus to the top panel, like macOS.

---

## 6. Performance Optimization

### 6a. KWin Compositor Settings

```bash
# Disable unnecessary animations for snappier feel
kwriteconfig6 --group "Plugins" --key "slideEnabled" --file kwinrc "false"
kwriteconfig6 --group "Plugins" --key "fadeEnabled" --file kwinrc "false"
kwriteconfig6 --group "Plugins" --key "scaleEnabled" --file kwinrc "true"

# Use XRender backend for lower GPU usage (or keep OpenGL for smooth rendering)
# kwriteconfig6 --group "Compositing" --key "Backend" --file kwinrc "XRender"

# Reduce animation speed (1 = fastest, 0 = instant)
kwriteconfig6 --group "KDE" --key "AnimationDurationFactor" --file kdeglobals "0.5"

# Apply changes
qdbus6 org.kde.KWin /KWin reconfigure
```

### 6b. GTK Animation

Already disabled in your config (`gtk-enable-animations=false`). This is optimal for performance.

### 6c. Solid vs Normal Opacity

Using `-o solid` in the install command eliminates CSS blur/transparency effects, which improves rendering performance on both GTK and compositor.

---

## 7. Aesthetics

### 7a. Font Pairing

macOS uses **SF Pro** (proprietary). Best open-source alternatives:

```bash
# Install Inter (closest to SF Pro for UI) + JetBrains Mono (code)
sudo apt install -y fonts-inter

# Or download SF Pro Display (if you have a Mac license):
# Place .otf files in ~/.local/share/fonts/ && fc-cache -fv
```

Apply in KDE:
```
System Settings → Appearance → Fonts
  → General:       Inter, 10pt
  → Fixed width:   JetBrains Mono, 10pt
  → Small:         Inter, 8pt
  → Toolbar:       Inter, 10pt
  → Menu:          Inter, 10pt
  → Window title:  Inter, Semi-Bold, 10pt
```

Update GTK configs to match:
```bash
# GTK3
sed -i 's/gtk-font-name=.*/gtk-font-name=Inter, 10/' ~/.config/gtk-3.0/settings.ini

# GTK4
sed -i 's/gtk-font-name=.*/gtk-font-name=Inter, 10/' ~/.config/gtk-4.0/settings.ini

# GTK2
sed -i 's/gtk-font-name=.*/gtk-font-name="Inter, 10"/' ~/.gtkrc-2.0
```

### 7b. Wallpaper

WhiteSur includes macOS-style wallpapers:

```bash
cd /tmp
git clone https://github.com/vinceliuice/WhiteSur-wallpapers.git
cd WhiteSur-wallpapers
# Install all variants
./install-wallpapers.sh
# Wallpapers installed to: /usr/share/backgrounds/WhiteSur/
```

Set dark wallpaper:
```
System Settings → Appearance → Wallpaper
  → Browse to /usr/share/backgrounds/WhiteSur/
  → Select a dark variant (e.g., WhiteSur-dark.png or Monterey-dark.jpg)
```

### 7c. Plasma Color Scheme

For consistent dark mode across all Qt/Plasma elements:

```
System Settings → Appearance → Colors
  → BreezeDark (or install WhiteSur color scheme from KDE Store)
```

Or search the store:
```
System Settings → Appearance → Colors → Get New... → Search "WhiteSur"
```

### 7d. Accent Color Alignment

KDE Plasma 6 supports accent colors natively:
```
System Settings → Appearance → Colors → Accent Color
  → Pick a color matching your WhiteSur accent (default = macOS blue: #007AFF)
```

---

## 8. Known KDE Compatibility Notes

| Issue | Workaround |
|-------|-----------|
| WhiteSur is primarily a GTK theme — Qt apps won't match without Kvantum | Use Kvantum with WhiteSur theme (Section 4c) |
| `--libadwaita` flag may overwrite your `gtk-4.0/settings.ini` | Re-check `settings.ini` values after running install (Section 4b) |
| GDM theming (`tweaks.sh -g`) is irrelevant on KDE Plasma | Skip GDM tweaks entirely — KDE uses SDDM |
| GNOME Shell tweaks (`--shell`) are irrelevant on KDE | Skip all `--shell` sub-flags |
| Flatpak apps may ignore system GTK theme | Use `tweaks.sh -F` to explicitly connect (Section 3b) |
| Firefox may need manual toolbar customization | Move "New Tab" button to titlebar after theme install |
| Window decorations are Qt-based in KDE, not GTK | Theme only affects window *content*, not title bar — use KDE decoration settings |

---

## 9. Verification Checklist

Run through this after completing all steps:

```bash
# 1. GTK theme consistency
echo "GTK2: $(grep 'gtk-theme-name' ~/.gtkrc-2.0)"
echo "GTK3: $(grep 'gtk-theme-name' ~/.config/gtk-3.0/settings.ini)"
echo "GTK4: $(grep 'gtk-theme-name' ~/.config/gtk-4.0/settings.ini)"
echo "gsettings: $(gsettings get org.gnome.desktop.interface gtk-theme)"

# 2. Dark mode
echo "GTK3 dark: $(grep 'prefer-dark' ~/.config/gtk-3.0/settings.ini)"
echo "GTK4 dark: $(grep 'prefer-dark' ~/.config/gtk-4.0/settings.ini)"
echo "gsettings dark: $(gsettings get org.gnome.desktop.interface color-scheme)"

# 3. Icons & cursor
echo "Icons: $(gsettings get org.gnome.desktop.interface icon-theme)"
echo "Cursor: $(gsettings get org.gnome.desktop.interface cursor-theme)"

# 4. Kvantum
echo "Kvantum theme: $(grep 'theme=' ~/.config/Kvantum/kvantum.kvconfig 2>/dev/null)"

# 5. Font
echo "Font: $(grep 'gtk-font-name' ~/.config/gtk-3.0/settings.ini)"

# 6. Window buttons
echo "Buttons left: $(kreadconfig6 --group 'org.kde.kdecoration2' --key 'ButtonsOnLeft' --file kwinrc)"
echo "Buttons right: $(kreadconfig6 --group 'org.kde.kdecoration2' --key 'ButtonsOnRight' --file kwinrc)"
```

**Expected output:**
```
GTK2: gtk-theme-name="WhiteSur-Dark-solid-alt"
GTK3: gtk-theme-name=WhiteSur-Dark-solid-alt
GTK4: gtk-theme-name=WhiteSur-Dark-solid-alt
gsettings: 'WhiteSur-Dark-solid-alt'
GTK3 dark: gtk-application-prefer-dark-theme=true
GTK4 dark: gtk-application-prefer-dark-theme=true
gsettings dark: 'prefer-dark'
Icons: 'WhiteSur-dark'
Cursor: 'WhiteSur-cursors'
Kvantum theme: theme=WhiteSur
Font: gtk-font-name=Inter, 10
Buttons left: XIA
Buttons right:
```

**Visual checks:**
- [ ] Open a GTK3 app (Firefox, Thunar) — dark WhiteSur theme visible
- [ ] Open a GTK4 app (if installed) — dark theme visible
- [ ] Open a Qt app (Dolphin, Kate) — Kvantum WhiteSur theme visible
- [ ] Window buttons are on the left (close, minimize, maximize)
- [ ] Panel/dock is centered and floating
- [ ] Fonts are Inter across all apps
- [ ] Cursor is WhiteSur-cursors

---

## Quick Reference — Re-install Command

```bash
# Full re-install (dark, solid, monterey, rounded, darker, libadwaita, alt buttons)
cd /tmp/WhiteSur-gtk-theme
./install.sh -r                    # Remove old first
./install.sh -c dark -o solid -m --round --darker -l -a alt
./tweaks.sh -f monterey darker     # Firefox theme
```
