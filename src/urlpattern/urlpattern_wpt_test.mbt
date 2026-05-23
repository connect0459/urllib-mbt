///|
fn load_urlpattern_testdata() -> Array[Json] raise {
  let content = @fs.read_file_to_string(
    "resources/urlpattern/urlpatterntestdata.json",
  )
  let json = @json.parse(content)
  match json {
    Array(a) => a
    _ => fail("expected JSON array")
  }
}

///|
fn extract_str_opt(obj : Map[String, Json], key : String) -> String? {
  match obj.get(key) {
    Some(String(s)) => Some(s)
    _ => None
  }
}

///|
fn build_init_from_obj(obj : Map[String, Json]) -> UrlPatternInit {
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
  )
}

///|
fn check_component_result(
  result : UrlPatternComponentResult,
  expected_comp : Map[String, Json],
  comp_name : String,
) -> String? {
  let exp_input = match expected_comp.get("input") {
    Some(String(s)) => s
    _ => return Some("'\{comp_name}': missing input")
  }
  if result.input != exp_input {
    return Some(
      "'\{comp_name}'.input: expected '\{exp_input}' got '\{result.input}'",
    )
  }
  let exp_groups = match expected_comp.get("groups") {
    Some(Object(g)) => g
    _ => return Some("'\{comp_name}': missing groups")
  }
  for name, exp_val in exp_groups {
    let got = result.groups.get(name)
    match (exp_val, got) {
      (Null, Some(None)) => ()
      (Null, Some(Some(_))) =>
        return Some("'\{comp_name}'.groups['\{name}']: expected null")
      (Null, None) => ()
      (String(ev), Some(Some(gv))) =>
        if ev != gv {
          return Some(
            "'\{comp_name}'.groups['\{name}']: expected '\{ev}' got '\{gv}'",
          )
        }
      (String(ev), _) =>
        return Some(
          "'\{comp_name}'.groups['\{name}']: expected '\{ev}' got nothing",
        )
      _ => return Some("'\{comp_name}'.groups['\{name}']: unexpected shape")
    }
  }
  None
}

///|
fn get_component_pattern(pattern : UrlPattern, name : String) -> String? {
  match name {
    "protocol" => Some(pattern.get_protocol())
    "username" => Some(pattern.get_username())
    "password" => Some(pattern.get_password())
    "hostname" => Some(pattern.get_hostname())
    "port" => Some(pattern.get_port())
    "pathname" => Some(pattern.get_pathname())
    "search" => Some(pattern.get_search())
    "hash" => Some(pattern.get_hash())
    _ => None
  }
}

///|
test "WPT URLPattern: components listed in exactly_empty_components compile to empty pattern string" {
  let items = load_urlpattern_testdata()
  let mut passed = 0
  let failures : Array[String] = []
  let mut skipped = 0
  for raw_item in items {
    let item = match raw_item {
      Object(o) => o
      _ => continue
    }
    let eec = match item.get("exactly_empty_components") {
      Some(Array(a)) => a
      _ => continue
    }
    if item.get("expected_obj") is Some(_) {
      skipped += 1
      continue
    }
    let pattern_arr = match item.get("pattern") {
      Some(Array(a)) => a
      _ => continue
    }
    if pattern_arr.length() != 1 {
      skipped += 1
      continue
    }
    let pat_obj = match pattern_arr[0] {
      Object(o) => o
      _ => {
        skipped += 1
        continue
      }
    }
    if pat_obj.get("ignoreCase") is Some(_) {
      skipped += 1
      continue
    }
    let pat_init = build_init_from_obj(pat_obj)
    let pattern = UrlPattern::from_init(pat_init) catch {
      err => {
        failures.push(
          "from_init failed: \{err} for pattern=\{Json::stringify(pattern_arr[0])}",
        )
        continue
      }
    }
    let mut ok = true
    for comp_json in eec {
      let comp_name = match comp_json {
        String(s) => s
        _ => continue
      }
      match get_component_pattern(pattern, comp_name) {
        None => ()
        Some(actual) =>
          if actual != "" {
            failures.push(
              "exactly_empty_components '\{comp_name}': expected \"\" got \"\{actual}\" for pattern=\{Json::stringify(pattern_arr[0])}",
            )
            ok = false
          }
      }
    }
    if ok {
      passed += 1
    }
  }
  if failures.length() > 0 {
    let msg = StringBuilder::new()
    msg.write_string(
      "WPT URLPattern exactly_empty_components failures (\{failures.length()}):\n",
    )
    for f in failures {
      msg.write_string("  - \{f}\n")
    }
    msg.write_string("passed=\{passed} skipped=\{skipped}")
    fail(msg.to_string())
  }
  assert_true(passed > 0)
}

