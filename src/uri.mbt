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
