"""Per-node users and GB per hour for the last HOURS hours (default 6), plus node status.
Read-only; runs inside the PasarGuard panel container with the panel's own DB settings
(works with MySQL/MariaDB and PostgreSQL):

    ssh PANEL 'docker exec -i PANEL_CONTAINER sh -c "cd /code && HOURS=8 python -"' < scripts/panel/node_usage.py

How to read it: a node whose users collapse while its siblings stay normal has lost its path, even
if its status still says "connected". Many users with ~0 GB means users reach Xray (or only run
delay tests) but no data flows. Confirm per relay with scripts/node/realuse.sh on the exit.
"""
import asyncio, os
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

HOURS = int(os.environ.get("HOURS", "6"))

async def main():
    e = create_async_engine(os.environ["SQLALCHEMY_DATABASE_URL"])
    pg = e.dialect.name == "postgresql"
    hour = "to_char(date_trunc('hour', u.created_at), 'HH24')" if pg else "DATE_FORMAT(u.created_at, '%H')"
    bucket = "date_trunc('hour', u.created_at)" if pg else "DATE_FORMAT(u.created_at, '%Y%m%d%H')"
    since = f"now() - interval '{HOURS} hours'" if pg else f"UTC_TIMESTAMP() - INTERVAL {HOURS} HOUR"
    async with e.connect() as c:
        if pg:
            await c.execute(text("SET SESSION CHARACTERISTICS AS TRANSACTION READ ONLY"))
            await c.execute(text("SET statement_timeout = 60000"))
        else:
            await c.execute(text("SET SESSION TRANSACTION READ ONLY"))
            await c.execute(text("SET SESSION max_execution_time = 60000"))
        q = text(f"""SELECT n.name, n.status, {hour} AS h, COUNT(DISTINCT u.user_id), ROUND(SUM(u.used_traffic)/1e9, 1)
                     FROM nodes n LEFT JOIN node_user_usages u ON u.node_id = n.id AND u.created_at >= {since}
                     WHERE n.status <> 'disabled'
                     GROUP BY n.id, n.name, n.status, {bucket}, h
                     ORDER BY n.name, MIN(u.created_at)""")
        cur = None
        for name, status, h, users, gb in (await c.execute(q)).all():
            if name != cur:
                print(f"\n {name:<26} [{status}]", end="")
                cur = name
            if h:
                print(f" {h}h:{users}/{gb}", end="")
        print()
    await e.dispose()

asyncio.run(main())
