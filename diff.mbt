///|
/// Diff two package-level snapshots.
pub fn diff_api_snapshots(
  old_snapshot : ApiSnapshot,
  new_snapshot : ApiSnapshot,
) -> ApiReport {
  diff_items(old_snapshot.items, new_snapshot.items)
}

///|
/// Compare two package-level snapshots and keep diagnostics beside the report.
pub fn compare_api_snapshots(
  old_snapshot : ApiSnapshot,
  new_snapshot : ApiSnapshot,
) -> ApiPackageComparison {
  let diagnostics = merge_diagnostics(
    old_snapshot.diagnostics,
    new_snapshot.diagnostics,
  )
  let report = diff_api_snapshots(old_snapshot, new_snapshot)
  {
    old_snapshot,
    new_snapshot,
    report,
    diagnostics,
    summary: summarize_report(report),
    diagnostic_summary: summarize_diagnostics(diagnostics),
  }
}

///|
/// Build snapshots from file sets and compare them as one package.
pub fn compare_api_file_sets(
  old_files : Array[ApiFile],
  new_files : Array[ApiFile],
) -> ApiPackageComparison {
  compare_api_snapshots(
    build_api_snapshot(old_files),
    build_api_snapshot(new_files),
  )
}

///|
/// Compare two MoonBit public API snapshots.
pub fn diff_interfaces(old_text : String, new_text : String) -> ApiReport {
  diff_items(parse_interface(old_text), parse_interface(new_text))
}

///|
/// Compare two normalized API lists.
pub fn diff_items(
  old_items : Array[ApiItem],
  new_items : Array[ApiItem],
) -> ApiReport {
  let changes : Array[ApiChange] = []
  for old_item in old_items {
    match find_item(new_items, old_item.kind, old_item.name) {
      Some(new_item) =>
        if old_item.signature != new_item.signature {
          changes.push({
            kind: Changed,
            impact: Major,
            item_kind: old_item.kind,
            name: old_item.name,
            old_signature: Some(old_item.signature),
            new_signature: Some(new_item.signature),
          })
        }
      None =>
        match find_kind_changed_item(new_items, old_item) {
          Some(new_item) =>
            changes.push({
              kind: Changed,
              impact: Major,
              item_kind: "\{old_item.kind}->\{new_item.kind}",
              name: old_item.name,
              old_signature: Some("\{old_item.kind} \{old_item.signature}"),
              new_signature: Some("\{new_item.kind} \{new_item.signature}"),
            })
          None =>
            if should_report_nested_change(new_items, old_item) {
              changes.push({
                kind: Removed,
                impact: Major,
                item_kind: old_item.kind,
                name: old_item.name,
                old_signature: Some(old_item.signature),
                new_signature: None,
              })
            }
        }
    }
  }
  for new_item in new_items {
    match find_item(old_items, new_item.kind, new_item.name) {
      Some(_) => ()
      None =>
        match find_kind_changed_item(old_items, new_item) {
          Some(_) => ()
          None =>
            if should_report_nested_change(old_items, new_item) {
              changes.push({
                kind: Added,
                impact: added_impact(new_item.kind),
                item_kind: new_item.kind,
                name: new_item.name,
                old_signature: None,
                new_signature: Some(new_item.signature),
              })
            }
        }
    }
  }
  sort_changes(changes)
  { changes, recommendation: recommended_impact(changes) }
}

///|
/// Count change kinds and impact levels in a report.
pub fn summarize_report(report : ApiReport) -> ApiSummary {
  let mut major = 0
  let mut minor = 0
  let mut patch = 0
  let mut added = 0
  let mut removed = 0
  let mut changed = 0
  for change in report.changes {
    match change.impact {
      Major => major += 1
      Minor => minor += 1
      Patch => patch += 1
    }
    match change.kind {
      Added => added += 1
      Removed => removed += 1
      Changed => changed += 1
    }
  }
  {
    total: report.changes.length(),
    major,
    minor,
    patch,
    added,
    removed,
    changed,
  }
}

///|
/// Return true when diagnostics include at least one error.
pub fn diagnostics_have_errors(diagnostics : Array[ApiDiagnostic]) -> Bool {
  for diagnostic in diagnostics {
    if diagnostic.severity == "error" {
      return true
    }
  }
  false
}

///|
/// Count diagnostics by severity.
pub fn summarize_diagnostics(
  diagnostics : Array[ApiDiagnostic],
) -> DiagnosticSummary {
  let mut errors = 0
  let mut warnings = 0
  let mut infos = 0
  for diagnostic in diagnostics {
    if diagnostic.severity == "error" {
      errors += 1
    } else if diagnostic.severity == "warning" {
      warnings += 1
    } else if diagnostic.severity == "info" {
      infos += 1
    }
  }
  { total: diagnostics.length(), errors, warnings, infos }
}

///|
/// Count API items by kind for package-level diagnostics and reporting.
pub fn count_items_by_kind(items : Array[ApiItem]) -> Array[ApiKindCount] {
  let counts : Array[ApiKindCount] = []
  for item in items {
    match find_kind_count_index(counts, item.kind) {
      Some(index) => {
        let old = counts[index]
        counts[index] = { kind: old.kind, count: old.count + 1 }
      }
      None => counts.push({ kind: item.kind, count: 1 })
    }
  }
  sort_kind_counts(counts)
  counts
}

