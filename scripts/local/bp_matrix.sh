#!/bin/bash
# Measure many temporary BackPack xDi links in one run, FORWARD (relay dials exit) or REVERSE (exit dials
# relay), from the operator's workstation. Each link uses scripts/node/bptest.sh (30-minute transient unit),
# is measured from the relay side, then removed on both ends. Nothing persistent is created.
#
#   LINKS="N DIR RELAY RELAY_JUMP RELAY_IP EXIT EXIT_JUMP EXIT_IP TEST LABEL" scripts/local/bp_matrix.sh
#     N        small integer, unique per line (tunnel /30 = 10.79.N.0, port 29900+N)
#     DIR      fwd | rev
#     *_JUMP   ssh ProxyJump host, or - for none
#     TEST     a port on the exit that serves /100MB.bin (scripts/node/nettest.sh), or
#              fb:PORT to time three HTTPS requests to an Xray Reality port instead (when a firewall on the
#              exit blocks the test file; only proves the listener path, not throughput)
#
# Example (one line per candidate):
#   LINKS='1 rev relay-a - 203.0.113.10 exit-de - 198.51.100.20 fb:21001 DE<-relay-a
#   2 fwd relay-b relay-a 203.0.113.11 exit-fi - 198.51.100.21 18889 relay-b->FI' scripts/local/bp_matrix.sh
#
# Read the result with care:
#   * Test candidates ONE AT A TIME per exit. An exit that dials two xDi links at once may keep only one
#     working ("xdi echoes ... carry a different tunnel's tag"); this script already runs links in sequence.
#   * A fresh path can be filtered within hours. Re-measure the next day before calling it stable, and
#     confirm with real users (scripts/node/realuse.sh) after it carries traffic.
set -u
BPTEST=$(dirname "$0")/../node/bptest.sh
rsh() { local h=$1 j=$2; shift 2; if [ "$j" = - ]; then ssh -o ConnectTimeout=15 "$h" "$@"; else ssh -o ConnectTimeout=15 -J "$j" "$h" "$@"; fi; }
while read -r N DIR R RJ RIP E EJ EIP TEST LABEL; do
  [ -z "${N:-}" ] && continue
  T=$(openssl rand -hex 32); A=10.79.$N.1; B=10.79.$N.2; P=$((29900+N))
  if [ "$DIR" = rev ]; then  # relay listens, exit dials the relay
    { echo "$T"; cat "$BPTEST"; } | rsh "$R" "$RJ" "f=\$(mktemp); read -r t; cat > \$f; printf '%s\n' \"\$t\" | NAME=mx$N ROLE=listen ADDR=0.0.0.0:$P CARRIER=xdi IFACE=bpmx$N LIP=$A/30 PIP=$B PORTS='' bash \$f >/dev/null; rm -f \$f"
    { echo "$T"; cat "$BPTEST"; } | rsh "$E" "$EJ" "f=\$(mktemp); read -r t; cat > \$f; printf '%s\n' \"\$t\" | NAME=mx$N ROLE=dial ADDR=$RIP:$P CARRIER=xdi IFACE=bpmx$N LIP=$B/30 PIP=$A PORTS='' bash \$f >/dev/null; rm -f \$f"
  else                       # exit listens, relay dials the exit
    { echo "$T"; cat "$BPTEST"; } | rsh "$E" "$EJ" "f=\$(mktemp); read -r t; cat > \$f; printf '%s\n' \"\$t\" | NAME=mx$N ROLE=listen ADDR=0.0.0.0:$P CARRIER=xdi IFACE=bpmx$N LIP=$B/30 PIP=$A PORTS='' bash \$f >/dev/null; rm -f \$f"
    { echo "$T"; cat "$BPTEST"; } | rsh "$R" "$RJ" "f=\$(mktemp); read -r t; cat > \$f; printf '%s\n' \"\$t\" | NAME=mx$N ROLE=dial ADDR=$EIP:$P CARRIER=xdi IFACE=bpmx$N LIP=$A/30 PIP=$B PORTS='' bash \$f >/dev/null; rm -f \$f"
  fi
  unset T; sleep 12
  case "$TEST" in
    fb:*) Q="s=''; for i in 1 2 3; do s=\"\$s \$(curl -sk -m8 -o /dev/null -w '%{http_code}/%{time_total}s' --resolve www.example.com:${TEST#fb:}:$B https://www.example.com:${TEST#fb:}/)\"; done" ;;
    *)    Q="s=''; for i in 1 2; do s=\"\$s \$(curl -s -m12 -o /dev/null -w '%{speed_download}' http://$B:$TEST/100MB.bin | awk '{printf \"%.0fMbit\", \$1*8/1e6}')\"; done" ;;
  esac
  RES=$(rsh "$R" "$RJ" "l=\$(ping -c8 -W1 -i0.3 $B | grep -oE '[0-9.]+% packet' | cut -d% -f1); $Q; echo \"loss=\$l% \$s\"; systemctl stop bp-mx$N; rm -f /etc/backpack/mx$N.toml" </dev/null 2>&1 | tail -1)
  rsh "$E" "$EJ" "systemctl stop bp-mx$N; rm -f /etc/backpack/mx$N.toml" </dev/null >/dev/null 2>&1
  printf '%-22s %-4s %s\n' "$LABEL" "$DIR" "$RES"
done <<< "${LINKS:?set LINKS}"
