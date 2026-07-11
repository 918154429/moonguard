# MoonGuard API Compatibility Report

- Recommendation: **major**
- Changes: 5

| Impact | Change | Symbol | Details |
| --- | --- | --- | --- |
| major | removed | `fn small_check` | `[A : @feat.Enumerable + @debug.Debug, B : Testable] small_check((A) -> B, max_size? : Int, expect? : @state.Expected, abort? : Bool, verbose? : Bool) -> Unit raise Failure` |
| major | removed | `fn small_check_error` | `[A : @feat.Enumerable + @debug.Debug, B : Testable] small_check_error((A) -> B raise, max_size? : Int, expect? : @state.Expected, abort? : Bool, verbose? : Bool) -> Unit raise Failure` |
| major | removed | `fn small_check_error_silence` | `[A : @feat.Enumerable + @debug.Debug, B : Testable] small_check_error_silence((A) -> B raise, max_size? : Int, expect? : @state.Expected, abort? : Bool, verbose? : Bool) -> String` |
| major | removed | `fn small_check_silence` | `[A : @feat.Enumerable + @debug.Debug, B : Testable] small_check_silence((A) -> B, max_size? : Int, expect? : @state.Expected, abort? : Bool, verbose? : Bool) -> String` |
| minor | added | `fn run_testable_once` | `[P : Testable] run_testable_once(P, Int, @state.State, @state.Expected, Bool) -> (@state.SingleResult, @state.State)` |
