///|
test "parse public functions and types" {
  let api = @moonguard.parse_interface(
    (
      #|// Generated using moon info
      #|package "ccfoss/demo"
      #|
      #|pub fn render(String) -> String
      #|pub struct Options {
      #|}
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
  inspect(api[1].signature, content="pub(all) Show")
}

///|
test "comment stripping preserves slashes inside strings" {
  let api = @moonguard.parse_interface(
    (
      #|pub const Docs : String = "https://moonbitlang.com/docs" // trailing comment
      #|pub const Escaped : String = "quote \"//\" stays"
    ),
  )
  inspect(api.length(), content="2")
  inspect(api[0].kind, content="const")
  inspect(
    api[0].signature,
    content="Docs : String = \"https://moonbitlang.com/docs\"",
  )
  inspect(api[1].kind, content="const")
  inspect(
    api[1].signature,
    content="Escaped : String = \"quote \\\"//\\\" stays\"",
  )
}

///|
test "normalization preserves whitespace inside strings" {
  let api = @moonguard.parse_interface(
    (
      #|pub   const   Message : String = "hello   moon"
      #|pub const Path : String = "C:\\tmp   dir"
    ),
  )
  inspect(api.length(), content="2")
  inspect(api[0].kind, content="const")
  inspect(api[0].signature, content="Message : String = \"hello   moon\"")
  inspect(api[1].kind, content="const")
  inspect(api[1].signature, content="Path : String = \"C:\\\\tmp   dir\"")
}

///|
test "string literal whitespace changes are signature changes" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub const Message : String = "hello  moon"
    ),
    (
      #|pub const Message : String = "hello moon"
    ),
  )
  assert_true(report.recommendation == @moonguard.Major)
  assert_true(report.changes[0].kind == @moonguard.Changed)
  inspect(report.changes[0].name, content="Message")
}

///|
test "visibility changes are signature changes" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub(open) trait Debug
    ),
    (
      #|pub trait Debug
    ),
  )
  assert_true(report.recommendation == @moonguard.Major)
  assert_true(report.changes[0].kind == @moonguard.Changed)
  inspect(report.changes[0].name, content="Debug")
  assert_true(report.changes[0].old_signature == Some("pub(open) Debug"))
  assert_true(report.changes[0].new_signature == Some("Debug"))
}

///|
test "attributes are part of public signatures" {
  let api = @moonguard.parse_interface(
    (
      #|#deprecated
      #|#alias(parse_string, deprecated)
      #|pub fn parse(String) -> Unit
    ),
  )
  inspect(api.length(), content="1")
  inspect(api[0].kind, content="fn")
  inspect(api[0].name, content="parse")
  inspect(
    api[0].signature,
    content="#deprecated #alias(parse_string, deprecated) parse(String) -> Unit",
  )
}

///|
test "attribute changes are major signature changes" {
  let report = @moonguard.diff_interfaces(
    (
      #|#deprecated
      #|pub fn parse(String) -> Unit
    ),
    (
      #|pub fn parse(String) -> Unit
    ),
  )
  assert_true(report.recommendation == @moonguard.Major)
  assert_true(report.changes[0].kind == @moonguard.Changed)
  inspect(report.changes[0].name, content="parse")
  assert_true(
    report.changes[0].old_signature == Some("#deprecated parse(String) -> Unit"),
  )
  assert_true(report.changes[0].new_signature == Some("parse(String) -> Unit"))
}

///|
test "attributes apply to trait methods" {
  let api = @moonguard.parse_interface(
    (
      #|pub(open) trait Debug {
      #|  #as_free_fn
      #|  fn to_repr(Self) -> Repr
      #|}
    ),
  )
  inspect(api.length(), content="2")
  inspect(api[0].kind, content="trait")
  inspect(api[0].signature, content="pub(open) Debug")
  inspect(api[1].kind, content="trait-method")
  inspect(api[1].name, content="Debug.to_repr")
  inspect(api[1].signature, content="#as_free_fn to_repr(Self) -> Repr")
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
test "detect top-level kind change as one major change" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub struct Options {
      #|}
    ),
    (
      #|pub enum Options {
      #|}
    ),
  )
  assert_true(report.recommendation == @moonguard.Major)
  inspect(report.changes.length(), content="1")
  assert_true(report.changes[0].kind == @moonguard.Changed)
  inspect(report.changes[0].item_kind, content="struct->enum")
  inspect(report.changes[0].name, content="Options")
  assert_true(report.changes[0].old_signature == Some("struct Options"))
  assert_true(report.changes[0].new_signature == Some("enum Options"))
}

