---
name: vue-styling
description: Styling, design tokens, and theming for Vue 3 apps with Tailwind CSS v4 — CSS-first config, the @theme token layer, semantic color tokens, light/dark theming, responsive design, and choosing between utility classes and scoped styles. Use whenever writing or reviewing styles in .vue files, CSS, or Tailwind config. Trigger when adding classes to a template, defining colors/spacing/typography, setting up dark mode, making a component responsive, or deciding between Tailwind utilities and scoped styles.
---

# Vue Styling

Styling for Vue 3 with Tailwind CSS v4. Design tokens are the single source of
truth; utility classes are the default authoring surface. This skill is the
authority for all CSS work — `vue-components` defers here for styling.

---

## Principles

- **Tokens first.** Colour, spacing, typography, and radii live in the `@theme`
  layer as CSS variables. Components consume tokens; they never hardcode values.
- **Utilities by default.** Style in the template with Tailwind utility classes.
  `<style scoped>` is the exception, for what utilities genuinely can't express.
- **Semantic over literal.** Markup references intent (`bg-surface`,
  `text-muted`), not raw palette (`bg-zinc-100`, `text-gray-500`). Semantic
  tokens are what make theming and dark mode possible at all.

---

## How it's wired

Tailwind v4 is CSS-first — there is no `tailwind.config.js`, no PostCSS config,
and no autoprefixer. All configuration lives in CSS. The Tailwind deps and the
Vite plugin are already in `package.json` and `vite.config.ts`; a feature change
only touches the CSS below.

The entry stylesheet, imported once in `src/main.ts`, is just:

```css
/* src/assets/main.css */
@import 'tailwindcss';
```

Everything below happens inside this file.

In a monorepo, components outside the app's own `src/` are not scanned by
default — add `@source` so their classes are picked up:

```css
@source '../../packages/ui/src';
```

---

## Design Tokens — the `@theme` layer

`@theme` defines the design system. Each entry becomes **both** a CSS variable
and a Tailwind utility. Define the **primitive palette** here — the raw scale
with no meaning attached.

```css
@import 'tailwindcss';

@theme {
  /* Brand palette — primitives */
  --color-brand-50:  oklch(0.97 0.02 250);
  --color-brand-500: oklch(0.62 0.19 250);
  --color-brand-700: oklch(0.48 0.17 250);

  /* Type / radii — extend only where Tailwind's defaults fall short */
  --font-display: 'Inter', sans-serif;
  --radius-card:  0.75rem;
}
```

`--color-brand-500` automatically makes `bg-brand-500`, `text-brand-500`, and
`border-brand-500` available. Naming follows Tailwind's namespaces: `--color-*`,
`--spacing-*`, `--radius-*`, `--font-*`, `--text-*`, `--shadow-*`.

Rules:
- Extend the default theme; don't redefine the whole scale. Tailwind's default
  spacing and sizing are fine for the vast majority of cases.
- Primitives carry no meaning. Meaning comes from semantic tokens, next.
- All `@theme` entries live in one `@theme` block — the snippets below are parts
  of the same block.

---

## Semantic Tokens

Never let a component reference a primitive directly. A component that says
`bg-zinc-900` cannot be re-themed; a component that says `bg-surface` can. Add a
second layer of tokens that maps **intent → primitive**:

```css
@theme {
  /* Semantic — what the colour means, not what it is. Light values. */
  --color-surface:      var(--color-white);
  --color-surface-sunk: var(--color-zinc-100);
  --color-text:         var(--color-zinc-900);
  --color-text-muted:   var(--color-zinc-500);
  --color-border:       var(--color-zinc-200);
  --color-brand:        var(--color-brand-500);
}
```

In markup, only semantic tokens appear:

```html
<article class="bg-surface text-text border border-border rounded-card">
  <p class="text-text-muted">…</p>
</article>
```

This is the Tailwind-native form of the old "CSS custom properties for theming,
no hardcoded colours" rule. The rule is unchanged — only the mechanism is now
the `@theme` layer.

---

## Theming and Dark Mode

Dark mode means the **semantic tokens take different values**. Primitives never
change; only the intent → primitive mapping flips. Because components use only
semantic tokens, **no component markup changes for dark mode**.

By default the `dark:` variant follows the OS via `prefers-color-scheme`. For an
explicit, user-controlled toggle, override the variant to a data attribute:

```css
@import 'tailwindcss';

/* User-controlled dark mode via data-theme on <html> */
@custom-variant dark (&:where([data-theme='dark'], [data-theme='dark'] *));
```

