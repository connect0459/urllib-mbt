///|
fn build_single_component_pattern(
  component : String,
  pattern : String,
) -> UrlPattern raise {
  let init = match component {
    "protocol" => UrlPatternInit::new(protocol=Some(pattern))
    "username" => UrlPatternInit::new(username=Some(pattern))
    "password" => UrlPatternInit::new(password=Some(pattern))
    "hostname" => UrlPatternInit::new(hostname=Some(pattern))
    "port" => UrlPatternInit::new(port=Some(pattern))
    "pathname" => UrlPatternInit::new(pathname=Some(pattern))
    "search" => UrlPatternInit::new(search=Some(pattern))
    "hash" => UrlPatternInit::new(hash=Some(pattern))
    _ => fail("unknown component: \{component}")
  }
  UrlPattern::from_init(init)
}

///|
test "WPT URLPattern: hasRegExpGroups - match-everything pattern has no regexp groups" {
  let p = try! UrlPattern::from_init(UrlPatternInit::new())
  assert_false(p.has_regexp_groups())
}

///|
test "WPT URLPattern: hasRegExpGroups - wildcard is not a regexp group" {
  let components = [
    "protocol", "username", "password", "hostname", "port", "pathname", "search",
    "hash",
  ]
  for component in components {
    let p = try! build_single_component_pattern(component, "*")
    assert_false(p.has_regexp_groups())
  }
}

///|
test "WPT URLPattern: hasRegExpGroups - segment wildcard is not a regexp group" {
  let components = [
    "protocol", "username", "password", "hostname", "port", "pathname", "search",
    "hash",
  ]
  for component in components {
    let p = try! build_single_component_pattern(component, ":foo")
    assert_false(p.has_regexp_groups())
  }
}

///|
test "WPT URLPattern: hasRegExpGroups - optional segment wildcard is not a regexp group" {
  let components = [
    "protocol", "username", "password", "hostname", "port", "pathname", "search",
    "hash",
  ]
  for component in components {
    let p = try! build_single_component_pattern(component, ":foo?")
    assert_false(p.has_regexp_groups())
  }
}

///|
test "WPT URLPattern: hasRegExpGroups - named regexp group is a regexp group" {
  let components = [
    "protocol", "username", "password", "hostname", "port", "pathname", "search",
    "hash",
  ]
  for component in components {
    let p = try! build_single_component_pattern(component, ":foo(hi)")
    assert_true(p.has_regexp_groups())
  }
}

///|
test "WPT URLPattern: hasRegExpGroups - anonymous regexp group is a regexp group" {
  let components = [
    "protocol", "username", "password", "hostname", "port", "pathname", "search",
    "hash",
  ]
  for component in components {
    let p = try! build_single_component_pattern(component, "(hi)")
    assert_true(p.has_regexp_groups())
  }
}

///|
test "WPT URLPattern: hasRegExpGroups - wildcards mixed with fixed text are not regexp groups" {
  let components = [
    "username", "password", "hostname", "pathname", "search", "hash",
  ]
  for component in components {
    let p = try! build_single_component_pattern(component, "a-{:hello}-z-*-a")
    assert_false(p.has_regexp_groups())
  }
}

///|
test "WPT URLPattern: hasRegExpGroups - regexp groups mixed with fixed text are regexp groups" {
  let components = [
    "username", "password", "hostname", "pathname", "search", "hash",
  ]
  for component in components {
    let p = try! build_single_component_pattern(component, "a-(hi)-z-(lo)-a")
    assert_true(p.has_regexp_groups())
  }
}

///|
test "WPT URLPattern: hasRegExpGroups - complex pathname without regexp has no regexp groups" {
  let p = try! UrlPattern::from_init(
    UrlPatternInit::new(pathname=Some("/a/:foo/:baz?/b/*")),
  )
  assert_false(p.has_regexp_groups())
}

///|
test "WPT URLPattern: hasRegExpGroups - complex pathname with regexp has regexp groups" {
  let p = try! UrlPattern::from_init(
    UrlPatternInit::new(pathname=Some("/a/:foo/:baz([a-z]+)?/b/*")),
  )
  assert_true(p.has_regexp_groups())
}
