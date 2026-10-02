#!/bin/bash
# Brand-separation audit for operators who run several brands on separate relay sets. Lists every A
# record in one Cloudflare account that points at a relay belonging to ANOTHER brand. Read-only.
#
#   TOKEN_FILE=~/.config/cloudflare/api_token_brand_a FORBIDDEN="203.0.113.10 203.0.113.11" \
#     scripts/local/dns_brand_audit.sh
# Run once per account with that brand's forbidden list (the other brands' relay IPs). Silence = clean.
# Pair it with a look at each relay's DNAT/tunnel targets (scripts/node/bpstatus.sh, `nft list ruleset`).
set -u
CF="$(dirname "$0")/cf.sh"
: "${FORBIDDEN:?space-separated relay IPs that this account must not use}"
for z in $(TOKEN_FILE=${TOKEN_FILE:-} bash "$CF" zones | awk '{print $1}'); do
  TOKEN_FILE=${TOKEN_FILE:-} bash "$CF" records "$z" | awk -v L="$FORBIDDEN" -v z="$z" '
    BEGIN { n = split(L, a, " "); for (i = 1; i <= n; i++) bad[a[i]] = 1 }
    $2 == "A" && ($3 in bad) { print "CROSS-BRAND: " $1 " -> " $3 "  (zone " z ")" }'
done
