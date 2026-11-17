## How to contribute

**Open an issue here** for anything about jarvis-voice: installing it, connecting it to a vault-template agent, `add-elevenlabs.sh`, or the changes listed in [CHANGES.md](CHANGES.md).

**A bug in the voice loop itself** (hearing, speaking, interrupts, permissions, the voice commands) most likely lives in [backtalk](https://github.com/jaredrhod/backtalk), which this is a copy of. If you can reproduce it there too, report it upstream: a fix there reaches everyone, and it arrives here with the next merge.

A good report has:
- **what you saw** and **what you expected instead**
- **how to reproduce it**, even roughly
- **your setup**: operating system, and the audio hardware if it's sound-related
- **the evidence**: the relevant lines of `logs/backtalk.log`, or the error message
