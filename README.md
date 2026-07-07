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
  - added public API -> minor
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
  diagnostics, and render snapshot inventories.
- Read `.mbti` files and directories from the CLI when running on the JS
  backend.

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
```

```sh
moon run --target js cmd/main -- check fixtures/old.mbti fixtures/new.mbti --config fixtures/moonguard-ci.conf
```

Compare package directories and inspect a generated interface inventory:

```sh
moon run --target js cmd/main -- report-dir fixtures/dir-old fixtures/dir-new
moon run --target js cmd/main -- check-dir fixtures/dir-old fixtures/dir-new --current 0.1.0 --next 1.0.0
moon run --target js cmd/main -- inventory-dir fixtures/dir-new --format json
```

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

## Compatibility Rules

MoonGuard starts with conservative rules:

- Removing a public declaration is a breaking change.
- Changing a public signature is a breaking change.
- Adding a public declaration is a minor-compatible change.
- Reordering declarations, changing comments, or changing whitespace does not
  affect the public API model.

The parser intentionally covers high-frequency `.mbti` declarations first,
including common nested members from generated interface files. Any
unrecognized `pub` line is retained as `unknown` so that public surface changes
remain visible instead of being silently ignored.

## Development

Common checks:

```sh
moon fmt
moon info
moon check
moon test
moon run --target js cmd/main -- report fixtures/old.mbti fixtures/new.mbti --format json
moon run --target js cmd/main -- report fixtures/old.mbti fixtures/new.mbti --config fixtures/moonguard-ci.conf
moon run --target js cmd/main -- report-dir fixtures/dir-old fixtures/dir-new
moon run --target js cmd/main -- check-dir fixtures/dir-old fixtures/dir-new --current 0.1.0 --next 1.0.0
moon run --target js cmd/main -- inventory-dir fixtures/dir-new
node _build/js/debug/build/cmd/main/main.js check fixtures/old.mbti fixtures/new.mbti --current 0.1.0 --next 0.2.0
node _build/js/debug/build/cmd/main/main.js check-dir fixtures/dir-old fixtures/dir-new --current 0.1.0 --next 1.0.0
```

Generated `pkg.generated.mbti` files are kept in the repository so interface
changes are reviewable after `moon info`.

Competition source-line tracking counts repository `.mbt` source files and
excludes generated `_build` output. The current tracked source total is 5873
lines, so future code changes should keep the project above the 5000-line
threshold.

See [docs/competition-plan.md](docs/competition-plan.md) for the competition
plan.
