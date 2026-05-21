///|
let punycode_base : Int = 36

///|
let punycode_tmin : Int = 1

///|
let punycode_tmax : Int = 26

///|
let punycode_skew : Int = 38

///|
let punycode_damp : Int = 700

///|
let punycode_initial_bias : Int = 72

///|
let punycode_initial_n : Int = 128

///|
fn punycode_adapt(delta : Int, numpoints : Int, firsttime : Bool) -> Int {
  let mut d = if firsttime { delta / punycode_damp } else { delta >> 1 }
  d = d + d / numpoints
  let mut k = 0
  while d > (punycode_base - punycode_tmin) * punycode_tmax / 2 {
    d = d / (punycode_base - punycode_tmin)
    k = k + punycode_base
  }
  k + (punycode_base - punycode_tmin + 1) * d / (d + punycode_skew)
}

///|
fn punycode_digit_value(c : Char) -> Int raise UrlParseError {
  let cp = c.to_int()
  if cp >= 'a'.to_int() && cp <= 'z'.to_int() {
    return cp - 'a'.to_int()
  }
  if cp >= 'A'.to_int() && cp <= 'Z'.to_int() {
    return cp - 'A'.to_int()
  }
  if cp >= '0'.to_int() && cp <= '9'.to_int() {
    return cp - '0'.to_int() + 26
  }
  raise UrlParseError("invalid punycode digit")
}

///|
fn punycode_digit_to_char(d : Int) -> Char {
  if d < 26 {
    Int::unsafe_to_char('a'.to_int() + d)
  } else {
    Int::unsafe_to_char('0'.to_int() + d - 26)
  }
}

///|
fn punycode_array_insert(arr : Array[Int], pos : Int, val : Int) -> Unit {
  arr.push(val)
  let n = arr.length()
  let mut j = n - 1
  while j > pos {
    arr[j] = arr[j - 1]
    j = j - 1
  }
  arr[pos] = val
}

///|
fn punycode_decode(input : String) -> Array[Int] raise UrlParseError {
  let chars : Array[Char] = []
  for c in input {
    chars.push(c)
  }
  let n_input = chars.length()
  if n_input == 0 {
    raise UrlParseError("punycode: empty input")
  }
  let output : Array[Int] = []
  let mut n = punycode_initial_n
  let mut i = 0
  let mut bias = punycode_initial_bias
  let mut basic_end = -1
  for idx = 0; idx < n_input; idx = idx + 1 {
    if chars[idx] == '-' {
      basic_end = idx
    }
  }
  let copy_end = if basic_end > 0 { basic_end } else { 0 }
  for idx = 0; idx < copy_end; idx = idx + 1 {
    let cp = chars[idx].to_int()
    if cp > 0x7E {
      raise UrlParseError("punycode: non-ASCII before delimiter")
    }
    output.push(cp)
  }
  let mut in_pos = if basic_end >= 0 { basic_end + 1 } else { 0 }
  while in_pos < n_input {
    let oldi = i
    let mut w = 1
    let mut k = punycode_base
    while true {
      if in_pos >= n_input {
        raise UrlParseError("punycode: unexpected end")
      }
      let digit = punycode_digit_value(chars[in_pos])
      in_pos = in_pos + 1
      i = i + digit * w
      let t = if k <= bias + punycode_tmin {
        punycode_tmin
      } else if k >= bias + punycode_tmax {
        punycode_tmax
      } else {
        k - bias
      }
      if digit < t {
        break
      }
      w = w * (punycode_base - t)
      k = k + punycode_base
    }
    let out_plus1 = output.length() + 1
    bias = punycode_adapt(i - oldi, out_plus1, oldi == 0)
    let dn = i / out_plus1
    if n > 0x10FFFF - dn {
      raise UrlParseError("punycode: code point overflow")
    }
    n = n + dn
    i = i % out_plus1
    if n >= 0xD800 && n <= 0xDFFF {
      raise UrlParseError("punycode: surrogate code point")
    }
    punycode_array_insert(output, i, n)
    i = i + 1
  }
  output
}

///|
fn punycode_encode(input : Array[Int]) -> String raise UrlParseError {
  let total = input.length()
  if total == 0 {
    raise UrlParseError("punycode: empty input")
  }
  let buf = StringBuilder::new()
  let mut n = punycode_initial_n
  let mut delta = 0
  let mut bias = punycode_initial_bias
  let mut basic_count = 0
  for cp in input {
    if cp < 0x80 {
      buf.write_char(Int::unsafe_to_char(cp))
      basic_count = basic_count + 1
    }
  }
  let mut handled = basic_count
  if basic_count > 0 {
    buf.write_char('-')
  }
  while handled < total {
    let mut m = 0x110000
    for cp in input {
      if cp >= n && cp < m {
        m = cp
      }
    }
    delta = delta + (m - n) * (handled + 1)
    n = m
    for cp in input {
      if cp < n {
        delta = delta + 1
      }
      if cp == n {
        let mut q = delta
        let mut k = punycode_base
        while true {
          let t = if k <= bias + punycode_tmin {
            punycode_tmin
          } else if k >= bias + punycode_tmax {
            punycode_tmax
          } else {
            k - bias
          }
          if q < t {
            break
          }
          buf.write_char(
            punycode_digit_to_char(t + (q - t) % (punycode_base - t)),
          )
          q = (q - t) / (punycode_base - t)
          k = k + punycode_base
        }
        buf.write_char(punycode_digit_to_char(q))
        bias = punycode_adapt(delta, handled + 1, handled == basic_count)
        delta = 0
        handled = handled + 1
      }
    }
    delta = delta + 1
    n = n + 1
  }
  buf.to_string()
}
