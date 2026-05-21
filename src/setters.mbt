// Remove ASCII tab (0x09), LF (0x0A), CR (0x0D) from input without touching
// leading/trailing C0 controls or spaces. Used by URL setters per WHATWG spec
// (basic URL parse with state override skips the C0/space trim).

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
fn safe_parse_host(input : String, is_special : Bool) -> Host? {
  Some(parse_host(input, is_special)) catch {
    _ => None
  }
}

///|
fn url_can_have_credentials(url : Url) -> Bool {
  if url.scheme == "file" {
    return false
  }
  match url.path {
    Opaque(_) => false
    _ =>
      match url.host {
        None | Some(Host::Domain("")) => false
        _ => true
      }
  }
}

// Returns (changed, new_port) where:
//   changed=false => keep original port unchanged
//   changed=true, new_port=None => clear port (default port or zero digits after stop)
//   changed=true, new_port=Some(p) => set port to p

///|
fn parse_setter_port(s : String, scheme : String) -> (Bool, Int?) {
  let mut val = 0
  let mut has_digits = false
  for c in s {
    if c >= '0' && c <= '9' {
      val = val * 10 + (c.to_int() - '0'.to_int())
      has_digits = true
      if val > 65535 {
        return (false, None)
      }
    } else {
      break
    }
  }
  if !has_digits {
    return (false, None)
  }
  match special_scheme_default_port(scheme) {
    Some(dp) if dp == val => (true, None)
    _ => (true, Some(val))
  }
}

// Truncate s at first /, ?, #, or \ (when is_special) after stripping tabs/newlines

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

// Split "host" or "host:port" string into (host_part, port_str?)
// port_str = None if no colon, Some(s) if colon found (s may be empty)

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
pub fn Url::set_href(self : Url, value : String) -> Url raise UrlParseError {
  parse(value)
}

///|
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
  if new_scheme.is_empty() {
    return self
  }
  let old_special = is_special_scheme(self.scheme)
  let new_special = is_special_scheme(new_scheme)
  if old_special != new_special {
    return self
  }
  if new_scheme == "file" &&
    (self.username != "" || self.password != "" || self.port != None) {
    return self
  }
  if self.scheme == "file" && new_scheme != "file" {
    let empty_host = match self.host {
      None | Some(Host::Domain("")) => true
      _ => false
    }
    if empty_host {
      return self
    }
  }
  let new_port = match self.port {
    Some(p) if special_scheme_default_port(new_scheme) == Some(p) => None
    p => p
  }
  { ..self, scheme: new_scheme, port: new_port }
}

///|
pub fn Url::set_username(self : Url, value : String) -> Url {
  if !url_can_have_credentials(self) {
    return self
  }
  { ..self, username: percent_encode_userinfo(value) }
}

///|
pub fn Url::set_password(self : Url, value : String) -> Url {
  if !url_can_have_credentials(self) {
    return self
  }
  { ..self, password: percent_encode_userinfo(value) }
}

///|
pub fn Url::set_port(self : Url, value : String) -> Url {
  if self.scheme == "file" {
    return self
  }
  match self.path {
    Opaque(_) => return self
    _ => ()
  }
  match self.host {
    None | Some(Host::Domain("")) => return self
    _ => ()
  }
  if value.is_empty() {
    return { ..self, port: None }
  }
  let stripped = strip_ascii_tabs_newlines(value)
  if stripped.is_empty() {
    return self
  }
  match parse_setter_port(stripped, self.scheme) {
    (false, _) => self
    (true, new_port) => { ..self, port: new_port }
  }
}

///|
pub fn Url::set_hash(self : Url, value : String) -> Url {
  let stripped = strip_ascii_tabs_newlines(value)
  if stripped.is_empty() {
    return { ..self, fragment: None }
  }
  let input = if stripped.has_prefix("#") {
    stripped[1:stripped.length()].to_owned()
  } else {
    stripped
  }
  { ..self, fragment: Some(percent_encode_fragment(input)) }
}

///|
pub fn Url::set_search(self : Url, value : String) -> Url {
  let stripped = strip_ascii_tabs_newlines(value)
  if stripped.is_empty() {
    return { ..self, query: None }
  }
  let input = if stripped.has_prefix("?") {
    stripped[1:stripped.length()].to_owned()
  } else {
    stripped
  }
  let encoded = percent_encode_query(input, is_special_scheme(self.scheme))
  { ..self, query: Some(encoded) }
}

///|
pub fn Url::set_pathname(self : Url, value : String) -> Url {
  match self.path {
    Opaque(_) => return self
    _ => ()
  }
  let is_special = is_special_scheme(self.scheme)
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
        let is_file_drive = self.scheme == "file" &&
          segs.is_empty() &&
          is_windows_drive_letter(seg)
        if is_file_drive {
          let c0 = seg.get_char(0).unwrap_or('C').to_string()
          let rest = seg[2:seg.length()].to_owned()
          segs.push(c0 + ":" + rest)
        } else {
          segs.push(percent_encode_path_seg(seg))
        }
      }
      if c == None {
        break
      }
    } else {
      match c {
        Some(ch) => buf.write_char(ch)
        None => ()
      }
    }
    i = i + 1
  }
  if segs.is_empty() && self.host == None {
    segs.push("")
  }
  { ..self, path: UrlPath::Segments(segs) }
}

///|
pub fn Url::set_host(self : Url, value : String) -> Url {
  match self.path {
    Opaque(_) => return self
    _ => ()
  }
  let is_special = is_special_scheme(self.scheme)
  let stripped = strip_ascii_tabs_newlines(value)
  let truncated = truncate_host_value(stripped, is_special)
  let (host_str, port_opt) = split_host_port(truncated)
  // File URLs: port is forbidden; empty host clears to ""
  if self.scheme == "file" {
    match port_opt {
      Some(ps) if ps != "" => return self
      _ => ()
    }
    if host_str == "" {
      return { ..self, host: Some(Host::Domain("")) }
    }
  }
  // Empty host + non-empty port is invalid
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
  let new_host = if self.scheme == "file" {
    match parsed {
      Host::Domain("localhost") => Host::Domain("")
      h => h
    }
  } else {
    parsed
  }
  match new_host {
    Host::Domain("") =>
      if !is_special &&
        (self.username != "" || self.password != "" || self.port != None) {
        return self
      }
    _ => ()
  }
  let url_with_host = { ..self, host: Some(new_host) }
  match port_opt {
    None | Some("") => url_with_host
    Some(port_str) =>
      match parse_setter_port(port_str, self.scheme) {
        (false, _) => url_with_host
        (true, new_port) => { ..url_with_host, port: new_port }
      }
  }
}

///|
pub fn Url::set_hostname(self : Url, value : String) -> Url {
  match self.path {
    Opaque(_) => return self
    _ => ()
  }
  let is_special = is_special_scheme(self.scheme)
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
  // File URL + empty input: explicitly clear host to ""
  if self.scheme == "file" && truncated == "" {
    return { ..self, host: Some(Host::Domain("")) }
  }
  let parsed = match safe_parse_host(truncated, is_special) {
    None => return self
    Some(h) => h
  }
  let new_host = if self.scheme == "file" {
    match parsed {
      Host::Domain("localhost") => Host::Domain("")
      h => h
    }
  } else {
    parsed
  }
  match new_host {
    Host::Domain("") =>
      if !is_special &&
        (self.username != "" || self.password != "" || self.port != None) {
        return self
      }
    _ => ()
  }
  { ..self, host: Some(new_host) }
}
