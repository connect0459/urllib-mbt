///|
fn load_urlpattern_testdata() -> Array[Json] raise {
  let content = @fs.read_file_to_string("resources/urlpatterntestdata.json")
  let json = @json.parse(content)
  match json {
    Array(a) => a
    _ => fail("expected JSON array")
  }
}

///|
fn extract_str_opt(obj : Map[String, Json], key : String) -> String? raise {
  match obj.get(key) {
    Some(String(s)) => Some(s)
    None => None
    _ => fail("unexpected type for '\{key}'")
  }
}

///|
fn build_init_from_obj(obj : Map[String, Json]) -> UrlPatternInit raise {
  UrlPatternInit::new(
    protocol=extract_str_opt(obj, "protocol"),
    username=extract_str_opt(obj, "username"),
    password=extract_str_opt(obj, "password"),
    hostname=extract_str_opt(obj, "hostname"),
    port=extract_str_opt(obj, "port"),
    pathname=extract_str_opt(obj, "pathname"),
    search=extract_str_opt(obj, "search"),
    hash=extract_str_opt(obj, "hash"),
  )
}

///|
fn check_component_result(
  result : UrlPatternComponentResult,
  expected_comp : Map[String, Json],
  comp_name : String,
) -> String? raise {
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
    let inp_obj = match inputs_arr[0] {
      Object(o) => o
      _ => {
        skipped += 1
        continue
      }
    }
    if pat_obj.get("baseURL") is Some(_) || inp_obj.get("baseURL") is Some(_) {
      skipped += 1
      continue
    }
    if pat_obj.get("ignoreCase") is Some(_) {
      skipped += 1
      continue
    }
    let pat_init = build_init_from_obj(pat_obj) catch {
      err => {
        failures.push("build pattern init failed: \{err}")
        continue
      }
    }
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
    let inp_init = build_init_from_obj(inp_obj) catch {
      err => {
        failures.push("build input init failed: \{err}")
        continue
      }
    }
    let result = pattern.exec_init(inp_init)
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
