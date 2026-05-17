---
name: vue-components
description: Patterns for authoring Vue 3 Single-File Components — SFC structure, props, emits, slots, template directives, composables, lifecycle, and template refs. Use whenever writing, reviewing, or refactoring .vue files or composables. Trigger when the file is an SFC, when questions involve component structure, props/emits design, slot API, v-for/v-if/v-model usage, composable extraction, or lifecycle hooks. Apply proactively — do not wait for an explicit "Vue" mention if the context is clearly frontend component work.
---

# Vue Components

Patterns for Single-File Components and composables. Everything about authoring individual components lives here — state management and routing are in `vue-state`.

---

## SFC Structure

Always in this order:

```vue
<script setup lang="ts">
// 1. imports
// 2. defineProps / defineEmits / defineModel / defineSlots / defineOptions
// 3. injected dependencies  (useRouter, stores, inject)
// 4. reactive state         (ref, reactive)
// 5. computed properties
// 6. functions / handlers
// 7. watchers
// 8. lifecycle hooks        (onMounted, onUnmounted)
</script>

<template>
  <!-- single root element preferred; fragments allowed in Vue 3 -->
</template>

<style scoped>
/* component-scoped CSS — optional; see the Styling section */
</style>
```

No `<script>` without `setup`. No Options API (`data()`, `methods:`, `computed:`) in new code.

---

## Props

```typescript
// Type-only syntax — no runtime schema needed
const props = defineProps<{
  userId: string
  label?: string                     // optional
  variant: 'primary' | 'secondary'
}>()

// Default values via withDefaults
const props = withDefaults(defineProps<{
  label?: string
  count?: number
  items?: string[]
}>(), {
  label: 'Submit',
  count: 0,
  items: () => [],                   // factory for reference types
})
```

Rules:
- Required props — no `?`. Optional props — always provide a default with `withDefaults`.
- `camelCase` in script; Vue auto-converts to `kebab-case` in templates.
- **Never mutate props.** Emit an event; let the parent update.
- Avoid boolean props that invert meaning (`noScroll`, `disabled` is fine; `notClickable` is not).

---

## Emits

```typescript
// Labeled tuple syntax — serves as documentation
const emit = defineEmits<{
  select: [id: string]
  update: [value: number]
  close: []                          // no payload
}>()

// Usage
emit('select', user.id)
```

Design:
- Emit names: `verb` or `verb:noun` — `select`, `update:modelValue`, `item:delete`.
- One event, one responsibility. Don't overload a single event with different payload shapes.

---

## Two-Way Binding — `defineModel`

For components that participate in `v-model` (Vue 3.4+):

```typescript
// Basic v-model
const model = defineModel<string>()
// Parent: <MyInput v-model="search" />

// Named model
const isOpen = defineModel<boolean>('open')
// Parent: <MyDialog v-model:open="dialogOpen" />

// With validation
const value = defineModel<number>({ required: true })
```

Use `defineModel` instead of manually declaring `modelValue` prop + `update:modelValue` emit.

---

## Slots

```vue
<!-- Component definition -->
<template>
  <div class="card">
    <header v-if="$slots.header"><slot name="header" /></header>
    <main><slot :item="currentItem" /></main>         <!-- scoped slot -->
    <footer><slot name="footer">Default text</slot></footer>
  </div>
</template>
```

```vue
<!-- Consumer -->
<MyCard>
  <template #header>Title</template>
  <template #default="{ item }">{{ item.name }}</template>
</MyCard>
```

Type scoped slots when the data shape matters:

```typescript
defineSlots<{
  default(props: { item: User }): unknown
  header(): unknown
}>()
```

Check `$slots.header` before rendering the wrapper element — avoid empty `<header>` tags.

---

## Template Directives

```html
<!-- Conditional rendering — destroys/recreates DOM -->
<div v-if="isLoading">Loading…</div>
<UserCard v-else-if="user" :user="user" />
<EmptyState v-else />

<!-- Toggle visibility — keeps DOM alive -->
<Tooltip v-show="isVisible" />

<!-- List rendering — always :key -->
<li v-for="item in items" :key="item.id">{{ item.name }}</li>

<!-- Bindings -->
<input :value="name" :disabled="isDisabled" />
<button v-bind="buttonAttrs" />          <!-- spread object -->

<!-- Events with modifiers -->
<form @submit.prevent="onSubmit">
<input @keyup.enter="search" @keyup.esc="clear" />

<!-- Two-way binding on native elements -->
<input v-model="search" type="text" />
<input v-model.trim="name" />
<input v-model.number="age" type="number" />
```

Rules:
- Never put `v-if` and `v-for` on the same element — wrap with `<template v-if>` outside `v-for`.
- `:key` in `v-for` must be **stable and unique** — never use the array index when items can be reordered or removed.
- `v-show` for elements that toggle frequently (modal, tooltip); `v-if` for rarely-shown elements.

---

## Reactivity in Components

