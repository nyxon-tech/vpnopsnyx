# BackPack Runbook

**Source:** https://github.com/AminMGMT/BackPack  
**Trust:** `verified-source`, `third-party`, `community`, `high-impact`

BackPack is a Go tunnel engine for Iran-to-origin deployments. Upstream documents
reverse tunnels, direct layer-3 tunnels, multiple TCP/UDP/WebSocket/ICMP carriers,
transport fallback, health checks, managed servers, monitoring, and backup/restore.

## Preflight

1. Record both servers, roles, routes, interfaces, ports, firewall rules, MTU, DNS,
   BackPack version, services, and an out-of-band management path.
2. Start with the Iran side for the documented reverse topology; confirm direction
   rather than assuming that product names imply client/server roles.
3. Treat security tokens, `backpack://` setup links, panel credentials, recovery
   codes, API tokens, TLS keys, Telegram settings, and backups as secrets.
4. Review the installer and pin a release when possible.

## Install Boundary

The upstream README currently documents this installer for both servers:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AminMGMT/BackPack/main/install.sh)
```

It is remote code execution. Download and inspect it first. Upstream states that
release archives are selected by architecture and checked against published SHA-256
values; independently record the selected version and checksum.

## Configure And Verify

- Configure Iran before kharej for a reverse tunnel and use the same transport and token.
- Keep the tunnel port distinct from user-facing forwarded ports.
- Enable UDP forwarding only when the transported service requires it.
- Use the built-in Status, Health Check, Link Test, and tunnel metrics.
- Verify sockets and counters on both ends, then test the real application through
  every advertised TCP/UDP port. A connected control path alone is insufficient.
- For direct layer-3 mode, verify routes, source addresses, MTU, and management reachability.

## Backup, Upgrade, And Rollback

Create and checksum a backup before changes; protect it because upstream backups may
contain tunnel configuration, panel settings, credentials, Telegram settings, TLS
material, and scheduled tasks. Preserve the previous binary, configuration, systemd
units, routes, and firewall state. On failure, stop new units, restore the recorded
state and prior release, reload systemd, and retest the original data path.
