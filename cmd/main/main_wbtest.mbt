///|
test "report-text unchanged api recommends patch" {
  inspect(
    run_args([
      "moonguard", "report-text", "pub fn render(String) -> String", "pub fn render(String) -> String",
    ]),
    content=(
      #|# MoonGuard API Compatibility Report
      #|
      #|- Recommendation: **patch**
      #|- Changes: 0
      #|
      #|No public API changes detected.
      #|
    ),
  )
}

///|
test "run_args ignores js process argv prefix" {
  inspect(
    run_args([
      "node", "_build/default/js/release/build/cmd/main/main.js", "report-text",
      "pub fn render(String) -> String", "pub fn render(String) -> String",
    ]),
    content=(
      #|# MoonGuard API Compatibility Report
      #|
      #|- Recommendation: **patch**
      #|- Changes: 0
      #|
      #|No public API changes detected.
      #|
    ),
  )
}

///|
test "report-text changed signature recommends major" {
  inspect(
    run_args([
      "moonguard", "report-text", "pub fn render(String) -> String", "pub fn render(String, Options) -> String",
    ]),
    content=(
      #|# MoonGuard API Compatibility Report
      #|
      #|- Recommendation: **major**
      #|- Changes: 1
      #|
      #|| Impact | Change | Symbol | Details |
      #|| --- | --- | --- | --- |
      #|| major | changed | `fn render` | `render(String) -> String` -> `render(String, Options) -> String` |
      #|
    ),
  )
}

///|
test "report-text supports json format" {
  inspect(
    run_args([
      "moonguard", "report-text", "pub fn render(String) -> String", "pub fn render(String) -> String",
      "--format", "json",
    ]),
    content=(
      #|{
      #|  "recommendation": "patch",
      #|  "change_count": 0,
      #|  "summary": {
      #|    "major": 0,
      #|    "minor": 0,
      #|    "patch": 0
      #|  },
      #|  "changes": []
      #|}
      #|
    ),
  )
}

///|
test "report-text rejects unknown format" {
  let result = run_args_result([
    "moonguard", "report-text", "pub fn a() -> Unit", "pub fn a() -> Unit", "--format",
    "xml",
  ])
  inspect(result.output, content="error: unsupported report format 'xml'")
  inspect(result.exit_code, content="2")
}

///|
test "report-text validates ignore-file option" {
  let result = run_args_result([
    "moonguard", "report-text", "pub fn a() -> Unit", "pub fn a() -> Unit", "--ignore-file",
  ])
  inspect(result.output, content="error: --ignore-file requires a path")
  inspect(result.exit_code, content="2")
}

///|
test "report-text reports non-js ignore-file read error" {
  let result = run_args_result([
    "moonguard", "report-text", "pub fn a() -> Unit", "pub fn b() -> Unit", "--ignore-file",
    "rules.txt",
  ])
  inspect(
    result.output,
    content="error: cannot read ignore file 'rules.txt': file input currently requires the JS backend; run with `moon run --target js cmd/main -- report old.mbti new.mbti`",
  )
  inspect(result.exit_code, content="2")
}

///|
test "report-text reports non-js config read error" {
  let result = run_args_result([
    "moonguard", "report-text", "pub fn a() -> Unit", "pub fn b() -> Unit", "--config",
    "moonguard.conf",
  ])
  inspect(
    result.output,
    content="error: cannot read config file 'moonguard.conf': file input currently requires the JS backend; run with `moon run --target js cmd/main -- report old.mbti new.mbti`",
  )
  inspect(result.exit_code, content="2")
}

///|
test "render ignore errors includes all parser errors" {
  inspect(
    render_ignore_errors("rules.txt", [
      "line 1: expected 'ignore KIND NAME'", "line 2: ignore rule requires kind and name",
    ]),
    content=(
      #|error: invalid ignore file 'rules.txt'
      #|  line 1: expected 'ignore KIND NAME'
      #|  line 2: ignore rule requires kind and name
    ),
  )
}

