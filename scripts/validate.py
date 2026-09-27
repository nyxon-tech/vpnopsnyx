#!/usr/bin/env python3
"""Dependency-free structural and secret-safety checks for VPNOpsNyx."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ERRORS: list[str] = []


def fail(message: str) -> None:
    ERRORS.append(message)


for path in sorted(ROOT.rglob("*.json")):
    try:
        json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        fail(f"invalid JSON: {path.relative_to(ROOT)}: {exc}")

skill = ROOT / "SKILL.md"
skill_text = skill.read_text(encoding="utf-8")
frontmatter = re.match(r"\A---\n(.*?)\n---\n", skill_text, re.DOTALL)
if not frontmatter:
    fail("SKILL.md has no YAML frontmatter")
else:
    header = frontmatter.group(1)
    for key in ("name:", "description:", "license:", "metadata:"):
        if key not in header:
            fail(f"SKILL.md frontmatter is missing {key}")
    if "name: vpnopsnyx" not in header:
        fail("SKILL.md name must remain vpnopsnyx")

required = [
    "README.md",
    "README.fa.md",
    "README.ru.md",
    "README.zh-CN.md",
    "agents/openai.yaml",
    "metadata.json",
    "guides/panels/README.md",
    "guides/tunnels/README.md",
]
for relative in required:
    if not (ROOT / relative).is_file():
        fail(f"missing required file: {relative}")

secret_patterns = {
    "private key": re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    "GitHub token": re.compile(r"\b(?:ghp|github_pat)_[A-Za-z0-9_]{20,}\b"),
    "AWS access key": re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    "generic bearer token": re.compile(r"\bBearer\s+[A-Za-z0-9._~-]{24,}\b", re.I),
}

for path in sorted(ROOT.rglob("*")):
    if not path.is_file() or ".git" in path.parts or path.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}:
        continue
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue
    for label, pattern in secret_patterns.items():
        if pattern.search(text):
            fail(f"possible {label}: {path.relative_to(ROOT)}")

if ERRORS:
    print("VPNOpsNyx validation failed:", file=sys.stderr)
    for error in ERRORS:
        print(f"- {error}", file=sys.stderr)
    raise SystemExit(1)

print("VPNOpsNyx validation passed")
