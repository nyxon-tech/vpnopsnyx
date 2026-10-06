"""Read-only audit: every inbound with its groups, user count and hosts. Flags inbounds that no user can
receive (no group) and inbounds with no host (users get nothing to connect to).
Runs inside the PasarGuard panel container (PostgreSQL or MySQL/MariaDB):

    ssh PANEL 'docker exec -i PANEL_CONTAINER sh -c "cd /code && python -"' < scripts/panel/inbound_groups.py
    FILTER=tunnel ...   only inbounds whose tag contains FILTER

Field note: a tunnel inbound that had hosts, DNS and working relays carried zero users for days because it
was in no group; adding it to the same groups as the other tunnel inbounds fixed it at once. Group
membership decides which customers see a location, so confirm the groups with the operator before changing
them (PUT /api/group/{id} with the full inbound_tags list).
"""
import asyncio
import os

from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

FILTER = os.environ.get("FILTER", "").lower()


async def main():
    engine = create_async_engine(os.environ["SQLALCHEMY_DATABASE_URL"])
    async with engine.connect() as conn:
        if engine.dialect.name == "postgresql":
            await conn.execute(text("SET TRANSACTION READ ONLY"))
        # "groups" is a reserved word in MySQL 8
        g_tbl = "`groups`" if engine.dialect.name in ("mysql", "mariadb") else "groups"
        inbounds = (await conn.execute(text("SELECT id, tag FROM inbounds ORDER BY tag"))).all()
        groups = {}
        for inbound_id, name, users in (await conn.execute(text(
            "SELECT a.inbound_id, g.name, (SELECT COUNT(*) FROM users_groups_association u WHERE u.groups_id = g.id) "
            f"FROM inbounds_groups_association a JOIN {g_tbl} g ON g.id = a.group_id"))).all():
            groups.setdefault(inbound_id, []).append(f"{name}({users})")
        hosts = {}
        for tag, n, enabled in (await conn.execute(text(
            "SELECT inbound_tag, COUNT(*), SUM(CASE WHEN is_disabled THEN 0 ELSE 1 END) FROM hosts GROUP BY inbound_tag"))).all():
            hosts[tag] = (n, int(enabled or 0))
    await engine.dispose()
    for inbound_id, tag in inbounds:
        if FILTER and FILTER not in tag.lower():
            continue
        g = groups.get(inbound_id, [])
        n_hosts, n_enabled = hosts.get(tag, (0, 0))
        flags = []
        if not g:
            flags.append("NO GROUP: no user receives it")
        if n_enabled == 0:
            flags.append("NO ENABLED HOST")
        print(f"{tag:32} hosts={n_enabled}/{n_hosts:<3} groups={', '.join(g) or '-'}"
              + (f"   <-- {'; '.join(flags)}" if flags else ""))


asyncio.run(main())
