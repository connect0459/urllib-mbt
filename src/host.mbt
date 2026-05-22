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
fn is_virama(cp : Int) -> Bool {
  cp == 0x094D ||
  cp == 0x09CD ||
  cp == 0x0A4D ||
  cp == 0x0ACD ||
  cp == 0x0B4D ||
  cp == 0x0BCD ||
  cp == 0x0C4D ||
  cp == 0x0CCD ||
  cp == 0x0D3B ||
  cp == 0x0D3C ||
  cp == 0x0D4D ||
  cp == 0x0DCA ||
  cp == 0x0E3A ||
  cp == 0x0F84 ||
  cp == 0x1039 ||
  cp == 0x103A ||
  cp == 0x1714 ||
  cp == 0x1734 ||
  cp == 0x17D2 ||
  cp == 0x1A60 ||
  cp == 0x1BAA ||
  cp == 0x1BAB ||
  cp == 0x2D7F ||
  cp == 0xA806 ||
  cp == 0xA8C4 ||
  cp == 0xA953 ||
  cp == 0xA9C0 ||
  cp == 0xAAF6 ||
  cp == 0xABED ||
  cp == 0x10A3F ||
  cp == 0x11134 ||
  cp == 0x111C0 ||
  cp == 0x11235 ||
  cp == 0x112EA ||
  cp == 0x1134D ||
  cp == 0x11442 ||
  cp == 0x114C2 ||
  cp == 0x115BF ||
  cp == 0x1163F ||
  cp == 0x116B6 ||
  cp == 0x11C3F
}

///|
fn is_arabic_script(cp : Int) -> Bool {
  cp >= 0x0600 && cp <= 0x06FF
}

///|
fn is_arabic_right_joining(cp : Int) -> Bool {
  cp == 0x0622 ||
  cp == 0x0623 ||
  cp == 0x0624 ||
  cp == 0x0625 ||
  cp == 0x0627 ||
  cp == 0x0629 ||
  cp == 0x062F ||
  cp == 0x0630 ||
  cp == 0x0631 ||
  cp == 0x0632 ||
  cp == 0x0648 ||
  cp == 0x0671 ||
  cp == 0x0672 ||
  cp == 0x0673 ||
  cp == 0x0675 ||
  cp == 0x0676 ||
  cp == 0x0677 ||
  (cp >= 0x0688 && cp <= 0x0699) ||
  (cp >= 0x06C4 && cp <= 0x06CF) ||
  cp == 0x06D2 ||
  cp == 0x06D3 ||
  cp == 0x06EE ||
  cp == 0x06EF
}

///|
fn is_arabic_nonjoining(cp : Int) -> Bool {
  // Arabic NSM (combining marks) and digits that don't participate in joining
  (cp >= 0x0610 && cp <= 0x061A) ||
  (cp >= 0x064B && cp <= 0x065F) ||
  cp == 0x0670 ||
  (cp >= 0x0660 && cp <= 0x0669) ||
  (cp >= 0x06F0 && cp <= 0x06F9) ||
  (cp >= 0x06D6 && cp <= 0x06DC) ||
  (cp >= 0x06DF && cp <= 0x06E4) ||
  cp == 0x06E7 ||
  cp == 0x06E8 ||
  (cp >= 0x06EA && cp <= 0x06ED)
}

///|
fn validate_contextj(cps : Array[Int]) -> Unit raise UrlParseError {
  for idx = 0; idx < cps.length(); idx = idx + 1 {
    let cp = cps[idx]
    if cp == 0x200D {
      // ZWJ: must immediately follow a virama
      if idx == 0 || !is_virama(cps[idx - 1]) {
        raise UrlParseError("ZWJ requires preceding virama")
      }
    } else if cp == 0x200C {
      // ZWNJ: RFC 5892 rule: valid after virama, or between (L|D)(T)* and (T)*(R|D)
      let allowed = if idx == 0 {
        false
      } else {
        let prev = cps[idx - 1]
        if is_virama(prev) {
          true
        } else {
          // Scan backwards through T-transparent (Arabic NSM/digits) to find L or D
          let mut back_idx = idx - 1
          while back_idx > 0 && is_arabic_nonjoining(cps[back_idx]) {
            back_idx = back_idx - 1
          }
          let back_cp = cps[back_idx]
          let prev_ok = is_arabic_script(back_cp) &&
            !is_arabic_right_joining(back_cp) &&
            !is_arabic_nonjoining(back_cp)
          if !prev_ok {
            false
          } else {
            // Scan forwards through T-transparent to find R or D
            let mut fwd_idx = idx + 1
            while fwd_idx < cps.length() && is_arabic_nonjoining(cps[fwd_idx]) {
              fwd_idx = fwd_idx + 1
            }
            fwd_idx < cps.length() &&
            is_arabic_script(cps[fwd_idx]) &&
            !is_arabic_nonjoining(cps[fwd_idx])
          }
        }
      }
      if !allowed {
        raise UrlParseError("ZWNJ requires virama or joining context")
      }
    }
  }
}