```typescript
import { ref, reactive, computed, watch, watchEffect } from 'vue'

// ref — primitives and replaceable objects
const count = ref(0)
const user = ref<User | null>(null)
count.value++                        // .value required in script

// reactive — objects always accessed together as a unit
const form = reactive({ name: '', email: '' })
form.name = 'Alice'                  // no .value

// computed — lazy, cached
const fullName = computed(() => `${props.first} ${props.last}`)

// watch — explicit source, runs on change
watch(() => props.userId, fetchUser, { immediate: true })

// watchEffect — implicit sources, runs immediately
watchEffect(() => { document.title = count.value.toString() })
```

Decision:
- `ref` for anything that might be replaced wholesale or is a primitive.
- `reactive` for form objects or grouped config where fields are always accessed together.
- Avoid `reactive` for objects you'll reassign — use `ref<T>()` instead.
- Prefer `computed` over deriving values inside a `watch` callback.

**Vue 3.5+ (the project target): destructured props stay reactive.** No
`toRefs` needed for in-component use:

```typescript
const { name, email } = defineProps<{ name: string; email: string }>()
// `name` and `email` track prop changes — read directly in template/computed
```

Use `toRefs(props)` only when **passing a prop as a `Ref` to a composable**
that expects refs:

```typescript
const { userId } = toRefs(props)
const { user } = useUser(userId)         // composable expects Ref<string>
```

For a `reactive(...)` object, the same rule applies — plain destructuring
breaks reactivity, `toRefs` preserves it.

---

## Composables

Composables extract and reuse stateful logic. They are plain functions using Vue's reactivity APIs.

```typescript
// src/composables/useAsync.ts
import { ref } from 'vue'

export function useAsync<T>(fn: () => Promise<T>) {
  const data = ref<T | null>(null)
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  async function execute(): Promise<void> {
    isLoading.value = true
    error.value = null
    try {
      data.value = await fn()
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Unknown error'
    } finally {
      isLoading.value = false
    }
  }

  return { data, isLoading, error, execute }
}
```

Rules:
- Name starts with `use` — always. File: `src/composables/use<Name>.ts`.
- Return a **plain object** (not `reactive`) so destructuring works: `const { data, execute } = useAsync(...)`.
- Clean up side effects in `onUnmounted` (remove listeners, cancel timers, abort fetches).
- If state needs to be shared globally, use Pinia instead.
- Don't access DOM inside composables — pass template refs as parameters.

---

## Lifecycle Hooks

```typescript
import { onMounted, onUnmounted } from 'vue'

onMounted(() => {
  // DOM ready — attach listeners, trigger initial fetch
})

onUnmounted(() => {
  // Clean up — remove listeners, cancel timers
})
```

Prefer `watch({ immediate: true })` over duplicating fetch logic in both `onMounted` and `watch`.

---

## Template Refs

```typescript
import { useTemplateRef } from 'vue'  // Vue 3.5+

const inputEl = useTemplateRef<HTMLInputElement>('input')
// Access only in onMounted or later — null before mount
```

```html
<input ref="input" type="text" />
```

---

## Provide / Inject

For passing data deep in a tree without prop drilling. Use `InjectionKey<T>` for type safety:

```typescript
// src/composables/keys.ts
import type { InjectionKey, Ref } from 'vue'
export const themeKey: InjectionKey<Ref<'light' | 'dark'>> = Symbol('theme')

// Provider (ancestor)
import { provide, ref } from 'vue'
const theme = ref<'light' | 'dark'>('light')
provide(themeKey, theme)

// Consumer (descendant)
import { inject } from 'vue'
const theme = inject(themeKey)    // type: Ref<'light' | 'dark'> | undefined
```

Provide/inject for component-tree concerns (theme, locale, feature flags). Pinia for app-wide shared state.

---

## Styling

Styling, design tokens, theming, and responsive layout are owned by the `vue-styling` skill — consult it for any CSS or Tailwind work. In short: Tailwind utility classes in the template are the default; `<style scoped>` is the exception, for what utilities can't express (complex selectors, keyframes, `:deep()`, genuinely dynamic values). Bind conditional styles with `:class` — never build class strings by concatenation.

---

## Component Naming and Organisation

- One component per file. File name = component name (PascalCase).
- `Base`/`App` prefix for base UI components (`BaseButton`, `AppHeader`).
- `The` prefix for layout singletons used once per page (`TheNavbar`, `TheSidebar`).
- Domain components named after the domain: `UserCard`, `ProductList`, `OrderSummary`.
- Split a component when it exceeds ~200 lines or has two distinct responsibilities.

---

## Common Pitfalls

- `v-if` + `v-for` on the same element — use a wrapping `<template>`.
- Array index as `:key` when items can reorder — causes incorrect patching.
- Mutating a prop — causes Vue warning and unpredictable state.
- `reactive` with a replaced object — old references go stale; use `ref<T>()` for replaceable objects.
- Async `setup` without `<Suspense>` in the parent — the component renders before data is ready.
