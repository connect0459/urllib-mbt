///|
fn serialize_host(host : Host) -> String {
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
  let mut cur_start = -1
  let mut cur_len = 0
  for i = 0; i < 8; i = i + 1 {
    if pieces[i] == 0U {
      if cur_start == -1 {
        cur_start = i
        cur_len = 1
      } else {
        cur_len = cur_len + 1
      }
      if cur_len > best_len {
        best_len = cur_len
        best_start = Some(cur_start)
      }
    } else {
      cur_start = -1
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
fn parse_host(input : String, is_special : Bool) -> Host raise UrlParseError {
  if input.is_empty() {
    if is_special {
      raise UrlParseError("empty host for special URL")
    }
    return Host::Domain("")
  }
  if input.has_prefix("[") {
    if !input.has_suffix("]") {
      raise UrlParseError("invalid IPv6: missing closing bracket")
    }
    let inner = input[1:input.length() - 1].to_owned()
    let pieces = parse_ipv6(inner)
    return Host::Ipv6(pieces)
  }
  if !is_special {
    let h = parse_opaque_host(input)
    return h
  }
  let domain = percent_decode(input)
  let ascii_domain = domain_to_ascii(domain)
  if domain_has_forbidden_char(ascii_domain) {
    raise UrlParseError("domain has forbidden host code point")
  }
  if ends_in_number(ascii_domain) {
    let addr = parse_ipv4(ascii_domain)
    return Host::Ipv4(addr)
  }
  Host::Domain(ascii_domain)
}

///|
fn parse_opaque_host(input : String) -> Host raise UrlParseError {
  for c in input {
    let cp = c.to_int()
    if is_forbidden_host_cp(cp) && cp != '%'.to_int() {
      raise UrlParseError("opaque host has forbidden code point")
    }
  }
  Host::OpaqueHost(percent_encode(input, fn(cp) { is_c0(cp) }))
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
fn domain_to_ascii(domain : String) -> String raise UrlParseError {
  if domain.is_empty() {
    raise UrlParseError("empty domain")
  }
  let buf = StringBuilder::new()
  for c in domain {
    let cp = c.to_int()
    if cp == 0x00AD || cp == 0x200B || cp == 0x2060 || cp == 0xFEFF {
      continue
    } else if cp == 0x3002 {
      buf.write_char('.')
    } else {
      let mapped = if cp >= 0xFF01 && cp <= 0xFF5E {
        cp - 0xFEE0
      } else if cp >= 0x1D400 && cp <= 0x1D419 {
        cp - 0x1D400 + 0x41
      } else if cp >= 0x1D41A && cp <= 0x1D433 {
        cp - 0x1D41A + 0x61
      } else {
        cp
      }
      if mapped >= 0x41 && mapped <= 0x5A {
        buf.write_char(Int::unsafe_to_char(mapped + 32))
      } else {
        buf.write_char(Int::unsafe_to_char(mapped))
      }
    }
  }
  let result = buf.to_string()
  if result.is_empty() {
    raise UrlParseError("empty domain")
  }
  result
}

///|
fn domain_has_forbidden_char(domain : String) -> Bool {
  for c in domain {
    if is_forbidden_host_cp(c.to_int()) {
      return true
    }
  }
  false
}

///|
fn ends_in_number(input : String) -> Bool {
  if input.is_empty() {
    return false
  }
  let effective = if input.has_suffix(".") {
    input[0:input.length() - 1].to_owned()
  } else {
    input
  }
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
  if n == 0 {
    return false
  }
  let mut all_decimal = true
  for c in label_chars {
    if c < '0' || c > '9' {
      all_decimal = false
    }
  }
  if all_decimal {
    return true
  }
  if n >= 2 &&
    label_chars[0] == '0' &&
    (label_chars[1] == 'x' || label_chars[1] == 'X') {
    let mut all_hex = true
    for i = 2; i < n; i = i + 1 {
      if hex_digit_value(label_chars[i]) == None {
        all_hex = false
      }
    }
    return all_hex
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
fn parse_ipv4(input : String) -> UInt raise UrlParseError {
  let effective = if input.has_suffix(".") {
    input[0:input.length() - 1].to_owned()
  } else {
    input
  }
  let parts = split_on_char(effective, '.')
  let n_parts = parts.length()
  if n_parts == 0 || n_parts > 4 {
    raise UrlParseError("invalid IPv4: bad number of parts")
  }
  let numbers : Array[UInt] = []
  for part in parts {
    if part.is_empty() {
      raise UrlParseError("invalid IPv4: empty part")
    }
    let n = parse_ipv4_number(part)
    numbers.push(n)
  }
  if n_parts == 4 {
    for num in numbers {
      if num > 255U {
        raise UrlParseError("invalid IPv4: octet > 255")
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
  } else if n_parts == 3 {
    0xFFFFU
  } else {
    raise UrlParseError("invalid IPv4")
  }
  if last > max_last {
    raise UrlParseError("invalid IPv4: last part too large")
  }
  let mut addr = last
  for i = 0; i < n_parts - 1; i = i + 1 {
    let octet = numbers[i]
    if octet > 255U {
      raise UrlParseError("invalid IPv4: octet > 255")
    }
    let shift = (3 - i) * 8
    addr = addr | (octet << shift)
  }
  addr
}

///|
fn parse_ipv4_number(input : String) -> UInt raise UrlParseError {
  let n = input.length()
  if n == 0 {
    raise UrlParseError("empty IPv4 number")
  }
  if n >= 2 {
    let c0 = input.get_char(0)
    let c1 = input.get_char(1)
    if c0 == Some('0') && (c1 == Some('x') || c1 == Some('X')) {
      let hex_str = input[2:].to_owned()
      if hex_str.is_empty() {
        return 0U
      }
      return parse_hex_uint(hex_str)
    }
    if c0 == Some('0') {
      return parse_octal_uint(input[1:].to_owned())
    }
  }
  parse_decimal_uint(input)
}

///|
fn parse_decimal_uint(input : String) -> UInt raise UrlParseError {
  let mut result = 0U
  for c in input {
    if c < '0' || c > '9' {
      raise UrlParseError("invalid decimal digit")
    }
    let digit = (c.to_int() - '0'.to_int()).reinterpret_as_uint()
    result = result * 10U + digit
  }
  result
}

///|
fn parse_hex_uint(input : String) -> UInt raise UrlParseError {
  let mut result = 0U
  for c in input {
    match hex_digit_value(c) {
      Some(v) => result = (result << 4) | v.reinterpret_as_uint()
      None => raise UrlParseError("invalid hex digit")
    }
  }
  result
}

///|
fn parse_octal_uint(input : String) -> UInt raise UrlParseError {
  let mut result = 0U
  for c in input {
    if c < '0' || c > '7' {
      raise UrlParseError("invalid octal digit")
    }
    let digit = (c.to_int() - '0'.to_int()).reinterpret_as_uint()
    result = result * 8U + digit
  }
  result
}

///|
fn parse_ipv6(input : String) -> Array[UInt] raise UrlParseError {
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
      raise UrlParseError("invalid IPv6: single leading colon")
    }
    pointer = pointer + 2
    piece_index = piece_index + 1
    compress = Some(piece_index)
  }
  while pointer < n {
    if piece_index == 8 {
      raise UrlParseError("invalid IPv6: too many pieces")
    }
    if chars[pointer] == ':' {
      if compress != None {
        raise UrlParseError("invalid IPv6: multiple compressions")
      }
      pointer = pointer + 1
      piece_index = piece_index + 1
      compress = Some(piece_index)
      continue
    }
    let mut value = 0U
    let mut length = 0
    while length < 4 && pointer < n {
      match hex_digit_value(chars[pointer]) {
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
        raise UrlParseError("invalid IPv6: bad IPv4 in IPv6")
      }
      pointer = pointer - length
      if piece_index > 6 {
        raise UrlParseError("invalid IPv6: IPv4 part overflows")
      }
      let mut numbers_seen = 0
      while pointer < n {
        let mut ipv4_piece : UInt? = None
        if numbers_seen > 0 {
          if chars[pointer] != '.' {
            raise UrlParseError("invalid IPv6: expected dot in IPv4")
          }
          pointer = pointer + 1
        }
        if pointer >= n || chars[pointer] < '0' || chars[pointer] > '9' {
          raise UrlParseError("invalid IPv6: expected digit in IPv4")
        }
        while pointer < n && chars[pointer] >= '0' && chars[pointer] <= '9' {
          let digit = (chars[pointer].to_int() - '0'.to_int()).reinterpret_as_uint()
          ipv4_piece = match ipv4_piece {
            None => Some(digit)
            Some(v) => {
              if v == 0U {
                raise UrlParseError("invalid IPv6: leading zero in IPv4")
              }
              let new_val = v * 10U + digit
              if new_val > 255U {
                raise UrlParseError("invalid IPv6: IPv4 octet > 255")
              }
              Some(new_val)
            }
          }
          pointer = pointer + 1
        }
        let p = match ipv4_piece {
          Some(v) => v
          None => raise UrlParseError("invalid IPv6: empty IPv4 octet")
        }
        pieces[piece_index] = pieces[piece_index] * 0x100U + p
        numbers_seen = numbers_seen + 1
        if numbers_seen == 2 || numbers_seen == 4 {
          piece_index = piece_index + 1
        }
      }
      if numbers_seen != 4 {
        raise UrlParseError("invalid IPv6: IPv4 must have 4 parts")
      }
      break
    }
    pieces[piece_index] = value
    piece_index = piece_index + 1
    if pointer < n {
      if chars[pointer] != ':' {
        raise UrlParseError("invalid IPv6: expected colon")
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
        raise UrlParseError("invalid IPv6: too few pieces")
      }
  }
  pieces
}
