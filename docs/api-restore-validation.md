# Versioned API And Restore Validation

This procedure turns a panel runbook into evidence without assuming that APIs,
database schemas, or backup commands are identical across releases.

## Version Record

Before using an API or restoring data, record:

| Field | Required evidence |
|---|---|
| Product and installed version | UI, package, container digest, or binary output |
| Upstream contract | Release-matched API/OpenAPI or administrator documentation URL |
| Deployment method | Package, installer, Compose, container, or custom service |
| Data stores | Database engine/version, volumes, config paths, certificate paths |
| Backup time and integrity | UTC timestamp, size, checksum, and restricted location |
| Restore target | Disposable isolated host; never the only production instance |

## API Probe Sequence

Use the exact endpoints and authentication scheme documented for the installed
release. Replace placeholders locally; never paste real values into an issue or chat.

```bash
export PANEL_BASE_URL='https://panel.example.invalid'
export PANEL_TOKEN_FILE='/run/secrets/panel-api-token'

# TLS and HTTP reachability; this does not prove authentication or data-plane health.
curl --fail --silent --show-error --head "$PANEL_BASE_URL/"

# Adapt API_PATH and header format only from the release-matched upstream contract.
curl --fail --silent --show-error \
  -H "Authorization: Bearer $(cat "$PANEL_TOKEN_FILE")" \
  "$PANEL_BASE_URL/API_PATH"
```

Start with a read-only health, version, or list operation. Record status code,
response schema, pagination, and redacted object counts. Do not run create, update,
delete, revoke, rotate, or restart operations until the operator approves them.

## Restore Drill

1. Provision an isolated target with no production DNS and blocked outbound user traffic.
2. Install the same application, core, and database versions as the backup source.
3. Verify checksums, ownership, permissions, and available disk space.
4. Restore database and files using the product's release-matched procedure.
5. Start dependencies in documented order and capture sanitized logs.
6. Compare expected users/inbounds/nodes/config objects by count and stable identifiers.
7. Use a disposable client and non-production record to test authentication and data flow.
8. Destroy or securely sanitize the test target after evidence is recorded.

## Result Matrix

Never mark a drill passed without running it.

| Product | Version | API read test | Restore test | Data-path test | Date | Evidence |
|---|---|---|---|---|---|---|
| Example only | `x.y.z` | `not-run` | `not-run` | `not-run` | - | Sanitized report location |

Allowed states are `pass`, `fail`, `blocked`, and `not-run`. A successful database
import with a failed client path is not a successful restore.

## Product Notes

- **3x-ui:** preserve its database, Xray-related configuration, certificates, and custom service overrides.
- **Marzban:** keep database and container/application versions aligned before schema migration or restore.
- **PasarGuard:** include panel data, node definitions, enrollment state, and generated services without exposing node credentials.
- **Remnawave:** preserve database, persistent volumes, Compose configuration, proxy state, and node metadata.
- **Hiddify:** use the release-supported export/restore path and separately capture certificates and custom templates.
- **S-UI:** preserve panel data, sing-box configuration/version, certificates, and systemd overrides.

Live validation requires operator-controlled test infrastructure. VPNOpsNyx provides
the procedure and evidence format; it must not claim that an unperformed restore passed.
