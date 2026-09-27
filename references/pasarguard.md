# PasarGuard internals for operators

PasarGuard is a Marzban fork (FastAPI + SQLAlchemy, MySQL/MariaDB/PostgreSQL/SQLite). Everything below
was verified on the 5.x series. Check your version before relying on a detail, because internals move
between releases.

## Contents
1. Layout and read-only DB access
2. Restart semantics (the most important section)
3. keep_alive: why nodes stop by themselves
4. Nodes, cores and inbounds
5. The inbound-cleanup trap when writing to the DB
6. Hosts, groups, users, resellers
7. Usage tables and heavy queries
8. Multi-node servers: port collisions
9. WARP inside Xray under heavy load
10. Subscriptions
11. Certificates behind relays
12. Rebooted exit with a stopped core
13. Host-service port collisions

## 1. Layout and read-only DB access

- Panel: `/opt/pasarguard` (docker compose), container `pasarguard-pasarguard-1` plus a DB container.
- Nodes: one directory per instance, `/opt/<name>` with `.env` (`SERVICE_PORT`, `API_PORT`, `API_KEY`,
  cert paths) and `docker-compose.yml`. The image is `pasarguard/node`. Pin it by digest so every node
  runs the same build.
- Read the DB **without ever seeing the DB password** by running Python inside the panel container,
  using its own environment:
  ```bash
  ssh PANEL 'docker exec -i pasarguard-pasarguard-1 sh -c "cd /code && python -"' < query.py
  ```
  ```python
  import asyncio, os
  from sqlalchemy import text
  from sqlalchemy.ext.asyncio import create_async_engine
  async def main():
      e = create_async_engine(os.environ["SQLALCHEMY_DATABASE_URL"])
      async with e.connect() as c:
          await c.execute(text("SET SESSION TRANSACTION READ ONLY"))
          await c.execute(text("SET SESSION max_execution_time = 60000"))   # MySQL
          for r in (await c.execute(text("SELECT id, name, status, address FROM nodes"))).all():
              print(r)
      await e.dispose()
  asyncio.run(main())
  ```
- For **writes**, import the app's own models and CRUD (`app.db.crud.node.create_node`,
  `app.db.crud.core.create_core_config`, `app.models.node.NodeCreate`). You get the same validation the
  API applies, and you need no admin login. Keep keys and certs out of stdout: build the script in a
  temp file, pipe it in, delete it.

## 2. Restart semantics

- With NATS disabled (the default single-process setup), the running panel keeps nodes, cores and hosts
  **in memory**. A direct DB change takes effect only after `docker compose restart pasarguard`.
- The node health checker skips nodes it does not have in memory. A newly inserted node therefore stays
  "connecting" until the next restart.
- **Restarting the panel restarts Xray on every node**: on startup the panel calls `Start` on each node
  and resends the config and all users. Users drop for a few seconds; a slow or overloaded node can take
  1–2 minutes. Batch DB changes, restart once, off-peak, and tell the operator first.
- Your SSH session to the panel host may drop briefly during the restart. That is harmless.

## 3. keep_alive: why nodes stop by themselves

`nodes.keep_alive` (commonly 60 seconds) is sent to the node in `Start`. If the node hears nothing from
the panel for that long, **it stops Xray itself** and logs `disconnect automatically due to keep alive
timeout`, even though the tunnels and the users are fine. So a one-minute network blip between panel
and node becomes a full outage for that location.
- Count these stops with `docker logs --since 168h <node> | grep "keep alive timeout"`.
- Raising `keep_alive` (for example to 600) costs nothing and needs no restart; it applies at each node's
  next `Start`. User changes made during a panel↔node gap are queued and flushed later.
- When you migrate a node to a new server, the **old** server's Xray stops about `keep_alive` seconds
  after the panel repoints, so anything still aimed at the old IP dies at that moment (see `node-lifecycle.md`).

## 4. Nodes, cores and inbounds

- Each node has exactly **one** core (`core_config_id`), either Xray or WireGuard. WireGuard therefore
  needs a second node instance on the same server.
- Inbound tags that are identical across cores are merged by the panel. That enables a useful trick: clone
  the main core into a location-specific one that differs only in routing (for example with WARP rules
  sent to `DIRECT` for one heavy node). Hosts, groups and users stay untouched, because the tags are the
  same. From then on, **mirror every change** (new inbound, Reality keys, routing) into the clone.
- A cloned core that keeps every inbound also means that node listens on **other locations' ports**. Never
  DNAT or tunnel a different location's port to it, or those users will exit in the wrong country.
- Register a node with `server_ca` (its self-signed cert, CN or SAN equal to its IP), `api_key` from its
  `.env`, `port`/`api_port`, `connection_type="grpc"`, `keep_alive`, `usage_coefficient`, and `core_config_id`.
- To repoint existing node rows to a new server, update `address`, `port`, `api_port`, `api_key` and
  `server_ca` in place. The node id stays the same, so traffic history, groups and hosts stay attached.

## 5. The inbound-cleanup trap when writing to the DB

