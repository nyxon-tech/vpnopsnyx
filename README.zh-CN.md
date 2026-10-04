# VPNOpsNyx

[English](README.md) | [فارسی](README.fa.md) | [Русский](README.ru.md) | [简体中文](README.zh-CN.md)

![VPNOpsNyx 网络运维概览](assets/vpnopsnyx-hero.png)

面向 Claude、Codex、ChatGPT 及其他 AI 编程代理的 VPN、代理、面板、节点、隧道和网络运维 Skill。

VPNOpsNyx 不是 VPN 协议、隧道实现或某个面板的分支。它是一套结构化运维知识库，用于帮助 AI 代理安全地检查、规划、安装、验证、排查并记录 VPN 与代理基础设施。

## 覆盖范围

- 面板与控制平面：3x-ui、PasarGuard、Marzban、Marzneshin、Hiddify、Remnawave、S-UI 和 WireGuard 面板。
- 核心与协议：Xray-core、sing-box、WireGuard、AmneziaWG、Hysteria2、TUIC、Trojan、VMess、VLESS、Shadowsocks、MTProto 和 Reality/TLS。
- 隧道与中继：Backhaul、[BackPack](https://github.com/AminMGMT/BackPack)、Rathole、Paqet、FRP、DaggerConnect、DNAT/nftables、GRE、GRE6、6TO4、SIT、IPIP、Geneve、WireGuard relay 和 SSH reverse tunnel。
- 运维流程：健康检查、真实数据路径验证、SSL、DNS、防火墙、节点生命周期、容量、故障处理、迁移和回滚。
- 社区研究：包含直接链接和验证状态的公开 GitHub 维护者与仓库目录。

![VPNOpsNyx 分层架构](assets/vpnopsnyx-architecture.png)

## 作为 Skill 安装

### Claude

```bash
git clone https://github.com/nyxon-tech/vpnopsnyx ~/.claude/skills/vpnopsnyx
```

### Codex

```bash
git clone https://github.com/nyxon-tech/vpnopsnyx ~/.codex/skills/vpnopsnyx
```

对于其他 AI 代理，请将仓库克隆到其 skill/plugin 目录，并将 `SKILL.md` 作为入口文件。

## 主要文件

- `SKILL.md`：代理入口、安全规则和参考资料路由。
- `scripts/`：经实地验证的运维脚本（见 `scripts/README.md`）：按中继统计真实用户流量、隧道健康、双向 xDi 测试矩阵、带预检的 DNAT、PasarGuard 节点与证书修改、Cloudflare DNS 及品牌隔离审计。
- `docs/field-observations-2026-09.md`、`docs/field-observations-2026-10.md`：脱敏的现场观察及其适用范围。
- `docs/ecosystem-guide.md`：区分面板、核心、VPN、反向隧道、覆盖网络、客户端和路由数据。
- `docs/install-recipes.md`：带有预检和验证说明的安装流程。
- `docs/community-review.md`：社区仓库逐项审查。
- `registries/ecosystem.json`：面板、核心、隧道、客户端、安装器和路由数据主目录。
- `registries/community-repositories.json`：指定账号的 111 个公开仓库快照。
- `CONTRIBUTING.md`：Fork、Pull Request、来源验证和安全要求。
- `guides/panels/`：主要面板的安装、API、备份、升级与故障排查专用指南。
- `guides/tunnels/`：包含验证和回滚步骤的隧道操作指南。
- `.github/workflows/`：自动检查 JSON、Skill 结构、链接、Secret 模式，并每月复查来源。
- `docs/agent-compatibility.md`：Codex、Claude 与其他代理的兼容说明。
- `CHANGELOG.md`：版本与变更记录。

## 现场经验（2026 年 10 月）

来自一个双品牌、多个伊朗中继机房的运维现场，已脱敏，均为 `operator-observed`：

1. **持久化 GRE 中继链路。** 在 TCP DNAT 和 xDi 都失败的路径上，普通 GRE 加 DNAT 仍能承载用户，几乎不占
   CPU，且每个出口没有链路数量限制；但部分机房会封锁 GRE。`scripts/relay/greunit.sh`，`references/tunnels.md` §16。
2. **换了 IP 的中继要当作新中继。** 新网段上 GRE 和大流量 TCP 失效，只有出口主动拨号的 xDi 可用，之后连它也
   失效。需重新测量所有方式，且不要让这类中继成为某个位置的唯一中继。`references/tunnels.md` §17。
3. **每个出口只能有一条主动拨号的 xDi 链路（再次确认）。** 四个出口上的第二条链路首测通过，几分钟后失效。
   两个品牌共用的出口合计也只有一条。`references/tunnels.md` §15。
4. **不要把 xDi 中继放到面板和订阅域名后面。** 读取正常，但 `POST`/`PUT` 请求体卡住约 16 分钟，导致机器人
   续费失败。请对域名的每个地址测试一次 `POST`。`references/pasarguard.md` §16。
5. **失效链路仍然消耗 CPU。** 确认失效后立即在两端停用。
6. **监控面板登录失败并有依据地封禁。** `scripts/panel/auth_failures.sh`、`scripts/panel/blocklist.sh`、
   `references/pasarguard.md` §17。
7. **在 DNS 和中继两侧都检查品牌隔离。** 记录用 `scripts/local/dns_brand_audit.sh`，转发端口用
   `scripts/relay/forward_audit.sh`。

## 安全模型

- 未经运维人员明确批准，代理应保持只读。
- 不得保存密码、API token、私钥、隧道密钥、订阅 URL 或真实服务器 inventory。
- `curl | bash` 和远程安装器都应按执行第三方代码处理。
- 生产环境应使用固定 tag、commit 或 release，并在变更前准备备份和回滚。
- 网络变更后必须验证真实数据流，不能只检查服务状态。

## 社区致谢

感谢 [erfjabplus](https://github.com/erfjabplus)、[AsanFillter](https://github.com/AsanFillter)、[rezazoom](https://github.com/rezazoom)、[azavaxhuman](https://github.com/azavaxhuman)、[ircfspace](https://github.com/ircfspace)、[primeZdev](https://github.com/primeZdev)、[ppouria](https://github.com/ppouria) 和 [MHSanaei](https://github.com/MHSanaei) 提供公开项目与文档，帮助互联网保持开放和可访问。

我们也感谢 VPNOpsNyx 所引用工具的开发者与维护者：[Azumi67](https://github.com/Azumi67)、[PasarGuard](https://github.com/PasarGuard)、[vpaneladmin](https://github.com/vpaneladmin)、[Gozargah](https://github.com/Gozargah)、[marzneshin](https://github.com/marzneshin)、[hiddify](https://github.com/hiddify)、[remnawave](https://github.com/remnawave)、[alireza0](https://github.com/alireza0)、[Musixal](https://github.com/Musixal)、[behzadea12](https://github.com/behzadea12)、[opiran-club](https://github.com/opiran-club) 和 [itsFLoKi](https://github.com/itsFLoKi)。列入名单仅表示致谢和来源归属，不代表对账号下所有项目作安全背书。

## Fork 与贡献

**Fork VPNOpsNyx，并帮助完善这套共享知识库。** 欢迎添加新面板、隧道、经验证的安装流程、安全回滚、故障排查、来源修正和翻译。

1. 点击仓库顶部的 **Fork**。
2. 在自己的 Fork 中创建独立 branch。
3. 提交修改并附上权威来源链接。
4. 向 `nyxon-tech/vpnopsnyx` 发起 Pull Request。

提交前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。请勿提交 credentials、私钥、订阅 URL、生产 IP 或用户数据。

## 许可证

MIT
