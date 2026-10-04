# VPNOpsNyx

[English](README.md) | [فارسی](README.fa.md) | [Русский](README.ru.md) | [简体中文](README.zh-CN.md)

![Обзор сетевых операций VPNOpsNyx](assets/vpnopsnyx-hero.png)

AI Skill для управления VPN, прокси, панелями, узлами, туннелями и сетевыми операциями в Claude, Codex, ChatGPT и других AI-агентах.

VPNOpsNyx не является VPN-протоколом, реализацией туннеля или форком панели. Это структурированная операционная база знаний, которая помогает AI-агентам анализировать, планировать, устанавливать, проверять, диагностировать и документировать VPN- и прокси-инфраструктуру.

## Возможности

- Панели и control plane: 3x-ui, PasarGuard, Marzban, Marzneshin, Hiddify, Remnawave, S-UI и панели WireGuard.
- Ядра и протоколы: Xray-core, sing-box, WireGuard, AmneziaWG, Hysteria2, TUIC, Trojan, VMess, VLESS, Shadowsocks, MTProto и Reality/TLS.
- Туннели и реле: Backhaul, [BackPack](https://github.com/AminMGMT/BackPack), Rathole, Paqet, FRP, DaggerConnect, DNAT/nftables, GRE, GRE6, 6TO4, SIT, IPIP, Geneve, WireGuard relay и SSH reverse tunnel.
- Операции: health check, проверка реального потока данных, SSL, DNS, firewall, жизненный цикл узлов, capacity, incident response, migration и rollback.
- Сообщество: каталог публичных профилей и репозиториев с прямыми ссылками и статусом проверки.

![Многоуровневая архитектура VPNOpsNyx](assets/vpnopsnyx-architecture.png)

## Установка как Skill

### Claude

```bash
git clone https://github.com/nyxon-tech/vpnopsnyx ~/.claude/skills/vpnopsnyx
```

### Codex

```bash
git clone https://github.com/nyxon-tech/vpnopsnyx ~/.codex/skills/vpnopsnyx
```

Для других AI-агентов клонируйте репозиторий в каталог skills/plugins и используйте `SKILL.md` как основную точку входа.

## Основные файлы

- `SKILL.md` — инструкции агента, правила безопасности и маршрутизация к справочным материалам.
- `scripts/` — проверенные на практике скрипты оператора (см. `scripts/README.md`): реальный трафик пользователей по релеям, состояние туннелей, тест xDi в обоих направлениях, DNAT с предпросмотром, правка нод и сертификатов PasarGuard, DNS Cloudflare и аудит разделения брендов.
- `docs/field-observations-2026-09.md`, `docs/field-observations-2026-10.md` — обезличенные полевые наблюдения и их ограничения.
- `docs/ecosystem-guide.md` — различия между панелями, ядрами, VPN, reverse tunnel, overlay, клиентами и routing data.
- `docs/install-recipes.md` — проверенные инструкции установки с preflight и verification.
- `docs/community-review.md` — обзор community-репозиториев.
- `registries/ecosystem.json` — основной каталог панелей, ядер, туннелей, клиентов, installer и routing data.
- `registries/community-repositories.json` — снимок 111 публичных репозиториев указанных аккаунтов.
- `CONTRIBUTING.md` — правила Fork, Pull Request, проверки источников и безопасности.
- `guides/panels/` — отдельные руководства по установке, API, backup, upgrade и troubleshooting основных панелей.
- `guides/tunnels/` — пошаговые руководства для туннелей с verification и rollback.
- `.github/workflows/` — автоматическая проверка JSON, структуры Skill, ссылок, шаблонов секретов и ежемесячная перепроверка источников.
- `docs/agent-compatibility.md` — совместимость с Codex, Claude и другими агентами.
- `CHANGELOG.md` — история выпусков.

## Полевые уроки (октябрь 2026)

Обезличенные наблюдения (`operator-observed`) в парке из двух брендов с несколькими иранскими дата-центрами реле:

1. **Постоянные GRE-линки реле.** Обычный GRE с DNAT пропускал пользователей там, где TCP DNAT и xDi не
   работали, почти без нагрузки на CPU и без лимита линков на выход; некоторые дата-центры его блокируют.
   `scripts/relay/greunit.sh`, `references/tunnels.md` §16.
2. **Реле с новым IP — это новое реле.** В новом диапазоне GRE и объёмный TCP перестали работать, оставался
   только xDi с набором со стороны выхода, затем пропал и он. Перемерьте все режимы и не делайте такое реле
   единственным для локации. `references/tunnels.md` §17.
3. **Один исходящий xDi-линк на выход — подтверждено снова.** Второй линк проходил первый тест и умирал через
   минуты на четырёх выходах. У выхода, общего для двух брендов, один такой линк на всех. `references/tunnels.md` §15.
4. **Не ставьте xDi-реле за домен панели и подписок.** Чтение работало, но тела `POST`/`PUT` зависали ~16 минут,
   и продления через бота не проходили. Проверяйте `POST` через каждый адрес. `references/pasarguard.md` §16.
5. **Мёртвые линки продолжают есть CPU.** Отключайте их с обеих сторон сразу после подтверждения.
6. **Следите за неудачными входами в панель и блокируйте осознанно.** `scripts/panel/auth_failures.sh`,
   `scripts/panel/blocklist.sh`, `references/pasarguard.md` §17.
7. **Проверяйте разделение брендов и в DNS, и на реле.** `scripts/local/dns_brand_audit.sh` для записей,
   `scripts/relay/forward_audit.sh` для пробрасываемых портов.

## Безопасность

- Агент должен оставаться в режиме read-only до явного разрешения оператора.
- Нельзя сохранять пароли, API-токены, private key, tunnel token, subscription URL и реальные inventory серверов.
- Команды `curl | bash` и удалённые installer следует рассматривать как выполнение стороннего кода.
- Для production используйте закреплённые tag, commit или release, а перед изменениями подготовьте backup и rollback.
- После сетевых изменений проверяйте реальный поток данных, а не только статус service.

## Благодарность сообществу

Мы благодарим [erfjabplus](https://github.com/erfjabplus), [AsanFillter](https://github.com/AsanFillter), [rezazoom](https://github.com/rezazoom), [azavaxhuman](https://github.com/azavaxhuman), [ircfspace](https://github.com/ircfspace), [primeZdev](https://github.com/primeZdev), [ppouria](https://github.com/ppouria) и [MHSanaei](https://github.com/MHSanaei) за публичные проекты и документацию, помогающие сохранять интернет открытым и доступным.

Мы также благодарим разработчиков и сопровождающих инструментов, упомянутых в VPNOpsNyx: [Azumi67](https://github.com/Azumi67), [PasarGuard](https://github.com/PasarGuard), [vpaneladmin](https://github.com/vpaneladmin), [Gozargah](https://github.com/Gozargah), [marzneshin](https://github.com/marzneshin), [hiddify](https://github.com/hiddify), [remnawave](https://github.com/remnawave), [alireza0](https://github.com/alireza0), [Musixal](https://github.com/Musixal), [behzadea12](https://github.com/behzadea12), [opiran-club](https://github.com/opiran-club) и [itsFLoKi](https://github.com/itsFLoKi). Упоминание является благодарностью и указанием источника, а не гарантией безопасности всех проектов аккаунта.

## Fork и участие

**Сделайте Fork VPNOpsNyx и помогите улучшить общую базу знаний.** Добавляйте панели, туннели, проверенные процедуры установки, безопасный rollback, troubleshooting, исправления источников и переводы.

1. Нажмите **Fork** в верхней части репозитория.
2. Создайте отдельную branch.
3. Добавьте изменение и ссылки на авторитетные источники.
4. Откройте Pull Request в `nyxon-tech/vpnopsnyx`.

Перед отправкой прочитайте [CONTRIBUTING.md](CONTRIBUTING.md). Не добавляйте credentials, private key, subscription URL, production IP или данные пользователей.

## Лицензия

MIT
