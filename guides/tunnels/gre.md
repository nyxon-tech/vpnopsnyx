# GRE, GRE6, 6TO4, SIT, And IPIP Runbook

**Community manager:** https://github.com/Azumi67/6TO4-GRE-IPIP-SIT  
**Trust:** `verified`, `third-party`, `community`; upstream describes it as educational.

Before changing interfaces, record public addresses, IP families, interface names,
routes, policy routing, MTU, firewall, forwarding sysctl, and provider protocol
support. Keep an out-of-band console open. Prefer explicit `iproute2` configuration
when the topology is understood; inspect manager scripts before execution.

Verify interface state, routes, bidirectional tunnel-endpoint ping where allowed,
path MTU, packet counters, source address, and the real transported application.
Avoid declaring success from interface `UP` alone.

**Rollback:** delete only newly created routes/interfaces/rules, restore forwarding
and firewall snapshots, restore prior persistent network configuration, and test the
original public route. Never flush an entire firewall remotely.