///|
test "detect typealias to type as kind change" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub typealias Name = String
    ),
    (
      #|pub type Name
    ),
  )
  assert_true(report.recommendation == @moonguard.Major)
  inspect(report.changes.length(), content="1")
  assert_true(report.changes[0].kind == @moonguard.Changed)
  inspect(report.changes[0].item_kind, content="typealias->type")
  inspect(report.changes[0].name, content="Name")
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
test "parse strict semver versions" {
  match @moonguard.parse_version("1.2.3") {
    None => fail("expected version")
    Some(version) => {
      inspect(version.major, content="1")
      inspect(version.minor, content="2")
      inspect(version.patch, content="3")
      inspect(@moonguard.version_to_string(version), content="1.2.3")
    }
  }
  match @moonguard.parse_version(" 10.20.30 ") {
    None => fail("expected trimmed version")
    Some(version) =>
      inspect(@moonguard.version_to_string(version), content="10.20.30")
  }
}

///|
test "reject invalid semver versions" {
  assert_true(@moonguard.parse_version("") == None)
  assert_true(@moonguard.parse_version("1") == None)
  assert_true(@moonguard.parse_version("1.2") == None)
  assert_true(@moonguard.parse_version("1.2.3.4") == None)
  assert_true(@moonguard.parse_version("1.2.x") == None)
  assert_true(@moonguard.parse_version("01.2.3") == None)
  assert_true(@moonguard.parse_version("1.02.3") == None)
  assert_true(@moonguard.parse_version("1.2.03") == None)
  assert_true(@moonguard.parse_version("1.2.3-alpha") == None)
}

///|
test "compare parsed versions" {
  let one = parsed_version_for_test("1.2.3")
  let same = parsed_version_for_test("1.2.3")
  let patch = parsed_version_for_test("1.2.4")
  let minor = parsed_version_for_test("1.3.0")
  let major = parsed_version_for_test("2.0.0")
  inspect(@moonguard.compare_versions(one, same), content="0")
  inspect(@moonguard.compare_versions(one, patch), content="-1")
  inspect(@moonguard.compare_versions(patch, one), content="1")
  inspect(@moonguard.compare_versions(one, minor), content="-1")
  inspect(@moonguard.compare_versions(major, one), content="1")
}

///|
test "version check accepts patch bump for patch report" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub fn render(String) -> String
    ),
    (
      #|pub fn render(String) -> String
    ),
  )
  let check = @moonguard.check_version_bump(report, "1.2.3", "1.2.4")
  assert_true(check.ok)
  assert_true(check.required == @moonguard.Patch)
  inspect(
    check.reason,
    content="next version satisfies the patch recommendation",
  )
}

///|
test "version check rejects unchanged next version" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub fn render(String) -> String
    ),
    (
      #|pub fn render(String) -> String
    ),
  )
  let check = @moonguard.check_version_bump(report, "1.2.3", "1.2.3")
  assert_true(!check.ok)
  assert_true(check.required == @moonguard.Patch)
  inspect(
    check.reason,
    content="next version must be greater than current version",
  )
}

///|
test "version check accepts minor bump for added api" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub fn render(String) -> String
    ),
    (
      #|pub fn parse(String) -> Unit
      #|pub fn render(String) -> String
    ),
  )
  let check = @moonguard.check_version_bump(report, "1.2.3", "1.3.0")
  assert_true(check.ok)
  assert_true(check.required == @moonguard.Minor)
  inspect(check.current, content="1.2.3")
  inspect(check.next, content="1.3.0")
}

