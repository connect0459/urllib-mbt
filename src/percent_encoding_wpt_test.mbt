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
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (input, expected) = item
    let url = @uri.parse("http://example.com/?\{input}")
    let got = url.search()
    if got == "?\{expected}" {
      passed = passed + 1
    } else {
      if failed < 10 {
        println("FAIL query: input=\{input} expected=?\{expected} got=\{got}")
      }
      failed = failed + 1
    }
  }
  println("WPT percent-encoding/query: \{passed}/\{cases.length()} passed")
  assert_eq(failed, 0)
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
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (input, expected) = item
    let url = @uri.parse("http://example.com/#\{input}")
    let got = url.hash()
    if got == "#\{expected}" {
      passed = passed + 1
    } else {
      if failed < 10 {
        println(
          "FAIL fragment: input=\{input} expected=#\{expected} got=\{got}",
        )
      }
      failed = failed + 1
    }
  }
  println("WPT percent-encoding/fragment: \{passed}/\{cases.length()} passed")
  assert_eq(failed, 0)
}
