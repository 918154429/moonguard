///|
/// One auditable compatibility exception.
pub struct ApiPolicyRule {
  change_kind : String
  item_kind : String
  name : String
  until : String
  max_matches : Int
  reason : String
  line : Int
} derive(Eq, Debug)

///|
/// Result of parsing a policy file.
pub struct PolicyParseResult {
  rules : Array[ApiPolicyRule]
  errors : Array[String]
} derive(Eq, Debug)

///|
/// A change accepted by one policy rule.
pub struct AcceptedApiChange {
  change : ApiChange
  rule : ApiPolicyRule
} derive(Eq, Debug)

///|
/// A diagnostic emitted while evaluating compatibility policy.
pub struct ApiPolicyDiagnostic {
  severity : String
  code : String
  line : Int
  message : String
} derive(Eq, Debug)

///|
/// Aggregate policy evaluation counters.
pub struct PolicySummary {
  rule_count : Int
  matched_rule_count : Int
  accepted_change_count : Int
  errors : Int
  warnings : Int
} derive(Eq, Debug)

///|
/// Original and effective reports together with their audit trail.
pub struct ApiPolicyEvaluation {
  original_report : ApiReport
  effective_report : ApiReport
  accepted_changes : Array[AcceptedApiChange]
  diagnostics : Array[ApiPolicyDiagnostic]
  summary : PolicySummary
} derive(Eq, Debug)

///|
/// A release plan evaluated against the effective compatibility report.
pub struct PolicyReleasePlan {
  evaluation : ApiPolicyEvaluation
  plan : ReleasePlan
} derive(Eq, Debug)

///|
/// Parse auditable compatibility rules.
///
/// Syntax: `allow CHANGE_KIND ITEM_KIND NAME [until VERSION]
/// [max_matches N] reason TEXT...`.
pub fn parse_policy_rules(text : String) -> PolicyParseResult {
  let rules : Array[ApiPolicyRule] = []
  let errors : Array[String] = []
  let mut line_number = 1
  for raw_line in split_lines(text[:]) {
    parse_policy_rule_line(raw_line, line_number, rules, errors)
    line_number += 1
  }
  { rules, errors }
}

