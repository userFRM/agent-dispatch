#!/usr/bin/env bash
#
# install.sh
# Installs the agent-dispatch skill and optionally the starter pack agents.
# Starter pack agents are pulled from the VoltAgent submodule — no copies in this repo.
#
# Respects SKILL_DIR and AGENTS_DIR env vars for platform-agnostic installs.
#
# Usage:
#   ./scripts/install.sh                  # Install skill + starter pack
#   ./scripts/install.sh --skill-only     # Install skill only
#   ./scripts/install.sh --project        # Install to current project
#
# Environment:
#   SKILL_DIR     Override skill install path (default: ~/.claude/skills/agent-dispatch)
#   AGENTS_DIR    Override agent install path (default: ~/.claude/agents)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SKILL_SOURCE="$REPO_DIR/skills/agent-dispatch"
VOLTAGENT_DIR="$REPO_DIR/vendors/voltagent"
MANIFEST="$REPO_DIR/starter-pack.txt"

# ── Resolve target paths ─────────────────────────────────────

if [[ "${1:-}" == "--project" ]]; then
  SKILL_TARGET="${SKILL_DIR:-.claude/skills/agent-dispatch}"
  AGENTS_TARGET="${AGENTS_DIR:-.claude/agents}"
else
  SKILL_TARGET="${SKILL_DIR:-${HOME}/.claude/skills/agent-dispatch}"
  AGENTS_TARGET="${AGENTS_DIR:-${HOME}/.claude/agents}"
fi

SKILL_ONLY=false
[[ "${1:-}" == "--skill-only" ]] && SKILL_ONLY=true

# ── Install skill ────────────────────────────────────────────

mkdir -p "$SKILL_TARGET"
cp -r "$SKILL_SOURCE"/* "$SKILL_TARGET/"
echo "Installed agent-dispatch skill to: $SKILL_TARGET"

# ── Install starter pack from submodule ──────────────────────

if [[ "$SKILL_ONLY" == true ]]; then
  echo ""
  echo "Skipping starter pack (--skill-only)."
  echo "Run ./scripts/fetch-agents.sh to get agents later."
  exit 0
fi

# Check if this is a git repo (ZIP downloads won't have .git)
if [[ ! -d "$REPO_DIR/.git" ]]; then
  echo ""
  echo "Warning: Not a git clone (no .git directory found)."
  echo "Starter pack requires git submodules. Either:"
  echo "  1. Clone with: git clone --recurse-submodules https://github.com/userFRM/agent-dispatch.git"
  echo "  2. Or fetch agents directly: ./scripts/fetch-agents.sh --category quality"
  exit 0
fi

# Make sure submodule is initialized
if [[ ! -f "$VOLTAGENT_DIR/README.md" ]]; then
  echo "Initializing VoltAgent submodule..."
  git -C "$REPO_DIR" submodule update --init vendors/voltagent
fi

if [[ ! -f "$MANIFEST" ]]; then
  echo "Warning: starter-pack.txt not found. Skipping agent install."
  exit 0
fi

mkdir -p "$AGENTS_TARGET"
count=0
while IFS= read -r line; do
  # Skip comments and empty lines
  [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

  src="$VOLTAGENT_DIR/$line"
  filename=$(basename "$line")
  target="$AGENTS_TARGET/$filename"

  if [[ ! -f "$src" ]]; then
    echo "  warn: $line not found in submodule, skipping"
    continue
  fi

  if [[ -f "$target" ]]; then
    echo "  skip: $filename (already exists)"
  else
    cp "$src" "$target"
    echo "  done: $filename"
    count=$((count + 1))
  fi
done < "$MANIFEST"

echo ""
echo "Installed $count starter pack agents to: $AGENTS_TARGET"
echo ""
echo "Next steps:"
echo "  - Fetch more agents:  ./scripts/fetch-agents.sh --list"
echo "  - Regenerate index:   ./scripts/generate-index.sh"
