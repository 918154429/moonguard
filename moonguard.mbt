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
pub struct Version {
  major : Int
  minor : Int
  patch : Int
} derive(Eq, Debug)

///|
pub struct VersionCheck {
  ok : Bool
  required : Impact
  current : String
  next : String
  reason : String
} derive(Eq, Debug)

///|
/// Parse a MoonBit interface file into a normalized public API list.
pub fn parse_interface(text : String) -> Array[ApiItem] {
  let items : Array[ApiItem] = []
  let mut container_kind = ""
  let mut container_name = ""
  let mut pending_attributes : Array[String] = []
  for raw_line in split_lines(text[:]) {
    let line = normalize_space(strip_comment(raw_line).trim())
    if line.length() == 0 {
      pending_attributes = []
      continue
    }
    if line.has_prefix("#") {
      pending_attributes.push(line)
      continue
    }
    if container_kind.length() > 0 {
      if line.has_prefix("}") {
        for item in parse_closing_derives(container_name, line[:]) {
          items.push(item)
        }
        container_kind = ""
        container_name = ""
        pending_attributes = []
        continue
      }
      if !is_public_line(line[:]) {
        match
          parse_container_item(
            container_kind,
            container_name,
            line[:],
            pending_attributes,
          ) {
          Some(item) => items.push(item)
          None => ()
        }
        pending_attributes = []
        continue
      }
      container_kind = ""
      container_name = ""
    }
    if !is_public_line(line[:]) {
      match parse_interface_item(line[:], pending_attributes) {
        Some(item) => {
          items.push(item)
          for derive_item in parse_closing_derives(item.name, line[:]) {
            items.push(derive_item)
          }
        }
        None => ()
      }
      pending_attributes = []
      continue
    }
    match parse_public_item(line[:], pending_attributes) {
      Some(item) => {
        if opens_public_container(item.kind, line[:]) {
          container_kind = item.kind
          container_name = item.name
        }
        items.push(item)
        for derive_item in parse_closing_derives(item.name, line[:]) {
          items.push(derive_item)
        }
      }
      None => ()
    }
    pending_attributes = []
  }
  sort_items(items)
  items
}