///|
/// Evaluate parsed rules against a compatibility report.
///
/// A rule with an expired deadline or exceeded budget accepts no changes.
/// When several valid rules match a change, the first rule owns its audit
/// record.
pub fn evaluate_policy(
  report : ApiReport,
  rules : Array[ApiPolicyRule],
  target_version : String,
) -> ApiPolicyEvaluation {
  let raw_match_counts : Array[Int] = []
  let eligible : Array[Bool] = []
  let diagnostics : Array[ApiPolicyDiagnostic] = []
  let target = if target_version.length() == 0 {
    None
  } else {
    parse_version(target_version)
  }
  for rule in rules {
    let mut count = 0
    for change in report.changes {
      if change_matches_policy_rule(change, rule) {
        count += 1
      }
    }
    raw_match_counts.push(count)
    let mut valid = true
    match policy_rule_validation_error(rule) {
      Some(message) => {
        valid = false
        diagnostics.push(
          policy_diagnostic("error", "policy-invalid-rule", rule.line, message),
        )
      }
      None => ()
    }
    if count == 0 {
      diagnostics.push(
        policy_diagnostic(
          "warning",
          "policy-unmatched-rule",
          rule.line,
          "policy rule matched no API changes",
        ),
      )
    }
    if rule.until.length() > 0 {
      if target_version.length() == 0 {
        valid = false
        diagnostics.push(
          policy_diagnostic(
            "error",
            "policy-version-required",
            rule.line,
            "target version is required for a rule with 'until'",
          ),
        )
      } else {
        match target {
          None => {
            valid = false
            diagnostics.push(
              policy_diagnostic(
                "error",
                "policy-invalid-target-version",
                rule.line,
                "target version must be a strict major.minor.patch value",
              ),
            )
          }
          Some(target_value) =>
            match parse_version(rule.until) {
              None => {
                valid = false
                diagnostics.push(
                  policy_diagnostic(
                    "error",
                    "policy-invalid-until-version",
                    rule.line,
                    "policy deadline must be a strict major.minor.patch value",
                  ),
                )
              }
              Some(deadline) =>
                if compare_versions(target_value, deadline) > 0 {
                  valid = false
                  diagnostics.push(
                    policy_diagnostic(
                      "error",
                      "policy-expired-rule",
                      rule.line,
                      "policy rule expired after version {rule.until}",
                    ),
                  )
                }
            }
        }
      }
    }
    if count > rule.max_matches {
      valid = false
      diagnostics.push(
        policy_diagnostic(
          "error",
          "policy-match-budget-exceeded",
          rule.line,
          "policy rule matched {count} changes, exceeding max_matches {rule.max_matches}",
        ),
      )
    }
    eligible.push(valid)
  }
  let accepted_changes : Array[AcceptedApiChange] = []
  let effective_changes : Array[ApiChange] = []
  for change in report.changes {
    let mut owner = -1
    let mut eligible_matches = 0
    for i in 0..<rules.length() {
      if eligible[i] && change_matches_policy_rule(change, rules[i]) {
        eligible_matches += 1
        if owner < 0 {
          owner = i
        }
      }
    }
    if owner >= 0 {
      accepted_changes.push({ change, rule: rules[owner] })
      if eligible_matches > 1 {
        diagnostics.push(
          policy_diagnostic(
            "warning",
            "policy-overlapping-rules",
            rules[owner].line,
            "API change matches {eligible_matches} valid policy rules; the first rule was used",
          ),
        )
      }
    } else {
      effective_changes.push(change)
    }
  }
  sort_changes(effective_changes)
  let mut matched_rule_count = 0
  for count in raw_match_counts {
    if count > 0 {
      matched_rule_count += 1
    }
  }
  let mut errors = 0
  let mut warnings = 0
  for diagnostic in diagnostics {
    if diagnostic.severity == "error" {
      errors += 1
    } else if diagnostic.severity == "warning" {
      warnings += 1
    }
  }
  if errors > 0 {
    return {
      original_report: report,
      effective_report: report,
      accepted_changes: [],
      diagnostics,
      summary: {
        rule_count: rules.length(),
        matched_rule_count,
        accepted_change_count: 0,
        errors,
        warnings,
      },
    }
  }
  {
    original_report: report,
    effective_report: {
      changes: effective_changes,
      recommendation: recommended_impact(effective_changes),
    },
    accepted_changes,
    diagnostics,
    summary: {
      rule_count: rules.length(),
      matched_rule_count,
      accepted_change_count: accepted_changes.length(),
      errors,
      warnings,
    },
  }
}

///|
/// Parse and evaluate policy text. Parse failures are preserved as policy
/// diagnostics and never accept changes.
pub fn evaluate_policy_text(
  report : ApiReport,
  rules_text : String,
  target_version : String,
) -> ApiPolicyEvaluation {
  let parsed = parse_policy_rules(rules_text)
  if parsed.errors.is_empty() {
    return evaluate_policy(report, parsed.rules, target_version)
  }
  let evaluated = evaluate_policy(report, [], target_version)
  let diagnostics = evaluated.diagnostics.copy()
  for error in parsed.errors {
    diagnostics.push(policy_diagnostic("error", "policy-parse-error", 0, error))
  }
  {
    original_report: evaluated.original_report,
    effective_report: evaluated.effective_report,
    accepted_changes: evaluated.accepted_changes,
    diagnostics,
    summary: {
      rule_count: parsed.rules.length(),
      matched_rule_count: 0,
      accepted_change_count: 0,
      errors: evaluated.summary.errors + parsed.errors.length(),
      warnings: evaluated.summary.warnings,
    },
  }
}

///|
/// Return true when policy diagnostics contain at least one error.
pub fn policy_diagnostics_have_errors(
  diagnostics : Array[ApiPolicyDiagnostic],
) -> Bool {
  for diagnostic in diagnostics {
    if diagnostic.severity == "error" {
      return true
    }
  }
  false
}

