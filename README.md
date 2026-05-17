# ai_aug_coding

Boilerplate for AI-augmented coding projects. 
Branch from this repo to start a new project with all the defaults already in place.

## Principles

- Monorepo: backend, frontend, and any extra components in one repo — keep everything together
- Backend: Python
- Frontend: TypeScript

## Structure

```
├── CLAUDE.md                        # Project instructions for Claude (loaded every session)
├── .mcp.json                        # Team-shared MCP servers
├── .worktreeinclude                 # Gitignored files to copy into new worktrees
├── .gitignore
├── backend/                         # Python application
├── frontend/                        # TypeScript application
└── .claude/
    ├── settings.json                # Tool permissions, hooks, env vars
    ├── settings.local.json          # Personal overrides — gitignored
    ├── rules/
    │   ├── backend.md               # Python rules, loaded when editing backend/
    │   └── frontend.md              # TypeScript rules, loaded when editing frontend/
    ├── skills/
    │   └── example/SKILL.md         # Reusable prompt, invoked with /example
    ├── commands/
    │   └── fix-issue.md             # Single-file prompt, invoked with /fix-issue
    ├── agents/
    │   └── code-reviewer.md         # Subagent with its own context and tool access
    └── output-styles/
        └── concise.md               # Custom system-prompt style
```

## Local checks

```bash
make lint       # ruff + eslint + prettier
make typecheck  # mypy + vue-tsc
make test       # pytest + vitest
make check      # all of the above
```

The same commands run in CI on every PR.

## MCP servers

Pre-configured in `.mcp.json` (available to the whole team):

| Server | Purpose | Key |
|--------|---------|-----|
| [context7](https://github.com/upstash/context7) | Up-to-date library docs in context | `CONTEXT7_API_KEY` |

Recommended additions:

- [MCP Toolbox for Databases](https://github.com/googleapis/mcp-toolbox) — query and manage databases
- [Docker MCP Toolkit](https://docs.docker.com/ai/mcp-catalog-and-toolkit/toolkit/) — interact with containers and images

## Usage

1. Branch from this repo
2. Add `ANTHROPIC_API_KEY` secret — GitHub → Settings → Secrets and variables → Actions
3. Set `CONTEXT7_API_KEY` in your environment — required for the context7 MCP server
4. Update `CLAUDE.md` with project context
