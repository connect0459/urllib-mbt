// Generated WPT URL setter test vectors

///|
test "WPT setter cases: protocol" {
  let cases : Array[(String, String, Array[(String, String)])] = [
    ("a://example.net", "", [("href", "a://example.net"), ("protocol", "a:")]),
    ("a://example.net", "b", [("href", "b://example.net"), ("protocol", "b:")]),
    (
      "javascript:alert(1)",
      "defuse",
      [("href", "defuse:alert(1)"), ("protocol", "defuse:")],
    ),
    ("a://example.net", "B", [("href", "b://example.net"), ("protocol", "b:")]),
    (
      "a://example.net",
      "\u{00E9}",
      [("href", "a://example.net"), ("protocol", "a:")],
    ),
    ("a://example.net", "0b", [("href", "a://example.net"), ("protocol", "a:")]),
    ("a://example.net", "+b", [("href", "a://example.net"), ("protocol", "a:")]),
    (
      "a://example.net",
      "bC0+-.",
      [("href", "bc0+-.://example.net"), ("protocol", "bc0+-.:")],
    ),
    (
      "a://example.net",
      "b,c",
      [("href", "a://example.net"), ("protocol", "a:")],
    ),
    (
      "a://example.net",
      "b\u{00E9}",
      [("href", "a://example.net"), ("protocol", "a:")],
    ),
    (
      "http://test@example.net",
      "file",
      [("href", "http://test@example.net/"), ("protocol", "http:")],
    ),
    (
      "https://example.net:1234",
      "file",
      [("href", "https://example.net:1234/"), ("protocol", "https:")],
    ),
    (
      "wss://x:x@example.net:1234",
      "file",
      [("href", "wss://x:x@example.net:1234/"), ("protocol", "wss:")],
    ),
    ("file://localhost/", "http", [("href", "file:///"), ("protocol", "file:")]),
    ("file:///test", "https", [("href", "file:///test"), ("protocol", "file:")]),
    ("file:", "wss", [("href", "file:///"), ("protocol", "file:")]),
    (
      "http://example.net",
      "b",
      [("href", "http://example.net/"), ("protocol", "http:")],
    ),
    ("file://hi/path", "s", [("href", "file://hi/path"), ("protocol", "file:")]),
    (
      "https://example.net",
      "s",
      [("href", "https://example.net/"), ("protocol", "https:")],
    ),
    (
      "ftp://example.net",
      "test",
      [("href", "ftp://example.net/"), ("protocol", "ftp:")],
    ),
    (
      "mailto:me@example.net",
      "http",
      [("href", "mailto:me@example.net"), ("protocol", "mailto:")],
    ),
    (
      "ssh://me@example.net",
      "http",
      [("href", "ssh://me@example.net"), ("protocol", "ssh:")],
    ),
    (
      "ssh://me@example.net",
      "https",
      [("href", "ssh://me@example.net"), ("protocol", "ssh:")],
    ),
    (
      "ssh://me@example.net",
      "file",
      [("href", "ssh://me@example.net"), ("protocol", "ssh:")],
    ),
    (
      "ssh://example.net",
      "file",
      [("href", "ssh://example.net"), ("protocol", "ssh:")],
    ),
    (
      "nonsense:///test",
      "https",
      [("href", "nonsense:///test"), ("protocol", "nonsense:")],
    ),
    (
      "http://example.net",
      "https:foo : bar",
      [("href", "https://example.net/"), ("protocol", "https:")],
    ),
    (
      "data:text/html,<p>Test",
      "view-source+data:foo : bar",
      [
        ("href", "view-source+data:text/html,<p>Test"),
        ("protocol", "view-source+data:"),
      ],
    ),
    (
      "http://foo.com:443/",
      "https",
      [("href", "https://foo.com/"), ("protocol", "https:"), ("port", "")],
    ),
    (
      "http://test/",
      "h\r\ntt\tps",
      [("href", "https://test/"), ("protocol", "https:"), ("port", "")],
    ),
    (
      "http://test/",
      "https\r",
      [("href", "https://test/"), ("protocol", "https:")],
    ),
    (
      "http://test/",
      "https\u{0000}",
      [("href", "http://test/"), ("protocol", "http:")],
    ),
    (
      "http://test/",
      "https\u{000C}",
      [("href", "http://test/"), ("protocol", "http:")],
    ),
    (
      "http://test/",
      "https\u{000E}",
      [("href", "http://test/"), ("protocol", "http:")],
    ),
    (
      "http://test/",
      "https ",
      [("href", "http://test/"), ("protocol", "http:")],
    ),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (href, new_value, expected_fields) = item
    let url = @uri.parse(href) catch { _ => continue }
    let result = url.set_protocol(new_value)
    for efld in expected_fields {
      let (field, expected_val) = efld
      let actual = match field {
        "href" => result.href()
        "protocol" => result.protocol()
        "username" => result.username
        "password" => result.password
        "host" => result.host_str()
        "hostname" => result.hostname()
        "port" => result.port_str()
        "pathname" => result.pathname()
        "search" => result.search()
        "hash" => result.hash()
        _ => ""
      }
      if actual != expected_val {
        if failed < 10 {
          println(
            "FAIL set_protocol: href=\{href} new=\{new_value} field=\{field} expected=\{expected_val} got=\{actual}",
          )
        }
        failed = failed + 1
      } else {
        passed = passed + 1
      }
    }
  }
  println("WPT setter protocol: \{passed}/\{passed + failed} passed")
  if failed > 0 {
    println("WARN: \{failed} protocol setter cases failed")
    assert_eq(failed, 0)
  }
}

