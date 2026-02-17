# WhiteSur Full Theme + Klassy Window Decoration

Mengganti seluruh theme KDE Plasma dengan WhiteSur ecosystem + Klassy window decoration.

## Komponen

| # | Komponen | Repo | Command |
|---|----------|------|---------|
| 1 | **Plasma Theme** | [WhiteSur-kde](https://github.com/vinceliuice/WhiteSur-kde) | `./install.sh` |
| 2 | **Window Decoration** | [Klassy](https://github.com/paulmcauley/klassy) (branch `6.3`) | Build from source |
| 3 | **Cursor Theme** | [WhiteSur-cursors](https://github.com/vinceliuice/WhiteSur-cursors) | `./install.sh` |
| 4 | **Icon Theme** | [WhiteSur-icon-theme](https://github.com/vinceliuice/WhiteSur-icon-theme) | `./install.sh -t red -b -p` |

## Execution

### Step 1: Dependencies
```bash
# Klassy build deps (Debian 13)
sudo apt install git build-essential cmake extra-cmake-modules \
  libkirigami-dev libkf5style-dev libkf6kcmutils-dev libkf6colorscheme-dev \
  libkf5config-dev libkf5configwidgets-dev libkf5coreaddons-dev libkf5guiaddons-dev \
  libkf6i18n-dev libkf6iconthemes-dev kirigami2-dev libkf6package-dev \
  libkf6service-dev libkf6windowsystem-dev kwayland-dev libx11-dev \
  libkdecorations3-dev libkf5i18n-dev libkf5iconthemes-dev libkf5kcmutils-dev \
  libkf5package-dev libkf5service-dev libkf5wayland-dev libkf5windowsystem-dev \
  libplasma-dev libqt5x11extras5-dev qt6-base-dev qt6-declarative-dev \
  qtbase5-dev qtdeclarative5-dev gettext qt6-svg-dev
```

### Step 2: WhiteSur-kde
```bash
cd /tmp && rm -rf WhiteSur-kde
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-kde.git
cd WhiteSur-kde && ./install.sh
```

### Step 3: Klassy (branch 6.3)
```bash
cd /tmp && rm -rf klassy
git clone https://github.com/paulmcauley/klassy
cd klassy && git checkout 6.3
./install.sh
```

### Step 4: WhiteSur Cursors
```bash
cd /tmp && rm -rf WhiteSur-cursors
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-cursors.git
cd WhiteSur-cursors && ./install.sh
```

### Step 5: WhiteSur Icons
```bash
cd /tmp && rm -rf WhiteSur-icon-theme
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git
cd WhiteSur-icon-theme && ./install.sh -t red -b -p
```

### Step 6: Configure & Apply
- Klassy macOS preset via `klassy-settings`
- Kvantum → WhiteSur
- Icons/Cursors via kwriteconfig6
- GTK + xsettingsd sync
- Update automation script
