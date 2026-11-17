#!/bin/bash
# jarvis-voice: connect the voice to an agent built with jarvis-vault-template.
# Copyright (C) 2026 Jonny Rose. Part of jarvis-voice, a modified copy of
# backtalk by Jared Rhodenizer.
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Writes backtalk.json for you: which folder is your agent, what it's called,
# and where its vault is. It reads all three from the agent's CLAUDE.md.
# Never overwrites an existing backtalk.json.
#
#   ./connect-agent.sh                 looks for ../agent (the vault template's layout)
#   ./connect-agent.sh ~/jarvis/agent  any agent folder with a CLAUDE.md

set -euo pipefail
cd "$(dirname "$0")"
HERE="$PWD"
CFG="$HERE/backtalk.json"

if [ -e "$CFG" ]; then
  echo "backtalk.json already exists, so it was left alone."
  python3 -c "import json;c=json.load(open('$CFG'));print('  agent:', c.get('agent_dir'), '| name:', c.get('name'))" 2>/dev/null || true
  echo "To reconnect, rename it (e.g. backtalk.json.old.bak) and run this again."
  exit 0
fi

AGENT="${1:-}"
if [ -z "$AGENT" ]; then
  if [ -f "$HERE/../agent/CLAUDE.md" ]; then
    AGENT="$HERE/../agent"
  else
    echo "Couldn't find your agent next to this folder (expected ../agent/CLAUDE.md)."
    echo "Run it with your agent folder:  ./connect-agent.sh ~/path/to/agent"
    echo "No agent yet? Build one first: https://github.com/jonny-rose/jarvis-vault-template"
    exit 1
  fi
fi
AGENT="${AGENT/#\~/$HOME}"
[ -f "$AGENT/CLAUDE.md" ] || { echo "error: $AGENT has no CLAUDE.md, so it isn't an agent folder"; exit 1; }
AGENT="$(cd "$AGENT" && pwd)"

python3 - "$AGENT" "$CFG" <<'PY'
import json, re, sys
agent, cfg = sys.argv[1], sys.argv[2]
text = open(f"{agent}/CLAUDE.md", encoding="utf-8").read()
# The vault template's boot file says: You are **Name**, ...  and  The vault is at `path`.
m = re.search(r"You are \*\*([^*\n]+)\*\*", text)
name = m.group(1).strip() if m else "Assistant"
v = re.search(r"The vault is at `([^`\n]+)`", text)
config = {
    "agent_dir": agent,
    "name": name,
    "ptt_key": "home",
    "voice": "bm_lewis",
    "stt_model": "small.en",
}
if v:
    config["extra_dirs"] = [v.group(1)]
with open(cfg, "w", encoding="utf-8") as fh:
    json.dump(config, fh, indent=2)
    fh.write("\n")
print(f"Connected to {name}")
print(f"  agent folder: {agent}")
print(f"  vault:        {v.group(1) if v else '(none found in CLAUDE.md; add it to extra_dirs if you have one)'}")
if not m:
    print("  (No name found in CLAUDE.md, so it's called 'Assistant': change \"name\" in backtalk.json.)")
PY
echo "  voice:        bm_lewis (built-in, British). Hold the Home key to talk."
echo
echo "Start it with ./run.sh. For a natural voice later: ./add-elevenlabs.sh"
