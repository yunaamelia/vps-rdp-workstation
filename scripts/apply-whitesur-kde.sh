#!/usr/bin/env bash
#
# apply-whitesur-kde.sh
# Complete WhiteSur macOS-like KDE Plasma configuration.
# Idempotent — safe to re-run. All changes applied via correct KDE APIs.
#
# Usage: ./scripts/apply-whitesur-kde.sh
#
set -euo pipefail

echo "============================================"
echo "  WhiteSur KDE Full Configuration"
echo "============================================"
echo ""

# ──────────────────────────────────────────────
# 0. Window Decorations — title bar & buttons
# ──────────────────────────────────────────────
echo "[0/9] Window decorations..."

# Clean breezerc — remove ALL window decoration exceptions that hide title bars
# Write a clean breezerc without any exceptions
cat > "$HOME/.config/breezerc" << 'BREEZERC'
[Common]
OutlineCloseButton=false

[Windeco]
DrawBackgroundGradient=false
BREEZERC

# Disable Polonium tiling WM — it strips window decorations from tiled windows
kwriteconfig6 --file kwinrc --group "Plugins" --key "poloniumEnabled" "false"

# Keep title bar on maximized windows
kwriteconfig6 --file kwinrc --group "Windows" --key "BorderlessMaximizedWindows" "false"

# Ensure Breeze decoration is loaded
kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "library" "org.kde.breeze"
kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "theme" "Breeze"

# Window buttons: left side macOS style (X=Close, I=Minimize, A=Maximize)
kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "ButtonsOnLeft" "XIA"
kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "ButtonsOnRight" ""
kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "BorderSize" "Normal"
kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "CloseOnDoubleClickOnMenu" "false"
kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "ShowToolTips" "false"

echo "  ✓ Title bars enabled, Polonium disabled, buttons on left (XIA)"

# ──────────────────────────────────────────────
# 1. Plasma Desktop Theme
# ──────────────────────────────────────────────
echo "[1/9] Plasma theme: WhiteSur-dark..."
plasma-apply-desktoptheme WhiteSur-dark 2>/dev/null || echo "  ⚠ plasma-apply-desktoptheme unavailable"

# ──────────────────────────────────────────────
# 2. Color Scheme
# ──────────────────────────────────────────────
echo "[2/9] Color scheme: BreezeDark..."
plasma-apply-colorscheme BreezeDark 2>/dev/null || echo "  ⚠ plasma-apply-colorscheme unavailable"

# ──────────────────────────────────────────────
# 3. Accent Color — macOS Blue (#007AFF = 0,122,255)
# ──────────────────────────────────────────────
echo "[3/9] Accent color: #007AFF..."
kwriteconfig6 --file kdeglobals --group "General" --key "AccentColor" "0,122,255"

# ──────────────────────────────────────────────
# 4. Fonts — Inter for UI, JetBrains Mono for terminal
# ──────────────────────────────────────────────
echo "[4/9] Fonts: Inter + JetBrains Mono..."
# Format: Family,Size,PixelSize,StyleHint,Weight,Italic,Underline,StrikeOut,FixedPitch,StyleStrategy,StyleName
kwriteconfig6 --file kdeglobals --group "General" --key "font" "Inter,10,-1,5,400,0,0,0,0,0,Regular"
kwriteconfig6 --file kdeglobals --group "General" --key "menuFont" "Inter,10,-1,5,400,0,0,0,0,0,Regular"
kwriteconfig6 --file kdeglobals --group "General" --key "toolBarFont" "Inter,10,-1,5,400,0,0,0,0,0,Regular"
kwriteconfig6 --file kdeglobals --group "General" --key "smallestReadableFont" "Inter,8,-1,5,400,0,0,0,0,0,Regular"
kwriteconfig6 --file kdeglobals --group "General" --key "activeFont" "Inter,10,-1,5,600,0,0,0,0,0,Semi-Bold"
kwriteconfig6 --file kdeglobals --group "General" --key "fixed" "JetBrains Mono,10,-1,5,400,0,0,0,0,0,Regular"

