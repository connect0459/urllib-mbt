///|
test "WPT toascii: domain-to-ascii cases" {
  let cases : Array[(String, String?)] = [
    ("aa--", Some("aa--")),
    ("a\u{2020}--", Some("xn--a---kp0a")),
    ("ab--c", Some("ab--c")),
    ("-x", Some("-x")),
    ("-\u{2020}", Some("xn----xhn")),
    ("-x.xn--zca", Some("-x.xn--zca")),
    ("-x.\u{00DF}", Some("-x.xn--zca")),
    ("x-.xn--zca", Some("x-.xn--zca")),
    ("x-.\u{00DF}", Some("x-.xn--zca")),
    ("x..xn--zca", Some("x..xn--zca")),
    ("x..\u{00DF}", Some("x..xn--zca")),
    ("xn--a", None),
    ("xn--a.xn--zca", None),
    ("xn--a.\u{00DF}", None),
    ("xn--ls8h=", None),
    ("xn--te\u{0161}la", None),
    ("xn--zca.xn--zca", Some("xn--zca.xn--zca")),
    ("xn--zca.\u{00DF}", Some("xn--zca.xn--zca")),
    ("ab--c.xn--zca", Some("ab--c.xn--zca")),
    ("ab--c.\u{00DF}", Some("ab--c.xn--zca")),
    ("\u{200D}.example", None),
    ("xn--1ug.example", None),
    ("\u{064A}a", None),
    ("xn--a-yoc", None),
    ("\u{0DC1}\u{0DCA}\u{200D}\u{0DBB}\u{0DD3}", Some("xn--10cl1a0b660p")),
    (
      "\u{0646}\u{0627}\u{0645}\u{0647}\u{200C}\u{0627}\u{06CC}",
      Some("xn--mgba3gch31f060k"),
    ),
    ("\u{FFFD}.com", None),
    ("xn--zn7c.com", None),
    (
      "x01234567890123456789012345678901234567890123456789012345678901x",
      Some("x01234567890123456789012345678901234567890123456789012345678901x"),
    ),
    (
      "x01234567890123456789012345678901234567890123456789012345678901\u{2020}",
      Some(
        "xn--x01234567890123456789012345678901234567890123456789012345678901-6963b",
      ),
    ),
    (
      "x01234567890123456789012345678901234567890123456789012345678901x.xn--zca",
      Some(
        "x01234567890123456789012345678901234567890123456789012345678901x.xn--zca",
      ),
    ),
    (
      "x01234567890123456789012345678901234567890123456789012345678901x.\u{00DF}",
      Some(
        "x01234567890123456789012345678901234567890123456789012345678901x.xn--zca",
      ),
    ),
    (
      "01234567890123456789012345678901234567890123456789.01234567890123456789012345678901234567890123456789.01234567890123456789012345678901234567890123456789.01234567890123456789012345678901234567890123456789.0123456789012345678901234567890123456789012345678.x",
      Some(
        "01234567890123456789012345678901234567890123456789.01234567890123456789012345678901234567890123456789.01234567890123456789012345678901234567890123456789.01234567890123456789012345678901234567890123456789.0123456789012345678901234567890123456789012345678.x",
      ),
    ),
    (
      "01234567890123456789012345678901234567890123456789.01234567890123456789012345678901234567890123456789.01234567890123456789012345678901234567890123456789.01234567890123456789012345678901234567890123456789.0123456789012345678901234567890123456789012345678.xn--zca",
      Some(
        "01234567890123456789012345678901234567890123456789.01234567890123456789012345678901234567890123456789.01234567890123456789012345678901234567890123456789.01234567890123456789012345678901234567890123456789.0123456789012345678901234567890123456789012345678.xn--zca",
      ),
    ),
    (
      "01234567890123456789012345678901234567890123456789.01234567890123456789012345678901234567890123456789.01234567890123456789012345678901234567890123456789.01234567890123456789012345678901234567890123456789.0123456789012345678901234567890123456789012345678.\u{00DF}",
      Some(
        "01234567890123456789012345678901234567890123456789.01234567890123456789012345678901234567890123456789.01234567890123456789012345678901234567890123456789.01234567890123456789012345678901234567890123456789.0123456789012345678901234567890123456789012345678.xn--zca",
      ),
    ),
    ("a\u{00AD}b", Some("ab")),
    ("\u{2260}", Some("xn--1ch")),
    ("\u{226E}", Some("xn--gdh")),
    ("\u{226F}", Some("xn--hdh")),
    ("=\u{0338}", Some("xn--1ch")),
    ("<\u{0338}", Some("xn--gdh")),
    (">\u{0338}", Some("xn--hdh")),
    ("=\u{00AD}\u{0338}", Some("xn--1ch")),
    ("<\u{00AD}\u{0338}", Some("xn--gdh")),
    (">\u{00AD}\u{0338}", Some("xn--hdh")),
    ("fa\u{00DF}.de", Some("xn--fa-hia.de")),
    ("\u{03B2}\u{03CC}\u{03BB}\u{03BF}\u{03C2}.com", Some("xn--nxasmm1c.com")),
    (
      "\u{0DC1}\u{0DCA}\u{200D}\u{0DBB}\u{0DD3}.com",
      Some("xn--10cl1a0b660p.com"),
    ),
    (
      "\u{0646}\u{0627}\u{0645}\u{0647}\u{200C}\u{0627}\u{06CC}.com",
      Some("xn--mgba3gch31f060k.com"),
    ),
    ("www.loo\u{0138}out.net", Some("www.xn--looout-5bb.net")),
    ("\u{15EF}\u{15EF}\u{15EF}.lookout.net", Some("xn--1qeaa.lookout.net")),
    ("www.lookout.\u{0441}\u{043E}\u{043C}", Some("www.lookout.xn--l1adi")),
    ("www\u{2025}lookout.net", None),
    ("www.lookout\u{2027}net", Some("www.xn--lookoutnet-406e")),
    ("www.lookout.net\u{2A74}80", None),
    ("www\u{00A0}.lookout.net", None),
    ("\u{1680}lookout.net", None),
    ("\u{001F}lookout.net", None),
    ("look\u{06DD}out.net", None),
    ("look\u{180E}out.net", Some("lookout.net")),
    ("look\u{2060}out.net", Some("lookout.net")),
    ("look\u{FEFF}out.net", Some("lookout.net")),
    ("look\u{1FFFE}out.net", None),
    ("look\u{FFFA}out.net", None),
    ("look\u{2FF0}out.net", None),
    ("look\u{0341}out.net", Some("xn--looout-kp7b.net")),
    ("look\u{202E}out.net", None),
    ("look\u{206B}out.net", Some("lookout.net")),
    ("look\u{E0001}out.net", None),
    ("look\u{E0020}out.net", None),
    ("look\u{05BE}out.net", None),
    ("B\u{00FC}cher.de", Some("xn--bcher-kva.de")),
    ("\u{2665}.net", Some("xn--g6h.net")),
    ("\u{0378}.net", None),
    ("\u{04C0}.com", Some("xn--s5a.com")),
    ("\u{2F868}.com", Some("xn--snl.com")),
    ("\u{2183}.com", Some("xn--r5g.com")),
    ("look\u{034F}out.net", Some("lookout.net")),
    ("gOoGle.com", Some("google.com")),
    ("\u{09DC}.com", Some("xn--15b8c.com")),
    ("\u{1E9E}.com", Some("xn--zca.com")),
    ("\u{1E9E}.foo.com", Some("xn--zca.foo.com")),
    ("-foo.bar.com", Some("-foo.bar.com")),
    ("foo-.bar.com", Some("foo-.bar.com")),
    ("ab--cd.com", Some("ab--cd.com")),
    ("xn--0.com", None),
    ("foo\u{0300}.bar.com", Some("xn--fo-3ja.bar.com")),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (input, expected) = item
    let url_str = "https://" + input + "/x"
    let result = @uri.parse_maybe(url_str, None)
    let actual = match result {
      None => None
      Some(url) => Some(url.hostname())
    }
    if actual == expected {
      passed = passed + 1
    } else {
      println("FAIL toascii: input=\{input}")
      println("  expected=\{expected}")
      println("  actual=\{actual}")
      failed = failed + 1
    }
  }
  println("WPT toascii: \{passed}/\{cases.length()} passed")
  assert_eq(failed, 0)
}