///|
test "report-dir explains non-js backend requirement" {
  inspect(
    run_args(["moonguard", "report-dir", "old-dir", "new-dir"]),
    content="error: cannot list old interface directory 'old-dir': directory input currently requires the JS backend; run with `moon run --target js cmd/main -- report-dir old_dir new_dir`",
  )
}

///|
test "run_args ignores js process argv prefix for report-dir" {
  inspect(
    run_args([
      "node", "_build/default/js/release/build/cmd/main/main.js", "report-dir", "old-dir",
      "new-dir",
    ]),
    content="error: cannot list old interface directory 'old-dir': directory input currently requires the JS backend; run with `moon run --target js cmd/main -- report-dir old_dir new_dir`",
  )
}

///|
test "check-dir requires versions before reading directories" {
  let result = run_args_result(["moonguard", "check-dir", "old-dir", "new-dir"])
  inspect(
    result.output,
    content="error: check requires --current major.minor.patch",
  )
  inspect(result.exit_code, content="2")
}

///|
test "check-dir explains non-js backend requirement" {
  let result = run_args_result([
    "moonguard", "check-dir", "old-dir", "new-dir", "--current", "1.0.0", "--next",
    "2.0.0",
  ])
  inspect(
    result.output,
    content="error: cannot list old interface directory 'old-dir': directory input currently requires the JS backend; run with `moon run --target js cmd/main -- report-dir old_dir new_dir`",
  )
  inspect(result.exit_code, content="2")
}

///|
test "run_args ignores js process argv prefix for check-dir" {
  inspect(
    run_args([
      "node", "_build/default/js/release/build/cmd/main/main.js", "check-dir", "old-dir",
      "new-dir", "--current", "1.0.0", "--next", "2.0.0",
    ]),
    content="error: cannot list old interface directory 'old-dir': directory input currently requires the JS backend; run with `moon run --target js cmd/main -- report-dir old_dir new_dir`",
  )
}

///|
test "read_dir_snapshot rejects directories without mbti files" {
  match read_dir_snapshot("empty-dir", [], "old") {
    Ok(_) => fail("expected empty directory error")
    Err(message) =>
      inspect(
        message,
        content="error: no .mbti files found in old interface directory 'empty-dir'",
      )
  }
}

///|
test "package result renders warning diagnostics without failing" {
  let report = @moonguard.diff_interfaces("", "")
  let snapshot = @moonguard.build_api_snapshot([
    @moonguard.api_file("empty.mbti", ""),
  ])
  let result = package_result(report, snapshot.diagnostics, "markdown")
  inspect(result.exit_code, content="0")
  assert_true(
    result.output.contains("# MoonGuard Package API Compatibility Report"),
  )
  assert_true(result.output.contains("empty-interface"))
}

///|
test "package result fails error diagnostics" {
  let report = @moonguard.diff_interfaces("", "")
  let snapshot = @moonguard.build_api_snapshot([
    @moonguard.api_file("", "pub fn render() -> Unit"),
  ])
  let result = package_result(report, snapshot.diagnostics, "json")
  inspect(result.exit_code, content="2")
  assert_true(result.output.contains("\"diagnostics\""))
  assert_true(result.output.contains("\"code\": \"empty-path\""))
}

///|
test "inventory command validates arguments" {
  let missing = run_args_result(["moonguard", "inventory-dir"])
  inspect(missing.output, content="error: inventory-dir requires DIR")
  inspect(missing.exit_code, content="2")
  let unsupported = run_args_result([
    "moonguard", "inventory-dir", "fixtures", "--ignore-file", "rules.txt",
  ])
  inspect(
    unsupported.output,
    content="error: inventory-dir does not support --ignore-file",
  )
  inspect(unsupported.exit_code, content="2")
}

