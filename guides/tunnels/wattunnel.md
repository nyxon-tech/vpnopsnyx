# WatTunnel Runbook

**Source:** https://github.com/JohnWatsoon/WatTunnel
**Author / contact:** JohnWatsoon — Telegram t.me/WatxDev (channel), t.me/watxox
**Status:** `verified-source`, `third-party`, `community`, `high-impact`
**License:** MIT (vendors `golang.org/x/crypto`, `x/net`, `x/sys` — BSD-3-Clause). Latest reviewed release: **v3.1.1**.

Fast, encrypted TCP/UDP tunnel aimed at Iran↔Kharej links that survive heavy
filtering ("keeps working when the network only lets ping through"). One static
Go binary (`wattun`) plus a menu-driven `wattun-manager`, configured from a single
pasted token. Positioned as an anti-censorship carrier you run a real end-to-end
protocol (VLESS+Reality, TLS, WireGuard) *inside*.

## What it provides

- **Carriers (transports):** `icmp`, `udp`, `tcp`, `tls`, `ws`, `wss`, `h2`, `h2c`,
  `grpc`, Cloudflare with **ECH**, and a **reverse** mode (Kharej dials Iran). Several
  carriers can be **bonded** into one tunnel.
- **Anti-DPI / evasion:** fake-SNI desync (`fake-sni` modes `seq`/`ttl`/`rst`/`synrst`/`paws`/`auto`),
  TLS-shaped raw TCP (`tcp-mimic`), DNS-shaped UDP (`udp-dns`), header masking
  (`hdr-mask`), padding/jitter (`shape`), TLS fragmentation (`tls-frag`), small ClientHello
  (`tls-small-ch`), ECH ladder (`ech: ladder`), connection churn (`pool-rotate`), ICMP volume governor.
- **Operations:** automatic CPU/RAM-based tuning of `conns`/`sessions`/`win-max`,
  per-port traffic stats and quotas, auto-heal + self-update with rollback, a loopback
  `metrics` endpoint. CLI: `wattun status | test NAME | ports NAME | matrix NAME | blackout NAME | update`.
- **Crypto:** ChaCha20-Poly1305 per session; key derived from a pre-shared key + random
  session ID; since 2.10.0 an ephemeral X25519 exchange per session (forward secrecy).
  **Encryption covers only the Iran↔Kharej leg** — run an E2E-encrypted protocol inside.

## Topology & config

- **Kharej (origin) is set up first** and generates the connection **token** (`wat1:...`).
  **Iran** pastes the token, tests carrier types, then forwards user ports to Kharej.
- Port-map syntax: `443, 8443:443, 53/udp` — `8443:443` means Iran:8443 → Kharej:443.
- **Kharej dials only its own `127.0.0.1` and allowlisted ports.** Reverse mode flips the
  dial direction.
- Config lives at `/etc/wattun/<name>.yml`; the systemd template is `wattun@<name>.service`
  (`ExecStart=/usr/local/bin/wattun -config /etc/wattun/%i.yml`, `Restart=always`, hardened:
  `NoNewPrivileges`, `ProtectSystem=strict`, `ReadWritePaths=/etc/wattun`, `MemoryDenyWriteExecute`).
  Full config schema: the repo's `docs/TECHNICAL.md` (not reproduced here).

## Install (review before running — treat as remote code execution)

Documented one-liner, run as **root** with systemd on both servers (linux amd64/arm64):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/JohnWatsoon/WatTunnel/main/install.sh)
```

The installer (reviewed at v3.1.x): resolves the latest release, downloads
`wattun-linux-$ARCH` + `.sha256`, verifies `SHA256SUMS`/`SHA256SUMS.sig` with an RSA
public key embedded in the script (`openssl dgst -verify`), installs the binary to
`/usr/local/bin/wattun` and sets `setcap cap_net_raw,cap_net_admin,cap_net_bind_service=+ep`,
installs `wattun-manager`, writes the systemd template, and offers a first-run wizard
(`wattun-manager kharej` / `iran`). Uninstall: `install.sh --uninstall` (keeps
`/etc/wattun` unless `WAT_PURGE=1` or an interactive yes).

**Security review flags (do not ignore):**
- Runs the `main` branch as root with **no pinned commit/tag** — pin a release/commit for production.
- Signature/checksum step can be **silently skipped** if `openssl` is missing or `WAT_SKIP_CHECKSUM=1`;
  the checksum file shares the binary's origin, so it is integrity, not provenance.
- **Unsigned paths:** local `dist/` builds, `go`/`build.sh` source builds (build.sh unreviewed),
  and `wattun-manager` fetched from `raw.githubusercontent.com/.../main` bypass the signed release.
- The downloaded binary is executed (`-version`) as root *before* full trust on unsigned paths.
- `WAT_SIG_PUB` can **override the trust anchor**; `WAT_PROXY` routes all downloads through a
  third-party mirror (docs suggest `ghproxy.net`) which then sees every request.
- The tunnel **service runs as root** (no `User=`); capabilities + hardening reduce but do not
  eliminate blast radius. Prefer a pinned binary, verify the signature yourself, and review
  `wattun@.service` before enabling.

## Operate safely

1. Record both sides: token (secret — **mask/never commit**), carriers in use, port maps,
   fake-sni/evasion settings, firewall rules, MTU, and last known-good `/etc/wattun/<name>.yml`.
2. Set up Kharej first, keep the token on a private channel (it contains the key — treat as a password).
3. Start Kharej, then Iran; confirm with `wattun test NAME` and `wattun status`, and inspect sockets/logs.
4. **Verify a real application request through every advertised port**, and confirm reconnect after a
   controlled `systemctl restart wattun@NAME`. Keep the `metrics` endpoint bound to `127.0.0.1`.
5. Treat it as unproven for 24h (filtered paths can die within the hour) — re-check tunnel health and
   real-user bytes the next day.

**Rollback:** `systemctl disable --now wattun@NAME`, restore the prior binary
(`/usr/local/bin/wattun.prev`), config, and firewall rules, `systemctl daemon-reload`, restart the
old path, and retest the original route. `--uninstall` for full removal.

> All performance claims on the project page (e.g. "~5x the next best ICMP tunnel") are the
> author's own and are **unverified**.
