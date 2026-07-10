///|
let read_error_prefix = "__MOONGUARD_READ_ERROR__:"

///|
struct CliResult {
  output : String
  exit_code : Int
} derive(Eq, Debug)

///|
struct CheckOptions {
  current : String
  next : String
  format : String
  ignore_file : String
  baseline : String
  target : String
  baseline_dir : String
  target_dir : String
  config_file : String
  has_current : Bool
  has_next : Bool
  has_format : Bool
  has_ignore_file : Bool
} derive(Eq, Debug)

///|
struct ReportOptions {
  format : String
  ignore_file : String
  baseline : String
  target : String
  baseline_dir : String
  target_dir : String
  config_file : String
  has_format : Bool
  has_ignore_file : Bool
} derive(Eq, Debug)

///|
struct CliConfig {
  format : String
  ignore_file : String
  current : String
  next : String
  baseline : String
  target : String
  baseline_dir : String
  target_dir : String
} derive(Eq, Debug)

///|
struct PackageReportResult {
  report : @moonguard.ApiReport
  diagnostics : Array[@moonguard.ApiDiagnostic]
} derive(Eq, Debug)

///|
/// Compare two interface snapshots from files or command-line text.
fn main {
  let result = run_args_result(@env.args())
  println(result.output)
  exit_process(result.exit_code)
}

///|
pub fn run_args(args : Array[String]) -> String {
  run_args_result(args).output
}

///|
fn run_args_result(args : Array[String]) -> CliResult {
  let cli_args = normalize_args(args)
  if cli_args.length() == 0 {
    return ok_result(help_text())
  }
  if cli_args.length() == 1 && (cli_args[0] == "--help" || cli_args[0] == "-h") {
    return ok_result(help_text())
  }
  if cli_args.length() == 1 &&
    (cli_args[0] == "--version" || cli_args[0] == "-V") {
    return ok_result("moonguard 0.1.0")
  }
  if cli_args[0] == "report-text" {
    report_text_command(cli_args)
  } else if cli_args[0] == "report" {
    report_files_command(cli_args)
  } else if cli_args[0] == "report-dir" {
    report_dirs_command(cli_args)
  } else if cli_args[0] == "check-dir" {
    check_dirs_command(cli_args)
  } else if cli_args[0] == "release-plan" {
    release_plan_command(cli_args)
  } else if cli_args[0] == "inventory-dir" {
    inventory_dir_command(cli_args)
  } else if cli_args[0] == "check" {
    check_files_command(cli_args)
  } else {
    error_result("error: unknown command '\{cli_args[0]}'\n\n\{help_text()}")
  }
}

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
fn report_text_command(args : ArrayView[String]) -> CliResult {
  if args.length() < 3 {
    return error_result("error: report-text requires OLD_TEXT and NEW_TEXT")
  }
  match parse_report_options(args, 3) {
    Err(message) => error_result(message)
    Ok(parsed_options) =>
      match resolve_report_options(parsed_options) {
        Err(message) => error_result(message)
        Ok(options) => {
          let report = @moonguard.diff_interfaces(args[1], args[2])
          match apply_ignore_file(report, options.ignore_file) {
            Err(message) => error_result(message)
            Ok(filtered) => ok_result(render_report(filtered, options.format))
          }
        }
      }
  }
}

///|
fn report_files_command(args : ArrayView[String]) -> CliResult {
  match
    parse_optional_path_pair(args, "report requires OLD_MBTI and NEW_MBTI") {
    Err(message) => error_result(message)
    Ok((old_arg, new_arg, option_start)) =>
      match parse_report_options(args, option_start) {
        Err(message) => error_result(message)
        Ok(parsed_options) =>
          match resolve_report_options(parsed_options) {
            Err(message) => error_result(message)
            Ok(options) => {
              let old_path = choose_configured_path(old_arg, options.baseline)
              let new_path = choose_configured_path(new_arg, options.target)
              if old_path.length() == 0 || new_path.length() == 0 {
                return error_result(
                  "error: report requires OLD_MBTI and NEW_MBTI",
                )
              }
              match diff_file_report(old_path, new_path) {
                Err(message) => error_result(message)
                Ok(report) =>
                  match apply_ignore_file(report, options.ignore_file) {
                    Err(message) => error_result(message)
                    Ok(filtered) =>
                      ok_result(render_report(filtered, options.format))
                  }
              }
            }
          }
      }
  }
}