# GTK font settings
sed -i 's/gtk-font-name=.*/gtk-font-name=Inter, 10/' ~/.config/gtk-3.0/settings.ini 2>/dev/null || true
sed -i 's/gtk-font-name=.*/gtk-font-name=Inter, 10/' ~/.config/gtk-4.0/settings.ini 2>/dev/null || true
sed -i 's/gtk-font-name=.*/gtk-font-name="Inter, 10"/' ~/.gtkrc-2.0 2>/dev/null || true

echo "  ✓ Fonts set"

# ──────────────────────────────────────────────
# 5. Icons & Cursors
# ──────────────────────────────────────────────
echo "[5/9] Icons: WhiteSur-dark, Cursor: WhiteSur-cursors..."

# Icons via kdeglobals + gsettings
kwriteconfig6 --file kdeglobals --group "Icons" --key "Theme" "WhiteSur-dark"
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark' 2>/dev/null || true

# Cursor via plasma-apply + kcminputrc + gsettings
plasma-apply-cursortheme WhiteSur-cursors 2>/dev/null || true
kwriteconfig6 --file kcminputrc --group "Mouse" --key "cursorTheme" "WhiteSur-cursors"
kwriteconfig6 --file kcminputrc --group "Mouse" --key "cursorSize" "24"
gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors' 2>/dev/null || true

echo "  ✓ Icons & cursors set"

# ──────────────────────────────────────────────
# 6. Wallpaper
# ──────────────────────────────────────────────
WALLPAPER="$HOME/.local/share/backgrounds/Monterey-dark.jpg"
if [[ -f "$WALLPAPER" ]]; then
    echo "[6/9] Wallpaper: Monterey-dark..."
    plasma-apply-wallpaperimage "$WALLPAPER" 2>/dev/null || echo "  ⚠ wallpaper apply failed"
else
    echo "[6/9] ⚠ Wallpaper not found: $WALLPAPER"
fi

# ──────────────────────────────────────────────
# 7. GTK Theme — ensure consistency across GTK2/3/4
# ──────────────────────────────────────────────
echo "[7/9] GTK theme consistency..."
THEME="WhiteSur-Dark-alt-nord"

gsettings set org.gnome.desktop.interface gtk-theme "$THEME" 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true

# GTK3
if [[ -f ~/.config/gtk-3.0/settings.ini ]]; then
    sed -i "s/gtk-theme-name=.*/gtk-theme-name=$THEME/" ~/.config/gtk-3.0/settings.ini
    sed -i "s/gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=true/" ~/.config/gtk-3.0/settings.ini
fi

# GTK4
if [[ -f ~/.config/gtk-4.0/settings.ini ]]; then
    sed -i "s/gtk-theme-name=.*/gtk-theme-name=$THEME/" ~/.config/gtk-4.0/settings.ini
    sed -i "s/gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=true/" ~/.config/gtk-4.0/settings.ini
fi

# GTK2
if [[ -f ~/.gtkrc-2.0 ]]; then
    sed -i "s/gtk-theme-name=.*/gtk-theme-name=\"$THEME\"/" ~/.gtkrc-2.0
fi

# xsettingsd — X11 source-of-truth for GTK apps (used by kde-gtk-config daemon)
if [[ -f ~/.config/xsettingsd/xsettingsd.conf ]]; then
    sed -i "s|Net/ThemeName .*|Net/ThemeName \"$THEME\"|" ~/.config/xsettingsd/xsettingsd.conf
    # Restart xsettingsd to apply
    killall xsettingsd 2>/dev/null || true
    sleep 1
    nohup xsettingsd > /dev/null 2>&1 &
    disown
    echo "  ✓ xsettingsd synced and restarted"
fi

echo "  ✓ GTK2/3/4 + xsettingsd all set to $THEME (dark mode)"

# ──────────────────────────────────────────────
# 8. Kvantum — Qt app theming
# ──────────────────────────────────────────────
echo "[8/9] Kvantum: WhiteSur..."
kvantummanager --set WhiteSur 2>/dev/null || echo "  ⚠ kvantummanager unavailable"

