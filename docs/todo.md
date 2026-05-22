# todo - uri

Current state: **611/611 WPT success cases pass (100%)**  
Coverage: **314 unit tests pass. 9 uncovered lines in 4 files.**  
- 1 placeholder (`cmd/main/main.mbt`)  
- 4 `panic()` assertions (unreachable invariants)  
- 4 defensive guards (parser/idna)  
WPT failure rejection: 275/275 (100%).  
WPT getters: 611/611. WPT origin: 399/399. WPT searchParams: 9/9.  
WPT stripping: 270/270 (all setter C0-char cases).  
WPT urlencoded-parser: 35/35. WPT percent-encoding: 14/14 (7 query + 7 fragment).  
WPT url-statics-canparse: 4/4. WPT url-statics-parse: 4/4. WPT url-tojson: 1/1.  
WPT urlsearchparams-append: 3/3. WPT urlsearchparams-constructor: 14/14.  
WPT urlsearchparams-delete: 4/4. WPT urlsearchparams-foreach: 2/2.  
WPT urlsearchparams-get: 2/2. WPT urlsearchparams-getall: 2/2.  
WPT urlsearchparams-has: 3/3. WPT urlsearchparams-set: 2/2.  
WPT urlsearchparams-size: 2/2. WPT urlsearchparams-sort: 8/8.  
WPT urlsearchparams-stringifier: 13/13.  
WPT toascii: 87/87.  
WPT IdnaTestV2: 2670/2670 (100%).

---

## Coverage gaps — action plan

Result of `moon coverage analyze` (65 uncovered lines, 9 files).
`src/cmd/main/main.mbt` (placeholder `println`) and ~5 logically dead defensive
branches in `parser.mbt` / `host.mbt` are excluded from the plan.

### B — `try_nfc_compose` unreached branches (8 lines in `src/idna/idna.mbt`)

These specific Unicode compositions were not triggered by the WPT/IDNA fixture
data. Implementation is correct; tests just need input that exercises each pair.

- [x] **B1** Add whitebox test: `A` + U+0300 (grave) → À (U+00C0)
- [x] **B2** Add whitebox test: `A` + U+0308 (diaeresis) → Ä (U+00C4)
- [x] **B3** Add whitebox test: `O` + U+0308 → Ö (U+00D6)
- [x] **B4** Add whitebox test: `U` + U+0308 → Ü (U+00DC)
- [x] **B5** Add whitebox test: `S` + U+0302 (circumflex) → Ŝ (U+015C)
- [x] **B6** Add whitebox test: `Y` + U+0307 (dot above) → Ẏ (U+1E8E)
- [x] **B7** Add whitebox test: Greek Ο (U+039F) + U+0301 (acute) → Ό (U+038C)
- [x] **B8** Add whitebox test: `o` + U+0301 → ó (U+00F3)

### C — Untested edge cases (~35 lines across 7 files)

#### C-types: `src/types.mbt` (2 lines)

- [x] **C-types-1** `UrlPath==`: test `Segments != Opaque` (cross-variant mismatch)
- [x] **C-types-2** `Show for UrlParseError`: assert formatted string contains message

#### C-host: `src/host/host.mbt` (10 lines)

- [x] **C-host-1** `Show for HostParseError`: assert formatted string contains message
- [x] **C-host-2** `parse_host("[::1"` (no closing `]`) → `HostParseError`
- [x] **C-host-3** `domain_has_forbidden_char`: U+FFFD in domain → rejected
- [x] **C-host-4** `domain_has_forbidden_char`: U+FDD0 (nonchar) in domain → rejected
- [x] **C-host-5** `domain_has_forbidden_char`: U+FFFE in domain → rejected
- [x] **C-host-6** `domain_has_forbidden_char`: U+00A0 (NBSP) in domain → rejected
- [x] **C-host-7** `parse_ipv4("1.256")` → `HostParseError` (last part too large)
- [x] **C-host-8** `parse_ipv4("256.1.1.1")` → `HostParseError` (octet > 255)
- [x] **C-host-9** `parse_hex_u64` with invalid hex digit → `HostParseError`
- [ ] **C-host-10** `parse_ipv6` with empty IPv4 octet → dead code (guard checks digit before loop)

