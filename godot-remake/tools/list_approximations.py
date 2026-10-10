"""Regenerate docs/APPROXIMATIONS.md from data/approximations.json.

Usage (from the project root):  python tools/list_approximations.py
Add an entry to data/approximations.json whenever a card or rule is implemented approximately.
"""
import json
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
data = json.load(open("data/approximations.json", encoding="utf-8"))
about = data.pop("_about", "")
cards = {k: v for k, v in data.items() if not k.startswith("RULE:")}
rules = {k: v for k, v in data.items() if k.startswith("RULE:")}

lines = ["# Approximations: things that are not yet like the original", "",
         "Generated from `data/approximations.json` by `tools/list_approximations.py`. Do not edit by hand.", "",
         "%d cards and %d rules." % (len(cards), len(rules)), "",
         "## Cards", "", "| Card | What differs | What it takes to fix |", "|---|---|---|"]
for name in sorted(cards):
    e = cards[name]
    lines.append("| %s | %s | %s |" % (name, e["gap"], e.get("fix", "")))
lines += ["", "## Rules and systems", "", "| Area | What differs | What it takes to fix |", "|---|---|---|"]
for name in sorted(rules):
    e = rules[name]
    lines.append("| %s | %s | %s |" % (name[len("RULE: "):], e["gap"], e.get("fix", "")))
open("docs/APPROXIMATIONS.md", "w", encoding="utf-8").write("\n".join(lines) + "\n")
print("wrote docs/APPROXIMATIONS.md")
