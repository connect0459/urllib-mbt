// Generated WPT url-setters-stripping test vectors

///|
test "WPT setters-stripping: protocol" {
  let cases : Array[(String, String, String, String)] = [
    (
      "https://username:password@host:8000/path?query#fragment", "\u{0000}http",
      "https:", "https://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "http\u{0000}",
      "https:", "https://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\thttp", "http:",
      "http://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "http\t", "http:",
      "http://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\nhttp", "http:",
      "http://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "http\n", "http:",
      "http://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\rhttp", "http:",
      "http://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "http\r", "http:",
      "http://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\u{001F}http",
      "https:", "https://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "http\u{001F}",
      "https:", "https://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\u{0000}wpt--",
      "wpt++:", "wpt++://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "wpt--\u{0000}",
      "wpt++:", "wpt++://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\twpt--", "wpt--:",
      "wpt--://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "wpt--\t", "wpt--:",
      "wpt--://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\nwpt--", "wpt--:",
      "wpt--://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "wpt--\n", "wpt--:",
      "wpt--://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\rwpt--", "wpt--:",
      "wpt--://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "wpt--\r", "wpt--:",
      "wpt--://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\u{001F}wpt--",
      "wpt++:", "wpt++://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "wpt--\u{001F}",
      "wpt++:", "wpt++://username:password@host:8000/path?query#fragment",
    ),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (base_str, setter_input, exp_protocol, exp_href) = item
    let url = @uri.parse(base_str)
    let new_url = url.set_protocol(setter_input)
    let mut ok = true
    if new_url.protocol() != exp_protocol {
      if failed < 10 {
        println(
          "FAIL protocol/protocol: got=\{new_url.protocol()} want=\{exp_protocol}",
        )
      }
      ok = false
    }
    if new_url.href() != exp_href {
      if failed < 10 {
        println("FAIL protocol/href: got=\{new_url.href()} want=\{exp_href}")
      }
      ok = false
    }
    if ok {
      passed = passed + 1
    } else {
      failed = failed + 1
    }
  }
  println("WPT stripping/protocol: \{passed}/\{passed + failed} passed")
  if failed > 0 {
    println("WARN: \{failed} WPT stripping/protocol cases failed")
  }
}

///|
test "WPT setters-stripping: username" {
  let cases : Array[(String, String, String, String)] = [
    (
      "https://username:password@host:8000/path?query#fragment", "\u{0000}test",
      "%00test", "https://%00test:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\u{0000}st",
      "te%00st", "https://te%00st:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\u{0000}",
      "test%00", "https://test%00:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\ttest", "%09test",
      "https://%09test:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\tst", "te%09st",
      "https://te%09st:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\t", "test%09",
      "https://test%09:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\ntest", "%0Atest",
      "https://%0Atest:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\nst", "te%0Ast",
      "https://te%0Ast:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\n", "test%0A",
      "https://test%0A:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\rtest", "%0Dtest",
      "https://%0Dtest:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\rst", "te%0Dst",
      "https://te%0Dst:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\r", "test%0D",
      "https://test%0D:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\u{001F}test",
      "%1Ftest", "https://%1Ftest:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\u{001F}st",
      "te%1Fst", "https://te%1Fst:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\u{001F}",
      "test%1F", "https://test%1F:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\u{0000}test",
      "%00test", "wpt++://%00test:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\u{0000}st",
      "te%00st", "wpt++://te%00st:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\u{0000}",
      "test%00", "wpt++://test%00:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\ttest", "%09test",
      "wpt++://%09test:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\tst", "te%09st",
      "wpt++://te%09st:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\t", "test%09",
      "wpt++://test%09:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\ntest", "%0Atest",
      "wpt++://%0Atest:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\nst", "te%0Ast",
      "wpt++://te%0Ast:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\n", "test%0A",
      "wpt++://test%0A:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\rtest", "%0Dtest",
      "wpt++://%0Dtest:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\rst", "te%0Dst",
      "wpt++://te%0Dst:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\r", "test%0D",
      "wpt++://test%0D:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\u{001F}test",
      "%1Ftest", "wpt++://%1Ftest:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\u{001F}st",
      "te%1Fst", "wpt++://te%1Fst:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\u{001F}",
      "test%1F", "wpt++://test%1F:password@host:8000/path?query#fragment",
    ),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (base_str, setter_input, exp_username, exp_href) = item
    let url = @uri.parse(base_str)
    let new_url = url.set_username(setter_input)
    let mut ok = true
    if new_url.username != exp_username {
      if failed < 10 {
        println(
          "FAIL username/username: got=\{new_url.username} want=\{exp_username}",
        )
      }
      ok = false
    }
    if new_url.href() != exp_href {
      if failed < 10 {
        println("FAIL username/href: got=\{new_url.href()} want=\{exp_href}")
      }
      ok = false
    }
    if ok {
      passed = passed + 1
    } else {
      failed = failed + 1
    }
  }
  println("WPT stripping/username: \{passed}/\{passed + failed} passed")
  if failed > 0 {
    println("WARN: \{failed} WPT stripping/username cases failed")
  }
}