#### C-punycode: `src/idna/punycode.mbt` (6 lines)

- [x] **C-pny-1** `punycode_digit_value` uppercase `A` → digit 0 (not error)
- [x] **C-pny-2** `punycode_decode("")` → `IdnaParseError("punycode: empty input")`
- [x] **C-pny-3** `punycode_decode` with non-ASCII char before `-` delimiter → error
- [x] **C-pny-4** `punycode_decode` crafted input that overflows code point → error
- [x] **C-pny-5** `punycode_decode` crafted input yielding surrogate → error
- [x] **C-pny-6** `punycode_encode([])` → `IdnaParseError("punycode: empty input")`

#### C-idna: `src/idna/idna.mbt` (5 lines)

- [x] **C-idna-1** `domain_to_ascii("")` → `IdnaParseError("empty domain")`
- [ ] **C-idna-2** Non-ASCII label with IDNA-disallowed code point (V7 path) → dead code (forbidden check fires first)
- [ ] **C-idna-3** `xn--` label whose Punycode decodes to non-NFC form → dead code (NFC preserves length invariant)
- [ ] **C-idna-4** `xn--` label with C0 control char in decoded output → dead code (status-4 check fires first)
- [ ] **C-idna-5** Mapping returns `None` in `idna_mapping_lookup` → dead code (table is complete)

#### C-parser: `src/parser.mbt` (4 lines)

- [x] **C-parser-1** `[::1]:` (IPv6 with empty port) → port `None`
- [x] **C-parser-2** `[::1]x` (invalid char after IPv6) → `UrlParseError`
- [x] **C-parser-3** `..` segment at `?`/`#` stop in opaque-path-free URL → trailing `/`
- [ ] **C-parser-4** `copy_path_from` with opaque-path base → dead code (`Relative` state always has Segments base)

#### C-pe: `src/percent_encoding/percent_encoding.mbt` (1 line)

- [x] **C-pe-1** `percent_encode_opaque_path_at_stop("")` → `""`

#### C-serial: `src/serializer.mbt` (6 lines)

- [x] **C-serial-1** `file:` URL with `host == None`: `href()` produces `file:/.//path`
- [x] **C-serial-2** Special-scheme URL with `host == None`: `origin()` → scheme-based origin
- [x] **C-serial-3** `blob:` URL where inner path is `Segments` → origin (non-empty and empty)

#### C-setters: `src/setters.mbt` (11 lines)

- [x] **C-set-1** `shorten_path_segs` on `file:` URL with single Windows-drive segment → no-op
- [x] **C-set-2** `split_host_port("[" …)` with no closing `]` → returns `(s, None)`
- [x] **C-set-3** `set_protocol` where parsed scheme is empty (e.g., input `:`)  → no-op (first guard catches it)
- [x] **C-set-4** `set_protocol`: `file:` → non-file with non-empty, non-localhost host → scheme converts
- [x] **C-set-5** `set_pathname` with single-dot segment at EOF → trailing `""`
- [x] **C-set-6** `set_pathname` for `file:` URL where first segment is Windows drive letter
- [x] **C-set-7** `set_host`/`set_hostname` on `file:` URL with non-localhost host → kept
- [x] **C-set-8** `set_hostname` with `[::1]extra` (extra chars after IPv6 bracket) → no-op

---

## Refactor: Package & File Structure (completed: `7487afdc`)

Goal: clarify file responsibilities and test-to-implementation correspondence by
extracting IDNA into a dedicated sub-package and splitting overloaded files.

### Step A — Create `src/idna/` sub-package

