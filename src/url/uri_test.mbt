///|
test "can_parse returns true for valid absolute URL" {
  assert_eq(@url.can_parse("aaa:b", None), true)
}

///|
test "can_parse returns true for valid URL with path" {
  assert_eq(@url.can_parse("aaa:/b", None), true)
}

///|
test "can_parse returns false for URL with invalid port" {
  assert_eq(@url.can_parse("https://test:test", None), false)
}

///|
test "can_parse returns true for relative URL against valid base" {
  let base = @url.parse("https://b/")
  assert_eq(@url.can_parse("a", Some(base)), true)
}

///|
test "can_parse returns false when schemeless and no base" {
  assert_eq(@url.can_parse("//example.com", None), false)
}

///|
test "parse_maybe returns Some for valid absolute URL" {
  let result = @url.parse_maybe("https://example.com/", None)
  assert_true(result is Some(_))
}

///|
test "parse_maybe returns None for invalid URL" {
  let result = @url.parse_maybe("https://test:test", None)
  assert_true(result is None)
}

///|
test "parse_maybe returns Some with correct href" {
  let result = @url.parse_maybe("http://example.com/path", None)
  match result {
    Some(url) => assert_eq(url.href(), "http://example.com/path")
    None => fail("expected Some but got None")
  }
}

///|
test "parse_maybe with base resolves relative URL" {
  let base = @url.parse("https://example.com/")
  let result = @url.parse_maybe("path", Some(base))
  match result {
    Some(url) => assert_eq(url.href(), "https://example.com/path")
    None => fail("expected Some but got None")
  }
}

///|
test "to_json returns the href string" {
  let url = @url.parse("https://example.com/")
  assert_eq(url.to_json(), "https://example.com/")
}

///|
test "to_json equals href for complex URL" {
  let url = @url.parse("http://user:pass@example.com:8080/path?query#hash")
  assert_eq(url.to_json(), url.href())
}

///|
test "search_params returns empty params when URL has no query" {
  let url = @url.parse("http://example.com/path")
  assert_eq(url.search_params().to_string(), "")
}

///|
test "search_params returns empty params for empty query" {
  let url = @url.parse("http://example.com/path?")
  assert_eq(url.search_params().to_string(), "")
}

///|
test "search_params parses key-value pairs from query" {
  let url = @url.parse("http://example.com/path?a=b&c=d")
  let params = url.search_params()
  assert_eq(params.to_string(), "a=b&c=d")
  @debug.assert_eq(params.get("a"), Some("b"))
  @debug.assert_eq(params.get("c"), Some("d"))
}

///|
test "search_params: query starting with ? encodes it (no stripping)" {
  let url = @url.parse_with_base(
    "??a=b&c=d",
    Some(@url.parse("http://example.org/foo/bar")),
  )
  assert_eq(url.search_params().to_string(), "%3Fa=b&c=d")
}

///|
test "search_params: key without value yields empty-string value" {
  let url = @url.parse("http://foo.bar/baz?qux")
  assert_eq(url.search_params().to_string(), "qux=")
}

///|
test "search_params returns independent copy (mutations do not affect URL)" {
  let url = @url.parse("http://example.com/?a=b")
  let params = url.search_params()
  params.append("x", "y")
  assert_eq(url.search(), "?a=b")
  assert_eq(url.search_params().to_string(), "a=b")
}

///|
test "Show for Url outputs href" {
  let url = @url.parse("https://example.com/path?q=1#hash")
  assert_eq("\{url}", "https://example.com/path?q=1#hash")
}

///|
test "Show for Url works for opaque-path URL" {
  let url = @url.parse("mailto:user@example.com")
  assert_eq("\{url}", "mailto:user@example.com")
}

// ===== Url::join =====

///|
test "join resolves relative path against base" {
  let base = @url.parse("https://example.com/a/b/c")
  assert_eq(base.join("../d").href(), "https://example.com/a/d")
}

///|
test "join resolves absolute path against base" {
  let base = @url.parse("https://example.com/a/b")
  assert_eq(base.join("/x/y").href(), "https://example.com/x/y")
}

