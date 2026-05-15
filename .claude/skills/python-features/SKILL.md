---
name: python-features
description: Authoritative reference for three modern Python language features — docstring conventions (PEP 257), structural pattern matching with `match`/`case` (PEP 634, Python 3.10+), and exception groups with `try`/`except*` (PEP 654, Python 3.11+). Use this skill whenever writing, reviewing, or refactoring Python code — especially when adding docstrings to functions/classes/modules, refactoring `if`/`elif`/`isinstance` chains into `match` statements, handling errors from `asyncio.gather`/`TaskGroup` or other concurrent code, or whenever the user mentions docstrings, `match`/`case`, pattern matching, `ExceptionGroup`, or `except*`. Apply proactively — do not wait for an explicit citation of a PEP.
---

# Python Features (PEP 257, 634, 654)

A compact reference for three Python features Claude Code should use idiomatically. Each section gives the rules; full code samples live in `examples.md`. Read `examples.md` whenever you are about to write more than a trivial snippet using any of these features — it shows correct patterns and the most common mistakes.

---

## 1. Docstrings (PEP 257)

### Where docstrings go

- Every module, public function, public class, public method, and `__init__` should have one.
- A package is documented in its `__init__.py` module docstring.
- A docstring is the **first statement** of the definition; it becomes `__doc__`.

### Quoting and form

- Always use `"""triple double quotes"""`. Use `r"""..."""` if the docstring contains backslashes.
- **One-line**: opening and closing quotes on the same line, no blank lines around it, phrased as an imperative command ending in a period — `"""Return the pathname of the KOS root directory."""`. Do **not** restate the signature.
- **Multi-line**: a one-line **summary** (fits on one line, imperative mood, ends in a period), then a blank line, then elaboration. Closing `"""` goes on its own line. The summary may sit on the same line as the opening `"""` or on the next line — pick one and be consistent.

### Content guidance

- **Function/method**: summarize behavior; document each argument (one per line), the return value, side effects, exceptions raised, and any calling restrictions. Mark optional arguments. State whether keyword arguments are part of the interface.
- **Class**: summarize behavior; list public methods and instance variables; document the constructor in `__init__`'s docstring. Insert a blank line after the class docstring. For subclasses, summarize differences; use the verb **override** when a method replaces a superclass method without calling it, **extend** when it calls the superclass method.
- **Module**: list the classes, exceptions, and functions exported, with a one-line summary of each.
- **Script** (stand-alone program): the module docstring should be usable as the `-h`/usage message — document function, command-line syntax, environment variables, and files.

### Don't

- Don't write `"""function(a, b) -> list"""` — introspection already provides the signature. State the *effect* and *return value* instead.
- Don't write argument names in uppercase running text — Python is case-sensitive and the names matter for keyword arguments.
- Don't use descriptive mood (`"""Returns the X..."""`); PEP 257 specifies imperative (`"""Return the X..."""`).

See `examples.md` § Docstrings for examples of each form.

---

## 2. Structural Pattern Matching (PEP 634, Python 3.10+)

### Syntax

```
match SUBJECT_EXPR:
    case PATTERN [if GUARD]:
        ...
    case PATTERN:
        ...
```

- `match` and `case` are **soft keywords** — they remain valid identifiers everywhere except where the grammar expects them. Variables named `match` or `case` continue to work.
- A comma-separated subject is built into a tuple: `match a, b:` matches against `(a, b)`.
- Cases are tried top-to-bottom; the **first** successful match (with a truthy guard, if present) runs and the rest are skipped.
- A **guard** (`if EXPR`) runs only after the pattern succeeds and after pattern variables are bound. A falsy guard moves on to the next case (with the side effect that any variables already bound stay bound).
- Names bound by a successful match are **regular local variables** and persist after the `match` block.

### Patterns — what each one does

