# Security Policy

## Reporting a Vulnerability

**DO NOT** open a public GitHub issue for security vulnerabilities.

**Email:** security@vps-rdp-workstation.dev (or create a private security advisory on GitHub)

**Response Time:** We aim to respond within 48 hours.

**Include in Your Report:**
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

**Disclosure Policy:**
- We will acknowledge receipt within 48 hours
- We will provide a fix timeline within 1 week
- We request 90 days before public disclosure

## Security Features

### Credential Management
- ✅ **No plain-text passwords** - All passwords read from secure files (0600 permissions)
- ✅ **SHA-512 hashing** - Passwords hashed using Python's crypt module
- ✅ **Immediate overwrite** - Plain-text variables unset after hashing
- ✅ **No command-line passwords** - Never pass passwords as arguments

### Network Security
- ✅ **Firewall-first** - UFW configured BEFORE any services exposed
- ✅ **Default deny** - Incoming traffic denied by default
- ✅ **Only 2 ports** - Port 22 (SSH) and 3389 (RDP) with rate limiting
- ✅ **Fail2ban** - Automatic ban after 5 failed attempts (1 hour)

### SSH Hardening
- ✅ **Root login disabled** - `PermitRootLogin no`
- ✅ **Max auth tries** - Limited to 3 attempts
- ✅ **Public key auth** - Enabled for passwordless login
- ✅ **X11 forwarding disabled** - Reduced attack surface

### Download Security
- ✅ **Checksum verification** - SHA-256 on binary downloads
- ✅ **Version pinning** - Specific versions to prevent supply chain attacks
- ✅ **Retries with backoff** - Network resilience

### Log Security
- ✅ **No passwords in logs** - All credential handling uses no_log
- ✅ **No hashes in logs** - Even hashes are never logged
- ✅ **Proper permissions** - Log files 0640 (owner read/write, group read)

## Known Limitations

> ⚠️ **Honest Disclosure**

1. **Single-user focus** - Not designed for multi-user environments
2. **RDP over internet** - RDP without VPN is inherently risky
3. **Trust required** - Implementer must follow security requirements
4. **Regular updates needed** - System requires ongoing maintenance

## Best Practices

### Before Installation
- Use a fresh Debian 13 installation
- Ensure VPS provider has DDoS protection
- Consider using a bastion host for SSH

### After Installation
- Enable SSH key authentication, disable password auth
- Consider using a VPN for RDP access
- Regularly update: `sudo apt update && sudo apt upgrade`
- Monitor fail2ban: `sudo fail2ban-client status`

### For Production Use
- Add IP whitelisting for SSH/RDP
- Enable full disk encryption
- Set up centralized logging
- Implement backup strategy

## Security Checklist

```bash
# Verify firewall is active
sudo ufw status

# Check SSH hardening
grep PermitRootLogin /etc/ssh/sshd_config

# Verify fail2ban jails
sudo fail2ban-client status

# Check for world-writable files
find /etc -type f -perm -002 2>/dev/null

# Review recent SSH attempts
sudo journalctl -u ssh --since "1 hour ago"
```

## Version History

| Version | Security Changes |
|---------|-----------------|
| 3.0.0 | Initial security implementation |
