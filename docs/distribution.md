# Distribution And Release Policy

## Supported Installation

VPNOpsNyx is distributed from its public GitHub repository. This preserves the
complete skill, references, registries, runbooks, templates, and validation scripts.

```bash
git clone https://github.com/nyxon-tech/vpnopsnyx ~/.codex/skills/vpnopsnyx
```

```bash
git clone https://github.com/nyxon-tech/vpnopsnyx ~/.claude/skills/vpnopsnyx
```

Other agents can clone the repository into their skill directory and use `SKILL.md`
as the entrypoint. Release archives are available from GitHub Releases for operators
who require a fixed version. Pin a release tag instead of tracking `main` in controlled
environments.

## Registry Status

The repository is packaged as a portable filesystem skill and includes
`agents/openai.yaml` plus `metadata.json`. It is not claimed to be listed in an
official OpenAI, Anthropic, or third-party marketplace. A registry submission should
be added only through that registry's documented review process, with its resulting
public listing linked here.

## Release Gate

Create the next release only when the repository has a meaningful, reviewed change.
Before tagging a release:

1. run structure, evidence, secret-pattern, and link validation;
2. confirm public documentation contains no credentials or infrastructure identifiers;
3. review open issues and pull requests;
4. update `CHANGELOG.md` and `metadata.json` together;
5. keep unperformed lab or benchmark work marked `not-run`;
6. tag the exact reviewed commit and publish release notes with evidence limits.

Do not reserve or publish `v0.7.0` until these gates are satisfied.

