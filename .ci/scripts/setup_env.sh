#!/usr/bin/env bash
# setup_env.sh — verify the build agent has the toolchain versions required by
# .ci/config/toolchain.yaml. Fails fast with a clear message on mismatch.
#
# Usage:
#   ./.ci/scripts/setup_env.sh
#
# Required env vars: none.
# Optional env vars:
#   STRICT_VERSION_MATCH=1   exact match required (default: prefix match on major.minor.patch)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TOOLCHAIN_FILE="${REPO_ROOT}/.ci/config/toolchain.yaml"

if ! command -v yq >/dev/null 2>&1; then
  echo "ERROR: yq is required but not installed on this agent." >&2
  exit 2
fi

if [[ ! -f "${TOOLCHAIN_FILE}" ]]; then
  echo "ERROR: toolchain config not found at ${TOOLCHAIN_FILE}" >&2
  exit 2
fi

REQ_FLUTTER="$(yq -r '.flutter_version' "${TOOLCHAIN_FILE}")"
REQ_DART="$(yq -r '.dart_version' "${TOOLCHAIN_FILE}")"
REQ_XCODE="$(yq -r '.required_xcode' "${TOOLCHAIN_FILE}")"
REQ_JDK="$(yq -r '.required_jdk' "${TOOLCHAIN_FILE}")"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

check_version() {
  local label="$1" required="$2" actual="$3"
  if [[ "${STRICT_VERSION_MATCH:-0}" == "1" ]]; then
    [[ "${actual}" == "${required}" ]] || fail "${label} version mismatch: required ${required}, got ${actual}"
  else
    [[ "${actual}" == "${required}"* ]] || fail "${label} version mismatch: required ${required} (prefix), got ${actual}"
  fi
}

# Flutter
if ! command -v flutter >/dev/null 2>&1; then
  fail "flutter not found in PATH"
fi
ACTUAL_FLUTTER="$(flutter --version | awk 'NR==1 {print $2}')"
check_version "Flutter" "${REQ_FLUTTER}" "${ACTUAL_FLUTTER}"

# Dart
if ! command -v dart >/dev/null 2>&1; then
  fail "dart not found in PATH"
fi
ACTUAL_DART="$(dart --version 2>&1 | awk '{print $4}')"
check_version "Dart" "${REQ_DART}" "${ACTUAL_DART}"

# Xcode (macOS only)
if [[ "$(uname -s)" == "Darwin" ]]; then
  if ! command -v xcodebuild >/dev/null 2>&1; then
    fail "xcodebuild not found on macOS agent"
  fi
  ACTUAL_XCODE="$(xcodebuild -version | awk 'NR==1 {print $2}')"
  check_version "Xcode" "${REQ_XCODE}" "${ACTUAL_XCODE}"
fi

# JDK
if ! command -v javac >/dev/null 2>&1; then
  fail "javac not found in PATH"
fi
ACTUAL_JDK="$(javac -version 2>&1 | awk '{print $2}')"
check_version "JDK" "${REQ_JDK}" "${ACTUAL_JDK}"

echo "Toolchain verification OK."
echo "Running flutter doctor for visibility:"
flutter doctor -v