A scheduled job (`remove_old_inbounds`) deletes every `inbounds` row that is not in the in-memory core
manager. If you create a core with new inbound tags directly in the DB and **don't restart right away**,
the job deletes the new tags. `hosts.inbound_tag` has `ON DELETE SET NULL`, and a delete listener also
removes the group↔inbound links. The result: hosts lose their inbound, groups lose their inbounds, and
subscriptions come out empty.
**Order:** create the core → restart the panel immediately → then attach hosts and groups → restart again
(hosts are loaded only at startup). If you were too late, re-set the host tags, re-insert the group
links, and restart.
Before changing a host's tag, call `upsert_inbounds(db, [tag])`, or the foreign key fails. In MySQL,
`groups` is a reserved word, so backtick it.

## 6. Hosts, groups, users, resellers

- `hosts`: `remark` (name template), `address` (can be `{HOST_DOMAIN}`), `port` (NULL = the inbound's
  port), `inbound_tag`, `is_disabled`, SNI/host/path overrides, and WireGuard overrides (DNS, keepalive,
  MTU, allowed IPs).
- A user's config lines are all enabled hosts of every inbound in the user's groups.
- Resellers are `admins` with `data_limit`/`used_traffic`. If their role sets
  `disconnect_users_when_limited`, **all of their users are cut at once** when the limit is reached.
  Check the reseller quota burn rate yourself (24-hour usage from `node_user_usages` joined to users),
  because the panel's Telegram notifications may be misconfigured and resellers never see the warning.

## 7. Usage tables and heavy queries

- `node_usages`: per node, time-bucketed uplink/downlink. Cheap.
- `node_user_usages`: per user per node per bucket. Millions of rows, so always filter on a recent
  `created_at` window and set `max_execution_time`.
- `node_stats` can be empty (CPU/RAM history is not always recorded).
- "Users and GB per node per hour for the last 24–26 h" is the best single outage detector: a node whose
  users collapse while its siblings don't has lost its path.
- To delete a node with a large history, remove `node_user_usages` in batches (`DELETE … LIMIT 20000`
  with a commit between batches), then `node_usages`, `node_usage_reset_logs` and `node_stats`, then the
  node row, then restart. Deleting through the UI can time out on large tables.

## 8. Multi-node servers: port collisions

Each node container gives Xray a random local API port. If that random port happens to equal a fixed
inbound port of another node on the same server, the victim's Xray never starts and loops on
`exit status 255`. The real error (`bind: address already in use`) appears only in the **panel** log.
Fix: restart the offending container so it picks another port, then restart the victim.

A related failure: with `ip_local_port_range = 1024 65535` and no reserved ports, a busy Xray can have
one of its own listener ports in use as an outbound source port at the moment it restarts. Prevent both
with `net.ipv4.ip_local_reserved_ports` listing every fixed port. It is harmless: explicit binds and
existing connections are not affected.

## 9. WARP inside Xray under heavy load

A WARP outbound implemented inside Xray (userspace WireGuard) stalled on a node with ~30k connections:
every request took 6–10 s, even locally on the node, and Google (routed via WARP) failed completely. The
client-side "ping" test (which fetches a Google URL) showed timeouts. A fresh Xray on the same box with
the same WARP key worked instantly, so the WARP path was saturated. If the exit IP is accepted by Google
without captchas, route those rules `DIRECT` in a node-specific cloned core. In that case request time
went from ~10 s to 0.06 s. Otherwise run WARP outside Xray (wireproxy or the kernel `warp-cli`) and point
an outbound at it.

## 10. Subscriptions

- `https://SUB_DOMAIN:PORT/sub/<token>` returns all links; `/sub/<token>/wireguard` returns a zip of
  `.conf` files (plain `wireguard://` links are not understood by the official WireGuard app).
- Tokens are derived from the numeric user id (`create_subscription_token(user_id)`), not the username.

## 11. Certificates behind relays

If the panel's subscription domain resolves to relays and the certificate is issued with ACME
standalone (HTTP-01 on port 80), the relay tunnels must forward port 80 to the panel. Remove that
forward and the next renewal fails silently weeks later. After a renewal, the reload command
(`docker compose restart pasarguard`) is a full panel restart, with the consequences in section 2.

## 12. Rebooted Exit With A Stopped Core

An operator observed that after an exit host reboot, its node container reconnected
while Xray remained stopped because the panel did not resend `Start`. Symptoms were
node RPC `Unavailable` errors, no inbound listeners, and a collapse in real usage.
Treat this as `operator-observed` until confirmed against the deployed PasarGuard
version. After every reboot verify Xray listeners and data flow, not only node status.
If approved, reconnect/restart the affected node or restart the panel during a
maintenance window. For a fleet reboot, exits first and panel host last can force a
fresh startup synchronization, but it also restarts every node and must be announced.

## 13. Host-Service Port Collisions

Compare every core inbound port against host listeners before reboot or upgrade:

```bash
ss -ltnp
```

A field incident showed a tunnel tool's web UI and an Xray inbound racing for the
same port. After reboot the other service won, Xray exited, and unrelated inbounds in
the same core disappeared. Stop/disable or reconfigure the conflicting service,
reserve fixed listener ports, restart the core, and verify every inbound.
