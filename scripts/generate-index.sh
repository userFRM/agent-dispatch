#!/usr/bin/env bash
#
# generate-index.sh
# Scans your agents directory and generates a compact TOML index
# for the agent-dispatch skill.
#
# Respects AGENTS_DIR and SKILL_FILE env vars for platform-agnostic use.
#
# Usage:
#   ./scripts/generate-index.sh              # Print to stdout
#   ./scripts/generate-index.sh --install    # Update SKILL.md in-place
#
# Environment:
#   AGENTS_DIR    Override agent directory (default: ~/.claude/agents)
#   SKILL_FILE    Override SKILL.md path (default: ~/.claude/skills/agent-dispatch/SKILL.md)
#

set -euo pipefail

AGENTS_DIR="${AGENTS_DIR:-${HOME}/.claude/agents}"
SKILL_FILE="${SKILL_FILE:-${HOME}/.claude/skills/agent-dispatch/SKILL.md}"

if [[ ! -d "$AGENTS_DIR" ]]; then
  echo "Error: No agents directory found at $AGENTS_DIR" >&2
  echo "Set AGENTS_DIR to your platform's agent path." >&2
  exit 1
fi

generate_index() {
  local count=0

  echo "# Auto-generated agent index"
  echo "# $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "#"
  echo "# Format: keyword = \"agent-name\""
  echo ""

  for agent_file in "$AGENTS_DIR"/*.md; do
    [[ -f "$agent_file" ]] || continue

    local filename
    filename=$(basename "$agent_file" .md)

    # Extract description from YAML frontmatter
    local description=""
    if head -1 "$agent_file" | grep -q '^---'; then
      description=$(sed -n '/^---$/,/^---$/{ /^description:/s/^description:[[:space:]]*//p; }' "$agent_file" | head -1)
    fi

    # Fallback: first line after frontmatter that looks like prose
    if [[ -z "$description" ]]; then
      description=$(awk '
        /^---$/ { front++; next }
        front >= 2 && /^[A-Za-z]/ { print; exit }
      ' "$agent_file" | head -c 80)
    fi

    # Clean up quotes from description
    description="${description#\"}"
    description="${description%\"}"

    printf '%-20s = "%s"  # %s\n' "$filename" "$filename" "${description:0:60}"
    count=$((count + 1))

  done

  echo ""
  echo "# Total: $count agents indexed"
}

if [[ "${1:-}" == "--install" ]]; then
  if [[ ! -f "$SKILL_FILE" ]]; then
    echo "Error: SKILL.md not found at $SKILL_FILE" >&2
    echo "Set SKILL_FILE or install the skill first: ./scripts/install.sh" >&2
    exit 1
  fi

  # Generate the new index
  tmpfile=$(mktemp)
  trap 'rm -f "$tmpfile"' EXIT
  generate_index > "$tmpfile"

  agent_count=$(grep -c '= "' "$tmpfile")

  # Replace the toml block in SKILL.md using awk (no python dependency)
  awk -v indexfile="$tmpfile" '
    /^```toml$/ { print; inside=1; while ((getline line < indexfile) > 0) print line; next }
    /^```$/ && inside { inside=0 }
    !inside { print }
  ' "$SKILL_FILE" > "${SKILL_FILE}.tmp" && mv "${SKILL_FILE}.tmp" "$SKILL_FILE"

  echo "Updated $SKILL_FILE with $agent_count agents from $AGENTS_DIR"
else
  generate_index
fi
