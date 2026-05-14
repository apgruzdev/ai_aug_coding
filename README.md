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

## Usage

1. Branch from this repo
2. Add `ANTHROPIC_API_KEY` secret — GitHub → Settings → Secrets and variables → Actions
3. Update `CLAUDE.md` with project context
4. Start coding following [`docs/development-process.md`](docs/development-process.md)
