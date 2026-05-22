///|
priv enum PartType {
  FixedText
  Regexp
  SegmentWildcard
  FullWildcard
}

///|
priv enum PartModifier {
  NoMod
  Optional
  ZeroOrMore
  OneOrMore
} derive(Eq)

///|
priv struct Part {
  kind : PartType
  value : String
  modifier : PartModifier
  name : String
  prefix : String
  suffix : String
}

///|
priv struct CompileOptions {
  delimiter : Char?
  prefix_char : Char?
}

///|
let default_options : CompileOptions = { delimiter: None, prefix_char: None }

///|
let hostname_options : CompileOptions = {
  delimiter: Some('.'),
  prefix_char: None,
}

///|
let pathname_options : CompileOptions = {
  delimiter: Some('/'),
  prefix_char: Some('/'),
}

///|
priv struct ParserCtx {
  tokens : Array[Token]
  mut i : Int
  parts : Array[Part]
  mut pending_fixed : String
  mut next_numeric_name : Int
  options : CompileOptions
}

///|
fn ParserCtx::new(tokens : Array[Token], options : CompileOptions) -> ParserCtx {
  { tokens, i: 0, parts: [], pending_fixed: "", next_numeric_name: 0, options }
}

///|
fn ParserCtx::peek(self : ParserCtx) -> TokenType {
  if self.i < self.tokens.length() {
    self.tokens[self.i].kind
  } else {
    End
  }
}

///|
fn ParserCtx::try_consume(self : ParserCtx, kind : TokenType) -> Token? {
  if self.i < self.tokens.length() && self.tokens[self.i].kind == kind {
    let t = self.tokens[self.i]
    self.i += 1
    Some(t)
  } else {
    None
  }
}

///|
fn ParserCtx::try_consume_modifier(self : ParserCtx) -> Token? {
  if self.i < self.tokens.length() {
    match self.tokens[self.i].kind {
      OtherModifier | Asterisk => {
        let t = self.tokens[self.i]
        self.i += 1
        Some(t)
      }
      _ => None
    }
  } else {
    None
  }
}

///|
fn ParserCtx::consume_text(self : ParserCtx) -> String {
  let buf = StringBuilder::new()
  while self.i < self.tokens.length() {
    match self.tokens[self.i].kind {
      Char | EscapedChar => {
        buf.write_string(self.tokens[self.i].value)
        self.i += 1
      }
      _ => break
    }
  }
  buf.to_string()
}

///|
fn ParserCtx::flush_pending(self : ParserCtx) -> Unit {
  let val = self.pending_fixed
  if val.length() > 0 {
    self.parts.push({
      kind: FixedText,
      value: val,
      modifier: NoMod,
      name: "",
      prefix: "",
      suffix: "",
    })
    self.pending_fixed = ""
  }
}

///|
fn ParserCtx::alloc_name(self : ParserCtx) -> String {
  let n = self.next_numeric_name.to_string()
  self.next_numeric_name += 1
  n
}

///|
fn ParserCtx::segment_wildcard_regexp(self : ParserCtx) -> String {
  match self.options.delimiter {
    None => "[^]+?"
    Some(d) => "[^" + escape_regexp_char(d) + "]+?"
  }
}

///|
fn ParserCtx::extract_prefix_from_pending(self : ParserCtx) -> String {
  match self.options.prefix_char {
    None => ""
    Some(pc) => {
      let pf = self.pending_fixed
      if pf.length() > 0 {
        let chars : Array[Char] = []
        for c in pf {
          chars.push(c)
        }
        if chars[chars.length() - 1] == pc {
          let buf = StringBuilder::new()
          for j = 0; j < chars.length() - 1; j = j + 1 {
            buf.write_char(chars[j])
          }
          self.pending_fixed = buf.to_string()
          pc.to_string()
        } else {
          ""
        }
      } else {
        ""
      }
    }
  }
}

///|
fn modifier_from_token(t : Token?) -> PartModifier {
  match t {
    None => NoMod
    Some({ kind: OtherModifier, value: "?" }) => Optional
    Some({ kind: OtherModifier, value: "+" }) => OneOrMore
    Some({ kind: Asterisk, .. }) => ZeroOrMore
    _ => NoMod
  }
}

