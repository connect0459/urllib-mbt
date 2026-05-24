///|
pub fn strip_leading_char(s : String, c : Char) -> String {
  match s.get_char(0) {
    Some(head) if head == c => s[1:].to_owned()
    _ => s
  }
}

///|
pub fn string_to_chars(s : String) -> Array[Char] {
  let chars : Array[Char] = []
  for c in s {
    chars.push(c)
  }
  chars
}

///|
pub fn split_on_char(s : String, sep : Char) -> Array[String] {
  let result : Array[String] = []
  let buf = StringBuilder::new()
  for c in s {
    if c == sep {
      result.push(buf.to_string())
      buf.reset()
    } else {
      buf.write_char(c)
    }
  }
  result.push(buf.to_string())
  result
}

///|
fn is_c0(cp : Int) -> Bool {
  cp <= 0x1F || cp > 0x7E
}

///|
fn in_fragment_set(cp : Int) -> Bool {
  is_c0(cp) || cp == ' ' || cp == '"' || cp == '<' || cp == '>' || cp == '`'
}

///|
fn in_query_set(cp : Int) -> Bool {
  is_c0(cp) || cp == ' ' || cp == '"' || cp == '#' || cp == '<' || cp == '>'
}

///|
fn in_special_query_set(cp : Int) -> Bool {
  in_query_set(cp) || cp == '\''
}

///|
fn in_path_set(cp : Int) -> Bool {
  in_query_set(cp) ||
  cp == '?' ||
  cp == '^' ||
  cp == '`' ||
  cp == '{' ||
  cp == '}'
}

///|
fn in_userinfo_set(cp : Int) -> Bool {
  in_path_set(cp) ||
  cp == '/' ||
  cp == ':' ||
  cp == ';' ||
  cp == '=' ||
  cp == '@' ||
  (cp >= '[' && cp <= '^') ||
  cp == '|'
}

///|
fn to_hex_upper(n : Int) -> Char {
  if n < 10 {
    Int::unsafe_to_char('0'.to_int() + n)
  } else {
    Int::unsafe_to_char('A'.to_int() + n - 10)
  }
}

///|
/// Returns the percent-encoded representation of a single byte
/// (e.g. `0x20` → `"%20"`).
pub fn percent_encode_byte(byte : Int) -> String {
  let hi = (byte >> 4) & 0xF
  let lo = byte & 0xF
  let buf = StringBuilder::new(size_hint=3)
  buf.write_char('%')
  buf.write_char(to_hex_upper(hi))
  buf.write_char(to_hex_upper(lo))
  buf.to_string()
}

///|
/// Encodes a Unicode character to its UTF-8 byte sequence as an array of integers.
/// Lone surrogate code points (U+D800–U+DFFF) are replaced with U+FFFD to
/// match the WHATWG "UTF-8 encode" algorithm applied to USVStrings.
pub fn char_to_utf8_bytes(c : Char) -> Array[Int] {
  let raw_cp = c.to_int()
  let cp = if raw_cp >= 0xD800 && raw_cp <= 0xDFFF { 0xFFFD } else { raw_cp }
  let result : Array[Int] = []
  if cp <= 0x7F {
    result.push(cp)
  } else if cp <= 0x7FF {
    result.push(0xC0 | (cp >> 6))
    result.push(0x80 | (cp & 0x3F))
  } else if cp <= 0xFFFF {
    result.push(0xE0 | (cp >> 12))
    result.push(0x80 | ((cp >> 6) & 0x3F))
    result.push(0x80 | (cp & 0x3F))
  } else {
    result.push(0xF0 | (cp >> 18))
    result.push(0x80 | ((cp >> 12) & 0x3F))
    result.push(0x80 | ((cp >> 6) & 0x3F))
    result.push(0x80 | (cp & 0x3F))
  }
  result
}

