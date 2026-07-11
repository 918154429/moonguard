# MoonGuard API Compatibility Report

- Recommendation: **minor**
- Changes: 2

| Impact | Change | Symbol | Details |
| --- | --- | --- | --- |
| minor | added | `fn ServerConnection::write` | `async fn ServerConnection::write(Self, &@io.Data) -> Unit` |
| minor | added | `fn ServerConnection::write_string` | `async fn ServerConnection::write_string(Self, String) -> Unit` |
