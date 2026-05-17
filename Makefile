.PHONY: lint typecheck test check

lint:
	ruff check backend/ && ruff format --check backend/
	cd frontend && pnpm lint && pnpm format:check

typecheck:
	cd backend && mypy .
	cd frontend && pnpm typecheck

test:
	cd backend && pytest
	cd frontend && pnpm test

check: lint typecheck test
