# Expense Agent AL module

This module implements expense capture, management rules, policy evaluation, approvals, travel requests,
corporate-card integration, and expense-report posting in Business Central. It contains the AL application,
its test application, and demo data; the external Expense Agent services are not implemented here.

## Start here

Read the repository [contribution guidelines](../../../../CONTRIBUTING.md), then the
[coding and testing guidelines](docs/development.md) before changing this module. The latter records a
small set of source-backed invariants, relevant regression tests, and the limits of the PR retrospective.
It supplements repository policy rather than replacing it.

| Path | Responsibility |
|---|---|
| [app/app.json](app/app.json) | Application identity, dependencies, supported targets, and object ranges |
| [app/src/Expense](app/src/Expense) | Individual expenses and their itemization, participants, and per diems |
| [app/src/ExpenseReport](app/src/ExpenseReport) | Report aggregation, policy state, release, posting, and posted history |
| [app/src/Setup](app/src/Setup) | Configuration, rule application and auto-population, Entra application management, and privacy notices |
| [app/src/APIs](app/src/APIs) | API pages, currency presentation, and policy-evaluation contracts |
| [app/src/Approval](app/src/Approval) and [app/src/Travel Request](app/src/Travel%20Request) | Expense approval and travel-request workflows |
| [app/src/Integration](app/src/Integration) | Service communication, email processing, scheduling, and recovery |
| [app/src/Permissions](app/src/Permissions) | Application permission sets |
| [test](test) | AL business, permissions, API, and configuration tests; shared fixture libraries |
| [demo data](demo%20data) | Demo-data application, including country-specific setup |

Use the manifests in the checkout being changed; do not assume that another branch's app version or
installed test application matches it. W1 changes can also affect localized applications under
`src/Apps/<country>/ExpenseAgent_<country>` and the separate Expense Withholding Tax application.
Check the affected paths and dependencies rather than assuming every change needs every localization.

## Existing feature documentation

The credit-card-feed documentation is
[Corporate Card Module Documentation](app/src/CorporateCard/CORPCARD_MODULE.md), inside this module.
It describes provider import, matching, settlement, reconciliation, and feature-specific limitations.
Keep those details there instead of duplicating them in module-wide guidance. Consult the current setup
pages and code when following older setup examples; a feature guide is not a replacement for the
current configuration and permission checks.

## Development and validation boundaries

The [local development guide](../../../../LOCAL_DEV_ENV.md) describes repository-supported environment
setup. The AL-Go [Apps W1 project](../../../../build/projects/Apps%20W1/.AL-Go/settings.json) includes
`ExpenseAgent/app` and `ExpenseAgent/test`. Use the existing environment and runner appropriate to the
change; this README does not provision an environment, publish applications, or prescribe a particular
editor, MCP server, container, or machine path.

Start with the invariant-specific tests in [development.md](docs/development.md#choosing-tests-and-reporting-evidence).
A successful API connectivity check is not evidence that a per-diem, currency, policy, or posting defect
has been fixed.

## Human and agent discovery

These are the canonical, tool-neutral component entry points:

- `src/Apps/W1/ExpenseAgent/README.md`
- `src/Apps/W1/ExpenseAgent/docs/development.md`

Tools and fresh-session bootstrap instructions should explicitly read these files from the actual
target checkout. Markdown files are not guaranteed to be loaded automatically by every agent.
There is no additional module-specific `AGENTS.md`, `CLAUDE.md`, or parallel rules file to maintain.

Cross-repository orchestration, environment setup, and evidence-collection mechanics belong in the
owning tooling, not this AL module. Read applicable component guidance from the actual checkout.
The AL contracts and the tests that establish correctness belong here.
