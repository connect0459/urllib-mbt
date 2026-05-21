///|
fn is_c0(cp : Int) -> Bool {
  cp <= 0x1F || cp > 0x7E
}

///|
fn in_fragment_set(cp : Int) -> Bool {
  is_c0(cp) ||
  cp == 0x20 ||
  cp == 0x22 ||
  cp == 0x3C ||
  cp == 0x3E ||
  cp == 0x60
}

///|
fn in_query_set(cp : Int) -> Bool {
  is_c0(cp) ||
  cp == 0x20 ||
  cp == 0x22 ||
  cp == 0x23 ||
  cp == 0x3C ||
  cp == 0x3E
}

///|
fn in_special_query_set(cp : Int) -> Bool {
  in_query_set(cp) || cp == 0x27
}

///|
fn in_path_set(cp : Int) -> Bool {
  in_query_set(cp) ||
  cp == 0x3F ||
  cp == 0x5E ||
  cp == 0x60 ||
  cp == 0x7B ||
  cp == 0x7D
}

///|
fn in_userinfo_set(cp : Int) -> Bool {
  in_path_set(cp) ||
  cp == 0x2F ||
  cp == 0x3A ||
  cp == 0x3B ||
  cp == 0x3D ||
  cp == 0x40 ||
  (cp >= 0x5B && cp <= 0x5E) ||
  cp == 0x7C
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
fn percent_encode_byte(byte : Int) -> String {
  let hi = (byte >> 4) & 0xF
  let lo = byte & 0xF
  let buf = StringBuilder::new(size_hint=3)
  buf.write_char('%')
  buf.write_char(to_hex_upper(hi))
  buf.write_char(to_hex_upper(lo))
  buf.to_string()
}

///|
fn char_to_utf8_bytes(c : Char) -> Array[Int] {
  let cp = c.to_int()
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
fn percent_encode(input : String, in_encode_set : (Int) -> Bool) -> String {
  let buf = StringBuilder::new()
  for c in input {
    let cp = c.to_int()
    if in_encode_set(cp) {
      for byte in char_to_utf8_bytes(c) {
        buf.write_string(percent_encode_byte(byte))
      }
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
fn percent_encode_fragment(input : String) -> String {
  percent_encode(input, in_fragment_set)
}

///|
fn percent_encode_query(input : String, is_special : Bool) -> String {
  if is_special {
    percent_encode(input, in_special_query_set)
  } else {
    percent_encode(input, in_query_set)
  }
}

///|
fn percent_encode_path_seg(input : String) -> String {
  percent_encode(input, in_path_set)
}

///|
fn percent_encode_userinfo(input : String) -> String {
  percent_encode(input, in_userinfo_set)
}

///|
fn percent_encode_opaque_path(input : String) -> String {
  percent_encode(input, is_c0)
}

///|
fn percent_encode_opaque_path_at_stop(input : String) -> String {
  let n = input.length()
  if n > 0 {
    let last = input.get_char(n - 1).unwrap_or('\u{0000}')
    if last == ' ' {
      let prefix = input[0:n - 1].to_owned()
      percent_encode(prefix, is_c0) + "%20"
    } else {
      percent_encode(input, is_c0)
    }
  } else {
    ""
  }
}

///|
fn hex_digit_value(c : Char) -> Int? {
  let cp = c.to_int()
  if cp >= '0'.to_int() && cp <= '9'.to_int() {
    Some(cp - '0'.to_int())
  } else if cp >= 'A'.to_int() && cp <= 'F'.to_int() {
    Some(cp - 'A'.to_int() + 10)
  } else if cp >= 'a'.to_int() && cp <= 'f'.to_int() {
    Some(cp - 'a'.to_int() + 10)
  } else {
    None
  }
}

///|
fn percent_decode(input : String) -> String {
  let bytes : Array[Int] = []
  let chars : Array[Char] = []
  for c in input {
    chars.push(c)
  }
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
    for byte in char_to_utf8_bytes(c) {
      bytes.push(byte)
    }
    i = i + 1
  }
  utf8_bytes_to_string(bytes)
}

///|
fn utf8_bytes_to_string(bytes : Array[Int]) -> String {
  let buf = StringBuilder::new()
  let n = bytes.length()
  let mut i = 0
  while i < n {
    let b = bytes[i]
    let (cp, advance) = if (b & 0x80) == 0 {
      (b, 1)
    } else if (b & 0xE0) == 0xC0 && i + 1 < n {
      (((b & 0x1F) << 6) | (bytes[i + 1] & 0x3F), 2)
    } else if (b & 0xF0) == 0xE0 && i + 2 < n {
      let cp = ((b & 0x0F) << 12) |
        ((bytes[i + 1] & 0x3F) << 6) |
        (bytes[i + 2] & 0x3F)
      (cp, 3)
    } else if (b & 0xF8) == 0xF0 && i + 3 < n {
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
