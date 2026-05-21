// Blackbox tests run against the package's public API. Use `@uri` to import.
// Prefer high-level behaviors over implementation details.
// Run `moon test` to execute and `moon test --update` to refresh snapshots.

///|
test "basic http URL parses all components" {
  let url = @uri.parse("http://user:pass@example.com:8080/path?query#hash")
  assert_eq(url.scheme, "http")
  assert_eq(url.username, "user")
  assert_eq(url.password, "pass")
  assert_eq(url.hostname(), "example.com")
  assert_eq(url.port_str(), "8080")
  assert_eq(url.pathname(), "/path")
  assert_eq(url.search(), "?query")
  assert_eq(url.hash(), "#hash")
}

///|
test "href round-trips simple http URL" {
  let input = "http://example.com/"
  let url = @uri.parse(input)
  assert_eq(url.href(), input)
}

///|
test "tabs and newlines are stripped from input" {
  let url = @uri.parse("http://example\t.\norg")
  assert_eq(url.hostname(), "example.org")
}

///|
test "default port is omitted from href" {
  let url = @uri.parse("http://example.com:80/")
  assert_eq(url.port_str(), "")
  assert_eq(url.href(), "http://example.com/")
}

///|
test "non-default port is preserved in href" {
  let url = @uri.parse("http://example.com:8080/")
  assert_eq(url.port_str(), "8080")
  assert_eq(url.host_str(), "example.com:8080")
}

///|
test "https default port 443 is omitted" {
  let url = @uri.parse("https://example.com:443/")
  assert_eq(url.port_str(), "")
}

///|
test "scheme is lowercased" {
  let url = @uri.parse("HTTP://example.com/")
  assert_eq(url.scheme, "http")
  assert_eq(url.protocol(), "http:")
}

///|
test "host is lowercased" {
  let url = @uri.parse("http://EXAMPLE.COM/")
  assert_eq(url.hostname(), "example.com")
}

///|
test "IPv4 address is serialized correctly" {
  let url = @uri.parse("http://192.168.1.1/")
  assert_eq(url.hostname(), "192.168.1.1")
}

///|
test "IPv6 address parses and serializes with brackets" {
  let url = @uri.parse("http://[::1]/")
  assert_eq(url.hostname(), "::1")
  assert_eq(url.host_str(), "[::1]")
}

///|
test "IPv6 with port parses correctly" {
  let url = @uri.parse("http://[::1]:8080/")
  assert_eq(url.hostname(), "::1")
  assert_eq(url.port_str(), "8080")
  assert_eq(url.host_str(), "[::1]:8080")
}

///|
test "origin includes scheme and host for http" {
  let url = @uri.parse("http://example.com/path?q#f")
  assert_eq(url.origin(), "http://example.com")
}

///|
test "origin is null for file URLs" {
  let url = @uri.parse("file:///etc/hosts")
  assert_eq(url.origin(), "null")
}

///|
test "relative URL resolves against base" {
  let base = @uri.parse("http://example.com/foo/bar")
  let url = @uri.parse_with_base("../baz", Some(base))
  assert_eq(url.pathname(), "/baz")
  assert_eq(url.href(), "http://example.com/baz")
}

///|
test "relative path segment resolution" {
  let base = @uri.parse("http://example.com/a/b/c")
  let url = @uri.parse_with_base("d", Some(base))
  assert_eq(url.pathname(), "/a/b/d")
}

///|
test "query-only relative URL preserves base path" {
  let base = @uri.parse("http://example.com/path?old")
  let url = @uri.parse_with_base("?new", Some(base))
  assert_eq(url.pathname(), "/path")
  assert_eq(url.search(), "?new")
}

///|
test "fragment-only relative URL preserves base" {
  let base = @uri.parse("http://example.com/path?q")
  let url = @uri.parse_with_base("#frag", Some(base))
  assert_eq(url.pathname(), "/path")
  assert_eq(url.search(), "?q")
  assert_eq(url.hash(), "#frag")
}

///|
test "search returns empty string when no query" {
  let url = @uri.parse("http://example.com/")
  assert_eq(url.search(), "")
}

///|
test "hash returns empty string when no fragment" {
  let url = @uri.parse("http://example.com/")
  assert_eq(url.hash(), "")
}

///|
test "pathname returns slash for empty path with host" {
  let url = @uri.parse("http://example.com")
  assert_eq(url.pathname(), "/")
}

