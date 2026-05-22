///|
test "set_hash sets fragment without leading hash" {
  let url = @uri.parse("https://example.net").set_hash("main")
  assert_eq(url.hash(), "#main")
  assert_eq(url.href(), "https://example.net/#main")
}

///|
test "set_hash replaces existing fragment" {
  let url = @uri.parse("https://example.net#nav").set_hash("main")
  assert_eq(url.hash(), "#main")
}

///|
test "set_hash strips leading hash from value" {
  let url = @uri.parse("https://example.net?q=1#nav").set_hash("#main")
  assert_eq(url.hash(), "#main")
}

///|
test "set_hash with empty string removes fragment" {
  let url = @uri.parse("https://example.net?q=1#nav").set_hash("")
  assert_eq(url.hash(), "")
  assert_eq(url.href(), "https://example.net/?q=1")
}

///|
test "set_hash percent-encodes special chars" {
  let url = @uri.parse("http://example.net").set_hash("#foo bar")
  assert_eq(url.hash(), "#foo%20bar")
}

///|
test "set_hash works on opaque-path URL" {
  let url = @uri.parse("javascript:alert(1)").set_hash("castle")
  assert_eq(url.hash(), "#castle")
  assert_eq(url.href(), "javascript:alert(1)#castle")
}

///|
test "set_search sets query without leading question mark" {
  let url = @uri.parse("https://example.net#nav").set_search("lang=fr")
  assert_eq(url.search(), "?lang=fr")
  assert_eq(url.href(), "https://example.net/?lang=fr#nav")
}

///|
test "set_search strips leading question mark from value" {
  let url = @uri.parse("https://example.net?old#nav").set_search("?lang=fr")
  assert_eq(url.search(), "?lang=fr")
}

///|
test "set_search with empty string removes query" {
  let url = @uri.parse("https://example.net?lang=en").set_search("")
  assert_eq(url.search(), "")
  assert_eq(url.href(), "https://example.net/")
}

///|
test "set_search with only question mark sets empty query" {
  let url = @uri.parse("https://example.net?lang=en-US#nav").set_search("?")
  assert_eq(url.search(), "")
  assert_eq(url.href(), "https://example.net/?#nav")
}

///|
test "set_search preserves fragment" {
  let url = @uri.parse("https://example.net?en#nav").set_search("lang=fr")
  assert_eq(url.search(), "?lang=fr")
  assert_eq(url.hash(), "#nav")
}

///|
test "set_username sets username for http URL" {
  let url = @uri.parse("http://example.net").set_username("me")
  assert_eq(url.username, "me")
  assert_eq(url.href(), "http://me@example.net/")
}

///|
test "set_username with empty string clears username" {
  let url = @uri.parse("http://me@example.net").set_username("")
  assert_eq(url.username, "")
  assert_eq(url.href(), "http://example.net/")
}

///|
test "set_username is no-op for file URL" {
  let url = @uri.parse("file://test/").set_username("test")
  assert_eq(url.username, "")
}

///|
test "set_username is no-op when no host" {
  let url = @uri.parse("file:///home/you/index.html").set_username("me")
  assert_eq(url.username, "")
  assert_eq(url.href(), "file:///home/you/index.html")
}

///|
test "set_username is no-op for opaque-path URL" {
  let url = @uri.parse("mailto:you@example.net").set_username("me")
  assert_eq(url.username, "")
}

///|
test "set_username percent-encodes value using userinfo set" {
  let url = @uri.parse("http://example.net").set_username("/foo")
  assert_eq(url.username, "%2Ffoo")
}

///|
test "set_password sets password for http URL" {
  let url = @uri.parse("http://example.net").set_password("secret")
  assert_eq(url.password, "secret")
  assert_eq(url.href(), "http://:secret@example.net/")
}

///|
test "set_password with empty string clears password" {
  let url = @uri.parse("http://:secret@example.net").set_password("")
  assert_eq(url.password, "")
  assert_eq(url.href(), "http://example.net/")
}

///|
test "set_password is no-op for file URL" {
  let url = @uri.parse("file://test/").set_password("test")
  assert_eq(url.password, "")
}

///|
test "set_password is no-op when no host" {
  let url = @uri.parse("unix:/run/foo.socket").set_password("secret")
  assert_eq(url.password, "")
}

///|
test "set_port sets port number" {
  let url = @uri.parse("http://example.net").set_port("8080")
  assert_eq(url.port_str(), "8080")
  assert_eq(url.href(), "http://example.net:8080/")
}

///|
test "set_port with empty string removes port" {
  let url = @uri.parse("http://example.net:8080").set_port("")
  assert_eq(url.port_str(), "")
  assert_eq(url.href(), "http://example.net/")
}