///|
fn push_utf8_bytes(c : Char, bytes : Array[Int]) -> Unit {
  let raw_cp = c.to_int()
  let cp = if raw_cp >= 0xD800 && raw_cp <= 0xDFFF { 0xFFFD } else { raw_cp }
  if cp <= 0x7F {
    bytes.push(cp)
  } else if cp <= 0x7FF {
    bytes.push(0xC0 | (cp >> 6))
    bytes.push(0x80 | (cp & 0x3F))
  } else if cp <= 0xFFFF {
    bytes.push(0xE0 | (cp >> 12))
    bytes.push(0x80 | ((cp >> 6) & 0x3F))
    bytes.push(0x80 | (cp & 0x3F))
  } else {
    bytes.push(0xF0 | (cp >> 18))
    bytes.push(0x80 | ((cp >> 12) & 0x3F))
    bytes.push(0x80 | ((cp >> 6) & 0x3F))
    bytes.push(0x80 | (cp & 0x3F))
  }
}

///|
fn write_percent_encoded_byte(byte : Int, buf : StringBuilder) -> Unit {
  let hi = (byte >> 4) & 0xF
  let lo = byte & 0xF
  buf.write_char('%')
  buf.write_char(to_hex_upper(hi))
  buf.write_char(to_hex_upper(lo))
}

///|
fn write_percent_encoded_char(c : Char, buf : StringBuilder) -> Unit {
  let raw_cp = c.to_int()
  let cp = if raw_cp >= 0xD800 && raw_cp <= 0xDFFF { 0xFFFD } else { raw_cp }
  if cp <= 0x7F {
    write_percent_encoded_byte(cp, buf)
  } else if cp <= 0x7FF {
    write_percent_encoded_byte(0xC0 | (cp >> 6), buf)
    write_percent_encoded_byte(0x80 | (cp & 0x3F), buf)
  } else if cp <= 0xFFFF {
    write_percent_encoded_byte(0xE0 | (cp >> 12), buf)
    write_percent_encoded_byte(0x80 | ((cp >> 6) & 0x3F), buf)
    write_percent_encoded_byte(0x80 | (cp & 0x3F), buf)
  } else {
    write_percent_encoded_byte(0xF0 | (cp >> 18), buf)
    write_percent_encoded_byte(0x80 | ((cp >> 12) & 0x3F), buf)
    write_percent_encoded_byte(0x80 | ((cp >> 6) & 0x3F), buf)
    write_percent_encoded_byte(0x80 | (cp & 0x3F), buf)
  }
}

