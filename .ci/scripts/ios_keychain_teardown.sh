#!/usr/bin/env bash
# ios_keychain_teardown.sh — delete the ephemeral signing keychain created by
# ios_keychain_setup.sh. Idempotent — safe to run if setup never executed.
#
# Usage:
#   ./.ci/scripts/ios_keychain_teardown.sh
#
# Required env vars: none. Reads keychain name from /tmp/build-keychain-name.

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  exit 0
fi

KEYCHAIN_FILE=/tmp/build-keychain-name
if [[ ! -f "${KEYCHAIN_FILE}" ]]; then
  echo "No build keychain to tear down."
  exit 0
fi

KEYCHAIN_NAME="$(cat "${KEYCHAIN_FILE}")"
if [[ -z "${KEYCHAIN_NAME}" ]]; then
  rm -f "${KEYCHAIN_FILE}"
  exit 0
fi

if security delete-keychain "${KEYCHAIN_NAME}" 2>/dev/null; then
  echo "Deleted ephemeral keychain."
else
  echo "Keychain already gone or never created — continuing."
fi

rm -f "${KEYCHAIN_FILE}"
