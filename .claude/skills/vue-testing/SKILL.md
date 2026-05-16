---
name: vue-testing
description: Testing patterns for Vue 3 with Vitest and Vue Test Utils — component mounting, async behavior, Pinia store mocking, HTTP mocking, and composable testing. Use whenever writing or reviewing test files for Vue components, composables, or Pinia stores. Trigger when file is *.test.ts / *.spec.ts in a Vue project, or when questions involve how to test a component, mock a store, or assert on emitted events.
---

# Vue Testing

Vitest + Vue Test Utils patterns for Vue 3. All imports from `vitest`, not `jest`.

---

## Setup

```typescript
// vite.config.ts (or vitest.config.ts)
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  test: {
    environment: 'jsdom',
    globals: true,           // no need to import describe/it/expect
    setupFiles: ['./src/test/setup.ts'],
  },
})
```

```typescript
// src/test/setup.ts
import { config } from '@vue/test-utils'
import { createPinia } from 'pinia'

// Global plugins available in all tests
config.global.plugins = [createPinia()]
```

---

## Mounting Components

```typescript
import { mount, shallowMount } from '@vue/test-utils'
import { describe, it, expect } from 'vitest'
import UserCard from '@/components/UserCard.vue'

describe('UserCard', () => {
  it('renders the user name', () => {
    const wrapper = mount(UserCard, {
      props: { userId: '1', name: 'Alice' },
    })
    expect(wrapper.text()).toContain('Alice')
  })
})
```

- `mount` — full render including child components. Use by default.
- `shallowMount` — stubs all child components. Use only when child components cause test noise (e.g. they make HTTP calls or have complex setup).

### Mount Options

```typescript
mount(MyComponent, {
  props: { label: 'Save' },
  slots: { default: '<span>Content</span>' },
  global: {
    plugins: [router, pinia],
    stubs: { BaseIcon: true },          // stub by name
    provide: { [themeKey as symbol]: ref('dark') },
  },
})
```

---

## Querying the DOM

Prefer queries that reflect how the user sees the component:

```typescript
wrapper.find('button')                      // CSS selector
wrapper.findAll('li')
wrapper.findComponent(BaseButton)           // by component definition
wrapper.findComponent({ name: 'BaseButton' })

wrapper.text()                              // all text content
wrapper.html()                              // full HTML string
wrapper.get('input').element.value          // DOM element access
wrapper.attributes('disabled')             // attribute value or undefined
wrapper.classes()                           // array of class names
```

Use `get` instead of `find` when the element must exist — it throws a useful error if missing, rather than returning `null`.

---

## Events and Emits

```typescript
// Trigger DOM events
await wrapper.find('button').trigger('click')
await wrapper.find('input').setValue('hello')   // sets value + triggers input + change

// Assert emitted events
expect(wrapper.emitted('select')).toBeTruthy()
expect(wrapper.emitted('select')).toHaveLength(1)
expect(wrapper.emitted('select')![0]).toEqual(['42'])

// Multiple emissions
const emissions = wrapper.emitted('update') as [number][]
expect(emissions[0][0]).toBe(1)
expect(emissions[1][0]).toBe(2)
```

---

## Async Behavior

Vue updates the DOM asynchronously. After triggering events or changing reactive state, wait for the DOM update:

```typescript
import { nextTick } from 'vue'
import { flushPromises } from '@vue/test-utils'

// After triggering events — nextTick is enough
await wrapper.find('button').trigger('click')
await nextTick()
expect(wrapper.find('.result').text()).toBe('done')

// After async operations (fetch, store actions) — flushPromises
await wrapper.find('button').trigger('click')
await flushPromises()          // resolves all pending promises
expect(store.items).toHaveLength(3)
```

Rule: use `nextTick` for DOM reactions, `flushPromises` when async operations (API calls, store actions) must complete.

---

## Testing Props and Computed Output

```typescript
it('shows primary style for primary variant', () => {
  const wrapper = mount(BaseButton, { props: { variant: 'primary' } })
  expect(wrapper.classes()).toContain('btn--primary')
})

it('is disabled when loading', () => {
  const wrapper = mount(BaseButton, { props: { loading: true } })
  expect(wrapper.attributes('disabled')).toBeDefined()
})

it('renders slot content', () => {
  const wrapper = mount(BaseButton, { slots: { default: 'Click me' } })
  expect(wrapper.text()).toBe('Click me')
})
```