///|
test "WPT setters-stripping: password" {
  let cases : Array[(String, String, String, String)] = [
    (
      "https://username:password@host:8000/path?query#fragment", "\u{0000}test",
      "%00test", "https://username:%00test@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\u{0000}st",
      "te%00st", "https://username:te%00st@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\u{0000}",
      "test%00", "https://username:test%00@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\ttest", "%09test",
      "https://username:%09test@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\tst", "te%09st",
      "https://username:te%09st@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\t", "test%09",
      "https://username:test%09@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\ntest", "%0Atest",
      "https://username:%0Atest@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\nst", "te%0Ast",
      "https://username:te%0Ast@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\n", "test%0A",
      "https://username:test%0A@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\rtest", "%0Dtest",
      "https://username:%0Dtest@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\rst", "te%0Dst",
      "https://username:te%0Dst@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\r", "test%0D",
      "https://username:test%0D@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\u{001F}test",
      "%1Ftest", "https://username:%1Ftest@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\u{001F}st",
      "te%1Fst", "https://username:te%1Fst@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\u{001F}",
      "test%1F", "https://username:test%1F@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\u{0000}test",
      "%00test", "wpt++://username:%00test@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\u{0000}st",
      "te%00st", "wpt++://username:te%00st@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\u{0000}",
      "test%00", "wpt++://username:test%00@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\ttest", "%09test",
      "wpt++://username:%09test@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\tst", "te%09st",
      "wpt++://username:te%09st@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\t", "test%09",
      "wpt++://username:test%09@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\ntest", "%0Atest",
      "wpt++://username:%0Atest@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\nst", "te%0Ast",
      "wpt++://username:te%0Ast@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\n", "test%0A",
      "wpt++://username:test%0A@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\rtest", "%0Dtest",
      "wpt++://username:%0Dtest@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\rst", "te%0Dst",
      "wpt++://username:te%0Dst@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\r", "test%0D",
      "wpt++://username:test%0D@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\u{001F}test",
      "%1Ftest", "wpt++://username:%1Ftest@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\u{001F}st",
      "te%1Fst", "wpt++://username:te%1Fst@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\u{001F}",
      "test%1F", "wpt++://username:test%1F@host:8000/path?query#fragment",
    ),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (base_str, setter_input, exp_password, exp_href) = item
    let url = @uri.parse(base_str)
    let new_url = url.set_password(setter_input)
    let mut ok = true
    if new_url.password != exp_password {
      if failed < 10 {
        println(
          "FAIL password/password: got=\{new_url.password} want=\{exp_password}",
        )
      }
      ok = false
    }
    if new_url.href() != exp_href {
      if failed < 10 {
        println("FAIL password/href: got=\{new_url.href()} want=\{exp_href}")
      }
      ok = false
    }
    if ok {
      passed = passed + 1
    } else {
      failed = failed + 1
    }
  }
  println("WPT stripping/password: \{passed}/\{passed + failed} passed")
  if failed > 0 {
    println("WARN: \{failed} WPT stripping/password cases failed")
  }
}

