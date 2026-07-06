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

## Current MVP

The MVP implements a pure library workflow:

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
- Preserve unrecognized public declarations as `unknown`.
- Detect added public API as `minor`.
- Detect removed public API as `major`.
- Detect changed public signatures as `major`.
- Render Markdown compatibility reports.
- Provide a small CLI demo command:

```sh
moon run cmd/main -- report "pub fn old() -> Unit" "pub fn new() -> Unit"
```

## Architecture

Current implementation is intentionally compact while the grammar is still
being validated:

- `moonguard.mbt`
  - public API model
  - interface parser
  - diff engine
  - SemVer recommendation
  - Markdown report renderer
- `cmd/main/main.mbt`
  - CLI demo entry point
- `moonguard_test.mbt`
  - black-box behavior tests
- `moonguard_wbtest.mbt`
  - package-scope parser tests

The next step is to split parser, model, diff, semver, report, and CLI into
separate modules once more grammar coverage is added.

## Design Decisions

The parser starts from `.mbti`-style public declaration lines instead of trying
to parse all MoonBit source syntax. This keeps the MVP focused on release
compatibility, which is the actual workflow MoonGuard needs to support.

Compatibility rules are conservative:

- Removing public API is breaking.
- Changing a public signature is breaking.
- Adding public API is minor-compatible.
- No public API model change is patch.

Unrecognized `pub` lines are not discarded. They are retained as `unknown`
items so that public surface changes remain visible until the parser gains
first-class support for that syntax.

## Testing

Current tests cover:

- parsing public functions, structs, enums, traits, and aliases;
- whitespace normalization;
- trailing comment stripping;
- added API detection;
- removed API detection;
- changed signature detection;
- unchanged API as patch;
- Markdown report rendering;
- unknown public declaration retention.

Validation commands:

```sh
moon fmt
moon info
moon check
moon test
moon run cmd/main -- --version
```

Current local result:

```text
Total tests: 8, passed: 8, failed: 0.
```

## Known Limits

- File-based CLI input is not implemented yet. The current CLI accepts two
  interface snapshots as arguments.
- Parser coverage is still line-oriented and does not yet model nested enum
  constructors or struct fields.
- JSON report output is planned but not implemented in the MVP.
- Directory/package-level comparison is planned but not implemented in the MVP.

## Roadmap

Near-term work:

- Add file input support for CLI.
- Split implementation into parser, model, diff, semver, report, and CLI
  modules.
- Add fixtures based on generated `.mbti` files.
- Add JSON report output.
- Add package-directory comparison.
- Add rule documentation with concrete breaking/minor examples.
- Add GitHub Actions usage documentation.

## AI Collaboration Notes

AI assistance was used for ecosystem-gap analysis, project direction selection,
MVP scoping, implementation drafting, and test iteration. The final direction
was chosen after comparing generic Markdown tooling with MoonBit-specific
engineering infrastructure needs.
