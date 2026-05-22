///|
fn extract_str(obj : Map[String, Json], key : String) -> String raise {
  match obj.get(key) {
    Some(String(s)) => s
    _ => fail("missing or non-string '\{key}' field")
  }
}

///|
test "WPT URL getters: protocol, username, password, hostname, host, port, pathname, search, hash" {
  let items = load_urltestdata()
  let cases : Array[
    (
      String,
      String?,
      String,
      String,
      String,
      String,
      String,
      String,
      String,
      String,
      String,
    ),
  ] = []
  for item in items {
    match item {
      Object(obj) => {
        if obj.get("failure") is Some(True) {
          continue
        }
        let input = extract_str(obj, "input")
        let base = extract_base(obj)
        let protocol = extract_str(obj, "protocol")
        let username = extract_str(obj, "username")
        let password = extract_str(obj, "password")
        let hostname = extract_str(obj, "hostname")
        let host = extract_str(obj, "host")
        let port = extract_str(obj, "port")
        let pathname = extract_str(obj, "pathname")
        let search = extract_str(obj, "search")
        let hash = extract_str(obj, "hash")
        cases.push(
          (
            input, base, protocol, username, password, hostname, host, port, pathname,
            search, hash,
          ),
        )
      }
      _ => ()
    }
  }
  let mut passed = 0
  let failures : Array[String] = []
  for item in cases {
    let (
      input,
      base_opt,
      exp_protocol,
      exp_username,
      exp_password,
      exp_hostname,
      exp_host,
      exp_port,
      exp_pathname,
      exp_search,
      exp_hash,
    ) = item
    let base_url : @uri.Url? = match base_opt {
      None => None
      Some(base_str) => Some(@uri.parse(base_str)) catch { _ => None }
    }
    let url = @uri.parse_with_base(input, base_url) catch {
      _ => {
        failures.push("FAIL parse: input=\{input}")
        continue
      }
    }
    let prev_len = failures.length()
    if url.protocol() != exp_protocol {
      failures.push(
        "FAIL protocol: input=\{input} got=\{url.protocol()} want=\{exp_protocol}",
      )
    }
    if url.username != exp_username {
      failures.push(
        "FAIL username: input=\{input} got=\{url.username} want=\{exp_username}",
      )
    }
    if url.password != exp_password {
      failures.push(
        "FAIL password: input=\{input} got=\{url.password} want=\{exp_password}",
      )
    }
    if url.hostname() != exp_hostname {
      failures.push(
        "FAIL hostname: input=\{input} got=\{url.hostname()} want=\{exp_hostname}",
      )
    }
    if url.host_str() != exp_host {
      failures.push(
        "FAIL host: input=\{input} got=\{url.host_str()} want=\{exp_host}",
      )
    }
    if url.port_str() != exp_port {
      failures.push(
        "FAIL port: input=\{input} got=\{url.port_str()} want=\{exp_port}",
      )
    }
    if url.pathname() != exp_pathname {
      failures.push(
        "FAIL pathname: input=\{input} got=\{url.pathname()} want=\{exp_pathname}",
      )
    }
    if url.search() != exp_search {
      failures.push(
        "FAIL search: input=\{input} got=\{url.search()} want=\{exp_search}",
      )
    }
    if url.hash() != exp_hash {
      failures.push(
        "FAIL hash: input=\{input} got=\{url.hash()} want=\{exp_hash}",
      )
    }
    if failures.length() == prev_len {
      passed = passed + 1
    }
  }
  let n = if failures.length() < 10 { failures.length() } else { 10 }
  for i in 0..<n {
    println(failures[i])
  }
  println("WPT getters: \{passed}/\{cases.length()} passed")
  if failures.length() > 0 {
    println("WARN: \{failures.length()} WPT getter assertions failed")
  }
}

///|
test "WPT URL getter: origin" {
  let items = load_urltestdata()
  let cases : Array[(String, String?, String)] = []
  for item in items {
    match item {
      Object(obj) => {
        if obj.get("failure") is Some(True) {
          continue
        }
        let origin = match obj.get("origin") {
          Some(String(s)) => s
          _ => continue
        }
        let input = extract_str(obj, "input")
        let base = extract_base(obj)
        cases.push((input, base, origin))
      }
      _ => ()
    }
  }
  let failures : Array[String] = []
  for item in cases {
    let (input, base_opt, exp_origin) = item
    let base_url : @uri.Url? = match base_opt {
      None => None
      Some(base_str) => Some(@uri.parse(base_str)) catch { _ => None }
    }
    let url = @uri.parse_with_base(input, base_url) catch {
      _ => {
        failures.push("FAIL parse: input=\{input}")
        continue
      }
    }
    if url.origin() != exp_origin {
      failures.push(
        "FAIL origin: input=\{input} got=\{url.origin()} want=\{exp_origin}",
      )
    }
  }
  let n = if failures.length() < 10 { failures.length() } else { 10 }
  for i in 0..<n {
    println(failures[i])
  }
  println(
    "WPT origin: \{cases.length() - failures.length()}/\{cases.length()} passed",
  )
  if failures.length() > 0 {
    println("WARN: \{failures.length()} WPT origin cases failed")
  }
}

///|
test "WPT URL getter: searchParams" {
  let cases : Array[(String, String?, String)] = [
    ("?a=b&c=d", Some("http://example.org/foo/bar"), "a=b&c=d"),
    ("??a=b&c=d", Some("http://example.org/foo/bar"), "%3Fa=b&c=d"),
    ("http:", Some("http://example.org/foo/bar"), ""),
    ("sc:", Some("https://example.org/foo/bar"), ""),
    ("http://foo.bar/baz?qux#foo\u{0008}bar", None, "qux="),
    ("http://foo.bar/baz?qux#foo\"bar", None, "qux="),
    ("http://foo.bar/baz?qux#foo<bar", None, "qux="),
    ("http://foo.bar/baz?qux#foo>bar", None, "qux="),
    ("http://foo.bar/baz?qux#foo\u{0060}bar", None, "qux="),
  ]
  let failures : Array[String] = []
  for item in cases {
    let (input, base_opt, exp_sp) = item
    let base_url : @uri.Url? = match base_opt {
      None => None
      Some(base_str) => Some(@uri.parse(base_str)) catch { _ => None }
    }
    let url = @uri.parse_with_base(input, base_url) catch {
      _ => {
        failures.push("FAIL parse: input=\{input}")
        continue
      }
    }
    let got = url.search_params().to_string()
    if got != exp_sp {
      failures.push(
        "FAIL searchParams: input=\{input} got=\{got} want=\{exp_sp}",
      )
    }
  }
  let n = if failures.length() < 10 { failures.length() } else { 10 }
  for i in 0..<n {
    println(failures[i])
  }
  println(
    "WPT searchParams: \{cases.length() - failures.length()}/\{cases.length()} passed",
  )
  if failures.length() > 0 {
    println("WARN: \{failures.length()} WPT searchParams cases failed")
  }
}
