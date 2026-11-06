#!/bin/bash
# Host tuning baseline for an exit or relay: BBR+fq, conntrack limits that survive a reboot,
# and RPS/RFS for single-queue network cards. Run ON THE HOST:
#   ssh HOST 'bash -s' < scripts/node/host_tune.sh                    # audit only (default)
#   ssh HOST 'APPLY=1 bash -s' < scripts/node/host_tune.sh            # write files and apply
#
# APPLY=1         write the files below and apply them live. Nothing is restarted, no connection drops.
# CT_MAX          nf_conntrack_max to set (default: 64k per GB of RAM, between 262144 and 1048576).
# CT_TIMEOUT      tcp established timeout in seconds (default 7200; the kernel default is 432000 = 5 days).
# SKIP_BBR=1 / SKIP_CT=1 / SKIP_RPS=1   leave one part out.
#
# Files written (all new, all removable):
#   /etc/sysctl.d/98-bbr.conf  /etc/modules-load.d/bbr.conf
#   /etc/sysctl.d/97-conntrack.conf  /etc/modules-load.d/nf_conntrack.conf
#   /usr/local/sbin/rps-spread.sh  /etc/systemd/system/rps-spread.service
# Undo: delete those files, `systemctl disable --now rps-spread`, `sysctl --system`.
#
# Do not overwrite a host that already has its own conntrack file (for example the DNAT unit written
# by relay/dnat.sh): the script reports it and leaves conntrack alone unless FORCE_CT=1.
# The thresholds are operator-observed examples, not universal values.
set -u
APPLY=${APPLY:-0}
say() { printf '%s\n' "$*"; }
[ "$(id -u)" = 0 ] || { say "run as root"; exit 1; }

ram_gb=$(awk '/MemTotal/{printf "%d", ($2+1048575)/1048576}' /proc/meminfo)
cpus=$(nproc)
say "== host: ${cpus} cpu, ${ram_gb} GB RAM, kernel $(uname -r)"

# ---------- BBR ----------
if [ "${SKIP_BBR:-0}" != 1 ]; then
  cc=$(sysctl -n net.ipv4.tcp_congestion_control); qd=$(sysctl -n net.core.default_qdisc)
  say "== tcp: congestion=$cc qdisc=$qd (want bbr + fq)"
  if [ "$APPLY" = 1 ] && [ "$cc" != bbr ]; then
    modprobe tcp_bbr 2>/dev/null || say "tcp_bbr is not available in this kernel; skipped"
    if grep -qw bbr /proc/sys/net/ipv4/tcp_available_congestion_control; then
      echo tcp_bbr > /etc/modules-load.d/bbr.conf
      printf 'net.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr\n' > /etc/sysctl.d/98-bbr.conf
      sysctl -q -p /etc/sysctl.d/98-bbr.conf
      say "   applied: now $(sysctl -n net.ipv4.tcp_congestion_control)/$(sysctl -n net.core.default_qdisc)"
    fi
  fi
fi

