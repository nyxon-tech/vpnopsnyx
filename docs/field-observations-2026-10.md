# Sanitized Field Observations - October 2026

## Scope And Trust

Continuation of `field-observations-2026-09.md`: the same operator, two brands, several Iranian
relay datacenters. Names, addresses, domains and tokens are removed. Everything here is
`operator-observed`.

## Repeated Patterns

- Relay-dialed xDi links were filtered per destination, often overnight; exit-dialed (reverse) links
  survived the same events and also served an exit whose IP was blacklisted for inbound traffic.
- One exit host could keep only one dialed xDi link working at a time.
- New paths were sometimes filtered within an hour of carrying traffic; next-day re-verification caught
  it, a 10-minute check did not.
- In-country datacenters throttled bulk traffic to a foreign IP while ping and small HTTPS stayed fine.
- A relay's exhausted traffic quota looked exactly like a datacenter outage.
- Sales bots hosted abroad must not reach the panel through in-country relays.
- Moving PasarGuard nodes to a new IP required new node certificates because the panel's TLS check is
  strict and pins the stored certificate.
- An exit with high download but a capped upload, and heavy loss to its panel, failed in ways that no
  relay change could fix.

## Handling Rule

Same as September: prefer live evidence and the deployed version's behavior, label new findings, and
never expose the operator's inventory.
