#!/usr/bin/env bash
# generate_build_manifest.sh — emit build/dist/manifest.json capturing the
# full build context for audit. This is the single source of truth for "what
# was in this build" — feature branch, dependency branch, package versions,
# tool versions, artifact hashes, agent identity, triggering user.
#
# Usage:
#   ./.ci/scripts/generate_build_manifest.sh \
#     --feature-branch=feature/foo \
#     --dependency-branch=main \
#     --git-sha=abcdef0 \
#     --build-number=12345 \
#     --flavor=int \
#     --build-type=release
#
# Optional env vars:
#   BUILD_USER, NODE_LABELS, AGENT_LABEL

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DIST_DIR="${REPO_ROOT}/build/dist"
MANIFEST="${DIST_DIR}/manifest.json"

FEATURE_BRANCH=""; DEPENDENCY_BRANCH=""; GIT_SHA=""
BUILD_NUMBER=""; FLAVOR=""; BUILD_TYPE=""

for arg in "$@"; do
  case "${arg}" in
    --feature-branch=*)     FEATURE_BRANCH="${arg#*=}" ;;
    --dependency-branch=*)  DEPENDENCY_BRANCH="${arg#*=}" ;;
    --git-sha=*)            GIT_SHA="${arg#*=}" ;;
    --build-number=*)       BUILD_NUMBER="${arg#*=}" ;;
    --flavor=*)             FLAVOR="${arg#*=}" ;;
    --build-type=*)         BUILD_TYPE="${arg#*=}" ;;
    *) echo "ERROR: unknown arg: ${arg}" >&2; exit 2 ;;
  esac
done

for v in FEATURE_BRANCH DEPENDENCY_BRANCH GIT_SHA BUILD_NUMBER FLAVOR BUILD_TYPE; do
  [[ -n "${!v}" ]] || { echo "ERROR: --${v,,} is required" >&2; exit 2; }
done

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required." >&2; exit 2
fi

mkdir -p "${DIST_DIR}"

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TRIGGERED_BY="${BUILD_USER:-${USER:-unknown}}"
AGENT="${AGENT_LABEL:-${NODE_LABELS:-unknown}}"

# Tool versions (best-effort, never fatal — manifest is a record, not a gate).
FLUTTER_VER="$(flutter --version 2>/dev/null | awk 'NR==1 {print $2}' || echo unknown)"
DART_VER="$(dart --version 2>&1 | awk '{print $4}' || echo unknown)"
JDK_VER="$(javac -version 2>&1 | awk '{print $2}' || echo unknown)"
if [[ "$(uname -s)" == "Darwin" ]] && command -v xcodebuild >/dev/null 2>&1; then
  XCODE_VER="$(xcodebuild -version 2>/dev/null | awk 'NR==1 {print $2}' || echo unknown)"
else
  XCODE_VER="n/a"
fi

# Resolved package versions from pubspec.lock.
PACKAGES_JSON="{}"
if [[ -f "${REPO_ROOT}/pubspec.lock" ]] && command -v yq >/dev/null 2>&1; then
  PACKAGES_JSON="$(yq -o=json '.packages | to_entries | map({(.key): .value.version}) | add // {}' "${REPO_ROOT}/pubspec.lock")"
fi

# Artifact list from build/dist/{android,ios}/.
ARTIFACTS_JSON="[]"
if compgen -G "${DIST_DIR}/android/*" > /dev/null || compgen -G "${DIST_DIR}/ios/*" > /dev/null; then
  ARTIFACTS_JSON="$(
    {
      shopt -s nullglob
      for f in "${DIST_DIR}/android"/* "${DIST_DIR}/ios"/*; do
        [[ -f "${f}" && "${f}" != *.sha256 ]] || continue
        sha="$(cat "${f}.sha256" 2>/dev/null || true)"
        if [[ -z "${sha}" ]]; then
          if command -v sha256sum >/dev/null 2>&1; then
            sha="$(sha256sum "${f}" | awk '{print $1}')"
          else
            sha="$(shasum -a 256 "${f}" | awk '{print $1}')"
          fi
        fi
        printf '{"file":"%s","sha256":"%s","size":%d}\n' \
          "$(basename "${f}")" "${sha}" "$(wc -c < "${f}")"
      done
    } | jq -s '.'
  )"
fi

jq -n \
  --arg timestamp "${TIMESTAMP}" \
  --arg feature_branch "${FEATURE_BRANCH}" \
  --arg dependency_branch "${DEPENDENCY_BRANCH}" \
  --arg git_sha "${GIT_SHA}" \
  --arg build_number "${BUILD_NUMBER}" \
  --arg flavor "${FLAVOR}" \
  --arg build_type "${BUILD_TYPE}" \
  --arg triggered_by "${TRIGGERED_BY}" \
  --arg agent "${AGENT}" \
  --arg flutter "${FLUTTER_VER}" \
  --arg dart "${DART_VER}" \
  --arg xcode "${XCODE_VER}" \
  --arg jdk "${JDK_VER}" \
  --argjson packages "${PACKAGES_JSON}" \
  --argjson artifacts "${ARTIFACTS_JSON}" \
  '{
    schema_version: 1,
    timestamp: $timestamp,
    build: {
      feature_branch: $feature_branch,
      dependency_branch: $dependency_branch,
      git_sha: $git_sha,
      build_number: $build_number,
      flavor: $flavor,
      build_type: $build_type
    },
    triggered_by: $triggered_by,
    agent: $agent,
    toolchain: {
      flutter: $flutter,
      dart: $dart,
      xcode: $xcode,
      jdk: $jdk
    },
    packages: $packages,
    artifacts: $artifacts
  }' > "${MANIFEST}"

echo "Wrote ${MANIFEST}"