///|
test "inventory result renders markdown and json" {
  let snapshot = @moonguard.build_api_snapshot([
    @moonguard.api_file("pkg.generated.mbti", "pub fn render(String) -> String"),
  ])
  let markdown = inventory_result(snapshot, "markdown")
  inspect(markdown.exit_code, content="0")
  assert_true(markdown.output.contains("# MoonGuard API Snapshot Inventory"))
  assert_true(markdown.output.contains("| fn | 1 |"))
  let json = inventory_result(snapshot, "json")
  inspect(json.exit_code, content="0")
  assert_true(json.output.contains("\"item_count\": 1"))
  assert_true(json.output.contains("\"kind_counts\""))
}

///|
test "inventory result fails duplicate diagnostics" {
  let snapshot = @moonguard.build_api_snapshot([
    @moonguard.api_file(
      "pkg.generated.mbti",
      (
        #|pub fn render(String) -> String
        #|pub fn render(String) -> String
      ),
    ),
  ])
  let result = inventory_result(snapshot, "markdown")
  inspect(result.exit_code, content="2")
  assert_true(result.output.contains("duplicate-symbol"))
  assert_true(result.output.contains("errors 1"))
}

///|
test "inventory command reports non-js list error" {
  let result = run_args_result(["moonguard", "inventory-dir", "fixtures"])
  inspect(
    result.output,
    content="error: cannot list interface directory 'fixtures': directory input currently requires the JS backend; run with `moon run --target js cmd/main -- report-dir old_dir new_dir`",
  )
  inspect(result.exit_code, content="2")
}

///|
test "package result json includes diagnostic summary" {
  let report = @moonguard.diff_interfaces("", "")
  let snapshot = @moonguard.build_api_snapshot([
    @moonguard.api_file("empty.mbti", ""),
  ])
  let result = package_result(report, snapshot.diagnostics, "json")
  inspect(result.exit_code, content="0")
  assert_true(result.output.contains("\"diagnostic_summary\""))
  assert_true(result.output.contains("\"warnings\": 1"))
  assert_true(result.output.contains("\"empty-interface\""))
}

///|
test "check package result fails insufficient directory bump" {
  let report = @moonguard.diff_interfaces(
    "pub fn render(String) -> String", "pub fn render(String, Options) -> String",
  )
  let result = check_package_result(report, [], "1.2.3", "1.3.0", "markdown")
  inspect(result.exit_code, content="1")
  assert_true(
    result.output.contains("# MoonGuard Package API Compatibility Report"),
  )
  assert_true(result.output.contains("## Version Check"))
  assert_true(result.output.contains("- Result: **fail**"))
}

///|
test "check package result passes sufficient directory bump" {
  let report = @moonguard.diff_interfaces(
    "pub fn render(String) -> String", "pub fn render(String, Options) -> String",
  )
  let result = check_package_result(report, [], "1.2.3", "2.0.0", "markdown")
  inspect(result.exit_code, content="0")
  assert_true(result.output.contains("- Result: **pass**"))
}

///|
test "check package result prefers diagnostic errors" {
  let report = @moonguard.diff_interfaces("", "")
  let snapshot = @moonguard.build_api_snapshot([
    @moonguard.api_file("", "pub fn broken() -> Unit"),
  ])
  let result = check_package_result(
    report,
    snapshot.diagnostics,
    "1.2.3",
    "1.2.4",
    "json",
  )
  inspect(result.exit_code, content="2")
  assert_true(result.output.contains("\"diagnostics\""))
  assert_true(result.output.contains("\"version_check\""))
  assert_true(result.output.contains("\"ok\": true"))
  assert_true(result.output.contains("\"empty-path\""))
}

///|
test "release-plan command validates paths and versions before directory reads" {
  let missing_paths = run_args_result([
    "moonguard", "release-plan", "--current", "1.2.3", "--next", "2.0.0",
  ])
  inspect(
    missing_paths.output,
    content="error: release-plan requires OLD_DIR and NEW_DIR",
  )
  inspect(missing_paths.exit_code, content="2")
  let missing_versions = run_args_result([
    "moonguard", "release-plan", "old-dir", "new-dir",
  ])
  inspect(
    missing_versions.output,
    content="error: check requires --current major.minor.patch",
  )
  inspect(missing_versions.exit_code, content="2")
}

