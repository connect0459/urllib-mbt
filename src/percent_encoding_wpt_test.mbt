///|
// WPT percent-encoding.window.js — UTF-8 encoding cases only.
// Non-UTF-8 encodings (big5, euc-kr, windows-1252, etc.) are out of scope
// because the WHATWG URL parser always uses UTF-8.
//
// Verifies two WHATWG invariants:
//   1. Query: input characters are percent-encoded using the UTF-8 encode set
//   2. Fragment: always UTF-8 encoded, regardless of document encoding

test "WPT percent-encoding: UTF-8 query encoding" {
  let cases : Array[(String, String)] = [
    ("\u{2020}", "%E2%80%A0"),
    ("\u{000E}A", "%0EA"),
    ("\u{203E}\u{005C}", "%E2%80%BE\\"),
    ("\u{E5E5}", "%EE%97%A5"),
    ("\u{2212}", "%E2%88%92"),
    ("\u{00A2}", "%C2%A2"),
    ("á|", "%C3%A1|"),
  ]
  let failures : Array[String] = []
  for item in cases {
    let (input, expected) = item
    let url = @uri.parse("http://example.com/?\{input}")
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
  let cases : Array[(String, String)] = [
    ("\u{2020}", "%E2%80%A0"),
    ("\u{000E}A", "%0EA"),
    ("\u{203E}\u{005C}", "%E2%80%BE\\"),
    ("\u{E5E5}", "%EE%97%A5"),
    ("\u{2212}", "%E2%88%92"),
    ("\u{00A2}", "%C2%A2"),
    ("á|", "%C3%A1|"),
  ]
  let failures : Array[String] = []
  for item in cases {
    let (input, expected) = item
    let url = @uri.parse("http://example.com/#\{input}")
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