- [x] **A1** Create `src/idna/moon.pkg`
- [x] **A2** `git mv src/idna_status.mbt src/idna/idna_status.mbt`
- [x] **A3** `git mv src/idna_mapping.mbt src/idna/idna_mapping.mbt`
- [x] **A4** `git mv src/combining_mark.mbt src/idna/combining_mark.mbt`
- [x] **A5** `git mv src/punycode.mbt src/idna/punycode.mbt`
- [x] **A6** `git mv src/punycode_wbtest.mbt src/idna/punycode_wbtest.mbt`
- [x] **A7** Create `src/idna/idna.mbt` with `domain_to_ascii` and all IDNA helpers

### Step B — Wire `src/` to the new sub-package

- [x] **B1** Add `"connect0459/uri/idna" @idna` to `src/moon.pkg`
- [x] **B2** `src/host.mbt` calls `@idna.domain_to_ascii`
- [x] **B3** `tools/gen_idna_mapping.py` outputs to `src/idna/`
- [x] **B4** `tools/gen_combining_mark.py` outputs to `src/idna/`

### Step C — Move IPv4/IPv6 parsers into `src/host.mbt`

- [x] **C1** Move `parse_ipv6`
- [x] **C2** Move `parse_ipv4`, `parse_ipv4_number`
- [x] **C3** Move `parse_decimal_u64`, `parse_hex_u64`, `parse_octal_u64`

### Step D — Reorganize test files

- [x] **D1** `src/parser_test.mbt` — URL-parsing tests
- [x] **D2** `src/setters_test.mbt` — setter tests
- [x] **D3** `src/uri_test.mbt` trimmed to getter edge cases + static API
- [x] **D4** `src/search_params_test.mbt` (renamed from `url_search_params_test.mbt`)

---

## Refactor: Extract `percent_encoding` and `host` sub-packages

Goal: align package graph with rust-url's architecture. `hex_digit_value`,
`percent_decode`, and UTF-8 helpers are currently shared by both `host.mbt`
and `search_params.mbt` — extracting them into a dedicated sub-package removes
the duplication and enables the `host` sub-package split.

### Target package graph

```text
connect0459/uri/idna              — IDNA (no deps)           [done]
connect0459/uri/percent_encoding  — percent encode/decode (no deps)
connect0459/uri/host              — Host type + parsing/serialization
                                    deps: @idna, @pe
connect0459/uri                   — URL parser/API
                                    deps: @host, @pe
```

### File-to-test correspondence (after refactor)

| Implementation | Test file(s) |
| :--- | :--- |
| `src/percent_encoding/percent_encoding.mbt` | `src/percent_encoding_wpt_test.mbt` (moved) |
| `src/host/host.mbt` | `src/host/host_test.mbt` (new unit tests) |
| `src/parser.mbt` | `src/parser_test.mbt` |
| `src/serializer.mbt` | `src/uri_getters_wpt_test.mbt` |
| `src/setters.mbt` | `src/setters_test.mbt`, `src/uri_setters_wpt_test.mbt` |
| `src/search_params.mbt` | `src/search_params_test.mbt`, `src/urlsearchparams_wpt_test.mbt` |
| `src/uri.mbt` | `src/uri_test.mbt` |

### Step P — Extract `src/percent_encoding/` sub-package

Move all of `src/percent_encode.mbt` to a new sub-package. Zero external deps.

- [x] **P1** Create `src/percent_encoding/moon.pkg` (empty import block)
- [x] **P2** Create `src/percent_encoding/percent_encoding.mbt` — moved from
  `src/percent_encode.mbt`; encode-set predicates and `percent_encode` stay
  private; 11 utility functions made `pub`
- [x] **P3** Delete `src/percent_encode.mbt`
- [x] **P4** Update `src/moon.pkg`: add `"connect0459/uri/percent_encoding" @pe`
- [x] **P5** Update all call-sites in `src/` to use `@pe.` prefix:
  - `parser.mbt`: all `percent_encode_*` calls
  - `host.mbt`: `percent_decode`, `@pe.hex_digit_value`,
    `percent_encode_opaque_path` (replaces raw `percent_encode(…, is_c0)`)
  - `setters.mbt`: all `percent_encode_*` calls
  - `search_params.mbt`: `hex_digit_value`, `char_to_utf8_bytes`,
    `utf8_bytes_to_string`, `percent_encode_byte`
