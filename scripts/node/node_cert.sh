#!/bin/bash
# New self-signed certificate for a PasarGuard node after it moved to a new server or IP. Run ON THE NODE:
#   ssh NEW_SERVER 'NODE=node-name IP=198.51.100.20 bash -s' < scripts/node/node_cert.sh
# Keeps the old pair as ssl_*.pem.old-<date>, restarts the node container and its service unit, and
# prints the new SAN. Then store the new certificate in the panel for that node (dashboard, or
# scripts/panel/node_edit.sh with CERT_HOST/CERT_PATH) - the panel pins the exact certificate it has.
#
# Why a new pair and not a re-signed one: the panel verifies nodes with Python's default SSL context,
# which on Python 3.13+ is strict (VERIFY_X509_STRICT). A leaf signed by the old self-signed certificate
# fails ("CA cert does not include key usage extension"), and a re-issued self-signed certificate with the
# same key is still a different certificate. Changing the stored certificate is the only clean path.
set -eu
NODE=${NODE:?node name, e.g. the /var/lib/<name> directory}; IP=${IP:?new public IP}
D=/var/lib/$NODE/certs
[ -f "$D/ssl_cert.pem" ] || { echo "no $D/ssl_cert.pem"; exit 1; }
s=$(date +%Y%m%d%H%M)
cp -p "$D/ssl_cert.pem" "$D/ssl_cert.pem.old-$s"; cp -p "$D/ssl_key.pem" "$D/ssl_key.pem.old-$s"
openssl req -x509 -newkey rsa:4096 -nodes -keyout "$D/ssl_key.pem" -out "$D/ssl_cert.pem" -days 3650 \
  -subj "/CN=$IP" -addext "subjectAltName=DNS:localhost,IP:127.0.0.1,IP:$IP" \
  -addext "basicConstraints=critical,CA:TRUE" 2>/dev/null
chmod 600 "$D/ssl_key.pem"
docker restart "$NODE" >/dev/null 2>&1 || true
systemctl restart "$NODE-service" 2>/dev/null || true
echo "$(hostname): $NODE $(openssl x509 -in "$D/ssl_cert.pem" -noout -ext subjectAltName | tail -1 | sed 's/^ *//')"
