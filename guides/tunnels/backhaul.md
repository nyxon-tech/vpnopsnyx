# Backhaul Runbook

**Source:** https://github.com/Musixal/Backhaul  
**Community manager:** https://github.com/Azumi67/Backhaul_script

1. Record source/destination addresses, transport, bind ports, forwarded ports,
   service files, firewall rules, MTU, and last known-good config on both hosts.
2. Prefer the upstream binary and pinned release. Treat the Azumi67 manager as
   `third-party`, `community`, and `high-impact`; inspect both bootstrap stages.
3. Keep tunnel tokens in root-readable secret files, never in Git or command output.
4. Validate configuration, start the server side, then the client side, and inspect
   both logs and sockets.
5. Verify a real application request through every advertised port plus reconnect
   after a controlled service restart.

**Rollback:** stop/disable new units, restore old binaries/configs and firewall rules,
reload systemd, start the old units, and retest the original path.
