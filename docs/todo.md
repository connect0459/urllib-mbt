# todo - uri

Current state: **607/611 WPT success cases pass (99.3%)**  
All 61 unit tests pass. WPT failure rejection: 175/275 (63.6%).

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

- [x] **Windows drive letter in file URLs** (`parser.mbt` — File/FileSlash/FileHost/Path states)  
  File state: detect WDL in remaining input → clear path instead of shortening.  
  FileSlash state: always copy base host; skip drive-segment copy only when WDL detected.  
  FileHost state: when buffer is a WDL, stay in Path state without clearing buffer.  
  Added `chars_start_with_wdl` helper; `|` normalized to `:` in Path state.

- [x] **Non-special `//` path normalization** (`serializer.mbt` — `Url::href`)  
  `non-spec:/a/..//path` → got `non-spec://path`, want `non-spec:/.//path`  
  WHATWG serializer step 5a: when `host == None && path[0] == "" && path.length > 1`,
  prepend `/.` before normal segment serialization to prevent `//` being read as authority.

- [x] **IDNA partial fixes** (`host.mbt` — `domain_to_ascii`)  
  Strip soft hyphen U+00AD and ignored chars (U+200B, U+2060, U+FEFF).  
  Map full-width period U+3002 → `.`, full-width ASCII U+FF01..FF5E → ASCII,  
  mathematical bold A-Z (U+1D400..U+1D419) and a-z (U+1D41A..U+1D433).  
  Raise error on empty domain after stripping. Covers all partial-fix WPT cases (+8).

- [ ] **IDNA / Punycode** (`host.mbt` — `domain_to_ascii`)  
  Full Punycode required for: `https://faß.ExAmPlE/` → `https://xn--fa-hia.example/`,  
  `http://你好你好` → `http://xn--6qqa088eba/`, `ftp://%e2%98%83` → `ftp://xn--n3h/`.  
  Remaining 4 WPT failures. Requires external Punycode library — out of scope for now.

---

## Cleanup (after fixes are done)

- [x] Restore WPT debug output limit: `if failed < 10 { println(...) }`
- [x] Remove `ERR:` debug printing from the WPT success test
- [x] Investigate WPT failure rejection rate (175/275 = 63.6%) — which cases are incorrectly accepted

### WPT failure rejection: investigation findings (100 incorrectly accepted)

| Category | Count | Example | Root cause |
| :--- | ---: | :--- | :--- |
| Percent-encoded forbidden host code points | ~33 | `http://ho%01st/` | %01–%1F/%7F decoded but not rejected |
| Literal control chars stripped from host | ~32 | `http://a\u{0001}b/` | C0/DEL chars silently removed |
| Invalid ACE / xn-- labels | ~8 | `http://a.b.c.xn--pokxncvks` | No Punycode decode validation |
| IPv4 overflow (> 0xFFFFFFFF) | ~6 | `http://4294967296` | 32-bit wrap instead of error |
| Non-character / forbidden Unicode in host | ~7 | `http://GOO\u{00A0}goo.com` | IDNA forbidden chars not checked |
| Full-width `%` sign in host | ~4 | `http://\u{FF05}\u{FF14}\u{FF11}.com` | Full-width `%` maps to valid `%XX` |
| High-byte %-encoding in host | ~4 | `ftp://example.com%80/` | Non-ASCII byte via `%80`/`%A0` accepted |
| Invalid percent encoding in host | ~4 | `file://example%/`, `http://%25` | Incomplete or bare `%` not rejected |
| Empty host with port | ~2 | `sc://:/`, `sc://:12/` | Non-special empty host+port accepted |
| Non-special schemes with empty host + port | ~7 | `data://:443` | Same root cause as above |

Most categories require full IDNA/Punycode support to fix properly. The IPv4 overflow
and empty-host-with-port categories are fixable without IDNA.

---

## Done

- [x] **`src/` layout migration** — Added `"source": "src"` to `moon.mod.json`
  and moved all source files under `src/`. Public module name `connect0459/moon_uri`.

- [x] **Module rename `moon_uri` → `uri`** — Renamed module to `connect0459/uri`
  to match the repository directory name `uri.mbt`. Updated all source file names,
  test aliases, and `.mbti` interface files.