# ---------- conntrack ----------
if [ "${SKIP_CT:-0}" != 1 ]; then
  modprobe nf_conntrack 2>/dev/null
  max=$(sysctl -n net.netfilter.nf_conntrack_max 2>/dev/null || echo 0)
  cnt=$(sysctl -n net.netfilter.nf_conntrack_count 2>/dev/null || echo 0)
  to=$(sysctl -n net.netfilter.nf_conntrack_tcp_timeout_established 2>/dev/null || echo 0)
  say "== conntrack: count=$cnt max=$max established_timeout=${to}s"
  other=$(grep -rlE 'nf_conntrack_(max|tcp_timeout_established)' /etc/sysctl.conf /etc/sysctl.d /etc/systemd/system 2>/dev/null | grep -v '/97-conntrack.conf' | tr '\n' ' ')
  [ -n "$other" ] && say "   other files set conntrack: $other"
  # A file that sets a value is not proof: compare it with the live value. When they differ the module
  # loaded after sysctl ran, which is the usual reason limits are "lost" after a reboot.
  [ -f /etc/modules-load.d/nf_conntrack.conf ] || grep -rqw nf_conntrack /etc/modules-load.d 2>/dev/null \
    || say "   WARNING: nothing loads nf_conntrack early at boot; sysctl lines for it can be skipped"
  if [ "$APPLY" = 1 ]; then
    if [ -n "$other" ] && [ "${FORCE_CT:-0}" != 1 ]; then
      say "   skipped: existing conntrack settings found (set FORCE_CT=1 to add ours anyway)"
    else
      want=${CT_MAX:-$(( ram_gb * 65536 ))}
      [ "$want" -lt 262144 ] && want=262144
      [ "$want" -gt 1048576 ] && want=1048576
      [ "$max" -gt "$want" ] && want=$max          # never lower an existing limit
      echo nf_conntrack > /etc/modules-load.d/nf_conntrack.conf
      printf 'net.netfilter.nf_conntrack_max=%s\nnet.netfilter.nf_conntrack_tcp_timeout_established=%s\n' \
        "$want" "${CT_TIMEOUT:-7200}" > /etc/sysctl.d/97-conntrack.conf
      sysctl -q -p /etc/sysctl.d/97-conntrack.conf
      say "   applied: max=$(sysctl -n net.netfilter.nf_conntrack_max) timeout=$(sysctl -n net.netfilter.nf_conntrack_tcp_timeout_established)"
    fi
  fi
  dmesg 2>/dev/null | grep -c 'nf_conntrack: table full' | sed 's/^/   dmesg "table full" lines: /'
fi

# ---------- RPS / RFS ----------
if [ "${SKIP_RPS:-0}" != 1 ]; then
  nic=$(ip -o route get 1.1.1.1 2>/dev/null | sed -n 's/.* dev \([^ ]*\).*/\1/p')
  rxq=$(ls -d /sys/class/net/"$nic"/queues/rx-* 2>/dev/null | wc -l)
  cur=$(cat /sys/class/net/"$nic"/queues/rx-0/rps_cpus 2>/dev/null || echo "?")
  say "== nic: $nic rx-queues=$rxq rps_cpus(rx-0)=$cur cpus=$cpus"
  si=$(awk '/^cpu[0-9]/{s=$8; t=0; for(i=2;i<=NF;i++)t+=$i; printf "%s:%d%% ", $1, (t?s*100/t:0)}' /proc/stat)
  say "   softirq share since boot: $si"
  if [ "$rxq" = 1 ] && [ "$cpus" -gt 1 ]; then
    say "   single-queue card on a multi-core host: RPS recommended"
    if [ "$APPLY" = 1 ]; then
      cat > /usr/local/sbin/rps-spread.sh <<'EOS'
#!/bin/bash
# Spread receive softirq of single-queue NICs over all CPUs (RPS) with flow steering (RFS).
n=$(nproc); mask=$(printf '%x' $(( (1<<n) - 1 )))
echo 32768 > /proc/sys/net/core/rps_sock_flow_entries
for d in /sys/class/net/*; do
  i=${d##*/}; [ "$i" = lo ] && continue; [ -e "$d/device" ] || continue
  q=$(ls -d "$d"/queues/rx-* 2>/dev/null | wc -l); [ "$q" = 1 ] || continue
  echo "$mask" > "$d/queues/rx-0/rps_cpus"
  echo 32768 > "$d/queues/rx-0/rps_flow_cnt"
done
exit 0
EOS
      chmod +x /usr/local/sbin/rps-spread.sh
      cat > /etc/systemd/system/rps-spread.service <<'EOS'
[Unit]
Description=Spread NIC receive softirq over all CPUs (RPS/RFS)
After=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/rps-spread.sh
[Install]
WantedBy=multi-user.target
EOS
      systemctl daemon-reload && systemctl enable --now rps-spread.service
      say "   applied: rps_cpus(rx-0)=$(cat /sys/class/net/"$nic"/queues/rx-0/rps_cpus)  unit: $(systemctl is-active rps-spread.service)"
    fi
  fi
fi
[ "$APPLY" = 1 ] || say "(audit only; re-run with APPLY=1 to apply the missing parts)"
