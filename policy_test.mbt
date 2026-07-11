///|
test "parse auditable policy rule with defaults and metadata" {
  let parsed = @moonguard.parse_policy_rules(
    "allow removed fn legacy_* reason 删除旧实验接口\n",
  )
  inspect(parsed.errors.length(), content="0")
  inspect(parsed.rules.length(), content="1")
  let rule = parsed.rules[0]
  inspect(rule.change_kind, content="removed")
  inspect(rule.item_kind, content="fn")
  inspect(rule.name, content="legacy_*")
  inspect(rule.until, content="")
  inspect(rule.max_matches, content="1")
  inspect(rule.reason, content="删除旧实验接口")
  inspect(rule.line, content="1")
}

///|
test "parse policy accepts deadline budget and comments" {
  let parsed = @moonguard.parse_policy_rules(
    (
      #|# release exceptions
      #|allow changed fn render until 0.4.0 max_matches 2 reason migration documented // owner note
    ),
  )
  inspect(parsed.errors.length(), content="0")
  inspect(parsed.rules.length(), content="1")
  inspect(parsed.rules[0].until, content="0.4.0")
  inspect(parsed.rules[0].max_matches, content="2")
  inspect(parsed.rules[0].reason, content="migration documented")
  inspect(parsed.rules[0].line, content="2")
}

///|
test "parse policy rejects unsafe or malformed rules" {
  let parsed = @moonguard.parse_policy_rules(
    (
      #|allow removed fn old
      #|allow renamed fn old reason unsupported change kind
      #|allow removed fn old until 1.0 reason invalid semver
      #|allow removed fn old max_matches 0 reason invalid budget
      #|allow removed fn old max_matches 1 max_matches 2 reason duplicate budget
    ),
  )
  inspect(parsed.rules.length(), content="0")
  inspect(parsed.errors.length(), content="5")
}

///|
test "policy accepts a matching breaking change and preserves original report" {
  let report = @moonguard.diff_interfaces(
    "pub fn legacy_render(String) -> String\n", "",
  )
  let evaluated = @moonguard.evaluate_policy_text(
    report, "allow removed fn legacy_* max_matches 1 reason legacy removal\n", "",
  )
  inspect(evaluated.original_report.changes.length(), content="1")
  assert_true(evaluated.original_report.recommendation == @moonguard.Major)
  inspect(evaluated.effective_report.changes.length(), content="0")
  assert_true(evaluated.effective_report.recommendation == @moonguard.Patch)
  inspect(evaluated.accepted_changes.length(), content="1")
  inspect(evaluated.accepted_changes[0].rule.reason, content="legacy removal")
  inspect(evaluated.summary.errors, content="0")
}

///|
test "policy matches change kind item kind and wildcard together" {
  let report = @moonguard.diff_interfaces(
    "pub fn render(String) -> String\npub let old_value : Int\n", "pub fn render(Int) -> String\n",
  )
  let evaluated = @moonguard.evaluate_policy_text(
    report, "allow changed fn ren* max_matches 1 reason signature migration\n", "",
  )
  inspect(evaluated.accepted_changes.length(), content="1")
  inspect(evaluated.accepted_changes[0].change.name, content="render")
  inspect(evaluated.effective_report.changes.length(), content="1")
  inspect(evaluated.effective_report.changes[0].name, content="old_value")
}

///|
test "policy budget overflow accepts no matching changes" {
  let report = @moonguard.diff_interfaces(
    "pub fn legacy_a() -> Unit\npub fn legacy_b() -> Unit\n", "",
  )
  let evaluated = @moonguard.evaluate_policy_text(
    report, "allow removed fn legacy_* max_matches 1 reason bounded cleanup\n", "",
  )
  inspect(evaluated.accepted_changes.length(), content="0")
  inspect(evaluated.effective_report.changes.length(), content="2")
  inspect(evaluated.summary.errors, content="1")
  inspect(evaluated.diagnostics[0].code, content="policy-match-budget-exceeded")
}

///|
test "policy deadline is inclusive and expiry fails closed" {
  let report = @moonguard.diff_interfaces("pub fn old() -> Unit\n", "")
  let rule = "allow removed fn old until 0.4.0 reason scheduled removal\n"
  let current = @moonguard.evaluate_policy_text(report, rule, "0.4.0")
  inspect(current.accepted_changes.length(), content="1")
  inspect(current.summary.errors, content="0")
  let expired = @moonguard.evaluate_policy_text(report, rule, "0.4.1")
  inspect(expired.accepted_changes.length(), content="0")
  inspect(expired.summary.errors, content="1")
  inspect(expired.diagnostics[0].code, content="policy-expired-rule")
}