- [x] **P6** `src/percent_encoding_wpt_test.mbt` stays in `src/` — it depends on
  `@uri.parse` so moving it to the sub-package would create a circular dependency

### Step H — Extract `src/host/` sub-package

- [x] **H1** Create `src/host/moon.pkg`:

  ```json
  import {
    "connect0459/uri/idna" @idna,
    "connect0459/uri/percent_encoding" @pe,
  }
  ```

- [x] **H2** Create `src/host/host.mbt` — move from `src/host.mbt` and
  `src/parser.mbt` (after Step C):
  - `Host` enum (move from `src/types.mbt`)
  - `serialize_host`, `serialize_ipv4`, `serialize_ipv6`
  - `nibble_to_lower_hex`, `uint_to_lower_hex`, `find_ipv6_compress`
  - `parse_host`, `parse_opaque_host`
  - `is_forbidden_host_cp`, `domain_has_forbidden_char`, `ends_in_number`,
    `split_on_char`
  - `parse_ipv4`, `parse_ipv4_number`, `parse_ipv6`
  - `parse_decimal_u64`, `parse_hex_u64`, `parse_octal_u64`
  - Update all `@idna.*` and `@pe.*` call-sites
  - Added `Host::empty_domain()` factory fn (MoonBit external enum constructors
    are pattern-match-only; factory fn needed for construction from `src/`)
- [x] **H3** Delete `src/host.mbt`
- [x] **H4** In `src/types.mbt`: remove `Host` enum definition; add
  `pub type Host = @host.Host` to re-export the type for public API consumers
  (generates `pub using @host {type Host}` in `.mbti`)
- [x] **H5** Update `src/moon.pkg`: add `"connect0459/uri/host"`
- [x] **H6** Update call-sites in `src/`:
  - `parser.mbt`: `parse_host` → `@host.parse_host` with
    `@host.HostParseError(msg) => raise UrlParseError(msg)` conversion;
    `Host::Domain("")` → `@host.Host::empty_domain()`
  - `serializer.mbt`: `serialize_host` → `@host.serialize_host`
  - `setters.mbt`: `safe_parse_host` uses `@host.parse_host`;
    `Host::Domain("")` → `@host.Host::empty_domain()`

### Step V — Verify

- [x] **V1** `moon check` — no errors
- [x] **V2** `moon test` — all test counts unchanged (270/270)
- [x] **V3** `moon info && moon fmt` — `.mbti` diffs show:
  - new `src/percent_encoding/pkg.generated.mbti`
  - new `src/host/pkg.generated.mbti`
  - `src/pkg.generated.mbti` loses `Host` enum definition; gains
    `pub using @host {type Host}` re-export; `Url.host` type is now `@host.Host?`
- [x] **V4** Commit each step separately: `refactor(percent_encoding): ...`,
  `refactor(host): ...`

---

## Phase 1 — Static utilities (completed)

- [x] **`can_parse(url, base?)`** — `src/uri.mbt`
  Returns `Bool` instead of raising. WHATWG `URL.canParse()` equivalent.

- [x] **`parse_maybe(url, base?)`** — `src/uri.mbt`
  Returns `Url?` instead of raising. WHATWG `URL.parse()` equivalent.

- [x] **`Url::to_json()`** — `src/uri.mbt`
  Alias for `href()`. WHATWG `URL.toJSON()` equivalent.

---

## Phase 2 — URLSearchParams (completed)

WHATWG `URLSearchParams` interface. Implemented in `src/search_params.mbt`;
tested in `src/url_search_params_test.mbt`.

### Type and constructor

