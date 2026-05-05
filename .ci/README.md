# `.ci/` — Repo-Based CI/CD for the Banking App

## Philosophy

Jenkinsfiles are **thin orchestrators**. All real build logic lives in
`.ci/scripts/*.sh` so the same commands a Jenkins agent runs can be run
locally on a developer laptop, and so we can migrate off Jenkins later
without rewriting the build.

If you find yourself writing logic in a Jenkinsfile beyond stage layout,
parameter wiring, and credential injection — stop and put it in a script.

## Layout

```
.ci/
├── Jenkinsfile.pr           # PR validation (placeholder; replaces /Jenkinsfile)
├── Jenkinsfile.release      # Monthly release/* branch builds, all flavors
├── Jenkinsfile.futuretest   # On-demand future-pool branch testing
├── Jenkinsfile.branchtest   # On-demand stable-pool branch testing
├── Jenkinsfile.web          # Web deployment (placeholder; replaces /integ_build.groovy)
├── scripts/                 # All build logic, callable locally
└── config/                  # Flavor / toolchain / agent-pool YAML

vars/
└── buildFlutterFlavor.groovy   # Jenkins shared-library wrapper
```

## Pipelines at a glance

| Pipeline                | Trigger                              | Pool                  | Flavors        | Build type | Distributes to     |
|-------------------------|--------------------------------------|-----------------------|----------------|------------|--------------------|
| `Jenkinsfile.pr`        | (placeholder, replaces `/Jenkinsfile`) | flutter-stable-pool   | n/a            | debug      | n/a                |
| `Jenkinsfile.release`   | Push to `release/*`                  | flutter-stable-pool   | qa, int, prod  | release    | qa-integration, prod-staging |
| `Jenkinsfile.futuretest`| Manual (Build with Parameters)       | flutter-future-pool   | int            | release/debug | future-test     |
| `Jenkinsfile.branchtest`| Manual                               | flutter-stable-pool   | qa             | debug/release | dev-self        |
| `Jenkinsfile.web`       | (placeholder, replaces `/integ_build.groovy`) | flutter-stable-pool | n/a    | n/a        | n/a                |

## Running a build locally

The same scripts Jenkins runs work on a developer laptop. Example:

```sh
./.ci/scripts/setup_env.sh

./.ci/scripts/build_android.sh \
  --flavor=qa \
  --build-type=debug \
  --build-number=local-1 \
  --git-sha=$(git rev-parse --short HEAD) \
  --suffix=local-test

# Build manifest (audit trail):
./.ci/scripts/generate_build_manifest.sh \
  --feature-branch=$(git rev-parse --abbrev-ref HEAD) \
  --dependency-branch=main \
  --git-sha=$(git rev-parse --short HEAD) \
  --build-number=local-1 \
  --flavor=qa \
  --build-type=debug
```

Outputs land in `build/dist/`. Each artifact has a `.sha256` sidecar.

## Required environment variables

| Script                          | Required env                                                      |
|---------------------------------|-------------------------------------------------------------------|
| `setup_env.sh`                  | _none_ (optional: `STRICT_VERSION_MATCH=1`)                       |
| `setup_dependencies.sh`         | `ARTIFACTORY_URL`, `ARTIFACTORY_USER`, `ARTIFACTORY_TOKEN`, `ARTIFACTORY_REPO` |
| `verify_artifactory_branch.sh`  | same as `setup_dependencies.sh`                                   |
| `build_android.sh` (release)    | `KEYSTORE_FILE`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` |
| `build_ios.sh` (release)        | keychain provisioned via `ios_keychain_setup.sh`; `ios/ExportOptions-${FLAVOR}.plist` present |
| `ios_keychain_setup.sh`         | _argv_: P12 file, P12 password, provisioning profile path        |
| `generate_build_manifest.sh`    | optional: `BUILD_USER`, `NODE_LABELS`, `AGENT_LABEL`              |

Secrets are **never echoed**. Build scripts read them from env or argv only.

## Adding a new flavor

1. Add an entry to `.ci/config/flavors.yaml` with all required fields.
2. Add `ios/ExportOptions-<flavor>.plist` matching the new flavor.
3. Add a matching Android product flavor in `android/app/build.gradle`.
4. Update `vars/buildFlutterFlavor.groovy` validation list (`'qa', 'int', 'prod'` → add the new one).
5. Update `build_android.sh` and `build_ios.sh` validation case statements.
6. Add the new flavor to `Jenkinsfile.release` parallel build matrix if it should
   ship every release; otherwise leave it for on-demand pipelines.
7. Wire any new Jenkins credentials (signing certs, provisioning profile) and
   reference them by `<credentialId>-<flavor>` convention used in
   `buildFlutterFlavor.groovy`.

## Bumping the toolchain

1. Update `.ci/config/toolchain.yaml`.
2. Update the agent images for the relevant pool (separate infra repo).
3. Run `Jenkinsfile.futuretest` first against the future pool to flush out
   issues before the bump lands on the stable pool.

## Migration status

- Existing `/Jenkinsfile` and `/integ_build.groovy` are still authoritative.
- `.ci/Jenkinsfile.pr` and `.ci/Jenkinsfile.web` are placeholders with TODO
  checklists for cutover.
- Cutover is handled separately — do not switch Jenkins jobs to point at the
  new files until the placeholder TODO lists have been worked through.

## Conventions

- All shell scripts use `set -euo pipefail` and are executable.
- YAML is parsed with `yq`; JSON with `jq`. Both must be on agent images.
- Cross-platform sha256: `sha256sum` on Linux, `shasum -a 256` on macOS.
- Artifact naming: `bankingapp-${FLAVOR}-${SUFFIX}.{aab|apk|ipa|app.zip}`.
- Symbol bundles: `bankingapp-${FLAVOR}-${SUFFIX}-symbols.zip`.
- Audit trail: every build emits `build/dist/manifest.json`.

## Out of scope (follow-up tasks)

- SBOM generation
- MobSF / static security scan implementation (placeholder only)
- Crash symbol upload to Crashlytics / App Store Connect
- Real distribution implementation (Firebase App Distribution, etc.)
- Notifications (Teams / Slack)
- Tests for the build scripts themselves
