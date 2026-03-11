# Issue Triage Agent

AI-powered GitHub issue quality assessment, enrichment, and triage for product managers.

## Quick start

1. Open any issue on this repository
2. Add the `ai-triage` label
3. Wait ~30 seconds for the GitHub Action to complete
4. Review the triage assessment comment posted on the issue

## How it works

```
 Add "ai-triage" label
        |
        v
 GitHub Action triggers
        |
        v
 Phase 1: Quality Assessment
 Scores issue 0-100 across 5 dimensions
        |
   Score >= 40?
   /         \
  Yes         No
   |           |
   v           v
 Phase 2    Post "needs info"
 Enrichment   comment + label
 & Triage
   |
   v
 Post full triage comment
 + apply labels
```

### Phase 1 - Quality assessment

Evaluates the issue across 5 dimensions (each scored 0-20):

- **Clarity** - Is the problem clearly stated?
- **Reproducibility** - Can someone act on this?
- **Context** - Environment, version, impact info?
- **Specificity** - Is the scope well-defined?
- **Actionability** - Can development start?

Verdicts:

- **READY** (75-100) - Proceed to enrichment and triage
- **NEEDS WORK** (40-74) - Has gaps, but still gets triaged
- **INSUFFICIENT** (0-39) - Requests specific missing info, skips triage

### Phase 2 - Enrichment and triage

Searches for related context:

- Microsoft Learn BC documentation
- Dynamics 365 Ideas Portal
- Community forums and Stack Overflow
- Related code areas in the repository

Produces a triage assessment:

| Data point | Values |
|-----------|--------|
| Complexity | Low / Medium / High / Very High |
| Value | Low / Medium / High / Critical |
| Risk | Low / Medium / High |
| Effort | XS / S / M / L / XL |
| Implementation path | Manual / Copilot-Assisted / Agentic |
| Priority score | 1-10 |
| Confidence | High / Medium / Low |
| Recommended action | Implement / Defer / Investigate / Reject |

## Labels applied

The agent automatically applies labels in these categories:

| Category | Labels |
|----------|--------|
| Triage status | `triage/ready`, `triage/needs-info`, `triage/insufficient` |
| Priority | `priority/critical`, `priority/high`, `priority/medium`, `priority/low` |
| Complexity | `complexity/low`, `complexity/medium`, `complexity/high` |
| Effort | `effort/xs-s`, `effort/m`, `effort/l-xl` |
| Impl. path | `path/manual`, `path/copilot-assisted`, `path/agentic` |

Conflicting labels in the same category are automatically removed before applying new ones.

## Re-triaging

To re-triage an issue (e.g., after the author provides more information):

1. Remove the `ai-triage` label
2. Re-add the `ai-triage` label
3. A new assessment is posted (previous ones are preserved for history)

## Configuration

All configuration is in `.github/scripts/triage/config.js`:

- **Model**: `openai/gpt-4o` via GitHub Models API (change to `openai/gpt-5.4` when available)
- **Score thresholds**: READY >= 75, NEEDS WORK >= 40, INSUFFICIENT < 40
- **App area mappings**: Shopify, Data Archive, E-Document, Subscription Billing, Quality Management

## File structure

```
.github/
  workflows/
    issue-triage.yml              # GitHub Action (trigger: issues.labeled)
  scripts/
    triage/
      index.js                    # Main orchestrator
      config.js                   # Labels, thresholds, app area mappings
      models-client.js            # GitHub Models API client (GPT-4o)
      github-client.js            # GitHub REST API client (Octokit)
      phase1-assess.js            # Phase 1: quality assessment
      phase2-enrich.js            # Phase 2: enrichment & triage
      format-comment.js           # Markdown comment formatter
      package.json                # Dependencies (@octokit/rest)
      prompts/
        system-phase1.md          # System prompt for quality scoring
        system-phase2.md          # System prompt for triage assessment
```

## Requirements

- GitHub Actions enabled on the repository
- `models: read` permission (GitHub Models API access)
- Node.js 20+ (configured in workflow)
- No additional secrets needed - uses `GITHUB_TOKEN`

## Design documentation

- Design doc: `docs/features/issue-triage-agent/design.md`
- Task list: `docs/features/issue-triage-agent/tasks.md`

---

**Last Updated**: 2026-03-11 by jeschulz
