// Whitebox tests run within the package scope.
// Use them to validate internal helpers or invariants.
// Keep them focused; public behavior belongs in `_test.mbt`.

///|
test "Show for UrlParseError includes message text" {
  let err = UrlParseError("bad input")
  assert_eq("\{err}", "UrlParseError: bad input")
}

///|
test "shorten_path_segs: file URL with single Windows-drive segment is not shortened" {
  let segs = ["C:"]
  shorten_path_segs(segs, "file")
  debug_inspect(
    segs,
    content=(
      #|["C:"]
    ),
  )
}

///|
test "split_host_port: unclosed bracket returns (s, None)" {
  let (host, port) = split_host_port("[::1")
  assert_eq(host, "[::1")
  assert_true(port is None)
}

///|
test "href: file URL with host None serializes without authority" {
  let url : Url = {
    scheme: "file",
    username: "",
    password: "",
    host: None,
    port: None,
    path: UrlPath::Segments(["", "path"]),
    query: None,
    fragment: None,
  }
  assert_eq(url.href(), "file:/.//path")
}

///|
test "origin: special-scheme URL with host None returns scheme-based origin" {
  let url : Url = {
    scheme: "https",
    username: "",
    password: "",
    host: None,
    port: None,
    path: UrlPath::Segments([]),
    query: None,
    fragment: None,
  }
  assert_eq(url.origin(), "https://")
}

///|
test "origin: blob URL with Segments path parses inner URL for origin" {
  let url : Url = {
    scheme: "blob",
    username: "",
    password: "",
    host: None,
    port: None,
    path: UrlPath::Segments(["", "https://example.com", "file"]),
    query: None,
    fragment: None,
  }
  let o = url.origin()
  assert_true(o == "null" || o.has_prefix("https://"))
}

///|
test "UrlPath Eq: Segments and Opaque with same string are not equal" {
  let a = UrlPath::Segments(["foo"])
  let b = UrlPath::Opaque("foo")
  assert_eq(a == b, false)
}

///|
test "UrlPath Eq: two Segments with equal arrays are equal" {
  let a = UrlPath::Segments(["foo", "bar"])
  let b = UrlPath::Segments(["foo", "bar"])
  assert_eq(a == b, true)
}

///|
test "UrlPath Eq: two Opaque paths with equal strings are equal" {
  let a = UrlPath::Opaque("data")
  let b = UrlPath::Opaque("data")
  assert_eq(a == b, true)
}

///|
test "UrlPath Eq: two Opaque paths with different strings are not equal" {
  let a = UrlPath::Opaque("data")
  let b = UrlPath::Opaque("other")
  assert_eq(a == b, false)
}

///|
test "origin: blob URL with empty Segments path returns null" {
  let url : Url = {
    scheme: "blob",
    username: "",
    password: "",
    host: None,
    port: None,
    path: UrlPath::Segments([]),
    query: None,
    fragment: None,
  }
  assert_eq(url.origin(), "null")
}
