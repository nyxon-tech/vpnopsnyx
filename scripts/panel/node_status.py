"""Every node with its address, port, status and the panel's last error message. Read-only.
Runs inside the PasarGuard panel container (MySQL/MariaDB or PostgreSQL):

    ssh PANEL 'docker exec -i PANEL_CONTAINER sh -c "cd /code && python -"' < scripts/panel/node_status.py
    FILTER=203.0.113.5 ...   only nodes whose name or address contains FILTER

Useful messages seen in the field:
  * "CERTIFICATE_VERIFY_FAILED ... IP address mismatch" - the node moved to a new IP but its certificate
    (and the server_ca stored in the panel) still name the old IP. See references/pasarguard.md §14.
  * "failed to start xray ... failed to listen TCP on PORT" - another process owns an inbound port.
  * "Request timed out" - the panel->node link is too slow or lossy for Start; see §15.
"""
import asyncio, os
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

FILTER = os.environ.get("FILTER", "")

async def main():
    e = create_async_engine(os.environ["SQLALCHEMY_DATABASE_URL"])
    async with e.connect() as c:
        rows = (await c.execute(text("SELECT id, name, address, port, status, message FROM nodes ORDER BY id"))).all()
        for nid, name, addr, port, status, msg in rows:
            if FILTER and FILTER not in f"{name} {addr}":
                continue
            print(f"{nid:>4} {name[:26]:<26} {addr:<16} {port:<6} {status:<11} {str(msg or '')[:140]}")
    await e.dispose()

asyncio.run(main())
