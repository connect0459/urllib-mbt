///|
pub struct UrlSearchParams {
  mut list : Array[(String, String)]
}

///|
pub fn UrlSearchParams::new() -> UrlSearchParams {
  { list: [] }
}

///|
fn parse_urlencoded(s : String) -> UrlSearchParams {
  let list : Array[(String, String)] = []
  for seq in s.split("&") {
    if seq == "" {
      continue
    }
    let seq_str = seq.to_owned()
    let eq_pos = seq_str.find("=")
    let (raw_name, raw_value) = match eq_pos {
      Some(pos) => (seq_str[0:pos].to_owned(), seq_str[pos + 1:].to_owned())
      None => (seq_str, "")
    }
    let name = url_form_decode(raw_name)
    let value = url_form_decode(raw_value)
    list.push((name, value))
  }
  { list, }
}

///|
pub fn UrlSearchParams::from_string(s : String) -> UrlSearchParams {
  let input = if s.length() > 0 && s.get_char(0) == Some('?') {
    s[1:].to_owned()
  } else {
    s
  }
  parse_urlencoded(input)
}

///|
pub fn UrlSearchParams::append(
  self : UrlSearchParams,
  name : String,
  value : String,
) -> Unit {
  self.list.push((name, value))
}

///|
pub fn UrlSearchParams::delete(self : UrlSearchParams, name : String) -> Unit {
  self.list = self.list.filter(fn(pair) { pair.0 != name })
}

///|
pub fn UrlSearchParams::delete_entry(
  self : UrlSearchParams,
  name : String,
  value : String,
) -> Unit {
  self.list = self.list.filter(fn(pair) { pair.0 != name || pair.1 != value })
}

///|
pub fn UrlSearchParams::get(self : UrlSearchParams, name : String) -> String? {
  for pair in self.list {
    if pair.0 == name {
      return Some(pair.1)
    }
  }
  None
}

///|
pub fn UrlSearchParams::get_all(
  self : UrlSearchParams,
  name : String,
) -> Array[String] {
  self.list.filter_map(fn(pair) {
    if pair.0 == name {
      Some(pair.1)
    } else {
      None
    }
  })
}

///|
pub fn UrlSearchParams::has(self : UrlSearchParams, name : String) -> Bool {
  self.list.any(fn(pair) { pair.0 == name })
}

///|
pub fn UrlSearchParams::has_entry(
  self : UrlSearchParams,
  name : String,
  value : String,
) -> Bool {
  self.list.any(fn(pair) { pair.0 == name && pair.1 == value })
}

///|
pub fn UrlSearchParams::set(
  self : UrlSearchParams,
  name : String,
  value : String,
) -> Unit {
  let mut found = false
  let new_list : Array[(String, String)] = []
  for pair in self.list {
    if pair.0 == name {
      if !found {
        new_list.push((name, value))
        found = true
      }
    } else {
      new_list.push(pair)
    }
  }
  if !found {
    new_list.push((name, value))
  }
  self.list = new_list
}

///|
pub fn UrlSearchParams::sort(self : UrlSearchParams) -> Unit {
  self.list.sort_by(fn(a, b) { compare_utf16(a.0, b.0) })
}

///|
pub fn UrlSearchParams::size(self : UrlSearchParams) -> Int {
  self.list.length()
}

///|
pub fn UrlSearchParams::to_string(self : UrlSearchParams) -> String {
  let parts : Array[String] = []
  for pair in self.list {
    let encoded_name = url_form_encode(pair.0)
    let encoded_value = url_form_encode(pair.1)
    parts.push(encoded_name + "=" + encoded_value)
  }
  parts.join("&")
}

///|
pub fn UrlSearchParams::iter(self : UrlSearchParams) -> Iter[(String, String)] {
  self.list.iter()
}

///|
pub fn UrlSearchParams::for_each(
  self : UrlSearchParams,
  f : (String, String) -> Unit,
) -> Unit {
  for pair in self.list {
    f(pair.0, pair.1)
  }
}

///|
fn url_form_decode(s : String) -> String {
  let chars : Array[Char] = []
  for c in s {
    chars.push(c)
  }
  let bytes : Array[Int] = []
  let n = chars.length()
  let mut i = 0
  while i < n {
    let c = chars[i]
    if c == '+' {
      bytes.push(0x20)
      i = i + 1
    } else if c == '%' && i + 2 < n {
      let hi = @pe.hex_digit_value(chars[i + 1])
      let lo = @pe.hex_digit_value(chars[i + 2])
      match (hi, lo) {
        (Some(h), Some(l)) => {
          bytes.push(h * 16 + l)
          i = i + 3
        }
        _ => {
          for byte in @pe.char_to_utf8_bytes(c) {
            bytes.push(byte)
          }
          i = i + 1
        }
      }
    } else {
      for byte in @pe.char_to_utf8_bytes(c) {
        bytes.push(byte)
      }
      i = i + 1
    }
  }
  @pe.utf8_bytes_to_string(bytes)
}

///|
fn url_form_encode(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    let cp = c.to_int()
    if cp == 0x20 {
      buf.write_char('+')
    } else if is_url_form_safe(cp) {
      buf.write_char(c)
    } else {
      for byte in @pe.char_to_utf8_bytes(c) {
        buf.write_string(@pe.percent_encode_byte(byte))
      }
    }
  }
  buf.to_string()
}

///|
fn is_url_form_safe(cp : Int) -> Bool {
  (cp >= 0x30 && cp <= 0x39) ||
  (cp >= 0x41 && cp <= 0x5A) ||
  (cp >= 0x61 && cp <= 0x7A) ||
  cp == 0x2A ||
  cp == 0x2D ||
  cp == 0x2E ||
  cp == 0x5F
}

///|
fn char_to_utf16(c : Char) -> Array[Int] {
  let cp = c.to_int()
  if cp <= 0xFFFF {
    [cp]
  } else {
    let adj = cp - 0x10000
    let high = 0xD800 + (adj >> 10)
    let low = 0xDC00 + (adj & 0x3FF)
    [high, low]
  }
}

///|
fn string_to_utf16_units(s : String) -> Array[Int] {
  let result : Array[Int] = []
  for c in s {
    for unit in char_to_utf16(c) {
      result.push(unit)
    }
  }
  result
}

///|
fn compare_utf16(a : String, b : String) -> Int {
  let ua = string_to_utf16_units(a)
  let ub = string_to_utf16_units(b)
  let la = ua.length()
  let lb = ub.length()
  let len = if la < lb { la } else { lb }
  let mut i = 0
  while i < len {
    let diff = ua[i] - ub[i]
    if diff != 0 {
      return diff
    }
    i = i + 1
  }
  ua.length() - ub.length()
}
