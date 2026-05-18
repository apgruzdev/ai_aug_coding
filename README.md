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
├── .env.example                     # Template for server-side env vars (copy to .env)
├── docker-compose.yml               # Production deployment: backend, frontend, Watchtower
├── backend/
│   ├── Dockerfile
│   └── ...                          # Python application
├── frontend/
│   ├── Dockerfile
│   └── ...                          # TypeScript application
└── .claude/
    ├── settings.json                # Tool permissions, hooks, env vars
    ├── settings.local.json          # Personal overrides — gitignored
    ├── rules/
    │   ├── backend.md               # Python rules, loaded when editing backend/
    │   └── frontend.md              # TypeScript rules, loaded when editing frontend/
    └── skills/
        └── <name>/SKILL.md          # Reusable prompt, invoked with /<name>
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
3. Set `CONTEXT7_API_KEY` for the context7 MCP server — add it to `.claude/settings.local.json` under `env`, or export it in your shell profile
4. Update `CLAUDE.md` with project context
5. For CD: on the server create a GitHub Personal Access Token (PAT) with `read:packages` scope and use it to authenticate with `ghcr.io` (see **CD** section below)

## CD (Continuous Deployment)

Images are built and pushed to `ghcr.io` on every push to `main`. Only the services with a `Dockerfile` present are built — projects with only a backend or only a frontend work automatically.

**On the server (first-time setup):**

```bash
# 1. Authenticate with ghcr.io (needed for private repos)
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin

# 2. Copy and fill in .env
cp .env.example .env
# edit .env: set GITHUB_REPOSITORY to owner/repo-name (must be lowercase)

# 3. Start services — choose a profile: backend | frontend | full
docker compose --profile full up -d
```

Watchtower polls `ghcr.io` every 5 minutes and automatically restarts containers when a new `:latest` image is pushed.
