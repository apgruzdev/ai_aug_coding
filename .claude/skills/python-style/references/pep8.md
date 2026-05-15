# PEP 8 — Condensed Rule Reference

Source: https://peps.python.org/pep-0008/. This file is rules only — examples stripped. For Correct/Wrong code blocks illustrating non-obvious cases, see `examples.md` in this directory. For the full PEP 8 with rationale, see the source URL.

**Override hierarchy:** project-specific style > PEP 8 > personal preference. Don't break backwards compatibility just to comply.

**Reasons to ignore a rule:** (1) following it reduces readability; (2) surrounding code already breaks it; (3) code predates the rule; (4) older Python compatibility required.

---

## Code Layout

### Indentation
- 4 spaces per level. Spaces only (Python 3 forbids mixing tabs and spaces).
- Continuation lines: either align with opening delimiter, or use a hanging indent (+4 spaces, **no arguments on the first line**).
- Closing brace/bracket/paren on multi-line constructs: align with first non-whitespace of the last line, OR with the first character of the line that started the construct. Pick one per file.
- Multi-line `if` conditions: PEP 8 takes no position on how to distinguish the condition continuation from the body. Add a comment, or extra indent on the continuation.
- For visual examples of all the above, see `examples.md` § Indentation.

### Maximum line length
- **79 characters** for code, **72** for docstrings and comments.
- Teams may extend to **99** for code if they wish — but keep docstrings/comments at 72.
- Prefer implicit continuation inside `()`, `[]`, `{}`. Use backslash only when implicit continuation is unavailable (e.g., `with` statements before Python 3.10).

### Line break around binary operators
- Break **before** the operator (Knuth style). Operator stays at the start of the next line.
- Old "break after" style is discouraged for new code.

### Blank lines
- **2 blank lines** around top-level function and class definitions.
- **1 blank line** around method definitions inside a class.
- Use blank lines sparingly inside functions to separate logical sections.
- Don't put a blank line between a `def`/`class` line and its docstring.

### Source file encoding
- **UTF-8.** No encoding declaration needed in new files (Python 3 default).
- Non-ASCII identifiers allowed but discouraged in the standard library.

### Imports
- **One per line** for `import x`. Multiple names on one line OK with `from x import a, b, c`.
- **Top of file**, after module docstring and `__future__` imports, before module globals.
- **Order**, separated by one blank line: (1) standard library, (2) third-party, (3) local/application.
- **Prefer absolute imports.** Explicit relative (`from .sibling import x`) is acceptable inside packages.
- **No wildcard imports** (`from x import *`) outside `__init__.py` re-exports.
- When importing a class from a module: usually fine to write `from module import ClassName`.

### Module-level dunder names
- `__all__`, `__version__`, `__author__` etc. go after the module docstring and `from __future__` imports, **before** any other imports.

---

## String Quotes
- Pick `'...'` or `"..."` and stick with it per file. No PEP 8 preference.
- Switch to the other style to avoid backslash escaping when one quote appears inside the string.
- Triple-quoted strings: **always `"""..."""`** (matches PEP 257 docstring convention).

---

## Whitespace

For Correct/Wrong examples on every whitespace rule below, see `examples.md` § Whitespace.

### No extra spaces immediately inside
- Brackets, braces, parentheses: `f(x)`, `arr[i]`, `{1, 2}` — not `f( x )`.
- Before a comma, semicolon, or colon: `f(x, y)`, not `f(x , y)`.
- Before the open paren of a call or open bracket of an index: `f(x)`, `arr[i]`.

### One space, not multiple
- Around `=` for assignment, around binary operators, around comparison/boolean operators.
- Around augmented assignments (`+=`, `*=`, etc.).
- **Exception:** when an operator has higher priority, may omit spaces around the lower-priority one for clarity: `hypot2 = x*x + y*y`. Use consistently if used at all.

### Special cases
- **Slice colon** acts like a binary operator: same amount of space on both sides (`a[1:9]`, `a[1:9:3]`, `a[ : x]`). Omitted parts get no extra space.
- **Keyword arguments and defaults:** no spaces around `=` (`f(x=1)`, `def f(x=1):`).
- **Annotated defaults:** *do* use spaces around `=` when an annotation is present (`def f(x: int = 1):`).
- **Function annotation colon:** no space before, one space after (`def f(x: int) -> str:`).
- **Return arrow:** spaces around `->`.

### Never
- Trailing whitespace.
- More than one statement per line separated by `;` (discouraged even for one-liners).

---

## Trailing Commas
- **Mandatory** for single-element tuples: `(1,)`.
- **Recommended** at the end of multi-line collections and parameter lists — produces cleaner diffs when items are added/removed.
- When using trailing commas in a multi-line construct, put the closing brace/bracket/paren on its own line.
- **Forbidden** in single-line constructs except the single-element tuple case.

