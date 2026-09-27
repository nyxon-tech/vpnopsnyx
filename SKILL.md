---
name: vpnopsnyx
description: >
  Operate, install, verify, and troubleshoot VPN/proxy panels, nodes, tunnels, relays,
  cores, subscriptions, SSL, DNS, and network paths for production VPN infrastructure.
  Use when an operator asks about 3x-ui/Sanaei, PasarGuard, VPanel, Marzban, Marzneshin,
  Hiddify, Xray, sing-box, WireGuard, Reality, Backhaul, GRE/6TO4/SIT/IPIP/Geneve,
  Cloudflare DNS, relay fleets, server optimization, or Persian VPN operations terms
  such as پنل، نود، تانل، رله، سرور ایران، سرور خارج، کانفیگ، ساب، فیلتر، SSL.
license: MIT
metadata:
  short-description: AI skill for VPN and network operations
  project: VPNOpsNyx
  repository: https://github.com/nyxon-tech/vpnopsnyx
---

# VPNOpsNyx

VPNOpsNyx is an AI-agent skill for VPN, proxy, panel, node, tunnel, and network operations. It is meant for Claude, Codex, ChatGPT, and other coding agents that help an operator manage production VPN infrastructure.

It is not itself a VPN, tunnel, or panel. It is an operating guide and source registry that helps an agent choose safe checks, installation recipes, verification steps, and rollback plans.

## Operating Model

Assume the operator may run a paid VPN/proxy service where one bad command can disconnect many users. Work in this order:

1. Identify the target: panel, core, node, relay, tunnel, DNS record, certificate, subscription path, or server optimizer.
2. Read the relevant reference or registry before proposing commands.
3. Classify every external script as `official`, `third-party`, `community`, `unverified`, or `deprecated`.
4. Stay read-only until the operator explicitly approves a change.
5. Verify by real data flow after any networking change. Service status alone is not proof.
6. Report what changed, what was verified, what remains uncertain, and how to roll back.

## Hard Safety Rules

- Never print, commit, or store panel passwords, API tokens, Reality private keys, WireGuard private keys, tunnel tokens, subscription URLs, Cloudflare tokens, SSH keys, or production inventories.
- Never invent credentials, domains, IPs, ports, panel paths, or usernames.
- Do not run remote installers blindly. Fetch/read the script or point the operator to review it, then run only the verified upstream URL or a pinned commit/tag when available.
- Do not restart panels, cores, tunnels, Docker stacks, DNS, or firewall rules without explicit operator approval and a rollback note.
- Treat `curl | bash`, `wget | bash`, and GitHub raw scripts as remote code execution.
- Prefer key-only SSH. Do not ask the agent to type passwords into chat.
- For production changes, preserve old values in the report so the operator can undo them.

## Source Trust Labels

Use these labels in plans and docs:

| Label | Meaning |
|---|---|
| `verified` | URL, repository, or command was checked against a public upstream source. |
| `official` | Maintained by the project or organization that owns the tool. |
| `third-party` | Useful but not owned by the upstream panel/core project. Review before use. |
| `community` | Public community project/profile. Do not imply endorsement. |
| `unverified` | Mentioned by a user or found indirectly, but not confirmed enough for automation. |
| `deprecated` | Known to be stale, superseded, or unsafe for new use. |

## Fast Routing

| Need | Read |
|---|---|
| Install commands and preflight checks | `docs/install-recipes.md` |
| Validated sources and community profiles | `docs/sources.md` |
| Panels and panel-adjacent projects | `registries/panels.json` |
| Cores, engines, and supported protocols | `registries/cores.json` |
| Tunnel and relay methods | `registries/tunnels.json` |
| SSL, DNS, optimization, and support tooling | `registries/tools.json` |
| Community GitHub profiles and public repos | `registries/community.json` |
| Relay-fleet architecture and port planning | `references/architecture.md` |
| Iran filtering/DPI diagnosis | `references/iran-filtering.md` |
| Backhaul, DNAT, FOU, SSH reverse, WireGuard paths | `references/tunnels.md` |
| PasarGuard internals and node behavior | `references/pasarguard.md` |
| Panel setup and API patterns | `references/panels.md` |
| Cloudflare DNS operations | `references/cloudflare.md` |
| Node lifecycle, migration, retirement | `references/node-lifecycle.md` |
| Capacity, bandwidth, CPU steal, conntrack | `references/capacity.md` |
| Real incident patterns | `references/incidents.md` |

## Verified Commands From Current Source Review

These commands are documented as known upstream/user-requested recipes, not as permission to execute them. Before running, review the linked script, pin a version or commit when possible, and confirm the target OS.

System update:

```bash
apt-get update -y && apt-get upgrade -y
```

3x-ui/Sanaei official installer:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
```

PasarGuard node installer script:

```bash
sudo bash -c "$(curl -sL https://github.com/PasarGuard/scripts/raw/main/pg-node.sh)" @ install --name node-eu-1
```

VPanel installer download and run:

```bash
wget -O vpanel-installer.sh https://raw.githubusercontent.com/vpaneladmin/vpanel-bash/main/vpanel-installer.sh
chmod +x vpanel-installer.sh
sudo ./vpanel-installer.sh
```

Certbot standalone certificate:

```bash
apt-get install certbot -y
certbot certonly --standalone --agree-tos --register-unsafely-without-email -d yourdomain.com
certbot renew --dry-run
```

Certificate paths:

```text
/etc/letsencrypt/live/YOURDOMAIN.COM/fullchain.pem
/etc/letsencrypt/live/YOURDOMAIN.COM/privkey.pem
```

The Azumi67 `6TO4-GRE-IPIP-SIT` tunnel project is confirmed as a public third-party/community tunnel manager. Read `registries/tunnels.json` and the upstream README before using it.

## Real Data Test

For Xray/Reality-style TCP paths, a TLS request through the advertised relay and location port is more meaningful than checking that a service is active:

```bash
curl -s -m 8 --resolve www.cloudflare.com:PORT:RELAY_IP -o /dev/null \
  -w '%{http_code} %{time_total}s\n' https://www.cloudflare.com:PORT/
```

Any HTTP status usually means bytes flowed through the path. `000` means the path accepted no useful data or timed out. Use an SNI/domain that matches the inbound's fallback behavior.

## Reporting Shape

When answering operators, especially in Persian, keep commands and paths unchanged but explain plainly:

- status: what is healthy, degraded, or broken;
- evidence: source links, command output, or data test results;
- risk: who is affected and what may disconnect users;
- change: exact old value to new value, with rollback;
- uncertainty: anything labeled `third-party`, `community`, or `unverified`.

## Persian Glossary

| Persian | Meaning |
|---|---|
| پنل | management panel |
| نود / سرور خارج | exit node / foreign server |
| رله / سرور ایران | relay / in-country server |
| تانل / تونل | tunnel |
| کانفیگ | client config |
| ساب / اشتراک | subscription link |
| دایرکت | direct config to the exit node |
| فیلتر / آی پی بسته شده | filtering or destination-IP block |
| اس اس ال | TLS certificate / SSL |
| آپدیت و آپگرید | OS package update and upgrade |

Keep production inventories in private files based on `templates/fleet-inventory.example.md`; never commit filled inventories.
