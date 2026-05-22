// WPT urlsearchparams-append.any.js

///|
test "WPT urlsearchparams-append: Append same name" {
  let p = @uri.UrlSearchParams::new()
  p.append("a", "b")
  assert_eq(p.to_string(), "a=b")
  p.append("a", "b")
  assert_eq(p.to_string(), "a=b&a=b")
  p.append("a", "c")
  assert_eq(p.to_string(), "a=b&a=b&a=c")
}

///|
test "WPT urlsearchparams-append: Append empty strings" {
  let p = @uri.UrlSearchParams::new()
  p.append("", "")
  assert_eq(p.to_string(), "=")
  p.append("", "")
  assert_eq(p.to_string(), "=&=")
}

///|
test "WPT urlsearchparams-append: Append multiple" {
  let p = @uri.UrlSearchParams::new()
  p.append("first", "1")
  p.append("second", "2")
  p.append("third", "")
  p.append("first", "10")
  assert_eq(p.has("first"), true)
  assert_eq(p.get("first"), Some("1"))
  assert_eq(p.get("second"), Some("2"))
  assert_eq(p.get("third"), Some(""))
  p.append("first", "10")
  assert_eq(p.get("first"), Some("1"))
}

// WPT urlsearchparams-constructor.any.js

///|
test "WPT urlsearchparams-constructor: Basic URLSearchParams construction" {
  let p = @uri.UrlSearchParams::new()
  assert_eq(p.to_string(), "")
  let p2 = @uri.UrlSearchParams::from_string("a=b")
  assert_eq(p2.to_string(), "a=b")
}

///|
test "WPT urlsearchparams-constructor: no arguments" {
  let p = @uri.UrlSearchParams::new()
  assert_eq(p.to_string(), "")
}

///|
test "WPT urlsearchparams-constructor: remove leading question mark" {
  let p = @uri.UrlSearchParams::from_string("?a=b")
  assert_eq(p.to_string(), "a=b")
}

///|
test "WPT urlsearchparams-constructor: string parsing edge cases" {
  let p = @uri.UrlSearchParams::from_string("a=b")
  assert_eq(p.has("a"), true)
  assert_eq(p.has("b"), false)
  let p2 = @uri.UrlSearchParams::from_string("a=b&c")
  assert_eq(p2.has("a"), true)
  assert_eq(p2.has("c"), true)
  let p3 = @uri.UrlSearchParams::from_string("&a&&& &&&&&a+b=& c&m%c3%b8%c3%b8")
  assert_eq(p3.has("a"), true)
  assert_eq(p3.has("a b"), true)
  assert_eq(p3.has(" "), true)
  assert_eq(p3.has("c"), false)
  assert_eq(p3.has(" c"), true)
  assert_eq(p3.has("møø"), true)
  let p4 = @uri.UrlSearchParams::from_string("id=0&value=%")
  assert_eq(p4.has("id"), true)
  assert_eq(p4.has("value"), true)
  assert_eq(p4.get("id"), Some("0"))
  assert_eq(p4.get("value"), Some("%"))
}

///|
test "WPT urlsearchparams-constructor: Parse +" {
  let p = @uri.UrlSearchParams::from_string("a=b+c")
  assert_eq(p.get("a"), Some("b c"))
  let p2 = @uri.UrlSearchParams::from_string("a+b=c")
  assert_eq(p2.get("a b"), Some("c"))
}

///|
test "WPT urlsearchparams-constructor: Parse encoded +" {
  let p = @uri.UrlSearchParams::new()
  p.set("query", "+15555555555")
  let p2 = @uri.UrlSearchParams::from_string(p.to_string())
  assert_eq(p.to_string(), "query=%2B15555555555")
  assert_eq(p.get("query"), Some("+15555555555"))
  assert_eq(p2.get("query"), Some("+15555555555"))
}

