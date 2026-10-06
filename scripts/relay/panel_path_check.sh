#!/bin/bash
# Read-only: test the panel / subscription domain through EVERY address in its DNS record, the way users
# and bots use it. Run on an in-country probe (a relay of the same brand is fine), ideally from 2-3
# different datacenters, and once from abroad for bots:
#   ssh PROBE 'NAME=sub.example.com PORT=8000 IPS="198.51.100.10 203.0.113.20" bash -s' < scripts/relay/panel_path_check.sh
#
# For each IP: a GET of the panel page (about 200 KB, like a subscription download) with bytes and time,
# and a POST login with a throwaway username (expect 401 quickly; the request body must arrive).
# Field notes (operator-observed):
#   * A direct panel IP answered small requests but delivered 0 bytes of the page in 18 s from two of three
#     in-country datacenters (bulk throttling of that foreign IP), so about half of the users who resolved
#     to it got a broken subscription link. Remove such an address from the record.
#   * Through an ICMP-carried (xDi) relay, GET worked but POST bodies stalled ~16 minutes and ended in 400,
#     so a sales bot's orders failed. A GET-only check would have passed.
NAME=${NAME:?NAME}; PORT=${PORT:-443}; IPS=${IPS:?IPS}; T=${T:-18}
for ip in $IPS; do
  g=$(curl -sk -m "$T" -o /dev/null -w '%{http_code} %{size_download}B %{time_total}s' \
      --resolve "$NAME:$PORT:$ip" "https://$NAME:$PORT/" 2>/dev/null)
  p=$(curl -sk -m "$T" -o /dev/null -w '%{http_code} %{time_total}s' -X POST \
      -d 'username=path_check_probe&password=x' --resolve "$NAME:$PORT:$ip" \
      "https://$NAME:$PORT/api/admin/token" 2>/dev/null)
  printf '%-16s GET %-28s POST %s\n' "$ip" "${g:-fail}" "${p:-fail}"
done
