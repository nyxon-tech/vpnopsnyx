# Architecture of a relay-based VPN fleet

## Contents
1. Components
2. Port plan
3. Config types and hosts
4. The subscription-domain trap
5. How traffic is metered
6. What "healthy" means at each layer

## 1. Components

| Component | Where | Runs | Notes |
|---|---|---|---|
| **Panel (master)** | abroad | PasarGuard / Marzban / Marzneshin / 3x-ui / Hiddify | Holds users, groups, inbounds, hosts, and resellers. Pushes Xray config and users to the nodes over gRPC/REST. |
| **Exit node** | abroad, one or two servers per location | Xray inside the panel's node container (e.g. `pasarguard/node`) | Listens on the location ports. Some servers also host other admins' nodes. |
| **Relay** | in-country datacenters (2–3 of them, different providers) | tunnel servers (backhaul) and/or nftables DNAT | Customers connect here. It forwards each location port toward the right exit. |
| **DNS** | Cloudflare, DNS-only | A records per location name; one per relay that can serve it | Round-robin. Also the subscription domain. |
| **Subscription** | panel, usually reached through the relays | `https://sub.example.com:PORT/sub/<token>` | Returns the config lines. The panel's port is forwarded by a relay tunnel like any other location. |

Several relays exist because any single in-country DC can get filtered, run out of its monthly traffic
quota, or be down for hours. Several exits exist per region so that one blocked IP or one saturated port
does not take a whole location down.

## 2. Port plan

Keep one port per location, identical on the node and on every relay, so a relay can switch between
modes without any change on the client side:

| Purpose | Example |
|---|---|
| Location port (TUNNEL configs) | DE `21001`, NL `21002`, FI `21003`, TR `21004`, UK `21005`, US `21006` |
| Extra Reality inbounds on the node | `443`, `8443` |
| DIRECT configs, one inbound per location | `24001`–`24006` |
| WireGuard, relay side → node `51820/udp` | `25001`–`25006` |
| Tunnel control ports on the relay (backhaul `bind_addr`) | `7101`, `7102`, … |
| Node service / API ports (one pair per node instance) | `62050/62051`, `62060/62061`, … |
| Panel (forwarded through the relays too) | `8000` (panel/sub), `80` (only if ACME standalone renews through a relay) |

Reserve every fixed listener port in `net.ipv4.ip_local_reserved_ports` on nodes and relays (see
`node-lifecycle.md`). Otherwise the kernel can hand one of them out as an ephemeral source port, and
Xray fails to bind it on its next restart.

## 3. Config types and hosts

In PasarGuard/Marzban terms, a **host** is one config line template attached to one inbound:

| Type | Address | Port | Path |
|---|---|---|---|
| TUNNEL | location domain, e.g. `de.example.com`, which resolves to relays | location port | user → relay → tunnel/DNAT → node |
| DIRECT | `de.direct.example.com` → the exit IP itself | direct port | user → node (works only while the exit IP is reachable from the user's ISP) |
| WireGuard | location domain (relays) | WG port | UDP through the relay's tcp+accept_udp tunnel |
| Info line | anything | anything | a dummy config whose name shows remaining data/days |

A user sees every host of every inbound their groups grant. The `hosts` table is loaded at panel
startup (see `pasarguard.md`).

## 4. The subscription-domain trap

Hosts can use a template address such as `{HOST_DOMAIN}`, which means "whatever domain the user fetched
the subscription from". If the DE TUNNEL host uses it, then `sub.example.com` is **also** the DE tunnel
address. Its A records must therefore list only relays that can serve DE **and** the panel port. When
you remove a relay from DE, remove it from the subscription domain as well. Otherwise DE keeps failing
for about 1/N of users even though `de.example.com` looks right.

Resellers often CNAME their own branded domain to one of your location names
(`de.reseller.example` → `de.example.com`). Every change to that record reaches all of their customers.

## 5. How traffic is metered

- Each GB a user moves crosses the relay's NIC twice (in and out). Half of that is international.
  In-country DCs often cap or bill monthly volume. When one runs out, the relay goes dark for everyone
  whose DNS answer pointed there.
- A relay → relay hop inside the country is billed on both relays: 4× the user's bytes on relay NICs.
- A foreign gateway hop (relay → foreign server → node) keeps the relay at 2× but doubles the foreign
  server's volume. Many foreign hosts include a monthly allowance (e.g. 20 TB) and charge per TB beyond it.
- Rough planning numbers from a real fleet: ~2.3–2.6 TB/day on each of three relays at ~1–2k concurrent
  users per location. That is ~70–80 TB/month per relay.
- Measure volumes with `sar -n DEV` history (`scripts/node/sar_traffic.sh`) or `vnstat`. Per node and
  per user from the panel DB: `node_usages`, `node_user_usages`.

## 6. What "healthy" means at each layer

| Layer | Looks fine but isn't | Real check |
|---|---|---|
| Panel ↔ node | "connected" | users and bytes per node in the last hour, compared with the same hour yesterday |
| Tunnel | unit `active`, "control channel established", TCP connects | data test through the relay; established connections to `remote_addr`; forward port listening |
| Relay | ping 0% loss | data test per advertised location from another in-country vantage point |
| Node | container up | Xray listening on all location ports; no `exit status 255` loop; no keep-alive stops |
| DNS | record exists | every advertised IP passes the data test for that name's port |
