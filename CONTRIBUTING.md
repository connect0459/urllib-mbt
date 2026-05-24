# Contributing

## Prerequisites

- [MoonBit toolchain](https://www.moonbitlang.com/download/) — `moon` CLI

## Setup

```sh
git clone https://github.com/connect0459/urllib.mbt
cd urllib.mbt
moon update
moon build
```

### pre-commit hooks

Install [pre-commit](https://pre-commit.com/) and set up the hooks:

```sh
pip install pre-commit   # or: brew install pre-commit
pre-commit install
```

To run all hooks manually:

```sh
pre-commit run --all-files
```

## Development workflow

| Command | Purpose |
| :--- | :--- |
| `moon test` | Run all tests (native backend) |
| `moon test --target wasm-gc` | Run tests on a specific backend |
| `moon fmt` | Format all source files |
| `moon check` | Type-check without building |
| `moon info` | Regenerate `.mbti` interface files |

Before opening a pull request:

```sh
moon fmt && moon check && moon test && moon info
git diff src/**/*.mbti  # review interface changes
```

## Testing guidelines

This project follows **Red → Green → Refactor** (Detroit-school TDD):

- Write a failing test first, then implement.
- Use real objects; mocks are only permitted at external boundaries.
- Test names describe **what business rule** is verified, not how.

Run tests across all backends to confirm cross-target compatibility:

```sh
moon test --target js
moon test --target wasm
moon test --target wasm-gc
moon test --target native
```

## Commit format

```text
<type>(<scope>): <subject>
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `tidy`, `test`, `chore`, `ci`, `perf`

**Scope**: package name when the change targets a specific package (`url`,
`urlpattern`); omit for project-wide changes.

**Subject**: imperative mood, 72 characters max, no trailing period.

Examples:

```text
feat(url): add make_relative helper
fix(urlpattern): handle empty pathname in exec_init
tidy(url): name UTF-16 surrogate pair encoding constants
```

## Pull request process

1. Fork the repository and create a branch: `feature/xxx`, `fix/xxx`, `docs/xxx`.
2. Follow the Red → Green → Refactor cycle.
3. Run `moon fmt && moon check && moon test && moon info` and commit any resulting diffs.
4. Open a pull request — the CI matrix tests `js`, `wasm`, `wasm-gc`, and `native`.

## Code style

- No code comments unless the **why** is genuinely non-obvious.
- Prefer immutability; avoid mutable state unless necessary.
- Enforce layer boundaries: internal packages (`percent_encoding`, `idna`, `host`) are
  not part of the public API and must not be re-exported.
- All user-facing strings (test names, error messages, doc comments) must be in **English**.
