# Incident case studies (anonymized)

Short and factual: symptom → diagnosis → fix → lesson. Names, addresses and dates are removed.

1. **Relays accept tunnels but carry nothing.** Only one location worked; users on two relays fell to
   zero; tunnel control channels said "established". Diagnosis: those DCs dropped data on flows opened
   from abroad, and reboots didn't help. Fix: DNAT mode on both relays toward exits they could still reach
   (18/18 paths OK). Lesson: only data tests count, and relay egress can survive when ingress dies.
2. **Fresh exit IP blacklisted after ~8 hours.** A new exit took one location's traffic from two DNAT
   relays: ~1,100 users, 60–80 GB/h. Overnight its users fell to 1, with 100% ping loss from every
   in-country server while it stayed fine from abroad. Fix: move those relays back to the older exit, and
   drop from DNS the relay that could reach neither exit. Lesson: DNAT exposes exit IPs; reverse tunnels
   survive the blacklist, so plan to rotate IPs.
3. **A heavy node became slow for everyone (6–10 s per request).** Google failed, and client "ping"
   tests timed out. Cause: WARP running inside Xray stalled at ~30k connections. Fix: a node-specific
   cloned core with the WARP rules sent DIRECT. Lesson: in-process WARP doesn't scale; per-node cores need mirroring.
4. **Tunnel clients reached 1–2 GB each, and the OOM killer struck at peak.** Cause: 4 MiB mux buffers
   plus pool bloat after reconnect storms. Fix: 1 MiB buffers, coordinated restarts, 4 GB swap. RAM in
   use halved.
5. **Xray looped on `exit status 255` after a restart.** Causes: another container's random API port
   equal to a fixed inbound port, or a fixed port taken as an ephemeral source port. Fix: restart the
   offender, and reserve all fixed ports. Lesson: the real error is only in the panel log.
6. **A location went fully down for a minute while the panel was unreachable.** Cause: node
   `keep_alive = 60` stopped Xray on its own. Lesson: raise keep_alive, and count the stops per week.
7. **A 5-minute outage caused by our own loop.** In zsh, `set -- $pair` did not split, so an IP address
   was written into a tunnel's buffer setting and the tunnel crash-looped. Lesson: explicit per-host
   commands, and grep configs after every batch edit.
8. **A relay was reported "dead" while it was only down for 2 hours.** Lesson: find the outage window
   in the journal before declaring anything dead, and probe from two vantage points.
9. **A provider throttled an exit to 20 Mbit/s** once the monthly volume crossed a threshold: 5%
   retransmits, ICMP loss even to a nearby anycast address, daily volume more than halved. Fix: replace the
   server, reusing the same tunnel tokens, so no relay changes were needed.
10. **Another admin's node ate the CPU on a shared exit** (119% CPU), on top of 50–70% hypervisor steal.
    Lesson: identify tenants by panel IPs in node logs; remove only with the owner's go-ahead; send steal
    evidence to the host.
11. **The certificate renewal silently depended on a relay forwarding port 80.** Lesson: document such
    forwards and never remove them in cleanups.
12. **The panel was unreachable through one relay only.** Cause: `tcp_mtu_probing=1` collapsed the MSS
    to 48–1024 bytes on a lossy path. Fix: set probing to 0 and restart that tunnel.
13. **Subscriptions came out empty after a DB-created core.** Cause: the panel's inbound-cleanup job
    deleted the new tags before the panel restarted. Fix: re-attach the hosts and groups, then restart.
    Lesson: restart immediately after creating a core.
14. **A retired server stole a relay's control channel** after a reboot. Cause: its tunnel clients were
    stopped but still enabled. Lesson: always disable them on retirement.
15. **DIRECT users dropped at migration time.** The DNS moved before the panel switch, so users reached a
    server without config. Lesson: switch the panel first, put an nft bridge on the old IP, then move DNS.
16. **Reseller hit their data cap and all their users dropped at once.** Their notifications were
    broken, so nobody saw it coming. Lesson: track reseller quota burn yourself and warn days ahead.
17. **Most forward xDi links died in one night.** Units stayed `active`; peer ping 100%. Links dialed by
    the exits survived. Fix: rebuild as reverse links. Lesson: prefer the exit-dials-relay direction and
    re-check every link daily.
18. **A fresh link was filtered 40 minutes after it went live.** It was reported as fixed after a
    10-minute check. Lesson: never call a new path stable before the next-day check.