///|
test "WPT urlsearchparams-constructor: Parse space" {
  let p = @uri.UrlSearchParams::from_string("a=b c")
  assert_eq(p.get("a"), Some("b c"))
  let p2 = @uri.UrlSearchParams::from_string("a b=c")
  assert_eq(p2.get("a b"), Some("c"))
}

///|
test "WPT urlsearchparams-constructor: Parse %20" {
  let p = @uri.UrlSearchParams::from_string("a=b%20c")
  assert_eq(p.get("a"), Some("b c"))
  let p2 = @uri.UrlSearchParams::from_string("a%20b=c")
  assert_eq(p2.get("a b"), Some("c"))
}

///|
test "WPT urlsearchparams-constructor: Parse NUL byte literal" {
  let p = @uri.UrlSearchParams::from_string("a=b\u{0000}c")
  assert_eq(p.get("a"), Some("b\u{0000}c"))
  let p2 = @uri.UrlSearchParams::from_string("a\u{0000}b=c")
  assert_eq(p2.get("a\u{0000}b"), Some("c"))
}

///|
test "WPT urlsearchparams-constructor: Parse %00 as NUL" {
  let p = @uri.UrlSearchParams::from_string("a=b%00c")
  assert_eq(p.get("a"), Some("b\u{0000}c"))
  let p2 = @uri.UrlSearchParams::from_string("a%00b=c")
  assert_eq(p2.get("a\u{0000}b"), Some("c"))
}

///|
test "WPT urlsearchparams-constructor: Parse U+2384 COMPOSITION SYMBOL literal" {
  let p = @uri.UrlSearchParams::from_string("a=b\u{2384}")
  assert_eq(p.get("a"), Some("b\u{2384}"))
  let p2 = @uri.UrlSearchParams::from_string("a\u{2384}b=c")
  assert_eq(p2.get("a\u{2384}b"), Some("c"))
}

///|
test "WPT urlsearchparams-constructor: Parse %e2%8e%84 as U+2384" {
  let p = @uri.UrlSearchParams::from_string("a=b%e2%8e%84")
  assert_eq(p.get("a"), Some("b\u{2384}"))
  let p2 = @uri.UrlSearchParams::from_string("a%e2%8e%84b=c")
  assert_eq(p2.get("a\u{2384}b"), Some("c"))
}

///|
test "WPT urlsearchparams-constructor: Parse U+1F4A9 PILE OF POO literal" {
  let p = @uri.UrlSearchParams::from_string("a=b\u{1F4A9}c")
  assert_eq(p.get("a"), Some("b\u{1F4A9}c"))
  let p2 = @uri.UrlSearchParams::from_string("a\u{1F4A9}b=c")
  assert_eq(p2.get("a\u{1F4A9}b"), Some("c"))
}

///|
test "WPT urlsearchparams-constructor: Parse %f0%9f%92%a9 as U+1F4A9" {
  let p = @uri.UrlSearchParams::from_string("a=b%f0%9f%92%a9c")
  assert_eq(p.get("a"), Some("b\u{1F4A9}c"))
  let p2 = @uri.UrlSearchParams::from_string("a%f0%9f%92%a9b=c")
  assert_eq(p2.get("a\u{1F4A9}b"), Some("c"))
}

// WPT urlsearchparams-delete.any.js

///|
test "WPT urlsearchparams-delete: Delete basics" {
  let p = @uri.UrlSearchParams::from_string("a=b&c=d")
  p.delete("a")
  assert_eq(p.to_string(), "c=d")
  let p2 = @uri.UrlSearchParams::from_string("a=a&b=b&a=a&c=c")
  p2.delete("a")
  assert_eq(p2.to_string(), "b=b&c=c")
  let p3 = @uri.UrlSearchParams::from_string("a=a&=&b=b&c=c")
  p3.delete("")
  assert_eq(p3.to_string(), "a=a&b=b&c=c")
  let p4 = @uri.UrlSearchParams::from_string("a=a&null=null&b=b")
  p4.delete("null")
  assert_eq(p4.to_string(), "a=a&b=b")
}

