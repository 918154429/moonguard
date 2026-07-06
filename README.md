# MoonGuard

MoonGuard is a MoonBit public API compatibility and SemVer guard. It compares
two MoonBit interface snapshots, reports public API additions, removals, and
signature changes, then recommends whether the next release should be patch,
minor, or major.

The project is being built for the MoonBit open-source ecosystem competition as
engineering infrastructure for package authors and CI workflows.

## MVP Features

- Parse public declarations from `.mbti`-style interface text.
- Normalize whitespace and declaration order.
- Track public `fn`, `type`, `typealias`, `struct`, `enum`, `trait`, `impl`,
  `let`, and `const` declarations.
- Track common generated `.mbti` members including struct fields, enum
  constructors, trait methods, generic methods, `suberror`, and `pub using`
  exports.
- Classify public API changes:
  - added public API -> minor
  - removed public API -> major
  - changed signature -> major
  - unchanged public API -> patch
- Render a Markdown compatibility report suitable for PR comments or release
  notes.
- Read `.mbti` files from the CLI when running on the JS backend.

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

Compare two `.mbti` files:

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

The file-reading command currently requires the JS backend because the MVP uses
Node `fs.readFileSync` through a MoonBit JS extern.

For quick demos without files, use `report-text`:

```sh
moon run cmd/main -- report-text "pub fn render(String) -> String" "pub fn render(String, Options) -> String"
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
moon info
moon fmt
moon check
moon test
moon run --target js cmd/main -- report fixtures/old.mbti fixtures/new.mbti
```

Generated `pkg.generated.mbti` files are kept in the repository so interface
changes are reviewable after `moon info`.

See [docs/competition-plan.md](docs/competition-plan.md) for the competition
plan.
