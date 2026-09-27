# Source Review

Review date: 2026-09-27

This file records what was checked before adding commands and community references. The review confirms public availability, not security, project quality, or suitability for any particular legal context.

## Ecosystem Inventory Review

The user-supplied panel and tunnel inventory was normalized into
`registries/ecosystem.json`. Repository paths were checked directly against GitHub
where possible. Most listed projects resolved. Three supplied paths need special
treatment:

- `https://github.com/iran-v2ray/rules` did not resolve during direct review and
  remains `unavailable-at-review`; the reachable Iran-focused rules source is
  `https://github.com/Chocolate4U/Iran-v2ray-rules`.
- `https://github.com/xtaci/kcptun` was visible in GitHub-indexed source results
  but did not complete the direct Git check; it is `source-visible` rather than
  fully verified in this snapshot.
- `https://github.com/trailofbits/algo` was visible through its current official
  GitHub documentation but did not complete the direct Git check. Upstream also
  states that Algo is a privacy VPN, not a censorship-circumvention system.

Rebecca, EylanPanel/OVPN Manager, and GoGuard were mentioned without an
unambiguous upstream repository. They remain `unverified` with no invented URL.

## Verified User-Provided Links

| Item | URL | Result | Label |
|---|---|---|---|
| VPNOpsNyx repo | https://github.com/nyxon-tech/vpnopsnyx | Repository cloned successfully. | `verified` |
| 3x-ui installer | https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh | HTTP 200 and official README documents the same quick-start command. | `verified`, `official` |
| PasarGuard node script | https://github.com/PasarGuard/scripts/raw/main/pg-node.sh | Redirects to raw GitHub and returns HTTP 200. Script validates `--name` and fetches shared libraries. | `verified` |
| VPanel installer | https://raw.githubusercontent.com/vpaneladmin/vpanel-bash/main/vpanel-installer.sh | HTTP 200. Script is third-party and downloads additional zip payload. | `verified`, `third-party` |
| Azumi67 tunnel repo | https://github.com/Azumi67/6TO4-GRE-IPIP-SIT | Repository README available. | `verified`, `third-party`, `community` |
| Azumi67 Backhaul script | https://github.com/Azumi67/Backhaul_script | Repository and installer are reachable; installer downloads a release-hosted Python manager. | `verified`, `third-party`, `community` |
| Paqet Tunnel Manager | https://github.com/behzadea12/Paqet-Tunnel-Manager | Repository and manager script are reachable; it changes sysctl, iptables, limits, and systemd. | `verified`, `third-party`, `community`, `high-impact` |
| Musixal Rathole v1/v2 | https://github.com/Musixal/rathole-tunnel | Both user-provided installer URLs return HTTP 200. Scripts modify systemd, firewall state, and `/etc/hosts`. | `verified`, `third-party`, `community`, `high-impact` |
| OPIran VPS Optimizer | https://github.com/opiran-club/VPS-Optimizer | Installer is reachable; it can change sysctl, DNS, APT mirrors, kernel packages, hosts entries, and reboot. | `verified`, `third-party`, `community`, `high-impact` |
| Ubuntu mirror selector gist | https://gist.github.com/dev-ir/16e2be52370f21fb8dd1baad87818883 | Gist exists and raw script is reachable; it rewrites Ubuntu APT source URLs. | `verified`, `third-party`, `community` |
| DaggerConnect | https://github.com/itsFLoKi/DaggerConnect | Repository, installer, and releases are reachable. The supplied 4.2.x notice was not found in reviewed public release metadata. | `verified-source`, `third-party`, `community`; notice `unverified` |
| BackPack | https://github.com/AminMGMT/BackPack | Repository and installer are reachable. Upstream documents checksum-verified release downloads, reverse/direct modes, health checks, backup, and rollback. | `verified-source`, `third-party`, `community`, `high-impact` |
| Sanitized operator field notes | `docs/field-observations-2026-09.md` | Observations from one multi-panel fleet; no identities or addresses included. External foundations were checked separately. | `operator-observed`, `limited-scope`, `sanitized` |
| IP lookup page | https://whatismyipaddress.com/ip/ | Public URL supplied by user; automated review received HTTP 403. Not needed for automation. | `third-party`, `manual-only` |
| Mahsa Alert | https://mahsaalert.com | Site returned HTTP 200, but no stable VPNOps integration contract was established. | `verified-reachable`, `third-party`, `informational` |
| Certbot commands | `apt-get install certbot`, `certbot certonly`, `certbot renew --dry-run` | Standard certbot workflow; no project-specific secret included. | `verified` |

## Community GitHub Profiles

These profiles were checked through the complete public-repository listing returned by GitHub on the review date. The snapshot contains 111 repositories: AsanFillter 6, azavaxhuman 22, ircfspace 28, MHSanaei 5, ppouria 24, primeZdev 6, and rezazoom 20. GitHub returned zero public repositories for erfjabplus. See `registries/community-repositories.json` for every repository and `docs/community-review.md` for the VPNOps-relevant subset. Inclusion is discovery, not endorsement.

| Profile | Public signal from review | Label |
|---|---|---|
| https://github.com/erfjabplus | Public profile existed during the initial review with no public repositories; it later returned HTTP 404. Attribution is retained. | `community`, `limited-public-data`, `unavailable-at-review` |
| https://github.com/AsanFillter | Public repositories include Playit-Launcher, WatchGuard, Remnawave-AutoSetup, MarzPort, ov-panel, WarpOnWarp. | `community` |
| https://github.com/rezazoom | Public repositories include subscription and Marzban-related tooling such as qoqnoos-template, sub-forward, mirzaplus, and Abuse-Defender. | `community` |
| https://github.com/azavaxhuman | Public repositories include VESSL, IPTABLE-Tunnel-multi-port, DDS-Xray-Inbound-Generator, DDS-Xray-Routing-Editor, Nodex, and ocserv-users-management. | `community` |
| https://github.com/ircfspace | Public repositories include cf2dns, masque-plus, tconfig, XrayRefiner, and Iran-based connectivity lists. | `community` |
| https://github.com/primeZdev | Public repositories include ov-panel, ov-node, whale-panel, Emergency-key, and ov-doc. | `community` |
| https://github.com/ppouria | Public repositories include Backuper, kabootar, 3xuiMirror, ping-tunnel, and marzhelp. | `community` |
| https://github.com/MHSanaei | Public repositories include 3x-ui, HLS-Proxy-Worker, mtg-multi, and profile/sponsor repos. | `community`, `official-for-3x-ui` |

## Unverified Or Not Included As Commands

- Any installer command not tied to an upstream URL in this repository is not included.
- Any credential, panel login path, token, subscription link, or production IP was intentionally excluded.
- Community repositories are listed as discovery sources only. Agents must inspect their README, license, issues, and scripts before use.
- A reachable raw script is not considered safe merely because it returned HTTP 200.
- The fixed GitHub hosts override `185.199.108.133 raw.githubusercontent.com` is retained only as a known unsafe/stale pattern; do not recommend it.
- The user-provided DaggerConnect 4.2.1-4.2.3 notice remains `unverified` because reviewed public releases used a different version line.
- The port/name string beginning `IRAN8080,...` has no confirmed schema or upstream source and was not turned into an executable recipe.