///|
test "WPT urlsearchparams-delete: Deleting appended multiple" {
  let p = @uri.UrlSearchParams::new()
  p.append("first", "1")
  assert_eq(p.has("first"), true)
  assert_eq(p.get("first"), Some("1"))
  p.delete("first")
  assert_eq(p.has("first"), false)
  p.append("first", "1")
  p.append("first", "10")
  p.delete("first")
  assert_eq(p.has("first"), false)
}

///|
test "WPT urlsearchparams-delete: Two-argument delete" {
  let p = @uri.UrlSearchParams::new()
  p.append("a", "b")
  p.append("a", "c")
  p.append("a", "d")
  p.delete_entry("a", "c")
  assert_eq(p.to_string(), "a=b&a=d")
}

///|
test "WPT urlsearchparams-delete: Two-argument delete across names" {
  let p = @uri.UrlSearchParams::new()
  p.append("a", "b")
  p.append("a", "c")
  p.append("b", "c")
  p.append("b", "d")
  p.delete_entry("b", "c")
  p.delete("a")
  assert_eq(p.to_string(), "b=d")
}

// WPT urlsearchparams-foreach.any.js

///|
test "WPT urlsearchparams-foreach: ForEach visits all pairs in order" {
  let p = @uri.UrlSearchParams::from_string("a=1&b=2&c=3")
  let keys : Array[String] = []
  let values : Array[String] = []
  p.for_each(fn(name, value) {
    keys.push(name)
    values.push(value)
  })
  assert_eq(keys, ["a", "b", "c"])
  assert_eq(values, ["1", "2", "3"])
}

///|
test "WPT urlsearchparams-foreach: ForEach on empty params" {
  let p = @uri.UrlSearchParams::new()
  let seen : Array[String] = []
  p.for_each(fn(name, _) { seen.push(name) })
  assert_eq(seen, [])
}

// WPT urlsearchparams-get.any.js

///|
test "WPT urlsearchparams-get: Get basics" {
  let p = @uri.UrlSearchParams::from_string("a=b&c=d")
  assert_eq(p.get("a"), Some("b"))
  assert_eq(p.get("c"), Some("d"))
  assert_eq(p.get("e"), None)
  let p2 = @uri.UrlSearchParams::from_string("a=b&c=d&a=e")
  assert_eq(p2.get("a"), Some("b"))
  let p3 = @uri.UrlSearchParams::from_string("=b&c=d")
  assert_eq(p3.get(""), Some("b"))
  let p4 = @uri.UrlSearchParams::from_string("a=&c=d&a=e")
  assert_eq(p4.get("a"), Some(""))
}

///|
test "WPT urlsearchparams-get: More get basics" {
  let p = @uri.UrlSearchParams::from_string("first=second&third&&")
  assert_eq(p.has("first"), true)
  assert_eq(p.get("first"), Some("second"))
  assert_eq(p.get("third"), Some(""))
  assert_eq(p.get("fourth"), None)
}

// WPT urlsearchparams-getall.any.js

///|
test "WPT urlsearchparams-getall: getAll basics" {
  let p = @uri.UrlSearchParams::from_string("a=b&c=d")
  assert_eq(p.get_all("a"), ["b"])
  assert_eq(p.get_all("c"), ["d"])
  assert_eq(p.get_all("e"), [])
  let p2 = @uri.UrlSearchParams::from_string("a=b&c=d&a=e")
  assert_eq(p2.get_all("a"), ["b", "e"])
  let p3 = @uri.UrlSearchParams::from_string("=b&c=d")
  assert_eq(p3.get_all(""), ["b"])
  let p4 = @uri.UrlSearchParams::from_string("a=&c=d&a=e")
  assert_eq(p4.get_all("a"), ["", "e"])
}

