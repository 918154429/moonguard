# MoonGuard Demo And Validation Report

This report records the reproducible competition demo state validated on
2026-07-10 with MoonBit `0.1.20260608`.

## Validation Summary

| Check | Result |
| --- | ---: |
| MoonBit tests | 139 passed, 0 failed |
| Instrumented coverage | 1900 / 2183 lines (87.0%) |
| Core library coverage | 1499 / 1654 lines (90.6%) |
| Real `.mbti` samples | 15 |
| Parsed real API items | 6700 |
| Unknown real declarations | 0 |
| Real snapshot diagnostics | 0 |
| Modern-format samples fully modeled | 14 / 14 |
| Historical-format samples partially modeled | 1 / 1 |

The real corpus includes official MoonBit projects and independent community
libraries. Exact repositories, paths, revisions, and licenses are recorded in
`fixtures/real/SOURCES.md`; the per-sample parser result is recorded in
`docs/real-world-compatibility.md`.

The partial historical sample contains 119 associated `fn`/`impl` lines without
a `pub` visibility prefix. MoonGuard does not silently claim those lines are
covered: the corpus analyzer reports them separately as a legacy-format gap.

## Breaking Change Demo

Run a package-level release decision:

```sh
moon run --target js cmd/main -- release-plan \
  fixtures/dir-old fixtures/dir-new \
  --current 0.1.0 --next 1.0.0
```

The demo detects three public API changes:

- `Options.mode` changes from `String` to `Int` (`major`);
- `render` gains an `Options` parameter (`major`);
- a new command package function is added (`minor`).

Because `0.1.0 -> 1.0.0` satisfies the required major bump, the release plan is
`ready`. Replacing `--next 1.0.0` with `--next 0.2.0` changes the result to
`needs-version-bump` and the direct Node CLI exits with status `1`.

## Snapshot Diagnostic Demo

```sh
node _build/js/debug/build/cmd/main/main.js release-plan \
  fixtures/dir-old fixtures/dir-duplicate \
  --current 0.1.0 --next 1.0.0
```

The duplicate public symbol prevents a reliable release decision. MoonGuard
renders a `blocked` plan and exits with status `2`, separating malformed input
from an ordinary insufficient version bump.

## Directory Hygiene Regression

Earlier directory scans recursively consumed `_build` output and repository
fixtures, which could create duplicate symbols unrelated to the target package.
MoonGuard now ignores common generated, vendored, coverage, fixture, and tool
directories. The following command scans the repository itself successfully:

```sh
moon run --target js cmd/main -- inventory-dir . --format json
```

The validated result contains 168 API items and zero diagnostics. Passing a
fixture directory as the explicit root still works, so the exclusion rules do
not disable test or saved-snapshot workflows.

## Formatting Regression

The parser normalizes inline and block container layouts. These two interfaces
now produce the same snapshot:

```moonbit
pub struct Options { mode : String }
```

```moonbit
pub struct Options {
  mode : String
}
```

Actual nested changes remain visible: changing the field type, adding a field,
adding an enum constructor, or adding a required trait method is conservatively
classified as `major`.

## Reproduction Commands

```sh
moon fmt --check
moon info
moon check
moon test
moon coverage analyze
moon coverage report -- -f summary
moon run --target js cmd/main -- inventory-dir fixtures/real --format json
```

GitHub Actions repeats format, check, test, CLI smoke, directory hygiene,
release-plan, and direct Node exit-code assertions on every push and pull
request.