///|
/// Merge diagnostics from two snapshots.
pub fn merge_diagnostics(
  left : Array[ApiDiagnostic],
  right : Array[ApiDiagnostic],
) -> Array[ApiDiagnostic] {
  let diagnostics : Array[ApiDiagnostic] = []
  for diagnostic in left {
    diagnostics.push(diagnostic)
  }
  for diagnostic in right {
    diagnostics.push(diagnostic)
  }
  diagnostics
}

///|
fn added_impact(kind : String) -> Impact {
  if kind == "field" || kind == "constructor" || kind == "trait-method" {
    Major
  } else {
    Minor
  }
}

///|
fn should_report_nested_change(
  opposite_items : Array[ApiItem],
  item : ApiItem,
) -> Bool {
  if !is_nested_kind(item.kind) {
    return true
  }
  for candidate in opposite_items {
    if is_container_kind(candidate.kind) &&
      item.name.has_prefix("\{candidate.name}.") {
      return true
    }
  }
  false
}

///|
fn is_nested_kind(kind : String) -> Bool {
  kind == "field" ||
  kind == "constructor" ||
  kind == "trait-method" ||
  kind == "derive"
}

///|
fn is_container_kind(kind : String) -> Bool {
  kind == "struct" || kind == "enum" || kind == "trait" || kind == "suberror"
}

///|
fn find_item(items : Array[ApiItem], kind : String, name : String) -> ApiItem? {
  for item in items {
    if item.kind == kind && item.name == name {
      return Some(item)
    }
  }
  None
}

///|
fn find_kind_changed_item(items : Array[ApiItem], item : ApiItem) -> ApiItem? {
  if !is_top_level_kind(item.kind) {
    return None
  }
  for candidate in items {
    if candidate.name == item.name &&
      candidate.kind != item.kind &&
      is_top_level_kind(candidate.kind) {
      return Some(candidate)
    }
  }
  None
}

///|
fn is_top_level_kind(kind : String) -> Bool {
  kind == "fn" ||
  kind == "type" ||
  kind == "typealias" ||
  kind == "struct" ||
  kind == "enum" ||
  kind == "trait" ||
  kind == "impl" ||
  kind == "let" ||
  kind == "const" ||
  kind == "suberror" ||
  kind == "using"
}

///|
fn recommended_impact(changes : Array[ApiChange]) -> Impact {
  let mut saw_minor = false
  for change in changes {
    match change.impact {
      Major => return Major
      Minor => saw_minor = true
      Patch => ()
    }
  }
  if saw_minor {
    Minor
  } else {
    Patch
  }
}

///|
fn impact_rank(impact : Impact) -> Int {
  match impact {
    Patch => 0
    Minor => 1
    Major => 2
  }
}

///|
fn change_kind_rank(kind : ChangeKind) -> Int {
  match kind {
    Removed => 0
    Changed => 1
    Added => 2
  }
}

///|
fn sort_items(items : Array[ApiItem]) -> Unit {
  items.sort_by((a, b) => compare_item_key(a, b))
}

///|
fn sort_changes(changes : Array[ApiChange]) -> Unit {
  changes.sort_by((a, b) => compare_change_key(a, b))
}

///|
fn sort_kind_counts(counts : Array[ApiKindCount]) -> Unit {
  counts.sort_by((a, b) => a.kind.lexical_compare(b.kind))
}

///|
fn find_kind_count_index(counts : Array[ApiKindCount], kind : String) -> Int? {
  for i in 0..<counts.length() {
    if counts[i].kind == kind {
      return Some(i)
    }
  }
  None
}

///|
fn compare_item_key(a : ApiItem, b : ApiItem) -> Int {
  let kind_cmp = a.kind.lexical_compare(b.kind)
  if kind_cmp != 0 {
    kind_cmp
  } else {
    a.name.lexical_compare(b.name)
  }
}

///|
fn compare_change_key(a : ApiChange, b : ApiChange) -> Int {
  let impact_cmp = impact_rank(b.impact) - impact_rank(a.impact)
  if impact_cmp != 0 {
    impact_cmp
  } else {
    let kind_cmp = change_kind_rank(a.kind) - change_kind_rank(b.kind)
    if kind_cmp != 0 {
      kind_cmp
    } else {
      let item_cmp = a.item_kind.lexical_compare(b.item_kind)
      if item_cmp != 0 {
        item_cmp
      } else {
        a.name.lexical_compare(b.name)
      }
    }
  }
}

///|
fn impact_label(impact : Impact) -> String {
  match impact {
    Patch => "patch"
    Minor => "minor"
    Major => "major"
  }
}

///|
fn change_kind_label(kind : ChangeKind) -> String {
  match kind {
    Added => "added"
    Removed => "removed"
    Changed => "changed"
  }
}

///|
fn change_details(change : ApiChange) -> String {
  match change.kind {
    Added =>
      match change.new_signature {
        Some(signature) => "`\{escape_markdown_cell(signature)}`"
        None => ""
      }
    Removed =>
      match change.old_signature {
        Some(signature) => "`\{escape_markdown_cell(signature)}`"
        None => ""
      }
    Changed => {
      let old_text = match change.old_signature {
        Some(signature) => escape_markdown_cell(signature)
        None => ""
      }
      let new_text = match change.new_signature {
        Some(signature) => escape_markdown_cell(signature)
        None => ""
      }
      "`\{old_text}` -> `\{new_text}`"
    }
  }
}
