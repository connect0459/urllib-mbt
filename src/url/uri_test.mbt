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
