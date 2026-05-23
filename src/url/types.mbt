///|
pub type Host = @host.Host

///|
/// The path of a parsed URL: either an ordered list of decoded path segments
/// or an opaque string for cannot-be-a-base URLs.
pub enum UrlPath {
  Segments(Array[String])
  Opaque(String)
} derive(Debug)

///|
impl Eq for UrlPath with fn equal(self : UrlPath, other : UrlPath) -> Bool {
  match (self, other) {
    (Segments(a), Segments(b)) => a == b
    (Opaque(a), Opaque(b)) => a == b
    _ => false
  }
}

///|
/// Error raised when a URL string fails to parse.
pub suberror UrlParseError {
  UrlParseError(String)
}

///|
pub impl Show for UrlParseError with fn output(self, logger) {
  match self {
    UrlParseError(msg) => logger.write_string("UrlParseError: " + msg)
  }
}

///|
/// An immutable parsed URL. All setter methods return a new `Url` value
/// rather than modifying this one.
pub struct Url {
  scheme : String
  username : String
  password : String
  host : Host?
  port : Int?
  path : UrlPath
  query : String?
  fragment : String?
} derive(Eq, Debug)

///|
priv struct UrlRecord {
  mut scheme : String
  mut username : String
  mut password : String
  mut host : Host?
  mut port : Int?
  mut path_segments : Array[String]
  mut opaque_path : String
  mut has_opaque_path : Bool
  mut query : String?
  mut fragment : String?
}

///|
fn UrlRecord::new() -> UrlRecord {
  {
    scheme: "",
    username: "",
    password: "",
    host: None,
    port: None,
    path_segments: [],
    opaque_path: "",
    has_opaque_path: false,
    query: None,
    fragment: None,
  }
}

///|
fn UrlRecord::copy_from(self : UrlRecord, other : Url) -> Unit {
  self.scheme = other.scheme
  self.username = other.username
  self.password = other.password
  self.host = other.host
  self.port = other.port
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
  self.query = other.query
  self.fragment = other.fragment
}

///|
fn UrlRecord::to_url(self : UrlRecord) -> Url {
  let path = if self.has_opaque_path {
    UrlPath::Opaque(self.opaque_path)
  } else {
    UrlPath::Segments(self.path_segments.copy())
  }
  {
    scheme: self.scheme,
    username: self.username,
    password: self.password,
    host: self.host,
    port: self.port,
    path,
    query: self.query,
    fragment: self.fragment,
  }
}

///|
fn UrlRecord::is_special(self : UrlRecord) -> Bool {
  is_special_scheme(self.scheme)
}

///|
fn is_special_scheme(scheme : String) -> Bool {
  scheme == "ftp" ||
  scheme == "file" ||
  scheme == "http" ||
  scheme == "https" ||
  scheme == "ws" ||
  scheme == "wss"
}

///|
fn special_scheme_default_port(scheme : String) -> Int? {
  if scheme == "ftp" {
    Some(21)
  } else if scheme == "http" || scheme == "ws" {
    Some(80)
  } else if scheme == "https" || scheme == "wss" {
    Some(443)
  } else {
    None
  }
}
