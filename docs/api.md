# API Reference

## Packages

| Package | Import alias | Description |
| :--- | :--- | :--- |
| `connect0459/urllib/url` | `@url` | URL parsing, getters, setters, URLSearchParams, IDNA |
| `connect0459/urllib/urlpattern` | `@urlpattern` | Route matching against URL components |

The sub-packages `percent_encoding`, `idna`, and `host` are internal
implementation details and are not importable by consumers.

---

## `url` package

### Constructors

| Function | Signature | Description |
| :--- | :--- | :--- |
| `parse` | `(String) -> Url raise UrlParseError` | Parse a URL string; raises on failure |
| `parse_maybe` | `(String, Url?) -> Url?` | Infallible variant; returns `None` on failure |
| `parse_with_base` | `(String, Url?) -> Url raise UrlParseError` | Parse with an explicit base URL |
| `can_parse` | `(String, Url?) -> Bool` | Returns `true` if the URL parses successfully |
| `parse_with_params` | `(String, Array[(String, String)]) -> Url raise UrlParseError` | Parse and append query parameters |
| `from_file_path` | `(String) -> Url raise UrlParseError` | Convert a filesystem path to a `file://` URL |
| `from_directory_path` | `(String) -> Url raise UrlParseError` | Like `from_file_path` with a trailing `/`; usable as a base URL |

```moonbit
let url = try! @url.parse("https://user:pass@example.com:8080/path?q=1#frag")

// Infallible — returns None instead of raising
let opt = @url.parse_maybe("not a url", None)          // None

// Validity check
let ok = @url.can_parse("https://example.com", None)   // true

// Parse with base
let base = try! @url.parse("https://example.com/dir/")
let url2 = try! @url.parse_with_base("/page", Some(base))

// Parse with query parameters appended
let url3 = try! @url.parse_with_params(
  "https://example.com/search",
  [("q", "moon"), ("lang", "en")],
)
```

### File URL helpers

```moonbit
// Filesystem path → file:// URL
let url = try! @url.from_file_path("/home/user/file.txt")
println(url.href())  // "file:///home/user/file.txt"

// Directory path (trailing /)
let base = try! @url.from_directory_path("/home/user/")
let rel  = try! base.join("file.txt")
println(rel.href())  // "file:///home/user/file.txt"

// file:// URL → filesystem path
let path = try! url.to_file_path()  // "/home/user/file.txt"
```

---

### `Url` type

```moonbit
pub struct Url { /* private fields */ } derive(Eq, @debug.Debug)
pub impl Show  for Url  // href()
pub impl ToJson for Url // href()
```

#### Getters

| Method | Returns | Description |
| :--- | :--- | :--- |
| `href()` | `String` | Full serialized URL |
| `protocol()` | `String` | Scheme with trailing colon (`"https:"`) |
| `scheme()` | `String` | Scheme without colon (`"https"`) |
| `username()` | `String` | Username (empty string if absent) |
| `password()` | `String` | Password (empty string if absent) |
| `hostname()` | `String` | Host without port |
| `host_str()` | `String` | Host with port if non-default |
| `port()` | `Int?` | Typed port; `None` if absent or default |
| `port_str()` | `String` | Port as string; empty string if absent |
| `port_or_known_default()` | `Int?` | Explicit port or scheme default (80/443/21) |
| `pathname()` | `String` | Path component |
| `search()` | `String` | Query string with leading `?`; empty if absent |
| `query()` | `String?` | Raw query without leading `?`; `None` if absent |
| `hash()` | `String` | Fragment with leading `#`; empty if absent |
| `fragment()` | `String?` | Raw fragment without leading `#`; `None` if absent |
| `origin()` | `String` | Serialized origin |
| `authority()` | `String` | `username:password@host:port` component |

#### Predicates

| Method | Returns | Description |
| :--- | :--- | :--- |
| `is_special()` | `Bool` | `true` for `http`, `https`, `ftp`, `file`, `ws`, `wss` |
| `has_credentials()` | `Bool` | `true` when username or password is non-empty |
| `has_opaque_path()` | `Bool` | `true` for non-hierarchical URLs (e.g. `data:…`) |
| `has_authority()` | `Bool` | `true` when the URL has an authority component |
| `has_host()` | `Bool` | `true` when the URL has a host |
| `has_port()` | `Bool` | `true` when an explicit port is present |
| `has_query()` | `Bool` | `true` when a query string is present |
| `has_fragment()` | `Bool` | `true` when a fragment is present |

