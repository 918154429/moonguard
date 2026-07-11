///|
fn normalize_args(args : Array[String]) -> ArrayView[String] {
  let start = command_start(args)
  args[start:]
}

///|
fn command_start(args : Array[String]) -> Int {
  for i in 0..<args.length() {
    let arg = args[i]
    if arg == "report" ||
      arg == "report-dir" ||
      arg == "report-text" ||
      arg == "check-dir" ||
      arg == "release-plan" ||
      arg == "inventory-dir" ||
      arg == "check" ||
      arg == "--help" ||
      arg == "-h" ||
      arg == "--version" ||
      arg == "-V" {
      return i
    }
  }
  args.length()
}

///|
fn parse_optional_path_pair(
  args : ArrayView[String],
  error_message : String,
) -> Result[(String, String, Int), String] {
  if args.length() >= 3 && !is_option_arg(args[1]) && !is_option_arg(args[2]) {
    Ok((args[1].to_string(), args[2].to_string(), 3))
  } else if args.length() >= 2 && !is_option_arg(args[1]) {
    Err("error: \{error_message}")
  } else {
    Ok(("", "", 1))
  }
}

///|
fn parse_optional_path(
  args : ArrayView[String],
  error_message : String,
) -> Result[(String, Int), String] {
  if args.length() >= 2 && !is_option_arg(args[1]) {
    if args.length() >= 3 && !is_option_arg(args[2]) {
      Err("error: \{error_message}")
    } else {
      Ok((args[1].to_string(), 2))
    }
  } else {
    Ok(("", 1))
  }
}

///|
fn is_option_arg(value : String) -> Bool {
  value.has_prefix("--")
}

///|
fn choose_configured_path(argument : String, configured : String) -> String {
  if argument.length() > 0 {
    argument
  } else {
    configured
  }
}

///|
fn parse_report_options(
  args : ArrayView[String],
  start : Int,
) -> Result[ReportOptions, String] {
  let mut format = "markdown"
  let mut ignore_file = ""
  let mut policy_file = ""
  let mut policy_version = ""
  let baseline = ""
  let target = ""
  let baseline_dir = ""
  let target_dir = ""
  let mut config_file = ""
  let mut has_format = false
  let mut has_ignore_file = false
  let mut has_policy_file = false
  let mut has_policy_version = false
  let mut i = start
  while i < args.length() {
    let option = args[i]
    if option == "--format" {
      if i + 1 >= args.length() {
        return Err("error: --format requires markdown or json")
      }
      match normalize_format(args[i + 1]) {
        None => return Err("error: unsupported report format '\{args[i + 1]}'")
        Some(value) => {
          format = value
          has_format = true
        }
      }
      i += 2
    } else if option == "--ignore-file" {
      if i + 1 >= args.length() {
        return Err("error: --ignore-file requires a path")
      }
      ignore_file = args[i + 1]
      has_ignore_file = true
      i += 2
    } else if option == "--policy-file" {
      if i + 1 >= args.length() {
        return Err("error: --policy-file requires a path")
      }
      policy_file = args[i + 1]
      has_policy_file = true
      i += 2
    } else if option == "--policy-version" {
      if i + 1 >= args.length() {
        return Err(
          "error: --policy-version requires a major.minor.patch version",
        )
      }
      policy_version = args[i + 1]
      has_policy_version = true
      i += 2
    } else if option == "--config" {
      if i + 1 >= args.length() {
        return Err("error: --config requires a path")
      }
      config_file = args[i + 1]
      i += 2
    } else {
      return Err("error: unknown option '\{option}'")
    }
  }
  Ok({
    format,
    ignore_file,
    policy_file,
    policy_version,
    baseline,
    target,
    baseline_dir,
    target_dir,
    config_file,
    has_format,
    has_ignore_file,
    has_policy_file,
    has_policy_version,
  })
}

///|
fn parse_check_options(
  args : ArrayView[String],
  start : Int,
) -> Result[CheckOptions, String] {
  let mut current = ""
  let mut next = ""
  let mut format = "markdown"
  let mut ignore_file = ""
  let mut policy_file = ""
  let mut policy_version = ""
  let baseline = ""
  let target = ""
  let baseline_dir = ""
  let target_dir = ""
  let mut config_file = ""
  let mut has_current = false
  let mut has_next = false
  let mut has_format = false
  let mut has_ignore_file = false
  let mut has_policy_file = false
  let mut has_policy_version = false
  let mut i = start
  while i < args.length() {
    let option = args[i]
    if option == "--current" {
      if i + 1 >= args.length() {
        return Err("error: --current requires a major.minor.patch version")
      }
      current = args[i + 1]
      has_current = true
      i += 2
    } else if option == "--next" {
      if i + 1 >= args.length() {
        return Err("error: --next requires a major.minor.patch version")
      }
      next = args[i + 1]
      has_next = true
      if !has_policy_version {
        policy_version = next
      }
      i += 2
    } else if option == "--format" {
      if i + 1 >= args.length() {
        return Err("error: --format requires markdown or json")
      }
      match normalize_format(args[i + 1]) {
        None => return Err("error: unsupported report format '\{args[i + 1]}'")
        Some(value) => {
          format = value
          has_format = true
        }
      }
      i += 2
    } else if option == "--ignore-file" {
      if i + 1 >= args.length() {
        return Err("error: --ignore-file requires a path")
      }
      ignore_file = args[i + 1]
      has_ignore_file = true
      i += 2
    } else if option == "--policy-file" {
      if i + 1 >= args.length() {
        return Err("error: --policy-file requires a path")
      }
      policy_file = args[i + 1]
      has_policy_file = true
      i += 2
    } else if option == "--policy-version" {
      if i + 1 >= args.length() {
        return Err(
          "error: --policy-version requires a major.minor.patch version",
        )
      }
      policy_version = args[i + 1]
      has_policy_version = true
      i += 2
    } else if option == "--config" {
      if i + 1 >= args.length() {
        return Err("error: --config requires a path")
      }
      config_file = args[i + 1]
      i += 2
    } else {
      return Err("error: unknown option '\{option}'")
    }
  }
  Ok({
    current,
    next,
    format,
    ignore_file,
    policy_file,
    policy_version,
    baseline,
    target,
    baseline_dir,
    target_dir,
    config_file,
    has_current,
    has_next,
    has_format,
    has_ignore_file,
    has_policy_file,
    has_policy_version,
  })
}

///|
fn normalize_format(value : String) -> String? {
  if value == "markdown" || value == "md" {
    Some("markdown")
  } else if value == "json" {
    Some("json")
  } else {
    None
  }
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
