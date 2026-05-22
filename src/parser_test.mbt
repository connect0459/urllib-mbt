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
  assert_eq(url.hostname(), "[::1]")
  assert_eq(url.host_str(), "[::1]")
}

///|
test "IPv6 with port parses correctly" {
  let url = @uri.parse("http://[::1]:8080/")
  assert_eq(url.hostname(), "[::1]")
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
  assert_true(result is Err(_))
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

///|
test "soft hyphen in HTTPS domain is stripped" {
  let url = @uri.parse("https://a%C2%ADb/")
  assert_eq(url.hostname(), "ab")
  assert_eq(url.href(), "https://ab/")
}

///|
test "soft hyphen raw in HTTP domain is stripped" {
  let url = @uri.parse("http://a\u{00AD}b.com/")
  assert_eq(url.hostname(), "ab.com")
}

///|
test "zero-width and invisible ignored chars in domain are stripped" {
  let url = @uri.parse("http://foo\u{200B}\u{2060}\u{FEFF}bar.com/")
  assert_eq(url.hostname(), "foobar.com")
}

///|
test "ideographic full stop U+3002 is treated as domain label separator" {
  let url = @uri.parse("http://www\u{3002}example\u{3002}com/")
  assert_eq(url.hostname(), "www.example.com")
}

///|
test "full-width ASCII letters in domain are mapped to ASCII" {
  let url = @uri.parse("http://\u{FF27}\u{FF4F}.com/")
  assert_eq(url.hostname(), "go.com")
}

///|
test "soft hyphen in file URL host is stripped" {
  let url = @uri.parse("file://a\u{00AD}b/p")
  assert_eq(url.hostname(), "ab")
  assert_eq(url.href(), "file://ab/p")
}

///|
test "mathematical bold localhost in file URL resolves to empty host" {
  let url = @uri.parse(
    "file://loC\u{1D400}\u{1D40B}\u{1D407}\u{1D428}\u{1D42C}\u{1D42D}/usr/bin",
  )
  assert_eq(url.hostname(), "")
  assert_eq(url.href(), "file:///usr/bin")
}

///|
test "Windows drive letter with single slash and file base overrides base path" {
  let base = @uri.parse("file:///tmp/mock/path")
  let url = @uri.parse_with_base("file:c:\\foo\\bar.html", Some(base))
  assert_eq(url.href(), "file:///c:/foo/bar.html")
}

///|
test "relative Windows drive letter with file base starts from drive root" {
  let base = @uri.parse("file:///tmp/mock/path")
  let url = @uri.parse_with_base("C|/foo/bar", Some(base))
  assert_eq(url.href(), "file:///C:/foo/bar")
}

///|
test "pipe in Windows drive letter is normalized to colon" {
  let base = @uri.parse("file:///tmp/mock/path")
  let url = @uri.parse_with_base("//C|/foo/bar", Some(base))
  assert_eq(url.href(), "file:///C:/foo/bar")
}

///|
test "absolute path with drive letter does not duplicate base drive" {
  let base = @uri.parse("file:///c:/baz/qux")
  let url = @uri.parse_with_base("/c:/foo/bar", Some(base))
  assert_eq(url.href(), "file:///c:/foo/bar")
}

///|
test "double-slash drive letter in file URL host position becomes path" {
  let base = @uri.parse("file:///C:/a/b")
  let url = @uri.parse_with_base("//d:", Some(base))
  assert_eq(url.href(), "file:///d:")
}

///|
test "double-slash drive with dotdot resolves to drive root" {
  let base = @uri.parse("file:///C:/a/b")
  let url = @uri.parse_with_base("//d:/..", Some(base))
  assert_eq(url.href(), "file:///d:/")
}

///|
test "drive letter in authority of file URL is treated as path" {
  let url = @uri.parse("file://C|/")
  assert_eq(url.href(), "file:///C:/")
}

///|
test "drive letter relative to file host base preserves host" {
  let base = @uri.parse("file://host/dir/file")
  let url = @uri.parse_with_base("C|", Some(base))
  assert_eq(url.href(), "file://host/C:")
}

///|
test "drive letter with query relative to file host base" {
  let base = @uri.parse("file://host/dir/file")
  let url = @uri.parse_with_base("C|?q=1", Some(base))
  assert_eq(url.href(), "file://host/C:?q=1")
}

///|
test "non-special double-slash path gets /. prefix in href" {
  let url = @uri.parse("non-spec:/.//")
  assert_eq(url.href(), "non-spec:/.//")
}

///|
test "non-special dotdot resolves to double-slash path with /. prefix" {
  let url = @uri.parse("non-spec:/..//")
  assert_eq(url.href(), "non-spec:/.//")
}

///|
test "non-special dotdot with path segment gets /. prefix" {
  let url = @uri.parse("non-spec:/..//path")
  assert_eq(url.href(), "non-spec:/.//path")
}

///|
test "non-special double-slash path relative to base gets /. prefix" {
  let base = @uri.parse("non-spec:/p")
  let url = @uri.parse_with_base("..//path", Some(base))
  assert_eq(url.href(), "non-spec:/.//path")
}

///|
test "empty input against non-special double-slash base preserves /. prefix" {
  let base = @uri.parse("non-spec:/..//p")
  let url = @uri.parse_with_base("", Some(base))
  assert_eq(url.href(), "non-spec:/.//p")
}

///|
test "IPv4 single-part decimal 2^32 is rejected" {
  let result : Result[@uri.Url, _] = Ok(@uri.parse("http://4294967296")) catch {
    e => Err(e)
  }
  assert_true(result is Err(_))
}

///|
test "IPv4 single-part decimal larger than 2^32 is rejected" {
  let result : Result[@uri.Url, _] = Ok(@uri.parse("http://10000000000")) catch {
    e => Err(e)
  }
  assert_true(result is Err(_))
}

///|
test "IPv4 single-part decimal much larger than 2^64 is rejected" {
  let result : Result[@uri.Url, _] = Ok(
    @uri.parse("http://18446744073709551616"),
  ) catch {
    e => Err(e)
  }
  assert_true(result is Err(_))
}

///|
test "IPv4 single-part hex 0x100000000 equals 2^32 is rejected" {
  let result : Result[@uri.Url, _] = Ok(@uri.parse("https://0x100000000/test")) catch {
    e => Err(e)
  }
  assert_true(result is Err(_))
}

///|
test "IPv4 single-part hex 0xffffffff1 exceeds 2^32 is rejected" {
  let result : Result[@uri.Url, _] = Ok(@uri.parse("http://0xffffffff1")) catch {
    e => Err(e)
  }
  assert_true(result is Err(_))
}

///|
test "IPv4 single-part decimal 2^32-1 is valid max address" {
  let url = @uri.parse("http://4294967295")
  assert_eq(url.href(), "http://255.255.255.255/")
}

///|
test "IPv4 single-part hex 0xffffffff is valid max address" {
  let url = @uri.parse("http://0xffffffff")
  assert_eq(url.href(), "http://255.255.255.255/")
}

///|
test "non-special empty host with colon and no port is rejected" {
  let result : Result[@uri.Url, _] = Ok(@uri.parse("sc://:/")) catch {
    e => Err(e)
  }
  assert_true(result is Err(_))
}

///|
test "non-special empty host with numeric port is rejected" {
  let result : Result[@uri.Url, _] = Ok(@uri.parse("sc://:12/")) catch {
    e => Err(e)
  }
  assert_true(result is Err(_))
}

///|
test "data scheme empty host with port is rejected" {
  let result : Result[@uri.Url, _] = Ok(@uri.parse("data://:443")) catch {
    e => Err(e)
  }
  assert_true(result is Err(_))
}

///|
test "javascript scheme empty host with port is rejected" {
  let result : Result[@uri.Url, _] = Ok(@uri.parse("javascript://:443")) catch {
    e => Err(e)
  }
  assert_true(result is Err(_))
}

///|
test "non-special empty host without port is valid" {
  let url = @uri.parse("sc:///")
  assert_eq(url.href(), "sc:///")
}

///|
test "non-special non-empty host with port is valid" {
  let url = @uri.parse("sc://host:12/")
  assert_eq(url.href(), "sc://host:12/")
}

///|
test "search returns empty string for empty-string query" {
  let url = @uri.parse("http://example.com/foo?")
  assert_eq(url.search(), "")
}

///|
test "hash returns empty string for empty-string fragment" {
  let url = @uri.parse("http://example.com/foo#")
  assert_eq(url.hash(), "")
}

///|
test "parse: IPv6 host with empty port parses port as None" {
  let url = @uri.parse("http://[::1]:/")
  assert_true(url.port is None)
  assert_eq(url.href(), "http://[::1]/")
}

///|
test "parse: IPv6 host with trailing non-colon char raises UrlParseError" {
  let result = @uri.parse_maybe("http://[::1]x/", None)
  assert_true(result is None)
}

///|
test "parse: single-dot segment before query produces trailing slash" {
  let url = @uri.parse("http://example.com/a/..?q=1")
  assert_eq(url.href(), "http://example.com/?q=1")
}
