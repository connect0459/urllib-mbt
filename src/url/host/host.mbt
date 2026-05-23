///|
pub enum Host {
  Domain(String)
  Ipv4(UInt)
  Ipv6(Array[UInt])
  OpaqueHost(String)
} derive(Eq, Debug)

///|
pub suberror HostParseError {
  HostParseError(String)
}

///|
pub impl Show for HostParseError with fn output(self, logger) {
  match self {
    HostParseError(msg) => logger.write_string("HostParseError: " + msg)
  }
}

///|
pub fn Host::empty_domain() -> Host {
  Domain("")
}

///|
pub fn serialize_host(host : Host) -> String {
  match host {
    Domain(s) => s
    Ipv4(addr) => serialize_ipv4(addr)
    Ipv6(pieces) => "[" + serialize_ipv6(pieces) + "]"
    OpaqueHost(s) => s
  }
}

///|
fn serialize_ipv4(addr : UInt) -> String {
  let n1 = (addr >> 24) & 0xFFU
  let n2 = (addr >> 16) & 0xFFU
  let n3 = (addr >> 8) & 0xFFU
  let n4 = addr & 0xFFU
  "\{n1}.\{n2}.\{n3}.\{n4}"
}

///|
fn nibble_to_lower_hex(n : Int) -> Char {
  if n < 10 {
    Int::unsafe_to_char('0'.to_int() + n)
  } else {
    Int::unsafe_to_char('a'.to_int() + n - 10)
  }
}

///|
fn uint_to_lower_hex(n : UInt) -> String {
  if n == 0U {
    return "0"
  }
  let chars : Array[Char] = []
  let mut val = n
  while val > 0U {
    let idx = val.reinterpret_as_int() & 0xF
    chars.push(nibble_to_lower_hex(idx))
    val = val >> 4
  }
  let buf = StringBuilder::new()
  for i = chars.length() - 1; i >= 0; i = i - 1 {
    buf.write_char(chars[i])
  }
  buf.to_string()
}

///|
fn find_ipv6_compress(pieces : Array[UInt]) -> Int? {
  let mut best_start : Int? = None
  let mut best_len = 1
  let mut cur_start : Int? = None
  let mut cur_len = 0
  for i = 0; i < 8; i = i + 1 {
    if pieces[i] == 0U {
      if cur_start is None {
        cur_start = Some(i)
        cur_len = 1
      } else {
        cur_len = cur_len + 1
      }
      if cur_len > best_len {
        best_len = cur_len
        best_start = cur_start
      }
    } else {
      cur_start = None
      cur_len = 0
    }
  }
  best_start
}

///|
fn serialize_ipv6(pieces : Array[UInt]) -> String {
  let buf = StringBuilder::new()
  let compress = find_ipv6_compress(pieces)
  let mut ignore0 = false
  for i = 0; i < 8; i = i + 1 {
    if ignore0 && pieces[i] == 0U {
      continue
    }
    if ignore0 {
      ignore0 = false
    }
    if compress == Some(i) {
      let sep = if i == 0 { "::" } else { ":" }
      buf.write_string(sep)
      ignore0 = true
      continue
    }
    buf.write_string(uint_to_lower_hex(pieces[i]))
    if i != 7 {
      buf.write_char(':')
    }
  }
  buf.to_string()
}

///|
pub fn parse_host(
  input : String,
  is_special : Bool,
) -> Host raise HostParseError {
  if input.is_empty() {
    if is_special {
      raise HostParseError("empty host for special URL")
    }
    return Host::Domain("")
  }
  if input.has_prefix("[") {
    if !input.has_suffix("]") {
      raise HostParseError("invalid IPv6: missing closing bracket")
    }
    let inner = input[1:input.length() - 1].to_owned()
    let pieces = parse_ipv6(inner)
    return Host::Ipv6(pieces)
  }
  if !is_special {
    let h = parse_opaque_host(input)
    return h
  }
  let domain = @pe.percent_decode(input)
  let ascii_domain = @idna.domain_to_ascii(domain) catch {
    @idna.IdnaParseError(msg) => raise HostParseError(msg)
  }
  if domain_has_forbidden_char(ascii_domain) {
    raise HostParseError("domain has forbidden host code point")
  }
  if ends_in_number(ascii_domain) {
    let addr = parse_ipv4(ascii_domain)
    return Host::Ipv4(addr)
  }
  Host::Domain(ascii_domain)
}

///|
fn parse_opaque_host(input : String) -> Host raise HostParseError {
  for c in input {
    let cp = c.to_int()
    if is_forbidden_host_cp(cp) && cp != '%'.to_int() {
      raise HostParseError("opaque host has forbidden code point")
    }
  }
  Host::OpaqueHost(@pe.percent_encode_opaque_path(input))
}

