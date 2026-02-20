# Upgrade Testing Guide

This document outlines the procedure for testing upgrades to the VPS RDP Workstation.

## Automated Upgrade Tests

We utilize standard Ansible playbook converging against existing state files to test idempotency and migrations.

### Testing Version Migrations

1. Deploy the previous version.
2. Checkout the new version branch.
3. Run `ansible-playbook -i inventory/staging.yml playbooks/main.yml`.
4. Run integration tests (`tests/integration-test.sh`).

### Data Migration

Ensure that any persistent volumes (like Docker Compose `/opt/monitoring`) are tested by simulating older configurations and applying the new roles.

To run an upgrade test locally via Molecule, you can use the Default scenario which inherently checks idempotence (that running the playbook twice makes zero changes). A true upgrade test starts from an older tag, but for now we rely on strict idempotency checks in CI.
