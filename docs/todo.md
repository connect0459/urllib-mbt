# todo - moon_uri

Current state: **542/611 WPT success cases pass (88.7%)**  
All 27 unit tests pass. WPT failure rejection: 167/275 (60.7%).

---

## Fixes (priority order)

### Quick wins

- [ ] **`%2e%2e` trailing slash** (`parser.mbt` — Path state)  
  `https://example.com/aaa/bbb/%2e%2e?query` → got `aaa?query`, want `aaa/?query`  
  After resolving a double-dot segment, push `""` to preserve the trailing slash when `c == Some('/')`.

- [ ] **IPv4 fallback on invalid hex** (`host.mbt` — `parse_host`)  
  `http://0x7f.0.0.0x7g` → currently raises error, want `http://0x7f.0.0.0x7g/` (treat as domain)  
  Wrap the `parse_ipv4` call in a try/catch; on failure return `Host::Domain(ascii_domain)`.

- [ ] **Opaque path encoding** (`parser.mbt` — `OpaquePath` state)  
  `non-special:opaque  ?hi` → got passthrough, want `non-special:opaque %20?hi`  
  Apply the C0 percent-encode set (U+0000–U+001F, >U+007E) plus space to each code point.  
  Also covers: `wow:￿` → `wow:%EF%BF%BF`, `non-special: y` → `non-special:%00y`.

---

### Moderate effort

- [ ] **Multiple `@` in credentials** (`parser.mbt` — Authority state)  
  `https://@@@example` → got `%40%40:%40%40@example/`, want `%40%40@example/`  
  When `at_sign_seen` is already true, the accumulated buffer should be re-percent-encoded
  and prepended to username (everything before last `@` goes into credentials). Fix the
  credential accumulation logic for the repeated-`@` case.

- [ ] **`///` and `////` relative to non-special base** (`parser.mbt`)  
  `///` with base `sc://x/` → got `sc://`, want `sc:///`  
  Leading slashes beyond `//` must be preserved as empty path segments, not collapsed.

- [ ] **Percent-encode set correctness** (`percent_encode.mbt`)  
  `foo://host/ !"$...^...~` — `^` (U+005E) not encoded in path, want `%5E`  
  Review `percent_encode_path_seg` and `percent_encode_userinfo` against WHATWG spec tables.

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
  `https://faß.ExAmPlE/` → want `https://xn--fa-hia.example/`  
  `http://你好你好` → want `http://xn--6qqa088eba/`  
  `http://www.foo。bar.com` → want `http://www.foo.bar.com/` (full-width period)  
  `file://a­b/p` → want `file://ab/p` (soft hyphen U+00AD stripped)  
  Requires UTS#46 mapping table + Punycode encoding. Consider a third-party MoonBit library
  or limit scope to full-width ASCII mapping + soft-hyphen stripping as a partial fix.

---

## Cleanup (after fixes are done)

- [ ] Restore WPT debug output limit: `if failed < 10 { println(...) }`
- [ ] Remove `ERR:` debug printing from the WPT success test
- [ ] Run `moon info && moon fmt`
- [ ] Investigate WPT failure rejection rate (167/275 = 60.7%) — which cases are incorrectly accepted
