# Troubleshooting Guide

Common issues and solutions for VPS RDP Workstation.

## Connection Issues

### Cannot connect via RDP

```bash
# Check XRDP service
sudo systemctl status xrdp

# Check firewall allows RDP
sudo ufw status | grep 3389

# Restart XRDP
sudo systemctl restart xrdp
```

### SSH connection refused

```bash
# Check SSH service
sudo systemctl status ssh

# Check firewall
sudo ufw status | grep 22

# Check SSH config
sudo sshd -t
```

## Desktop Issues

### Black screen after RDP login

```bash
# Check startwm.sh
cat ~/.xsession
cat /etc/xrdp/startwm.sh

# Restart XRDP
sudo systemctl restart xrdp
```

### KDE not starting

```bash
# Check KDE packages
dpkg -l | grep kde-plasma-desktop

# Start manually
startplasma-x11
```

## Service Issues

### Docker permission denied

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Logout and login again
```

### Fail2ban not starting

```bash
# Check configuration
sudo fail2ban-client -t

# View logs
sudo tail -f /var/log/fail2ban.log
```

## Security Issues

### Locked out of SSH

Use VPS console to:
```bash
# Restore SSH config
sudo cp /var/backups/vps-setup/sshd_config.backup /etc/ssh/sshd_config
sudo systemctl restart ssh
```

### UFW blocking everything

```bash
# Reset UFW via console
sudo ufw reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 3389/tcp
sudo ufw enable
```

## Logs Location

| Log | Path |
|-----|------|
| Main log | `/var/log/vps-setup.log` |
| Error log | `/var/log/vps-setup-error.log` |
| Summary | `/var/log/vps-setup-summary.log` |
| XRDP | `/var/log/xrdp.log` |
| Fail2ban | `/var/log/fail2ban.log` |