///|
test "version check rejects patch bump for added api" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub fn render(String) -> String
    ),
    (
      #|pub fn parse(String) -> Unit
      #|pub fn render(String) -> String
    ),
  )
  let check = @moonguard.check_version_bump(report, "1.2.3", "1.2.4")
  assert_true(!check.ok)
  assert_true(check.required == @moonguard.Minor)
  inspect(
    check.reason,
    content="minor recommendation requires increasing minor or major version",
  )
}

///|
test "version check accepts major bump for breaking api" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub fn render(String) -> String
    ),
    (
      #|pub fn render(String, Options) -> String
    ),
  )
  let check = @moonguard.check_version_bump(report, "1.2.3", "2.0.0")
  assert_true(check.ok)
  assert_true(check.required == @moonguard.Major)
}

///|
test "version check rejects minor bump for breaking api" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub fn render(String) -> String
    ),
    (
      #|pub fn render(String, Options) -> String
    ),
  )
  let check = @moonguard.check_version_bump(report, "1.2.3", "1.3.0")
  assert_true(!check.ok)
  assert_true(check.required == @moonguard.Major)
  inspect(
    check.reason,
    content="major recommendation requires increasing major version",
  )
}

///|
test "version check reports invalid current and next versions" {
  let report = @moonguard.diff_interfaces("", "")
  let bad_current = @moonguard.check_version_bump(report, "1.2", "1.2.3")
  assert_true(!bad_current.ok)
  inspect(
    bad_current.reason,
    content="current version must be a strict major.minor.patch value",
  )
  let bad_next = @moonguard.check_version_bump(report, "1.2.3", "next")
  assert_true(!bad_next.ok)
  inspect(
    bad_next.reason,
    content="next version must be a strict major.minor.patch value",
  )
}

///|
test "interface version check combines diff and semver" {
  let check = @moonguard.check_interface_version_bump(
    (
      #|pub struct Options {
      #|  mode : String
      #|}
    ),
    (
      #|pub struct Options {
      #|  mode : Int
      #|}
    ),
    "0.1.0",
    "0.2.0",
  )
  assert_true(!check.ok)
  assert_true(check.required == @moonguard.Major)
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

///|
test "render json report for unchanged api" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub fn render(String) -> String
    ),
    (
      #|pub fn render(String) -> String
    ),
  )
  inspect(
    @moonguard.render_json_report(report),
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
test "render json report includes changed and added fields" {
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
    @moonguard.render_json_report(report),
    content=(
      #|{
      #|  "recommendation": "major",
      #|  "change_count": 2,
      #|  "summary": {
      #|    "major": 1,
      #|    "minor": 1,
      #|    "patch": 0
      #|  },
      #|  "changes": [
      #|    {
      #|      "kind": "changed",
      #|      "impact": "major",
      #|      "item_kind": "fn",
      #|      "name": "render",
      #|      "old_signature": "render(String) -> String",
      #|      "new_signature": "render(String, Options) -> String"
      #|    },
      #|    {
      #|      "kind": "added",
      #|      "impact": "minor",
      #|      "item_kind": "fn",
      #|      "name": "parse",
      #|      "old_signature": null,
      #|      "new_signature": "parse(String) -> Unit"
      #|    }
      #|  ]
      #|}
      #|
    ),
  )
}

///|
test "render json report includes removed fields" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub fn parse(String) -> Unit
      #|pub fn render(String) -> String
    ),
    (
      #|pub fn render(String) -> String
    ),
  )
  inspect(
    @moonguard.render_json_report(report),
    content=(
      #|{
      #|  "recommendation": "major",
      #|  "change_count": 1,
      #|  "summary": {
      #|    "major": 1,
      #|    "minor": 0,
      #|    "patch": 0
      #|  },
      #|  "changes": [
      #|    {
      #|      "kind": "removed",
      #|      "impact": "major",
      #|      "item_kind": "fn",
      #|      "name": "parse",
      #|      "old_signature": "parse(String) -> Unit",
      #|      "new_signature": null
      #|    }
      #|  ]
      #|}
      #|
    ),
  )
}

