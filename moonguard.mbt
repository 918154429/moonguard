///|
pub(all) enum ChangeKind {
  Added
  Removed
  Changed
} derive(Eq, Debug)

///|
pub(all) enum Impact {
  Patch
  Minor
  Major
} derive(Eq, Debug)

///|
pub struct ApiItem {
  kind : String
  name : String
  signature : String
} derive(Eq, Debug)

///|
pub struct ApiChange {
  kind : ChangeKind
  impact : Impact
  item_kind : String
  name : String
  old_signature : String?
  new_signature : String?
} derive(Eq, Debug)

///|
pub struct ApiReport {
  changes : Array[ApiChange]
  recommendation : Impact
} derive(Eq, Debug)

///|
/// Parse a MoonBit interface file into a normalized public API list.
pub fn parse_interface(text : String) -> Array[ApiItem] {
  let items : Array[ApiItem] = []
  for raw_line in split_lines(text[:]) {
    let line = normalize_space(strip_comment(raw_line).trim())
    if line.length() == 0 || !is_public_line(line[:]) {
      continue
    }
    match parse_public_item(line[:]) {
      Some(item) => items.push(item)
      None => ()
    }
  }
  sort_items(items)
  items
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
  for new_item in new_items {
    match find_item(old_items, new_item.kind, new_item.name) {
      Some(_) => ()
      None =>
        changes.push({
          kind: Added,
          impact: Minor,
          item_kind: new_item.kind,
          name: new_item.name,
          old_signature: None,
          new_signature: Some(new_item.signature),
        })
    }
  }
  sort_changes(changes)
  { changes, recommendation: recommended_impact(changes) }
}

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
pub fn semver_recommendation(old_text : String, new_text : String) -> String {
  impact_label(diff_interfaces(old_text, new_text).recommendation)
}

///|
fn parse_public_item(line : StringView) -> ApiItem? {
  let public_body = public_body(line)
  if public_body.length() == 0 {
    return None
  }
  if public_body.has_prefix("fn ") {
    Some(make_item("fn", public_body.view(start_offset=3)))
  } else if public_body.has_prefix("async fn ") {
    Some(make_item("fn", public_body.view(start_offset=9)))
  } else if public_body.has_prefix("typealias ") {
    Some(make_item("typealias", public_body.view(start_offset=10)))
  } else if public_body.has_prefix("type ") {
    Some(make_item("type", public_body.view(start_offset=5)))
  } else if public_body.has_prefix("struct ") {
    Some(make_item("struct", public_body.view(start_offset=7)))
  } else if public_body.has_prefix("enum ") {
    Some(make_item("enum", public_body.view(start_offset=5)))
  } else if public_body.has_prefix("trait ") {
    Some(make_item("trait", public_body.view(start_offset=6)))
  } else if public_body.has_prefix("impl ") {
    Some(make_item("impl", public_body.view(start_offset=5)))
  } else if public_body.has_prefix("let ") {
    Some(make_item("let", public_body.view(start_offset=4)))
  } else if public_body.has_prefix("const ") {
    Some(make_item("const", public_body.view(start_offset=6)))
  } else {
    Some(make_item("unknown", public_body))
  }
}

///|
fn make_item(kind : String, body : StringView) -> ApiItem {
  let signature = normalize_signature(body)
  { kind, name: extract_name(signature[:]), signature }
}

///|
fn public_body(line : StringView) -> StringView {
  if line.has_prefix("pub(all) ") {
    line.view(start_offset=9).trim()
  } else if line.has_prefix("pub(open) ") {
    line.view(start_offset=10).trim()
  } else if line.has_prefix("pub ") {
    line.view(start_offset=4).trim()
  } else {
    ""
  }
}

///|
fn is_public_line(line : StringView) -> Bool {
  line.has_prefix("pub ") ||
  line.has_prefix("pub(all) ") ||
  line.has_prefix("pub(open) ")
}

///|
fn normalize_signature(text : StringView) -> String {
  normalize_space(text.trim())
}

///|
fn extract_name(signature : StringView) -> String {
  let mut end = 0
  while end < signature.length() {
    let ch = signature.unsafe_get(end).unsafe_to_char()
    if is_name_boundary(ch) {
      break
    }
    end += 1
  }
  signature.view(start_offset=0, end_offset=end).to_owned()
}

///|
fn is_name_boundary(ch : Char) -> Bool {
  ch == '(' ||
  ch == ':' ||
  ch == '[' ||
  ch == '{' ||
  ch == '=' ||
  is_ascii_space(ch.to_int())
}

///|
fn strip_comment(line : StringView) -> StringView {
  match line.find("//") {
    Some(index) => line.view(start_offset=0, end_offset=index)
    None => line
  }
}

///|
fn normalize_space(text : StringView) -> String {
  let out = StringBuilder(size_hint=text.length())
  let mut saw_space = false
  for ch in text {
    if is_ascii_space(ch.to_int()) {
      saw_space = true
    } else {
      if saw_space && !out.is_empty() {
        out.write(" ")
      }
      out.write_char(ch)
      saw_space = false
    }
  }
  out.to_string()
}

///|
fn split_lines(text : StringView) -> Array[StringView] {
  let lines : Array[StringView] = []
  let mut start = 0
  for i in 0..<text.length() {
    if text.unsafe_get(i).to_int() == '\n'.to_int() {
      lines.push(
        text.view(start_offset=start, end_offset=i).trim_end(chars="\r"),
      )
      start = i + 1
    }
  }
  lines.push(
    text.view(start_offset=start, end_offset=text.length()).trim_end(chars="\r"),
  )
  lines
}

///|
fn is_ascii_space(code : Int) -> Bool {
  code == ' '.to_int() || code == '\t'.to_int() || code == '\r'.to_int()
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