///|
fn is_forbidden_host_cp(cp : Int) -> Bool {
  cp == 0x00 ||
  cp == 0x09 ||
  cp == 0x0A ||
  cp == 0x0D ||
  cp == 0x20 ||
  cp == '#'.to_int() ||
  cp == '/'.to_int() ||
  cp == ':'.to_int() ||
  cp == '<'.to_int() ||
  cp == '>'.to_int() ||
  cp == '?'.to_int() ||
  cp == '@'.to_int() ||
  cp == '['.to_int() ||
  cp == '\\'.to_int() ||
  cp == ']'.to_int() ||
  cp == '^'.to_int() ||
  cp == '|'.to_int()
}

///|
fn is_unicode_nonchar(cp : Int) -> Bool {
  (cp >= 0xFDD0 && cp <= 0xFDEF) ||
  (cp & 0xFFFF) == 0xFFFE ||
  (cp & 0xFFFF) == 0xFFFF
}

///|
fn domain_has_forbidden_char(domain : String) -> Bool {
  for c in domain {
    let cp = c.to_int()
    if cp <= 0x1F || cp == 0x7F {
      return true
    }
    if is_forbidden_host_cp(cp) {
      return true
    }
    if cp == 0x25 {
      return true
    }
    if cp == 0xFFFD || is_unicode_nonchar(cp) {
      return true
    }
    if cp == 0x00A0 || cp == 0x3000 {
      return true
    }
  }
  false
}

///|
fn all_decimal_digits(chars : Array[Char]) -> Bool {
  for c in chars {
    if c < '0' || c > '9' {
      return false
    }
  }
  true
}

///|
fn all_hex_digits_from(chars : Array[Char], from : Int) -> Bool {
  for i = from; i < chars.length(); i = i + 1 {
    if @pe.hex_digit_value(chars[i]) == None {
      return false
    }
  }
  true
}

///|
fn strip_trailing_dot(s : String) -> String {
  if s.has_suffix(".") {
    s[0:s.length() - 1].to_owned()
  } else {
    s
  }
}

///|
fn ends_in_number(input : String) -> Bool {
  let effective = strip_trailing_dot(input)
  let last_label = match effective.rev_find(".") {
    Some(pos) => effective[pos + 1:].to_owned()
    None => effective
  }
  if last_label.is_empty() {
    return false
  }
  let label_chars : Array[Char] = []
  for c in last_label {
    label_chars.push(c)
  }
  let n = label_chars.length()
  if all_decimal_digits(label_chars) {
    return true
  }
  if n >= 2 &&
    label_chars[0] == '0' &&
    (label_chars[1] == 'x' || label_chars[1] == 'X') {
    return all_hex_digits_from(label_chars, 2)
  }
  false
}