///|
test "release-plan result succeeds for a sufficient version bump" {
  let report = @moonguard.diff_interfaces(
    "pub fn render(String) -> String", "pub fn render(String, Options) -> String",
  )
  let result = release_plan_result(report, [], "1.2.3", "2.0.0", "markdown")
  inspect(result.exit_code, content="0")
  assert_true(result.output.contains("# MoonGuard Release Plan"))
  assert_true(result.output.contains("- Status: **ready**"))
  assert_true(
    result.output.contains(
      "- [x] Proposed version satisfies MoonGuard's recommendation.",
    ),
  )
}

///|
test "release-plan result fails an insufficient version bump" {
  let report = @moonguard.diff_interfaces(
    "pub fn render(String) -> String", "pub fn render(String, Options) -> String",
  )
  let result = release_plan_result(report, [], "1.2.3", "1.3.0", "json")
  inspect(result.exit_code, content="1")
  assert_true(result.output.contains("\"status\": \"needs-version-bump\""))
  assert_true(result.output.contains("\"ok\": false"))
  assert_true(result.output.contains("\"required\": \"major\""))
}

///|
test "release-plan result blocks publishing on diagnostic errors" {
  let report = @moonguard.diff_interfaces("", "")
  let snapshot = @moonguard.build_api_snapshot([
    @moonguard.api_file("", "pub fn broken() -> Unit"),
  ])
  let result = release_plan_result(
    report,
    snapshot.diagnostics,
    "1.2.3",
    "1.2.4",
    "markdown",
  )
  inspect(result.exit_code, content="2")
  assert_true(result.output.contains("- Status: **blocked**"))
  assert_true(result.output.contains("empty-path"))
  assert_true(result.output.contains("Fix diagnostic errors"))
}

///|
test "parse cli config supports common keys" {
  match
    parse_cli_config(
      "moonguard.conf",
      (
        #|# shared CI defaults
        #|format = json
        #|ignore_file = fixtures/ignore-render.rules
        #|current = 0.1.0
        #|next = 1.0.0
        #|baseline = fixtures/old.mbti
        #|target = fixtures/new.mbti
        #|baseline_dir = fixtures/dir-old
        #|target_dir = fixtures/dir-new
      ),
    ) {
    Err(message) => fail(message)
    Ok(config) => {
      inspect(config.format, content="json")
      inspect(config.ignore_file, content="fixtures/ignore-render.rules")
      inspect(config.current, content="0.1.0")
      inspect(config.next, content="1.0.0")
      inspect(config.baseline, content="fixtures/old.mbti")
      inspect(config.target, content="fixtures/new.mbti")
      inspect(config.baseline_dir, content="fixtures/dir-old")
      inspect(config.target_dir, content="fixtures/dir-new")
    }
  }
}

///|
test "parse cli config reports invalid lines" {
  match
    parse_cli_config(
      "bad.conf",
      (
        #|format = xml
        #|ignore_file =
        #|bad line
        #|unknown = value
      ),
    ) {
    Ok(_) => fail("expected invalid config")
    Err(message) => {
      assert_true(message.contains("error: invalid config file 'bad.conf'"))
      assert_true(message.contains("line 1: unsupported report format 'xml'"))
      assert_true(
        message.contains(
          "line 2: config value for 'ignore_file' must not be empty",
        ),
      )
      assert_true(message.contains("line 3: expected KEY = VALUE"))
      assert_true(message.contains("line 4: unknown config key 'unknown'"))
    }
  }
}