| Pattern | Form | Behavior |
|---|---|---|
| Literal | `42`, `"text"`, `None`, `True`, `False`, `-1+2j` | `None`/`True`/`False` compared with `is`; everything else with `==`. **F-strings are not allowed.** |
| Capture | bare `NAME` | Always succeeds; binds subject to `NAME`. A name may be bound **only once** in a single pattern (`case x, x:` is rejected). |
| Wildcard | `_` | Always succeeds; binds nothing. `_` is **not** a capture. |
| Value | dotted `name.attr` (e.g. `Color.RED`) | Looks up the name and compares with `==`. Use this — not a bare name — for constants and enums, otherwise it becomes a capture. |
| Group | `(pattern)` | Pure grouping (no comma — a comma makes it a sequence). |
| Sequence | `[a, b, *rest]` or `(a, b, *rest)` | At most one `*name` (or `*_`). Matches `list`, `tuple`, `range`, `array.array`, `collections.deque`, `memoryview`, and any `collections.abc.Sequence` subclass. **Does NOT match `str`, `bytes`, or `bytearray`.** |
| Mapping | `{"k": pattern, **rest}` | Matches `dict`, `mappingproxy`, and `collections.abc.Mapping` subclasses. Extra keys in the subject are **ignored** unless you bind them with `**rest`. Duplicate keys → `ValueError`. **Uses `get()`**, so `defaultdict.__missing__` is **not** triggered. `**_` is disallowed (redundant). |
| Class | `Cls(pos, kw=pat)` | `isinstance(subject, Cls)` must hold. Keyword args match attributes by name. Positional args use `Cls.__match_args__`. For `bool`, `bytearray`, `bytes`, `dict`, `float`, `frozenset`, `int`, `list`, `set`, `str`, `tuple` a single positional matches the **whole subject** (so `int(n)` binds `n = subject`). |
| OR | `a \| b \| c` | Alternatives tried left-to-right. **All alternatives must bind the same names.** Only the last alternative may be irrefutable. |
| AS | `pattern as NAME` | Match pattern, then bind whole subject to `NAME`. `_` is not a valid AS target. |

### Irrefutable cases (catch-alls)

A pattern is **irrefutable** if it always succeeds: capture patterns, the wildcard, irrefutable AS patterns, OR patterns containing an irrefutable alternative, and parenthesized irrefutable patterns. A case with an irrefutable pattern and no guard is an irrefutable case. **At most one** irrefutable case is allowed per `match`, and it **must be last**.

### Working with classes

- Dataclasses and namedtuples get `__match_args__` auto-generated in the order arguments appear in `__init__` (excluding `init=False` fields).
- For other classes, set `__match_args__ = ("name1", "name2", ...)` explicitly to enable positional patterns.
- Class patterns use `isinstance`, so subclasses match.

### Common pitfalls

