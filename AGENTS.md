# yamlite — coding agent guide

This repo defines **yamlite** (a YAML subset) and ships per-language implementations that share a single conformance corpus. This file is a top-level orientation for coding agents; the deeper guides live next to the things they describe.

---

## Layout

```
README.md           ← the language-agnostic spec (Keep / Drop)
tests/              ← language-agnostic conformance corpus
  AGENTS.md         ← structural guide for adding/extending cases
  README.md         ← YAML→JSON value mapping table
  valid/<cat>/...   ← .yaml + .json pairs
  invalid/<cat>/... ← .yaml only (must begin with `# reason: ...`)
<lang>-yamlite/     ← per-language implementation
  tests             ← symlink → ../tests (each impl consumes the same corpus)
```

Currently the only implementation is `zig-yamlite/`. Future implementations follow the same shape.

---

## Invariants

- **The spec lives in `README.md`.** If behavior is in question, README is authoritative. If the corpus disagrees with the spec, fix one of them — do not paper over it in an implementation.
- **The corpus is shared, not auto-walked.** Each implementation keeps its own explicit allowlist of enabled cases; dropping files into `tests/` alone does not enable them. See `tests/AGENTS.md` §5.
- **Integers are i64.** Do not coerce to floats anywhere — not in the parser, not in the comparison harness, not in expected JSON.

---

## Where to do what

| Change | Go here |
| --- | --- |
| Spec wording / Keep / Drop | `README.md` |
| New or modified conformance case | `tests/` (follow `tests/AGENTS.md`) |
| Zig parser or harness | `zig-yamlite/yamlite.zig` (single-file parser + in-file conformance runner) |
| Zig build wiring | `zig-yamlite/build.zig` |

When you add a new implementation in another language, mirror the `zig-yamlite/` shape: one symlink to `tests/`, one explicit allowlist, one entry-point file documented in this table.
