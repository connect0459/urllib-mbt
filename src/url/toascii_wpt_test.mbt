///|
test "WPT toascii: domain-to-ascii cases" {
  let content = @fs.read_file_to_string("resources/url/toascii.json")
  let json = @json.parse(content)
  let items = match json {
    Array(a) => a
    _ => fail("expected JSON array")
  }
  let cases : Array[(String, String?)] = []
  for item in items {
    match item {
      Object(obj) => {
        let input = match obj.get("input") {
          Some(String(s)) => s
          _ => fail("missing or non-string 'input' field")
        }
        let expected : String? = match obj.get("output") {
          Some(String(s)) => Some(s)
          Some(Null) => None
          _ => fail("unexpected 'output' field type")
        }
        cases.push((input, expected))
      }
      _ => ()
    }
  }
  let failures : Array[String] = []
  for item in cases {
    let (input, expected) = item
    let url_str = "https://" + input + "/x"
    let result = @url.parse_maybe(url_str, None)
    let actual = match result {
      None => None
      Some(url) => Some(url.hostname())
    }
    if actual != expected {
      failures.push(
        "FAIL toascii: input=\{input}\n  expected=\{to_repr(expected)}\n  actual=\{to_repr(actual)}",
      )
    }
  }
  let n = if failures.length() < 10 { failures.length() } else { 10 }
  for i = 0; i < n; i = i + 1 {
    println(failures[i])
  }
  println(
    "WPT toascii: \{cases.length() - failures.length()}/\{cases.length()} passed",
  )
  assert_eq(failures.length(), 0)
}
