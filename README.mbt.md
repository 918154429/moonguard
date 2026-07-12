# 918154429/moonguard

MoonGuard is a MoonBit public API compatibility and SemVer guard.

```moonbit nocheck
///|
let report = @moonguard.diff_interfaces(
  "pub fn render(String) -> String", "pub fn render(String, Options) -> String",
)
```

See `README.md` for full project documentation.
