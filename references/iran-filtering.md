# Censorship and DPI patterns (Iran), and how to tell them apart

These patterns were observed on real relays in 2026. Filtering changes week to week and differs between
datacenters and ISPs, so treat this as a list of hypotheses to test, not as facts about today.

## Contents
1. Signature table
2. Pattern details
3. Diagnostic procedure (three vantage points)
4. Mitigation catalog
5. Measurement pitfalls

## 1. Signature table

| Symptom | Likely cause | Confirm with |
|---|---|---|
| Reverse tunnels show "established", users on that relay drop to ~0, and 0 bytes move in either direction | The relay's DC drops **data** on flows that were opened **from abroad** (the handshake still passes) | From a foreign server: TLS to a relay port gives `000` while TCP connects; `tcpdump` shows only retransmits |
| UDP "works" in a quick echo test, but WireGuard, KCP and QUIC tunnels die | **Per-flow UDP allowance**: the first ~3 packets of each 5-tuple pass, then the flow is dropped. An idle gap resets the allowance | Send 20+ packets on one flow and count arrivals with `tcpdump` on the far side |
| One exit IP fails from **all** in-country servers (100% ping loss, TLS `000`) but works from abroad | **Destination-IP blacklist.** Seen after an exit received ~60–80 GB/h directly from in-country DCs for ~8 hours | `path_test.sh` from 2–3 in-country relays and from one foreign server |
| A relay reaches only some foreign providers or ranges; others show an SSH banner, then stall | **DC egress allow-list** | The same target set from a relay in a different DC |
| Flows **started abroad toward the country** are slow (~1.2–1.5 Mbit/s each), even from unrelated providers | **Per-flow throttle** on foreign-initiated flows | Compare single-flow speed from two different foreign servers into the same relay. If both are equally slow, it is the throttle, not the server |
| Large ping loss (40%) while TCP data is fine, or 0% ping loss with dead TCP | ICMP is handled separately from TCP | Always run a data test; never conclude from ping alone |
| TLS stalls right after the Client Hello on one relay path only | `tcp_mtu_probing=1` on a lossy link collapsed the MSS to 1024/256/48 bytes | `ss -tin` shows tiny `mss`/`advmss`; set probing to 0 |
| Plain `http://` to a panel hosted in Iran stalls after ~5 KB, while HTTPS works | Keyword/HTTP inspection of cleartext | Retry the same request over HTTPS or through SOCKS/SSH |
| xDi links that **relays dial** die across many exits in one night, units stay `active`; links that the **exits dial** survive | Per-destination ICMP filtering from the relay's DC (operator-observed, Oct 2026) | `scripts/node/bpstatus.sh` peer loss 100% and `handshake did not complete`; `scripts/local/bp_matrix.sh` reverse test |
| Ping and small HTTPS (panel pages, subscriptions) to a foreign host work, but bulk downloads from in-country DCs to it are ~0 | **Bulk throttling** of that destination IP | Download a test file (`scripts/node/nettest.sh`) from 2 relays vs timing the panel URL |
| An exit downloads at line rate from the internet but sends only a few Mbit to anyone, plus loss to its panel | **Provider caps the exit's upload or network**, not censorship | `curl` a large file on the exit vs from the exit to a foreign server; ping exit↔panel |
| After the provider rotated a relay's IP: GRE to every exit carries nothing, relay-to-exit ICMP 85–100% loss, bulk TCP from the relay to foreign hosts stalls at 0 bytes (even TLS) while small requests work | The new address range is filtered harder than the old one | `scripts/relay/gretest.sh` and a direct download from the relay; reverse xDi (`scripts/local/bp_matrix.sh`) may still pass, see `tunnels.md` §17 |
| Panel pages and subscriptions load through a relay, but bot orders and renewals fail; the panel log shows `400` on `POST`/`PUT` after ~16 minutes | Request bodies stall on an ICMP-carried (xDi) path | `POST` a login with a wrong password through each address of the panel domain; see `pasarguard.md` §16 |
| Every relay of one datacenter loses its reverse xDi links in the same night; ping from abroad to that range 50–100% loss | ICMP from abroad to that datacenter is filtered | Ping the relay from several exits; restarting the links does not help |

## 2. Pattern details

**Inbound-from-abroad data blackhole (DC level).** Rebooting the relay does not help, and the tunnel
binary is not the cause: another relay in a different DC with the same binary and config keeps working.
Once it gets stricter, even the control channel stops establishing. The relay's **outbound** usually
still works, and that is why DNAT mode (relay dials the node) rescues it.

**Per-flow UDP allowance.** This is why "just use a UDP tunnel" fails. A 3-packet echo test gives a false
"UDP is open". Kernel FOU/IPIP, WireGuard, and KCP/QUIC-based tunnels all hit the same wall. Re-test
only if the filter's behaviour changes.

