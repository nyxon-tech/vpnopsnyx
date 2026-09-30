#!/bin/bash
# Reboot ONE server and verify it came back healthy. Run from the operator's machine.
#   scripts/local/reboot_verify.sh LABEL ssh-args...     e.g.  scripts/local/reboot_verify.sh relay-a relay-a
# Detects the reboot by a changed /proc/sys/kernel/random/boot_id (ping is not enough), waits up to
# 9 minutes, then prints kernel, failed units, enabled tunnel/DNAT units not active, DNAT tables,
# ip_forward and container state. Follow with a data test through the host from another server.
# Order: least-risky host first, the panel host last (a panel restart re-starts Xray on nodes whose
# hosts were rebooted; PasarGuard does not do that by itself).
LABEL=$1; shift
SSH=(ssh -o BatchMode=yes -o ConnectTimeout=10 "$@")
before=$("${SSH[@]}" 'cat /proc/sys/kernel/random/boot_id' 2>/dev/null)
[ -n "$before" ] || { echo "$LABEL: unreachable before reboot, skipped"; exit 1; }
"${SSH[@]}" 'nohup sh -c "sleep 2; systemctl reboot" >/dev/null 2>&1 &' 2>/dev/null
t0=$(date +%s); sleep 25
while :; do
  b=$("${SSH[@]}" 'cat /proc/sys/kernel/random/boot_id' 2>/dev/null)
  [ -n "$b" ] && [ "$b" != "$before" ] && break
  [ $(( $(date +%s) - t0 )) -gt 540 ] && { echo "$LABEL: NOT BACK after 9 min"; exit 2; }
  sleep 10
done
echo "$LABEL: back after $(( $(date +%s) - t0 ))s"
sleep 20
"${SSH[@]}" 'echo "  kernel=$(uname -r) reboot_required=$([ -f /var/run/reboot-required ] && echo YES || echo no)"
f=$(systemctl --failed --no-legend --plain | awk "{print \$1}" | tr "\n" ","); echo "  failed_units=[${f%,}]"
d=""; for u in $(systemctl list-unit-files --no-legend --plain --state=enabled | awk "{print \$1}" | grep -E "^(backpack-|relay-dnat|backhaul)"); do systemctl is-active -q $u || d="$d$u,"; done; echo "  enabled_tunnel_units_not_active=[${d%,}]"
echo "  dnat_tables=$(nft list tables 2>/dev/null | awk "{print \$3}" | grep -i dnat | tr "\n" ",") ip_forward=$(sysctl -n net.ipv4.ip_forward)"
k=$(docker ps -a --format "{{.Names}}:{{.Status}}" 2>/dev/null | grep -v ":Up" | tr "\n" ","); echo "  docker_not_up=[${k%,}] docker_up=$(docker ps -q 2>/dev/null | wc -l)"' 2>&1