///|
test "render json report escapes strings" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub const Message : String = "hello \"moon\""
    ),
    (
      #|pub const Message : String = "hello \\moon"
    ),
  )
  let json = @moonguard.render_json_report(report)
  assert_true(json.contains("\\\"hello \\\\\\\"moon\\\\\\\"\\\""))
  assert_true(json.contains("\\\"hello \\\\\\\\moon\\\""))
}

///|
test "render markdown version check" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub fn render(String) -> String
    ),
    (
      #|pub fn render(String, Options) -> String
    ),
  )
  let check = @moonguard.check_version_bump(report, "1.2.3", "1.3.0")
  inspect(
    @moonguard.render_version_check_markdown(check),
    content=(
      #|## Version Check
      #|
      #|- Required bump: **major**
      #|- Current version: `1.2.3`
      #|- Next version: `1.3.0`
      #|- Result: **fail**
      #|- Reason: major recommendation requires increasing major version
      #|
    ),
  )
}

///|
test "render json check result" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub fn render(String) -> String
    ),
    (
      #|pub fn parse(String) -> Unit
      #|pub fn render(String) -> String
    ),
  )
  let check = @moonguard.check_version_bump(report, "1.2.3", "1.2.4")
  inspect(
    @moonguard.render_json_check_result(report, check),
    content=(
      #|{
      #|  "report": {
      #|    "recommendation": "minor",
      #|    "change_count": 1,
      #|    "summary": {
      #|      "major": 0,
      #|      "minor": 1,
      #|      "patch": 0
      #|    },
      #|    "changes": [
      #|      {
      #|        "kind": "added",
      #|        "impact": "minor",
      #|        "item_kind": "fn",
      #|        "name": "parse",
      #|        "old_signature": null,
      #|        "new_signature": "parse(String) -> Unit"
      #|      }
      #|    ]
      #|  },
      #|  "version_check": {
      #|    "ok": false,
      #|    "required": "minor",
      #|    "current": "1.2.3",
      #|    "next": "1.2.4",
      #|    "reason": "minor recommendation requires increasing minor or major version"
      #|  }
      #|}
      #|
    ),
  )
}

///|
test "parse generic functions methods and impls" {
  let api = @moonguard.parse_interface(
    (
      #|pub fn[A, B] map(Array[A], (A) -> B) -> Array[B]
      #|pub fn[A] LazyList::map(Self[A], (A) -> B) -> LazyList[B]
      #|pub impl[A : Debug] Debug for LazyList[A]
    ),
  )
  inspect(api.length(), content="3")
  inspect(api[0].kind, content="fn")
  inspect(api[0].name, content="LazyList::map")
  inspect(api[1].kind, content="fn")
  inspect(api[1].name, content="map")
  inspect(api[2].kind, content="impl")
  inspect(api[2].name, content="Debug for LazyList[A]")
}

///|
test "async functions keep distinct signatures" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub fn load(String) -> Bytes
    ),
    (
      #|pub async fn load(String) -> Bytes
    ),
  )
  assert_true(report.recommendation == @moonguard.Major)
  assert_true(report.changes[0].kind == @moonguard.Changed)
  inspect(report.changes[0].name, content="load")
  assert_true(report.changes[0].old_signature == Some("load(String) -> Bytes"))
  assert_true(
    report.changes[0].new_signature == Some("async fn load(String) -> Bytes"),
  )
}

///|
test "parse interface with namespace prefixes names" {
  let api = @moonguard.parse_interface_with_namespace(
    (
      #|pub fn render(String) -> String
      #|pub struct Options {
      #|  mode : String
      #|} derive(Eq)
    ),
    "pkg/generated.mbti",
  )
  inspect(api.length(), content="4")
  inspect(api[0].kind, content="derive")
  inspect(api[0].name, content="pkg/generated.mbti::Options.Eq")
  inspect(api[1].kind, content="field")
  inspect(api[1].name, content="pkg/generated.mbti::Options.mode")
  inspect(api[2].kind, content="fn")
  inspect(api[2].name, content="pkg/generated.mbti::render")
  inspect(api[3].kind, content="struct")
  inspect(api[3].name, content="pkg/generated.mbti::Options")
}

