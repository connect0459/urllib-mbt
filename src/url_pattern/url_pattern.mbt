///|
fn compile_component(
  pattern : String,
  options : CompileOptions,
  policy : TokenizePolicy,
) -> UrlPatternComponent raise UrlPatternError {
  let parts = parse_pattern_to_parts(pattern, options, policy)
  let pat_str = generate_pattern_string(parts)
  let (regexp_str, group_names) = generate_regexp(parts, options)
  let regex = @string.Regex(regexp_str) catch {
    err =>
      raise UrlPatternError(
        "compile_component: invalid regex '\{regexp_str}': \{err}",
      )
  }
  { pattern: pat_str, regex, group_names }
}

///|
pub fn UrlPattern::from_init(
  init : UrlPatternInit,
) -> UrlPattern raise UrlPatternError {
  let proto_val = init.protocol.unwrap_or("*")
  let port_raw = init.port.unwrap_or("*")
  let port_val = match (proto_val, port_raw) {
    ("http" | "ws", "80") => ""
    ("https" | "wss", "443") => ""
    ("ftp", "21") => ""
    (_, v) => v
  }
  let protocol = compile_component(proto_val, default_options, Strict)
  let username = compile_component(
    init.username.unwrap_or("*"),
    default_options,
    Strict,
  )
  let password = compile_component(
    init.password.unwrap_or("*"),
    default_options,
    Strict,
  )
  let hostname = compile_component(
    init.hostname.unwrap_or("*"),
    hostname_options,
    Strict,
  )
  let port = compile_component(port_val, default_options, Strict)
  let pathname = compile_component(
    init.pathname.unwrap_or("*"),
    pathname_options,
    Strict,
  )
  let search = compile_component(
    init.search.unwrap_or("*"),
    default_options,
    Strict,
  )
  let hash = compile_component(
    init.hash.unwrap_or("*"),
    default_options,
    Strict,
  )
  { protocol, username, password, hostname, port, pathname, search, hash }
}

///|
fn match_component(
  component : UrlPatternComponent,
  input : String,
) -> UrlPatternComponentResult? {
  match component.regex.execute(input) {
    None => None
    Some(m) => {
      let groups : Map[String, String?] = {}
      for idx, name in component.group_names {
        let val = match m.group(idx + 1) {
          None => None
          Some(sv) => Some(sv.to_owned())
        }
        groups[name] = val
      }
      Some({ input, groups })
    }
  }
}

///|
pub fn UrlPattern::exec_init(
  self : UrlPattern,
  init : UrlPatternInit,
) -> UrlPatternResult? {
  let mut protocol : UrlPatternComponentResult? = None
  let mut username : UrlPatternComponentResult? = None
  let mut password : UrlPatternComponentResult? = None
  let mut hostname : UrlPatternComponentResult? = None
  let mut port : UrlPatternComponentResult? = None
  let mut pathname : UrlPatternComponentResult? = None
  let mut search : UrlPatternComponentResult? = None
  let mut hash : UrlPatternComponentResult? = None

  let proto_str = init.protocol.unwrap_or("")

  if init.protocol is Some(v) {
    match match_component(self.protocol, v) {
      None => return None
      Some(r) => protocol = Some(r)
    }
  }
  if init.username is Some(v) {
    match match_component(self.username, canonicalize_userinfo(v)) {
      None => return None
      Some(r) => username = Some(r)
    }
  }
  if init.password is Some(v) {
    match match_component(self.password, canonicalize_password(v)) {
      None => return None
      Some(r) => password = Some(r)
    }
  }
  if init.hostname is Some(v) {
    match match_component(self.hostname, canonicalize_hostname(v)) {
      None => return None
      Some(r) => hostname = Some(r)
    }
  }
  if init.port is Some(v) {
    match match_component(self.port, canonicalize_port(v, proto_str)) {
      None => return None
      Some(r) => port = Some(r)
    }
  }
  if init.pathname is Some(v) {
    let nv = if proto_str == "" ||
      proto_str == "http" ||
      proto_str == "https" ||
      proto_str == "ws" ||
      proto_str == "wss" ||
      proto_str == "ftp" ||
      proto_str == "file" {
      canonicalize_pathname(v)
    } else {
      v
    }
    match match_component(self.pathname, nv) {
      None => return None
      Some(r) => pathname = Some(r)
    }
  }
  if init.search is Some(v) {
    match match_component(self.search, canonicalize_search(v)) {
      None => return None
      Some(r) => search = Some(r)
    }
  }
  if init.hash is Some(v) {
    match match_component(self.hash, canonicalize_hash(v)) {
      None => return None
      Some(r) => hash = Some(r)
    }
  }

  Some({
    inputs: [Init(init)],
    protocol,
    username,
    password,
    hostname,
    port,
    pathname,
    search,
    hash,
  })
}

///|
fn canonicalize_hostname(input : String) -> String {
  if input == "" {
    return ""
  }
  let base = try? @uri.parse("https://dummy.test")
  match base {
    Err(_) => input
    Ok(u) => u.set_hostname(input).hostname()
  }
}

///|
fn canonicalize_userinfo(input : String) -> String {
  if input == "" {
    return ""
  }
  let base = try? @uri.parse("https://x/")
  match base {
    Err(_) => input
    Ok(u) => u.set_username(input).username
  }
}

