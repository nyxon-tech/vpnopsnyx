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
