# agent-dispatch

A lightweight, platform-agnostic skill that acts as an agent registry and router. Instead of doing specialized work inline (burning your main context window), your AI agent consults a compact keyword index and dispatches to the right subagent.

Works with **Claude Code**, **OpenClaw**, **Cursor**, **Codex**, and any platform that supports the SKILL.md format.

**The problem:** you have 50+ subagents installed but your agent doesn't "think" to use them mid-task. Agent descriptions in the system prompt scale poorly. Full orchestrator agents are overkill — you'd spawn an agent just to pick an agent.

**The solution:** a single skill file with a TOML index mapping keywords to agent names. Skills load on-demand (not at startup), cost near-zero tokens, and give your agent the routing table it needs.

## How it works

```
You're coding → agent hits a security-related task
                    ↓
         Skill auto-activates (keyword: "security")
                    ↓
         Index lookup: security = "security-auditor"
                    ↓
         Agent dispatches to security-auditor subagent
                    ↓
         Work done in separate context window
                    ↓
         Results returned to main conversation
```

### Skills vs agents vs MCP

| Mechanism | When loaded | Context impact | Best for |
|-----------|-------------|----------------|----------|
| **Skill** | On-demand during conversation | Into main context (~minimal) | Routing, instructions, capabilities |
| **Agent** | When dispatched | Own context window (zero main impact) | Delegated specialized work |
| **MCP** | At startup before model loads | Consumes context upfront | External tool integrations |

This skill bridges the gap: it's a **skill** (lightweight, on-demand) that routes to **agents** (isolated, specialized). The SKILL.md format is part of the [AgentSkills spec](https://github.com/openclaw/clawhub/blob/main/docs/skill-format.md), portable across platforms.

## Installation

### OpenClaw (via ClawHub)

```bash
clawhub install agent-dispatch
```

### Claude Code

```bash
git clone --recurse-submodules https://github.com/userFRM/agent-dispatch.git
cd agent-dispatch
./scripts/install.sh
```

This installs:
- The dispatch skill to `~/.claude/skills/agent-dispatch/`
- 10 starter agents from the VoltAgent submodule to `~/.claude/agents/`

No files are duplicated — the starter pack is a manifest (`starter-pack.txt`) pointing to files in `vendors/voltagent/`.

### Skill only (no agents)

```bash
./scripts/install.sh --skill-only
```

### Manual (any platform)

Copy `skills/agent-dispatch/SKILL.md` to your platform's skill directory:

| Platform | Skill path |
|----------|-----------|
| Claude Code | `~/.claude/skills/agent-dispatch/SKILL.md` |
| OpenClaw | `~/.openclaw/skills/agent-dispatch/SKILL.md` |
| Cursor | `.cursor/skills/agent-dispatch/SKILL.md` |

## Getting agents

Agents live in `~/.claude/agents/` as `.md` files. Three ways to get them there:

### Option 1: Starter pack (via submodule)

The install script reads `starter-pack.txt` and copies 10 essential agents from the VoltAgent submodule:

code-reviewer, security-auditor, architect-reviewer, debugger, performance-engineer, error-detective, qa-expert, refactoring-specialist, documentation-engineer, api-designer

Edit `starter-pack.txt` to add or remove agents from the starter set.

### Option 2: Fetch from GitHub by category

```bash
# List available categories
./scripts/fetch-agents.sh --list

# Fetch specific categories
./scripts/fetch-agents.sh --category quality
./scripts/fetch-agents.sh --category infra

# Fetch all 130 agents from VoltAgent
./scripts/fetch-agents.sh --all

# Fetch from 0xfurai instead
./scripts/fetch-agents.sh --source 0xfurai
```

Available categories:

| Category | Key | Agents | Examples |
|----------|-----|--------|----------|
| Core development | `core` | 10 | api-designer, frontend-developer |
| Language specialists | `languages` | 26 | typescript-pro, python-pro, rust-engineer |
| Infrastructure | `infra` | 16 | docker-expert, kubernetes-specialist |
| Quality and security | `quality` | 14 | code-reviewer, debugger, penetration-tester |
| Data and AI | `data` | 12 | data-scientist, llm-architect |
| Developer experience | `devex` | 13 | refactoring-specialist, documentation-engineer |
| Specialized domains | `domains` | 12 | fintech-engineer, game-developer |
| Business and product | `business` | 11 | product-manager, ux-researcher |
| Meta orchestration | `meta` | 10 | multi-agent-coordinator |
| Research and analysis | `research` | 6 | research-analyst, competitive-analyst |

### Option 3: Git submodules (pinned versions)

The full source repos are embedded as submodules under `vendors/`. Copy what you need:

```bash
git submodule update --init
cp vendors/voltagent/categories/04-quality-security/*.md ~/.claude/agents/
cp vendors/0xfurai/agents/python-expert.md ~/.claude/agents/
```

## Usage

### Automatic (recommended)

Once installed, Claude auto-consults the dispatch index when it encounters specialized tasks. No action needed.

### Manual

```
/agent-dispatch
```

### Regenerate index from your agents

```bash
./scripts/generate-index.sh
```

## Dispatch decision logic

The skill instructs Claude to **dispatch** when:
- The task is clearly specialized (security review, performance profiling)
- The agent can work independently with clear inputs/outputs
- The work would consume significant main context

And to **do it inline** when:
- The task is a quick one-liner
- Tight back-and-forth with the user is needed
- No matching agent is installed

## Uninstall

```bash
# Remove skill only (agents untouched)
./scripts/uninstall.sh

# Remove skill + starter pack agents
./scripts/uninstall.sh --agents

# Remove skill + ALL agents in directory (with confirmation)
./scripts/uninstall.sh --all
```

## Cross-platform usage

All scripts respect environment variables for platform-agnostic installs:

```bash
# Override agent directory (default: ~/.claude/agents)
AGENTS_DIR=~/.openclaw/agents ./scripts/fetch-agents.sh --all

# Override skill directory (default: ~/.claude/skills/agent-dispatch)
SKILL_DIR=~/.openclaw/skills/agent-dispatch ./scripts/install.sh

# Override SKILL.md path for index regeneration
SKILL_FILE=~/.openclaw/skills/agent-dispatch/SKILL.md ./scripts/generate-index.sh --install
```

## Known limitations

- Each keyword maps to exactly one agent (TOML requires unique keys). If you need one keyword to fan out to multiple agents, use a composite agent or pick the most relevant one.
- ZIP downloads from GitHub don't include submodules. Clone with `--recurse-submodules` or use the fetch script instead.

## Customization

Edit `~/.claude/skills/agent-dispatch/SKILL.md` to:
- **Add keywords** for your specific workflows
- **Remove agents** you don't have installed
- **Add categories** for your domain

The index format is simple TOML:

```toml
keyword = "agent-name"
```

## Works with

This skill is agent-source agnostic. It works with agents from:

- [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) (130 agents, MIT)
- [0xfurai/claude-code-subagents](https://github.com/0xfurai/claude-code-subagents) (100+ agents, MIT)
- [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code)
- Your own custom agents in `~/.claude/agents/`

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)

## Acknowledgments

- Agent definitions from [VoltAgent](https://github.com/VoltAgent) and [0xfurai](https://github.com/0xfurai), both MIT licensed
- Built on [Claude Code's skill system](https://code.claude.com/docs/en/skills)