- [x] `pub struct UrlSearchParams` with mutable `list : Array[(String, String)]`
- [x] `UrlSearchParams::new() -> UrlSearchParams`
- [x] `UrlSearchParams::from_string(s: String) -> UrlSearchParams`
  - Strips leading `?`
  - Splits on `&`, splits each pair on first `=`
  - Replaces `+` with space, then percent-decodes (application/x-www-form-urlencoded)

### Operations

- [x] `append(name, value)` — add pair at end
- [x] `delete(name)` — remove all pairs with name
- [x] `delete_entry(name, value)` — remove all pairs with exact (name, value)
- [x] `get(name) -> String?` — first value for name
- [x] `get_all(name) -> Array[String]` — all values for name
- [x] `has(name) -> Bool` — any pair with name
- [x] `has_entry(name, value) -> Bool` — any pair with exact (name, value)
- [x] `set(name, value)` — replace all; if none, append
- [x] `sort()` — stable sort by name using UTF-16 code unit order
- [x] `size() -> Int` — number of pairs
- [x] `to_string() -> String` — application/x-www-form-urlencoded serialization
- [x] `iter() -> Iter[(String, String)]`
- [x] `for_each((String, String) -> Unit)`

### Key implementation notes - 1

- `url_form_decode`: `+`→space, then percent-decode (lenient: invalid `%XX` passed through)
- `url_form_encode`: space→`+`, safe chars literal, else `%XX`; safe = `*-._ 0-9 A-Z a-z`
- `sort()` uses UTF-16 code unit comparison via `compare_utf16` (stable)
- `has_entry` / `delete_entry` = two-argument form from WHATWG spec

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

- [x] **IDNA / Punycode** (`host.mbt` — `domain_to_ascii`, `punycode.mbt`)  
  Full Punycode (RFC 3492) implemented in `src/punycode.mbt`.  
  `domain_to_ascii` Phase 2: per-label encode non-ASCII labels to ACE form (`xn--`),  
  validate existing `xn--` labels via decode, reject IDNA-forbidden codepoints before encode.  
  Fixed 4 WPT success cases: 607/611 → 611/611 (100%).  
  Remaining 6 failure cases (`xn--pokxncvks`) require IDNA validation tables — out of scope.

- [x] **WPT toascii: 87/87** (`src/toascii_wpt_test.mbt`)  
  Full UTS#46 domain-to-ascii WPT test suite. Implemented in multiple passes:  
  • Expanded `is_idna_forbidden_cp`: nonchars, space-like, C0 control, BIDI formats, Arabic  
    end-of-ayah, interlinear annotation, IDS chars, Tags block, specific disallowed chars.  
  • Phase 1 ignored chars: U+00AD, U+200B, U+2060, U+FEFF, U+180E, U+034F, U+206B.  
  • Phase 1 char mappings: U+0341→U+0301, U+2F868→U+36FC, U+1E9E→U+00DF, U+04C0→U+04CF,  
    U+2183→U+2184, U+09DC→[U+09A1, U+09BC] (NFC decomposition exclusion).  
  • NFC composition (`nfc_compose`/`try_nfc_compose`): targeted pairs for `=`/`<`/`>`+U+0338.  
  • Post-decode xn-- validation: decoded chars checked via `is_idna_forbidden_cp`.  
  • CONTEXTJ: `validate_contextj` requires ZWJ (U+200D) to follow a virama (CCC=9).  
  • BIDI: `validate_bidi` rejects RTL labels (Arabic/Hebrew) mixed with basic Latin chars.

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

## URL Setters — Completed

### Design

- `Url` remains immutable; all setters return a new `Url` value.
- Setter signatures: `Url::set_<name>(self, value: String) -> Url`
  (exception: `set_href` raises `UrlParseError` on invalid input)

### WPT: setters_tests.json, 278 cases — **278/278 pass**

