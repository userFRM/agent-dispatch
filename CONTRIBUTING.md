# Contributing to agent-dispatch

Thank you for your interest in contributing.

## How to contribute

### Adding keywords

The most valuable contribution is improving the keyword-to-agent mapping in `skills/agent-dispatch/SKILL.md`. Good keywords are:

- **Specific** enough to avoid false matches
- **Natural** — words a developer would actually use
- **Lowercase** and hyphenated for multi-word terms

### Adding agent categories

If you work in a domain not covered by the index, open a PR adding the category with relevant keywords.

### Improving scripts

The fetch and generate scripts can always be improved. PRs welcome.

## Guidelines

1. Keep the SKILL.md body under 200 lines — the whole point is to stay lightweight
2. Test that the skill loads correctly in Claude Code before submitting
3. Use the v2 TOML format for index entries: `keyword = "agent-name:category"`
4. One keyword per line, grouped by category with comment headers
5a. The `:category` suffix must match a key in the category directory mapping (core, languages, infra, quality, data, devex, domains, business, meta, research)
5b. For custom/local agents not in VoltAgent, use `:local`
5. Use sentence case for all headings (not title case)
6. Don't duplicate agent files — reference submodules or upstream repos

## Reporting issues

Open an issue if:
- A keyword maps to the wrong agent
- Claude isn't picking up the skill when it should
- A script fails on your platform

## License

By contributing, you agree that your contributions will be licensed under MIT.