///|
test "WPT setters-stripping: host" {
  let cases : Array[(String, String, String, String, String)] = [
    (
      "https://username:password@host:8000/path?query#fragment", "\u{0000}test",
      "host", "host:8000", "https://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\u{0000}st",
      "host", "host:8000", "https://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\u{0000}",
      "host", "host:8000", "https://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\ttest", "test",
      "test:8000", "https://username:password@test:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\tst", "test",
      "test:8000", "https://username:password@test:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\t", "test",
      "test:8000", "https://username:password@test:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\ntest", "test",
      "test:8000", "https://username:password@test:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\nst", "test",
      "test:8000", "https://username:password@test:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\n", "test",
      "test:8000", "https://username:password@test:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\rtest", "test",
      "test:8000", "https://username:password@test:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\rst", "test",
      "test:8000", "https://username:password@test:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\r", "test",
      "test:8000", "https://username:password@test:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\u{001F}test",
      "host", "host:8000", "https://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\u{001F}st",
      "host", "host:8000", "https://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\u{001F}",
      "host", "host:8000", "https://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\u{0000}test",
      "host", "host:8000", "wpt++://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\u{0000}st",
      "host", "host:8000", "wpt++://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\u{0000}",
      "host", "host:8000", "wpt++://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\ttest", "test",
      "test:8000", "wpt++://username:password@test:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\tst", "test",
      "test:8000", "wpt++://username:password@test:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\t", "test",
      "test:8000", "wpt++://username:password@test:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\ntest", "test",
      "test:8000", "wpt++://username:password@test:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\nst", "test",
      "test:8000", "wpt++://username:password@test:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\n", "test",
      "test:8000", "wpt++://username:password@test:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\rtest", "test",
      "test:8000", "wpt++://username:password@test:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\rst", "test",
      "test:8000", "wpt++://username:password@test:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\r", "test",
      "test:8000", "wpt++://username:password@test:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\u{001F}test",
      "%1Ftest", "%1Ftest:8000", "wpt++://username:password@%1Ftest:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\u{001F}st",
      "te%1Fst", "te%1Fst:8000", "wpt++://username:password@te%1Fst:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\u{001F}",
      "test%1F", "test%1F:8000", "wpt++://username:password@test%1F:8000/path?query#fragment",
    ),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (base_str, setter_input, exp_hostname, exp_host_str, exp_href) = item
    let url = @uri.parse(base_str)
    let new_url = url.set_host(setter_input)
    let mut ok = true
    if new_url.hostname() != exp_hostname {
      if failed < 10 {
        println(
          "FAIL host/hostname: input=\{setter_input} got=\{new_url.hostname()} want=\{exp_hostname}",
        )
      }
      ok = false
    }
    if new_url.host_str() != exp_host_str {
      if failed < 10 {
        println(
          "FAIL host/host_str: input=\{setter_input} got=\{new_url.host_str()} want=\{exp_host_str}",
        )
      }
      ok = false
    }
    if new_url.href() != exp_href {
      if failed < 10 {
        println(
          "FAIL host/href: input=\{setter_input} got=\{new_url.href()} want=\{exp_href}",
        )
      }
      ok = false
    }
    if ok {
      passed = passed + 1
    } else {
      failed = failed + 1
    }
  }
  println("WPT stripping/host: \{passed}/\{passed + failed} passed")
  if failed > 0 {
    println("WARN: \{failed} WPT stripping/host cases failed")
  }
}