///|
/// Build a release plan using the effective report. Policy errors block the
/// plan independently of interface snapshot diagnostics.
pub fn make_policy_release_plan(
  evaluation : ApiPolicyEvaluation,
  diagnostics : Array[ApiDiagnostic],
  current : String,
  next : String,
) -> PolicyReleasePlan {
  let base = make_release_plan(
    evaluation.effective_report,
    diagnostics,
    current,
    next,
  )
  let plan = if policy_diagnostics_have_errors(evaluation.diagnostics) {
    {
      report: base.report,
      diagnostics: base.diagnostics,
      version_check: base.version_check,
      summary: base.summary,
      diagnostic_summary: base.diagnostic_summary,
      status: "blocked",
      decision: "Fix compatibility policy errors before publishing.",
      next_action: "Resolve policy errors, then rerun MoonGuard.",
    }
  } else {
    base
  }
  { evaluation, plan }
}

///|
/// Render an audited compatibility evaluation as Markdown.
pub fn render_markdown_policy_evaluation(
  evaluation : ApiPolicyEvaluation,
) -> String {
  let out = StringBuilder()
  out.write("# MoonGuard Audited API Compatibility Report\n\n")
  out.write("- Original recommendation: **")
  out.write(impact_label(evaluation.original_report.recommendation))
  out.write("**\n- Effective recommendation: **")
  out.write(impact_label(evaluation.effective_report.recommendation))
  out.write("**\n- Original changes: ")
  out.write(evaluation.original_report.changes.length().to_string())
  out.write("\n- Accepted changes: ")
  out.write(evaluation.summary.accepted_change_count.to_string())
  out.write("\n- Policy diagnostics: ")
  out.write(evaluation.diagnostics.length().to_string())
  out.write("\n\n")
  write_markdown_accepted_changes(out, evaluation.accepted_changes)
  out.write("## Effective Changes\n\n")
  write_markdown_changes(out, evaluation.effective_report.changes)
  out.write("\n")
  write_markdown_policy_diagnostics(out, evaluation.diagnostics)
  out.to_string()
}

///|
/// Render an audited compatibility evaluation as JSON.
pub fn render_json_policy_evaluation(
  evaluation : ApiPolicyEvaluation,
) -> String {
  let out = StringBuilder()
  write_json_policy_evaluation_object(out, evaluation, 0)
  out.write("\n")
  out.to_string()
}

///|
/// Render a policy-aware release plan as Markdown.
pub fn render_markdown_policy_release_plan(plan : PolicyReleasePlan) -> String {
  let out = StringBuilder()
  out.write(render_markdown_policy_evaluation(plan.evaluation))
  out.write("\n## Effective Release Plan\n\n")
  out.write("- Status: **")
  out.write(escape_markdown_cell(plan.plan.status))
  out.write("**\n- Decision: ")
  out.write(escape_markdown_cell(plan.plan.decision))
  out.write("\n- Next action: ")
  out.write(escape_markdown_cell(plan.plan.next_action))
  out.write("\n- Required bump: **")
  out.write(impact_label(plan.plan.version_check.required))
  out.write("**\n- Version: `")
  out.write(escape_markdown_cell(plan.plan.version_check.current))
  out.write("` -> `")
  out.write(escape_markdown_cell(plan.plan.version_check.next))
  out.write("`")
  out.write("\n- Version check: **")
  if plan.plan.version_check.ok {
    out.write("pass")
  } else {
    out.write("fail")
  }
  out.write("**\n\n## Maintainer Checklist\n\n")
  write_release_plan_checklist(out, plan.plan)
  if plan.evaluation.summary.accepted_change_count > 0 {
    out.write("- [ ] Review accepted compatibility exceptions.\n")
  } else {
    out.write("- [x] No compatibility exceptions were accepted.\n")
  }
  if plan.evaluation.summary.errors > 0 {
    out.write("- [ ] Resolve compatibility policy errors.\n")
  } else if plan.evaluation.summary.warnings > 0 {
    out.write("- [ ] Review compatibility policy warnings.\n")
  } else {
    out.write("- [x] Compatibility policy has no diagnostics.\n")
  }
  out.write("\n")
  write_markdown_diagnostics(out, plan.plan.diagnostics)
  out.to_string()
}

