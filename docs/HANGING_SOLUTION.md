# Solusi Hang pada Deployment VPS RDP Workstation

## Ringkasan Masalah

Deployment `setup.sh` mengalami hang di environment non-interactive karena beberapa komponen memerlukan proper terminal/TTY.

## Root Cause Analysis

### 1. Interactive Prompts (setup.sh:186-203)
```bash
# Fungsi get_credentials() menggunakan read
read -rp "Enter username: " VPS_USERNAME
read -rp "Enter password: " VPS_PASSWORD
```
**Masalah:** Di environment tanpa TTY (SSH automation, background process), `read` akan hang menunggu input.

### 2. TUI Initialization (setup.sh:77-105)
```bash
init_tui() {
    clear
    rows=$(tput lines)  # Requires TTY
    tput sc             # Save cursor position
    tput cup 0 0        # Cursor positioning
}
```
**Masalah:** `tput` commands memerlukan terminal capabilities.

### 3. Rich TUI Callback (plugins/callback/rich_tui.py:179)
```python
self.live = Live(self.layout, refresh_per_second=12)
self.live.start()  # Requires terminal
```
**Masalah:** Rich library memerlukan proper terminal untuk live display.

## Solusi: Tmux Wrapper

### Cara Kerja

1. **Tmux menyediakan pseudo-TTY**
   - Tmux membuat session dengan terminal emulator built-in
   - Semua command di dalam tmux mendapatkan proper TTY
   - TUI dan interactive prompts bisa berjalan normal

2. **Environment Variables**
   - `VPS_USERNAME` dan `VPS_SECRETS_FILE` di-set sebelum masuk tmux
   - Tidak ada interactive prompt yang tersisa

3. **TERM setting**
   - `TERM=screen-256color` memastikan TUI rendering berjalan baik

### File Solusi

**`deploy-tmux.sh`** - Wrapper script yang:
- Validasi environment dan install tmux jika belum ada
- Setup credentials dari environment variables atau prompt
- Buat tmux session detached untuk deployment
- Monitor progress sampai selesai
- Support attach/detach untuk monitoring

### Penggunaan

#### 1. Interactive Mode (dengan prompt)
```bash
sudo ./deploy-tmux.sh
# Akan menanyakan username dan password
# Deployment berjalan di tmux background
# Bisa dipantau dengan: tmux attach -t vps-setup
```

#### 2. Dengan Environment Variables
```bash
export VPS_USERNAME=developer
export VPS_SECRETS_FILE=/root/.secrets
sudo ./deploy-tmux.sh
```

#### 3. Dengan Password Langsung
```bash
export VPS_USERNAME=developer
export VPS_PASSWORD=secret123
sudo ./deploy-tmux.sh
```

#### 4. Monitoring Commands

**Cek status:**
```bash
./deploy-tmux.sh status
```

**Attach ke session (lihat TUI):**
```bash
./deploy-tmux.sh attach
# atau
# tmux attach -t vps-setup
```

**Lihat log:**
```bash
./deploy-tmux.sh logs
# atau
# tail -f /var/log/vps-tmux-deploy.log
```

**Hentikan deployment:**
```bash
./deploy-tmux.sh kill
```

## Keuntungan Menggunakan Tmux

1. **No Hang** - Tmux menyediakan proper TTY untuk TUI
2. **Detachable** - Bisa keluar dari SSH dan deployment tetap berjalan
3. **Reattachable** - Bisa kembali untuk melihat progress kapan saja
4. **Logging** - Output tersimpan di log file untuk debugging
5. **Session Management** - Bisa mengelola multiple deployment sessions

## Troubleshooting

### TUI masih hang di tmux
Pastikan TERM di-set dengan benar:
```bash
export TERM=screen-256color
```

### Tidak bisa attach ke session
```bash
# List sessions
tmux ls

# Attach ke session yang ada
tmux attach -t vps-setup
```

### Deployment timeout
Default timeout adalah 1 jam. Jika deployment lebih lama:
```bash
# Edit di deploy-tmux.sh
local max_wait=7200  # 2 jam
```

## Perbandingan: setup.sh vs deploy-tmux.sh

| Aspek | setup.sh langsung | deploy-tmux.sh |
|-------|------------------|----------------|
| TTY Requirement | Memerlukan TTY | Tmux menyediakan TTY |
| Background Run | Tidak bisa | Bisa (detached) |
| Reattach | Tidak | Ya |
| Log Persistence | Hanya ke file | File + bisa dilihat real-time |
| Automation | Sulit | Mudah |

## Rekomendasi

**Gunakan `deploy-tmux.sh` untuk:**
- Deployment via SSH automation
- Background deployment
- Environment tanpa proper TTY
- Deployment yang memakan waktu lama

**Gunakan `setup.sh` langsung untuk:**
- Interactive deployment di terminal lokal
- Quick testing
- Environment dengan proper TTY

## Technical Details

### Tmux Session
- Nama session: `vps-setup`
- Window name: `deploy`
- Log file: `/var/log/vps-tmux-deploy.log`
- State file: `/var/lib/vps-setup/tmux-deploy.state`

### Flow Deployment
1. Wrapper validasi environment
2. Setup credentials (env var atau prompt)
3. Buat tmux session detached
4. Jalankan setup.sh dalam tmux
5. Monitor sampai deployment complete
6. Cleanup temporary files

### Exit Codes
- 0: Deployment sukses
- 1: Error (environment, credentials, atau deployment failed)
