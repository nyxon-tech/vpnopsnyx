# VPNOpsNyx

[English](README.md) | [فارسی](README.fa.md) | [Русский](README.ru.md) | [简体中文](README.zh-CN.md)

![VPNOpsNyx network operations overview](assets/vpnopsnyx-hero.png)

AI skill for VPN, proxy, panel, node, tunnel, and network operations - built for Claude, Codex, ChatGPT, and other AI coding agents.

VPNOpsNyx is not a VPN protocol, tunnel implementation, or one-click panel fork. It is an operator skill: a structured knowledge base that helps AI agents inspect, plan, install, verify, troubleshoot, and safely document VPN/proxy infrastructure.

## What It Covers

- Panels: 3x-ui/Sanaei, PasarGuard node scripts, VPanel installer, Marzban, Marzneshin, Hiddify, and related panel patterns.
- Cores and protocols: Xray-core, sing-box, WireGuard, AmneziaWG, Hysteria2, TUIC, Trojan, VMess, VLESS, Shadowsocks, MTProto, HTTP/SOCKS, and Reality/TLS operations.
- Tunnels and relays: Backhaul, [BackPack](https://github.com/AminMGMT/BackPack), Rathole, Paqet, FRP, DaggerConnect, DNAT/nftables, GRE/GRE6/6TO4/SIT/IPIP/Geneve, WireGuard relay paths, SSH reverse tunnels, and Cloudflare DNS steering.
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
- `agents/openai.yaml` - OpenAI/Codex skill interface metadata.
- `guides/panels/` - dedicated runbooks for major panels.
- `guides/tunnels/` - dedicated operational runbooks for major tunnel families.
- `.github/workflows/` - structure, JSON, link, secret-pattern, and monthly source checks.
- `docs/agent-compatibility.md` - Codex, Claude, and generic agent integration.
- `docs/maintenance.md` - periodic source and registry review procedure.
- `docs/api-restore-validation.md` - versioned API probes and repeatable restore-drill evidence.
- `docs/field-observations-2026-09.md` - sanitized operator evidence with explicit limits on generalization.
- `docs/lab-and-benchmark-program.md` - auditable panel restore/API and datacenter measurement program.
- `SECURITY.md` and `.github/` - safe reporting, issue, review, and ownership policy.
- `CHANGELOG.md` - release history.

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

## Community Acknowledgements

VPNOpsNyx recognizes the maintainers and community members whose public work has
helped people operate VPN, proxy, routing, subscription, and anti-censorship
infrastructure. Their repositories informed the community registry and source
review:

- [erfjabplus](https://github.com/erfjabplus)
- [AsanFillter](https://github.com/AsanFillter)
- [rezazoom](https://github.com/rezazoom)
- [azavaxhuman](https://github.com/azavaxhuman)
- [ircfspace](https://github.com/ircfspace)
- [primeZdev](https://github.com/primeZdev)
- [ppouria](https://github.com/ppouria)
- [MHSanaei](https://github.com/MHSanaei)

We also thank the maintainers whose panels, tunnels, and operational tools are
referenced throughout VPNOpsNyx:

- [Azumi67](https://github.com/Azumi67)
- [PasarGuard](https://github.com/PasarGuard)
- [vpaneladmin](https://github.com/vpaneladmin)
- [Gozargah](https://github.com/Gozargah)
- [marzneshin](https://github.com/marzneshin)
- [hiddify](https://github.com/hiddify)
- [remnawave](https://github.com/remnawave)
- [alireza0](https://github.com/alireza0)
- [Musixal](https://github.com/Musixal)
- [behzadea12](https://github.com/behzadea12)
- [opiran-club](https://github.com/opiran-club)
- [itsFLoKi](https://github.com/itsFLoKi)
- [AminMGMT](https://github.com/AminMGMT)

Thank you to everyone building and documenting tools that help keep the internet
open and accessible. Inclusion is recognition and source attribution, not a
security endorsement. See `docs/community-review.md` and the community registries
for repository-level notes.

## Fork and Contribute

**Fork VPNOpsNyx and help improve the shared knowledge base.** Contributions are
welcome for new panels, tunnels, verified install procedures, safer rollback
steps, troubleshooting cases, source corrections, translations, and documentation.

1. Click **Fork** at the top of this repository.
2. Create a branch in your fork.
3. Make the change and include authoritative source links.
4. Open a Pull Request back to `nyxon-tech/vpnopsnyx`.

Read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting. Please never include
credentials, private keys, subscription URLs, production IP inventories, or user
data.

## License

MIT
