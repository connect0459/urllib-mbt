# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.2] - 2026-06-10

### Miscellaneous

- **docs**: fix broken relative package link in root `README.mbt.md` (#41)
- **ci**: unify test matrix into a single sequential job; deny warnings in check steps (#42)
- **test**: replace deprecated `try?` with `try/catch/noraise` (#43)

## [0.4.1] - 2026-06-08

### Miscellaneous

- **docs**: add mooncakes.io docs badge to README
- **docs**: add per-package `README.mbt.md` as the single documentation source for each public package
- **docs**: enable `README.mbt.md` doc-tests via root `moon.pkg`
- **docs**: fix mooncakes.io path resolution for doc rendering
- **chore**: update apm lock; reorder `import` block in `moon.mod`

## [0.4.0] - 2026-06-07

### Miscellaneous

- **repo**: rename repository from `urllib.mbt` to `urllib-mbt`
- **chore**: migrate module layout to flat package structure
- **chore**: expand `just verify` to all four CI backends (`js`, `wasm`, `wasm-gc`, `native`)
- **chore**: bump `moonbitlang/x` from 0.4.43 to 0.4.45
- **ci**: set `persist-credentials: false` on `actions/checkout`
- **docs**: update CONTRIBUTING.md and AGENTS.md to document pre-commit hooks and `just verify` gate

## [0.3.0] - 2026-05-27

### Changed

- **urlpattern**: `UrlPatternInit`, `UrlPatternComponentResult`, and `UrlPatternResult` fields are now private; use getter methods to access values (`input()`, `groups()`, `protocol()`, `pathname()`, etc.)

### Miscellaneous

- **urlpattern**: add benchmark suite covering pattern compilation (`from_string`, `from_init`) and URL matching (`exec_url`, `test_url`)

## [0.2.0] - 2026-05-24

### Changed

- **urlpattern**: `compare_component` / `generate` take a typed `UrlPatternComponent` enum (was `String`)
- **url**: `Url` implements `ToJson` trait instead of exposing a `to_json()` method

### Added

- **url**: `impl Show for UrlSearchParams`

### Removed

- Hide `percent_encoding`, `idna`, and `host` sub-packages under `internal/` (no longer importable)
- **url**: drop the `@url.Host` type re-export
- **url**: privatize fields of `Url` and `UrlSearchParams`
- **url**: privatize `UrlPath` enum constructors

### Performance

- **url**: eliminate O(N²) string concat in credentials parsing
- **url**: reduce allocations in `percent_decode`, `percent_encode`, `UrlSearchParams` sort / serialization
- **url**: add fast paths in `strip_tab_newline`, `is_dot_segment`, `is_single_dot`
- **host / idna**: reduce allocations in hex / numeric helpers and ASCII-only label processing

### Refactored

- **url / urlpattern**: replace C-style loops and mutation blocks with idiomatic MoonBit iteration
- **url / urlpattern**: extract shared utilities (`lower_ipv6_literal`, `strip_leading_char`, `encode_part_str`)
- **host**: eliminate `parse_ipv6` panic path (returns `None` instead)

### Miscellaneous

- **ci**: extend test matrix to `js`, `wasm`, `wasm-gc`, `native`
- **docs**: add GitHub issue and pull request templates

## [0.1.0] - 2026-05-23

### Added

#### URL parsing (`connect0459/urllib/url`)

- `parse(String)` — parses a URL string; raises `UrlParseError` on failure
- `parse_maybe(String, Url?)` — infallible variant; returns `None` on failure
- `parse_with_base(String, Url?)` — parses with an explicit base URL
- `can_parse(String, Url?)` — validity check without allocating a `Url`
- Full WHATWG URL Standard compliance with 100 % WPT pass rate

**Getters**: `href`, `protocol`, `scheme`, `username`, `password`, `hostname`,
`host_str`, `port`, `port_str`, `pathname`, `search`, `hash`, `origin`, `to_json`

**Predicates**: `is_special`, `has_credentials`, `has_opaque_path`, `has_host`,
`has_port`, `has_query`, `has_fragment`, `has_authority`

**Setters** (immutable — each returns a new `Url`): `set_href` (raises),
`set_protocol`, `set_username`, `set_password`, `set_host`, `set_hostname`,
`set_port`, `set_pathname`, `set_search`, `set_hash`

**Path utilities**: `path_segments` iterator; `join` for relative URL resolution

**File URL helpers**: `from_file_path`, `from_directory_path`, `to_file_path`

**Query helpers**: `search_params`, `query_pairs`, `parse_with_params`

**Authority helpers**: `authority`, `domain`, `make_relative`,
`port_or_known_default`

#### URLSearchParams (`connect0459/urllib/url`)

- `UrlSearchParams::from_string(String)` — parses `application/x-www-form-urlencoded` data
- Operations: `get`, `get_all`, `has`, `size`, `append`, `delete`, `set`, `sort`
- Iterators: `iter` (name-value pairs), `keys`, `values`, `entries`

#### IDNA utilities (`connect0459/urllib/url`)

- `domain_to_ascii(String)` — UTS#46 Unicode-to-ACE conversion
- `domain_to_unicode(String)` — ACE-to-Unicode conversion
- Full WPT IdnaTestV2 coverage (2670 / 2670)

#### URLPattern (`connect0459/urllib/urlpattern`)

- `UrlPattern::from_string` — constructs a pattern from a URL pattern string
- `UrlPattern::from_init` — constructs from a `UrlPatternInit` object
- `ignore_case` option for case-insensitive matching
- `test_url` / `test_init` — boolean URL matching
- `exec_url` / `exec_init` — match with captured group extraction
- Compiled pattern accessors: `get_protocol`, `get_username`, `get_password`,
  `get_hostname`, `get_port`, `get_pathname`, `get_search`, `get_hash`
- `has_regexp_groups` — reports whether any component contains a custom regexp group
- `generate` — reconstructs a URL string from a pattern and captured group values
- `compare_component` — specificity ordering for route-priority comparisons

---

[Unreleased]: <https://github.com/connect0459/urllib-mbt/compare/v0.4.2...HEAD>
[0.4.2]: <https://github.com/connect0459/urllib-mbt/compare/v0.4.1...v0.4.2>
[0.4.1]: <https://github.com/connect0459/urllib-mbt/compare/v0.4.0...v0.4.1>
[0.4.0]: <https://github.com/connect0459/urllib-mbt/compare/v0.3.0...v0.4.0>
[0.3.0]: <https://github.com/connect0459/urllib-mbt/compare/v0.2.0...v0.3.0>
[0.2.0]: <https://github.com/connect0459/urllib-mbt/compare/v0.1.0...v0.2.0>
[0.1.0]: <https://github.com/connect0459/urllib-mbt/releases/tag/v0.1.0>
