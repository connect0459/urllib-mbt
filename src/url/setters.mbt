///|
fn strip_leading_char(s : String, c : Char) -> String {
  if s.has_prefix(c.to_string()) {
    s[1:s.length()].to_owned()
  } else {
    s
  }
}

///|
fn strip_ascii_tabs_newlines(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    let cp = c.to_int()
    if cp != 0x09 && cp != 0x0A && cp != 0x0D {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
fn shorten_path_segs(segs : Array[String], scheme : String) -> Unit {
  if scheme == "file" && segs.length() == 1 && is_windows_drive_letter(segs[0]) {
    return
  }
  if segs.length() > 0 {
    let _ = segs.pop()
  }
}

///|
fn normalize_file_host(h : Host) -> Host {
  match h {
    Host::Domain("localhost") => @host.Host::empty_domain()
    _ => h
  }
}

///|
fn safe_parse_host(input : String, is_special : Bool) -> Host? {
  Some(@host.parse_host(input, is_special)) catch {
    _ => None
  }
}

///|
fn url_can_have_credentials(url : Url) -> Bool {
  url.scheme != "file" &&
  !url.has_opaque_path() &&
  !(url.host is (None | Some(Host::Domain(""))))
}

///|
priv enum SetterPort {
  Unchanged
  Changed(Int?)
}

///|
fn parse_setter_port(s : String, scheme : String) -> SetterPort {
  let mut val = 0
  let mut has_digits = false
  for c in s {
    if c >= '0' && c <= '9' {
      val = val * 10 + (c.to_int() - '0'.to_int())
      has_digits = true
      if val > 65535 {
        return Unchanged
      }
    } else {
      break
    }
  }
  if !has_digits {
    return Unchanged
  }
  match special_scheme_default_port(scheme) {
    Some(dp) if dp == val => Changed(None)
    _ => Changed(Some(val))
  }
}

///|
fn truncate_host_value(s : String, is_special : Bool) -> String {
  let chars : Array[Char] = []
  for c in s {
    chars.push(c)
  }
  let n = chars.length()
  let mut end = n
  for i = 0; i < n; i = i + 1 {
    let c = chars[i]
    if c == '/' || c == '?' || c == '#' || (is_special && c == '\\') {
      end = i
      break
    }
  }
  if end == n {
    s
  } else {
    s[0:end].to_owned()
  }
}

///|
fn split_host_port(s : String) -> (String, String?) {
  if s.has_prefix("[") {
    match s.rev_find("]") {
      None => (s, None)
      Some(pos) => {
        let after = s[pos + 1:s.length()].to_owned()
        if after.has_prefix(":") {
          (s[0:pos + 1].to_owned(), Some(after[1:after.length()].to_owned()))
        } else {
          (s, None)
        }
      }
    }
  } else {
    let chars : Array[Char] = []
    for c in s {
      chars.push(c)
    }
    let n = chars.length()
    let mut colon : Int? = None
    for i = 0; i < n; i = i + 1 {
      if chars[i] == ':' {
        colon = Some(i)
        break
      }
    }
    match colon {
      None => (s, None)
      Some(i) => (s[0:i].to_owned(), Some(s[i + 1:n].to_owned()))
    }
  }
}

///|
/// Re-parses `value` as an absolute URL; raises `UrlParseError` if invalid.
pub fn Url::set_href(_ : Url, value : String) -> Url raise UrlParseError {
  parse(value)
}

///|
/// Changes the URL scheme if the new scheme is valid and compatible with the
/// current scheme type; no-op otherwise.
pub fn Url::set_protocol(self : Url, value : String) -> Url {
  let stripped = strip_ascii_tabs_newlines(value)
  if stripped.is_empty() {
    return self
  }
  let chars : Array[Char] = []
  for c in stripped {
    chars.push(c)
  }
  let n = chars.length()
  if !is_ascii_alpha(chars[0]) {
    return self
  }
  let buf = StringBuilder::new()
  let mut i = 0
  while i < n && chars[i] != ':' {
    let c = chars[i]
    if is_ascii_alphanumeric(c) || c == '+' || c == '-' || c == '.' {
      buf.write_char(ascii_lowercase(c))
    } else {
      return self
    }
    i = i + 1
  }
  let new_scheme = buf.to_string()
  let old_special = self.is_special()
  let new_special = is_special_scheme(new_scheme)
  if old_special != new_special {
    return self
  }
  if new_scheme == "file" &&
    (self.username != "" || self.password != "" || self.port != None) {
    return self
  }
  if self.scheme == "file" &&
    new_scheme != "file" &&
    self.host is (None | Some(Host::Domain(""))) {
    return self
  }
  let new_port = match self.port {
    Some(p) if special_scheme_default_port(new_scheme) == Some(p) => None
    p => p
  }
  { ..self, scheme: new_scheme, port: new_port }
}

///|
/// Sets the percent-encoded username; no-op when credentials are not allowed.
pub fn Url::set_username(self : Url, value : String) -> Url {
  if !url_can_have_credentials(self) {
    return self
  }
  { ..self, username: @pe.percent_encode_userinfo(value) }
}

///|
/// Sets the percent-encoded password; no-op when credentials are not allowed.
pub fn Url::set_password(self : Url, value : String) -> Url {
  if !url_can_have_credentials(self) {
    return self
  }
  { ..self, password: @pe.percent_encode_userinfo(value) }
}

///|
/// Sets the port; clears it when `value` is empty or matches the scheme default.
/// No-op for `file:` URLs and opaque-path URLs.
pub fn Url::set_port(self : Url, value : String) -> Url {
  if !url_can_have_credentials(self) {
    return self
  }
  if value.is_empty() {
    return { ..self, port: None }
  }
  let stripped = strip_ascii_tabs_newlines(value)
  if stripped.is_empty() {
    return self
  }
  match parse_setter_port(stripped, self.scheme) {
    Unchanged => self
    Changed(new_port) => { ..self, port: new_port }
  }
}

///|
/// Sets the fragment from `value`, stripping a leading `"#"`; clears the
/// fragment when `value` is empty.
pub fn Url::set_hash(self : Url, value : String) -> Url {
  let stripped = strip_ascii_tabs_newlines(value)
  if stripped.is_empty() {
    return { ..self, fragment: None }
  }
  let input = strip_leading_char(stripped, '#')
  { ..self, fragment: Some(@pe.percent_encode_fragment(input)) }
}

///|
/// Sets the query from `value`, stripping a leading `"?"`; clears the query
/// when `value` is empty.
pub fn Url::set_search(self : Url, value : String) -> Url {
  let stripped = strip_ascii_tabs_newlines(value)
  if stripped.is_empty() {
    return { ..self, query: None }
  }
  let input = strip_leading_char(stripped, '?')
  let encoded = @pe.percent_encode_query(input, self.is_special())
  { ..self, query: Some(encoded) }
}

///|
/// Sets the URL path from `value`; no-op for opaque-path URLs.
pub fn Url::set_pathname(self : Url, value : String) -> Url {
  if self.has_opaque_path() {
    return self
  }
  let is_special = self.is_special()
  let stripped = strip_ascii_tabs_newlines(value)
  if stripped.is_empty() {
    let new_path = if self.host != None {
      UrlPath::Segments([])
    } else {
      UrlPath::Segments([""])
    }
    return { ..self, path: new_path }
  }
  let chars : Array[Char] = []
  for c in stripped {
    chars.push(c)
  }
  let n = chars.length()
  let segs : Array[String] = []
  let buf = StringBuilder::new()
  let mut i = 0
  if i < n {
    let c = chars[i]
    if c == '/' || (is_special && c == '\\') {
      i = i + 1
    }
  }
  while i <= n {
    let c : Char? = if i < n { Some(chars[i]) } else { None }
    let is_sep = c == Some('/') || (is_special && c == Some('\\')) || c == None
    if is_sep {
      let seg = buf.to_string()
      buf.reset()
      if is_dot_segment(seg) {
        shorten_path_segs(segs, self.scheme)
        if !(c == Some('/') || (is_special && c == Some('\\'))) {
          segs.push("")
        }
      } else if is_single_dot(seg) {
        if !(c == Some('/') || (is_special && c == Some('\\'))) {
          segs.push("")
        }
      } else {
        push_normalized_segment(segs, seg, self.scheme)
      }
      if c == None {
        break
      }
    } else if c is Some(ch) {
      buf.write_char(ch)
    }
    i = i + 1
  }
  { ..self, path: UrlPath::Segments(segs) }
}

///|
fn Url::normalize_and_guard_host(
  self : Url,
  parsed : Host,
  is_special : Bool,
) -> Host? {
  let h = if self.scheme == "file" {
    normalize_file_host(parsed)
  } else {
    parsed
  }
  match h {
    Host::Domain("") if !is_special &&
      (self.username != "" || self.password != "" || self.port != None) => None
    _ => Some(h)
  }
}

///|
/// Sets the host and optional port from a `"host"` or `"host:port"` string.
/// No-op for opaque-path URLs or on parse failure.
pub fn Url::set_host(self : Url, value : String) -> Url {
  if self.has_opaque_path() {
    return self
  }
  let is_special = self.is_special()
  let stripped = strip_ascii_tabs_newlines(value)
  let truncated = truncate_host_value(stripped, is_special)
  let (host_str, port_opt) = split_host_port(truncated)
  if self.scheme == "file" {
    match port_opt {
      Some(ps) if ps != "" => return self
      _ => ()
    }
    if host_str == "" {
      return { ..self, host: Some(@host.Host::empty_domain()) }
    }
  }
  if host_str == "" {
    match port_opt {
      Some(ps) if ps != "" => return self
      _ => ()
    }
  }
  let parsed = match safe_parse_host(host_str, is_special) {
    None => return self
    Some(h) => h
  }
  let new_host = match self.normalize_and_guard_host(parsed, is_special) {
    None => return self
    Some(h) => h
  }
  let url_with_host = { ..self, host: Some(new_host) }
  match port_opt {
    None | Some("") => url_with_host
    Some(port_str) =>
      match parse_setter_port(port_str, self.scheme) {
        Unchanged => url_with_host
        Changed(new_port) => { ..url_with_host, port: new_port }
      }
  }
}

///|
/// Sets the host from `value` without modifying the port.
/// No-op for opaque-path URLs or on parse failure.
pub fn Url::set_hostname(self : Url, value : String) -> Url {
  if self.has_opaque_path() {
    return self
  }
  let is_special = self.is_special()
  let stripped = strip_ascii_tabs_newlines(value)
  let truncated = truncate_host_value(stripped, is_special)
  if truncated.has_prefix("[") {
    match truncated.rev_find("]") {
      Some(pos) if pos + 1 < truncated.length() => return self
      _ => ()
    }
  } else {
    for c in truncated {
      if c == ':' {
        return self
      }
    }
  }
  if self.scheme == "file" && truncated == "" {
    return { ..self, host: Some(@host.Host::empty_domain()) }
  }
  let parsed = match safe_parse_host(truncated, is_special) {
    None => return self
    Some(h) => h
  }
  let new_host = match self.normalize_and_guard_host(parsed, is_special) {
    None => return self
    Some(h) => h
  }
  { ..self, host: Some(new_host) }
}
