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

// ===== getter fixes =====

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

// ===== set_hash =====

///|
test "set_hash sets fragment without leading hash" {
  let url = @uri.parse("https://example.net").set_hash("main")
  assert_eq(url.hash(), "#main")
  assert_eq(url.href(), "https://example.net/#main")
}

///|
test "set_hash replaces existing fragment" {
  let url = @uri.parse("https://example.net#nav").set_hash("main")
  assert_eq(url.hash(), "#main")
}

///|
test "set_hash strips leading hash from value" {
  let url = @uri.parse("https://example.net?q=1#nav").set_hash("#main")
  assert_eq(url.hash(), "#main")
}

///|
test "set_hash with empty string removes fragment" {
  let url = @uri.parse("https://example.net?q=1#nav").set_hash("")
  assert_eq(url.hash(), "")
  assert_eq(url.href(), "https://example.net/?q=1")
}

///|
test "set_hash percent-encodes special chars" {
  let url = @uri.parse("http://example.net").set_hash("#foo bar")
  assert_eq(url.hash(), "#foo%20bar")
}

///|
test "set_hash works on opaque-path URL" {
  let url = @uri.parse("javascript:alert(1)").set_hash("castle")
  assert_eq(url.hash(), "#castle")
  assert_eq(url.href(), "javascript:alert(1)#castle")
}

// ===== set_search =====

///|
test "set_search sets query without leading question mark" {
  let url = @uri.parse("https://example.net#nav").set_search("lang=fr")
  assert_eq(url.search(), "?lang=fr")
  assert_eq(url.href(), "https://example.net/?lang=fr#nav")
}

///|
test "set_search strips leading question mark from value" {
  let url = @uri.parse("https://example.net?old#nav").set_search("?lang=fr")
  assert_eq(url.search(), "?lang=fr")
}

///|
test "set_search with empty string removes query" {
  let url = @uri.parse("https://example.net?lang=en").set_search("")
  assert_eq(url.search(), "")
  assert_eq(url.href(), "https://example.net/")
}

///|
test "set_search with only question mark sets empty query" {
  let url = @uri.parse("https://example.net?lang=en-US#nav").set_search("?")
  assert_eq(url.search(), "")
  assert_eq(url.href(), "https://example.net/?#nav")
}

///|
test "set_search preserves fragment" {
  let url = @uri.parse("https://example.net?en#nav").set_search("lang=fr")
  assert_eq(url.search(), "?lang=fr")
  assert_eq(url.hash(), "#nav")
}

// ===== set_username =====

///|
test "set_username sets username for http URL" {
  let url = @uri.parse("http://example.net").set_username("me")
  assert_eq(url.username, "me")
  assert_eq(url.href(), "http://me@example.net/")
}

///|
test "set_username with empty string clears username" {
  let url = @uri.parse("http://me@example.net").set_username("")
  assert_eq(url.username, "")
  assert_eq(url.href(), "http://example.net/")
}

///|
test "set_username is no-op for file URL" {
  let url = @uri.parse("file://test/").set_username("test")
  assert_eq(url.username, "")
}

///|
test "set_username is no-op when no host" {
  let url = @uri.parse("file:///home/you/index.html").set_username("me")
  assert_eq(url.username, "")
  assert_eq(url.href(), "file:///home/you/index.html")
}

///|
test "set_username is no-op for opaque-path URL" {
  let url = @uri.parse("mailto:you@example.net").set_username("me")
  assert_eq(url.username, "")
}

///|
test "set_username percent-encodes value using userinfo set" {
  let url = @uri.parse("http://example.net").set_username("/foo")
  assert_eq(url.username, "%2Ffoo")
}

// ===== set_password =====

///|
test "set_password sets password for http URL" {
  let url = @uri.parse("http://example.net").set_password("secret")
  assert_eq(url.password, "secret")
  assert_eq(url.href(), "http://:secret@example.net/")
}

