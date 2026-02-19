# Emergency Rollback Procedure

**Last Updated**: 2024-02-19
**Version**: 1.0.0

---

## ⚠️ When to Rollback

Rollback immediately if you observe:

| Symptom | Severity | Action |
|---------|----------|--------|
| **Service completely down** | 🔴 CRITICAL | Rollback immediately |
| **Critical security breach** | 🔴 CRITICAL | Rollback immediately |
| **Data corruption** | 🔴 CRITICAL | Rollback immediately |
| **Performance degraded >50%** | 🟡 HIGH | Consider rollback |
| **Minor functionality broken** | 🟢 LOW | Fix forward if possible |

---

## Pre-Rollback Checklist

Before executing rollback:

- [ ] **Identify the issue** - Know what went wrong
- [ ] **Check logs** - Capture error messages
- [ ] **Notify team** - Alert stakeholders
- [ ] **Document symptoms** - For post-mortem
- [ ] **Verify backup exists** - Confirm restoration point

---

## Method 1: Ansible Rollback Playbook (Recommended)

### Quick Rollback

```bash
# SSH to VPS
ssh root@your-vps-ip

# Navigate to project
cd /opt/vps-rdp-workstation

# Execute rollback playbook
ansible-playbook playbooks/rollback.yml
```

### Rollback Specific Component

```bash
# Rollback only Docker configuration
ansible-playbook playbooks/rollback.yml --tags docker

# Rollback security settings
ansible-playbook playbooks/rollback.yml --tags security

# Rollback desktop environment
ansible-playbook playbooks/rollback.yml --tags desktop
```

### Verify After Rollback

```bash
# Run smoke tests
./tests/smoke-test.sh localhost

# Check services
systemctl status docker xrdp fail2ban

# Test RDP connection
# Try connecting via Remote Desktop to verify XRDP works
```

---

## Method 2: Manual Service Restoration

If Ansible rollback fails, restore services manually:

### Step 1: Stop Problematic Services

```bash
# Stop services
systemctl stop docker
systemctl stop xrdp
systemctl stop fail2ban
```

### Step 2: Restore Configuration from Backup

```bash
# Restore SSH config
sudo cp /var/backups/vps-setup/sshd_config.backup /etc/ssh/sshd_config
sudo systemctl restart sshd

# Restore Docker config
sudo cp /var/backups/vps-setup/docker-daemon.json.backup /etc/docker/daemon.json
sudo systemctl restart docker

# Restore fail2ban config
sudo cp /var/backups/vps-setup/jail.local.backup /etc/fail2ban/jail.local
sudo systemctl restart fail2ban

# Restore UFW rules
sudo cp /var/backups/vps-setup/ufw-rules.backup /etc/ufw/user.rules
sudo ufw reload
```

### Step 3: Restart Services

```bash
# Start services in order
systemctl start fail2ban
systemctl start ufw
systemctl start docker
systemctl start xrdp

# Verify all started
systemctl is-active fail2ban docker xrdp
```

---

## Method 3: Git Revert (Code Issues)

If the issue is in playbook code:

```bash
# Check recent commits
git log --oneline -10

# Identify problematic commit
git show <commit-hash>

# Revert to previous working version
git revert <bad-commit-hash>

# Or reset to last known good commit
git reset --hard <good-commit-hash>

# Re-deploy
./setup.sh
```

---

## Method 4: Full System Restore (Last Resort)

If everything is broken, restore from snapshot:

### Option A: Cloud Provider Snapshot

```bash
# AWS
aws ec2 create-snapshot --volume-id <vol-id> --description "Pre-rollback"

# DigitalOcean
doctl compute snapshot create <droplet-id> --snapshot-name "pre-rollback"

# Linode
linode-cli linodes snapshot <linode-id> --label "pre-rollback"
```

### Option B: Manual Backup Restoration

```bash
# Stop all services
systemctl stop docker xrdp fail2ban

# Restore from backup
tar -xzf /var/backups/full-system-backup.tar.gz -C /

# Reboot
reboot
```

---

## Post-Rollback Actions

After successful rollback:

1. **Verify Services**
   ```bash
   ./tests/smoke-test.sh localhost
   ```

2. **Check Logs**
   ```bash
   # Check for errors
   journalctl -xe --since "10 minutes ago"

   # Check specific services
   journalctl -u docker -n 50
   journalctl -u xrdp -n 50
   ```

3. **Test RDP Connection**
   - Open Remote Desktop client
   - Connect to VPS IP:3389
   - Login with user credentials
   - Verify desktop loads

4. **Test Docker**
   ```bash
   docker run --rm hello-world
   docker ps
   docker compose version
   ```

5. **Document Incident**
   - What went wrong?
   - What was rolled back?
   - What needs to be fixed before retry?

---

## Rollback Validation Checklist

- [ ] All critical services running
- [ ] XRDP accepting connections
- [ ] Docker daemon responsive
- [ ] UFW firewall active
- [ ] fail2ban running
- [ ] SSH accessible
- [ ] User can login
- [ ] No critical errors in logs