///|
test "WPT setters-stripping: hostname" {
  let cases : Array[(String, String, String, String, String)] = [
    (
      "https://username:password@host:8000/path?query#fragment", "\u{0000}test",
      "host", "host:8000", "https://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\u{0000}st",
      "host", "host:8000", "https://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\u{0000}",
      "host", "host:8000", "https://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\ttest", "test",
      "test:8000", "https://username:password@test:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\tst", "test",
      "test:8000", "https://username:password@test:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\t", "test",
      "test:8000", "https://username:password@test:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\ntest", "test",
      "test:8000", "https://username:password@test:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\nst", "test",
      "test:8000", "https://username:password@test:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\n", "test",
      "test:8000", "https://username:password@test:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\rtest", "test",
      "test:8000", "https://username:password@test:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\rst", "test",
      "test:8000", "https://username:password@test:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\r", "test",
      "test:8000", "https://username:password@test:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\u{001F}test",
      "host", "host:8000", "https://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\u{001F}st",
      "host", "host:8000", "https://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\u{001F}",
      "host", "host:8000", "https://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\u{0000}test",
      "host", "host:8000", "wpt++://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\u{0000}st",
      "host", "host:8000", "wpt++://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\u{0000}",
      "host", "host:8000", "wpt++://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\ttest", "test",
      "test:8000", "wpt++://username:password@test:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\tst", "test",
      "test:8000", "wpt++://username:password@test:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\t", "test",
      "test:8000", "wpt++://username:password@test:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\ntest", "test",
      "test:8000", "wpt++://username:password@test:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\nst", "test",
      "test:8000", "wpt++://username:password@test:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\n", "test",
      "test:8000", "wpt++://username:password@test:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\rtest", "test",
      "test:8000", "wpt++://username:password@test:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\rst", "test",
      "test:8000", "wpt++://username:password@test:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\r", "test",
      "test:8000", "wpt++://username:password@test:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\u{001F}test",
      "%1Ftest", "%1Ftest:8000", "wpt++://username:password@%1Ftest:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\u{001F}st",
      "te%1Fst", "te%1Fst:8000", "wpt++://username:password@te%1Fst:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\u{001F}",
      "test%1F", "test%1F:8000", "wpt++://username:password@test%1F:8000/path?query#fragment",
    ),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (base_str, setter_input, exp_hostname, exp_host_str, exp_href) = item
    let url = @uri.parse(base_str)
    let new_url = url.set_hostname(setter_input)
    let mut ok = true
    if new_url.hostname() != exp_hostname {
      if failed < 10 {
        println(
          "FAIL hostname/hostname: input=\{setter_input} got=\{new_url.hostname()} want=\{exp_hostname}",
        )
      }
      ok = false
    }
    if new_url.host_str() != exp_host_str {
      if failed < 10 {
        println(
          "FAIL hostname/host_str: input=\{setter_input} got=\{new_url.host_str()} want=\{exp_host_str}",
        )
      }
      ok = false
    }
    if new_url.href() != exp_href {
      if failed < 10 {
        println(
          "FAIL hostname/href: input=\{setter_input} got=\{new_url.href()} want=\{exp_href}",
        )
      }
      ok = false
    }
    if ok {
      passed = passed + 1
    } else {
      failed = failed + 1
    }
  }
  println("WPT stripping/hostname: \{passed}/\{passed + failed} passed")
  if failed > 0 {
    println("WARN: \{failed} WPT stripping/hostname cases failed")
  }
}

