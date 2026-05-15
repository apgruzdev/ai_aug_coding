---
name: python-typing
description: Authoritative guide for writing Python type hints using the modern, unified syntax from PEPs 484, 526, 544, 585, 604, and 695. Use this skill whenever writing, reviewing, or refactoring Python code that involves type annotations — including function signatures, variable annotations, generic classes, protocols, type aliases, or any `from typing import …` line. Trigger even when the user does not say "types" explicitly: if the code has annotations or asks for "modern", "PEP-compliant", "strict", or "well-typed" Python, use this skill. Also trigger when migrating legacy `typing.List`/`typing.Dict`/`Union[X, Y]`/`Optional[X]` to modern syntax, when configuring mypy/pyright, or when writing `.pyi` stubs.
---

# Python Typing (PEPs 484 / 526 / 544 / 585 / 604 / 695)

This skill consolidates Python's typing PEPs into a single set of rules. **Target Python ≥ 3.12** (full PEP 695 support); fall back gracefully for older versions when the user asks.

Read `EXAMPLES.md` (sibling file) when you need a concrete worked example for any construct below — every section here has a matching example block there.

---

## Core principles

1. **Annotations are for static checkers, not the runtime.** They have no effect on program behavior beyond being stored in `__annotations__`. Never write code that depends on annotation values at runtime unless explicitly asked.
2. **Prefer the newest syntax the target Python version supports.** Modern syntax is shorter, has fewer imports, and reads better. Drop down to legacy forms only when targeting older interpreters.
3. **Annotate the public surface; let inference do the rest.** Always annotate function parameters and return types and module/class-level variables. Local variables only need annotations when inference cannot recover the intended type (empty containers, conditional assignment, narrowing).
4. **Annotate `__init__` with `-> None`.** Unannotated `__init__` is skipped by checkers.
5. **`self` and `cls` are not annotated** unless using a self-type pattern (see Protocols).

---

## Version-keyed feature matrix

When generating code, default to the highest tier available. If the user signals an older target, drop to the appropriate row.

| Feature                                 | Syntax                          | Min Python | PEP |
| --------------------------------------- | ------------------------------- | ---------- | --- |
| Function & return annotations           | `def f(x: int) -> str:`         | 3.0        | 484 |
| Variable annotations                    | `x: int = 0`                    | 3.6        | 526 |
| Protocols (structural typing)           | `class P(Protocol): ...`        | 3.8        | 544 |
| Builtin generics (`list[int]`)          | `list[int]`, `dict[str, int]`   | 3.9        | 585 |
| Union with `\|`                         | `int \| str`, `T \| None`       | 3.10       | 604 |
| PEP 695 generics (`class C[T]`)         | `class C[T]:`, `def f[T](...)` | 3.12       | 695 |
| `type` statement for aliases            | `type Vec[T] = list[T]`         | 3.12       | 695 |

For 3.9–3.11 code that still needs `X | Y` style, use `from __future__ import annotations` — this makes all annotations strings and lets newer syntax appear without being evaluated.

---

## PEP 585 — Use built-in collections, not `typing.List` etc.

Since 3.9, every standard collection accepts `[…]` directly. Importing `List`, `Dict`, `Tuple`, `Set`, `FrozenSet`, `Type`, etc., from `typing` is deprecated.

- Use `list[int]`, `dict[str, int]`, `tuple[int, ...]`, `set[str]`, `type[User]`.
- For abstract types, import from `collections.abc`: `Iterable`, `Iterator`, `Mapping`, `MutableMapping`, `Sequence`, `Callable`, `Awaitable`, etc. — NOT from `typing`.
- Empty tuple is `tuple[()]`. Homogeneous variable-length tuple is `tuple[int, ...]`.

The reason: a single hierarchy is easier to teach and removes a class of import bookkeeping. Imports from `typing` for these names will likely be removed in a future release.

---

## PEP 604 — Use `X | Y`, not `Union[X, Y]` or `Optional[X]`

Since 3.10:

- `int | str` replaces `Union[int, str]`.
- `T | None` replaces `Optional[T]`. Always write `T | None` explicitly — implicit `Optional` from a `None` default is not assumed by checkers.
- Works in `isinstance(x, int | str)` and `issubclass(...)` too (but parameterized generics like `list[int]` still cannot be used in `isinstance`).
- Order does not matter for equality: `int | str == str | int`.

