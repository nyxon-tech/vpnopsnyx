# VPNOpsNyx

![VPNOpsNyx network operations overview](assets/vpnopsnyx-hero.png)

AI skill for VPN, proxy, panel, node, tunnel, and network operations - built for Claude, Codex, ChatGPT, and other AI coding agents.

VPNOpsNyx is not a VPN protocol, tunnel implementation, or one-click panel fork. It is an operator skill: a structured knowledge base that helps AI agents inspect, plan, install, verify, troubleshoot, and safely document VPN/proxy infrastructure.

## What It Covers

- Panels: 3x-ui/Sanaei, PasarGuard node scripts, VPanel installer, Marzban, Marzneshin, Hiddify, and related panel patterns.
- Cores and protocols: Xray-core, sing-box, WireGuard, AmneziaWG, Hysteria2, TUIC, Trojan, VMess, VLESS, Shadowsocks, MTProto, HTTP/SOCKS, and Reality/TLS operations.
- Tunnels and relays: Backhaul, DNAT/nftables, GRE/GRE6/6TO4/SIT/IPIP/Geneve, WireGuard relay paths, SSH reverse tunnels, and Cloudflare DNS steering.
- Operations: health checks, data-path verification, certificate handling, node lifecycle, capacity, incident triage, migration, and rollback.
- Community research: a registry of public GitHub maintainers and repositories relevant to VPN/proxy tooling.

![VPNOpsNyx layered architecture](assets/vpnopsnyx-architecture.png)

## Install As A Skill

### Claude

```bash
git clone https://github.com/nyxon-tech/vpnopsnyx ~/.claude/skills/vpnopsnyx
```

### Codex

```bash
git clone https://github.com/nyxon-tech/vpnopsnyx ~/.codex/skills/vpnopsnyx
```

### Other AI Agents

Copy or clone this repository into the agent's skill/plugin directory and point the agent at `SKILL.md`. The supporting references and registries are intentionally plain Markdown and JSON so they are easy to load from any coding-agent runtime.

## Repository Map

- `SKILL.md` - agent entrypoint, safety rules, triage flow, and reference routing.
- `references/` - detailed operational guides for architecture, panels, tunnels, Cloudflare, incidents, capacity, filtering patterns, and node lifecycle.
- `docs/install-recipes.md` - verified and third-party install commands, with preflight and verification notes.
- `docs/sources.md` - source validation log and community profile review.
- `docs/community-review.md` - repo-by-repo review of VPNOps-relevant community projects.
- `docs/networking-recipes.md` - DNS, firewall, IPv4/IPv6, BBR, mirror, and hosts-file guidance.
- `docs/ecosystem-guide.md` - how agents distinguish panels, cores, VPNs, reverse tunnels, overlays, clients, and routing data.
- `registries/panels.json` - panel and panel-adjacent tools.
- `registries/cores.json` - VPN/proxy cores and protocol engines.
- `registries/tunnels.json` - tunnel, relay, and forwarding tools.
- `registries/tools.json` - supporting tools such as ACME, DNS, and optimizers.
- `registries/community.json` - public GitHub profiles and relevant public repositories from the community list.
- `registries/community-repositories.json` - complete snapshot of all 111 public repositories returned for the requested profiles.
- `registries/ecosystem.json` - verified master inventory of panels, control planes, cores, VPNs, reverse tunnels, overlays, clients, routing data, and installers.
- `assets/` - project artwork used by Markdown documentation.
- `templates/fleet-inventory.example.md` - private inventory template; never commit a filled-in copy.
- `metadata.json` - package metadata for non-Claude/Codex runtimes.

## Verification Policy

Only commands and links that were checked against public upstream locations are marked `verified`. Third-party installers and community scripts may still be useful, but the agent must treat them as remote code execution and review them before use. Anything not confirmed is labeled `unverified`, `deprecated`, or `third-party`.

This repository does not contain secrets, credentials, subscription links, API tokens, private keys, or production IP inventories.

## Safety Model

VPNOpsNyx assumes production VPN infrastructure can affect paying users. Agents using it should:

- stay read-only until the operator explicitly approves a change;
- never print or store credentials, private keys, tunnel tokens, or subscription links;
- prefer official upstream documentation and pinned versions;
- test real data flow, not only service status;
- record rollback steps for every change;
- label uncertain tools and community scripts clearly.

## License

MIT