///|
test "parse nested fields constructors and trait methods" {
  let api = @moonguard.parse_interface(
    (
      #|pub struct Options {
      #|  mode : String
      #|  retries : Int
      #|}
      #|pub enum Level {
      #|  Basic
      #|  Advanced(Int)
      #|}
      #|pub(open) trait Render {
      #|  fn render(Self, Options) -> String
      #|}
    ),
  )
  inspect(api.length(), content="8")
  inspect(api[0].kind, content="constructor")
  inspect(api[0].name, content="Level.Advanced")
  inspect(api[1].kind, content="constructor")
  inspect(api[1].name, content="Level.Basic")
  inspect(api[2].kind, content="enum")
  inspect(api[2].name, content="Level")
  inspect(api[3].kind, content="field")
  inspect(api[3].name, content="Options.mode")
  inspect(api[4].kind, content="field")
  inspect(api[4].name, content="Options.retries")
  inspect(api[5].kind, content="struct")
  inspect(api[5].name, content="Options")
  inspect(api[6].kind, content="trait")
  inspect(api[6].name, content="Render")
  inspect(api[7].kind, content="trait-method")
  inspect(api[7].name, content="Render.render")
}

///|
test "parse derive clauses as public api items" {
  let api = @moonguard.parse_interface(
    (
      #|pub struct Options {
      #|  mode : String
      #|} derive(Eq, @debug.Debug)
    ),
  )
  inspect(api.length(), content="4")
  inspect(api[0].kind, content="derive")
  inspect(api[0].name, content="Options.@debug.Debug")
  inspect(api[0].signature, content="derive(@debug.Debug)")
  inspect(api[1].kind, content="derive")
  inspect(api[1].name, content="Options.Eq")
  inspect(api[1].signature, content="derive(Eq)")
  inspect(api[2].kind, content="field")
  inspect(api[2].name, content="Options.mode")
  inspect(api[3].kind, content="struct")
  inspect(api[3].name, content="Options")
}

///|
test "parse abstract type declarations from generated interfaces" {
  let api = @moonguard.parse_interface(
    (
      #|#alias(T, deprecated)
      #|type HashMap[K, V] derive(Eq)
      #|type Repr
    ),
  )
  inspect(api.length(), content="3")
  inspect(api[0].kind, content="derive")
  inspect(api[0].name, content="HashMap.Eq")
  inspect(api[0].signature, content="derive(Eq)")
  inspect(api[1].kind, content="type")
  inspect(api[1].name, content="HashMap")
  inspect(api[1].signature, content="#alias(T, deprecated) HashMap[K, V]")
  inspect(api[2].kind, content="type")
  inspect(api[2].name, content="Repr")
  inspect(api[2].signature, content="Repr")
}

///|
test "public type inline derive is split from type signature" {
  let api = @moonguard.parse_interface(
    (
      #|pub type Name derive(Eq)
    ),
  )
  inspect(api.length(), content="2")
  inspect(api[0].kind, content="derive")
  inspect(api[0].name, content="Name.Eq")
  inspect(api[1].kind, content="type")
  inspect(api[1].name, content="Name")
  inspect(api[1].signature, content="Name")
}

///|
test "removed abstract type is a major api change" {
  let report = @moonguard.diff_interfaces(
    (
      #|type Repr
    ),
    "",
  )
  assert_true(report.recommendation == @moonguard.Major)
  inspect(report.changes.length(), content="1")
  assert_true(report.changes[0].kind == @moonguard.Removed)
  inspect(report.changes[0].item_kind, content="type")
  inspect(report.changes[0].name, content="Repr")
}

