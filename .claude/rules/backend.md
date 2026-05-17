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

Async tests (`asyncio_mode = "auto"` is configured — no `@pytest.mark.asyncio` decorator needed):
```python
async def test_create_user(async_client: AsyncClient) -> None:
    response = await async_client.post("/users", json={"name": "Alice"})
    assert response.status_code == 201
```

FastAPI test client fixture pattern:
```python
@pytest.fixture
async def async_client(app: FastAPI) -> AsyncGenerator[AsyncClient, None]:
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        yield client
```

## Stack Decisions

Use these libraries for common tasks. Don't introduce alternatives without a strong reason documented in the PR.

### Web API — FastAPI

- **FastAPI** for all HTTP APIs. Use async handlers by default.
- Organise routes with `APIRouter`; mount routers in `main.py`.
- Use Pydantic models for all request/response schemas — never raw `dict`.
- Use `Depends()` for shared resources: DB sessions, auth, settings.

### Data Validation — Pydantic

Pydantic is the primary tool for all structured data — not just API schemas. Use it at every data boundary:

- **API**: request bodies, response models, query parameters
- **Config**: via `pydantic-settings` (see below)
- **External data**: third-party API responses, file parsing, event payloads
- **Internal domain models**: wherever validation or coercion matters

Rules:
- Use **Pydantic v2**. Never v1 patterns: no `class Config:`, no `.dict()`, no `@validator`.
- Use `model_config = ConfigDict(...)` instead of `class Config`.
- Use `model_dump()` / `model_validate()` instead of `.dict()` / `.from_orm()`.
- Enable `strict=True` to prevent silent type coercion where correctness matters.
- Use `@field_validator` and `@model_validator` for validation logic; keep models declarative.
- ORM → schema: `Model.model_validate(orm_obj, from_attributes=True)`.

### Database — SQLAlchemy 2.0 + Alembic

- Use **SQLAlchemy 2.0** mapped class style — not legacy 1.x `declarative_base()`.
- Use `DeclarativeBase` with full type annotations on columns (`Mapped[int]`, `Mapped[str | None]`).
- Async sessions via `AsyncSession` + `asyncpg` (PostgreSQL) or `aiosqlite` (SQLite).
- **Alembic** for all schema migrations — never `create_all()` in production, never hand-edit schema.
- Keep migrations in `alembic/` at the backend root; every schema change gets a migration.

### Config — pydantic-settings

- One `Settings(BaseSettings)` class per service, loaded from environment variables / `.env`.
- All secrets via environment variables — never hardcoded, never committed.
- Expose settings via `@lru_cache` singleton: `get_settings() -> Settings`.

### Async Patterns

- **Never call blocking I/O in async handlers**: no `requests`, no synchronous `open()`, no sync SQLAlchemy calls. Use `httpx.AsyncClient`, `aiofiles`, `AsyncSession`.
- Initialize shared resources (DB connection pool, HTTP client) in FastAPI lifespan — not at module level:
```python
@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    async with engine.begin() as conn:
        ...  # startup
    yield
    await engine.dispose()  # shutdown
```
- Use `asyncio.gather()` for concurrent independent operations; avoid sequential `await` when parallelism is possible.
- Yield DB sessions via dependency, never share a session across requests:
```python
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session
```

### Logging — structlog

- **structlog** for all logging. No bare `print()` or `logging.getLogger()` in application code.
- Bind request-scoped context (request_id, user_id) at middleware level.
- JSON output in production; pretty-printed in development — control via `LOG_FORMAT` env var.

## AI-Assisted Development Rules

- **Always write types first**, then implementation — types are the spec.
- When generating a new module or class: produce docstring → signature → body, in that order.
- When refactoring: preserve existing public API signatures unless change is explicitly requested.
- **Do not add dependencies** without noting them explicitly (`# requires: httpx`).
- Prefer **stdlib** over third-party for simple tasks.
- When in doubt about intent: **ask one clarifying question** rather than guess and produce wrong code.

## Project Context

<!-- Project-level CLAUDE.md overrides this section. Leave empty in global file. -->