19. **Two reverse links on one exit, only one worked.** Each passed alone; together the second showed
    100% loss and "different tunnel's tag" warnings. Fix: one dialed xDi link per exit, other relays via
    other modes.
20. **Nodes on a moved server stayed "error".** The node certificates named the old IP and the panel's
    strict TLS check refused them. Fix: new certificates and an updated stored certificate in the panel.
21. **A relay went dark for hours: its traffic quota ran out.** Three locations that used only that relay
    dropped. Lesson: track relay quotas and give every location a second relay.
22. **A sales bot abroad could not create services.** It called the panel through an in-country relay
    that drops foreign-initiated flows. Fix: pin the panel name to the panel IP on the bot's server.
23. **The panel and subscriptions were erratic (1 s to timeout).** One busy relay carried the panel
    domain. Fix: timed each path, moved the domain to the steady ones and a direct record.
24. **A location was "unusable" though every unit was up.** Its only relay reached the exit with 50%
    loss; handshakes took 5–9 s. Fix: a reverse link from another relay; real-user bytes per connection
    roughly doubled.
25. **A rebooted exit's node failed to start.** First an inbound port was busy at start time, then the
    panel-to-node path lost half its packets so `Start` never arrived. The provider's network was the
    cause; a sibling node with a small user list still connected.
26. **Adding a location to a 1-core relay slowed two others on it.** Fix: moved a location that had a
    healthy alternative relay off it instead of removing the new one.
27. **A relay dropped packets after a provider reboot.** Its conntrack limits lived only in `sysctl.d`,
    which runs before the conntrack module loads, so the table was back at 8192 entries with a 5-day
    timeout and filled up (`table full, dropping packet`). Fix: higher limits applied immediately, module
    loaded at boot, sysctl re-applied by the DNAT unit. Lesson: check `nf_conntrack_max` after any reboot.
28. **GRE carried a whole fleet when TCP and xDi did not.** One relay's datacenter passed GRE to every
    exit; persistent GRE links plus DNAT gave every location a second relay and cut a 1-core relay's CPU
    from 60% to 1%. Another datacenter blocked GRE entirely. Lesson: measure GRE per relay.
29. **A relay's IP was rotated three times in two days.** Each time its tunnels died and a location that
    depended on it went down until someone noticed. On the new range only exit-dialed xDi worked, and a
    day later that died too. Lesson: a relay with an unstable address must never be a location's only
    relay; a health check that removes dead relays from DNS would have saved hours.
30. **Bot renewals failed for an hour after a relay was added to the panel domain.** The relay used an
    xDi path; reads worked, but `POST`/`PUT` bodies stalled ~16 minutes and returned `400`, so the bot
    refunded every order. Fix: removed the relay from the panel domain. Lesson: test a `POST`, not a page
    load, before putting a path behind the panel domain.
31. **A second dialed xDi link on four exits looked fine, then died.** Each passed its first test and was
    at 0 Mbit minutes later; the original links survived. Lesson: one dialed xDi link per exit, also on
    exits shared by two brands.
32. **A dead reverse link burned half a core on a saturated relay.** Fix: disabled it on both ends.
    Lesson: remove dead links as soon as they are confirmed dead.
33. **20,000 failed panel logins per day from one address went unnoticed for four days.** Found while
    debugging a bot failure. Fix: blocked with a dedicated nftables table after the operator confirmed.
    Lesson: review `auth_failures.sh` output during routine checks.
34. **Half of the users could not load their subscription.** The subscription domain listed a relay and
    the panel's direct IP; the direct IP answered small requests but delivered nothing from two of three
    in-country datacenters. Fix: removed the direct IP. Lesson: test a realistic download through every
    address (`scripts/relay/panel_path_check.sh`), not only a login.
35. **A location stayed down 30 minutes after its relay was fixed.** All of its records had been deleted
    while no relay worked, and resolvers had cached the NXDOMAIN. Lesson: never leave a name empty.
36. **A tunnel location had zero users for days with every path healthy.** Its inbound was in no group.
    Fix: added it to the same groups as the other tunnel inbounds (`scripts/panel/inbound_groups.py`).
37. **The same relay ran out of traffic quota twice in one week.** Each time the locations it served alone
    went dark until the operator bought more. Lesson: watch relay quotas and keep a second relay per
    location.
