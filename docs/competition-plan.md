# Moonmark Competition Plan

This document is the local working plan for turning `moonmark` from a small
Markdown-to-HTML prototype into a credible MoonBit open-source ecosystem
competition submission.

No implementation work is implied by this document. It records the current
state, target positioning, phased work, and risks.

## Competition Constraints

The MoonBit competition expects a real open-source ecosystem project rather
than a one-off demo. The relevant requirements are:

- The project should primarily be implemented in MoonBit.
- GitHub and GitLink repositories should be public and synchronized.
- Commit history should be clear. The project application phase mentions
  10-20 meaningful commits.
- Source structure should be clear and should implement the declared core
  functionality.
- README should explain project goals, installation, usage, examples, and
  reproducibility.
- CI should cover check, build, and test workflows.
- Suggested scale is 4k-10k effective MoonBit lines.
- The final submission should include source code, tests, documentation, and a
  development report.

## Current State

Project path:

```text
E:\C_Moved_From_C\Users\Lenovo\Desktop\schoolwork\CCF\moonbit\moonmark
```

Current capabilities:

- Safe HTML escaping.
- Paragraph rendering.
- ATX headings.
- Unordered lists.
- Ordered lists.
- Fenced code blocks.
- Inline code spans.
- Inline links.
- Emphasis and strong emphasis.
- Basic tests for the above behavior.

Current gaps:

- CLI is still template-level and only prints `Hello`.
- README is short and not enough for competition review.
- `moon.mod` metadata is incomplete: repository, description, and keywords are
  empty.
- GitHub workflow is not a real MoonBit CI workflow.
- Effective MoonBit code size is far below the suggested 4k-10k line range.
- Generated interface files are present as untracked files and need a deliberate
  policy.

## Project Positioning

Recommended positioning:

> Moonmark is a safe Markdown-to-HTML renderer for the MoonBit ecosystem. It
> provides a reusable library API, a command-line renderer, a documented
> CommonMark-inspired subset, HTML-safe output, tests, CI, and development
> documentation.

The project should avoid claiming full CommonMark compliance unless a formal
compatibility suite is added. The safer claim is "CommonMark-inspired subset" or
"practical Markdown subset".

## Phase 1: Project Foundation

Goal: make the repository look like a credible open-source project.

Tasks:

- Complete `moon.mod` metadata:
  - repository
  - description
  - keywords
  - keep version at `0.1.0` unless release semantics are added
- Expand `README.md`:
  - project goal
  - supported Markdown subset
  - installation or setup
  - library API examples
  - CLI examples
  - security behavior: HTML is escaped by default
  - compatibility and non-goals
- Add `docs/development-report.md`:
  - motivation
  - feature scope
  - architecture
  - implementation decisions
  - testing strategy
  - AI collaboration notes
  - future roadmap
- Add GitHub Actions CI:
  - `moon check`
  - `moon test`
  - formatting check if supported by the installed toolchain

## Phase 2: Real CLI

Goal: provide a runnable tool for demos and review.

Tasks:

- Replace the template CLI with a real renderer.
- Support rendering Markdown passed through arguments or stdin.
- Add `--help`.
- Add `--version`.
- Document examples in README, such as:

```bash
moon run cmd/main -- "# Hello"
```

or:

```bash
echo "# Hello" | moon run cmd/main
```

Testing:

- Prefer tests if the MoonBit toolchain supports testing the command package
  cleanly.
- Otherwise ensure CI still checks and builds the CLI package.

## Phase 3: Markdown Feature Expansion

Goal: make the library useful enough to be credible, while staying within a
clear subset.

Priority features:

- Blockquotes:
  - `> quote`
  - multi-line quotes
  - inline rendering inside quotes
- Thematic breaks:
  - `---`
  - `***`
- Setext headings:
  - `Title\n=====`
  - `Title\n-----`
- Fenced code language classes:
  - input fence info string such as `moonbit`
  - output class such as `language-moonbit`
- Images:
  - `![alt](url)`
  - safe escaping for `alt` and `src`
- Autolinks:
  - `<https://example.com>`
  - `<user@example.com>`
- Soft and hard break behavior:
  - either implement explicit behavior or document the current paragraph merge
    strategy
- Inline parser improvements:
  - reduce false emphasis matches
  - clarify nested inline behavior
  - preserve safe fallback behavior for malformed input

## Phase 4: Test and Quality Expansion

Goal: increase review confidence through broad tests and stable behavior.

Tasks:

- Add tests per syntax group.
- Add security escaping tests.
- Add malformed input tests.
- Add empty input, whitespace-only input, and CRLF tests.
- Add unclosed code fence, link, emphasis, and image tests.
- Add fuzz-like cases that assert the renderer does not panic and still emits
  safe HTML.
- Consider fixture-style tests with Markdown input and HTML expected output if
  file IO is convenient in the current toolchain.

Recommended final checks:

```bash
moon info
moon fmt
moon test
```

Optional internal check:

```bash
moon coverage analyze > uncovered.log
```

Do not commit `uncovered.log` unless it is intentionally used as documentation.

## Phase 5: Module Structure

Goal: keep the codebase maintainable as features grow.

Suggested split:

- `escape.mbt`
- `inline.mbt`
- `block.mbt`
- `render.mbt`
- `types.mbt`
- `cmd/main` for CLI only

This should be done after the first few functional changes, not as premature
refactoring before the parser direction is stable.

## Phase 6: Submission Materials

Goal: satisfy MoonBit competition review expectations.

Tasks:

- Ensure GitHub and GitLink repositories are public and synchronized.
- Keep commits meaningful; avoid empty or artificially split commits.
- Maintain README and development report alongside implementation changes.
- Provide clear examples and test commands.
- Provide final validation logs or CI badges if available.

Suggested commit sequence:

1. `Document moonmark scope and usage`
2. `Add Markdown blockquote rendering`
3. `Render thematic breaks`
4. `Support setext headings`
5. `Add code fence language classes`
6. `Implement image spans`
7. `Add CLI rendering command`
8. `Add CI for MoonBit check and tests`
9. `Expand malformed markdown tests`
10. `Add development report`

## Risk Assessment

Primary risk:

- The current project is much smaller than the suggested 4k-10k effective
  MoonBit line range.

Mitigation:

- Expand feature coverage deliberately.
- Add broad tests.
- Provide strong documentation and a real CLI.
- Avoid overclaiming CommonMark compliance.

Secondary risks:

- MoonBit toolchain behavior may constrain CLI input handling and CI formatting
  checks.
- Markdown parsing can grow complex quickly; keep the supported subset explicit.
- Generated `.mbti` files need a clear policy after running `moon info`.

## Recommended Execution Order

1. Project foundation: README, `moon.mod`, CI, development report skeleton.
2. Real CLI.
3. Blockquote, thematic break, setext heading, code fence language classes.
4. Images and autolinks.
5. Test expansion and malformed input coverage.
6. Module split if the main file becomes difficult to maintain.

