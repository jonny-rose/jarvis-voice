# jarvis-voice

**Talk to your Claude Code agent out loud.** Hold a key, say the thing, let go: your words are transcribed on your machine, handed to your agent, and the answer comes back through your speakers about a second later. It's the same agent you type to, with the same name, personality and memory. It just talks now.

This is the optional voice module for [jarvis-vault-template](https://github.com/jonny-rose/jarvis-vault-template). It's a modified copy of **[backtalk](https://github.com/jaredrhod/backtalk) by Jared Rhodenizer**, which does all the hard work here; see [Credits](#credits) and [CHANGES.md](CHANGES.md).

**Runs on:** Claude Code with a Claude subscription (the $20 Pro plan is enough), macOS or Linux. Windows works through the setup wizard; see [Windows](#windows).

---

## Two voices

- **Built-in (the default): free, local, offline.** Speech recognition (Whisper) and the voice (Kokoro) both run on your computer. No accounts, no API keys, no per-word costs. It sounds good, but a little computer-generated. Jarvis gets `bm_lewis`, a British male voice; around 60 others ship free.
- **ElevenLabs (add it any time later): the natural one.** A human-sounding voice on your own ElevenLabs account. Run `./add-elevenlabs.sh` whenever you want it. The built-in voice stays installed as the automatic fallback, so if ElevenLabs ever fails (out of credits, no internet), your agent switches back to the built-in voice instead of going silent.

## Install

Put it next to the agent folder the vault template made:

```bash
cd ~/jarvis && git clone https://github.com/jonny-rose/jarvis-voice voice && cd voice && ./install.sh
```

The installer sets up a Python environment, the local models (about 1 GB, downloaded once) and the one system library they need (`espeak-ng`). Then it **connects itself to your agent**: it finds `../agent`, reads your agent's name and vault path from its `CLAUDE.md`, and writes `backtalk.json` for you.

Agent somewhere else? `./install.sh --agent ~/path/to/agent`, or later: `./connect-agent.sh ~/path/to/agent`.

Then:

```bash
./run.sh
```

Hold the **Home** key, talk, let go. Say "goodbye <your agent's name>" to hang up.

**On macOS**, the first run asks for **Microphone** permission. The talk key also needs **Input Monitoring** for your terminal app: System Settings → Privacy & Security → Input Monitoring.

**Prefer a guided setup?** Open this folder in Claude Code and say *"read backtalk.md and set me up"*. It walks through the key, the voice, the microphone mode and permissions with you, then tests the whole loop.

No agent yet? Build one first with [jarvis-vault-template](https://github.com/jonny-rose/jarvis-vault-template). Any Claude Code agent folder with a `CLAUDE.md` works too.

## Add ElevenLabs later

```bash
./add-elevenlabs.sh
```

It walks you through it:
1. Checks for `ffmpeg` (the voice is polished through it) and offers to install it.
2. Asks for your ElevenLabs API key and stores it in the **macOS Keychain** (or Linux `secret-tool`). You paste it at a hidden prompt: it never goes in a file, and the script never shows it.
3. Lists the voices on your account, plays each one you pick through your own speakers, and keeps the one you like.

Costs: ElevenLabs' free tier is enough to try voices; everyday talking needs a paid plan (Starter). Check current prices at elevenlabs.io. Want a voice from their Voice Library? Add it to **My Voices** on the website first, then run the script.

Changed your mind? `./add-elevenlabs.sh --off` goes back to the built-in voice and keeps the key stored.

## What it does

- **Push to talk, or hands-free.** By default the microphone only records while you hold the key, so nothing is recorded in the background. Say "go hands free" for always-on listening, and "push to talk mode" to go back.
- **Interrupt it.** Press the key while it's talking: it stops and listens.
- **Type when you want.** Typing in the terminal is the same conversation, and the reply is still spoken.
- **It asks before it acts.** When your agent wants to change something, it asks out loud in plain words and waits for a spoken "yes". "Details" reads you the exact command. Prefer auto-approve? Say "stop asking for permission".
- **Voice commands:** "clear the session", "compact the session", "switch to the deep model" / "back to the fast model", "set effort to low" (or medium, high, max), "usage report".
- **Speaks plain sentences.** Markdown (bold, bullets, headings, `[[links]]`) is stripped before speaking, so the voice never reads out asterisks or brackets.
- **Pick up where you left off.** Set `"resume_last_session": true` in `backtalk.json` and every launch continues the previous conversation.
- **Music ducks while it speaks** (Spotify on macOS).

## Usage and cost

Every spoken turn is a normal Claude Code turn on your plan. The voice uses the fast model on purpose: it's most of what makes replies arrive in about a second. The built-in voice costs nothing; ElevenLabs bills on your own account.

## Settings

Everything lives in `backtalk.json`, which is yours: it isn't tracked by git, so updates never touch it. You don't need to edit it by hand; ask your agent to change a setting. The full list of options, each with an explanation, is in `backtalk/config.py`.

## Updating

`./update.sh` shows what's new, then updates. It never touches `backtalk.json`.

## Windows

`install.sh`, `run.sh`, `connect-agent.sh` and `add-elevenlabs.sh` are Mac and Linux scripts. On Windows, open this folder in Claude Code and say *"read backtalk.md and set me up"*: the wizard installs everything natively and launches with `uv run python -m backtalk.main`. On Windows the ElevenLabs key goes in the `ELEVENLABS_API_KEY` environment variable. Known quirks are in [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Something wrong?

Ask your agent to fix it: [TROUBLESHOOTING.md](TROUBLESHOOTING.md) is written for it to read, and `logs/backtalk.log` records every step.

---

## Credits

**jarvis-voice is a modified copy of [backtalk](https://github.com/jaredrhod/backtalk) by Jared Rhodenizer.** The voice loop, the interrupt handling, the spoken permission checks, the voice commands and nearly everything else here are his work. If you want the original, or the rest of his stack (a face, hands, a one-command installer), go to [github.com/jaredrhod](https://github.com/jaredrhod).

What this copy changes is listed in [CHANGES.md](CHANGES.md).

Speech recognition by [faster-whisper](https://github.com/SYSTRAN/faster-whisper) (MIT) running [OpenAI Whisper](https://github.com/openai/whisper) models (MIT). Voice by [Kokoro](https://github.com/hexgrad/kokoro) (Apache 2.0) with [espeak-ng](https://github.com/espeak-ng/espeak-ng) (GPL-3.0, used as a system tool). Built on the [Claude Agent SDK](https://docs.claude.com/en/api/agent-sdk/overview).

## License

Copyright (c) 2026 Jared Rhodenizer (backtalk). Modifications copyright (c) 2026 Jonny Rose.

Licensed under the GNU Affero General Public License, version 3 or later (AGPL-3.0-or-later), the same licence as backtalk. Use it commercially, change it, run it for others. If you share a modified version or run it as a service for other people, your version must use this same licence, with its source available. Full terms are in [LICENSE](LICENSE) and at https://www.gnu.org/licenses/agpl-3.0.html
