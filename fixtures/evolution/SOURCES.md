# API evolution fixture sources

These unmodified `.mbti` snapshots are pinned to public GitHub commits and are
used to reproduce MoonGuard's real API evolution reports. Copyright remains
with the original authors. All three external repositories are Apache-2.0
licensed.

| Case | Repository | Path | Old commit | New commit | Old SHA-256 | New SHA-256 |
| --- | --- | --- | --- | --- | --- | --- |
| `moonbitlang-async-http` | [moonbitlang/async](https://github.com/moonbitlang/async) | `src/http/pkg.generated.mbti` | [`b2169b7`](https://github.com/moonbitlang/async/commit/b2169b7e4226d44808c9eee31e9b21e091efdc6c) | [`ff28856`](https://github.com/moonbitlang/async/commit/ff2885666e02859735331f4035b668cc957b1b6e) | `04d291da8c964895ca953b7f81021101149509868e1040ccde2add4e8791ee0d` | `606f65550279310d7dad5349c70edb80b0d41c825e8955b834d90535632c932b` |
| `moonbitlang-quickcheck` | [moonbitlang/quickcheck](https://github.com/moonbitlang/quickcheck) | `src/pkg.generated.mbti` | [`6d97a1c`](https://github.com/moonbitlang/quickcheck/commit/6d97a1cc1e4f3be5ae9ef0d15b5d269977362f6d) | [`9648749`](https://github.com/moonbitlang/quickcheck/commit/9648749c3b0272d561d7c7bbb5f71550b737026d) | `f80db77ca3f79bca8c1c668df83df7fe6e340f4af1bf0b359fd744a2996aeec6` | `651b06fe5cc43941860f988410eb6817a721e50087471b68b42db2734d00777e` |
| `oboard-mocket` | [oboard/mocket](https://github.com/oboard/mocket) | `pkg.generated.mbti` | [`8f4a8e9`](https://github.com/oboard/mocket/commit/8f4a8e9a8b04f2e4b5bf1b4c613890e137c09b5a) | [`544178c`](https://github.com/oboard/mocket/commit/544178cef3fe611ac1c8ac91671c246510668cd9) | `cc90be41f488c0671b5d0cffac3b2fc7cd9e48ede647d73f5b477f6eec5c9ca2` | `53ab40196e84cfed2d3b5dc7c2b3fb53e9d2563036b508f1b833b1182f1ad9ad` |

The MoonGuard self-evolution fixture is extracted from the repository's signed
`v0.1.0` tag by `scripts/generate-evolution-evidence.ps1`; the new side is the
current tracked `pkg.generated.mbti`.
