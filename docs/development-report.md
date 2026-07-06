# Moonmark Development Report

## Motivation

MoonBit needs small, readable ecosystem libraries that demonstrate practical
package structure, tests, documentation, and CI. Moonmark targets that space by
providing a safe Markdown-to-HTML renderer written primarily in MoonBit.

## Scope

Moonmark implements a practical CommonMark-inspired subset:

- paragraphs
- ATX and setext headings
- unordered and ordered lists
- fenced code blocks
- fenced code language classes
- blockquotes
- thematic breaks
- inline code
- links, images, and autolinks
- emphasis and strong emphasis
- HTML escaping for text and attributes

The project avoids claiming full CommonMark compatibility. Unsupported syntax
is rendered as escaped text where possible.

## Architecture

The current implementation is intentionally compact:

- `moonmark.mbt` contains block scanning, inline rendering, and escaping.
- `moonmark_test.mbt` covers public renderer behavior.
- `cmd/main` is a small executable package that delegates rendering to the
  library.
- `docs/competition-plan.md` tracks phased competition work.

The parser is line-oriented. It first recognizes block constructs, flushes
pending paragraphs or lists as needed, and then applies inline rendering inside
text-bearing blocks.

## Implementation Decisions

HTML escaping is the default safety boundary. Text nodes and attributes both
escape `&`, `<`, `>`, quotes, and apostrophes before output.

The supported Markdown subset is deliberately explicit. This keeps behavior
reviewable and avoids overstating compatibility before a CommonMark fixture
suite exists.

Code fence language classes are restricted to ASCII alphanumeric names plus
`-` and `_`, which prevents unsafe class attribute construction from arbitrary
info strings.

The CLI currently renders Markdown passed through command-line arguments and
supports `--help` and `--version`. Stdin rendering remains a future task because
the local MoonBit core package exposes argv through `moonbitlang/core/env`, but
does not expose an equally clear stdin API in this toolchain snapshot.

## Testing Strategy

Tests are black-box renderer checks using expected HTML snapshots. Current
coverage includes:

- escaping behavior
- paragraphs and whitespace-only input
- headings
- lists
- code blocks and unclosed fences
- inline code
- links and malformed links
- images and autolinks
- emphasis and unmatched markers
- blockquotes, thematic breaks, and setext headings

The expected next step is to add more malformed-input and fuzz-like cases that
assert the renderer does not panic and continues to emit safe HTML.

## AI Collaboration Notes

AI assistance was used to plan and implement incremental competition-oriented
work. The project scope was kept conservative: functionality, tests, CI, and
documentation were prioritized over broad claims or parser rewrites.

## Roadmap

- Add stdin rendering once the preferred MoonBit IO API is confirmed.
- Broaden malformed Markdown tests.
- Improve nested inline behavior.
- Split `moonmark.mbt` into `escape`, `inline`, `block`, `render`, and `types`
  modules when the implementation grows enough to justify the structure.
- Add GitLink synchronization for the final competition submission.