- [x] Fix `search()` / `hash()` getters for empty-string `Some("")` case
- [x] `set_href(value)` — 1 WPT case
- [x] `set_protocol(value)` — 35 WPT cases
- [x] `set_username(value)` — 13 WPT cases
- [x] `set_password(value)` — 12 WPT cases
- [x] `set_host(value)` — 67 WPT cases
- [x] `set_hostname(value)` — 48 WPT cases
- [x] `set_port(value)` — 27 WPT cases
- [x] `set_pathname(value)` — 33 WPT cases
- [x] `set_search(value)` — 16 WPT cases
- [x] `set_hash(value)` — 26 WPT cases

### Key implementation notes - 2

- `src/setters.mbt`: all 10 setter methods + helper functions
- `strip_ascii_tabs_newlines`: setters strip only `\t`/`\n`/`\r` (NOT leading/trailing C0 or space),
  matching WHATWG basic URL parse with state override behaviour
- `hostname()` serializer: IPv6 includes `[...]` brackets (matches WHATWG)
- `url_can_have_credentials`: rejects `Domain("")` (empty host) and `file:` scheme
- File URL special cases: `localhost` host → `""`, port forbidden, empty host settable
- `set_pathname("")` with host: produces `Segments([])` (not `Segments([""])`)
- `set_port("")`: clears port (original empty); stripped-to-empty → no-op (keep existing)

---

## Phase 3 — WPT URL getter tests (completed)

Extended WPT test coverage to verify all URL property getters against WHATWG spec
test vectors. Implemented in `src/uri_getters_wpt_test.mbt`.

- [x] **WPT getter tests** — 611/611 cases: `protocol`, `username`, `password`,
  `hostname`, `host`, `port`, `pathname`, `search`, `hash`
- [x] **WPT origin tests** — 399/399 cases: `origin` getter for all URL types
- [x] **`blob:` URL origin** (`serializer.mbt` — `Url::origin`)
  `blob:https://example.com:443/` → `https://example.com` (http/https inner only)
  Fixed by parsing the blob URL's opaque path as an inner URL; only http/https
  schemes yield a non-null origin per WHATWG spec.

---

## Phase 5 — URL.search_params getter (completed)

WHATWG `URLSearchParams` integration with `Url`. Implemented in `src/uri.mbt`
and `src/search_params.mbt`. Tested in `src/uri_test.mbt` and appended to
`src/uri_getters_wpt_test.mbt`.

- [x] **`Url::search_params(self) -> UrlSearchParams`** — returns a snapshot of
  the URL's query parsed as `UrlSearchParams` without stripping a leading `?`.
  - No query (`None`) → empty `UrlSearchParams`
  - Empty query (`Some("")`) → empty `UrlSearchParams`
  - `??a=b&c=d` → query=`?a=b&c=d` → `%3Fa=b&c=d` (leading `?` is data, not stripped)
- [x] **Internal `parse_urlencoded`** — extracted from `from_string` into a
  package-private function that parses without any leading-`?` stripping.
- [x] **WPT searchParams: 9/9 cases** — all WHATWG test vectors pass.

### Key difference from `from_string`

`from_string("?a=b")` strips the leading `?` (constructor behavior).
`search_params()` passes the raw query string directly to `parse_urlencoded`
(URL association behavior per WHATWG spec).

---

## Phase 7 — WPT percent-encoding tests (completed)

WHATWG `percent-encoding.window.js` — UTF-8 encoding cases from
`resources/percent-encoding.json`. Tested in `src/percent_encoding_wpt_test.mbt`.
Non-UTF-8 encoding variants (big5, euc-kr, windows-1252, etc.) are out of scope
because the WHATWG URL parser always uses UTF-8.

- [x] **WPT percent-encoding/query: 7/7** — Unicode chars percent-encoded in URL query
- [x] **WPT percent-encoding/fragment: 7/7** — fragment always UTF-8 encoded

No implementation changes required; existing `percent_encode_query` and
`percent_encode_fragment` already handled all cases correctly.

---

## Phase 6 — WPT urlencoded-parser tests (completed)

WHATWG `urlencoded-parser.any.js`: 35 test vectors for `URLSearchParams` construction
from `application/x-www-form-urlencoded` strings. Tested in
`src/urlencoded_parser_wpt_test.mbt`.

