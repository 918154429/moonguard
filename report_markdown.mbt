///|
/// Render a Markdown compatibility report for PR comments or release notes.
pub fn render_markdown_report(report : ApiReport) -> String {
  let out = StringBuilder()
  out.write("# MoonGuard API Compatibility Report\n\n")
  out.write("- Recommendation: **")
  out.write(impact_label(report.recommendation))
  out.write("**\n")
  out.write("- Changes: ")
  out.write(report.changes.length().to_string())
  out.write("\n\n")
  if report.changes.is_empty() {
    out.write("No public API changes detected.\n")
    return out.to_string()
  }
  out.write("| Impact | Change | Symbol | Details |\n")
  out.write("| --- | --- | --- | --- |\n")
  for change in report.changes {
    out.write("| ")
    out.write(impact_label(change.impact))
    out.write(" | ")
    out.write(change_kind_label(change.kind))
    out.write(" | `")
    out.write(change.item_kind)
    out.write(" ")
    out.write(change.name)
    out.write("` | ")
    out.write(change_details(change))
    out.write(" |\n")
  }
  out.to_string()
}

///|
/// Render a Markdown summary for a SemVer check result.
pub fn render_version_check_markdown(check : VersionCheck) -> String {
  let out = StringBuilder()
  out.write("## Version Check\n\n")
  out.write("- Required bump: **")
  out.write(impact_label(check.required))
  out.write("**\n")
  out.write("- Current version: `")
  out.write(escape_markdown_cell(check.current))
  out.write("`\n")
  out.write("- Next version: `")
  out.write(escape_markdown_cell(check.next))
  out.write("`\n")
  out.write("- Result: **")
  if check.ok {
    out.write("pass")
  } else {
    out.write("fail")
  }
  out.write("**\n")
  out.write("- Reason: ")
  out.write(escape_markdown_cell(check.reason))
  out.write("\n")
  out.to_string()
}

///|
/// Render a package-level Markdown report with a SemVer check section.
pub fn render_markdown_package_check_result(
  report : ApiReport,
  diagnostics : Array[ApiDiagnostic],
  check : VersionCheck,
) -> String {
  let out = StringBuilder()
  out.write(render_markdown_package_report(report, diagnostics))
  out.write("\n")
  out.write(render_version_check_markdown(check))
  out.to_string()
}

///|
/// Render a package-level Markdown report with summary and diagnostics.
pub fn render_markdown_package_report(
  report : ApiReport,
  diagnostics : Array[ApiDiagnostic],
) -> String {
  let out = StringBuilder()
  let summary = summarize_report(report)
  let diagnostic_summary = summarize_diagnostics(diagnostics)
  out.write("# MoonGuard Package API Compatibility Report\n\n")
  out.write("- Recommendation: **")
  out.write(impact_label(report.recommendation))
  out.write("**\n")
  out.write("- Changes: ")
  out.write(summary.total.to_string())
  out.write("\n")
  out.write("- Major changes: ")
  out.write(summary.major.to_string())
  out.write("\n")
  out.write("- Minor changes: ")
  out.write(summary.minor.to_string())
  out.write("\n")
  out.write("- Patch changes: ")
  out.write(summary.patch.to_string())
  out.write("\n")
  out.write("- Added/Removed/Changed: ")
  out.write(summary.added.to_string())
  out.write("/")
  out.write(summary.removed.to_string())
  out.write("/")
  out.write(summary.changed.to_string())
  out.write("\n")
  out.write("- Diagnostics: ")
  out.write(diagnostic_summary.total.to_string())
  out.write(" (errors ")
  out.write(diagnostic_summary.errors.to_string())
  out.write(", warnings ")
  out.write(diagnostic_summary.warnings.to_string())
  out.write(", infos ")
  out.write(diagnostic_summary.infos.to_string())
  out.write(")\n\n")
  write_markdown_diagnostics(out, diagnostics)
  write_markdown_changes(out, report.changes)
  out.to_string()
}

///|
/// Render a Markdown inventory for one package API snapshot.
pub fn render_markdown_snapshot_inventory(snapshot : ApiSnapshot) -> String {
  let out = StringBuilder()
  let diagnostic_summary = summarize_diagnostics(snapshot.diagnostics)
  out.write("# MoonGuard API Snapshot Inventory\n\n")
  out.write("- Items: ")
  out.write(snapshot.items.length().to_string())
  out.write("\n")
  out.write("- Diagnostics: ")
  out.write(diagnostic_summary.total.to_string())
  out.write(" (errors ")
  out.write(diagnostic_summary.errors.to_string())
  out.write(", warnings ")
  out.write(diagnostic_summary.warnings.to_string())
  out.write(", infos ")
  out.write(diagnostic_summary.infos.to_string())
  out.write(")\n\n")
  write_markdown_kind_counts(out, count_items_by_kind(snapshot.items))
  write_markdown_diagnostics(out, snapshot.diagnostics)
  out.to_string()
}