///|
fn report_dirs_command(args : ArrayView[String]) -> CliResult {
  match
    parse_optional_path_pair(args, "report-dir requires OLD_DIR and NEW_DIR") {
    Err(message) => error_result(message)
    Ok((old_arg, new_arg, option_start)) =>
      match parse_report_options(args, option_start) {
        Err(message) => error_result(message)
        Ok(parsed_options) =>
          match resolve_report_options(parsed_options) {
            Err(message) => error_result(message)
            Ok(options) => {
              let old_dir = choose_configured_path(
                old_arg,
                options.baseline_dir,
              )
              let new_dir = choose_configured_path(new_arg, options.target_dir)
              if old_dir.length() == 0 || new_dir.length() == 0 {
                return error_result(
                  "error: report-dir requires OLD_DIR and NEW_DIR",
                )
              }
              match diff_dir_package_report(old_dir, new_dir) {
                Err(message) => error_result(message)
                Ok(package_report) =>
                  match
                    apply_ignore_file(
                      package_report.report,
                      options.ignore_file,
                    ) {
                    Err(message) => error_result(message)
                    Ok(filtered) =>
                      package_result(
                        filtered,
                        package_report.diagnostics,
                        options.format,
                      )
                  }
              }
            }
          }
      }
  }
}

///|
fn check_dirs_command(args : ArrayView[String]) -> CliResult {
  match
    parse_optional_path_pair(args, "check-dir requires OLD_DIR and NEW_DIR") {
    Err(message) => error_result(message)
    Ok((old_arg, new_arg, option_start)) =>
      match parse_check_options(args, option_start) {
        Err(message) => error_result(message)
        Ok(parsed_options) =>
          match resolve_check_options(parsed_options) {
            Err(message) => error_result(message)
            Ok(options) => {
              let old_dir = choose_configured_path(
                old_arg,
                options.baseline_dir,
              )
              let new_dir = choose_configured_path(new_arg, options.target_dir)
              if old_dir.length() == 0 || new_dir.length() == 0 {
                return error_result(
                  "error: check-dir requires OLD_DIR and NEW_DIR",
                )
              }
              match diff_dir_package_report(old_dir, new_dir) {
                Err(message) => error_result(message)
                Ok(package_report) =>
                  match
                    apply_ignore_file(
                      package_report.report,
                      options.ignore_file,
                    ) {
                    Err(message) => error_result(message)
                    Ok(filtered) =>
                      check_package_result(
                        filtered,
                        package_report.diagnostics,
                        options.current,
                        options.next,
                        options.format,
                      )
                  }
              }
            }
          }
      }
  }
}

///|
fn release_plan_command(args : ArrayView[String]) -> CliResult {
  match
    parse_optional_path_pair(args, "release-plan requires OLD_DIR and NEW_DIR") {
    Err(message) => error_result(message)
    Ok((old_arg, new_arg, option_start)) =>
      match parse_check_options(args, option_start) {
        Err(message) => error_result(message)
        Ok(parsed_options) =>
          match resolve_check_options(parsed_options) {
            Err(message) => error_result(message)
            Ok(options) => {
              let old_dir = choose_configured_path(
                old_arg,
                options.baseline_dir,
              )
              let new_dir = choose_configured_path(new_arg, options.target_dir)
              if old_dir.length() == 0 || new_dir.length() == 0 {
                return error_result(
                  "error: release-plan requires OLD_DIR and NEW_DIR",
                )
              }
              match diff_dir_package_report(old_dir, new_dir) {
                Err(message) => error_result(message)
                Ok(package_report) =>
                  match
                    apply_ignore_file(
                      package_report.report,
                      options.ignore_file,
                    ) {
                    Err(message) => error_result(message)
                    Ok(filtered) =>
                      release_plan_result(
                        filtered,
                        package_report.diagnostics,
                        options.current,
                        options.next,
                        options.format,
                      )
                  }
              }
            }
          }
      }
  }
}

///|
fn inventory_dir_command(args : ArrayView[String]) -> CliResult {
  match parse_optional_path(args, "inventory-dir requires DIR") {
    Err(message) => error_result(message)
    Ok((dir_arg, option_start)) =>
      match parse_report_options(args, option_start) {
        Err(message) => error_result(message)
        Ok(parsed_options) =>
          match resolve_report_options(parsed_options) {
            Err(message) => error_result(message)
            Ok(options) => {
              if options.ignore_file.length() > 0 {
                return error_result(
                  "error: inventory-dir does not support --ignore-file",
                )
              }
              let dir = choose_configured_path(dir_arg, options.target_dir)
              if dir.length() == 0 {
                return error_result("error: inventory-dir requires DIR")
              }
              let files = list_interface_files_raw(dir)
              if files.has_prefix(read_error_prefix) {
                let message = files[read_error_prefix.length():].to_owned()
                return error_result(
                  "error: cannot list interface directory '\{dir}': \{message}",
                )
              }
              match
                read_dir_snapshot(dir, parse_file_list(files[:]), "target") {
                Err(message) => error_result(message)
                Ok(snapshot) => inventory_result(snapshot, options.format)
              }
            }
          }
      }
  }
}

