# Development Process

## Branch model

Two permanent branches:

- `main` — production; always deployable; protected, no direct pushes
- `develop` — integration; default target for feature work; protected, no direct pushes

Short-lived branches:

| Branch | Branched from | Merges into | Purpose |
|--------|--------------|-------------|---------|
| `feature/<name>` | `develop` | `develop` | New functionality |
| `fix/<name>` | `develop` | `develop` | Bug fixes |
| `hotfix/<name>` | `main` | `main`, then back-merge into `develop` | Urgent production fixes |

Releases happen by merging `develop` → `main` via PR. No `release/*` branches.

`<name>` can be a kebab-case slug (`feature/add-jwt-refresh`) or include a ticket id (`feature/PROJ-123-add-jwt-refresh`).

## Commit convention

[Conventional Commits](https://www.conventionalcommits.org/) — `<type>(<scope>): <description>`

Types:

- `feat` — new feature
- `fix` — bug fix
- `docs` — documentation only
- `refactor` — code change that neither adds a feature nor fixes a bug
- `test` — adding or updating tests
- `chore` — maintenance work that doesn't change runtime behavior: dependency bumps, build config, tooling, CI tweaks

Scope is optional: `backend`, `frontend`, `auth`, etc.

Examples:
```
feat(auth): add JWT refresh token rotation
fix(backend): handle null response from payment API
chore: update Python dependencies
```

## Workflow

```
1. Branch     git checkout -b feature/<name> develop
2. Develop    write code with Claude Code
3. Commit     conventional commit messages
4. Push & PR  open PR into develop
5. CI         GitHub Actions runs all required checks (see below)
6. Iterate    address review findings and CI failures, push again
7. Merge      human clicks "Squash and merge" once all checks are green
```

The author's job ends at "all checks green". The human reviewer's only action is clicking merge.

## Code review

**Fully automated.** A GitHub Action runs Claude on every PR diff and posts findings as PR comments. There is no human review step.

The reviewer flags:
- Logic errors and edge cases
- Security issues
- Style and convention violations

Author responsibilities:
- Address every finding — fix it, or justify it in a PR comment
- Push again to re-trigger the review

Implementation: Anthropic's [`claude-code-action`](https://github.com/anthropics/claude-code-action) or an equivalent GitHub Action that calls the Claude API on the PR diff.

## CI checks

Required checks (must all pass before merge):

| Check | Backend | Frontend |
|-------|---------|----------|
| `lint` | ruff | eslint |
| `tests` | pytest | vitest |
| `typecheck` | — | tsc |
| `claude-review` | automated Claude code review (no critical findings) | |

## Branch protection

Configured via GitHub Ruleset — see `.github/rulesets/main_dev_rule.json`. Import it when setting up a new repository (Settings → Rules → Rulesets → Import).

Rules applied to `main` and `develop`:

- No direct pushes — all changes via PRs
- Squash merge only — linear history enforced
- No force pushes
- No branch deletion

Required status checks (`lint`, `tests`, `typecheck`, `claude-review`) must be added manually after GitHub Actions workflows run for the first time on a PR.

## Releases

Releases happen on merge from `develop` → `main`:

- **Continuous deployment**: every merge to `main` auto-deploys
- **Tagged releases**: tag the merge commit on `main` with `v<version>` (semver); update the changelog in the same PR
