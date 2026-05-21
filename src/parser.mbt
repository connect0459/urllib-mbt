///|
priv enum State {
  SchemeStart
  Scheme
  NoScheme
  SpecialRelativeOrAuthority
  PathOrAuthority
  Relative
  RelativeSlash
  SpecialAuthoritySlashes
  SpecialAuthorityIgnoreSlashes
  Authority
  File
  FileSlash
  FileHost
  PathStart
  Path
  OpaquePath
  Query
  Fragment
}

///|
fn is_ascii_alpha(c : Char) -> Bool {
  (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
}

///|
fn is_ascii_alphanumeric(c : Char) -> Bool {
  is_ascii_alpha(c) || (c >= '0' && c <= '9')
}

///|
fn ascii_lowercase(c : Char) -> Char {
  if c >= 'A' && c <= 'Z' {
    Int::unsafe_to_char(c.to_int() + 32)
  } else {
    c
  }
}

///|
fn is_windows_drive_letter(s : String) -> Bool {
  let n = s.length()
  if n < 2 {
    return false
  }
  let c0 = s.get_char(0).unwrap_or(' ')
  let c1 = s.get_char(1).unwrap_or(' ')
  if !is_ascii_alpha(c0) {
    return false
  }
  if c1 == ':' || c1 == '|' {
    if n == 2 {
      return true
    }
    if n >= 3 {
      let c2 = s.get_char(2).unwrap_or(' ')
      return c2 == '/' || c2 == '\\' || c2 == '?' || c2 == '#'
    }
  }
  false
}

///|
fn shorten_url_path(url : UrlRecord) -> Unit {
  let is_file_drive = url.scheme == "file" &&
    url.path_segments.length() == 1 &&
    is_windows_drive_letter(url.path_segments[0])
  if is_file_drive {
    return
  }
  if url.path_segments.length() > 0 {
    let _ = url.path_segments.pop()
  }
}

///|
fn strip_tabs_and_newlines(input : String) -> String {
  let chars : Array[Char] = []
  for c in input {
    chars.push(c)
  }
  let mut start = 0
  let mut end = chars.length()
  while start < end && chars[start].to_int() <= 0x20 {
    start = start + 1
  }
  while end > start && chars[end - 1].to_int() <= 0x20 {
    end = end - 1
  }
  let buf = StringBuilder::new()
  for i = start; i < end; i = i + 1 {
    let cp = chars[i].to_int()
    if cp != 0x09 && cp != 0x0A && cp != 0x0D {
      buf.write_char(chars[i])
    }
  }
  buf.to_string()
}

///|
fn ascii_lower(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    let cp = c.to_int()
    if cp >= 'A'.to_int() && cp <= 'Z'.to_int() {
      buf.write_char(Int::unsafe_to_char(cp + 32))
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
fn is_dot_segment(s : String) -> Bool {
  let low = ascii_lower(s)
  low == ".." || low == ".%2e" || low == "%2e." || low == "%2e%2e"
}

///|
fn is_single_dot(s : String) -> Bool {
  let low = ascii_lower(s)
  low == "." || low == "%2e"
}

///|
pub fn parse(input : String) -> Url raise UrlParseError {
  parse_with_base(input, None)
}

///|
pub fn parse_with_base(input : String, base : Url?) -> Url raise UrlParseError {
  let stripped = strip_tabs_and_newlines(input)
  let url = UrlRecord::new()
  let chars : Array[Char] = []
  for c in stripped {
    chars.push(c)
  }
  let n = chars.length()
  let mut state = State::SchemeStart
  let buf = StringBuilder::new()
  let mut pointer = 0
  let mut at_sign_seen = false
  let mut password_token_seen = false

  while pointer <= n {
    let c : Char? = if pointer < n { Some(chars[pointer]) } else { None }
    let mut advance = true

    match state {
      SchemeStart =>
        match c {
          Some(ch) if is_ascii_alpha(ch) => {
            buf.write_char(ascii_lowercase(ch))
            state = State::Scheme
          }
          _ => {
            state = State::NoScheme
            advance = false
          }
        }
      Scheme =>
        match c {
          Some(ch) if is_ascii_alphanumeric(ch) ||
            ch == '+' ||
            ch == '-' ||
            ch == '.' => buf.write_char(ascii_lowercase(ch))
          Some(':') => {
            url.scheme = buf.to_string()
            buf.reset()
            if url.scheme == "file" {
              state = State::File
            } else {
              let base_same_scheme = match base {
                Some(b) => b.scheme == url.scheme
                None => false
              }
              if url.is_special() && base != None && base_same_scheme {
                state = State::SpecialRelativeOrAuthority
              } else if url.is_special() {
                state = State::SpecialAuthoritySlashes
              } else if pointer + 1 < n && chars[pointer + 1] == '/' {
                state = State::PathOrAuthority
                pointer = pointer + 1
              } else {
                url.has_opaque_path = true
                state = State::OpaquePath
              }
            }
          }
          _ => {
            buf.reset()
            state = State::NoScheme
            pointer = 0
            advance = false
          }
        }
      NoScheme =>
        match base {
          None => raise UrlParseError("no scheme and no base URL")
          Some(b) => {
            let base_has_opaque = match b.path {
              Opaque(_) => true
              _ => false
            }
            if base_has_opaque {
              match c {
                Some('#') => {
                  url.scheme = b.scheme
                  url.copy_from(b)
                  url.fragment = Some("")
                  state = State::Fragment
                }
                _ => raise UrlParseError("no scheme and base has opaque path")
              }
            } else if b.scheme != "file" {
              state = State::Relative
              advance = false
            } else {
              state = State::File
              advance = false
            }
          }
        }
      SpecialRelativeOrAuthority => {
        let next_is_slash = pointer + 1 < n && chars[pointer + 1] == '/'
        if c == Some('/') && next_is_slash {
          state = State::SpecialAuthorityIgnoreSlashes
          pointer = pointer + 1
        } else {
          state = State::Relative
          advance = false
        }
      }
      PathOrAuthority =>
        if c == Some('/') {
          state = State::Authority
        } else {
          state = State::Path
          advance = false
        }
      Relative =>
        match base {
          None => raise UrlParseError("relative URL with no base")
          Some(b) => {
            url.scheme = b.scheme
            match c {
              None => url.copy_from(b)
              Some('/') => state = State::RelativeSlash
              Some('\\') if url.is_special() => state = State::RelativeSlash
              Some('?') => {
                url.username = b.username
                url.password = b.password
                url.host = b.host
                url.port = b.port
                url.copy_path_from(b)
                url.query = Some("")
                state = State::Query
              }
              Some('#') => {
                url.username = b.username
                url.password = b.password
                url.host = b.host
                url.port = b.port
                url.copy_path_from(b)
                url.query = b.query
                url.fragment = Some("")
                state = State::Fragment
              }
              _ => {
                url.username = b.username
                url.password = b.password
                url.host = b.host
                url.port = b.port
                url.copy_path_from(b)
                shorten_url_path(url)
                state = State::Path
                advance = false
              }
            }
          }
        }
      RelativeSlash => {
        let is_special = url.is_special()
        if is_special && (c == Some('/') || c == Some('\\')) {
          state = State::SpecialAuthorityIgnoreSlashes
        } else if c == Some('/') {
          state = State::Authority
        } else {
          match base {
            Some(b) => {
              url.username = b.username
              url.password = b.password
              url.host = b.host
              url.port = b.port
            }
            None => ()
          }
          state = State::Path
          advance = false
        }
      }
      SpecialAuthoritySlashes => {
        let next_is_slash = pointer + 1 < n && chars[pointer + 1] == '/'
        if c == Some('/') && next_is_slash {
          state = State::SpecialAuthorityIgnoreSlashes
          pointer = pointer + 1
        } else {
          state = State::SpecialAuthorityIgnoreSlashes
          advance = false
        }
      }
      SpecialAuthorityIgnoreSlashes =>
        if c != Some('/') && c != Some('\\') {
          state = State::Authority
          advance = false
        }
      Authority => {
        let c = if url.is_special() && c == Some('\\') { Some('/') } else { c }
        match c {
          Some('@') => {
            let raw_creds = buf.to_string()
            buf.reset()
            let creds = if at_sign_seen { "%40" + raw_creds } else { raw_creds }
            at_sign_seen = true
            for ch in creds {
              if ch == ':' && !password_token_seen {
                password_token_seen = true
                continue
              }
              let enc = percent_encode_userinfo(ch.to_string())
              if password_token_seen {
                url.password = url.password + enc
              } else {
                url.username = url.username + enc
              }
            }
          }
          None | Some('/') | Some('?') | Some('#') => {
            let host_str = buf.to_string()
            buf.reset()
            if at_sign_seen && host_str.is_empty() {
              raise UrlParseError("empty host after @")
            }
            if url.is_special() && host_str.is_empty() {
              raise UrlParseError("empty host for special URL")
            }
            let (h, p) = parse_host_and_port(host_str, url.is_special())
            url.host = Some(h)
            match p {
              Some(pn) =>
                match special_scheme_default_port(url.scheme) {
                  Some(dp) if pn == dp => url.port = None
                  _ => url.port = Some(pn)
                }
              None => ()
            }
            match c {
              Some('?') => {
                url.query = Some("")
                state = State::Query
              }
              Some('#') => {
                url.fragment = Some("")
                state = State::Fragment
              }
              Some('/') | Some('\\') => {
                state = State::PathStart
                advance = false
              }
              _ => state = State::PathStart
            }
          }
          Some('[') => buf.write_char('[')
          Some(ch) => buf.write_char(ch)
        }
      }
      File => {
        url.scheme = "file"
        url.host = Some(Host::Domain(""))
        match c {
          Some('/') | Some('\\') => state = State::FileSlash
          _ => {
            let is_file_base = match base {
              Some(b) => b.scheme == "file"
              None => false
            }
            if is_file_base {
              let b = match base {
                Some(b) => b
                None => raise UrlParseError("no base")
              }
              url.host = b.host
              url.copy_path_from(b)
              url.query = b.query
              match c {
                Some('?') => {
                  url.query = Some("")
                  state = State::Query
                }
                Some('#') => {
                  url.fragment = Some("")
                  state = State::Fragment
                }
                None => ()
                _ => {
                  url.query = None
                  shorten_url_path(url)
                  state = State::Path
                  advance = false
                }
              }
            } else {
              state = State::Path
              advance = false
            }
          }
        }
      }
      FileSlash =>
        match c {
          Some('/') | Some('\\') => state = State::FileHost
          _ => {
            match base {
              Some(b) if b.scheme == "file" => {
                url.host = b.host
                let first_seg = match b.path {
                  Segments(segs) if segs.length() > 0 => segs[0]
                  _ => ""
                }
                if is_windows_drive_letter(first_seg) {
                  url.path_segments.push(first_seg)
                }
              }
              _ => ()
            }
            state = State::Path
            advance = false
          }
        }
      FileHost =>
        match c {
          None | Some('/') | Some('\\') | Some('?') | Some('#') => {
            let host_str = buf.to_string()
            buf.reset()
            if is_windows_drive_letter(host_str) {
              state = State::Path
            } else if host_str.is_empty() {
              url.host = Some(Host::Domain(""))
              state = State::PathStart
            } else {
              let normalized = if ascii_lower(host_str) == "localhost" {
                ""
              } else {
                host_str
              }
              let h = parse_host(normalized, false)
              url.host = Some(h)
              state = State::PathStart
            }
            advance = false
          }
          Some(ch) => buf.write_char(ch)
        }
      PathStart => {
        let is_special_backslash = c == Some('\\') && url.is_special()
        if c == Some('/') || is_special_backslash {
          state = State::Path
        } else {
          state = State::Path
          advance = false
        }
      }
      Path => {
        let is_sep = c == Some('/') ||
          (c == Some('\\') && url.is_special()) ||
          c == None
        let is_query = c == Some('?')
        let is_frag = c == Some('#')
        if is_sep || is_query || is_frag {
          let seg = buf.to_string()
          buf.reset()
          if is_dot_segment(seg) {
            shorten_url_path(url)
            if c != Some('/') && !(c == Some('\\') && url.is_special()) {
              url.path_segments.push("")
            }
          } else if is_single_dot(seg) {
            if c != Some('/') && !(c == Some('\\') && url.is_special()) {
              url.path_segments.push("")
            }
          } else {
            let is_file_drive = url.scheme == "file" &&
              url.path_segments.is_empty() &&
              is_windows_drive_letter(seg)
            if is_file_drive {
              let c0 = seg.get_char(0).unwrap_or('C').to_string()
              let rest = seg[2:].to_owned()
              url.path_segments.push(c0 + ":" + rest)
            } else {
              url.path_segments.push(percent_encode_path_seg(seg))
            }
          }
          if is_query {
            url.query = Some("")
            state = State::Query
          } else if is_frag {
            url.fragment = Some("")
            state = State::Fragment
          }
        } else {
          match c {
            Some(ch) => buf.write_char(ch)
            None => ()
          }
        }
      }
      OpaquePath =>
        match c {
          Some('?') => {
            url.opaque_path = percent_encode_opaque_path_at_stop(
              buf.to_string(),
            )
            buf.reset()
            url.query = Some("")
            state = State::Query
          }
          Some('#') => {
            url.opaque_path = percent_encode_opaque_path_at_stop(
              buf.to_string(),
            )
            buf.reset()
            url.fragment = Some("")
            state = State::Fragment
          }
          None => url.opaque_path = percent_encode_opaque_path(buf.to_string())
          Some(ch) => buf.write_char(ch)
        }
      Query =>
        match c {
          Some('#') => {
            let q = buf.to_string()
            buf.reset()
            url.query = Some(percent_encode_query(q, url.is_special()))
            url.fragment = Some("")
            state = State::Fragment
          }
          None =>
            url.query = Some(
              percent_encode_query(buf.to_string(), url.is_special()),
            )
          Some(ch) => buf.write_char(ch)
        }
      Fragment =>
        match c {
          None => url.fragment = Some(percent_encode_fragment(buf.to_string()))
          Some(ch) => buf.write_char(ch)
        }
    }

    if advance {
      pointer = pointer + 1
    }
  }

  url.to_url()
}

///|
fn parse_host_and_port(
  input : String,
  is_special : Bool,
) -> (Host, Int?) raise UrlParseError {
  if input.has_prefix("[") {
    match input.rev_find("]") {
      Some(bracket_pos) => {
        let host_part = input[0:bracket_pos + 1].to_owned()
        let after = input[bracket_pos + 1:].to_owned()
        let h = parse_host(host_part, is_special)
        let p = if after.has_prefix(":") {
          let port_str = after[1:].to_owned()
          if port_str.is_empty() {
            None
          } else {
            Some(parse_port_number(port_str))
          }
        } else if after.is_empty() {
          None
        } else {
          raise UrlParseError("invalid character after IPv6 address")
        }
        (h, p)
      }
      None => raise UrlParseError("invalid IPv6: no closing bracket")
    }
  } else {
    match input.rev_find(":") {
      Some(colon_pos) => {
        let host_part = input[0:colon_pos].to_owned()
        let port_str = input[colon_pos + 1:].to_owned()
        let h = parse_host(host_part, is_special)
        let p = if port_str.is_empty() {
          None
        } else {
          Some(parse_port_number(port_str))
        }
        (h, p)
      }
      None => {
        let h = parse_host(input, is_special)
        (h, None)
      }
    }
  }
}

///|
fn parse_port_number(s : String) -> Int raise UrlParseError {
  let mut result = 0
  for c in s {
    if c < '0' || c > '9' {
      raise UrlParseError("invalid port character")
    }
    result = result * 10 + (c.to_int() - '0'.to_int())
    if result > 65535 {
      raise UrlParseError("port out of range")
    }
  }
  result
}

///|
fn UrlRecord::copy_path_from(self : UrlRecord, other : Url) -> Unit {
  match other.path {
    Segments(segs) => {
      self.has_opaque_path = false
      self.path_segments = segs.copy()
    }
    Opaque(s) => {
      self.has_opaque_path = true
      self.opaque_path = s
    }
  }
}
