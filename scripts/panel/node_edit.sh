#!/usr/bin/env bash
# Edit ONE PasarGuard node (address, port, server certificate, timeouts) through the panel's own HTTP API,
# the same call the dashboard makes when you save a node. Only that node reconnects; the panel is not
# restarted. Requires root SSH to the panel host. Operator approval required: it changes production state.
#
#   PANEL=panel-host [CONTAINER=pasarguard-pasarguard-1] \
#     scripts/panel/node_edit.sh NODE_ID ADDRESS PORT [CERT_HOST CERT_PATH]
#   optional env: DEFAULT_TIMEOUT=SEC INTERNAL_TIMEOUT=SEC (3..60) for slow or lossy panel->node links
#
# CERT_HOST/CERT_PATH: ssh alias and path of the node's new ssl_cert.pem (for example after
# scripts/node/node_cert.sh on a new server). The certificate is public; it is read over ssh and passed
# to the panel inside the request, never printed. Secrets are not handled here: the script mints a
# short-lived admin token INSIDE the panel container with the panel's own code and never outputs it.
# Output: node id, HTTP status, name, address, port, status (and an error detail if any).
# Uses `PUT /api/node/{id}` and the NodeModify fields of the deployed panel; confirm them on your version.
set -eu
nid=${1:?node id}; addr=${2:?address}; port=${3:?port}
PANEL=${PANEL:?set PANEL to the panel host ssh alias}; CONTAINER=${CONTAINER:-pasarguard-pasarguard-1}
[[ $nid =~ ^[0-9]+$ && $port =~ ^[0-9]+$ ]] || { echo "bad id/port" >&2; exit 2; }
[[ $addr =~ ^[0-9a-zA-Z.:-]+$ ]] || { echo "bad address" >&2; exit 2; }
[[ $CONTAINER =~ ^[A-Za-z0-9_.-]+$ ]] || { echo "bad container name" >&2; exit 2; }
[[ ${DEFAULT_TIMEOUT:-0} =~ ^[0-9]+$ && ${INTERNAL_TIMEOUT:-0} =~ ^[0-9]+$ ]] || { echo "bad timeout" >&2; exit 2; }
cert=""
if [ $# -ge 5 ]; then cert=$(ssh -o ConnectTimeout=15 "$4" "cat '$5'"); fi
{
  printf 'ARGS = ["%s", "%s", "%s", "%s"]\n' "$nid" "$addr" "$port" "$(printf %s "$cert" | base64 | tr -d '\n')"
  printf 'TIMEOUTS = [%s, %s]\n' "${DEFAULT_TIMEOUT:-0}" "${INTERNAL_TIMEOUT:-0}"
  cat <<'PY'
import asyncio, os, base64, json, ssl, urllib.request, urllib.error
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine
from app.utils.jwt import create_admin_token
nid, addr, port, cert_b64 = ARGS
body = {"address": addr, "port": int(port)}
if cert_b64:
    body["server_ca"] = base64.b64decode(cert_b64).decode()
if TIMEOUTS[0]: body["default_timeout"] = int(TIMEOUTS[0])
if TIMEOUTS[1]: body["internal_timeout"] = int(TIMEOUTS[1])
async def main():
    e = create_async_engine(os.environ["SQLALCHEMY_DATABASE_URL"])
    async with e.connect() as c:
        cols = [r[0] for r in (await c.execute(text("select column_name from information_schema.columns where table_name='admins'"))).all()]
        cond = "is_sudo" if "is_sudo" in cols else "1=1"
        aid, uname = (await c.execute(text(f"select id, username from admins where {cond} order by id limit 1"))).one()
    await e.dispose()
    tok = await create_admin_token(aid, uname)
    req = urllib.request.Request(f"https://127.0.0.1:{os.environ.get('UVICORN_PORT', '8000')}/api/node/{nid}",
        data=json.dumps(body).encode(), method="PUT",
        headers={"Authorization": f"Bearer {tok}", "Content-Type": "application/json"})
    try:
        r = urllib.request.urlopen(req, context=ssl._create_unverified_context(), timeout=90); code = r.status; raw = r.read()
    except urllib.error.HTTPError as err:
        code = err.code; raw = err.read()
    try: d = json.loads(raw)
    except Exception: d = {}
    print(nid, code, d.get("name"), d.get("address"), d.get("port"), d.get("status"), str(d.get("detail", ""))[:160])
asyncio.run(main())
PY
} | ssh -o ConnectTimeout=15 "$PANEL" "docker exec -i $CONTAINER sh -c 'cd /code && python -'"
