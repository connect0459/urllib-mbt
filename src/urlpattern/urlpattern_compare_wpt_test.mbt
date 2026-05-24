///|
fn load_compare_testdata() -> Array[Json] raise {
  let content = @fs.read_file_to_string(
    "resources/urlpattern/urlpattern-compare-test-data.json",
  )
  match @json.parse(content) {
    Array(a) => a
    _ => fail("expected JSON array")
  }
}

///|
test "WPT URLPattern: compare_component compares pattern specificity" {
  let data = load_compare_testdata()
  let mut passed = 0
  let mut failed = 0
  for entry_json in data {
    let entry = match entry_json {
      Object(obj) => obj
      _ => continue
    }
    let component_str = match entry.get("component") {
      Some(String(s)) => s
      _ => continue
    }
    let component = match parse_component_name(component_str) {
      Some(c) => c
      None => continue
    }
    let left_json = match entry.get("left") {
      Some(j) => j
      None => continue
    }
    let right_json = match entry.get("right") {
      Some(j) => j
      None => continue
    }
    let expected = match entry.get("expected") {
      Some(Number(n, ..)) => n.to_int()
      _ => continue
    }
    let left = build_pattern_from_json(left_json) catch {
      e => {
        println(
          "FAIL (build left): Component=\{component_str} Left=\{Json::stringify(left_json)}: \{e}",
        )
        failed += 4
        continue
      }
    }
    let right = build_pattern_from_json(right_json) catch {
      e => {
        println(
          "FAIL (build right): Component=\{component_str} Right=\{Json::stringify(right_json)}: \{e}",
        )
        failed += 4
        continue
      }
    }
    let rev_expected = if expected > 0 {
      -1
    } else if expected < 0 {
      1
    } else {
      0
    }
    let r1 = UrlPattern::compare_component(component, left, right)
    if r1 == expected {
      passed += 1
    } else {
      println(
        "FAIL: Component=\{component_str} Left=\{Json::stringify(left_json)} Right=\{Json::stringify(right_json)}",
      )
      println("  expected: \{expected}, got: \{r1}")
      failed += 1
    }
    let r2 = UrlPattern::compare_component(component, right, left)
    if r2 == rev_expected {
      passed += 1
    } else {
      println(
        "FAIL (reverse): Component=\{component_str} expected: \{rev_expected}, got: \{r2}",
      )
      failed += 1
    }
    let r3 = UrlPattern::compare_component(component, left, left)
    if r3 == 0 {
      passed += 1
    } else {
      println(
        "FAIL (left self): Component=\{component_str} expected: 0, got: \{r3}",
      )
      failed += 1
    }
    let r4 = UrlPattern::compare_component(component, right, right)
    if r4 == 0 {
      passed += 1
    } else {
      println(
        "FAIL (right self): Component=\{component_str} expected: 0, got: \{r4}",
      )
      failed += 1
    }
  }
  println(
    "WPT URLPattern compare_component: \{passed}/\{passed + failed} passed",
  )
  if failed > 0 {
    fail("\{failed} compare_component test(s) failed")
  }
}
