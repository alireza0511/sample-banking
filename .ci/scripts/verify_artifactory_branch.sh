#!/usr/bin/env bash
# verify_artifactory_branch.sh — pre-flight check for futuretest pipeline.
# Confirms Artifactory has at least one banking_* artifact for the branch
# slug before we burn agent time on a build that is going to fail at
# dependency resolution.
#
# Usage:
#   ./.ci/scripts/verify_artifactory_branch.sh <branch>
#
# Required env vars: ARTIFACTORY_URL, ARTIFACTORY_USER, ARTIFACTORY_TOKEN, ARTIFACTORY_REPO

set -euo pipefail

BRANCH="${1:-}"
if [[ -z "${BRANCH}" ]]; then
  echo "Usage: $0 <branch>" >&2
  exit 2
fi

: "${ARTIFACTORY_URL:?ARTIFACTORY_URL is required}"
: "${ARTIFACTORY_USER:?ARTIFACTORY_USER is required}"
: "${ARTIFACTORY_TOKEN:?ARTIFACTORY_TOKEN is required}"
: "${ARTIFACTORY_REPO:?ARTIFACTORY_REPO is required}"

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required." >&2
  exit 2
fi

BRANCH_SLUG="$(echo "${BRANCH}" | tr '/' '-' | tr '[:upper:]' '[:lower:]')"

api="${ARTIFACTORY_URL%/}/api/search/artifact?name=banking_&repos=${ARTIFACTORY_REPO}"
response="$(curl -sS --fail \
  -u "${ARTIFACTORY_USER}:${ARTIFACTORY_TOKEN}" \
  -H "Accept: application/json" \
  "${api}")"

count="$(echo "${response}" | jq --arg slug "${BRANCH_SLUG}" '
  [.results[]? | select(.uri | contains("/" + $slug + "/"))] | length
')"

if [[ "${count}" -eq 0 ]]; then
  echo "ERROR: Artifactory has no banking_* artifacts for branch '${BRANCH}' (slug '${BRANCH_SLUG}')." >&2
  echo "       Publish dependency snapshots before running this pipeline." >&2
  exit 1
fi

echo "OK: found ${count} matching artifact(s) for branch '${BRANCH}'."