///|
fn validate_bidi(cps : Array[Int]) -> Unit raise UrlParseError {
  // RFC 5893 BiDi check: a label mixing R/AL chars with L chars is invalid.
  // Combining marks (NSM) inherit directionality and do not count as RTL or LTR.
  let mut has_rtl = false
  let mut has_ltr = false
  for cp in cps {
    if is_combining_mark_table(cp) {
      continue
    }
    if (cp >= 0x0590 && cp <= 0x05FF) || (cp >= 0x0700 && cp <= 0x074F) {
      has_rtl = true
    } else if is_arabic_script(cp) && !is_arabic_nonjoining(cp) {
      has_rtl = true
    } else if (cp >= 0x41 && cp <= 0x5A) ||
      (cp >= 0x61 && cp <= 0x7A) ||
      (cp >= 0x0370 && cp <= 0x03FF) ||
      (cp >= 0x0400 && cp <= 0x04FF) ||
      (cp >= 0x10A0 && cp <= 0x10FF) ||
      (cp >= 0x2D00 && cp <= 0x2D2F) ||
      (cp >= 0x3040 && cp <= 0x9FFF) ||
      (cp >= 0xAC00 && cp <= 0xD7A3) {
      has_ltr = true
    }
  }
  if has_rtl && has_ltr {
    raise UrlParseError("BIDI violation: label mixes RTL and LTR scripts")
  }
}

///|
fn nfc_compose(cps : Array[Int]) -> Array[Int] {
  if cps.length() <= 1 {
    return cps
  }
  let result : Array[Int] = []
  let mut i = 0
  while i < cps.length() {
    let mut cur = cps[i]
    let mut j = i + 1
    while j < cps.length() {
      let composed = try_nfc_compose(cur, cps[j])
      if composed >= 0 {
        cur = composed
        j = j + 1
      } else {
        break
      }
    }
    result.push(cur)
    i = j
  }
  result
}

///|
fn hangul_compose(l : Int, v : Int) -> Int {
  let s_base = 0xAC00
  let l_base = 0x1100
  let v_base = 0x1161
  let t_count = 28
  let n_count = 21 * t_count
  s_base + (l - l_base) * n_count + (v - v_base) * t_count
}