///|
/// Render a policy-aware release plan as JSON.
pub fn render_json_policy_release_plan(plan : PolicyReleasePlan) -> String {
  let out = StringBuilder()
  out.write("{\n")
  write_json_indent(out, 2)
  out.write("\"evaluation\": ")
  write_json_policy_evaluation_object(out, plan.evaluation, 2)
  out.write(",\n")
  write_json_indent(out, 2)
  out.write("\"release_plan\": ")
  let rendered_plan = render_json_release_plan(plan.plan).trim()
  out.write(rendered_plan)
  out.write("\n}\n")
  out.to_string()
}

///|
fn parse_policy_rule_line(
  raw_line : StringView,
  line_number : Int,
  rules : Array[ApiPolicyRule],
  errors : Array[String],
) -> Unit {
  let line = strip_rule_comment(raw_line).trim()
  if line.length() == 0 || line.has_prefix("#") {
    return
  }
  let words = split_rule_words(line)
  if words.length() < 4 || words[0] != "allow" {
    errors.push(
      "line {line_number}: expected 'allow CHANGE_KIND ITEM_KIND NAME ... reason TEXT'",
    )
    return
  }
  let change_kind = words[1]
  let item_kind = words[2]
  let name = words[3]
  if !valid_policy_change_kind(change_kind) {
    errors.push("line {line_number}: invalid change kind '{change_kind}'")
    return
  }
  if !valid_ignore_kind(item_kind) {
    errors.push("line {line_number}: invalid policy item kind '{item_kind}'")
    return
  }
  if !valid_ignore_name_pattern(name) {
    errors.push("line {line_number}: invalid policy name '{name}'")
    return
  }
  let mut until = ""
  let mut max_matches = 1
  let mut has_max_matches = false
  let mut index = 4
  let mut found_reason = false
  while index < words.length() {
    if words[index] == "reason" {
      found_reason = true
      index += 1
      break
    } else if words[index] == "until" {
      if until.length() > 0 || index + 1 >= words.length() {
        errors.push("line {line_number}: 'until' requires one version")
        return
      }
      until = words[index + 1]
      if parse_version(until) is None {
        errors.push("line {line_number}: invalid policy deadline '{until}'")
        return
      }
      index += 2
    } else if words[index] == "max_matches" {
      if has_max_matches || index + 1 >= words.length() {
        errors.push("line {line_number}: 'max_matches' requires a number")
        return
      }
      match parse_positive_policy_int(words[index + 1]) {
        None => {
          errors.push(
            "line {line_number}: max_matches must be a positive integer",
          )
          return
        }
        Some(value) => max_matches = value
      }
      has_max_matches = true
      index += 2
    } else {
      errors.push(
        "line {line_number}: expected 'until', 'max_matches', or 'reason'",
      )
      return
    }
  }
  let reason = join_words(words, index)
  if !found_reason || reason.trim().length() == 0 {
    errors.push("line {line_number}: policy rule requires a non-empty reason")
    return
  }
  rules.push({
    change_kind,
    item_kind,
    name,
    until,
    max_matches,
    reason,
    line: line_number,
  })
}

///|
fn parse_positive_policy_int(text : String) -> Int? {
  match parse_version_number(text[:]) {
    Some(value) => if value > 0 { Some(value) } else { None }
    None => None
  }
}

///|
fn valid_policy_change_kind(kind : String) -> Bool {
  kind == "*" || kind == "added" || kind == "removed" || kind == "changed"
}

