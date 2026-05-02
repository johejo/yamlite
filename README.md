# yamlite

lightweight YAML subset

## Keep

- scalar := quoted string | int | bool | null
- int := decimal only, optional leading `-`, i64 (overflow is an error; no leading zeros except `0`/`-0`; no `+`/exponent)
- bool := `true` | `True` | `TRUE` | `false` | `False` | `FALSE`
- null := `null` | `Null` | `NULL`
- key := quoted string (`"..."` or `'...'`)
- string value must be quoted (`"..."` or `'...'`)
- double-quoted escapes: `\\` `\"` `\n` `\t` `\r` `\uXXXX` (others are an error)
- single-quoted: `''` for `'`, backslash is literal
- control chars (`0x00`-`0x1F`) forbidden in strings, whether raw or via `\uXXXX`
- lone surrogate `\uXXXX` is an error; surrogate pairs combine into one codepoint
- strings are single-line (use `\n`)
- input must be valid UTF-8, no BOM
- line endings: LF or CRLF (CRLF normalized to LF)
- empty input or comments-only input parses as an empty mapping
- the document root is always a block mapping (top-level sequence or scalar is an error)
- duplicate keys in a mapping are an error
- block mapping (`key: value`); the value must be present on the same line or via a child block (an empty value like `"key":` with nothing after is an error — write `null` explicitly)
- block sequence (`- item`); `-` must be indented one level under its parent key
- block literal `|` (content at parent-indent + 2, single trailing newline kept; at least one content line is required)
- comments (`#` to end of line)
- indent := 2 spaces per level, fixed (tabs are an error)

## Drop

- unquoted string values
- anchors/aliases
- merge keys (no special semantics for `<<`; if it appears as a quoted key it is just a string)
- tags
- flow style (`{}`, `[]`)
- multi-document (`---`, `...`)
- unquoted keys
- bool aliases (`yes`/`no`/`on`/`off`)
- float (parse error, not coerced to string)
- folded block scalar (`>`)
- block scalar chomping (`-`/`+`) and indent indicators
