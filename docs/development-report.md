# MoonGuard Development Report

MoonGuard is a MoonBit public API compatibility and SemVer guard. The project
compares two interface snapshots, extracts public declarations, reports API
changes, and recommends whether the next release should be patch, minor, or
major.

## Motivation

MoonBit package authors need lightweight engineering tools around public API
stability. The MoonBit toolchain can generate interface files such as
`pkg.generated.mbti`, but the ecosystem still needs a tool that can turn those
interfaces into compatibility decisions usable in CI and release workflows.

MoonGuard targets that gap directly. It is narrower than a general Markdown or
documentation tool, but its value is more specific to MoonBit's package
ecosystem.

## Current Implementation

MoonGuard now implements both a library workflow and a JS-target CLI workflow:

```text
old interface text -> parse_interface -> API model \
                                              -> diff -> report
new interface text -> parse_interface -> API model /
```

Implemented capabilities:

- Parse public declarations from `.mbti`-style text.
- Normalize whitespace and declaration order.
- Track public `fn`, `type`, `typealias`, `struct`, `enum`, `trait`, `impl`,
  `let`, and `const` declarations.
- Track generated `.mbti` nested public surface such as struct fields, enum
  constructors, trait methods, generic methods, `suberror`, and `pub using`
  type or trait exports.
- Preserve unrecognized public declarations as `unknown`.
- Detect ordinary top-level added public API as `minor`.
- Conservatively detect added struct fields, enum/suberror constructors, and
  required trait methods as `major`.
- Detect removed public API as `major`.
- Detect changed public signatures as `major`.
- Render Markdown and JSON compatibility reports.
- Parse and validate `major.minor.patch` SemVer versions.
- Check whether a proposed next version satisfies a file or package report
  recommendation.
- Parse simple ignore-rule files and filter accepted or experimental API
  changes from reports.
- Parse and evaluate auditable policy rules with reasons, optional SemVer
  deadlines, match budgets, accepted-change records, and fail-closed
  diagnostics while preserving original and effective reports.
- Parse simple CLI config files for shared `format`, `ignore_file`,
  `policy_file`, `policy_version`, `current`, `next`, `baseline`, `target`,
  `baseline_dir`, and `target_dir` defaults.
- Build package snapshots from multiple `.mbti` files.
- Identify package APIs by parent-directory scope plus symbol identity. The
  source filename remains diagnostic provenance, so moving an API between
  files in one package is unchanged while cross-package names stay distinct.
- Ignore generated, vendored, fixture, coverage, and nested tool directories
  when a project root is scanned.
- Report directory diagnostics such as empty input, no `.mbti` files, duplicate
  symbols, and file-read failures.
- Render package-level comparison reports, package version-check reports, and
  snapshot inventories in Markdown or JSON.
- Render release plans with a status, SemVer decision, diagnostics, and a
  maintainer checklist.
- Provide file-based CLI comparison on the JS backend:

```sh
moon run --target js cmd/main -- report fixtures/old.mbti fixtures/new.mbti
```

- Preserve a text-only CLI demo command:

```sh
moon run cmd/main -- report-text "pub fn old() -> Unit" "pub fn new() -> Unit"
```

- Provide CI-oriented CLI commands:

```sh
moon run --target js cmd/main -- report fixtures/old.mbti fixtures/new.mbti --format json
moon run --target js cmd/main -- report --config fixtures/moonguard-ci.conf
moon run --target js cmd/main -- check fixtures/old.mbti fixtures/new.mbti --current 0.1.0 --next 0.2.0
moon run --target js cmd/main -- report-dir fixtures/dir-old fixtures/dir-new
moon run --target js cmd/main -- report-dir --config fixtures/moonguard-ci.conf
moon run --target js cmd/main -- check-dir fixtures/dir-old fixtures/dir-new --current 0.1.0 --next 1.0.0
moon run --target js cmd/main -- check-dir --config fixtures/moonguard-ci.conf
moon run --target js cmd/main -- release-plan --config fixtures/moonguard-ci.conf
moon run --target js cmd/main -- inventory-dir --config fixtures/moonguard-ci.conf
```

## Architecture

The core and CLI have been split by stable responsibility:

- `api_model.mbt`: public API, change, report, snapshot, and diagnostic models;
- `parser.mbt`: `.mbti` parsing and normalization;
- `snapshot.mbt`: package snapshots, scope derivation, and duplicate checks;
- `diff.mbt`: item and snapshot comparison;
- `semver.mbt`: version parsing, recommendations, and bump validation;
- `policy.mbt`: auditable policy parsing, evaluation, and policy release plans;
- `report_markdown.mbt` / `report_json.mbt`: format-specific rendering;
- `moonguard.mbt`: compatibility helpers retained as a small core surface;
- `cmd/main/args.mbt`, `config.mbt`, `commands.mbt`, `output.mbt`, and
  `snapshot_io.mbt`: CLI parsing, resolution, dispatch, output, and snapshot
  integration;
- `cmd/main/read_file_js.mbt` / `read_file_nonjs.mbt`: backend-specific I/O;
- `moonguard_test.mbt`
  - black-box behavior tests
- `moonguard_wbtest.mbt`
  - package-scope parser tests
- `policy_test.mbt` / `policy_wbtest.mbt`
  - policy API and internal fail-closed behavior tests

## Design Decisions

The parser starts from `.mbti`-style public declaration lines instead of trying
to parse all MoonBit source syntax. This keeps the implementation focused on
release compatibility, which is the actual workflow MoonGuard needs to support.

Compatibility and version rules are conservative:

- Removing public API is breaking.
- Changing a public signature is breaking.
- Adding ordinary top-level public API is minor-compatible.
- Adding a field, enum/suberror constructor, or required trait method is
  conservatively breaking because it can invalidate construction, exhaustive
  matching, or existing implementations.
