# Agent Compatibility

VPNOpsNyx uses a portable Markdown-and-JSON layout. `SKILL.md` is authoritative;
agents should load supporting files only when the routing table points to them.

## Codex And OpenAI-Compatible Agents

Install the repository as `vpnopsnyx` inside the agent's skills directory. The
interface metadata is in `agents/openai.yaml`. Invoke it explicitly as
`$vpnopsnyx` when deterministic activation is desired.

## Claude-Compatible Agents

Install the repository in the configured skills directory and use `SKILL.md` as the
entrypoint. The YAML frontmatter name and description provide discovery metadata.
No Claude-specific credentials or account configuration belong in this repository.

## Other Coding Agents

Point the runtime at `SKILL.md`, preserve relative paths, and allow read access to
`guides/`, `references/`, `docs/`, and `registries/`. If the runtime has a smaller
context window, load one product runbook plus only the referenced registry entries.

## Behavioral Contract

All runtimes must preserve the hard safety rules, trust labels, approval boundary,
secret redaction, real-data verification, and rollback reporting defined in
`SKILL.md`. Compatibility does not permit an agent to execute privileged changes
without operator approval.
