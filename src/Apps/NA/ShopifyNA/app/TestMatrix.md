# Shopify Tax Matching Agent - Test Coverage

This document summarizes the behavioral coverage for the Tax Matching Agent. It intentionally avoids duplicating every test object, dataset entry, telemetry tag, and security evaluation detail from the implementation.

## Configuration dimensions

Coverage exercises the meaningful combinations of:

- Feature and Copilot capability availability.
- Automatic creation of Tax Jurisdictions and Tax Areas.
- Existing versus missing Business Central tax setup.
- Review mode: Always, Low Confidence Only, or Never.
- Product, shipping, complete, partial, and conflicting tax data.

## Coverage matrix

| Area | Representative coverage | Required invariant |
|------|-------------------------|--------------------|
| Eligibility and guards | Feature disabled, capability unavailable, tax-exempt order, existing address-based Tax Area, empty order, or no unmatched lines. | The agent does not change the order and standard synchronization continues. |
| Jurisdiction matching | Exact, semantic, geographic, multilingual, ambiguous, partial, and no-match cases across multiple tax lines. | Only validated assignments are applied; unresolved lines remain available for review. |
| Jurisdiction creation | Missing jurisdictions with creation enabled or disabled, repeated use, and approval of agent-created records. | Creation is opt-in, idempotent, and provisional until reviewed. |
| Tax Detail handling | Product and shipping tax groups, missing details, repeated processing, effective dates, and blank tax groups. | Missing details can be seeded without creating duplicates. |
| Rate divergence | Existing Business Central rate differs from Shopify for product or shipping tax. | The existing rate is preserved, the order is flagged, and review is required in every mode. |
| Tax Area handling | Exact area reuse, missing area, creation disabled, creation enabled, and code collisions. | Existing exact matches are preferred; new areas are created only when allowed. |
| Review policy | All review modes with high-confidence, low-confidence, incomplete, and conflicting results. | Review preference follows the selected mode, while incomplete and conflicting results always remain held. |
| Review workflow | Edit, approve, undo approval, close without approval, unresolved lines, and explicit rate correction. | Only approved assignments are released; unsafe or incomplete changes cannot silently continue. |
| Audit and notifications | Applied-match audit entries, review entry points, notification suppression, and state propagation to the sales order. | Prompts and audit state reflect the persisted order state without requiring a separate queue. |
| Error handling | Service failure, unavailable safeguards, malformed or incomplete structured output, invalid identifiers, and missing records. | Failures do not abort Shopify synchronization or apply partial unvalidated data. |
| Reprocessing | Re-import, re-run after review changes, and repeated setup creation. | Processing is stable and does not duplicate assignments or tax setup. |
| Refunds | Refund and credit memo creation from a matched order. | Refund tax context remains consistent with the original order without another AI call. |

## End-to-end acceptance

The end-to-end scenarios verify that:

1. A fully matched order can reuse or create the required tax setup and continue according to its review policy.
2. A partial or unresolved match remains held until a reviewer completes it.
3. An existing address-based Tax Area prevents the agent from running.
4. A rate conflict never overwrites maintained Business Central tax setup without an explicit reviewer action.
5. Approved tax context is propagated to the resulting sales document and inherited by refunds.

## AI evaluation

AI evaluations cover representative US and Canadian jurisdiction naming, abbreviations, regional terminology, multilingual titles, geographic ambiguity, distractors, and valid no-match outcomes. They include both curated scenarios and broader generated datasets.

Evaluation emphasizes false-positive avoidance: leaving an uncertain line unmatched is safer than confidently assigning the wrong jurisdiction because unresolved lines are held for review.

Security and Responsible AI evaluations are maintained in restricted test infrastructure. Exact prompts, adversarial inputs, datasets, and mitigation details are intentionally not described in this public document.

## Test layers

| Layer | Focus |
|-------|-------|
| Deterministic AL tests | Guards, tax setup behavior, review gates, rate-conflict handling, reprocessing, and state transitions. |
| AI Test Toolkit evaluations | Matching quality and structured-response behavior using representative tax scenarios. |
| Client-level verification | Page actions, field visibility, notifications, confirmation dialogs, rate highlighting, and edit/close behavior. |

## Release criteria

- Disabled or unavailable AI functionality leaves the standard connector behavior intact.
- Incomplete and conflicting tax matches cannot be auto-released.
- Existing tax rates are not changed without an explicit reviewer decision.
- Repeated processing does not duplicate tax setup or lose existing assignments.
- Public documentation and tests do not expose restricted prompt or security-evaluation details.
