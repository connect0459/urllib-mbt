///|
priv enum ComponentKind {
  Protocol
  Username
  Password
  Hostname
  Port
  Pathname
  OpaquePathname
  Search
  Hash
} derive(Eq)

///|
fn canonicalize_protocol_for_pattern(
  input : String,
) -> String raise UrlPatternError {
  if input == "" {
    return ""
  }
  let chars : Array[Char] = []
  for c in input {
    chars.push(c)
  }
  let stripped = if chars.length() > 0 && chars[chars.length() - 1] == ':' {
    let buf = StringBuilder::new()
    for j = 0; j < chars.length() - 1; j = j + 1 {
      buf.write_char(chars[j])
    }
    buf.to_string()
  } else {
    input
  }
  let parsed = @url.parse(stripped + "://dummy.test") catch {
    _ => raise UrlPatternError("invalid protocol: '\{input}'")
  }
  parsed.scheme
}

///|
fn canonicalize_hostname_for_pattern(
  input : String,
) -> String raise UrlPatternError {
  if input == "" {
    return ""
  }
  // Strip C0 controls; truncate at #, /, \ (URL parsing would do the same)
  let buf = StringBuilder::new()
  for c in input {
    let cp = c.to_int()
    if cp <= 0x1F || cp == 0x7F {
      continue
    }
    if c == '#' || c == '/' || c == '\\' || c == '?' {
      break
    }
    buf.write_char(c)
  }
  let processed = buf.to_string()
  if processed == "" {
    return ""
  }
  let host = @host.parse_host(processed, true) catch {
    e => raise UrlPatternError("invalid hostname: \{e}")
  }
  @host.serialize_host(host)
}

///|
fn is_literal_port_out_of_range(s : String) -> Bool {
  if s == "" {
    return false
  }
  let chars : Array[Char] = []
  for c in s {
    chars.push(c)
  }
  for c in chars {
    if !(c >= '0' && c <= '9') {
      return false
    }
  }
  let mut n = 0
  for c in chars {
    n = n * 10 + (c.to_int() - '0'.to_int())
    if n > 65535 {
      return true
    }
  }
  false
}

///|
fn apply_encode_for_component(
  value : String,
  kind : ComponentKind,
) -> String raise UrlPatternError {
  match kind {
    Protocol => canonicalize_protocol_for_pattern(value)
    Username => canonicalize_userinfo(value)
    Password => canonicalize_password(value)
    Hostname => canonicalize_hostname_for_pattern(value)
    Port => canonicalize_port(value, "")
    Pathname => canonicalize_pathname(value)
    OpaquePathname => value
    Search => canonicalize_search(value)
    Hash => canonicalize_hash(value)
  }
}

///|
fn is_ipv6_literal_char(c : Char) -> Bool {
  (c >= '0' && c <= '9') ||
  (c >= 'a' && c <= 'f') ||
  (c >= 'A' && c <= 'F') ||
  c == ':' ||
  c == '.' ||
  c == '[' ||
  c == ']'
}

///|
fn encode_hostname_value(
  value : String,
  in_ipv6 : Bool,
) -> String raise UrlPatternError {
  if value == "" {
    return ""
  }
  if in_ipv6 {
    for c in value {
      if !is_ipv6_literal_char(c) {
        raise UrlPatternError(
          "invalid character '\{c}' in IPv6 address literal",
        )
      }
    }
    let buf = StringBuilder::new()
    for c in value {
      buf.write_char(
        if c >= 'A' && c <= 'F' {
          (c.to_int() + 32).unsafe_to_char()
        } else {
          c
        },
      )
    }
    return buf.to_string()
  }
  let first_char : Char? = {
    let mut fc : Char? = None
    for c in value {
      fc = Some(c)
      break
    }
    fc
  }
  if first_char == Some('[') {
    for c in value {
      if !is_ipv6_literal_char(c) {
        raise UrlPatternError(
          "invalid character '\{c}' in IPv6 address literal",
        )
      }
    }
    let buf = StringBuilder::new()
    for c in value {
      buf.write_char(
        if c >= 'A' && c <= 'F' {
          (c.to_int() + 32).unsafe_to_char()
        } else {
          c
        },
      )
    }
    return buf.to_string()
  }
  canonicalize_hostname_for_pattern(value)
}

