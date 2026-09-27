# VPN panels: fast setup of a new panel, and the APIs bots use

Items marked **(verify)** come from general knowledge of the upstream projects and change between
versions. Check them against the version you install, for example by opening the panel's `/docs`
(FastAPI panels) or its GitHub README.

## Contents
1. Which panel for what
2. Rules for every install
3. New PasarGuard panel in ~30 minutes (checklist)
4. New 3x-ui (Sanaei) panel (checklist)
5. Marzban, Marzneshin, Hiddify: what differs
6. Reality inbound baseline
7. Wiring a new panel into the relay fleet
8. API cheat-sheet for sales bots
9. Traps that break customers
10. Bot-side robustness (timeouts and idempotency)

## 1. Which panel for what

| Panel | Model | Good for | Watch out |
|---|---|---|---|
| **PasarGuard** (Marzban fork) | central panel + remote nodes, groups → inbounds, multiple cores, resellers | multi-location fleets with relays | restart = Xray restart on all nodes; DB writes need a restart |
| **Marzban** | panel + nodes, per-user inbound selection | smaller fleets, huge ecosystem of bots | project is less active; migration path to PasarGuard |
| **Marzneshin** | panel + marznode, "services" instead of inbounds | teams that like its service model | different API shape (services, expire strategies) |
| **3x-ui (Sanaei)** | single server, clients live inside inbounds | one-box resellers, quick personal panels | no real multi-node; version-specific traps (section 9) |
| **Hiddify Manager** | all-in-one with many protocols and its own apps | customers who use the Hiddify app | API v1/v2 differences; forks behave differently |

## 2. Rules for every install

- Prefer the project's **official** installer from its GitHub, pin a version where the installer allows it,
  and read what it will do before running it as root. Don't run pastebin or gist "mirror" scripts.
- **The operator creates admin accounts and types the passwords.** Installers and CLIs prompt
  interactively (`… cli admin create`). Hand them the command; don't generate or enter passwords yourself.
- Put the panel behind HTTPS on a hostname (not a bare IP), on a non-default port and path. Allow only the
  ports you use in the firewall.
- Schedule a nightly DB dump (off-box), and before any risky change on an existing panel, if the operator wants backups.
- For bots, create a **dedicated API admin** with the least rights that work. Never reuse the owner's
  login in a bot.
- Record in the private inventory: hostname, panel URL/port/path, container or service name, DB type,
  version, and where the API credentials live (not the credentials themselves).

## 3. New PasarGuard panel (checklist)

1. **Server prep:** key-only SSH, updates, swap 2–4 GB, BBR and buffer sysctls, `tcp_mtu_probing=0`,
   reserved ports (`node-lifecycle.md`).
2. **Install** with the official script, choosing the DB (MySQL/MariaDB/PostgreSQL for anything beyond a
   toy; SQLite only for tests) **(verify)**:
   `sudo bash -c "$(curl -sL https://github.com/PasarGuard/scripts/raw/main/pasarguard.sh)" @ install --database mysql`
3. **Admin:** the operator runs `pasarguard cli admin create --sudo` **(verify)** and types the password.
4. **HTTPS:** issue a certificate for the panel/subscription hostname. DNS-01 with a zone-scoped
   Cloudflare token avoids depending on port 80 being forwarded through relays. Set the cert/key paths in
   `/opt/pasarguard/.env` (`UVICORN_SSL_CERTFILE`, `UVICORN_SSL_KEYFILE`) and restart.
5. **Core:** one Xray core with a VLESS+Reality inbound per location port, plus DIRECT inbounds
   (section 6). Keep inbound tags stable and readable (`vless-reality-de`, `direct-de`), because hosts,
   groups and every bot integration refer to them.
6. **Nodes:** on each exit server, install a node (official node script, or copy the fleet's template
   and pin the image digest), then register it with its cert and API key, choosing the core.
7. **Hosts:** per inbound, a TUNNEL host (address = location domain resolving to relays, port = location
   port), a DIRECT host (exit domain), and optionally an info host (`{DATA_LEFT}` / `{DAYS_LEFT}` in the remark).
