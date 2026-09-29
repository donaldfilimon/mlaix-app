# Self-hosted CI runner

The GitHub Actions billing for the `donaldfilimon` account is locked, so every
GitHub-hosted job fails within seconds without being assigned a runner.
Self-hosted jobs still run. `CI / build-and-test` therefore runs on a macOS
arm64 runner registered to this repository.

## Labels

The job uses `runs-on: [self-hosted, macOS, ARM64, mlaix-app]`.
`self-hosted`, `macOS` and `ARM64` are added automatically when a runner is
registered on an Apple silicon Mac. `mlaix-app` is a custom label: add it
during registration (or later under the runner's settings). actionlint is told
about it in `.github/actionlint.yaml`.

## Registering the runner

1. Open **Settings → Actions → Runners → New self-hosted runner** in this
   repository and choose **macOS** and **ARM64**.
2. Follow the download and `./config.sh` steps shown there. When asked for
   additional labels, enter `mlaix-app`.
3. Start it with `./run.sh`, or install it as a per-user service with
   `./svc.sh install && ./svc.sh start` (a LaunchAgent for the logged-in
   user, not a LaunchDaemon; see prerequisites below).

A runner is registered to one repository. If the Mac already serves another
repository (for example `abi`, `gama` or `mlai-website-app`), download and
configure a second copy of the runner in its own directory, such as
`~/actions-runner-mlaix-app`, and register that copy here. Each directory keeps
its own `.runner` configuration, `_work` folder and service.

Until a runner with these labels is online, `build-and-test` stays queued.

## Host prerequisites

- **Xcode 26 or later with Swift 6.3 or later**, selected as the active
  developer directory (`sudo xcode-select -s /Applications/Xcode.app` once, by
  hand). `Package.swift` declares `swift-tools-version: 6.3` and every
  platform at version 26. The workflow prints `xcode-select -p` and
  `swift --version` but never changes them, because that needs sudo and would
  affect the whole machine. Accept the Xcode license and run
  `xcodebuild -runFirstLaunch` once.
- **Apple silicon** (the app requires it on macOS) running macOS 26 or later,
  so the macOS product can be built and the test bundle can load.
- **Git LFS** (`brew install git-lfs && git lfs install`). The checkout uses
  `lfs: true` for the Slide Studio `marp` binary.
- Network access to GitHub for the SwiftPM dependencies in `Package.resolved`.
- An unlocked login keychain for the runner user: `KeychainHelperTests` writes
  and deletes uniquely named test items. Running the runner as a LaunchAgent
  of a logged-in user (or with `./run.sh` in a session) provides this; a
  LaunchDaemon does not.
- Disk space for `.build` (several GB with release and debug builds).

## Security model

A self-hosted runner executes the workflow's code on your Mac with your user's
access. The job only runs on trusted events:

```yaml
if: >
  github.repository == 'donaldfilimon/mlaix-app' &&
  (github.event_name == 'push' ||
   (github.event_name == 'pull_request' &&
    github.event.pull_request.head.repo.full_name == github.repository))
```

- `push` to `main` and pull requests whose head branch lives in this
  repository run self-hosted. Only people with write access can create those.
- Pull requests from forks never reach the Mac. They run
  `build-and-test (GitHub-hosted, fork PRs)`, an unchanged copy of the
  original job on `macos-15` (it cannot run while billing is locked, but it
  keeps the Mac isolated from untrusted code).
- The `github.repository` check keeps forks of this repository that enable
  Actions from targeting a runner label they do not own.
- The workflow has `permissions: contents: read`, and the self-hosted checkout
  uses `persist-credentials: false`, so the token is not left in the working
  copy's git config.
- No job here is triggered by `pull_request_target`, `issue_comment` or
  `workflow_run`. Do not add such triggers to a self-hosted job.

In repository settings, also consider **Actions → General → Fork pull request
workflows → Require approval for all outside collaborators**.

## Jobs that stay GitHub-hosted

- `build-and-test-hosted` — `build-and-test (GitHub-hosted, fork PRs)`: runs
  only for pull requests from forks, by design.

Every other job in this repository runs on the self-hosted runner.