///|
test "WPT setters-stripping: port" {
  let cases : Array[(String, String, String, String)] = [
    (
      "https://username:password@host:8000/path?query#fragment", "\u{0000}9000",
      "8000", "https://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "90\u{0000}00",
      "90", "https://username:password@host:90/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "9000\u{0000}",
      "9000", "https://username:password@host:9000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\t9000", "9000",
      "https://username:password@host:9000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "90\t00", "9000",
      "https://username:password@host:9000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "9000\t", "9000",
      "https://username:password@host:9000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\n9000", "9000",
      "https://username:password@host:9000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "90\n00", "9000",
      "https://username:password@host:9000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "9000\n", "9000",
      "https://username:password@host:9000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\r9000", "9000",
      "https://username:password@host:9000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "90\r00", "9000",
      "https://username:password@host:9000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "9000\r", "9000",
      "https://username:password@host:9000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\u{001F}9000",
      "8000", "https://username:password@host:8000/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "90\u{001F}00",
      "90", "https://username:password@host:90/path?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "9000\u{001F}",
      "9000", "https://username:password@host:9000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\u{0000}9000",
      "8000", "wpt++://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "90\u{0000}00",
      "90", "wpt++://username:password@host:90/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "9000\u{0000}",
      "9000", "wpt++://username:password@host:9000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\t9000", "9000",
      "wpt++://username:password@host:9000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "90\t00", "9000",
      "wpt++://username:password@host:9000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "9000\t", "9000",
      "wpt++://username:password@host:9000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\n9000", "9000",
      "wpt++://username:password@host:9000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "90\n00", "9000",
      "wpt++://username:password@host:9000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "9000\n", "9000",
      "wpt++://username:password@host:9000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\r9000", "9000",
      "wpt++://username:password@host:9000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "90\r00", "9000",
      "wpt++://username:password@host:9000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "9000\r", "9000",
      "wpt++://username:password@host:9000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\u{001F}9000",
      "8000", "wpt++://username:password@host:8000/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "90\u{001F}00",
      "90", "wpt++://username:password@host:90/path?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "9000\u{001F}",
      "9000", "wpt++://username:password@host:9000/path?query#fragment",
    ),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (base_str, setter_input, exp_port, exp_href) = item
    let url = @uri.parse(base_str)
    let new_url = url.set_port(setter_input)
    let mut ok = true
    if new_url.port_str() != exp_port {
      if failed < 10 {
        println("FAIL port/port: got=\{new_url.port_str()} want=\{exp_port}")
      }
      ok = false
    }
    if new_url.href() != exp_href {
      if failed < 10 {
        println("FAIL port/href: got=\{new_url.href()} want=\{exp_href}")
      }
      ok = false
    }
    if ok {
      passed = passed + 1
    } else {
      failed = failed + 1
    }
  }
  println("WPT stripping/port: \{passed}/\{passed + failed} passed")
  if failed > 0 {
    println("WARN: \{failed} WPT stripping/port cases failed")
  }
}

///|
test "WPT setters-stripping: pathname" {
  let cases : Array[(String, String, String, String)] = [
    (
      "https://username:password@host:8000/path?query#fragment", "\u{0000}test",
      "/%00test", "https://username:password@host:8000/%00test?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\u{0000}st",
      "/te%00st", "https://username:password@host:8000/te%00st?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\u{0000}",
      "/test%00", "https://username:password@host:8000/test%00?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\ttest", "/test",
      "https://username:password@host:8000/test?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\tst", "/test",
      "https://username:password@host:8000/test?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\t", "/test",
      "https://username:password@host:8000/test?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\ntest", "/test",
      "https://username:password@host:8000/test?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\nst", "/test",
      "https://username:password@host:8000/test?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\n", "/test",
      "https://username:password@host:8000/test?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\rtest", "/test",
      "https://username:password@host:8000/test?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\rst", "/test",
      "https://username:password@host:8000/test?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\r", "/test",
      "https://username:password@host:8000/test?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\u{001F}test",
      "/%1Ftest", "https://username:password@host:8000/%1Ftest?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\u{001F}st",
      "/te%1Fst", "https://username:password@host:8000/te%1Fst?query#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\u{001F}",
      "/test%1F", "https://username:password@host:8000/test%1F?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\u{0000}test",
      "/%00test", "wpt++://username:password@host:8000/%00test?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\u{0000}st",
      "/te%00st", "wpt++://username:password@host:8000/te%00st?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\u{0000}",
      "/test%00", "wpt++://username:password@host:8000/test%00?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\ttest", "/test",
      "wpt++://username:password@host:8000/test?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\tst", "/test",
      "wpt++://username:password@host:8000/test?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\t", "/test",
      "wpt++://username:password@host:8000/test?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\ntest", "/test",
      "wpt++://username:password@host:8000/test?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\nst", "/test",
      "wpt++://username:password@host:8000/test?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\n", "/test",
      "wpt++://username:password@host:8000/test?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\rtest", "/test",
      "wpt++://username:password@host:8000/test?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\rst", "/test",
      "wpt++://username:password@host:8000/test?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\r", "/test",
      "wpt++://username:password@host:8000/test?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\u{001F}test",
      "/%1Ftest", "wpt++://username:password@host:8000/%1Ftest?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\u{001F}st",
      "/te%1Fst", "wpt++://username:password@host:8000/te%1Fst?query#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\u{001F}",
      "/test%1F", "wpt++://username:password@host:8000/test%1F?query#fragment",
    ),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (base_str, setter_input, exp_pathname, exp_href) = item
    let url = @uri.parse(base_str)
    let new_url = url.set_pathname(setter_input)
    let mut ok = true
    if new_url.pathname() != exp_pathname {
      if failed < 10 {
        println(
          "FAIL pathname/pathname: got=\{new_url.pathname()} want=\{exp_pathname}",
        )
      }
      ok = false
    }
    if new_url.href() != exp_href {
      if failed < 10 {
        println("FAIL pathname/href: got=\{new_url.href()} want=\{exp_href}")
      }
      ok = false
    }
    if ok {
      passed = passed + 1
    } else {
      failed = failed + 1
    }
  }
  println("WPT stripping/pathname: \{passed}/\{passed + failed} passed")
  if failed > 0 {
    println("WARN: \{failed} WPT stripping/pathname cases failed")
  }
}

