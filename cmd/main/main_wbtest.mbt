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
test "help mentions file and text modes" {
  let help = run_args(["moonguard", "--help"])
  assert_true(help.contains("report old.mbti new.mbti"))
  assert_true(help.contains("report-dir old_dir new_dir"))
  assert_true(help.contains("report-text"))
}
