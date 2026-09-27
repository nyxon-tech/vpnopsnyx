# vpn-provider-ops — a Claude skill for running a VPN provider's fleet

[فارسی](README.fa.md)

A [Claude Code / Claude Agent skill](https://docs.claude.com/en/docs/agents-and-tools/agent-skills) that
turns Claude into a careful operator for a VPN/proxy business: Xray panels (PasarGuard, Marzban,
Marzneshin, 3x-ui, Hiddify), exit nodes abroad, in-country relays, reverse tunnels (backhaul), nftables
DNAT relays, Cloudflare DNS round-robin, and censorship/DPI diagnosis, with a focus on Iran.

It encodes lessons from running a real multi-relay fleet: only data tests prove health, how the Iranian
filter behaves and how to tell its patterns apart, which relay mode survives which block, never
hopping traffic between metered in-country relays, panel restart and keep-alive semantics, tunnel memory
traps, safe migrations, and bot/API robustness.

## Install

```bash
git clone https://github.com/nyxon-tech/vpnopsnyx ~/.claude/skills/vpn-provider-ops
```
Then start a new Claude Code session and ask something like "check whether all configs connect" or
"set up a new PasarGuard panel".

## What's inside

- `SKILL.md`: the mental model, ground rules, the data test, the triage flow, and how to report.
- `references/`: architecture, Iran filtering patterns, tunnels, PasarGuard internals, panel setup and
  APIs, Cloudflare, node lifecycle, capacity, and anonymized incident case studies.
- `templates/fleet-inventory.example.md`: the shape of the **private** inventory Claude should keep for
  your fleet. Never commit your real one.

## Safety model

Claude works read-only until you approve each change. It never prints tokens, keys or passwords, and it
never logs in with passwords. You create admin accounts and type passwords yourself.

## License

MIT