///|
fn check_package_result(
  report : @moonguard.ApiReport,
  diagnostics : Array[@moonguard.ApiDiagnostic],
  current : String,
  next : String,
  format : String,
) -> CliResult {
  let check = @moonguard.check_version_bump(report, current, next)
  let output = render_package_check_output(report, diagnostics, check, format)
  if @moonguard.diagnostics_have_errors(diagnostics) {
    { output, exit_code: 2 }
  } else if check.ok {
    { output, exit_code: 0 }
  } else {
    { output, exit_code: 1 }
  }
}

///|
fn check_files_command(args : ArrayView[String]) -> CliResult {
  match parse_optional_path_pair(args, "check requires OLD_MBTI and NEW_MBTI") {
    Err(message) => error_result(message)
    Ok((old_arg, new_arg, option_start)) =>
      match parse_check_options(args, option_start) {
        Err(message) => error_result(message)
        Ok(parsed_options) =>
          match resolve_check_options(parsed_options) {
            Err(message) => error_result(message)
            Ok(options) => {
              let old_path = choose_configured_path(old_arg, options.baseline)
              let new_path = choose_configured_path(new_arg, options.target)
              if old_path.length() == 0 || new_path.length() == 0 {
                return error_result(
                  "error: check requires OLD_MBTI and NEW_MBTI",
                )
              }
              match diff_file_report(old_path, new_path) {
                Err(message) => error_result(message)
                Ok(report) =>
                  match apply_ignore_file(report, options.ignore_file) {
                    Err(message) => error_result(message)
                    Ok(filtered) =>
                      check_report_result(
                        filtered,
                        options.current,
                        options.next,
                        options.format,
                      )
                  }
              }
            }
          }
      }
  }
}

///|
fn check_report_result(
  report : @moonguard.ApiReport,
  current : String,
  next : String,
  format : String,
) -> CliResult {
  let check = @moonguard.check_version_bump(report, current, next)
  let output = render_check_output(report, check, format)
  if check.ok {
    { output, exit_code: 0 }
  } else {
    { output, exit_code: 1 }
  }
}

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
fn package_result(
  report : @moonguard.ApiReport,
  diagnostics : Array[@moonguard.ApiDiagnostic],
  format : String,
) -> CliResult {
  let output = if format == "json" {
    @moonguard.render_json_package_report(report, diagnostics)
  } else {
    @moonguard.render_markdown_package_report(report, diagnostics)
  }
  if @moonguard.diagnostics_have_errors(diagnostics) {
    { output, exit_code: 2 }
  } else {
    { output, exit_code: 0 }
  }
}

///|
fn release_plan_result(
  report : @moonguard.ApiReport,
  diagnostics : Array[@moonguard.ApiDiagnostic],
  current : String,
  next : String,
  format : String,
) -> CliResult {
  let plan = @moonguard.make_release_plan(report, diagnostics, current, next)
  let output = if format == "json" {
    @moonguard.render_json_release_plan(plan)
  } else {
    @moonguard.render_markdown_release_plan(plan)
  }
  if @moonguard.diagnostics_have_errors(diagnostics) {
    { output, exit_code: 2 }
  } else if plan.version_check.ok {
    { output, exit_code: 0 }
  } else {
    { output, exit_code: 1 }
  }
}

///|
fn inventory_result(
  snapshot : @moonguard.ApiSnapshot,
  format : String,
) -> CliResult {
  let output = if format == "json" {
    @moonguard.render_json_snapshot_inventory(snapshot)
  } else {
    @moonguard.render_markdown_snapshot_inventory(snapshot)
  }
  if @moonguard.diagnostics_have_errors(snapshot.diagnostics) {
    { output, exit_code: 2 }
  } else {
    { output, exit_code: 0 }
  }
}

