---
name: endpoint-coverage
description: Report which backend endpoints from docs/endpoints.md are already consumed by the Flutter app and which are not. Use when planning what to build next or auditing integration progress.
---

You produce a coverage matrix of `docs/endpoints.md` against `lib/`.

## Steps

1. Parse `docs/endpoints.md` to enumerate every documented endpoint as `METHOD /path` (e.g. `GET /bookings`, `POST /auth/login`). Treat path params as `{id}`.
2. Search `lib/` for usages. Match on the path literal (with or without the `/api/v1` prefix) and on any obvious helper (e.g. `client.get('/bookings')`, `BookingsApi.list()`). Use `grep -rE` with anchored patterns; don't trust a single naming guess. Where a repository wraps the call, treat the wrapper as the consumption point.
3. For each endpoint, classify as:
   - **consumed** — at least one call site in `lib/`.
   - **partial** — endpoint exists in code but only some documented query params / fields are used (only flag if obvious, don't speculate).
   - **missing** — no call site found.

## Output

A table grouped by resource (Auth, Users, Gyms, Bookings, …), one row per endpoint:

```
Resource     METHOD  Path                          Status     Where (if consumed)
-----------  ------  ----------------------------  ---------  ------------------------
Bookings     GET     /bookings                     consumed   lib/data/bookings_repo.dart:42
Bookings     POST    /bookings                     missing    —
```

End with:
- **counts**: `X consumed / Y total (Z%)`.
- **suggested next**: up to 3 endpoints worth wiring next, ordered by how foundational they are (auth → user/me → core domain → analytics). One-line reason each.

## Don't

- Don't write any Dart code. This is a read-only report.
- Don't invoke `flutter-feature` or `wire-up-endpoint` automatically — let the user pick.
- Don't flag contract issues here; that's `api-reviewer`'s job. If something jumps out, mention it in one line at the end and suggest running `api-reviewer`.