///|
test "config defaults merge with report options" {
  let config = {
    format: "json",
    ignore_file: "config.rules",
    current: "0.1.0",
    next: "1.0.0",
    baseline: "config-old.mbti",
    target: "config-new.mbti",
    baseline_dir: "config-old-dir",
    target_dir: "config-new-dir",
  }
  match
    parse_report_options(
      ["report", "old.mbti", "new.mbti", "--config", "moonguard.conf"][:],
      3,
    ) {
    Err(message) => fail(message)
    Ok(options) => {
      let merged = merge_report_options(options, config)
      inspect(merged.format, content="json")
      inspect(merged.ignore_file, content="config.rules")
      inspect(merged.baseline, content="config-old.mbti")
      inspect(merged.target, content="config-new.mbti")
      inspect(merged.baseline_dir, content="config-old-dir")
      inspect(merged.target_dir, content="config-new-dir")
      inspect(merged.config_file, content="moonguard.conf")
    }
  }
}

///|
test "config path defaults merge without positional report paths" {
  let config = {
    format: "json",
    ignore_file: "",
    current: "",
    next: "",
    baseline: "config-old.mbti",
    target: "config-new.mbti",
    baseline_dir: "config-old-dir",
    target_dir: "config-new-dir",
  }
  match parse_report_options(["report", "--config", "moonguard.conf"][:], 1) {
    Err(message) => fail(message)
    Ok(options) => {
      let merged = merge_report_options(options, config)
      inspect(merged.baseline, content="config-old.mbti")
      inspect(merged.target, content="config-new.mbti")
      inspect(merged.baseline_dir, content="config-old-dir")
      inspect(merged.target_dir, content="config-new-dir")
      inspect(
        choose_configured_path("", merged.baseline),
        content="config-old.mbti",
      )
      inspect(
        choose_configured_path("", merged.target_dir),
        content="config-new-dir",
      )
    }
  }
}

///|
test "command line report options override config defaults" {
  let config = {
    format: "json",
    ignore_file: "config.rules",
    current: "0.1.0",
    next: "1.0.0",
    baseline: "config-old.mbti",
    target: "config-new.mbti",
    baseline_dir: "config-old-dir",
    target_dir: "config-new-dir",
  }
  match
    parse_report_options(
      [
        "report", "old.mbti", "new.mbti", "--config", "moonguard.conf", "--format",
        "markdown", "--ignore-file", "cli.rules",
      ][:],
      3,
    ) {
    Err(message) => fail(message)
    Ok(options) => {
      let merged = merge_report_options(options, config)
      inspect(merged.format, content="markdown")
      inspect(merged.ignore_file, content="cli.rules")
    }
  }
}

///|
test "config supplies check versions" {
  let config = {
    format: "json",
    ignore_file: "",
    current: "0.1.0",
    next: "1.0.0",
    baseline: "config-old.mbti",
    target: "config-new.mbti",
    baseline_dir: "config-old-dir",
    target_dir: "config-new-dir",
  }
  match
    parse_check_options(
      ["check", "old.mbti", "new.mbti", "--config", "moonguard.conf"][:],
      3,
    ) {
    Err(message) => fail(message)
    Ok(options) => {
      let merged = merge_check_options(options, config)
      inspect(merged.current, content="0.1.0")
      inspect(merged.next, content="1.0.0")
      inspect(merged.format, content="json")
      inspect(merged.baseline, content="config-old.mbti")
      inspect(merged.target, content="config-new.mbti")
    }
  }
}

///|
test "config path defaults merge without positional check paths" {
  let config = {
    format: "json",
    ignore_file: "",
    current: "0.1.0",
    next: "1.0.0",
    baseline: "config-old.mbti",
    target: "config-new.mbti",
    baseline_dir: "config-old-dir",
    target_dir: "config-new-dir",
  }
  match parse_check_options(["check", "--config", "moonguard.conf"][:], 1) {
    Err(message) => fail(message)
    Ok(options) => {
      let merged = merge_check_options(options, config)
      inspect(merged.current, content="0.1.0")
      inspect(merged.next, content="1.0.0")
      inspect(merged.baseline, content="config-old.mbti")
      inspect(merged.target, content="config-new.mbti")
      inspect(merged.baseline_dir, content="config-old-dir")
      inspect(merged.target_dir, content="config-new-dir")
    }
  }
}

