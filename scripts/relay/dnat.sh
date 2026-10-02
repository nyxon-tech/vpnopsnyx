#!/bin/bash
# Relay DNAT table (nftables) + boot unit. Run ON THE RELAY:
#   ssh RELAY 'MAP="21001:198.51.100.10 21002:10.77.1.2" bash -s' < scripts/relay/dnat.sh
#
# MAP   space-separated "port:target_ip" pairs; each port is forwarded unchanged to target_ip:port.
#       target_ip may be an exit's public IP (plain DNAT) or the far end of an L3 tunnel
#       (e.g. a BackPack peer 10.x.y.2) when the relay's DC breaks direct traffic to that exit.
# TABLE nft table / unit name suffix (default relay_dnat -> unit relay-dnat.service,
#       file /etc/nftables-relay-dnat.nft). Use a different TABLE per fleet on shared relays.
# DRYRUN=1          print the file and run `nft -c` only; change nothing (review before applying).
# ALLOW_LISTENER=1  allow ports that already have a local listener. DNAT at priority -110 bypasses
#                   it for traffic from outside; local tests still reach the listener.
#
# Re-running replaces the whole table with the new MAP (existing flows keep their conntrack mapping).
# Undo: systemctl disable --now <unit>
set -e
TABLE=${TABLE:-relay_dnat}
UNIT=$(echo "$TABLE" | tr _ -)
FILE=/etc/nftables-$UNIT.nft
[ -n "$MAP" ] || { echo "MAP is empty"; exit 1; }
if [ "${ALLOW_LISTENER:-0}" != 1 ]; then
  for m in $MAP; do p=${m%%:*}
    ss -Hltn "( sport = :$p )" | grep -q . && { echo "ABORT: port $p has a local listener (set ALLOW_LISTENER=1 to bypass it deliberately)"; exit 1; }
  done
fi
pre=""; post=""
for m in $MAP; do p=${m%%:*}; ip=${m##*:}
  pre="$pre    tcp dport $p counter dnat to $ip:$p
"
  post="$post    ip daddr $ip tcp dport $p counter masquerade
"
done
NEW=$(mktemp)
cat > "$NEW" <<EOF
table ip $TABLE {
  chain pre  { type nat hook prerouting priority -110;
$pre  }
  chain post { type nat hook postrouting priority 90;
$post  }
  chain mssclamp { type filter hook forward priority -150;
    tcp flags syn tcp option maxseg size set rt mtu;
  }
}
EOF
# validate under a throwaway table name so a live table of the same name is untouched
sed "s/^table ip $TABLE /table ip ${TABLE}_check /" "$NEW" > "$NEW.check"
nft -c -f "$NEW.check"; rm -f "$NEW.check"
if [ "${DRYRUN:-0}" = 1 ]; then
  echo "--- would write $FILE:"; cat "$NEW"
  [ -f "$FILE" ] && { echo "--- diff vs current:"; diff "$FILE" "$NEW" || true; }
  rm -f "$NEW"; exit 0
fi
[ -f "$FILE" ] && cp -a "$FILE" "$FILE.bak-$(date +%Y%m%d%H%M)"
mv "$NEW" "$FILE"; chmod 644 "$FILE"
cat > /etc/systemd/system/$UNIT.service <<EOF
[Unit]
Description=Relay DNAT table $TABLE
After=network-online.target
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=-/usr/sbin/nft delete table ip $TABLE
ExecStart=/usr/sbin/nft -f $FILE
# Re-apply conntrack limits here: at boot sysctl.d runs before nf_conntrack is loaded, so the limits in
# the sysctl file are silently skipped and the kernel default (8192 on a 1 GB host) fills up.
ExecStartPost=-/usr/sbin/sysctl -q -p /etc/sysctl.d/99-$UNIT.conf
ExecStop=/usr/sbin/nft delete table ip $TABLE
[Install]
WantedBy=multi-user.target
EOF
# conntrack_max sized to RAM (~300 bytes per entry): 64k per GB, at least 65536, at most 1048576.
CT_MAX=$(awk '/MemTotal/{m=int($2/1048576*65536); if (m<65536) m=65536; if (m>1048576) m=1048576; print m}' /proc/meminfo)
printf "net.ipv4.ip_forward=1\nnet.netfilter.nf_conntrack_max=%s\nnet.netfilter.nf_conntrack_tcp_timeout_established=10800\n" "$CT_MAX" > /etc/sysctl.d/99-$UNIT.conf
echo nf_conntrack > /etc/modules-load.d/conntrack.conf
modprobe nf_conntrack 2>/dev/null || true
sysctl -q -p /etc/sysctl.d/99-$UNIT.conf
systemctl daemon-reload
systemctl enable $UNIT.service >/dev/null 2>&1
systemctl restart $UNIT.service
echo "$(hostname): $UNIT $(systemctl is-active $UNIT)/$(systemctl is-enabled $UNIT)"
nft list table ip $TABLE | grep "dnat to"