///|
/// Parse a MoonBit interface file and namespace every public API name.
pub fn parse_interface_with_namespace(
  text : String,
  scope : String,
) -> Array[ApiItem] {
  let items = parse_interface(text)
  if scope.length() == 0 {
    return items
  }
  let namespaced : Array[ApiItem] = []
  for item in items {
    namespaced.push({
      kind: item.kind,
      name: "\{scope}::\{item.name}",
      signature: item.signature,
    })
  }
  sort_items(namespaced)
  namespaced
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
  for new_item in new_items {
    match find_item(old_items, new_item.kind, new_item.name) {
      Some(_) => ()
      None =>
        match find_kind_changed_item(old_items, new_item) {
          Some(_) => ()
          None =>
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
  sort_changes(changes)
  { changes, recommendation: recommended_impact(changes) }
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
/// Render a machine-readable JSON compatibility report.
pub fn render_json_report(report : ApiReport) -> String {
  let out = StringBuilder()
  write_json_report_object(out, report, 0)
  out.write("\n")
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
pub fn semver_recommendation(old_text : String, new_text : String) -> String {
  impact_label(diff_interfaces(old_text, new_text).recommendation)
}

///|
/// Parse a strict `major.minor.patch` SemVer core version.
pub fn parse_version(text : String) -> Version? {
  parse_version_view(text[:])
}

///|
/// Convert a parsed version back to its canonical `major.minor.patch` form.
pub fn version_to_string(version : Version) -> String {
  "\{version.major}.\{version.minor}.\{version.patch}"
}

///|
/// Compare two parsed versions.
///
/// Returns `-1` when `left < right`, `0` when equal, and `1` when
/// `left > right`.
pub fn compare_versions(left : Version, right : Version) -> Int {
  if left.major < right.major {
    -1
  } else if left.major > right.major {
    1
  } else if left.minor < right.minor {
    -1
  } else if left.minor > right.minor {
    1
  } else if left.patch < right.patch {
    -1
  } else if left.patch > right.patch {
    1
  } else {
    0
  }
}

///|
/// Check whether `next` satisfies the SemVer bump required by a report.
pub fn check_version_bump(
  report : ApiReport,
  current : String,
  next : String,
) -> VersionCheck {
  let required = report.recommendation
  match parse_version(current) {
    None =>
      make_version_check(
        false, required, current, next, "current version must be a strict major.minor.patch value",
      )
    Some(current_version) =>
      match parse_version(next) {
        None =>
          make_version_check(
            false, required, current, next, "next version must be a strict major.minor.patch value",
          )
        Some(next_version) =>
          check_parsed_version_bump(
            required, current, next, current_version, next_version,
          )
      }
  }
}

///|
/// Diff two interface texts and check the proposed SemVer bump.
pub fn check_interface_version_bump(
  old_text : String,
  new_text : String,
  current : String,
  next : String,
) -> VersionCheck {
  check_version_bump(diff_interfaces(old_text, new_text), current, next)
}

///|
fn parse_version_view(text : StringView) -> Version? {
  let text = text.trim()
  match text.find(".") {
    None => None
    Some(first_dot) => {
      let major_part = text.view(start_offset=0, end_offset=first_dot)
      let rest = text.view(start_offset=first_dot + 1)
      match rest.find(".") {
        None => None
        Some(second_dot) => {
          let minor_part = rest.view(start_offset=0, end_offset=second_dot)
          let patch_part = rest.view(start_offset=second_dot + 1)
          match patch_part.find(".") {
            Some(_) => None
            None =>
              match parse_version_number(major_part) {
                None => None
                Some(major) =>
                  match parse_version_number(minor_part) {
                    None => None
                    Some(minor) =>
                      match parse_version_number(patch_part) {
                        None => None
                        Some(patch) => Some({ major, minor, patch })
                      }
                  }
              }
          }
        }
      }
    }
  }
}

///|
fn parse_version_number(text : StringView) -> Int? {
  if text.length() == 0 {
    return None
  }
  if text.length() > 1 && text.unsafe_get(0).unsafe_to_char() == '0' {
    return None
  }
  let mut value = 0
  for ch in text {
    match decimal_digit_value(ch) {
      None => return None
      Some(digit) => value = value * 10 + digit
    }
  }
  Some(value)
}

///|
fn decimal_digit_value(ch : Char) -> Int? {
  let code = ch.to_int()
  if code >= '0'.to_int() && code <= '9'.to_int() {
    Some(code - '0'.to_int())
  } else {
    None
  }
}

///|
fn check_parsed_version_bump(
  required : Impact,
  current : String,
  next : String,
  current_version : Version,
  next_version : Version,
) -> VersionCheck {
  if compare_versions(next_version, current_version) <= 0 {
    return make_version_check(
      false, required, current, next, "next version must be greater than current version",
    )
  }
  if version_satisfies_required_bump(required, current_version, next_version) {
    make_version_check(
      true,
      required,
      current,
      next,
      "next version satisfies the \{impact_label(required)} recommendation",
    )
  } else {
    make_version_check(
      false,
      required,
      current,
      next,
      required_bump_failure_reason(required),
    )
  }
}

///|
fn version_satisfies_required_bump(
  required : Impact,
  current : Version,
  next : Version,
) -> Bool {
  match required {
    Patch => compare_versions(next, current) > 0
    Minor =>
      next.major > current.major ||
      (next.major == current.major && next.minor > current.minor)
    Major => next.major > current.major
  }
}

///|
fn required_bump_failure_reason(required : Impact) -> String {
  match required {
    Patch => "patch recommendation requires any greater next version"
    Minor => "minor recommendation requires increasing minor or major version"
    Major => "major recommendation requires increasing major version"
  }
}

///|
fn make_version_check(
  ok : Bool,
  required : Impact,
  current : String,
  next : String,
  reason : String,
) -> VersionCheck {
  { ok, required, current, next, reason }
}

///|
fn parse_interface_item(
  line : StringView,
  attributes : Array[String],
) -> ApiItem? {
  if line.has_prefix("type ") {
    Some(make_type_item(line.view(start_offset=5), attributes))
  } else {
    None
  }
}

///|
fn parse_public_item(line : StringView, attributes : Array[String]) -> ApiItem? {
  let public_body = public_body(line)
  let visibility = public_visibility(line)
  if public_body.length() == 0 {
    return None
  }
  if public_body.has_prefix("fn ") {
    Some(
      make_item_with_visibility(
        "fn",
        public_body.view(start_offset=3),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("fn[") {
    Some(
      make_item_with_visibility(
        "fn",
        public_body.view(start_offset=2),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("async fn ") {
    Some(make_item_with_visibility("fn", public_body, visibility, attributes))
  } else if public_body.has_prefix("async fn[") {
    Some(make_item_with_visibility("fn", public_body, visibility, attributes))
  } else if public_body.has_prefix("typealias ") {
    Some(
      make_item_with_visibility(
        "typealias",
        public_body.view(start_offset=10),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("type ") {
    Some(
      make_type_item_with_visibility(
        public_body.view(start_offset=5),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("struct ") {
    Some(
      make_item_with_visibility(
        "struct",
        public_body.view(start_offset=7),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("enum ") {
    Some(
      make_item_with_visibility(
        "enum",
        public_body.view(start_offset=5),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("trait ") {
    Some(
      make_item_with_visibility(
        "trait",
        public_body.view(start_offset=6),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("impl ") {
    Some(
      make_impl_item(public_body.view(start_offset=5), visibility, attributes),
    )
  } else if public_body.has_prefix("impl[") {
    Some(
      make_impl_item(public_body.view(start_offset=4), visibility, attributes),
    )
  } else if public_body.has_prefix("let ") {
    Some(
      make_item_with_visibility(
        "let",
        public_body.view(start_offset=4),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("const ") {
    Some(
      make_item_with_visibility(
        "const",
        public_body.view(start_offset=6),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("suberror ") {
    Some(
      make_item_with_visibility(
        "suberror",
        public_body.view(start_offset=9),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("using ") {
    Some(
      make_using_item(public_body.view(start_offset=6), visibility, attributes),
    )
  } else {
    Some(make_unknown_item(public_body, visibility, attributes))
  }
}

///|
fn make_type_item(body : StringView, attributes : Array[String]) -> ApiItem {
  let signature = normalize_signature(strip_inline_derive(body))
  {
    kind: "type",
    name: extract_name(signature[:]),
    signature: apply_attributes(signature, attributes),
  }
}

///|
fn make_type_item_with_visibility(
  body : StringView,
  visibility : String,
  attributes : Array[String],
) -> ApiItem {
  let signature = normalize_signature(strip_inline_derive(body))
  {
    kind: "type",
    name: extract_name(signature[:]),
    signature: apply_attributes(
      apply_visibility(signature, visibility),
      attributes,
    ),
  }
}

///|
fn make_item_with_visibility(
  kind : String,
  body : StringView,
  visibility : String,
  attributes : Array[String],
) -> ApiItem {
  let signature = normalize_signature(body)
  {
    kind,
    name: extract_name(signature[:]),
    signature: apply_attributes(
      apply_visibility(signature, visibility),
      attributes,
    ),
  }
}

///|
fn make_named_item_with_attributes(
  kind : String,
  name : String,
  body : StringView,
  attributes : Array[String],
) -> ApiItem {
  {
    kind,
    name,
    signature: apply_attributes(normalize_signature(body), attributes),
  }
}

///|
fn make_impl_item(
  body : StringView,
  visibility : String,
  attributes : Array[String],
) -> ApiItem {
  let signature = normalize_signature(body)
  let name = trim_leading_generic_params(signature[:]).to_owned()
  {
    kind: "impl",
    name,
    signature: apply_attributes(
      apply_visibility(signature, visibility),
      attributes,
    ),
  }
}

///|
fn make_using_item(
  body : StringView,
  visibility : String,
  attributes : Array[String],
) -> ApiItem {
  let signature = normalize_signature(body)
  {
    kind: "using",
    name: extract_using_name(signature[:]),
    signature: apply_attributes(
      apply_visibility(signature, visibility),
      attributes,
    ),
  }
}

///|
fn make_unknown_item(
  body : StringView,
  visibility : String,
  attributes : Array[String],
) -> ApiItem {
  let signature = normalize_signature(body)
  {
    kind: "unknown",
    name: signature,
    signature: apply_attributes(
      apply_visibility(signature, visibility),
      attributes,
    ),
  }
}

///|
fn parse_container_item(
  kind : String,
  parent : String,
  line : StringView,
  attributes : Array[String],
) -> ApiItem? {
  if line.has_prefix("#") || line.has_prefix("priv ") {
    return None
  }
  if kind == "struct" {
    parse_struct_field(parent, line, attributes)
  } else if kind == "enum" || kind == "suberror" {
    parse_constructor(parent, line, attributes)
  } else if kind == "trait" {
    parse_trait_method(parent, line, attributes)
  } else {
    None
  }
}

///|
fn parse_struct_field(
  parent : String,
  line : StringView,
  attributes : Array[String],
) -> ApiItem? {
  match line.find(":") {
    Some(_) => {
      let field_name = extract_field_name(line)
      if field_name.length() == 0 {
        None
      } else {
        Some(
          make_named_item_with_attributes(
            "field",
            "\{parent}.\{field_name}",
            line,
            attributes,
          ),
        )
      }
    }
    None => None
  }
}

///|
fn parse_constructor(
  parent : String,
  line : StringView,
  attributes : Array[String],
) -> ApiItem? {
  let signature = normalize_signature(line)
  if signature.length() == 0 {
    None
  } else {
    let name = extract_name(signature[:])
    if name.length() == 0 {
      None
    } else {
      Some({
        kind: "constructor",
        name: "\{parent}.\{name}",
        signature: apply_attributes(signature, attributes),
      })
    }
  }
}

///|
fn parse_closing_derives(parent : String, line : StringView) -> Array[ApiItem] {
  let items : Array[ApiItem] = []
  match derive_body(line) {
    Some(body) =>
      for trait_name in split_top_level_commas(body) {
        let trait_name = trait_name.trim()
        if trait_name.length() > 0 {
          let signature = "derive(\{normalize_signature(trait_name)})"
          items.push({
            kind: "derive",
            name: "\{parent}.\{normalize_signature(trait_name)}",
            signature,
          })
        }
      }
    None => ()
  }
  items
}

///|
fn derive_body(line : StringView) -> StringView? {
  match line.find("derive(") {
    Some(start) => {
      let body_start = start + 7
      let mut depth = 1
      for i in body_start..<line.length() {
        let ch = line.unsafe_get(i).unsafe_to_char()
        if ch == '(' {
          depth += 1
        } else if ch == ')' {
          depth -= 1
          if depth == 0 {
            return Some(line.view(start_offset=body_start, end_offset=i).trim())
          }
        }
      }
      None
    }
    None => None
  }
}

///|
fn strip_inline_derive(text : StringView) -> StringView {
  match text.find(" derive(") {
    Some(index) => text.view(start_offset=0, end_offset=index).trim()
    None => text.trim()
  }
}

///|
fn split_top_level_commas(text : StringView) -> Array[StringView] {
  let parts : Array[StringView] = []
  let mut start = 0
  let mut round_depth = 0
  let mut square_depth = 0
  for i in 0..<text.length() {
    let ch = text.unsafe_get(i).unsafe_to_char()
    if ch == '(' {
      round_depth += 1
    } else if ch == ')' {
      round_depth -= 1
    } else if ch == '[' {
      square_depth += 1
    } else if ch == ']' {
      square_depth -= 1
    } else if ch == ',' && round_depth == 0 && square_depth == 0 {
      parts.push(text.view(start_offset=start, end_offset=i))
      start = i + 1
    }
  }
  parts.push(text.view(start_offset=start, end_offset=text.length()))
  parts
}

///|
fn parse_trait_method(
  parent : String,
  line : StringView,
  attributes : Array[String],
) -> ApiItem? {
  if line.has_prefix("fn ") {
    Some(make_trait_method(parent, line.view(start_offset=3), attributes))
  } else if line.has_prefix("fn[") {
    Some(make_trait_method(parent, line.view(start_offset=2), attributes))
  } else if line.has_prefix("async fn ") || line.has_prefix("async fn[") {
    Some(make_trait_method(parent, line, attributes))
  } else {
    None
  }
}

///|
fn make_trait_method(
  parent : String,
  body : StringView,
  attributes : Array[String],
) -> ApiItem {
  let signature = normalize_signature(body)
  let name = extract_name(signature[:])
  {
    kind: "trait-method",
    name: "\{parent}.\{name}",
    signature: apply_attributes(signature, attributes),
  }
}

///|
fn opens_public_container(kind : String, line : StringView) -> Bool {
  (kind == "struct" || kind == "enum" || kind == "trait" || kind == "suberror") &&
  has_open_brace(line) &&
  !has_close_brace(line)
}

///|
fn has_open_brace(line : StringView) -> Bool {
  match line.find("{") {
    Some(_) => true
    None => false
  }
}

///|
fn has_close_brace(line : StringView) -> Bool {
  match line.find("}") {
    Some(_) => true
    None => false
  }
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
fn public_visibility(line : StringView) -> String {
  if line.has_prefix("pub(all) ") {
    "pub(all)"
  } else if line.has_prefix("pub(open) ") {
    "pub(open)"
  } else {
    "pub"
  }
}

///|
fn apply_visibility(signature : String, visibility : String) -> String {
  if visibility == "pub" {
    signature
  } else {
    "\{visibility} \{signature}"
  }
}

///|
fn apply_attributes(signature : String, attributes : Array[String]) -> String {
  if attributes.is_empty() {
    return signature
  }
  let out = StringBuilder()
  for attribute in attributes {
    if !out.is_empty() {
      out.write(" ")
    }
    out.write(attribute)
  }
  out.write(" ")
  out.write(signature)
  out.to_string()
}

///|
fn is_public_line(line : StringView) -> Bool {
  line.has_prefix("pub ") ||
  line.has_prefix("pub(all) ") ||
  line.has_prefix("pub(open) ")
}

///|
fn normalize_signature(text : StringView) -> String {
  let signature = normalize_space(text.trim())
  if signature.length() > 0 &&
    signature.unsafe_get(signature.length() - 1).unsafe_to_char() == '{' {
    signature[:signature.length() - 1].trim().to_owned()
  } else {
    signature
  }
}

///|
fn extract_name(signature : StringView) -> String {
  let signature = trim_callable_prefix(signature)
  let mut end = 0
  while end < signature.length() {
    let ch = signature.unsafe_get(end).unsafe_to_char()
    if ch == ':' &&
      end + 1 < signature.length() &&
      signature.unsafe_get(end + 1).unsafe_to_char() == ':' {
      end += 2
      continue
    }
    if is_name_boundary(ch) {
      break
    }
    end += 1
  }
  signature.view(start_offset=0, end_offset=end).to_owned()
}

///|
fn trim_callable_prefix(signature : StringView) -> StringView {
  let signature = signature.trim()
  if signature.has_prefix("async fn ") {
    trim_leading_generic_params(signature.view(start_offset=9))
  } else if signature.has_prefix("async fn[") {
    trim_leading_generic_params(signature.view(start_offset=8))
  } else if signature.has_prefix("fn ") {
    trim_leading_generic_params(signature.view(start_offset=3))
  } else if signature.has_prefix("fn[") {
    trim_leading_generic_params(signature.view(start_offset=2))
  } else {
    trim_leading_generic_params(signature)
  }
}

///|
fn trim_leading_generic_params(text : StringView) -> StringView {
  let text = text.trim()
  if !text.has_prefix("[") {
    return text
  }
  let mut depth = 0
  for i in 0..<text.length() {
    let ch = text.unsafe_get(i).unsafe_to_char()
    if ch == '[' {
      depth += 1
    } else if ch == ']' {
      depth -= 1
      if depth == 0 {
        return text.view(start_offset=i + 1).trim()
      }
    }
  }
  text
}

///|
fn extract_field_name(line : StringView) -> String {
  let head = match line.find(":") {
    Some(index) => line.view(start_offset=0, end_offset=index).trim()
    None => line.trim()
  }
  let head = if head.has_prefix("mut ") {
    head.view(start_offset=4).trim()
  } else {
    head
  }
  extract_name(head)
}

///|
fn extract_using_name(signature : StringView) -> String {
  match brace_body(signature) {
    Some(body) =>
      match body.find(" as ") {
        Some(index) => extract_name(body.view(start_offset=index + 4).trim())
        None => {
          let body = if body.has_prefix("type ") {
            body.view(start_offset=5).trim()
          } else {
            body
          }
          extract_name(body)
        }
      }
    None => extract_name(signature)
  }
}

///|
fn brace_body(text : StringView) -> StringView? {
  match text.find("{") {
    Some(start) =>
      match text.find("}") {
        Some(end) =>
          if end > start {
            Some(text.view(start_offset=start + 1, end_offset=end).trim())
          } else {
            None
          }
        None => None
      }
    None => None
  }
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
  let mut in_string = false
  let mut escaped = false
  let mut i = 0
  while i < line.length() {
    let ch = line.unsafe_get(i).unsafe_to_char()
    if in_string {
      if escaped {
        escaped = false
      } else if ch == '\\' {
        escaped = true
      } else if ch == '"' {
        in_string = false
      }
    } else if ch == '"' {
      in_string = true
    } else if ch == '/' &&
      i + 1 < line.length() &&
      line.unsafe_get(i + 1).unsafe_to_char() == '/' {
      return line.view(start_offset=0, end_offset=i)
    }
    i += 1
  }
  line
}

///|
fn normalize_space(text : StringView) -> String {
  let out = StringBuilder(size_hint=text.length())
  let mut saw_space = false
  let mut in_string = false
  let mut escaped = false
  for ch in text {
    if in_string {
      out.write_char(ch)
      if escaped {
        escaped = false
      } else if ch == '\\' {
        escaped = true
      } else if ch == '"' {
        in_string = false
      }
    } else if ch == '"' {
      if saw_space && !out.is_empty() {
        out.write(" ")
      }
      out.write_char(ch)
      saw_space = false
      in_string = true
    } else if is_ascii_space(ch.to_int()) {
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
