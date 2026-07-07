# MoonGuard Handoff

This document is a practical handoff note for the next engineer or agent
continuing MoonGuard.

## Project Snapshot

Repository:

- GitHub: `https://github.com/918154429/moonguard`
- Local path:
  `E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\moonguard`
- Main branch: `master`
- CI expectation: `moon check`, `moon test`, CLI smoke tests, direct Node check
  exit-code tests, and `moon fmt` diff checks should pass.

Toolchain used locally:

- `E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe`
- The repository also works with the MoonBit toolchain installed in GitHub
  Actions through `https://cli.moonbitlang.com/install/unix.sh`.

Workflow requirement:

- Keep implementation slices small.
- Commit each slice with author and sign-off:
  `Q <918154429@users.noreply.github.com>`.
- Push each completed slice to `origin master`.

## What MoonGuard Does

MoonGuard compares MoonBit public interface snapshots and reports API
compatibility changes.

Current flow:

```text
old .mbti text/files -> parse/snapshot -> API model \
                                                    -> diff -> report/check
new .mbti text/files -> parse/snapshot -> API model /
```

Current impact rules:

- Added public API -> `minor`
- Removed public API -> `major`
- Changed public signature -> `major`
- No public API model change -> `patch`
- Nested public surface such as struct fields, enum constructors, trait
  methods, and suberror constructors uses the same rules.

Version-bump checks:

- `major` recommendation requires a major version increase.
- `minor` recommendation accepts a minor or major version increase.
- `patch` recommendation accepts any non-decreasing version.

## Implemented Capabilities

Library API in `moonguard.mbt` includes:

- Parser and diff: `parse_interface`, `parse_interface_with_namespace`,
  `diff_interfaces`, `diff_items`, `diff_api_snapshots`,
  `compare_api_snapshots`, `compare_api_file_sets`.
- Reports: `render_markdown_report`, `render_json_report`,
  `render_markdown_package_report`, `render_json_package_report`,
  `render_markdown_package_check_result`,
  `render_json_package_check_result`,
  `render_markdown_snapshot_inventory`, `render_json_snapshot_inventory`.
- SemVer: `parse_version`, `compare_versions`, `check_version_bump`,
  `check_interface_version_bump`, `render_version_check_markdown`,
  `render_json_check_result`.
- Ignore rules: `parse_ignore_rules`, `filter_report`,
  `filter_report_with_rules`.
- Snapshot helpers and summaries: `api_file`, `build_api_snapshot`,
  `summarize_report`, `summarize_diagnostics`, `count_items_by_kind`,
  `merge_diagnostics`.

Public models include:

- `ApiItem`, `ApiChange`, `ApiReport`
- `Version`, `VersionCheck`
- `ApiIgnoreRule`, `IgnoreParseResult`
- `ApiFile`, `ApiDiagnostic`, `ApiSnapshot`, `ApiPackageComparison`
- `ApiSummary`, `DiagnosticSummary`, `ApiKindCount`

CLI in `cmd/main` supports:

```sh
moon run --target js cmd/main -- report old.mbti new.mbti [--format markdown|json] [--ignore-file path]
moon run --target js cmd/main -- report-dir old_dir new_dir [--format markdown|json] [--ignore-file path]
moon run --target js cmd/main -- inventory-dir dir [--format markdown|json]
moon run --target js cmd/main -- check old.mbti new.mbti --current 0.1.0 --next 0.2.0 [--format markdown|json] [--ignore-file path]
moon run --target js cmd/main -- check-dir old_dir new_dir --current 0.1.0 --next 0.2.0 [--format markdown|json] [--ignore-file path]
moon run cmd/main -- report-text "pub fn old() -> Unit" "pub fn new() -> Unit" [--format markdown|json] [--ignore-file path]
```

Important CLI detail:

- File and directory commands currently require `--target js`.
- `cmd/main/read_file_js.mbt` uses Node APIs for file and directory input.
- `cmd/main/read_file_nonjs.mbt` returns clear fallback errors for non-JS
  targets.
- Direct Node execution of `_build/js/debug/build/cmd/main/main.js` propagates
  the intended nonzero exit status for failing `check` and `check-dir`
  commands.
- `moon run --target js` may not propagate that nonzero JavaScript exit status,
  so CI should use direct Node execution when it needs to assert failure.

Ignore files use one rule per line:

```text
ignore fn debug_tmp temporary demo API
ignore field Options.experimental
ignore * pkg.generated.mbti::internal_*
```

Ignore rules filter report changes and recommendations. They do not change the
raw parser or snapshot output.

## Tests, Fixtures, And CI

Test files:

- `moonguard_test.mbt`
- `moonguard_wbtest.mbt`
- `cmd/main/main_wbtest.mbt`

Fixtures:

- `fixtures/old.mbti`
- `fixtures/new.mbti`
- `fixtures/ignore-render.rules`
- `fixtures/dir-old`
- `fixtures/dir-new`
- `fixtures/dir-duplicate`
- `fixtures/dir-no-mbti`

Current local test result:

```text
Total tests: 119, passed: 119, failed: 0.
```

GitHub Actions should cover:

- `moon check`
- `moon test`
- Markdown and JSON CLI report smoke tests
- directory report, directory check, and inventory smoke tests
- direct Node `check` and `check-dir` success and failure exit-code assertions
- `moon fmt` plus `git diff --exit-code`

## Verification Commands

Run from the repository root:

```powershell
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' fmt
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' info
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' check
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' test
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' run --target js cmd/main -- report fixtures/old.mbti fixtures/new.mbti --format json
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' run --target js cmd/main -- report-dir fixtures/dir-old fixtures/dir-new
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' run --target js cmd/main -- check-dir fixtures/dir-old fixtures/dir-new --current 0.1.0 --next 1.0.0
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' run --target js cmd/main -- inventory-dir fixtures/dir-new
node _build\js\debug\build\cmd\main\main.js check fixtures/old.mbti fixtures/new.mbti --current 0.1.0 --next 0.2.0
node _build\js\debug\build\cmd\main\main.js check-dir fixtures/dir-old fixtures/dir-new --current 0.1.0 --next 1.0.0
```

Check GitHub Actions:

```powershell
gh run list --repo 918154429/moonguard --limit 5
```

## Current Limits

- Parser is line-oriented and intentionally conservative.
- It models common generated `.mbti` nested members, but it is not a full
  MoonBit source parser.
- Native file and directory input is not implemented; CLI file/directory mode
  is JS target only.
- Source-line competition tracking counts repository `.mbt` files and excludes
  generated `_build` output. Current tracked source total is 5421 lines, so
  future implementation slices should keep a buffer above the 5000-line
  threshold.

## Recommended Next Slices

Strong next options:

- Add a baseline workflow for comparing a package against a saved release
  interface snapshot.
- Add lightweight configuration support for repeated CLI options such as
  current version, next version, report format, and ignore file.
- Mine more real toolchain/core `.mbti` files for parser edge cases.
- Split the large implementation into parser, model, diff, semver, report, and
  CLI-focused modules once the public API shape is stable.

## Competition Positioning

Use this positioning in submission and demo material:

> MoonGuard is a MoonBit public API compatibility and SemVer guard. It reads
> MoonBit interface snapshots, detects public API changes, validates version
> bumps, and generates CI- and release-friendly Markdown or JSON reports.

Comparable tools in mature ecosystems:

- Rust: `cargo-semver-checks`
- Go: `golang.org/x/exp/apidiff`
- TypeScript: API Extractor
- Java: Revapi / japicmp

MoonGuard is not a direct port. It is a MoonBit-specific tool built around
`.mbti` interface snapshots and MoonBit package workflows.
