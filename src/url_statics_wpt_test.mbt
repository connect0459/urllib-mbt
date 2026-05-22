// WPT url-statics-canparse.any.js (4/8 applicable — undefined url cases are JS-specific)
// WPT url-statics-parse.any.js (4/7 applicable — undefined url cases are JS-specific)
// WPT url-tojson.any.js (1/1)

///|
test "WPT url-statics-canparse: absolute non-special URL" {
  assert_eq(@uri.can_parse("aaa:b", None), true)
}

///|
test "WPT url-statics-canparse: non-special URL with hierarchical path" {
  assert_eq(@uri.can_parse("aaa:/b", None), true)
}

///|
test "WPT url-statics-canparse: URL with invalid port returns false" {
  assert_eq(@uri.can_parse("https://test:test", None), false)
}

///|
test "WPT url-statics-canparse: relative URL with valid base" {
  let base = @uri.parse("https://b/")
  assert_eq(@uri.can_parse("a", Some(base)), true)
}

///|
test "WPT url-statics-parse: absolute non-special URL returns Some" {
  assert_true(@uri.parse_maybe("aaa:b", None) is Some(_))
}

///|
test "WPT url-statics-parse: non-special URL with hierarchical path returns Some" {
  let result = @uri.parse_maybe("aaa:/b", None)
  assert_true(result is Some(_))
  assert_eq(result.unwrap().href(), "aaa:/b")
}

///|
test "WPT url-statics-parse: URL with invalid port returns None" {
  assert_true(@uri.parse_maybe("https://test:test", None) is None)
}

///|
test "WPT url-statics-parse: relative URL with base resolves correctly" {
  let base = @uri.parse("https://b/")
  let result = @uri.parse_maybe("a", Some(base))
  assert_true(result is Some(_))
  assert_eq(result.unwrap().href(), "https://b/a")
}

///|
test "WPT url-tojson: to_json returns the URL href string" {
  let url = @uri.parse("https://example.com/")
  assert_eq(url.to_json(), "https://example.com/")
}
