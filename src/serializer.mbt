///|
pub fn Url::href(self : Url) -> String {
  let buf = StringBuilder::new()
  buf.write_string(self.scheme)
  buf.write_char(':')
  match self.host {
    None => ()
    _ => buf.write_string("//")
  }
  if self.host != None || self.scheme == "file" {
    if self.username != "" || self.password != "" {
      buf.write_string(self.username)
      if self.password != "" {
        buf.write_char(':')
        buf.write_string(self.password)
      }
      buf.write_char('@')
    }
    match self.host {
      Some(h) => buf.write_string(serialize_host(h))
      None => ()
    }
    match self.port {
      Some(p) => {
        buf.write_char(':')
        buf.write_string(p.to_string())
      }
      None => ()
    }
  }
  match self.path {
    Opaque(s) => buf.write_string(s)
    Segments(segs) =>
      if segs.is_empty() {
        if self.host != None && is_special_scheme(self.scheme) {
          buf.write_char('/')
        }
      } else {
        if self.host == None && segs.length() > 1 && segs[0] == "" {
          buf.write_string("/.")
        }
        for seg in segs {
          buf.write_char('/')
          buf.write_string(seg)
        }
      }
  }
  match self.query {
    Some(q) => {
      buf.write_char('?')
      buf.write_string(q)
    }
    None => ()
  }
  match self.fragment {
    Some(f) => {
      buf.write_char('#')
      buf.write_string(f)
    }
    None => ()
  }
  buf.to_string()
}

///|
pub fn Url::origin(self : Url) -> String {
  if is_special_scheme(self.scheme) && self.scheme != "file" {
    let buf = StringBuilder::new()
    buf.write_string(self.scheme)
    buf.write_string("://")
    match self.host {
      Some(h) => buf.write_string(serialize_host(h))
      None => ()
    }
    match self.port {
      Some(p) => {
        buf.write_char(':')
        buf.write_string(p.to_string())
      }
      None => ()
    }
    buf.to_string()
  } else {
    "null"
  }
}

///|
pub fn Url::protocol(self : Url) -> String {
  self.scheme + ":"
}

///|
pub fn Url::hostname(self : Url) -> String {
  match self.host {
    Some(Ipv6(pieces)) => serialize_ipv6(pieces)
    Some(h) => serialize_host(h)
    None => ""
  }
}

///|
pub fn Url::host_str(self : Url) -> String {
  match self.host {
    None => ""
    Some(h) => {
      let serialized = serialize_host(h)
      match self.port {
        None => serialized
        Some(p) => serialized + ":" + p.to_string()
      }
    }
  }
}

///|
pub fn Url::port_str(self : Url) -> String {
  match self.port {
    None => ""
    Some(p) => p.to_string()
  }
}

///|
pub fn Url::pathname(self : Url) -> String {
  match self.path {
    Opaque(s) => s
    Segments(segs) =>
      if segs.is_empty() {
        if is_special_scheme(self.scheme) || self.host != None {
          "/"
        } else {
          ""
        }
      } else {
        let buf = StringBuilder::new()
        for seg in segs {
          buf.write_char('/')
          buf.write_string(seg)
        }
        buf.to_string()
      }
  }
}

///|
pub fn Url::search(self : Url) -> String {
  match self.query {
    None => ""
    Some(q) => "?" + q
  }
}

///|
pub fn Url::hash(self : Url) -> String {
  match self.fragment {
    None => ""
    Some(f) => "#" + f
  }
}
