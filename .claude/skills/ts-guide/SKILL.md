---
name: ts-guide
description: TypeScript style, idioms, and type system for strict TypeScript 5.x. Use whenever writing, reviewing, or refactoring TypeScript or JavaScript — utilities, composables, stores, API modules, configs, tests. Trigger when code uses type annotations, asks for "strict" or "modern" TS, migrates from `any`/`Object`/`Function`, or when any question is about naming, formatting, imports, async patterns, or error handling in a TypeScript codebase.
---

# TypeScript Guide (TypeScript 5.x, strict mode)

Style and typing in one place — because in TypeScript they are the same concern.

---

## Philosophy

- **Explicit over clever.** A longer, readable expression beats a compact one requiring mental parsing.
- **No `any`.** Use `unknown` and narrow, or model the type. Every `any` is a hole in the type checker for every downstream consumer.
- **Immutability by default.** `const` everywhere; `let` only when reassignment is genuinely needed; never `var`.
- **Types are the spec.** Write types before implementation — they document intent and catch mistakes early.
- **Errors are values.** Never swallow rejections. Handle them or let them propagate.

---

## Naming

| Element | Convention | Example |
|---|---|---|
| Variable, function, method | `camelCase` | `fetchUser`, `retryCount` |
| Class, type alias, interface, enum | `PascalCase` | `UserProfile`, `ApiError` |
| Vue component (file + template) | `PascalCase` | `UserCard.vue`, `<UserCard />` |
| Module-level constant (never reassigned) | `UPPER_SNAKE_CASE` | `MAX_RETRIES`, `BASE_URL` |
| Composable | `use` prefix | `useUserSession` |
| Pinia store | `use` + domain + `Store` | `useAuthStore` |
| Boolean variable | `is` / `has` / `can` prefix | `isLoading`, `hasError` |
| Generic type parameter | Single uppercase or descriptive | `T`, `TItem`, `TKey` |

Avoid abbreviations that aren't universally known (`usr`, `mgr`), numbered suffixes (`data2`), and Hungarian notation (`strName`).

---

## Formatting

Enforced by **Prettier** — don't hand-format. Run `pnpm lint --fix`. Key settings:

- 2-space indent, single quotes, trailing commas (`"all"`), **no semicolons**, max line length 100.
- Arrow functions: omit parens for single parameter (`x => x + 1`), include for zero or multiple.

---

## Imports

Order (enforced by `eslint-plugin-simple-import-sort`):

1. Node.js builtins with the `node:` protocol (config files only)
2. External packages (`vue`, `pinia`, `zod`)
3. Internal aliases (`@/`)
4. Relative imports (`./`)

Blank line between groups. Use `import type { Foo }` for type-only imports — stripped at build time with no runtime cost.

```typescript
import { ref, computed } from 'vue'
import { defineStore } from 'pinia'

import type { User } from '@/types/user'
import { fetchUser } from '@/api/users'

import BaseButton from './BaseButton.vue'
```

Prefer named exports for utilities and composables. Default exports for Vue components (framework convention).

---

## Types

### Primitives and Literals

```typescript
const status = 'active' as const   // type: "active"
type Direction = 'north' | 'south' | 'east' | 'west'
type EventName = `on${Capitalize<string>}`
```

### Object Types

```typescript
// type, not interface (unless declaration merging is needed)
type User = {
  readonly id: string
  name: string
  email: string | null
  role: 'admin' | 'viewer'
}

// satisfies — validates shape without widening the inferred type
const config = {
  host: 'localhost',
  port: 3000,
} satisfies Record<string, string | number>
// config.port stays number, not string | number
```

### Discriminated Unions — primary tool for multi-state data

Never use nullable fields to encode state. Model states explicitly:

```typescript
// Prefer
type AsyncState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: string }

// Avoid
type AsyncState<T> = { loading: boolean; data?: T; error?: string }
```

Pair with an exhaustive check:

```typescript
function assertNever(x: never): never {
  throw new Error(`Unhandled case: ${JSON.stringify(x)}`)
}
```

### Generics

```typescript
function first<T>(items: readonly T[]): T | undefined {
  return items[0]
}

function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key]
}

type ApiResult<T> = { ok: true; data: T } | { ok: false; error: string }
```

### Utility Types (use these, don't reinvent)

`Partial`, `Required`, `Readonly`, `Pick`, `Omit`, `Record`, `Exclude`, `Extract`, `NonNullable`, `ReturnType`, `Parameters`, `Awaited`.

### `unknown` vs `any`

```typescript
// unknown — must narrow before use
async function load(url: string): Promise<unknown> {
  return fetch(url).then(r => r.json())
}
const data = await load('/api/user')
if (isUser(data)) { console.log(data.name) }  // OK after narrowing

// any — bypasses all checks, avoid
```

Validate external data with **zod** at the boundary; derive types from schemas:

```typescript
import { z } from 'zod'

const UserSchema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string().email().nullable(),
})

type User = z.infer<typeof UserSchema>  // single source of truth
const user = UserSchema.parse(rawResponse)
```

### Type Guards

```typescript
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' && value !== null &&
    'id' in value && typeof (value as Record<string, unknown>).id === 'string'
  )
}

// Assertion function
function assertDefined<T>(value: T | null | undefined): asserts value is T {
  if (value == null) throw new Error('Expected defined value')
}
```

Prefer narrowing over non-null assertions (`!`). Every `!` needs a comment explaining why it's safe.

### No Enums — Use Unions

```typescript
// Avoid
enum Status { Active = 'active', Inactive = 'inactive' }

// Prefer
type Status = 'active' | 'inactive'

// Or as const object when you need the values as a map
const STATUS = { Active: 'active', Inactive: 'inactive' } as const
type Status = typeof STATUS[keyof typeof STATUS]
```

---

## Functions

- Arrow functions for callbacks and composable internals; `function` declarations for top-level module exports.
- Annotate return types on all exported functions. Local helpers may rely on inference.
- Return early to flatten control flow. Avoid more than 2 levels of nesting.

```typescript
// Prefer
function getLabel(user: User): string {
  if (!user.name) return 'Anonymous'
  return user.name.trim()
}
```

---

## Async / Await

- Always `async/await` — no `.then()/.catch()` chains.
- `try/catch` when handling errors locally; let them propagate otherwise.
- Parallel independent calls with `Promise.all`, not sequential `await`:

```typescript
const [user, posts] = await Promise.all([fetchUser(id), fetchPosts(id)])
```

---

## Error Handling

- Never empty `catch {}`.
- Operational errors (network, 404) — catch and handle. Programmer errors (null dereference) — let crash.
- Typed error results for domain errors:

```typescript
type Result<T> = { ok: true; data: T } | { ok: false; error: string }
```

---

## Comments

Default: **no comments**. Write one only when the **why** is non-obvious — a hidden constraint, a workaround, a non-intuitive invariant. Never describe what the code does line-by-line. JSDoc on exported public APIs; first line imperative mood.

---

## Working Style

1. Read surrounding code first — project consistency beats any rule here.
2. Run `pnpm lint --fix` — don't hand-format.
3. Don't reformat code you didn't touch.
