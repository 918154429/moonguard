///|
test "parse public functions and types" {
  let api = @moonguard.parse_interface(
    (
      #|// Generated using moon info
      #|package "ccfoss/demo"
      #|
      #|pub fn render(String) -> String
      #|pub struct Options {
      #|priv fn helper() -> Unit
      #|pub enum Level
      #|pub typealias Name = String
    ),
  )
  inspect(api.length(), content="4")
  inspect(api[0].kind, content="enum")
  inspect(api[0].name, content="Level")
  inspect(api[1].kind, content="fn")
  inspect(api[1].signature, content="render(String) -> String")
  inspect(api[2].kind, content="struct")
  inspect(api[2].name, content="Options")
  inspect(api[3].kind, content="typealias")
  inspect(api[3].signature, content="Name = String")
}

///|
test "normalize whitespace and ignore comments" {
  let api = @moonguard.parse_interface(
    (
      #|pub   fn   parse( String )  ->  Unit  // trailing comment
      #|pub(all) trait   Show
    ),
  )
  inspect(api.length(), content="2")
  inspect(api[0].kind, content="fn")
  inspect(api[0].signature, content="parse( String ) -> Unit")
  inspect(api[1].kind, content="trait")
  inspect(api[1].signature, content="Show")
}

///|
test "detect added public api as minor" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub fn render(String) -> String
    ),
    (
      #|pub fn parse(String) -> Unit
      #|pub fn render(String) -> String
    ),
  )
  assert_true(report.recommendation == @moonguard.Minor)
  inspect(report.changes.length(), content="1")
  assert_true(report.changes[0].kind == @moonguard.Added)
  inspect(report.changes[0].name, content="parse")
}

///|
test "detect removed public api as major" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub fn parse(String) -> Unit
      #|pub fn render(String) -> String
    ),
    (
      #|pub fn render(String) -> String
    ),
  )
  assert_true(report.recommendation == @moonguard.Major)
  assert_true(report.changes[0].kind == @moonguard.Removed)
  inspect(report.changes[0].name, content="parse")
}

///|
test "detect changed signature as major" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub fn render(String) -> String
    ),
    (
      #|pub fn render(String, Options) -> String
    ),
  )
  assert_true(report.recommendation == @moonguard.Major)
  assert_true(report.changes[0].kind == @moonguard.Changed)
  assert_true(
    report.changes[0].old_signature == Some("render(String) -> String"),
  )
  assert_true(
    report.changes[0].new_signature == Some("render(String, Options) -> String"),
  )
}

///|
test "unchanged api is patch" {
  inspect(
    @moonguard.semver_recommendation(
      (
        #|pub fn render(String) -> String
      ),
      (
        #|pub   fn   render(String)  ->  String
      ),
    ),
    content="patch",
  )
}

///|
test "render markdown report" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub fn render(String) -> String
    ),
    (
      #|pub fn parse(String) -> Unit
      #|pub fn render(String, Options) -> String
    ),
  )
  inspect(
    @moonguard.render_markdown_report(report),
    content=(
      #|# MoonGuard API Compatibility Report
      #|
      #|- Recommendation: **major**
      #|- Changes: 2
      #|
      #|| Impact | Change | Symbol | Details |
      #|| --- | --- | --- | --- |
      #|| major | changed | `fn render` | `render(String) -> String` -> `render(String, Options) -> String` |
      #|| minor | added | `fn parse` | `parse(String) -> Unit` |
      #|
    ),
  )
}
