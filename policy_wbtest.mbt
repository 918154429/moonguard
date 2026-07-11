///|
test "evaluate policy defensively rejects directly constructed invalid rules" {
  let report = diff_interfaces("pub fn old() -> Unit\n", "")
  let evaluated = evaluate_policy(
    report,
    [
      {
        change_kind: "removed",
        item_kind: "fn",
        name: "old",
        until: "",
        max_matches: 1,
        reason: "",
        line: 1,
      },
    ],
    "",
  )
  inspect(evaluated.accepted_changes.length(), content="0")
  inspect(evaluated.effective_report.changes.length(), content="1")
  inspect(evaluated.diagnostics[0].code, content="policy-invalid-rule")
}