Avoid mixing styles within a single project. If the codebase uses `Union[...]`, match it; if it uses `|`, use `|`.

---

## PEP 526 — Variable annotations

Syntax: `name: Type = value`, `name: Type` (no value), or `name: Type; name = value` (equivalent).

Rules:
- One space after `:`, no space before. One space on each side of `=`. (`x: int = 0`, not `x:int=0` or `x : int = 0`.)
- Annotating a local variable forces it to be local for the entire function (avoids `UnboundLocalError` confusion — checker can flag use-before-assignment).
- **No tuple-unpacking annotations:** `x, y: int` is invalid. Annotate ahead: `x: int; y: int; x, y = pair`.
- **No annotations on `for` or `with` targets:** annotate the variable on a prior line.
- **No chained assignment annotations:** `x: int = y = 1` is disallowed.
- At module/class scope, the annotation expression is evaluated; at function scope it is not.

### ClassVar

Inside a class body, wrap class-level (shared) variables in `ClassVar` to tell checkers "do not set this on instances":

```python
class Starship:
    captain: str = 'Picard'                 # instance attribute with default
    damage: int                             # instance attribute (set in __init__)
    stats: ClassVar[dict[str, int]] = {}    # truly class-level
```

`ClassVar` cannot contain a type variable. Import from `typing`.

Instance attributes may be declared either in the class body (preferred — easier for readers and checkers to discover) or annotated in `__init__` as `self.x: T = ...`.

---

## PEP 695 — Modern generics (Python 3.12+)

This is the **preferred** way to declare generic functions, classes, and aliases. Stop reaching for `TypeVar` and `Generic[T]` first.

```python
# Generic function — T is scoped to this function only
def first[T](items: Sequence[T]) -> T:
    return items[0]

# Generic class — no Generic[T] base needed
class Box[T]:
    def __init__(self, value: T) -> None:
        self.value = value

# Generic type alias — replaces TypeAlias
type Vector[T] = list[tuple[T, T]]

# Bounded type parameter
def longest[T: Sized](a: T, b: T) -> T: ...

# Constrained type parameter (two or more types in a tuple literal)
def concat[S: (str, bytes)](x: S, y: S) -> S:
    return x + y

# Variadic and ParamSpec
class Pipeline[*Ts, **P]: ...
```

Key consequences:

- **No `Generic[T]` base class** — it's implied, and including it explicitly is an error.
- **No `TypeVar('T')` call** — the `[T]` syntax declares it; the name is local to the construct.
- **Variance is inferred** by the type checker from how `T` appears in the class body. Do not declare `covariant=True` / `contravariant=True` manually unless using the legacy `TypeVar` form for backward compatibility.
- **`type` statement is lazy:** the right-hand side of `type Alias = ...` is only evaluated when `Alias.__value__` is accessed, so forward references and recursion work without quotes:
  ```python
  type RecursiveList[T] = T | list[RecursiveList[T]]
  ```
- **Bounds and constraints are lazily evaluated** — quoted forward references still allowed but rarely needed.
- **Do not mix old `TypeVar` with new `[T]` in the same construct.** It's fine to keep legacy `TypeVar`s in a module that also uses new-style elsewhere, but a single class/function should pick one.

Fall back to PEP 484 `TypeVar` + `Generic` only when targeting Python < 3.12 (see EXAMPLES.md for the side-by-side).

---

## PEP 544 — Protocols (structural / duck typing)

When a function only needs "anything with a `.close()` method" or "anything iterable that also has `__len__`", use a `Protocol` instead of an ABC. Classes match by structure — no explicit inheritance required.

```python
from typing import Protocol

class SupportsClose(Protocol):
    def close(self) -> None: ...

def close_all(items: Iterable[SupportsClose]) -> None:
    for item in items:
        item.close()
```

Any class with a compatible `close` method satisfies `SupportsClose` — no `(SupportsClose)` base needed. Define methods with `...` as body (or `raise NotImplementedError` if `@abstractmethod`). Method bodies in protocols ARE type-checked.

### Rules and idioms