///|
test "WPT setters-stripping: search" {
  let cases : Array[(String, String, String, String)] = [
    (
      "https://username:password@host:8000/path?query#fragment", "\u{0000}test",
      "?%00test", "https://username:password@host:8000/path?%00test#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\u{0000}st",
      "?te%00st", "https://username:password@host:8000/path?te%00st#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\u{0000}",
      "?test%00", "https://username:password@host:8000/path?test%00#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\ttest", "?test",
      "https://username:password@host:8000/path?test#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\tst", "?test",
      "https://username:password@host:8000/path?test#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\t", "?test",
      "https://username:password@host:8000/path?test#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\ntest", "?test",
      "https://username:password@host:8000/path?test#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\nst", "?test",
      "https://username:password@host:8000/path?test#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\n", "?test",
      "https://username:password@host:8000/path?test#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\rtest", "?test",
      "https://username:password@host:8000/path?test#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\rst", "?test",
      "https://username:password@host:8000/path?test#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\r", "?test",
      "https://username:password@host:8000/path?test#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\u{001F}test",
      "?%1Ftest", "https://username:password@host:8000/path?%1Ftest#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\u{001F}st",
      "?te%1Fst", "https://username:password@host:8000/path?te%1Fst#fragment",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\u{001F}",
      "?test%1F", "https://username:password@host:8000/path?test%1F#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\u{0000}test",
      "?%00test", "wpt++://username:password@host:8000/path?%00test#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\u{0000}st",
      "?te%00st", "wpt++://username:password@host:8000/path?te%00st#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\u{0000}",
      "?test%00", "wpt++://username:password@host:8000/path?test%00#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\ttest", "?test",
      "wpt++://username:password@host:8000/path?test#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\tst", "?test",
      "wpt++://username:password@host:8000/path?test#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\t", "?test",
      "wpt++://username:password@host:8000/path?test#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\ntest", "?test",
      "wpt++://username:password@host:8000/path?test#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\nst", "?test",
      "wpt++://username:password@host:8000/path?test#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\n", "?test",
      "wpt++://username:password@host:8000/path?test#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\rtest", "?test",
      "wpt++://username:password@host:8000/path?test#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\rst", "?test",
      "wpt++://username:password@host:8000/path?test#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\r", "?test",
      "wpt++://username:password@host:8000/path?test#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\u{001F}test",
      "?%1Ftest", "wpt++://username:password@host:8000/path?%1Ftest#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\u{001F}st",
      "?te%1Fst", "wpt++://username:password@host:8000/path?te%1Fst#fragment",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\u{001F}",
      "?test%1F", "wpt++://username:password@host:8000/path?test%1F#fragment",
    ),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (base_str, setter_input, exp_search, exp_href) = item
    let url = @uri.parse(base_str)
    let new_url = url.set_search(setter_input)
    let mut ok = true
    if new_url.search() != exp_search {
      if failed < 10 {
        println(
          "FAIL search/search: got=\{new_url.search()} want=\{exp_search}",
        )
      }
      ok = false
    }
    if new_url.href() != exp_href {
      if failed < 10 {
        println("FAIL search/href: got=\{new_url.href()} want=\{exp_href}")
      }
      ok = false
    }
    if ok {
      passed = passed + 1
    } else {
      failed = failed + 1
    }
  }
  println("WPT stripping/search: \{passed}/\{passed + failed} passed")
  if failed > 0 {
    println("WARN: \{failed} WPT stripping/search cases failed")
  }
}

