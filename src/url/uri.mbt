///|
pub fn can_parse(url : String, base : Url?) -> Bool {
  (parse_with_base(url, base) catch { _ => return false }) |> ignore
  true
}

///|
pub fn parse_maybe(url : String, base : Url?) -> Url? {
  Some(parse_with_base(url, base)) catch {
    _ => None
  }
}

///|
pub fn Url::to_json(self : Url) -> String {
  self.href()
}

///|
pub fn Url::is_special(self : Url) -> Bool {
  is_special_scheme(self.scheme)
}

///|
pub fn Url::has_credentials(self : Url) -> Bool {
  self.username != "" || self.password != ""
}

///|
pub fn Url::has_opaque_path(self : Url) -> Bool {
  self.path is UrlPath::Opaque(_)
}

///|
pub fn Url::join(self : Url, url : String) -> Url raise UrlParseError {
  parse_with_base(url, Some(self))
}

///|
pub fn Url::search_params(self : Url) -> UrlSearchParams {
  match self.query {
    None | Some("") => UrlSearchParams::new()
    Some(q) => parse_urlencoded(q)
  }
}

///|
pub fn Url::scheme(self : Url) -> String {
  self.scheme
}

///|
pub fn Url::username(self : Url) -> String {
  self.username
}

///|
pub fn Url::password(self : Url) -> String {
  self.password
}

///|
pub fn Url::port(self : Url) -> Int? {
  self.port
}

///|
pub fn Url::path_segments(self : Url) -> Iter[String]? {
  match self.path {
    UrlPath::Opaque(_) => None
    UrlPath::Segments(segs) => Some(segs.iter())
  }
}
