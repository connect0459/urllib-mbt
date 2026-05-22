///|
test "WPT urlencoded-parser: URLSearchParams constructed from string" {
  let cases : Array[(String, Array[(String, String)])] = [
    ("test", [("test", "")]),
    ("\u{FEFF}test=\u{FEFF}", [("\u{FEFF}test", "\u{FEFF}")]),
    ("%EF%BB%BFtest=%EF%BB%BF", [("\u{FEFF}test", "\u{FEFF}")]),
    ("%EF%BF%BF=%EF%BF%BF", [("\u{FFFF}", "\u{FFFF}")]),
    ("%FE%FF", [("\u{FFFD}\u{FFFD}", "")]),
    ("%FF%FE", [("\u{FFFD}\u{FFFD}", "")]),
    ("\u{2020}&\u{2020}=x", [("\u{2020}", ""), ("\u{2020}", "x")]),
    ("%C2", [("\u{FFFD}", "")]),
    ("%C2x", [("\u{FFFD}x", "")]),
    (
      "_charset_=windows-1252&test=%C2x",
      [("_charset_", "windows-1252"), ("test", "\u{FFFD}x")],
    ),
    ("", []),
    ("a", [("a", "")]),
    ("a=b", [("a", "b")]),
    ("a=", [("a", "")]),
    ("=b", [("", "b")]),
    ("&", []),
    ("&a", [("a", "")]),
    ("a&", [("a", "")]),
    ("a&a", [("a", ""), ("a", "")]),
    ("a&b&c", [("a", ""), ("b", ""), ("c", "")]),
    ("a=b&c=d", [("a", "b"), ("c", "d")]),
    ("a=b&c=d&", [("a", "b"), ("c", "d")]),
    ("&&&a=b&&&&c=d&", [("a", "b"), ("c", "d")]),
    ("a=a&a=b&a=c", [("a", "a"), ("a", "b"), ("a", "c")]),
    ("a==a", [("a", "=a")]),
    ("a=a+b+c+d", [("a", "a b c d")]),
    ("%=a", [("%", "a")]),
    ("%a=a", [("%a", "a")]),
    ("%a_=a", [("%a_", "a")]),
    ("%61=a", [("a", "a")]),
    ("%61+%4d%4D=", [("a MM", "")]),
    ("id=0&value=%", [("id", "0"), ("value", "%")]),
    ("b=%2sf%2a", [("b", "%2sf*")]),
    ("b=%2%2af%2a", [("b", "%2*f*")]),
    ("b=%%2a", [("b", "%*")]),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (input, expected) = item
    let params = @uri.UrlSearchParams::from_string(input)
    let actual : Array[(String, String)] = []
    params.for_each(fn(name, value) { actual.push((name, value)) })
    if actual == expected {
      passed = passed + 1
    } else {
      if failed < 10 {
        println(
          "FAIL: input=\{input} expected_len=\{expected.length()} actual_len=\{actual.length()}",
        )
      }
      failed = failed + 1
    }
  }
  println("WPT urlencoded-parser: \{passed}/\{cases.length()} passed")
  assert_eq(failed, 0)
}
