#!/bin/bash
# Temporary GRE (proto 47) + SIT/6to4 (proto 41) test links between an exit (side a) and relays
# (side b). No third-party script needed; links delete themselves after 15 minutes.
#   exit:  ssh EXIT  'PEERS="r1:RELAY1_IP:0:a r2:RELAY2_IP:1:a" bash -s' < scripts/relay/gretest.sh
#   relay: ssh RELAY1 'PEERS="r1:EXIT_IP:0:b" bash -s' < scripts/relay/gretest.sh
# Then from the relay: ping 172.31.250.(idx*4+1) over GRE, ping -6 fd00:250:idx::1 over SIT, and a
# data/speed test to the exit's location port on 172.31.250.(idx*4+1). A GRE link that passes but
# is pinned at one exact low speed is being rate-limited on purpose.
LOCAL=$(ip -4 route get 1.1.1.1 | grep -oP 'src \K[0-9.]+')
echo "$(hostname) local=$LOCAL"
modprobe ip_gre 2>/dev/null; modprobe sit 2>/dev/null
for p in ${PEERS:?}; do IFS=: read -r n r i s <<< "$p"
  if [ "$s" = a ]; then v4=$((i*4+1)); v6=1; else v4=$((i*4+2)); v6=2; fi
  ip link del gt_$n 2>/dev/null; ip link del st_$n 2>/dev/null
  ip link add gt_$n type gre local $LOCAL remote $r ttl 255 && ip addr add 172.31.250.$v4/30 dev gt_$n && ip link set gt_$n mtu 1400 up
  ip tunnel add st_$n mode sit local $LOCAL remote $r ttl 255 && ip -6 addr add fd00:250:$i::$v6/64 dev st_$n && ip link set st_$n mtu 1400 up
  systemd-run --quiet --on-active=900 --unit=gretest-cleanup-$n /bin/sh -c "ip link del gt_$n; ip link del st_$n" 2>/dev/null
  echo "  $n: gt_$n 172.31.250.$v4  st_$n fd00:250:$i::$v6 -> $r"
done
