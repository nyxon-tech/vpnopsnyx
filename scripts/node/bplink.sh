#!/bin/bash
# Permanent BackPack L3 link (https://github.com/AminMGMT/BackPack), one side per run.
# The token is read from stdin and never printed. Generate it on the operator's machine and pipe
# the same value to both ends:
#   T=$(openssl rand -hex 32)
#   { echo "$T"; cat scripts/node/bplink.sh; } | ssh EXIT  'read -r t; s=$(cat); printf "%s\n" "$t" | NAME=relay-a ROLE=listen ADDR=0.0.0.0:29701 CARRIER=xdi IFACE=bprelaya LIP=10.77.1.2/30 PIP=10.77.1.1 PORTS= bash -c "$s"'
#   { echo "$T"; cat scripts/node/bplink.sh; } | ssh RELAY 'read -r t; s=$(cat); printf "%s\n" "$t" | NAME=de ROLE=dial ADDR=EXIT_IP:29701 CARRIER=xdi IFACE=bpde LIP=10.77.1.1/30 PIP=10.77.1.2 PORTS="\"21001\"" bash -c "$s"'
#   unset T
#
# env: NAME ROLE(listen on the exit | dial on the relay) ADDR CARRIER(xdi|pck) IFACE(<=15 chars)
#      LIP(cidr) PIP [PORTS='"21001","21002"'  relay side: BackPack listens on these and forwards to PIP:port]
# Leave PORTS empty and use relay DNAT to PIP instead when an old listener still owns the port.
# REVERSE direction (exit dials relay): run ROLE=listen ADDR=0.0.0.0:PORT on the RELAY and ROLE=dial
#      ADDR=RELAY_IP:PORT on the EXIT, then DNAT the relay's public port to the exit's tunnel IP. Use it when
#      the relay->exit ICMP path is filtered; see references/tunnels.md §15 (one dialed xdi link per exit host).
# BIN=/usr/local/bin/backpack-X  run a second BackPack version side by side (both ends should match).
# Undo: systemctl disable --now backpack-NAME   (config kept for re-enable)
set -e
read -r TOKEN
[ ${#TOKEN} -ge 32 ] || { echo "no token on stdin"; exit 1; }
[ -x ${BIN:-/usr/local/bin/backpack} ] || { echo "backpack binary missing (copy it from a host that runs it and verify sha256)"; exit 1; }
mkdir -p /etc/backpack; chmod 700 /etc/backpack
umask 077
cat > /etc/backpack/$NAME.toml <<EOF
[l3]
mode         = "$ROLE"
addr         = "$ADDR"
token        = "$TOKEN"
carrier      = "$CARRIER"
encap        = "gre"
iface        = "$IFACE"
local_ip     = "$LIP"
peer_ip      = "$PIP"
mtu          = 1400
preset       = "balance"
txqueuelen   = 1024
qdisc        = "fq_codel"
sockbuf      = 4194304
ports        = [${PORTS}]
accept_udp   = false
EOF
umask 022
cat > /etc/systemd/system/backpack-$NAME.service <<EOF
[Unit]
Description=BackPack L3 link $NAME
After=network-online.target
Wants=network-online.target
[Service]
ExecStart=${BIN:-/usr/local/bin/backpack} -c /etc/backpack/$NAME.toml
Restart=always
RestartSec=3
LimitNOFILE=1048576
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable backpack-$NAME >/dev/null 2>&1
systemctl restart backpack-$NAME
sleep 2
echo "$(hostname): backpack-$NAME $(systemctl is-active backpack-$NAME) $ROLE $CARRIER $LIP -> $PIP ports=[${PORTS}]"