///|
fn parse_pattern_to_parts(
  input : String,
  options : CompileOptions,
  policy : TokenizePolicy,
) -> Array[Part] raise UrlPatternError {
  let tokens = tokenize(input, policy)
  let ctx = ParserCtx::new(tokens, options)

  while ctx.i < ctx.tokens.length() {
    match ctx.peek() {
      End => break
      Open => {
        ctx.i += 1
        let prefix_text = ctx.consume_text()
        let name_tok = ctx.try_consume(Name)
        let rw_tok = match ctx.try_consume(Regexp) {
          Some(t) => Some(t)
          None => ctx.try_consume(Asterisk)
        }
        let suffix_text = ctx.consume_text()
        let _ = ctx.try_consume(Close)
        let mod_tok = ctx.try_consume_modifier()
        ctx.flush_pending()
        let name = match name_tok {
          Some(nt) => nt.value
          None =>
            if rw_tok is Some(_) {
              ctx.alloc_name()
            } else {
              let modifier = modifier_from_token(mod_tok)
              if modifier == NoMod {
                ctx.pending_fixed = ctx.pending_fixed +
                  prefix_text +
                  suffix_text
              } else {
                ctx.parts.push({
                  kind: FixedText,
                  value: prefix_text + suffix_text,
                  modifier,
                  name: "",
                  prefix: "",
                  suffix: "",
                })
              }
              continue
            }
        }
        let (pk, pv) = match rw_tok {
          Some({ kind: Regexp, value: rv }) => (PartType::Regexp, rv)
          Some({ kind: Asterisk, .. }) => (FullWildcard, ".*")
          _ => (SegmentWildcard, ctx.segment_wildcard_regexp())
        }
        ctx.parts.push({
          kind: pk,
          value: pv,
          modifier: modifier_from_token(mod_tok),
          name,
          prefix: prefix_text,
          suffix: suffix_text,
        })
      }
      Name => {
        let name_tok = ctx.tokens[ctx.i]
        ctx.i += 1
        let prefix = ctx.extract_prefix_from_pending()
        ctx.flush_pending()
        let rw_tok = ctx.try_consume(Regexp)
        let mod_tok = ctx.try_consume_modifier()
        let (pk, pv) = match rw_tok {
          Some({ kind: Regexp, value: rv }) => (PartType::Regexp, rv)
          _ => (SegmentWildcard, ctx.segment_wildcard_regexp())
        }
        ctx.parts.push({
          kind: pk,
          value: pv,
          modifier: modifier_from_token(mod_tok),
          name: name_tok.value,
          prefix,
          suffix: "",
        })
      }
      Regexp => {
        let rw_tok = ctx.tokens[ctx.i]
        ctx.i += 1
        let prefix = ctx.extract_prefix_from_pending()
        ctx.flush_pending()
        let mod_tok = ctx.try_consume_modifier()
        ctx.parts.push({
          kind: PartType::Regexp,
          value: rw_tok.value,
          modifier: modifier_from_token(mod_tok),
          name: ctx.alloc_name(),
          prefix,
          suffix: "",
        })
      }
      Asterisk => {
        ctx.i += 1
        let prefix = ctx.extract_prefix_from_pending()
        ctx.flush_pending()
        let mod_tok = ctx.try_consume_modifier()
        ctx.parts.push({
          kind: FullWildcard,
          value: ".*",
          modifier: modifier_from_token(mod_tok),
          name: ctx.alloc_name(),
          prefix,
          suffix: "",
        })
      }
      Char | EscapedChar => {
        ctx.pending_fixed = ctx.pending_fixed + ctx.tokens[ctx.i].value
        ctx.i += 1
      }
      _ => ctx.i += 1
    }
  }
  ctx.flush_pending()
  ctx.parts
}