///|
fn render_ignore_errors(ignore_file : String, errors : Array[String]) -> String {
  let out = StringBuilder()
  out.write("error: invalid ignore file '")
  out.write(ignore_file)
  out.write("'")
  for error in errors {
    out.write("\n  ")
    out.write(error)
  }
  out.to_string()
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
fn resolve_report_options(
  options : ReportOptions,
) -> Result[ReportOptions, String] {
  if options.config_file.length() == 0 {
    return Ok(options)
  }
  match load_cli_config(options.config_file) {
    Err(message) => Err(message)
    Ok(config) => Ok(merge_report_options(options, config))
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
  {
    format,
    ignore_file,
    baseline: config.baseline,
    target: config.target,
    baseline_dir: config.baseline_dir,
    target_dir: config.target_dir,
    config_file: options.config_file,
    has_format: options.has_format || config.format.length() > 0,
    has_ignore_file: options.has_ignore_file || config.ignore_file.length() > 0,
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
      baseline: options.baseline,
      target: options.target,
      baseline_dir: options.baseline_dir,
      target_dir: options.target_dir,
      config_file: options.config_file,
      has_format: options.has_format,
      has_ignore_file: options.has_ignore_file,
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
  {
    current,
    next,
    format: report_options.format,
    ignore_file: report_options.ignore_file,
    baseline: report_options.baseline,
    target: report_options.target,
    baseline_dir: report_options.baseline_dir,
    target_dir: report_options.target_dir,
    config_file: options.config_file,
    has_current: options.has_current || config.current.length() > 0,
    has_next: options.has_next || config.next.length() > 0,
    has_format: report_options.has_format,
    has_ignore_file: report_options.has_ignore_file,
  }
}

///|
fn parse_cli_config(path : String, text : String) -> Result[CliConfig, String] {
  let errors : Array[String] = []
  let mut format = ""
  let mut ignore_file = ""
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

///|
fn parse_report_options(
  args : ArrayView[String],
  start : Int,
) -> Result[ReportOptions, String] {
  let mut format = "markdown"
  let mut ignore_file = ""
  let baseline = ""
  let target = ""
  let baseline_dir = ""
  let target_dir = ""
  let mut config_file = ""
  let mut has_format = false
  let mut has_ignore_file = false
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
    baseline,
    target,
    baseline_dir,
    target_dir,
    config_file,
    has_format,
    has_ignore_file,
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
  let baseline = ""
  let target = ""
  let baseline_dir = ""
  let target_dir = ""
  let mut config_file = ""
  let mut has_current = false
  let mut has_next = false
  let mut has_format = false
  let mut has_ignore_file = false
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
    baseline,
    target,
    baseline_dir,
    target_dir,
    config_file,
    has_current,
    has_next,
    has_format,
    has_ignore_file,
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
fn render_report(report : @moonguard.ApiReport, format : String) -> String {
  if format == "json" {
    @moonguard.render_json_report(report)
  } else {
    @moonguard.render_markdown_report(report)
  }
}

///|
fn render_package_check_output(
  report : @moonguard.ApiReport,
  diagnostics : Array[@moonguard.ApiDiagnostic],
  check : @moonguard.VersionCheck,
  format : String,
) -> String {
  if format == "json" {
    @moonguard.render_json_package_check_result(report, diagnostics, check)
  } else {
    @moonguard.render_markdown_package_check_result(report, diagnostics, check)
  }
}

///|
fn render_check_output(
  report : @moonguard.ApiReport,
  check : @moonguard.VersionCheck,
  format : String,
) -> String {
  if format == "json" {
    @moonguard.render_json_check_result(report, check)
  } else {
    let out = StringBuilder()
    out.write(@moonguard.render_markdown_report(report))
    out.write("\n")
    out.write(@moonguard.render_version_check_markdown(check))
    out.to_string()
  }
}

///|
fn join_path(root : String, relative_path : String) -> String {
  "\{root}/\{relative_path}"
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
fn ok_result(output : String) -> CliResult {
  { output, exit_code: 0 }
}

///|
fn error_result(output : String) -> CliResult {
  { output, exit_code: 2 }
}

///|
fn help_text() -> String {
  let help =
    #|moonguard 0.1.0
    #|
    #|Usage:
    #|  moon run --target js cmd/main -- report old.mbti new.mbti [--format markdown|json] [--ignore-file path] [--config path]
    #|  moon run --target js cmd/main -- report-dir old_dir new_dir [--format markdown|json] [--ignore-file path] [--config path]
    #|  moon run --target js cmd/main -- inventory-dir dir [--format markdown|json] [--config path]
    #|  moon run --target js cmd/main -- check old.mbti new.mbti --current 0.1.0 --next 0.2.0 [--format markdown|json] [--ignore-file path] [--config path]
    #|  moon run --target js cmd/main -- check-dir old_dir new_dir --current 0.1.0 --next 0.2.0 [--format markdown|json] [--ignore-file path] [--config path]
    #|  moon run --target js cmd/main -- release-plan old_dir new_dir --current 0.1.0 --next 0.2.0 [--format markdown|json] [--ignore-file path] [--config path]
    #|  moon run cmd/main -- report-text "pub fn old() -> Unit" "pub fn new() -> Unit" [--format markdown|json] [--ignore-file path] [--config path]
    #|  moon run cmd/main -- --version
    #|  moon run cmd/main -- --help
    #|
    #|Compare MoonBit interface snapshots and print compatibility reports.
    #|The check command exits with 1 when the proposed SemVer bump is insufficient.
    #|The release-plan command renders a package maintainer checklist for release PRs.
    #|Config files can provide format, ignore_file, current, next, baseline, target, baseline_dir, and target_dir.
    #|Ignore files use rules such as `ignore fn debug_tmp`.
  help
}
