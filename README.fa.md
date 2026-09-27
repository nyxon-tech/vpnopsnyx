# VPNOpsNyx

[English](README.md) | [فارسی](README.fa.md)

![نمای کلی عملیات شبکه VPNOpsNyx](assets/vpnopsnyx-hero.png)

یک AI Skill برای مدیریت VPN، پراکسی، پنل، نود، تونل و عملیات شبکه؛ قابل استفاده در Claude، Codex، ChatGPT و سایر AI coding agentها.

VPNOpsNyx خودش پروتکل VPN، پیاده‌سازی تونل یا fork یک پنل نیست. این پروژه یک پایگاه دانش عملیاتی ساختاریافته است که به AI Agentها کمک می‌کند زیرساخت VPN و پراکسی را بررسی، طراحی، نصب، اعتبارسنجی، عیب‌یابی و مستندسازی کنند.

## پوشش پروژه

- پنل‌ها و control planeها: 3x-ui، PasarGuard، Marzban، Marzneshin، Hiddify، Remnawave، S-UI، پنل‌های WireGuard و پروژه‌های مرتبط.
- Coreها و پروتکل‌ها: Xray-core، sing-box، WireGuard، AmneziaWG، Hysteria2، TUIC، Trojan، VMess، VLESS، Shadowsocks، MTProto و Reality/TLS.
- تونل‌ها و رله‌ها: Backhaul، Rathole، Paqet، FRP، DNAT/nftables، GRE، GRE6، 6TO4، SIT، IPIP، Geneve، WireGuard relay و SSH reverse tunnel.
- عملیات: health check، تست واقعی مسیر داده، SSL، DNS، firewall، lifecycle نود، ظرفیت، incident، migration و rollback.
- کامیونیتی: فهرست کامل پروفایل‌ها و ریپازیتوری‌های عمومی معرفی‌شده، همراه با لینک مستقیم و وضعیت اعتبارسنجی.

![معماری لایه‌ای VPNOpsNyx](assets/vpnopsnyx-architecture.png)

## نصب به‌عنوان Skill

### Claude

```bash
git clone https://github.com/nyxon-tech/vpnopsnyx ~/.claude/skills/vpnopsnyx
```

### Codex

```bash
git clone https://github.com/nyxon-tech/vpnopsnyx ~/.codex/skills/vpnopsnyx
```

### سایر AI Agentها

ریپازیتوری را در پوشه skill یا plugin ابزار خود clone کنید و فایل `SKILL.md` را به‌عنوان نقطه شروع معرفی کنید. مستندات Markdown و registryهای JSON طوری طراحی شده‌اند که در runtimeهای مختلف قابل استفاده باشند.

## فایل‌های مهم

- `SKILL.md`: نقطه شروع Agent، قواعد امنیتی و مسیر دسترسی به منابع.
- `docs/ecosystem-guide.md`: تفاوت پنل، core، VPN، reverse tunnel، overlay، client و routing data.
- `docs/install-recipes.md`: دستورهای نصب بررسی‌شده همراه با preflight و verification.
- `docs/networking-recipes.md`: راهنمای DNS، firewall، IPv4/IPv6، BBR، mirror و hosts file.
- `docs/community-review.md`: بررسی repo-by-repo پروژه‌های کامیونیتی.
- `docs/sources.md`: گزارش اعتبارسنجی منابع و لینک‌ها.
- `registries/ecosystem.json`: فهرست اصلی پنل‌ها، coreها، تونل‌ها، clientها، installerها و routing data.
- `registries/community-repositories.json`: snapshot کامل ۱۱۱ ریپازیتوری عمومی حساب‌های معرفی‌شده.
- `references/`: راهنماهای عملیاتی معماری، پنل، تونل، Cloudflare، incident، capacity و lifecycle نود.
- `templates/fleet-inventory.example.md`: نمونه inventory خصوصی؛ نسخه تکمیل‌شده را commit نکنید.

## وضعیت منابع

- `verified`: لینک یا منبع عمومی بررسی شده است.
- `official`: منبع توسط سازنده یا سازمان اصلی نگهداری می‌شود.
- `third-party`: ابزار شخص ثالث است و باید قبل از اجرا بررسی شود.
- `community`: پروژه عمومی کامیونیتی است و وجود آن به معنی تأیید امنیتی نیست.
- `unverified`: منبع رسمی یا اطلاعات کافی برای اتوماسیون تأیید نشده است.
- `deprecated`: پروژه قدیمی، متوقف یا جایگزین شده است.

## مدل امنیتی

- Agent تا زمان تأیید صریح اپراتور باید فقط بررسی‌های read-only انجام دهد.
- password، API token، private key، tunnel token، subscription URL و inventory واقعی سرورها نباید داخل chat یا repository ذخیره شوند.
- دستورهای `curl | bash` و installerهای remote باید مانند اجرای کد خارجی بررسی شوند.
- برای محیط production از tag، commit یا release ثابت استفاده کنید و قبل از تغییر backup و rollback آماده داشته باشید.
- بعد از تغییر شبکه، فعال بودن service کافی نیست؛ مسیر واقعی داده باید تست شود.
- ابزارهای نامطمئن، community یا third-party باید با برچسب روشن گزارش شوند.

## مجوز

MIT
