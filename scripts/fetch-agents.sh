#!/usr/bin/env bash
#
# fetch-agents.sh
# Downloads agent .md files from GitHub repos by category.
#
# Respects AGENTS_DIR env var for platform-agnostic installs.
# Defaults: ~/.claude/agents (Claude Code), override for other platforms.
#
# Usage:
#   ./scripts/fetch-agents.sh                    # Interactive category picker
#   ./scripts/fetch-agents.sh --all              # Download all 130 agents
#   ./scripts/fetch-agents.sh --category quality # Download one category
#   ./scripts/fetch-agents.sh --list             # List available categories
#   ./scripts/fetch-agents.sh --source 0xfurai   # Use alternate source
#
# Environment:
#   AGENTS_DIR    Override agent install path (default: ~/.claude/agents)
#

set -euo pipefail

AGENTS_DIR="${AGENTS_DIR:-${HOME}/.claude/agents}"
VOLTAGENT_BASE="https://raw.githubusercontent.com/VoltAgent/awesome-claude-code-subagents/main/categories"

# ── VoltAgent category mapping ────────────────────────────────

declare -A CATEGORIES
CATEGORIES=(
  [core]="01-core-development"
  [languages]="02-language-specialists"
  [infra]="03-infrastructure"
  [quality]="04-quality-security"
  [data]="05-data-ai"
  [devex]="06-developer-experience"
  [domains]="07-specialized-domains"
  [business]="08-business-product"
  [meta]="09-meta-orchestration"
  [research]="10-research-analysis"
)

declare -A CATEGORY_AGENTS
CATEGORY_AGENTS=(
  [core]="api-designer backend-developer electron-pro frontend-developer fullstack-developer graphql-architect microservices-architect mobile-developer ui-designer websocket-engineer"
  [languages]="typescript-pro sql-pro swift-expert vue-expert angular-architect cpp-pro csharp-developer django-developer dotnet-core-expert dotnet-framework-4.8-expert elixir-expert flutter-expert golang-pro java-architect javascript-pro powershell-5.1-expert powershell-7-expert kotlin-specialist laravel-specialist nextjs-developer php-pro python-pro rails-expert react-specialist rust-engineer spring-boot-engineer"
  [infra]="azure-infra-engineer cloud-architect database-administrator docker-expert deployment-engineer devops-engineer devops-incident-responder incident-responder kubernetes-specialist network-engineer platform-engineer security-engineer sre-engineer terraform-engineer terragrunt-expert windows-infra-admin"
  [quality]="accessibility-tester ad-security-reviewer architect-reviewer chaos-engineer code-reviewer compliance-auditor debugger error-detective penetration-tester performance-engineer powershell-security-hardening qa-expert security-auditor test-automator"
  [data]="ai-engineer data-analyst data-engineer data-scientist database-optimizer llm-architect machine-learning-engineer ml-engineer mlops-engineer nlp-engineer postgres-pro prompt-engineer"
  [devex]="build-engineer cli-developer dependency-manager documentation-engineer dx-optimizer git-workflow-manager legacy-modernizer mcp-developer powershell-ui-architect powershell-module-architect refactoring-specialist slack-expert tooling-engineer"
  [domains]="api-documenter blockchain-developer embedded-systems fintech-engineer game-developer iot-engineer m365-admin mobile-app-developer payment-integration quant-analyst risk-manager seo-specialist"
  [business]="business-analyst content-marketer customer-success-manager legal-advisor product-manager project-manager sales-engineer scrum-master technical-writer ux-researcher wordpress-master"
  [meta]="agent-installer agent-organizer context-manager error-coordinator it-ops-orchestrator knowledge-synthesizer multi-agent-coordinator performance-monitor task-distributor workflow-orchestrator"
  [research]="research-analyst search-specialist trend-analyst competitive-analyst market-researcher data-researcher"
)

