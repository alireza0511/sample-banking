#!/usr/bin/env bash
# Rewrites cached pub versions.json entries whose containing-package's pubspec
# declares a dependency as { path: ... } instead of a hosted version string.
# Each broken dep is rewritten to a hosted version constraint so
# `flutter pub get` can resolve the package.
#
# Args:
#   $1  pub cache root (directory; trailing slash optional)
#
# Env-var overrides (defaults below):
#   WALLET_ACCESS_PLATFORM_INTERFACE_VERSION  default ^1.0.0
#   CHECK_DEPOSIT_ANDROID_VERSION             default 5.8.3
#   CHECK_DEPOSIT_IOS_VERSION                 default 4.9.2
#   CHECK_DEPOSIT_PLATFORM_INTERFACE_VERSION  default 0.0.1
#
# NOTE: Only patches versions.json files already in the pub cache. On a cold
# agent, there is nothing to patch and the next stage will hit the original
# parse error — re-run the build so the second attempt has a warm cache.

set -eo pipefail

PUB_CACHE_ROOT="${1:-$HOME/.pub-cache/}"
[[ "${PUB_CACHE_ROOT}" != */ ]] && PUB_CACHE_ROOT="${PUB_CACHE_ROOT}/"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# (containing-package | broken-dep-name | replacement-version)
PATCH_TARGETS=(
    "wallet_access_android|wallet_access_platform_interface|${WALLET_ACCESS_PLATFORM_INTERFACE_VERSION:-^1.0.0}"
    "check_deposit|check_deposit_android|${CHECK_DEPOSIT_ANDROID_VERSION:-5.8.3}"
    "check_deposit|check_deposit_ios|${CHECK_DEPOSIT_IOS_VERSION:-4.9.2}"
    "check_deposit|check_deposit_platform_interface|${CHECK_DEPOSIT_PLATFORM_INTERFACE_VERSION:-0.0.1}"
)

HOSTED="${PUB_CACHE_ROOT}hosted"
if [[ ! -d "${HOSTED}" ]]; then
    echo "[Patch] No hosted cache — nothing to patch."
    exit 0
fi

for target in "${PATCH_TARGETS[@]}"; do
    IFS='|' read -r pkg dep ver <<< "${target}"
    echo "[Patch] ${pkg}-versions.json :: ${dep} -> ${ver}"

    VFILES=()
    while IFS= read -r -d '' vf; do
        VFILES+=("$vf")
    done < <(find "${HOSTED}" -type f -path "*/.cache/${pkg}-versions.json" -print0 2>/dev/null)

    if [[ ${#VFILES[@]} -eq 0 ]]; then
        echo "[Patch]   no ${pkg}-versions.json files in cache — skipping."
        continue
    fi

    for vf in "${VFILES[@]}"; do
        ruby "${SCRIPT_DIR}/patch_pubcache_path_dep.rb" "${vf}" "${dep}" "${ver}"
    done
done

echo "[Patch] Done."
