# todo - moon_uri

Current state: **568/611 WPT success cases pass (93.0%)**  
All 40 unit tests pass. WPT failure rejection: 167/275 (60.7%).

---

## Fixes (priority order)

### Quick wins

- [x] **`%2e%2e` trailing slash** (`parser.mbt` — Path state)  
  `https://example.com/aaa/bbb/%2e%2e?query` → got `aaa?query`, want `aaa/?query`  
  Removed `is_sep &&` guard so `""` is pushed after dot segments before `?`, `#`, or EOF.

- [x] **IPv4 fallback on invalid hex** (`host.mbt` — `ends_in_number`)  
  `http://0x7f.0.0.0x7g` → was raising error, now returns `http://0x7f.0.0.0x7g/` (treat as domain)  
  Rewrote `ends_in_number` to validate all hex digits; `0x7g` → returns false → treated as domain.

- [x] **Opaque path encoding** (`parser.mbt` — `OpaquePath` state)  
  `non-special:opaque  ?hi` → got passthrough, want `non-special:opaque %20?hi`  
  Apply C0 percent-encode set + trailing-space `%20` rule at `?`/`#` stops.  
  Also fixed: `wow:￿` → `wow:%EF%BF%BF`, `non-special:\u{0000}y` → `non-special:%00y`.

---

### Moderate effort

- [x] **Multiple `@` in credentials** (`parser.mbt` — Authority state)  
  `https://@@@example` → was `%40%40:%40%40@example/`, now `%40%40@example/`  
  Per WHATWG spec: prepend `%40` to buffer only; do NOT reset `password_token_seen`.

- [x] **`///` and `////` relative to non-special base** (`parser.mbt`)  
  `///` with base `sc://x/` → was `sc://`, now `sc:///`  
  Fixed dead-code branch in RelativeSlash state: non-special `//` now goes to Authority state.

- [x] **Percent-encode set correctness** (`percent_encode.mbt`)  
  `foo://host/a^b` — `^` (U+005E) was not encoded in path, now `%5E`  
  Added `0x5E` to `in_path_set`.

---

### Complex

- [ ] **Windows drive letter in file URLs** (`parser.mbt` — File/FileSlash/FileHost/Path states)  
  Multiple sub-cases:
  - `file:c:\foo\bar.html` with file base → `file:///c:/foo/bar.html`  
    (single-slash + drive letter should go to path, not merge with base)
  - `C|/foo/bar` with file base → `file:///C:/foo/bar`  
    (`C|` must be recognized as drive letter and `|` normalized to `:`)
  - `//C|/foo/bar`, `file://C:/`, `file://C|/` → drive letter in authority position  
    (when authority is a Windows drive letter, treat it as a path segment instead)
  - `/c:/foo/bar` with `file:///c:/baz/qux` base → `file:///c:/foo/bar`  
    (path starting with drive letter should replace from drive root, not duplicate it)
  - `//d:`, `//d:/..` with file base → `file:///d:`, `file:///d:/`  
  Read WHATWG spec "file slash state" and "Windows drive letter" notes carefully before starting.

- [ ] **Non-special `//` path normalization** (`parser.mbt` — Path state)  
  `non-spec:/a/..//path` → got `non-spec://path`, want `non-spec:/.//path`  
  After `..` resolves, the `//` that follows must emit an empty segment so the path
  becomes `["", "", "path"]` → `/.//path`, preventing reinterpretation as authority.  
  Also affects relative URLs whose base path contains `/.//`.

- [ ] **IDNA / Punycode** (`host.mbt` — `domain_to_ascii`)  
  Full Punycode: `https://faß.ExAmPlE/` → `https://xn--fa-hia.example/`, `http://你好你好` → `http://xn--6qqa088eba/`  
  Partial fixes implementable without Punycode library:
  - Strip soft hyphen U+00AD and ignored chars (U+200B, U+2060, U+FEFF) from domains
  - Map full-width period U+3002 → `.`
  - Map full-width ASCII U+FF01..U+FF5E → U+0021..U+007E
  These partial fixes cover ~4 additional WPT cases.

---

## Cleanup (after fixes are done)

- [ ] Restore WPT debug output limit: `if failed < 10 { println(...) }`
- [ ] Remove `ERR:` debug printing from the WPT success test
- [ ] Investigate WPT failure rejection rate (167/275 = 60.7%) — which cases are incorrectly accepted

---

## Done

- [x] **`src/` layout migration** — Added `"source": "src"` to `moon.mod.json`
  and moved all source files under `src/`. Public module name
  `connect0459/moon_uri` unchanged.