///|
fn try_nfc_compose(a : Int, b : Int) -> Int {
  // Hangul LV composition: Jamo L (U+1100-U+1112) + Jamo V (U+1161-U+1175)
  if a >= 0x1100 && a <= 0x1112 && b >= 0x1161 && b <= 0x1175 {
    return hangul_compose(a, b)
  }
  // Hangul LVT composition: LV syllable (T_index == 0) + Jamo T (U+11A8-U+11C2)
  if a >= 0xAC00 &&
    a <= 0xD7A3 &&
    (a - 0xAC00) % 28 == 0 &&
    b >= 0x11A8 &&
    b <= 0x11C2 {
    return a + (b - 0x11A7)
  }
  // Latin with combining marks
  if b == 0x0300 {
    if a == 0x0041 {
      return 0x00C0
    } // A + grave → À
    if a == 0x0061 {
      return 0x00E0
    } // a + grave → à
    if a == 0x006F {
      return 0x00F2
    } // o + grave → ò
  }
  if b == 0x0308 {
    if a == 0x0041 {
      return 0x00C4
    } // A + diaeresis → Ä
    if a == 0x0061 {
      return 0x00E4
    } // a + diaeresis → ä
    if a == 0x004F {
      return 0x00D6
    } // O + diaeresis → Ö
    if a == 0x006F {
      return 0x00F6
    } // o + diaeresis → ö
    if a == 0x0055 {
      return 0x00DC
    } // U + diaeresis → Ü
    if a == 0x0075 {
      return 0x00FC
    } // u + diaeresis → ü
  }
  if b == 0x0302 {
    if a == 0x0053 {
      return 0x015C
    } // S + circumflex → Ŝ
    if a == 0x0073 {
      return 0x015D
    } // s + circumflex → ŝ
  }
  if b == 0x0307 {
    if a == 0x0059 {
      return 0x1E8E
    } // Y + dot above → Ẏ
    if a == 0x0079 {
      return 0x1E8F
    } // y + dot above → ẏ
  }
  // Greek with tonos
  if b == 0x0301 {
    if a == 0x039F {
      return 0x038C
    } // Ο + tonos → Ό
    if a == 0x03BF {
      return 0x03CC
    } // ο + tonos → ό
    if a == 0x006F {
      return 0x00F3
    } // o + acute → ó
    if a == 0x006B {
      return 0x1E31
    } // k + acute → ḱ (keep existing)
  }
  // Arabic with hamza
  if a == 0x0648 && b == 0x0654 {
    return 0x0624 // waw + hamza above → ؤ
  }
  // Remaining existing pairs
  if a == 0x003D && b == 0x0338 {
    return 0x2260 // = + combining solidus → ≠
  }
  if a == 0x003C && b == 0x0338 {
    return 0x226E // < + combining solidus → ≮
  }
  if a == 0x003E && b == 0x0338 {
    return 0x226F // > + combining solidus → ≯
  }
  -1
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
  // Phase 1: apply UTS#46 mapping/ignoring/disallowed via IdnaMappingTable.
  // UseSTD3ASCIIRules=false (per WHATWG URL host parser): treat
  //   disallowed_STD3_valid as valid and disallowed_STD3_mapped as mapped.
  // Transitional_Processing=false: treat deviation as valid (write self).
  let buf = StringBuilder::new()
  for c in domain {
    let cp = c.to_int()
    let st = idna_status_code(cp)
    if st == 1 {
      // ignored
      continue
    }
    if st == 4 {
      raise UrlParseError("domain has IDNA-disallowed code point")
    }
    if st == 2 || st == 6 {
      // mapped / disallowed_STD3_mapped (UseSTD3=false → mapped)
      match idna_mapping_lookup(cp) {
        Some(targets) =>
          for t in targets {
            buf.write_char(Int::unsafe_to_char(t))
          }
        None => buf.write_char(Int::unsafe_to_char(cp))
      }
      continue
    }
    // valid (0), deviation (3), disallowed_STD3_valid (5): keep
    buf.write_char(Int::unsafe_to_char(cp))
  }
  let mapped = buf.to_string()
  if mapped.is_empty() {
    raise UrlParseError("empty domain")
  }
  // Phase 2: per-label Punycode encode/validate
  let labels = split_on_char(mapped, '.')
  let out = StringBuilder::new()
  for i = 0; i < labels.length(); i = i + 1 {
    if i > 0 {
      out.write_char('.')
    }
    let label = labels[i]
    if label.is_empty() {
      continue
    }
    let mut has_non_ascii = false
    let cps : Array[Int] = []
    for c in label {
      let cp = c.to_int()
      cps.push(cp)
      if cp > 0x7F {
        has_non_ascii = true
      }
    }
    // Apply NFC composition for combining sequences
    let cps = if has_non_ascii { nfc_compose(cps) } else { cps }
    has_non_ascii = false
    for cp in cps {
      if cp > 0x7F {
        has_non_ascii = true
      }
    }
    if has_non_ascii {
      // An xn-- prefix with non-ASCII chars is an invalid ACE label
      if label.has_prefix("xn--") {
        raise UrlParseError("invalid ACE label: non-ASCII in xn-- label")
      }
      // V6: label must not start with a combining mark
      if cps.length() > 0 && is_combining_mark_table(cps[0]) {
        raise UrlParseError("label starts with combining mark (V6)")
      }
      for cp in cps {
        if is_idna_forbidden_cp(cp) {
          raise UrlParseError("domain has IDNA-forbidden code point")
        }
        let st = idna_status_code(cp)
        if st == 4 {
          raise UrlParseError("domain has IDNA-disallowed code point (V7)")
        }
      }
      validate_contextj(cps)
      validate_bidi(cps)
      let encoded = punycode_encode(cps)
      out.write_string("xn--")
      out.write_string(encoded)
    } else {
      // ASCII label: validate existing xn-- labels by decoding and checking
      if label.has_prefix("xn--") {
        let suffix = label[4:label.length()].to_owned()
        if suffix.is_empty() {
          raise UrlParseError("invalid ACE label: empty xn-- extension")
        }
        let decoded = punycode_decode(suffix)
        // P4: decoded label must not be empty or all-ASCII
        if decoded.length() == 0 {
          raise UrlParseError("decoded ACE label is empty (P4)")
        }
        let mut has_nonascii_in_decoded = false
        for cp in decoded {
          if cp > 0x7F {
            has_nonascii_in_decoded = true
            break
          }
        }
        if !has_nonascii_in_decoded {
          raise UrlParseError("decoded ACE label contains no non-ASCII (P4)")
        }
        // V2: decoded label must be in NFC form
        let nfc_decoded = nfc_compose(decoded)
        if nfc_decoded.length() != decoded.length() {
          raise UrlParseError("decoded ACE label is not in NFC form (V2)")
        }
        let mut nfc_ok = true
        for k = 0; k < nfc_decoded.length(); k = k + 1 {
          if nfc_decoded[k] != decoded[k] {
            nfc_ok = false
            break
          }
        }
        if !nfc_ok {
          raise UrlParseError("decoded ACE label is not in NFC form (V2)")
        }
        // V4: decoded label must not start with "xn--" (would be a nested ACE label)
        if decoded.length() >= 4 &&
          decoded[0] == 0x78 &&
          decoded[1] == 0x6E &&
          decoded[2] == 0x2D &&
          decoded[3] == 0x2D {
          raise UrlParseError("decoded ACE label starts with xn-- (V4)")
        }
        // V6: decoded label must not start with a combining mark
        if decoded.length() > 0 && is_combining_mark_table(decoded[0]) {
          raise UrlParseError(
            "decoded ACE label starts with combining mark (V6)",
          )
        }
        for cp in decoded {
          if is_idna_forbidden_cp(cp) {
            raise UrlParseError("decoded ACE label has forbidden code point")
          }
          // V7: each cp in decoded label must have valid IDNA status.
          // Acceptable statuses (with UseSTD3ASCIIRules=false): valid (0),
          // deviation (3, Non-transitional treats as valid),
          // disallowed_STD3_valid (5). All others fail.
          let st = idna_status_code(cp)
          if st != 0 && st != 3 && st != 5 {
            raise UrlParseError(
              "decoded ACE label has IDNA-disallowed code point (V7)",
            )
          }
          // C0 controls and DEL are disallowed regardless of UseSTD3ASCIIRules
          if cp < 0x80 && (cp <= 0x1F || cp == 0x7F) {
            raise UrlParseError("decoded ACE label has control char")
          }
        }
        validate_contextj(decoded)
        validate_bidi(decoded)
      }
      out.write_string(label)
    }
  }
  let result = out.to_string()
  if result.is_empty() {
    raise UrlParseError("empty domain")
  }
  result
}

