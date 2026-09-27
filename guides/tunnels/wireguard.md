# WireGuard Runbook

**Source:** https://www.wireguard.com/ and https://github.com/WireGuard/wireguard-tools

Generate private keys locally and never print or commit them. Record interface,
addresses, peer public keys, endpoints, AllowedIPs, listen ports, MTU, DNS, routing,
NAT, and firewall state. Validate that AllowedIPs do not steal the management route.

Bring up one peer at a time. Verify `latest handshake`, increasing transfer counters,
route selection, DNS where applicable, and a real application request. Handshake
alone is insufficient if return routing or MTU is broken.

**Rollback:** bring down the new interface, restore the previous config and routing/
firewall snapshots, bring up the old interface, and verify management plus data paths.
Rotate any key that was exposed during diagnosis.