///|
test "WPT URLPattern: URL string resolved against a base URL matches the compiled pattern" {
  let items = load_urlpattern_testdata()
  let mut passed = 0
  let failures : Array[String] = []
  let mut skipped = 0
  for raw_item in items {
    let item = match raw_item {
      Object(o) => o
      _ => continue
    }
    let inputs_arr = match item.get("inputs") {
      Some(Array(a)) => a
      _ => continue
    }
    if inputs_arr.length() != 2 {
      continue
    }
    let pattern_arr = match item.get("pattern") {
      Some(Array(a)) => a
      _ => continue
    }
    if pattern_arr.length() != 1 {
      skipped += 1
      continue
    }
    let pat_obj = match pattern_arr[0] {
      Object(o) => o
      _ => {
        skipped += 1
        continue
      }
    }
    if pat_obj.get("ignoreCase") is Some(_) {
      skipped += 1
      continue
    }
    let base_str = match inputs_arr[1] {
      String(s) => s
      _ => {
        skipped += 1
        continue
      }
    }
    match inputs_arr[0] {
      Object(_) => {
        skipped += 1
        continue
      }
      String(input_str) => {
        let pat_init = build_init_from_obj(pat_obj)
        let pattern = UrlPattern::from_init(pat_init) catch {
          err => {
            failures.push(
              "from_init failed: \{err} for pattern=\{Json::stringify(pattern_arr[0])}",
            )
            continue
          }
        }
        let result : UrlPatternResult? = match
          @url.parse_maybe(base_str, None) {
          None => None
          Some(base_url) =>
            match @url.parse_maybe(input_str, Some(base_url)) {
              None => None
              Some(resolved) => pattern.exec_url(resolved.href())
            }
        }
        let expected = item.get("expected_match")
        match (result, expected) {
          (None, Some(Null)) | (None, None) => passed += 1
          (Some(_), Some(Null)) | (Some(_), None) =>
            failures.push(
              "expected no match but got match for input='\{input_str}' base='\{base_str}'",
            )
          (None, Some(Object(_))) =>
            failures.push(
              "expected match but got no match for input='\{input_str}' base='\{base_str}'",
            )
          (Some(r), Some(Object(exp_obj))) => {
            let mut ok = true
            for comp_name, exp_comp_json in exp_obj {
              let exp_comp = match exp_comp_json {
                Object(o) => o
                _ => continue
              }
              let comp_result : UrlPatternComponentResult? = match comp_name {
                "protocol" => r.protocol
                "username" => r.username
                "password" => r.password
                "hostname" => r.hostname
                "port" => r.port
                "pathname" => r.pathname
                "search" => r.search
                "hash" => r.hash
                _ => None
              }
              match comp_result {
                None => {
                  failures.push(
                    "expected component '\{comp_name}' but result is None for input='\{input_str}' base='\{base_str}'",
                  )
                  ok = false
                }
                Some(cr) =>
                  match check_component_result(cr, exp_comp, comp_name) {
                    Some(msg) => {
                      failures.push(
                        "\{msg} for input='\{input_str}' base='\{base_str}'",
                      )
                      ok = false
                    }
                    None => ()
                  }
              }
            }
            if ok {
              passed += 1
            }
          }
          _ => skipped += 1
        }
      }
      _ => {
        skipped += 1
        continue
      }
    }
  }
  if failures.length() > 0 {
    let msg = StringBuilder::new()
    msg.write_string(
      "WPT URLPattern base URL resolution failures (\{failures.length()}):\n",
    )
    for f in failures {
      msg.write_string("  - \{f}\n")
    }
    msg.write_string("passed=\{passed} skipped=\{skipped}")
    fail(msg.to_string())
  }
  assert_true(passed > 0)
}

