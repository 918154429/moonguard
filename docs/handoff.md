# MoonGuard Handoff

This document is a practical handoff note for the next engineer or agent
continuing MoonGuard.

## Project Snapshot

Repository:

- GitHub: `https://github.com/918154429/moonguard`
- Local path:
  `E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\moonguard`
- Main branch: `master`
- CI expectation: `moon check`, `moon test`, `moon test --target js`, CLI smoke tests, direct Node check
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

For directory input, logical API identity is parent-directory package scope
plus symbol identity. The source `.mbti` filename is diagnostic provenance, so
moving a symbol between files in one package produces no change; same-named
symbols in different package directories remain distinct.

Current impact rules:

- Added ordinary top-level public API -> `minor`
- Added struct field, enum/suberror constructor, or required trait method ->
  `major` (conservative)
- Removed public API -> `major`
- Changed public signature -> `major`
- No public API model change -> `patch`
- Inline and multi-line struct, enum, trait, and suberror layouts normalize to
  the same API model.

Version-bump checks:

- `major` recommendation requires a major version increase.
- `minor` recommendation accepts a minor or major version increase.
- `patch` recommendation accepts any greater version.

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
- Release workflow: `make_release_plan`, `render_markdown_release_plan`,
  `render_json_release_plan`.
- SemVer: `parse_version`, `compare_versions`, `check_version_bump`,
  `check_interface_version_bump`, `render_version_check_markdown`,
  `render_json_check_result`.
- Ignore rules: `parse_ignore_rules`, `filter_report`,
  `filter_report_with_rules`.
- Auditable policy: `parse_policy_rules`, `evaluate_policy`,
  `evaluate_policy_text`, `policy_diagnostics_have_errors`,
  `make_policy_release_plan`, `render_markdown_policy_evaluation`,
  `render_json_policy_evaluation`, `render_markdown_policy_release_plan`,
  `render_json_policy_release_plan`.
- Snapshot helpers and summaries: `api_file`, `build_api_snapshot`,
  `summarize_report`, `summarize_diagnostics`, `count_items_by_kind`,
  `merge_diagnostics`.

Public models include:

- `ApiItem`, `ApiChange`, `ApiReport`
- `Version`, `VersionCheck`
- `ApiIgnoreRule`, `IgnoreParseResult`
- `ApiPolicyRule`, `PolicyParseResult`, `AcceptedApiChange`,
  `ApiPolicyDiagnostic`, `PolicySummary`, `ApiPolicyEvaluation`,
  `PolicyReleasePlan`
- `ApiFile`, `ApiDiagnostic`, `ApiSnapshot`, `ApiPackageComparison`
- `ApiSummary`, `DiagnosticSummary`, `ApiKindCount`
- `ReleasePlan`

CLI in `cmd/main` supports:

```sh
moon run --target js cmd/main -- report old.mbti new.mbti [--format markdown|json] [--ignore-file path | --policy-file path] [--policy-version version]
moon run --target js cmd/main -- report-dir old_dir new_dir [--format markdown|json] [--ignore-file path | --policy-file path] [--policy-version version]
moon run --target js cmd/main -- inventory-dir dir [--format markdown|json]
moon run --target js cmd/main -- check old.mbti new.mbti --current 0.1.0 --next 0.2.0 [--format markdown|json] [--ignore-file path | --policy-file path] [--policy-version version]
moon run --target js cmd/main -- check-dir old_dir new_dir --current 0.1.0 --next 0.2.0 [--format markdown|json] [--ignore-file path | --policy-file path] [--policy-version version]
moon run --target js cmd/main -- release-plan old_dir new_dir --current 0.1.0 --next 0.2.0 [--format markdown|json] [--ignore-file path | --policy-file path] [--policy-version version]
moon run cmd/main -- report-text "pub fn old() -> Unit" "pub fn new() -> Unit" [--format markdown|json] [--ignore-file path | --policy-file path] [--policy-version version]
```

All report and check commands also accept `--config path`. Config files use
simple `key = value` lines for `format`, `ignore_file`, `policy_file`,
`policy_version`, `current`, `next`, `baseline`, `target`, `baseline_dir`, and
`target_dir`. File and directory
commands may omit positional paths when the corresponding config defaults are
present. Command-line positional paths and options override config defaults.

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

Prefer policy files for new release governance:

```text
allow changed fn render until 0.2.0 max_matches 1 reason render migration reviewed
allow removed fn legacy_* max_matches 2 reason legacy cleanup approved
```

Policy syntax is `allow CHANGE_KIND ITEM_KIND NAME [until VERSION]
[max_matches N] reason TEXT...`. The reason is required, `max_matches` defaults
to `1`, and change kind may be `added`, `removed`, `changed`, or `*`. Policy
evaluation retains original and effective reports plus accepted-change audit
records. Expired, malformed, missing-version, and over-budget policies fail
closed. `check`, `check-dir`, and `release-plan` fall back to `--next` as the
policy version. `--ignore-file` and `--policy-file` are mutually exclusive;
`inventory-dir` rejects policy files.

