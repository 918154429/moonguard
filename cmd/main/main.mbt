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
} derive(Eq, Debug)

///|
struct ReportOptions {
  format : String
  ignore_file : String
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
    Ok(options) => {
      let report = @moonguard.diff_interfaces(args[1], args[2])
      match apply_ignore_file(report, options.ignore_file) {
        Err(message) => error_result(message)
        Ok(filtered) => ok_result(render_report(filtered, options.format))
      }
    }
  }
}

///|
fn report_files_command(args : ArrayView[String]) -> CliResult {
  if args.length() < 3 {
    return error_result("error: report requires OLD_MBTI and NEW_MBTI")
  }
  match parse_report_options(args, 3) {
    Err(message) => error_result(message)
    Ok(format) =>
      match diff_file_report(args[1], args[2]) {
        Err(message) => error_result(message)
        Ok(report) =>
          match apply_ignore_file(report, format.ignore_file) {
            Err(message) => error_result(message)
            Ok(filtered) => ok_result(render_report(filtered, format.format))
          }
      }
  }
}

///|
fn report_dirs_command(args : ArrayView[String]) -> CliResult {
  if args.length() < 3 {
    return error_result("error: report-dir requires OLD_DIR and NEW_DIR")
  }
  match parse_report_options(args, 3) {
    Err(message) => error_result(message)
    Ok(format) =>
      match diff_dir_package_report(args[1], args[2]) {
        Err(message) => error_result(message)
        Ok(package_report) =>
          match apply_ignore_file(package_report.report, format.ignore_file) {
            Err(message) => error_result(message)
            Ok(filtered) =>
              package_result(
                filtered,
                package_report.diagnostics,
                format.format,
              )
          }
      }
  }
}

///|
fn check_dirs_command(args : ArrayView[String]) -> CliResult {
  if args.length() < 3 {
    return error_result("error: check-dir requires OLD_DIR and NEW_DIR")
  }
  match parse_check_options(args, 3) {
    Err(message) => error_result(message)
    Ok(options) =>
      match diff_dir_package_report(args[1], args[2]) {
        Err(message) => error_result(message)
        Ok(package_report) =>
          match apply_ignore_file(package_report.report, options.ignore_file) {
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

///|
fn inventory_dir_command(args : ArrayView[String]) -> CliResult {
  if args.length() < 2 {
    return error_result("error: inventory-dir requires DIR")
  }
  match parse_report_options(args, 2) {
    Err(message) => error_result(message)
    Ok(options) => {
      if options.ignore_file.length() > 0 {
        return error_result(
          "error: inventory-dir does not support --ignore-file",
        )
      }
      let files = list_interface_files_raw(args[1])
      if files.has_prefix(read_error_prefix) {
        let message = files[read_error_prefix.length():].to_owned()
        return error_result(
          "error: cannot list interface directory '\{args[1]}': \{message}",
        )
      }
      match read_dir_snapshot(args[1], parse_file_list(files[:]), "target") {
        Err(message) => error_result(message)
        Ok(snapshot) => inventory_result(snapshot, options.format)
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
  if args.length() < 3 {
    return error_result("error: check requires OLD_MBTI and NEW_MBTI")
  }
  match parse_check_options(args, 3) {
    Err(message) => error_result(message)
    Ok(options) =>
      match diff_file_report(args[1], args[2]) {
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
fn parse_report_options(
  args : ArrayView[String],
  start : Int,
) -> Result[ReportOptions, String] {
  let mut format = "markdown"
  let mut ignore_file = ""
  let mut i = start
  while i < args.length() {
    let option = args[i]
    if option == "--format" {
      if i + 1 >= args.length() {
        return Err("error: --format requires markdown or json")
      }
      match normalize_format(args[i + 1]) {
        None => return Err("error: unsupported report format '\{args[i + 1]}'")
        Some(value) => format = value
      }
      i += 2
    } else if option == "--ignore-file" {
      if i + 1 >= args.length() {
        return Err("error: --ignore-file requires a path")
      }
      ignore_file = args[i + 1]
      i += 2
    } else {
      return Err("error: unknown option '\{option}'")
    }
  }
  Ok({ format, ignore_file })
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
  let mut i = start
  while i < args.length() {
    let option = args[i]
    if option == "--current" {
      if i + 1 >= args.length() {
        return Err("error: --current requires a major.minor.patch version")
      }
      current = args[i + 1]
      i += 2
    } else if option == "--next" {
      if i + 1 >= args.length() {
        return Err("error: --next requires a major.minor.patch version")
      }
      next = args[i + 1]
      i += 2
    } else if option == "--format" {
      if i + 1 >= args.length() {
        return Err("error: --format requires markdown or json")
      }
      match normalize_format(args[i + 1]) {
        None => return Err("error: unsupported report format '\{args[i + 1]}'")
        Some(value) => format = value
      }
      i += 2
    } else if option == "--ignore-file" {
      if i + 1 >= args.length() {
        return Err("error: --ignore-file requires a path")
      }
      ignore_file = args[i + 1]
      i += 2
    } else {
      return Err("error: unknown option '\{option}'")
    }
  }
  if current.length() == 0 {
    Err("error: check requires --current major.minor.patch")
  } else if next.length() == 0 {
    Err("error: check requires --next major.minor.patch")
  } else {
    Ok({ current, next, format, ignore_file })
  }
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
    #|  moon run --target js cmd/main -- report old.mbti new.mbti [--format markdown|json] [--ignore-file path]
    #|  moon run --target js cmd/main -- report-dir old_dir new_dir [--format markdown|json] [--ignore-file path]
    #|  moon run --target js cmd/main -- inventory-dir dir [--format markdown|json]
    #|  moon run --target js cmd/main -- check old.mbti new.mbti --current 0.1.0 --next 0.2.0 [--format markdown|json] [--ignore-file path]
    #|  moon run --target js cmd/main -- check-dir old_dir new_dir --current 0.1.0 --next 0.2.0 [--format markdown|json] [--ignore-file path]
    #|  moon run cmd/main -- report-text "pub fn old() -> Unit" "pub fn new() -> Unit" [--format markdown|json] [--ignore-file path]
    #|  moon run cmd/main -- --version
    #|  moon run cmd/main -- --help
    #|
    #|Compare MoonBit interface snapshots and print compatibility reports.
    #|The check command exits with 1 when the proposed SemVer bump is insufficient.
    #|Ignore files use rules such as `ignore fn debug_tmp`.
  help
}