///|
test "WPT setters-stripping: hash" {
  let cases : Array[(String, String, String, String)] = [
    (
      "https://username:password@host:8000/path?query#fragment", "\u{0000}test",
      "#%00test", "https://username:password@host:8000/path?query#%00test",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\u{0000}st",
      "#te%00st", "https://username:password@host:8000/path?query#te%00st",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\u{0000}",
      "#test%00", "https://username:password@host:8000/path?query#test%00",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\ttest", "#test",
      "https://username:password@host:8000/path?query#test",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\tst", "#test",
      "https://username:password@host:8000/path?query#test",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\t", "#test",
      "https://username:password@host:8000/path?query#test",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\ntest", "#test",
      "https://username:password@host:8000/path?query#test",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\nst", "#test",
      "https://username:password@host:8000/path?query#test",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\n", "#test",
      "https://username:password@host:8000/path?query#test",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\rtest", "#test",
      "https://username:password@host:8000/path?query#test",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\rst", "#test",
      "https://username:password@host:8000/path?query#test",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\r", "#test",
      "https://username:password@host:8000/path?query#test",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "\u{001F}test",
      "#%1Ftest", "https://username:password@host:8000/path?query#%1Ftest",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "te\u{001F}st",
      "#te%1Fst", "https://username:password@host:8000/path?query#te%1Fst",
    ),
    (
      "https://username:password@host:8000/path?query#fragment", "test\u{001F}",
      "#test%1F", "https://username:password@host:8000/path?query#test%1F",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\u{0000}test",
      "#%00test", "wpt++://username:password@host:8000/path?query#%00test",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\u{0000}st",
      "#te%00st", "wpt++://username:password@host:8000/path?query#te%00st",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\u{0000}",
      "#test%00", "wpt++://username:password@host:8000/path?query#test%00",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\ttest", "#test",
      "wpt++://username:password@host:8000/path?query#test",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\tst", "#test",
      "wpt++://username:password@host:8000/path?query#test",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\t", "#test",
      "wpt++://username:password@host:8000/path?query#test",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\ntest", "#test",
      "wpt++://username:password@host:8000/path?query#test",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\nst", "#test",
      "wpt++://username:password@host:8000/path?query#test",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\n", "#test",
      "wpt++://username:password@host:8000/path?query#test",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\rtest", "#test",
      "wpt++://username:password@host:8000/path?query#test",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\rst", "#test",
      "wpt++://username:password@host:8000/path?query#test",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\r", "#test",
      "wpt++://username:password@host:8000/path?query#test",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "\u{001F}test",
      "#%1Ftest", "wpt++://username:password@host:8000/path?query#%1Ftest",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "te\u{001F}st",
      "#te%1Fst", "wpt++://username:password@host:8000/path?query#te%1Fst",
    ),
    (
      "wpt++://username:password@host:8000/path?query#fragment", "test\u{001F}",
      "#test%1F", "wpt++://username:password@host:8000/path?query#test%1F",
    ),
  ]
  let mut passed = 0
  let mut failed = 0
  for item in cases {
    let (base_str, setter_input, exp_hash, exp_href) = item
    let url = @uri.parse(base_str)
    let new_url = url.set_hash(setter_input)
    let mut ok = true
    if new_url.hash() != exp_hash {
      if failed < 10 {
        println("FAIL hash/hash: got=\{new_url.hash()} want=\{exp_hash}")
      }
      ok = false
    }
    if new_url.href() != exp_href {
      if failed < 10 {
        println("FAIL hash/href: got=\{new_url.href()} want=\{exp_href}")
      }
      ok = false
    }
    if ok {
      passed = passed + 1
    } else {
      failed = failed + 1
    }
  }
  println("WPT stripping/hash: \{passed}/\{passed + failed} passed")
  if failed > 0 {
    println("WARN: \{failed} WPT stripping/hash cases failed")
  }
}
