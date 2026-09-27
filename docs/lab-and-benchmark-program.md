# Lab And Datacenter Benchmark Program

## Current Public Status

All six panel lab entries and the datacenter benchmark template start as `not-run`.
This is intentional: VPNOpsNyx has no authorized lab hosts, panel credentials, or
datacenter endpoints. A structural CI pass is not an infrastructure test pass.

## Panel Lab Procedure

For each supported panel, use a disposable isolated host and the exact upstream
release documented in `guides/panels/`. Follow `docs/api-restore-validation.md`, then
record only sanitized results in a private copy of
`templates/panel-lab-results.example.json`.

A `pass` requires:

1. a UTC timestamp and exact product version or image digest;
2. a read-only API probe using the release-matched contract;
3. restore into a separate target from a checksum-verified backup;
4. object-count and stable-identifier comparison;
5. a disposable client's real data-path test;
6. a sanitized evidence reference with no secrets or production identifiers.

## Datacenter Benchmark Procedure

Use aliases instead of provider names or addresses. Record the actual vantage point,
confirm the operator VPN and system proxy are disabled, use a fixed duration, and
measure latency, jitter, loss, throughput, retransmits, and CPU at the same time.
Repeat at off-peak and peak periods before drawing conclusions.

Never commit public IPs, customer domains, provider account data, credentials, or raw
logs. Keep the filled evidence privately unless it has been independently sanitized.

## Validation

Run:

```bash
python3 scripts/validate_evidence.py
```

The validator rejects unknown states and rejects `pass` entries without the minimum
version/timestamp/evidence fields. It does not claim that evidence is authentic; a
human reviewer must compare it with sanitized logs and upstream behavior.