**Destination-IP blacklisting.** This is the dangerous one for DNAT designs. A fresh exit IP that
carried two relays' worth of one location over DNAT (~1,100 users, 60–80 GB/h) was blocked nationwide
about 8 hours later. It stayed reachable from abroad, and flows the exit itself started toward the
country still passed. Consequences:
- DNAT from a relay exposes the exit's IP. Spread high-volume locations over several exit IPs, keep a
  spare IP, and watch per-node user counts for a sudden collapse.
- A reverse tunnel (the exit dials the relay) keeps working through the same blacklist. Moving a
  location's tunnel client to the blocked server, using the same tunnel token, needs no change on the
  relay. It is the cheapest way to put a blacklisted exit back to work.
- Another exit that took similar DNAT traffic from one relay for ~20 hours was **not** blocked. The
  trigger is probabilistic or volume-related, so don't assume a working path is safe for good.

**Per-flow throttle on foreign-initiated flows.** A single TCP flow opened from abroad toward the
country got ~1.4 Mbit/s, and two unrelated foreign servers measured the same. Backhaul reverse tunnels
keep a pool of many connections and multiplex streams across them, so aggregate throughput is fine even
though each flow is throttled. Don't reject a reverse-tunnel design because of a single-flow speed test.

**DC egress allow-lists.** One relay could reach only one provider's range in one country. Every other
foreign target got an SSH banner or a TCP handshake, then nothing. Map what each relay can reach
(section 3) before deciding its DNAT targets.

## 3. Diagnostic procedure (three vantage points)

For each failing (relay, location), run the same three probes toward the **exit IP and location port**:

1. From the relay itself (this tests relay egress): ping loss, `curl --resolve` TLS through the Reality
   fallback, and a 10 MB download.
2. From another in-country server in a different DC (this tells the relay's problem apart from a
   nationwide one).
3. From a foreign server (this tells you whether the exit is alive).

| Relay → exit | Other in-country → exit | Abroad → exit | Conclusion |
|---|---|---|---|
| ❌ | ❌ | ❌ | Exit down (Xray, ports, disk, keep-alive) |
| ❌ | ❌ | ✅ | Exit IP blacklisted in-country |
| ❌ | ✅ | ✅ | This relay's egress is filtered toward that IP |
| ✅ | ✅ | ✅, but users fail | Check the relay's forwarding (DNAT map, tunnel forward port), DNS, and the host/port in the panel |

Then test the relay's **inbound**: from abroad, TLS to one of the relay's own ports. If that fails while
in-country clients succeed, the relay can no longer host reverse tunnels.

## 4. Mitigation catalog (cheapest first)

1. **Remove the relay from that location's DNS** (and from the subscription domain if needed). Instant,
   free, reversible.
2. **Switch the relay's mode** for that location: tunnel → DNAT when inbound from abroad is filtered;
   DNAT → reverse tunnel when the exit IP is blacklisted.
3. **Move a tunnel client** to another exit server using the same token. The relay side is untouched.
4. **New exit IP** (most clouds let you swap the primary IPv4 after a power-off). Expect it to get
   flagged again if the same heavy DNAT pattern continues.
5. **Foreign gateway hop** through a server the relay can still reach. This costs double traffic on the
   gateway and needs the operator's explicit OK.
6. **UDP-based tunnels** only after re-measuring that UDP flows survive past a few packets.
7. **Reverse xDi** (the exit dials the relay over ICMP) when relay-to-exit ICMP or TCP is filtered,
   including exits whose IP is blacklisted for inbound traffic. One dialed xDi link per exit host;
   re-verify the next day. See `tunnels.md` §15.

## 5. Measurement pitfalls

- A request from the relay to its own public IP never passes PREROUTING, so it bypasses DNAT and tests
  the local listener (the old tunnel) instead.
- Replies to foreign sources can be dropped, so an in-country service can look dead when probed from abroad.
- The operator's laptop may reach the internet through their own VPN, which makes it a foreign source.
- Reboots, provider maintenance, and monthly quota cut-offs look exactly like filtering. Check provider
  panels, `last -x`, and traffic counters before blaming the censor.
- Test files expire: `scripts/node/nettest.sh` removes itself after 72 hours, and a test against an expired
  file reads 0 Mbit. Check that the port still listens before blaming the path.
- A relay that answers on every port from inside the country but not from abroad, and cannot fetch
  foreign sites, has usually run out of its international traffic quota (seen twice in one week on the
  same relay). Ask the operator to check the provider panel before changing tunnels.
- Restarting a tunnel that the operator's own laptop VPN goes through drops the operator's SSH sessions
  mid-command; know which path your workstation uses.
- Record the time (UTC and local) of every change of state. The per-node user history in the panel DB
  is often the only precise clock you have for when a block started.