///|
test "set_port with default port removes port" {
  let url = @uri.parse("http://example.net:8080").set_port("80")
  assert_eq(url.port_str(), "")
}

///|
test "set_port with out-of-range number is no-op" {
  let url = @uri.parse("http://example.net:8080/path").set_port("65536")
  assert_eq(url.port_str(), "8080")
}

///|
test "set_port stops at non-digit chars" {
  let url = @uri.parse("http://example.net/path").set_port("8080stuff2")
  assert_eq(url.port_str(), "8080")
}

///|
test "set_port is no-op for file URL" {
  let url = @uri.parse("file://test/").set_port("12")
  assert_eq(url.port_str(), "")
}

///|
test "set_pathname sets path" {
  let url = @uri.parse("https://example.net#nav").set_pathname("home")
  assert_eq(url.pathname(), "/home")
  assert_eq(url.href(), "https://example.net/home#nav")
}

///|
test "set_pathname resolves dot segments" {
  let url = @uri.parse("https://example.net#nav").set_pathname("../home")
  assert_eq(url.pathname(), "/home")
}

///|
test "set_pathname is no-op for opaque-path URL" {
  let url = @uri.parse("mailto:me@example.net").set_pathname("/foo")
  assert_eq(url.pathname(), "me@example.net")
}

///|
test "set_pathname encodes path chars" {
  let url = @uri.parse("http://example.net").set_pathname("?")
  assert_eq(url.pathname(), "/%3F")
}

///|
test "set_host sets host and port" {
  let url = @uri.parse("http://example.net").set_host("example.com:8080")
  assert_eq(url.host_str(), "example.com:8080")
  assert_eq(url.href(), "http://example.com:8080/")
}

///|
test "set_host updates host only when no port in value" {
  let url = @uri.parse("http://example.net:8080").set_host("example.com")
  assert_eq(url.hostname(), "example.com")
  assert_eq(url.port_str(), "8080")
}

///|
test "set_host is no-op for opaque-path URL" {
  let url = @uri.parse("mailto:me@example.net").set_host("example.com")
  assert_eq(url.host_str(), "")
}

///|
test "set_host stops at slash delimiter" {
  let url = @uri.parse("http://example.net/path").set_host("example.com/stuff")
  assert_eq(url.hostname(), "example.com")
}

///|
test "set_hostname updates only hostname preserving port" {
  let url = @uri.parse("http://example.net:8080").set_hostname("example.com")
  assert_eq(url.hostname(), "example.com")
  assert_eq(url.port_str(), "8080")
}

///|
test "set_hostname with colon is no-op" {
  let url = @uri.parse("http://example.net/path").set_hostname(
    "example.com:8080",
  )
  assert_eq(url.hostname(), "example.net")
}

///|
test "set_hostname is no-op for opaque-path URL" {
  let url = @uri.parse("mailto:me@example.net").set_hostname("example.com")
  assert_eq(url.hostname(), "")
}

///|
test "set_protocol changes scheme" {
  let url = @uri.parse("a://example.net").set_protocol("b")
  assert_eq(url.protocol(), "b:")
  assert_eq(url.href(), "b://example.net")
}

///|
test "set_protocol lowercases scheme" {
  let url = @uri.parse("a://example.net").set_protocol("B")
  assert_eq(url.protocol(), "b:")
}

///|
test "set_protocol ignores stuff after first colon" {
  let url = @uri.parse("http://example.net").set_protocol("https:foo:bar")
  assert_eq(url.protocol(), "https:")
}

///|
test "set_protocol from special to non-special is no-op" {
  let url = @uri.parse("http://example.net").set_protocol("b")
  assert_eq(url.protocol(), "http:")
}

///|
test "set_protocol from non-special to special is no-op" {
  let url = @uri.parse("ssh://me@example.net").set_protocol("http")
  assert_eq(url.protocol(), "ssh:")
}

///|
test "set_protocol to file with credentials is no-op" {
  let url = @uri.parse("http://test@example.net").set_protocol("file")
  assert_eq(url.protocol(), "http:")
}

///|
test "set_protocol clears port when it becomes default for new scheme" {
  let url = @uri.parse("http://foo.com:443/").set_protocol("https")
  assert_eq(url.protocol(), "https:")
  assert_eq(url.port_str(), "")
}

///|
test "set_protocol strips tabs and newlines from value" {
  let url = @uri.parse("http://test/").set_protocol("h\r\ntt\tps")
  assert_eq(url.protocol(), "https:")
}

///|
test "set_href re-parses the URL" {
  let url = @uri.parse("file:///var/log/system.log").set_href(
    "http://0300.168.0xF0",
  )
  assert_eq(url.href(), "http://192.168.0.240/")
  assert_eq(url.protocol(), "http:")
}