declare -A CATEGORY_DESCRIPTIONS
CATEGORY_DESCRIPTIONS=(
  [core]="Core development (API, backend, frontend, fullstack, mobile)"
  [languages]="Language specialists (TypeScript, Python, Rust, Go, Java, etc.)"
  [infra]="Infrastructure (Docker, K8s, Terraform, cloud, DevOps, SRE)"
  [quality]="Quality and security (code review, debugging, testing, security)"
  [data]="Data and AI (ML, data science, LLM, NLP, Postgres)"
  [devex]="Developer experience (refactoring, docs, CLI, build, git)"
  [domains]="Specialized domains (blockchain, fintech, gamedev, IoT)"
  [business]="Business and product (PM, UX, scrum, technical writing)"
  [meta]="Meta orchestration (agent coordination, workflows)"
  [research]="Research and analysis (market research, trends, competitive)"
)

CATEGORY_ORDER=(core languages infra quality data devex domains business meta research)

# ── Helper functions ──────────────────────────────────────────

print_header() {
  echo ""
  echo "agent-dispatch: fetch agents"
  echo "──────────────────────────────────────"
  echo "Target: $AGENTS_DIR"
}

list_categories() {
  print_header
  echo ""
  for key in "${CATEGORY_ORDER[@]}"; do
    local count
    count=$(echo "${CATEGORY_AGENTS[$key]}" | wc -w | tr -d ' ')
    printf "  %-12s %s (%s agents)\n" "$key" "${CATEGORY_DESCRIPTIONS[$key]}" "$count"
  done
  echo ""
  echo "Total: 130 agents across 10 categories"
  echo ""
  echo "Usage:"
  echo "  ./scripts/fetch-agents.sh --category quality"
  echo "  ./scripts/fetch-agents.sh --all"
  echo ""
  echo "Override target: AGENTS_DIR=~/.openclaw/agents ./scripts/fetch-agents.sh --all"
}

download_agent() {
  local category_key="$1"
  local agent_name="$2"
  local category_dir="${CATEGORIES[$category_key]}"
  local url="${VOLTAGENT_BASE}/${category_dir}/${agent_name}.md"
  local target="${AGENTS_DIR}/${agent_name}.md"

  if [[ -f "$target" ]]; then
    echo "  skip: ${agent_name}.md (already exists)"
    return 0
  fi

  local http_code
  http_code=$(curl -s -w '%{http_code}' -o "$target" "$url")

  if [[ "$http_code" == "200" ]]; then
    echo "  done: ${agent_name}.md"
    return 0
  else
    rm -f "$target"
    echo "  fail: ${agent_name}.md (HTTP $http_code)"
    return 1
  fi
}

download_category() {
  local category_key="$1"
  local agents="${CATEGORY_AGENTS[$category_key]}"
  local success=0
  local failed=0
  local skipped=0

  echo ""
  echo "Fetching: ${CATEGORY_DESCRIPTIONS[$category_key]}"
  echo ""

  for agent in $agents; do
    if [[ -f "${AGENTS_DIR}/${agent}.md" ]]; then
      echo "  skip: ${agent}.md (already exists)"
      skipped=$((skipped + 1))
    elif download_agent "$category_key" "$agent"; then
      success=$((success + 1))
    else
      failed=$((failed + 1))
    fi
  done

  echo ""
  echo "  Results: $success downloaded, $skipped skipped, $failed failed"
}

