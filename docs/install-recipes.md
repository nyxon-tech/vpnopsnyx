# Install Recipes

These recipes were added only after checking that their upstream URLs exist. They are still remote code execution when used on a server. Review the script, prefer pinned tags or commits, and confirm the operating system before running anything.

## Baseline Debian/Ubuntu Update

Status: `verified` as a standard Debian/Ubuntu package operation.

```bash
apt-get update -y && apt-get upgrade -y
```

Notes:

- Run in a maintenance window on production nodes.
- Kernel, Docker, network stack, or libc upgrades may require a reboot.
- Check disk space first on small VPS instances.

## 3x-ui / Sanaei Panel

Status: `verified`, `official`

Source:

- Repository: https://github.com/MHSanaei/3x-ui
- Installer: https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh
- Docs: https://docs.sanaei.dev

Install:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
```

Pinned stable install example:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) v3.7.0
```

Verification:

```bash
systemctl status x-ui --no-pager
x-ui
```

Operational notes:

- The official README says random username, password, and access path are generated during install.
- Release archives include `.sha256` sums and the installer/updater verifies them.
- The upstream README says the project is intended for personal use and not for illegal or production use; operators should make their own risk decision.

## PasarGuard Node Script

Status: `verified`, `official/third-party to this skill`

Source:

- Repository: https://github.com/PasarGuard/scripts
- Script: https://github.com/PasarGuard/scripts/raw/main/pg-node.sh

Install:

```bash
sudo bash -c "$(curl -sL https://github.com/PasarGuard/scripts/raw/main/pg-node.sh)" @ install --name node-eu-1
```

Verification:

```bash
systemctl list-units --type=service | grep -i pasarguard
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

Notes:

- `--name` is validated by the script and should be stable; use a descriptive name such as `node-eu-1`.
- The script fetches supporting shell libraries. Review the repository before use.
- Do not paste generated node API keys, `.env` values, or certificates into chat.

## VPanel Installer

Status: `verified`, `third-party`

Source:

- Repository: https://github.com/vpaneladmin/vpanel-bash
- Installer: https://raw.githubusercontent.com/vpaneladmin/vpanel-bash/main/vpanel-installer.sh

Install:

```bash
wget -O vpanel-installer.sh https://raw.githubusercontent.com/vpaneladmin/vpanel-bash/main/vpanel-installer.sh
chmod +x vpanel-installer.sh
sudo ./vpanel-installer.sh
```

Important review notes:

- The installer installs packages, enables services, prompts for Telegram bot and panel credentials, and downloads additional files from `https://vpanel.pluslimoo.de/vpanel-bot-main.zip`.
- Treat it as third-party remote code. Review the script and downstream zip source before production use.
- Do not let an AI agent see or store the Telegram bot token, panel username/password, or generated database password.

## Certbot Standalone Certificate

Status: `verified`, common ACME/certbot recipe.

Install and request a certificate:

```bash
apt-get install certbot -y
certbot certonly --standalone --agree-tos --register-unsafely-without-email -d yourdomain.com
```

Renewal test:

```bash
certbot renew --dry-run
```

Certificate paths:

```text
/etc/letsencrypt/live/YOURDOMAIN.COM/fullchain.pem
/etc/letsencrypt/live/YOURDOMAIN.COM/privkey.pem
```

Notes:

- Standalone HTTP-01 needs port 80 free and reachable for the domain.
- If the domain resolves to relays, the relay must forward port 80 to the certificate host during issuance/renewal.
- Prefer using a real email address unless the operator intentionally chooses `--register-unsafely-without-email`.

## Azumi67 6TO4/GRE/IPIP/SIT Tunnel Project

Status: `verified`, `third-party`, `community`

Source:

- Repository: https://github.com/Azumi67/6TO4-GRE-IPIP-SIT

Use:

- Review the upstream README and script before installing.
- Label any generated tunnel configuration as third-party.
- Confirm firewall, private IP, MTU, and rollback plan before applying.

Notes:

- The upstream README describes the project as educational.
- It includes many tunnel types and automated reconfiguration options, so it can change routes, firewall behavior, cron/systemd timers, and kernel tunnel interfaces.

