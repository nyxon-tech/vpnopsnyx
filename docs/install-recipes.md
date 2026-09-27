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

