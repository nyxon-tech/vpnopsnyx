#!/usr/bin/env python3
"""Validate public-safe lab and benchmark evidence templates."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ALLOWED = {"pass", "fail", "blocked", "not-run"}
ERRORS: list[str] = []


def load(relative: str) -> dict:
    try:
        return json.loads((ROOT / relative).read_text(encoding="utf-8"))
    except Exception as exc:  # validation should report malformed evidence cleanly
        ERRORS.append(f"{relative}: {exc}")
        return {}


lab = load("templates/panel-lab-results.example.json")
expected = {"3x-ui", "Marzban", "PasarGuard", "Remnawave", "Hiddify", "S-UI"}
panels = lab.get("panels", [])
if {item.get("name") for item in panels} != expected:
    ERRORS.append("panel lab template must contain exactly the six supported panels")
for item in panels:
    states = [item.get("api_read"), item.get("restore"), item.get("data_path")]
    if any(state not in ALLOWED for state in states):
        ERRORS.append(f"invalid panel state: {item.get('name')}")
    if "pass" in states and not all((lab.get("generated_at"), item.get("version"), item.get("evidence"))):
        ERRORS.append(f"pass without timestamp, version, and evidence: {item.get('name')}")

benchmark = load("templates/datacenter-benchmark.example.json")
if benchmark.get("result") not in ALLOWED:
    ERRORS.append("invalid benchmark result")
if benchmark.get("result") == "pass" and not all(
    (benchmark.get("measured_at"), benchmark.get("duration_seconds"), benchmark.get("evidence"))
):
    ERRORS.append("benchmark pass requires timestamp, duration, and evidence")
if not benchmark.get("operator_vpn_disabled"):
    ERRORS.append("benchmark must record operator VPN disabled")

if ERRORS:
    print("Evidence validation failed:", file=sys.stderr)
    for error in ERRORS:
        print(f"- {error}", file=sys.stderr)
    raise SystemExit(1)

print("Evidence templates are valid and remain not-run")
