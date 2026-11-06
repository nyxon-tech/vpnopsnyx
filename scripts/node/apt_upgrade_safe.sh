#!/bin/bash
# Safe, detached package upgrade. Run ON THE SERVER:  ssh HOST 'bash -s' < scripts/node/apt_upgrade_safe.sh
# - docker/containerd are held during the run (a Docker upgrade restarts every container = every
#   Xray on that host, or the whole panel on the panel host). Upgrade Docker separately, off-peak,
#   one host at a time, panel host last.
# - keeps existing config files, does not restart services by itself (needrestart list mode),
#   never reboots. Check /var/run/reboot-required afterwards and plan reboots (reboot_verify.sh).
# - runs as a transient unit so an SSH drop cannot kill it halfway. Log: /root/ops-apt-upgrade.log
# - preflight/postflight (printed in the log): the SSH listener ports before and after (an OpenSSH upgrade
#   on a custom port has left a relay without sshd), the bootloader device (a cloned image can keep a disk
#   name that does not exist, which leaves grub half-configured and unsafe to reboot), and `dpkg --audit`.
#   If the postflight lists a problem, fix it BEFORE any reboot and keep a second path (jump host or provider
#   console) open until `ss -tlnp` shows sshd again.
cat > /root/ops-apt-upgrade.run <<'IN'
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=l NEEDRESTART_SUSPEND=1
echo "== start $(date -u)"
ssh_ports() { ss -tlnp 2>/dev/null | awk '/sshd|"ssh"/{n=split($4,a,":"); print a[n]}' | sort -un | paste -sd,; }
echo "preflight: sshd listening on [$(ssh_ports)]"
gd=$(debconf-show grub-pc 2>/dev/null | sed -n 's/^\* grub-pc\/install_devices: //p')
if [ -n "$gd" ]; then for d in ${gd//,/ }; do [ -b "$d" ] || echo "preflight WARNING: grub-pc install device $d is not a block device here; fix with debconf-set-selections before upgrading grub"; done; fi
held=""; for p in docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin docker.io containerd; do dpkg -s $p >/dev/null 2>&1 && held="$held $p"; done
[ -n "$held" ] && apt-mark hold $held
apt-get update -q || true
nice -n 10 ionice -c3 apt-get -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef upgrade
rc=$?
[ -n "$held" ] && apt-mark unhold $held >/dev/null
echo "postflight: sshd listening on [$(ssh_ports)]; dpkg --audit says: $(dpkg --audit | head -3 | tr '\n' ' ')"
echo "== end $(date -u) rc=$rc reboot_required=$([ -f /var/run/reboot-required ] && echo YES || echo no) held_back=$(apt list --upgradable 2>/dev/null | grep -c upgradable)"
IN
chmod 700 /root/ops-apt-upgrade.run
systemctl reset-failed ops-apt-upgrade 2>/dev/null
systemd-run --quiet --unit=ops-apt-upgrade /bin/sh -c "/root/ops-apt-upgrade.run > /root/ops-apt-upgrade.log 2>&1"
echo "$(hostname): upgrade started (tail /root/ops-apt-upgrade.log; done when it prints '== end')"
