# MoonGuard v0.1.0

MoonGuard v0.1.0 is the first competition-ready release of the MoonBit public
API compatibility and SemVer guard.

## Highlights

- Parses common generated `.mbti` declarations and nested public members.
- Normalizes declaration order, whitespace, comments, and inline/block
  container formatting.
- Detects added, removed, changed, and kind-changed public API.
- Produces conservative `patch`, `minor`, or `major` recommendations.
- Checks proposed version bumps with CI-friendly exit codes.
- Supports single files, package directories, ignore rules, and shared config.
- Renders Markdown/JSON reports, inventories, package checks, and release plans.
- Excludes common build, fixture, vendor, coverage, and nested tool directories
  during repository-root scans.

## Validation

- 139 automated tests pass.
- Instrumented coverage is 1900/2183 lines (87.0%).
- 15 pinned real-world interface snapshots produce 6700 modeled API items.
- Fourteen modern-format samples are fully modeled with zero unknown items and
  zero diagnostics.
- GitHub Actions verifies formatting, compilation, tests, CLI smoke paths,
  directory hygiene, real fixtures, and direct Node exit statuses.

## Known Limitation

One historical `python.mbt` interface snapshot contains 119 associated
functions and implementations without a public visibility prefix. They are
reported by the corpus analyzer but are not yet part of the compatibility
model. Native file/directory input is also not implemented; those CLI modes use
the JavaScript target and Node runtime.

See the repository README, compatibility rules, real-world compatibility
matrix, and GitHub Actions integration guide for reproducible examples.
