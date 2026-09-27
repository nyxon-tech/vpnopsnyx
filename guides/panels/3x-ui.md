# 3x-ui Runbook

**Source:** https://github.com/MHSanaei/3x-ui  
**Trust:** `verified`, `official`  
**Scope:** Xray panel installation, lifecycle, database backup, and diagnosis.

## Preflight

1. Confirm a supported Linux distribution, root access, free ports, DNS, and time sync.
2. Record the current 3x-ui and Xray versions, listening ports, firewall rules, and certificate paths.
3. Check upstream release notes and download URLs. Do not assume `master` is immutable.
4. Take a provider snapshot in addition to an application backup.

## Install And Upgrade

The upstream bootstrap currently documented by VPNOpsNyx is:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
```

Treat it as remote code execution: download and inspect it first, then use the
upstream menu for installation or upgrade. For production, prefer a reviewed,
pinned release. Never overwrite an existing deployment before exporting its
database and recording the installed binary versions.

## API Boundary

Discover the API base path and authentication behavior from the installed version;
they can change. Use a dedicated least-privilege account where supported, keep
cookies/tokens outside logs, and test read-only list/status calls before writes.
Never commit exported subscriptions or inbound credentials.

## Backup And Restore

- Export the panel database and configuration using the installed panel's supported tooling.
- Copy the Xray configuration, certificates, and any custom systemd overrides separately.
- Record ownership and permissions without printing secret contents.
- Restore into an isolated host first; verify login, inbound count, expiry data, and one test client.

## Verification

Check the panel listener, Xray process, certificate chain, firewall exposure, and a
real client data path. A healthy web UI alone does not prove proxy traffic works.

## Troubleshooting And Rollback

- Login failure: verify base path, time, reverse proxy headers, and database health.
- Inbound failure: compare panel-generated Xray config with the last known-good copy.
- Upgrade failure: collect service logs, restore the snapshot/database, reinstall the
  previous pinned version, and retest one inbound before reopening traffic.
