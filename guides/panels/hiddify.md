# Hiddify Manager Runbook

**Source:** https://github.com/hiddify/Hiddify-Manager  
**Trust:** `verified`, `official`

## Preflight

Record the manager version, installation channel, domain/DNS state, proxy core
versions, ports, certificates, custom templates, and provider snapshot capability.

## Install, Upgrade, And API

Use only the current upstream documentation for the chosen release. Inspect any
bootstrap script, avoid unpinned mirrors, and preserve the existing installation
metadata before upgrade. API paths and authentication must be taken from that
release's documentation; use a dedicated token and redact all subscription output.

## Backup And Verification

Use the manager's supported backup/export path and separately preserve certificates,
custom configuration, and reverse-proxy/firewall state. Test restore on an isolated
host. Verify administration, user/subscription generation, core listeners, DNS/TLS,
and actual traffic from a disposable client.

## Troubleshooting And Rollback

Distinguish dashboard, database, core, certificate, DNS, and routing failures. Roll
back with the provider snapshot or documented restore process and the prior release;
then confirm data flow before changing DNS or admitting users.
