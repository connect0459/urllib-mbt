///|
test "bench compile static pattern from string" (it : @bench.T) {
  let pattern = "https://example.com/users/profile"
  it.bench(fn() {
    it.keep(UrlPattern::from_string(pattern, None) catch { _ => abort("") })
  })
}

///|
test "bench compile named-segment pattern from string" (it : @bench.T) {
  let pattern = "https://example.com/users/:id"
  it.bench(fn() {
    it.keep(UrlPattern::from_string(pattern, None) catch { _ => abort("") })
  })
}

///|
test "bench compile wildcard pattern from string" (it : @bench.T) {
  let pattern = "https://example.com/*"
  it.bench(fn() {
    it.keep(UrlPattern::from_string(pattern, None) catch { _ => abort("") })
  })
}

///|
test "bench compile multi-group pattern from init" (it : @bench.T) {
  let init = UrlPatternInit::new(
    protocol=Some("https"),
    hostname=Some(":subdomain.example.com"),
    pathname=Some("/:category/:id"),
  )
  it.bench(fn() {
    it.keep(UrlPattern::from_init(init) catch { _ => abort("") })
  })
}

///|
test "bench exec_url static match" (it : @bench.T) {
  let p = UrlPattern::from_string("https://example.com/users/profile", None) catch {
    _ => abort("")
  }
  let url = "https://example.com/users/profile"
  it.bench(fn() { it.keep(p.exec_url(url)) })
}

///|
test "bench exec_url named-segment match" (it : @bench.T) {
  let p = UrlPattern::from_string("https://example.com/users/:id", None) catch {
    _ => abort("")
  }
  let url = "https://example.com/users/42"
  it.bench(fn() { it.keep(p.exec_url(url)) })
}

///|
test "bench exec_url wildcard match" (it : @bench.T) {
  let p = UrlPattern::from_string("https://example.com/*", None) catch {
    _ => abort("")
  }
  let url = "https://example.com/a/b/c/d"
  it.bench(fn() { it.keep(p.exec_url(url)) })
}

///|
test "bench exec_url no match" (it : @bench.T) {
  let p = UrlPattern::from_string("https://example.com/users/:id", None) catch {
    _ => abort("")
  }
  let url = "https://other.com/users/42"
  it.bench(fn() { it.keep(p.exec_url(url)) })
}

///|
test "bench test_url static" (it : @bench.T) {
  let p = UrlPattern::from_string("https://example.com/users/profile", None) catch {
    _ => abort("")
  }
  let url = "https://example.com/users/profile"
  it.bench(fn() { it.keep(p.test_url(url)) })
}

///|
test "bench test_url named-segment" (it : @bench.T) {
  let p = UrlPattern::from_string("https://example.com/users/:id", None) catch {
    _ => abort("")
  }
  let url = "https://example.com/users/42"
  it.bench(fn() { it.keep(p.test_url(url)) })
}
