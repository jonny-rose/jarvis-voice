#!/bin/bash
# jarvis-voice: switch the voice to ElevenLabs, any time after install.
# Copyright (C) 2026 Jonny Rose. Part of jarvis-voice, a modified copy of
# backtalk by Jared Rhodenizer.
# SPDX-License-Identifier: AGPL-3.0-or-later
#
#   ./add-elevenlabs.sh        set up the key, pick a voice by ear, switch it on
#   ./add-elevenlabs.sh --off  back to the built-in voice (the key stays stored)
#
# The API key is never written to a file and never shown: it lives in the
# macOS Keychain (or Linux secret-tool), the same place the voice reads it from.
# The built-in voice stays installed as the automatic fallback.

set -euo pipefail
cd "$(dirname "$0")"
CFG="backtalk.json"
API="${ELEVENLABS_API_BASE:-https://api.elevenlabs.io}"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

[ -f "$CFG" ] || { echo "No backtalk.json yet. Connect the voice to your agent first: ./connect-agent.sh"; exit 1; }

# Update keys inside "elevenlabs" in backtalk.json, keeping everything else.
#   set_el key value [key value ...]   ("true"/"false" become booleans)
set_el() {
  python3 - "$CFG" "$@" <<'PY'
import json, sys
path, pairs = sys.argv[1], sys.argv[2:]
changes = {k: {"true": True, "false": False}.get(v, v) for k, v in zip(pairs[::2], pairs[1::2])}
cfg = json.load(open(path, encoding="utf-8"))
cfg.setdefault("elevenlabs", {}).update(changes)
with open(path, "w", encoding="utf-8") as fh:
    json.dump(cfg, fh, indent=2)
    fh.write("\n")
PY
}

if [ "${1:-}" = "--off" ]; then
  set_el enabled false
  echo "ElevenLabs is off: the built-in voice speaks from the next launch. Your key stays stored."
  exit 0
fi

ask() { local a=""; read -r -p "$1" a || true; echo "$a"; }

SLOT="$(python3 -c "import json;print(json.load(open('$CFG')).get('elevenlabs',{}).get('key_slot') or 'backtalk-elevenlabs')")"

echo "== ElevenLabs voice =="
echo "A natural, human-sounding voice on your own ElevenLabs account. The free tier is"
echo "enough to try voices; everyday talking needs a paid plan (Starter; see elevenlabs.io/pricing)."
echo

# 1. ffmpeg: the voice is mastered through it.
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "-- ffmpeg is needed and isn't installed."
  case "$(uname -s)" in
    Darwin) CMD="brew install ffmpeg" ;;
    Linux)  CMD="sudo apt-get install -y ffmpeg" ;;
    *)      CMD="" ;;
  esac
  if [ -n "$CMD" ] && [ "$(ask "   Install it now with '$CMD'? [Y/n] ")" != "n" ]; then
    $CMD
  else
    echo "   Install ffmpeg, then run this again."; exit 1
  fi
fi

# 2. The key, from the same stores the voice reads, in the same order.
get_key() {
  local k=""
  if [ "$(uname -s)" = Darwin ]; then
    k="$(security find-generic-password -s "$SLOT" -w 2>/dev/null || true)"
  elif command -v secret-tool >/dev/null 2>&1; then
    k="$(secret-tool lookup service "$SLOT" 2>/dev/null || true)"
  fi
  echo "${k:-${ELEVENLABS_API_KEY:-}}"
}
KEY="$(get_key)"
if [ -z "$KEY" ]; then
  echo "-- Your API key: on elevenlabs.io, sign in, open your profile menu, then API Keys, and create one."
  echo "   It goes into your system's secret store, never a file. Paste it at the prompt (it stays hidden)."
  if [ "$(uname -s)" = Darwin ]; then
    security add-generic-password -a "$USER" -s "$SLOT" -T /usr/bin/security -w
  elif command -v secret-tool >/dev/null 2>&1; then
    secret-tool store --label "backtalk ElevenLabs" service "$SLOT"
  else
    echo "   No secret store found. Set ELEVENLABS_API_KEY in your environment and run this again."
    exit 1
  fi
  KEY="$(get_key)"
  [ -n "$KEY" ] || { echo "   The key wasn't saved. Run this again."; exit 1; }
  echo "   Saved as '$SLOT'."
fi

# 3. The voices on this account. The key goes to curl through a file
#    descriptor, never as an argument other programs could see.
RC=0
VOICES="$(curl -fsS "$API/v1/voices" -H @<(printf 'xi-api-key: %s\n' "$KEY") 2>/dev/null)" || RC=$?
if [ "$RC" = 22 ]; then
  echo "-- ElevenLabs refused the key. It's usually wrong or expired: delete the stored key"
  echo "   (macOS: Keychain Access, item '$SLOT') and run this again to enter a new one."
  exit 1
elif [ "$RC" != 0 ]; then
  echo "-- Couldn't reach ElevenLabs. Check your internet connection and run this again."
  exit 1
fi
unset KEY

LIST="$(printf '%s' "$VOICES" | python3 -c '
import json, sys
voices = sorted(json.load(sys.stdin).get("voices", []), key=lambda v: v.get("name", "").lower())
for v in voices:
    lab = v.get("labels") or {}
    bits = [lab.get(k) for k in ("gender", "accent", "age", "description", "use_case") if lab.get(k)]
    print(v["voice_id"] + "\t" + v.get("name", "?") + "\t" + ", ".join(bits))
')"
[ -n "$LIST" ] || { echo "No voices on this account yet. Add some from the Voice Library on elevenlabs.io, then run this again."; exit 1; }

cp "$CFG" "$CFG.before-elevenlabs.bak"
while true; do
  echo
  echo "Voices on your account:"
  printf '%s\n' "$LIST" | awk -F'\t' '{printf "  %2d. %s%s\n", NR, $2, ($3 != "" ? "  (" $3 ")" : "")}'
  echo "  (Want one from the Voice Library? Add it to My Voices on elevenlabs.io, then run this again.)"
  PICK="$(ask "Number to try, or q to quit: ")"
  case "$PICK" in
    ""|q|Q) echo "Stopped. Your previous settings are in $CFG.before-elevenlabs.bak if you want them back."; exit 0 ;;
    *[!0-9]*) echo "Type a number from the list."; continue ;;
  esac
  LINE="$(printf '%s\n' "$LIST" | sed -n "${PICK}p")"
  [ -n "$LINE" ] || { echo "Not on the list."; continue; }
  VID="$(printf '%s' "$LINE" | cut -f1)"; VNAME="$(printf '%s' "$LINE" | cut -f2)"
  set_el enabled true voice_id "$VID" voice_note "$VNAME"
  if [ -x .venv/bin/python ]; then
    echo "-- Playing $VNAME..."
    .venv/bin/python -m backtalk.mouth "Hello. This is what I'd sound like as your voice." || echo "   (Playback failed; logs/backtalk.log says why.)"
  else
    echo "-- (Install the voice first to hear samples: ./install.sh)"
  fi
  [ "$(ask "Keep $VNAME? [Y/n] ")" = n ] || break
done
echo
echo "Done: $VNAME speaks from the next launch (./run.sh)."
echo "If ElevenLabs ever fails (no credits, no internet), the built-in voice takes over and logs/backtalk.log says why."
echo "Back to the built-in voice any time: ./add-elevenlabs.sh --off"
