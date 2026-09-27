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
