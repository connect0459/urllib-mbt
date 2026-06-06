///|
fn load_generate_testdata() -> Array[Json] raise {
  let content = @fs.read_file_to_string(
    "wpt/urlpattern/resources/urlpattern-generate-test-data.json",
  )
  let json = @json.parse(content)
  match json {
    Array(a) => a
    _ => fail("expected JSON array")
  }
}

///|
fn parse_component_name(s : String) -> UrlPatternComponent? {
  match s {
    "protocol" => Some(Protocol)
    "username" => Some(Username)
    "password" => Some(Password)
    "hostname" => Some(Hostname)
    "port" => Some(Port)
    "pathname" => Some(Pathname)
    "search" => Some(Search)
    "hash" => Some(Hash)
    _ => None
  }
}

///|
fn build_pattern_from_json(pattern_json : Json) -> UrlPattern raise {
  match pattern_json {
    String(s) => UrlPattern::from_string(s, None)
    Object(obj) =>
      UrlPattern::from_init(
        UrlPatternInit::new(
          protocol=extract_str_opt(obj, "protocol"),
          username=extract_str_opt(obj, "username"),
          password=extract_str_opt(obj, "password"),
          hostname=extract_str_opt(obj, "hostname"),
          port=extract_str_opt(obj, "port"),
          pathname=extract_str_opt(obj, "pathname"),
          search=extract_str_opt(obj, "search"),
          hash=extract_str_opt(obj, "hash"),
          base_url=extract_str_opt(obj, "baseURL"),
        ),
      )
    _ => fail("invalid pattern JSON")
  }
}

///|
test "WPT URLPattern: generate URL component from pattern and groups" {
  let data = load_generate_testdata()
  let mut passed = 0
  let mut failed = 0
  let mut skipped = 0
  for entry_json in data {
    let entry = match entry_json {
      Object(obj) => obj
      _ => continue
    }
    let pattern_json = match entry.get("pattern") {
      Some(j) => j
      None => continue
    }
    let component_str = match entry.get("component") {
      Some(String(s)) => s
      _ => continue
    }
    let component = match parse_component_name(component_str) {
      Some(c) => c
      None => {
        skipped += 1
        continue
      }
    }
    let groups_json = match entry.get("groups") {
      Some(Object(g)) => g
      _ => {}
    }
    let groups : Map[String, String] = {}
    for k, v in groups_json {
      match v {
        String(s) => groups[k] = s
        _ => ()
      }
    }
    let expected : String? = match entry.get("expected") {
      Some(Null) => None
      Some(String(s)) => Some(s)
      _ => None
    }
    let pattern = build_pattern_from_json(pattern_json) catch {
      e => {
        println(
          "FAIL (build): Pattern=\{Json::stringify(pattern_json)} Component=\{component_str}: \{e}",
        )
        failed += 1
        continue
      }
    }
    let result = pattern.generate(component, groups)
    if result == expected {
      passed += 1
    } else {
      println(
        "FAIL: Pattern=\{Json::stringify(pattern_json)} Component=\{component_str}",
      )
      let expected_str = match expected {
        None => "None"
        Some(s) => "Some(\"\{s}\")"
      }
      println("  expected: \{expected_str}")
      let got_str = match result {
        None => "None"
        Some(s) => "Some(\"\{s}\")"
      }
      println("  got:      \{got_str}")
      failed += 1
    }
  }
  println(
    "WPT URLPattern generate: \{passed}/\{passed + failed} passed (\{skipped} skipped)",
  )
  if failed > 0 {
    fail("\{failed} generate test(s) failed")
  }
}
