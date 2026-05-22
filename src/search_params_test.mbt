// Blackbox tests for UrlSearchParams.
// Run `moon test` to execute and `moon test --update` to refresh snapshots.

// ===== Constructor =====

///|
test "empty string produces empty params" {
  let p = @uri.UrlSearchParams::from_string("")
  @debug.assert_eq(p.size(), 0)
  @debug.assert_eq(p.to_string(), "")
}

///|
test "leading question mark is stripped from input" {
  let p = @uri.UrlSearchParams::from_string("?a=b")
  @debug.assert_eq(p.get("a"), Some("b"))
}

///|
test "basic key=value pairs are parsed" {
  let p = @uri.UrlSearchParams::from_string("a=b&c=d")
  @debug.assert_eq(p.get("a"), Some("b"))
  @debug.assert_eq(p.get("c"), Some("d"))
}

///|
test "key without value gets empty-string value" {
  let p = @uri.UrlSearchParams::from_string("a")
  @debug.assert_eq(p.get("a"), Some(""))
}

///|
test "plus sign in value decodes to space" {
  let p = @uri.UrlSearchParams::from_string("a=b+c")
  @debug.assert_eq(p.get("a"), Some("b c"))
}

///|
test "plus sign in name decodes to space" {
  let p = @uri.UrlSearchParams::from_string("a+b=c")
  @debug.assert_eq(p.get("a b"), Some("c"))
}

///|
test "percent-encoded name and value are decoded" {
  let p = @uri.UrlSearchParams::from_string("%61=a")
  @debug.assert_eq(p.get("a"), Some("a"))
}

///|
test "percent-encoded plus is decoded to plus not space" {
  let p = @uri.UrlSearchParams::from_string("a=b%2Bc")
  @debug.assert_eq(p.get("a"), Some("b+c"))
}

///|
test "empty pairs from consecutive ampersands are ignored" {
  let p = @uri.UrlSearchParams::from_string("&a&&& &&&&&a+b=&")
  @debug.assert_eq(p.has("a"), true)
  @debug.assert_eq(p.has("a b"), true)
}

///|
test "invalid percent sequence is passed through" {
  let p = @uri.UrlSearchParams::from_string("b=%2sf%2a")
  @debug.assert_eq(p.get("b"), Some("%2sf*"))
}

///|
test "percent sign followed by invalid hex is passed through" {
  let p = @uri.UrlSearchParams::from_string("b=%%2a")
  @debug.assert_eq(p.get("b"), Some("%*"))
}

// ===== get =====

///|
test "get returns None for missing key" {
  let p = @uri.UrlSearchParams::from_string("a=b&c=d")
  @debug.assert_eq(p.get("e"), None)
}

///|
test "get returns first value for duplicate keys" {
  let p = @uri.UrlSearchParams::from_string("a=b&c=d&a=e")
  @debug.assert_eq(p.get("a"), Some("b"))
}

///|
test "get matches empty-string key" {
  let p = @uri.UrlSearchParams::from_string("=b&c=d")
  @debug.assert_eq(p.get(""), Some("b"))
}

// ===== get_all =====

///|
test "get_all returns all values for duplicate keys" {
  let p = @uri.UrlSearchParams::from_string("a=b&c=d&a=e")
  @debug.assert_eq(p.get_all("a"), ["b", "e"])
}

///|
test "get_all returns empty array for missing key" {
  let p = @uri.UrlSearchParams::from_string("a=b")
  @debug.assert_eq(p.get_all("c"), [])
}

// ===== has =====

///|
test "has returns true for existing key" {
  let p = @uri.UrlSearchParams::from_string("a=b&c=d")
  @debug.assert_eq(p.has("a"), true)
  @debug.assert_eq(p.has("c"), true)
}

///|
test "has returns false for missing key" {
  let p = @uri.UrlSearchParams::from_string("a=b")
  @debug.assert_eq(p.has("b"), false)
}

///|
test "has with value returns true when name+value pair exists" {
  let p = @uri.UrlSearchParams::from_string("a=b&a=d")
  @debug.assert_eq(p.has_entry("a", "b"), true)
  @debug.assert_eq(p.has_entry("a", "d"), true)
  @debug.assert_eq(p.has_entry("a", "c"), false)
}

// ===== append =====

///|
test "append adds name-value pair" {
  let p = @uri.UrlSearchParams::new()
  p.append("a", "b")
  @debug.assert_eq(p.get("a"), Some("b"))
  @debug.assert_eq(p.to_string(), "a=b")
}

///|
test "append can add duplicate keys" {
  let p = @uri.UrlSearchParams::new()
  p.append("a", "b")
  p.append("a", "b")
  @debug.assert_eq(p.to_string(), "a=b&a=b")
}

///|
test "append empty name and value" {
  let p = @uri.UrlSearchParams::new()
  p.append("", "")
  @debug.assert_eq(p.to_string(), "=")
}

// ===== delete =====

///|
test "delete removes all pairs with given name" {
  let p = @uri.UrlSearchParams::from_string("a=b&c=d")
  p.delete("a")
  @debug.assert_eq(p.to_string(), "c=d")
}

///|
test "delete removes all duplicates" {
  let p = @uri.UrlSearchParams::from_string("a=a&b=b&a=a&c=c")
  p.delete("a")
  @debug.assert_eq(p.to_string(), "b=b&c=c")
}

