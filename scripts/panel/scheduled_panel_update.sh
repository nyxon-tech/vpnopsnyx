#!/bin/bash
# Update ONLY the panel container, with a database dump first, a health check, and an automatic image
# rollback. Run ON THE PANEL HOST, either by hand (as a transient unit) or from a one-shot systemd timer.
#   Install:  scp scripts/panel/scheduled_panel_update.sh HOST:/root/ops/ && ssh HOST chmod 700 /root/ops/scheduled_panel_update.sh
#   Now:      ssh HOST 'systemd-run --unit=ops-panel-update /root/ops/scheduled_panel_update.sh'
#   Later:    a service whose ExecStart is this script plus a timer with
#             OnCalendar=YYYY-MM-DD HH:MM:SS UTC  (state the operator's local time too; take the offset
#             from the operator machine's `date +%z`, do not assume it). Timers on the server fire even when
#             the workstation is asleep.
# Settings (environment, defaults in brackets):
#   PANEL_DIR [/opt/pasarguard]        compose directory
#   SERVICE   [pasarguard]             compose service name of the panel (the database service is never touched)
#   CONTAINER [pasarguard-pasarguard-1] panel container name
#   DB_KIND   [mysql]                  mysql or postgres
#   DB_CONTAINER [pasarguard-mysql-1]  database container (read its credentials from its own environment)
#   PANEL_URL [https://127.0.0.1:8000/] local URL that must answer (any HTTP code, even 404, means alive)
#   WAIT_ROUNDS [20]                   health rounds of 15 s each
# Rollback of the image only: the database dump is kept and its path is logged, because a newer panel may
# have migrated the schema. Log: /root/ops/panel-update.log. Never reboots, never touches the database service.
PANEL_DIR=${PANEL_DIR:-/opt/pasarguard}; SERVICE=${SERVICE:-pasarguard}; CONTAINER=${CONTAINER:-pasarguard-pasarguard-1}
DB_KIND=${DB_KIND:-mysql}; DB_CONTAINER=${DB_CONTAINER:-pasarguard-mysql-1}
PANEL_URL=${PANEL_URL:-https://127.0.0.1:8000/}; WAIT_ROUNDS=${WAIT_ROUNDS:-20}
mkdir -p /root/ops /root/backups; exec >>/root/ops/panel-update.log 2>&1
echo "== $(date -u '+%F %T') UTC start"
cd "$PANEL_DIR" || exit 1
dump() {
  if [ "$DB_KIND" = postgres ]; then docker exec "$DB_CONTAINER" sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fp'
  else docker exec "$DB_CONTAINER" sh -c 'mysqldump --all-databases --single-transaction -uroot -p"$MYSQL_ROOT_PASSWORD" 2>/dev/null'; fi
}
connected() {
  if [ "$DB_KIND" = postgres ]; then
    docker exec "$DB_CONTAINER" sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -At -c "select count(*) from nodes where status::text = '"'"'connected'"'"'"' 2>/dev/null | tail -1
  else
    docker exec "$DB_CONTAINER" sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "${MYSQL_DATABASE:-pasarguard}" -N -e "select count(*) from nodes where status=\"connected\"" 2>/dev/null' | tail -1
  fi
}
OLD=$(docker inspect -f '{{.Image}}' "$CONTAINER") || exit 1
BK=/root/backups/panel-pre-update-$(date +%Y%m%d-%H%M).sql.gz
dump | gzip > "$BK"
gzip -t "$BK" && [ "$(stat -c %s "$BK")" -gt 100000 ] || { echo "BACKUP FAILED - aborting, panel untouched"; exit 1; }
echo "backup ok: $BK"
docker tag "$OLD" panel-rollback-pre-update            # keep the running image reachable by name
BEFORE=$(connected); echo "nodes connected before: $BEFORE; old image: $OLD"
docker compose pull "$SERVICE" 2>&1 | tail -2
docker compose up -d --no-deps "$SERVICE" 2>&1 | tail -3
ok=0
for i in $(seq 1 "$WAIT_ROUNDS"); do
  sleep 15
  st=$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)
  code=$(curl -sk -o /dev/null -m 6 -w '%{http_code}' "$PANEL_URL" 2>/dev/null)
  now=$(connected)
  echo "t+$((i*15))s running=$st http=$code nodes=$now/$BEFORE"
  [ "$st" = true ] && [ "$code" != 000 ] && [ "${now:-0}" -ge "${BEFORE:-0}" ] && { ok=1; break; }
done
if [ "$ok" = 1 ]; then echo "UPDATE OK"; exit 0; fi
echo "UPDATE FAILED health check - rolling back to $OLD"
IMG=$(docker inspect -f '{{.Config.Image}}' "$CONTAINER")   # the tag the compose file uses
docker tag panel-rollback-pre-update "$IMG"
docker compose up -d --no-deps --force-recreate "$SERVICE" 2>&1 | tail -3
sleep 60
echo "after rollback: running=$(docker inspect -f '{{.State.Running}}' "$CONTAINER") nodes=$(connected)/$BEFORE (database dump kept: $BK)"
