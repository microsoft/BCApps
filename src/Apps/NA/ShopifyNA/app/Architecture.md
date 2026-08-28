# Shopify Tax Matching Agent - Architecture

## Purpose

Shopify orders contain free-text tax descriptions, while Business Central requires structured Tax Jurisdictions and a Tax Area. The Tax Matching Agent attempts to resolve that gap when the standard address-based tax-area lookup does not find a match.

The feature is part of the Shopify Connector NA app and is currently enabled for supported North American scenarios.

## Design goals

- **Conservative by default**: The feature is disabled until an administrator enables it for a shop.
- **Preserve the standard flow**: Existing address-based tax mapping runs first and takes precedence.
- **Fail safely**: If the AI service or its required safeguards are unavailable, matching is skipped and order synchronization continues normally.
- **Require explicit creation settings**: New tax jurisdictions and tax areas are created only when the corresponding shop settings allow it.
- **Keep people in control**: Incomplete, conflicting, or policy-selected matches are held for review before a sales document is created.
- **Remain auditable**: Applied matches and review decisions are recorded through standard Business Central surfaces.

## High-level flow

```text
Shopify order import
    |
    v
Standard address-based tax mapping
    |
    v
Eligibility and safety checks
    |
    v
AI-assisted jurisdiction matching
    |
    v
Validate and apply accepted matches
    |
    v
Reuse or create a Tax Area
    |
    +--> Hold for review when required
    |
    v
Continue sales document creation
```

The matcher processes product and shipping tax lines. Existing assignments are retained, unresolved lines remain unmatched, and the Tax Area is built only from validated jurisdiction assignments.

## Responsibilities

| Area | Responsibility |
|------|----------------|
| Orchestration | Runs after standard order mapping, applies eligibility checks, and coordinates matching and review state. |
| Matching | Supplies the minimum required tax and geographic context to the AI service and validates its structured response. |
| Tax setup | Reuses existing tax setup where possible and creates jurisdictions, tax details, or tax areas only when configured. |
| Review | Shows the proposed result, rate differences, confidence, and unresolved lines before approval when review is required. |
| Audit and notifications | Records applied decisions and provides entry points from Shopify orders and sales orders. |

Implementation-specific object IDs and inventories are intentionally kept in source rather than duplicated here.

## Safety and validation

All externally supplied text is treated as untrusted data. The feature uses managed safeguards around the model request and does not run matching when those safeguards cannot be applied. The exact prompts and security configuration are intentionally not documented in this public repository.

Model output is treated as a proposal, not as an instruction:

- The response must have the expected structured shape.
- Referenced tax lines and jurisdictions must be valid.
- New jurisdictions are created only when explicitly allowed.
- Unresolved lines are left for a person to complete.
- Existing Business Central tax rates are not silently overwritten.

When Shopify's rate differs from an existing Business Central Tax Detail, the jurisdiction can still be matched, but the existing rate is preserved and the order is held for review. A reviewer can accept the Business Central rate, select another jurisdiction, or explicitly choose to update tax setup to the Shopify rate.

Jurisdictions created by the agent remain provisional until they are approved through the review workflow. This prevents newly generated master data from being treated as trusted without human confirmation.

## Review policy

Each shop selects a review mode:

| Mode | Behavior |
|------|----------|
| Always | Hold every applied match for review. |
| Low Confidence Only | Hold matches that require additional validation. |
| Never | Do not hold solely because of the review preference. |

Rate conflicts and incomplete matches are hard safety gates and are held in every mode.

The review page is the canonical place to inspect and adjust a match. It presents the resolved Tax Area, relevant ship-to context, matched tax lines, and the Shopify and Business Central rates. Approval rebuilds the Tax Area from the final assignments and rechecks conflicts before releasing the order.

Changes made on the review page are not considered approved until the reviewer completes the approval action. Approval can be undone before a sales document is created.

## Data boundaries

The model receives only the information needed for jurisdiction matching:

- Tax-line identifiers, descriptions, and rates.
- Candidate jurisdiction codes and descriptions.
- Coarse ship-to geography such as country, state or province, and city.
- Whether jurisdiction creation is allowed.

Customer names, monetary totals, item details, street addresses, and postal codes are not included in the matching request.

## Configuration and user experience

The Shopify Shop Card contains the feature toggle, creation settings, Tax Area naming preference, and review mode. Settings that depend on another option remain unavailable until their prerequisite is enabled.

The main user surfaces are:

- **Tax Match Review**: Review, correct, and approve jurisdiction assignments and rate differences.
- **Shopify Order**: Open the review page and see when approval is pending.
- **Sales Order**: Review the originating tax match for orders that were allowed to continue automatically.

Notifications are derived from the current order state and can be disabled by the user through standard notification settings.

## Data and integration boundaries

The feature stores jurisdiction assignments and review state with the Shopify order, reads and updates standard Business Central tax setup as configured, and propagates the resolved tax context to the sales document.

It integrates with the connector at three lifecycle points:

1. After Shopify order mapping, to attempt matching when standard tax mapping did not succeed.
2. Before sales document creation, to enforce the review gate.
3. After sales document creation, to propagate the applied-match marker.

The feature does not replace the connector's import or document-creation pipeline.

## Installation and upgrades

Feature enablement and automatic jurisdiction creation remain opt-in. Dependent settings receive defaults for new and existing shops without enabling the agent on behalf of the administrator.

Eligible environments can be prompted to install the North America app through the standard extension-management experience.

## Refunds

Refunds do not invoke the matcher again. They inherit the Tax Area, tax-liable state, and related tax context from the original Shopify order so that the resulting credit memo remains consistent with the processed order.

## Verification

Coverage is split between deterministic AL tests, AI evaluation scenarios, and client-level review workflow checks. See [TestMatrix.md](TestMatrix.md) for the public coverage summary.
