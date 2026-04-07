# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Orion is a SQL-first, type-safe data access layer for MoonBit, following the Mapper pattern. It aims to combine the strengths of MyBatis (Mapper), sqlx (type safety), and Prisma (engineering).

## Commands

```bash
# Run the CLI entry point
moon run cmd/main

# Format code
moon fmt

# Check code / run pre-commit hook
moon check

# Run tests
moon test
moon test --update  # Update snapshots

# Update package interfaces and format
moon info && moon fmt

# Coverage analysis
moon coverage analyze > uncovered.log

# Git hooks setup
chmod +x .githooks/pre-commit
git config core.hooksPath .githooks
```

## Architecture

```
        ┌────────────────────┐
        │     Orion CLI      │
        │ (generate/migrate) │
        └────────┬───────────┘
                 │
        ┌────────▼───────────┐
        │   SQL / Mapper     │
        │    (*.sql files)   │
        └────────┬───────────┘
                 │
        ┌────────▼───────────┐
        │   Code Generator   │
        │ (types + functions)│
        └────────┬───────────┘
                 │
        ┌────────▼───────────┐
        │   Orion Runtime    │
        │  (pool/tx/log)     │
        └────────┬───────────┘
                 │
           ┌─────▼─────┐
           │ Database  │
           └───────────┘
```

## Project Structure

- **MoonBit packages**: Each directory contains a `moon.pkg` file listing dependencies
- **Test files**: `*_test.mbt` (blackbox) and `*_wbtest.mbt` (whitebox)
- **Module config**: `moon.mod.json` at root
- **Entry point**: `cmd/main/main.mbt` - keep focused, move logic to library packages

## Coding Conventions

- **Block style**: Code blocks separated by `///|`, order is irrelevant
- **Deprecations**: Move deprecated blocks to `deprecated.mbt` in each directory
- **Interface tracking**: Check `.mbti` diff after changes - no change means safe refactoring

## Development Workflow

1. Make changes block by block
2. Run `moon check` to verify
3. Run `moon test` (use `--update` for snapshot changes)
4. Run `moon info && moon fmt` before committing
5. Verify `.mbti` changes are expected

## Database Support Strategy

- v0.1: SQLite (primary)
- v0.2: Postgres
- v0.3: MySQL
