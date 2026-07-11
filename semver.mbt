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
/// Build a release-oriented decision from API, diagnostics, and SemVer data.
pub fn make_release_plan(
  report : ApiReport,
  diagnostics : Array[ApiDiagnostic],
  current : String,
  next : String,
) -> ReleasePlan {
  let version_check = check_version_bump(report, current, next)
  let diagnostic_summary = summarize_diagnostics(diagnostics)
  let status = release_plan_status(diagnostic_summary, version_check)
  {
    report,
    diagnostics,
    version_check,
    summary: summarize_report(report),
    diagnostic_summary,
    status,
    decision: release_plan_decision(status, version_check.required),
    next_action: release_plan_next_action(status, version_check),
  }
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
fn release_plan_status(
  diagnostic_summary : DiagnosticSummary,
  version_check : VersionCheck,
) -> String {
  if diagnostic_summary.errors > 0 {
    "blocked"
  } else if version_check.ok {
    "ready"
  } else {
    "needs-version-bump"
  }
}

///|
fn release_plan_decision(status : String, required : Impact) -> String {
  if status == "blocked" {
    "Fix interface snapshot diagnostics before publishing."
  } else if status == "ready" {
    "The proposed version satisfies the \{impact_label(required)} API impact."
  } else {
    "Increase the proposed version to satisfy the \{impact_label(required)} API impact."
  }
}

///|
fn release_plan_next_action(
  status : String,
  version_check : VersionCheck,
) -> String {
  if status == "blocked" {
    "Resolve diagnostic errors, regenerate package interfaces, then rerun MoonGuard."
  } else if status == "ready" {
    "Publish or merge after normal project checks pass."
  } else if version_check.required == Major {
    "Use a major version bump or accept the breaking API changes explicitly."
  } else if version_check.required == Minor {
    "Use a minor or major version bump for the added public API."
  } else {
    "Use any greater patch, minor, or major version."
  }
}
