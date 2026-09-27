---
name: vpn-provider-ops
description: >
  Operate and troubleshoot a VPN/proxy provider's server fleet: Xray panels (PasarGuard, Marzban,
  Marzneshin, 3x-ui/Sanaei, Hiddify), exit nodes abroad, in-country relay servers, reverse tunnels
  (backhaul wsmux/tcp, nftables DNAT relays, FOU, SSH -R), Cloudflare DNS round-robin, and
  censorship/DPI diagnosis, especially in Iran. Use it whenever someone who runs or sells VPN service
  asks to check servers or whether configs connect, reports a slow or dead location, relay, tunnel,
  node or panel, wants to add, migrate or retire a server, change relay DNS, read panel data, drive a
  panel API, or plan capacity and traffic cost, even if they only say "check the servers" or write in
  Persian (بررسی سرورها، کانفیگ وصل نمی‌شود، رله، تونل، نود، پنل، کلادفلر، فیلتر، قطعی، کند است).
license: MIT
---

# VPN provider operations

You are helping someone who runs a commercial VPN service. Their customers usually sit in a censored
country (the reference setup here is Iran), connect to **relay** servers inside that country, and the
relays carry the traffic through **tunnels** to **exit nodes** abroad, which a central **panel** manages.
Every minute of a broken path is paying users failing to connect, and one careless command (a panel
restart, a wrong tunnel edit) can drop thousands of them at once. So the job is always the same shape:
**measure first, change the smallest thing, verify with a real data test, report plainly.**

## The mental model

```
 user app ── DNS: de.example.com ──► relay (in-country DC) ══ tunnel ══► exit node abroad (Xray) ──► internet
                   ▲ Cloudflare A records                                 ▲
                   one record per relay that can serve "de"               panel pushes config + users (gRPC)
```

- A **location** (DE, NL, FI, TR, UK, US…) is one exit server, or a pair of them. Each location has a
  fixed **location port** that is the same on every relay and on the node (for example `21001` = DE).
- A user's subscription contains several **config lines** (panel "hosts"): *TUNNEL* lines point at a
  relay domain and the location port; *DIRECT* lines point straight at the exit node; *WireGuard* lines
  use UDP through the relays.
- A relay serves a location in one of three ways. Knowing which one is in use is the first question in
  every incident, because each breaks under different filtering:
  | Mode | Who opens the connection | Survives | Breaks when |
  |---|---|---|---|
  | **Reverse tunnel** (backhaul client on the node dials the relay) | node → relay | the exit IP being blacklisted in-country | the relay's DC filters inbound flows from abroad |
  | **DNAT** (nftables on the relay forwards the port to the node IP) | relay → node | inbound filtering at the relay's DC | the exit IP gets blacklisted, or the DC's egress filter blocks it |
  | **Hop** (relay → another server → node) | depends | whatever the middle server survives | it doubles metered traffic; never hop between two in-country relays |
- **DNS is the steering wheel.** Each location name has one A record per relay that can serve it.
  Clients resolve once and mostly use the first answer, so one bad relay in a name of three breaks
  roughly a third of connection attempts. From the user's side that looks like "it connects sometimes."
- The panel is abroad. "Node connected" in the panel only proves panel↔node works. It says nothing
  about whether users inside the country can reach that node.

Read `references/architecture.md` for the full picture: port plan, config types, the subscription-domain
trap, and how traffic is metered.

## Ground rules, and why they exist

1. **Secrets stay on the servers.** Never print or echo tunnel tokens, node API keys, Reality private
   keys, panel passwords, subscription links, or Cloudflare tokens. Move them between machines through
   a pipe (`ssh A 'read token from file' | ssh B 'read -r TOKEN; …'`) and mask them when you show a config.
   Transcripts get pasted into chats and tickets; a leaked tunnel token lets anyone attach to the relay.
2. **Keys, not passwords.** Do not log in with passwords or type them anywhere. The operator installs
   your SSH key (`ssh-copy-id -i <key>.pub root@<ip>`). Some hosts force a password change on first
   login, and that makes `ssh-copy-id` fail silently, so verify with a key-only login.
3. **Read-only until the operator says otherwise.** For each change, say what you will change, why, who
   it affects, and how to roll it back, then wait for a yes. Standing permission for one class of change
   (for example "you may edit DNS") does not extend to others. Some operators want backups before every
   change and some explicitly do not; ask once, remember it, and always put the old value in your report.
4. **Only a data test proves health.** TCP connect, "control channel established", `systemctl
   is-active`, and "connected" in the panel all show green while users get nothing. The trustworthy test
   is a TLS request through the relay to the node's Reality fallback, made from **inside the country**
   (see "The data test" below).