- [x] **WPT urlencoded-parser: 35/35 cases** — all pass.
- [x] **`utf8_bytes_to_string` fix** (`percent_encode.mbt`) — added continuation-byte
  validation (`(b & 0xC0) == 0x80`) for 2/3/4-byte sequences. Without this,
  `%C2x` decoded to U+00B8 instead of U+FFFD + `x` because `x` (0x78) was
  incorrectly consumed as a continuation byte.

### Key cases covered

| Input | Expected output |
| :--- | :--- |
| `%C2` | `[("�", "")]` — incomplete 2-byte seq |
| `%C2x` | `[("�x", "")]` — invalid continuation byte |
| `%FE%FF` | `[("��", "")]` — 0xFE/0xFF never valid in UTF-8 |
| `%EF%BB%BF=…` | `[("﻿", "…")]` — BOM round-trips correctly |
| `b=%%2a` | `[("b", "%*")]` — lone `%` passes through, `%2a` decodes |
| `a=a+b+c+d` | `[("a", "a b c d")]` — `+` → space |

---

## Phase 4 — WPT url-setters-stripping tests (completed)

WHATWG `url-setters-stripping.any.js`: control-character handling for all setters.
Tested: U+0000 (NULL), U+0009 (TAB), U+000A (LF), U+000D (CR), U+001F (US)
× leading/middle/trailing positions × 2 schemes (https, wpt++) × all setter props.

- [x] `set_protocol` with C0 chars — 20/20 cases: stripped (TAB/LF/CR) → scheme changes;
  others (0x00/0x1F) → scheme unchanged (non-alpha fails grammar)
- [x] `set_username` / `set_password` — 30/30 each: all chars percent-encoded (no stripping)
- [x] `set_host` / `set_hostname` — 30/30 each: stripped → changes; 0x00 → rejected (keep original);
  0x1F + https → rejected; 0x1F + non-special → `%1F` encoded via opaque host
- [x] `set_port` — 30/30: stripped → parses past char; others → parse stops at non-digit
- [x] `set_pathname` / `set_search` / `set_hash` — 30/30 each: stripped → stripped; others → encoded

All 270 stripping test cases pass; implementation already compliant.

---

## Phase 8 — WPT static methods and URLSearchParams operation tests (completed)

WPT conformance tests for `URL.canParse`, `URL.parse`, `URL.toJSON`, and all
`URLSearchParams` operation test suites. Implemented in
`src/url_statics_wpt_test.mbt` and `src/urlsearchparams_wpt_test.mbt`.

JS-specific cases omitted: `undefined`/`null` coercion, `DOMException`, `FormData`,
live URL↔searchParams bidirectional sync (requires mutable `Url`).

- [x] **WPT url-statics-canparse: 4/4** — `can_parse` with opaque/hierarchical
  non-special URLs, invalid-port https, and relative-with-base.
- [x] **WPT url-statics-parse: 4/4** — `parse_maybe` returns `Some`/`None`
  correctly; relative URL resolves to expected href.
- [x] **WPT url-tojson: 1/1** — `to_json()` returns the URL href.
- [x] **WPT urlsearchparams-append: 3/3** — same name, empty strings, multiple.
- [x] **WPT urlsearchparams-constructor: 14/14** — string edge cases, NUL byte
  (`\u{0000}` / `%00`), U+2384 COMPOSITION SYMBOL, U+1F4A9 PILE OF POO (4-byte
  UTF-8 `%f0%9f%92%a9`), `+` and `%20` parsing.
- [x] **WPT urlsearchparams-delete: 4/4** — basics, duplicates, two-argument
  `delete_entry`.
- [x] **WPT urlsearchparams-foreach: 2/2** — ordered iteration, empty params.
- [x] **WPT urlsearchparams-get: 2/2** — basics including empty-key and
  empty-value lookups.
