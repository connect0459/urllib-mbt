///|
test "property: parse_maybe never panics on any ASCII input" {
  let result = @quickcheck.quick_check_fn_silence(fn(
    s : @qcmod.ASCIIString,
  ) -> Bool {
    let _ = @url.parse_maybe(s.0, None)
    true
  })
  assert_true(result.has_prefix("+++"))
}

///|
test "property: parsed URL href re-parses to the same href" {
  let result = @quickcheck.quick_check_fn_silence(fn(
    s : @qcmod.ASCIIString,
  ) -> Bool {
    match @url.parse_maybe(s.0, None) {
      None => true
      Some(url) => {
        let href1 = url.href()
        match @url.parse_maybe(href1, None) {
          None => false
          Some(url2) => url2.href() == href1
        }
      }
    }
  })
  assert_true(result.has_prefix("+++"))
}

///|
test "property: protocol equals scheme plus colon" {
  let result = @quickcheck.quick_check_fn_silence(fn(
    s : @qcmod.ASCIIString,
  ) -> Bool {
    match @url.parse_maybe(s.0, None) {
      None => true
      Some(url) => url.protocol() == url.scheme() + ":"
    }
  })
  assert_true(result.has_prefix("+++"))
}

///|
test "property: search reflects query component" {
  let result = @quickcheck.quick_check_fn_silence(fn(
    s : @qcmod.ASCIIString,
  ) -> Bool {
    match @url.parse_maybe(s.0, None) {
      None => true
      Some(url) =>
        match url.query() {
          None => url.search() == ""
          Some(q) => url.search() == "?" + q
        }
    }
  })
  assert_true(result.has_prefix("+++"))
}

///|
test "property: search params to_string then from_string is stable" {
  let result = @quickcheck.quick_check_fn_silence(fn(
    s : @qcmod.ASCIIString,
  ) -> Bool {
    let params = @url.UrlSearchParams::from_string(s.0)
    let serialized = params.to_string()
    let reparsed = @url.UrlSearchParams::from_string(serialized)
    reparsed.to_string() == serialized
  })
  assert_true(result.has_prefix("+++"))
}