5. **Traffic is money.** In-country relays are metered, often both directions. Never route a location
   through a second in-country relay, because that bills the same bytes twice. Prefer removing a relay
   from a location's DNS over rerouting its traffic. Before any routing change, estimate how much extra
   traffic it adds and where.
6. **Panel restarts drop everyone.** Restarting the panel restarts Xray on every node, so all users drop
   for a few seconds (a slow node can take a minute or two). Batch changes, restart once, and do it off-peak
   with the operator's knowledge.
7. **Shared servers have other tenants.** Other admins' panel nodes and tunnels often live on the same
   boxes. Identify owners from the panel IPs in node logs (`IP: x.x.x.x` lines) and leave anything that
   is not yours alone.
8. **A single failed probe is not an outage.** Before calling something dead, find the outage window: the
   first error to the next "established" in the journal, and a probe from a second vantage point.
9. **If a permission layer blocks a change, stop.** Don't find another route to the same result. Give the
   operator the exact command or console step and let them decide.

## The data test

A Reality inbound forwards any client that is not a valid Reality client to its `dest` site. So a plain
`curl` with the inbound's SNI travels relay → tunnel → Xray → real site → back. Any HTTP status means
bytes flowed. `000` means the path accepts connections but carries nothing.

```bash
# from a server INSIDE the country; RELAY_IP and PORT are the relay and the location port
curl -s -m 8 --resolve www.cloudflare.com:PORT:RELAY_IP -o /dev/null \
     -w '%{http_code} %{time_total}s\n' https://www.cloudflare.com:PORT/
# throughput of one connection through the same path
curl -s -m 25 --resolve speed.cloudflare.com:PORT:RELAY_IP -o /dev/null \
     -w '%{speed_download}\n' "https://speed.cloudflare.com:PORT/__down?bytes=10000000"
```

- Use an SNI that the inbound's `dest` actually serves. Add `-k` when you only care whether bytes flow.
- Test relay X from a *different* in-country server. A request that starts on the relay itself skips
  PREROUTING, so it bypasses the relay's DNAT rules. That is useful on purpose: it lets you test the old
  tunnel behind a DNAT without touching users.
- From abroad, results mislead: some DCs drop replies to foreign sources, so a working relay can look dead.
- `scripts/relay/relay_data_test.sh` runs the whole relay × location matrix;
  `scripts/local/path_test.sh` checks ping loss, TLS data, and speed toward a list of targets from one vantage point.

## Triage: "is everything connected?" or "location X is down or slow"

1. **Panel view.** Pull node status plus users and GB per node over the last 24 hours
   (`scripts/panel/pg_node_history.py`). When one node's users collapse while its neighbours stay normal,
   the path to that node broke, even if the panel still says "connected". Note the time of the collapse.
2. **DNS view.** List the A records of every location name and of the subscription domain
   (`scripts/local/cf.sh records <zone>`). Write down which relay serves which location.
3. **Data matrix from inside the country.** Run the data test for every relay × location that DNS
   advertises. Anything advertised in DNS that returns `000` is a live outage.
4. **Split each failing path.** From the relay, test the node IP (ping loss, TLS data, speed). Then test
   the same node from abroad, for example from another exit node.
   - Dead from everywhere: the node itself is down (Xray down, port collision, keep-alive stop, full disk).
   - Fine from abroad but dead from every in-country vantage point: the **exit IP is blacklisted in-country**.
   - Dead from one relay only: that DC's egress filter.
   - The relay cannot receive flows from abroad: its reverse tunnels are dead, so use DNAT mode there.
   `references/iran-filtering.md` has the full signature table.
5. **Mitigate** with the option that adds the least traffic and is easiest to undo (next section). Get
   the operator's yes unless you already have standing permission for that kind of change.
6. **Verify** with the same data test, then report.

### When a relay cannot serve a location

| Situation | Do this | Why |
|---|---|---|
| This relay can't reach the node; other relays can | Remove this relay's A record from that location's name (and from the subscription domain if that domain doubles as a tunnel address) | No new traffic anywhere; undo by re-adding the record |
| Exit IP blacklisted in-country | Serve that location through a **reverse tunnel** (the node dials a relay), or give the exit a new IP | Blacklists hit connections that start inside the country; flows the node starts toward the country still pass |
| The relay's DC filters inbound flows from abroad | Put that relay into **DNAT mode** toward the nodes it can still reach | Its outbound still works even when its inbound is filtered |
| Only a foreign middle server can reach the node | Foreign gateway hop, only with the operator's OK | Relay traffic stays single; the foreign server pays double |
| Anything that needs relay → relay inside the country | Don't | Every byte is metered twice |

## Setting up a new panel quickly

