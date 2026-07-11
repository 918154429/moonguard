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
          if options.policy_file.length() > 0 {
            policy_report_result(
              report,
              options.policy_file,
              options.policy_version,
              options.format,
            )
          } else {
            match apply_ignore_file(report, options.ignore_file) {
              Err(message) => error_result(message)
              Ok(filtered) => ok_result(render_report(filtered, options.format))
            }
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
                  if options.policy_file.length() > 0 {
                    policy_report_result(
                      report,
                      options.policy_file,
                      options.policy_version,
                      options.format,
                    )
                  } else {
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
                  if options.policy_file.length() > 0 {
                    policy_package_result(
                      package_report.report,
                      package_report.diagnostics,
                      options.policy_file,
                      options.policy_version,
                      options.format,
                    )
                  } else {
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
                  if options.policy_file.length() > 0 {
                    policy_check_result(
                      package_report.report,
                      package_report.diagnostics,
                      options.policy_file,
                      options.policy_version,
                      options.current,
                      options.next,
                      options.format,
                    )
                  } else {
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
                  if options.policy_file.length() > 0 {
                    policy_release_plan_result(
                      package_report.report,
                      package_report.diagnostics,
                      options.policy_file,
                      options.policy_version,
                      options.current,
                      options.next,
                      options.format,
                    )
                  } else {
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
              if options.policy_file.length() > 0 {
                return error_result(
                  "error: inventory-dir does not support --policy-file",
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
                  if options.policy_file.length() > 0 {
                    policy_check_result(
                      report,
                      [],
                      options.policy_file,
                      options.policy_version,
                      options.current,
                      options.next,
                      options.format,
                    )
                  } else {
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
}