///|
fn canonicalize_password(input : String) -> String {
  if input == "" {
    return ""
  }
  let base = try? @uri.parse("https://x/")
  match base {
    Err(_) => input
    Ok(u) => u.set_password(input).password
  }
}

///|
fn canonicalize_pathname(input : String) -> String {
  if input == "" {
    return ""
  }
  let leading_slash = input.length() > 0 &&
    ({
      let chars : Array[Char] = []
      for c in input {
        chars.push(c)
      }
      chars[0] == '/'
    })
  let full = if leading_slash {
    "https://x" + input
  } else {
    "https://x/-" + input
  }
  match (try? @uri.parse(full)) {
    Err(_) => input
    Ok(url) => {
      let p = url.pathname()
      if leading_slash {
        p
      } else {
        let chars : Array[Char] = []
        for c in p {
          chars.push(c)
        }
        if chars.length() < 2 {
          input
        } else {
          let buf = StringBuilder::new()
          for j = 2; j < chars.length(); j = j + 1 {
            buf.write_char(chars[j])
          }
          buf.to_string()
        }
      }
    }
  }
}

///|
fn canonicalize_search(input : String) -> String {
  if input == "" {
    return ""
  }
  let stripped = strip_leading_char(input, '?')
  if stripped == "" {
    return ""
  }
  match (try? @uri.parse("https://x/?" + stripped)) {
    Err(_) => stripped
    Ok(url) => strip_leading_char(url.search(), '?')
  }
}

///|
fn canonicalize_hash(input : String) -> String {
  if input == "" {
    return ""
  }
  let stripped = strip_leading_char(input, '#')
  if stripped == "" {
    return ""
  }
  match (try? @uri.parse("https://x/#" + stripped)) {
    Err(_) => stripped
    Ok(url) => strip_leading_char(url.hash(), '#')
  }
}

///|
fn canonicalize_port(port : String, protocol : String) -> String {
  if port == "" {
    return ""
  }
  let buf = StringBuilder::new()
  for c in port {
    if c != '\t' && c != '\n' && c != '\r' && c.to_int() != 12 {
      buf.write_char(c)
    }
  }
  let trimmed = buf.to_string()
  if trimmed == "" {
    return ""
  }
  let digit_buf = StringBuilder::new()
  for c in trimmed {
    if c >= '0' && c <= '9' {
      digit_buf.write_char(c)
    } else {
      break
    }
  }
  let digits = digit_buf.to_string()
  if digits == "" {
    return port
  }
  let mut n = 0
  for c in digits {
    n = n * 10 + (c.to_int() - '0'.to_int())
  }
  if n > 65535 {
    return port
  }
  let normalized = n.to_string()
  match protocol {
    "http" | "ws" => if normalized == "80" { "" } else { normalized }
    "https" | "wss" => if normalized == "443" { "" } else { normalized }
    "ftp" => if normalized == "21" { "" } else { normalized }
    _ => normalized
  }
}

///|
fn strip_leading_char(s : String, c : Char) -> String {
  if s.length() == 0 {
    return s
  }
  let chars : Array[Char] = []
  for ch in s {
    chars.push(ch)
  }
  if chars[0] != c {
    return s
  }
  let buf = StringBuilder::new()
  for i = 1; i < chars.length(); i = i + 1 {
    buf.write_char(chars[i])
  }
  buf.to_string()
}

///|
pub fn UrlPattern::exec_url(
  self : UrlPattern,
  url_str : String,
) -> UrlPatternResult? {
  let parsed = try? @uri.parse(url_str)
  match parsed {
    Err(_) => None
    Ok(url) => {
      let scheme = url.scheme
      let search_raw = url.search()
      let hash_raw = url.hash()
      let init = {
        protocol: Some(scheme),
        username: Some(url.username),
        password: Some(url.password),
        hostname: Some(url.hostname()),
        port: Some(url.port_str()),
        pathname: Some(url.pathname()),
        search: Some(strip_leading_char(search_raw, '?')),
        hash: Some(strip_leading_char(hash_raw, '#')),
        base_url: None,
      }
      self.exec_init(init)
    }
  }
}

///|
pub fn UrlPattern::test_init(self : UrlPattern, init : UrlPatternInit) -> Bool {
  self.exec_init(init) is Some(_)
}

///|
pub fn UrlPattern::test_url(self : UrlPattern, url : String) -> Bool {
  self.exec_url(url) is Some(_)
}

///|
pub fn UrlPattern::get_protocol(self : UrlPattern) -> String {
  self.protocol.pattern
}

///|
pub fn UrlPattern::get_username(self : UrlPattern) -> String {
  self.username.pattern
}

///|
pub fn UrlPattern::get_password(self : UrlPattern) -> String {
  self.password.pattern
}

///|
pub fn UrlPattern::get_hostname(self : UrlPattern) -> String {
  self.hostname.pattern
}

///|
pub fn UrlPattern::get_port(self : UrlPattern) -> String {
  self.port.pattern
}

///|
pub fn UrlPattern::get_pathname(self : UrlPattern) -> String {
  self.pathname.pattern
}

///|
pub fn UrlPattern::get_search(self : UrlPattern) -> String {
  self.search.pattern
}

///|
pub fn UrlPattern::get_hash(self : UrlPattern) -> String {
  self.hash.pattern
}
