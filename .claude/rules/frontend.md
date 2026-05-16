---
paths:
  - "frontend/**/*"
---

# Frontend Development Standards

Always-on rules for everything under `frontend/`. This file is deliberately thin.
It records **what** stack we use and **how to run it** — the locked decisions and
the commands. It does **not** describe how to write code: that lives in the
skills. Do not copy skill content back into this file.

## Authority

When guidance conflicts, the more specific source wins:

1. A project-level `CLAUDE.md` or repo instructions
2. This file (`frontend.md`)
3. The skills listed below

This file overrides a skill only on **stack choices**. For *how* to write code,
the skills are authoritative — if a skill says more than this file, follow the
skill.

## Where the patterns live

Consult these skills for anything past the decisions on this page. Do not restate
their contents here — a rule that belongs in a skill goes in the skill.

| Skill | Covers |
|---|---|
| `ts-guide` | TypeScript style, types, idioms, error handling |
| `vue-components` | SFC structure, props/emits, slots, composables, lifecycle |
| `vue-state` | Pinia stores, Vue Router, HTTP / API layer |
| `vue-styling` | Tailwind, design tokens, theming, responsive styling |
| `vue-testing` | Vitest + Vue Test Utils |

## Stack — locked decisions

Don't substitute alternatives without a reason documented in the PR.

- **Language** — TypeScript 5.x, `strict: true`, ESNext.
- **UI** — Vue 3, Composition API, `<script setup>` only. No Options API.
- **Routing** — Vue Router 4.
- **State** — Pinia, setup-store syntax. No Vuex.
- **HTTP** — native `fetch` / `ofetch`. No axios.
- **Styling** — Tailwind CSS v4 (CSS-first config). No CSS-in-JS, no other UI kit.
- **Build** — Vite. **Package manager** — pnpm.
- **Lint / format** — ESLint + Prettier.
- **Tests** — Vitest + @vue/test-utils. **Type-check** — vue-tsc.

## Toolchain — commands

Run from `frontend/`:

```bash
pnpm install      # install dependencies
pnpm dev          # dev server
pnpm lint         # eslint
pnpm typecheck    # vue-tsc --noEmit
pnpm test         # vitest run
pnpm build        # production build
```

Before declaring code complete, verify it would pass `pnpm lint` and
`pnpm typecheck`. Use `vue-tsc`, not plain `tsc` — it type-checks `.vue` files.

## Working agreement

How to work — process rules, not coding patterns (those are in the skills):

- **Types first.** Model `defineProps` / `defineEmits` and return types before
  implementation. New component order: prop & emit types → template → script.
- **Respect existing project setup.** Configs, conventions, and folder structure
  already exist — extend them, never regenerate them. A skill that shows a
  from-scratch setup is illustrative; it is not licence to overwrite ours.
- **Preserve public contracts** when refactoring — keep prop names and emit
  signatures stable unless a change is explicitly requested.
- **No new dependencies** without calling them out explicitly in the PR.
- **Ask, don't guess.** When intent is unclear, ask one clarifying question
  instead of producing plausible-but-wrong code.
- No bare `console.log` in committed code.

## Project Context

<!-- Project-level CLAUDE.md overrides this section. Leave empty in the global file. -->
