///|
fn to_repr_idna(s : String?) -> String {
  match s {
    None => "None"
    Some(v) => "Some(\{v})"
  }
}

///|
test "WPT IdnaTestV2: domain-to-ascii cases" {
  let content = @fs.read_file_to_string("wpt/url/resources/IdnaTestV2.json")
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
        if input == "" {
          continue
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
        "FAIL: input=\{input}\n  expected=\{to_repr_idna(expected)}\n  actual=\{to_repr_idna(actual)}",
      )
    }
  }
  let total = cases.length()
  let passed = total - failures.length()
  let n = if failures.length() < 10 { failures.length() } else { 10 }
  for i in 0..<n {
    println(failures[i])
  }
  println("WPT IdnaTestV2: \{passed}/\{total} passed")
  assert_eq(failures.length(), 0)
}