///|
test "WPT urlsearchparams-getall: getAll after set replaces multiples" {
  let p = @uri.UrlSearchParams::from_string("a=1&a=2&a=3&a")
  assert_eq(p.has("a"), true)
  assert_eq(p.get_all("a"), ["1", "2", "3", ""])
  p.set("a", "one")
  assert_eq(p.get("a"), Some("one"))
  assert_eq(p.get_all("a"), ["one"])
}

// WPT urlsearchparams-has.any.js

///|
test "WPT urlsearchparams-has: Has basics" {
  let p = @uri.UrlSearchParams::from_string("a=b&c=d")
  assert_eq(p.has("a"), true)
  assert_eq(p.has("c"), true)
  assert_eq(p.has("e"), false)
  let p2 = @uri.UrlSearchParams::from_string("a=b&c=d&a=e")
  assert_eq(p2.has("a"), true)
  let p3 = @uri.UrlSearchParams::from_string("=b&c=d")
  assert_eq(p3.has(""), true)
  let p4 = @uri.UrlSearchParams::from_string("null=a")
  assert_eq(p4.has("null"), true)
}

///|
test "WPT urlsearchparams-has: has following delete" {
  let p = @uri.UrlSearchParams::from_string("a=b&c=d&&")
  p.append("first", "1")
  p.append("first", "2")
  assert_eq(p.has("a"), true)
  assert_eq(p.has("c"), true)
  assert_eq(p.has("first"), true)
  assert_eq(p.has("d"), false)
  p.delete("first")
  assert_eq(p.has("first"), false)
}

///|
test "WPT urlsearchparams-has: Two-argument has" {
  let p = @uri.UrlSearchParams::from_string("a=b&a=d&c&e&")
  assert_eq(p.has_entry("a", "b"), true)
  assert_eq(p.has_entry("a", "c"), false)
  assert_eq(p.has_entry("a", "d"), true)
  assert_eq(p.has_entry("e", ""), true)
  p.append("first", "null")
  assert_eq(p.has_entry("first", ""), false)
  assert_eq(p.has_entry("first", "null"), true)
  p.delete_entry("a", "b")
  assert_eq(p.has_entry("a", "d"), true)
}

// WPT urlsearchparams-set.any.js

///|
test "WPT urlsearchparams-set: Set basics" {
  let p = @uri.UrlSearchParams::from_string("a=b&c=d")
  p.set("a", "B")
  assert_eq(p.to_string(), "a=B&c=d")
  let p2 = @uri.UrlSearchParams::from_string("a=b&c=d&a=e")
  p2.set("a", "B")
  assert_eq(p2.to_string(), "a=B&c=d")
  p2.set("e", "f")
  assert_eq(p2.to_string(), "a=B&c=d&e=f")
}

///|
test "WPT urlsearchparams-set: URLSearchParams.set" {
  let p = @uri.UrlSearchParams::from_string("a=1&a=2&a=3")
  assert_eq(p.has("a"), true)
  assert_eq(p.get("a"), Some("1"))
  p.set("first", "4")
  assert_eq(p.has("a"), true)
  assert_eq(p.get("a"), Some("1"))
  p.set("a", "4")
  assert_eq(p.has("a"), true)
  assert_eq(p.get("a"), Some("4"))
}

// WPT urlsearchparams-size.any.js

///|
test "WPT urlsearchparams-size: size and deletion" {
  let p = @uri.UrlSearchParams::from_string("a=1&b=2&a=3")
  assert_eq(p.size(), 3)
  p.delete("a")
  assert_eq(p.size(), 1)
}

///|
test "WPT urlsearchparams-size: size and addition" {
  let p = @uri.UrlSearchParams::from_string("a=1&b=2&a=3")
  assert_eq(p.size(), 3)
  p.append("b", "4")
  assert_eq(p.size(), 4)
}

// WPT urlsearchparams-sort.any.js
// "URL parse and sort" cases require URL mutability — skipped
// "Sorting non-existent params removes ? from URL" — skipped

