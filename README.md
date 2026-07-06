# moonmark

Moonmark is a safe Markdown-to-HTML renderer written in MoonBit. It provides a
small reusable library API and a command-line renderer for a practical
CommonMark-inspired subset.

The project is intentionally scoped for predictable behavior rather than full
CommonMark compliance. User text is escaped before it is written into HTML, so
rendering untrusted Markdown does not directly inject raw HTML.

## Features

- Paragraphs and whitespace-only documents
- ATX headings (`#` through `######`)
- Setext headings (`Title` followed by `===` or `---`)
- Unordered and ordered lists
- Fenced code blocks with optional `language-*` classes
- Blockquotes
- Thematic breaks
- Inline code spans
- Inline links and images
- URI and email autolinks
- Emphasis and strong emphasis
- HTML escaping for text and attributes

## Installation

Install the MoonBit toolchain, then clone this repository:

```sh
git clone https://github.com/918154429/moonmark.git
cd moonmark
moon check
moon test
```

## Library Usage

Use `@moonmark.render` to render a Markdown document into an HTML fragment:

```moonbit
let html = @moonmark.render("# Hello <MoonBit>")
// <h1>Hello &lt;MoonBit&gt;</h1>
```

Inline-only rendering is available through `@moonmark.render_inline`, and
`@moonmark.escape_html` is exposed for callers that need the same escaping
policy.

## CLI Usage

Render Markdown passed as command-line arguments:

```sh
moon run cmd/main -- "# Hello <MoonBit>"
```

Output:

```html
<h1>Hello &lt;MoonBit&gt;</h1>
```

Other commands:

```sh
moon run cmd/main -- --help
moon run cmd/main -- --version
```

Stdin rendering is planned, but this version keeps the CLI on the reliably
portable argument path exposed by `moonbitlang/core/env`.

## Compatibility

Moonmark implements a documented Markdown subset. It does not currently claim
full CommonMark compatibility, raw HTML passthrough, nested block parsing, table
syntax, task lists, or reference-style links.

Malformed inline markup falls back to escaped text where practical. The tests
cover unclosed code fences, malformed links, unmatched emphasis markers, HTML
escaping, and CRLF-tolerant line handling.

## Development

Common checks:

```sh
moon info
moon fmt
moon check
moon test
```

Generated `pkg.generated.mbti` files are kept in the repository so interface
changes are reviewable after `moon info`.

See [docs/development-report.md](docs/development-report.md) and
[docs/competition-plan.md](docs/competition-plan.md) for project scope,
architecture notes, and competition execution status.
