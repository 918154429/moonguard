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
- Parse simple CLI config files for shared `format`, `ignore_file`, `current`,
  `next`, `baseline`, `target`, `baseline_dir`, and `target_dir` defaults.
- Build package snapshots from multiple `.mbti` files.
- Compare package directories with file namespaces so same-named symbols in
  different files do not overwrite each other.
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

Current implementation is intentionally compact while the grammar is still
being validated:

- `moonguard.mbt`
  - public API model
  - interface parser
  - diff engine
  - SemVer recommendation and version-bump checks
  - ignore-rule parser and report filtering
  - package snapshot model and diagnostics
  - Markdown and JSON report renderers
- `cmd/main/main.mbt`
  - CLI entry point for text, file, directory, inventory, check, check-dir, and
    shared config defaults
- `cmd/main/read_file_js.mbt`
  - JS backend file and directory reading through Node APIs
- `cmd/main/read_file_nonjs.mbt`
  - clear fallback message for non-JS backends
- `moonguard_test.mbt`
  - black-box behavior tests
- `moonguard_wbtest.mbt`
  - package-scope parser tests

The next step is to split parser, model, diff, semver, report, and CLI into
separate modules once more grammar coverage is added.

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

Ignore rules only filter the rendered report and derived recommendation. They
do not change `parse_interface`, raw snapshots, or the underlying API model.

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
- config parsing, path defaults, and command-line override behavior;
- package snapshot construction and diagnostics;
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
Total tests: 139, passed: 139, failed: 0.
Instrumented coverage: 1900/2183 lines (87.0%).
```

The real-world corpus contains 15 pinned public interface snapshots from 15
repositories. It produces 6700 modeled API items, zero `unknown` items, and zero
snapshot diagnostics. Fourteen modern-format samples are fully modeled. One
historical `python.mbt` snapshot contains 119 associated `fn`/`impl` lines
without a visibility prefix and is explicitly marked partial rather than being
presented as fully covered.

## Known Limits

- File-based CLI input currently requires the JS backend and Node runtime.
- Parser coverage is still line-oriented and intentionally focused on generated
  `.mbti` shapes rather than full MoonBit source syntax.
- Historical interface files can contain unqualified associated methods or
  `impl` lines. The corpus analyzer reports them, but the compatibility model
  does not yet include them.
- `moon run --target js` does not reliably propagate a nonzero JavaScript
  process exit status. The generated JS file does return the intended status
  when run directly with Node, so CI uses direct Node execution for strict
  failing `check` assertions.
- The tracked `.mbt` source total is currently 7098 lines excluding `_build`.
  Future implementation slices should keep the project comfortably above the
  5000-line competition threshold.

## Roadmap

Near-term work:

- Add native file input support when a stable MoonBit file IO path is available.
- Split implementation into parser, model, diff, semver, report, and CLI
  modules.
- Add baseline-oriented release commands that can save or consume published
  interface snapshots.
- Add a legacy interface mode for unqualified associated methods and `impl`
  declarations.
- Continue expanding the pinned real-world corpus when new MoonBit interface
  shapes appear.

## AI Collaboration Notes

AI assistance was used for ecosystem-gap analysis, project direction selection,
initial scoping, implementation drafting, and test iteration. The final direction
was chosen after comparing generic Markdown tooling with MoonBit-specific
engineering infrastructure needs.
