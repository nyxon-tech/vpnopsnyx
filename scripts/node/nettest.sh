#!/bin/bash
# Temporary public test file for a hosting provider's support team: lets them test your exits from
# their own network without any credentials. Serves /srv/nettest/100MB.bin on PORT (default 18888,
# or the first free of 18889/18890/28888) and removes itself after 72 hours.
#   ssh EXIT 'bash -s' < scripts/node/nettest.sh
# Their test:  curl -o /dev/null -w "%{http_code} %{speed_download}\n" http://EXIT_IP:PORT/100MB.bin
# Stop early:  systemctl stop nettest
# Stop a previous run FIRST: it frees its port, and its ExecStopPost deletes /srv/nettest (a file created
# before the stop would vanish and the new server would answer 404).
systemctl stop nettest 2>/dev/null; systemctl reset-failed nettest 2>/dev/null
for p in ${PORT:-18888} 18889 18890 28888; do
  ss -Htan "( sport = :$p )" | grep -q . && continue
  mkdir -p /srv/nettest && { [ -s /srv/nettest/100MB.bin ] || head -c 100000000 /dev/zero > /srv/nettest/100MB.bin; }
  systemd-run --quiet --unit=nettest -p RuntimeMaxSec=259200 -p ExecStopPost="/bin/rm -rf /srv/nettest" \
    /usr/bin/python3 -m http.server $p --bind 0.0.0.0 --directory /srv/nettest
  sleep 1
  systemctl is-active -q nettest && { echo "$(hostname): http://<this-ip>:$p/100MB.bin (auto-stop in 72h)"; exit 0; }
done
echo "no free port found"; exit 1