///|
test "command line check versions override config defaults" {
  let config = {
    format: "json",
    ignore_file: "",
    current: "0.1.0",
    next: "1.0.0",
    baseline: "config-old.mbti",
    target: "config-new.mbti",
    baseline_dir: "config-old-dir",
    target_dir: "config-new-dir",
  }
  match
    parse_check_options(
      [
        "check", "old.mbti", "new.mbti", "--config", "moonguard.conf", "--current",
        "2.0.0", "--next", "3.0.0", "--format", "markdown",
      ][:],
      3,
    ) {
    Err(message) => fail(message)
    Ok(options) => {
      let merged = merge_check_options(options, config)
      inspect(merged.current, content="2.0.0")
      inspect(merged.next, content="3.0.0")
      inspect(merged.format, content="markdown")
    }
  }
}

///|
test "optional path parsers allow config only commands" {
  match
    parse_optional_path_pair(
      ["report", "--config", "moonguard.conf"][:],
      "report requires OLD_MBTI and NEW_MBTI",
    ) {
    Err(message) => fail(message)
    Ok((old_path, new_path, option_start)) => {
      inspect(old_path, content="")
      inspect(new_path, content="")
      inspect(option_start, content="1")
    }
  }
  match
    parse_optional_path_pair(
      ["report", "old.mbti"][:],
      "report requires OLD_MBTI and NEW_MBTI",
    ) {
    Ok(_) => fail("expected partial path pair error")
    Err(message) =>
      inspect(message, content="error: report requires OLD_MBTI and NEW_MBTI")
  }
  match
    parse_optional_path(
      ["inventory-dir", "--config", "moonguard.conf"][:],
      "inventory-dir requires DIR",
    ) {
    Err(message) => fail(message)
    Ok((path, option_start)) => {
      inspect(path, content="")
      inspect(option_start, content="1")
    }
  }
  match
    parse_optional_path(
      ["inventory-dir", "one", "two"][:],
      "inventory-dir requires DIR",
    ) {
    Ok(_) => fail("expected extra path error")
    Err(message) =>
      inspect(message, content="error: inventory-dir requires DIR")
  }
}

///|
test "config only commands reach config loading" {
  let report = run_args_result([
    "moonguard", "report", "--config", "moonguard.conf",
  ])
  inspect(
    report.output,
    content="error: cannot read config file 'moonguard.conf': file input currently requires the JS backend; run with `moon run --target js cmd/main -- report old.mbti new.mbti`",
  )
  inspect(report.exit_code, content="2")
  let check = run_args_result([
    "moonguard", "check", "--config", "moonguard.conf",
  ])
  inspect(
    check.output,
    content="error: cannot read config file 'moonguard.conf': file input currently requires the JS backend; run with `moon run --target js cmd/main -- report old.mbti new.mbti`",
  )
  inspect(check.exit_code, content="2")
  let inventory = run_args_result([
    "moonguard", "inventory-dir", "--config", "moonguard.conf",
  ])
  inspect(
    inventory.output,
    content="error: cannot read config file 'moonguard.conf': file input currently requires the JS backend; run with `moon run --target js cmd/main -- report old.mbti new.mbti`",
  )
  inspect(inventory.exit_code, content="2")
}

///|
test "report options accept md alias and ignore file" {
  match
    parse_report_options(
      [
        "report", "old.mbti", "new.mbti", "--format", "md", "--ignore-file", "rules.txt",
      ][:],
      3,
    ) {
    Err(message) => fail(message)
    Ok(options) => {
      inspect(options.format, content="markdown")
      inspect(options.ignore_file, content="rules.txt")
    }
  }
}

///|
test "check options accept json and ignore file" {
  match
    parse_check_options(
      [
        "check", "old.mbti", "new.mbti", "--current", "1.2.3", "--next", "2.0.0",
        "--format", "json", "--ignore-file", "rules.txt",
      ][:],
      3,
    ) {
    Err(message) => fail(message)
    Ok(options) => {
      inspect(options.current, content="1.2.3")
      inspect(options.next, content="2.0.0")
      inspect(options.format, content="json")
      inspect(options.ignore_file, content="rules.txt")
    }
  }
}

