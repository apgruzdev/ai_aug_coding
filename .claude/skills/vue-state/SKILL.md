---
name: vue-state
description: State management and routing in Vue 3 — Pinia stores, reactivity patterns for shared state, Vue Router configuration, and HTTP/API integration. Use whenever writing, reviewing, or refactoring Pinia stores, route configs, or API modules. Trigger when code imports from 'pinia' or 'vue-router', when designing store structure, handling async state, or setting up navigation guards.
---

# Vue State and Routing

Pinia stores, Vue Router, and HTTP patterns. Component-level reactivity is in `vue-components`.

---

## Pinia Stores

### Structure

Always use **setup stores** (function syntax) — full TypeScript inference, same API as Composition API:

```typescript
// src/stores/useProductStore.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Product } from '@/types/product'
import { api } from '@/api/products'

export const useProductStore = defineStore('product', () => {
  // State
  const items = ref<Product[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  // Getters
  const count = computed(() => items.value.length)
  const inStock = computed(() => items.value.filter(p => p.stock > 0))

  // Actions
  async function load(): Promise<void> {
    isLoading.value = true
    error.value = null
    try {
      items.value = await api.list()
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to load'
    } finally {
      isLoading.value = false
    }
  }

  function reset(): void {
    items.value = []
    error.value = null
  }

  return { items, isLoading, error, count, inStock, load, reset }
})
```

### Rules

- One store per domain. Name: `use<Domain>Store` (`useAuthStore`, `useCartStore`).
- Stores hold shared/global state. Component-local state stays in the component with `ref`/`reactive`.
- **Always model async state** with three fields: `data`, `isLoading`, `error`. Never omit the error field.
- Actions are the only place that mutates store state. Components call actions; they never write `store.x = y` directly.
- Keep stores free of presentation logic (formatting, routing). That belongs in components or computed properties that live in the component.

### Using Stores in Components

```typescript
import { storeToRefs } from 'pinia'
import { useProductStore } from '@/stores/useProductStore'

const store = useProductStore()

// Destructure reactive state with storeToRefs — preserves reactivity
const { items, isLoading, error } = storeToRefs(store)

// Actions can be destructured directly (they are plain functions)
const { load, reset } = store

onMounted(() => load())
```

`storeToRefs` is the Pinia equivalent of `toRefs`. Destructuring state directly from the store loses reactivity.

### Store Composition

Stores can use other stores:

```typescript
export const useCartStore = defineStore('cart', () => {
  const auth = useAuthStore()  // access another store inside setup

  const items = ref<CartItem[]>([])

  async function checkout(): Promise<void> {
    if (!auth.isAuthenticated) throw new Error('Not authenticated')
    // ...
  }

  return { items, checkout }
})
```

---

## Vue Router

### Route Configuration

```typescript
// src/router/index.ts
import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'home',
    component: () => import('@/views/HomeView.vue'),   // lazy-load all views
  },
  {
    path: '/users/:id',
    name: 'user',
    component: () => import('@/views/UserView.vue'),
    meta: { requiresAuth: true },
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'not-found',
    component: () => import('@/views/NotFoundView.vue'),
  },
]

export const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
  scrollBehavior: (to, from, savedPosition) => savedPosition ?? { top: 0 },
})
```

### Navigation Guards

```typescript
// Global auth guard — in src/router/index.ts after createRouter
router.beforeEach((to) => {
  const auth = useAuthStore()
  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
})
```

### Using Router in Components

```typescript
import { useRouter, useRoute } from 'vue-router'

const router = useRouter()
const route = useRoute()

// Navigate with named routes — not path strings
router.push({ name: 'user', params: { id: userId } })

// Read params — without typed routes, params can be `string | string[]`,
// and with `noUncheckedIndexedAccess` they may also be `undefined`.
// Normalise defensively; never cast with `as string`.
const userId = Array.isArray(route.params.id) ? route.params.id[0] : route.params.id ?? ''

// Query params — same shape; coerce with Number/String + default
const page = Number(route.query.page ?? 1)
```

Rules:
- Always lazy-load views (`() => import(...)`).
- Navigate with **named routes**, not path strings — names survive path refactors.
- Never import `router` directly in a component — use `useRouter()`.
- Use `<RouterLink :to="{ name: 'user', params: { id } }">` for declarative navigation, never `<a href>`.

### Typed Routes (recommended for large projects)

Use `unplugin-vue-router` or `vue-router/auto-routes` for automatic typed route generation. With typed routes, `route.params.id` is `string` without manual casting.

---

## HTTP and API Integration

### API Module Pattern

Centralise all HTTP calls in `src/api/` — never call `fetch` directly from a component or store.

```typescript
// src/api/users.ts
import { ofetch } from 'ofetch'
import { UserSchema } from '@/types/user'
import type { User } from '@/types/user'

const BASE = '/api/users'

export const usersApi = {
  async get(id: string): Promise<User> {
    const raw = await ofetch(`${BASE}/${id}`)
    return UserSchema.parse(raw)               // validate at the boundary
  },

  async list(): Promise<User[]> {
    const raw = await ofetch(BASE)
    return UserSchema.array().parse(raw)
  },

  async create(input: CreateUserInput): Promise<User> {
    const raw = await ofetch(BASE, { method: 'POST', body: input })
    return UserSchema.parse(raw)
  },
}
```

Rules:
- **Validate responses with zod** when the API is external or untrusted. Derive TypeScript types from schemas (`z.infer<typeof Schema>`).
- **Never swallow errors** in API modules — let them propagate to the store where they're caught and surfaced to the UI.
- Use `ofetch` over raw `fetch` for automatic JSON parsing, error throwing on 4xx/5xx, and TypeScript generics. No axios.
- Group API functions by domain: `usersApi`, `productsApi`, `authApi`.

### Async State Pattern

Consistent pattern across all stores that load remote data:

```typescript
type AsyncData<T> = {
  data: T | null
  isLoading: boolean
  error: string | null
}

// Alternatively, discriminated union for exhaustive handling
type RemoteData<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: string }
```

Use the simple three-field pattern for most cases. Use discriminated union when the component needs to handle all states exhaustively (prevents partially-filled UI states like showing stale data alongside a new error).

---

## Global State vs Local State — Decision Guide

| State type | Where it lives |
|---|---|
| Fetched remote data used in multiple views | Pinia store |
| UI state local to one component (open/closed, hover) | `ref` in component |
| Form data | `reactive` in component or a dedicated form composable |
| User session, auth token | Pinia store (persisted if needed) |
| Theme, locale, feature flags | Pinia store + provide/inject |
| Derived/computed values | `computed` in store or component |
| URL state (pagination, filters) | Vue Router query params |

---

## Store Persistence

For state that must survive page reload (auth token, user preferences):

```typescript
import { useLocalStorage } from '@vueuse/core'

export const useAuthStore = defineStore('auth', () => {
  // Automatically synced to localStorage
  const token = useLocalStorage<string | null>('auth-token', null)
  const isAuthenticated = computed(() => token.value !== null)

  function logout(): void {
    token.value = null
  }

  return { token, isAuthenticated, logout }
})
```

Use `@vueuse/core`'s `useLocalStorage` / `useSessionStorage` instead of raw `localStorage.setItem`.
