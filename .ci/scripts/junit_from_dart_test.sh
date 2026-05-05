#!/usr/bin/env bash
# junit_from_dart_test.sh — convert `dart test --machine` JSON output to a
# JUnit XML file suitable for Jenkins' JUnit publisher.
#
# Usage:
#   dart test --machine > test-results.json
#   ./.ci/scripts/junit_from_dart_test.sh test-results.json test-results.xml
#
# Required deps: jq, awk. No external test-converter binary required.

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <input.json> <output.xml>" >&2
  exit 2
fi

INPUT="$1"
OUTPUT="$2"

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required." >&2; exit 2
fi
[[ -f "${INPUT}" ]] || { echo "ERROR: input not found: ${INPUT}" >&2; exit 1; }

# Build a flat list of test results, then collapse into JUnit.
# `dart test --machine` emits one JSON event per line.
jq -s --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
  # Index tests by id from testStart events.
  ( [ .[] | select(.type == "testStart") | .test ]
    | map({(.id|tostring): {name: .name, group: (.groupIDs // []), suite: .url}})
    | add // {}
  ) as $tests
  |
  # Collect testDone events with status info.
  [ .[] | select(.type == "testDone") ] as $done
  |
  # Collect error events keyed by testID.
  ( [ .[] | select(.type == "error") ]
    | group_by(.testID)
    | map({(.[0].testID|tostring): map({error, stackTrace})})
    | add // {}
  ) as $errors
  |
  {
    timestamp: $timestamp,
    cases: ($done | map(
      . as $d
      | ($tests[($d.testID|tostring)] // {}) as $t
      | ($errors[($d.testID|tostring)] // []) as $errs
      | {
          name: ($t.name // "unknown"),
          time_ms: (($d.time // 0) - ($d.startTime // 0)),
          status: $d.result,
          hidden: ($d.hidden // false),
          errors: $errs
        }
    ))
  }
' "${INPUT}" > "${INPUT}.normalized.json"

python3 - "${INPUT}.normalized.json" "${OUTPUT}" <<'PY'
import json, sys, html, time

src, dst = sys.argv[1], sys.argv[2]
with open(src) as f:
    data = json.load(f)

cases = [c for c in data["cases"] if not c.get("hidden")]
total = len(cases)
failures = sum(1 for c in cases if c["status"] == "failure")
errors   = sum(1 for c in cases if c["status"] == "error")
skipped  = sum(1 for c in cases if c["status"] == "skipped")
total_time = sum(max(c.get("time_ms") or 0, 0) for c in cases) / 1000.0

def esc(s): return html.escape(str(s), quote=True)

out = []
out.append('<?xml version="1.0" encoding="UTF-8"?>')
out.append(
    f'<testsuite name="dart-test" tests="{total}" failures="{failures}" '
    f'errors="{errors}" skipped="{skipped}" time="{total_time:.3f}" '
    f'timestamp="{esc(data["timestamp"])}">'
)
for c in cases:
    name = esc(c["name"])
    t = max(c.get("time_ms") or 0, 0) / 1000.0
    out.append(f'  <testcase classname="dart" name="{name}" time="{t:.3f}">')
    if c["status"] == "failure" or c["status"] == "error":
        for e in c.get("errors") or [{"error": c["status"], "stackTrace": ""}]:
            tag = "failure" if c["status"] == "failure" else "error"
            msg = esc(e.get("error") or c["status"])
            stack = esc(e.get("stackTrace") or "")
            out.append(f'    <{tag} message="{msg}"><![CDATA[{stack}]]></{tag}>')
    elif c["status"] == "skipped":
        out.append('    <skipped/>')
    out.append('  </testcase>')
out.append('</testsuite>')

with open(dst, "w") as f:
    f.write("\n".join(out))
PY

rm -f "${INPUT}.normalized.json"
echo "Wrote ${OUTPUT}"
