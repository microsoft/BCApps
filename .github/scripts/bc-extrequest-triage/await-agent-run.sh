#!/usr/bin/env bash
set -euo pipefail

: "${AGENT_REPO:?AGENT_REPO must be set}"
: "${AGENT_WORKFLOW:?AGENT_WORKFLOW must be set}"
: "${RUN_TOKEN:?RUN_TOKEN must be set}"

run_list_limit=${RUN_LIST_LIMIT:-100}
poll_attempts=${POLL_ATTEMPTS:-30}
poll_interval_seconds=${POLL_INTERVAL_SECONDS:-10}
watch_interval_seconds=${WATCH_INTERVAL_SECONDS:-10}

run_id=""
for ((attempt = 1; attempt <= poll_attempts; attempt++)); do
  run_id=$(gh run list -R "$AGENT_REPO" --workflow "$AGENT_WORKFLOW" \
    --json databaseId,displayTitle -L "$run_list_limit" \
    -q "[.[] | select(.displayTitle | contains(\"[$RUN_TOKEN]\"))][0].databaseId")
  if [ -n "$run_id" ] && [ "$run_id" != "null" ]; then
    break
  fi
  sleep "$poll_interval_seconds"
done

if [ -z "$run_id" ] || [ "$run_id" = "null" ]; then
  echo "::error::Timed out waiting for $AGENT_WORKFLOW run [$RUN_TOKEN] to appear."
  exit 1
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "run_id=$run_id" >> "$GITHUB_OUTPUT"
fi

gh run watch "$run_id" -R "$AGENT_REPO" --interval "$watch_interval_seconds"