///|
fn percent_encode(input : String, in_encode_set : (Int) -> Bool) -> String {
  let buf = StringBuilder::new()
  for c in input {
    let cp = c.to_int()
    if in_encode_set(cp) {
      write_percent_encoded_char(c, buf)
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Encodes `input` using the WHATWG fragment percent-encode set.
pub fn percent_encode_fragment(input : String) -> String {
  percent_encode(input, in_fragment_set)
}

///|
/// Encodes `input` using the WHATWG query percent-encode set; uses the
/// special-query set (which also encodes `'`) when `is_special` is `true`.
pub fn percent_encode_query(input : String, is_special : Bool) -> String {
  if is_special {
    percent_encode(input, in_special_query_set)
  } else {
    percent_encode(input, in_query_set)
  }
}

///|
/// Encodes `input` using the WHATWG path percent-encode set.
pub fn percent_encode_path_seg(input : String) -> String {
  percent_encode(input, in_path_set)
}

///|
/// Encodes `input` using the WHATWG userinfo percent-encode set.
pub fn percent_encode_userinfo(input : String) -> String {
  percent_encode(input, in_userinfo_set)
}

///|
/// Encodes `input` using the C0 percent-encode set (control chars ≤ U+001F
/// and non-ASCII > U+007E).
///
/// ### Example
///
/// ```mbt check
/// test {
///   inspect(percent_encode_c0("hello\nworld"), content="hello%0Aworld")
/// }
/// ```
pub fn percent_encode_c0(input : String) -> String {
  percent_encode(input, is_c0)
}

///|
/// Encodes `input` using the C0 set, additionally encoding a trailing space
/// as `"%20"` (used at query/fragment stop boundaries in opaque paths).
pub fn percent_encode_opaque_path_at_stop(input : String) -> String {
  if input.has_suffix(" ") {
    percent_encode(input[0:input.length() - 1].to_owned(), is_c0) + "%20"
  } else {
    percent_encode(input, is_c0)
  }
}

///|
/// Returns the numeric value of an ASCII hex digit (`0`–`9`, `a`–`f`, `A`–`F`),
/// or `None` for any other character.
pub fn hex_digit_value(c : Char) -> Int? {
  if c >= '0' && c <= '9' {
    Some(c.to_int() - '0'.to_int())
  } else if c >= 'A' && c <= 'F' {
    Some(c.to_int() - 'A'.to_int() + 10)
  } else if c >= 'a' && c <= 'f' {
    Some(c.to_int() - 'a'.to_int() + 10)
  } else {
    None
  }
}

///|
/// Decodes percent-encoded sequences in `input`; invalid sequences are passed
/// through as-is.
///
/// ### Example
///
/// ```mbt check
/// test {
///   inspect(percent_decode("hello%20world"), content="hello world")
///   inspect(percent_decode("%E4%B8%AD%E6%96%87"), content="中文")
/// }
/// ```
pub fn percent_decode(input : String) -> String {
  let bytes : Array[Int] = []
  let chars = string_to_chars(input)
  let n = chars.length()
  let mut i = 0
  while i < n {
    let c = chars[i]
    if c == '%' && i + 2 < n {
      match (hex_digit_value(chars[i + 1]), hex_digit_value(chars[i + 2])) {
        (Some(hi), Some(lo)) => {
          bytes.push(hi * 16 + lo)
          i = i + 3
          continue
        }
        _ => ()
      }
    }
    push_utf8_bytes(c, bytes)
    i = i + 1
  }
  utf8_bytes_to_string(bytes)
}

///|
fn is_continuation(b : Int) -> Bool {
  (b & 0xC0) == 0x80
}

///|
/// Decodes a UTF-8 byte sequence to a `String`, replacing any invalid byte
/// sequences with U+FFFD (replacement character).
pub fn utf8_bytes_to_string(bytes : Array[Int]) -> String {
  let buf = StringBuilder::new()
  let n = bytes.length()
  let mut i = 0
  while i < n {
    let b = bytes[i]
    let (cp, advance) = if (b & 0x80) == 0 {
      (b, 1)
    } else if (b & 0xE0) == 0xC0 && i + 1 < n && is_continuation(bytes[i + 1]) {
      (((b & 0x1F) << 6) | (bytes[i + 1] & 0x3F), 2)
    } else if (b & 0xF0) == 0xE0 &&
      i + 2 < n &&
      is_continuation(bytes[i + 1]) &&
      is_continuation(bytes[i + 2]) {
      let cp = ((b & 0x0F) << 12) |
        ((bytes[i + 1] & 0x3F) << 6) |
        (bytes[i + 2] & 0x3F)
      (cp, 3)
    } else if (b & 0xF8) == 0xF0 &&
      i + 3 < n &&
      is_continuation(bytes[i + 1]) &&
      is_continuation(bytes[i + 2]) &&
      is_continuation(bytes[i + 3]) {
      let cp = ((b & 0x07) << 18) |
        ((bytes[i + 1] & 0x3F) << 12) |
        ((bytes[i + 2] & 0x3F) << 6) |
        (bytes[i + 3] & 0x3F)
      (cp, 4)
    } else {
      (0xFFFD, 1)
    }
    buf.write_char(Int::unsafe_to_char(cp))
    i = i + advance
  }
  buf.to_string()
}