///|
test "WPT setter cases: username" {
  let cases : Array[(String, String, Array[(String, String)])] = [
    (
      "file:///home/you/index.html",
      "me",
      [("href", "file:///home/you/index.html"), ("username", "")],
    ),
    (
      "unix:/run/foo.socket",
      "me",
      [("href", "unix:/run/foo.socket"), ("username", "")],
    ),
    (
      "mailto:you@example.net",
      "me",
      [("href", "mailto:you@example.net"), ("username", "")],
    ),
    (
      "javascript:alert(1)",
      "wario",
      [("href", "javascript:alert(1)"), ("username", "")],
    ),
    (
      "http://example.net",
      "me",
      [("href", "http://me@example.net/"), ("username", "me")],
    ),
    (
      "http://:secret@example.net",
      "me",
      [("href", "http://me:secret@example.net/"), ("username", "me")],
    ),
    (
      "http://me@example.net",
      "",
      [("href", "http://example.net/"), ("username", "")],
    ),
    (
      "http://me:secret@example.net",
      "",
      [("href", "http://:secret@example.net/"), ("username", "")],
    ),
    (
      "http://example.net",
      "\u{0000}\u{0001}\t\n\r\u{001F} !\"#$%&'()*+,-./09:;<=>?@AZ[\\]^_`az{|}~\u{007F}\u{0080}\u{0081}\u{00C9}\u{00E9}",
      [
        (
          "href", "http://%00%01%09%0A%0D%1F%20!%22%23$%&'()*+,-.%2F09%3A%3B%3C%3D%3E%3F%40AZ%5B%5C%5D%5E_%60az%7B%7C%7D~%7F%C2%80%C2%81%C3%89%C3%A9@example.net/",
        ),
        (
          "username", "%00%01%09%0A%0D%1F%20!%22%23$%&'()*+,-.%2F09%3A%3B%3C%3D%3E%3F%40AZ%5B%5C%5D%5E_%60az%7B%7C%7D~%7F%C2%80%C2%81%C3%89%C3%A9",
        ),
      ],
    ),
    (
      "http://example.net",
      "%c3%89t\u{00E9}",
      [
        ("href", "http://%c3%89t%C3%A9@example.net/"),
        ("username", "%c3%89t%C3%A9"),
      ],
    ),
    ("sc:///", "x", [("href", "sc:///"), ("username", "")]),
    (
      "javascript://x/",
      "wario",
      [("href", "javascript://wario@x/"), ("username", "wario")],
    ),
    ("file://test/", "test", [("href", "file://test/"), ("username", "")]),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (href, new_value, expected_fields) = item
    let url = @uri.parse(href) catch { _ => continue }
    let result = url.set_username(new_value)
    for efld in expected_fields {
      let (field, expected_val) = efld
      let actual = match field {
        "href" => result.href()
        "protocol" => result.protocol()
        "username" => result.username
        "password" => result.password
        "host" => result.host_str()
        "hostname" => result.hostname()
        "port" => result.port_str()
        "pathname" => result.pathname()
        "search" => result.search()
        "hash" => result.hash()
        _ => ""
      }
      if actual != expected_val {
        if failed < 10 {
          println(
            "FAIL set_username: href=\{href} new=\{new_value} field=\{field} expected=\{expected_val} got=\{actual}",
          )
        }
        failed = failed + 1
      } else {
        passed = passed + 1
      }
    }
  }
  println("WPT setter username: \{passed}/\{passed + failed} passed")
  if failed > 0 {
    println("WARN: \{failed} username setter cases failed")
    assert_eq(failed, 0)
  }
}

///|
test "WPT setter cases: password" {
  let cases : Array[(String, String, Array[(String, String)])] = [
    (
      "file:///home/me/index.html",
      "secret",
      [("href", "file:///home/me/index.html"), ("password", "")],
    ),
    (
      "unix:/run/foo.socket",
      "secret",
      [("href", "unix:/run/foo.socket"), ("password", "")],
    ),
    (
      "mailto:me@example.net",
      "secret",
      [("href", "mailto:me@example.net"), ("password", "")],
    ),
    (
      "http://example.net",
      "secret",
      [("href", "http://:secret@example.net/"), ("password", "secret")],
    ),
    (
      "http://me@example.net",
      "secret",
      [("href", "http://me:secret@example.net/"), ("password", "secret")],
    ),
    (
      "http://:secret@example.net",
      "",
      [("href", "http://example.net/"), ("password", "")],
    ),
    (
      "http://me:secret@example.net",
      "",
      [("href", "http://me@example.net/"), ("password", "")],
    ),
    (
      "http://example.net",
      "\u{0000}\u{0001}\t\n\r\u{001F} !\"#$%&'()*+,-./09:;<=>?@AZ[\\]^_`az{|}~\u{007F}\u{0080}\u{0081}\u{00C9}\u{00E9}",
      [
        (
          "href", "http://:%00%01%09%0A%0D%1F%20!%22%23$%&'()*+,-.%2F09%3A%3B%3C%3D%3E%3F%40AZ%5B%5C%5D%5E_%60az%7B%7C%7D~%7F%C2%80%C2%81%C3%89%C3%A9@example.net/",
        ),
        (
          "password", "%00%01%09%0A%0D%1F%20!%22%23$%&'()*+,-.%2F09%3A%3B%3C%3D%3E%3F%40AZ%5B%5C%5D%5E_%60az%7B%7C%7D~%7F%C2%80%C2%81%C3%89%C3%A9",
        ),
      ],
    ),
    (
      "http://example.net",
      "%c3%89t\u{00E9}",
      [
        ("href", "http://:%c3%89t%C3%A9@example.net/"),
        ("password", "%c3%89t%C3%A9"),
      ],
    ),
    ("sc:///", "x", [("href", "sc:///"), ("password", "")]),
    (
      "javascript://x/",
      "bowser",
      [("href", "javascript://:bowser@x/"), ("password", "bowser")],
    ),
    ("file://test/", "test", [("href", "file://test/"), ("password", "")]),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (href, new_value, expected_fields) = item
    let url = @uri.parse(href) catch { _ => continue }
    let result = url.set_password(new_value)
    for efld in expected_fields {
      let (field, expected_val) = efld
      let actual = match field {
        "href" => result.href()
        "protocol" => result.protocol()
        "username" => result.username
        "password" => result.password
        "host" => result.host_str()
        "hostname" => result.hostname()
        "port" => result.port_str()
        "pathname" => result.pathname()
        "search" => result.search()
        "hash" => result.hash()
        _ => ""
      }
      if actual != expected_val {
        if failed < 10 {
          println(
            "FAIL set_password: href=\{href} new=\{new_value} field=\{field} expected=\{expected_val} got=\{actual}",
          )
        }
        failed = failed + 1
      } else {
        passed = passed + 1
      }
    }
  }
  println("WPT setter password: \{passed}/\{passed + failed} passed")
  if failed > 0 {
    println("WARN: \{failed} password setter cases failed")
    assert_eq(failed, 0)
  }
}

