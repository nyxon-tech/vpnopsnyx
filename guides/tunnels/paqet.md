# Paqet Runbook

**Core:** https://github.com/hanselime/paqet  
**Manager:** https://github.com/behzadea12/Paqet-Tunnel-Manager

Treat raw-packet and firewall changes as high impact. Confirm kernel capability,
interface names, routes, MTU, packet-filter policy, and an out-of-band SSH path.
Pin the core version and inspect the manager before use; it can change sysctl,
iptables, limits, and systemd.

Verify process health, packet counters in both directions, retransmission/loss, and
an application request through the tunnel. Test persistence only after foreground
traffic succeeds.

**Rollback:** stop the manager/core, remove only rules and routes recorded during
the change, restore sysctl/limits and prior services, then confirm normal routing.
