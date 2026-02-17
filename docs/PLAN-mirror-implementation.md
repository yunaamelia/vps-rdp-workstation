# Mirror Implementation: Ansible ↔ Running System Sync

Mengintegrasikan SEMUA konfigurasi manual yang dilakukan selama sesi ini ke dalam Ansible codebase, sehingga `ansible-playbook playbooks/main.yml` menghasilkan sistem yang 100% identik dengan running system saat ini.

> [!IMPORTANT]
> **Mirror Implementation** = setiap config change yang aktif di running system HARUS punya padanan di Ansible codebase (template/task/default). Tidak ada config yang hanya hidup di running system.

---

## Gap Analysis: Running System vs Ansible Codebase

### 🔴 Critical Gaps (Config Mismatch)

| # | Item | Running System | Ansible Codebase | Action |
|---|------|---------------|------------------|--------|
| 1 | **Window Decoration** | `org.kde.klassy` | Not in kwinrc.j2, no Klassy role | Create `klassy` role + update template |
| 2 | **Polonium** | `poloniumEnabled=false` | `poloniumEnabled=true` in kwinrc.j2 | Fix template |
| 3 | **Title Bars** | `BorderlessMaximizedWindows=false` | `true` in kwinrc.j2 | Fix template |
| 4 | **Button Layout** | `ButtonsOnLeft=XIA`, `ButtonsOnRight=""` | `MF` / `IAX` in kwinrc.j2 | Fix template |
| 5 | **Fonts** | Inter 10pt / JetBrains Mono | Cantarell 10pt in kdeglobals.j2 | Fix template |
| 6 | **GTK Theme** | `WhiteSur-Dark-alt-nord` | `Breeze` in gtk3-settings.ini.j2 | Fix template |
| 7 | **GTK Cursor** | `WhiteSur-cursors` | `breeze_cursors` in gtk3-settings.ini.j2 | Fix template |
| 8 | **GTK Icons** | `WhiteSur-dark` | `breeze` in gtk3-settings.ini.j2 | Fix template |
| 9 | **Icon Options** | `-t red -b -p` | defaults: `default`, no bold, no plasma | Fix defaults |
| 10 | **Accent Color** | `0,122,255` (macOS Blue) | Not in kdeglobals.j2 | Add to template |

### 🟡 Missing Components (Not in Ansible at all)

| # | Component | Running System | Ansible |
|---|-----------|---------------|---------|
| 11 | **Klassy role** | Built from source, configured | ❌ Does not exist |
| 12 | **GTK4 settings** | `~/.config/gtk-4.0/settings.ini` | ❌ No template |
| 13 | **GTK2 settings** | `~/.gtkrc-2.0` | ❌ No template |
| 14 | **xsettingsd.conf** | Synced with WhiteSur theme | ❌ No template |
| 15 | **Firefox user.js** | Dark mode + WhiteSur prefs | ❌ No config |
| 16 | **Panel config** | Bottom dock, floating, 52px | ❌ No scripting |
| 17 | **Klassyrc** | Traffic Lights, Tiny buttons | ❌ No template |
| 18 | **Breezerc** | Clean (no exceptions) | ❌ No template |

### 🟢 Already Correct (No change needed)

| Component | Status |
|-----------|--------|
| WhiteSur-cursors install | ✅ Already in role |
| WhiteSur-icon-theme install | ✅ Already in role (needs option update) |
| WhiteSur-kde install | ✅ Already in role |
| Kvantum config | ✅ Already in desktop + whitesur roles |

---

## Proposed Changes

### 1. New Role: `klassy`
> [!NOTE]
> New role for Klassy window decoration (build from source)

#### [NEW] `roles/klassy/defaults/main.yml`
- `vps_klassy_install: true`
- `vps_klassy_repo`, `vps_klassy_branch: "plasma6.3"`
- `vps_klassy_button_type: "TrafficLights"`
- `vps_klassy_button_size: "Tiny"`

