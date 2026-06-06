///|
test "bench parse small URL" (it : @bench.T) {
  let input = "http://foo.com"
  it.bench(fn() { it.keep(@url.parse_maybe(input, None)) })
}

///|
test "bench parse URL with IPv6" (it : @bench.T) {
  let input = "http://[dead:beef::dead:0:beaf]/"
  it.bench(fn() { it.keep(@url.parse_maybe(input, None)) })
}

///|
test "bench parse complete URL with credentials" (it : @bench.T) {
  let input = "https://user:pass@foo.com:123/wh/at/ever?foo=1&bar=5#5"
  it.bench(fn() { it.keep(@url.parse_maybe(input, None)) })
}

///|
test "bench parse query-heavy URL" (it : @bench.T) {
  let input = "http://domain?f+1=bar&+f2=bar%212"
  it.bench(fn() { it.keep(@url.parse_maybe(input, None)) })
}

///|
test "bench parse path-heavy URL" (it : @bench.T) {
  let input = "http://a/b/c/g;x?y#s"
  it.bench(fn() { it.keep(@url.parse_maybe(input, None)) })
}

///|
test "bench parse opaque URN" (it : @bench.T) {
  let input = "urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6"
  it.bench(fn() { it.keep(@url.parse_maybe(input, None)) })
}

///|
test "bench serialize complete URL" (it : @bench.T) {
  let input = "https://user:pass@foo.com:123/wh/at/ever?foo=1&bar=5#5"
  let url = @url.parse_maybe(input, None).unwrap()
  it.bench(fn() { it.keep(url.href()) })
}

///|
test "bench search params parse" (it : @bench.T) {
  let input = "foo=1&bar=2&baz=hello+world&x=%20&y=a%26b"
  it.bench(fn() { it.keep(@url.UrlSearchParams::from_string(input)) })
}
