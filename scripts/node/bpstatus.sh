#!/bin/bash
# Status of every active BackPack L3 link on this host: role, carrier, address, tunnel peer and the
# packet loss to that peer. Read-only. Run on relays and exits:
#   ssh HOST 'bash -s' < scripts/node/bpstatus.sh
# A unit can stay `active` while the path is dead (the journal fills with "handshake did not complete").
# Judge a link only by the peer ping here plus real-user bytes (scripts/node/realuse.sh on the exit).
for u in $(systemctl list-units --type=service --state=active --no-legend 'backpack-*' | awk '{print $1}'); do
  n=${u%.service}; n=${n#backpack-}; f=/etc/backpack/$n.toml
  [ -f "$f" ] || continue                       # helper units such as monitor or webui have no link config
  mode=$(awk -F'"' '/^mode/{print $2}' "$f"); car=$(awk -F'"' '/^carrier/{print $2}' "$f")
  addr=$(awk -F'"' '/^addr/{print $2}' "$f"); peer=$(awk -F'"' '/^peer_ip/{print $2}' "$f")
  [ -n "$peer" ] || continue
  loss=$(ping -c5 -W1 -i0.3 "$peer" 2>/dev/null | grep -oE '[0-9.]+% packet' | cut -d% -f1)
  fails=$(journalctl -u "$u" --since -30min --no-pager 2>/dev/null | grep -c 'handshake did not complete')
  printf '%-12s %-6s %-4s %-24s peer=%-12s loss=%s%% handshake_fail_30m=%s\n' "$n" "$mode" "$car" "$addr" "$peer" "${loss:-?}" "$fails"
done
