# MoonGuard Handoff

This document is a practical handoff note for the next engineer or agent
continuing MoonGuard.

## Project Snapshot

Repository:

- GitHub: `https://github.com/918154429/moonguard`
- Local path:
  `E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\moonguard`
- Main branch: `master`
- Current latest commit: `91a3930 Add file-based CLI report mode`
- CI status at handoff: passing

Toolchain used locally:

- `E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe`
- Observed version earlier in this workstream: `moon 0.1.20260608`

## What MoonGuard Does

MoonGuard compares two MoonBit public interface snapshots and reports API
compatibility changes.

Current flow:

```text
old .mbti text -> parse_interface -> API model \
                                             -> diff -> SemVer impact -> Markdown report
new .mbti text -> parse_interface -> API model /
```

Current impact rules:

- Added public API -> `minor`
- Removed public API -> `major`
- Changed public signature -> `major`
- No public API model change -> `patch`
- Nested public surface such as struct fields, enum constructors, trait methods,
  and suberror constructors use the same rules.

## Implemented Capabilities

Library API in `moonguard.mbt`:

- `parse_interface(text : String) -> Array[ApiItem]`
- `diff_interfaces(old_text : String, new_text : String) -> ApiReport`
- `diff_items(old_items : Array[ApiItem], new_items : Array[ApiItem]) -> ApiReport`
- `render_markdown_report(report : ApiReport) -> String`
- `semver_recommendation(old_text : String, new_text : String) -> String`

Public model:

- `ApiItem`
- `ApiChange`
- `ApiReport`
- `ChangeKind`
- `Impact`

CLI in `cmd/main`:

- File mode:

```sh
moon run --target js cmd/main -- report fixtures/old.mbti fixtures/new.mbti
```

- Text mode:

```sh
moon run cmd/main -- report-text "pub fn old() -> Unit" "pub fn new() -> Unit"
```

Important CLI detail:

- File mode currently requires `--target js`.
- `cmd/main/read_file_js.mbt` uses Node `fs.readFileSync`.
- `cmd/main/read_file_nonjs.mbt` returns a clear fallback error for non-JS
  targets.
- `cmd/main/moon.pkg` selects those files with `options(targets: ...)`.

## Current Tests and Fixtures

Test files:

- `moonguard_test.mbt`
- `moonguard_wbtest.mbt`
- `cmd/main/main_wbtest.mbt`

Fixtures:

- `fixtures/old.mbti`
- `fixtures/new.mbti`

Current local result:

```text
Total tests: 19, passed: 19, failed: 0.
```

GitHub Actions:

- `moon check`
- `moon test`
- `moon run --target js cmd/main -- report fixtures/old.mbti fixtures/new.mbti`
- `moon fmt` plus `git diff --exit-code`

## Verification Commands

Run from the repository root:

```powershell
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' fmt
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' info
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' check
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' test
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' run --target js cmd/main -- report fixtures/old.mbti fixtures/new.mbti
```

Check GitHub Actions:

```powershell
gh run list --repo 918154429/moonguard --limit 5
```

## Current Limitations

- Parser is line-oriented and intentionally conservative.
- It now models common generated `.mbti` nested members, but it is still not a
  full MoonBit source parser.
- JSON report output is not implemented.
- Native file input is not implemented; file mode is JS target only.
- Exit codes are not yet expressive. The CLI prints reports/errors, but does
  not yet fail CI on breaking changes.
- Package/directory-level comparison is not implemented.

## Recommended Next Slice

The strongest next slice is CI-oriented behavior and machine-readable output.

Recommended scope:

- Add `--format markdown|json`.
- Add JSON report output for machine consumption.
- Add a `check` command that exits non-zero for `major` recommendations.
- Document a GitHub Actions usage snippet.

Why this next:

- File-based CLI is already usable.
- Parser coverage now handles common generated interface shapes.
- JSON and check mode make the tool easier to wire into CI and downstream
  tooling.

Suggested check mode:

```sh
moon run --target js cmd/main -- check old.mbti new.mbti
```

Expected behavior:

- exit success for patch/minor;
- exit failure for major;
- print the same Markdown report or a concise error summary.

This likely needs checking how to exit with status codes in the current
MoonBit runtime. `moonbitlang/core/argparse` has runtime exit internals that may
be useful to study.

## Important Implementation Notes

- Keep `pkg.generated.mbti` files tracked. They are intentionally committed so
  interface changes are reviewable.
- Use `moon.pkg` `targets` mapping for target-specific files. Do not rely on
  filename suffixes alone.
- Be careful with `@env.args()` on JS target. It returns full `process.argv`,
  so `cmd/main/main.mbt` normalizes arguments by finding the first known command
  or flag.
- Avoid adding a full MoonBit source parser. The project is scoped around
  interface snapshots, not source syntax.
- Keep compatibility rules conservative. If a public item is hard to classify,
  prefer making it visible rather than silently ignoring it.

## Competition Positioning

Use this positioning in申报/展示材料:

> MoonGuard is a MoonBit public API compatibility and SemVer guard. It reads
> MoonBit interface snapshots, detects public API changes, and generates CI- and
> release-friendly compatibility reports.

Comparable tools in mature ecosystems:

- Rust: `cargo-semver-checks`
- Go: `golang.org/x/exp/apidiff`
- TypeScript: API Extractor
- Java: Revapi / japicmp

MoonGuard is not a direct port. It is a MoonBit-specific tool built around
`.mbti` interface snapshots and MoonBit package workflows.
