# BCQuality integration

This directory holds the **shared BCQuality integration layer** for every
agent in this repository that consumes BCQuality. The Copilot PR reviewer
under `tools/Code Review/` is the first consumer; future code-generation,
telemetry-audit, and other agents follow the same pattern.

> **Precedent:** Agents in this repository carry **no** review or generation
> knowledge of their own. Skills and knowledge live in
> [microsoft/BCQuality](https://github.com/microsoft/BCQuality) (or a
> partner fork). This directory is the boundary that every agent crosses to
> reach BCQuality.

> **Security:** the runner clones the configured `bcquality.repo` and makes it
> the Copilot CLI's working directory, so its skill and knowledge files are
> read by the agent *before* it sees the PR diff. Point `repo` (and the
> `BCQUALITY_REPO` override) **only** at a trusted source: a malicious or
> compromised fork can embed prompt-injection payloads that manipulate review
> output. Pin `ref` to a reviewed commit SHA rather than a moving branch.

## What's here

| File | Purpose |
|---|---|
| `bcquality.config.yaml` | Tracked default configuration: which BCQuality repo + ref to consume, which layers/skills are enabled, which knowledge articles are allowed/denied, and the task-context dimensions passed to BCQuality's `skills/entry.md`. |
| `scripts/Get-BCQualityConfig.ps1` | Loads the YAML, applies environment-variable overrides, validates, returns a resolved configuration hashtable. |
| `scripts/Invoke-BCQualityFilter.ps1` | After an agent clones BCQuality, this filter prunes the clone on disk so the agent only sees the content this repository wants to consume. Writes `_filter-report.json` next to the clone. |

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
file edit, every value above can be overridden at workflow runtime:

| Environment variable | Overrides | Format |
|---|---|---|
| `BCQUALITY_REPO`             | `bcquality.repo`   | URL |
| `BCQUALITY_REF`              | `bcquality.ref`    | branch/tag/SHA |
| `BCQUALITY_ENABLED_LAYERS`   | `enabled-layers`   | comma-separated |
| `BCQUALITY_DISABLED_SKILLS`  | `disabled-skills`  | comma-separated |
| `BCQUALITY_KNOWLEDGE_ALLOW`  | `knowledge.allow`  | comma-separated |
| `BCQUALITY_KNOWLEDGE_DENY`   | `knowledge.deny`   | comma-separated |

Set these as GitHub Actions repo or org variables (`vars.BCQUALITY_*`) and
the runner workflow forwards them automatically.

## Partner-fork workflow

A partner who has forked BCQuality (public fork, private mirror, internal
HTTPS host) usually only needs one change:

1. Fork this repository (or your downstream orchestrator repo).
2. Edit `tools/BCQuality/bcquality.config.yaml`:
   ```yaml
   bcquality:
     repo: https://github.com/your-org/your-bcquality-fork
     ref:  v2025.05
   enabled-layers: [microsoft, custom]
   ```
3. Open a PR. Configuration is in-tree, so the change is visible to every
   downstream reviewer.

Per-article opt-outs without forking BCQuality:

```yaml
knowledge:
  deny:
    - 'microsoft/knowledge/style/**'   # turn off all style rules
    - 'microsoft/knowledge/ui/use-and-not-ampersand-in-ui-captions.md'
```

The filter runs on the local clone, so denied articles cannot influence the
agent — and the deletion list is recorded in `_filter-report.json` and
uploaded as a workflow artifact.

## Contract for new agents

When you write a new agent that consumes BCQuality, follow this pattern in
its runner workflow:

1. `Install-Module powershell-yaml -Scope CurrentUser -Force` (one-liner).
2. Clone the upstream and check out the ref returned by
   `Get-BCQualityConfig.ps1`.
3. Run `Invoke-BCQualityFilter.ps1` against the clone.
4. Tell your agent: **start by reading `skills/entry.md`**. Pass the
   resolved configuration's `task-context` dimensions, and use the agent's
   structured output verbatim — do not bake knowledge or skill discovery
   into the orchestrator. BCQuality is an **additive** knowledge layer:
   review skills may surface findings the agent identifies on its own
   judgement (no matching knowledge article) with
   `from-sub-skill: "agent"` and an empty `references[]`. Render and
   post those distinctly from knowledge-backed findings — don't drop
   them.

That convention — *"start at `skills/entry.md`"* — is the only thing every
future agent inherits from this directory. Everything else (which models
to call, how to render results, how to deliver findings to humans) is the
agent's own concern.

## Background

- [BCQuality README](https://github.com/microsoft/BCQuality#readme)
- [agent-consumption.md](https://github.com/microsoft/BCQuality/blob/main/agent-consumption.md)
- [skills/entry.md](https://github.com/microsoft/BCQuality/blob/main/skills/entry.md)
