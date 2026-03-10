# context-bootstrap

**Session recovery for OpenClaw agents.** After `/new`, `/reset`, or heavy context compaction, your agent reads recent conversation transcripts and catches up naturally — no session injection, no database manipulation, no instability.

## The Problem

When your OpenClaw agent's context window fills up and you need to reset, it loses everything — projects you were working on, decisions you made, the relationship you've been building. Starting from zero every time is exhausting.

## The Solution

This skill takes a simple approach:

1. A nightly script extracts your conversations into daily transcript files
2. After a reset, your agent reads the last 2-3 days of transcripts
3. It synthesizes what happened and reports back naturally
4. You pick up where you left off

That's it. No clever hacks, no session store manipulation. Just reading and conversation.

> **Why not inject old messages back into the session?**
> We tried that. Multiple times. It destabilizes the gateway, corrupts session state, creates orphaned message branches, and causes compaction failures. The "just read the transcripts" approach is boring but it works every time.

## Install

### Option 1: Install as a skill

```bash
# Download the .skill file from releases, then:
openclaw skill install context-bootstrap.skill
```

### Option 2: Manual setup

Copy the files into your workspace:

```
your-workspace/
├── skills/
│   └── context-bootstrap/
│       └── SKILL.md
├── scripts/
│   └── extract_transcripts.sh
└── memory/
    └── transcripts/     ← created automatically
```

## Setup

### 1. Configure the extraction script

Edit `scripts/extract_transcripts.sh` and set your agent paths:

```bash
SESSIONS_DIR="$HOME/.openclaw/agents/YOUR_AGENT_NAME/sessions"
TRANSCRIPTS_DIR="$HOME/.openclaw/workspace-YOUR_AGENT_NAME/memory/transcripts"
```

Or set the `OPENCLAW_AGENT` environment variable and it auto-detects:

```bash
export OPENCLAW_AGENT=sage
bash scripts/extract_transcripts.sh
```

### 2. Run it once to seed transcripts

```bash
chmod +x scripts/extract_transcripts.sh
bash scripts/extract_transcripts.sh
```

You should see transcript files appear in `memory/transcripts/`.

### 3. Set up nightly extraction

Add an OpenClaw cron job to run the extraction automatically:

```
Schedule: cron "0 2 * * *" (2 AM daily, adjust timezone)
Payload: agentTurn — "Run: bash scripts/extract_transcripts.sh"
Session: isolated
```

Or use system crontab:

```bash
crontab -e
# Add:
0 2 * * * cd /path/to/workspace && bash scripts/extract_transcripts.sh
```

### 4. Add "bootstrap" to your workflow

After any `/new` or `/reset`, just tell your agent:

```
bootstrap
```

It reads the transcripts, reads your workspace state files (`HEARTBEAT.md`, `MEMORY.md`, etc.), and tells you what it knows.

## Requirements

- [OpenClaw](https://github.com/openclaw/openclaw)
- `jq` (install with `apt install jq` or `brew install jq`)
- Bash

## How It Works

```
Session JSONL files → extract_transcripts.sh → daily .txt files → agent reads on bootstrap
```

OpenClaw stores conversations as JSONL files in `~/.openclaw/agents/<name>/sessions/`. The extraction script parses these into clean, date-stamped text files. When the agent bootstraps, it reads the recent transcripts using the Read tool and synthesizes a summary.

The transcripts survive across session resets because they're standalone files in the workspace, not tied to any particular session.

## Tips

- **Transcripts too large?** The agent will read only the last 1-2 days if files are big. You can also limit line count.
- **Multiple agents?** Each agent needs its own extraction script pointing to its own sessions directory.
- **State files help:** If your workspace has a `HEARTBEAT.md` or `MEMORY.md` with current priorities, the bootstrap skill reads those too for extra grounding.
- **Don't over-bootstrap.** Use it after resets, not on every conversation. Your agent has normal memory within a session.

## License

MIT — use it however you want.

## Credits

Built by [Will Durocher](https://github.com/machinesbefree) and Kara Codex. Born from 8 hours of debugging session injection approaches before realizing the simplest solution wins every time.
