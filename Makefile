.PHONY: lint lint-backend lint-frontend
.PHONY: typecheck typecheck-backend typecheck-frontend
.PHONY: test test-backend test-frontend
.PHONY: check

lint-backend:
	ruff check backend/
	ruff format --check backend/

lint-frontend:
	cd frontend && pnpm lint && pnpm format:check

lint: lint-backend lint-frontend

typecheck-backend:
	cd backend && mypy .

typecheck-frontend:
	cd frontend && pnpm typecheck

typecheck: typecheck-backend typecheck-frontend

test-backend:
	cd backend && pytest

test-frontend:
	cd frontend && pnpm test

test: test-backend test-frontend

check: lint typecheck test
