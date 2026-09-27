# Ecosystem Guide

![VPNOpsNyx layered architecture](../assets/vpnopsnyx-architecture.png)

VPNOpsNyx separates projects by operational role. Do not call every item a VPN
or manage every item through the same interface.

## Panels and control planes

Panels own users, inbounds, subscriptions, quotas, expiry, nodes, and sometimes
billing. Prefer a documented API over direct database edits. Before automation,
identify the exact panel family and version because similarly named x-ui forks
can have incompatible schemas and endpoints.

- Xray families: 3x-ui, PasarGuard, Marzban, Remnawave, x-ui, TX-UI, Xray-UI,
  CELERITY, and Marzban-derived systems.
- sing-box families: S-UI and panels that explicitly expose sing-box objects.
- Multi-core/multi-VPN families: VPN-UI and Nova Server.
- WireGuard families: wg-easy, WGDashboard, wireguard-ui, swgPanel, and related
  controllers.

Treat Marzneshin and Remnawave as control planes when they manage separate node
agents or backends. Treat MikroTik RouterOS as a network platform, not a panel.

## Cores and protocol implementations

Cores execute traffic policy and protocol state. Manage them through validated
configuration, service lifecycle, and data-path tests. Xray-core, V2Ray-core,
sing-box, Mihomo, WireGuard, Hysteria 2, TUIC, Juicity, Shadowsocks, Trojan, and
NaiveProxy belong here. A panel may embed one or more cores but does not make
those cores interchangeable.

## Reverse tunnels and forwarding

FRP, rathole, Chisel, GOST, bore, kcptun, udp2raw, Backhaul, Paqet, GRE, IPIP,
SIT, Geneve, DNAT, and SSH reverse tunnels solve reachability or forwarding
problems. They are not user-management panels. Record direction, listener,
transport, authentication, MTU, firewall changes, service units, and rollback.

## Overlay and remote-access systems

NetBird, Netmaker, Headscale, Tailscale, Firezone, Defguard, Pritunl, PiVPN,
OpenVPN, WireGuard, and IPsec/IKEv2 provide device or network access. Their ACL,
identity, peer, and route models differ from proxy subscriptions.

## Clients and dashboards

Clients consume configurations or subscriptions. Hiddify App, v2rayN, NekoBox,
nekoray, Clash Verge Rev, MetaCubeXD, WireGuard clients, Tailscale, and Defguard
Client must not receive server private keys or panel administrator credentials.
Validate output format against the exact client version.

## Subscription, routing, and geo data

Sub-Store and subconverter transform subscriptions. Domain and geo repositories
feed routing policy. Preserve provenance when combining sources and never treat a
community list as an authoritative security feed.

Iran-focused routing references are explicitly catalogued:

- https://github.com/Chocolate4U/Iran-v2ray-rules - reachable during review.
- https://github.com/iran-v2ray/rules - supplied reference, unavailable during
  direct verification; keep it `unavailable-at-review` until it resolves.

The community registry also links Iranian maintainers and tools from AsanFillter,
azavaxhuman, ircfspace, primeZdev, ppouria, rezazoom, and MHSanaei.

## Installers

Installers are executable supply-chain inputs, not documentation shortcuts.
Download, inspect, pin, and hash them where possible. Capture current packages,
services, ports, firewall state, sysctl values, and configuration before running
an installer. Verify a real client data path and retain a rollback plan afterward.

## Selection workflow

1. Identify whether the target is a panel, core, tunnel, overlay, client, data
   source, installer, or platform.
2. Read `registries/ecosystem.json`, then open the focused registry and upstream
   documentation.
3. Confirm repository ownership, release status, license, architecture, operating
   system, and management interface.
4. Keep the first pass read-only. Back up configuration and databases before any
   approved mutation.
5. Verify control-plane health and real data flow separately.