///|
fn policy_rule_validation_error(rule : ApiPolicyRule) -> String? {
  if rule.line <= 0 {
    Some("policy rule line must be a positive integer")
  } else if !valid_policy_change_kind(rule.change_kind) {
    Some("invalid policy change kind '{rule.change_kind}'")
  } else if !valid_ignore_kind(rule.item_kind) {
    Some("invalid policy item kind '{rule.item_kind}'")
  } else if !valid_ignore_name_pattern(rule.name) {
    Some("invalid policy name '{rule.name}'")
  } else if rule.max_matches <= 0 {
    Some("policy max_matches must be a positive integer")
  } else if rule.reason.trim().length() == 0 {
    Some("policy rule requires a non-empty reason")
  } else {
    None
  }
}

///|
fn change_matches_policy_rule(change : ApiChange, rule : ApiPolicyRule) -> Bool {
  (
    rule.change_kind == "*" ||
    rule.change_kind == change_kind_label(change.kind)
  ) &&
  ignore_kind_matches(rule.item_kind, change.item_kind) &&
  wildcard_matches(rule.name, change.name)
}

///|
fn policy_diagnostic(
  severity : String,
  code : String,
  line : Int,
  message : String,
) -> ApiPolicyDiagnostic {
  { severity, code, line, message }
}

///|
fn write_markdown_accepted_changes(
  out : StringBuilder,
  accepted : Array[AcceptedApiChange],
) -> Unit {
  out.write("## Accepted Changes\n\n")
  if accepted.is_empty() {
    out.write("No compatibility exceptions were accepted.\n\n")
    return
  }
  out.write("| Change | Symbol | Rule | Until | Budget | Reason |\n")
  out.write("| --- | --- | --- | --- | --- | --- |\n")
  for accepted_change in accepted {
    let change = accepted_change.change
    let rule = accepted_change.rule
    out.write("| ")
    out.write(change_kind_label(change.kind))
    out.write(" | `")
    out.write(escape_markdown_cell(change.item_kind))
    out.write(" ")
    out.write(escape_markdown_cell(change.name))
    out.write("` | line ")
    out.write(rule.line.to_string())
    out.write(" | ")
    if rule.until.length() == 0 {
      out.write("-")
    } else {
      out.write("`")
      out.write(escape_markdown_cell(rule.until))
      out.write("`")
    }
    out.write(" | ")
    out.write(rule.max_matches.to_string())
    out.write(" | ")
    out.write(escape_markdown_cell(rule.reason))
    out.write(" |\n")
  }
  out.write("\n")
}

///|
fn write_markdown_policy_diagnostics(
  out : StringBuilder,
  diagnostics : Array[ApiPolicyDiagnostic],
) -> Unit {
  out.write("## Policy Diagnostics\n\n")
  if diagnostics.is_empty() {
    out.write("No policy diagnostics.\n")
    return
  }
  out.write("| Severity | Code | Line | Message |\n")
  out.write("| --- | --- | --- | --- |\n")
  for diagnostic in diagnostics {
    out.write("| ")
    out.write(escape_markdown_cell(diagnostic.severity))
    out.write(" | ")
    out.write(escape_markdown_cell(diagnostic.code))
    out.write(" | ")
    out.write(diagnostic.line.to_string())
    out.write(" | ")
    out.write(escape_markdown_cell(diagnostic.message))
    out.write(" |\n")
  }
}

///|
fn write_json_policy_evaluation_object(
  out : StringBuilder,
  evaluation : ApiPolicyEvaluation,
  indent : Int,
) -> Unit {
  out.write("{\n")
  write_json_indent(out, indent + 2)
  out.write("\"original_report\": ")
  write_json_report_object(out, evaluation.original_report, indent + 2)
  out.write(",\n")
  write_json_indent(out, indent + 2)
  out.write("\"effective_report\": ")
  write_json_report_object(out, evaluation.effective_report, indent + 2)
  out.write(",\n")
  write_json_indent(out, indent + 2)
  out.write("\"policy_summary\": ")
  write_json_policy_summary(out, evaluation.summary, indent + 2)
  out.write(",\n")
  write_json_indent(out, indent + 2)
  out.write("\"accepted_changes\": ")
  write_json_accepted_changes(out, evaluation.accepted_changes, indent + 2)
  out.write(",\n")
  write_json_indent(out, indent + 2)
  out.write("\"policy_diagnostics\": ")
  write_json_policy_diagnostics(out, evaluation.diagnostics, indent + 2)
  out.write("\n")
  write_json_indent(out, indent)
  out.write("}")
}

