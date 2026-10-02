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
