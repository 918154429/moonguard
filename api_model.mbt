///|
pub(all) enum ChangeKind {
  Added
  Removed
  Changed
} derive(Eq, Debug)

///|
pub(all) enum Impact {
  Patch
  Minor
  Major
} derive(Eq, Debug)

///|
pub struct ApiItem {
  kind : String
  name : String
  signature : String
} derive(Eq, Debug)

///|
pub struct ApiChange {
  kind : ChangeKind
  impact : Impact
  item_kind : String
  name : String
  old_signature : String?
  new_signature : String?
} derive(Eq, Debug)

///|
pub struct ApiReport {
  changes : Array[ApiChange]
  recommendation : Impact
} derive(Eq, Debug)

///|
pub struct Version {
  major : Int
  minor : Int
  patch : Int
} derive(Eq, Debug)

///|
pub struct VersionCheck {
  ok : Bool
  required : Impact
  current : String
  next : String
  reason : String
} derive(Eq, Debug)

///|
pub struct ApiIgnoreRule {
  item_kind : String
  name : String
  reason : String
} derive(Eq, Debug)

///|
pub struct IgnoreParseResult {
  rules : Array[ApiIgnoreRule]
  errors : Array[String]
} derive(Eq, Debug)

///|
pub struct ApiFile {
  path : String
  text : String
} derive(Eq, Debug)

///|
pub struct ApiDiagnostic {
  severity : String
  code : String
  path : String
  message : String
} derive(Eq, Debug)

///|
pub struct ApiSnapshot {
  items : Array[ApiItem]
  diagnostics : Array[ApiDiagnostic]
} derive(Eq, Debug)

///|
priv struct LocatedApiItem {
  item : ApiItem
  path : String
}

///|
pub struct ApiSummary {
  total : Int
  major : Int
  minor : Int
  patch : Int
  added : Int
  removed : Int
  changed : Int
} derive(Eq, Debug)

///|
pub struct DiagnosticSummary {
  total : Int
  errors : Int
  warnings : Int
  infos : Int
} derive(Eq, Debug)

///|
pub struct ApiKindCount {
  kind : String
  count : Int
} derive(Eq, Debug)

///|
pub struct ApiPackageComparison {
  old_snapshot : ApiSnapshot
  new_snapshot : ApiSnapshot
  report : ApiReport
  diagnostics : Array[ApiDiagnostic]
  summary : ApiSummary
  diagnostic_summary : DiagnosticSummary
} derive(Eq, Debug)

///|
pub struct ReleasePlan {
  report : ApiReport
  diagnostics : Array[ApiDiagnostic]
  version_check : VersionCheck
  summary : ApiSummary
  diagnostic_summary : DiagnosticSummary
  status : String
  decision : String
  next_action : String
} derive(Eq, Debug)
