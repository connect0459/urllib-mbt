///|
/// Returns `true` if `url` (optionally resolved against `base`) parses without error.
///
/// ### Example
///
/// ```mbt check
/// test {
///   inspect(can_parse("https://example.com", None), content="true")
///   inspect(can_parse("not a url", None), content="false")
/// }
/// ```
pub fn can_parse(url : String, base : Url?) -> Bool {
  (parse_with_base(url, base) catch { _ => return false }) |> ignore
  true
}

///|
/// Parses `url` (optionally against `base`), returning `None` on failure instead of raising.
///
/// ### Example
///
/// ```mbt check
/// test {
///   inspect(parse_maybe("https://example.com", None) is Some(_), content="true")
///   inspect(parse_maybe("not a url", None) is None, content="true")
/// }
/// ```
pub fn parse_maybe(url : String, base : Url?) -> Url? {
  Some(parse_with_base(url, base)) catch {
    _ => None
  }
}

///|
/// Returns the serialized URL string, equivalent to `href()`.
pub fn Url::to_json(self : Url) -> String {
  self.href()
}

///|
/// Returns `true` when the scheme is one of the WHATWG special schemes
/// (`ftp`, `file`, `http`, `https`, `ws`, `wss`).
pub fn Url::is_special(self : Url) -> Bool {
  is_special_scheme(self.scheme)
}

///|
/// Returns `true` when the URL has a non-empty username or password.
pub fn Url::has_credentials(self : Url) -> Bool {
  self.username != "" || self.password != ""
}

///|
/// Returns `true` when the URL has an opaque path (cannot-be-a-base URL).
pub fn Url::has_opaque_path(self : Url) -> Bool {
  self.path is UrlPath::Opaque(_)
}

///|
/// Resolves `url` relative to this URL; raises `UrlParseError` on failure.
///
/// ### Example
///
/// ```mbt check
/// test {
///   let base = try! parse("https://example.com/a/b/")
///   inspect((try! base.join("../c")).href(), content="https://example.com/a/c")
/// }
/// ```
pub fn Url::join(self : Url, url : String) -> Url raise UrlParseError {
  parse_with_base(url, Some(self))
}

///|
/// Returns the URL query string parsed as `UrlSearchParams`; an absent or empty
/// query produces an empty `UrlSearchParams`.
///
/// ### Example
///
/// ```mbt check
/// test {
///   let url = try! parse("https://example.com/?a=1&b=2")
///   inspect(url.search_params().get("a") == Some("1"), content="true")
/// }
/// ```
pub fn Url::search_params(self : Url) -> UrlSearchParams {
  match self.query {
    None | Some("") => UrlSearchParams::new()
    Some(q) => parse_urlencoded(q)
  }
}

///|
/// Returns the URL scheme without the trailing colon (e.g. `"https"`).
pub fn Url::scheme(self : Url) -> String {
  self.scheme
}

///|
/// Returns the percent-encoded username, or `""` when absent.
pub fn Url::username(self : Url) -> String {
  self.username
}

///|
/// Returns the percent-encoded password, or `""` when absent.
pub fn Url::password(self : Url) -> String {
  self.password
}

///|
/// Returns the port number, or `None` when absent or equal to the scheme default.
pub fn Url::port(self : Url) -> Int? {
  self.port
}

///|
/// Returns an iterator over percent-encoded path segments, or `None` for opaque-path URLs.
pub fn Url::path_segments(self : Url) -> Iter[String]? {
  match self.path {
    UrlPath::Opaque(_) => None
    UrlPath::Segments(segs) => Some(segs.iter())
  }
}

///|
/// Converts a domain name to its ACE/Punycode form per UTS#46;
/// returns `""` on error.
///
/// ### Example
///
/// ```mbt check
/// test {
///   inspect(domain_to_ascii("例え.jp"), content="xn--r8jz45g.jp")
///   inspect(domain_to_ascii("EXAMPLE.COM"), content="example.com")
/// }
/// ```
pub fn domain_to_ascii(domain : String) -> String {
  @idna.domain_to_ascii(domain) catch {
    _ => ""
  }
}

///|
/// Converts an ACE-encoded domain to its Unicode form per UTS#46;
/// returns `""` on error.
///
/// ### Example
///
/// ```mbt check
/// test {
///   inspect(domain_to_unicode("xn--r8jz45g.jp"), content="例え.jp")
///   inspect(domain_to_unicode("example.com"), content="example.com")
/// }
/// ```
pub fn domain_to_unicode(domain : String) -> String {
  @idna.domain_to_unicode(domain) catch {
    _ => ""
  }
}
