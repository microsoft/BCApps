# BCQuality integration policy

This directory holds this repository's **policy config** for the Business
Central Copilot PR reviewer: which [BCQuality](https://github.com/microsoft/BCQuality)
content the reviewer consumes when it runs against BCApps pull requests.

The reviewer engine itself — the orchestrator script, the BCQuality
clone+filter scripts, and the reusable workflow — lives in
[microsoft/BC-PullRequestReviewAgent](https://github.com/microsoft/BC-PullRequestReviewAgent).
BCApps is a **caller**: `.github/workflows/CopilotPRReviewRunner.yaml`
invokes the engine's reusable workflow and points it at the config below.

> **Precedent:** BCApps carries **no** review knowledge of its own. Skills and
> knowledge live in BCQuality (or a partner fork); the engine is mechanism
> only. This file is BCApps' auditable, in-tree statement of *what* to review
> against.

> **Security:** the engine clones the configured `bcquality.repo` and makes it
> the Copilot CLI's working directory, so its skill and knowledge files are
> read by the agent *before* it sees the PR diff. Point `repo` (and the
> `BCQUALITY_REPO` override) **only** at a trusted source: a malicious or
> compromised fork can embed prompt-injection payloads that manipulate review
> output. Pin `ref` to a reviewed commit SHA rather than a moving branch.

## What's here

| File | Purpose |
|---|---|
| `bcquality.config.yaml` | This repository's tracked policy: which BCQuality repo + ref to consume, which layers/skills are enabled, which knowledge articles are allowed/denied, and the task-context dimensions passed to BCQuality's `skills/entry.md`. |

## Configuration schema

```yaml
bcquality:
  repo: https://github.com/microsoft/BCQuality   # any HTTPS-reachable BCQuality fork
  ref:  main                                     # branch, tag, or SHA

enabled-layers:                                  # microsoft | community | custom
  - microsoft                                    # this Microsoft repo's default

disabled-skills:                                 # repo-relative action-skill paths to skip
  - # e.g. microsoft/skills/review/al-style-review.md

knowledge:
  allow:                                         # globs (matched on repo-relative path)
    - 'microsoft/knowledge/**'
  deny: []                                       # evaluated after allow

task-context:                                    # passed verbatim to entry.md
  technologies: [al]
  countries:    [w1]
  application-area: [all]
  bc-version:   [all]
```

## Environment-variable overrides

For operator-controlled one-off changes that should not require a tracked
file edit, the caller workflow forwards these repo/org Actions variables to
the engine, which applies them on top of the config file:

| Actions variable | Overrides | Format |
|---|---|---|
| `BCQUALITY_REPO`             | `bcquality.repo`   | URL |
| `BCQUALITY_REF`              | `bcquality.ref`    | branch/tag/SHA |
| `BCQUALITY_ENABLED_LAYERS`   | `enabled-layers`   | comma-separated |
| `BCQUALITY_DISABLED_SKILLS`  | `disabled-skills`  | comma-separated |
| `BCQUALITY_KNOWLEDGE_ALLOW`  | `knowledge.allow`  | comma-separated |
| `BCQUALITY_KNOWLEDGE_DENY`   | `knowledge.deny`   | comma-separated |

## Partner-fork workflow

A partner who has forked BCQuality (public fork, private mirror, internal
HTTPS host) usually only needs to edit `bcquality.config.yaml`:

```yaml
bcquality:
  repo: https://github.com/your-org/your-bcquality-fork
  ref:  v2025.05
enabled-layers: [microsoft, custom]
```

Per-article opt-outs without forking BCQuality:

```yaml
knowledge:
  deny:
    - 'microsoft/knowledge/style/**'   # turn off all style rules
    - 'microsoft/knowledge/ui/use-and-not-ampersand-in-ui-captions.md'
```

The engine filters the local clone before the agent runs, so denied articles
cannot influence the agent — and the deletion list is recorded in
`_filter-report.json` and uploaded as a workflow artifact.

## Background

- [BC PR Reviewer Agent (engine)](https://github.com/microsoft/BC-PullRequestReviewAgent#readme)
- [BCQuality README](https://github.com/microsoft/BCQuality#readme)
- [skills/entry.md](https://github.com/microsoft/BCQuality/blob/main/skills/entry.md)
