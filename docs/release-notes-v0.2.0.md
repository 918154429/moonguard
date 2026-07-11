# MoonGuard v0.2.0 Release Candidate

MoonGuard v0.2.0 is the package-publication candidate for the MoonBit public
API compatibility and SemVer guard.

## Highlights

- Splits the implementation into focused API model, parser, snapshot, diff,
  SemVer, policy, and report modules.
- Adds auditable compatibility policies with reasons, deadlines, match budgets,
  accepted-change records, and diagnostics.
- Adds policy-aware Markdown/JSON reports and release plans.
- Supports single interfaces and package directories, including stable package
  identity across file moves and duplicate-symbol diagnostics.
- Provides CI-oriented config files, version checks, release plans, inventories,
  and strict direct-Node exit statuses.
- Models historical generated interfaces through narrowly gated legacy
  inference instead of silently dropping public surface.

## Validation

- 164 default-target tests and 165 JS-target tests pass.
- Instrumented coverage is 2383/2808 lines (84.9%); core library coverage is
  1940/2125 lines (91.3%).
- 15 pinned real-world interface snapshots produce 6819 modeled API items.
- All 15 samples are fully modeled with zero unknown items and zero snapshot
  diagnostics.
- `moon package --list` succeeds and produces a publication archive.
- Self-hosted `v0.1.0 -> v0.2.0` analysis recommends minor and passes the
  proposed version check; three pinned external evolution reports cover minor
  additions and major removals/container expansion.

## Known Limitations

- Native file/directory input uses the JavaScript target and Node runtime.
- Parsing intentionally targets generated `.mbti` shapes rather than the full
  MoonBit source grammar.
- Historical visibility inference requires the recognized `moon info` generator
  header and package declaration.

## Publication Gate

The release remains a candidate until the publisher logs in to mooncakes,
confirms ownership of the `ccfoss` namespace, updates `moon.mod` to `0.2.0`,
runs `moon publish --dry-run`, and creates the matching `v0.2.0` Git tag on the
final release commit.