download_0xfurai() {
  echo ""
  echo "Fetching from 0xfurai/claude-code-subagents..."
  echo ""

  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT

  git clone --depth 1 --quiet https://github.com/0xfurai/claude-code-subagents.git "$tmpdir"

  local count=0
  for agent_file in "$tmpdir/agents"/*.md; do
    [[ -f "$agent_file" ]] || continue
    local filename
    filename=$(basename "$agent_file")
    local target="${AGENTS_DIR}/${filename}"

    if [[ -f "$target" ]]; then
      echo "  skip: $filename (already exists)"
    else
      cp "$agent_file" "$target"
      echo "  done: $filename"
      count=$((count + 1))
    fi
  done

  echo ""
  echo "  Installed $count agents from 0xfurai"
}

# ── Main ──────────────────────────────────────────────────────

mkdir -p "$AGENTS_DIR"

case "${1:-}" in
  --list|-l)
    list_categories
    ;;

  --all|-a)
    print_header
    for key in "${CATEGORY_ORDER[@]}"; do
      download_category "$key"
    done
    echo ""
    echo "All categories fetched. Agents installed to: $AGENTS_DIR"
    ;;

  --category|-c)
    if [[ -z "${2:-}" ]]; then
      echo "Error: Specify a category. Use --list to see available categories." >&2
      exit 1
    fi
    if [[ -z "${CATEGORIES[${2}]+x}" ]]; then
      echo "Error: Unknown category '${2}'. Use --list to see available categories." >&2
      exit 1
    fi
    print_header
    download_category "$2"
    echo ""
    echo "Agents installed to: $AGENTS_DIR"
    ;;

  --single|-s)
    if [[ -z "${2:-}" ]]; then
      echo "Error: Specify agent-name:category (e.g. debugger:quality)" >&2
      exit 1
    fi
    IFS=':' read -r agent_name category_key <<< "$2"
    if [[ -z "$agent_name" || -z "$category_key" ]]; then
      echo "Error: Format must be agent-name:category (e.g. debugger:quality)" >&2
      exit 1
    fi
    if [[ -z "${CATEGORIES[$category_key]+x}" ]]; then
      echo "Error: Unknown category '$category_key'. Use --list to see available categories." >&2
      exit 1
    fi
    print_header
    echo ""
    download_agent "$category_key" "$agent_name"
    echo ""
    echo "Agent installed to: $AGENTS_DIR"
    ;;

  --source)
    if [[ "${2:-}" == "0xfurai" ]]; then
      print_header
      download_0xfurai
      echo ""
      echo "Agents installed to: $AGENTS_DIR"
    else
      echo "Error: Unknown source '${2:-}'. Available: 0xfurai" >&2
      exit 1
    fi
    ;;

  --help|-h)
    print_header
    echo ""
    echo "Usage:"
    echo "  ./scripts/fetch-agents.sh --list              List categories"
    echo "  ./scripts/fetch-agents.sh --all               Download all 130 agents"
    echo "  ./scripts/fetch-agents.sh --category <name>   Download one category"
    echo "  ./scripts/fetch-agents.sh --single <n:cat>    Download one agent (e.g. debugger:quality)"
    echo "  ./scripts/fetch-agents.sh --source 0xfurai    Fetch from alternate repo"
    echo ""
    echo "Agents are installed to: $AGENTS_DIR"
    echo "Override with: AGENTS_DIR=/your/path ./scripts/fetch-agents.sh"
    ;;

  *)
    # Interactive mode
    print_header
    echo ""
    echo "Select what to install:"
    echo ""
    echo "  1) Pick categories from VoltAgent (130 agents)"
    echo "  2) All VoltAgent agents"
    echo "  3) All 0xfurai agents"
    echo ""
    read -rp "Choice [1-3]: " choice

    case "$choice" in
      1)
        list_categories
        echo ""
        read -rp "Categories (space-separated, e.g. 'quality devex infra'): " cats
        for cat in $cats; do
          if [[ -n "${CATEGORIES[$cat]+x}" ]]; then
            download_category "$cat"
          else
            echo "Skipping unknown category: $cat"
          fi
        done
        ;;
      2)
        for key in "${CATEGORY_ORDER[@]}"; do
          download_category "$key"
        done
        ;;
      3) download_0xfurai ;;
      *) echo "Invalid choice." >&2; exit 1 ;;
    esac

    echo ""
    echo "Agents installed to: $AGENTS_DIR"
    echo "Run ./scripts/generate-index.sh to update your dispatch index."
    ;;
esac
