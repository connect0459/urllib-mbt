///|
test "exact pathname match succeeds" {
  let p = try! UrlPattern::from_init(
    UrlPatternInit::new(pathname=Some("/foo/bar")),
  )
  let result = p.exec_init(UrlPatternInit::new(pathname=Some("/foo/bar")))
  assert_true(result is Some(_))
  guard result is Some(r) else { fail("expected match") }
  guard r.pathname is Some(pr) else { fail("expected pathname result") }
  assert_eq(pr.input, "/foo/bar")
  assert_eq(pr.groups.length(), 0)
}

///|
test "exact pathname match fails on different path" {
  let p = try! UrlPattern::from_init(
    UrlPatternInit::new(pathname=Some("/foo/bar")),
  )
  let result = p.exec_init(UrlPatternInit::new(pathname=Some("/foo/ba")))
  assert_true(result is None)
}

///|
test "wildcard pathname matches anything" {
  let p = try! UrlPattern::from_init(UrlPatternInit::new(pathname=Some("*")))
  let result = p.exec_init(UrlPatternInit::new(pathname=Some("/foo/bar/baz")))
  assert_true(result is Some(_))
  guard result is Some(r) else { fail("expected match") }
  guard r.pathname is Some(pr) else { fail("expected pathname result") }
  assert_eq(pr.input, "/foo/bar/baz")
  match pr.groups.get("0") {
    Some(Some(v)) => assert_eq(v, "/foo/bar/baz")
    _ => fail("expected group 0 = '/foo/bar/baz'")
  }
}

///|
test "named group :bar captures segment" {
  let p = try! UrlPattern::from_init(
    UrlPatternInit::new(pathname=Some("/foo/:bar")),
  )
  let result = p.exec_init(UrlPatternInit::new(pathname=Some("/foo/hello")))
  assert_true(result is Some(_))
  guard result is Some(r) else { fail("expected match") }
  guard r.pathname is Some(pr) else { fail("expected pathname result") }
  assert_eq(pr.input, "/foo/hello")
  match pr.groups.get("bar") {
    Some(Some(v)) => assert_eq(v, "hello")
    _ => fail("expected group bar = 'hello'")
  }
}

///|
test "named group :bar does not match across slash" {
  let p = try! UrlPattern::from_init(
    UrlPatternInit::new(pathname=Some("/foo/:bar")),
  )
  let result = p.exec_init(UrlPatternInit::new(pathname=Some("/foo/a/b")))
  assert_true(result is None)
}

// ===== ignoreCase =====

///|
test "ignoreCase: exact pathname match succeeds case-insensitively" {
  let p = try! UrlPattern::from_init(
    UrlPatternInit::new(pathname=Some("/foo/bar")),
    ignore_case=true,
  )
  let result = p.exec_init(UrlPatternInit::new(pathname=Some("/FOO/BAR")))
  assert_true(result is Some(_))
}

///|
test "ignoreCase: exact pathname does not match when flag is false" {
  let p = try! UrlPattern::from_init(
    UrlPatternInit::new(pathname=Some("/foo/bar")),
  )
  let result = p.exec_init(UrlPatternInit::new(pathname=Some("/FOO/BAR")))
  assert_true(result is None)
}

///|
test "ignoreCase: named group captures uppercase input" {
  let p = try! UrlPattern::from_init(
    UrlPatternInit::new(pathname=Some("/foo/:name")),
    ignore_case=true,
  )
  let result = p.exec_init(UrlPatternInit::new(pathname=Some("/FOO/HELLO")))
  assert_true(result is Some(_))
  guard result is Some(r) else { fail("expected match") }
  guard r.pathname is Some(pr) else { fail("expected pathname result") }
  match pr.groups.get("name") {
    Some(Some(v)) => assert_eq(v, "HELLO")
    _ => fail("expected group name = 'HELLO'")
  }
}

///|
test "ignoreCase: from_string matches uppercase input" {
  let p = try! UrlPattern::from_string(
    "https://example.com/foo",
    None,
    ignore_case=true,
  )
  let result = p.exec_url("https://example.com/FOO")
  assert_true(result is Some(_))
}

///|
test "ignoreCase: from_string without flag does not match uppercase" {
  let p = try! UrlPattern::from_string("https://example.com/foo", None)
  let result = p.exec_url("https://example.com/FOO")
  assert_true(result is None)
}

///|
test "custom regexp group (.*) captures greedily" {
  let p = try! UrlPattern::from_init(
    UrlPatternInit::new(pathname=Some("/foo/(.*)")),
  )
  let result = p.exec_init(UrlPatternInit::new(pathname=Some("/foo/bar/baz")))
  assert_true(result is Some(_))
  guard result is Some(r) else { fail("expected match") }
  guard r.pathname is Some(pr) else { fail("expected pathname result") }
  match pr.groups.get("0") {
    Some(Some(v)) => assert_eq(v, "bar/baz")
    _ => fail("expected group 0 = 'bar/baz'")
  }
}