- [x] **WPT urlsearchparams-getall: 2/2** — multiple values, `set` collapses to
  one.
- [x] **WPT urlsearchparams-has: 3/3** — basics, after delete, two-argument
  `has_entry`.
- [x] **WPT urlsearchparams-set: 2/2** — replaces first, removes duplicates.
- [x] **WPT urlsearchparams-size: 2/2** — size after delete and append.
- [x] **WPT urlsearchparams-sort: 8/8** — all Unicode sort cases: U+FFFC/U+FFFD
  ordering, ligature ﬃ (U+FB03) vs emoji 🌈 (U+1F308 → surrogate D83C), combining
  marks (é / e+U+0301 / e+U+FFFD), long stable sort, emoji pair (🌈 < 💩 via
  D83C < D83D).
- [x] **WPT urlsearchparams-stringifier: 13/13** — all encoding cases (space,
  `+`, `%`, `=`, `&`, `*-._`, NUL `%00`, emoji `%F0%9F%92%A9`, comma `%2C`),
  roundtrip, and newline non-normalization (`%0A`, `%0D`).

---

## Phase 9 — WPT IdnaTestV2 (completed)

WHATWG IDNA V2 compliance test suite. 2670 test cases (792 success + 1878 expected
failure). **2670/2670 pass (100%).** Tested in `src/idna_v2_wpt_test.mbt`;
fixture at `resources/IdnaTestV2.json` (Unicode 17.0.0).

### Implementation

- [x] **IDNA mapping & status tables** — generated from `IdnaMappingTable.txt`
  (Unicode 17.0.0) via `tools/gen_idna_mapping.py`. Produces:
  - `src/idna_status.mbt`: sorted (start, end, status_code) ranges with binary
    search (`idna_status_code`). Status codes: 0=valid 1=ignored 2=mapped
    3=deviation 4=disallowed 5=disallowed_STD3_valid 6=disallowed_STD3_mapped.
  - `src/idna_mapping.mbt`: per-codepoint mapping target arrays
    (`idna_mapping_lookup`).
- [x] **Phase 1 mapping rewrite** (`host.mbt` — `domain_to_ascii`) — replaced
  ad-hoc per-codepoint mapping with table-driven UTS#46 processing:
  UseSTD3ASCIIRules=false (per WHATWG URL host parser; STD3_mapped → mapped,
  STD3_valid → valid), Transitional_Processing=false (deviation treated as
  valid). Removed `unicode_lowercase` ad-hoc table.
- [x] **NFC composition: iterative + Hangul LVT** (`host.mbt` — `nfc_compose`,
  `try_nfc_compose`) — now applies composition iteratively so a composed result
  can compose again with the next code point. Added Hangul LV+T → LVT
  composition (U+11A8..U+11C2 trailing jamo).
- [x] **V6 leading combining mark** — generated full Unicode 16.0.0 Mark
  (Mn|Mc|Me) ranges via `tools/gen_combining_mark.py` →
  `src/combining_mark.mbt` (`is_combining_mark_table`). Used in both
  Phase 2 (non-ASCII labels) and post-Punycode-decode validation.
- [x] **V7 IDNA-disallowed code point check** — after Punycode decode of
  `xn--` labels, each decoded code point must have IDNA status 0/3/5
  (valid, deviation, or disallowed_STD3_valid). Same check applied in the
  Phase 2 non-ASCII encode path for defense in depth.

### Files generated by tooling

- `tools/gen_idna_mapping.py` → `src/idna_status.mbt`, `src/idna_mapping.mbt`
- `tools/gen_combining_mark.py` → `src/combining_mark.mbt`

---

## Done

- [x] **`src/` layout migration** — Added `"source": "src"` to `moon.mod.json`
  and moved all source files under `src/`. Public module name `connect0459/moon_uri`.

- [x] **Module rename `moon_uri` → `uri`** — Renamed module to `connect0459/uri`
  to match the repository directory name `uri.mbt`. Updated all source file names,
  test aliases, and `.mbti` interface files.
