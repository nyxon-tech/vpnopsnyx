# Source Review

Review date: 2026-09-27

This file records what was checked before adding commands and community references. The review confirms public availability, not security, project quality, or suitability for any particular legal context.

## Verified User-Provided Links

| Item | URL | Result | Label |
|---|---|---|---|
| VPNOpsNyx repo | https://github.com/nyxon-tech/vpnopsnyx | Repository cloned successfully. | `verified` |
| 3x-ui installer | https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh | HTTP 200 and official README documents the same quick-start command. | `verified`, `official` |
| PasarGuard node script | https://github.com/PasarGuard/scripts/raw/main/pg-node.sh | Redirects to raw GitHub and returns HTTP 200. Script validates `--name` and fetches shared libraries. | `verified` |
| VPanel installer | https://raw.githubusercontent.com/vpaneladmin/vpanel-bash/main/vpanel-installer.sh | HTTP 200. Script is third-party and downloads additional zip payload. | `verified`, `third-party` |
| Azumi67 tunnel repo | https://github.com/Azumi67/6TO4-GRE-IPIP-SIT | Repository README available. | `verified`, `third-party`, `community` |
| Certbot commands | `apt-get install certbot`, `certbot certonly`, `certbot renew --dry-run` | Standard certbot workflow; no project-specific secret included. | `verified` |

## Community GitHub Profiles

These profiles were checked through public GitHub metadata and recent public repositories. Include them as community discovery sources, not as endorsements.

| Profile | Public signal from review | Label |
|---|---|---|
| https://github.com/erfjabplus | Public profile exists, no public repositories reported by the API at review time. | `community`, `limited-public-data` |
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