///|
test "WPT setter cases: host" {
  let cases : Array[(String, String, Array[(String, String)])] = [
    (
      "sc://x/",
      "\u{0000}",
      [("href", "sc://x/"), ("host", "x"), ("hostname", "x")],
    ),
    ("sc://x/", "\t", [("href", "sc:///"), ("host", ""), ("hostname", "")]),
    ("sc://x/", "\n", [("href", "sc:///"), ("host", ""), ("hostname", "")]),
    ("sc://x/", "\r", [("href", "sc:///"), ("host", ""), ("hostname", "")]),
    ("sc://x/", " ", [("href", "sc://x/"), ("host", "x"), ("hostname", "x")]),
    ("sc://x/", "#", [("href", "sc:///"), ("host", ""), ("hostname", "")]),
    ("sc://x/", "/", [("href", "sc:///"), ("host", ""), ("hostname", "")]),
    ("sc://x/", "?", [("href", "sc:///"), ("host", ""), ("hostname", "")]),
    ("sc://x/", "@", [("href", "sc://x/"), ("host", "x"), ("hostname", "x")]),
    (
      "sc://x/",
      "\u{00DF}",
      [("href", "sc://%C3%9F/"), ("host", "%C3%9F"), ("hostname", "%C3%9F")],
    ),
    (
      "https://x/",
      "\u{00DF}",
      [
        ("href", "https://xn--zca/"),
        ("host", "xn--zca"),
        ("hostname", "xn--zca"),
      ],
    ),
    (
      "mailto:me@example.net",
      "example.com",
      [("href", "mailto:me@example.net"), ("host", "")],
    ),
    (
      "data:text/plain,Stuff",
      "example.net",
      [("href", "data:text/plain,Stuff"), ("host", "")],
    ),
    (
      "http://example.net",
      "example.com:8080",
      [
        ("href", "http://example.com:8080/"),
        ("host", "example.com:8080"),
        ("hostname", "example.com"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net:8080",
      "example.com",
      [
        ("href", "http://example.com:8080/"),
        ("host", "example.com:8080"),
        ("hostname", "example.com"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net:8080",
      "example.com:",
      [
        ("href", "http://example.com:8080/"),
        ("host", "example.com:8080"),
        ("hostname", "example.com"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net",
      "",
      [("href", "http://example.net/"), ("host", "example.net")],
    ),
    (
      "view-source+http://example.net/foo",
      "",
      [("href", "view-source+http:///foo"), ("host", "")],
    ),
    (
      "a:/foo",
      "example.net",
      [("href", "a://example.net/foo"), ("host", "example.net")],
    ),
    (
      "http://example.net",
      "0x7F000001:8080",
      [
        ("href", "http://127.0.0.1:8080/"),
        ("host", "127.0.0.1:8080"),
        ("hostname", "127.0.0.1"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net",
      "[::0:01]:2",
      [
        ("href", "http://[::1]:2/"),
        ("host", "[::1]:2"),
        ("hostname", "[::1]"),
        ("port", "2"),
      ],
    ),
    (
      "http://example.net",
      "[2001:db8::2]:4002",
      [
        ("href", "http://[2001:db8::2]:4002/"),
        ("host", "[2001:db8::2]:4002"),
        ("hostname", "[2001:db8::2]"),
        ("port", "4002"),
      ],
    ),
    (
      "http://example.net",
      "example.com:80",
      [
        ("href", "http://example.com/"),
        ("host", "example.com"),
        ("hostname", "example.com"),
        ("port", ""),
      ],
    ),
    (
      "https://example.net",
      "example.com:443",
      [
        ("href", "https://example.com/"),
        ("host", "example.com"),
        ("hostname", "example.com"),
        ("port", ""),
      ],
    ),
    (
      "https://example.net",
      "example.com:80",
      [
        ("href", "https://example.com:80/"),
        ("host", "example.com:80"),
        ("hostname", "example.com"),
        ("port", "80"),
      ],
    ),
    (
      "http://example.net:8080",
      "example.com:80",
      [
        ("href", "http://example.com/"),
        ("host", "example.com"),
        ("hostname", "example.com"),
        ("port", ""),
      ],
    ),
    (
      "http://example.net/path",
      "example.com/stuff",
      [
        ("href", "http://example.com/path"),
        ("host", "example.com"),
        ("hostname", "example.com"),
        ("port", ""),
      ],
    ),
    (
      "http://example.net/path",
      "example.com:8080/stuff",
      [
        ("href", "http://example.com:8080/path"),
        ("host", "example.com:8080"),
        ("hostname", "example.com"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net/path",
      "example.com?stuff",
      [
        ("href", "http://example.com/path"),
        ("host", "example.com"),
        ("hostname", "example.com"),
        ("port", ""),
      ],
    ),
    (
      "http://example.net/path",
      "example.com?stuff:8080",
      [
        ("href", "http://example.com/path"),
        ("host", "example.com"),
        ("hostname", "example.com"),
        ("port", ""),
      ],
    ),
    (
      "http://example.net/path",
      "example.com:8080?stuff",
      [
        ("href", "http://example.com:8080/path"),
        ("host", "example.com:8080"),
        ("hostname", "example.com"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net/path",
      "example.com#stuff",
      [
        ("href", "http://example.com/path"),
        ("host", "example.com"),
        ("hostname", "example.com"),
        ("port", ""),
      ],
    ),
    (
      "http://example.net/path",
      "example.com:8080#stuff",
      [
        ("href", "http://example.com:8080/path"),
        ("host", "example.com:8080"),
        ("hostname", "example.com"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net/path",
      "example.com\\stuff",
      [
        ("href", "http://example.com/path"),
        ("host", "example.com"),
        ("hostname", "example.com"),
        ("port", ""),
      ],
    ),
    (
      "http://example.net/path",
      "example.com:8080\\stuff",
      [
        ("href", "http://example.com:8080/path"),
        ("host", "example.com:8080"),
        ("hostname", "example.com"),
        ("port", "8080"),
      ],
    ),
    (
      "view-source+http://example.net/path",
      "example.com\\stuff",
      [
        ("href", "view-source+http://example.net/path"),
        ("host", "example.net"),
        ("hostname", "example.net"),
        ("port", ""),
      ],
    ),
    (
      "view-source+http://example.net/path",
      "example.com:8080stuff2",
      [
        ("href", "view-source+http://example.com:8080/path"),
        ("host", "example.com:8080"),
        ("hostname", "example.com"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net/path",
      "example.com:8080stuff2",
      [
        ("href", "http://example.com:8080/path"),
        ("host", "example.com:8080"),
        ("hostname", "example.com"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net/path",
      "example.com:8080+2",
      [
        ("href", "http://example.com:8080/path"),
        ("host", "example.com:8080"),
        ("hostname", "example.com"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net:8080",
      "example.com:invalid",
      [
        ("href", "http://example.com:8080/"),
        ("host", "example.com:8080"),
        ("hostname", "example.com"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net:8080/test",
      "[::1]:invalid",
      [
        ("href", "http://[::1]:8080/test"),
        ("host", "[::1]:8080"),
        ("hostname", "[::1]"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net:8080/test",
      "[::1]",
      [
        ("href", "http://[::1]:8080/test"),
        ("host", "[::1]:8080"),
        ("hostname", "[::1]"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net/path",
      "example.com:65535",
      [
        ("href", "http://example.com:65535/path"),
        ("host", "example.com:65535"),
        ("hostname", "example.com"),
        ("port", "65535"),
      ],
    ),
    (
      "http://example.net/path",
      "example.com:65536",
      [
        ("href", "http://example.com/path"),
        ("host", "example.com"),
        ("hostname", "example.com"),
        ("port", ""),
      ],
    ),
    (
      "http://example.net/",
      "[google.com]",
      [
        ("href", "http://example.net/"),
        ("host", "example.net"),
        ("hostname", "example.net"),
      ],
    ),
    (
      "http://example.net/",
      "[::1.2.3.4x]",
      [
        ("href", "http://example.net/"),
        ("host", "example.net"),
        ("hostname", "example.net"),
      ],
    ),
    (
      "http://example.net/",
      "[::1.2.3.]",
      [
        ("href", "http://example.net/"),
        ("host", "example.net"),
        ("hostname", "example.net"),
      ],
    ),
    (
      "http://example.net/",
      "[::1.2.]",
      [
        ("href", "http://example.net/"),
        ("host", "example.net"),
        ("hostname", "example.net"),
      ],
    ),
    (
      "http://example.net/",
      "[::1.]",
      [
        ("href", "http://example.net/"),
        ("host", "example.net"),
        ("hostname", "example.net"),
      ],
    ),
    (
      "file://y/",
      "x:123",
      [("href", "file://y/"), ("host", "y"), ("hostname", "y"), ("port", "")],
    ),
    (
      "file://y/",
      "loc%41lhost",
      [("href", "file:///"), ("host", ""), ("hostname", ""), ("port", "")],
    ),
    (
      "file://hi/x",
      "",
      [("href", "file:///x"), ("host", ""), ("hostname", ""), ("port", "")],
    ),
    (
      "sc://test@test/",
      "",
      [
        ("href", "sc://test@test/"),
        ("host", "test"),
        ("hostname", "test"),
        ("username", "test"),
      ],
    ),
    (
      "sc://test:12/",
      "",
      [
        ("href", "sc://test:12/"),
        ("host", "test:12"),
        ("hostname", "test"),
        ("port", "12"),
      ],
    ),
    (
      "http://example.com/",
      "///bad.com",
      [
        ("href", "http://example.com/"),
        ("host", "example.com"),
        ("hostname", "example.com"),
      ],
    ),
    (
      "sc://example.com/",
      "///bad.com",
      [("href", "sc:///"), ("host", ""), ("hostname", "")],
    ),
    (
      "https://example.com/",
      "a%C2%ADb",
      [("href", "https://ab/"), ("host", "ab"), ("hostname", "ab")],
    ),
    (
      "https://example.com/",
      "\u{00AD}",
      [
        ("href", "https://example.com/"),
        ("host", "example.com"),
        ("hostname", "example.com"),
      ],
    ),
    (
      "https://example.com/",
      "%C2%AD",
      [
        ("href", "https://example.com/"),
        ("host", "example.com"),
        ("hostname", "example.com"),
      ],
    ),
    (
      "https://example.com/",
      "xn--",
      [
        ("href", "https://example.com/"),
        ("host", "example.com"),
        ("hostname", "example.com"),
      ],
    ),
    (
      "https://test.invalid/",
      "*",
      [("href", "https://*/"), ("host", "*"), ("hostname", "*")],
    ),
    (
      "https://test.invalid/",
      "x@x",
      [
        ("href", "https://test.invalid/"),
        ("host", "test.invalid"),
        ("hostname", "test.invalid"),
      ],
    ),
    (
      "https://test.invalid/",
      "foo\t\r\nbar",
      [("href", "https://foobar/"), ("host", "foobar"), ("hostname", "foobar")],
    ),
    (
      "https://test.invalid/",
      "><",
      [
        ("href", "https://test.invalid/"),
        ("host", "test.invalid"),
        ("hostname", "test.invalid"),
      ],
    ),
    (
      "https://test.invalid/",
      "test/@aaa",
      [("href", "https://test/"), ("host", "test"), ("hostname", "test")],
    ),
    (
      "https://test.invalid/",
      "test/:aaa",
      [("href", "https://test/"), ("host", "test"), ("hostname", "test")],
    ),
    (
      "foo://path/to",
      ":80",
      [("href", "foo://path/to"), ("host", "path"), ("port", "")],
    ),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (href, new_value, expected_fields) = item
    let url = @uri.parse(href) catch { _ => continue }
    let result = url.set_host(new_value)
    for efld in expected_fields {
      let (field, expected_val) = efld
      let actual = match field {
        "href" => result.href()
        "protocol" => result.protocol()
        "username" => result.username
        "password" => result.password
        "host" => result.host_str()
        "hostname" => result.hostname()
        "port" => result.port_str()
        "pathname" => result.pathname()
        "search" => result.search()
        "hash" => result.hash()
        _ => ""
      }
      if actual != expected_val {
        if failed < 10 {
          println(
            "FAIL set_host: href=\{href} new=\{new_value} field=\{field} expected=\{expected_val} got=\{actual}",
          )
        }
        failed = failed + 1
      } else {
        passed = passed + 1
      }
    }
  }
  println("WPT setter host: \{passed}/\{passed + failed} passed")
  if failed > 0 {
    println("WARN: \{failed} host setter cases failed")
    assert_eq(failed, 0)
  }
}

///|
test "WPT setter cases: hostname" {
  let cases : Array[(String, String, Array[(String, String)])] = [
    (
      "sc://x/",
      "\u{0000}",
      [("href", "sc://x/"), ("host", "x"), ("hostname", "x")],
    ),
    ("sc://x/", "\t", [("href", "sc:///"), ("host", ""), ("hostname", "")]),
    ("sc://x/", "\n", [("href", "sc:///"), ("host", ""), ("hostname", "")]),
    ("sc://x/", "\r", [("href", "sc:///"), ("host", ""), ("hostname", "")]),
    ("sc://x/", " ", [("href", "sc://x/"), ("host", "x"), ("hostname", "x")]),
    ("sc://x/", "#", [("href", "sc:///"), ("host", ""), ("hostname", "")]),
    ("sc://x/", "/", [("href", "sc:///"), ("host", ""), ("hostname", "")]),
    ("sc://x/", "?", [("href", "sc:///"), ("host", ""), ("hostname", "")]),
    ("sc://x/", "@", [("href", "sc://x/"), ("host", "x"), ("hostname", "x")]),
    (
      "mailto:me@example.net",
      "example.com",
      [("href", "mailto:me@example.net"), ("host", "")],
    ),
    (
      "data:text/plain,Stuff",
      "example.net",
      [("href", "data:text/plain,Stuff"), ("host", "")],
    ),
    (
      "http://example.net:8080",
      "example.com",
      [
        ("href", "http://example.com:8080/"),
        ("host", "example.com:8080"),
        ("hostname", "example.com"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net",
      "",
      [("href", "http://example.net/"), ("host", "example.net")],
    ),
    (
      "view-source+http://example.net/foo",
      "",
      [("href", "view-source+http:///foo"), ("host", "")],
    ),
    (
      "a:/foo",
      "example.net",
      [("href", "a://example.net/foo"), ("host", "example.net")],
    ),
    (
      "http://example.net:8080",
      "0x7F000001",
      [
        ("href", "http://127.0.0.1:8080/"),
        ("host", "127.0.0.1:8080"),
        ("hostname", "127.0.0.1"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net",
      "[::0:01]",
      [
        ("href", "http://[::1]/"),
        ("host", "[::1]"),
        ("hostname", "[::1]"),
        ("port", ""),
      ],
    ),
    (
      "http://example.net/path",
      "example.com:8080",
      [
        ("href", "http://example.net/path"),
        ("host", "example.net"),
        ("hostname", "example.net"),
        ("port", ""),
      ],
    ),
    (
      "http://example.net:8080/path",
      "example.com:",
      [
        ("href", "http://example.net:8080/path"),
        ("host", "example.net:8080"),
        ("hostname", "example.net"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net/path",
      "example.com/stuff",
      [
        ("href", "http://example.com/path"),
        ("host", "example.com"),
        ("hostname", "example.com"),
        ("port", ""),
      ],
    ),
    (
      "http://example.net/path",
      "example.com?stuff",
      [
        ("href", "http://example.com/path"),
        ("host", "example.com"),
        ("hostname", "example.com"),
        ("port", ""),
      ],
    ),
    (
      "http://example.net/path",
      "example.com#stuff",
      [
        ("href", "http://example.com/path"),
        ("host", "example.com"),
        ("hostname", "example.com"),
        ("port", ""),
      ],
    ),
    (
      "http://example.net/path",
      "example.com\\stuff",
      [
        ("href", "http://example.com/path"),
        ("host", "example.com"),
        ("hostname", "example.com"),
        ("port", ""),
      ],
    ),
    (
      "view-source+http://example.net/path",
      "example.com\\stuff",
      [
        ("href", "view-source+http://example.net/path"),
        ("host", "example.net"),
        ("hostname", "example.net"),
        ("port", ""),
      ],
    ),
    (
      "http://example.net/",
      "[google.com]",
      [
        ("href", "http://example.net/"),
        ("host", "example.net"),
        ("hostname", "example.net"),
      ],
    ),
    (
      "http://example.net/",
      "[::1.2.3.4x]",
      [
        ("href", "http://example.net/"),
        ("host", "example.net"),
        ("hostname", "example.net"),
      ],
    ),
    (
      "http://example.net/",
      "[::1.2.3.]",
      [
        ("href", "http://example.net/"),
        ("host", "example.net"),
        ("hostname", "example.net"),
      ],
    ),
    (
      "http://example.net/",
      "[::1.2.]",
      [
        ("href", "http://example.net/"),
        ("host", "example.net"),
        ("hostname", "example.net"),
      ],
    ),
    (
      "http://example.net/",
      "[::1.]",
      [
        ("href", "http://example.net/"),
        ("host", "example.net"),
        ("hostname", "example.net"),
      ],
    ),
    (
      "file://y/",
      "x:123",
      [("href", "file://y/"), ("host", "y"), ("hostname", "y"), ("port", "")],
    ),
    (
      "file://y/",
      "loc%41lhost",
      [("href", "file:///"), ("host", ""), ("hostname", ""), ("port", "")],
    ),
    (
      "file://hi/x",
      "",
      [("href", "file:///x"), ("host", ""), ("hostname", ""), ("port", "")],
    ),
    (
      "sc://test@test/",
      "",
      [
        ("href", "sc://test@test/"),
        ("host", "test"),
        ("hostname", "test"),
        ("username", "test"),
      ],
    ),
    (
      "sc://test:12/",
      "",
      [
        ("href", "sc://test:12/"),
        ("host", "test:12"),
        ("hostname", "test"),
        ("port", "12"),
      ],
    ),
    (
      "non-spec:/.//p",
      "h",
      [
        ("href", "non-spec://h//p"),
        ("host", "h"),
        ("hostname", "h"),
        ("pathname", "//p"),
      ],
    ),
    (
      "non-spec:/.//p",
      "",
      [
        ("href", "non-spec:////p"),
        ("host", ""),
        ("hostname", ""),
        ("pathname", "//p"),
      ],
    ),
    (
      "http://example.com/",
      "///bad.com",
      [
        ("href", "http://example.com/"),
        ("host", "example.com"),
        ("hostname", "example.com"),
      ],
    ),
    (
      "sc://example.com/",
      "///bad.com",
      [("href", "sc:///"), ("host", ""), ("hostname", "")],
    ),
    (
      "https://example.com/",
      "a%C2%ADb",
      [("href", "https://ab/"), ("host", "ab"), ("hostname", "ab")],
    ),
    (
      "https://example.com/",
      "\u{00AD}",
      [
        ("href", "https://example.com/"),
        ("host", "example.com"),
        ("hostname", "example.com"),
      ],
    ),
    (
      "https://example.com/",
      "%C2%AD",
      [
        ("href", "https://example.com/"),
        ("host", "example.com"),
        ("hostname", "example.com"),
      ],
    ),
    (
      "https://example.com/",
      "xn--",
      [
        ("href", "https://example.com/"),
        ("host", "example.com"),
        ("hostname", "example.com"),
      ],
    ),
    (
      "https://test.invalid/",
      "*",
      [("href", "https://*/"), ("host", "*"), ("hostname", "*")],
    ),
    (
      "https://test.invalid/",
      "x@x",
      [
        ("href", "https://test.invalid/"),
        ("host", "test.invalid"),
        ("hostname", "test.invalid"),
      ],
    ),
    (
      "https://test.invalid/",
      "foo\t\r\nbar",
      [("href", "https://foobar/"), ("host", "foobar"), ("hostname", "foobar")],
    ),
    (
      "https://test.invalid/",
      "><",
      [
        ("href", "https://test.invalid/"),
        ("host", "test.invalid"),
        ("hostname", "test.invalid"),
      ],
    ),
    (
      "https://test.invalid/",
      "test/@aaa",
      [("href", "https://test/"), ("host", "test"), ("hostname", "test")],
    ),
    (
      "https://test.invalid/",
      "test/:aaa",
      [("href", "https://test/"), ("host", "test"), ("hostname", "test")],
    ),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (href, new_value, expected_fields) = item
    let url = @uri.parse(href) catch { _ => continue }
    let result = url.set_hostname(new_value)
    for efld in expected_fields {
      let (field, expected_val) = efld
      let actual = match field {
        "href" => result.href()
        "protocol" => result.protocol()
        "username" => result.username
        "password" => result.password
        "host" => result.host_str()
        "hostname" => result.hostname()
        "port" => result.port_str()
        "pathname" => result.pathname()
        "search" => result.search()
        "hash" => result.hash()
        _ => ""
      }
      if actual != expected_val {
        if failed < 10 {
          println(
            "FAIL set_hostname: href=\{href} new=\{new_value} field=\{field} expected=\{expected_val} got=\{actual}",
          )
        }
        failed = failed + 1
      } else {
        passed = passed + 1
      }
    }
  }
  println("WPT setter hostname: \{passed}/\{passed + failed} passed")
  if failed > 0 {
    println("WARN: \{failed} hostname setter cases failed")
    assert_eq(failed, 0)
  }
}

///|
test "WPT setter cases: port" {
  let cases : Array[(String, String, Array[(String, String)])] = [
    (
      "http://example.net",
      "8080",
      [
        ("href", "http://example.net:8080/"),
        ("host", "example.net:8080"),
        ("hostname", "example.net"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net:8080",
      "",
      [
        ("href", "http://example.net/"),
        ("host", "example.net"),
        ("hostname", "example.net"),
        ("port", ""),
      ],
    ),
    (
      "http://example.net:8080",
      "80",
      [
        ("href", "http://example.net/"),
        ("host", "example.net"),
        ("hostname", "example.net"),
        ("port", ""),
      ],
    ),
    (
      "https://example.net:4433",
      "443",
      [
        ("href", "https://example.net/"),
        ("host", "example.net"),
        ("hostname", "example.net"),
        ("port", ""),
      ],
    ),
    (
      "https://example.net",
      "80",
      [
        ("href", "https://example.net:80/"),
        ("host", "example.net:80"),
        ("hostname", "example.net"),
        ("port", "80"),
      ],
    ),
    (
      "http://example.net/path",
      "8080/stuff",
      [
        ("href", "http://example.net:8080/path"),
        ("host", "example.net:8080"),
        ("hostname", "example.net"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net/path",
      "8080?stuff",
      [
        ("href", "http://example.net:8080/path"),
        ("host", "example.net:8080"),
        ("hostname", "example.net"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net/path",
      "8080#stuff",
      [
        ("href", "http://example.net:8080/path"),
        ("host", "example.net:8080"),
        ("hostname", "example.net"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net/path",
      "8080\\stuff",
      [
        ("href", "http://example.net:8080/path"),
        ("host", "example.net:8080"),
        ("hostname", "example.net"),
        ("port", "8080"),
      ],
    ),
    (
      "view-source+http://example.net/path",
      "8080stuff2",
      [
        ("href", "view-source+http://example.net:8080/path"),
        ("host", "example.net:8080"),
        ("hostname", "example.net"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net/path",
      "8080stuff2",
      [
        ("href", "http://example.net:8080/path"),
        ("host", "example.net:8080"),
        ("hostname", "example.net"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net/path",
      "8080+2",
      [
        ("href", "http://example.net:8080/path"),
        ("host", "example.net:8080"),
        ("hostname", "example.net"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net/path",
      "65535",
      [
        ("href", "http://example.net:65535/path"),
        ("host", "example.net:65535"),
        ("hostname", "example.net"),
        ("port", "65535"),
      ],
    ),
    (
      "http://example.net:8080/path",
      "65536",
      [
        ("href", "http://example.net:8080/path"),
        ("host", "example.net:8080"),
        ("hostname", "example.net"),
        ("port", "8080"),
      ],
    ),
    (
      "http://example.net:8080/path",
      "randomstring",
      [
        ("href", "http://example.net:8080/path"),
        ("host", "example.net:8080"),
        ("hostname", "example.net"),
        ("port", "8080"),
      ],
    ),
    (
      "non-special://example.net:8080/path",
      "65536",
      [
        ("href", "non-special://example.net:8080/path"),
        ("host", "example.net:8080"),
        ("hostname", "example.net"),
        ("port", "8080"),
      ],
    ),
    ("file://test/", "12", [("href", "file://test/"), ("port", "")]),
    ("file://localhost/", "12", [("href", "file:///"), ("port", "")]),
    ("non-base:value", "12", [("href", "non-base:value"), ("port", "")]),
    ("sc:///", "12", [("href", "sc:///"), ("port", "")]),
    ("sc://x/", "12", [("href", "sc://x:12/"), ("port", "12")]),
    ("javascript://x/", "12", [("href", "javascript://x:12/"), ("port", "12")]),
    ("https://domain.com:443", "\t8080", [("port", "8080")]),
    ("wpt++://domain.com:443", "\t8080", [("port", "8080")]),
    ("https://www.google.com:4343", "4wpt", [("port", "4")]),
    ("https://domain.com:3000", "\n\t80\n\t80\n\t", [("port", "8080")]),
    ("https://domain.com:3000", "\n\n\t\t", [("port", "3000")]),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (href, new_value, expected_fields) = item
    let url = @uri.parse(href) catch { _ => continue }
    let result = url.set_port(new_value)
    for efld in expected_fields {
      let (field, expected_val) = efld
      let actual = match field {
        "href" => result.href()
        "protocol" => result.protocol()
        "username" => result.username
        "password" => result.password
        "host" => result.host_str()
        "hostname" => result.hostname()
        "port" => result.port_str()
        "pathname" => result.pathname()
        "search" => result.search()
        "hash" => result.hash()
        _ => ""
      }
      if actual != expected_val {
        if failed < 10 {
          println(
            "FAIL set_port: href=\{href} new=\{new_value} field=\{field} expected=\{expected_val} got=\{actual}",
          )
        }
        failed = failed + 1
      } else {
        passed = passed + 1
      }
    }
  }
  println("WPT setter port: \{passed}/\{passed + failed} passed")
  if failed > 0 {
    println("WARN: \{failed} port setter cases failed")
    assert_eq(failed, 0)
  }
}

///|
test "WPT setter cases: pathname" {
  let cases : Array[(String, String, Array[(String, String)])] = [
    (
      "mailto:me@example.net",
      "/foo",
      [("href", "mailto:me@example.net"), ("pathname", "me@example.net")],
    ),
    (
      "data:original",
      "new value",
      [("href", "data:original"), ("pathname", "original")],
    ),
    (
      "sc:original",
      "new value",
      [("href", "sc:original"), ("pathname", "original")],
    ),
    ("file:///some/path", "", [("href", "file:///"), ("pathname", "/")]),
    (
      "foo://somehost/some/path",
      "",
      [("href", "foo://somehost"), ("pathname", "")],
    ),
    ("foo:///some/path", "", [("href", "foo://"), ("pathname", "")]),
    ("foo:/some/path", "", [("href", "foo:/"), ("pathname", "/")]),
    ("foo:/some/path", "test", [("href", "foo:/test"), ("pathname", "/test")]),
    (
      "unix:/run/foo.socket?timeout=10",
      "/var/log/../run/bar.socket",
      [
        ("href", "unix:/var/run/bar.socket?timeout=10"),
        ("pathname", "/var/run/bar.socket"),
      ],
    ),
    (
      "https://example.net#nav",
      "home",
      [("href", "https://example.net/home#nav"), ("pathname", "/home")],
    ),
    (
      "https://example.net#nav",
      "../home",
      [("href", "https://example.net/home#nav"), ("pathname", "/home")],
    ),
    (
      "http://example.net/home?lang=fr#nav",
      "\\a\\%2E\\b\\%2e.\\c",
      [("href", "http://example.net/a/c?lang=fr#nav"), ("pathname", "/a/c")],
    ),
    (
      "view-source+http://example.net/home?lang=fr#nav",
      "\\a\\%2E\\b\\%2e.\\c",
      [
        (
          "href", "view-source+http://example.net/\\a\\%2E\\b\\%2e.\\c?lang=fr#nav",
        ),
        ("pathname", "/\\a\\%2E\\b\\%2e.\\c"),
      ],
    ),
    (
      "a:/",
      "\u{0000}\u{0001}\t\n\r\u{001F} !\"#$%&'()*+,-./09:;<=>?@AZ[\\]^_`az{|}~\u{007F}\u{0080}\u{0081}\u{00C9}\u{00E9}",
      [
        (
          "href", "a:/%00%01%1F%20!%22%23$%&'()*+,-./09:;%3C=%3E%3F@AZ[\\]%5E_%60az%7B|%7D~%7F%C2%80%C2%81%C3%89%C3%A9",
        ),
        (
          "pathname", "/%00%01%1F%20!%22%23$%&'()*+,-./09:;%3C=%3E%3F@AZ[\\]%5E_%60az%7B|%7D~%7F%C2%80%C2%81%C3%89%C3%A9",
        ),
      ],
    ),
    (
      "http://example.net",
      "%2e%2E%c3%89t\u{00E9}",
      [
        ("href", "http://example.net/%2e%2E%c3%89t%C3%A9"),
        ("pathname", "/%2e%2E%c3%89t%C3%A9"),
      ],
    ),
    (
      "http://example.net",
      "?",
      [("href", "http://example.net/%3F"), ("pathname", "/%3F")],
    ),
    (
      "http://example.net",
      "#",
      [("href", "http://example.net/%23"), ("pathname", "/%23")],
    ),
    (
      "sc://example.net",
      "?",
      [("href", "sc://example.net/%3F"), ("pathname", "/%3F")],
    ),
    (
      "sc://example.net",
      "#",
      [("href", "sc://example.net/%23"), ("pathname", "/%23")],
    ),
    (
      "http://example.net",
      "/?\u{00E9}",
      [("href", "http://example.net/%3F%C3%A9"), ("pathname", "/%3F%C3%A9")],
    ),
    (
      "http://example.net",
      "/#\u{00E9}",
      [("href", "http://example.net/%23%C3%A9"), ("pathname", "/%23%C3%A9")],
    ),
    (
      "file://monkey/",
      "\\\\",
      [("href", "file://monkey//"), ("pathname", "//")],
    ),
    (
      "file:///unicorn",
      "//\\/",
      [("href", "file://////"), ("pathname", "////")],
    ),
    (
      "file:///unicorn",
      "//monkey/..//",
      [("href", "file://///"), ("pathname", "///")],
    ),
    ("non-spec:/", "/.//p", [("href", "non-spec:/.//p"), ("pathname", "//p")]),
    ("non-spec:/", "/..//p", [("href", "non-spec:/.//p"), ("pathname", "//p")]),
    ("non-spec:/", "//p", [("href", "non-spec:/.//p"), ("pathname", "//p")]),
    ("non-spec:/.//", "p", [("href", "non-spec:/p"), ("pathname", "/p")]),
    (
      "data:/nospace",
      "space ",
      [("href", "data:/space%20"), ("pathname", "/space%20")],
    ),
    (
      "sc:/nospace",
      "space ",
      [("href", "sc:/space%20"), ("pathname", "/space%20")],
    ),
    (
      "http://example.net",
      " ",
      [("href", "http://example.net/%20"), ("pathname", "/%20")],
    ),
    (
      "http://example.net",
      "\u{0000}",
      [("href", "http://example.net/%00"), ("pathname", "/%00")],
    ),
    ("foo://path/to", "/..", [("href", "foo://path/"), ("pathname", "/")]),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (href, new_value, expected_fields) = item
    let url = @uri.parse(href) catch { _ => continue }
    let result = url.set_pathname(new_value)
    for efld in expected_fields {
      let (field, expected_val) = efld
      let actual = match field {
        "href" => result.href()
        "protocol" => result.protocol()
        "username" => result.username
        "password" => result.password
        "host" => result.host_str()
        "hostname" => result.hostname()
        "port" => result.port_str()
        "pathname" => result.pathname()
        "search" => result.search()
        "hash" => result.hash()
        _ => ""
      }
      if actual != expected_val {
        if failed < 10 {
          println(
            "FAIL set_pathname: href=\{href} new=\{new_value} field=\{field} expected=\{expected_val} got=\{actual}",
          )
        }
        failed = failed + 1
      } else {
        passed = passed + 1
      }
    }
  }
  println("WPT setter pathname: \{passed}/\{passed + failed} passed")
  if failed > 0 {
    println("WARN: \{failed} pathname setter cases failed")
    assert_eq(failed, 0)
  }
}

///|
test "WPT setter cases: search" {
  let cases : Array[(String, String, Array[(String, String)])] = [
    (
      "https://example.net#nav",
      "lang=fr",
      [("href", "https://example.net/?lang=fr#nav"), ("search", "?lang=fr")],
    ),
    (
      "https://example.net?lang=en-US#nav",
      "lang=fr",
      [("href", "https://example.net/?lang=fr#nav"), ("search", "?lang=fr")],
    ),
    (
      "https://example.net?lang=en-US#nav",
      "?lang=fr",
      [("href", "https://example.net/?lang=fr#nav"), ("search", "?lang=fr")],
    ),
    (
      "https://example.net?lang=en-US#nav",
      "??lang=fr",
      [("href", "https://example.net/??lang=fr#nav"), ("search", "??lang=fr")],
    ),
    (
      "https://example.net?lang=en-US#nav",
      "?",
      [("href", "https://example.net/?#nav"), ("search", "")],
    ),
    (
      "https://example.net?lang=en-US#nav",
      "",
      [("href", "https://example.net/#nav"), ("search", "")],
    ),
    (
      "https://example.net?lang=en-US",
      "",
      [("href", "https://example.net/"), ("search", "")],
    ),
    (
      "https://example.net",
      "",
      [("href", "https://example.net/"), ("search", "")],
    ),
    (
      "a:/",
      "\u{0000}\u{0001}\t\n\r\u{001F} !\"#$%&'()*+,-./09:;<=>?@AZ[\\]^_`az{|}~\u{007F}\u{0080}\u{0081}\u{00C9}\u{00E9}",
      [
        (
          "href", "a:/?%00%01%1F%20!%22%23$%&'()*+,-./09:;%3C=%3E?@AZ[\\]^_`az{|}~%7F%C2%80%C2%81%C3%89%C3%A9",
        ),
        (
          "search", "?%00%01%1F%20!%22%23$%&'()*+,-./09:;%3C=%3E?@AZ[\\]^_`az{|}~%7F%C2%80%C2%81%C3%89%C3%A9",
        ),
      ],
    ),
    (
      "http://example.net",
      "%c3%89t\u{00E9}",
      [
        ("href", "http://example.net/?%c3%89t%C3%A9"),
        ("search", "?%c3%89t%C3%A9"),
      ],
    ),
    (
      "data:space ?query",
      "",
      [("href", "data:space%20"), ("pathname", "space%20"), ("search", "")],
    ),
    (
      "sc:space ?query",
      "",
      [("href", "sc:space%20"), ("pathname", "space%20"), ("search", "")],
    ),
    (
      "data:space  ?query#fragment",
      "",
      [("href", "data:space %20#fragment"), ("search", "")],
    ),
    (
      "sc:space  ?query#fragment",
      "",
      [("href", "sc:space %20#fragment"), ("search", "")],
    ),
    (
      "http://example.net",
      " ",
      [("href", "http://example.net/?%20"), ("search", "?%20")],
    ),
    (
      "http://example.net",
      "\u{0000}",
      [("href", "http://example.net/?%00"), ("search", "?%00")],
    ),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (href, new_value, expected_fields) = item
    let url = @uri.parse(href) catch { _ => continue }
    let result = url.set_search(new_value)
    for efld in expected_fields {
      let (field, expected_val) = efld
      let actual = match field {
        "href" => result.href()
        "protocol" => result.protocol()
        "username" => result.username
        "password" => result.password
        "host" => result.host_str()
        "hostname" => result.hostname()
        "port" => result.port_str()
        "pathname" => result.pathname()
        "search" => result.search()
        "hash" => result.hash()
        _ => ""
      }
      if actual != expected_val {
        if failed < 10 {
          println(
            "FAIL set_search: href=\{href} new=\{new_value} field=\{field} expected=\{expected_val} got=\{actual}",
          )
        }
        failed = failed + 1
      } else {
        passed = passed + 1
      }
    }
  }
  println("WPT setter search: \{passed}/\{passed + failed} passed")
  if failed > 0 {
    println("WARN: \{failed} search setter cases failed")
    assert_eq(failed, 0)
  }
}

///|
test "WPT setter cases: hash" {
  let cases : Array[(String, String, Array[(String, String)])] = [
    (
      "https://example.net",
      "main",
      [("href", "https://example.net/#main"), ("hash", "#main")],
    ),
    (
      "https://example.net#nav",
      "main",
      [("href", "https://example.net/#main"), ("hash", "#main")],
    ),
    (
      "https://example.net?lang=en-US",
      "##nav",
      [("href", "https://example.net/?lang=en-US##nav"), ("hash", "##nav")],
    ),
    (
      "https://example.net?lang=en-US#nav",
      "#main",
      [("href", "https://example.net/?lang=en-US#main"), ("hash", "#main")],
    ),
    (
      "https://example.net?lang=en-US#nav",
      "#",
      [("href", "https://example.net/?lang=en-US#"), ("hash", "")],
    ),
    (
      "https://example.net?lang=en-US#nav",
      "",
      [("href", "https://example.net/?lang=en-US"), ("hash", "")],
    ),
    (
      "http://example.net",
      "#foo bar",
      [("href", "http://example.net/#foo%20bar"), ("hash", "#foo%20bar")],
    ),
    (
      "http://example.net",
      "#foo\"bar",
      [("href", "http://example.net/#foo%22bar"), ("hash", "#foo%22bar")],
    ),
    (
      "http://example.net",
      "#foo<bar",
      [("href", "http://example.net/#foo%3Cbar"), ("hash", "#foo%3Cbar")],
    ),
    (
      "http://example.net",
      "#foo>bar",
      [("href", "http://example.net/#foo%3Ebar"), ("hash", "#foo%3Ebar")],
    ),
    (
      "http://example.net",
      "#foo`bar",
      [("href", "http://example.net/#foo%60bar"), ("hash", "#foo%60bar")],
    ),
    (
      "a:/",
      "\u{0000}\u{0001}\t\n\r\u{001F} !\"#$%&'()*+,-./09:;<=>?@AZ[\\]^_`az{|}~\u{007F}\u{0080}\u{0081}\u{00C9}\u{00E9}",
      [
        (
          "href", "a:/#%00%01%1F%20!%22#$%&'()*+,-./09:;%3C=%3E?@AZ[\\]^_%60az{|}~%7F%C2%80%C2%81%C3%89%C3%A9",
        ),
        (
          "hash", "#%00%01%1F%20!%22#$%&'()*+,-./09:;%3C=%3E?@AZ[\\]^_%60az{|}~%7F%C2%80%C2%81%C3%89%C3%A9",
        ),
      ],
    ),
    (
      "http://example.net",
      "a\u{0000}b",
      [("href", "http://example.net/#a%00b"), ("hash", "#a%00b")],
    ),
    (
      "non-spec:/",
      "a\u{0000}b",
      [("href", "non-spec:/#a%00b"), ("hash", "#a%00b")],
    ),
    (
      "http://example.net",
      "%c3%89t\u{00E9}",
      [
        ("href", "http://example.net/#%c3%89t%C3%A9"),
        ("hash", "#%c3%89t%C3%A9"),
      ],
    ),
    (
      "javascript:alert(1)",
      "castle",
      [("href", "javascript:alert(1)#castle"), ("hash", "#castle")],
    ),
    (
      "data:space                                                                                                                                  #fragment",
      "",
      [
        (
          "href", "data:space                                                                                                                                 %20",
        ),
        (
          "pathname", "space                                                                                                                                 %20",
        ),
        ("hash", ""),
      ],
    ),
    (
      "sc:space    #fragment",
      "",
      [("href", "sc:space   %20"), ("pathname", "space   %20"), ("hash", "")],
    ),
    (
      "data:space  ?query#fragment",
      "",
      [("href", "data:space %20?query"), ("hash", "")],
    ),
    (
      "sc:space  ?query#fragment",
      "",
      [("href", "sc:space %20?query"), ("hash", "")],
    ),
    (
      "http://example.net",
      " ",
      [("href", "http://example.net/#%20"), ("hash", "#%20")],
    ),
    (
      "http://example.net",
      "\u{0000}",
      [("href", "http://example.net/#%00"), ("hash", "#%00")],
    ),
    (
      "data:text/plain,test",
      "#<foo> <bar>",
      [
        ("href", "data:text/plain,test#%3Cfoo%3E%20%3Cbar%3E"),
        ("hash", "#%3Cfoo%3E%20%3Cbar%3E"),
      ],
    ),
    (
      "about:blank",
      "#<foo> <bar>",
      [
        ("href", "about:blank#%3Cfoo%3E%20%3Cbar%3E"),
        ("hash", "#%3Cfoo%3E%20%3Cbar%3E"),
      ],
    ),
    (
      "data:text/plain,test",
      "#\u{0000}\u{0001}\t\n\r\u{001F} !\"#$%&'()*+,-./09:;<=>?@AZ[\\]^_`az{|}~\u{007F}\u{0080}\u{0081}\u{00C9}\u{00E9}",
      [
        (
          "href", "data:text/plain,test#%00%01%1F%20!%22#$%&'()*+,-./09:;%3C=%3E?@AZ[\\]^_%60az{|}~%7F%C2%80%C2%81%C3%89%C3%A9",
        ),
        (
          "hash", "#%00%01%1F%20!%22#$%&'()*+,-./09:;%3C=%3E?@AZ[\\]^_%60az{|}~%7F%C2%80%C2%81%C3%89%C3%A9",
        ),
      ],
    ),
    (
      "about:blank",
      "#\u{0000}\u{0001}\t\n\r\u{001F} !\"#$%&'()*+,-./09:;<=>?@AZ[\\]^_`az{|}~\u{007F}\u{0080}\u{0081}\u{00C9}\u{00E9}",
      [
        (
          "href", "about:blank#%00%01%1F%20!%22#$%&'()*+,-./09:;%3C=%3E?@AZ[\\]^_%60az{|}~%7F%C2%80%C2%81%C3%89%C3%A9",
        ),
        (
          "hash", "#%00%01%1F%20!%22#$%&'()*+,-./09:;%3C=%3E?@AZ[\\]^_%60az{|}~%7F%C2%80%C2%81%C3%89%C3%A9",
        ),
      ],
    ),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (href, new_value, expected_fields) = item
    let url = @uri.parse(href) catch { _ => continue }
    let result = url.set_hash(new_value)
    for efld in expected_fields {
      let (field, expected_val) = efld
      let actual = match field {
        "href" => result.href()
        "protocol" => result.protocol()
        "username" => result.username
        "password" => result.password
        "host" => result.host_str()
        "hostname" => result.hostname()
        "port" => result.port_str()
        "pathname" => result.pathname()
        "search" => result.search()
        "hash" => result.hash()
        _ => ""
      }
      if actual != expected_val {
        if failed < 10 {
          println(
            "FAIL set_hash: href=\{href} new=\{new_value} field=\{field} expected=\{expected_val} got=\{actual}",
          )
        }
        failed = failed + 1
      } else {
        passed = passed + 1
      }
    }
  }
  println("WPT setter hash: \{passed}/\{passed + failed} passed")
  if failed > 0 {
    println("WARN: \{failed} hash setter cases failed")
    assert_eq(failed, 0)
  }
}

///|
test "WPT setter cases: href" {
  let cases : Array[(String, String, Array[(String, String)])] = [
    (
      "file:///var/log/system.log",
      "http://0300.168.0xF0",
      [("href", "http://192.168.0.240/"), ("protocol", "http:")],
    ),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (href, new_value, expected_fields) = item
    let url = @uri.parse(href) catch { _ => continue }
    let result = url.set_href(new_value) catch { _ => continue }
    for efld in expected_fields {
      let (field, expected_val) = efld
      let actual = match field {
        "href" => result.href()
        "protocol" => result.protocol()
        "username" => result.username
        "password" => result.password
        "host" => result.host_str()
        "hostname" => result.hostname()
        "port" => result.port_str()
        "pathname" => result.pathname()
        "search" => result.search()
        "hash" => result.hash()
        _ => ""
      }
      if actual != expected_val {
        if failed < 10 {
          println(
            "FAIL set_href: href=\{href} new=\{new_value} field=\{field} expected=\{expected_val} got=\{actual}",
          )
        }
        failed = failed + 1
      } else {
        passed = passed + 1
      }
    }
  }
  println("WPT setter href: \{passed}/\{passed + failed} passed")
  if failed > 0 {
    println("WARN: \{failed} href setter cases failed")
    assert_eq(failed, 0)
  }
}
