#!/usr/bin/env bash
# Wipes the agent's pub cache so the next `flutter pub get` re-downloads
# every package from scratch.
#
# Args:
#   $1  pub cache directory (defaults to $PUB_CACHE, then $HOME/.pub-cache)

set -eo pipefail

PUB_CACHE_DIR="${1:-${PUB_CACHE:-$HOME/.pub-cache}}"

if [[ -z "${PUB_CACHE_DIR}" ]]; then
    echo "[Clean] pub cache path is empty — nothing to clean."
    exit 0
fi

if [[ ! -d "${PUB_CACHE_DIR}" ]]; then
    echo "[Clean] ${PUB_CACHE_DIR} does not exist — nothing to clean."
    exit 0
fi

echo "[Clean] Wiping pub cache at ${PUB_CACHE_DIR}"
rm -rf "${PUB_CACHE_DIR}"
echo "[Clean] Done."
