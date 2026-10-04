# Operator Scripts

Small, dependency-light helpers extracted from real fleet operations. They contain no
addresses, names, or secrets; every target comes from arguments or environment
variables. Read each script before running it. The header of every file documents its
inputs, where it runs, and how to undo it.

`validate.py` and `validate_evidence.py` in this directory are repository CI checks, not
operator tools.

## Read-only checks

| Script | Runs on | Purpose |
|---|---|---|
| `node/realuse.sh` | exit | Real-user bytes and RTT per relay on one inbound port, from `ss -ti`. Separates "users connect but get no data" from a healthy path. |
| `node/health.sh` | any host | One-line snapshot: CPU busy/steal, NIC rx/tx, TCP retransmits, free download headroom, RAM, disk, failed units, inactive tunnel/DNAT units, stopped containers. |
| `panel/node_usage.py` | PasarGuard panel container | Users and GB per node per hour (MySQL/MariaDB or PostgreSQL), in a read-only transaction. |
| `relay/data_matrix.sh` | an in-country probe that is not one of the relays | TLS/Reality fallback test of every relay × location port. Proves the listener path only (see `SKILL.md`, Real Data Test). |
| `relay/udp_survival.py` | probe and target | Whether a single UDP flow survives past its first packets, before offering WireGuard, KCP, or QUIC on a path. |
| `local/cf.sh` | operator workstation | Cloudflare DNS listing and A-record add/delete. The token is read from a mode-600 file and never appears in argv or history. |
| `node/bpstatus.sh` | relay or exit | Every active BackPack link with its role, carrier, peer and packet loss to the peer. A unit can be `active` while the path is dead. |
| `panel/node_status.py` | PasarGuard panel container | Every node with address, port, status and the panel's last error message (certificate, port-bind, timeout errors). |
| `local/dns_brand_audit.sh` | operator workstation | Lists A records in one Cloudflare account that point at another brand's relays. |
| `relay/forward_audit.sh` | relay | Every port the relay forwards (nftables DNAT, Backhaul and BackPack maps) and its target; flags ports of another brand (`FORBID`). |
| `panel/auth_failures.sh` | panel host | Failed and successful admin logins per source address from the panel access log. |

## Changes (operator approval required)

| Script | Runs on | Purpose |
|---|---|---|
| `relay/dnat.sh` | relay | Dedicated nftables DNAT table plus boot unit. `DRYRUN=1` prints the candidate, a diff, and an `nft -c` check without applying. |
| `node/bptest.sh` | relay and exit | Temporary BackPack L3 link as a transient unit with a fixed lifetime, for measurement. |
| `node/bplink.sh` | relay and exit | Persistent BackPack L3 link. The shared token is read from stdin. |
| `relay/gretest.sh` | exit and relays | Temporary GRE and SIT/6to4 links that remove themselves; measures what a provider really passes. |
| `relay/iran_mirror.sh` | in-country relay | Measures domestic Ubuntu mirrors, backs up the sources file, switches, and restores it if `apt-get update` fails. |
| `node/apt_upgrade_safe.sh` | any host | Detached upgrade with Docker packages held, configs kept, no automatic restarts or reboot. |
| `local/reboot_verify.sh` | operator workstation | Reboots one host, waits for a new `boot_id`, then prints failed units, inactive enabled tunnel/DNAT units, NAT tables, forwarding, and containers. |
| `node/nettest.sh` | exit | Public 100 MB test file for a provider's support team, auto-removed after 72 hours. Use only in an approved window. |
| `local/bp_matrix.sh` | operator workstation | Measures many temporary xDi links, forward or reverse, one at a time, then removes them. |
| `panel/node_edit.sh` | operator workstation -> panel host | Changes one node's address, port, stored certificate or timeouts through the panel's own API; only that node reconnects. |
| `node/node_cert.sh` | node host | New self-signed node certificate for a new IP (old pair kept), restarts the node; store the new certificate in the panel. |
| `relay/greunit.sh` | relay and exit | Persistent GRE link as a oneshot unit (one run per end); pair with `relay/dnat.sh`. |
| `panel/blocklist.sh` | panel host | Persistent source-IP blocklist in its own nftables table (`ACTION` = `list`, `add` or `del`). |

## Rules

- Stay read-only until the operator approves a change, and state the rollback first.
- Never pass tokens as arguments; the scripts that need one read it from a file or stdin.
- After any change, verify real data flow (`node/realuse.sh` on the exit), not only unit status.
- Treat the thresholds in script comments as `operator-observed` examples, not universal values.