38. **A new exit could not carry a tunnel at any useful speed.** It downloaded at 680 Mbit but uploaded
    7–11 Mbit to anyone; every relay measured the same. The cause was the provider's upload cap, which no
    tunnel can fix.
39. **One relay rotated through four public IPs in four days.** Two ranges were usable (GRE and downloads
    fine), two were dead in every mode; another provider's new range was dead for days too. Lesson: when
    a new range fails every test, ask for a different range.
40. **A relay was pulled from DNS while ~1,500 users were on it.** The operator's own connection to the
    relay ports failed one evening (0 bytes), while every other in-country datacenter reached them fine.
    Fix: put the relay back. Lesson: confirm a dead relay from two independent in-country probes and from
    the exit side before touching DNS.
41. **The panel failed now and then for no visible reason.** Its database pool was at the default 5+5 and
    hit `QueuePool limit` 89 times in three hours. Fix: pool 20+40 and a recreate of the container
    (`pasarguard.md` §19).
42. **The panel did not open from Iran at all.** It sat behind Cloudflare's proxy, which in-country
    resolvers mapped to `188.114.98.0/.99.0`, and its direct IP was bulk-throttled. Fix: the panel port
    DNATed over GRE on two relays, a certificate covering the subscription name, then DNS-only records
    on the relays (`pasarguard.md` §20).
43. **An exit was pinned at 200 Mbit.** Idle CPU, no steal, and 2–4 Mbit for a fresh download: a provider
    throttle. Fix: the relay's path for that location moved to another exit over a new GRE link, tested on
    a spare port first (`node-lifecycle.md` §12): 10.7 → 92 Mbit per connection.
44. **A foreign panel's node was found on an exit.** Its control connection went to a panel IP outside the
    fleet and it carried ~54 users. Removed with the operator's go-ahead after backing up its compose
    directory and data.
45. **Two servers came back changed one morning.** One had new SSH host keys, the other half its cores; the
    provider had rebuilt or resized them. Lesson: verify a changed host key from abroad before trusting it
    (`node-lifecycle.md` §13).
46. **A reverse link to a relay lost 65% of its packets.** Packets of every size were lost, so it was not
    the MTU: the relay's network was dropping foreign traffic. Fix: removed that relay from the
    location's DNS.
47. **Bot purchases failed again a week later.** Someone re-added a relay that was known to stall `POST`
    bodies to the panel domain (this time over GRE). Lesson: keep a list of addresses that must never be in
    the panel record, and run `scripts/relay/panel_path_check.sh` after anyone changes it.
48. **One exit carried a whole location while its sibling idled.** Re-pointing one relay to the idle exit
    halved the load in minutes (`capacity.md` §10).
49. **Two new exits got hosts and DNS but no group.** Neither would have reached a single user. Lesson:
    run `scripts/panel/inbound_groups.py` after adding any node or inbound.
50. **A bot abroad had to sell services on panels hosted in the country.** It could not reach them
    directly; a password-protected proxy on the one in-country relay that accepts flows started abroad,
    open only to the bot's IP, solved it (`scripts/relay/bot_panel_proxy.sh`).
51. **A location died after a provider reboot while the panel said `connected`.** The exit's Xray never
    restarted; re-saving the two nodes fixed it (`pasarguard.md` §12).
52. **A relay's xDi links all died in 20 minutes.** Four reverse links had tested at ~200 Mbit; after
    several ran together, ICMP from abroad to the relay was blocked (`tunnels.md` §15).
53. **A relay's direct DNAT to one exit gave users almost nothing.** 0.02 MB per connection through that
    relay while the exit served other paths at ~1 MB. A forward xDi link to the same exit passed
    100–140 Mbit; re-pointing the DNAT to the tunnel IP fixed it without a DNS change.
54. **Two servers' SSH host keys changed overnight.** The provider had migrated both (new cloud-init
    instance id, new hostnames, data intact). The keys matched from three vantage points and only known
    keys were authorized, so the entries were replaced (`node-lifecycle.md` §13).
55. **Two relays in one datacenter could not keep any tunnel.** GRE lost 70%, direct TCP to every exit
    carried ~0 while Cloudflare ran at 100+ Mbit. A single reverse xDi link ran at ~100 Mbit for 2–6
    minutes, then ICMP between that relay and that exit was blocked; exits without a link stayed open.
    Lesson: when a fresh link dies like this, disable it at once (each retry burns another pair) and ask
    the provider for an IP in another range (`tunnels.md` §15).
