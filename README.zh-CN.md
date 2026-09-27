# VPNOpsNyx

[English](README.md) | [فارسی](README.fa.md) | [Русский](README.ru.md) | [简体中文](README.zh-CN.md)

![VPNOpsNyx 网络运维概览](assets/vpnopsnyx-hero.png)

面向 Claude、Codex、ChatGPT 及其他 AI 编程代理的 VPN、代理、面板、节点、隧道和网络运维 Skill。

VPNOpsNyx 不是 VPN 协议、隧道实现或某个面板的分支。它是一套结构化运维知识库，用于帮助 AI 代理安全地检查、规划、安装、验证、排查并记录 VPN 与代理基础设施。

## 覆盖范围

- 面板与控制平面：3x-ui、PasarGuard、Marzban、Marzneshin、Hiddify、Remnawave、S-UI 和 WireGuard 面板。
- 核心与协议：Xray-core、sing-box、WireGuard、AmneziaWG、Hysteria2、TUIC、Trojan、VMess、VLESS、Shadowsocks、MTProto 和 Reality/TLS。
- 隧道与中继：Backhaul、Rathole、Paqet、FRP、DNAT/nftables、GRE、GRE6、6TO4、SIT、IPIP、Geneve、WireGuard relay 和 SSH reverse tunnel。
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
- `docs/ecosystem-guide.md`：区分面板、核心、VPN、反向隧道、覆盖网络、客户端和路由数据。
- `docs/install-recipes.md`：带有预检和验证说明的安装流程。
- `docs/community-review.md`：社区仓库逐项审查。
- `registries/ecosystem.json`：面板、核心、隧道、客户端、安装器和路由数据主目录。
- `registries/community-repositories.json`：指定账号的 111 个公开仓库快照。
- `CONTRIBUTING.md`：Fork、Pull Request、来源验证和安全要求。

## 安全模型

- 未经运维人员明确批准，代理应保持只读。
- 不得保存密码、API token、私钥、隧道密钥、订阅 URL 或真实服务器 inventory。
- `curl | bash` 和远程安装器都应按执行第三方代码处理。
- 生产环境应使用固定 tag、commit 或 release，并在变更前准备备份和回滚。
- 网络变更后必须验证真实数据流，不能只检查服务状态。

## 社区致谢

感谢 [erfjabplus](https://github.com/erfjabplus)、[AsanFillter](https://github.com/AsanFillter)、[rezazoom](https://github.com/rezazoom)、[azavaxhuman](https://github.com/azavaxhuman)、[ircfspace](https://github.com/ircfspace)、[primeZdev](https://github.com/primeZdev)、[ppouria](https://github.com/ppouria) 和 [MHSanaei](https://github.com/MHSanaei) 提供公开项目与文档，帮助互联网保持开放和可访问。列入名单不代表对账号下所有项目作安全背书。

## Fork 与贡献

**Fork VPNOpsNyx，并帮助完善这套共享知识库。** 欢迎添加新面板、隧道、经验证的安装流程、安全回滚、故障排查、来源修正和翻译。

1. 点击仓库顶部的 **Fork**。
2. 在自己的 Fork 中创建独立 branch。
3. 提交修改并附上权威来源链接。
4. 向 `nyxon-tech/vpnopsnyx` 发起 Pull Request。

提交前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。请勿提交 credentials、私钥、订阅 URL、生产 IP 或用户数据。

## 许可证

MIT
