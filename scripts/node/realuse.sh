#!/bin/bash
# REAL-USER health per relay, measured on the EXIT. The most trustworthy check in this skill.
#   ssh EXIT 'PORTS="21001 21002" bash -s' < scripts/node/realuse.sh
#
# For every established connection on each location port, groups by peer address (= which relay
# the user came through: the relay IP for DNAT, 127.0.0.1 for a reverse tunnel client on this host,
# the relay's tunnel IP for an L3 tunnel) and prints connections, average MB sent per connection
# and average RTT.
# Healthy: tenths of MB to several MB per connection, RTT of a few hundred ms at most.
# Broken:  ~0.01 MB per connection and/or RTT > 1 s, even when synthetic tests through the same
#          relay pass. Remove that relay from the location's DNS name.
# Note: right after a DNS change, connections still arriving on the old relay are stale cache hits;
#       compare after 10+ minutes.
MIN=${MIN:-10}
for PORT in ${PORTS:?set PORTS}; do
  ss -Htin state established "( sport = :$PORT )" | awk -v p="$PORT" -v min="$MIN" '
    /^[0-9]/ { peer=$4; sub(/:[0-9]+$/,"",peer); gsub(/[\[\]]/,"",peer); sub(/^::ffff:/,"",peer) }
    /bytes_acked/ {
      match($0,/bytes_acked:[0-9]+/); ba=substr($0,RSTART+12,RLENGTH-12)
      rt=0; if (match($0,/rtt:[0-9.]+/)) rt=substr($0,RSTART+4,RLENGTH-4)
      B[peer]+=ba; R[peer]+=rt; N[peer]++ }
    END { for (x in B) if (N[x]>=min) printf "%s :%s from %-16s conns=%-6d MB/conn=%-6.2f rtt=%.0fms\n", h, p, x, N[x], B[x]/N[x]/1e6, R[x]/N[x] }' h="$(hostname | cut -c1-12)"
done
