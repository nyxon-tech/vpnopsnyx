# VPNOpsNyx

[English](README.md)

**VPNOpsNyx** یک AI Skill برای مدیریت عملیات VPN، پراکسی، پنل، نود، تانل، SSL، DNS و شبکه است؛ برای Claude، Codex، ChatGPT و سایر AI coding agentها.

این پروژه خود VPN یا تانل نیست. هدفش این است که هوش مصنوعی‌ها بتوانند با احتیاط و با منبع معتبر روی زیرساخت VPN کار کنند: اول بررسی، بعد برنامه، بعد اجرای تأییدشده، بعد تست واقعی و گزارش.

## پوشش پروژه

- **پنل‌ها:** 3x-ui/Sanaei، PasarGuard، VPanel، Marzban، Marzneshin، Hiddify و ابزارهای مشابه.
- **Core و پروتکل‌ها:** Xray-core، sing-box، WireGuard، AmneziaWG، Hysteria2، TUIC، Trojan، VMess، VLESS، Shadowsocks، MTProto و Reality/TLS.
- **تانل‌ها و رله‌ها:** Backhaul، DNAT/nftables، GRE/GRE6/6TO4/SIT/IPIP/Geneve، WireGuard relay، SSH reverse tunnel و Cloudflare DNS.
- **عملیات:** نصب، SSL، health check، تست مسیر واقعی، مهاجرت نود، capacity، troubleshooting، rollback و گزارش حادثه.
- **کامیونیتی:** رجیستری GitHubهای معرفی‌شده و repoهای عمومی مرتبط.

## نصب

### Claude

```bash
git clone https://github.com/nyxon-tech/vpnopsnyx ~/.claude/skills/vpnopsnyx
```

### Codex

```bash
git clone https://github.com/nyxon-tech/vpnopsnyx ~/.codex/skills/vpnopsnyx
```

## فایل‌های مهم

- `SKILL.md`: نقطه شروع اسکیل، قوانین امنیتی، مسیرهای بررسی و glossary فارسی.
- `docs/install-recipes.md`: دستورهای نصب تأییدشده و نکات preflight.
- `docs/sources.md`: گزارش اعتبارسنجی لینک‌ها و GitHubهای معرفی‌شده.
- `registries/`: رجیستری پنل‌ها، coreها، تانل‌ها، ابزارها، کامیونیتی و فهرست کامل ۱۱۱ ریپازیتوری بررسی‌شده.
- `docs/community-review.md`: بررسی ریپو به ریپوی پروژه‌های مرتبط کامیونیتی.
- `docs/networking-recipes.md`: نکات DNS، فایروال، IPv4/IPv6، BBR و optimizerها.
- `references/`: راهنماهای عملیاتی عمیق برای DNS، tunnel، panel، filtering، node lifecycle و incidentها.
- `templates/fleet-inventory.example.md`: نمونه inventory خصوصی؛ نسخه واقعی را داخل repo نگذار.

## مدل امنیتی

- تا اپراتور تأیید نکند، agent فقط باید بخواند و بررسی کند.
- secret، token، private key، لینک subscription، رمز پنل و IP inventory واقعی نباید داخل chat یا repo ذخیره شود.
- هر `curl | bash` یا installer خام باید مثل remote code execution بررسی شود.
- بعد از تغییر شبکه، status سرویس کافی نیست؛ باید تست داده واقعی انجام شود.
- هر مورد نامطمئن با `third-party`، `community`، `unverified` یا `deprecated` علامت می‌خورد.

## مجوز

MIT
