# Copilot PR Review

GitHub Actions orchestration for the Copilot CLI–driven AL code review.
This directory holds **only** orchestration — the trigger workflows, the
PR-resolution + commenting plumbing, and the script that bootstraps the
Copilot agent against BCQuality. All skills and knowledge live in
[BCQuality](https://github.com/microsoft/BCQuality); see
`tools/BCQuality/README.md` for the shared integration layer.

## Components

| File | Role |
|---|---|
| `.github/workflows/CopilotPRReview.yaml` | Unprivileged intake. Runs on `pull_request`; captures PR metadata as a workflow artifact. |
| `.github/workflows/CopilotPRReviewRunner.yaml` | Runs on `workflow_run`. Checks out the PR head into a detached worktree, clones + filters BCQuality, installs the Copilot CLI, invokes the review script. |
| `.github/workflows/CopilotPRReviewSmoke.yaml` | On-demand / scheduled smoke test that exercises the BCQuality bootstrap end-to-end. |
| `scripts/Invoke-CopilotPRReview.ps1` | The review orchestrator. Builds task-context, invokes Copilot CLI with a bootstrap prompt that points at `skills/entry.md`, parses BCQuality's `findings-report` per the DO contract, posts inline comments and a per-PR summary. |

## Two-workflow security pattern

The review uses the `pull_request` → `workflow_run` privilege-escalation
pattern (as in the original BCApps port). The unprivileged intake job
fires on `pull_request` events from untrusted forks; the runner job fires
on `workflow_run` events, runs against the **trusted base branch**. The
tool-enabled Copilot CLI runs in a `review` job whose token is read-only
(`contents: read` + `copilot-requests: write`); a separate `publish` job
holds the `issues`/`pull-requests: write` token and posts comments from the
saved agent output, so the model process never holds a write-scoped token.
This eliminates the `pull_request_target` attack surface entirely.

## Severity mapping

BCQuality's DO contract uses `blocker | major | minor | info`. This
orchestrator maps them to the existing comment taxonomy:

| BCQuality | Comment label | Badge |
|---|---|---|
| `blocker` | Critical | 🔴 |
| `major`   | High     | 🟠 |
| `minor`   | Medium   | 🟡 |
| `info`    | Low      | 🟢 |

`MINIMUM_SEVERITY` (workflow variable
`COPILOT_REVIEW_MINIMUM_SEVERITY`, default `Medium`) is applied after the
mapping to knowledge-backed findings.

## Knowledge-backed vs agent findings

BCQuality is an **additive** knowledge layer, not the exclusive source
of review findings. The dispatched skills surface two kinds of
findings:

- **Knowledge-backed**: cites at least one BCQuality knowledge article
  via `references[]`. Rendered with a **Knowledge** footer linking
  into BCQuality at the resolved SHA.
- **Agent**: the agent's own judgement; no matching BCQuality rule.
  Emitted by the skills with `from-sub-skill: "agent"` (or
  `knowledge-backed: false`) and an empty `references[]`. Rendered
  with a clearly labelled "Agent finding" notice instead of a
  Knowledge footer, and tagged in HTML metadata with
  `<!-- agent_finding: true -->`. Routed to the `Agent` domain.

`AGENT_MINIMUM_SEVERITY` (workflow variable
`COPILOT_REVIEW_AGENT_MINIMUM_SEVERITY`, default = `MINIMUM_SEVERITY`)
applies a separate severity floor to agent findings, so operators can
raise the bar for unbacked findings without changing the knowledge-
backed gate.

## Domain labels

Inline-comment headers and the per-PR summary group findings by *domain*.
A finding's domain label is emitted by BCQuality on each finding (the leaf
skill sets it; the super-skill preserves it on rollup), and the orchestrator
renders it verbatim — so adding a BCQuality domain needs no change here. For
example, a finding produced by `al-security-review` is labelled **Security**.
Findings with `from-sub-skill: "agent"` (or `knowledge-backed: false`) land in
the **Agent** domain.

For findings from older BCQuality pins that predate the `domain` field, the
orchestrator falls back to a static `$DomainMap` in
`Invoke-CopilotPRReview.ps1` keyed on `from-sub-skill`; unmapped sub-skills
fall back to **Other**.

## What each PR comment carries

Every inline finding includes:

- A severity-coloured pre-header (`🔴 Critical Severity — Security`).
- A short lead title derived from the first sentence of the finding's
  message.
- The full message (split on `Recommendation:` / `Fix:` if the skill
  includes one).
- A **Knowledge** footer listing every BCQuality reference the finding
  cites, with links into BCQuality at the resolved commit SHA. Agent
  findings (no backing knowledge article) instead carry a short
  "Agent finding — no matching BCQuality knowledge article" notice.
- HTML-comment metadata (`agent_version`, `agent_label`,
  `agent_domain`, `agent_finding`) used by the dedup logic on
  subsequent iterations.

When a finding carries a concrete fix, the orchestrator renders it as a
GitHub ```suggestion``` block. Because such a block replaces *exactly* the
line(s) its comment is anchored to, the suggested code is matched against the
PR-head file to re-derive the correct RIGHT-side span: a single-line fix is
snapped onto the line it actually rewrites, and a fix that edits a multi-line
construct is posted as a multi-line comment over the whole span (so an
inserted property lands in place instead of duplicating the surrounding
lines). If the fix cannot be anchored with confidence the applicable block is
dropped and the change is shown as a manual, non-applicable snippet.

