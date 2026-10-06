# Changelog

All notable changes to VPNOpsNyx are documented here.

## Unreleased

- Added: subscription-domain path check with a real download (`relay/panel_path_check.sh`, `pasarguard.md` §16), inbound-to-group audit and adding a tunnel inbound/host/groups through the API (`panel/inbound_groups.py`, `pasarguard.md` §18), SNI router for two services on port 443 (`tunnels.md` §18), IP-range and IP-change checklist (§17), backhaul RSS vs bloat, empty DNS names and NXDOMAIN caching, SSH key login disabled on provider images, test-file expiry and relay quota signatures, incidents 34–39. READMEs list lessons 8–12.
- Added persistent GRE relay links (`relay/greunit.sh`, `tunnels.md` §16), relay IP rotation behaviour (§17), panel/subscription domain behind relays and failed-login blocking (`pasarguard.md` §16–17), new filtering signatures, incidents 28–33, and October field notes. One dialed xDi link per exit re-confirmed, including exits shared by two brands; dead links burn CPU.
- Added scripts: `relay/greunit.sh`, `relay/forward_audit.sh`, `panel/auth_failures.sh`, `panel/blocklist.sh`. `relay/gretest.sh` rejects link indexes above 63. READMEs (all languages) list the October field lessons.
- Added October 2026 field lessons: reverse xDi links (exit dials relay) and their survival, one dialed xDi link per exit, next-day re-verification, moving PasarGuard nodes to a new IP (strict TLS, new certificates), slow panel-to-node links, relay quota outages, panel and bot paths through relays, new filtering signatures, server-migration checklist, incidents 17-26.
- Added scripts: `node/bpstatus.sh`, `local/bp_matrix.sh`, `panel/node_edit.sh`, `panel/node_status.py`, `node/node_cert.sh`, `local/dns_brand_audit.sh`. `bptest.sh`/`bplink.sh` accept `BIN` for a second BackPack version; fixed `nettest.sh` deleting its own test file when restarted.
- `relay/dnat.sh` loads `nf_conntrack` at boot, re-applies conntrack limits from the DNAT unit (they were silently lost after reboots) and sizes `nf_conntrack_max` to RAM. READMEs list `scripts/` and the October field notes.
- Added sanitized operator helper scripts under `scripts/` (real-user traffic per relay, health snapshot, per-node usage, relay data matrix, UDP survival, token-safe Cloudflare DNS, reviewed DNAT with dry-run, BackPack test/persistent links, GRE/SIT tests, domestic mirror selection, safe upgrade, reboot verification, provider test file).
- Added weekly read-only Issue and Pull Request reporting.
- Added safe fast-forward synchronization for the personal fork.
- Documented supported GitHub distribution, registry status, and release gates.
- Recorded the latest maintenance review without claiming unperformed infrastructure tests.

## [0.6.0] - 2026-09-28

### Added

- Evidence-gated lab matrix for API, restore, and data-path tests across six panels.
- Anonymized datacenter benchmark schema and operating procedure.
- CI validation that prevents unsupported `pass` states without versioned evidence.
- Community submission form for sanitized lab and benchmark findings.
- Updated source-review and agent routing for the evidence program.

### Changed

- Bumped package metadata to `0.6.0`.

## [0.5.0] - 2026-09-27

### Added

- Dedicated runbooks for 3x-ui, Marzban, PasarGuard, Remnawave, Hiddify, and S-UI.
- Dedicated runbooks for Backhaul, rathole, Paqet, GRE-family tunnels, WireGuard, FRP, and DaggerConnect.
- GitHub Actions for structural validation, JSON validation, link checking, and secret-pattern checks.
- Monthly source-review workflow and maintainer checklist.
- Cross-agent compatibility guidance for Codex, Claude, ChatGPT-compatible, and generic coding agents.
- Initial release documentation and a portable dependency-free validation script.
- Security policy, structured issue form, pull request checklist, and CODEOWNERS.
- Version-specific API probing and restore-drill evidence matrix for major panels.
- Verified BackPack source entry, dedicated operational runbook, registry metadata, and multilingual README links.
- Sanitized field observations covering test vantage points, Reality test limits, tunnel/provider behavior, PasarGuard reboot and port-collision incidents, capacity, safe upgrades, certificates, and Cloudflare token handling.

### Changed

- Expanded `SKILL.md` routing so agents load product-specific operational guidance.
- Bumped package metadata to `0.5.0`.

## [0.4.0] - 2026-09-27

- Added English, Persian, Russian, and Simplified Chinese documentation.
- Added OpenAI/Codex interface metadata, ecosystem registries, community attribution,
  visual assets, verified recipes, and safety guidance.

[0.5.0]: https://github.com/nyxon-tech/vpnopsnyx/releases
[0.6.0]: https://github.com/nyxon-tech/vpnopsnyx/releases
[0.4.0]: https://github.com/nyxon-tech/vpnopsnyx/commits/main
