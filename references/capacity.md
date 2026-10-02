# Capacity, performance and cost

## Contents
1. The one-line snapshot
2. CPU steal (the noisy-neighbour problem)
3. Bandwidth ceilings under load
4. Per-connection speed through a relay
5. Peak hours
6. RAM: tunnel processes and OOM
7. conntrack on DNAT relays
8. Retransmits and loss
9. Traffic volume and quotas
10. Splitting one location across two exits
11. Relay headroom and exit assignment
12. Relay quota exhaustion and single-relay dependency

## 1. The one-line snapshot

`scripts/node/fleet_quick.sh` prints cores, load, CPU busy and steal over 5 s, RAM, swap, NIC rx/tx over
5 s, today's volume (if vnstat is installed), and free download capacity. Run it on every server in
parallel, one call per host, and compare the lines side by side.

## 2. CPU steal

`steal` is CPU time the hypervisor gave to other tenants. Above ~10% sustained, Xray and the tunnels
slow down, and health checks start timing out (`DeadlineExceeded` in node logs). Collect evidence for a
provider ticket:
- the share of steal since boot (`/proc/stat`), three live 20 s samples, and load (`scripts/node/steal.sh`);
- daily averages and the worst 10-minute window from the sar archive (`scripts/node/sarhist.sh`). In
  `sar -u`, `%steal` is column 7 and `%idle` is column 8.
Also look for other admins' containers burning CPU on the same box (`docker stats`). One of them took
119% CPU on a 4-core node that was also suffering 50–70% steal.

## 3. Bandwidth ceilings under load

Download 25–50 MB from `speed.cloudflare.com/__down?bytes=N` **on the node while it serves users**.
Headroom is what is left. If headroom collapses while user traffic sits at a round number (100, 200,
250 Mbit/s), the port is capped or throttled. Signs of a host-side throttle: throughput pinned to an
exact value, TCP retransmits of 5% or more, ICMP loss even to a nearby anycast address, and a sudden
drop in daily volume right after the monthly usage crosses some threshold. Show the evidence to the
provider, or replace the server.

## 4. Per-connection speed through a relay

Ride the Reality fallback, so no user credentials are needed:
```bash
curl -s -m 25 --resolve speed.cloudflare.com:PORT:RELAY_IP -o /dev/null -w '%{speed_download}\n' \
  "https://speed.cloudflare.com:PORT/__down?bytes=10000000"
# upload: head -c 10000000 /dev/zero | curl … -X POST --data-binary @- "https://speed.cloudflare.com:PORT/__up"
```
Run it from an in-country server, for each relay × location. As a rough guide from one fleet: 40–60
Mbit/s per connection is good, 5–10 is noticeably slow, and under 1 is broken for video. Compare with
the node's own headroom to locate the bottleneck (relay, tunnel, or exit).

## 5. Peak hours

In Iran the evening peak runs about 19:30–00:30 local (16:00–21:00 UTC). Plan any risky change outside
that window. Size nodes for peak: in one fleet a 2-core exit ran at 35% CPU on ~105 Mbit/s, while a
2-core node with more connections sat at 66–75% CPU, which is the point to upgrade.

## 6. RAM: tunnel processes and OOM

- Backhaul clients with 4 MiB mux buffers grew to ~1–2 GB each after reconnect storms, and the kernel
  OOM-killed them. With 1 MiB buffers and a swap cushion, RSS stayed under ~300 MB.
- On relays, compare users with tunnel connections per tunnel (`relay_conns.sh`). A pool several times
  larger than the user count is left over from a reconnect burst; a coordinated restart reclaims it.
- `unacc` memory (RAM owned by no process, cache or slab) over 1 GB usually means the hypervisor
  ballooned it back (`health.sh`).

## 7. conntrack on DNAT relays

Every forwarded user flow lives in conntrack. With the default 5-day established timeout, dead mobile
flows filled a 262k table in about 2 days. Use `nf_conntrack_max = 1048576` and
`nf_conntrack_tcp_timeout_established = 10800`, and watch `nf_conntrack_count`.