- No public API model change is patch.
- A `major` recommendation requires a major version increase.
- A `minor` recommendation accepts a minor or major version increase.
- A `patch` recommendation accepts any greater version.

Unrecognized `pub` lines are not discarded. They are retained as `unknown`
items so that public surface changes remain visible until the parser gains
first-class support for that syntax.

Directory snapshot identity deliberately excludes the `.mbti` filename. The
parent directory supplies package scope and the declaration supplies symbol
identity; the full path is kept only for diagnostics. This makes same-package
file moves compatibility-neutral without merging symbols from different
packages.

Legacy ignore rules only filter the report and derived recommendation. The
preferred policy layer retains the original report, records accepted changes
with their owning rules, and derives an effective report. Invalid, expired, or
over-budget rules accept nothing and block reliable CI decisions with exit code
`2`.

## Testing

Current tests cover:

- parsing public functions, structs, enums, traits, and aliases;
- parsing generic functions, methods, impls, struct fields, enum constructors,
  trait methods, `suberror`, and `pub using` type or trait exports;
- whitespace normalization;
- trailing comment stripping;
- added API detection;
- removed API detection;
- changed signature detection;
- unchanged API as patch;
- Markdown report rendering;
- JSON report rendering;
- SemVer parsing and version-bump validation;
- ignore-rule parsing and filtering;
- policy parsing, deadlines, default and explicit match budgets, unmatched and
  overlapping diagnostics, original/effective reports, and policy-aware
  release decisions;
- config parsing, path defaults, and command-line override behavior;
- package snapshot construction and diagnostics;
- same-package cross-file moves, cross-package same-name symbols, and
  same-package duplicate detection;
- package report, package check, and inventory rendering;
- CLI argument handling;
- JS-target file and directory CLI smoke tests;
- CLI check output and exit-code intent;
- release-plan ready, insufficient-bump, and diagnostic-blocked states;
- single-line/multi-line container normalization;
- unknown public declaration retention.

Validation commands:

```sh
moon fmt
moon info
moon check
moon test
moon test --target js
moon run cmd/main -- --version
moon run --target js cmd/main -- report fixtures/old.mbti fixtures/new.mbti --format json
moon run --target js cmd/main -- report --config fixtures/moonguard-ci.conf
moon run --target js cmd/main -- report-dir fixtures/dir-old fixtures/dir-new
moon run --target js cmd/main -- report-dir --config fixtures/moonguard-ci.conf
moon run --target js cmd/main -- check-dir fixtures/dir-old fixtures/dir-new --current 0.1.0 --next 1.0.0
moon run --target js cmd/main -- check-dir --config fixtures/moonguard-ci.conf
moon run --target js cmd/main -- release-plan --config fixtures/moonguard-ci.conf
moon run --target js cmd/main -- inventory-dir --config fixtures/moonguard-ci.conf
moon run --target js cmd/main -- inventory-dir fixtures/real --format json
node _build/js/debug/build/cmd/main/main.js check fixtures/old.mbti fixtures/new.mbti --current 0.1.0 --next 0.2.0
node _build/js/debug/build/cmd/main/main.js check --config fixtures/moonguard-ci.conf
node _build/js/debug/build/cmd/main/main.js check-dir fixtures/dir-old fixtures/dir-new --current 0.1.0 --next 1.0.0
node _build/js/debug/build/cmd/main/main.js check-dir --config fixtures/moonguard-ci.conf
```

Current local result:

```text
Total tests: 164, passed: 164, failed: 0.
JS target tests: 165, passed: 165, failed: 0.
Instrumented coverage: 2383/2808 lines (84.9%).
Core library coverage: 1940/2125 lines (91.3%).
```

The real-world corpus contains 15 pinned public interface snapshots from 15
repositories. It produces 6819 modeled API items, zero `unknown` items, and zero
snapshot diagnostics. All samples are fully modeled. The historical
`python.mbt` snapshot contributes 119 associated `fn`/`impl` lines without a
visibility prefix through generator-header-gated legacy inference.

The version-evolution evidence adds one self-hosted comparison and three pinned
external comparisons. The first self-comparison exposed a false major result
for members of an entirely new container. The diff engine now suppresses those
redundant nested changes while preserving major results for members added to an
existing container. The corrected `v0.1.0 -> v0.2.0` report recommends minor
and passes the proposed version check. See `docs/evidence/README.md`.

## Known Limits

- File-based CLI input currently requires the JS backend and Node runtime.
- Parser coverage is still line-oriented and intentionally focused on generated
  `.mbti` shapes rather than full MoonBit source syntax.
- Legacy inference currently depends on the historical `moon info` generator
  header and package declaration; other undocumented historical formats may
  still require new fixtures and parser rules.
- `moon run --target js` does not reliably propagate a nonzero JavaScript
  process exit status. The generated JS file does return the intended status
  when run directly with Node, so CI uses direct Node execution for strict
  failing `check` assertions.
- The tracked `.mbt` source total is currently 8580 lines excluding `_build`.
  Of these, 5215 are non-test lines, above the confirmed 4000-line competition
  threshold.

## Roadmap

Near-term work:

- Add native file input support when a stable MoonBit file IO path is available.
- Add baseline-oriented release commands that can save or consume published
  interface snapshots.
- Continue expanding the pinned real-world corpus when new MoonBit interface
  shapes appear.

## AI Collaboration Notes

AI assistance was used for ecosystem-gap analysis, project direction selection,
initial scoping, implementation drafting, and test iteration. The final direction
was chosen after comparing generic Markdown tooling with MoonBit-specific
engineering infrastructure needs.