8. **Groups:** e.g. "All locations", "DE only", "Direct only", each bound to its inbounds.
9. **Relays and DNS:** tunnels or DNAT for the new location ports, reserved ports on the relays, A records
   (`cloudflare.md`).
10. **Test:** create a test user, fetch its subscription from an in-country server, run the data test per
    relay × location and an end-to-end test with the real link (xray client plus curl), then delete or
    disable the test user.
11. **Hand-off:** the bot's API admin, backups, and a note of the panel in the inventory.

## 4. New 3x-ui (Sanaei) panel (checklist)

1. Server prep as above.
2. Official installer; the version can be pinned as an argument **(verify)**:
   `bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh)`.
   It asks for the username, password, port and web base path, and the operator answers.
3. **HTTPS: set certificates from the web panel's settings**, not with the CLI's cert menu (see the trap
   in section 9). Decide deliberately whether the subscription server also moves to HTTPS. If it does, all
   existing `http://` subscription links break and must be reissued.
4. Inbounds: VLESS+Reality (section 6). Clients live inside inbounds. Give a customer's clients the same
   `subId` across inbounds, so that one subscription link lists all of them.
5. Subscription service: enable it, set its port/path, and keep HWID limits **off** unless every client
   app the customers use supports them (section 9).
6. For bots: a web base path makes the API base `https://host:port/<webBasePath>/panel/api/...`.

## 5. Marzban, Marzneshin, Hiddify: what differs

- **Marzban:** users choose inbounds per protocol (`inbounds: {vless: [tags]}`), and `proxies` holds
  per-protocol settings such as `flow`. Nodes connect with a cert. The subscription URL prefix comes from
  `XRAY_SUBSCRIPTION_URL_PREFIX` **(verify)**.
- **Marzneshin:** "services" group the inbounds. Users get `service_ids`, and expiry has a strategy
  (`never`, `fixed_date`, `start_on_first_use` + `usage_duration`) **(verify)**.
- **Hiddify Manager:** an admin proxy path plus the admin UUID act as credentials. Usage is in GB, and
  validity is `package_days` from `start_date`. Some forks answer API **v2** user calls with HTTP 500
  while **v1** works; test both and use the one that answers.

## 6. Reality inbound baseline

- Generate the key pair on the panel host (`xray x25519`). The private key stays in the core config; the
  public key is published in the links.
- `shortIds`: a few random hex strings (`openssl rand -hex 8`); an empty string is allowed as one of them.
- `dest`/`serverNames`: a large TLS 1.3 site that is reachable and fast **from the exit node**, and whose
  name is plausible for traffic leaving the country. Different locations can use different ones.
- `flow: xtls-rprx-vision` for TCP Reality.
- The Reality fallback forwards non-Reality clients to `dest`. That makes the data test possible (any
  HTTP code = path OK) and hides the server from active probing.
- Routing on exits: block private ranges (`geoip:private`). Decide explicitly how to handle
  domestic-destination traffic (e.g. `geoip:ir`, `geosite:category-ir`): blocking it avoids abuse and
  helps users notice when their app is misconfigured.

## 7. Wiring a new panel into the relay fleet

- A second panel can share exit servers: install another node instance on different service/API ports.
  Reserve its ports, and label its containers so nobody mistakes them for the first panel's.
- Its location ports must not collide with the first panel's. Give each panel its own port range.
- Relays: add tunnel forwards or DNAT rules for the new ports. Keep a relay's traffic budget in mind,
  because a new panel's users share the same relay quota.
- DNS: separate location names per panel (`de.panel2.example.com`) make it possible to steer each panel's
  users independently.

## 8. API cheat-sheet for sales bots

All values are illustrative; field names and units **(verify)** against your version's `/docs`.