///|
fn is_idna_forbidden_cp(cp : Int) -> Bool {
  // Noncharacters
  cp == 0xFFFD ||
  (cp >= 0xFDD0 && cp <= 0xFDEF) ||
  (cp & 0xFFFF) == 0xFFFE ||
  (cp & 0xFFFF) == 0xFFFF ||
  // Space-like chars disallowed in domain labels
  cp == 0x00A0 ||
  cp == 0x3000 ||
  cp == 0x1680 ||
  // C1 controls
  (cp >= 0x80 && cp <= 0x9F) ||
  // Surrogates
  (cp >= 0xD800 && cp <= 0xDFFF) ||
  // Bidi format controls
  (cp >= 0x202A && cp <= 0x202E) ||
  (cp >= 0x2066 && cp <= 0x2069) ||
  // Arabic End of Ayah
  cp == 0x06DD ||
  // Interlinear annotation chars
  (cp >= 0xFFFA && cp <= 0xFFFC) ||
  // Ideographic Description Characters
  (cp >= 0x2FF0 && cp <= 0x2FFB) ||
  // Tags block and adjacent unassigned (U+E0000-U+E00FF, U+E01F0-U+E0FFF)
  (cp >= 0xE0000 && cp <= 0xE00FF) ||
  (cp >= 0xE01F0 && cp <= 0xE0FFF) ||
  // Digit n Full Stop (U+2488-U+249B, disallowed in IDNA per UTS#46)
  (cp >= 0x2488 && cp <= 0x249B) ||
  // Georgian capital letters (Asomtavruli) must be mapped before encoding
  (cp >= 0x10A0 && cp <= 0x10C5) ||
  // Hangul filler characters are disallowed in domain labels
  cp == 0x1160 ||
  cp == 0x3164 ||
  // Dot-separator chars that map to '.' and must not appear in labels
  cp == 0x3002 ||
  cp == 0xFF61 ||
  cp == 0xFE12 ||
  cp == 0xFE52 ||
  // Unassigned plane 3 (beyond CJK Extension J which ends at U+33FFD)
  (cp >= 0x34000 && cp <= 0x3FFFF) ||
  // Unassigned supplementary planes 4-13 (all unassigned in Unicode 15)
  (cp >= 0x40000 && cp <= 0xDFFFF) ||
  // Unassigned plane 14 chars beyond Tags and variation supplement
  (cp >= 0xE1000 && cp <= 0xEFFFF) ||
  // BMP Private Use Area
  (cp >= 0xE000 && cp <= 0xF8FF) ||
  // Supplementary Private Use Areas (planes 15-16)
  cp >= 0xF0000 ||
  // Specific disallowed chars
  cp == 0x2025 ||
  cp == 0x2A74 ||
  cp == 0x05BE ||
  cp == 0x0378
}

