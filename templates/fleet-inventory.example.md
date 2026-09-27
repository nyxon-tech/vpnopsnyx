# Fleet inventory (PRIVATE — never commit the filled-in copy)

Keep the real version in your agent's memory or a private file. All values below are placeholders.

## Panel
| Item | Value |
|---|---|
| Panel type / version | PasarGuard 5.x |
| SSH alias | `panel` |
| Panel container | `pasarguard-pasarguard-1` |
| Subscription domain | `sub.example.com:8000` |
| Where API credentials live | password manager entry "panel api" |

## Relays (in-country)
| Alias | IP | DC | Mode per location | Notes |
|---|---|---|---|---|
| `relay-a` | 192.0.2.10 | DC 1 | DE tunnel, FI tunnel | monthly cap 80 TB |
| `relay-b` | 192.0.2.20 | DC 2 | DE DNAT → exit-de-1 | inbound from abroad filtered |

## Exits (abroad)
| Alias | IP | Location | Node instances (service/api ports → panel node id) | Other tenants |
|---|---|---|---|---|
| `exit-de-1` | 198.51.100.10 | DE | node-1 62050/62051 → #1 | none |

## Ports
| Location | Tunnel port | Direct port | WG port | Relay control ports |
|---|---|---|---|---|
| DE | 21001 | 24001 | 25001 | relay-a 7101 |

## DNS (Cloudflare, DNS-only)
| Name | A records | Used by |
|---|---|---|
| `de.example.com` | relay-a, relay-b | DE TUNNEL host |

## Operator preferences
- Backups before changes: yes / no
- Standing permissions: e.g. "DNS edits OK without asking"
- Timezone for reports: Asia/Tehran (UTC+3:30)