#### Authority helpers

| Method | Returns | Description |
| :--- | :--- | :--- |
| `domain()` | `String?` | Registered domain name; `None` for IPs and opaque hosts |
| `make_relative(other: Url)` | `String?` | Relative path from `self` to `other`; `None` if different origins |

```moonbit
let base  = try! @url.parse("https://example.com/a/b/")
let other = try! @url.parse("https://example.com/a/c/d")
println(base.make_relative(other))  // Some("../c/d")
```

#### Path utilities

| Method | Returns | Description |
| :--- | :--- | :--- |
| `path_segments()` | `Iter[String]?` | Iterator over decoded path segments; `None` for opaque-path URLs |
| `join(relative: String)` | `Url raise UrlParseError` | Resolve a relative URL against this URL |

```moonbit
let url = try! @url.parse("https://example.com/a/b/c")
match url.path_segments() {
  Some(iter) => for seg in iter { println(seg) }  // "a", "b", "c"
  None       => println("opaque path")
}

let base     = try! @url.parse("https://example.com/a/b/c")
let resolved = try! base.join("../d")
println(resolved.href())  // "https://example.com/a/d"
```

#### Query helpers

| Method | Returns | Description |
| :--- | :--- | :--- |
| `search_params()` | `UrlSearchParams` | Snapshot of the query string as `UrlSearchParams` |
| `query_pairs()` | `Iter[(String, String)]` | Iterator over decoded name-value pairs |

#### File URL helper

| Method | Returns | Description |
| :--- | :--- | :--- |
| `to_file_path()` | `String raise UrlParseError` | Convert a `file://` URL back to a filesystem path |

#### Setters

All setters return a **new** `Url` — the original is unchanged.

| Method | Signature | Notes |
| :--- | :--- | :--- |
| `set_href` | `(String) -> Url raise UrlParseError` | Raises on invalid input |
| `set_protocol` | `(String) -> Url` | No-op on invalid input |
| `set_username` | `(String) -> Url` | No-op on invalid input |
| `set_password` | `(String) -> Url` | No-op on invalid input |
| `set_host` | `(String) -> Url` | Sets host and port together |
| `set_hostname` | `(String) -> Url` | Sets host only |
| `set_port` | `(String) -> Url` | No-op on invalid input |
| `set_pathname` | `(String) -> Url` | No-op on invalid input |
| `set_search` | `(String) -> Url` | No-op on invalid input |
| `set_hash` | `(String) -> Url` | No-op on invalid input |

```moonbit
let url  = try! @url.parse("https://example.com/old")
let url2 = url.set_pathname("/new").set_search("q=hello")
println(url.href())   // "https://example.com/old"
println(url2.href())  // "https://example.com/new?q=hello"
```

---

### `UrlParseError` type

```moonbit
pub suberror UrlParseError { UrlParseError(String) }
pub impl Show for UrlParseError
```

Raised by `parse`, `parse_with_base`, `parse_with_params`, `from_file_path`,
`from_directory_path`, `set_href`, `join`, and `to_file_path` on invalid input.

---

### `UrlSearchParams` type

```moonbit
pub struct UrlSearchParams { /* private fields */ }
pub impl Show for UrlSearchParams
```

#### UrlSearchParams constructors

| Method | Description |
| :--- | :--- |
| `UrlSearchParams::new()` | Empty params |
| `UrlSearchParams::from_string(String)` | Parse `application/x-www-form-urlencoded` data |

#### Read operations

| Method | Signature | Description |
| :--- | :--- | :--- |
| `get` | `(String) -> String?` | First value for the given name |
| `get_all` | `(String) -> Array[String]` | All values for the given name |
| `has` | `(String) -> Bool` | Whether any entry with the given name exists |
| `has_entry` | `(String, String) -> Bool` | Whether a specific name-value pair exists |
| `size` | `() -> Int` | Total number of entries |

#### Write operations

