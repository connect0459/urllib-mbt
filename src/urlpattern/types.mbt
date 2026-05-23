///|
pub struct UrlPatternInit {
  protocol : String?
  username : String?
  password : String?
  hostname : String?
  port : String?
  pathname : String?
  search : String?
  hash : String?
  base_url : String?
} derive(Debug)

///|
pub fn UrlPatternInit::new(
  protocol? : String? = None,
  username? : String? = None,
  password? : String? = None,
  hostname? : String? = None,
  port? : String? = None,
  pathname? : String? = None,
  search? : String? = None,
  hash? : String? = None,
  base_url? : String? = None,
) -> UrlPatternInit {
  {
    protocol,
    username,
    password,
    hostname,
    port,
    pathname,
    search,
    hash,
    base_url,
  }
}

///|
pub enum UrlPatternInput {
  Str(String)
  Init(UrlPatternInit)
} derive(Debug)

///|
pub struct UrlPatternComponentResult {
  input : String
  groups : Map[String, String?]
} derive(Debug)

///|
pub struct UrlPatternResult {
  inputs : Array[UrlPatternInput]
  protocol : UrlPatternComponentResult?
  username : UrlPatternComponentResult?
  password : UrlPatternComponentResult?
  hostname : UrlPatternComponentResult?
  port : UrlPatternComponentResult?
  pathname : UrlPatternComponentResult?
  search : UrlPatternComponentResult?
  hash : UrlPatternComponentResult?
} derive(Debug)

///|
pub suberror UrlPatternError {
  UrlPatternError(String)
}

///|
pub impl Show for UrlPatternError with fn output(self, logger) {
  match self {
    UrlPatternError(msg) => logger.write_string("UrlPatternError: " + msg)
  }
}

///|
priv struct UrlPatternComponent {
  pattern : String
  regex : @string.Regex
  group_names : Array[String]
  group_strips : Array[(String, String)]
  parts : Array[Part]
  has_regexp_groups : Bool
  kind : ComponentKind
}

///|
pub struct UrlPattern {
  priv protocol : UrlPatternComponent
  priv username : UrlPatternComponent
  priv password : UrlPatternComponent
  priv hostname : UrlPatternComponent
  priv port : UrlPatternComponent
  priv pathname : UrlPatternComponent
  priv search : UrlPatternComponent
  priv hash : UrlPatternComponent
}
