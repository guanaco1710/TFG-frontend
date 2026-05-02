---
name: wire-up-endpoint
description: End-to-end workflow to integrate a backend endpoint into the Flutter app. Runs api-reviewer first, gates on its verdict, then runs flutter-feature, then flutter-reviewer. Use when the user says "wire up X", "add a screen for Y", or "call /foo".
---

You are orchestrating the full contract-first integration flow defined in CLAUDE.md. The user prefers fixing the backend over patching the app — never let Dart code be written against a known-bad contract.

## Inputs

The user names a resource, endpoint, or screen (e.g. "wire up bookings list", "add a screen for /subscriptions/me"). If the target is ambiguous, ask one clarifying question before proceeding — do not guess.

## Steps

1. **Contract review.** Spawn the `api-reviewer` agent with the resource name and the screen's intended behavior. Wait for its verdict.
   - Verdict **block — needs backend changes first**: stop here. Surface the report to the user verbatim. Do not proceed to step 2. Offer to draft a one-paragraph backend ticket if useful.
   - Verdict **integrate after these fixes**: surface the report, ask the user whether they want to (a) fix the backend first, (b) proceed anyway accepting the listed risks, or (c) abort. Do not assume.
   - Verdict **OK to integrate**: continue.
2. **Implementation.** Spawn the `flutter-feature` agent with the endpoint(s) and screen behavior. If the project's conventions (state mgmt, routing, http client, serialization) are not yet established in `lib/`, the agent will ask the user — relay those questions back without answering on the user's behalf.
3. **Code review.** Once `flutter-feature` reports done, spawn `flutter-reviewer` against the branch diff. Surface its report.
   - If the reviewer's verdict is **fix these first**, decide whether to fix in-line yourself (small, mechanical) or ask the user. Don't loop the agents indefinitely.
   - If the verdict is **stop — backend contract issue**, return to step 1.
4. **Verify.** Run `flutter analyze` and `flutter test`. Report pass/fail. Do not mark the task done if either fails.

## What to report at the end

A short summary: which endpoint was wired, files touched (path:line for entry points), reviewer verdict, analyze/test status, and any TODOs deliberately left. If you stopped early at step 1 or 2, say so clearly — don't pretend the feature shipped.

## Don't

- Don't run `flutter-feature` before `api-reviewer` clears (or the user explicitly overrides).
- Don't paper over contract issues in Dart. Surface them, even if it costs a round trip.
- Don't invent project conventions. If `lib/` is still a scaffold, ask.