| Method | Signature | Description |
| :--- | :--- | :--- |
| `append` | `(String, String) -> Unit` | Add a new entry |
| `delete` | `(String) -> Unit` | Remove all entries with the given name |
| `delete_entry` | `(String, String) -> Unit` | Remove a specific name-value pair |
| `set` | `(String, String) -> Unit` | Replace all entries for the name with one value |
| `sort` | `() -> Unit` | Sort entries by name (Unicode code-unit order) |

#### Iteration

| Method | Returns | Description |
| :--- | :--- | :--- |
| `iter()` | `Iter[(String, String)]` | All name-value pairs |
| `entries()` | `Iter[(String, String)]` | Alias for `iter()` |
| `keys()` | `Iter[String]` | Names only |
| `values()` | `Iter[String]` | Values only |
| `for_each((String, String) -> Unit)` | `Unit` | Apply a function to each pair |

#### Output

| Method | Returns | Description |
| :--- | :--- | :--- |
| `to_string()` | `String` | Serialize to `application/x-www-form-urlencoded` format |

```moonbit
let params = @url.UrlSearchParams::from_string("a=1&b=2&a=3")
println(params.get("a"))           // Some("1")
println(params.get_all("a"))       // ["1", "3"]
println(params.has("b"))           // true
println(params.has_entry("a","1")) // true
println(params.size())             // 3

params.append("c", "4")
params.delete("b")
params.set("a", "99")
println(params.to_string())        // "a=99&c=4"

for name, value in params.iter() {
  println("\{name}=\{value}")
}

params.sort()
```

---

### IDNA utilities

| Function | Signature | Description |
| :--- | :--- | :--- |
| `domain_to_ascii` | `(String) -> String` | UTS#46 Unicode-to-ACE; returns `""` on failure |
| `domain_to_unicode` | `(String) -> String` | ACE-to-Unicode; returns `""` on failure |

```moonbit
println(@url.domain_to_ascii("münchen.example"))         // "xn--mnchen-3ya.example"
println(@url.domain_to_ascii("EXAMPLE.COM"))              // "example.com"
println(@url.domain_to_unicode("xn--mnchen-3ya.example")) // "münchen.example"
```

---

## `urlpattern` package

### `UrlPattern` type

```moonbit
pub struct UrlPattern { /* private fields */ }
```

#### UrlPattern constructors

| Method | Signature | Description |
| :--- | :--- | :--- |
| `from_string` | `(String, String?, ignore_case?: Bool) -> Self raise UrlPatternError` | Construct from a URL pattern string and optional base URL |
| `from_init` | `(UrlPatternInit, ignore_case?: Bool) -> Self raise UrlPatternError` | Construct from an init object |

```moonbit
// From a pattern string
let p = try! @urlpattern.UrlPattern::from_string(
  "https://example.com/books/:id",
  None,
)

// From an init object
let p = try! @urlpattern.UrlPattern::from_init(
  @urlpattern.UrlPatternInit::new(pathname=Some("/books/:id")),
)

// Case-insensitive
let p = try! @urlpattern.UrlPattern::from_init(
  @urlpattern.UrlPatternInit::new(pathname=Some("/Books/:id")),
  ignore_case=true,
)
```

#### Testing and executing

| Method | Signature | Description |
| :--- | :--- | :--- |
| `test_url` | `(String) -> Bool` | Returns `true` if the URL matches the pattern |
| `test_init` | `(UrlPatternInit) -> Bool` | Returns `true` if the init object matches |
| `exec_url` | `(String) -> UrlPatternResult?` | Match with captured group extraction |
| `exec_init` | `(UrlPatternInit) -> UrlPatternResult?` | Match init with captured group extraction |

```moonbit
let p = try! @urlpattern.UrlPattern::from_string(
  "https://example.com/books/:id",
  None,
)

println(p.test_url("https://example.com/books/42"))   // true
println(p.test_url("https://other.com/books/42"))     // false

match p.exec_url("https://example.com/books/42") {
  None         => println("no match")
  Some(result) =>
    match result.pathname {
      Some(pr) =>
        match pr.groups.get("id") {
          Some(Some(v)) => println(v)  // "42"
          _             => println("no capture")
        }
      None => ()
    }
}
```

#### Compiled pattern accessors

