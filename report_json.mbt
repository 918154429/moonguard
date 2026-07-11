///|
/// Render a machine-readable JSON compatibility report.
pub fn render_json_report(report : ApiReport) -> String {
  let out = StringBuilder()
  write_json_report_object(out, report, 0)
  out.write("\n")
  out.to_string()
}

///|
/// Render a combined JSON object for API diff and version-check output.
pub fn render_json_check_result(
  report : ApiReport,
  check : VersionCheck,
) -> String {
  let out = StringBuilder()
  out.write("{\n")
  write_json_indent(out, 2)
  out.write("\"report\": ")
  write_json_report_object(out, report, 2)
  out.write(",\n")
  write_json_indent(out, 2)
  out.write("\"version_check\": ")
  write_json_version_check_object(out, check, 2)
  out.write("\n")
  out.write("}\n")
  out.to_string()
}

///|
/// Render a package-level JSON report with diagnostics and a SemVer check.
pub fn render_json_package_check_result(
  report : ApiReport,
  diagnostics : Array[ApiDiagnostic],
  check : VersionCheck,
) -> String {
  let out = StringBuilder()
  out.write("{\n")
  write_json_indent(out, 2)
  out.write("\"report\": ")
  write_json_report_object(out, report, 2)
  out.write(",\n")
  write_json_indent(out, 2)
  out.write("\"diagnostic_summary\": ")
  write_json_diagnostic_summary_object(
    out,
    summarize_diagnostics(diagnostics),
    2,
  )
  out.write(",\n")
  write_json_indent(out, 2)
  out.write("\"diagnostics\": ")
  write_json_diagnostics_array(out, diagnostics, 2)
  out.write(",\n")
  write_json_indent(out, 2)
  out.write("\"version_check\": ")
  write_json_version_check_object(out, check, 2)
  out.write("\n")
  out.write("}\n")
  out.to_string()
}

///|
/// Render a package-level JSON report with diagnostics.
pub fn render_json_package_report(
  report : ApiReport,
  diagnostics : Array[ApiDiagnostic],
) -> String {
  let out = StringBuilder()
  out.write("{\n")
  write_json_indent(out, 2)
  out.write("\"report\": ")
  write_json_report_object(out, report, 2)
  out.write(",\n")
  write_json_indent(out, 2)
  out.write("\"diagnostic_summary\": ")
  write_json_diagnostic_summary_object(
    out,
    summarize_diagnostics(diagnostics),
    2,
  )
  out.write(",\n")
  write_json_indent(out, 2)
  out.write("\"diagnostics\": ")
  write_json_diagnostics_array(out, diagnostics, 2)
  out.write("\n")
  out.write("}\n")
  out.to_string()
}

///|
/// Render a JSON inventory for one package API snapshot.
pub fn render_json_snapshot_inventory(snapshot : ApiSnapshot) -> String {
  let out = StringBuilder()
  out.write("{\n")
  write_json_number_field(out, "item_count", snapshot.items.length(), 2)
  out.write(",\n")
  write_json_indent(out, 2)
  out.write("\"kind_counts\": ")
  write_json_kind_counts_array(out, count_items_by_kind(snapshot.items), 2)
  out.write(",\n")
  write_json_indent(out, 2)
  out.write("\"diagnostic_summary\": ")
  write_json_diagnostic_summary_object(
    out,
    summarize_diagnostics(snapshot.diagnostics),
    2,
  )
  out.write(",\n")
  write_json_indent(out, 2)
  out.write("\"diagnostics\": ")
  write_json_diagnostics_array(out, snapshot.diagnostics, 2)
  out.write("\n")
  out.write("}\n")
  out.to_string()
}

///|
/// Render a release-oriented JSON report for CI and dashboards.
pub fn render_json_release_plan(plan : ReleasePlan) -> String {
  let out = StringBuilder()
  out.write("{\n")
  write_json_string_field(out, "status", plan.status, 2)
  out.write(",\n")
  write_json_string_field(out, "decision", plan.decision, 2)
  out.write(",\n")
  write_json_string_field(out, "next_action", plan.next_action, 2)
  out.write(",\n")
  write_json_indent(out, 2)
  out.write("\"summary\": ")
  write_json_api_summary_object(out, plan.summary, 2)
  out.write(",\n")
  write_json_indent(out, 2)
  out.write("\"diagnostic_summary\": ")
  write_json_diagnostic_summary_object(out, plan.diagnostic_summary, 2)
  out.write(",\n")
  write_json_indent(out, 2)
  out.write("\"version_check\": ")
  write_json_version_check_object(out, plan.version_check, 2)
  out.write(",\n")
  write_json_indent(out, 2)
  out.write("\"report\": ")
  write_json_report_object(out, plan.report, 2)
  out.write(",\n")
  write_json_indent(out, 2)
  out.write("\"diagnostics\": ")
  write_json_diagnostics_array(out, plan.diagnostics, 2)
  out.write("\n")
  out.write("}\n")
  out.to_string()
}