## Per-PR summary comment

Marker: `<!-- copilot-pr-review-summary -->`. Upserted once per
iteration. Contains:

- Iteration number and overall `outcome`
  (`completed | partial | not-applicable | no-knowledge | failed`).
- Knowledge-source link with the resolved BCQuality SHA.
- Per-domain finding counts, split into **Knowledge-backed** (cite a
  BCQuality article) and **Agent** (the agent's own judgement, no
  matching BCQuality rule), plus inline / fallback placement counts.
- Knowledge files **suppressed** by layer precedence or configuration
  (BCQuality's `suppressed[]`).
- Sub-skills the super-skill **skipped** (BCQuality's
  `skipped-sub-skills[]`).
- Orchestrator pre-filter counts (knowledge files removed by
  `Invoke-BCQualityFilter.ps1` per `_filter-report.json`).

## Workflow variables consumed

Defined as repo or org-level Actions variables:

| Variable | Default | Purpose |
|---|---|---|
| `COPILOT_REVIEW_MODEL` | (unset) | Explicit Copilot CLI `--model` value. |
| `COPILOT_REVIEW_MINIMUM_SEVERITY` | `Medium` | Severity gate for knowledge-backed findings. |
| `COPILOT_REVIEW_AGENT_MINIMUM_SEVERITY` | = `MINIMUM_SEVERITY` | Severity gate for agent findings (those without a backing BCQuality article). Raise to suppress lower-confidence unbacked findings without affecting knowledge-backed ones. |
| `COPILOT_REVIEW_MAX_FINDINGS_PER_DOMAIN` | `25` | Per-domain finding cap. |
| `COPILOT_REVIEW_FAIL_ON_PARSE_ERROR` | `true` | Fail the workflow if BCQuality output is unparseable. |
| `COPILOT_REVIEW_AGENT_LABEL` | `copilot-pr-review` | Stable label used in comment metadata. |
| `COPILOT_REVIEW_AGENT_RELEASE_DATE` | today UTC | YYYY-MM-DD; surfaced in agent-version metadata. |
| `COPILOT_REVIEW_AGENT_RELEASE_VERSION` | `0` | Non-negative integer; surfaced in agent-version metadata. |

BCQuality-side configuration (repo URL, ref, layers, allow/deny lists)
lives in `tools/BCQuality/bcquality.config.yaml`; see that directory's
README for the partner-fork workflow.

## Authentication

The Copilot CLI authenticates via `GH_TOKEN`.

- In CI, the runner workflow sets `GH_TOKEN` to the built-in `GITHUB_TOKEN`
  (requires `copilot-requests: write` to bill inference to the org). No PAT
  secret is required.
- For local runs, set `GH_TOKEN` to a Copilot-enabled PAT.

## Local development

The review script is shaped for a CI runner. To experiment locally:

```pwsh
$env:GITHUB_TOKEN     = '...'
$env:GH_TOKEN         = '...'
$env:GITHUB_REPOSITORY = 'org/repo'
$env:PR_NUMBER        = '123'
$env:PR_HEAD_SHA      = '<sha>'
$env:BCQUALITY_ROOT   = './bcquality'   # clone of BCQuality
git clone https://github.com/microsoft/BCQuality bcquality
./tools/BCQuality/scripts/Invoke-BCQualityFilter.ps1 -BCQualityRoot ./bcquality
./tools/Code\ Review/scripts/Invoke-CopilotPRReview.ps1
```

The Copilot CLI must be installed (`npm install -g @github/copilot`) and
authenticated (`$env:GH_TOKEN`).

## Workflow log structure

The orchestrator emits a phased, GitHub-Actions-aware log so a follower can
tag along during a review cycle. On CI each phase is wrapped in a collapsible
`::group::` block; locally (no `GITHUB_ACTIONS`) the same phases render as
`--- Title ---` / `--- end ---` markers.

| Phase | What's in it |
|---|---|
| **Configuration banner** (always visible) | Iteration, PR + head SHA, base branch, model, agent label/version, severity gates, BCQuality root + SHA |
| **Discovery** | Base/PR-head fetch, worktree checkout, full changed-files list (capped at 50, `… and N more` suffix beyond that), task-context path |
| **Agent run** | Copilot CLI stdout/stderr streamed live, line-by-line (`stderr` prefixed `[copilot-err]`). Exit code + elapsed time at the footer. On the 20-minute hard cap the wrapper kills the process and emits an `::error::` annotation. |
| **Parse & filter** | Outcome + reason, per-severity breakdown, knowledge-backed vs agent split, per-domain pre-post counts, BCQuality consumption summary, localized-duplicate filter count |
| **Post comments** | Per-domain `Posting N findings…` + result line (`inline / fallback / knowledge-backed / agent`), summary-comment upsert |
| **Finalize** (always visible) | Artifact directory + file list, then a single `::notice::` / `::warning::` / `::error::` outcome annotation so the run header surfaces the result. |

### Live transcript artifact

Alongside `al-code-review-raw.txt` (parsed stdout) and
`al-code-review-findings.json` (normalized findings), the orchestrator now
writes `agent-transcript.log` — an interleaved, in-arrival-order capture of
Copilot CLI stdout (`out:` lines) and stderr (`err:` lines). Use it to replay
exactly what the agent emitted during the run.
