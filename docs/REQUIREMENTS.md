# GymBook — Frontend Requirements

## 1. Project Overview

**GymBook** is a multi-platform gym management application built with Flutter. It connects three types of users — customers, instructors, and administrators — through a shared class-booking, subscription, and analytics system backed by a REST API.

**Target platforms:** Android · iOS · macOS · Windows · Linux · Web  
**Tech stack:** Flutter (Dart ≥ 3.11.5) · Material Design 3 · JWT auth · REST API (`/api/v1`)

---

## 2. User Roles

| Role | Who they are | Core capabilities |
|------|--------------|-------------------|
| `CUSTOMER` | Gym member | Browse schedule, book classes, manage subscription, view personal stats, rate sessions |
| `INSTRUCTOR` | Class instructor | View own session bookings, mark attendance |
| `ADMIN` | Gym staff / owner | Full CRUD on all resources, manage users, view gym-level analytics |

Public (unauthenticated) users can browse gyms, class types, and the schedule but cannot book or take any action.

---

## 3. Authentication & Session

### Goals
- Secure, passwordless-ready login flow using JWT tokens.
- Tokens stored in platform secure storage (Keychain / Keystore), never in plain `SharedPreferences`.
- Transparent token refresh: the app automatically rotates the access token before it expires (TTL 900 s) without forcing the user to re-login.

### Functional Requirements

| ID | Requirement |
|----|-------------|
| A-01 | User can create a CUSTOMER account with first name, last name, email, and password. |
| A-02 | User can log in with email and password; receives `accessToken` + `refreshToken`. |
| A-03 | App silently refreshes the access token using the refresh token before expiry. |
| A-04 | User can log out; the refresh token is revoked server-side. |
| A-05 | User can request a password-reset email and confirm the reset with the received token. |
| A-06 | All authenticated requests attach `Authorization: Bearer <token>`. Token is injected in one place (HTTP interceptor). |
| A-07 | On refresh failure the app clears stored tokens and redirects to the login screen. |

---

## 4. User Profile

### Functional Requirements

| ID | Requirement |
|----|-------------|
| U-01 | Authenticated user can view their own profile (name, email, role). |
| U-02 | User can update first name, last name, phone number, and avatar URL. |
| U-03 | User can change their password by providing the current password and a new one. |
| U-04 | `ADMIN` can list all users, filtered by role, with pagination and sort. |
| U-05 | `ADMIN` can view any user's profile. |
| U-06 | `ADMIN` can create users with any role (e.g. create an `INSTRUCTOR` account). |
| U-07 | `ADMIN` can update or soft-delete any user account. |

---

## 5. Gyms

### Functional Requirements

| ID | Requirement |
|----|-------------|
| G-01 | Any user (including unauthenticated) can browse the list of gyms. |
| G-02 | Any user can view a gym's detail (name, address, city, phone, opening hours). |
| G-03 | `ADMIN` can create, update, and delete gyms. |

---

## 6. Class Types

Class types are reusable templates (e.g. "Spinning 45 min", "Yoga Flow") that describe a category of class independent of schedule.

### Functional Requirements

| ID | Requirement |
|----|-------------|
| CT-01 | Any user can browse the class-type catalogue. |
| CT-02 | Class types display name, description, duration in minutes, category, and an optional icon. |
| CT-03 | `ADMIN` can create, update, and delete class types. |

---

## 7. Class Schedule & Sessions

A class session is a concrete scheduled occurrence of a class type, at a specific gym, with an instructor and a fixed capacity.

### Functional Requirements

| ID | Requirement |
|----|-------------|
| CS-01 | Any user can browse the schedule filtered by gym, class type, instructor, date range, status, and available-only flag. |
| CS-02 | Schedule items display: class name, gym, instructor name, start time, duration, capacity, spots available, room, and status (`SCHEDULED / CANCELLED / COMPLETED`). |
| CS-03 | User can view full session detail. |
| CS-04 | `ADMIN` can schedule, update, and cancel sessions. |
| CS-05 | `INSTRUCTOR` and `ADMIN` can view the full booking list for a session. |
| CS-06 | `INSTRUCTOR` and `ADMIN` can mark attendance for each enrolled user (`ATTENDED` / `NO_SHOW`) in bulk. |

---

## 8. Bookings

### Goals
- Customers book class sessions and get a confirmed spot or a waitlist position.
- When a spot opens (booking cancelled), the first waitlisted customer is automatically promoted to CONFIRMED by the backend.

### Booking state machine

