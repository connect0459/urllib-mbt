///|
fn load_percent_encoding_utf8_cases() -> Array[(String, String)] raise {
  let content = @fs.read_file_to_string("resources/percent-encoding.json")
  let json = @json.parse(content)
  let items = match json {
    Array(a) => a
    _ => fail("expected JSON array")
  }
  let cases : Array[(String, String)] = []
  for item in items {
    match item {
      Object(obj) => {
        let input = match obj.get("input") {
          Some(String(s)) => s
          _ => fail("missing or non-string 'input' field")
        }
        let utf8 = match obj.get("output") {
          Some(Object(output)) =>
            match output.get("utf-8") {
              Some(String(s)) => s
              _ => fail("missing 'utf-8' in output")
            }
          _ => fail("unexpected 'output' field type")
        }
        cases.push((input, utf8))
      }
      _ => ()
    }
  }
  cases
}

///|
test "WPT percent-encoding: UTF-8 query encoding" {
  let cases = load_percent_encoding_utf8_cases()
  let failures : Array[String] = []
  for item in cases {
    let (input, expected) = item
    let url = @url.parse("http://example.com/?\{input}")
    let got = url.search()
    if got != "?\{expected}" {
      failures.push(
        "FAIL query: input=\{input} expected=?\{expected} got=\{got}",
      )
    }
  }
  let n = if failures.length() < 10 { failures.length() } else { 10 }
  for i in 0..<n {
    println(failures[i])
  }
  println(
    "WPT percent-encoding/query: \{cases.length() - failures.length()}/\{cases.length()} passed",
  )
  assert_eq(failures.length(), 0)
}

///|
test "WPT percent-encoding: UTF-8 fragment encoding" {
  let cases = load_percent_encoding_utf8_cases()
  let failures : Array[String] = []
  for item in cases {
    let (input, expected) = item
    let url = @url.parse("http://example.com/#\{input}")
    let got = url.hash()
    if got != "#\{expected}" {
      failures.push(
        "FAIL fragment: input=\{input} expected=#\{expected} got=\{got}",
      )
    }
  }
  let n = if failures.length() < 10 { failures.length() } else { 10 }
  for i in 0..<n {
    println(failures[i])
  }
  println(
    "WPT percent-encoding/fragment: \{cases.length() - failures.length()}/\{cases.length()} passed",
  )
  assert_eq(failures.length(), 0)
}
