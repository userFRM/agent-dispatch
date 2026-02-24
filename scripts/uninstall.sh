#!/usr/bin/env bash
#
# uninstall.sh
# Removes the agent-dispatch skill and optionally the starter pack agents.
#
# Usage:
#   ./scripts/uninstall.sh                # Remove skill only (safe)
#   ./scripts/uninstall.sh --agents       # Also remove starter pack agents
#   ./scripts/uninstall.sh --all          # Remove skill + ALL agents in directory
#
# Environment:
#   SKILL_DIR     Override skill path (default: ~/.claude/skills/agent-dispatch)
#   AGENTS_DIR    Override agent path (default: ~/.claude/agents)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
MANIFEST="$REPO_DIR/starter-pack.txt"

SKILL_TARGET="${SKILL_DIR:-${HOME}/.claude/skills/agent-dispatch}"
AGENTS_TARGET="${AGENTS_DIR:-${HOME}/.claude/agents}"

# ── Remove skill ─────────────────────────────────────────────

if [[ -d "$SKILL_TARGET" ]]; then
  rm -rf "$SKILL_TARGET"
  echo "Removed skill from: $SKILL_TARGET"
else
  echo "Skill not found at: $SKILL_TARGET (already removed?)"
fi

# ── Optionally remove agents ─────────────────────────────────

case "${1:-}" in
  --agents)
    if [[ -f "$MANIFEST" ]]; then
      count=0
      while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        filename=$(basename "$line")
        target="$AGENTS_TARGET/$filename"
        if [[ -f "$target" ]]; then
          rm "$target"
          echo "  removed: $filename"
          count=$((count + 1))
        fi
      done < "$MANIFEST"
      echo "Removed $count starter pack agents from: $AGENTS_TARGET"
    else
      echo "starter-pack.txt not found, cannot determine which agents to remove."
    fi
    ;;

  --all)
    echo ""
    echo "WARNING: This will remove ALL .md files in $AGENTS_TARGET"
    read -rp "Are you sure? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      count=$(find "$AGENTS_TARGET" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
      rm -f "$AGENTS_TARGET"/*.md
      echo "Removed $count agent files from: $AGENTS_TARGET"
    else
      echo "Aborted."
    fi
    ;;

  *)
    echo ""
    echo "Agents were left untouched in: $AGENTS_TARGET"
    echo "To also remove agents: ./scripts/uninstall.sh --agents"
    ;;
esac
