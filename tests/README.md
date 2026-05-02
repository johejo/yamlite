# yamlite test corpus

Language-agnostic conformance tests for yamlite.

## Layout

- `valid/<category>/<name>.yaml` — input that must parse successfully
- `valid/<category>/<name>.json` — the expected parse result as JSON
- `invalid/<category>/<name>.yaml` — input that must fail to parse

## Value mapping (yamlite → JSON)

| yamlite | JSON |
| --- | --- |
| string | string |
| int (i64) | number (integer literal, no fractional part) |
| bool | `true` / `false` |
| null | `null` |
| mapping | object |
| sequence | array |

JSON is used purely as a transport for the value tree. Whitespace, object key order, and trailing newlines in the JSON file are not significant — runners must compare structurally.

Numbers in expected JSON files may exceed JavaScript's safe-integer range (e.g. `9223372036854775807`). Runners must parse them as 64-bit integers, not as IEEE-754 doubles.

## Runner contract

A runner for a yamlite implementation should:

1. For every `valid/**/*.yaml`: parse it, parse the sibling `.json`, and assert the values are deeply equal.
2. For every `invalid/**/*.yaml`: parse it and assert that parsing failed.

## Conventions

- One concern per file. Don't pile multiple spec points into one test.
- File names use kebab-case and read like a spec heading: `string-escape-unicode.yaml`, `mapping-duplicate-key.yaml`.
- Invalid tests should include a `# reason: ...` comment at the top documenting what is expected to fail.