CLI exit codes are `0` for success/sufficient bump, `1` for an insufficient
version bump after valid evaluation, and `2` for input, config, snapshot, or
policy errors that prevent a reliable decision.

Core modules are now split into `api_model.mbt`, `parser.mbt`, `snapshot.mbt`,
`diff.mbt`, `semver.mbt`, `policy.mbt`, `report_markdown.mbt`, and
`report_json.mbt`. CLI responsibilities are split across `args.mbt`,
`config.mbt`, `commands.mbt`, `output.mbt`, `snapshot_io.mbt`, and the two
backend I/O files under `cmd/main`.

## Tests, Fixtures, And CI

Test files:

- `moonguard_test.mbt`
- `moonguard_wbtest.mbt`
- `policy_test.mbt`
- `policy_wbtest.mbt`
- `cmd/main/main_wbtest.mbt`
- `cmd/main/main_js_wbtest.mbt`
- `cmd/main/main_nonjs_wbtest.mbt`

Fixtures:

- `fixtures/old.mbti`
- `fixtures/new.mbti`
- `fixtures/ignore-render.rules`
- `fixtures/allow-render.policy`
- `fixtures/allow-dir.policy`
- `fixtures/expired-render.policy`
- `fixtures/moonguard-policy.conf`
- `fixtures/dir-old`
- `fixtures/dir-new`
- `fixtures/dir-duplicate`
- `fixtures/dir-no-mbti`
- `fixtures/real` (15 pinned public interface snapshots with provenance)

Current local test result:

```text
Default target: 162 tests, passed: 162, failed: 0.
JS target: 163 tests, passed: 163, failed: 0.
Instrumented coverage: 1900/2183 lines (87.0%).
```

GitHub Actions should cover:

- `moon check`
- `moon test`
- `moon test --target js`
- Markdown and JSON CLI report smoke tests
- config-driven CLI smoke tests
- directory report, directory check, and inventory smoke tests
- release-plan Markdown/JSON/config smoke tests
- policy CLI/config, audit rendering, fail-closed diagnostics, and effective
  SemVer assertions
- direct Node `check`, `check-dir`, and `release-plan` exit-code assertions
- `moon fmt` plus `git diff --exit-code`

## Verification Commands

Run from the repository root:

```powershell
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' fmt
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' info
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' check
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' test
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' run --target js cmd/main -- report fixtures/old.mbti fixtures/new.mbti --format json
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' run --target js cmd/main -- report --config fixtures/moonguard-ci.conf
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' run --target js cmd/main -- report-dir fixtures/dir-old fixtures/dir-new
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' run --target js cmd/main -- report-dir --config fixtures/moonguard-ci.conf
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' run --target js cmd/main -- check-dir fixtures/dir-old fixtures/dir-new --current 0.1.0 --next 1.0.0
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' run --target js cmd/main -- check-dir --config fixtures/moonguard-ci.conf
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' run --target js cmd/main -- release-plan --config fixtures/moonguard-ci.conf
& 'E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\.toolchain\bin\moon.exe' run --target js cmd/main -- inventory-dir --config fixtures/moonguard-ci.conf
& '.\scripts\analyze-real-fixtures.ps1'
node _build\js\debug\build\cmd\main\main.js check fixtures/old.mbti fixtures/new.mbti --current 0.1.0 --next 0.2.0
node _build\js\debug\build\cmd\main\main.js check --config fixtures/moonguard-ci.conf
node _build\js\debug\build\cmd\main\main.js check-dir fixtures/dir-old fixtures/dir-new --current 0.1.0 --next 1.0.0
node _build\js\debug\build\cmd\main\main.js check-dir --config fixtures/moonguard-ci.conf
```

Check GitHub Actions:

```powershell
gh run list --repo 918154429/moonguard --limit 5
```

## Current Limits

- Parser is line-oriented and intentionally conservative.
- It models common generated `.mbti` nested members, but it is not a full
  MoonBit source parser.
- Historical `moon info` interfaces with a generator header and package
  declaration include unqualified associated `fn`/`impl` lines in the model.
- Native file and directory input is not implemented; CLI file/directory mode
  is JS target only.
- Source-line competition tracking counts repository `.mbt` files and excludes
  generated `_build` output. Current tracked source total is 8502 lines,
  including 5184 non-test lines, above the confirmed 4000-line threshold.

## Recommended Next Slices

Strong next options:

- Add a baseline save/update command around the documented baseline workflow.
- Add performance baselines for large snapshots and large policy rule sets.

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
