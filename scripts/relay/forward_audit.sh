#!/bin/bash
# Read-only: every port this relay forwards (nftables DNAT, Backhaul and BackPack port maps) and where it
# goes, and a warning for any port that belongs to another brand. Run on each relay of a multi-brand fleet:
#   ssh RELAY 'FORBID="21001 21002 21003" bash -s' < scripts/relay/forward_audit.sh
#
# FORBID  space-separated location ports of the OTHER brand(s). Any match is printed as FOREIGN PORT.
# Pair it with scripts/local/dns_brand_audit.sh (DNS side): brand separation needs both checks, because a
# relay can forward another brand's port even when no DNS name points at it.
echo "== $(hostname)"
{
  nft list ruleset 2>/dev/null | grep -oE 'dport [0-9]+ .*dnat to [0-9.:]+' | sed -E 's/dport ([0-9]+) .*dnat to ([0-9.:]+)/nft \1 -> \2/'
  for f in /etc/backhaul/*.toml /etc/backpack/*.toml; do
    [ -f "$f" ] || continue
    unit=$(basename "$f" .toml)
    grep -oE '"[0-9]+=[^"]+"' "$f" | tr -d '"' | sed -E "s/^([0-9]+)=(.*)/$unit \1 -> \2/"
  done
} | sort -u | while read -r src port arrow dst; do
  flag=""
  for p in $FORBID; do [ "$p" = "$port" ] && flag="   <-- FOREIGN PORT"; done
  printf '%-14s %-6s -> %s%s\n' "$src" "$port" "$dst" "$flag"
done