///|
fn write_json_report_object(
  out : StringBuilder,
  report : ApiReport,
  indent : Int,
) -> Unit {
  out.write("{\n")
  write_json_string_field(
    out,
    "recommendation",
    impact_label(report.recommendation),
    indent + 2,
  )
  out.write(",\n")
  write_json_number_field(
    out,
    "change_count",
    report.changes.length(),
    indent + 2,
  )
  out.write(",\n")
  write_json_summary_field(out, report, indent + 2)
  out.write(",\n")
  write_json_changes_field(out, report.changes, indent + 2)
  out.write("\n")
  write_json_indent(out, indent)
  out.write("}")
}

///|
fn write_json_diagnostics_array(
  out : StringBuilder,
  diagnostics : Array[ApiDiagnostic],
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
    write_json_diagnostic(out, diagnostics[i], indent + 2)
  }
  out.write("\n")
  write_json_indent(out, indent)
  out.write("]")
}

///|
fn write_json_kind_counts_array(
  out : StringBuilder,
  counts : Array[ApiKindCount],
  indent : Int,
) -> Unit {
  out.write("[")
  if counts.is_empty() {
    out.write("]")
    return
  }
  out.write("\n")
  for i in 0..<counts.length() {
    if i > 0 {
      out.write(",\n")
    }
    write_json_kind_count(out, counts[i], indent + 2)
  }
  out.write("\n")
  write_json_indent(out, indent)
  out.write("]")
}

///|
fn write_json_kind_count(
  out : StringBuilder,
  count : ApiKindCount,
  indent : Int,
) -> Unit {
  write_json_indent(out, indent)
  out.write("{\n")
  write_json_string_field(out, "kind", count.kind, indent + 2)
  out.write(",\n")
  write_json_number_field(out, "count", count.count, indent + 2)
  out.write("\n")
  write_json_indent(out, indent)
  out.write("}")
}

///|
fn write_json_diagnostic_summary_object(
  out : StringBuilder,
  summary : DiagnosticSummary,
  indent : Int,
) -> Unit {
  out.write("{\n")
  write_json_number_field(out, "total", summary.total, indent + 2)
  out.write(",\n")
  write_json_number_field(out, "errors", summary.errors, indent + 2)
  out.write(",\n")
  write_json_number_field(out, "warnings", summary.warnings, indent + 2)
  out.write(",\n")
  write_json_number_field(out, "infos", summary.infos, indent + 2)
  out.write("\n")
  write_json_indent(out, indent)
  out.write("}")
}

///|
fn write_json_diagnostic(
  out : StringBuilder,
  diagnostic : ApiDiagnostic,
  indent : Int,
) -> Unit {
  write_json_indent(out, indent)
  out.write("{\n")
  write_json_string_field(out, "severity", diagnostic.severity, indent + 2)
  out.write(",\n")
  write_json_string_field(out, "code", diagnostic.code, indent + 2)
  out.write(",\n")
  write_json_string_field(out, "path", diagnostic.path, indent + 2)
  out.write(",\n")
  write_json_string_field(out, "message", diagnostic.message, indent + 2)
  out.write("\n")
  write_json_indent(out, indent)
  out.write("}")
}

///|
fn write_json_version_check_object(
  out : StringBuilder,
  check : VersionCheck,
  indent : Int,
) -> Unit {
  out.write("{\n")
  write_json_bool_field(out, "ok", check.ok, indent + 2)
  out.write(",\n")
  write_json_string_field(
    out,
    "required",
    impact_label(check.required),
    indent + 2,
  )
  out.write(",\n")
  write_json_string_field(out, "current", check.current, indent + 2)
  out.write(",\n")
  write_json_string_field(out, "next", check.next, indent + 2)
  out.write(",\n")
  write_json_string_field(out, "reason", check.reason, indent + 2)
  out.write("\n")
  write_json_indent(out, indent)
  out.write("}")
}

///|
fn write_json_api_summary_object(
  out : StringBuilder,
  summary : ApiSummary,
  indent : Int,
) -> Unit {
  out.write("{\n")
  write_json_number_field(out, "total", summary.total, indent + 2)
  out.write(",\n")
  write_json_number_field(out, "major", summary.major, indent + 2)
  out.write(",\n")
  write_json_number_field(out, "minor", summary.minor, indent + 2)
  out.write(",\n")
  write_json_number_field(out, "patch", summary.patch, indent + 2)
  out.write(",\n")
  write_json_number_field(out, "added", summary.added, indent + 2)
  out.write(",\n")
  write_json_number_field(out, "removed", summary.removed, indent + 2)
  out.write(",\n")
  write_json_number_field(out, "changed", summary.changed, indent + 2)
  out.write("\n")
  write_json_indent(out, indent)
  out.write("}")
}