///|
fn write_json_policy_summary(
  out : StringBuilder,
  summary : PolicySummary,
  indent : Int,
) -> Unit {
  out.write("{\n")
  write_json_number_field(out, "rule_count", summary.rule_count, indent + 2)
  out.write(",\n")
  write_json_number_field(
    out,
    "matched_rule_count",
    summary.matched_rule_count,
    indent + 2,
  )
  out.write(",\n")
  write_json_number_field(
    out,
    "accepted_change_count",
    summary.accepted_change_count,
    indent + 2,
  )
  out.write(",\n")
  write_json_number_field(out, "errors", summary.errors, indent + 2)
  out.write(",\n")
  write_json_number_field(out, "warnings", summary.warnings, indent + 2)
  out.write("\n")
  write_json_indent(out, indent)
  out.write("}")
}

///|
fn write_json_accepted_changes(
  out : StringBuilder,
  accepted : Array[AcceptedApiChange],
  indent : Int,
) -> Unit {
  out.write("[")
  if accepted.is_empty() {
    out.write("]")
    return
  }
  out.write("\n")
  for i in 0..<accepted.length() {
    if i > 0 {
      out.write(",\n")
    }
    let item = accepted[i]
    write_json_indent(out, indent + 2)
    out.write("{\n")
    write_json_indent(out, indent + 4)
    out.write("\"change\": ")
    write_json_change(out, item.change, indent + 4)
    out.write(",\n")
    write_json_indent(out, indent + 4)
    out.write("\"rule\": ")
    write_json_policy_rule(out, item.rule, indent + 4)
    out.write("\n")
    write_json_indent(out, indent + 2)
    out.write("}")
  }
  out.write("\n")
  write_json_indent(out, indent)
  out.write("]")
}

///|
fn write_json_policy_rule(
  out : StringBuilder,
  rule : ApiPolicyRule,
  indent : Int,
) -> Unit {
  out.write("{\n")
  write_json_number_field(out, "line", rule.line, indent + 2)
  out.write(",\n")
  write_json_string_field(out, "change_kind", rule.change_kind, indent + 2)
  out.write(",\n")
  write_json_string_field(out, "item_kind", rule.item_kind, indent + 2)
  out.write(",\n")
  write_json_string_field(out, "name", rule.name, indent + 2)
  out.write(",\n")
  write_json_string_field(out, "until", rule.until, indent + 2)
  out.write(",\n")
  write_json_number_field(out, "max_matches", rule.max_matches, indent + 2)
  out.write(",\n")
  write_json_string_field(out, "reason", rule.reason, indent + 2)
  out.write("\n")
  write_json_indent(out, indent)
  out.write("}")
}

///|
fn write_json_policy_diagnostics(
  out : StringBuilder,
  diagnostics : Array[ApiPolicyDiagnostic],
  indent : Int,
) -> Unit {
  out.write("[")
  if diagnostics.is_empty() {
    out.write("]")
    return
  }
  out.write("\n")
  for i in 0..<diagnostics.length() {
    if i > 0 {
      out.write(",\n")
    }
    let diagnostic = diagnostics[i]
    write_json_indent(out, indent + 2)
    out.write("{\n")
    write_json_string_field(out, "severity", diagnostic.severity, indent + 4)
    out.write(",\n")
    write_json_string_field(out, "code", diagnostic.code, indent + 4)
    out.write(",\n")
    write_json_number_field(out, "line", diagnostic.line, indent + 4)
    out.write(",\n")
    write_json_string_field(out, "message", diagnostic.message, indent + 4)
    out.write("\n")
    write_json_indent(out, indent + 2)
    out.write("}")
  }
  out.write("\n")
  write_json_indent(out, indent)
  out.write("]")
}
