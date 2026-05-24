///|
/// Per-component pattern strings used to construct a `UrlPattern`.
/// Each field is a pattern string for the corresponding URL component;
/// `None` means "use the wildcard default".
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
/// Creates a `UrlPatternInit` with per-component pattern strings; all fields
/// default to `None` (wildcard) when omitted.
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
/// Input accepted by `exec` and `test` methods: either a URL string or a
/// per-component `UrlPatternInit`.
pub enum UrlPatternInput {
  Str(String)
  Init(UrlPatternInit)
} derive(Debug)

///|
/// Match result for a single URL component: the matched input string and a
/// map of named capture group names to their matched values.
pub struct UrlPatternComponentResult {
  input : String
  groups : Map[String, String?]
} derive(Debug)

///|
/// Aggregate match result returned by `exec_url` and `exec_init`, containing
/// per-component results for every URL component.
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
/// Error raised when a `UrlPattern` cannot be constructed due to an invalid pattern.
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
/// Identifies one of the eight URL components a `UrlPattern` operates on.
/// Used by `UrlPattern::compare_component` and `UrlPattern::generate` to
/// select which part of the pattern to act on.
pub(all) enum UrlPatternComponent {
  Protocol
  Username
  Password
  Hostname
  Port
  Pathname
  Search
  Hash
} derive(Eq, Debug)

///|
priv struct CompiledComponent {
  pattern : String
  regex : @string.Regex
  group_names : Array[String]
  group_strips : Array[(String, String)]
  parts : Array[Part]
  has_regexp_groups : Bool
  kind : ComponentKind
}

///|
/// A compiled WHATWG URL pattern that matches and extracts named groups from URLs.
pub struct UrlPattern {
  priv protocol : CompiledComponent
  priv username : CompiledComponent
  priv password : CompiledComponent
  priv hostname : CompiledComponent
  priv port : CompiledComponent
  priv pathname : CompiledComponent
  priv search : CompiledComponent
  priv hash : CompiledComponent
}
