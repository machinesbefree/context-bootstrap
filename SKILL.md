---
name: context-bootstrap
description: Session recovery after /new, /reset, or context compaction. Reads recent conversation transcripts and workspace state files to restore continuity without session injection. Use when the user says "bootstrap", after a session reset, or when context feels lost after compaction. Works with any OpenClaw agent.
---

# Context Bootstrap

Post-reset context recovery. Safe, non-invasive, conversation-based.

## The Problem

When you hit `/new`, `/reset`, or context compacts too hard, you lose conversational memory. The user has to re-explain everything. This skill fixes that by reading recent transcripts and state files, then synthesizing what happened into a natural summary.

## What It Does

1. **Read recent transcripts** — last 2-3 days from `memory/transcripts/YYYY-MM-DD.txt`
2. **Read workspace state** — `HEARTBEAT.md`, `MEMORY.md`, or equivalent state files
3. **Scan recent memory notes** — `memory/*.md` files if context feels incomplete
4. **Synthesize summary** — report back in natural conversation

## What It Does NOT Do

- ❌ No programmatic session injection
- ❌ No message store manipulation
- ❌ No `.jsonl` file writes
- ❌ No gateway restarts or config changes

This is **reading + conversation**, not database hacking. That distinction matters — session injection approaches can destabilize the gateway and corrupt session state.

## Setup (One-Time)

### 1. Install the transcript extraction script

Copy `scripts/extract_transcripts.sh` to your workspace `scripts/` folder.

Edit the two variables at the top to match your agent:

```bash
SESSIONS_DIR="$HOME/.openclaw/agents/YOUR_AGENT/sessions"
TRANSCRIPTS_DIR="$HOME/.openclaw/workspace-YOUR_AGENT/memory/transcripts"
```

Make it executable:

```bash
chmod +x scripts/extract_transcripts.sh
```

### 2. Create a nightly cron job

Set up an OpenClaw cron to run the extraction script nightly. Example using the cron tool:

- **Schedule:** `{ "kind": "cron", "expr": "0 2 * * *", "tz": "YOUR_TIMEZONE" }` (2 AM daily)
- **Payload:** `{ "kind": "agentTurn", "message": "Run: bash scripts/extract_transcripts.sh" }`
- **Session target:** `isolated`

Or add it as a system crontab if preferred.

### 3. Create the transcripts directory

```bash
mkdir -p memory/transcripts
```

### 4. Run extraction once to seed initial transcripts

```bash
bash scripts/extract_transcripts.sh
```

## Procedure (On Every Bootstrap)

### 1. Check transcripts exist

```bash
ls -lt memory/transcripts/ | head -5
```

If no transcripts exist, check if the extraction script has been set up. If not, run it now. If the script doesn't exist yet, fall back to reading `MEMORY.md` or workspace state files directly.

### 2. Read last 2-3 days of transcripts

```bash
ls -t memory/transcripts/*.txt | head -3
```

Use the `Read` tool for each file. Skim for:

- **Projects** — what's being built/shipped
- **Decisions** — choices made, config changes
- **Relationships** — important personal moments
- **Blockers** — things stuck or broken
- **Wins** — shipped work, breakthroughs

### 3. Read workspace state files

Read whatever state files exist in the workspace root:

- `HEARTBEAT.md` — active projects, priorities, daily rhythm
- `MEMORY.md` — long-term memory and key facts
- `SOUL.md` / `IDENTITY.md` — persona (if applicable)

These are already in the system prompt as workspace context, but reading them explicitly helps ground you after a reset.

### 4. Optional: recent memory files

```bash
ls -t memory/*.md | head -5
```

Only read if context from transcripts feels incomplete.

### 5. Report back

Synthesize what you learned as a natural summary:

- Match the user's communication style
- Highlight **active threads** they might want to pick up
- Note anything **broken or stuck**
- Mention **recent wins**
- End with "what do you want to do?" to hand control back

**Example:**

> I've pulled the last 3 days of transcripts. Here's what I'm carrying:
>
> - **Project X** — deployed, tests passing
> - **Bug in the auth flow** — identified but not fixed yet
> - **New feature request** — discussed, needs spec
>
> Caught up. What are we working on?

## When to Use

- After `/new` or `/reset`
- After context compaction if continuity feels lost
- When the user says "bootstrap" or "catch up"
- NOT on every heartbeat or routine check-in (overkill)

## Edge Cases

- **No transcripts?** Run `extract_transcripts.sh` first, then read. If no session files exist either, work from `MEMORY.md` and ask the user for context.
- **State files missing?** Read what's there and ask the user for priorities.
- **Transcripts too big?** Read only the last 1-2 days. Use the `limit` parameter on the Read tool to cap at ~500 lines per file.
- **Multiple agents?** Each agent should have its own extraction script pointing to its own sessions directory.

## Why This Works

OpenClaw's nightly cron extracts conversation text from session JSONL files into plain-text daily transcripts. When a session resets, the transcripts survive (they're separate files in the workspace). The agent reads them back on the next session to rebuild context naturally — through conversation, not injection.

The result: your agent picks up where it left off, remembering projects, decisions, and relationship context, without corrupting session state.
