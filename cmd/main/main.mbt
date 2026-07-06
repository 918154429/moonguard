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
  if cli_args.length() == 3 && cli_args[0] == "report-dir" {
    return report_dirs(cli_args[1], cli_args[2])
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
      arg == "report-dir" ||
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
fn report_dirs(old_dir : String, new_dir : String) -> String {
  let old_files = list_interface_files_raw(old_dir)
  if old_files.has_prefix(read_error_prefix) {
    let message = old_files[read_error_prefix.length():].to_owned()
    return "error: cannot list old interface directory '\{old_dir}': \{message}"
  }
  let new_files = list_interface_files_raw(new_dir)
  if new_files.has_prefix(read_error_prefix) {
    let message = new_files[read_error_prefix.length():].to_owned()
    return "error: cannot list new interface directory '\{new_dir}': \{message}"
  }
  let old_items = match
    read_dir_items(old_dir, parse_file_list(old_files[:]), "old") {
    Ok(items) => items
    Err(message) => return message
  }
  let new_items = match
    read_dir_items(new_dir, parse_file_list(new_files[:]), "new") {
    Ok(items) => items
    Err(message) => return message
  }
  @moonguard.render_markdown_report(@moonguard.diff_items(old_items, new_items))
}

///|
fn read_dir_items(
  root : String,
  files : Array[String],
  label : String,
) -> Result[Array[@moonguard.ApiItem], String] {
  let items : Array[@moonguard.ApiItem] = []
  for rel in files {
    let path = join_path(root, rel)
    let text = read_file_raw(path)
    if text.has_prefix(read_error_prefix) {
      let message = text[read_error_prefix.length():].to_owned()
      return Err(
        "error: cannot read \{label} interface file '\{rel}': \{message}",
      )
    }
    for item in prefixed_items(rel, text) {
      items.push(item)
    }
  }
  Ok(items)
}

///|
fn prefixed_items(
  relative_path : String,
  text : String,
) -> Array[@moonguard.ApiItem] {
  @moonguard.parse_interface_with_namespace(text, relative_path)
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
fn help_text() -> String {
  let help =
    #|moonguard 0.1.0
    #|
    #|Usage:
    #|  moon run --target js cmd/main -- report old.mbti new.mbti
    #|  moon run --target js cmd/main -- report-dir old_dir new_dir
    #|  moon run cmd/main -- report-text "pub fn old() -> Unit" "pub fn new() -> Unit"
    #|  moon run cmd/main -- --version
    #|  moon run cmd/main -- --help
    #|
    #|Compare two MoonBit interface snapshots and print a Markdown report.
  help
}