///|
fn split_on_char(s : String, sep : Char) -> Array[String] {
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
fn parse_ipv4(input : String) -> UInt raise HostParseError {
  let effective = strip_trailing_dot(input)
  let parts = split_on_char(effective, '.')
  let n_parts = parts.length()
  if n_parts == 0 || n_parts > 4 {
    raise HostParseError("invalid IPv4: bad number of parts")
  }
  let numbers : Array[UInt] = []
  for part in parts {
    if part.is_empty() {
      raise HostParseError("invalid IPv4: empty part")
    }
    let n = parse_ipv4_number(part)
    numbers.push(n)
  }
  if n_parts == 4 {
    for num in numbers {
      if num > 255U {
        raise HostParseError("invalid IPv4: octet > 255")
      }
    }
    return (numbers[0] << 24) |
      (numbers[1] << 16) |
      (numbers[2] << 8) |
      numbers[3]
  }
  let last = numbers[n_parts - 1]
  let max_last : UInt = if n_parts == 1 {
    0xFFFFFFFFU
  } else if n_parts == 2 {
    0xFFFFFFU
  } else {
    0xFFFFU
  }
  if last > max_last {
    raise HostParseError("invalid IPv4: last part too large")
  }
  let mut addr = last
  for i = 0; i < n_parts - 1; i = i + 1 {
    let octet = numbers[i]
    if octet > 255U {
      raise HostParseError("invalid IPv4: octet > 255")
    }
    let shift = (3 - i) * 8
    addr = addr | (octet << shift)
  }
  addr
}

///|
fn parse_ipv4_number(input : String) -> UInt raise HostParseError {
  let n = input.length()
  let val : UInt64 = if n >= 2 {
    let c0 = input.get_char(0)
    let c1 = input.get_char(1)
    if c0 == Some('0') && (c1 == Some('x') || c1 == Some('X')) {
      let hex_str = input[2:].to_owned()
      if hex_str.is_empty() {
        0UL
      } else {
        parse_hex_u64(hex_str)
      }
    } else if c0 == Some('0') {
      parse_octal_u64(input[1:].to_owned())
    } else {
      parse_decimal_u64(input)
    }
  } else {
    parse_decimal_u64(input)
  }
  if val >= 0x1_0000_0000UL {
    raise HostParseError("IPv4 number >= 2^32")
  }
  val.to_uint()
}

///|
fn parse_decimal_u64(input : String) -> UInt64 raise HostParseError {
  let mut result = 0UL
  let cap = 0x1_0000_0000UL
  for c in input {
    if c < '0' || c > '9' {
      raise HostParseError("invalid decimal digit")
    }
    let digit = (c.to_int() - '0'.to_int()).to_uint64()
    if result <= cap {
      let next = result * 10UL + digit
      result = if next > cap { cap + 1UL } else { next }
    }
  }
  result
}

///|
fn parse_hex_u64(input : String) -> UInt64 raise HostParseError {
  let mut result = 0UL
  let cap = 0x1_0000_0000UL
  for c in input {
    match @pe.hex_digit_value(c) {
      Some(v) =>
        if result <= cap {
          let next = (result << 4) | v.to_uint64()
          result = if next > cap { cap + 1UL } else { next }
        }
      None => raise HostParseError("invalid hex digit")
    }
  }
  result
}

///|
fn parse_octal_u64(input : String) -> UInt64 raise HostParseError {
  let mut result = 0UL
  let cap = 0x1_0000_0000UL
  for c in input {
    if c < '0' || c > '7' {
      raise HostParseError("invalid octal digit")
    }
    let digit = (c.to_int() - '0'.to_int()).to_uint64()
    if result <= cap {
      let next = result * 8UL + digit
      result = if next > cap { cap + 1UL } else { next }
    }
  }
  result
}

///|
fn parse_ipv6(input : String) -> Array[UInt] raise HostParseError {
  let pieces : Array[UInt] = [0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U]
  let mut piece_index = 0
  let mut compress : Int? = None
  let chars : Array[Char] = []
  for c in input {
    chars.push(c)
  }
  let n = chars.length()
  let mut pointer = 0
  if pointer < n && chars[pointer] == ':' {
    if pointer + 1 >= n || chars[pointer + 1] != ':' {
      raise HostParseError("invalid IPv6: single leading colon")
    }
    pointer = pointer + 2
    piece_index = piece_index + 1
    compress = Some(piece_index)
  }
  while pointer < n {
    if piece_index == 8 {
      raise HostParseError("invalid IPv6: too many pieces")
    }
    if chars[pointer] == ':' {
      if compress != None {
        raise HostParseError("invalid IPv6: multiple compressions")
      }
      pointer = pointer + 1
      piece_index = piece_index + 1
      compress = Some(piece_index)
      continue
    }
    let mut value = 0U
    let mut length = 0
    while length < 4 && pointer < n {
      match @pe.hex_digit_value(chars[pointer]) {
        Some(v) => {
          value = (value << 4) | v.reinterpret_as_uint()
          pointer = pointer + 1
          length = length + 1
        }
        None => break
      }
    }
    if pointer < n && chars[pointer] == '.' {
      if length == 0 {
        raise HostParseError("invalid IPv6: bad IPv4 in IPv6")
      }
      pointer = pointer - length
      if piece_index > 6 {
        raise HostParseError("invalid IPv6: IPv4 part overflows")
      }
      let mut numbers_seen = 0
      while pointer < n {
        let mut ipv4_piece : UInt? = None
        if numbers_seen > 0 {
          if chars[pointer] != '.' {
            raise HostParseError("invalid IPv6: expected dot in IPv4")
          }
          pointer = pointer + 1
        }
        if pointer >= n || chars[pointer] < '0' || chars[pointer] > '9' {
          raise HostParseError("invalid IPv6: expected digit in IPv4")
        }
        while pointer < n && chars[pointer] >= '0' && chars[pointer] <= '9' {
          let digit = (chars[pointer].to_int() - '0'.to_int()).reinterpret_as_uint()
          ipv4_piece = match ipv4_piece {
            None => Some(digit)
            Some(v) => {
              if v == 0U {
                raise HostParseError("invalid IPv6: leading zero in IPv4")
              }
              let new_val = v * 10U + digit
              if new_val > 255U {
                raise HostParseError("invalid IPv6: IPv4 octet > 255")
              }
              Some(new_val)
            }
          }
          pointer = pointer + 1
        }
        let p = match ipv4_piece {
          Some(v) => v
          None => panic()
        }
        pieces[piece_index] = pieces[piece_index] * 0x100U + p
        numbers_seen = numbers_seen + 1
        if numbers_seen == 2 || numbers_seen == 4 {
          piece_index = piece_index + 1
        }
      }
      if numbers_seen != 4 {
        raise HostParseError("invalid IPv6: IPv4 must have 4 parts")
      }
      break
    }
    pieces[piece_index] = value
    piece_index = piece_index + 1
    if pointer < n {
      if chars[pointer] != ':' {
        raise HostParseError("invalid IPv6: expected colon")
      }
      pointer = pointer + 1
    }
  }
  match compress {
    Some(c) => {
      let mut swaps = piece_index - c
      let mut pi = 7
      while pi != 0 && swaps > 0 {
        let tmp = pieces[pi]
        pieces[pi] = pieces[c + swaps - 1]
        pieces[c + swaps - 1] = tmp
        pi = pi - 1
        swaps = swaps - 1
      }
    }
    None =>
      if piece_index != 8 {
        raise HostParseError("invalid IPv6: too few pieces")
      }
  }
  pieces
}
