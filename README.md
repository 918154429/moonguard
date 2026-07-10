# MoonGuard

MoonGuard is a MoonBit public API compatibility and SemVer guard. It compares
two MoonBit interface snapshots, reports public API additions, removals, and
signature changes, then recommends whether the next release should be patch,
minor, or major.

The project is being built for the MoonBit open-source ecosystem competition as
engineering infrastructure for package authors and CI workflows.

## Current Features

- Parse public declarations from `.mbti`-style interface text.
- Normalize whitespace and declaration order.
- Track public `fn`, `type`, `typealias`, `struct`, `enum`, `trait`, `impl`,
  `let`, and `const` declarations.
- Track common generated `.mbti` members including struct fields, enum
  constructors, trait methods, generic methods, `suberror`, and `pub using`
  type or trait exports.
- Classify public API changes:
  - added top-level public API -> minor
  - added struct fields, enum/suberror constructors, or required trait methods
    -> major (conservative)
  - removed public API -> major
  - changed signature -> major
  - unchanged public API -> patch
- Render Markdown and JSON compatibility reports for PR comments, release
  notes, and downstream tooling.
- Validate whether a proposed SemVer bump satisfies the recommended impact for
  single-file or package-directory comparisons.
- Filter accepted or experimental changes with simple ignore rules.
- Share repeated CLI defaults through simple config files.
- Compare package directories, detect duplicate symbols and directory
  diagnostics, ignore generated/vendor/tool directories, and render snapshot
  inventories.
- Read `.mbti` files and directories from the CLI when running on the JS
  backend.
- Render package release plans that combine API impact, diagnostics, SemVer
  validation, and maintainer checklist items for release PRs.

## Installation

Install the MoonBit toolchain, then clone this repository:

```sh
git clone https://github.com/918154429/moonguard.git
cd moonguard
moon check
moon test
```

## Library Usage

```moonbit
let old_api = "pub fn render(String) -> String"
let new_api = "pub fn render(String, Options) -> String"

let report = @moonguard.diff_interfaces(old_api, new_api)
let markdown = @moonguard.render_markdown_report(report)
```

The report recommendation is `patch`, `minor`, or `major`.

## CLI Usage

Compare two `.mbti` files with the default Markdown report:

```sh
moon run --target js cmd/main -- report fixtures/old.mbti fixtures/new.mbti
```

Output:

```md
# MoonGuard API Compatibility Report

- Recommendation: **major**
- Changes: 2

| Impact | Change | Symbol | Details |
| --- | --- | --- | --- |
| major | changed | `fn render` | `render(String) -> String` -> `render(String, Options) -> String` |
| minor | added | `fn parse` | `parse(String) -> Unit` |
```

Render the same report as JSON:

```sh
moon run --target js cmd/main -- report fixtures/old.mbti fixtures/new.mbti --format json
```

Check whether a planned version bump is sufficient:

```sh
moon run --target js cmd/main -- check fixtures/old.mbti fixtures/new.mbti --current 0.1.0 --next 0.2.0
```

Use a config file for repeated CI defaults:

```text
format = json
current = 0.1.0
next = 1.0.0
baseline = fixtures/old.mbti
target = fixtures/new.mbti
baseline_dir = fixtures/dir-old
target_dir = fixtures/dir-new
```

```sh
moon run --target js cmd/main -- report --config fixtures/moonguard-ci.conf
moon run --target js cmd/main -- check --config fixtures/moonguard-ci.conf
```

Compare package directories and inspect a generated interface inventory:

```sh
moon run --target js cmd/main -- report-dir fixtures/dir-old fixtures/dir-new
moon run --target js cmd/main -- check-dir fixtures/dir-old fixtures/dir-new --current 0.1.0 --next 1.0.0
moon run --target js cmd/main -- release-plan fixtures/dir-old fixtures/dir-new --current 0.1.0 --next 1.0.0
moon run --target js cmd/main -- inventory-dir fixtures/dir-new --format json
moon run --target js cmd/main -- report-dir --config fixtures/moonguard-ci.conf
moon run --target js cmd/main -- check-dir --config fixtures/moonguard-ci.conf
moon run --target js cmd/main -- release-plan --config fixtures/moonguard-ci.conf
moon run --target js cmd/main -- inventory-dir --config fixtures/moonguard-ci.conf
```

The release-plan command is intended for application-facing package workflows:
it prints whether a release is ready, blocked by snapshot diagnostics, or needs
a larger version bump, then includes checklist items for release notes and
migration review.

Ignore files filter report changes without changing the parsed API model:

```text
ignore fn debug_tmp temporary demo API
ignore field Options.experimental
ignore * pkg.generated.mbti::internal_*
```

```sh
moon run --target js cmd/main -- report fixtures/old.mbti fixtures/new.mbti --ignore-file fixtures/ignore-render.rules
```

File and directory commands currently require the JS backend because the CLI
uses Node `fs.readFileSync` and directory APIs through MoonBit JS externs.
For strict CI exit-code checks, run the generated JS with Node directly after a
JS-target command has built it:

```sh
node _build/js/debug/build/cmd/main/main.js check fixtures/old.mbti fixtures/new.mbti --current 0.1.0 --next 0.2.0
node _build/js/debug/build/cmd/main/main.js check-dir fixtures/dir-old fixtures/dir-new --current 0.1.0 --next 1.0.0
```

For quick demos without files, use `report-text`:

```sh
moon run cmd/main -- report-text "pub fn render(String) -> String" "pub fn render(String, Options) -> String" --format json
```

## GitHub Actions

MoonGuard can compare a committed release baseline with interfaces generated in
a pull request, fail on an insufficient version bump, and upload a JSON release
plan. See [docs/github-actions.md](docs/github-actions.md) for a complete
downstream workflow pinned to the `v0.1.0` release.

## Compatibility Rules

MoonGuard starts with conservative rules:

- Removing a public declaration is a breaking change.
- Changing a public signature is a breaking change.
- Adding an ordinary top-level public declaration is minor-compatible.
- Adding a struct field, enum/suberror constructor, or required trait method is
  conservatively breaking because it can invalidate construction, exhaustive
  matching, or existing trait implementations.
- Reordering declarations, changing comments, or changing whitespace does not
  affect the public API model.

The parser intentionally covers high-frequency `.mbti` declarations first,
including common nested members from generated interface files. Any
unrecognized `pub` line is retained as `unknown` so that public surface changes
remain visible instead of being silently ignored.

The complete rule table and rationale are in
[docs/api-compat-rules.md](docs/api-compat-rules.md).

## Real-World Validation

The repository includes 15 pinned public `pkg.generated.mbti` samples from
official and community MoonBit projects. MoonGuard currently extracts 6700 API
items from this corpus with zero unknown declarations and zero snapshot
diagnostics. Fourteen modern-format samples are fully modeled; one historical
sample is marked partial because 119 legacy associated `fn`/`impl` lines do not
carry a public visibility prefix and are intentionally reported as a known
coverage gap.

- Sources, revisions, and licenses:
  [fixtures/real/SOURCES.md](fixtures/real/SOURCES.md)
- Per-sample compatibility matrix:
  [docs/real-world-compatibility.md](docs/real-world-compatibility.md)
- Reproducible demo and validation record:
  [docs/demo-report.md](docs/demo-report.md)

## Development

Common checks:

```sh
moon fmt
moon info
moon check
moon test
moon run --target js cmd/main -- report fixtures/old.mbti fixtures/new.mbti --format json
moon run --target js cmd/main -- report --config fixtures/moonguard-ci.conf
moon run --target js cmd/main -- report-dir fixtures/dir-old fixtures/dir-new
moon run --target js cmd/main -- report-dir --config fixtures/moonguard-ci.conf
moon run --target js cmd/main -- check-dir fixtures/dir-old fixtures/dir-new --current 0.1.0 --next 1.0.0
moon run --target js cmd/main -- check-dir --config fixtures/moonguard-ci.conf
moon run --target js cmd/main -- release-plan --config fixtures/moonguard-ci.conf
moon run --target js cmd/main -- inventory-dir --config fixtures/moonguard-ci.conf
node _build/js/debug/build/cmd/main/main.js check fixtures/old.mbti fixtures/new.mbti --current 0.1.0 --next 0.2.0
node _build/js/debug/build/cmd/main/main.js check --config fixtures/moonguard-ci.conf
node _build/js/debug/build/cmd/main/main.js check-dir fixtures/dir-old fixtures/dir-new --current 0.1.0 --next 1.0.0
node _build/js/debug/build/cmd/main/main.js check-dir --config fixtures/moonguard-ci.conf
```

Generated `pkg.generated.mbti` files are kept in the repository so interface
changes are reviewable after `moon info`.

Competition source-line tracking counts repository `.mbt` source files and
excludes generated `_build` output. The current tracked source total is 7098
lines, so future code changes should keep the project above the 5000-line
threshold.

See [docs/competition-plan.md](docs/competition-plan.md) for the competition
plan.
