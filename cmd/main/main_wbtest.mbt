///|
test "report-text unchanged api recommends patch" {
  inspect(
    run_args([
      "moonguard", "report-text", "pub fn render(String) -> String", "pub fn render(String) -> String",
    ]),
    content=(
      #|# MoonGuard API Compatibility Report
      #|
      #|- Recommendation: **patch**
      #|- Changes: 0
      #|
      #|No public API changes detected.
      #|
    ),
  )
}

///|
test "run_args ignores js process argv prefix" {
  inspect(
    run_args([
      "node", "_build/default/js/release/build/cmd/main/main.js", "report-text",
      "pub fn render(String) -> String", "pub fn render(String) -> String",
    ]),
    content=(
      #|# MoonGuard API Compatibility Report
      #|
      #|- Recommendation: **patch**
      #|- Changes: 0
      #|
      #|No public API changes detected.
      #|
    ),
  )
}

///|
test "report-text changed signature recommends major" {
  inspect(
    run_args([
      "moonguard", "report-text", "pub fn render(String) -> String", "pub fn render(String, Options) -> String",
    ]),
    content=(
      #|# MoonGuard API Compatibility Report
      #|
      #|- Recommendation: **major**
      #|- Changes: 1
      #|
      #|| Impact | Change | Symbol | Details |
      #|| --- | --- | --- | --- |
      #|| major | changed | `fn render` | `render(String) -> String` -> `render(String, Options) -> String` |
      #|
    ),
  )
}

///|
test "report-text supports json format" {
  inspect(
    run_args([
      "moonguard", "report-text", "pub fn render(String) -> String", "pub fn render(String) -> String",
      "--format", "json",
    ]),
    content=(
      #|{
      #|  "recommendation": "patch",
      #|  "change_count": 0,
      #|  "summary": {
      #|    "major": 0,
      #|    "minor": 0,
      #|    "patch": 0
      #|  },
      #|  "changes": []
      #|}
      #|
    ),
  )
}

///|
test "report-text rejects unknown format" {
  let result = run_args_result([
    "moonguard", "report-text", "pub fn a() -> Unit", "pub fn a() -> Unit", "--format",
    "xml",
  ])
  inspect(result.output, content="error: unsupported report format 'xml'")
  inspect(result.exit_code, content="2")
}

///|
test "report-dir explains non-js backend requirement" {
  inspect(
    run_args(["moonguard", "report-dir", "old-dir", "new-dir"]),
    content="error: cannot list old interface directory 'old-dir': directory input currently requires the JS backend; run with `moon run --target js cmd/main -- report-dir old_dir new_dir`",
  )
}

///|
test "run_args ignores js process argv prefix for report-dir" {
  inspect(
    run_args([
      "node", "_build/default/js/release/build/cmd/main/main.js", "report-dir", "old-dir",
      "new-dir",
    ]),
    content="error: cannot list old interface directory 'old-dir': directory input currently requires the JS backend; run with `moon run --target js cmd/main -- report-dir old_dir new_dir`",
  )
}

///|
test "check command requires versions before reading files" {
  let result = run_args_result(["moonguard", "check", "old.mbti", "new.mbti"])
  inspect(
    result.output,
    content="error: check requires --current major.minor.patch",
  )
  inspect(result.exit_code, content="2")
}

///|
test "check command reports non-js read errors with exit code two" {
  let result = run_args_result([
    "moonguard", "check", "old.mbti", "new.mbti", "--current", "1.0.0", "--next",
    "2.0.0",
  ])
  inspect(
    result.output,
    content="error: cannot read old interface file 'old.mbti': file input currently requires the JS backend; run with `moon run --target js cmd/main -- report old.mbti new.mbti`",
  )
  inspect(result.exit_code, content="2")
}

///|
test "check report result fails insufficient major bump" {
  let report = @moonguard.diff_interfaces(
    "pub fn render(String) -> String", "pub fn render(String, Options) -> String",
  )
  let result = check_report_result(report, "1.2.3", "1.3.0", "markdown")
  inspect(result.exit_code, content="1")
  assert_true(result.output.contains("## Version Check"))
  assert_true(result.output.contains("- Result: **fail**"))
  assert_true(
    result.output.contains(
      "major recommendation requires increasing major version",
    ),
  )
}

///|
test "check report result passes sufficient major bump" {
  let report = @moonguard.diff_interfaces(
    "pub fn render(String) -> String", "pub fn render(String, Options) -> String",
  )
  let result = check_report_result(report, "1.2.3", "2.0.0", "markdown")
  inspect(result.exit_code, content="0")
  assert_true(result.output.contains("- Result: **pass**"))
}

///|
test "check report result supports json output" {
  let report = @moonguard.diff_interfaces(
    "pub fn render(String) -> String", "pub fn parse(String) -> Unit\npub fn render(String) -> String",
  )
  let result = check_report_result(report, "1.2.3", "1.2.4", "json")
  inspect(result.exit_code, content="1")
  assert_true(result.output.contains("\"version_check\""))
  assert_true(result.output.contains("\"ok\": false"))
  assert_true(result.output.contains("\"required\": \"minor\""))
}

///|
test "help mentions file and text modes" {
  let help = run_args(["moonguard", "--help"])
  assert_true(help.contains("report old.mbti new.mbti"))
  assert_true(help.contains("report-dir old_dir new_dir"))
  assert_true(help.contains("check old.mbti new.mbti"))
  assert_true(help.contains("report-text"))
  assert_true(help.contains("--format markdown|json"))
}
