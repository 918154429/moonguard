# MoonGuard API Compatibility Report

- Recommendation: **major**
- Changes: 61

| Impact | Change | Symbol | Details |
| --- | --- | --- | --- |
| major | added | `constructor HttpMethod.ACL` | `ACL` |
| major | added | `constructor HttpMethod.BIND` | `BIND` |
| major | added | `constructor HttpMethod.CHECKIN` | `CHECKIN` |
| major | added | `constructor HttpMethod.CHECKOUT` | `CHECKOUT` |
| major | added | `constructor HttpMethod.COPY` | `COPY` |
| major | added | `constructor HttpMethod.LABEL` | `LABEL` |
| major | added | `constructor HttpMethod.LINK` | `LINK` |
| major | added | `constructor HttpMethod.LOCK` | `LOCK` |
| major | added | `constructor HttpMethod.MERGE` | `MERGE` |
| major | added | `constructor HttpMethod.MKACTIVITY` | `MKACTIVITY` |
| major | added | `constructor HttpMethod.MKCALENDAR` | `MKCALENDAR` |
| major | added | `constructor HttpMethod.MKCOL` | `MKCOL` |
| major | added | `constructor HttpMethod.MKREDIRECTREF` | `MKREDIRECTREF` |
| major | added | `constructor HttpMethod.MKWORKSPACE` | `MKWORKSPACE` |
| major | added | `constructor HttpMethod.MOVE` | `MOVE` |
| major | added | `constructor HttpMethod.ORDERPATCH` | `ORDERPATCH` |
| major | added | `constructor HttpMethod.PRI` | `PRI` |
| major | added | `constructor HttpMethod.PROPFIND` | `PROPFIND` |
| major | added | `constructor HttpMethod.PROPPATCH` | `PROPPATCH` |
| major | added | `constructor HttpMethod.QUERY` | `QUERY` |
| major | added | `constructor HttpMethod.REBIND` | `REBIND` |
| major | added | `constructor HttpMethod.REPORT` | `REPORT` |
| major | added | `constructor HttpMethod.SEARCH` | `SEARCH` |
| major | added | `constructor HttpMethod.UNBIND` | `UNBIND` |
| major | added | `constructor HttpMethod.UNCHECKOUT` | `UNCHECKOUT` |
| major | added | `constructor HttpMethod.UNLINK` | `UNLINK` |
| major | added | `constructor HttpMethod.UNLOCK` | `UNLOCK` |
| major | added | `constructor HttpMethod.UPDATE` | `UPDATE` |
| major | added | `constructor HttpMethod.UPDATEREDIRECTREF` | `UPDATEREDIRECTREF` |
| major | added | `constructor HttpMethod.VERSION_CONTROL` | `VERSION_CONTROL` |
| minor | added | `fn HttpRequest::json` | `[T : @json.FromJson] HttpRequest::json(Self) -> T raise` |
| minor | added | `fn Mocket::acl` | `Mocket::acl(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::bind` | `Mocket::bind(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::checkin` | `Mocket::checkin(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::checkout` | `Mocket::checkout(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::copy` | `Mocket::copy(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::label` | `Mocket::label(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::link` | `Mocket::link(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::lock` | `Mocket::lock(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::merge` | `Mocket::merge(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::mkactivity` | `Mocket::mkactivity(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::mkcalendar` | `Mocket::mkcalendar(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::mkcol` | `Mocket::mkcol(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::mkredirectref` | `Mocket::mkredirectref(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::mkworkspace` | `Mocket::mkworkspace(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::move_` | `Mocket::move_(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::orderpatch` | `Mocket::orderpatch(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::pri` | `Mocket::pri(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::propfind` | `Mocket::propfind(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::proppatch` | `Mocket::proppatch(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::query` | `Mocket::query(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::rebind` | `Mocket::rebind(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::report` | `Mocket::report(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::search` | `Mocket::search(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::unbind` | `Mocket::unbind(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::uncheckout` | `Mocket::uncheckout(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::unlink` | `Mocket::unlink(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::unlock` | `Mocket::unlock(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::update` | `Mocket::update(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::updateredirectref` | `Mocket::updateredirectref(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
| minor | added | `fn Mocket::version_control` | `Mocket::version_control(Self, String, async (MocketEvent) -> &Responder noraise) -> Unit` |
