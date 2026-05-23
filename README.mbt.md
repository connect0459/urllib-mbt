# urllib.mbt

A WHATWG-compliant URL parsing library for [MoonBit](https://moonbitlang.com).

Implements the [URL Standard](https://url.spec.whatwg.org/) and
[URL Pattern Standard](https://urlpattern.spec.whatwg.org/) with full WPT
(Web Platform Tests) coverage.

## Packages

| Package | Description |
| :--- | :--- |
| `connect0459/urllib/url` | URL parsing, getters, setters, URLSearchParams, IDNA utilities |
| `connect0459/urllib/urlpattern` | URLPattern — route matching against URL components |

## URL Parsing

Import the `url` package and call `parse` (raises on invalid input) or one of
the infallible helpers.

```moonbit
// Raises UrlParseError on invalid input
let url = try! @url.parse("https://user:pass@example.com:8080/path?q=1#frag")

println(url.href())      // "https://user:pass@example.com:8080/path?q=1#frag"
println(url.protocol())  // "https:"
println(url.scheme())    // "https"
println(url.username())  // "user"
println(url.password())  // "pass"
println(url.hostname())  // "example.com"
println(url.port())      // Some(8080)
println(url.port_str())  // "8080"
println(url.pathname())  // "/path"
println(url.search())    // "?q=1"
println(url.hash())      // "#frag"
println(url.origin())    // "https://example.com:8080"
```

### Infallible helpers

```moonbit
// Returns None instead of raising
match @url.parse_maybe("not a url", None) {
  Some(url) => println(url.href())
  None      => println("invalid")
}

// Quick validity check
let ok = @url.can_parse("https://example.com", None)  // true
```

### Resolving relative URLs

```moonbit
let base = try! @url.parse("https://example.com/a/b/c")
let resolved = try! base.join("../d")
println(resolved.href())  // "https://example.com/a/d"
```

### Parsing with an explicit base

```moonbit
let base = try! @url.parse("https://example.com/dir/")
let url  = try! @url.parse_with_base("/page", Some(base))
println(url.href())  // "https://example.com/page"
```

## URL Getters

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
| `port_str()` | `String` | Port as string (empty string if absent) |
| `pathname()` | `String` | Path component |
| `search()` | `String` | Query string with leading `?` (empty if absent) |
| `hash()` | `String` | Fragment with leading `#` (empty if absent) |
| `origin()` | `String` | Serialized origin |
| `to_json()` | `String` | Alias for `href()` |

### Predicates

```moonbit
url.is_special()        // true for http, https, ftp, file, ws, wss
url.has_credentials()   // true when username or password is non-empty
url.has_opaque_path()   // true for non-hierarchical URLs (e.g. "data:…")
```

### Path segments iterator

```moonbit
let url = try! @url.parse("https://example.com/a/b/c")
match url.path_segments() {
  Some(iter) => for seg in iter { println(seg) }  // "a", "b", "c"
  None       => println("opaque path")
}
```

## URL Setters

All setters return a **new** `Url` value — the original is unchanged.

```moonbit
let url  = try! @url.parse("https://example.com/old")
let url2 = url.set_pathname("/new")
let url3 = url2.set_search("q=hello")

println(url.href())   // "https://example.com/old"
println(url3.href())  // "https://example.com/new?q=hello"
```

Available setters: `set_href` (raises), `set_protocol`, `set_username`,
`set_password`, `set_host`, `set_hostname`, `set_port`, `set_pathname`,
`set_search`, `set_hash`.

## URLSearchParams

```moonbit
// Parse a query string
let params = @url.UrlSearchParams::from_string("a=1&b=2&a=3")
println(params.get("a"))      // Some("1")
println(params.get_all("a"))  // ["1", "3"]
println(params.has("b"))      // true
println(params.size())        // 3

// Mutate
params.append("c", "4")
params.delete("b")
params.set("a", "99")         // replaces all "a" entries
println(params.to_string())   // "a=99&c=4"

// Iterate
for name, value in params.iter() {
  println("\{name}=\{value}")
}

// Sort by name (Unicode code-unit order)
params.sort()

// Access from a URL
let url = try! @url.parse("https://example.com/?q=moon&lang=en")
let sp  = url.search_params()
println(sp.get("q"))  // Some("moon")
```

## IDNA Utilities

```moonbit
// Convert a Unicode domain to its ACE (ASCII-Compatible Encoding) form.
// Returns "" on failure.
println(@url.domain_to_ascii("münchen.example"))  // "xn--mnchen-3ya.example"
println(@url.domain_to_ascii("EXAMPLE.COM"))       // "example.com"
println(@url.domain_to_ascii(""))                  // ""

// Convert an ACE domain back to Unicode.
// Returns "" on failure.
println(@url.domain_to_unicode("xn--mnchen-3ya.example"))  // "münchen.example"
println(@url.domain_to_unicode("example.com"))              // "example.com"
```

## URLPattern

Route-matching against URL components using the
[URL Pattern Standard](https://urlpattern.spec.whatwg.org/).

### Constructing a pattern

```moonbit
// From a URL pattern string
let p = try! @urlpattern.UrlPattern::from_string(
  "https://example.com/books/:id",
  None,
)

// From an init object
let p = try! @urlpattern.UrlPattern::from_init(
  @urlpattern.UrlPatternInit::new(pathname=Some("/books/:id")),
)

// Case-insensitive matching
let p = try! @urlpattern.UrlPattern::from_init(
  @urlpattern.UrlPatternInit::new(pathname=Some("/books/:id")),
  ignore_case=true,
)
```

### Testing and executing

```moonbit
let p = try! @urlpattern.UrlPattern::from_string(
  "https://example.com/books/:id",
  None,
)

// Boolean test
println(p.test_url("https://example.com/books/42"))  // true
println(p.test_url("https://other.com/books/42"))    // false

// Execute and extract captured groups
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

### Compiled pattern strings

```moonbit
let p = try! @urlpattern.UrlPattern::from_string(
  "https://example.com/books/:id",
  None,
)
println(p.get_protocol())  // "https"
println(p.get_hostname())  // "example.com"
println(p.get_pathname())  // "/books/:id"
```

## WPT Compliance

| Test suite | Passing |
| :--- | :--- |
| URL parsing (urltestdata.json) | 611 / 611 (100 %) |
| URL failure rejection | 275 / 275 (100 %) |
| URL getters | 611 / 611 |
| URL origin | 399 / 399 |
| URL setters | 278 / 278 |
| URL setters stripping | 270 / 270 |
| URLSearchParams (all suites) | 53 / 53 |
| URL static methods | 9 / 9 |
| Percent-encoding | 14 / 14 |
| IDNA ToASCII | 87 / 87 |
| IDNA V2 (IdnaTestV2.json) | 2670 / 2670 (100 %) |
| URLPattern | 382 / 382 |

## License

Apache-2.0
