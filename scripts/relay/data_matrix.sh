#!/bin/bash
# Relay x location data test, run from an IN-COUNTRY server that is NOT one of the relays tested
# (a request that starts on the relay itself bypasses its DNAT and tests the local listener instead).
#   ssh relay-c 'RELAYS="relay-a:192.0.2.10 relay-b:192.0.2.20" LOCS="de:21001 nl:21002:www.example.com us:21006:tcp" bash -s' < scripts/relay/data_matrix.sh
#
# LOCS entries: name:port[:sni]. sni defaults to www.cloudflare.com (must be served by the
# inbound's Reality dest). Use sni "tcp" for inbounds whose fallback does not answer (test = TCP
# connect only). Speed downloads 6 MB through the Reality fallback, so it is capped by the exit's
# own link to the fallback site: an exit with a bad upstream looks slow from every relay.
# TRIES=N repeats the TLS test N times per cell and prints "code(ok/N)". Use TRIES>=6 always and
# TRIES>=20 for a location split across two exits by a numgen DNAT: a half-dead tunnel then fails
# 30-70% of the time and a single probe passes by luck. One tunnel server can wedge after a network
# blip while its client, the panel and every agent still report healthy.
# This proves the path reaches Xray. It does NOT prove real users get data: confirm with
# scripts/node/realuse.sh on the exit.
SIZE=${SIZE:-6000000}
TRIES=${TRIES:-1}
for r in ${RELAYS:?}; do rn=${r%%:*}; rip=${r##*:}
  printf "%-10s" "$rn"
  for l in ${LOCS:?}; do IFS=: read -r ln lp lsni <<< "$l"; lsni=${lsni:-www.cloudflare.com}
    if [ "$lsni" = tcp ]; then
      r2=$(timeout 5 bash -c "</dev/tcp/$rip/$lp" 2>/dev/null && echo tcp-ok || echo FAIL)
      printf " %s:%s" "$ln" "$r2"; continue
    fi
    d=000; ok=0
    for _ in $(seq 1 "$TRIES"); do
      c=$(curl -sk -m 8 --resolve "$lsni:$lp:$rip" -o /dev/null -w "%{http_code}" "https://$lsni:$lp/")
      [ "$c" != 000 ] && { ok=$((ok+1)); d=$c; }
    done
    s=""
    [ "$ok" -gt 0 ] && s=$(curl -sk -m 20 --resolve "speed.cloudflare.com:$lp:$rip" -o /dev/null -w "%{speed_download}" "https://speed.cloudflare.com:$lp/__down?bytes=$SIZE" | awk '{printf "/%.0fM",$1*8/1e6}')
    [ "$TRIES" -gt 1 ] && d="$d($ok/$TRIES)"
    printf " %s:%s%s" "$ln" "$d" "$s"
  done; echo
done