| | 3x-ui | Marzban | Marzneshin | PasarGuard | Hiddify |
|---|---|---|---|---|---|
| Auth | `POST /login` (form) → session cookie | `POST /api/admin/token` (form) → Bearer | `POST /api/admins/token` → Bearer | `POST /api/admin/token` → Bearer | `Hiddify-API-Key: ADMIN_UUID` header on `/ADMIN_PATH/api/v2/admin/…` |
| Create user | `POST /panel/api/inbounds/addClient` (`id`, `settings` = JSON string with `clients[]`) | `POST /api/user` | `POST /api/users` | `POST /api/user` (with `group_ids`) | `POST …/admin/user/` |
| Read user | `GET /panel/api/inbounds/getClientTraffics/{email}` | `GET /api/user/{username}` | `GET /api/users/{username}` | `GET /api/user/{username}` | `GET …/admin/user/{uuid}/` |
| Update | `POST /panel/api/inbounds/updateClient/{uuid}` | `PUT /api/user/{username}` | `PUT /api/users/{username}` | `PUT /api/user/{username}` | `PATCH …/admin/user/{uuid}/` |
| Reset usage | `POST /panel/api/inbounds/{id}/resetClientTraffic/{email}` | `POST /api/user/{username}/reset` | `POST /api/users/{username}/reset` | `POST /api/user/{username}/reset` | set `current_usage_GB` to 0 |
| Volume unit | bytes (field `totalGB`, despite the name), 0 = unlimited | bytes, 0/null = unlimited | bytes | bytes | GB (float) |
| Expiry | `expiryTime` ms epoch; 0 = none; negative = days after first use | `expire` unix seconds; 0/null = none | strategy + date/duration | datetime; `on_hold` status for start-on-first-use | `package_days` from `start_date` |
| Sub link | `http(s)://host:subPort/subPath/{subId}` | `subscription_url` in the user object | `subscription_url` | `subscription_url` | `https://host/CLIENT_PATH/{uuid}/` |

Log in once per process and reuse the token or cookie until it expires. On 401, log in again once, then
fail loudly.

## 9. Traps that break customers

- **3x-ui HWID limit (v3.8-era):** `limitHwid > 0` makes the subscription endpoint return 404 to clients
  that don't send an HWID header (v2rayNG, the Hiddify app), so their subscriptions look deleted. Keep it
  off by default and enable it per customer only when their app supports it.
- **3x-ui HTTPS via CLI:** the CLI's certificate option, answered "yes" to also applying to the panel,
  puts the certificate on the subscription server too. Every `http://` subscription link then breaks. Use
  the web settings, and move the subscription to HTTPS only on purpose.
- **Panels hosted inside Iran, reached from abroad over plain HTTP,** stall after ~5 KB. Big responses
  such as the inbound list never finish, while HTTPS works. Use HTTPS, or reach the panel through
  SOCKS5/SSH. Bots should say "panel did not answer" rather than "inbound not found".
- **Hiddify forks** answering v2 user calls with 500: switch that panel to v1.
- **Reseller data limits** with "disconnect users when limited" cut every user of that reseller at once
  (`pasarguard.md` §6).
- **Subscription domain = tunnel address** (`{HOST_DOMAIN}`): DNS changes to the sub domain also change
  a location's tunnel path (`architecture.md` §4).

## 10. Bot-side robustness (timeouts and idempotency)

- Give every panel call a hard timeout (connect ~10 s, read ~30–60 s). An overloaded or locked panel
  otherwise hangs a purchase for 10+ minutes.
- **Send non-idempotent writes once.** If "add client" or "renew" times out, don't blindly resend it. Read
  back, and only retry when the read proves that the write did not happen.
- **Don't re-read a list that just timed out** in the same operation. Fail fast, refund or keep the order
  pending, and tell the user that the panel did not answer.
- **Order matters on renewals:** extend the expiry first and confirm it, and only then reset usage. If the
  panel dies halfway, the customer must not end up with free zero usage and no renewal.
- Map errors honestly: timeout → "panel did not answer"; confirmed-missing client → "client not found";
  never report a timeout as HTTP 404.
