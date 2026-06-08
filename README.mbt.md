# urllib-mbt

[![CI](https://github.com/connect0459/urllib-mbt/actions/workflows/ci.yml/badge.svg)](https://github.com/connect0459/urllib-mbt/actions/workflows/ci.yml)
[![docs](https://img.shields.io/badge/docs-mooncakes.io-green)](https://mooncakes.io/docs/connect0459/urllib)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](https://github.com/connect0459/urllib-mbt/blob/main/LICENSE)

A WHATWG-compliant URL parsing library for [MoonBit](https://moonbitlang.com).

Implements the [URL Standard](https://url.spec.whatwg.org/) and
[URL Pattern Standard](https://urlpattern.spec.whatwg.org/) with full WPT
(Web Platform Tests) coverage.

## Packages

| Package | Description |
| :--- | :--- |
| `connect0459/urllib/url` | URL parsing, getters, setters, URLSearchParams, IDNA utilities |
| `connect0459/urllib/urlpattern` | URLPattern — route matching against URL components |

## Installation

```sh
moon add connect0459/urllib
```

Then declare the packages you need in your `moon.pkg`:

```text
import {
  "connect0459/urllib/url",
  "connect0459/urllib/urlpattern",
}
```

## Usage

### URL Parsing

```moonbit
let url = try! @url.parse("https://user:pass@example.com:8080/path?q=1#frag")

println(url.href())      // "https://user:pass@example.com:8080/path?q=1#frag"
println(url.hostname())  // "example.com"
println(url.port())      // Some(8080)
println(url.pathname())  // "/path"
println(url.search())    // "?q=1"
println(url.origin())    // "https://example.com:8080"

// Infallible variant — returns None instead of raising
let opt = @url.parse_maybe("not a url", None)  // None

// Resolve a relative URL
let base     = try! @url.parse("https://example.com/a/b/c")
let resolved = try! base.join("../d")
println(resolved.href())  // "https://example.com/a/d"
```

### URLSearchParams

```moonbit
let params = @url.UrlSearchParams::from_string("a=1&b=2&a=3")
println(params.get("a"))      // Some("1")
println(params.get_all("a"))  // ["1", "3"]

params.append("c", "4")
params.delete("b")
params.set("a", "99")
println(params.to_string())   // "a=99&c=4"
```

### URLPattern

```moonbit
let p = try! @urlpattern.UrlPattern::from_string(
  "https://example.com/books/:id",
  None,
)

println(p.test_url("https://example.com/books/42"))  // true

match p.exec_url("https://example.com/books/42") {
  Some(result) =>
    match result.pathname() {
      Some(pr) =>
        match pr.groups().get("id") {
          Some(Some(id)) => println(id)  // "42"
          _              => ()
        }
      None => ()
    }
  None => ()
}
```

### IDNA

```moonbit
println(@url.domain_to_ascii("münchen.example"))          // "xn--mnchen-3ya.example"
println(@url.domain_to_unicode("xn--mnchen-3ya.example")) // "münchen.example"
```

## Compliance

Full [Web Platform Tests (WPT)](https://github.com/web-platform-tests/wpt)
coverage for the URL and URLPattern standards.

## Documentation

Each public package has a `README.mbt.md` with a key-types overview, usage
examples, and a full API reference. Start with [`url`](./url) for the main
entry point.

- [ARCHITECTURE.md](https://github.com/connect0459/urllib-mbt/blob/main/docs/ARCHITECTURE.md) : Architecture overview

## Contributing

See [CONTRIBUTING.md](https://github.com/connect0459/urllib-mbt/blob/main/CONTRIBUTING.md).

## License

Apache-2.0
