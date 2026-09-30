#!/bin/bash
# Temporary BackPack L3 test link: same inputs as bplink.sh, but runs as a transient unit
# (bp-NAME) that stops itself after 30 minutes. Use it to measure a path before committing.
# Measure from the relay:  ping -c 10 PIP ;  curl --resolve SNI:PORT:PIP ... (data test through the link)
# Clean up early:          systemctl stop bp-NAME; rm /etc/backpack/NAME.toml
set -e
read -r TOKEN
[ ${#TOKEN} -ge 32 ] || { echo "no token on stdin"; exit 1; }
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
systemctl stop bp-$NAME 2>/dev/null || true
systemd-run --quiet --unit=bp-$NAME -p RuntimeMaxSec=1800 /usr/local/bin/backpack -c /etc/backpack/$NAME.toml
sleep 2
echo "$(hostname): bp-$NAME $(systemctl is-active bp-$NAME) $ROLE $CARRIER $LIP -> $PIP (auto-stop 30 min)"
