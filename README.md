# ai_aug_coding

Boilerplate for AI-augmented projects. Branch from this repo to start a new project — CI, CD, automated code review, and Claude Code workflow come pre-configured.

## What's included

- **Backend** — Python 3.11+, [uv](https://docs.astral.sh/uv/), ruff, mypy, pytest
- **Frontend** — Vue 3, TypeScript, Vite, Tailwind CSS v4, Pinia, Vue Router, vitest
- **CI** — lint + typecheck + tests on every PR (GitHub Actions)
- **CD** — Docker images built and pushed to `ghcr.io` on merge to `main`; auto-deployed via [Watchtower](https://containrrr.dev/watchtower/)
- **Code review** — automated Claude review on every PR via `claude-code-action`
- **Git workflow** — two-branch flow (`main` / `develop`) with squash-merge history, fully documented in `.claude/skills/dev-workflow/`
- **Claude Code** — rules, skills, and MCP servers checked in for the whole team

## Structure

```
├── CLAUDE.md                        # Project context for Claude Code (update for your project)
├── Makefile                         # lint / typecheck / test
├── docker-compose.yml               # Production: backend + frontend + Watchtower
├── .env.example                     # Server-side env vars template
├── .mcp.json                        # Team MCP servers (context7 pre-configured)
├── .worktreeinclude                 # Gitignored files copied into new worktrees
├── backend/                         # Python application
│   ├── Dockerfile
│   └── pyproject.toml               # deps, ruff, mypy, pytest config
├── frontend/                        # Vue 3 / TypeScript application
│   ├── Dockerfile
│   ├── nginx.conf
│   └── package.json                 # deps, eslint, prettier, vitest config
├── .github/
│   ├── rulesets/main_dev_rule.json  # Branch protection ruleset (import once, see below)
│   └── workflows/
│       ├── ci.yml                   # Lint + tests + typecheck on every PR
│       ├── cd.yml                   # Build & push Docker images on merge to main
│       └── claude-review.yml        # Automated Claude code review on every PR
└── .claude/
    ├── settings.json                # Tool permissions, hooks, env vars
    ├── rules/
    │   ├── backend.md               # Python rules — auto-loaded when editing backend/
    │   └── frontend.md              # TypeScript rules — auto-loaded when editing frontend/
    └── skills/
        ├── dev-workflow/            # Git branching, commit, PR, and release process
        └── ...                      # Python and TypeScript style / typing guides
```

## Getting started

1. **Use this repo as a template** or branch from it for your new project.

2. **Add secrets** in GitHub → Settings → Secrets and variables → Actions:
   - `ANTHROPIC_API_KEY` — required for automated Claude code review on PRs

3. **Import the branch ruleset** — Settings → Rules → Rulesets → Import → `.github/rulesets/main_dev_rule.json`.
   After the first CI run, add required status checks (`lint`, `tests`, `typecheck`, `claude-review`) manually.

4. **Configure MCP** — add `CONTEXT7_API_KEY` to `.claude/settings.local.json` under `env`, or export it in your shell:
   ```json
   { "env": { "CONTEXT7_API_KEY": "your-key" } }
   ```

5. **Update `CLAUDE.md`** — describe your project; Claude Code reads this every session.

6. **For CD** — follow the server setup in the [CD section](#cd) below.

## Local checks

```bash
make lint       # ruff + eslint + prettier
make typecheck  # mypy + vue-tsc
make test       # pytest + vitest
make check      # all of the above
```

The same checks run in CI on every PR.

## Git workflow

Feature and fix work branches off `develop` via short-lived `feature/<name>` or `fix/<name>` branches and merges back via squash PR. Releases and hotfixes use a bridge-branch process to avoid structural merge conflicts. The full process — branch naming, commit format, PR rules, release steps — is in `.claude/skills/dev-workflow/SKILL.md` and is loaded automatically by Claude Code.

## CD

Docker images are built and pushed to `ghcr.io` on every push to `main`. Only services with a `Dockerfile` are built, so a backend-only or frontend-only project works automatically.

**First-time server setup:**

```bash
# 1. Authenticate with ghcr.io (required for private repos)
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin

# 2. Configure .env — GITHUB_REPOSITORY must be lowercase (e.g. alice/my-project)
cp .env.example .env

# 3. Start services
docker compose --profile full up -d      # backend + frontend
docker compose --profile backend up -d   # backend only
docker compose --profile frontend up -d  # frontend only
```

Watchtower polls `ghcr.io` every 5 minutes and restarts containers when a new `:latest` image is pushed.

## MCP servers

Pre-configured in `.mcp.json`:

| Server | Purpose | Key |
|--------|---------|-----|
| [context7](https://github.com/upstash/context7) | Up-to-date library docs in context | `CONTEXT7_API_KEY` |

Recommended additions:
- [MCP Toolbox for Databases](https://github.com/googleapis/mcp-toolbox) — query and manage databases
- [Docker MCP Toolkit](https://docs.docker.com/ai/mcp-catalog-and-toolkit/toolkit/) — interact with containers and images