///|
test "join with different scheme overrides base entirely" {
  let base = @url.parse("https://example.com/a")
  assert_eq(base.join("https://other.com/b").href(), "https://other.com/b")
}

///|
test "join with query-only input replaces query" {
  let base = @url.parse("https://example.com/path?old=1")
  assert_eq(base.join("?new=2").href(), "https://example.com/path?new=2")
}

///|
test "join with fragment-only input replaces fragment" {
  let base = @url.parse("https://example.com/path#old")
  assert_eq(base.join("#new").href(), "https://example.com/path#new")
}

///|
test "join with empty string returns base href" {
  let base = @url.parse("https://example.com/path?q=1")
  assert_eq(base.join("").href(), "https://example.com/path?q=1")
}

///|
test "join raises for URL with invalid port" {
  let base = @url.parse("https://example.com/")
  let result : Result[@url.Url, @url.UrlParseError] = Ok(
    base.join("https://invalid:port"),
  ) catch {
    e => Err(e)
  }
  assert_true(result is Err(_))
}

// ===== Url::is_special =====

///|
test "is_special returns true for http URL" {
  assert_eq(@url.parse("http://example.com/").is_special(), true)
}

///|
test "is_special returns true for https URL" {
  assert_eq(@url.parse("https://example.com/").is_special(), true)
}

///|
test "is_special returns true for ftp URL" {
  assert_eq(@url.parse("ftp://example.com/").is_special(), true)
}

///|
test "is_special returns true for file URL" {
  assert_eq(@url.parse("file:///tmp/file").is_special(), true)
}

///|
test "is_special returns true for ws URL" {
  assert_eq(@url.parse("ws://example.com/").is_special(), true)
}

///|
test "is_special returns true for wss URL" {
  assert_eq(@url.parse("wss://example.com/").is_special(), true)
}

///|
test "is_special returns false for non-special scheme" {
  assert_eq(@url.parse("custom://example.com/").is_special(), false)
}

// ===== Url::has_credentials =====

///|
test "has_credentials returns false when no username or password" {
  assert_eq(@url.parse("https://example.com/").has_credentials(), false)
}

///|
test "has_credentials returns true when username is non-empty" {
  assert_eq(@url.parse("https://user@example.com/").has_credentials(), true)
}

///|
test "has_credentials returns true when both username and password are set" {
  assert_eq(
    @url.parse("https://user:pass@example.com/").has_credentials(),
    true,
  )
}

// ===== Url::has_opaque_path =====

///|
test "has_opaque_path returns false for hierarchical URL" {
  assert_eq(@url.parse("https://example.com/path").has_opaque_path(), false)
}

///|
test "has_opaque_path returns true for data URL" {
  assert_eq(@url.parse("data:text/html,Hello").has_opaque_path(), true)
}

///|
test "has_opaque_path returns true for mailto URL" {
  assert_eq(@url.parse("mailto:user@example.com").has_opaque_path(), true)
}

// ===== Url::scheme =====

///|
test "scheme returns scheme string without colon" {
  assert_eq(@url.parse("https://example.com/").scheme(), "https")
}

///|
test "scheme returns non-special scheme without colon" {
  assert_eq(@url.parse("custom://example.com/").scheme(), "custom")
}

///|
test "scheme returns file for file URL" {
  assert_eq(@url.parse("file:///tmp").scheme(), "file")
}

// ===== Url::username =====

///|
test "username returns empty string when no credentials" {
  assert_eq(@url.parse("https://example.com/").username(), "")
}

///|
test "username returns percent-encoded username" {
  assert_eq(@url.parse("https://user@example.com/").username(), "user")
}

///|
test "username returns username from user:pass URL" {
  assert_eq(@url.parse("https://user:pass@example.com/").username(), "user")
}

// ===== Url::password =====

///|
test "password returns empty string when no credentials" {
  assert_eq(@url.parse("https://example.com/").password(), "")
}

///|
test "password returns empty string for user-only credentials" {
  assert_eq(@url.parse("https://user@example.com/").password(), "")
}