///|
test "set_password with empty string clears password" {
  let url = @uri.parse("http://:secret@example.net").set_password("")
  assert_eq(url.password, "")
  assert_eq(url.href(), "http://example.net/")
}

///|
test "set_password is no-op for file URL" {
  let url = @uri.parse("file://test/").set_password("test")
  assert_eq(url.password, "")
}

///|
test "set_password is no-op when no host" {
  let url = @uri.parse("unix:/run/foo.socket").set_password("secret")
  assert_eq(url.password, "")
}

// ===== set_port =====

///|
test "set_port sets port number" {
  let url = @uri.parse("http://example.net").set_port("8080")
  assert_eq(url.port_str(), "8080")
  assert_eq(url.href(), "http://example.net:8080/")
}

///|
test "set_port with empty string removes port" {
  let url = @uri.parse("http://example.net:8080").set_port("")
  assert_eq(url.port_str(), "")
  assert_eq(url.href(), "http://example.net/")
}

///|
test "set_port with default port removes port" {
  let url = @uri.parse("http://example.net:8080").set_port("80")
  assert_eq(url.port_str(), "")
}

///|
test "set_port with out-of-range number is no-op" {
  let url = @uri.parse("http://example.net:8080/path").set_port("65536")
  assert_eq(url.port_str(), "8080")
}

///|
test "set_port stops at non-digit chars" {
  let url = @uri.parse("http://example.net/path").set_port("8080stuff2")
  assert_eq(url.port_str(), "8080")
}

///|
test "set_port is no-op for file URL" {
  let url = @uri.parse("file://test/").set_port("12")
  assert_eq(url.port_str(), "")
}

// ===== set_pathname =====

///|
test "set_pathname sets path" {
  let url = @uri.parse("https://example.net#nav").set_pathname("home")
  assert_eq(url.pathname(), "/home")
  assert_eq(url.href(), "https://example.net/home#nav")
}

///|
test "set_pathname resolves dot segments" {
  let url = @uri.parse("https://example.net#nav").set_pathname("../home")
  assert_eq(url.pathname(), "/home")
}

///|
test "set_pathname is no-op for opaque-path URL" {
  let url = @uri.parse("mailto:me@example.net").set_pathname("/foo")
  assert_eq(url.pathname(), "me@example.net")
}

///|
test "set_pathname encodes path chars" {
  let url = @uri.parse("http://example.net").set_pathname("?")
  assert_eq(url.pathname(), "/%3F")
}

// ===== set_host =====

///|
test "set_host sets host and port" {
  let url = @uri.parse("http://example.net").set_host("example.com:8080")
  assert_eq(url.host_str(), "example.com:8080")
  assert_eq(url.href(), "http://example.com:8080/")
}

///|
test "set_host updates host only when no port in value" {
  let url = @uri.parse("http://example.net:8080").set_host("example.com")
  assert_eq(url.hostname(), "example.com")
  assert_eq(url.port_str(), "8080")
}

///|
test "set_host is no-op for opaque-path URL" {
  let url = @uri.parse("mailto:me@example.net").set_host("example.com")
  assert_eq(url.host_str(), "")
}

///|
test "set_host stops at slash delimiter" {
  let url = @uri.parse("http://example.net/path").set_host("example.com/stuff")
  assert_eq(url.hostname(), "example.com")
}

// ===== set_hostname =====

///|
test "set_hostname updates only hostname preserving port" {
  let url = @uri.parse("http://example.net:8080").set_hostname("example.com")
  assert_eq(url.hostname(), "example.com")
  assert_eq(url.port_str(), "8080")
}

///|
test "set_hostname with colon is no-op" {
  let url = @uri.parse("http://example.net/path").set_hostname(
    "example.com:8080",
  )
  assert_eq(url.hostname(), "example.net")
}

///|
test "set_hostname is no-op for opaque-path URL" {
  let url = @uri.parse("mailto:me@example.net").set_hostname("example.com")
  assert_eq(url.hostname(), "")
}