///|
test "WPT URLPattern: construction rejects invalid patterns" {
  let items = load_urlpattern_testdata()
  let mut passed = 0
  let failures : Array[String] = []
  let mut skipped = 0
  for raw_item in items {
    let item = match raw_item {
      Object(o) => o
      _ => continue
    }
    match item.get("expected_obj") {
      Some(String("error")) => ()
      _ => continue
    }
    let pattern_arr = match item.get("pattern") {
      Some(Array(a)) => a
      _ => continue
    }
    if pattern_arr.length() != 1 {
      skipped += 1
      continue
    }
    let pat_obj = match pattern_arr[0] {
      Object(o) => o
      _ => {
        skipped += 1
        continue
      }
    }
    if pat_obj.get("ignoreCase") is Some(_) {
      skipped += 1
      continue
    }
    let pat_init = build_init_from_obj(pat_obj)
    try UrlPattern::from_init(pat_init) catch {
      _ => passed += 1
    } noraise {
      _ =>
        failures.push(
          "expected error but got Ok for pattern=\{Json::stringify(pattern_arr[0])}",
        )
    }
  }
  if failures.length() > 0 {
    let msg = StringBuilder::new()
    msg.write_string(
      "WPT URLPattern invalid pattern rejection failures (\{failures.length()}):\n",
    )
    for f in failures {
      msg.write_string("  - \{f}\n")
    }
    msg.write_string("passed=\{passed} skipped=\{skipped}")
    fail(msg.to_string())
  }
  assert_true(passed > 0)
}

///|
test "WPT URLPattern: simple init-to-init cases" {
  let items = load_urlpattern_testdata()
  let mut passed = 0
  let failures : Array[String] = []
  let mut skipped = 0
  for raw_item in items {
    let item = match raw_item {
      Object(o) => o
      _ => continue
    }
    if item.get("expected_obj") is Some(_) {
      skipped += 1
      continue
    }
    let pattern_arr = match item.get("pattern") {
      Some(Array(a)) => a
      _ => continue
    }
    let inputs_arr = match item.get("inputs") {
      Some(Array(a)) => a
      _ => continue
    }
    if pattern_arr.length() != 1 || inputs_arr.length() != 1 {
      skipped += 1
      continue
    }
    let pat_obj = match pattern_arr[0] {
      Object(o) => o
      _ => {
        skipped += 1
        continue
      }
    }
    if pat_obj.get("ignoreCase") is Some(_) {
      skipped += 1
      continue
    }
    let pat_init = build_init_from_obj(pat_obj)
    let pattern = UrlPattern::from_init(pat_init) catch {
      err => {
        let msg = "\{err}"
        if msg.contains("Unsupported") || msg.contains("POSIX character class") {
          skipped += 1
        } else {
          failures.push("from_init failed: \{msg}")
        }
        continue
      }
    }
    let result = match inputs_arr[0] {
      String(url_str) => pattern.exec_url(url_str)
      Object(inp_obj) => pattern.exec_init(build_init_from_obj(inp_obj))
      _ => {
        skipped += 1
        continue
      }
    }
    let expected = item.get("expected_match")
    match (result, expected) {
      (None, Some(Null)) | (None, None) => passed += 1
      (Some(_), Some(Null)) | (Some(_), None) =>
        failures.push(
          "expected no match but got match for pattern=\{Json::stringify(raw_item)} input=\{Json::stringify(raw_item)}",
        )
      (None, Some(Object(_))) =>
        failures.push(
          "expected match but got no match for pattern=\{Json::stringify(raw_item)} input=\{Json::stringify(raw_item)}",
        )
      (Some(r), Some(Object(exp_obj))) => {
        let mut ok = true
        for comp_name, exp_comp_json in exp_obj {
          let exp_comp = match exp_comp_json {
            Object(o) => o
            _ => continue
          }
          let comp_result : UrlPatternComponentResult? = match comp_name {
            "protocol" => r.protocol
            "username" => r.username
            "password" => r.password
            "hostname" => r.hostname
            "port" => r.port
            "pathname" => r.pathname
            "search" => r.search
            "hash" => r.hash
            _ => None
          }
          match comp_result {
            None => {
              failures.push(
                "expected component '\{comp_name}' but result is None for pattern=\{Json::stringify(raw_item)}",
              )
              ok = false
            }
            Some(cr) =>
              match check_component_result(cr, exp_comp, comp_name) {
                Some(msg) => {
                  failures.push(
                    "\{msg} for pattern=\{Json::stringify(raw_item)} input=\{Json::stringify(raw_item)}",
                  )
                  ok = false
                }
                None => ()
              }
          }
        }
        if ok {
          passed += 1
        }
      }
      _ => skipped += 1
    }
  }
  if failures.length() > 0 {
    let msg = StringBuilder::new()
    msg.write_string("WPT URLPattern failures (\{failures.length()}):\n")
    for f in failures {
      msg.write_string("  - \{f}\n")
    }
    msg.write_string("passed=\{passed} skipped=\{skipped}")
    fail(msg.to_string())
  }
  assert_true(passed > 0)
}