56. **The relay that stalls bot `POST` bodies was found in the panel record a third time**, this time
    replacing the working address instead of joining it. Lesson: run `scripts/relay/panel_path_check.sh`
    on every routine check, not only after a known DNS change.
57. **A GRE link answered from one end only.** Exit-to-relay ping worked, relay-to-exit lost 100%, and
    the location's ports were closed on that relay; restarting the relay's GRE unit fixed it
    (`tunnels.md` §16).
58. **A relay that was also every SSH jump host went dark.** Ping still answered but every TCP port,
    SSH included, was closed, so the operator lost SSH to the other relays too. Its users moved off once
    the record was removed. Lesson: keep a second jump host in the SSH config and probe relays with TCP,
    not ping.
59. **A new relay set up by someone else lacked one port.** Every location worked except one name whose
    host used a second port on the same exit. Lesson: map ports from the panel's host list
    (address, port), not from memory, and probe every port on every relay before adding it to DNS.
60. **A location had zero users while the panel showed its node connected.** The node had not
    rebooted; its core had stopped. Re-saving the node fixed it in seconds. Lesson: check listeners
    on every routine check (`scripts/local/listener_check.sh`, `pasarguard.md` §12).
61. **A 2-core relay ran out of CPU at 150 Mbit.** Two copies of a third-party tunnel tool, started by
    hand from an SSH session days earlier, were spinning at ~16% CPU each while listening on nothing;
    the binary ran from a deleted in-memory file under a one-character process name. Lesson: on a
    relay that is busier than its traffic explains, list processes by CPU, check
    `/proc/PID/cmdline` and `/proc/PID/exe`, and ask the operator before stopping anything you did not
    start.
62. **Offloading a saturated relay took three locations down.** To relieve one relay at its bandwidth
    ceiling, three names were left on the other relay only; that relay dropped an hour later and the three
    locations went dark. Lesson: never leave a name on one relay, even temporarily. Relieve a saturated
    relay by adding capacity, or by dropping it only from names that keep two other relays.
63. **Almost every node of a panel lost its core within a few hours.** Tunnel, WireGuard and direct nodes
    on seven exits all showed `connected` while their Xray was stopped; the panel log said
    `Stream failed ... backend not initialized` and also showed database lock timeouts and 5–15 s API
    responses. Re-saving every node brought them back. A port-listener check only covered the tunnel
    ports and missed the others. Lesson: scan every node container for `Code: Unavailable`
    (`docker logs --since 3m`), and consider a panel-side watchdog that re-saves nodes whose stream fails.

64. **Constant disconnects on one exit that every synthetic test called healthy.** Ping, bulk TCP and the
    panel were clean. Per-relay `ss -ti` on the exit showed one relay's users with 5x the retransmission
    and connections moving a tenth of the data. Moving that relay's port from DNAT to an exit-dialed stealth
    BackPack tunnel fixed it. Lesson: judge a relay-exit pair by its real user sockets, not by ping or
    `nc` throughput.

65. **Every direct config died at once, with every server healthy.** The direct names lived in a separate
    domain whose registration had lapsed; the registrar put it on `clientHold` and removed its nameservers,
    so the names stopped resolving everywhere. Exit ports, nodes and the panel were fine, and the direct
    ports simply had no connections. Moving the hosts to new names in a live domain restored them. Lesson:
    when every config under one domain fails together, run `dig @1.1.1.1` and `whois` before touching
    servers, and track the expiry date of every domain the subscription uses.
66. **Panel API scripts broke after a panel upgrade.** After PasarGuard 5.5, `create_admin_token` rejects
    database admins without the password hash (`Database admin tokens require a password hash`), so
    every helper that mints a token inside the container failed. Lesson: pass `hashed_password` from the
    `admins` row (see `scripts/panel/node_edit.sh`), and re-run one read-only API call after any panel
    upgrade before relying on the helpers.

Provider tickets: give a short table of measurements with time and time zone, compare the failing
destinations with a working baseline (1.1.1.1, domestic datacenters), state what changed (for example a
new IP), and ask for a concrete fix (re-routing, another IP range, removing a bandwidth limit, moving off
an overloaded host). For in-country providers, describe the problem as connectivity to foreign servers;
do not describe the workload.