///|
fn domain_has_forbidden_char(domain : String) -> Bool {
  for c in domain {
    let cp = c.to_int()
    // All C0 control chars and DEL are IDNA-disallowed in domain labels
    if cp <= 0x1F || cp == 0x7F {
      return true
    }
    if is_forbidden_host_cp(cp) {
      return true
    }
    // '%' must not appear in domain names (result of %25 decoding or invalid %-seq)
    if cp == 0x25 {
      return true
    }
    // U+FFFD is produced from invalid UTF-8 byte sequences and is IDNA-disallowed
    if cp == 0xFFFD {
      return true
    }
    // Unicode noncharacters U+FDD0-U+FDEF
    if cp >= 0xFDD0 && cp <= 0xFDEF {
      return true
    }
    // Noncharacters at end of each Unicode plane (U+XFFFE and U+XFFFF)
    if (cp & 0xFFFF) == 0xFFFE || (cp & 0xFFFF) == 0xFFFF {
      return true
    }
    // IDNA-disallowed space characters
    if cp == 0x00A0 || cp == 0x3000 {
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
    raise UrlParseError("IPv4 number >= 2^32")
  }
  val.to_uint()
}

///|
fn parse_decimal_u64(input : String) -> UInt64 raise UrlParseError {
  let mut result = 0UL
  let cap = 0x1_0000_0000UL
  for c in input {
    if c < '0' || c > '9' {
      raise UrlParseError("invalid decimal digit")
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
fn parse_hex_u64(input : String) -> UInt64 raise UrlParseError {
  let mut result = 0UL
  let cap = 0x1_0000_0000UL
  for c in input {
    match hex_digit_value(c) {
      Some(v) =>
        if result <= cap {
          let next = (result << 4) | v.to_uint64()
          result = if next > cap { cap + 1UL } else { next }
        }
      None => raise UrlParseError("invalid hex digit")
    }
  }
  result
}

///|
fn parse_octal_u64(input : String) -> UInt64 raise UrlParseError {
  let mut result = 0UL
  let cap = 0x1_0000_0000UL
  for c in input {
    if c < '0' || c > '7' {
      raise UrlParseError("invalid octal digit")
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
