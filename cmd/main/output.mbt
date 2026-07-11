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
fn policy_report_result(
  report : @moonguard.ApiReport,
  policy_file : String,
  target_version : String,
  format : String,
) -> CliResult {
  match apply_policy_file(report, policy_file, target_version) {
    Err(message) => error_result(message)
    Ok(evaluation) => {
      let output = render_policy_evaluation(evaluation, format)
      if @moonguard.policy_diagnostics_have_errors(evaluation.diagnostics) {
        { output, exit_code: 2 }
      } else {
        { output, exit_code: 0 }
      }
    }
  }
}

///|
fn policy_package_result(
  report : @moonguard.ApiReport,
  diagnostics : Array[@moonguard.ApiDiagnostic],
  policy_file : String,
  target_version : String,
  format : String,
) -> CliResult {
  match apply_policy_file(report, policy_file, target_version) {
    Err(message) => error_result(message)
    Ok(evaluation) => {
      let output = render_policy_package_output(evaluation, diagnostics, format)
      if @moonguard.policy_diagnostics_have_errors(evaluation.diagnostics) ||
        @moonguard.diagnostics_have_errors(diagnostics) {
        { output, exit_code: 2 }
      } else {
        { output, exit_code: 0 }
      }
    }
  }
}

///|
fn policy_check_result(
  report : @moonguard.ApiReport,
  diagnostics : Array[@moonguard.ApiDiagnostic],
  policy_file : String,
  target_version : String,
  current : String,
  next : String,
  format : String,
) -> CliResult {
  match apply_policy_file(report, policy_file, target_version) {
    Err(message) => error_result(message)
    Ok(evaluation) => {
      let check = @moonguard.check_version_bump(
        evaluation.effective_report,
        current,
        next,
      )
      let output = render_policy_check_output(
        evaluation, diagnostics, check, format,
      )
      if @moonguard.policy_diagnostics_have_errors(evaluation.diagnostics) ||
        @moonguard.diagnostics_have_errors(diagnostics) {
        { output, exit_code: 2 }
      } else if check.ok {
        { output, exit_code: 0 }
      } else {
        { output, exit_code: 1 }
      }
    }
  }
}

///|
fn policy_release_plan_result(
  report : @moonguard.ApiReport,
  diagnostics : Array[@moonguard.ApiDiagnostic],
  policy_file : String,
  target_version : String,
  current : String,
  next : String,
  format : String,
) -> CliResult {
  match apply_policy_file(report, policy_file, target_version) {
    Err(message) => error_result(message)
    Ok(evaluation) => {
      let plan = @moonguard.make_policy_release_plan(
        evaluation, diagnostics, current, next,
      )
      let output = if format == "json" {
        @moonguard.render_json_policy_release_plan(plan)
      } else {
        @moonguard.render_markdown_policy_release_plan(plan)
      }
      if @moonguard.policy_diagnostics_have_errors(evaluation.diagnostics) ||
        @moonguard.diagnostics_have_errors(diagnostics) {
        { output, exit_code: 2 }
      } else if plan.plan.version_check.ok {
        { output, exit_code: 0 }
      } else {
        { output, exit_code: 1 }
      }
    }
  }
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
fn render_report(report : @moonguard.ApiReport, format : String) -> String {
  if format == "json" {
    @moonguard.render_json_report(report)
  } else {
    @moonguard.render_markdown_report(report)
  }
}

///|
fn render_policy_evaluation(
  evaluation : @moonguard.ApiPolicyEvaluation,
  format : String,
) -> String {
  if format == "json" {
    @moonguard.render_json_policy_evaluation(evaluation)
  } else {
    @moonguard.render_markdown_policy_evaluation(evaluation)
  }
}

///|
fn render_policy_package_output(
  evaluation : @moonguard.ApiPolicyEvaluation,
  diagnostics : Array[@moonguard.ApiDiagnostic],
  format : String,
) -> String {
  if format == "json" {
    combine_json_objects(
      "policy_evaluation",
      @moonguard.render_json_policy_evaluation(evaluation),
      "effective_package_report",
      @moonguard.render_json_package_report(
        evaluation.effective_report,
        diagnostics,
      ),
    )
  } else {
    let out = StringBuilder()
    out.write(@moonguard.render_markdown_policy_evaluation(evaluation))
    out.write("\n")
    out.write(
      @moonguard.render_markdown_package_report(
        evaluation.effective_report,
        diagnostics,
      ),
    )
    out.to_string()
  }
}

///|
fn render_policy_check_output(
  evaluation : @moonguard.ApiPolicyEvaluation,
  diagnostics : Array[@moonguard.ApiDiagnostic],
  check : @moonguard.VersionCheck,
  format : String,
) -> String {
  if format == "json" {
    combine_json_objects(
      "policy_evaluation",
      @moonguard.render_json_policy_evaluation(evaluation),
      "effective_check",
      @moonguard.render_json_package_check_result(
        evaluation.effective_report,
        diagnostics,
        check,
      ),
    )
  } else {
    let out = StringBuilder()
    out.write(@moonguard.render_markdown_policy_evaluation(evaluation))
    out.write("\n")
    out.write(
      @moonguard.render_markdown_package_check_result(
        evaluation.effective_report,
        diagnostics,
        check,
      ),
    )
    out.to_string()
  }
}

///|
fn combine_json_objects(
  first_key : String,
  first_json : String,
  second_key : String,
  second_json : String,
) -> String {
  let out = StringBuilder()
  out.write("{\n  \"")
  out.write(first_key)
  out.write("\": ")
  out.write(first_json.trim())
  out.write(",\n  \"")
  out.write(second_key)
  out.write("\": ")
  out.write(second_json.trim())
  out.write("\n}\n")
  out.to_string()
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
fn ok_result(output : String) -> CliResult {
  { output, exit_code: 0 }
}

///|
fn error_result(output : String) -> CliResult {
  { output, exit_code: 2 }
}
