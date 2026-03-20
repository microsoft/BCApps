# Workflow

Integrates Quality Management with BC's standard Workflow engine, enabling event-driven automation of quality processes. Workflows can trigger on inspection creation or completion and execute disposition actions automatically.

## How it works

The `QltyStartWorkflow` codeunit publishes workflow events: "When a Quality Inspection is Created" and "When a Quality Inspection is Finished". The `QltyWorkflowApprovals` codeunit registers these events with BC's workflow engine and defines available responses.

Workflow conditions can filter on any inspection header field -- typically `Result Code` to trigger different actions for PASS vs FAIL. Available workflow responses include: block lot, unblock lot, create negative adjustment, move inventory, create transfer order, create purchase return, create re-inspection, and send notification.

A common workflow: inspection finishes with FAIL result -> automatically block the lot -> create a purchase return order -> send notification to quality manager.

## Things to know

- **Workflow is optional** -- all disposition actions can be done manually without workflows. Workflows add automation.
- **The `Workflow Integration Enabled` toggle** on QltyManagementSetup controls whether workflow events fire at all. If disabled, no workflow processing occurs.
- **Lot blocking via workflow** -- the workflow response creates/modifies `Lot No. Information Card` entries, which is BC's built-in mechanism for blocking lots from transactions. This is a stronger block than the result-based per-transaction-type blocking.
- **Re-inspection via workflow** -- a workflow response can automatically create a re-inspection when an inspection fails, continuing the quality chain without manual intervention.
