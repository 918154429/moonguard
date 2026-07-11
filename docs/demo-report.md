# MoonGuard Demo And Validation Report

This report records the reproducible competition demo state validated on
2026-07-10 with MoonBit `0.1.20260608`.

## Validation Summary

| Check | Result |
| --- | ---: |
| MoonBit tests | 162 passed, 0 failed |
| MoonBit JS-target tests | 163 passed, 0 failed |
| Instrumented coverage | 1900 / 2183 lines (87.0%) |
| Core library coverage | 1499 / 1654 lines (90.6%) |
| Real `.mbti` samples | 15 |
| Parsed real API items | 6819 |
| Unknown real declarations | 0 |
| Real snapshot diagnostics | 0 |
| Modern-format samples fully modeled | 14 / 14 |
| Historical-format samples fully modeled | 1 / 1 |

The real corpus includes official MoonBit projects and independent community
libraries. Exact repositories, paths, revisions, and licenses are recorded in
`fixtures/real/SOURCES.md`; the per-sample parser result is recorded in
`docs/real-world-compatibility.md`.

The historical sample contains 119 associated `fn`/`impl` lines without a
`pub` visibility prefix. MoonGuard models them only after recognizing the
historical `moon info` generator header and package declaration.

## Package Identity Regression

Directory snapshots now derive logical identity from the parent-directory
package scope plus the API symbol. The individual `.mbti` filename is retained
for diagnostics but does not participate in same-package identity. Regression
tests demonstrate that moving a declaration from `pkg/a.mbti` to `pkg/b.mbti`
produces zero changes and a `patch` recommendation, while same-named symbols in
different package directories remain distinct and duplicates inside one
package are still diagnosed.

## Auditable Policy Demo

Run a report with a reviewed compatibility exception:

```sh
moon run --target js cmd/main -- report \
  fixtures/old.mbti fixtures/new.mbti --format json \
  --policy-file fixtures/allow-render.policy --policy-version 0.2.0
```

The output contains `original_report`, `effective_report`, accepted changes,
the owning rule and reason, policy counters, and diagnostics. The fixture rule
uses a deadline and a one-change match budget:

```text
allow changed fn render until 0.2.0 max_matches 1 reason render migration reviewed
```

Using `fixtures/expired-render.policy` at version `0.2.0`, omitting a required
policy version, or exceeding a rule budget fails closed and exits with status
`2`. A valid effective report whose proposed version is insufficient exits
with status `1`; a sufficient decision exits with `0`.

## Refactoring Result

The former monolithic implementation is now separated into API model, parser,
snapshot, diff, SemVer, policy, Markdown renderer, and JSON renderer modules.
The CLI is independently split into argument, configuration, command, output,
snapshot I/O, and backend I/O modules. This preserves the public workflow while
making parser, governance, rendering, and CLI changes independently testable.

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
moon test --target js
moon coverage analyze
moon coverage report -- -f summary
moon run --target js cmd/main -- inventory-dir fixtures/real --format json
```

GitHub Actions repeats format, check, test, CLI smoke, directory hygiene,
release-plan, and direct Node exit-code assertions on every push and pull
request.
