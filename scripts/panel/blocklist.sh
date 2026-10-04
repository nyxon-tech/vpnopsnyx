#!/bin/bash
# Persistent source-IP blocklist on a panel host (or any host): its own nftables table plus a boot unit.
# Operator approval required. Only the listed addresses are dropped; nothing else in the firewall changes.
#   ssh HOST 'ACTION=add IPS="198.51.100.7 203.0.113.9" bash -s' < scripts/panel/blocklist.sh
#   ssh HOST 'ACTION=del IPS="198.51.100.7" bash -s' < scripts/panel/blocklist.sh
#   ssh HOST 'ACTION=list bash -s' < scripts/panel/blocklist.sh
#
# Drops in an inet input hook, which covers a panel container in host network mode. A container with a
# published (DNAT-ed) port is reached through forward, not input: check `docker inspect` first.
# Never add relay addresses: users and bots that reach the panel through a relay share its address.
# Undo everything: systemctl disable --now blocklist && rm /etc/nftables-blocklist.nft
set -e
FILE=/etc/nftables-blocklist.nft
ACTION=${ACTION:-list}
cur=""
[ -f "$FILE" ] && cur=$(grep -oE 'elements = \{[^}]*\}' "$FILE" | grep -oE '[0-9]+(\.[0-9]+){3}' | tr '\n' ' ')
case "$ACTION" in
  list) echo "blocked: ${cur:-none}"; nft list table inet blocklist 2>/dev/null | grep counter || true; exit 0 ;;
  add)  for ip in $IPS; do [[ $ip =~ ^[0-9]+(\.[0-9]+){3}$ ]] || { echo "bad IP $ip"; exit 1; }; done
        new=$(echo $cur $IPS | tr ' ' '\n' | sort -u | grep . | tr '\n' ' ') ;;
  del)  new=$(echo $cur | tr ' ' '\n' | grep -vxF -f <(echo $IPS | tr ' ' '\n') | tr '\n' ' ' || true) ;;
  *)    echo "ACTION must be list, add or del"; exit 1 ;;
esac
el=$(echo $new | sed 's/ /, /g')
TMP=$(mktemp)
cat > "$TMP" <<EOF
table inet blocklist {
  set bad4 { type ipv4_addr;${el:+ elements = { $el };} }
  chain input { type filter hook input priority -10; ip saddr @bad4 counter drop; }
}
EOF
sed 's/table inet blocklist /table inet blocklist_check /' "$TMP" > "$TMP.c"; nft -c -f "$TMP.c"; rm -f "$TMP.c"
mv "$TMP" "$FILE"; chmod 644 "$FILE"
cat > /etc/systemd/system/blocklist.service <<EOF
[Unit]
Description=Blocked source IPs (table inet blocklist)
After=network-online.target
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=-/usr/sbin/nft delete table inet blocklist
ExecStart=/usr/sbin/nft -f $FILE
ExecStop=/usr/sbin/nft delete table inet blocklist
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload; systemctl enable blocklist >/dev/null 2>&1; systemctl restart blocklist
echo "$(hostname): blocklist $(systemctl is-active blocklist); blocked: ${new:-none}"
