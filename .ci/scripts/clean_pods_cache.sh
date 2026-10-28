#!/usr/bin/env bash
# Deletes only podspec JSON files in the CocoaPods trunk cache that can't be
# parsed as JSON. Leaves everything else in place so it survives agents that
# can't refill from the CocoaPods CDN.
#
# Args:
#   $1  cocoapods trunk repo path (defaults to $HOME/.cocoapods/repos/trunk)

set -eo pipefail

TRUNK_DIR="${1:-$HOME/.cocoapods/repos/trunk}"

if [[ ! -d "${TRUNK_DIR}" ]]; then
    echo "[Clean] ${TRUNK_DIR} does not exist — nothing to clean."
    exit 0
fi

REMOVED=0
SCANNED=0
while IFS= read -r -d '' f; do
    SCANNED=$((SCANNED + 1))
    if ! ruby -rjson -e "JSON.parse(File.read(ARGV[0]))" "$f" >/dev/null 2>&1; then
        echo "[Clean] removing corrupt $f"
        rm -f "$f"
        REMOVED=$((REMOVED + 1))
    fi
done < <(find "${TRUNK_DIR}" -type f -name '*.podspec.json' -print0)

echo "[Clean] scanned ${SCANNED} files, removed ${REMOVED} corrupt."