Then redefine the semantic tokens for the dark scope:

```css
[data-theme='dark'] {
  --color-surface:      var(--color-zinc-900);
  --color-surface-sunk: var(--color-zinc-800);
  --color-text:         var(--color-zinc-100);
  --color-text-muted:   var(--color-zinc-400);
  --color-border:       var(--color-zinc-800);
}
```

`bg-surface` compiles once to `background-color: var(--color-surface)`; the
variable's *value* is what the `[data-theme='dark']` scope overrides. Reach for
the `dark:` variant only for a one-off adjustment no token can express.

Drive the attribute from a Pinia store (see `vue-state` for persistence with
`useLocalStorage`):

```typescript
// themeStore.value is persisted; mirror it onto <html>
watchEffect(() => {
  document.documentElement.dataset.theme = themeStore.value
})
```

---

## Utilities vs `<style scoped>` vs `@apply`

**Default: utility classes in the template.** They sit next to the markup, need
no naming, and are dead-code-eliminated automatically.

Use **`<style scoped>`** only for what utilities can't reach:
- Complex selectors (`:nth-child`, sibling combinators).
- `@keyframes` animations.
- Styling a child component's internals via `:deep()`.
- A genuinely dynamic value — e.g. a `width` computed as a pixel number.

```vue
<template>
  <div class="bg-surface rounded-card p-4" :style="{ width: `${width}px` }">
    <slot />
  </div>
</template>

<style scoped>
@keyframes fade-in { from { opacity: 0 } to { opacity: 1 } }
</style>
```

**Avoid `@apply`.** It recreates the indirection Tailwind removes — you read a
class name, then hunt for its definition elsewhere. The only two reasonable uses:
- A base-layer style on a bare HTML element (`body`, form-control resets).
- A class consumed by `v-html` content whose markup you don't control.

If a utility string repeats, the answer is almost always **extract a component**,
not `@apply`.

---

## Conditional and Dynamic Classes

Bind classes with the object or array form — never assemble class strings by
concatenation. Tailwind's scanner only sees complete class names in the source;
a name built at runtime is never generated and the style silently vanishes.

```vue
<!-- object form — key is the class, value is the condition -->
<button :class="{ 'opacity-50 pointer-events-none': isLoading }">

<!-- array form — static plus conditional -->
<span :class="['rounded-card px-3 py-1', isActive ? 'bg-brand text-white' : 'bg-surface-sunk']">
```

```typescript
// ✗ scanner can't see this — the class is never generated
const cls = `bg-${color}-500`

// ✓ complete class names, statically visible
const cls = isError ? 'bg-red-500' : 'bg-brand'
```

For variant-heavy components (button sizes/tones), map each prop value to a
complete class string in a lookup object — or use `tailwind-variants` / `cva` if
the project already depends on one. Never interpolate class fragments.

---

## Responsive Design

Tailwind is mobile-first: an unprefixed utility applies everywhere; a prefixed
one applies at that breakpoint and up.

```html
<!-- one column on mobile, three from the md breakpoint up -->
<div class="grid grid-cols-1 md:grid-cols-3 gap-4">
```

- Write the mobile layout first, then layer `sm:` / `md:` / `lg:` overrides on top.
- Use the named breakpoints. Drop to an arbitrary `min-[…]` value only when a
  design genuinely demands one.
- A custom breakpoint is a token too: `--breakpoint-3xl: 120rem;`.

---

## Class Order and Readability

- Install **`prettier-plugin-tailwindcss`** — it sorts classes into a canonical
  order on every format, so class ordering is never a manual decision or a
  review comment.
- A long but flat class list is acceptable. A class list long enough to bury the
  markup is a signal the component should be split.
- When hand-writing, group by concern (layout → spacing → colour → state); the
  plugin normalises it anyway.

---

## Common Pitfalls

- **Dynamic class fragments** (`` `text-${size}` ``) — not generated by the
  scanner; use complete names or a lookup map.
- **Primitive palette in markup** (`bg-zinc-100`) — bypasses theming; use a
  semantic token.
- **`@apply` to share styles** — extract a component instead.
- **A `tailwind.config.js` file** — v4 has no JS config; configuration is
  `@theme` in CSS. A stray config file is a v3 leftover.
- **Editing `<style scoped>` for colours** — colours belong in tokens, never in
  per-component CSS.
- **Fighting the defaults** — redefining the entire spacing or colour scale.
  Extend only what the design actually needs.
