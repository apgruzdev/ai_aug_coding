---
name: python-style
description: Apply PEP 8 style and PEP 20 Zen of Python to all Python code. Use whenever Claude writes, edits, refactors, reviews, or generates Python — scripts, modules, packages, type hints, notebook cells, tests, configs. Also use for any question about Python style, naming, formatting, idioms, or "is this Pythonic?". Treat as the default style guide for Python work, even when the user doesn't explicitly ask about style. Especially relevant in Claude Code where the output lands in a real codebase.
---

# Python Style

Apply PEP 8 (mechanics) and PEP 20 (philosophy) to every line of Python.

- For any specific rule not covered below → `references/pep8.md` (full rule set, no examples).
- For visual Correct/Wrong code examples → `references/examples.md` (indentation styles, whitespace cases, Yes/No idioms).
- For commentary on the Zen → `references/pep20.md`.

Load `examples.md` when a rule is non-obvious to apply without seeing code (continuation indents, slice colons, kwargs spacing with vs without annotations, return consistency, narrow `try` blocks).

## The Zen of Python (PEP 20)

```
Beautiful is better than ugly.            Errors should never pass silently.
Explicit is better than implicit.         Unless explicitly silenced.
Simple is better than complex.            In the face of ambiguity, refuse the temptation to guess.
Complex is better than complicated.       There should be one-- and preferably only one --obvious way to do it.
Flat is better than nested.               Although that way may not be obvious at first unless you're Dutch.
Sparse is better than dense.              Now is better than never.
Readability counts.                       Although never is often better than *right* now.
Special cases aren't special enough       If the implementation is hard to explain, it's a bad idea.
  to break the rules.                     If the implementation is easy to explain, it may be a good idea.
Although practicality beats purity.       Namespaces are one honking great idea -- let's do more of those!
```

Apply as tiebreakers: prefer explicit kwargs, flat control flow, standard idioms, raising over guessing.

## Mechanics (PEP 8 essentials)

**Layout.** 4-space indent (never tabs). Lines ≤79 chars, or match project (88 Black, 99 common). 2 blank lines around top-level defs, 1 around methods. Break *before* binary operators. UTF-8, no encoding cookie.

**Imports.** Top of file. Order: stdlib → third-party → local, separated by blank lines. One per line for `import x`. No wildcards. Prefer absolute imports.

**Strings.** One quote style per file. Docstrings always `"""..."""`. Prefer f-strings; use `%`-formatting only in `logger.info("...%s...", x)` to defer formatting.

**Whitespace.** Spaces around binary operators (`a + b`, `x = 1`). **No** spaces around `=` in kwargs/defaults (`f(x=1)`) — but **do** use spaces when an annotation is present (`def f(x: int = 1):`). No spaces inside brackets (`f(x)`, not `f( x )`). No spaces before `,`, `;`, `:`. No trailing whitespace.

**Naming:**

| Element | Convention | Example |
|---|---|---|
| Class, Exception, type alias | `CapWords` | `HttpClient`, `ParseError` |
| Function, method, variable, attribute | `lower_snake_case` | `fetch_user`, `retry_count` |
| Constant | `UPPER_SNAKE_CASE` | `MAX_RETRIES` |
| Module, package | `lower_snake_case` | `data_pipeline` |
| Internal / non-public | `_leading_underscore` | `_cache` |
| Avoid keyword clash | trailing `_` | `class_`, `type_` |
| Don't invent new dunders | `__existing_protocol__` only | `__init__`, `__repr__` |

Never use `l`, `O`, `I` as single-char names. Methods take `self`; classmethods take `cls`. Exception class names end in `Error`.

## Correctness traps (high-leverage)

Not formatting — bugs waiting to happen:

- `is` / `is not` for `None`, `True`, `False`. Never `== None`.
- Never bare `except:`. Catch specific exceptions. Comment any `except Exception:`.
- Use `with` for files, locks, connections — never trust manual `close()`.
- **Never use mutable defaults:** `def f(x=None): x = x or []`, not `def f(x=[])`.
- `isinstance(x, T)`, not `type(x) == T` (subclass-safe).
- `if seq:` / `if not seq:` for emptiness — not `len(seq) == 0`.
- Booleans: `if active:`, not `if active == True:`.
- Chained exceptions: `raise NewError(...) from err` preserves the traceback.
- Type hints (PEP 484): `def f(x: int) -> str:` — space after `:`, spaces around `->`.
- One return convention per function: either every path returns a value, or none do.

## Working style

1. **Read surrounding code first.** Project consistency beats PEP 8. If the file uses single quotes and 99-char lines, match it.
2. **Check the tooling.** `pyproject.toml`, `.ruff.toml`, `setup.cfg`, pre-commit config — that's the actual style guide for that project. Run the formatter rather than hand-formatting.
3. **Don't drive-by-reformat** code you didn't touch. It pollutes diffs.
4. **When you deviate, say why** — in a comment or PR description.

For new projects without tooling: recommend **Ruff** (linter + formatter; supersedes Flake8/isort/Black for most needs).

## When to deviate from PEP 8

In this order: (1) project has its own convention — match it; (2) the rule reduces readability in this specific spot; (3) backwards compatibility prevents the change. Never deviate on the grounds of personal taste.
