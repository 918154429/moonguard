# MoonGuard Real API Evolution Evidence

This evidence set applies MoonGuard to its own public interface and to three
pinned API evolutions from public MoonBit repositories. It is intended to show
real release decisions rather than parser-only fixture coverage.

## Results

| Case | Old -> new | Result | Changes | Evidence |
| --- | --- | --- | ---: | --- |
| MoonGuard self-check | `v0.1.0` -> current `v0.2.0` candidate | `minor`, version check passes | 16 minor | [Markdown](generated/moonguard-v0.1.0-to-v0.2.0.md) / [JSON](generated/moonguard-v0.1.0-to-v0.2.0.json) |
| `moonbitlang/async` HTTP package | `b2169b7` -> `ff28856` | `minor` | 2 minor | [Markdown](generated/moonbitlang-async-http.md) / [JSON](generated/moonbitlang-async-http.json) |
| `moonbitlang/quickcheck` | `6d97a1c` -> `9648749` | `major` | 4 major, 1 minor | [Markdown](generated/moonbitlang-quickcheck.md) / [JSON](generated/moonbitlang-quickcheck.json) |
| `oboard/mocket` | `8f4a8e9` -> `544178c` | `major` | 30 major, 31 minor | [Markdown](generated/oboard-mocket.md) / [JSON](generated/oboard-mocket.json) |

The official async HTTP sample adds `ServerConnection::write` and
`ServerConnection::write_string`, so existing callers remain compatible and a
minor release is sufficient. The official QuickCheck sample removes four
`small_check*` functions and adds `run_testable_once`, correctly requiring a
major release. The Mocket sample expands the existing public `HttpMethod` enum
and adds related API, exercising MoonGuard's conservative exhaustive-match
rule on a larger community project.

## Self-Hosting Finding

The first self-check exposed a real semantic defect: members of an entirely new
public struct were reported independently as newly added fields, which elevated
an otherwise additive release from `minor` to `major`. MoonGuard now suppresses
redundant nested-member changes when their whole container is added or removed.
Adding a field, constructor, or required trait method to an existing container
remains conservatively `major`.

Two regression tests cover newly added and removed populated containers. After
the fix, MoonGuard reports 16 additive top-level policy APIs, recommends
`minor`, and accepts the proposed `0.1.0 -> 0.2.0` version change.

## Provenance And Reproduction

External snapshots are unmodified, pinned to full commit SHAs, protected by
SHA-256 checks, and documented in
[`fixtures/evolution/SOURCES.md`](../../fixtures/evolution/SOURCES.md). All
three external repositories are Apache-2.0 licensed.

From PowerShell, regenerate every snapshot and report with:

```powershell
& '.\scripts\generate-evolution-evidence.ps1'
```

The script uses IPv4, retries GitHub raw downloads, verifies every external
snapshot hash, extracts MoonGuard's old interface from the signed `v0.1.0` Git
tag, and emits both Markdown and JSON reports. The reports describe the pinned
commits only; they do not claim that those commits correspond to upstream
release tags.

GitHub Actions runs the same script with `-Offline`, regenerates reports from
the committed snapshots, and fails if the generated evidence differs from the
tracked artifacts.
