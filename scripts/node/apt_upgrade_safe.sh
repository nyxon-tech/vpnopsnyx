#!/bin/bash
# Safe, detached package upgrade. Run ON THE SERVER:  ssh HOST 'bash -s' < scripts/node/apt_upgrade_safe.sh
# - docker/containerd are held during the run (a Docker upgrade restarts every container = every
#   Xray on that host, or the whole panel on the panel host). Upgrade Docker separately, off-peak,
#   one host at a time, panel host last.
# - keeps existing config files, does not restart services by itself (needrestart list mode),
#   never reboots. Check /var/run/reboot-required afterwards and plan reboots (reboot_verify.sh).
# - runs as a transient unit so an SSH drop cannot kill it halfway. Log: /root/ops-apt-upgrade.log
cat > /root/ops-apt-upgrade.run <<'IN'
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=l NEEDRESTART_SUSPEND=1
echo "== start $(date -u)"
held=""; for p in docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin docker.io containerd; do dpkg -s $p >/dev/null 2>&1 && held="$held $p"; done
[ -n "$held" ] && apt-mark hold $held
apt-get update -q || true
nice -n 10 ionice -c3 apt-get -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef upgrade
rc=$?
[ -n "$held" ] && apt-mark unhold $held >/dev/null
echo "== end $(date -u) rc=$rc reboot_required=$([ -f /var/run/reboot-required ] && echo YES || echo no) held_back=$(apt list --upgradable 2>/dev/null | grep -c upgradable)"
IN
chmod 700 /root/ops-apt-upgrade.run
systemctl reset-failed ops-apt-upgrade 2>/dev/null
systemd-run --quiet --unit=ops-apt-upgrade /bin/sh -c "/root/ops-apt-upgrade.run > /root/ops-apt-upgrade.log 2>&1"
echo "$(hostname): upgrade started (tail /root/ops-apt-upgrade.log; done when it prints '== end')"