///|
/// Render a release-oriented Markdown report for maintainers and PR comments.
pub fn render_markdown_release_plan(plan : ReleasePlan) -> String {
  let out = StringBuilder()
  out.write("# MoonGuard Release Plan\n\n")
  out.write("- Status: **")
  out.write(escape_markdown_cell(plan.status))
  out.write("**\n")
  out.write("- Decision: ")
  out.write(escape_markdown_cell(plan.decision))
  out.write("\n")
  out.write("- Next action: ")
  out.write(escape_markdown_cell(plan.next_action))
  out.write("\n")
  out.write("- Required bump: **")
  out.write(impact_label(plan.version_check.required))
  out.write("**\n")
  out.write("- Version: `")
  out.write(escape_markdown_cell(plan.version_check.current))
  out.write("` -> `")
  out.write(escape_markdown_cell(plan.version_check.next))
  out.write("`\n")
  out.write("- Version check: **")
  if plan.version_check.ok {
    out.write("pass")
  } else {
    out.write("fail")
  }
  out.write("**\n")
  out.write("- API changes: ")
  out.write(plan.summary.total.to_string())
  out.write(" (major ")
  out.write(plan.summary.major.to_string())
  out.write(", minor ")
  out.write(plan.summary.minor.to_string())
  out.write(", patch ")
  out.write(plan.summary.patch.to_string())
  out.write(")\n")
  out.write("- Added/Removed/Changed: ")
  out.write(plan.summary.added.to_string())
  out.write("/")
  out.write(plan.summary.removed.to_string())
  out.write("/")
  out.write(plan.summary.changed.to_string())
  out.write("\n")
  out.write("- Diagnostics: ")
  out.write(plan.diagnostic_summary.total.to_string())
  out.write(" (errors ")
  out.write(plan.diagnostic_summary.errors.to_string())
  out.write(", warnings ")
  out.write(plan.diagnostic_summary.warnings.to_string())
  out.write(", infos ")
  out.write(plan.diagnostic_summary.infos.to_string())
  out.write(")\n\n")
  out.write("## Maintainer Checklist\n\n")
  write_release_plan_checklist(out, plan)
  out.write("\n")
  write_markdown_diagnostics(out, plan.diagnostics)
  write_markdown_changes(out, plan.report.changes)
  out.to_string()
}

///|
fn write_release_plan_checklist(
  out : StringBuilder,
  plan : ReleasePlan,
) -> Unit {
  if plan.diagnostic_summary.errors > 0 {
    out.write("- [ ] Fix diagnostic errors in generated interface snapshots.\n")
  } else {
    out.write("- [x] Generated interface snapshots are readable.\n")
  }
  if plan.version_check.ok {
    out.write("- [x] Proposed version satisfies MoonGuard's recommendation.\n")
  } else {
    out.write("- [ ] Update the proposed version before release.\n")
  }
  if plan.summary.major > 0 {
    out.write("- [ ] Review breaking changes and document migration notes.\n")
  } else if plan.summary.minor > 0 {
    out.write("- [ ] Mention added public APIs in release notes.\n")
  } else {
    out.write("- [x] No public API release notes are required by MoonGuard.\n")
  }
}

///|
fn write_markdown_diagnostics(
  out : StringBuilder,
  diagnostics : Array[ApiDiagnostic],
) -> Unit {
  if diagnostics.is_empty() {
    return
  }
  out.write("## Diagnostics\n\n")
  out.write("| Severity | Code | Path | Message |\n")
  out.write("| --- | --- | --- | --- |\n")
  for diagnostic in diagnostics {
    out.write("| ")
    out.write(escape_markdown_cell(diagnostic.severity))
    out.write(" | ")
    out.write(escape_markdown_cell(diagnostic.code))
    out.write(" | `")
    out.write(escape_markdown_cell(diagnostic.path))
    out.write("` | ")
    out.write(escape_markdown_cell(diagnostic.message))
    out.write(" |\n")
  }
  out.write("\n")
}

///|
fn write_markdown_changes(
  out : StringBuilder,
  changes : Array[ApiChange],
) -> Unit {
  if changes.is_empty() {
    out.write("No public API changes detected.\n")
    return
  }
  out.write("| Impact | Change | Symbol | Details |\n")
  out.write("| --- | --- | --- | --- |\n")
  for change in changes {
    out.write("| ")
    out.write(impact_label(change.impact))
    out.write(" | ")
    out.write(change_kind_label(change.kind))
    out.write(" | `")
    out.write(change.item_kind)
    out.write(" ")
    out.write(change.name)
    out.write("` | ")
    out.write(change_details(change))
    out.write(" |\n")
  }
}

///|
fn write_markdown_kind_counts(
  out : StringBuilder,
  counts : Array[ApiKindCount],
) -> Unit {
  out.write("## Item Kinds\n\n")
  if counts.is_empty() {
    out.write("No public API items detected.\n\n")
    return
  }
  out.write("| Kind | Count |\n")
  out.write("| --- | --- |\n")
  for count in counts {
    out.write("| ")
    out.write(escape_markdown_cell(count.kind))
    out.write(" | ")
    out.write(count.count.to_string())
    out.write(" |\n")
  }
  out.write("\n")
}

///|
fn escape_markdown_cell(text : String) -> String {
  let out = StringBuilder(size_hint=text.length())
  for ch in text {
    if ch == '|' {
      out.write("\\|")
    } else {
      out.write_char(ch)
    }
  }
  out.to_string()
}
