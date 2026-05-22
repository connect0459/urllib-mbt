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
  let init = apply_base_url(init, true)
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
  let init = apply_base_url(init, false) catch { _ => return None }
  let proto_str = init.protocol.unwrap_or("")
  let proto_input = init.protocol.unwrap_or("")
  let protocol = match match_component(self.protocol, proto_input) {
    None => return None
    Some(r) => Some(r)
  }
  let username_input = canonicalize_userinfo(init.username.unwrap_or(""))
  let username = match match_component(self.username, username_input) {
    None => return None
    Some(r) => Some(r)
  }
  let password_input = canonicalize_password(init.password.unwrap_or(""))
  let password = match match_component(self.password, password_input) {
    None => return None
    Some(r) => Some(r)
  }
  let hostname_input = canonicalize_hostname(init.hostname.unwrap_or(""))
  let hostname = match match_component(self.hostname, hostname_input) {
    None => return None
    Some(r) => Some(r)
  }
  let port_input = canonicalize_port(init.port.unwrap_or(""), proto_str)
  let port = match match_component(self.port, port_input) {
    None => return None
    Some(r) => Some(r)
  }
  let raw_pathname = init.pathname.unwrap_or("")
  let pathname_input = if proto_str == "" ||
    proto_str == "http" ||
    proto_str == "https" ||
    proto_str == "ws" ||
    proto_str == "wss" ||
    proto_str == "ftp" ||
    proto_str == "file" {
    canonicalize_pathname(raw_pathname)
  } else {
    raw_pathname
  }
  let pathname = match match_component(self.pathname, pathname_input) {
    None => return None
    Some(r) => Some(r)
  }
  let search_input = canonicalize_search(init.search.unwrap_or(""))
  let search = match match_component(self.search, search_input) {
    None => return None
    Some(r) => Some(r)
  }
  let hash_input = canonicalize_hash(init.hash.unwrap_or(""))
  let hash = match match_component(self.hash, hash_input) {
    None => return None
    Some(r) => Some(r)
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
  let base = try? @url.parse("https://dummy.test")
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
  let base = try? @url.parse("https://x/")
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
  let base = try? @url.parse("https://x/")
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
  let parsed = try? @url.parse(full)
  match parsed {
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
  let parsed = try? @url.parse("https://x/?" + stripped)
  match parsed {
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
  let parsed = try? @url.parse("https://x/#" + stripped)
  match parsed {
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
fn get_base_dir(pathname : String) -> String {
  let chars : Array[Char] = []
  for c in pathname {
    chars.push(c)
  }
  let mut last_slash = 0
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '/' {
      last_slash = i + 1
    }
  }
  let buf = StringBuilder::new()
  for i = 0; i < last_slash; i = i + 1 {
    buf.write_char(chars[i])
  }
  buf.to_string()
}

///|
fn apply_base_url(
  init : UrlPatternInit,
  for_pattern : Bool,
) -> UrlPatternInit raise UrlPatternError {
  let base_str = match init.base_url {
    None => return init
    Some(s) => s
  }
  let base = @url.parse(base_str) catch {
    _ => raise UrlPatternError("invalid baseURL: \{base_str}")
  }
  let base_search = strip_leading_char(base.search(), '?')
  let base_hash = strip_leading_char(base.hash(), '#')
  let base_port = base.port_str()
  let has_protocol = init.protocol is Some(_)
  let has_username = init.username is Some(_)
  let has_password = init.password is Some(_)
  let has_hostname = init.hostname is Some(_)
  let has_port = init.port is Some(_)
  let has_pathname = init.pathname is Some(_)
  let has_search = init.search is Some(_)
  let protocol = if has_protocol { init.protocol } else { Some(base.scheme) }
  let username = if !for_pattern &&
    !has_protocol &&
    !has_hostname &&
    !has_port &&
    !has_username {
    Some(base.username)
  } else {
    init.username
  }
  let password = if !for_pattern &&
    !has_protocol &&
    !has_hostname &&
    !has_port &&
    !has_username &&
    !has_password {
    Some(base.password)
  } else {
    init.password
  }
  let hostname = if !has_protocol && !has_hostname {
    Some(base.hostname())
  } else {
    init.hostname
  }
  let port = if !has_protocol && !has_hostname && !has_port {
    Some(base_port)
  } else {
    init.port
  }
  let pathname = if !has_protocol && !has_hostname && !has_port && !has_pathname {
    Some(base.pathname())
  } else if !has_protocol &&
    !has_hostname &&
    !has_port &&
    has_pathname &&
    !for_pattern {
    let pn = init.pathname.unwrap_or("")
    let chars : Array[Char] = []
    for c in pn {
      chars.push(c)
    }
    if chars.length() > 0 && chars[0] == '/' {
      init.pathname
    } else {
      Some(get_base_dir(base.pathname()) + pn)
    }
  } else {
    init.pathname
  }
  let search = if !has_protocol &&
    !has_hostname &&
    !has_port &&
    !has_pathname &&
    !has_search {
    Some(base_search)
  } else {
    init.search
  }
  let hash = if !has_protocol &&
    !has_hostname &&
    !has_port &&
    !has_pathname &&
    !has_search &&
    init.hash is None {
    Some(base_hash)
  } else {
    init.hash
  }
  {
    protocol,
    username,
    password,
    hostname,
    port,
    pathname,
    search,
    hash,
    base_url: None,
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
  let parsed = try? @url.parse(url_str)
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
      match self.exec_init(init) {
        None => None
        Some(r) =>
          Some({
            inputs: [Str(url_str)],
            protocol: r.protocol,
            username: r.username,
            password: r.password,
            hostname: r.hostname,
            port: r.port,
            pathname: r.pathname,
            search: r.search,
            hash: r.hash,
          })
      }
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
