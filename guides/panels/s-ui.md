# S-UI Runbook

**Source:** https://github.com/alireza0/s-ui  
**Trust:** `verified`, `official`

Use the evidence matrix in [`docs/api-restore-validation.md`](../../docs/api-restore-validation.md) for every version-specific API or restore drill.

## Preflight And Install

Confirm supported OS/architecture, free ports, sing-box compatibility, DNS, TLS, and
firewall policy. Review the current tagged release and installer before execution;
record installed paths and services and avoid silently upgrading the bundled core.

## API And Backup

Treat the web/API endpoint as administrative. Restrict exposure, use unique
credentials, redact sessions, and confirm the installed release's API contract.
Back up the database, panel configuration, sing-box configuration, certificates,
and systemd overrides. Test that the backup can be restored on a staging host.

## Verification And Rollback

Verify the UI, sing-box config validation, listeners, certificate chain, firewall,
and one real client path. If an upgrade fails, restore the saved database/config,
return to the prior panel and core versions, restart only during the approved window,
and repeat the end-to-end test.