///|
fn generate_pattern_string(parts : Array[Part]) -> String {
  let buf = StringBuilder::new()
  for part in parts {
    match part.kind {
      FixedText => buf.write_string(escape_pattern_string(part.value))
      SegmentWildcard => {
        buf.write_string(part.prefix)
        buf.write_char(':')
        buf.write_string(part.name)
        buf.write_string(part.suffix)
        buf.write_string(modifier_to_string(part.modifier))
      }
      FullWildcard => {
        buf.write_string(part.prefix)
        buf.write_char('*')
        buf.write_string(part.suffix)
        buf.write_string(modifier_to_string(part.modifier))
      }
      Regexp => {
        buf.write_string(part.prefix)
        buf.write_char('(')
        buf.write_string(part.value)
        buf.write_char(')')
        buf.write_string(part.suffix)
        buf.write_string(modifier_to_string(part.modifier))
      }
    }
  }
  buf.to_string()
}

///|
fn generate_regexp(
  parts : Array[Part],
  options : CompileOptions,
) -> (String, Array[String]) {
  let buf = StringBuilder::new()
  let names : Array[String] = []
  buf.write_string("^")
  for part in parts {
    match part.kind {
      FixedText =>
        if part.modifier == NoMod {
          buf.write_string(escape_regexp_string(part.value))
        } else {
          buf.write_string("(?:")
          buf.write_string(escape_regexp_string(part.value))
          buf.write_string(")")
          buf.write_string(modifier_to_string(part.modifier))
        }
      _ => {
        names.push(part.name)
        let regexp_value = match part.kind {
          SegmentWildcard =>
            match options.delimiter {
              None => "[^]+?"
              Some(d) => "[^" + escape_regexp_char(d) + "]+?"
            }
          FullWildcard => ".*"
          Regexp => part.value
          FixedText => ""
        }
        let esc_prefix = escape_regexp_string(part.prefix)
        let esc_suffix = escape_regexp_string(part.suffix)
        if part.prefix.length() == 0 && part.suffix.length() == 0 {
          if part.modifier == NoMod || part.modifier == Optional {
            buf.write_string("(")
            buf.write_string(regexp_value)
            buf.write_string(")")
            buf.write_string(modifier_to_string(part.modifier))
          } else {
            buf.write_string("((?:")
            buf.write_string(regexp_value)
            buf.write_string(")")
            buf.write_string(modifier_to_string(part.modifier))
            buf.write_string(")")
          }
        } else if part.modifier == NoMod || part.modifier == Optional {
          buf.write_string("(?:")
          buf.write_string(esc_prefix)
          buf.write_string("(")
          buf.write_string(regexp_value)
          buf.write_string(")")
          buf.write_string(esc_suffix)
          buf.write_string(")")
          buf.write_string(modifier_to_string(part.modifier))
        } else {
          buf.write_string("(?:")
          buf.write_string(esc_prefix)
          buf.write_string("((?:")
          buf.write_string(regexp_value)
          buf.write_string(")(?:")
          buf.write_string(esc_suffix)
          buf.write_string(esc_prefix)
          buf.write_string("(?:")
          buf.write_string(regexp_value)
          buf.write_string("))*)")
          buf.write_string(esc_suffix)
          buf.write_string(")")
          if part.modifier == ZeroOrMore {
            buf.write_string("?")
          }
        }
      }
    }
  }
  buf.write_string("$")
  (buf.to_string(), names)
}

///|
fn modifier_to_string(m : PartModifier) -> String {
  match m {
    NoMod => ""
    Optional => "?"
    ZeroOrMore => "*"
    OneOrMore => "+"
  }
}

///|
fn escape_regexp_string(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    if needs_regexp_escape(c) {
      buf.write_string("\\")
    }
    buf.write_char(c)
  }
  buf.to_string()
}

///|
fn escape_regexp_char(c : Char) -> String {
  if needs_regexp_escape(c) {
    "\\" + c.to_string()
  } else {
    c.to_string()
  }
}

///|
fn needs_regexp_escape(c : Char) -> Bool {
  match c {
    '.'
    | '+'
    | '*'
    | '?'
    | '^'
    | '$'
    | '{'
    | '}'
    | '('
    | ')'
    | '['
    | ']'
    | '|'
    | '\\'
    | '/' => true
    _ => false
  }
}

///|
fn escape_pattern_string(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    match c {
      '+' | '*' | '?' | ':' | '{' | '}' | '(' | ')' | '\\' => {
        buf.write_string("\\")
        buf.write_char(c)
      }
      _ => buf.write_char(c)
    }
  }
  buf.to_string()
}
