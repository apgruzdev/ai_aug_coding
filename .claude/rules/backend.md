---
paths:
  - "backend/**/*"
---

# Backend Development Standards

## Python

- **Target: Python 3.11+**. Never suggest compatibility shims for older versions unless explicitly asked.
- **Type hints are mandatory** on all function signatures and class attributes. No untyped public API.
- Use **modern generics syntax** (PEP 585/604): `list[str]`, `dict[str, int]`, `int | None` — never `List`, `Optional`, `Union` from `typing`.
- Use **Protocols** (PEP 544) for structural typing instead of ABC when the interface is small.
- **Docstrings required** on all public functions, classes, and modules. Google style. First line: imperative mood, one sentence. Args/Returns/Raises sections when non-obvious.
- **Explicit over implicit** (PEP 20): no magic, no hidden side effects, no clever one-liners that sacrifice clarity.
- Never use bare `except:` — always catch specific exception types.
- Prefer **dataclasses** or **Pydantic models** over plain dicts for structured data.
- Use **`match/case`** (PEP 634) for multi-branch dispatch instead of long `if/elif` chains.

## Code Quality Toolchain

- Package manager: **uv** (`uv pip install`, `uv run`)
- Formatter + Linter: **ruff** (`ruff format` + `ruff check` incl. security rules, line length 88, configured in `pyproject.toml`)
- Type checker: **mypy** (strict mode, configured in `pyproject.toml`)
- Tests + Coverage: **pytest** + **pytest-cov** (coverage report on every test run, configured in `pyproject.toml`)
- Before declaring code complete: mentally verify it passes `ruff check` + `ruff format --check` + `mypy --strict`

## Testing

- Framework: **pytest**. No unittest-style classes unless wrapping legacy code.
- Test files: `tests/test_<module>.py`, mirroring the source tree.
- Test functions: `test_<behaviour>` — name what the test asserts, not what it calls.
- Use **fixtures** (`@pytest.fixture`) for shared setup; avoid module-level state.
- Each test must be independent — no shared mutable state, no order dependency.
- Test the public API, not implementation details. Refactoring internals must not break tests.

## AI-Assisted Development Rules

- **Always write types first**, then implementation — types are the spec.
- When generating a new module or class: produce docstring → signature → body, in that order.
- When refactoring: preserve existing public API signatures unless change is explicitly requested.
- **Do not add dependencies** without noting them explicitly (`# requires: httpx`).
- Prefer **stdlib** over third-party for simple tasks.
- When in doubt about intent: **ask one clarifying question** rather than guess and produce wrong code.

## Project Context

<!-- Project-level CLAUDE.md overrides this section. Leave empty in global file. -->