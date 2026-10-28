#!/usr/bin/env bash
# Configures the agent to resolve CocoaPods through Artifactory.
#
# 1. Writes a ~/.netrc entry for the Artifactory host so pod can authenticate.
# 2. Installs the cocoapods-art plugin if missing.
# 3. Registers the Artifactory repo via `pod repo-art add` (idempotent).
# 4. Removes any leftover `cocoapods` git repo from prior bootstrap attempts.
#
# NOTE: We deliberately do NOT touch the `trunk` repo. CocoaPods hardcodes
# trunk's URL to https://cdn.cocoapods.org/ and silently ignores any URL
# passed to `pod repo add-cdn trunk`. The cocoapods-art plugin handles
# routing through Artifactory via the Podfile `plugin 'cocoapods-art'` line.
#
# Args:
#   $1  Artifactory CocoaPods repo URL (defaults to $ARTIFACTORY_PODS_URL)
#   $2  Local repo name to register under (defaults to "artifactory")
#
# Env:
#   ARTIFACTORY_PODS_USER    JFrog username for Basic auth (required for ~/.netrc).
#   ARTIFACTORY_PODS_TOKEN   token used as the password. Falls back to
#                             ARTIFACTORY_NUID_TOKEN if unset.

set -eo pipefail

PODS_URL="${1:-${ARTIFACTORY_PODS_URL:-}}"
PODS_URL="${PODS_URL%/}"   # strip trailing slash so cocoapods-art doesn't produce //
REPO_NAME="${2:-artifactory}"
PODS_USER="${ARTIFACTORY_PODS_USER:-}"
PODS_TOKEN="${ARTIFACTORY_PODS_TOKEN:-${ARTIFACTORY_NUID_TOKEN:-}}"

if [[ -z "${PODS_URL}" ]]; then
    echo "[CocoaPods setup] ARTIFACTORY_PODS_URL is empty — nothing to do."
    exit 0
fi

POD_BIN="${POD_PATH:-/usr/local/bin/pod}"
if [[ ! -x "${POD_BIN}" ]]; then
    POD_BIN="$(command -v pod || true)"
fi
if [[ -z "${POD_BIN}" || ! -x "${POD_BIN}" ]]; then
    echo "[CocoaPods setup] pod binary not found — skipping."
    exit 0
fi

PODS_HOST="$(printf '%s' "${PODS_URL}" | awk -F[/:] '{print $4}')"
echo "[CocoaPods setup] Artifactory host: ${PODS_HOST}"
echo "[CocoaPods setup] Artifactory pods URL: ${PODS_URL}"
echo "[CocoaPods setup] Local repo name: ${REPO_NAME}"

# 1. ~/.netrc entry for the Artifactory host.
# Always rewrite the entry so a stale username/token from a prior build
# doesn't shadow the current credentials.
NETRC="${HOME}/.netrc"
if [[ -n "${PODS_USER}" && -n "${PODS_TOKEN}" ]]; then
    echo "[CocoaPods setup] Writing ${PODS_HOST} entry to ~/.netrc (user: ${PODS_USER})."
    touch "${NETRC}"
    chmod 600 "${NETRC}"
    # Strip any existing entry for this host, then append a fresh one.
    awk -v host="${PODS_HOST}" '
        BEGIN { skip = 0 }
        /^machine[[:space:]]+/ {
            skip = ($2 == host) ? 1 : 0
        }
        skip == 0 { print }
    ' "${NETRC}" > "${NETRC}.tmp" && mv "${NETRC}.tmp" "${NETRC}"
    {
        echo ""
        echo "machine ${PODS_HOST}"
        echo "  login ${PODS_USER}"
        echo "  password ${PODS_TOKEN}"
    } >> "${NETRC}"
    chmod 600 "${NETRC}"
else
    echo "[CocoaPods setup] ARTIFACTORY_PODS_USER or ARTIFACTORY_PODS_TOKEN unset — leaving ~/.netrc untouched."
fi

# 2. Install cocoapods-art plugin if missing.
if "${POD_BIN}" plugins installed 2>/dev/null | grep -qi 'cocoapods-art'; then
    echo "[CocoaPods setup] cocoapods-art plugin already installed."
else
    echo "[CocoaPods setup] Installing cocoapods-art plugin via gem..."
    if ! gem install cocoapods-art --no-document; then
        echo "[CocoaPods setup] ERROR: 'gem install cocoapods-art' failed."
        echo "[CocoaPods setup] If rubygems.org is blocked from this agent,"
        echo "[CocoaPods setup] install the gem manually or via a private gems mirror."
        exit 1
    fi
fi

# 3. Register the Artifactory repo (idempotent).
if "${POD_BIN}" repo-art list 2>/dev/null | grep -qE "^[[:space:]]*-?[[:space:]]*${REPO_NAME}\b"; then
    echo "[CocoaPods setup] Artifactory repo '${REPO_NAME}' already registered."
else
    echo "[CocoaPods setup] Registering Artifactory repo '${REPO_NAME}'."
    "${POD_BIN}" repo-art add "${REPO_NAME}" "${PODS_URL}"
fi

# 4. Remove stale 'cocoapods' git repo from earlier setup attempts.
if "${POD_BIN}" repo list 2>/dev/null | grep -qE '^cocoapods$'; then
    echo "[CocoaPods setup] Removing stale 'cocoapods' git repo."
    "${POD_BIN}" repo remove cocoapods >/dev/null 2>&1 || true
fi

echo "[CocoaPods setup] Done."
echo "[CocoaPods setup] repo-art list:"
"${POD_BIN}" repo-art list 2>/dev/null || true
echo "[CocoaPods setup] repo list:"
"${POD_BIN}" repo list | head -n 20 || true