///|
test "WPT urlsearchparams-sort: all parse-and-sort cases" {
  let cases : Array[(String, Array[(String, String)])] = [
    ("z=b&a=b&z=a&a=a", [("a", "b"), ("a", "a"), ("z", "b"), ("z", "a")]),
    (
      "\u{FFFD}=x&\u{FFFC}&\u{FFFD}=a",
      [("\u{FFFC}", ""), ("\u{FFFD}", "x"), ("\u{FFFD}", "a")],
    ),
    ("\u{FB03}&\u{1F308}", [("\u{1F308}", ""), ("\u{FB03}", "")]),
    (
      "\u{00E9}&e\u{FFFD}&e\u{0301}",
      [("e\u{0301}", ""), ("e\u{FFFD}", ""), ("\u{00E9}", "")],
    ),
    (
      "z=z&a=a&z=y&a=b&z=x&a=c&z=w&a=d&z=v&a=e&z=u&a=f&z=t&a=g",
      [
        ("a", "a"),
        ("a", "b"),
        ("a", "c"),
        ("a", "d"),
        ("a", "e"),
        ("a", "f"),
        ("a", "g"),
        ("z", "z"),
        ("z", "y"),
        ("z", "x"),
        ("z", "w"),
        ("z", "v"),
        ("z", "u"),
        ("z", "t"),
      ],
    ),
    (
      "bbb&bb&aaa&aa=x&aa=y",
      [("aa", "x"), ("aa", "y"), ("aaa", ""), ("bb", ""), ("bbb", "")],
    ),
    ("z=z&=f&=t&=x", [("", "f"), ("", "t"), ("", "x"), ("z", "z")]),
    ("a\u{1F308}&a\u{1F4A9}", [("a\u{1F308}", ""), ("a\u{1F4A9}", "")]),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (input, expected) = item
    let p = @uri.UrlSearchParams::from_string(input)
    p.sort()
    let actual : Array[(String, String)] = []
    p.for_each(fn(name, value) { actual.push((name, value)) })
    if actual == expected {
      passed = passed + 1
    } else {
      if failed < 10 {
        println("FAIL sort: input=\{input}")
        println("  expected=\{expected}")
        println("  actual=\{actual}")
      }
      failed = failed + 1
    }
  }
  println("WPT urlsearchparams-sort: \{passed}/\{cases.length()} passed")
  assert_eq(failed, 0)
}

// WPT urlsearchparams-stringifier.any.js
// "URLSearchParams connected to URL" requires URL mutability — skipped

///|
test "WPT urlsearchparams-stringifier: Serialize space" {
  let p = @uri.UrlSearchParams::new()
  p.append("a", "b c")
  assert_eq(p.to_string(), "a=b+c")
  p.delete("a")
  p.append("a b", "c")
  assert_eq(p.to_string(), "a+b=c")
}

///|
test "WPT urlsearchparams-stringifier: Serialize empty value" {
  let p = @uri.UrlSearchParams::new()
  p.append("a", "")
  assert_eq(p.to_string(), "a=")
  p.append("a", "")
  assert_eq(p.to_string(), "a=&a=")
  p.append("", "b")
  assert_eq(p.to_string(), "a=&a=&=b")
  p.append("", "")
  assert_eq(p.to_string(), "a=&a=&=b&=")
  p.append("", "")
  assert_eq(p.to_string(), "a=&a=&=b&=&=")
}

///|
test "WPT urlsearchparams-stringifier: Serialize empty name" {
  let p = @uri.UrlSearchParams::new()
  p.append("", "b")
  assert_eq(p.to_string(), "=b")
  p.append("", "b")
  assert_eq(p.to_string(), "=b&=b")
}

///|
test "WPT urlsearchparams-stringifier: Serialize empty name and value" {
  let p = @uri.UrlSearchParams::new()
  p.append("", "")
  assert_eq(p.to_string(), "=")
  p.append("", "")
  assert_eq(p.to_string(), "=&=")
}

