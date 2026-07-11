///|
fn diff_file_report(
  old_path : String,
  new_path : String,
) -> Result[@moonguard.ApiReport, String] {
  let old_text = read_file_raw(old_path)
  if old_text.has_prefix(read_error_prefix) {
    let message = old_text[read_error_prefix.length():].to_owned()
    return Err(
      "error: cannot read old interface file '\{old_path}': \{message}",
    )
  }
  let new_text = read_file_raw(new_path)
  if new_text.has_prefix(read_error_prefix) {
    let message = new_text[read_error_prefix.length():].to_owned()
    return Err(
      "error: cannot read new interface file '\{new_path}': \{message}",
    )
  }
  Ok(@moonguard.diff_interfaces(old_text, new_text))
}

///|
fn diff_dir_package_report(
  old_dir : String,
  new_dir : String,
) -> Result[PackageReportResult, String] {
  let old_files = list_interface_files_raw(old_dir)
  if old_files.has_prefix(read_error_prefix) {
    let message = old_files[read_error_prefix.length():].to_owned()
    return Err(
      "error: cannot list old interface directory '\{old_dir}': \{message}",
    )
  }
  let new_files = list_interface_files_raw(new_dir)
  if new_files.has_prefix(read_error_prefix) {
    let message = new_files[read_error_prefix.length():].to_owned()
    return Err(
      "error: cannot list new interface directory '\{new_dir}': \{message}",
    )
  }
  let old_snapshot = match
    read_dir_snapshot(old_dir, parse_file_list(old_files[:]), "old") {
    Ok(snapshot) => snapshot
    Err(message) => return Err(message)
  }
  let new_snapshot = match
    read_dir_snapshot(new_dir, parse_file_list(new_files[:]), "new") {
    Ok(snapshot) => snapshot
    Err(message) => return Err(message)
  }
  let comparison = @moonguard.compare_api_snapshots(old_snapshot, new_snapshot)
  Ok({ report: comparison.report, diagnostics: comparison.diagnostics })
}

///|
fn apply_ignore_file(
  report : @moonguard.ApiReport,
  ignore_file : String,
) -> Result[@moonguard.ApiReport, String] {
  if ignore_file.length() == 0 {
    return Ok(report)
  }
  let rules_text = read_file_raw(ignore_file)
  if rules_text.has_prefix(read_error_prefix) {
    let message = rules_text[read_error_prefix.length():].to_owned()
    return Err("error: cannot read ignore file '\{ignore_file}': \{message}")
  }
  let parsed = @moonguard.parse_ignore_rules(rules_text)
  if !parsed.errors.is_empty() {
    return Err(render_ignore_errors(ignore_file, parsed.errors))
  }
  Ok(@moonguard.filter_report_with_rules(report, parsed.rules))
}

///|
fn apply_policy_file(
  report : @moonguard.ApiReport,
  policy_file : String,
  target_version : String,
) -> Result[@moonguard.ApiPolicyEvaluation, String] {
  let rules_text = read_file_raw(policy_file)
  if rules_text.has_prefix(read_error_prefix) {
    let message = rules_text[read_error_prefix.length():].to_owned()
    return Err("error: cannot read policy file '\{policy_file}': \{message}")
  }
  Ok(@moonguard.evaluate_policy_text(report, rules_text, target_version))
}

///|
fn read_dir_snapshot(
  root : String,
  files : Array[String],
  label : String,
) -> Result[@moonguard.ApiSnapshot, String] {
  if files.is_empty() {
    return Err(
      "error: no .mbti files found in \{label} interface directory '\{root}'",
    )
  }
  let api_files : Array[@moonguard.ApiFile] = []
  for rel in files {
    let path = join_path(root, rel)
    let text = read_file_raw(path)
    if text.has_prefix(read_error_prefix) {
      let message = text[read_error_prefix.length():].to_owned()
      return Err(
        "error: cannot read \{label} interface file '\{rel}': \{message}",
      )
    }
    api_files.push(@moonguard.api_file(rel, text))
  }
  Ok(@moonguard.build_api_snapshot(api_files))
}

///|
fn parse_file_list(raw : StringView) -> Array[String] {
  let files : Array[String] = []
  for line in split_lines(raw) {
    let file = line.trim()
    if file.length() > 0 {
      files.push(file.to_owned())
    }
  }
  files
}

///|
fn join_path(root : String, relative_path : String) -> String {
  "\{root}/\{relative_path}"
}