#### [NEW] `roles/klassy/tasks/main.yml`
- Install build deps
- Clone repo, checkout branch
- Run `./install.sh`
- Deploy `klassyrc` template
- Cleanup

#### [NEW] `roles/klassy/templates/klassyrc.j2`
- Button config from variables

#### [NEW] `roles/klassy/handlers/main.yml`
- KWin reconfigure handler

---

### 2. Update Role: `kde-optimization`

#### [MODIFY] `templates/kwinrc.j2`
- `poloniumEnabled=false`
- `BorderlessMaximizedWindows=false`
- `library=org.kde.klassy`, `theme=Klassy`
- `ButtonsOnLeft=XIA`, `ButtonsOnRight=`
- Remove `BorderSize=Normal`

#### [MODIFY] `templates/kdeglobals.j2`
- Fonts: `Inter,10` → all font keys
- `fixed=JetBrains Mono,10`
- Add `[General] AccentColor=0,122,255`
- Add `[General] ColorScheme=BreezeDark`
- `AnimationDurationFactor=0.5`

#### [MODIFY] `templates/gtk3-settings.ini.j2`
- `gtk-theme-name=WhiteSur-Dark-alt-nord`
- `gtk-cursor-theme-name=WhiteSur-cursors`
- `gtk-icon-theme-name=WhiteSur-dark`
- `gtk-font-name=Inter%, 10`
- `gtk-decoration-layout=close,minimize,maximize:icon`

#### [NEW] `templates/gtk4-settings.ini.j2`
- Mirror of GTK3 (same keys)

#### [NEW] `templates/gtkrc-2.0.j2`
- GTK2 equivalent

#### [NEW] `templates/xsettingsd.conf.j2`
- Full xsettingsd config with WhiteSur theme

#### [NEW] `templates/breezerc.j2`
- Clean breezerc without exceptions

#### [NEW] `templates/klassyrc.j2`
- Klassy window decoration config

#### [MODIFY] `tasks/main.yml`
- Deploy new templates (gtk4, gtkrc-2.0, xsettingsd, breezerc)
- Restart xsettingsd handler
- Panel config via qdbus6 evaluateScript

---

### 3. Update Role: `whitesur-theme`

#### [MODIFY] `defaults/main.yml`
- `vps_whitesur_icon_theme: "red"` (was `default`)
- `vps_whitesur_icon_bold: true` (was `false`)
- Add `vps_whitesur_icon_plasma_logo: true` (new, for `-p`)
- `vps_whitesur_icon_variant: "WhiteSur-red-dark"` (was `WhiteSur-dark`)

#### [MODIFY] `tasks/main.yml`
- Add `-p` flag to icon install command
- Update icon variant references

---

### 4. Update Role: `desktop`

#### [MODIFY] `tasks/main.yml`
- Replace SierraBreeze build deps with Klassy build deps
- Update package list comments

---

### 5. Firefox Config

#### [NEW] `roles/kde-optimization/templates/firefox-user.js.j2`
- All dark mode + WhiteSur preferences

#### [MODIFY] `roles/kde-optimization/tasks/main.yml`
- Deploy `user.js` ke semua Firefox profiles

---

### 6. Update Playbook

#### [MODIFY] `playbooks/main.yml`
- Add `klassy` role in Phase 4 (after `whitesur-theme`)

---

## Execution Order

```
1. roles/klassy/           — Create new role (4 files)
2. roles/whitesur-theme/   — Update defaults + tasks (2 files)
3. roles/desktop/          — Update desktop deps (1 file)
4. roles/kde-optimization/ — Update templates + tasks (8 files)
5. playbooks/main.yml      — Add klassy role (1 file)
6. docs/                   — Update/cleanup (1 file)
```

**Total: ~16 files modified/created**

---

## Verification

- [ ] `ansible-playbook playbooks/main.yml --check` passes
- [ ] `yamllint` on all YAML files
- [ ] `ansible-lint` on all roles
- [ ] Templates render correctly with test vars
- [ ] Commit and push