///|
test "WPT urlsearchparams-stringifier: Serialize +" {
  let p = @uri.UrlSearchParams::new()
  p.append("a", "b+c")
  assert_eq(p.to_string(), "a=b%2Bc")
  p.delete("a")
  p.append("a+b", "c")
  assert_eq(p.to_string(), "a%2Bb=c")
}

///|
test "WPT urlsearchparams-stringifier: Serialize =" {
  let p = @uri.UrlSearchParams::new()
  p.append("=", "a")
  assert_eq(p.to_string(), "%3D=a")
  p.append("b", "=")
  assert_eq(p.to_string(), "%3D=a&b=%3D")
}

///|
test "WPT urlsearchparams-stringifier: Serialize &" {
  let p = @uri.UrlSearchParams::new()
  p.append("&", "a")
  assert_eq(p.to_string(), "%26=a")
  p.append("b", "&")
  assert_eq(p.to_string(), "%26=a&b=%26")
}

///|
test "WPT urlsearchparams-stringifier: Serialize safe chars *-._" {
  let p = @uri.UrlSearchParams::new()
  p.append("a", "*-._")
  assert_eq(p.to_string(), "a=*-._")
  p.delete("a")
  p.append("*-._", "c")
  assert_eq(p.to_string(), "*-._=c")
}

///|
test "WPT urlsearchparams-stringifier: Serialize %" {
  let p = @uri.UrlSearchParams::new()
  p.append("a", "b%c")
  assert_eq(p.to_string(), "a=b%25c")
  p.delete("a")
  p.append("a%b", "c")
  assert_eq(p.to_string(), "a%25b=c")
  let p2 = @uri.UrlSearchParams::from_string("id=0&value=%")
  assert_eq(p2.to_string(), "id=0&value=%25")
}

///|
test "WPT urlsearchparams-stringifier: Serialize NUL byte" {
  let p = @uri.UrlSearchParams::new()
  p.append("a", "b\u{0000}c")
  assert_eq(p.to_string(), "a=b%00c")
  p.delete("a")
  p.append("a\u{0000}b", "c")
  assert_eq(p.to_string(), "a%00b=c")
}

///|
test "WPT urlsearchparams-stringifier: Serialize U+1F4A9 PILE OF POO" {
  let p = @uri.UrlSearchParams::new()
  p.append("a", "b\u{1F4A9}c")
  assert_eq(p.to_string(), "a=b%F0%9F%92%A9c")
  p.delete("a")
  p.append("a\u{1F4A9}b", "c")
  assert_eq(p.to_string(), "a%F0%9F%92%A9b=c")
}

///|
test "WPT urlsearchparams-stringifier: URLSearchParams.toString roundtrip" {
  let p = @uri.UrlSearchParams::from_string("a=b&c=d&&e&&")
  assert_eq(p.to_string(), "a=b&c=d&e=")
  let p2 = @uri.UrlSearchParams::from_string("a = b &a=b&c=d%20")
  assert_eq(p2.to_string(), "a+=+b+&a=b&c=d+")
  let p3 = @uri.UrlSearchParams::from_string("a=&a=b")
  assert_eq(p3.to_string(), "a=&a=b")
  let p4 = @uri.UrlSearchParams::from_string("b=%2sf%2a")
  assert_eq(p4.to_string(), "b=%252sf*")
  let p5 = @uri.UrlSearchParams::from_string("b=%2%2af%2a")
  assert_eq(p5.to_string(), "b=%252*f*")
  let p6 = @uri.UrlSearchParams::from_string("b=%%2a")
  assert_eq(p6.to_string(), "b=%25*")
}

///|
test "WPT urlsearchparams-stringifier: must not do newline normalization" {
  let p = @uri.UrlSearchParams::new()
  p.append("a\nb", "c\rd")
  p.append("e\n\rf", "g\r\nh")
  assert_eq(p.to_string(), "a%0Ab=c%0Dd&e%0A%0Df=g%0D%0Ah")
}
