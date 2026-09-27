# Contributing to VPNOpsNyx

Thank you for helping improve an open, source-aware knowledge base for VPN and
network operations. Contributions from maintainers, operators, documentarians,
and community researchers are welcome.

## Ways to contribute

- Add a panel, core, protocol, tunnel, overlay, client, installer, or routing source.
- Correct a repository link, ownership label, deprecation status, or capability.
- Document a safe installation, upgrade, backup, verification, rollback, or
  troubleshooting procedure.
- Improve English or Persian documentation.
- Report a broken link, unsafe command, leaked secret, or stale recommendation.

## Contribution workflow

1. Fork `nyxon-tech/vpnopsnyx` into your GitHub account.
2. Create a focused branch from the latest `main`.
3. Make one coherent change and preserve the existing JSON schemas and Markdown style.
4. Validate every JSON file and check Markdown links and commands.
5. Commit with a clear message and open a Pull Request against `main`.

Keep your fork current through GitHub's **Sync fork** action or by fetching the
upstream repository before starting new work.

## Evidence requirements

- Link to the project's authoritative repository or documentation.
- Distinguish `official`, `third-party`, `community`, `unverified`, `legacy`, and
  `deprecated` sources.
- Do not mark a URL `verified` only because it returns HTTP 200. Review ownership,
  README, releases, and relevant executable code.
- Explain high-impact behavior such as firewall, routing, sysctl, DNS, package,
  systemd, Docker, certificate, or reboot changes.
- Prefer pinned releases, tags, commits, and checksums for production recipes.

## Safety and privacy

Never commit or paste:

- passwords, API tokens, SSH keys, TLS private keys, Reality keys, or WireGuard keys;
- subscription URLs, tunnel secrets, panel sessions, cookies, or bot tokens;
- production domains, IP inventories, customer records, traffic logs, or backups;
- copied installers or binaries when a maintained upstream link is sufficient.

Use placeholders in examples and include preflight, verification, and rollback
steps for operational changes. Do not submit instructions for unauthorized access,
credential theft, disruption, abuse, or concealment of harmful activity.

## Pull Request checklist

- [ ] The change is focused and uses the existing taxonomy.
- [ ] Source links are authoritative and reachable.
- [ ] Trust and lifecycle labels are accurate.
- [ ] Commands do not contain real credentials or infrastructure identifiers.
- [ ] High-impact commands include risk, verification, and rollback notes.
- [ ] JSON parses successfully and Markdown links are correct.
- [ ] English documentation is updated; Persian translation is updated when relevant.

By contributing, you agree that your contribution is provided under this
repository's MIT License.
