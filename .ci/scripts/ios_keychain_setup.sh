#!/usr/bin/env bash
# ios_keychain_setup.sh — provision an ephemeral keychain for iOS signing.
# Imports the signing certificate and installs the provisioning profile.
# Writes the keychain name to /tmp/build-keychain-name for teardown.
#
# Usage:
#   ./.ci/scripts/ios_keychain_setup.sh <P12_FILE> <P12_PASSWORD> <PROVISIONING_PROFILE>
#
# Note: do not echo P12_PASSWORD. Pass it via env var or argv from withCredentials.

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: keychain setup only valid on macOS." >&2
  exit 2
fi

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <P12_FILE> <P12_PASSWORD> <PROVISIONING_PROFILE>" >&2
  exit 2
fi

P12_FILE="$1"
P12_PASSWORD="$2"
PROVISIONING_PROFILE="$3"

[[ -f "${P12_FILE}" ]] || { echo "ERROR: P12 file not found." >&2; exit 1; }
[[ -f "${PROVISIONING_PROFILE}" ]] || { echo "ERROR: provisioning profile not found." >&2; exit 1; }

# Generate random keychain name + password.
KEYCHAIN_NAME="build-$(uuidgen | tr '[:upper:]' '[:lower:]').keychain-db"
KEYCHAIN_PASSWORD="$(uuidgen)"

echo "Creating ephemeral keychain..."
security create-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_NAME}"
security set-keychain-settings -lut 21600 "${KEYCHAIN_NAME}"
security unlock-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_NAME}"

# Add to user keychain search list (preserving existing entries).
EXISTING="$(security list-keychains -d user | sed -e 's/^[[:space:]]*//' -e 's/"//g' | tr '\n' ' ')"
# shellcheck disable=SC2086
security list-keychains -d user -s "${KEYCHAIN_NAME}" ${EXISTING}

echo "Importing certificate..."
security import "${P12_FILE}" \
  -k "${KEYCHAIN_NAME}" \
  -P "${P12_PASSWORD}" \
  -T /usr/bin/codesign \
  -T /usr/bin/security \
  -T /usr/bin/productbuild

# Allow codesign to access the key without a UI prompt.
security set-key-partition-list \
  -S apple-tool:,apple:,codesign: \
  -s -k "${KEYCHAIN_PASSWORD}" \
  "${KEYCHAIN_NAME}" >/dev/null

# Install provisioning profile.
PROFILE_DEST="${HOME}/Library/MobileDevice/Provisioning Profiles"
mkdir -p "${PROFILE_DEST}"
PROFILE_UUID="$(security cms -D -i "${PROVISIONING_PROFILE}" \
  | /usr/libexec/PlistBuddy -c 'Print :UUID' /dev/stdin)"
cp "${PROVISIONING_PROFILE}" "${PROFILE_DEST}/${PROFILE_UUID}.mobileprovision"

# Hand off keychain identity to subsequent scripts.
echo "${KEYCHAIN_NAME}" > /tmp/build-keychain-name
export KEYCHAIN_NAME

echo "Keychain ready (name redacted in logs)."
echo "Provisioning profile installed: ${PROFILE_UUID}"
