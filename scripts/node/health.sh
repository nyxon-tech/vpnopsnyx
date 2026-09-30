#!/bin/bash
# One-line health snapshot for any server (exit, relay or panel host).
#   ssh HOST 'LABEL=relay-a bash -s' < scripts/node/health.sh
# Prints CPU busy/steal, NIC rx/tx, TCP retransmit %, free download headroom, RAM, disk, uptime,
# failed units, enabled tunnel/DNAT units that are not active, and containers that are not Up.
i=$(ip route | awk '/default/{print $5; exit}')
read -r _ u n s id w q sq st _ < /proc/stat; r1=$(cat /sys/class/net/$i/statistics/rx_bytes); t1=$(cat /sys/class/net/$i/statistics/tx_bytes)
rs1=$(awk '/^Tcp:/{if(++c==2)print $13}' /proc/net/snmp); os1=$(awk '/^Tcp:/{if(++c==2)print $12}' /proc/net/snmp)
sleep 4
read -r _ u2 n2 s2 id2 w2 q2 sq2 st2 _ < /proc/stat; r2=$(cat /sys/class/net/$i/statistics/rx_bytes); t2=$(cat /sys/class/net/$i/statistics/tx_bytes)
rs2=$(awk '/^Tcp:/{if(++c==2)print $13}' /proc/net/snmp); os2=$(awk '/^Tcp:/{if(++c==2)print $12}' /proc/net/snmp)
tot=$(( (u2+n2+s2+id2+w2+q2+sq2+st2)-(u+n+s+id+w+q+sq+st) ))
dl=$(curl -s -m 15 -o /dev/null -w '%{speed_download}' "https://speed.cloudflare.com/__down?bytes=25000000" | awk '{printf "%.0f",$1*8/1e6}')
failed=$(systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}' | tr '\n' ',')
down=$(for x in $(systemctl list-unit-files --no-legend --plain --state=enabled 2>/dev/null | awk '{print $1}' | grep -E '^(backpack-|relay-dnat|backhaul)'); do systemctl is-active -q "$x" || printf '%s,' "$x"; done)
dk=$(docker ps -a --format '{{.Names}}:{{.Status}}' 2>/dev/null | grep -v ':Up' | tr '\n' ',')
printf '%-12s cores=%s cpu=%s%% steal=%s%% rx=%sM tx=%sM retr=%s%% free_dl=%sM mem=%sMB disk=%s up=%s failed=[%s] tunnel_down=[%s] docker_down=[%s]\n' \
 "${LABEL:-$(hostname | cut -c1-12)}" "$(nproc)" "$(( 100*(tot-(id2-id)-(w2-w))/tot ))" "$(( 100*(st2-st)/tot ))" \
 "$(( (r2-r1)*8/4/1000000 ))" "$(( (t2-t1)*8/4/1000000 ))" \
 "$(awk -v a=$((rs2-rs1)) -v b=$((os2-os1)) 'BEGIN{printf "%.1f", b?100*a/b:0}')" "$dl" \
 "$(free -m | awk '/Mem/{print $7}')" "$(df -h / | awk 'NR==2{print $5}')" "$(uptime -p | sed 's/up //')" "${failed%,}" "${down%,}" "${dk%,}"
