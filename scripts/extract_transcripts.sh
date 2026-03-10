#!/bin/bash
# =============================================================================
# extract_transcripts.sh — Extract session conversations into daily transcripts
# =============================================================================
# Usage: bash extract_transcripts.sh
#
# Edit these two paths to match your agent setup:
SESSIONS_DIR="$HOME/.openclaw/agents/main/sessions"
TRANSCRIPTS_DIR="$HOME/.openclaw/workspace/memory/transcripts"
#
# Auto-detection: if OPENCLAW_AGENT is set, use it
if [[ -n "$OPENCLAW_AGENT" ]]; then
  SESSIONS_DIR="$HOME/.openclaw/agents/$OPENCLAW_AGENT/sessions"
  TRANSCRIPTS_DIR="$HOME/.openclaw/workspace-$OPENCLAW_AGENT/memory/transcripts"
fi
# =============================================================================

set -euo pipefail
mkdir -p "$TRANSCRIPTS_DIR"

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not installed. Install with: apt install jq / brew install jq"
  exit 1
fi

shopt -s nullglob
for f in "$SESSIONS_DIR"/*.jsonl "$SESSIONS_DIR"/*.reset.* "$SESSIONS_DIR"/*.deleted.*; do
  # Get all unique dates in this session
  dates=$(jq -r 'select(.message.role == "user" or .message.role == "assistant") | .timestamp' "$f" 2>/dev/null | \
    while read ts; do
      echo "$ts" | cut -dT -f1
    done | sort -u)

  for date in $dates; do
    [[ -z "$date" || "$date" == "null" ]] && continue
    outfile="$TRANSCRIPTS_DIR/${date}.txt"

    # Extract messages for this date
    jq -r "select(.timestamp | startswith(\"$date\")) | select(.message.role == \"user\" or .message.role == \"assistant\") | select(.message.content != null) |
      \"\\(.timestamp | split(\"T\")[1] | split(\".\")[0]) [\\(.message.role)]\" + \"\\n\" +
      (.message.content[] | select(.type == \"text\") | .text) + \"\\n---\"" "$f" 2>/dev/null >> "$outfile.tmp"
  done
done

# Merge, sort, deduplicate
for tmp in "$TRANSCRIPTS_DIR"/*.tmp; do
  [[ ! -f "$tmp" ]] && continue
  base="${tmp%.tmp}"
  if [[ -f "$base" ]]; then
    cat "$base" "$tmp" | sort -u > "${base}.merged"
    mv "${base}.merged" "$base"
    rm "$tmp"
  else
    sort -u "$tmp" > "$base"
    rm "$tmp"
  fi
done

echo "=== Transcript files ==="
ls -lh "$TRANSCRIPTS_DIR"/*.txt 2>/dev/null | awk '{print $5, $NF}'