///|
test "no base and no scheme raises error" {
  let result : Result[@uri.Url, @uri.UrlParseError] = Ok(
    @uri.parse("//example.com"),
  ) catch {
    e => Err(e)
  }
  assert_eq(result.is_err(), true)
}

///|
test "opaque path for non-special scheme" {
  let url = @uri.parse("data:text/plain,hello")
  assert_eq(url.scheme, "data")
  assert_eq(url.pathname(), "text/plain,hello")
}

///|
test "file URL parses path" {
  let url = @uri.parse("file:///etc/passwd")
  assert_eq(url.scheme, "file")
  assert_eq(url.pathname(), "/etc/passwd")
  assert_eq(url.hostname(), "")
}

///|
test "percent-encoded path is preserved" {
  let url = @uri.parse("http://example.com/p%20ath")
  assert_eq(url.pathname(), "/p%20ath")
}

///|
test "user:pass@foo:21 URL" {
  let url = @uri.parse("http://user:pass@foo:21/bar;par?b#c")
  assert_eq(url.username, "user")
  assert_eq(url.password, "pass")
  assert_eq(url.hostname(), "foo")
  assert_eq(url.port_str(), "21")
  assert_eq(url.pathname(), "/bar;par")
  assert_eq(url.search(), "?b")
  assert_eq(url.hash(), "#c")
  assert_eq(url.href(), "http://user:pass@foo:21/bar;par?b#c")
}

///|
test "double-dot percent-encoded segment preserves trailing slash before query" {
  let url = @uri.parse("https://example.com/aaa/bbb/%2e%2e?query")
  assert_eq(url.href(), "https://example.com/aaa/?query")
}

///|
test "double-dot percent-encoded segment preserves trailing slash before fragment" {
  let url = @uri.parse("https://example.com/aaa/bbb/%2e%2e#frag")
  assert_eq(url.href(), "https://example.com/aaa/#frag")
}

///|
test "IPv4 address with invalid hex digit is treated as domain" {
  let url = @uri.parse("http://0x7f.0.0.0x7g")
  assert_eq(url.hostname(), "0x7f.0.0.0x7g")
  assert_eq(url.href(), "http://0x7f.0.0.0x7g/")
}

///|
test "opaque path encodes non-ASCII code points with C0 set" {
  let url = @uri.parse("wow:\u{FFFF}")
  assert_eq(url.href(), "wow:%EF%BF%BF")
}

///|
test "opaque path encodes NUL byte with C0 set" {
  let url = @uri.parse("non-special:\u{0000}y")
  assert_eq(url.href(), "non-special:%00y")
}

///|
test "opaque path encodes trailing space as %20 before query" {
  let url = @uri.parse("non-special:opaque  ?hi")
  assert_eq(url.href(), "non-special:opaque %20?hi")
}

///|
test "opaque path encodes trailing space as %20 before fragment" {
  let url = @uri.parse("non-special:opaque  #hi")
  assert_eq(url.href(), "non-special:opaque %20#hi")
}

///|
test "opaque path does not encode spaces in middle before query" {
  let url = @uri.parse("non-special:opaque  x?hi")
  assert_eq(url.href(), "non-special:opaque  x?hi")
}

///|
test "multiple @ signs encode earlier credentials into username" {
  let base = @uri.parse("http://doesnotmatter/")
  let url = @uri.parse_with_base("https://@@@example", Some(base))
  assert_eq(url.href(), "https://%40%40@example/")
}

///|
test "multiple @ with credentials preserves password from first colon" {
  let base = @uri.parse("http://doesnotmatter/")
  let url = @uri.parse_with_base("https://@test@test@example:800/", Some(base))
  assert_eq(url.href(), "https://%40test%40test@example:800/")
}

///|
test "triple slash relative to non-special base preserves empty host" {
  let base = @uri.parse("sc://x/")
  let url = @uri.parse_with_base("///", Some(base))
  assert_eq(url.href(), "sc:///")
}

///|
test "quadruple slash relative to non-special base preserves empty segments" {
  let base = @uri.parse("sc://x/")
  let url = @uri.parse_with_base("////", Some(base))
  assert_eq(url.href(), "sc:////")
}

///|
test "caret in URL path is percent-encoded" {
  let url = @uri.parse("foo://host/a^b")
  assert_eq(url.pathname(), "/a%5Eb")
}