**The limits silently reset after a reboot.** `sysctl.d` runs before the `nf_conntrack` module loads,
so the conntrack lines are skipped and the kernel default applies: 8192 entries and a 5-day timeout on a
1 GB relay. One such relay filled its table after a provider reboot (`nf_conntrack: table full, dropping
packet` in `dmesg`), and every tunnel through it showed 40–60% loss at peak while the units stayed healthy.
Fix: load the module at boot (`/etc/modules-load.d/conntrack.conf`) and re-apply the sysctl file from the
DNAT unit (`ExecStartPost`), which `scripts/relay/dnat.sh` now does. Size the table to RAM (~300 bytes per
entry; `dnat.sh` uses 64k per GB, capped at 1M) and check `nf_conntrack_max` after every relay reboot.

## 8. Retransmits and loss

`/proc/net/snmp` RetransSegs/OutSegs over a 5 s window: about 1% is normal, 5% or more means trouble
on that path or host. ICMP loss toward a nearby anycast address (1.1.1.1) that is not zero points at
the host or its uplink, not at the censor.

## 9. Traffic volume and quotas

- Relay NICs see each user byte twice. Typical numbers: 2–3 TB/day per relay, 70–80 TB/month.
- In-country DCs often have monthly caps, and hitting one takes the relay offline mid-evening. Track
  daily volume (`sar_traffic.sh`, `vnstat -d`) against the cap and drop that relay from some DNS names
  before it runs out.
- Foreign clouds often include ~20 TB/month and charge per TB after that. A foreign gateway hop doubles
  that server's volume, so estimate it before proposing one.

## 10. Splitting one location across two exits

Assign relays to exits (relays A and B → exit 1, relay C → exit 2) rather than trying to balance
inside one relay. Check that each relay can actually reach its exit, and keep checking: a direct DNAT
path can get the exit IP blacklisted after hours of heavy traffic (`iran-filtering.md`). A reverse
tunnel from the second exit into one relay is the most robust way to split.

## 11. Relay Headroom And Exit Assignment

Measure free relay bandwidth at peak, not only interface capacity. In one observed
fleet, a relay carrying roughly 360 Mbit/s with about 90 Mbit/s download headroom
slowed every location. Moving the heaviest DNS name to a less-loaded relay restored
headroom. These values are fleet-specific; use current peak measurements and leave a
documented safety margin.

Where possible, assign relays deliberately across different exit IPs. This divides
CPU and connection load and limits the effect of an exit-IP block. Do not call a
relay move successful until per-relay traffic and client data paths are rechecked.

If an exit is slow to several independent destinations and also shows packet loss
and high TCP retransmission locally, treat the exit/provider path as the likely
bottleneck. Preserve timestamped evidence, open a provider ticket, or replace the
host; moving relays cannot repair a universally degraded exit upstream.

## 12. Relay Quota Exhaustion And Single-Relay Dependency

`operator-observed`. A relay that the provider sells with a monthly traffic quota simply goes dark when
the quota runs out: no ping and no SSH from anywhere, so it looks like a datacenter outage. Every
location that depends only on that relay drops at once. After the top-up, tunnel clients that backed off
for hours may need a restart to reconnect immediately.

- Track each relay's quota burn like any other capacity metric and warn days ahead.
- List the locations that have exactly one working relay; they are the ones a quota or DC event takes
  down. Adding a second relay of a *different* path type (for example a reverse xDi link next to a
  reverse backhaul tunnel) protects against both quota and filtering events.
- Every xDi link a relay terminates costs CPU. A 4-core relay terminating three busy links reached
  ~65% CPU at ~260 Mbit; a 1-core relay saturated (0 free download, 60% ping loss) after one more busy
  location was added, which slowed the other locations on it. Rebalance by moving a location that has a
  healthy alternative relay, not by removing the newest one.
