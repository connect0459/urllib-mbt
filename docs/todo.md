# todo - uri

Current state: **607/611 WPT success cases pass (99.3%)**  
All 74 unit tests pass. WPT failure rejection: 269/275 (97.8%).

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

- [x] **IPv4 overflow** (`host.mbt` — `parse_ipv4_number`)  
  `http://4294967296` / `http://0x100000000` should fail; currently wraps at 32-bit.  
  Changed `parse_decimal_u64`/`parse_hex_u64`/`parse_octal_u64` to use `UInt64` with
  saturation at 2^32; `parse_ipv4_number` rejects values ≥ 2^32.  
  Fixed 6 WPT failure cases: 175→181 correctly rejected.

- [x] **Empty host with port for non-special schemes** (`parser.mbt` — `parse_host_and_port`)  
  `sc://:/` / `sc://:12/` / `data://:443` should fail; currently accepted.  
  In `parse_host_and_port`, raise error when non-special + colon found + host part empty.  
  Fixed 9 WPT failure cases: 181→190 correctly rejected.

- [x] **Forbidden chars in special URL domain hosts** (`host.mbt` — `domain_has_forbidden_char`)  
  `http://a\u{0001}b/` / `http://ho%01st/` / `ftp://example.com%80/` should fail.  
  Expanded checks: all C0 (0x00-0x1F), DEL (0x7F), `%`, U+FFFD, Unicode nonchars  
  (U+FDD0-U+FDEF, U+XFFFE/U+XFFFF), IDNA-disallowed spaces (U+00A0, U+3000).  
  Also added `xn--` empty-extension label rejection.  
  Fixed 79 WPT failure cases: 190→269 correctly rejected.

---

## Cleanup (after fixes are done)

- [x] Restore WPT debug output limit: `if failed < 10 { println(...) }`
- [x] Remove `ERR:` debug printing from the WPT success test
- [x] Investigate WPT failure rejection rate (175/275 = 63.6%) — which cases are incorrectly accepted

### WPT failure rejection: investigation findings (resolved to 6/275 remaining)

| Category | Count | Fixed? | Root cause |
| :--- | ---: | :--- | :--- |
| Percent-encoded forbidden host code points | ~33 | ✅ | Expanded C0/DEL range in `domain_has_forbidden_char` |
| Literal control chars stripped from host | ~32 | ✅ | Same expansion |
| Invalid ACE / xn-- labels | ~8 | ⚠️ (2 of 8) | `xn--` empty extension rejected; full Punycode needed for rest |
| IPv4 overflow (> 0xFFFFFFFF) | ~6 | ✅ | Fixed in earlier commits |
| Non-character / forbidden Unicode in host | ~7 | ✅ | U+FFFD, nonchars, forbidden spaces added |
| Full-width `%` sign in host | ~4 | ✅ | `%` in domain now rejected |
| High-byte %-encoding in host | ~4 | ✅ | U+FFFD check catches invalid UTF-8 bytes |
| Invalid percent encoding in host | ~4 | ✅ | `%` in domain now rejected |
| Empty host with port | ~2 | ✅ | Fixed in earlier commit |
| Non-special schemes with empty host + port | ~7 | ✅ | Fixed in earlier commit |

**Remaining 6 incorrectly accepted cases** are all invalid `xn--pokxncvks` Punycode labels —
require a Punycode decoder to detect invalid Punycode-encoded strings (out of scope).

---

## Done

- [x] **`src/` layout migration** — Added `"source": "src"` to `moon.mod.json`
  and moved all source files under `src/`. Public module name `connect0459/moon_uri`.

- [x] **Module rename `moon_uri` → `uri`** — Renamed module to `connect0459/uri`
  to match the repository directory name `uri.mbt`. Updated all source file names,
  test aliases, and `.mbti` interface files.
