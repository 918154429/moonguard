///|
/// Parse ignore rules used to filter accepted or experimental API changes.
///
/// Supported rule syntax:
///
/// `ignore KIND NAME [reason...]`
///
/// `KIND` and `NAME` may be `*`; `NAME` may also use a single `*` prefix,
/// suffix, or infix wildcard.
pub fn parse_ignore_rules(text : String) -> IgnoreParseResult {
  let rules : Array[ApiIgnoreRule] = []
  let errors : Array[String] = []
  let mut line_number = 1
  for raw_line in split_lines(text[:]) {
    parse_ignore_rule_line(raw_line, line_number, rules, errors)
    line_number += 1
  }
  { rules, errors }
}

///|
/// Filter a report using textual ignore rules.
pub fn filter_report(report : ApiReport, rules_text : String) -> ApiReport {
  let parsed = parse_ignore_rules(rules_text)
  filter_report_with_rules(report, parsed.rules)
}

///|
/// Filter a report using pre-parsed ignore rules.
pub fn filter_report_with_rules(
  report : ApiReport,
  rules : Array[ApiIgnoreRule],
) -> ApiReport {
  if rules.is_empty() {
    return report
  }
  let changes : Array[ApiChange] = []
  for change in report.changes {
    if !change_matches_any_ignore_rule(change, rules) {
      changes.push(change)
    }
  }
  sort_changes(changes)
  { changes, recommendation: recommended_impact(changes) }
}

///|
fn parse_ignore_rule_line(
  raw_line : StringView,
  line_number : Int,
  rules : Array[ApiIgnoreRule],
  errors : Array[String],
) -> Unit {
  let line = strip_rule_comment(raw_line).trim()
  if line.length() == 0 || line.has_prefix("#") {
    return
  }
  let words = split_rule_words(line)
  if words.length() == 0 {
    return
  }
  if words[0] != "ignore" {
    errors.push("line \{line_number}: expected 'ignore KIND NAME'")
    return
  }
  if words.length() < 3 {
    errors.push("line \{line_number}: ignore rule requires kind and name")
    return
  }
  let item_kind = words[1]
  let name = words[2]
  if !valid_ignore_kind(item_kind) {
    errors.push("line \{line_number}: invalid ignore kind '\{item_kind}'")
    return
  }
  if !valid_ignore_name_pattern(name) {
    errors.push("line \{line_number}: invalid ignore name '\{name}'")
    return
  }
  rules.push({ item_kind, name, reason: join_words(words, 3) })
}

///|
fn strip_rule_comment(line : StringView) -> StringView {
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
    } else if ch == '#' {
      return line.view(start_offset=0, end_offset=i)
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
fn split_rule_words(line : StringView) -> Array[String] {
  let words : Array[String] = []
  let mut start = 0
  let mut in_word = false
  for i in 0..<line.length() {
    let ch = line.unsafe_get(i).unsafe_to_char()
    if is_ascii_space(ch.to_int()) {
      if in_word {
        words.push(line.view(start_offset=start, end_offset=i).to_owned())
        in_word = false
      }
    } else if !in_word {
      start = i
      in_word = true
    }
  }
  if in_word {
    words.push(
      line.view(start_offset=start, end_offset=line.length()).to_owned(),
    )
  }
  words
}

///|
fn join_words(words : Array[String], start : Int) -> String {
  if start >= words.length() {
    return ""
  }
  let out = StringBuilder()
  for i in start..<words.length() {
    if i > start {
      out.write(" ")
    }
    out.write(words[i])
  }
  out.to_string()
}

///|
fn valid_ignore_kind(kind : String) -> Bool {
  kind == "*" ||
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
  kind == "using" ||
  kind == "field" ||
  kind == "constructor" ||
  kind == "trait-method" ||
  kind == "derive" ||
  kind == "unknown"
}

///|
fn valid_ignore_name_pattern(name : String) -> Bool {
  if name.length() == 0 {
    return false
  }
  for ch in name {
    if is_ascii_space(ch.to_int()) {
      return false
    }
  }
  true
}

///|
fn change_matches_any_ignore_rule(
  change : ApiChange,
  rules : Array[ApiIgnoreRule],
) -> Bool {
  for rule in rules {
    if change_matches_ignore_rule(change, rule) {
      return true
    }
  }
  false
}

///|
fn change_matches_ignore_rule(change : ApiChange, rule : ApiIgnoreRule) -> Bool {
  ignore_kind_matches(rule.item_kind, change.item_kind) &&
  wildcard_matches(rule.name, change.name)
}

///|
fn ignore_kind_matches(pattern : String, actual : String) -> Bool {
  if pattern == "*" || pattern == actual {
    return true
  }
  match actual.find("->") {
    Some(index) => {
      let left = actual[:index].to_owned()
      let right = actual[index + 2:].to_owned()
      pattern == left || pattern == right
    }
    None => false
  }
}

///|
fn wildcard_matches(pattern : String, value : String) -> Bool {
  if pattern == "*" || pattern == value {
    return true
  }
  if pattern.has_prefix("*") && pattern.has_suffix("*") && pattern.length() > 2 {
    return value.contains(pattern[1:pattern.length() - 1])
  }
  match pattern.find("*") {
    None => false
    Some(star) =>
      if star == 0 && pattern.length() == 1 {
        true
      } else {
        let prefix = pattern[:star]
        let suffix = pattern[star + 1:]
        value.has_prefix(prefix) && value.has_suffix(suffix)
      }
  }
}