// ===== set_protocol =====

///|
test "set_protocol changes scheme" {
  let url = @uri.parse("a://example.net").set_protocol("b")
  assert_eq(url.protocol(), "b:")
  assert_eq(url.href(), "b://example.net")
}

///|
test "set_protocol lowercases scheme" {
  let url = @uri.parse("a://example.net").set_protocol("B")
  assert_eq(url.protocol(), "b:")
}

///|
test "set_protocol ignores stuff after first colon" {
  let url = @uri.parse("http://example.net").set_protocol("https:foo:bar")
  assert_eq(url.protocol(), "https:")
}

///|
test "set_protocol from special to non-special is no-op" {
  let url = @uri.parse("http://example.net").set_protocol("b")
  assert_eq(url.protocol(), "http:")
}

///|
test "set_protocol from non-special to special is no-op" {
  let url = @uri.parse("ssh://me@example.net").set_protocol("http")
  assert_eq(url.protocol(), "ssh:")
}

///|
test "set_protocol to file with credentials is no-op" {
  let url = @uri.parse("http://test@example.net").set_protocol("file")
  assert_eq(url.protocol(), "http:")
}

///|
test "set_protocol clears port when it becomes default for new scheme" {
  let url = @uri.parse("http://foo.com:443/").set_protocol("https")
  assert_eq(url.protocol(), "https:")
  assert_eq(url.port_str(), "")
}

///|
test "set_protocol strips tabs and newlines from value" {
  let url = @uri.parse("http://test/").set_protocol("h\r\ntt\tps")
  assert_eq(url.protocol(), "https:")
}

// ===== set_href =====

///|
test "set_href re-parses the URL" {
  let url = @uri.parse("file:///var/log/system.log").set_href(
    "http://0300.168.0xF0",
  )
  assert_eq(url.href(), "http://192.168.0.240/")
  assert_eq(url.protocol(), "http:")
}

// ===== can_parse =====

///|
test "can_parse returns true for valid absolute URL" {
  assert_eq(@uri.can_parse("aaa:b", None), true)
}

///|
test "can_parse returns true for valid URL with path" {
  assert_eq(@uri.can_parse("aaa:/b", None), true)
}

///|
test "can_parse returns false for URL with invalid port" {
  assert_eq(@uri.can_parse("https://test:test", None), false)
}

///|
test "can_parse returns true for relative URL against valid base" {
  let base = @uri.parse("https://b/")
  assert_eq(@uri.can_parse("a", Some(base)), true)
}

///|
test "can_parse returns false when schemeless and no base" {
  assert_eq(@uri.can_parse("//example.com", None), false)
}

// ===== parse_maybe =====

///|
test "parse_maybe returns Some for valid absolute URL" {
  let result = @uri.parse_maybe("https://example.com/", None)
  assert_true(result is Some(_))
}

///|
test "parse_maybe returns None for invalid URL" {
  let result = @uri.parse_maybe("https://test:test", None)
  assert_true(result is None)
}

///|
test "parse_maybe returns Some with correct href" {
  let result = @uri.parse_maybe("http://example.com/path", None)
  match result {
    Some(url) => assert_eq(url.href(), "http://example.com/path")
    None => fail("expected Some but got None")
  }
}

///|
test "parse_maybe with base resolves relative URL" {
  let base = @uri.parse("https://example.com/")
  let result = @uri.parse_maybe("path", Some(base))
  match result {
    Some(url) => assert_eq(url.href(), "https://example.com/path")
    None => fail("expected Some but got None")
  }
}

// ===== to_json =====

///|
test "to_json returns the href string" {
  let url = @uri.parse("https://example.com/")
  assert_eq(url.to_json(), "https://example.com/")
}

///|
test "to_json equals href for complex URL" {
  let url = @uri.parse("http://user:pass@example.com:8080/path?query#hash")
  assert_eq(url.to_json(), url.href())
}