---

## Mocking Pinia Stores

```typescript
import { setActivePinia, createPinia } from 'pinia'
import { useProductStore } from '@/stores/useProductStore'
import { vi } from 'vitest'

beforeEach(() => {
  setActivePinia(createPinia())
})

it('calls store.load on mount', async () => {
  const store = useProductStore()
  store.load = vi.fn().mockResolvedValue(undefined)

  mount(ProductList)
  await flushPromises()

  expect(store.load).toHaveBeenCalledOnce()
})

it('renders items from the store', async () => {
  const store = useProductStore()
  store.items = [{ id: '1', name: 'Widget', stock: 5 }]

  const wrapper = mount(ProductList)
  expect(wrapper.findAll('[data-testid="product-item"]')).toHaveLength(1)
})
```

- `setActivePinia(createPinia())` in `beforeEach` — gives each test a fresh store instance.
- Mutate store state directly in tests — no need to dispatch actions.
- Spy on actions with `vi.fn()`.

---

## Mocking HTTP

Use `vi.mock` to mock the API module, not the `fetch` primitive:

```typescript
import { vi } from 'vitest'
import { usersApi } from '@/api/users'

vi.mock('@/api/users', () => ({
  usersApi: {
    list: vi.fn(),
    get: vi.fn(),
  },
}))

it('loads users on mount', async () => {
  vi.mocked(usersApi.list).mockResolvedValue([
    { id: '1', name: 'Alice', email: null, role: 'viewer' },
  ])

  const wrapper = mount(UserList)
  await flushPromises()

  expect(wrapper.findAll('[data-testid="user-row"]')).toHaveLength(1)
})
```

Mock at the API module boundary — not `fetch` directly. This keeps tests decoupled from the HTTP library.

---

## Testing Composables

Composables that only use reactivity can be tested without mounting a component:

```typescript
import { useAsync } from '@/composables/useAsync'
import { vi } from 'vitest'

it('sets isLoading during execution', async () => {
  const fn = vi.fn().mockResolvedValue('result')
  const { data, isLoading, execute } = useAsync(fn)

  expect(isLoading.value).toBe(false)
  const promise = execute()
  expect(isLoading.value).toBe(true)
  await promise
  expect(isLoading.value).toBe(false)
  expect(data.value).toBe('result')
})

it('captures error on failure', async () => {
  const fn = vi.fn().mockRejectedValue(new Error('oops'))
  const { error, execute } = useAsync(fn)

  await execute()
  expect(error.value).toBe('oops')
})
```

For composables that use `inject`, `useRouter`, or other component-context APIs, wrap in a minimal component:

```typescript
import { defineComponent, h } from 'vue'

function mountComposable<T>(setup: () => T): T {
  let result!: T
  mount(defineComponent({
    setup() { result = setup(); return () => h('div') },
  }))
  return result
}
```

---

## Testing Vue Router

```typescript
import { createRouter, createMemoryHistory } from 'vue-router'
import { routes } from '@/router'

function buildRouter(initialPath = '/') {
  const router = createRouter({ history: createMemoryHistory(), routes })
  router.push(initialPath)
  return router
}

it('redirects to login when not authenticated', async () => {
  const router = buildRouter('/dashboard')
  const wrapper = mount(App, { global: { plugins: [router, createPinia()] } })
  await router.isReady()
  await flushPromises()

  expect(router.currentRoute.value.name).toBe('login')
})
```

Use `createMemoryHistory()` in tests — no actual browser URL, no side effects.

---

## Naming and Organisation

- File: alongside source as `<Component>.spec.ts` or in `__tests__/<Component>.test.ts`.
- `describe` block matches the component or composable name.
- `it` describes behavior: `it('emits select when item is clicked')`, not `it('calls onClick')`.
- One assertion per test when possible. Multiple assertions are fine when they validate a single behavior.
- No shared mutable state between tests — reset in `beforeEach`.

---

## What Not to Test

- Implementation details: internal ref values, method names, component instance properties.
- Vue internals: don't assert on `_vnode`, `$options`, or private properties.
- The framework itself: don't test that `v-if` works.
- Third-party library behavior: trust Pinia, Vue Router, and Zod to work correctly.

Test the **public contract**: what the component renders, what it emits, what the store returns.
