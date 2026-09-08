# Extensibility Request Implementation

The implementation automation supports two repository-configured modes through the
`EXT_REQ_IMPLEMENTATION_MODE` repository variable:

- `per-issue` implements an eligible issue when it receives the `ext-ready-to-implement` label.
  This is also the default when the variable is not defined.
- `per-team` batches `event-request` and `request-for-external` issues in the scheduled team
  workflow. Every other request type continues through the standalone label-triggered workflow.
- `disabled` disables both automatic implementation modes.

The team workflow runs at 18:10 Europe/Copenhagen time on weekdays. It processes at most ten
eligible issues for each of these teams, oldest first:

- `Team: Finance`
- `Team: SCM`
- `Team: Integrations`

An issue must be open, have type `Task`, carry `ext-ready-to-implement`, have exactly one team
label, have exactly one of `event-request` or `request-for-external`, and have no open pull request
that closes it. Other request types are always implemented in standalone PRs. A team with no
eligible issues completes successfully without creating a branch or pull request.

Each issue is implemented sequentially in an isolated worktree and produces one commit. The
workflow creates one draft pull request per team and local calendar date. Re-running the same team
on the same date updates that branch and pull request.

The batch pull request description template is
[`batch-pr-template.md`](./batch-pr-template.md). `{{TEAM}}` and `{{ISSUE_SECTIONS}}` are populated
when the PR is created. The `EXT_REQ_BATCH_END` marker is retained so same-day reruns can append
new issue sections without replacing existing ones.

## Telemetry

Telemetry remains issue-based. Team-batch events use the same lifecycle tags as per-issue
implementation and reference the shared pull request. The existing implementation telemetry table
must include this additional column:

```kusto
BatchId:string
```

The sender uses `.set-or-append` with `extend_schema=true`, allowing the configured identity to add
the column automatically when it has Database Admin permission. Otherwise, add the column before
enabling `per-team` mode. Per-issue events store an empty `BatchId`; team events use values such as
`finance-2026-09-08`.
