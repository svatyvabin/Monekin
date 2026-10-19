# Git/GitHub branches workflow

As a rule, you as a project collaborator should create working branches (fix/XXXX, feature/XXX....) starting from <code>develop</code>. When you have your collaboration ready, you must make a Pull Request to this branch. Below you have more information about the purpose of each branch.

## Branch resume

<table>
  <thead>
    <tr>
      <th>Branch name</th>
      <th>Description, instructions, notes...</th>
      <th>Protected</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>main</td>
      <td>Only accepts merges from <code>develop</code></td>
      <td>Yes</td>
    </tr>
    <tr>
      <td>develop</td>
      <td>Accepts merges from the working branches (next row)</td>
      <td>Yes</td>
    </tr>
    <tr>
      <td>feature/XXXX, fix/XXXX....</td>
      <td>It originates from <code>develop</code>, and accepts and receives merges from it.</td>
      <td>No</td>
    </tr>
  </tbody>
</table>

### Branch `main`

The default branch of the app. Contains the code of the latest version of the application displayed in the application stores and in the launch section. It is only updated under two circumstances:

- **Merge/Pull request from the <code>develop</code> branch**: When this happens it means that a new version of the application will be created in the release section, and soon it will be available in the app stores.
- **Documentation update or CI/CD update**: Being quick changes that do not affect the deployed version of the app, it is allowed to make commits directly in this branch for this aspect (only for project admins). In this case, a new app version will not be created.

This is a protected branch, so no external code can enter it without the administrators' approval.

### Branch `develop`

Contains code ready to be deployed to the <code>main</code> branch. Changes to this branch are only accepted via Pull Request from the working branches. Administrators will also take care of keeping this branch updated with <code>main</code> branch

Each Pull Request made on this branch will be displayed as a separate item in the description of the version changes in the release section when the branch merges to <code>develop</code>.

Again, this is a protected branch, so no external code can enter it without the administrators' approval.

### Working branches

Branches where the entire development process is carried out, since as seen before, the other branches are only in charge of accepting merges/pull requests with few exceptions. Usually named <code>feature/xxxx</code> or <code>fix/xxxx</code>, but feel free to call them whatever you see fit. Once merged with develop they are deleted from the remote repository.

## Fork workflow (keeping up with upstream)

This repository is a fork. Our own features are developed on top of the original project (`upstream`) while still receiving its new commits.

### One-time setup

```bash
git remote add upstream https://github.com/enrique-lozano/Monekin.git
git remote -v   # origin = our fork, upstream = original project
git config --global rerere.enabled true   # remember conflict resolutions
```

### Fork branches

| Branch | Purpose |
| --- | --- |
| `develop` | Pure mirror of `upstream/develop`. Never commit own code here. |
| `my-main` | Our integration branch: upstream + all our features. Used for daily work and release builds. |
| `feature/xxx` | One branch per own feature, created from `my-main` (or from `develop` if it may be sent upstream). |

### Syncing with upstream

```bash
git fetch upstream

# 1) Update the mirror (fast-forward only, never conflicts)
git checkout develop
git merge --ff-only upstream/develop
git push origin develop

# 2) Bring upstream changes into our integration branch
git checkout my-main
git merge develop
```

- Prefer **merge** (safe, conflicts are solved once, no history rewriting). Use `rebase` + `git push --force-with-lease` only on branches that nobody else uses.
- Sync small and often (e.g. weekly or after each upstream release). The longer you wait, the harder the conflicts.
- After syncing, rebase/merge `my-main` into any in-progress `feature/xxx` branches.

### Reducing merge conflicts

1. Implement features in **new files** whenever possible; only touch upstream files for the minimal wiring (routes, imports, a few lines).
2. Keep each feature in its own small branch.
3. **Never hand-resolve generated files** (`*.g.dart`, `*.freezed.dart`, `translations.g.dart`). Resolve the sources (`.drift`, models, `lib/i18n/json/*.json`) and regenerate:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   dart run slang
   ```
4. **Database schema**: if we change tables while upstream bumps the schema version, the versions and `assets/sql/migrations/vN.sql` will clash. Check both sides before merging and ask the maintainer how to number the migration.

### Verify after every sync

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze && flutter test
```

### Contributing a feature back to upstream

Create a clean branch from the latest `upstream/develop`, add only that feature, and open the PR against upstream's `develop`:

```bash
git checkout -b feature/xxx upstream/develop
git cherry-pick <our feature commits>
```
