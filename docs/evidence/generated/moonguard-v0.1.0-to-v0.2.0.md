# MoonGuard API Compatibility Report

- Recommendation: **minor**
- Changes: 16

| Impact | Change | Symbol | Details |
| --- | --- | --- | --- |
| minor | added | `fn evaluate_policy` | `evaluate_policy(ApiReport, Array[ApiPolicyRule], String) -> ApiPolicyEvaluation` |
| minor | added | `fn evaluate_policy_text` | `evaluate_policy_text(ApiReport, String, String) -> ApiPolicyEvaluation` |
| minor | added | `fn make_policy_release_plan` | `make_policy_release_plan(ApiPolicyEvaluation, Array[ApiDiagnostic], String, String) -> PolicyReleasePlan` |
| minor | added | `fn parse_policy_rules` | `parse_policy_rules(String) -> PolicyParseResult` |
| minor | added | `fn policy_diagnostics_have_errors` | `policy_diagnostics_have_errors(Array[ApiPolicyDiagnostic]) -> Bool` |
| minor | added | `fn render_json_policy_evaluation` | `render_json_policy_evaluation(ApiPolicyEvaluation) -> String` |
| minor | added | `fn render_json_policy_release_plan` | `render_json_policy_release_plan(PolicyReleasePlan) -> String` |
| minor | added | `fn render_markdown_policy_evaluation` | `render_markdown_policy_evaluation(ApiPolicyEvaluation) -> String` |
| minor | added | `fn render_markdown_policy_release_plan` | `render_markdown_policy_release_plan(PolicyReleasePlan) -> String` |
| minor | added | `struct AcceptedApiChange` | `AcceptedApiChange` |
| minor | added | `struct ApiPolicyDiagnostic` | `ApiPolicyDiagnostic` |
| minor | added | `struct ApiPolicyEvaluation` | `ApiPolicyEvaluation` |
| minor | added | `struct ApiPolicyRule` | `ApiPolicyRule` |
| minor | added | `struct PolicyParseResult` | `PolicyParseResult` |
| minor | added | `struct PolicyReleasePlan` | `PolicyReleasePlan` |
| minor | added | `struct PolicySummary` | `PolicySummary` |

## Version Check

- Required bump: **minor**
- Current version: `0.1.0`
- Next version: `0.2.0`
- Result: **pass**
- Reason: next version satisfies the minor recommendation