---

## Prevention: Pre-Deployment Checklist

To avoid needing rollbacks:

- [ ] Run `molecule test` locally first
- [ ] Deploy to staging before production
- [ ] Run smoke tests after staging deploy
- [ ] Create backup before production deploy
- [ ] Deploy during low-traffic window
- [ ] Have rollback plan ready
- [ ] Monitor logs during deployment
- [ ] Wait 15 minutes to observe

---

## Backup Strategy

### Automated Backups

```bash
# Add to crontab
0 2 * * * /opt/vps-rdp-workstation/scripts/backup.sh

# backup.sh content
#!/bin/bash
DATE=$(date +%Y%m%d-%H%M%S)
tar -czf "/var/backups/vps-setup-${DATE}.tar.gz" \
    /etc/ssh/sshd_config \
    /etc/docker/daemon.json \
    /etc/fail2ban/jail.local \
    /etc/ufw/user.rules \
    /home/*/

# Keep only last 7 backups
find /var/backups -name "vps-setup-*.tar.gz" -mtime +7 -delete
```

### Manual Backup Before Deploy

```bash
# Create pre-deployment backup
./scripts/create-backup.sh production

# Verify backup
ls -lh /var/backups/vps-setup/
```

---

## Emergency Contacts

| Role | Contact | When to Call |
|------|---------|--------------|
| DevOps Lead | ops@example.com | Critical failures |
| Security Team | security@example.com | Security incidents |
| Infrastructure | infra@example.com | VPS issues |

---

## Common Rollback Scenarios

### Scenario 1: Docker Won't Start

```bash
# Check logs
journalctl -u docker -n 100

# Restore config
sudo cp /var/backups/vps-setup/docker-daemon.json.backup /etc/docker/daemon.json

# Restart
sudo systemctl restart docker
```

### Scenario 2: XRDP Not Accepting Connections

```bash
# Check port
ss -tlnp | grep 3389

# Restart service
sudo systemctl restart xrdp

# Check logs
journalctl -u xrdp -n 50
```

### Scenario 3: UFW Locked You Out

```bash
# From console/VNC (not SSH):
sudo ufw disable
sudo ufw allow 22/tcp
sudo ufw enable
```

### Scenario 4: User Can't Login

```bash
# Reset user password
sudo passwd username

# Check shell
grep username /etc/passwd

# Reset shell if needed
sudo chsh -s /bin/bash username
```

---

## Testing Rollback Procedure

**DO THIS IN STAGING FIRST!**

```bash
# 1. Deploy to staging
./scripts/deploy-staging.sh

# 2. Verify working
./tests/smoke-test.sh staging.example.com

# 3. Intentionally break something
ssh staging.example.com "sudo systemctl stop docker"

# 4. Execute rollback
ansible-playbook -i inventory/staging.yml playbooks/rollback.yml

# 5. Verify recovery
./tests/smoke-test.sh staging.example.com
```

---

## Rollback Success Criteria

Rollback is successful when:

1. ✅ All smoke tests pass
2. ✅ No critical services down
3. ✅ RDP connection works
4. ✅ Docker can run containers
5. ✅ Users can login
6. ✅ No error logs
7. ✅ Performance normal

---

## Post-Mortem Template

After rollback, document what happened:

```markdown
## Incident Report: [Date]

### Summary
Brief description of what went wrong

### Timeline
- 14:00 - Deployment started
- 14:15 - Issue detected
- 14:20 - Rollback initiated
- 14:30 - Rollback completed
- 14:45 - Verified recovery

### Root Cause
What caused the failure?

### Impact
- Services affected:
- Duration of outage:
- Users impacted:

### Resolution
How was it fixed?

### Action Items
1. [ ] Fix the issue
2. [ ] Add test to prevent recurrence
3. [ ] Update documentation
4. [ ] Improve monitoring

### Lessons Learned
What did we learn? How to prevent next time?
```

---

## Quick Reference Commands

```bash
# Check service status
systemctl status docker xrdp fail2ban ufw

# View recent logs
journalctl -xe --since "30 minutes ago"

# Restore from backup
cp /var/backups/vps-setup/*.backup /path/to/original

# Run rollback playbook
ansible-playbook playbooks/rollback.yml

# Verify with smoke tests
./tests/smoke-test.sh localhost

# Full service restart
systemctl restart docker xrdp fail2ban ssh

# Emergency UFW disable (console only!)
ufw disable
```

---

## Additional Resources

- [Ansible Playbook Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Systemd Service Management](https://www.freedesktop.org/software/systemd/man/systemctl.html)
- [Docker Troubleshooting](https://docs.docker.com/config/daemon/)
- [UFW Guide](https://help.ubuntu.com/community/UFW)

---

**Remember**:
- ⏱️ Time is critical - Don't debug during an outage, rollback first
- 📝 Document everything - Logs help prevent future issues
- 🧪 Test rollbacks in staging - Practice makes perfect
- 🔄 Always have a Plan B - If Ansible fails, know manual steps

**"In production, the only thing worse than a failure is a slow recovery."**
