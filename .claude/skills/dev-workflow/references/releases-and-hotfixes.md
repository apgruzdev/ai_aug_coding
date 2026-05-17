# Releases and Hotfixes

Both procedures use a short-lived **bridge branch** instead of merging two protected branches directly. This page explains why, then gives the exact steps.

## Why a bridge branch

`main` and `develop` are both squash-merge-only. A squash-merge of `develop → main` writes **one new commit** on `main` containing all of develop's changes — and that commit's SHA does not exist anywhere in develop's history. Develop still holds its own original per-feature squash commits.

The next time you try `develop → main`, Git does a 3-way merge and sees both branches independently "modifying" the same files since the merge-base. It reports a conflict — even though develop's content is a strict *superset* of main's. The disagreement is **structural, not semantic**: nobody actually made conflicting edits.

A bridge branch sidesteps this by reconciling the two histories in a branch where you control the resolution explicitly, using `-X theirs` / `-X ours` to silence the false conflict while any real edits still merge normally.

Do **not** try to "fix" this conflict by force-pushing, by disabling squash-merge, or by hand-resolving the diff file-by-file — you would either lose history or ship the wrong content. Use the procedures below.

## Release procedure

Goal: get everything on `develop` onto `main` as a tagged release.

1. **Pre-flight.** Confirm `main` has nothing that `develop` is missing:
   ```bash
   git fetch origin && git log origin/develop..origin/main
   ```
   The output must be empty. If `main` has extra commits, a hotfix back-merge was skipped — finish that first (see Hotfix back-merge below) before releasing.

2. **Create the release branch from `main`:**
   ```bash
   git checkout -b release/v<version> origin/main
   ```

3. **Merge `develop` into it, preferring develop on structural conflicts.** Develop is the newer integration branch, so its content wins:
   ```bash
   git merge origin/develop -X theirs
   ```
   Inspect the result. `-X theirs` only silences the squash-divergence noise; a genuine semantic conflict (rare) still needs real human resolution.

4. **Update the changelog** on the release branch, so it lands in the same PR.

5. **Push and open a PR** `release/v<version> → main`. Standard CI runs.

6. **Squash-merge once CI is green.** As with any PR, a human performs the merge.

7. **Tag the merge commit on `main`:**
   ```bash
   git tag v<version> <merge-sha> && git push origin v<version>
   ```

8. **Delete the release branch.**

`develop` needs no back-merge from a release — it already contains everything that was merged. The next release branches fresh from `main`, so no drift accumulates.

Every merge to `main` auto-deploys.

## Hotfix procedure

A hotfix patches production urgently, so it branches from `main` (not `develop`) and merges back into `main`:

1. **Branch from `main`:**
   ```bash
   git checkout -b hotfix/<name> origin/main
   ```
2. Make the fix. Commit with a Conventional Commit message and push.
3. Open a PR `hotfix/<name> → main`. Get CI green; a human squash-merges. It auto-deploys.
4. **Immediately do the back-merge below.** The fix currently exists only on `main` — if you skip this, `develop` never receives it.

## Hotfix back-merge

After the hotfix merges, its commit lives only on `main`. Pull it into `develop` through a bridge branch (same squash-divergence reason as a release):

1. **Branch from `develop`:**
   ```bash
   git checkout -b back-merge/<hotfix-name> origin/develop
   ```
2. **Merge `main`, keeping develop's versions on structural conflicts:**
   ```bash
   git merge origin/main -X ours
   ```
   `-X ours` keeps develop's content where the histories falsely diverge. The hotfix's real changes still land — they are new on `main` and untouched on `develop`, so there is nothing for them to conflict with.
3. Open a PR `back-merge/<hotfix-name> → develop`. Get CI green; a human squash-merges.
4. Delete the branch.

Skipping the back-merge leaves `main` ahead of `develop` and breaks the next release's pre-flight check.
