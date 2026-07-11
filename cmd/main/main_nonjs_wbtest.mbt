///|
test "report-text reports non-js ignore-file read error" {
  let result = run_args_result([
    "moonguard", "report-text", "pub fn a() -> Unit", "pub fn b() -> Unit", "--ignore-file",
    "rules.txt",
  ])
  assert_true(
    result.output.contains("file input currently requires the JS backend"),
  )
  inspect(result.exit_code, content="2")
}

///|
test "report-text reports non-js config read error" {
  let result = run_args_result([
    "moonguard", "report-text", "pub fn a() -> Unit", "pub fn b() -> Unit", "--config",
    "moonguard.conf",
  ])
  assert_true(
    result.output.contains("file input currently requires the JS backend"),
  )
  inspect(result.exit_code, content="2")
}

///|
test "report-dir explains non-js backend requirement" {
  let result = run_args_result(["moonguard", "report-dir", "old-dir", "new-dir"])
  assert_true(
    result.output.contains("directory input currently requires the JS backend"),
  )
  inspect(result.exit_code, content="2")
}

///|
test "run_args ignores js process argv prefix for report-dir" {
  let result = run_args_result([
    "node", "_build/default/js/release/build/cmd/main/main.js", "report-dir", "old-dir",
    "new-dir",
  ])
  assert_true(
    result.output.contains("directory input currently requires the JS backend"),
  )
  inspect(result.exit_code, content="2")
}

///|
test "check-dir explains non-js backend requirement" {
  let result = run_args_result([
    "moonguard", "check-dir", "old-dir", "new-dir", "--current", "1.0.0", "--next",
    "2.0.0",
  ])
  assert_true(
    result.output.contains("directory input currently requires the JS backend"),
  )
  inspect(result.exit_code, content="2")
}

///|
test "run_args ignores js process argv prefix for check-dir" {
  let result = run_args_result([
    "node", "_build/default/js/release/build/cmd/main/main.js", "check-dir", "old-dir",
    "new-dir", "--current", "1.0.0", "--next", "2.0.0",
  ])
  assert_true(
    result.output.contains("directory input currently requires the JS backend"),
  )
  inspect(result.exit_code, content="2")
}

///|
test "inventory command reports non-js list error" {
  let result = run_args_result(["moonguard", "inventory-dir", "fixtures"])
  assert_true(
    result.output.contains("directory input currently requires the JS backend"),
  )
  inspect(result.exit_code, content="2")
}

///|
test "config only commands reach non-js config loading" {
  for
    args in [
      ["moonguard", "report", "--config", "moonguard.conf"],
      ["moonguard", "check", "--config", "moonguard.conf"],
      ["moonguard", "inventory-dir", "--config", "moonguard.conf"],
    ] {
    let result = run_args_result(args)
    assert_true(
      result.output.contains("file input currently requires the JS backend"),
    )
    inspect(result.exit_code, content="2")
  }
}

///|
test "check command reports non-js read errors with exit code two" {
  let result = run_args_result([
    "moonguard", "check", "old.mbti", "new.mbti", "--current", "1.0.0", "--next",
    "2.0.0",
  ])
  assert_true(
    result.output.contains("file input currently requires the JS backend"),
  )
  inspect(result.exit_code, content="2")
}
