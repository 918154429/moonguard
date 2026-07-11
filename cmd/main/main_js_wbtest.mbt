///|
test "js report reads config and interface files" {
  let result = run_args_result([
    "moonguard", "report", "--config", "fixtures/moonguard-ci.conf",
  ])
  inspect(result.exit_code, content="0")
  assert_true(result.output.contains("\"recommendation\": \"major\""))
  assert_true(result.output.contains("\"change_count\": 2"))
}

///|
test "js report reads ignore rules" {
  let result = run_args_result([
    "moonguard", "report", "fixtures/old.mbti", "fixtures/new.mbti", "--format",
    "json", "--ignore-file", "fixtures/ignore-render.rules",
  ])
  inspect(result.exit_code, content="0")
  assert_true(result.output.contains("\"recommendation\": \"minor\""))
  assert_true(result.output.contains("\"change_count\": 1"))
  assert_true(result.output.contains("\"name\": \"parse\""))
}

///|
test "js report-dir recursively reads sorted interface files" {
  let result = run_args_result([
    "moonguard", "report-dir", "fixtures/dir-old", "fixtures/dir-new", "--format",
    "json",
  ])
  inspect(result.exit_code, content="0")
  assert_true(result.output.contains("\"change_count\": 3"))
  assert_true(result.output.contains("cmd::main"))
}

///|
test "js check exposes insufficient version exit code" {
  let result = run_args_result([
    "moonguard", "check", "fixtures/old.mbti", "fixtures/new.mbti", "--current",
    "0.1.0", "--next", "0.2.0", "--format", "json",
  ])
  inspect(result.exit_code, content="1")
  assert_true(result.output.contains("\"ok\": false"))
  assert_true(result.output.contains("\"required\": \"major\""))
}

///|
test "js inventory reports duplicate symbols" {
  let result = run_args_result([
    "moonguard", "inventory-dir", "fixtures/dir-duplicate", "--format", "json",
  ])
  inspect(result.exit_code, content="2")
  assert_true(result.output.contains("duplicate-symbol"))
  assert_true(result.output.contains("\"errors\": 1"))
}

///|
test "js inventory rejects a file used as directory" {
  let result = run_args_result([
    "moonguard", "inventory-dir", "fixtures/old.mbti",
  ])
  inspect(result.exit_code, content="2")
  assert_true(result.output.contains("expected a directory"))
}

///|
test "js report renders audited policy output and config" {
  let direct = run_args_result([
    "moonguard", "report", "fixtures/old.mbti", "fixtures/new.mbti", "--format",
    "json", "--policy-file", "fixtures/allow-render.policy", "--policy-version",
    "0.2.0",
  ])
  inspect(direct.exit_code, content="0")
  assert_true(direct.output.contains("\"original_report\""))
  assert_true(direct.output.contains("\"effective_report\""))
  assert_true(direct.output.contains("\"recommendation\": \"minor\""))
  let configured = run_args_result([
    "moonguard", "report", "--config", "fixtures/moonguard-policy.conf",
  ])
  inspect(configured.exit_code, content="0")
  assert_true(configured.output.contains("\"effective_report\""))
}

///|
test "js report policy errors exit two and fail closed" {
  let missing_version = run_args_result([
    "moonguard", "report", "fixtures/old.mbti", "fixtures/new.mbti", "--format",
    "json", "--policy-file", "fixtures/allow-render.policy",
  ])
  inspect(missing_version.exit_code, content="2")
  assert_true(missing_version.output.contains("policy-version-required"))
  assert_true(missing_version.output.contains("\"recommendation\": \"major\""))
  let expired = run_args_result([
    "moonguard", "check", "fixtures/old.mbti", "fixtures/new.mbti", "--current",
    "0.1.0", "--next", "0.2.0", "--format", "json", "--policy-file", "fixtures/expired-render.policy",
  ])
  inspect(expired.exit_code, content="2")
  assert_true(expired.output.contains("policy-expired-rule"))
  assert_true(expired.output.contains("\"required\": \"major\""))
}

///|
test "js check uses next as policy version and effective impact" {
  let result = run_args_result([
    "moonguard", "check", "fixtures/old.mbti", "fixtures/new.mbti", "--current",
    "0.1.0", "--next", "0.2.0", "--format", "json", "--policy-file", "fixtures/allow-render.policy",
  ])
  inspect(result.exit_code, content="0")
  assert_true(result.output.contains("\"required\": \"minor\""))
  assert_true(result.output.contains("\"ok\": true"))
}

///|
test "js report-dir and release-plan use audited policy" {
  let report = run_args_result([
    "moonguard", "report-dir", "fixtures/dir-old", "fixtures/dir-new", "--format",
    "json", "--policy-file", "fixtures/allow-dir.policy", "--policy-version", "0.2.0",
  ])
  inspect(report.exit_code, content="0")
  assert_true(report.output.contains("\"policy_evaluation\""))
  let plan = run_args_result([
    "moonguard", "release-plan", "fixtures/dir-old", "fixtures/dir-new", "--current",
    "0.1.0", "--next", "0.2.0", "--format", "json", "--policy-file", "fixtures/allow-dir.policy",
  ])
  inspect(plan.exit_code, content="0")
  assert_true(plan.output.contains("\"status\": \"ready\""))
}