- Bare unqualified name = capture, not constant. Use `Color.RED` (value pattern) or `case x if x == RED:` (guard) — never `case RED:` when `RED` is meant as a constant.
- `case [x]:` matches a one-element sequence; `case (x):` is a **group pattern** (because there's no comma) and just matches anything, binding `x`. Use `case (x,):` or `case [x]:` if you want a one-element tuple/list.
- `str`, `bytes`, `bytearray` are NOT matched as sequences — match them with class patterns (`case str(s):`) instead.
- Mapping patterns ignore extra keys; this is *intentional* — use `**rest` to capture or refuse them.
- Don't rely on bindings made during a *failed* match — behavior is intentionally unspecified.

See `examples.md` § Pattern Matching for examples organized by pattern type.

---

## 3. Exception Groups and `except*` (PEP 654, Python 3.11+)

### The types

- `ExceptionGroup(message, exceptions)` extends `Exception`. Wraps only `Exception` subclasses.
- `BaseExceptionGroup(message, exceptions)` extends `BaseException`. Can wrap anything — including `KeyboardInterrupt`, `SystemExit`. If all wrapped items are `Exception` subclasses, the `BaseExceptionGroup(...)` constructor returns an `ExceptionGroup` instead.
- `except Exception:` will catch `ExceptionGroup` but **not** `BaseExceptionGroup` (by design — base exceptions stay uncaught).

### When to use them

Use exception groups when **multiple unrelated exceptions** need to propagate together — typical sources are `asyncio.gather`, `asyncio.TaskGroup`, batch-retry code, multiple cleanup handlers (`atexit`, finalizers), and wrappers whose `__exit__` may raise alongside the user's exception. Raising an exception group is an **API-breaking change**; prefer a new API over modifying an existing one.

### `except*` semantics

```python
try:
    ...
except* TypeError as e:
    ...
except* (ValueError, KeyError) as e:
    ...
```

- Each `except*` clause runs **at most once**, receiving an exception **group** containing all matching leaf exceptions from the original group (recursively, preserving structure).
- A single raised group may trigger **multiple** `except*` clauses — one per matching type.
- Clauses are evaluated **in order**; subclasses must come before parents (just like `except`).
- Matching is recursive — `except* TypeError` matches `TypeError`s nested arbitrarily deep inside nested `ExceptionGroup`s.
- A **naked** (non-group) exception raised inside `try` is auto-wrapped in `ExceptionGroup('', [exc])` for handler matching — but propagates **naked** if uncaught.
- **Unhandled** exceptions in the group propagate as a residual group after all clauses run.
- The `e` bound by `except* T as e:` is **ephemeral** — mutating it (adding attributes, etc.) does not persist.

### Forbidden combinations

- Mixing `except:` and `except*:` in the same `try` → **SyntaxError**.
- `except* ExceptionGroup:` or `except* BaseExceptionGroup:` (including in a tuple) → **runtime error** — ambiguous, since `except*` itself wraps in a group.
- `except*:` with no type → **SyntaxError**.
- `continue`, `break`, `return` inside an `except*` block → **SyntaxError** (control flow from one clause must not influence the others).

### Raising from inside `except*`

- Naked `raise` reraises the matched subgroup with original metadata (traceback, cause, context).
- `raise e` reraises with a new traceback (the current frame is added), like in regular `except`.
- Raising **new** exceptions (whether `raise X` or `raise X from y`) chains them — they end up combined with any unhandled/reraised subgroups into a fresh outer `ExceptionGroup` at the end of the `try` statement.
- Exceptions raised in one `except*` clause are **not** caught by later `except*` clauses in the same `try`.

### Inspecting and splitting groups

- `eg.split(condition_or_type)` → `(matching_group, rest_group)`. Either may be `None` if trivial.
- `eg.subgroup(condition_or_type)` → just the matching group, or `None`.
- Both accept a callable predicate, an exception type, or a tuple of types.
- For custom `ExceptionGroup` subclasses, override `derive(self, excs)` so that `split`/`subgroup` return instances of your subclass (and override `__new__`, not `__init__`, to add fields).
- The traceback of an exception group represents the path the group itself travelled; each nested exception has its own `__traceback__`. To walk leaf tracebacks, recurse and concatenate.

### Common pitfalls

- `except* T as e:` always binds `e` to a **group**, not a `T` instance. Use `e.exceptions` or iterate to access the leaves.
- Don't use `except*` to catch group types directly — wrap a `try`/`except ExceptionGroup` around the `try`/`except*` block if you need to handle the residual group.
- Exception groups should be raised by APIs **deliberately**; treat introducing them as a breaking change.

See `examples.md` § Exception Groups for examples of `split`, `subgroup`, `except*` ordering, naked exceptions, and subclassing.

---

## Quick reference: which PEP for what

| Task | PEP | Python version |
|---|---|---|
| Write or improve a docstring | 257 | any |
| Replace `isinstance`/`if-elif` chain with declarative cases | 634 | 3.10+ |
| Destructure dicts/lists/dataclasses safely | 634 | 3.10+ |
| Handle errors from `asyncio.TaskGroup`, `asyncio.gather`, batch operations | 654 | 3.11+ |
| Aggregate cleanup/finalizer errors | 654 | 3.11+ |
