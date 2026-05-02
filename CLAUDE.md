# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # install / restore dependencies
flutter analyze          # static analysis (dart lint)
flutter test             # run all tests
flutter test test/widget_test.dart   # run a single test file
flutter run              # run app (prompts for device)
flutter run -d chrome    # run on a specific device (chrome, linux, android, ios…)
flutter build apk        # build Android APK
flutter build web        # build for web
```

Hot reload during `flutter run`: press `r`. Hot restart: `R`.

## Architecture

The app is a Flutter (Dart 3.11.5+) multi-platform project targeting Android, iOS, macOS, Windows, Linux, and Web. It uses Material Design 3 (`useMaterial3` / seed colors). The source lives in `lib/`; the project is in early development — `lib/main.dart` is currently the default counter scaffold.

### Backend API

The full REST contract is in `docs/endpoints.md`. Key facts:

- Base URL: `/api/v1`
- Auth: JWT `Authorization: Bearer <token>`. `/auth/login` returns `accessToken` + `refreshToken` (TTL 900 s). Use `/auth/refresh` to rotate.
- Roles: `CUSTOMER`, `INSTRUCTOR`, `ADMIN` — endpoints are role-gated as documented.
- All error responses share a common envelope: `{ timestamp, status, error, message, path }`.

### Domain model (API resources)

| Resource | Path prefix | Notes |
|---|---|---|
| Auth | `/auth` | register, login, refresh, logout, password-reset |
| Users | `/users` | CRUD (ADMIN); `/users/me` for self |
| Gyms | `/gyms` | public read, ADMIN write |
| Class Types | `/class-types` | templates (e.g. "Spinning 45 min") |
| Class Sessions | `/class-sessions` | scheduled occurrences; status: `SCHEDULED / CANCELLED / COMPLETED` |
| Bookings | `/bookings` | CUSTOMER books sessions; supports waitlist; state machine: `CONFIRMED → ATTENDED / CANCELLED / NO_SHOW`, `WAITLISTED → CONFIRMED` |
| Membership Plans | `/membership-plans` | plan catalogue |
| Subscriptions | `/subscriptions` | links a CUSTOMER to a plan; tracks `classesUsedThisMonth` |
| Ratings | `/ratings` | one rating per user per attended session (score 1–5) |
| Notifications | `/notifications/me` | polled by the app; types: `CONFIRMATION / REMINDER / CANCELLATION`; mark-read endpoints available |
| Payment Methods | `/users/{id}/payment-methods` | card metadata only (no real processing); auto-promotes default on delete |
| Statistics | `/stats` | per-user and gym-level analytics |

## API quality — flag issues to the user immediately

This frontend is being built against a backend the user controls. Whenever you start integrating a new endpoint (reading `docs/endpoints.md`, writing the Dart client, parsing a response), if you spot a contract problem, **stop and surface it to the user before coding around it** — they will fix the backend / DB rather than have the app paper over it.

Things to flag on sight:

- **Inconsistent pagination shape** across endpoints (`total` vs `totalElements`/`totalPages`, missing `totalPages` on some lists, etc.).
- **Inconsistent verb choice for the same intent** (`PATCH /bookings/{id}/cancel` vs `POST /subscriptions/me/cancel` — pick one).
- **Inconsistent field naming** (`name` vs `firstName`/`lastName`, `userId` vs `user.id`, snake/camel mixing).
- **Missing role gating** or IDOR risk (e.g. an endpoint takes `{userId}` in the path but no documented owner-check).
- **Wrong status codes** (404 used for "forbidden", 400 used for business-rule conflicts that should be 409/422).
- **Response shape that doesn't match the request** (e.g. POST returns less than what GET returns for the same resource — forces an extra round-trip).
- **Missing fields the UI demonstrably needs** (e.g. a list endpoint that omits a field every screen has to display, forcing N+1 detail fetches).
- **Datetimes without timezone** (`"2024-06-01T09:00:00"` vs `"...Z"` — the schedule endpoint mixes both).
- **Enum values not documented** or values that leak persistence concerns.
- **Pagination defaults inconsistent** with other list endpoints.

Format the report as: *endpoint, problem, suggested fix*. Don't try to be exhaustive in one pass — flag what blocks the current task, then continue.