///|
test "removed derive is a major api change" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub enum Level {
      #|  Basic
      #|} derive(Eq, @debug.Debug)
    ),
    (
      #|pub enum Level {
      #|  Basic
      #|} derive(Eq)
    ),
  )
  assert_true(report.recommendation == @moonguard.Major)
  inspect(report.changes.length(), content="1")
  assert_true(report.changes[0].kind == @moonguard.Removed)
  inspect(report.changes[0].item_kind, content="derive")
  inspect(report.changes[0].name, content="Level.@debug.Debug")
}

///|
test "added derive remains a minor api change" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub enum Level {
      #|  Basic
      #|}
    ),
    (
      #|pub enum Level {
      #|  Basic
      #|} derive(Eq)
    ),
  )
  assert_true(report.recommendation == @moonguard.Minor)
  inspect(report.changes.length(), content="1")
  assert_true(report.changes[0].kind == @moonguard.Added)
  inspect(report.changes[0].item_kind, content="derive")
  inspect(report.changes[0].name, content="Level.Eq")
}

///|
test "nested api changes feed existing semver rules" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub struct Options {
      #|  mode : String
      #|}
      #|pub enum Level {
      #|  Basic
      #|  Advanced(Int)
      #|}
      #|pub(open) trait Render {
      #|  fn render(Self, Options) -> String
      #|}
    ),
    (
      #|pub struct Options {
      #|  mode : Int
      #|}
      #|pub enum Level {
      #|  Basic
      #|}
      #|pub(open) trait Render {
      #|  fn render(Self) -> String
      #|}
    ),
  )
  assert_true(report.recommendation == @moonguard.Major)
  inspect(report.changes.length(), content="3")
  assert_true(report.changes[0].kind == @moonguard.Removed)
  inspect(report.changes[0].item_kind, content="constructor")
  inspect(report.changes[0].name, content="Level.Advanced")
  assert_true(report.changes[1].kind == @moonguard.Changed)
  inspect(report.changes[1].item_kind, content="field")
  inspect(report.changes[1].name, content="Options.mode")
  assert_true(report.changes[2].kind == @moonguard.Changed)
  inspect(report.changes[2].item_kind, content="trait-method")
  inspect(report.changes[2].name, content="Render.render")
}

///|
test "parse using and suberror declarations" {
  let api = @moonguard.parse_interface(
    (
      #|pub using @builtin {type ArrayView as View}
      #|pub using @builtin {type ArgsLoc}
      #|pub suberror Malformed {
      #|  Malformed(BytesView)
      #|}
    ),
  )
  inspect(api.length(), content="4")
  inspect(api[0].kind, content="constructor")
  inspect(api[0].name, content="Malformed.Malformed")
  inspect(api[1].kind, content="suberror")
  inspect(api[1].name, content="Malformed")
  inspect(api[2].kind, content="using")
  inspect(api[2].name, content="ArgsLoc")
  inspect(api[3].kind, content="using")
  inspect(api[3].name, content="View")
}

///|
test "render markdown report includes nested symbols" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub struct Options {
      #|}
      #|pub enum Level {
      #|  Basic
      #|}
    ),
    (
      #|pub struct Options {
      #|  mode : String
      #|}
      #|pub enum Level {
      #|  Basic
      #|  Advanced
      #|}
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
      #|| major | added | `constructor Level.Advanced` | `Advanced` |
      #|| major | added | `field Options.mode` | `mode : String` |
      #|
    ),
  )
}

///|
test "added trait method is a major api change" {
  let report = @moonguard.diff_interfaces(
    (
      #|pub(open) trait Render {
      #|  fn render(Self) -> String
      #|}
    ),
    (
      #|pub(open) trait Render {
      #|  fn parse(Self, String) -> Unit
      #|  fn render(Self) -> String
      #|}
    ),
  )
  assert_true(report.recommendation == @moonguard.Major)
  inspect(report.changes.length(), content="1")
  assert_true(report.changes[0].kind == @moonguard.Added)
  inspect(report.changes[0].item_kind, content="trait-method")
  inspect(report.changes[0].name, content="Render.parse")
}

///|
fn parsed_version_for_test(text : String) -> @moonguard.Version raise {
  match @moonguard.parse_version(text) {
    Some(version) => version
    None => fail("expected valid version: \{text}")
  }
}
