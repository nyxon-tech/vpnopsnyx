# PasarGuard Runbook

**Sources:** https://github.com/PasarGuard/panel and https://github.com/PasarGuard/scripts  
**Trust:** `verified`, `official`; bootstrap scripts remain remote code execution.

## Preflight

Read `references/pasarguard.md`. Determine panel versus node role, database mode,
node name, transport ports, and control-plane reachability. Never reuse a node name
or paste node credentials into chat or logs.

## Install And Upgrade

The reviewed node command is:

```bash
sudo bash -c "$(curl -sL https://github.com/PasarGuard/scripts/raw/main/pg-node.sh)" @ install --name node-eu-1
```

Replace the example name deliberately. Inspect the script and its sourced libraries,
pin a commit when possible, and record generated services and files. Use current
upstream panel documentation for panel installation and database migrations.

## API, Backup, And Verification

Discover API behavior from the deployed version and protect node enrollment data.
Back up the database, application configuration, node definitions, certificates,
and service units. Verify node heartbeat, control-plane sync, listening sockets, and
real client traffic through the selected node.

## Troubleshooting And Rollback

Separate DNS/TLS, panel API, node enrollment, and data-path failures. If a node
upgrade fails, remove it from scheduling, restore prior service/config artifacts,
restart the pinned version, verify locally, then re-enable it.
