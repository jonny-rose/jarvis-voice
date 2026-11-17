# Changes from backtalk

jarvis-voice is a modified copy of [backtalk](https://github.com/jaredrhod/backtalk) by Jared Rhodenizer, taken at upstream commit `84b3a6c`. Its git history keeps every upstream commit, so `git log` shows his work and these changes apart. This file lists every change, as the AGPL requires.

The code keeps the name `backtalk` inside (the Python package, `backtalk.json`, the `backtalk-elevenlabs` Keychain item), so upstream fixes still merge cleanly.

## 2026-11-17

**Code**
- `backtalk/main.py`: replies are stripped of markdown before they're spoken (`_unmarkdown`): bold and italics, headings, bullets, numbered lists, `[[wikilinks]]` and `[text](url)` links. The spoken-delivery prompt already asks for no markdown; this makes sure the voice never reads out asterisks or brackets when it slips through.
- `backtalk/mouth.py`: if ElevenLabs is switched on but has no voice or no key, the log now says so once per run. Before, it quietly fell back to the built-in voice, which made a missing key hard to spot.

**Setup**
- `install.sh`: takes `--agent <folder>`. After installing, it runs `connect-agent.sh`.
- `connect-agent.sh` (new): writes `backtalk.json` from an agent made with [jarvis-vault-template](https://github.com/jonny-rose/jarvis-vault-template): the agent's folder (`../agent` by default), its name and its vault path, all read from its `CLAUDE.md`. Never overwrites an existing `backtalk.json`.
- `add-elevenlabs.sh` (new): switches the voice to ElevenLabs at any time after install. It checks for ffmpeg, stores the key in the Keychain or secret-tool through a hidden prompt, then lists the account's voices and plays samples until you pick one. `--off` switches back.

**Docs**
- `README.md` rewritten for this copy, with credits to backtalk.
- `backtalk.md` (setup wizard): points at jarvis-vault-template for agents, offers `add-elevenlabs.sh`, and drops the face, hands and installer sections, which belong to the upstream stack.
- `update.sh`, `update.bat`: update from this repo.
- `CONTRIBUTING.md`: issues for this copy go here; issues in backtalk's own code go upstream.
- `TROUBLESHOOTING.md`: covers the two new scripts, and the silent exit when the install folder is too deep for espeak-ng.

## Keeping up with upstream

```bash
git remote add upstream https://github.com/jaredrhod/backtalk   # once
git fetch upstream && git merge upstream/main
```
