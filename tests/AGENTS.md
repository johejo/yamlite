# tests/ — coding agent guide

This directory holds the **language-agnostic conformance test corpus** for yamlite.
Each implementation (e.g. `zig-yamlite/`) consumes it through a symlink.

The primary human-facing spec lives in [`README.md`](./README.md). This file is a **structural guide for coding agents** exploring or extending the corpus, and it intentionally avoids listing individual case names or current category names (so it does not rot as the corpus grows).

---

## 1. Directory and path layout

```
tests/
├── valid/<category>/<name>.yaml      ← input that must parse successfully
├── valid/<category>/<name>.json      ← expected value (compared structurally)
└── invalid/<category>/<name>.yaml    ← input that must fail to parse (no .json)
```

Invariants:

- Hierarchy is **strictly two levels**: `{valid|invalid}/<category>/<file>`. Never nest subdirectories under a category.
- A case is "a pair of files directly inside a category directory". **Do not create a per-case subdirectory** — `<name>.yaml` / `<name>.json` sit side-by-side at the category level.
- A category name may exist in both `valid/` and `invalid/`; the two are independent.

Before placing a new case, inspect the immediate children of `tests/valid/` and `tests/invalid/` to learn the current categories. Use whatever directory-listing facility is available; the contents are not enumerated here so this guide stays accurate as the corpus evolves.

When to introduce a new category: only when a new concern does not fit any existing one. Avoid carving out categories for convenience.

---

## 2. Per-case file shape (invariants)

### valid case

- `<name>.yaml` and `<name>.json` are **both required**. Never commit only one.
- The `.json` is the expected parse result of the `.yaml`. Whitespace, key order, and trailing newlines are **ignored**; comparison is structural.
- Integers are **i64** (do not coerce to IEEE-754 doubles).
- See [`README.md`](./README.md) for the YAML→JSON value mapping table.

### invalid case

- Only `<name>.yaml`. **Do not** add a `.json`.
- The `.yaml` **must begin with a `# reason: ...` comment** explaining what is expected to fail, in one line.
- The runner asserts that parsing **returns an error**; the test fails if parsing succeeds.

---

## 3. Naming conventions

- Filenames and category names are **kebab-case**.
- Category names are **semantic** (no numeric IDs, no sequential numbering).
- Case names read like a spec heading and follow **one concern per file** — do not pile multiple spec points into one case.
- The `<name>` is typically prefixed with the category name so that **the filename alone tells you what is being tested**.

---

## 4. Runner contract

| Bucket | Inputs | Expected behavior |
| --- | --- | --- |
| valid | `valid/<category>/<name>.yaml` + `<name>.json` | Parse the YAML, parse the sibling JSON, assert **structural deepEqual** |
| invalid | `invalid/<category>/<name>.yaml` | Parsing the YAML **must return an error** |

---

## 5. Harness wiring (implementation side)

The corpus is **not auto-walked**. Each implementation keeps an explicit **allowlist** of case names; dropping files into the corpus alone does not enable them.

For `zig-yamlite/`:

- Harness: two allowlists in `zig-yamlite/yamlite.zig`
  - `conformance_valid: []const []const u8` — enabled valid cases
  - `conformance_invalid: []const []const u8` — enabled invalid cases
- Entry format: `<category>/<name>`, no extension.
- Corpus location: `zig-yamlite/build.zig` passes `corpus_dir` via `b.pathFromRoot("tests")`. `zig-yamlite/tests` is a symlink to `../tests`.

When a new implementation in another language is added, it should consume the same corpus and provide its own allowlist mechanism — the filtering convention is per-implementation.

---

## 6. Workflow for adding a case

1. **Pick the category**
   - Inspect the existing children of `tests/valid/` (or `tests/invalid/`) to see current categories.
   - Reuse one if it fits; otherwise create a new category directory with a kebab-case, semantic name.
2. **Create the files**
   - valid: write `<name>.yaml` and `<name>.json` **as a pair**.
   - invalid: write `<name>.yaml` only and **start with `# reason: ...`**.
   - Follow the naming rules in §3.
3. **(If needed) confirm value mapping** in [`README.md`](./README.md).
4. **Add the entry to the implementation's allowlist**
   - For `zig-yamlite`: append `<category>/<name>` to `conformance_valid` or `conformance_invalid` in `zig-yamlite/yamlite.zig`.
5. **Run the implementation's conformance tests** to verify the case is wired up.

If you forget the allowlist edit, the case sits in the corpus but **silently does not run** — easy to miss.

---

## 7. Anti-patterns (do not do these)

- Creating per-case subdirectories (breaks the two-level rule in §1).
- Shipping a valid case without `.json`, or shipping a `.json` for an invalid case.
- Omitting the `# reason:` comment on an invalid case.
- Numeric/timestamped naming (e.g. `case-001.yaml`).
- Multiple spec points crammed into one file.
- Creating a new category when an existing one would do.