///|
fn encode_parts(
  raw_parts : Array[Part],
  kind : ComponentKind,
) -> Array[Part] raise UrlPatternError {
  let result : Array[Part] = []
  let mut ipv6_open = false
  for part in raw_parts {
    match part.kind {
      FixedText => {
        let enc = if kind == Hostname {
          let v = encode_hostname_value(part.value, ipv6_open)
          for c in part.value {
            if c == '[' {
              ipv6_open = true
            } else if c == ']' {
              ipv6_open = false
            }
          }
          v
        } else {
          apply_encode_for_component(part.value, kind)
        }
        result.push({
          kind: FixedText,
          value: enc,
          modifier: part.modifier,
          name: part.name,
          prefix: part.prefix,
          suffix: part.suffix,
        })
      }
      Regexp => {
        for c in part.value {
          if c.to_int() > 0x7F {
            raise UrlPatternError(
              "regexp value contains non-ASCII character '\{c}'",
            )
          }
        }
        let enc_prefix = if kind == Hostname {
          let p = encode_hostname_value(part.prefix, ipv6_open)
          for c in part.prefix {
            if c == '[' {
              ipv6_open = true
            } else if c == ']' {
              ipv6_open = false
            }
          }
          p
        } else {
          apply_encode_for_component(part.prefix, kind)
        }
        let enc_suffix = if kind == Hostname {
          let s = encode_hostname_value(part.suffix, ipv6_open)
          for c in part.suffix {
            if c == '[' {
              ipv6_open = true
            } else if c == ']' {
              ipv6_open = false
            }
          }
          s
        } else {
          apply_encode_for_component(part.suffix, kind)
        }
        result.push({
          kind: Regexp,
          value: part.value,
          modifier: part.modifier,
          name: part.name,
          prefix: enc_prefix,
          suffix: enc_suffix,
        })
      }
      SegmentWildcard | FullWildcard => {
        let enc_prefix = if kind == Hostname {
          let p = encode_hostname_value(part.prefix, ipv6_open)
          for c in part.prefix {
            if c == '[' {
              ipv6_open = true
            } else if c == ']' {
              ipv6_open = false
            }
          }
          p
        } else {
          apply_encode_for_component(part.prefix, kind)
        }
        let enc_suffix = if kind == Hostname {
          let s = encode_hostname_value(part.suffix, ipv6_open)
          for c in part.suffix {
            if c == '[' {
              ipv6_open = true
            } else if c == ']' {
              ipv6_open = false
            }
          }
          s
        } else {
          apply_encode_for_component(part.suffix, kind)
        }
        result.push({
          kind: part.kind,
          value: part.value,
          modifier: part.modifier,
          name: part.name,
          prefix: enc_prefix,
          suffix: enc_suffix,
        })
      }
    }
  }
  result
}

