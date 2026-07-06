///|
let read_error_prefix = "__MOONGUARD_READ_ERROR__:"

///|
/// Compare two interface snapshots from files or command-line text.
fn main {
  let args = @env.args()
  println(run_args(args))
}

///|
fn run_args(args : Array[String]) -> String {
  let cli_args = normalize_args(args)
  if cli_args.length() == 1 && (cli_args[0] == "--help" || cli_args[0] == "-h") {
    return help_text()
  }
  if cli_args.length() == 1 &&
    (cli_args[0] == "--version" || cli_args[0] == "-V") {
    return "moonguard 0.1.0"
  }
  if cli_args.length() == 3 && cli_args[0] == "report-text" {
    return report_text(cli_args[1], cli_args[2])
  }
  if cli_args.length() == 3 && cli_args[0] == "report" {
    return report_files(cli_args[1], cli_args[2])
  }
  help_text()
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
      arg == "report-text" ||
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
fn report_text(old_api : String, new_api : String) -> String {
  let report = @moonguard.diff_interfaces(old_api, new_api)
  @moonguard.render_markdown_report(report)
}

///|
fn report_files(old_path : String, new_path : String) -> String {
  let old_text = read_file_raw(old_path)
  if old_text.has_prefix(read_error_prefix) {
    let message = old_text[read_error_prefix.length():].to_owned()
    return "error: cannot read old interface file '\{old_path}': \{message}"
  }
  let new_text = read_file_raw(new_path)
  if new_text.has_prefix(read_error_prefix) {
    let message = new_text[read_error_prefix.length():].to_owned()
    return "error: cannot read new interface file '\{new_path}': \{message}"
  }
  report_text(old_text, new_text)
}

///|
fn help_text() -> String {
  let help =
    #|moonguard 0.1.0
    #|
    #|Usage:
    #|  moon run --target js cmd/main -- report old.mbti new.mbti
    #|  moon run cmd/main -- report-text "pub fn old() -> Unit" "pub fn new() -> Unit"
    #|  moon run cmd/main -- --version
    #|  moon run cmd/main -- --help
    #|
    #|Compare two MoonBit interface snapshots and print a Markdown report.
  help
}
