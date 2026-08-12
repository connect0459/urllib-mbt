///|
fn load_urltestdata() -> Array[Json] raise {
  let content = @fs.read_file_to_string("wpt/url/resources/urltestdata.json")
  let json = @json.parse(content)
  match json {
    Array(a) => a
    _ => fail("expected JSON array")
  }
}

///|
fn extract_base(obj : Map[String, Json]) -> String? raise {
  match obj.get("base") {
    Some(String(s)) => Some(s)
    Some(Null) | None => None
    _ => fail("unexpected 'base' field type")
  }
}

///|
test "WPT success cases: href round-trip" {
  let items = load_urltestdata()
  let cases : Array[(String, String?, String)] = []
  for item in items {
    match item {
      Object(obj) => {
        if obj.get("failure") is Some(True) {
          continue
        }
        let input = match obj.get("input") {
          Some(String(s)) => s
          _ => fail("missing or non-string 'input' field")
        }
        let base = extract_base(obj)
        let href = match obj.get("href") {
          Some(String(s)) => s
          _ => fail("missing or non-string 'href' field")
        }
        cases.push((input, base, href))
      }
      _ => ()
    }
  }
  let failures : Array[String] = []
  for item in cases {
    let (input, base_opt, expected_href) = item
    let base_url : @url.Url? = match base_opt {
      None => None
      Some(base_str) =>
        Some(@url.parse(base_str)) catch {
          _ => {
            failures.push("FAIL parse_base: base=\{base_str}")
            continue
          }
        }
    }
    let url = @url.parse_with_base(input, base_url) catch {
      _ => {
        failures.push("FAIL parse: input=\{input} base=\{Repr(base_opt)}")
        continue
      }
    }
    if url.href() != expected_href {
      failures.push(
        "FAIL: input=\{input} base=\{Repr(base_opt)} got=\{url.href()} want=\{expected_href}",
      )
    }
  }
  let n = if failures.length() < 10 { failures.length() } else { 10 }
  for i in 0..<n {
    println(failures[i])
  }
  println(
    "WPT success: \{cases.length() - failures.length()}/\{cases.length()} passed",
  )
  if failures.length() > 0 {
    println("WARN: \{failures.length()} WPT success cases failed")
  }
  assert_eq(failures.length(), 0)
}

///|
test "WPT failure cases: parse rejects invalid URLs" {
  let items = load_urltestdata()
  let cases : Array[(String, String?)] = []
  for item in items {
    match item {
      Object(obj) => {
        if !(obj.get("failure") is Some(True)) {
          continue
        }
        let input = match obj.get("input") {
          Some(String(s)) => s
          _ => fail("missing or non-string 'input' field")
        }
        let base = extract_base(obj)
        cases.push((input, base))
      }
      _ => ()
    }
  }
  let mut rejected = 0
  let mut accepted = 0
  for item in cases {
    let (input, base_opt) = item
    let base_url : @url.Url? = match base_opt {
      None => None
      Some(base_str) => Some(@url.parse(base_str)) catch { _ => None }
    }
    let result : Result[@url.Url, @url.UrlParseError] = Ok(
      @url.parse_with_base(input, base_url),
    ) catch {
      e => Err(e)
    }
    match result {
      Err(_) => rejected = rejected + 1
      Ok(_) => accepted = accepted + 1
    }
  }
  println("WPT failure: \{rejected}/\{rejected + accepted} correctly rejected")
  if accepted > 0 {
    println("WARN: \{accepted} WPT failure cases incorrectly accepted")
  }
}
