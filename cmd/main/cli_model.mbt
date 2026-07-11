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
  policy_file : String
  policy_version : String
  baseline : String
  target : String
  baseline_dir : String
  target_dir : String
  config_file : String
  has_current : Bool
  has_next : Bool
  has_format : Bool
  has_ignore_file : Bool
  has_policy_file : Bool
  has_policy_version : Bool
} derive(Eq, Debug)

///|
struct ReportOptions {
  format : String
  ignore_file : String
  policy_file : String
  policy_version : String
  baseline : String
  target : String
  baseline_dir : String
  target_dir : String
  config_file : String
  has_format : Bool
  has_ignore_file : Bool
  has_policy_file : Bool
  has_policy_version : Bool
} derive(Eq, Debug)

///|
struct CliConfig {
  format : String
  ignore_file : String
  policy_file : String
  policy_version : String
  current : String
  next : String
  baseline : String
  target : String
  baseline_dir : String
  target_dir : String
} derive(Eq, Debug)

///|
struct PackageReportResult {
  report : @moonguard.ApiReport
  diagnostics : Array[@moonguard.ApiDiagnostic]
} derive(Eq, Debug)