---

## Naming Conventions

### Styles
- `b` — single lowercase letter
- `B` — single uppercase letter
- `lowercase`, `lower_case_with_underscores`
- `UPPERCASE`, `UPPER_CASE_WITH_UNDERSCORES`
- `CapWords` (aka CamelCase, StudlyCaps). Acronyms keep all caps: `HTTPServerError`.
- `mixedCase` — differs from CapWords only in lowercase first letter
- `Capitalized_Words_With_Underscores` — never use; ugly.
- `_single_leading_underscore` — weak "internal use" indicator
- `single_trailing_underscore_` — avoid clash with Python keyword (`class_`)
- `__double_leading_underscore` — name mangling on class attributes
- `__double_leading_and_trailing__` — "magic" / dunder; never invent your own

### Prescriptive rules

| Element | Convention | Notes |
|---|---|---|
| Package | `lowercase`, prefer short, no underscores if readable | |
| Module | `lower_snake_case` | underscores OK |
| Class, Exception, Type variable | `CapWords` | Exceptions should end in `Error` if they are errors |
| Function, variable, method, instance attribute | `lower_snake_case` | |
| Constant | `UPPER_SNAKE_CASE` | module level |
| Method first arg | `self` (instance), `cls` (class) | |
| Type variable | `CapWords`, short | `T`, `KT`, `VT`, `AnyStr` |
| Non-public method / attribute | `_leading_underscore` | |
| Name-mangled | `__double_leading` (no trailing) | only when needed inside a class hierarchy |

### Forbidden
- Single character names `l`, `O`, `I` (look like `1`, `0`, `1`).
- Inventing new dunder names (`__myname__`).

### Public vs internal
- A public name is one a user of the module is expected to use. Document it in `__all__`.
- Internal names get a leading underscore.
- `from M import *` imports only names listed in `__all__`; if `__all__` is absent, imports everything not starting with `_`.

---

## Programming Recommendations

For Correct/Wrong examples illustrating each rule, see `examples.md` § Programming Recommendations.

### Comparisons
- Compare to singletons (`None`, `True`, `False`) with `is` / `is not`, never `==`.
- Never `if x == None:` — write `if x is None:`.
- Don't compare booleans to `True`/`False` with `==`: `if active:`, not `if active == True:`.
- Use `is not` instead of `not ... is`.
- Use `isinstance(obj, T)`, not `type(obj) == T` or `type(obj) is T`.

### Truthiness
- `if seq:` / `if not seq:` for sequences and collections, not `if len(seq) == 0:` or `if seq == []:`.

### Exceptions
- Catch specific exceptions. `except SomeError:`, not bare `except:`.
- Bare `except:` catches `KeyboardInterrupt` and `SystemExit` — forbidden. If you really mean "catch all", write `except Exception:` and comment why.
- When defining exceptions: inherit from `Exception` (not `BaseException`).
- Exception class names end in `Error` if they represent an error.
- Use `raise X from Y` to chain exceptions and preserve context. Use bare `raise` to re-raise.
- Don't `except Exception: pass` silently. Log or re-raise.

### Resource management
- Use `with` for files, locks, network connections, and any context-managed resource.
- Don't rely on `__del__` or manual `close()`.

### Function design
- **Never use mutable default arguments.** `def f(x=[]):` is a footgun. Use `def f(x=None): if x is None: x = []`.
- **Be consistent with return.** Either all paths return a value, or none do. If a function may return early without a value, write explicit `return None`.
- **Lambdas** only for one-shot callbacks (`key=lambda r: r.timestamp`). For named functions, use `def`.

### String operations
- Use `''.join(parts)`, not repeated `+=` in a loop.
- Use `str.startswith()` / `str.endswith()` instead of slicing for prefix/suffix checks.

### Other
- For `print` and similar: don't compare values with `==` when an `is`-style identity check is needed.
- Use `.lower()` / `.casefold()` for case-insensitive comparison, not `re` with `IGNORECASE`.
- Object equality: prefer `==` for value comparison, `is` for identity.

### Function annotations (PEP 484)
- Use type hints on public APIs.
- Space rules: no space before `:`, one space after (`x: int`). Spaces around `->`.

### Variable annotations (PEP 526)
- `x: int = 0` — space after `:`, spaces around `=`.
- Class-level annotations without assignment: `x: int` — no `=` at all.

---

## References (in the source PEP 8)

- PEP 7 — C code style
- PEP 257 — Docstring conventions
- PEP 484 — Type hints
- PEP 526 — Variable annotations
