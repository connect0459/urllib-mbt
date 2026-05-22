///|
test "Show for HostParseError includes message" {
  let err = HostParseError("test message")
  assert_eq("\{err}", "HostParseError: test message")
}

///|
test "domain_has_forbidden_char: U+FFFD replacement char is forbidden" {
  assert_eq(domain_has_forbidden_char("\u{FFFD}"), true)
}

///|
test "domain_has_forbidden_char: U+FDD0 noncharacter is forbidden" {
  assert_eq(domain_has_forbidden_char("\u{FDD0}"), true)
}

///|
test "domain_has_forbidden_char: U+FFFE noncharacter is forbidden" {
  assert_eq(domain_has_forbidden_char("\u{FFFE}"), true)
}

///|
test "domain_has_forbidden_char: U+00A0 NBSP is forbidden" {
  assert_eq(domain_has_forbidden_char("\u{00A0}"), true)
}

///|
test "parse_host: unclosed IPv6 bracket raises HostParseError" {
  let caught = try {
    let _ = parse_host("[::1", true)
    false
  } catch {
    HostParseError(_) => true
  }
  assert_eq(caught, true)
}

///|
test "parse_ipv4: 2-part address with last part exceeding 24-bit max raises error" {
  let caught = try {
    let _ = parse_ipv4("1.16777216")
    false
  } catch {
    HostParseError(_) => true
  }
  assert_eq(caught, true)
}

///|
test "parse_ipv4: leading octet > 255 in 2-part address raises error" {
  let caught = try {
    let _ = parse_ipv4("256.1")
    false
  } catch {
    HostParseError(_) => true
  }
  assert_eq(caught, true)
}

///|
test "parse_hex_u64: non-hex char raises HostParseError" {
  let caught = try {
    let _ = parse_hex_u64("gg")
    false
  } catch {
    HostParseError(_) => true
  }
  assert_eq(caught, true)
}
