# Tunnels: backhaul, DNAT relays, FOU, SSH reverse, WireGuard over TCP

## Contents
1. Backhaul reverse tunnels (server on the relay, client on the node)
2. Recommended settings and why
3. Backhaul traps
4. Moving a tunnel client to another server (same token)
5. Coordinated restart of a relay tunnel
6. DNAT relay mode (nftables)
7. Temporary nft bridge during migrations
8. FOU / IPIP kernel tunnels
9. SSH reverse tunnels
10. WireGuard through relays
11. Test vantage point and evidence limits
12. BackPack direct L3 and xDi
13. GRE, SIT, and IPIP provider testing
14. DNAT to an L3 tunnel peer
15. Reverse xDi (exit dials relay) and link survival
16. Persistent GRE relay links
17. When a relay gets a new IP
18. Sharing port 443 between services (SNI router)

## 1. Backhaul reverse tunnels

[Backhaul](https://github.com/Musixal/Backhaul) runs a **server** on the relay and a **client** on the
exit node. The client dials the relay's `bind_addr` and keeps a pool of connections open. The server
listens on the forwarded user ports (`ports = ["21001=127.0.0.1:21001"]`) and carries each user
connection through the pool to `127.0.0.1:21001` on the client side, where Xray listens.

Relay (server), `/etc/backhaul/de.toml`:
```toml
[server]
bind_addr = "0.0.0.0:7101"
transport = "wsmux"          # tcp | tcpmux | ws | wsmux | udp
token = "…"                  # the tunnel's identity; never print it
keepalive_period = 75
nodelay = true
heartbeat = 40
channel_size = 2048
mux_con = 8
mux_version = 1
mux_framesize = 32768
mux_recievebuffer = 1048576  # 1 MiB (see traps)
mux_streambuffer = 65536
sniffer = false
web_port = 0
log_level = "info"
ports = ["21001=127.0.0.1:21001"]
```
Node (client), `/etc/backhaul/relay-a.toml`:
```toml
[client]
remote_addr = "RELAY_A_IP:7101"
transport = "wsmux"
token = "…"
connection_pool = 8
aggressive_pool = false
keepalive_period = 75
nodelay = true
dial_timeout = 10
retry_interval = 3
mux_version = 1
mux_framesize = 32768
mux_recievebuffer = 1048576
mux_streambuffer = 65536
sniffer = false
web_port = 0
log_level = "info"
```
Each tunnel is a systemd unit (`ExecStart=/usr/local/bin/backhaul -c /etc/backhaul/<name>.toml`,
`Restart=always`, `LimitNOFILE=1048576`). Config files hold the token, so keep them `chmod 600`.
Menu-driven manager scripts often keep their own registry (for example `/etc/<manager>/tunnels.conf`).
If one is present, update it together with the unit and the toml, or the manager's menu drifts out of sync.

A tunnel is **healthy** when all three hold: the client has established connections to `remote_addr`,
the relay listens on the forward port, and a data test through the relay passes. `systemctl is-active`
stays green on a dead tunnel; the unit only writes errors to its journal.

## 2. Recommended settings and why

| Setting | Value | Reason |
|---|---|---|
| `mux_recievebuffer` | 1 MiB, not the 4 MiB default | With 4 MiB, clients on busy nodes grew to ~1–2 GB RSS and got OOM-killed. At 1 MiB, RSS dropped to under 300 MB with no measurable speed loss |
| `connection_pool` | 8 | Enough to spread the per-flow throttle on foreign-initiated flows; more only adds idle sockets |
| `keepalive_period` / `heartbeat` | 75 / 40 | Keeps NAT state alive without much chatter |
| `nodelay` | true | Interactive traffic |
| `sniffer`, `web_port` | false / 0 | No extra listeners or overhead |
| transport | `wsmux` for Xray TCP; `tcp` + `accept_udp = true` for WireGuard | mux shares a few TCP connections among many user streams; UDP needs the tcp transport's datagram support |

## 3. Backhaul traps

1. **Clients do not re-establish after the server side restarts.** After a plain `systemctl restart` of
   a relay-side tunnel, the node's client often stays stuck: the forward port never reopens and that
   relay's users for that location drop to zero. A full relay reboot usually recovers. Use the
   coordinated restart in section 5.
2. **Pool bloat.** After a reconnect storm, a relay can hold 5–10× more tunnel connections than users
   (healthy mux is roughly 1 tunnel connection per 3 users). RAM grows on both sides and stays there.
   Restarting the pair (coordinated) reclaims it. Detect it with users vs tunnel connections per tunnel
   and the RSS of the backhaul processes (`scripts/relay/relay_conns.sh`).
   High RSS alone is not bloat: one relay tunnel carrying ~10,000 users used 1.7 GB and was back at 0.9 GB
   two minutes after a coordinated restart, because the memory follows the load. Restart only when the
   tunnel-connections-per-user ratio is far above normal.
3. **Stale clients steal the control channel.** A retired server whose client is stopped but still
   *enabled* comes back after a reboot, reconnects with the same token, and takes the relay's control
   channel away from the new server. When you retire a server, always `stop` **and** `disable`.
4. **Units lie.** See the health definition above.
5. **Token = identity.** Anyone with the token can attach. Move tokens only through pipes, and mask them
   in every output (`sed -E 's/(token *= *)".*"/\1"***"/'`).
6. **Port 80 forwards matter.** If the panel's certificate renews with ACME standalone through a relay
   (the domain resolves to relays), the relay tunnel must forward `80` too. Deleting that forward
   silently breaks the next renewal.

## 4. Moving a tunnel client to another server (same token)

This is how you migrate a location, or put a blacklisted exit back to work, **without touching the relay**:

```bash
# 1) create the client on the NEW server, token piped from the OLD one, not started yet
{ ssh OLD "sed -nE 's/^token = \"(.*)\"$/\1/p' /etc/backhaul/relay-a.toml"; cat client_tunnel.sh; } \
  | ssh NEW 'read -r TOKEN && export TOKEN && PREPARE_ONLY=1 exec bash -s -- relay-a RELAY_A_IP 7101 wsmux'
# 2) cut over in one shot, so the relay never sees two clients with one token
ssh OLD 'systemctl disable --now relay-a'
ssh NEW 'systemctl enable --now relay-a'
# 3) verify: established connections to the relay, forward port on the relay, data test from in-country
```

## 5. Coordinated restart of a relay tunnel

Use this for buffer changes or to clear pool bloat, one tunnel at a time, preferably off-peak:
1. On the relay: back up the toml if the operator wants backups, edit it, restart the unit
   (`relay_tunnel_step.sh apply <tunnel>`).
2. **Right away**, restart the matching client on the node.
3. On the relay: check "control channel established" in the journal since the restart, the forward port
   listening, and users coming back (`relay_tunnel_step.sh verify <tunnel>`).
4. After any batch edit, grep every edited toml for the value you meant to write. One bad substitution
   crash-loops the tunnel.

## 6. DNAT relay mode (nftables)

When a relay's DC stops passing data on flows from abroad, reverse tunnels die, but the relay can still
dial out. Forward each location port straight to the exit:

```nft
table ip relay_dnat {
  chain pre  { type nat hook prerouting priority -110;
    tcp dport 21001 counter dnat to EXIT_DE_IP:21001
    tcp dport 21003 counter dnat to EXIT_FI_IP:21003
    tcp dport 8000  counter dnat to PANEL_IP:8000 }
  chain post { type nat hook postrouting priority 90;
    ip daddr EXIT_DE_IP tcp dport 21001 masquerade
    ip daddr EXIT_FI_IP tcp dport 21003 masquerade
    ip daddr PANEL_IP   tcp dport 8000  masquerade }
  chain mssclamp { type filter hook forward priority -150;
    tcp flags syn tcp option maxseg size set rt mtu }
}
```
Plus `net.ipv4.ip_forward=1`, a systemd oneshot unit that reloads the file at boot, and conntrack sizing:
`nf_conntrack_max=1048576` and `nf_conntrack_tcp_timeout_established=10800`. The default 5-day timeout
filled a 262k table in about 2 days with dead mobile flows.

Notes:
- Priority `-110` runs before other NAT, and the relay's own backhaul listeners on the same ports are
  simply bypassed. Leave them in place; they let you test the old tunnel locally
  (`tunnel_local_test.sh`), because local traffic skips PREROUTING.
- Reloading the table (`nft delete table …; nft -f file`) keeps existing flows, since conntrack keeps
  their mapping. Only new connections follow the new map.
- Point a port only at a server that terminates **that** location. An exit's Xray may also listen on
  other locations' port numbers (shared core config), and users would silently exit in the wrong country.
- Nodes now see the relay's IP as the client source, so per-IP limits count the whole relay as one client.
- UDP (WireGuard) is not forwarded by this table.
- DNAT exposes the exit IP to destination blacklisting (see `iran-filtering.md`).
- Name nft chains anything except reserved words such as `fwd`.
- `counter` on every rule lets you see which ports carry traffic (`nft list table ip relay_dnat`).

## 7. Temporary nft bridge during migrations

On the **old** exit, a table named `*_bridge` that DNATs the direct ports to the new exit (prerouting
`dnat to NEW_IP`, postrouting `masquerade`) makes the DIRECT DNS change timing irrelevant. Remove it once
DNS has moved and traffic on the old IP is gone. `FORWARD` policy is usually `accept` on these hosts. If
`iptables -S` complains about incompatible rules, use `nft`.

## 8. FOU / IPIP kernel tunnels

`ip fou add port P ipproto 4` plus `ip link add NAME type ipip remote R local L encap fou encap-sport P
encap-dport P` gives an IP-in-UDP link with no extra software (28 bytes of overhead per packet, no
encryption; the payload is already TLS). Using the same source and destination port makes the flow one
symmetric 5-tuple. It is useful **only** where UDP flows survive; under the per-flow UDP allowance, only
the first 3 pings pass.

## 9. SSH reverse tunnels

`ssh -N -R` (autossh, or wrappers such as FluxTunnel) is fine for **management** paths, for example
letting a sales bot abroad reach a panel inside the country. It is not suited to user traffic: it is a
single TCP flow, it suffers head-of-line blocking, and SSH in and out of filtered DCs often stalls after
the banner.

## 10. WireGuard through relays

- PasarGuard allows one core per node, so WireGuard needs a **second node instance** on the same server,
  attached to a `wg` core (`interface_name`, `private_key`, `listen_port` 51820/udp, `address`).
- Relay: a backhaul server with `transport = "tcp"`, `accept_udp = true`, and
  `ports = ["25001=127.0.0.1:51820"]`. Node: a matching tcp client. The node container builds its own NAT
  (`wg0` → eth0).
- The panel's `/sub/<token>/wireguard` returns a zip of `.conf` files for the official app. Add DNS,
  keepalive and MTU (1280 is safe) through host overrides.
- Test with a real handshake from inside a throwaway network namespace (`wg_e2e_test.sh`), run from an
  in-country server.
- Check usage before investing: in one fleet WireGuard carried **zero bytes** across all nodes for days,
  while it would have needed UDP forwarding added on every DNAT relay.

## 11. Test vantage Point And Evidence Limits

Before trusting a client delay test or panel request from an operator workstation,
confirm whether a VPN, TUN interface, or system proxy is active and identify the
egress country. A foreign egress can make an in-country-only relay look unavailable.
Use an independent in-country probe for customer-path decisions.
An optional lookup such as `curl -s https://ipinfo.io/country` reveals the probe's
source IP to that external service; use it only when the operator accepts that
privacy tradeoff. Disable both the VPN tunnel and system proxy before retesting.

A TLS/Reality fallback request proves bytes reached the listener and fallback. It
does not prove authentication, outbound routing, non-TLS protocols, or throughput.
Test the fallback locally on the exit first. If the exit's own upstream is slow, a
relay test through it is also slow. Use a short-lived, access-controlled test file
from the exit only during an approved window and remove the listener afterwards.
Client delay probes may create tiny usage rows, so a panel's "users per node" count
is not equivalent to active customer traffic. Compare tunnel-interface bytes or
per-listener acknowledged bytes and use a protocol-appropriate end-to-end test.

## 12. BackPack Direct L3 And xDi

BackPack documents direct layer-3 tunneling using GRE inside selectable carriers,
including the experimental xDi ICMP carrier. See `guides/tunnels/backpack.md` and
https://github.com/AminMGMT/BackPack. Operator measurements in September 2026 found
xDi useful on some paths where TCP opened but carried no data, but ineffective on
already lossy paths and CPU-heavy on small relays. Treat those numbers as
`operator-observed`, not a universal benchmark.

Test a temporary unit with a fixed lifetime before persistence. Prefer a pinned,
checksum-verified binary copied through an approved channel. Keep setup links and
64-character tokens secret. Verify routes, MTU, CPU, packet loss, and real traffic.

## 13. GRE, SIT, And IPIP Provider Testing

Kernel protocol availability is provider-specific. One field review found SIT/6to4
blocked across three tested networks and GRE heavily rate-limited on one network,
while other paths passed. A provider saying GRE is supported does not establish its
capacity. Build reversible temporary links with an automatic cleanup timer, measure
both directions, and remove them before deciding on persistent configuration.

## 14. DNAT To An L3 Tunnel Peer

nftables DNAT may target the far-side address of an L3 tunnel, with masquerade in a
NAT postrouting chain. This can preserve a relay's public port while changing the
private path behind it. The nftables wiki confirms DNAT and masquerade semantics:
https://wiki.nftables.org/wiki-nftables/index.php/Performing_Network_Address_Translation_(NAT)

Use a dedicated table, validate the complete candidate with `nft -c -f`, preserve a
ruleset backup, verify forwarding and return routing, and never flush a remote host's
entire firewall as rollback.

## 15. Reverse xDi (Exit Dials Relay) And Link Survival

`operator-observed`, October 2026, several Iranian datacenters. In xDi the dialing side sends ICMP echo
requests and the listening side answers with echo replies. The direction matters:

- **Forward** (relay dials exit): needs ICMP from the relay's datacenter to the exit IP. Over one night
  most forward links in one fleet died together (relay-to-exit ICMP 100% filtered) while their units stayed
  `active` and logged `handshake did not complete`.
- **Reverse** (exit dials relay): needs ICMP from the exit to the relay. In the same night every reverse
  link survived. Reverse also worked for an exit whose IP was blacklisted for inbound traffic from Iran,
  and for exits that no relay could reach forward.

Build a reverse link by running `ROLE=listen` on the relay and `ROLE=dial` on the exit
(`scripts/node/bplink.sh`), then DNAT the relay's public location port to the exit's tunnel IP
(`scripts/relay/dnat.sh`, section 14). Measure candidates in both directions with
`scripts/local/bp_matrix.sh`.

Traps:
- **One dialed xDi link per exit host.** An exit that dialed two relays at the same time kept only one
  working; the other showed 100% peer loss and the log said `xdi echoes from ... carry a different tunnel's
  tag`. Tests run one at a time both passed, so test the final combination, not each link alone. Use other
  relays through a different mode (forward link, reverse backhaul, DNAT) for the same exit.
- **Dead links break live ones.** Old forward links that are still `active` on an exit keep receiving
  stray echoes and confused the new reverse link. Disable dead links on both ends before building new ones.
- **A new path can be filtered within an hour.** One reverse link ran at ~250 Mbit and carried users,
  then the relay-exit pair was blocked ~40 minutes later. Never report a fresh link as stable: re-check
  the peer ping (`scripts/node/bpstatus.sh`) and real-user bytes (`scripts/node/realuse.sh`) the next day.
- The relay's CPU grows with every xDi link it terminates; watch it at peak before adding more.
- **Field-confirmed again (October 2026):** four exits that already dialed one relay were each given a
  second dialed link to another relay. Every second link passed its first throughput test (35–80 Mbit)
  and was at 0 Mbit a few minutes later, while the original links survived. A short test after adding
  a second dial proves nothing; the rule holds.
- **A shared exit has one dial budget for all brands.** An exit that hosts nodes of two brands can still
  dial only one relay. Decide which brand gets it, and reach the other brand through GRE, a forward link
  or a reverse backhaul.
- **Dead links keep burning CPU.** A reverse link whose path had died still used about half a core on
  the relay, which was already saturated. Disable dead links on both ends as soon as they are confirmed
  dead (`scripts/node/bpstatus.sh`), not only before building new ones.

## 16. Persistent GRE Relay Links

`operator-observed`, October 2026. Plain GRE (IP protocol 47) between a relay and an exit, with the
relay's public location port DNAT-ed to the exit's tunnel address (section 14), carried real users well
on paths where TCP DNAT died and xDi was lossy:

- **No ICMP dependence and almost no CPU.** A 1-core relay that ran 60% CPU on xDi links dropped to about
  1% after its links moved to GRE; another relay forwarded ~100 Mbit at 0% CPU.
- **It is a per-datacenter property.** From one datacenter GRE reached every foreign exit (150–540 Mbit);
  another datacenter of the same country blocked GRE to every exit, and a third blocked it only after
  its IP was rotated (section 17). Measure each relay with `scripts/relay/gretest.sh` before planning.
- **No per-exit dial limit.** One exit can hold GRE links to several relays at once, unlike dialed xDi.
- Build each end with `scripts/relay/greunit.sh` (oneshot unit, MTU 1476). Delete the temporary
  `gt_*`/`st_*` test links of the same endpoint pair first, or the kernel answers `File exists`.
- GRE adds no encryption; it carries traffic that is already encrypted end to end.
- The unit pins both public IPs. When either end's IP changes, update `local`/`remote` on both ends.
- Verify with real users (`scripts/node/realuse.sh`); a GRE link that passes ping can still be rate
  limited on purpose, which shows as one exact low speed.

## 17. When A Relay Gets A New IP

`operator-observed`, October 2026, one datacenter that rotated the public IP of two relays three times in
two days (each change needed a reboot before the new address answered):

- On the new IPs, GRE to every exit carried nothing, ICMP from the relay to exits lost 85–100%, and bulk
  TCP from the relay to foreign servers stalled at 0 bytes, even over TLS, while small requests worked.
- Only **reverse xDi** (the exit dials the relay) passed: 100–290 Mbit to most exits. It carried real
  users for about a day, then every one of those links died in one night when ICMP from abroad to the
  relay's range was filtered too.
- Treat a rotated IP as a new relay: re-measure every mode (`gretest.sh`, `bp_matrix.sh` in both
  directions, direct download), move the DNS records, update GRE units and xDi dial addresses, and
  re-verify the next day.
- A relay whose address keeps changing should not be the only relay of any location.
- Ranges differ. A later rotation of the same relay landed in a range where GRE passed with 0% loss and
  130–200 Mbit, while another provider's new range stayed dead in every mode for days. When a new range
  fails every test, ask the provider for an address from a different range rather than waiting.
- After a change of IP, search everything that names the old address: GRE `local`/`remote` on both ends,
  xDi dial addresses on peers, DNS records, allowlists and NAT rules of other services on the same host
  (rules matching `-d OLD_IP` silently stop matching), and SSH aliases.

## 18. Sharing Port 443 Between Services (SNI Router)

`operator-observed`, October 2026. A relay already used 443 for another service's tunnel, and a webhook
relay for a messenger bot needed 443 too. nginx `stream` with `ssl_preread` split the port by TLS name
without touching the existing service:

```nginx
stream {
    map_hash_bucket_size 128;
    map $ssl_preread_server_name $up443 {
        relay.example.com 127.0.0.1:7443;   # the new HTTPS server (listen 127.0.0.1:7443 ssl proxy_protocol)
        default           127.0.0.1:4444;   # everything else, unchanged
    }
    server { listen 443; listen [::]:443; ssl_preread on; proxy_protocol on; proxy_pass $up443; }
    # strip the PROXY header again for the old service, which does not expect it
    server { listen 127.0.0.1:4444 proxy_protocol; proxy_pass 127.0.0.1:4443; }
}
```

- Move the old listener from `:443` to `127.0.0.1:4443` first (for Backhaul: `"127.0.0.1:4443=..."`), then
  start nginx; the switch costs the old service a few seconds.
- With `proxy_protocol` plus `set_real_ip_from 127.0.0.1; real_ip_header proxy_protocol;` the new server
  still sees client addresses, so `allow`/`deny` rules keep working.
- Use `nginx -t && systemctl reload nginx` afterwards; a restart drops both services.
- **Check the host firewall first.** On that relay an allowlist in the `raw` table dropped every new
  connection to 443 from unlisted sources, so the webhook provider never reached nginx. To learn the
  provider's addresses, capture SYNs before any firewall while the operator triggers a webhook:
  `tcpdump -Q in -ni any 'tcp dst port 443 and tcp[tcpflags] & tcp-syn != 0 and tcp[tcpflags] & tcp-ack == 0'`
  (print field 5 = source). If nothing arrives at all, the provider rejected the URL before connecting.