```
POST /bookings
     │
     ├─ spots available  ──► CONFIRMED ──► ATTENDED
     │                            └──► CANCELLED
     │                            └──► NO_SHOW (set by instructor/admin)
     │
     └─ session full + waitlist enabled ──► WAITLISTED ──► CONFIRMED (auto-promoted)
```

### Functional Requirements

| ID | Requirement |
|----|-------------|
| B-01 | `CUSTOMER` can book a spot in a `SCHEDULED` session. |
| B-02 | If the session is full and waitlisting is enabled, the booking is created with status `WAITLISTED` and a position number. |
| B-03 | Customer can view their own bookings, filtered by status and date range. |
| B-04 | Customer or `ADMIN` can cancel a booking. |
| B-05 | `ADMIN` can list all bookings, filtered by user, session, or status. |
| B-06 | The UI distinguishes CONFIRMED, WAITLISTED, CANCELLED, ATTENDED, and NO_SHOW states visually. |

---

## 9. Membership Plans & Subscriptions

### Goals
- Plans define the number of classes a customer can book per month and the monthly price.
- Each customer has at most one active subscription at a time.

### Functional Requirements

| ID | Requirement |
|----|-------------|
| MP-01 | Any user can browse available membership plans (name, description, price, classes/month, waitlist eligibility). |
| MP-02 | `CUSTOMER` can subscribe to a plan. |
| MP-03 | Customer can view their own subscription: plan details, status, renewal date, classes used and remaining this month. |
| MP-04 | Customer can cancel their own subscription (takes effect at end of current period). |
| MP-05 | `ADMIN` can list, create, update, and deactivate plans. |
| MP-06 | `ADMIN` can view, cancel, or renew any subscription. |

---

## 10. Ratings

### Goals
- Customers provide feedback on sessions they attended, enabling quality tracking.
- One rating per customer per session; can be updated or deleted.

### Functional Requirements

| ID | Requirement |
|----|-------------|
| R-01 | `CUSTOMER` can submit a rating (score 1–5, optional comment) for a session they attended. |
| R-02 | Customer can update their own rating. |
| R-03 | Customer or `ADMIN` can delete a rating. |
| R-04 | Any authenticated user can view all ratings for a session (paginated, sortable). |
| R-05 | Any authenticated user can list their own ratings. |

---

## 11. Notifications

### Goals
- Backend pushes booking confirmations, session reminders, and cancellation notices automatically.
- The app polls the notification inbox and displays an unread badge.

### Notification types

| Type | Trigger |
|------|---------|
| `CONFIRMATION` | Booking confirmed or waitlist promoted |
| `REMINDER` | Upcoming session (sent by backend scheduler) |
| `CANCELLATION` | Session or booking cancelled |

### Functional Requirements

| ID | Requirement |
|----|-------------|
| N-01 | App displays a notification inbox with type, message, and timestamp. |
| N-02 | App shows an unread count badge on the notification icon. |
| N-03 | User can mark a single notification as read or mark all as read. |
| N-04 | User can delete a notification. |
| N-05 | `ADMIN` can view notifications for any user or any session. |
| N-06 | App polls `/notifications/me/unread-count` periodically to refresh the badge without loading the full list. |

---

## 12. Payment Methods

> No real payment processing — card metadata only (last 4 digits, brand, expiry).

### Business rules
- First card added is automatically set as default.
- Deleting the default card auto-promotes the most recently added sibling.
- Expired cards are rejected (409).
- Duplicate `cardType + last4` per user is rejected (409).

### Functional Requirements

| ID | Requirement |
|----|-------------|
| PM-01 | User can add a card (type: VISA / MASTERCARD / AMEX / DISCOVER; last 4, expiry, cardholder name). |
| PM-02 | User can list and view their saved payment methods. |
| PM-03 | User can set a card as default. |
| PM-04 | User can delete a card; default is auto-promoted if needed. |
| PM-05 | `ADMIN` can manage payment methods for any user. |

---

## 13. Statistics

### Functional Requirements

| ID | Requirement |
|----|-------------|
| ST-01 | `CUSTOMER` can view personal stats over a date range: total classes attended, current and longest streak, no-show and cancellation counts, favourite class type, monthly attendance chart, attendance breakdown by class type. |
| ST-02 | `ADMIN` can view any user's stats. |
| ST-03 | `INSTRUCTOR` and `ADMIN` can view occupancy stats for a specific session. |
| ST-04 | `ADMIN` can view gym-level stats: total members, active subscriptions, total sessions scheduled, average occupancy rate, most popular class type, peak hour, peak day of week. |