The user-provided direct Python command is reachable, but the script was roughly
6 MB at review time and accepts network-changing options. Do not execute it through
process substitution. Download, inspect, hash, and run a pinned copy instead.

## Azumi67 Backhaul Script

Status: `verified`, `third-party`, `community`, `high-impact`

Source:

- Repository: https://github.com/Azumi67/Backhaul_script
- Installer: https://raw.githubusercontent.com/Azumi67/Backhaul_script/refs/heads/main/backhaul.sh

The supplied installer is only a small bootstrap: it installs `wget`, writes a
launcher under `/etc`, and downloads `backhaul.py` from a GitHub release. Review
both stages. Prefer downloading a pinned release and checking its digest rather
than running this command directly:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Azumi67/Backhaul_script/refs/heads/main/backhaul.sh)"
```

Verify the generated systemd units, listening ports, process owner, and an actual
end-to-end data path. Keep the original configuration for rollback.

## Paqet Tunnel Manager

Status: `verified`, `third-party`, `community`, `high-impact`

Source:

- Repository: https://github.com/behzadea12/Paqet-Tunnel-Manager
- Installer: https://raw.githubusercontent.com/behzadea12/Paqet-Tunnel-Manager/main/paqet-manager.sh
- Core referenced by the manager: https://github.com/hanselime/paqet

User-provided quick start:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/behzadea12/Paqet-Tunnel-Manager/main/paqet-manager.sh)
```

The reviewed manager changes systemd, sysctl, security limits, and iptables raw and
mangle tables. Download and inspect it first. Record current `sysctl`, `iptables-save`,
and service files, then test rollback on a non-production node.

## Musixal Rathole Tunnel v1 and v2

Status: `verified`, `third-party`, `community`, `high-impact`

Source: https://github.com/Musixal/rathole-tunnel

User-provided entrypoints:

```bash
bash <(curl -Ls --ipv4 https://raw.githubusercontent.com/Musixal/rathole-tunnel/main/rathole.sh)
bash <(curl -Ls --ipv4 https://raw.githubusercontent.com/Musixal/rathole-tunnel/main/rathole_v2.sh)
```

Both URLs were reachable. Reviewed scripts install packages, download Rathole,
write systemd units, change firewall state, and may append a fixed GitHub CDN
address to `/etc/hosts`. That hosts override is not recommended. Remove or patch
that behavior in a reviewed local copy before production use. Prefer upstream
Rathole releases for the binary and verify the release artifact.

## OPIran VPS Optimizer

Status: `verified-source`, `third-party`, `community`, `high-impact`

Source: https://github.com/opiran-club/VPS-Optimizer

User-provided quick start:

```bash
apt install curl -y
bash <(curl -s --ipv4 https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/optimizer.sh)
```

Do not use the quick start blindly. Reviewed code can change BBR/sysctl settings,
APT mirrors, DNS, kernel packages, `/etc/hosts`, swap, and reboot the host. Use
`docs/networking-recipes.md` for preflight checks and apply only the selected change.

## Ubuntu Mirror Selector Gist

Status: `verified-source`, `third-party`, `community`

Source: https://gist.github.com/dev-ir/16e2be52370f21fb8dd1baad87818883

The user-provided command is reachable:

```bash
bash <(curl -sSL https://gist.githubusercontent.com/dev-ir/16e2be52370f21fb8dd1baad87818883/raw)
```

The script benchmarks mirrors and rewrites `/etc/apt/sources.list` or the deb822
Ubuntu sources file. Pin the gist revision, back up the source files, inspect the
selected mirror, and verify `apt-get update` before upgrading packages.

## DaggerConnect

Status: `verified-source`, `third-party`, `community`, `high-impact`

Source: https://github.com/itsFLoKi/DaggerConnect

Download-before-run workflow supplied by the user:

```bash
curl -O https://raw.githubusercontent.com/itsFLoKi/DaggerConnect/main/setup.sh
chmod +x setup.sh
sudo ./setup.sh
```

The installer and repository were reachable. Reviewed code downloads a release
binary, writes systemd units, can obtain certificates, and can apply persistent
network tuning. Inspect the script and pin the binary release. The user's prose
about versions 4.2.1 through 4.2.3 and transports named Quantum+/DC could not be
matched to the reviewed public release metadata, so those claims remain
`unverified` and must not drive automated upgrades.