///|
test "option parsers reject missing values and unknown options" {
  match
    parse_report_options(["report", "old.mbti", "new.mbti", "--format"][:], 3) {
    Ok(_) => fail("expected missing format value error")
    Err(message) =>
      inspect(message, content="error: --format requires markdown or json")
  }
  match
    parse_report_options(["report", "old.mbti", "new.mbti", "--config"][:], 3) {
    Ok(_) => fail("expected missing config value error")
    Err(message) => inspect(message, content="error: --config requires a path")
  }
  match
    parse_report_options(["report", "old.mbti", "new.mbti", "--bad"][:], 3) {
    Ok(_) => fail("expected unknown report option error")
    Err(message) => inspect(message, content="error: unknown option '--bad'")
  }
  match
    parse_check_options(
      ["check", "old.mbti", "new.mbti", "--current", "1.2.3", "--next"][:],
      3,
    ) {
    Ok(_) => fail("expected missing next value error")
    Err(message) =>
      inspect(
        message,
        content="error: --next requires a major.minor.patch version",
      )
  }
}

///|
test "check command requires versions before reading files" {
  let result = run_args_result(["moonguard", "check", "old.mbti", "new.mbti"])
  inspect(
    result.output,
    content="error: check requires --current major.minor.patch",
  )
  inspect(result.exit_code, content="2")
}

///|
test "check command reports non-js read errors with exit code two" {
  let result = run_args_result([
    "moonguard", "check", "old.mbti", "new.mbti", "--current", "1.0.0", "--next",
    "2.0.0",
  ])
  inspect(
    result.output,
    content="error: cannot read old interface file 'old.mbti': file input currently requires the JS backend; run with `moon run --target js cmd/main -- report old.mbti new.mbti`",
  )
  inspect(result.exit_code, content="2")
}

///|
test "check report result fails insufficient major bump" {
  let report = @moonguard.diff_interfaces(
    "pub fn render(String) -> String", "pub fn render(String, Options) -> String",
  )
  let result = check_report_result(report, "1.2.3", "1.3.0", "markdown")
  inspect(result.exit_code, content="1")
  assert_true(result.output.contains("## Version Check"))
  assert_true(result.output.contains("- Result: **fail**"))
  assert_true(
    result.output.contains(
      "major recommendation requires increasing major version",
    ),
  )
}

///|
test "check report result passes sufficient major bump" {
  let report = @moonguard.diff_interfaces(
    "pub fn render(String) -> String", "pub fn render(String, Options) -> String",
  )
  let result = check_report_result(report, "1.2.3", "2.0.0", "markdown")
  inspect(result.exit_code, content="0")
  assert_true(result.output.contains("- Result: **pass**"))
}

///|
test "check report result supports json output" {
  let report = @moonguard.diff_interfaces(
    "pub fn render(String) -> String", "pub fn parse(String) -> Unit\npub fn render(String) -> String",
  )
  let result = check_report_result(report, "1.2.3", "1.2.4", "json")
  inspect(result.exit_code, content="1")
  assert_true(result.output.contains("\"version_check\""))
  assert_true(result.output.contains("\"ok\": false"))
  assert_true(result.output.contains("\"required\": \"minor\""))
}

///|
test "help mentions file and text modes" {
  let help = run_args(["moonguard", "--help"])
  assert_true(help.contains("report old.mbti new.mbti"))
  assert_true(help.contains("report-dir old_dir new_dir"))
  assert_true(help.contains("inventory-dir dir"))
  assert_true(help.contains("check old.mbti new.mbti"))
  assert_true(help.contains("check-dir old_dir new_dir"))
  assert_true(help.contains("release-plan old_dir new_dir"))
  assert_true(help.contains("report-text"))
  assert_true(help.contains("--format markdown|json"))
  assert_true(help.contains("--ignore-file path"))
  assert_true(help.contains("--config path"))
}
