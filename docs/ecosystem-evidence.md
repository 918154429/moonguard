# MoonGuard Ecosystem Evidence

This note records concrete ecosystem evidence collected on 2026-07-08 for
positioning MoonGuard as a MoonBit package infrastructure project.

## Registry Evidence

Mooncakes is the public package registry for MoonBit packages:

- Source: https://mooncakes.io
- Statistics API: https://mooncakes.io/api/v0/modules/statistics

Observed registry statistics:

| Metric | Value |
| --- | ---: |
| Downloads | 4,394,001 |
| Modules | 1,483 |
| Packages | 12,825 |
| Lines indexed | 46,033,997 |

The registry homepage also links to package documentation, recent updates, new
modules, popular modules, build queue, and registry statistics. This shows that
MoonBit already has a package distribution and documentation workflow where API
compatibility checks can fit naturally.

Representative recently updated or published packages observed through
`/api/v0/modules?recent=5&new=5&popular=5`:

| Package | Version | Repository | Why it matters |
| --- | --- | --- | --- |
| `python123/moondepsolve` | `0.3.1` | https://github.com/python123-ops/moondepsolve | SemVer and dependency resolution tooling; adjacent to MoonGuard's release-checking goal. |
| `Han-Wentao/moonbench` | `0.2.0` | https://github.com/Han-Wentao/moonbench | Benchmark/reporting tooling; evidence of ecosystem infrastructure projects. |
| `liuhuo23/clickhouse-driver` | `0.1.1` | https://github.com/liuhuo23/clickhouse-driver.git | Database driver; public APIs matter to downstream users. |
| `morning-start/mbtgraph` | `0.1.2` | https://github.com/morning-start/mbtgraph | Graph algorithm library; API changes affect users directly. |
| `moonbitlang/x` | `0.4.46` | https://github.com/moonbitlang/x | Official experimental packages with active API evolution. |
| `moonbitlang/async` | `0.20.1` | https://github.com/moonbitlang/async | Official async library; a high-value target for interface compatibility checking. |

## GitHub Ecosystem Evidence

GitHub Search and GitHub CLI were used to estimate available real-world
MoonBit material:

| Query | Observed count | Evidence |
| --- | ---: | --- |
| Repositories with topic `moonbit` | 219 | https://github.com/search?q=topic%3Amoonbit&type=repositories |
| Repositories whose primary language is MoonBit | 1,703 | https://github.com/search?q=language%3AMoonBit&type=repositories |
| Repositories mentioning MoonBit in name, description, or README | 2,266 | https://github.com/search?q=moonbit+in%3Aname%2Cdescription%2Creadme&type=repositories |
| `moonbit-community` repositories | 302 | https://github.com/search?q=org%3Amoonbit-community&type=repositories |
| `moonbit-community` repositories whose primary language is MoonBit | 245 | https://github.com/search?q=org%3Amoonbit-community+language%3AMoonBit&type=repositories |
| MoonBit-language repositories pushed since 2026-01-01 | 1,239 | https://github.com/search?q=language%3AMoonBit+pushed%3A%3E%3D2026-01-01&type=repositories |
| Repositories with topic `moonbit` pushed since 2026-01-01 | 183 | https://github.com/search?q=topic%3Amoonbit+pushed%3A%3E%3D2026-01-01&type=repositories |
| Public `pkg.generated.mbti` files matching MoonBit search | 3,076 | https://github.com/search?q=filename%3Apkg.generated.mbti+moonbit&type=code |

The most important number for MoonGuard is the `pkg.generated.mbti` count: it
shows that MoonGuard's input format exists across many public repositories and
can be mined for parser coverage, regression tests, and demo reports.

Representative repositories:

| Repository | Stars observed | Type |
| --- | ---: | --- |
| https://github.com/moonbitlang/core | 1,148 | Official core library |
| https://github.com/moonbitlang/x | 56 | Official experimental libraries |
| https://github.com/moonbitlang/async | 64 | Official async library |
| https://github.com/moonbit-community/rabbita | 119 | Community UI framework |
| https://github.com/oboard/mocket | 94 | Community web framework |
| https://github.com/mizchi/markdown.mbt | 97 | Markdown parser |
| https://github.com/mizchi/luna.mbt | 161 | Declarative UI framework |
| https://github.com/moonbit-community/cmark.mbt | 34 | CommonMark toolkit |

## API Change And Release Workflow Evidence

MoonBit ecosystem repositories already contain release, compatibility, removal,
and deprecation activity. Examples from GitHub PR search:

| Repository | PR | Signal |
| --- | --- | --- |
| `moonbitlang/core` | https://github.com/moonbitlang/core/pull/3795 | Removed deprecated collection type aliases. |
| `moonbitlang/core` | https://github.com/moonbitlang/core/pull/3581 | Removed a deprecated public-style API surface. |
| `moonbitlang/core` | https://github.com/moonbitlang/core/pull/3760 | Added constructor and deprecated old API. |
| `moonbitlang/core` | https://github.com/moonbitlang/core/pull/3757 | Added constructor and deprecated old API. |
| `moonbitlang/core` | https://github.com/moonbitlang/core/pull/3761 | Added constructor and deprecated old API. |
| `mizchi/luna.mbt` | https://github.com/mizchi/luna.mbt/pull/94 | Updated MoonBit dependencies and bumped mooncakes version. |

These examples support the claim that MoonBit packages are actively changing
and need release-time API compatibility checks. MoonGuard can turn interface
changes into a clear major/minor/patch recommendation before publishing.

## Positioning Argument

MoonBit is still a small ecosystem, so MoonGuard should not claim broad
adoption. The stronger claim is:

> MoonBit already has a package registry, SemVer-based package versions,
> generated public interface files, and active package churn. MoonGuard uses
> those existing ecosystem artifacts to provide an early infrastructure layer
> for API compatibility and release safety.

This is stronger than relying on user testimonials because it is based on
observable ecosystem artifacts:

- Mooncakes registry statistics.
- Public package metadata and repositories.
- Thousands of generated `.mbti` files.
- Active official and community repositories.
- Real deprecation/removal/release PRs.

## Completed Validation Follow-up

The first real-world validation slice is now part of the repository:

- 15 repositories are pinned to full commit SHAs.
- All samples use Apache-2.0 or MIT licenses and include source metadata and
  SHA-256 hashes.
- MoonGuard models 6700 API items with zero unknown declarations or snapshot
  diagnostics.
- Fourteen modern-format samples are fully modeled; one historical sample
  exposed 119 unqualified associated `fn`/`impl` lines as a documented parser
  gap.

Recommended next ecosystem work:

- Open a few small issues or PRs offering MoonGuard CI examples to package
  maintainers.
- Extend the corpus when the toolchain introduces new interface syntax.
