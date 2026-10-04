#!/bin/bash
# Read-only: who is failing to log in to a PasarGuard panel, from the panel container's access log.
#   ssh PANEL 'bash -s' < scripts/panel/auth_failures.sh
#   SINCE=72h CONTAINER=pasarguard-pasarguard-1 TOP=10 ...
#
# Prints, per source address: failed admin logins (401 on POST /api/admin/token), successful logins, and
# the first/last time seen. A source with thousands of failures and zero successes is either a bot or a
# reseller integration still using an old password, or someone guessing passwords. Ask the operator which;
# block with scripts/panel/blocklist.sh only after they decide.
# Sources 127.0.0.1 and private tunnel addresses are requests that came through a relay; their real
# origin is not visible here.
SINCE=${SINCE:-24h}; CONTAINER=${CONTAINER:-pasarguard-pasarguard-1}; TOP=${TOP:-10}
docker logs --since "$SINCE" "$CONTAINER" 2>&1 | grep '"POST /api/admin/token' | awk '
  { src=$5; t=$2" "substr($3,1,8)
    if ($0 ~ /" 401 /) bad[src]++; else if ($0 ~ /" 200 /) ok[src]++
    if (!(src in first)) first[src]=t; last[src]=t }
  END { for (s in first) printf "%8d fail %6d ok  %-18s %s .. %s\n", bad[s], ok[s], s, first[s], last[s] }' \
  | sort -rn | head -n "$TOP"
