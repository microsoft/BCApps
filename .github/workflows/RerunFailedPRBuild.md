---
description: Analyzes failed Pull Request Build jobs for transient instabilities and reruns them when appropriate, posting a diagnostic comment on the PR
on:
  workflow_run:
    workflows: ['Pull Request Build']
    types: [completed]

permissions:
  actions: read
  contents: read
  pull-requests: read
  checks: read

engine: copilot

tools:
  github:
    toolsets: [default, actions]
  bash: ["gh"]

safe-outputs:
  rerun-failed-jobs:
    max: 1
  add-comment:
    max: 1
    hide-older-comments: true
  noop:
    max: 1
  messages:
    footer: "> 🔄 *Analysis by [{workflow_name}]({run_url})*"
    run-started: "🔍 Analyzing failed PR Build [{workflow_name}]({run_url})..."
    run-success: "✅ [{workflow_name}]({run_url}) has completed analysis."
    run-failure: "❌ [{workflow_name}]({run_url}) encountered an error during analysis."

timeout-minutes: 10

steps:
  - name: Gather failed job information
    if: github.event.workflow_run.conclusion == 'failure' && github.event.workflow_run.event == 'pull_request'
    env:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      RUN_ID: ${{ github.event.workflow_run.id }}
      REPO: ${{ github.repository }}
    run: |
      set -e
      WORK_DIR="/tmp/rerun-analyzer"
      LOG_DIR="$WORK_DIR/logs"
      FILTERED_DIR="$WORK_DIR/filtered"
      mkdir -p "$LOG_DIR" "$FILTERED_DIR"

      echo "=== Rerun Analyzer: Gathering info for run $RUN_ID ==="

      # Get the run attempt number
      RUN_ATTEMPT=$(gh api "repos/$REPO/actions/runs/$RUN_ID" --jq '.run_attempt')
      echo "Run attempt: $RUN_ATTEMPT" > "$WORK_DIR/run-info.txt"
      echo "Run ID: $RUN_ID" >> "$WORK_DIR/run-info.txt"

      # Get PR number from the workflow run
      PR_NUMBER=$(gh api "repos/$REPO/actions/runs/$RUN_ID" --jq '.pull_requests[0].number // empty')
      echo "PR number: ${PR_NUMBER:-none}" >> "$WORK_DIR/run-info.txt"

      if [ -z "$PR_NUMBER" ]; then
        echo "No PR associated with this run, nothing to do."
        echo "NO_PR=true" >> "$WORK_DIR/run-info.txt"
        exit 0
      fi

      # Get all failed jobs
      gh api "repos/$REPO/actions/runs/$RUN_ID/jobs?filter=latest&per_page=100" \
        --jq '[.jobs[] | select(.conclusion == "failed") | {id:.id, name:.name, conclusion:.conclusion, failed_steps:[.steps[]? | select(.conclusion=="failure") | .name]}]' \
        > "$LOG_DIR/failed-jobs.json"

      FAILED_COUNT=$(jq 'length' "$LOG_DIR/failed-jobs.json")
      echo "Failed job count: $FAILED_COUNT" >> "$WORK_DIR/run-info.txt"
      echo "Found $FAILED_COUNT failed job(s)"

      if [ "$FAILED_COUNT" -eq 0 ]; then
        echo "No failed jobs found."
        exit 0
      fi

      echo "Failed jobs:"
      jq -r '.[] | "  Job \(.id): \(.name) — failed steps: \(.failed_steps | join(", "))"' "$LOG_DIR/failed-jobs.json"

      # Download logs for each failed job
      jq -r '.[].id' "$LOG_DIR/failed-jobs.json" | while read -r JOB_ID; do
        LOG_FILE="$LOG_DIR/job-${JOB_ID}.log"
        echo "Downloading log for job $JOB_ID..."
        gh api "repos/$REPO/actions/jobs/$JOB_ID/logs" > "$LOG_FILE" 2>/dev/null \
          || echo "(log download failed)" > "$LOG_FILE"

        # Keep only the last 200 lines per job
        tail -200 "$LOG_FILE" > "$LOG_FILE.trimmed" && mv "$LOG_FILE.trimmed" "$LOG_FILE"
        echo "  -> Saved $(wc -l < "$LOG_FILE") lines to $LOG_FILE"

        # Apply error heuristics
        HINTS_FILE="$FILTERED_DIR/job-${JOB_ID}-hints.txt"
        grep -n -iE "(error[: ]|ERROR|FAIL|panic:|fatal[: ]|exception|exit status [1-9]|timeout|timed out|connection refused|cannot access|rate limit)" \
          "$LOG_FILE" | head -30 > "$HINTS_FILE" 2>/dev/null || true

        if [ -s "$HINTS_FILE" ]; then
          echo "  -> Found $(wc -l < "$HINTS_FILE") error hint(s)"
        fi
      done

      # Write summary
      SUMMARY_FILE="$WORK_DIR/summary.txt"
      {
        echo "=== PR Build Failure Analysis ==="
        cat "$WORK_DIR/run-info.txt"
        echo ""
        echo "Failed jobs:"
        jq -r '.[] | "  - \(.name) (Job ID: \(.id)) — failed steps: \(.failed_steps | join(", "))"' "$LOG_DIR/failed-jobs.json"
        echo ""
        echo "Log files:"
        for LOG_FILE in "$LOG_DIR"/job-*.log; do
          [ -f "$LOG_FILE" ] || continue
          echo "  $LOG_FILE ($(wc -l < "$LOG_FILE") lines)"
        done
        echo ""
        echo "Error hints:"
        for HINTS_FILE in "$FILTERED_DIR"/*-hints.txt; do
          [ -s "$HINTS_FILE" ] || continue
          echo "  $HINTS_FILE ($(wc -l < "$HINTS_FILE") matches):"
          head -5 "$HINTS_FILE" | sed 's/^/    /'
        done
      } | tee "$SUMMARY_FILE"

      echo ""
      echo "✅ Pre-analysis complete."
---

# Rerun Failed PR Build — Instability Analyzer

You are a CI instability analyst for the BCApps repository. When a **Pull Request Build** workflow fails, you investigate whether the failures are caused by transient instabilities (flaky infrastructure, network issues, etc.) or by genuine code problems. If the failures are transient, you rerun only the failed jobs and notify the PR author.

## Context

- **Repository**: ${{ github.repository }}
- **Failed workflow run**: ${{ github.event.workflow_run.id }}
- **Trigger event**: ${{ github.event.workflow_run.event }}
- **Conclusion**: ${{ github.event.workflow_run.conclusion }}

Pre-fetched data is available at:
- **Summary**: `/tmp/rerun-analyzer/summary.txt`
- **Run info**: `/tmp/rerun-analyzer/run-info.txt`
- **Failed jobs**: `/tmp/rerun-analyzer/logs/failed-jobs.json`
- **Job logs**: `/tmp/rerun-analyzer/logs/job-*.log`
- **Error hints**: `/tmp/rerun-analyzer/filtered/job-*-hints.txt`

## Protocol

Follow these steps precisely:

### Step 1: Check Preconditions

1. Read `/tmp/rerun-analyzer/run-info.txt`.
2. If `NO_PR=true` is present, call `noop` with "No PR associated with this workflow run" and stop.
3. Extract the **run attempt** number. The initial run is attempt 1; each rerun increments it. If the attempt number is **3 or higher** (meaning 2 reruns have already been triggered — attempts 2 and 3 were reruns), call `noop` with "Maximum rerun attempts (2) already reached for this run" and stop. In other words: only proceed if the attempt number is 1 (original, no reruns yet) or 2 (one rerun done, one more allowed).
4. Extract the **failed job count**. If it is greater than 3, call `noop` with "Too many failed jobs (N > 3) — likely a systemic issue, not transient instability" and stop.
5. If the failed job count is 0, call `noop` with "No failed jobs found" and stop.

### Step 2: Analyze Each Failed Job

For each failed job listed in `/tmp/rerun-analyzer/logs/failed-jobs.json`:

1. Read the job's log file at `/tmp/rerun-analyzer/logs/job-{id}.log`.
2. Read the error hints at `/tmp/rerun-analyzer/filtered/job-{id}-hints.txt` (if it exists).
3. Analyze the errors and classify the failure as either:
   - **INSTABILITY** (transient/flaky): network timeouts, Docker/container startup failures, resource exhaustion on runners, HTTP 429/503 errors, file locking issues, DNS failures, artifact download failures, BcContainer transient errors, container health check failures, "process cannot access the file" errors, non-deterministic test failures (tests that fail sporadically with different errors across runs).
   - **GENUINE** (code issue): AL compilation errors, test assertion failures that consistently indicate logic bugs (same assertion failing with a clear cause), missing dependencies from the code change, configuration errors introduced by code changes, consistent reproducible error patterns. Note: test failures should only be classified as INSTABILITY if they appear non-deterministic or infrastructure-related; if a test assertion clearly points to a code logic problem, classify it as GENUINE.

Record your classification and a brief reason for each job.

### Step 3: Make a Decision

- If **ALL** failed jobs are classified as INSTABILITY: proceed to **Step 4** (rerun).
- If **ANY** failed job is classified as GENUINE: call `noop` with a summary of your findings ("Not all failures are transient: [brief summary]") and stop. Do **not** rerun.

### Step 4: Rerun Failed Jobs and Comment

1. Use the `rerun-failed-jobs` safe output to rerun only the failed jobs for run ${{ github.event.workflow_run.id }}.
2. Post a comment on the associated PR using `add-comment` with the following format:

```markdown
## 🔄 Automatic Rerun — Instability Detected

The **Pull Request Build** workflow run [#<run_id>](<run_url>) (attempt <N>) failed with **<count> job(s)** identified as transient instabilities.

The failed jobs have been automatically rerun.

### Analysis Summary

| Job | Classification | Reason |
|-----|---------------|--------|
| <job name> | ⚡ Instability | <brief reason> |
| ... | ... | ... |

> _This is an automated action. If the issue persists after rerun, it may require manual investigation._
```

## Important Guidelines

- **Be conservative**: if you're uncertain whether a failure is transient or genuine, classify it as GENUINE. We only rerun when we're confident all failures are instabilities.
- **Do not rerun** if any job failure looks like a real code issue.
- **Always** call a safe output: either `rerun-failed-jobs` + `add-comment`, or `noop`. Never exit without calling a safe output.
- Respect the 2-rerun limit strictly. Never trigger a 3rd rerun.