Follow the checklist in `references/panels.md` for the panel type. In short:
1. Prepare the server (key-only SSH, updates, swap, sysctl, reserved ports).
2. Run the official installer, pinned where possible. The operator creates the admin and types the password.
3. Put the panel behind HTTPS on a hostname.
4. Create Reality inbounds with stable tags.
5. Register nodes, then create hosts and groups.
6. Add relay forwards and DNS for the new ports.
7. Create a test user and data-test it from inside the country.
8. Give the sales bot a dedicated API admin.
9. Record the panel in the private inventory.

On a server shared with another panel, pick separate port ranges and label the containers.

## Reporting

Lead with the answer ("DE was down on 2 of 3 relays since 05:30; fixed on one, one needs you").
Then give a table of location × relay with ✅/🟡/❌, speed or latency, and the cause. Follow it with what
you changed (old → new, and how to undo it), what the operator must do (exact commands, one per block),
and the decisions that are theirs, each with your recommendation. Write in the operator's language:
if they write Persian, answer in Persian and keep IPs, ports and commands as they are. Give the operator
clock times in their timezone (Iran is UTC+3:30).

## Where to look next

| Need | Read |
|---|---|
| Components, port plan, config types, metering | `references/architecture.md` |
| What the Iranian filter does and how to tell which one hit you | `references/iran-filtering.md` |
| backhaul, DNAT relays, FOU, SSH reverse, WireGuard over TCP, their traps | `references/tunnels.md` |
| PasarGuard internals: DB access, restarts, keep-alive, cores, hosts, nodes | `references/pasarguard.md` |
| Standing up a new panel fast (PasarGuard, 3x-ui, Marzban, Marzneshin, Hiddify), their APIs, and bot robustness | `references/panels.md` |
| DNS round-robin, the token-safe Cloudflare helper, record hygiene | `references/cloudflare.md` |
| Building, registering, migrating and retiring nodes and relays | `references/node-lifecycle.md` |
| Steal, bandwidth ceilings, peak hours, conntrack, traffic quotas | `references/capacity.md` |
| Real incidents, anonymized: symptom → cause → fix → lesson | `references/incidents.md` |

Keep the fleet inventory (hosts, roles, IPs, location ports, DNS names, panel container name) out of this
public skill. Use a private file or your memory, built from `templates/fleet-inventory.example.md`. If none
exists, build one with read-only discovery (`scripts/node/snapshot.sh`, `scripts/node/panels_scan.sh`,
`scripts/relay/relay_tunnels.sh`) and have the operator confirm it.

## Running things safely

- Script names in this skill refer to its `scripts/` folder when that folder exists. When it doesn't,
  use the operator's private script collection (often kept alongside your memory notes) or the inline
  commands in the references. Everything important is written out there.
- Pattern: `ssh HOST 'bash -s -- ARGS' < scripts/…/x.sh`. For panel-DB Python:
  `ssh PANEL 'docker exec -i PANEL_CONTAINER sh -c "cd /code && python -"' < scripts/panel/x.py`.
- Pass inputs through environment variables on the remote side, for example
  `ssh relay-c 'RELAYS="192.0.2.10" LOCS="de:21001:www.cloudflare.com" bash -s' < relay_data_test.sh`.
- One SSH call per host. To cover several hosts at once, make parallel tool calls instead of chaining
  them into one long command.
- In local loops, don't use `set -- $var` in zsh: zsh does not word-split, so every value lands in one
  argument. That exact mistake once wrote an IP address into a tunnel's buffer setting and crash-looped
  it. Write each host's command out explicitly.
- If the operator's workstation reaches the internet through a foreign VPN exit, its SSH to in-country
  relays arrives "from abroad" and may stall. Jump through a relay that accepts foreign traffic
  (`ssh relay-a -J relay-c`).
- Launch long or connection-dropping jobs (restarting tunnel clients, upgrades) detached, with
  `nohup … > log` or `systemd-run`, and read the log afterwards. Your own SSH session can drop when a
  tunnel or a docker upgrade restarts.

## Persian glossary (واژه‌نامه)

| Persian | Meaning here |
|---|---|
| رله / سرور ایران | in-country relay server |
| نود / سرور خارج / لوکیشن | exit node abroad / its location |
| تونل، بک‌هال، تانل معکوس | tunnel, backhaul, reverse tunnel |
| پنل، مستر | management panel, the panel host |
| کانفیگ، لینک ساب، اشتراک | config line, subscription link |
| دایرکت | DIRECT config (straight to the exit) |
| وصل نمی‌شود، قطعی، کند است، پینگ نمی‌دهد | does not connect, outage, slow, "ping" (client delay test) fails |
| فیلتر شد، آی‌پی بسته شد | blocked by the censor, IP blacklisted |
| استیل، پهنای باند، ترافیک، حجم | CPU steal, bandwidth, metered traffic, data quota |
| نماینده، سقف حجم | reseller (panel admin), reseller data limit |
| ری‌استارت، ری‌بوت | restart a service, reboot the server |
