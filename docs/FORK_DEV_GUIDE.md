# Fork Development Guide

Rules for developing custom features in this fork while keeping upstream merges cheap.

## 1. Repository and branches

| Item | Convention |
| --- | --- |
| `origin` | This fork |
| `upstream` | The original Monekin repository |
| `main` / `develop` | Mirrors of `upstream/main` / `upstream/develop`. No development here |
| `custom` | Fork mainline: `develop` plus custom features. Builds and releases come from here |
| Feature branches | `my/feature-xxx`, branched from and merged back into `custom` |
| Fixes for upstream | Branch `fix/XXXX` from `upstream/develop`; keep private features out |

```bash
git remote add upstream <upstream-url>
git fetch upstream
git checkout develop && git merge --ff-only upstream/develop
git checkout custom && git merge develop
```

Sync on every upstream release, or every 2-4 weeks at most.

## 2. Code principles

1. Add rather than modify: put custom code in new files/folders (`lib/app/<feature>/`, new `*_service.dart`).
2. Touch upstream files minimally (route registration, menu entry, a single call). No refactors, reformatting or import reordering.
3. Never run `dart format .` on the whole repo; format only the files you changed.
4. Mark every edit to an upstream file with `// FORK: <reason>` so it can be found when merging.
5. Follow existing patterns: singleton services (`._()` + `static final instance`), `lib/core/routes`, Drift streams, `ExpandingSegmentedTabs`, `Logger.printDebug`.

## 3. Generated files

- Never edit `*.g.dart` / `*.freezed.dart`, and never resolve conflicts in them by hand.
- After a merge, take either side, then regenerate:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  dart run slang
  ```
- Commit generated changes separately from feature code.

## 4. Database and migrations

- Upstream migrations are `assets/sql/migrations/vN.sql` with a schema version. A fork adding its own `vN+1` collides with upstream's next version.
- Store custom data in **new tables prefixed `x_`**; do not alter columns of upstream tables.
- Write a migration only when needed. Before writing, check upstream's current version; after merging upstream, re-check numbering.
- Backup/restore must cover custom tables; verify that an old backup imports into the new version.
- If a custom migration is required, record it in `docs/FORK.md`.

## 5. Translations

- Edit only `lib/i18n/json/en.json` (and any extra locale), then run `dart run slang` as the last step.
- Put custom keys under the `fork.*` namespace to avoid collisions with upstream keys.
- No hardcoded user-facing strings.

## 6. App identity (coexist with the official app)

- Change Android `applicationId`, app name and icon.
- Add a suffix to the `pubspec.yaml` version, e.g. `10.2.0+fork.1`.
- No network calls, telemetry or ads.

## 7. Commits

- Follow `docs/COMMIT_MSG.md`.
- One logical change per commit; generated files, translations and feature logic in separate commits.
- AI-assisted commits carry the trailer `Includes-AI-Code: true`.

## 8. Pre-commit checklist

- [ ] `flutter analyze` clean
- [ ] Only changed files formatted
- [ ] Code generation up to date
- [ ] `flutter test` passes; new logic has tests
- [ ] Changed screens verified on Android or Windows
- [ ] Schema changes: upgrade from an old DB and backup restore verified
- [ ] Upstream-file edits are minimal and marked `// FORK:`
- [ ] `docs/FORK.md` change log (and related tables) updated

## 9. Fork ledger

Keep `docs/FORK.md` up to date with: a change log, custom features, modified upstream files, custom tables/migrations, and known behavior differences from upstream.

**Rule:** every functional change (feature, behavior change, fix, schema change) is recorded in the "Change log" of `docs/FORK.md` in the same commit as the code. The change is not complete until the ledger is updated.