| Method | Returns | Description |
| :--- | :--- | :--- |
| `get_protocol()` | `String` | Compiled protocol pattern |
| `get_username()` | `String` | Compiled username pattern |
| `get_password()` | `String` | Compiled password pattern |
| `get_hostname()` | `String` | Compiled hostname pattern |
| `get_port()` | `String` | Compiled port pattern |
| `get_pathname()` | `String` | Compiled pathname pattern |
| `get_search()` | `String` | Compiled search pattern |
| `get_hash()` | `String` | Compiled hash pattern |

#### Advanced

| Method | Signature | Description |
| :--- | :--- | :--- |
| `has_regexp_groups()` | `Bool` | Whether any component contains a custom regexp group |
| `generate` | `(UrlPatternComponent, Map[String, String]) -> String?` | Reconstruct a URL component string from captured group values |
| `compare_component` | `(UrlPatternComponent, UrlPattern, UrlPattern) -> Int` | Specificity ordering for route-priority comparisons |

```moonbit
let p = try! @urlpattern.UrlPattern::from_string(
  "https://example.com/books/:id",
  None,
)
println(p.has_regexp_groups())  // false

// Generate a URL component from captured values
let groups = { "id": "42" }
match p.generate(@urlpattern.UrlPatternComponent::Pathname, groups) {
  Some(s) => println(s)  // "/books/42"
  None    => println("could not generate")
}

// Specificity comparison
let p1 = try! @urlpattern.UrlPattern::from_string("/books/:id", None)
let p2 = try! @urlpattern.UrlPattern::from_string("/books/42",  None)
let cmp = @urlpattern.UrlPattern::compare_component(
  @urlpattern.UrlPatternComponent::Pathname,
  p1,
  p2,
)
// cmp < 0: p1 is less specific than p2
```

---

### `UrlPatternInit` type

```moonbit
pub struct UrlPatternInit {
  protocol : String?
  username : String?
  password : String?
  hostname : String?
  port     : String?
  pathname : String?
  search   : String?
  hash     : String?
  base_url : String?
}
pub fn UrlPatternInit::new(
  protocol? : String?,
  username? : String?,
  password? : String?,
  hostname? : String?,
  port?     : String?,
  pathname? : String?,
  search?   : String?,
  hash?     : String?,
  base_url? : String?,
) -> Self
```

All fields default to `None` (wildcard) when omitted.

---

### `UrlPatternComponent` enum

```moonbit
pub(all) enum UrlPatternComponent {
  Protocol
  Username
  Password
  Hostname
  Port
  Pathname
  Search
  Hash
} derive(Eq, @debug.Debug)
```

Used as the component selector in `compare_component` and `generate`.

---

### `UrlPatternResult` type

```moonbit
pub struct UrlPatternResult {
  inputs   : Array[UrlPatternInput]
  protocol : UrlPatternComponentResult?
  username : UrlPatternComponentResult?
  password : UrlPatternComponentResult?
  hostname : UrlPatternComponentResult?
  port     : UrlPatternComponentResult?
  pathname : UrlPatternComponentResult?
  search   : UrlPatternComponentResult?
  hash     : UrlPatternComponentResult?
}
```

Returned by `exec_url` and `exec_init`. When the call returns `Some(result)`,
every component field is `Some(...)` — `exec_init` matches and guards each
component before constructing the result, so a mismatch on any single
component aborts the whole call with `None`. The `Option` wrapper on each
field exists only to keep room for forward-compatible component additions.

---

### `UrlPatternComponentResult` type

```moonbit
pub struct UrlPatternComponentResult {
  input  : String
  groups : Map[String, String?]
}
```

`groups` maps capture-group names to their matched values. Reading via
`groups.get(name)`, a `Some(None)` result means the named group did not
participate in the match (mirrors WPT's expected `null`); a
`Some(Some(""))` result means the group participated and captured an
empty string.

---

### `UrlPatternInput` type

```moonbit
pub enum UrlPatternInput {
  Str(String)
  Init(UrlPatternInit)
}
```

Records which form of input was passed to `exec_url` or `exec_init`.

---

### `UrlPatternError` type

```moonbit
pub suberror UrlPatternError { UrlPatternError(String) }
pub impl Show for UrlPatternError
```

Raised by `from_string` and `from_init` when the pattern is invalid.
