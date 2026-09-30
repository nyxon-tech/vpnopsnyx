#!/bin/bash
# Point an in-country Ubuntu relay at the fastest domestic mirror (upstream Ubuntu mirrors are slow
# from Iran and download.docker.com answers 403 to Iranian IPs).
#   ssh RELAY 'bash -s' < scripts/relay/iran_mirror.sh          (DRYRUN=1 to only measure)
# Backs up the sources file and restores it automatically if `apt-get update` then reports errors
# for Ubuntu entries (errors from third-party repos such as Docker's are ignored).
# Mirror list taken from public community scripts; verify it is still current.
. /etc/os-release
MIRRORS="ubuntu.pars.host ir.ubuntu.sindad.cloud/ubuntu mirror.arvancloud.ir/ubuntu ubuntu.mobinhost.com/ubuntu mirror.iranserver.com/ubuntu ubuntu.parsvds.com/ubuntu ubuntu.shatel.ir/ubuntu ubuntu.pishgaman.net/ubuntu mirror.aminidc.com/ubuntu ir.archive.ubuntu.com/ubuntu"
best=""; bs=0
for m in $MIRRORS; do
  r=$(curl -s -m 8 -o /dev/null -w "%{http_code} %{speed_download}" "http://$m/dists/$VERSION_CODENAME/main/binary-amd64/Packages.gz")
  c=${r%% *}; v=${r##* }; v=${v%.*}; [ "$c" = 200 ] || v=0
  printf "%s=%sKB/s " "${m%%/*}" $((v/1000))
  [ "$v" -gt "$bs" ] && { bs=$v; best=$m; }
done; echo
[ -n "$best" ] || { echo "no mirror answered"; exit 1; }
echo "best: http://$best ($((bs/1000)) KB/s)"
[ "${DRYRUN:-0}" = 1 ] && exit 0
f=$( [ -f /etc/apt/sources.list.d/ubuntu.sources ] && echo /etc/apt/sources.list.d/ubuntu.sources || echo /etc/apt/sources.list )
cp -a "$f" "$f.bak-$(date +%Y%m%d)"
sed -i -E "s#https?://([a-z]{2}\.)?archive\.ubuntu\.com/ubuntu/?#http://$best/#g; s#https?://security\.ubuntu\.com/ubuntu/?#http://$best/#g" "$f"
apt-get update -q > /tmp/aptu.log 2>&1
if grep -E "^(E:|Err:)" /tmp/aptu.log | grep -vqE "docker\.com"; then
  cp -a "$f.bak-$(date +%Y%m%d)" "$f"; echo "apt-get update failed on Ubuntu entries -> restored backup"; grep -E "^(E:|Err:)" /tmp/aptu.log | head -3
else
  echo "$(hostname): $f now uses http://$best"
fi