///|
fn write_json_summary_field(
  out : StringBuilder,
  report : ApiReport,
  indent : Int,
) -> Unit {
  write_json_indent(out, indent)
  out.write("\"summary\": {\n")
  write_json_number_field(
    out,
    "major",
    count_changes_by_impact(report.changes, Major),
    indent + 2,
  )
  out.write(",\n")
  write_json_number_field(
    out,
    "minor",
    count_changes_by_impact(report.changes, Minor),
    indent + 2,
  )
  out.write(",\n")
  write_json_number_field(
    out,
    "patch",
    count_changes_by_impact(report.changes, Patch),
    indent + 2,
  )
  out.write("\n")
  write_json_indent(out, indent)
  out.write("}")
}

///|
fn write_json_changes_field(
  out : StringBuilder,
  changes : Array[ApiChange],
  indent : Int,
) -> Unit {
  write_json_indent(out, indent)
  out.write("\"changes\": [")
  if changes.is_empty() {
    out.write("]")
    return
  }
  out.write("\n")
  for i in 0..<changes.length() {
    if i > 0 {
      out.write(",\n")
    }
    write_json_change(out, changes[i], indent + 2)
  }
  out.write("\n")
  write_json_indent(out, indent)
  out.write("]")
}

///|
fn write_json_change(
  out : StringBuilder,
  change : ApiChange,
  indent : Int,
) -> Unit {
  write_json_indent(out, indent)
  out.write("{\n")
  write_json_string_field(
    out,
    "kind",
    change_kind_label(change.kind),
    indent + 2,
  )
  out.write(",\n")
  write_json_string_field(
    out,
    "impact",
    impact_label(change.impact),
    indent + 2,
  )
  out.write(",\n")
  write_json_string_field(out, "item_kind", change.item_kind, indent + 2)
  out.write(",\n")
  write_json_string_field(out, "name", change.name, indent + 2)
  out.write(",\n")
  write_json_optional_string_field(
    out,
    "old_signature",
    change.old_signature,
    indent + 2,
  )
  out.write(",\n")
  write_json_optional_string_field(
    out,
    "new_signature",
    change.new_signature,
    indent + 2,
  )
  out.write("\n")
  write_json_indent(out, indent)
  out.write("}")
}

///|
fn write_json_string_field(
  out : StringBuilder,
  key : String,
  value : String,
  indent : Int,
) -> Unit {
  write_json_indent(out, indent)
  write_json_string(out, key)
  out.write(": ")
  write_json_string(out, value)
}

///|
fn write_json_optional_string_field(
  out : StringBuilder,
  key : String,
  value : String?,
  indent : Int,
) -> Unit {
  write_json_indent(out, indent)
  write_json_string(out, key)
  out.write(": ")
  match value {
    Some(text) => write_json_string(out, text)
    None => out.write("null")
  }
}

///|
fn write_json_number_field(
  out : StringBuilder,
  key : String,
  value : Int,
  indent : Int,
) -> Unit {
  write_json_indent(out, indent)
  write_json_string(out, key)
  out.write(": ")
  out.write(value.to_string())
}

///|
fn write_json_bool_field(
  out : StringBuilder,
  key : String,
  value : Bool,
  indent : Int,
) -> Unit {
  write_json_indent(out, indent)
  write_json_string(out, key)
  out.write(": ")
  if value {
    out.write("true")
  } else {
    out.write("false")
  }
}

///|
fn write_json_string(out : StringBuilder, text : String) -> Unit {
  out.write("\"")
  out.write(escape_json_string(text))
  out.write("\"")
}

///|
fn write_json_indent(out : StringBuilder, indent : Int) -> Unit {
  for _ in 0..<indent {
    out.write(" ")
  }
}

///|
fn count_changes_by_impact(changes : Array[ApiChange], impact : Impact) -> Int {
  let mut count = 0
  for change in changes {
    if change.impact == impact {
      count += 1
    }
  }
  count
}

///|
fn escape_json_string(text : String) -> String {
  let out = StringBuilder(size_hint=text.length())
  for ch in text {
    if ch == '"' {
      out.write("\\\"")
    } else if ch == '\\' {
      out.write("\\\\")
    } else if ch == '\n' {
      out.write("\\n")
    } else if ch == '\r' {
      out.write("\\r")
    } else if ch == '\t' {
      out.write("\\t")
    } else if ch.to_int() < 32 {
      out.write("\\u00")
      out.write(hex_digit(ch.to_int() / 16))
      out.write(hex_digit(ch.to_int() % 16))
    } else {
      out.write_char(ch)
    }
  }
  out.to_string()
}

///|
fn hex_digit(value : Int) -> String {
  match value {
    0 => "0"
    1 => "1"
    2 => "2"
    3 => "3"
    4 => "4"
    5 => "5"
    6 => "6"
    7 => "7"
    8 => "8"
    9 => "9"
    10 => "a"
    11 => "b"
    12 => "c"
    13 => "d"
    14 => "e"
    15 => "f"
    _ => "0"
  }
}