///|
test "policy requires target version when deadline exists" {
  let report = @moonguard.diff_interfaces("pub fn old() -> Unit\n", "")
  let evaluated = @moonguard.evaluate_policy_text(
    report, "allow removed fn old until 0.4.0 reason scheduled removal\n", "",
  )
  inspect(evaluated.accepted_changes.length(), content="0")
  inspect(evaluated.diagnostics[0].code, content="policy-version-required")
  inspect(
    @moonguard.policy_diagnostics_have_errors(evaluated.diagnostics),
    content="true",
  )
}

///|
test "unmatched and overlapping policy rules are auditable" {
  let report = @moonguard.diff_interfaces("pub fn old() -> Unit\n", "")
  let evaluated = @moonguard.evaluate_policy_text(
    report,
    (
      #|allow removed fn old reason first owner
      #|allow removed * old reason overlap
      #|allow added fn missing reason stale rule
    ),
    "",
  )
  inspect(evaluated.accepted_changes.length(), content="1")
  inspect(evaluated.accepted_changes[0].rule.reason, content="first owner")
  inspect(evaluated.summary.matched_rule_count, content="2")
  inspect(evaluated.summary.warnings, content="2")
}

///|
test "policy parse errors fail closed" {
  let report = @moonguard.diff_interfaces("pub fn old() -> Unit\n", "")
  let evaluated = @moonguard.evaluate_policy_text(
    report,
    (
      #|allow removed fn old reason valid line
      #|allow removed fn other
    ),
    "",
  )
  inspect(evaluated.accepted_changes.length(), content="0")
  inspect(evaluated.effective_report.changes.length(), content="1")
  inspect(evaluated.diagnostics[0].code, content="policy-parse-error")
}

///|
test "any policy evaluation error globally preserves original impact" {
  let report = @moonguard.diff_interfaces(
    "pub fn old() -> Unit\npub fn expired() -> Unit\n", "",
  )
  let evaluated = @moonguard.evaluate_policy_text(
    report,
    (
      #|allow removed fn old reason otherwise valid
      #|allow removed fn expired until 0.3.0 reason expired exception
    ),
    "0.4.0",
  )
  inspect(evaluated.summary.errors, content="1")
  inspect(evaluated.accepted_changes.length(), content="0")
  inspect(evaluated.effective_report.changes.length(), content="2")
  assert_true(evaluated.effective_report.recommendation == @moonguard.Major)
}

///|
test "policy renderers expose original effective and audit metadata" {
  let report = @moonguard.diff_interfaces("pub fn old() -> Unit\n", "")
  let evaluated = @moonguard.evaluate_policy_text(
    report, "allow removed fn old reason reviewed \"migration\" \\ path\n", "",
  )
  let markdown = @moonguard.render_markdown_policy_evaluation(evaluated)
  inspect(
    markdown.contains("Original recommendation: **major**"),
    content="true",
  )
  inspect(
    markdown.contains("Effective recommendation: **patch**"),
    content="true",
  )
  inspect(markdown.contains("reviewed \"migration\" \\ path"), content="true")
  let json = @moonguard.render_json_policy_evaluation(evaluated)
  inspect(json.contains("\"original_report\""), content="true")
  inspect(json.contains("\"effective_report\""), content="true")
  inspect(json.contains("reviewed \\\"migration\\\" \\\\ path"), content="true")
}

///|
test "policy release plan uses effective impact and blocks policy errors" {
  let report = @moonguard.diff_interfaces("pub fn old() -> Unit\n", "")
  let accepted = @moonguard.evaluate_policy_text(
    report, "allow removed fn old reason approved removal\n", "",
  )
  let ready = @moonguard.make_policy_release_plan(
    accepted,
    [],
    "0.3.0",
    "0.3.1",
  )
  assert_true(ready.plan.version_check.required == @moonguard.Patch)
  inspect(ready.plan.status, content="ready")
  let invalid = @moonguard.evaluate_policy_text(
    report, "allow removed fn old until 0.4.0 reason scheduled\n", "",
  )
  let blocked = @moonguard.make_policy_release_plan(
    invalid,
    [],
    "0.3.0",
    "1.0.0",
  )
  inspect(blocked.plan.status, content="blocked")
  inspect(
    @moonguard.render_markdown_policy_release_plan(blocked).contains(
      "Resolve compatibility policy errors",
    ),
    content="true",
  )
  inspect(
    @moonguard.render_json_policy_release_plan(blocked).contains(
      "\"release_plan\"",
    ),
    content="true",
  )
}
