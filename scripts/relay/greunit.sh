#!/bin/bash
# Persistent point-to-point GRE (IP protocol 47) link as a oneshot systemd unit. Run once on EACH end,
# with LOCAL/REMOTE swapped and the two addresses of one /30:
#   relay: ssh RELAY 'N=gde LOCAL=203.0.113.10 REMOTE=198.51.100.20 ADDR=10.90.0.1/30 bash -s' < scripts/relay/greunit.sh
#   exit:  ssh EXIT  'N=grrelay LOCAL=198.51.100.20 REMOTE=203.0.113.10 ADDR=10.90.0.2/30 bash -s' < scripts/relay/greunit.sh
# Then DNAT the relay's public location port to the exit's tunnel address (scripts/relay/dnat.sh).
#
# N       interface and unit name (gre-N.service), at most 15 characters
# LOCAL   this host's public IPv4 (must be the address the packets leave from)
# REMOTE  the other end's public IPv4
# ADDR    this end's tunnel address in CIDR form
# MTU     optional, default 1476 (1500 minus the GRE and outer IP headers)
#
# Measure first with scripts/relay/gretest.sh and delete its gt_*/st_* links for the same endpoint pair:
# the kernel refuses a second GRE tunnel with the same local/remote ("File exists").
# GRE has no keys or encryption: it only moves already-encrypted VPN traffic between two of your hosts.
# If a host's public IP changes, LOCAL/REMOTE in the unit files on BOTH ends must be updated.
# Undo: systemctl disable --now gre-N && rm /etc/systemd/system/gre-N.service
set -e
: "${N:?N}" "${LOCAL:?LOCAL}" "${REMOTE:?REMOTE}" "${ADDR:?ADDR}"
MTU=${MTU:-1476}
[ ${#N} -le 15 ] || { echo "N longer than 15 characters"; exit 1; }
ip -4 addr show | grep -q "inet $LOCAL/" || echo "WARNING: $LOCAL is not configured on this host (wrong LOCAL, or the IP changed)"
cat > /etc/systemd/system/gre-$N.service <<EOF
[Unit]
Description=GRE link $N ($LOCAL <-> $REMOTE)
After=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=-/sbin/ip link del $N
ExecStart=/sbin/ip tunnel add $N mode gre local $LOCAL remote $REMOTE ttl 255
ExecStart=/sbin/ip addr add $ADDR dev $N
ExecStart=/sbin/ip link set $N mtu $MTU up
ExecStop=/sbin/ip link del $N
[Install]
WantedBy=multi-user.target
EOF
modprobe ip_gre 2>/dev/null || true
systemctl daemon-reload
systemctl enable --now gre-$N >/dev/null 2>&1
echo "$(hostname): gre-$N $(systemctl is-active gre-$N) $ADDR ($LOCAL -> $REMOTE)"
