#!/usr/bin/env sh
# Usage: ./install.sh [claude-dir]     (FORCE=1 to overwrite an existing install)
set -eu

CLAUDE_DIR="${1:-$HOME/.claude}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
SKILL_SRC="$ROOT/skills/ai-code-checker"
AGENT_SRC="$ROOT/agents"
SKILL_TARGET="$CLAUDE_DIR/skills/ai-code-checker"
AGENT_DIR="$CLAUDE_DIR/agents"

[ -f "$SKILL_SRC/SKILL.md" ] || { echo "SKILL.md not found in $SKILL_SRC" >&2; exit 1; }
ls "$AGENT_SRC"/*.md >/dev/null 2>&1 || { echo "No agent files found in $AGENT_SRC" >&2; exit 1; }

existing=""
[ -e "$SKILL_TARGET" ] && existing="$existing $SKILL_TARGET"
for f in "$AGENT_SRC"/*.md; do
    [ -e "$AGENT_DIR/$(basename "$f")" ] && existing="$existing $AGENT_DIR/$(basename "$f")"
done
if [ -n "$existing" ] && [ "${FORCE:-0}" != "1" ]; then
    echo "Already installed:" >&2
    for e in $existing; do echo "  $e" >&2; done
    echo "Re-run with FORCE=1 to overwrite." >&2
    exit 1
fi

mkdir -p "$CLAUDE_DIR/skills" "$AGENT_DIR"
rm -rf "$SKILL_TARGET"
cp -R "$SKILL_SRC" "$SKILL_TARGET"
cp "$AGENT_SRC"/*.md "$AGENT_DIR/"

echo "Installed skill and agents under $CLAUDE_DIR"
echo "Restart Claude Code, then run /ai-code-checker, or ask: Use the ai-code-fixer agent to fix the report."
