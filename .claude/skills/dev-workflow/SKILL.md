---
name: dev-workflow
description: Follow this project's Git branching, commit, pull request, and release process. Use whenever working with code in a repository that uses this workflow — creating or naming branches, writing commit messages, opening or titling pull requests, responding to automated code review, cutting a release, or applying a production hotfix. Trigger this even when the user just says "commit this", "open a PR", "make a branch", "ship a release", or "patch production" without explicitly naming a process, because branch names, commit subjects, PR titles, and especially release and hotfix merges all follow non-obvious rules that are easy to get wrong.
---

# Dev Workflow

This repository uses a two-branch Git flow with **squash-merge-only history** and **fully automated code review**. Follow this process for every code change. Most rules exist to keep history linear and to avoid one specific structural merge conflict (explained under Releases) — deviating quietly breaks `develop` or `main` for everyone.

## Pick the right path first

Before touching anything, identify what kind of change this is. The starting branch and procedure differ:

| Change | Branch from | Read |
|--------|-------------|------|
| New feature | `develop` | this file |
| Bug fix (not urgent) | `develop` | this file |
| Urgent production fix | `main` | `references/releases-and-hotfixes.md` **before starting** |
| Cutting a release | `main` | `references/releases-and-hotfixes.md` **before starting** |

Releases and hotfixes use bridge branches and conflict-resolution flags that are easy to get wrong. Always open the reference file before doing either — do not improvise them from this page.

## Branch model

Two permanent branches, both protected (no direct pushes, no force-push, no deletion):

- `main` — production. Always deployable. Every merge here auto-deploys.
- `develop` — integration. The default target for feature and fix work.

Short-lived branches:

| Branch | From | Merges into | Purpose |
|--------|------|-------------|---------|
| `feature/<name>` | `develop` | `develop` | New functionality |
| `fix/<name>` | `develop` | `develop` | Bug fixes |
| `hotfix/<name>` | `main` | `main` | Urgent production fixes |
| `release/v<version>` | `main` | `main` | Bridge `develop` → `main` for a release |
| `back-merge/<name>` | `main` | `develop` | Bridge a hotfix back into `develop` |

`<name>` is a kebab-case slug, optionally prefixed with a ticket id: `feature/add-jwt-refresh` or `feature/PROJ-123-add-jwt-refresh`.

## Standard workflow (feature / fix)

1. **Start from a fresh base.** A branch off a stale local base hides conflicts CI won't catch but the next push will:
   ```bash
   git fetch origin && git checkout develop && git pull
   git checkout -b feature/<name> develop
   ```
2. **Write the code.** Make focused commits as you go.
3. **Commit** using the Conventional Commit format (see below).
4. **Push and open a PR into `develop`.** The PR title matters — see Pull requests.
5. **Let CI run.** GitHub Actions runs every required check.
6. **Iterate.** Address review findings and CI failures, then push again to re-trigger the checks.
7. **Stop at green.** The author's job ends when all checks pass. **Do not merge the PR yourself** — a human performs the squash-merge.

## Commit convention

Use [Conventional Commits](https://www.conventionalcommits.org/): `<type>(<scope>): <description>`

Types:

- `feat` — new feature
- `fix` — bug fix
- `docs` — documentation only
- `refactor` — code change that neither adds a feature nor fixes a bug
- `test` — adding or updating tests
- `chore` — maintenance that doesn't change runtime behavior: dependency bumps, build config, tooling, CI tweaks

Scope is optional and names the affected area: `backend`, `frontend`, `auth`, etc.

**Examples**

Input: Added JWT refresh token rotation to the auth service
Output: `feat(auth): add JWT refresh token rotation`

Input: Fixed a crash when the payment API returns null
Output: `fix(backend): handle null response from payment API`

Input: Bumped Python dependencies
Output: `chore: update Python dependencies`

## Pull requests

- **Target `develop`** for feature and fix branches.
- **The PR title becomes the commit message.** GitHub's squash-merge uses the PR title verbatim as the commit subject on `develop`. Format the PR title as a Conventional Commit, exactly like a commit message. A PR titled `Fix the thing` lands as literally `Fix the thing` in history and silently breaks the convention.
- **Sync with the base before requesting merge.** If `develop` moved while the PR was open, merge `origin/develop` into the branch and push, so CI re-runs against the true merge state. Skipping this can leave `develop` broken even though the PR's CI was green — it passed on a stale base.
- **Force-push to your own branch is fine.** Short-lived branches aren't protected. Use `git push --force-with-lease` to clean up history — fix commit messages, drop WIP commits. Force-push to `main` or `develop` is blocked by the ruleset.
- **Delete the branch when it merges.** Stale branches accumulate and clutter `git branch -a`. Use the "Delete branch" button, or `gh pr merge <n> --squash --delete-branch`.

## CI checks

All required checks must be green before a PR can merge:

| Check | Backend | Frontend |
|-------|---------|----------|
| `lint` | ruff (lint + format) | eslint + prettier |
| `tests` | pytest | vitest |
| `typecheck` | mypy | vue-tsc |
| `claude-review` | automated Claude code review — no critical findings | |

When a check fails, fix the cause and push again. Never try to merge around a red check.

## Automated code review

Code review is **fully automated** — a GitHub Action runs Claude on every PR diff and posts findings as PR comments. There is no human review step. The reviewer flags logic errors and edge cases, security issues, and style/convention violations.

As the author:

- **Address every finding** — either fix it, or justify it in a PR comment explaining why it is intentional.
- **Push again** to re-trigger the review after changes.
- The `claude-review` check passes only once there are no unresolved critical findings.

## Releases and hotfixes

Do **not** open a direct `develop → main` pull request, and do **not** merge a hotfix straight into `develop`. Both hit a structural squash-merge conflict and need a bridge branch instead.

Read **`references/releases-and-hotfixes.md`** before cutting a release or applying a hotfix. It explains why the conflict happens and gives the exact step-by-step procedure for each.

## Setting up a new repository

Branch protection is defined by a GitHub Ruleset committed at `.github/rulesets/main_dev_rule.json`. For a new repo, import it under Settings → Rules → Rulesets → Import. It enforces, on `main` and `develop`: no direct pushes, squash-merge only, no force-push, no branch deletion. The required status checks (`lint`, `tests`, `typecheck`, `claude-review`) must be added by hand after the Actions workflows have run once on a PR.
