# Community Repository Review

Review date: 2026-09-27. This review used the complete public GitHub repository
listing for the eight requested profiles plus each available README. The complete
111-repository snapshot, including forks, archived projects, and unrelated work, is
in `registries/community-repositories.json`. This document highlights what changes
VPNOps decisions; it is not an endorsement or a security audit.

## AsanFillter

- `MarzPort`: Marzban-oriented port/network helper; inspect its shell workflow before use.
- `ov-panel`: fork of the OpenVPN client management panel; prefer the upstream `primeZdev/ov-panel` for provenance.
- `Playit-Launcher`: Linux launcher/manager for Playit.gg tunneling; third-party service dependency.
- `Remnawave-AutoSetup`: automated Remnawave panel/node deployment; high-impact remote installer.
- `WarpOnWarp`: archived; retain for detection/migration, not new deployment.
- `WatchGuard`: server/domain renewal tracking panel and Telegram bot; operational support tool, not a VPN panel.

## azavaxhuman

- `4x-ui`: forked Xray panel; distinguish it from official/upstream 3x-ui releases.
- `AutoSQL`: database helper with unclear scope; `unverified` until a task requires it.
- `Backuper`: forked backup automation; inspect retention, remote destinations, and secrets handling.
- `Bulk-Address-Changer`: bulk inbound address editor; back up panel data before use.
- `conflux`: many-to-one combination tool; third-party and task-specific.
- `DDS-Xray-Inbound-Generator`: browser-based Xray inbound generator; validate generated JSON against the installed core.
- `DDS-Xray-Routing-Editor`: Xray routing JSON editor; use schema validation before deployment.
- `gozargah.github.io`: forked project site; reference only.
- `IPTABLE-Tunnel-multi-port`: iptables forwarding/tunnel helper; high-impact firewall changes.
- `IPv6-TunnelBroker`: TunnelBroker IPv6 setup helper; verify delegated prefix, routes, and MTU.
- `Marzban-Reality-Generator`: Reality configuration generator with no README in the snapshot; `unverified`.
- `MarzbanInboundGenerator`: Marzban inbound generator; validate output and private-key handling.
- `Nodex`: unofficial 3x-ui node synchronization; do not treat as official 3x-ui.
- `ocserv-users-management`: forked ocserv/OpenConnect server management panel.
- `PhpLiteAdmin-On-Marzban`, `SQLiteWeb_Marzban`, `SQLiteWeb_XUI`: direct database administration helpers; expose only on trusted interfaces and back up first.
- `Quick_Warp_on_Warp`: WARP-on-WARP generator/scanner; Cloudflare account and ToS considerations apply.
- `VESSL`: forked certificate helper; Certbot remains the preferred documented baseline.
- `WUI`: archived WordPress/X-UI integration; detection/migration only.
- `Xray-docs-next`: forked Xray documentation; prefer current upstream docs.
- `Xray_ReverseTunnel`: reverse-tunnel builder; validate topology, authentication, and routing before use.

## ircfspace

- `cf-ip-ranges`, `cf2dns`, `gscanner`, and archived `scanner`: Cloudflare range/clean-IP discovery tools; scan results are observations, not durable endpoints.
- `DnsRefiner`: normalizes DNS subscription sources.
- `encodify`: reversible text/config encoding; not encryption and not a secret store.
- `endpoint`, `testUrl`: suggested WARP/MASQUE endpoints and test URLs; network-dependent.
- `fragment`: client/config helper for fragmented connections; validate client compatibility.
- `gconfig`: G-Core configuration updater; third-party service integration.
- `githubMirror`: mirrors GitHub releases to Telegram; supply-chain helper, not an authoritative release source.
- `iran-based`: curated Iran-origin connectivity methods; informational/community data.
- `location`, `tconfig`, archived `tvc`, `updater`: public config/list tooling; never treat third-party configs as trusted credentials.
- `masque-plus`: Cloudflare MASQUE/usque SOCKS launcher.
- `portal`: no README in the snapshot; `unverified`.
- `proxyReset`: Windows proxy reset utility; client troubleshooting tool.
- `shirokhorshid-cleanip`: no README in the snapshot; endpoint data only.
- `teleFeed`, `teleMirror`: Telegram content tools; adjacent, not infrastructure control.
- `tester`: V2Ray configuration tester; test results depend on location and time.
- archived `warpkey`: WARP key collector; do not use collected credentials.
- `warpplus`, `warpsub`: WARP client/subscription tooling; third-party and network-dependent.
- `XrayRefiner`, archived `XraySubRefiner`: normalize/merge Xray subscription sources; preserve source trust labels.

## primeZdev

- `Emergency-key`: emergency V2Ray subscription mechanism; review token exposure and cache behavior.
- `ov-doc`: official documentation for this maintainer's OV stack.
- `ov-node`: backend manager for `ov-panel`.
- `ov-panel`: OpenVPN client management panel.
- `whale-panel`: role-based dashboard for multiple X-UI panels; verify supported X-UI variants and API permissions.
- `TheWritter`: no README in the snapshot and no established VPNOps role; `out-of-scope`.

## ppouria

- `3xuiMirror`: 3x-ui mirror helper; verify release hashes against upstream.
- `Backuper`: forked backup automation.
- `Generate-Traffic`: traffic-generation tool; use only in controlled tests, never against third parties.
- `geo-templates`: Xray geo update template; validate source and update paths.
- `kabootar`: community proxy-related project; inspect code and deployment docs before use.
- archived `marzban-backup`: legacy Marzban backup importer; migration-only.
- `marzhelp`: Marzban database management bot; database backup and least privilege are mandatory.
- `Nabzram`: forked desktop client for Marzban connections.
- `Ourenus`, `rebecca-template`: subscription templates; sanitize injected values and generated links.
- `ping-tunnel`: community tunnel installer; high-impact networking tool.
- `Throne`: forked sing-box GUI client.
- `persian-encoder`: encoding utility, not encryption.
- Remaining repositories are Telegram libraries/apps, Jitsi, Hackintosh/driver projects, Steam tooling, or generic libraries and are retained as `out-of-scope` in the full registry.

## rezazoom

- `Abuse-Defender`: forked IP-blocking script; firewall and false-positive risk.
- `Marzban`: fork of the Marzban panel; prefer upstream for releases and documentation.
- `marzban-sub`: forked Marzban subscription component.
- `mirzabot`, `mirzaplus`: forked VPN sales bots for Marzban; payment, credential, and customer-data review required.
- `qoqnoos-template`: subscription page template for Marzban/Marzneshin.
- `sub-forward`: Marzban subscription forwarder; carefully protect origin subscription URLs.
- `SimplePhpDownloader`: generic downloader, adjacent only.
- Other repositories are bots, WordPress projects, date/data packages, or unrelated utilities and remain `out-of-scope` in the full registry.

## MHSanaei

- `3x-ui`: authoritative repository for the Sanaei 3x-ui project and installer.
- `HLS-Proxy-Worker`: Cloudflare Worker HLS proxy; separate from VPN panel operations.
- `mtg-multi`: forked multi-account MTProto proxy.
- `MHSanaei` and `sponsors`: profile/sponsorship metadata, retained as `out-of-scope`.

## erfjabplus

The public profile was reachable, but GitHub returned zero public repositories on
the review date. Do not infer private or deleted projects.
