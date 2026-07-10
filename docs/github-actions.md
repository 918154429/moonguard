# GitHub Actions Integration

MoonGuard can block a release when a committed API baseline and the current
generated interfaces require a larger SemVer bump.

## Repository Layout

Keep the last released interfaces in a directory that is committed with the
project:

```text
api-baseline/
  pkg.generated.mbti
  subpackage/pkg.generated.mbti
```

Before publishing a release, update `CURRENT_VERSION` and `NEXT_VERSION` in the
workflow. After the release succeeds, replace `api-baseline/` with the newly
generated interfaces in a separate reviewable commit.

## Release Compatibility Workflow

```yaml
name: API compatibility

on:
  pull_request:
  workflow_dispatch:

jobs:
  moonguard:
    runs-on: ubuntu-latest
    env:
      CURRENT_VERSION: 0.4.0
      NEXT_VERSION: 0.5.0

    steps:
      - name: Checkout project
        uses: actions/checkout@v5

      - name: Set up MoonBit
        run: |
          curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
          echo "$HOME/.moon/bin" >> "$GITHUB_PATH"

      - name: Generate current interfaces
        run: moon info

      - name: Checkout MoonGuard
        uses: actions/checkout@v5
        with:
          repository: 918154429/moonguard
          ref: v0.1.0
          path: .tools/moonguard

      - name: Build MoonGuard
        working-directory: .tools/moonguard
        run: moon run --target js cmd/main -- --version

      - name: Check API and SemVer
        working-directory: .tools/moonguard
        run: |
          node _build/js/debug/build/cmd/main/main.js check-dir \
            "$GITHUB_WORKSPACE/api-baseline" \
            "$GITHUB_WORKSPACE" \
            --current "$CURRENT_VERSION" \
            --next "$NEXT_VERSION"
```

The generated JavaScript entry is invoked with Node for the final step because
Node preserves MoonGuard's exit status:

- `0`: the proposed version is sufficient;
- `1`: the API impact requires a larger version bump;
- `2`: input, configuration, or snapshot diagnostics prevented a reliable
  comparison.

## JSON Artifact

For dashboards or later workflow steps, add `--format json` and redirect the
report to a file:

```yaml
      - name: Create machine-readable release plan
        working-directory: .tools/moonguard
        run: |
          node _build/js/debug/build/cmd/main/main.js release-plan \
            "$GITHUB_WORKSPACE/api-baseline" \
            "$GITHUB_WORKSPACE" \
            --current "$CURRENT_VERSION" \
            --next "$NEXT_VERSION" \
            --format json > "$GITHUB_WORKSPACE/moonguard-release-plan.json"

      - name: Upload MoonGuard report
        uses: actions/upload-artifact@v4
        with:
          name: moonguard-release-plan
          path: moonguard-release-plan.json
```

Do not add an ignore rule only to make a failing build green. Each rule should
include a reason and should be reviewed like a compatibility exception.
