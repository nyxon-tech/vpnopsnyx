# Marzban Runbook

**Source:** https://github.com/Gozargah/Marzban  
**Trust:** `verified`, `official`

Use the evidence matrix in [`docs/api-restore-validation.md`](../../docs/api-restore-validation.md) for every version-specific API or restore drill.

## Preflight

Identify whether the deployment uses the official installation method, Docker
Compose, an external database, or custom Xray configuration. Record container image
tags, environment variable names (not values), volumes, domains, and reverse proxy.

## Install And Upgrade

Follow the current upstream documentation and pin images/releases. Before upgrade,
export the database, copy the environment file securely, save Compose overrides,
and inspect schema-migration notes. Pulling `latest` is not a rollback plan.

## API Boundary

Use the documented OpenAPI surface for the installed release. Authenticate with a
dedicated operator identity, begin with read-only endpoints, redact bearer tokens,
and use idempotency checks before creating or modifying users. Validate generated
subscriptions without exposing their URLs.

## Backup And Restore

Back up the database transactionally, persistent volumes, environment/config files,
Xray templates, certificates, and reverse-proxy configuration. Restore into a test
stack with the same release, then verify user counts, quotas, nodes, and one data path.

## Troubleshooting And Rollback

Inspect application, database, Xray, and proxy logs separately. For migration or
container failures, stop writes, restore the database and volumes, redeploy the
previous pinned image set, and confirm API plus end-to-end traffic.
