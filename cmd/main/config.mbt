///|
fn resolve_report_options(
  options : ReportOptions,
) -> Result[ReportOptions, String] {
  let resolved = if options.config_file.length() == 0 {
    options
  } else {
    match load_cli_config(options.config_file) {
      Err(message) => return Err(message)
      Ok(config) => merge_report_options(options, config)
    }
  }
  if resolved.ignore_file.length() > 0 && resolved.policy_file.length() > 0 {
    Err("error: --ignore-file and --policy-file cannot be used together")
  } else {
    Ok(resolved)
  }
}

///|
fn resolve_check_options(
  options : CheckOptions,
) -> Result[CheckOptions, String] {
  let resolved = if options.config_file.length() == 0 {
    options
  } else {
    match load_cli_config(options.config_file) {
      Err(message) => return Err(message)
      Ok(config) => merge_check_options(options, config)
    }
  }
  if resolved.current.length() == 0 {
    Err("error: check requires --current major.minor.patch")
  } else if resolved.next.length() == 0 {
    Err("error: check requires --next major.minor.patch")
  } else if resolved.ignore_file.length() > 0 &&
    resolved.policy_file.length() > 0 {
    Err("error: --ignore-file and --policy-file cannot be used together")
  } else {
    Ok(resolved)
  }
}

///|
fn load_cli_config(path : String) -> Result[CliConfig, String] {
  let text = read_file_raw(path)
  if text.has_prefix(read_error_prefix) {
    let message = text[read_error_prefix.length():].to_owned()
    return Err("error: cannot read config file '\{path}': \{message}")
  }
  parse_cli_config(path, text)
}

///|
fn merge_report_options(
  options : ReportOptions,
  config : CliConfig,
) -> ReportOptions {
  let format = if options.has_format || config.format.length() == 0 {
    options.format
  } else {
    config.format
  }
  let ignore_file = if options.has_ignore_file ||
    config.ignore_file.length() == 0 {
    options.ignore_file
  } else {
    config.ignore_file
  }
  let policy_file = if options.has_policy_file ||
    config.policy_file.length() == 0 {
    options.policy_file
  } else {
    config.policy_file
  }
  let policy_version = if options.has_policy_version ||
    config.policy_version.length() == 0 {
    options.policy_version
  } else {
    config.policy_version
  }
  {
    format,
    ignore_file,
    policy_file,
    policy_version,
    baseline: config.baseline,
    target: config.target,
    baseline_dir: config.baseline_dir,
    target_dir: config.target_dir,
    config_file: options.config_file,
    has_format: options.has_format || config.format.length() > 0,
    has_ignore_file: options.has_ignore_file || config.ignore_file.length() > 0,
    has_policy_file: options.has_policy_file || config.policy_file.length() > 0,
    has_policy_version: options.has_policy_version ||
    config.policy_version.length() > 0,
  }
}

///|
fn merge_check_options(
  options : CheckOptions,
  config : CliConfig,
) -> CheckOptions {
  let report_options = merge_report_options(
    {
      format: options.format,
      ignore_file: options.ignore_file,
      policy_file: options.policy_file,
      policy_version: options.policy_version,
      baseline: options.baseline,
      target: options.target,
      baseline_dir: options.baseline_dir,
      target_dir: options.target_dir,
      config_file: options.config_file,
      has_format: options.has_format,
      has_ignore_file: options.has_ignore_file,
      has_policy_file: options.has_policy_file,
      has_policy_version: options.has_policy_version,
    },
    config,
  )
  let current = if options.has_current || config.current.length() == 0 {
    options.current
  } else {
    config.current
  }
  let next = if options.has_next || config.next.length() == 0 {
    options.next
  } else {
    config.next
  }
  let policy_version = if options.has_policy_version {
    options.policy_version
  } else if options.has_next {
    options.next
  } else if config.policy_version.length() > 0 {
    config.policy_version
  } else {
    next
  }
  {
    current,
    next,
    format: report_options.format,
    ignore_file: report_options.ignore_file,
    policy_file: report_options.policy_file,
    policy_version,
    baseline: report_options.baseline,
    target: report_options.target,
    baseline_dir: report_options.baseline_dir,
    target_dir: report_options.target_dir,
    config_file: options.config_file,
    has_current: options.has_current || config.current.length() > 0,
    has_next: options.has_next || config.next.length() > 0,
    has_format: report_options.has_format,
    has_ignore_file: report_options.has_ignore_file,
    has_policy_file: report_options.has_policy_file,
    has_policy_version: options.has_policy_version ||
    config.policy_version.length() > 0 ||
    next.length() > 0,
  }
}

///|
fn parse_cli_config(path : String, text : String) -> Result[CliConfig, String] {
  let errors : Array[String] = []
  let mut format = ""
  let mut ignore_file = ""
  let mut policy_file = ""
  let mut policy_version = ""
  let mut current = ""
  let mut next = ""
  let mut baseline = ""
  let mut target = ""
  let mut baseline_dir = ""
  let mut target_dir = ""
  let mut line_number = 1
  for raw_line in split_lines(text[:]) {
    let line = strip_config_comment(raw_line).trim()
    if line.length() > 0 {
      match parse_config_assignment(line) {
        None => errors.push("line \{line_number}: expected KEY = VALUE")
        Some((key, value)) =>
          if key.length() == 0 {
            errors.push("line \{line_number}: config key must not be empty")
          } else if value.length() == 0 {
            errors.push(
              "line \{line_number}: config value for '\{key}' must not be empty",
            )
          } else if key == "format" {
            match normalize_format(value) {
              None =>
                errors.push(
                  "line \{line_number}: unsupported report format '\{value}'",
                )
              Some(normalized) => format = normalized
            }
          } else if key == "ignore_file" || key == "ignore-file" {
            ignore_file = value
          } else if key == "policy_file" || key == "policy-file" {
            policy_file = value
          } else if key == "policy_version" || key == "policy-version" {
            policy_version = value
          } else if key == "current" {
            current = value
          } else if key == "next" {
            next = value
          } else if key == "baseline" {
            baseline = value
          } else if key == "target" {
            target = value
          } else if key == "baseline_dir" || key == "baseline-dir" {
            baseline_dir = value
          } else if key == "target_dir" || key == "target-dir" {
            target_dir = value
          } else {
            errors.push("line \{line_number}: unknown config key '\{key}'")
          }
      }
    }
    line_number += 1
  }
  if errors.is_empty() {
    Ok({
      format,
      ignore_file,
      policy_file,
      policy_version,
      current,
      next,
      baseline,
      target,
      baseline_dir,
      target_dir,
    })
  } else {
    Err(render_config_errors(path, errors))
  }
}

///|
fn strip_config_comment(line : StringView) -> StringView {
  match line.find("#") {
    Some(index) => line.view(start_offset=0, end_offset=index)
    None => line
  }
}

///|
fn parse_config_assignment(line : StringView) -> (String, String)? {
  match line.find("=") {
    Some(index) =>
      Some(
        (
          line.view(start_offset=0, end_offset=index).trim().to_owned(),
          line.view(start_offset=index + 1).trim().to_owned(),
        ),
      )
    None => None
  }
}

///|
fn render_config_errors(config_file : String, errors : Array[String]) -> String {
  let out = StringBuilder()
  out.write("error: invalid config file '")
  out.write(config_file)
  out.write("'")
  for error in errors {
    out.write("\n  ")
    out.write(error)
  }
  out.to_string()
}
