# Contributing to Lipa-Cart

Thanks for working on Lipa-Cart. This document captures the rules and
expectations for code in this repository. They exist so the codebase stays
maintainable, secure, and scalable as the team and surface area grow.

## Ground rules

1. **Security and long-term stability come before convenience.** Lipa-Cart
   handles real customer PII (phone numbers, addresses, delivery details) and
   payment flows. Shortcuts that compromise either are not acceptable, even
   if they unblock something short-term.
2. **Match the patterns already in the codebase.** When adding new code, read
   the nearest similar screen/provider/service first and follow its
   conventions (folder layout, naming, state management, error handling).
3. **Never commit secrets.** API keys, Firebase service accounts, Sentry DSNs,
   signing keystores, and any credential files must never be committed. Use
   `--dart-define` for build-time config and platform secret storage
   (`flutter_secure_storage` / Keychain / Keystore) at runtime.
4. **No direct pushes to `main`.** All changes go through a pull request with
   at least one reviewer.

## Before you commit

Run these locally on anything you change:

```bash
flutter pub get              # Install dependencies
flutter analyze              # Static analysis (blocking in CI)
dart format .                # Format Dart sources
flutter test                 # Run unit + widget tests
flutter build web --release  # Sanity-check the web build
```

An optional git pre-commit hook that runs `flutter analyze` and
`dart format --set-exit-if-changed` on staged files can be wired up locally —
see `scripts/` if one is added. Phase 1 does not enforce this.

## Pull request checklist

Before opening a PR, please verify:

- [ ] `flutter analyze` passes locally with no new findings.
- [ ] `flutter test` passes locally (or the PR explains why it doesn't).
- [ ] `flutter build web --release` succeeds locally.
- [ ] You have tested the change end-to-end on at least one target platform
      (Android, iOS, or Web) against a local or staging backend.
- [ ] You have not committed any API keys, Firebase configs, signing keys, or
      other secrets.
- [ ] The PR description explains **why** the change is being made, not just
      **what** changed.
- [ ] If the change touches auth, payments, KYC, secure storage, or external
      API contracts, you have flagged it in the PR description for extra review.
- [ ] If the change is a bug fix, a regression test exists (or the PR
      description explains why it doesn't).

## CI expectations

Every PR runs:

- **Analyze + test** (`.github/workflows/ci.yml`) — `flutter analyze` is
  blocking. `flutter test` and the web build are currently non-blocking while
  the test suite is built up and the baseline stabilizes.
- **Format check** — currently non-blocking. Do not introduce new formatting
  drift; run `dart format .` on files you touch.
- **Semgrep SAST** — findings print to the workflow log with file:line
  annotations. Treat high/critical findings as blockers unless there is a
  documented reason. Note that Semgrep does not ship a dedicated Dart ruleset,
  so coverage relies on OWASP Top Ten, mobile, and secrets packs.
- **gitleaks** — blocks PRs that introduce secrets.
- **Dependabot** — tracks `pub` and `github-actions` updates weekly.

## Phase 2: when format / test / build stop being warn-only

Format check, tests, and the web build currently have `continue-on-error: true`
so they do not block PRs while the baseline is being cleaned up and real test
coverage is being written. Once each is clean, flip `continue-on-error` to
`false` one at a time. If you are fixing baseline debt as part of a dedicated
cleanup PR, say so in the PR title:
`chore(ci): make <area> blocking`.

## Reporting security issues

See [SECURITY.md](SECURITY.md). Do not open public GitHub issues for
vulnerabilities.

## Commit messages

Short, imperative, in present tense. Prefer conventional commit prefixes where
they add clarity (`fix:`, `feat:`, `chore:`, `refactor:`, `docs:`) but don't
force them if the existing history in the area doesn't use them. Explain the
**why** in the body if it isn't obvious from the diff.