///|
test "delete with value removes only matching pair" {
  let p = @uri.UrlSearchParams::new()
  p.append("a", "b")
  p.append("a", "c")
  p.append("a", "d")
  p.delete_entry("a", "c")
  @debug.assert_eq(p.to_string(), "a=b&a=d")
}

///|
test "delete non-existent key is no-op" {
  let p = @uri.UrlSearchParams::from_string("a=b")
  p.delete("c")
  @debug.assert_eq(p.to_string(), "a=b")
}

// ===== set =====

///|
test "set creates new entry when key does not exist" {
  let p = @uri.UrlSearchParams::new()
  p.set("a", "b")
  @debug.assert_eq(p.get("a"), Some("b"))
}

///|
test "set replaces all existing entries and keeps first position" {
  let p = @uri.UrlSearchParams::from_string("a=a&b=b&a=a&c=c")
  p.set("a", "x")
  @debug.assert_eq(p.to_string(), "a=x&b=b&c=c")
}

// ===== size =====

///|
test "size returns number of pairs" {
  let p = @uri.UrlSearchParams::from_string("a=1&b=2&a=3")
  @debug.assert_eq(p.size(), 3)
}

///|
test "size decreases after delete" {
  let p = @uri.UrlSearchParams::from_string("a=1&b=2&a=3")
  p.delete("a")
  @debug.assert_eq(p.size(), 1)
}

// ===== to_string / serialization =====

///|
test "serialize space as plus" {
  let p = @uri.UrlSearchParams::new()
  p.append("a", "b c")
  @debug.assert_eq(p.to_string(), "a=b+c")
}

///|
test "serialize plus as %2B" {
  let p = @uri.UrlSearchParams::new()
  p.append("a", "b+c")
  @debug.assert_eq(p.to_string(), "a=b%2Bc")
}

///|
test "serialize percent as %25" {
  let p = @uri.UrlSearchParams::new()
  p.append("a", "b%c")
  @debug.assert_eq(p.to_string(), "a=b%25c")
}

///|
test "serialize ampersand as %26" {
  let p = @uri.UrlSearchParams::new()
  p.append("&", "a")
  @debug.assert_eq(p.to_string(), "%26=a")
}

///|
test "serialize equals as %3D" {
  let p = @uri.UrlSearchParams::new()
  p.append("=", "a")
  @debug.assert_eq(p.to_string(), "%3D=a")
}

///|
test "safe chars are not encoded" {
  let p = @uri.UrlSearchParams::new()
  p.append("a", "*-._")
  @debug.assert_eq(p.to_string(), "a=*-._")
}

///|
test "NUL byte is encoded" {
  let p = @uri.UrlSearchParams::new()
  p.append("a", "b\u{0000}c")
  @debug.assert_eq(p.to_string(), "a=b%00c")
}

///|
test "roundtrip: parse then serialize" {
  let p = @uri.UrlSearchParams::from_string("a=b&c=d&&e&&")
  @debug.assert_eq(p.to_string(), "a=b&c=d&e=")
}

///|
test "roundtrip: spaces in parsed string become plus in serialized" {
  let p = @uri.UrlSearchParams::from_string("a = b &a=b&c=d%20")
  @debug.assert_eq(p.to_string(), "a+=+b+&a=b&c=d+")
}

// ===== sort =====

///|
test "sort orders pairs by name in code unit order" {
  let p = @uri.UrlSearchParams::from_string("z=b&a=b&z=a&a=a")
  p.sort()
  @debug.assert_eq(p.to_string(), "a=b&a=a&z=b&z=a")
}

///|
test "sort is stable for equal names" {
  let p = @uri.UrlSearchParams::from_string("z=z&a=a&z=y&a=b&z=x&a=c")
  p.sort()
  @debug.assert_eq(p.to_string(), "a=a&a=b&a=c&z=z&z=y&z=x")
}

///|
test "sort empty string name before non-empty" {
  let p = @uri.UrlSearchParams::from_string("z=z&=f&=t&=x")
  p.sort()
  @debug.assert_eq(p.to_string(), "=f&=t&=x&z=z")
}

// ===== iter / for_each =====

///|
test "for_each visits all pairs in order" {
  let p = @uri.UrlSearchParams::from_string("a=1&b=2&c=3")
  let keys : Array[String] = []
  let values : Array[String] = []
  p.for_each(fn(name, value) {
    keys.push(name)
    values.push(value)
  })
  @debug.assert_eq(keys, ["a", "b", "c"])
  @debug.assert_eq(values, ["1", "2", "3"])
}

///|
test "iter yields all pairs" {
  let p = @uri.UrlSearchParams::from_string("a=1&b=2")
  let pairs : Array[(String, String)] = []
  for pair in p.iter() {
    pairs.push(pair)
  }
  @debug.assert_eq(pairs, [("a", "1"), ("b", "2")])
}

///|
test "Show for UrlSearchParams outputs serialized form" {
  let p = @uri.UrlSearchParams::from_string("a=1&b=2")
  assert_eq("\{p}", "a=1&b=2")
}

///|
test "Show for UrlSearchParams outputs empty string for empty params" {
  let p = @uri.UrlSearchParams::new()
  assert_eq("\{p}", "")
}