---

## 14. Non-Functional Requirements

| ID | Category | Requirement |
|----|----------|-------------|
| NF-01 | Platforms | App must run on Android, iOS, macOS, Windows, Linux, and Web from a single codebase. |
| NF-02 | Design system | Material Design 3 with a seed-color theme; consistent across all platforms. |
| NF-03 | Security | Tokens stored in platform secure storage. No tokens logged or written to plain files. HTTPS only in production. |
| NF-04 | Auth resilience | Token refresh handled in a single HTTP interceptor; concurrent 401s must not trigger parallel refresh races. |
| NF-05 | Error handling | All API errors parsed using the common envelope `{ timestamp, status, error, message, path }` into typed exceptions; raw HTTP codes never shown in the UI. |
| NF-06 | Role-gated UI | Screens and actions are hidden or disabled when the user's role lacks permission, in addition to server-side enforcement. |
| NF-07 | Pagination | All list screens support incremental loading (pagination); no unbounded fetches. |
| NF-08 | Offline | App shows a clear error state and allows retry when the API is unreachable; it does not crash or show spinner forever. |
| NF-09 | Code quality | `flutter analyze --fatal-infos` passes on every commit; `dart format` applied before every PR. |
| NF-10 | Test coverage | Each new screen ships with at least one widget test covering the golden path and one error path. |
| NF-11 | CI | Every PR runs format check → analyze → tests → build web + Android debug before merge (see `.github/workflows/ci.yml`). |

---

## 15. API Contract Summary

| Domain | Base path | Public | CUSTOMER | INSTRUCTOR | ADMIN |
|--------|-----------|--------|----------|------------|-------|
| Auth | `/auth` | register, login, refresh, reset | logout | logout | logout |
| Users | `/users` | — | `/me` | `/me` | full CRUD |
| Gyms | `/gyms` | list, get | — | — | create, update, delete |
| Class Types | `/class-types` | list, get | — | — | create, update, delete |
| Class Sessions | `/class-sessions` | list, get | — | bookings, attendance | full CRUD + bookings + attendance |
| Bookings | `/bookings` | — | book, `/me`, cancel | session bookings | all bookings |
| Plans | `/membership-plans` | list, get | — | — | create, update, delete |
| Subscriptions | `/subscriptions` | — | `/me`, subscribe, cancel | — | full management |
| Ratings | `/ratings` | — | submit, edit, delete own | view | delete any |
| Notifications | `/notifications` | — | `/me`, mark-read, delete | session notifications | any user |
| Payment Methods | `/users/{id}/payment-methods` | — | own | — | any user |
| Statistics | `/stats` | — | `/me` | `/sessions/{id}` | all stats |

Auth: JWT Bearer · TTL: 900 s access / rotated refresh · Error envelope: `{ timestamp, status, error, message, path }`

---

## 16. Screen Inventory

A minimal screen list derived from the functional requirements above.

| Screen | Roles | Key endpoints |
|--------|-------|---------------|
| Login | Public | `POST /auth/login` |
| Register | Public | `POST /auth/register` |
| Password Reset | Public | `POST /auth/password-reset/*` |
| Home / Dashboard | All | — (aggregates data) |
| Schedule (browse + filter) | All | `GET /class-sessions` |
| Session Detail | All | `GET /class-sessions/{id}` |
| Booking Confirmation | CUSTOMER | `POST /bookings` |
| My Bookings | CUSTOMER | `GET /bookings/me` |
| Attendance (mark) | INSTRUCTOR, ADMIN | `POST /class-sessions/{id}/attendance` |
| My Subscription | CUSTOMER | `GET /subscriptions/me` |
| Plan Catalogue | All | `GET /membership-plans` |
| My Profile | All | `GET /users/me`, `PUT /users/me` |
| Change Password | All | `PATCH /users/me/password` |
| Payment Methods | All | `GET/POST/PATCH/DELETE /users/{id}/payment-methods` |
| Notifications Inbox | All | `GET /notifications/me`, mark-read |
| My Stats | CUSTOMER | `GET /stats/me` |
| Rate Session | CUSTOMER | `POST /ratings` |
| Gym List | All | `GET /gyms` |
| Admin — User Management | ADMIN | `GET/POST/PUT/DELETE /users` |
| Admin — Session Management | ADMIN | `POST/PUT/DELETE /class-sessions` |
| Admin — Subscription Management | ADMIN | `GET /subscriptions`, cancel, renew |
| Admin — Gym Stats | ADMIN | `GET /stats/gym` |
