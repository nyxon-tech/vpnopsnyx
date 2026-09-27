# Remnawave Runbook

**Source:** https://github.com/remnawave/panel  
**Trust:** `verified`, `official`

## Preflight And Install

Inventory Compose files, pinned images, database/cache services, domains, nodes,
environment variable names, volumes, and reverse proxy. Follow the release-matched
upstream documentation; do not combine instructions from old community installers.

## API Boundary

Use the API schema shipped with the installed release. Keep tokens in a secret store,
start with read-only inventory calls, paginate large datasets, and verify object IDs
before mutation. Never expose subscription links or node credentials in reports.

## Backup And Upgrade

Create a consistent database dump plus copies of persistent volumes, Compose and
proxy configuration, certificates, and node metadata. Read migration notes, pin the
new image set, stage the upgrade, and retain the old image digests and database dump.

## Verification And Rollback

Verify web/API health, database migrations, node connectivity, config generation,
and a real client path. On failure, stop writes, restore the pre-upgrade database and
volumes, redeploy the previous images, and verify nodes before serving users.