///|
fn compile_component(
  pattern : String,
  options : CompileOptions,
  policy : TokenizePolicy,
  kind : ComponentKind,
) -> UrlPatternComponent raise UrlPatternError {
  let raw_parts = parse_pattern_to_parts(pattern, options, policy)
  let parts = encode_parts(raw_parts, kind)
  let pat_str = generate_pattern_string(parts, options)
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
  let proto_raw = init.protocol.unwrap_or("*")
  let proto_val = if proto_raw.length() > 0 &&
    proto_raw[proto_raw.length() - 1] == ':' {
    proto_raw[0:proto_raw.length() - 1].to_owned()
  } else {
    proto_raw
  }
  let port_raw = init.port.unwrap_or("*")
  if is_literal_port_out_of_range(port_raw) {
    raise UrlPatternError("port out of range: '\{port_raw}'")
  }
  let port_val = match (proto_val, port_raw) {
    ("http" | "ws", "80") => ""
    ("https" | "wss", "443") => ""
    ("ftp", "21") => ""
    (_, v) => v
  }
  let protocol = compile_component(proto_val, default_options, Strict, Protocol)
  let username = compile_component(
    init.username.unwrap_or("*"),
    default_options,
    Strict,
    Username,
  )
  let password = compile_component(
    init.password.unwrap_or("*"),
    default_options,
    Strict,
    Password,
  )
  let hostname = compile_component(
    init.hostname.unwrap_or("*"),
    hostname_options,
    Strict,
    Hostname,
  )
  let port = compile_component(port_val, default_options, Strict, Port)
  let can_match_special_proto = protocol.regex.execute("ftp") is Some(_) ||
    protocol.regex.execute("file") is Some(_) ||
    protocol.regex.execute("http") is Some(_) ||
    protocol.regex.execute("https") is Some(_) ||
    protocol.regex.execute("ws") is Some(_) ||
    protocol.regex.execute("wss") is Some(_)
  let pathname_kind = if !can_match_special_proto {
    OpaquePathname
  } else {
    Pathname
  }
  let pathname = compile_component(
    init.pathname.unwrap_or("*"),
    pathname_options,
    Strict,
    pathname_kind,
  )
  let search_raw = init.search.unwrap_or("*")
  let search_val = if search_raw.length() > 0 && search_raw[0] == '?' {
    search_raw[1:].to_owned()
  } else {
    search_raw
  }
  let search = compile_component(search_val, default_options, Strict, Search)
  let hash_raw = init.hash.unwrap_or("*")
  let hash_val = if hash_raw.length() > 0 && hash_raw[0] == '#' {
    hash_raw[1:].to_owned()
  } else {
    hash_raw
  }
  let hash = compile_component(hash_val, default_options, Strict, Hash)
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
  let proto_raw = init.protocol.unwrap_or("")
  let proto_input = try? canonicalize_protocol_for_pattern(proto_raw)
  let proto_input = match proto_input {
    Err(_) => return None
    Ok(s) => s
  }
  let proto_str = proto_input
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
  let raw_port = init.port.unwrap_or("")
  let port_input = if raw_port != "" {
    let p = canonicalize_port(raw_port, proto_str)
    // If port has non-digit characters after canonicalization, it's invalid
    let valid = {
      let mut ok = true
      for c in p {
        if !(c >= '0' && c <= '9') {
          ok = false
          break
        }
      }
      ok
    }
    if !valid {
      return None
    }
    p
  } else {
    ""
  }
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
  let base_search_raw = strip_leading_char(base.search(), '?')
  let base_hash_raw = strip_leading_char(base.hash(), '#')
  let base_port = base.port_str()
  let esc : (String) -> String = if for_pattern {
    escape_pattern_string
  } else {
    fn(s) { s }
  }
  let has_protocol = init.protocol is Some(_)
  let has_username = init.username is Some(_)
  let has_password = init.password is Some(_)
  let has_hostname = init.hostname is Some(_)
  let has_port = init.port is Some(_)
  let has_pathname = init.pathname is Some(_)
  let has_search = init.search is Some(_)
  let protocol = if has_protocol {
    init.protocol
  } else {
    Some(esc(base.scheme))
  }
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
    Some(esc(base.hostname()))
  } else {
    init.hostname
  }
  let port = if !has_protocol && !has_hostname && !has_port {
    Some(esc(base_port))
  } else {
    init.port
  }
  let pathname = if !has_protocol && !has_hostname && !has_port && !has_pathname {
    Some(esc(base.pathname()))
  } else if !has_protocol && !has_hostname && !has_port && has_pathname {
    let pn = init.pathname.unwrap_or("")
    let first_slash : Bool = {
      let chars : Array[Char] = []
      for c in pn {
        chars.push(c)
      }
      if chars.is_empty() {
        false
      } else {
        let c0 = chars[0]
        c0 == '/' ||
        (chars.length() > 1 && (c0 == '{' || c0 == '\\') && chars[1] == '/')
      }
    }
    if first_slash {
      init.pathname
    } else {
      let resolved = get_base_dir(base.pathname()) + pn
      if for_pattern {
        let normalized = try? @url.parse("https://dummy.test" + resolved)
        Some(
          match normalized {
            Ok(u) => u.pathname()
            Err(_) => resolved
          },
        )
      } else {
        Some(resolved)
      }
    }
  } else {
    init.pathname
  }
  let search = if !has_protocol &&
    !has_hostname &&
    !has_port &&
    !has_pathname &&
    !has_search {
    Some(esc(base_search_raw))
  } else {
    init.search
  }
  let hash = if !has_protocol &&
    !has_hostname &&
    !has_port &&
    !has_pathname &&
    !has_search &&
    init.hash is None {
    Some(esc(base_hash_raw))
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