- **Protocol attributes:** declare with PEP 526 syntax inside the class body. Attributes assigned only via `self.foo` in a method body are NOT protocol members.
- **Generic protocols:** combine with PEP 695 — `class Comparable[T](Protocol): def __lt__(self, other: T) -> bool: ...`.
- **Callback protocols:** define a `__call__` method to type complex callables that `Callable[[...], ...]` cannot express (keyword arguments, overloads, variadics).
- **`@runtime_checkable`** lets `isinstance(obj, MyProtocol)` work, but only checks for attribute presence — not signatures. Use sparingly; prefer static checking.
- **Modules can satisfy protocols:** a module is treated as having the protocol's methods minus `self`. Useful for plug-in configuration objects.
- **A protocol cannot extend a non-protocol class.** All bases must be protocols (or `Protocol` itself).

### Protocol vs ABC

Use a protocol when the consumer should accept "anything shaped like X" without imposing inheritance. Use an ABC when you want to provide default implementations *and* have callers explicitly opt in by subclassing.

---

## PEP 484 — Remaining essentials

Most of PEP 484 has been superseded by the syntax in 526/585/604/695. What remains relevant:

### Special forms

- **`Any`** — assignable to and from every type. Use sparingly; prefer narrower types or `object` when you only need "some value".
- **`object`** — the top type for attribute access (almost nothing is allowed without narrowing).
- **`Never` / `NoReturn`** — return type for functions that always raise or `sys.exit()`. Code after such calls is unreachable.
- **`Literal[...]`** — exact value types: `def set_mode(m: Literal["r", "w", "a"]) -> None`.
- **`Final`** — variables that should not be reassigned (checker-enforced).
- **`ClassVar`** — see PEP 526 section.
- **`cast(T, x)`** — tells the checker to treat `x` as `T`. Zero runtime cost; no actual conversion. Use when you have proven a narrower type the checker cannot infer.
- **`NewType('UserId', int)`** — creates a distinct nominal type from a base. Implicit `UserId → int`, explicit `int → UserId` required. Almost zero runtime cost.
- **`TYPE_CHECKING`** — `False` at runtime, `True` to the checker. Wrap imports that are only needed for annotations to break import cycles and avoid runtime cost. With `from __future__ import annotations`, all annotations become strings and no runtime import is needed at all.
- **`@overload`** — multiple type signatures for one function. In runtime modules, follow N overloaded stubs with one real implementation. In `.pyi` stubs, no implementation is needed.

### Generators and coroutines

- Generator: `Generator[YieldT, SendT, ReturnT]` or `Iterator[YieldT]` if `send`/return are not used.
- Async generator: `AsyncGenerator[YieldT, SendT]` or `AsyncIterator[YieldT]`.
- Async function: annotate the awaited value, e.g. `async def fetch() -> str:` returns `str` (not `Coroutine[..., ..., str]`).

### Forward references

With `from __future__ import annotations` (recommended for any code targeting 3.7+), all annotations are strings and forward references work automatically. Without it, use quoted strings: `def f(node: 'Node') -> None: ...`.

### Stubs (`.pyi`)

- Stubs contain only signatures. Bodies are `...`.
- `.pyi` takes precedence over `.py` for the type checker.
- Variable annotations without value are allowed: `BUFFER_SIZE: int`.

---

## Idiom checklist (use this when writing or reviewing)

- `list[int]`, not `List[int]`.
- `int | None`, not `Optional[int]`.
- `int | str`, not `Union[int, str]`.
- Abstract bases from `collections.abc`, not `typing`.
- Python ≥ 3.12: `class C[T]:` / `def f[T](...):` / `type A[T] = ...`.
- Python 3.9–3.11: `from __future__ import annotations` to unlock newer syntax in annotations.
- Annotate every public function parameter and return value.
- Annotate `__init__` with `-> None`.
- Use `Protocol` for structural typing, not ABC inheritance.
- Use `Literal` for fixed-string flags, not bare `str`.
- Use `cast()` only when you know more than the checker; never to silence a real error.
- Use `TYPE_CHECKING` blocks for import cycles.
- Never write `Optional[T] = None` together — the `= None` is the default value, not the type.

---

## Worked examples

Full, runnable examples for every section above are in `EXAMPLES.md` (sibling file). Read it when you need to verify the exact syntax for a less common pattern — protocols with self-types, variadic generics, callback protocols, overloads with constrained type vars, the lazy-evaluation behavior of `type` statements, etc.
