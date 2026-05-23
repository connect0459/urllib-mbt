# Architecture

## Package graph

```text
connect0459/urllib/url/percent_encoding   no external deps
        │
        ├── connect0459/urllib/url/idna   deps: @pe
        │         │
        │         └── connect0459/urllib/url/host   deps: @idna, @pe
        │                       │
        │         ┌─────────────┘
        │         │
        └── connect0459/urllib/url        deps: @idna, @pe, @host
                  │
        ┌─────────┘
        │
        └── connect0459/urllib/urlpattern deps: @url, @host, @pe
```

| Package | Role |
| :--- | :--- |
| `percent_encoding` | Percent-encode/decode, UTF-8 codec, shared char utilities |
| `idna` | UTS#46 domain mapping, Punycode, IDNA status/mapping tables |
| `host` | `Host` type, IPv4/IPv6/domain parsing and serialization |
| `url` | URL parser, serializer, setters, `UrlSearchParams` |
| `urlpattern` | WHATWG URL Pattern API |

## `percent_encoding` as shared low-level substrate

`percent_encoding` contains three functions that are unrelated to
percent-encoding by name:

| Function | Used for (outside `percent_encoding`) |
| :--- | :--- |
| `string_to_chars` | Random-access char iteration in `host`, `url`, `urlpattern` |
| `split_on_char` | IPv4 label splitting in `host`; domain label splitting in `idna` |
| `hex_digit_value` | IPv4/IPv6 hex parsing in `host` |

Extracting these into a dedicated package (e.g. `chars` or `ascii`)
was considered and deliberately deferred. The new-package overhead
(moon.pkg, namespace, all call-site updates) outweighs the semantic
benefit at the current project size.

**Revisit trigger**: if a future package needs any of these functions
without needing any percent-encoding function, extraction becomes
worthwhile.

Note: `string_to_chars` exists because MoonBit's `String` type does
not currently expose a method that converts to `Array[Char]` for
random-access iteration. It can be removed if the standard library
adds such a method.