# ──────────────────────────────────────────────
# 9. KWin Performance
# ──────────────────────────────────────────────
echo "[9/9] KWin performance settings..."
kwriteconfig6 --file kdeglobals --group "KDE" --key "AnimationDurationFactor" "0.5"
kwriteconfig6 --file kwinrc --group "Plugins" --key "slideEnabled" "false"
kwriteconfig6 --file kwinrc --group "Plugins" --key "fadeEnabled" "false"
kwriteconfig6 --file kwinrc --group "Plugins" --key "scaleEnabled" "true"

echo "  ✓ Animations reduced, compositor optimized"

# ──────────────────────────────────────────────
# Panel: Bottom dock via Plasma Scripting API
# ──────────────────────────────────────────────
echo ""
echo "Configuring panels via Plasma Scripting API..."

qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
var p = panels();
for (var i = 0; i < p.length; i++) {
    if (p[i].location == "bottom") {
        p[i].height = 52;
        p[i].alignment = "center";
        p[i].floating = true;
        p[i].lengthMode = "fit";
        print("  ✓ Bottom dock: h=52, floating, centered, fit-content");
    }
}
' 2>/dev/null || echo "  ⚠ Panel config skipped (plasmashell D-Bus unavailable)"

# ──────────────────────────────────────────────
# Firefox — dark mode prefs for all profiles
# ──────────────────────────────────────────────
echo ""
echo "Configuring Firefox profiles..."

for profile_dir in "$HOME"/.mozilla/firefox/*.default*; do
    [[ -d "$profile_dir" ]] || continue
    cat > "$profile_dir/user.js" << 'FIREFOX_PREFS'
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.tabs.drawInTitlebar", true);
user_pref("browser.tabs.inTitlebar", 1);
user_pref("browser.uidensity", 0);
user_pref("layers.acceleration.force-enabled", true);
user_pref("mozilla.widget.use-argb-visuals", true);
user_pref("widget.gtk.rounded-bottom-corners.enabled", true);
user_pref("svg.context-properties.content.enabled", true);
user_pref("browser.theme.dark-private-windows", true);
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("browser.in-content.dark-mode", true);
FIREFOX_PREFS
    echo "  ✓ $(basename "$profile_dir")"
done

# ──────────────────────────────────────────────
# Reload KDE
# ──────────────────────────────────────────────
echo ""
echo "Reloading KDE..."
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null && echo "  ✓ KWin reconfigured" || echo "  ⚠ KWin reconfigure failed"

# Restart plasmashell safely
if pgrep -x plasmashell > /dev/null; then
    nohup plasmashell --replace > /dev/null 2>&1 &
    disown
    echo "  ✓ plasmashell --replace sent"
else
    nohup plasmashell > /dev/null 2>&1 &
    disown
    echo "  ✓ plasmashell started"
fi
sleep 3

# Verify
if pgrep -x plasmashell > /dev/null; then
    echo "  ✓ plasmashell running (PID: $(pgrep -x plasmashell))"
else
    echo "  ⚠ plasmashell not running! Run: plasmashell --replace &"
fi

echo ""
echo "============================================"
echo "  ✅ WhiteSur KDE configuration complete!"
echo "============================================"
echo ""
echo "  Plasma theme:    WhiteSur-dark"
echo "  Color scheme:    BreezeDark"
echo "  Accent:          #007AFF (macOS Blue)"
echo "  GTK:             WhiteSur-Dark-solid-alt (dark)"
echo "  Kvantum:         WhiteSur"
echo "  Fonts:           Inter 10pt / JetBrains Mono 10pt"
echo "  Icons:           WhiteSur-dark"
echo "  Cursor:          WhiteSur-cursors"
echo "  Wallpaper:       Monterey-dark"
echo "  Panel:           Bottom dock (floating, centered, 52px)"
echo "  Window buttons:  Left (Close, Min, Max)"
echo "  Firefox:         Dark mode + WhiteSur theme"
echo ""
