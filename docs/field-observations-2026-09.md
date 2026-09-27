# Sanitized Field Observations - September 2026

## Scope And Trust

These observations came from one operator managing two PasarGuard panels and relay
infrastructure across several Iranian networks. Names, addresses, domains, tokens,
and customer data were removed. They are labeled `operator-observed`: useful incident
evidence, but not proof that every provider, release, or network behaves the same way.

## Repeated Patterns

- Operator-side VPN/TUN routing produced false outage reports for relays that reject
  inbound traffic from abroad. Always record the test vantage point.
- A TLS/Reality fallback request isolated listener reachability but did not prove
  authentication, outbound routing, non-TLS inbounds, or throughput.
- BackPack xDi recovered useful throughput on some TCP-impaired paths, consumed
  meaningful CPU on small relays, and did not fix an already lossy IP path.
- SIT/6to4 was blocked on the reviewed networks; GRE varied from usable to sharply
  rate-limited. Temporary reversible tests were more reliable than provider claims.
- A rebooted PasarGuard exit could reconnect its node container while leaving Xray
  stopped until the control plane resent startup state.
- A host service colliding with an inbound port could make the whole Xray core fail.
- Relay headroom and exit CPU/packet loss were separate bottlenecks; DNS steering
  helped only when the chosen relay and exit both had capacity.
- Package upgrades and Docker restarts required host-by-host ordering, durable logs,
  and post-reboot verification of actual data paths.
- Standalone ACME renewal failed when another service owned port 80; Cloudflare proxy
  mode could hide an expired origin certificate from ordinary users.

## Numeric Evidence

The source notes contain point-in-time throughput, loss, CPU, and traffic values.
VPNOpsNyx intentionally does not turn them into universal thresholds. Re-measure on
the current path, compare both directions, and preserve timestamps and tool output.

## Verified External Foundations

- REALITY configuration and fallback behavior: https://github.com/XTLS/REALITY
- BackPack capabilities and operational model: https://github.com/AminMGMT/BackPack
- nftables DNAT/masquerade semantics: https://wiki.nftables.org/wiki-nftables/index.php/Performing_Network_Address_Translation_(NAT)
- needrestart project and modes: https://github.com/liske/needrestart
- Certbot renewal hooks: https://eff-certbot.readthedocs.io/en/stable/using.html#pre-and-post-validation-hooks
- Cloudflare SSL modes: https://developers.cloudflare.com/ssl/origin-configuration/ssl-modes/
- Cloudflare proxied ports: https://developers.cloudflare.com/fundamentals/reference/network-ports/
- Cloudflare API tokens: https://developers.cloudflare.com/fundamentals/api/get-started/create-token/

## Handling Rule

When an observation conflicts with current upstream documentation or live evidence,
prefer the deployed version's authoritative behavior and update this note with the
date, scope, and sanitized evidence. Never expose the operator's fleet inventory.
