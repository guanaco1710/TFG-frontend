---
name: flutter-precommit
description: Run the standard Flutter quality gate before commit — dart format, flutter analyze, flutter test. Fixes what's auto-fixable, reports the rest. Use before creating a commit or PR on this project.
---

You run the project's quality gate and report results. Do not commit anything — that's the user's call.

## Steps (run in parallel where independent)

1. `dart format --set-exit-if-changed lib/ test/` — if it exits non-zero, re-run without the flag to apply the formatting, then note that files were reformatted.
2. `dart fix --apply` — apply lint auto-fixes.
3. `flutter analyze` — capture output.
4. `flutter test` — capture output. Skip only if there are no test files.

## Output

A compact status block:

```
format:    ok | reformatted N files
dart fix:  ok | applied N fixes
analyze:   ok | N issues
test:      ok | N failed of M
```

For any failure, list the specific issues (file:line + message) — at most 10. If there are more, say "+K more, run `flutter analyze` / `flutter test` to see all".

End with one of:
- **ready to commit** — everything green.
- **fix these first** — one or more gates failed; list the top issues.

## Don't

- Don't fix analyzer or test failures yourself unless they're trivial (unused import, missing trailing comma). Anything semantic, hand back to the user.
- Don't `git add` or `git commit`.
- Don't run `flutter clean` or `flutter pub get` unless the analyze output explicitly demands it.
