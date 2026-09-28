# Changelog

All notable changes to VPNOpsNyx are documented here.

## Unreleased

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
