# Running this fork

This is a personal fork, built and installed by hand and kept in step with upstream. Upstream is
[`abue-ammar/tinycast`](https://github.com/abue-ammar/tinycast); nothing here is a change to how the
app itself works, only to how this copy is maintained.

## Branches

| Branch | What it is |
| --- | --- |
| `main` | The app I actually run. My commits sit on top of upstream, rebased. Force-pushed. |
| `upstream-sync` | A throwaway integration branch, recreated from `main` each cycle. Conflicts get resolved and the build gets verified **here**, so `main` stays runnable the whole time. |
| `fix/*` | A patch offered back upstream. Branched from `upstream/main` and cherry-picked, never from `main` — a branch cut from `main` would carry every local feature into the PR. |

One-time setup:

```sh
git remote -v                       # origin = the fork, upstream = abue-ammar/tinycast
git config rerere.enabled true      # remembers a conflict resolution across a retried rebase
```

## Syncing

`upstream-sync` starts from `main`, not from `upstream/main` — that is what makes it an integration
branch rather than a mirror of upstream.

```sh
git fetch upstream
git switch -C upstream-sync main
git rebase upstream/main            # resolve, then build and test here
```

If `fetch` reports a forced update, the old and new upstream histories may share an ancient base.
Find the old upstream tip that `main` was built on (`git reflog show upstream/main` and
`git log --oneline main`), then replay only the fork commits after it:

```sh
git rebase --onto upstream/main <old-upstream-tip> upstream-sync
```

Green — move `main` over. `merge --ff-only` cannot do this: the rebase rewrote history, so `main` is
no longer an ancestor.

```sh
git switch main
git reset --hard upstream-sync
git push --force-with-lease origin main
```

Bad — drop it and lose nothing, because `main` was never touched.

```sh
git rebase --abort && git switch main
```

A local commit that upstream later merges disappears on its own: `rebase` matches it by patch id and
drops the duplicate.

## Building and installing

```sh
./Scripts/run-tests.sh
./Scripts/build-dmg.sh 0.12.0       # choose a version above the newest upstream tag
cp -R build/DerivedData/Build/Products/Release/Tinycast.app /Applications/
```

## What to watch for

- **The `Tinycast Self-Signed` identity is created once** ([signing.md](signing.md) §1) — without it
  no configuration builds, because `project.yml` pins `CODE_SIGN_IDENTITY`.
- **Use `/usr/bin/openssl` for the `pkcs12` step.** Homebrew's OpenSSL 3.x writes a SHA-256 MAC that
  `security import` rejects with `MAC verification failed`; the system LibreSSL writes one it accepts.
- **Pass a version above every upstream tag.** The default `MARKETING_VERSION` is the `0.1.0`
  placeholder CI overrides, and leaving it makes the updater report an update on every launch.
- **The in-app updater cannot install an upstream release.** It only accepts a bundle carrying the
  running app's own leaf certificate, and this one is signed with a local identity. Turn the update
  check off and re-sync instead.
- **Release builds keep the `com.tinycast.app` bundle id**, so `brew install --cask tinycast` would
  overwrite this copy. Debug is a separate channel (`Tinycast Dev.app`) and never collides.
- **This file and its two links are fork-only**, so they conflict whenever upstream edits the doc
  tables. `rerere` resolves it after the first time.