///|
test "password returns password from user:pass URL" {
  assert_eq(@url.parse("https://user:pass@example.com/").password(), "pass")
}

// ===== Url::port =====

///|
test "port returns None for URL without explicit port" {
  let url = @url.parse("https://example.com/")
  assert_true(url.port() is None)
}

///|
test "port returns Some for URL with explicit port" {
  let url = @url.parse("https://example.com:8080/")
  assert_true(url.port() is Some(8080))
}

///|
test "port returns None when port matches default for scheme" {
  let url = @url.parse("https://example.com:443/")
  assert_true(url.port() is None)
}

///|
test "port returns Some for non-default port" {
  let url = @url.parse("http://example.com:8000/")
  assert_true(url.port() is Some(8000))
}

// ===== Url::path_segments =====

///|
fn collect_segments(url : @url.Url) -> Array[String]? {
  match url.path_segments() {
    None => None
    Some(iter) => {
      let arr : Array[String] = []
      for s in iter {
        arr.push(s)
      }
      Some(arr)
    }
  }
}

///|
test "path_segments returns None for opaque-path URL" {
  assert_true(collect_segments(@url.parse("mailto:user@example.com")) is None)
}

///|
test "path_segments returns None for data URL" {
  assert_true(collect_segments(@url.parse("data:text/html,Hello")) is None)
}

///|
test "path_segments returns single empty segment for root path" {
  let url = @url.parse("https://example.com/")
  @debug.assert_eq(collect_segments(url), Some(([""] : Array[String])))
}

///|
test "path_segments returns segments for multi-segment path" {
  let url = @url.parse("https://example.com/a/b/c")
  @debug.assert_eq(
    collect_segments(url),
    Some((["a", "b", "c"] : Array[String])),
  )
}

///|
test "path_segments includes trailing empty segment for trailing slash" {
  let url = @url.parse("https://example.com/a/b/")
  @debug.assert_eq(
    collect_segments(url),
    Some((["a", "b", ""] : Array[String])),
  )
}

///|
test "path_segments returns empty iterator for non-special URL with no path" {
  let url = @url.parse("sc://example.com")
  @debug.assert_eq(collect_segments(url), Some(([] : Array[String])))
}

///|
test "path_segments returns percent-encoded segment values as-is" {
  let url = @url.parse("https://example.com/hello%20world")
  @debug.assert_eq(
    collect_segments(url),
    Some((["hello%20world"] : Array[String])),
  )
}

///|
test "path_segments returns Some for file URL" {
  let url = @url.parse("file:///usr/local/bin")
  @debug.assert_eq(
    collect_segments(url),
    Some((["usr", "local", "bin"] : Array[String])),
  )
}

// ===== domain_to_ascii =====

///|
test "domain_to_ascii: ASCII domain lowercased" {
  assert_eq(@url.domain_to_ascii("gOoGle.com"), "google.com")
}

///|
test "domain_to_ascii: Unicode domain encodes to Punycode" {
  assert_eq(@url.domain_to_ascii("ẞ.com"), "xn--zca.com")
}

///|
test "domain_to_ascii: already-ACE label unchanged" {
  assert_eq(@url.domain_to_ascii("xn--zca.com"), "xn--zca.com")
}

///|
test "domain_to_ascii: empty input returns empty string" {
  assert_eq(@url.domain_to_ascii(""), "")
}

// ===== domain_to_unicode =====

///|
test "domain_to_unicode: ACE label decodes to Unicode" {
  assert_eq(@url.domain_to_unicode("xn--zca.com"), "ß.com")
}

///|
test "domain_to_unicode: ASCII domain unchanged" {
  assert_eq(@url.domain_to_unicode("google.com"), "google.com")
}

///|
test "domain_to_unicode: roundtrip from Unicode input" {
  assert_eq(@url.domain_to_unicode("ẞ.com"), "ß.com")
}

///|
test "domain_to_unicode: empty input returns empty string" {
  assert_eq(@url.domain_to_unicode(""), "")
}
