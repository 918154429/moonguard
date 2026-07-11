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
fn help_text() -> String {
  let help =
    #|moonguard 0.1.0
    #|
    #|Usage:
    #|  moon run --target js cmd/main -- report old.mbti new.mbti [--format markdown|json] [--ignore-file path | --policy-file path] [--policy-version version] [--config path]
    #|  moon run --target js cmd/main -- report-dir old_dir new_dir [--format markdown|json] [--ignore-file path | --policy-file path] [--policy-version version] [--config path]
    #|  moon run --target js cmd/main -- inventory-dir dir [--format markdown|json] [--config path]
    #|  moon run --target js cmd/main -- check old.mbti new.mbti --current 0.1.0 --next 0.2.0 [--format markdown|json] [--ignore-file path | --policy-file path] [--policy-version version] [--config path]
    #|  moon run --target js cmd/main -- check-dir old_dir new_dir --current 0.1.0 --next 0.2.0 [--format markdown|json] [--ignore-file path | --policy-file path] [--policy-version version] [--config path]
    #|  moon run --target js cmd/main -- release-plan old_dir new_dir --current 0.1.0 --next 0.2.0 [--format markdown|json] [--ignore-file path | --policy-file path] [--policy-version version] [--config path]
    #|  moon run cmd/main -- report-text "pub fn old() -> Unit" "pub fn new() -> Unit" [--format markdown|json] [--ignore-file path | --policy-file path] [--policy-version version] [--config path]
    #|  moon run cmd/main -- --version
    #|  moon run cmd/main -- --help
    #|
    #|Compare MoonBit interface snapshots and print compatibility reports.
    #|The check command exits with 1 when the proposed SemVer bump is insufficient.
    #|The release-plan command renders a package maintainer checklist for release PRs.
    #|Config files can provide format, ignore_file, policy_file, policy_version, current, next, baseline, target, baseline_dir, and target_dir.
    #|Ignore files use rules such as `ignore fn debug_tmp`.
    #|Policy files use auditable rules such as `allow removed fn legacy_* max_matches 1 reason migration complete`.
  help
}
