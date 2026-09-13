# Shopify Tax Matching Agent - Test Coverage

This document summarizes the behavioral coverage for the Tax Matching Agent. It intentionally avoids duplicating every test object, dataset entry, telemetry tag, and security evaluation detail from the implementation.

## Configuration dimensions

Coverage exercises the meaningful combinations of:

- Feature and Copilot capability availability.
- Automatic creation of Tax Jurisdictions and Tax Areas.
- Existing versus missing Business Central tax setup.
- Review mode: Always, Low Confidence Only, or Never.
- Product, shipping, complete, partial, and conflicting tax data.

## Numbered scenario matrix

The scenario IDs provide stable references for reviews and defect discussions. Detailed mappings to test methods, objects, and datasets remain in the test source.

### Eligibility and guard scenarios

| ID | Scenario | Expected result |
|----|----------|-----------------|
| G1 | Feature disabled for the shop | No AI request or order change; standard synchronization continues. |
| G2 | Copilot capability unavailable or inactive | Matching is skipped without affecting order import. |
| G3 | Standard address mapping already assigned a Tax Area | The existing Tax Area takes precedence and the agent does not run. |
| G4 | Order is tax exempt | Matching is skipped and the tax-exempt state is preserved. |
| G5 | No unmatched tax lines are available | No matching work or tax setup changes are performed. |
| G6 | Required AI safeguards are unavailable | Matching is skipped and synchronization continues through the standard path. |

### Jurisdiction matching scenarios

| ID | Scenario | Expected result |
|----|----------|-----------------|
| J1 | All tax lines have clear existing jurisdiction matches | Every validated line is assigned to the existing jurisdiction. |
| J2 | Only some lines can be matched and creation is disabled | Valid matches are retained; unresolved lines remain blank and require review. |
| J3 | A required jurisdiction is missing and creation is enabled | A provisional jurisdiction can be created and the order is held according to the review rules. |
| J4 | Similar candidates require geographic disambiguation | Coarse ship-to geography is used to select the defensible candidate. |
| J5 | No defensible match exists | No jurisdiction is invented from untrusted text; the line remains unresolved. |
| J6 | An order is reprocessed with existing assignments | Existing assignments are retained and combined with newly validated matches. |

### Tax setup scenarios

| ID | Scenario | Expected result |
|----|----------|-----------------|
| JC1 | Multiple jurisdictions are created for one order | Records are created only when enabled and form a usable jurisdiction hierarchy. |
| JC2 | A suggested jurisdiction already exists | The existing record is reused rather than duplicated or overwritten. |
| TD1 | No applicable Tax Detail exists | A detail is seeded for the relevant jurisdiction, tax group, rate, and effective date. |
| TD2 | An equivalent Tax Detail already exists | No duplicate detail is created. |
| TD3 | Product and shipping tax lines use different tax groups or rates | Each line uses the tax setup associated with what the tax was charged on. |
| TA1 | A Tax Area has exactly the required jurisdictions | The existing Tax Area is reused. |
| TA2 | No exact Tax Area exists and creation is disabled | The order remains unresolved and cannot be released as a completed match. |
| TA3 | No exact Tax Area exists and creation is enabled | A new Tax Area is created without overwriting an unrelated existing code. |

### Rate divergence scenarios

| ID | Scenario | Expected result |
|----|----------|-----------------|
| RD1 | A product tax line differs from the maintained Business Central rate | The jurisdiction is retained, the maintained rate is preserved, and the order is held. |
| RD2 | A shipping tax line differs from the maintained Business Central rate | The shipping conflict is handled with the same safety gate as a product-line conflict. |
| RD3 | Review mode is set to Never but a rate conflict exists | The order is still held; conflicts override the review preference. |
| RD4 | Reviewer accepts the Business Central rate | Approval rebuilds the Tax Area and allows the maintained rate to remain authoritative. |
| RD5 | Reviewer explicitly adopts the Shopify rate | The shared Tax Detail is updated only after confirmation, then the conflict is re-evaluated. |
| RD6 | Reviewer changes a jurisdiction assignment | Approval rebuilds the complete Tax Area and recalculates applicable rates and conflicts. |

### Review mode and provenance scenarios

| ID | Scenario | Expected result |
|----|----------|-----------------|
| RM1 | Review mode is Always | Every applied match is held until approved. |
| RM2 | Review mode is Low Confidence Only and validation is needed | The order is held. |
| RM3 | Review mode is Low Confidence Only and all matches are sufficiently validated | The order can continue automatically when no hard safety gate exists. |
| RM4 | Review mode is Never with a complete, non-conflicting match | The order is not held solely for review preference. |
| RM5 | Any review mode with an incomplete match | The order remains held until all tax lines are resolved. |
| PV1 | An agent-created jurisdiction is first used | It remains provisional and requires human validation under the applicable review policy. |
| PV2 | A reviewer approves a provisional jurisdiction | It becomes verified for subsequent matching. |
| PV3 | Approval is undone before document creation | The order is held again and its agent-created jurisdictions return to provisional state. |

### Human-in-the-loop scenarios

| ID | Scenario | Expected result |
|----|----------|-----------------|
| HITL-1 | Reviewer opens a held order | The review page shows the resolved Tax Area, tax lines, assignments, and rate comparison. |
| HITL-2 | A tax line is still unresolved | Approval is blocked until the reviewer assigns a jurisdiction. |
| HITL-3 | Reviewer edits a jurisdiction and closes without approving | The pending edit is not silently accepted. |
| HITL-4 | Reviewer approves a completed match | The Tax Area and safety state are recalculated before the order is released. |
| HITL-5 | Reviewer undoes approval before a Sales Document exists | The order returns to the held state. |
| HITL-6 | A Shopify Order or Sales Order has an applied match | The appropriate review entry point is available. |
| HITL-7 | Review notification is dismissed or the order is reviewed | Notification behavior follows the current order and user-notification state. |
| HITL-8 | Shopify and Business Central rates differ | The difference is visually apparent and corrective actions require an explicit decision. |

### Error and reprocessing scenarios

| ID | Scenario | Expected result |
|----|----------|-----------------|
| E1 | The AI service call fails | No unvalidated match is applied and Shopify synchronization continues. |
| E2 | The response is missing or malformed | The response is rejected without creating tax setup from invalid data. |
| E3 | The response references an invalid tax line or jurisdiction | The invalid assignment is not persisted. |
| E4 | The same order or setup is processed again | Existing assignments and setup are reused without duplication. |
| E5 | A refund is created for a matched order | Tax context is inherited from the original order without another AI request. |

## End-to-end acceptance

| ID | Flow | Expected end state |
|----|------|--------------------|
| F1 | Complete match using existing setup | Existing jurisdictions and Tax Area are assigned and the order follows its review policy. |
| F2 | Complete match with permitted setup creation | Required tax setup is created once and remains provisional until applicable review completes. |
| F3 | Partial or unresolved match | The resolved work is retained, but the order remains held until the missing assignments are completed. |
| F4 | Match with a rate conflict | Existing Business Central setup remains unchanged until the reviewer makes an explicit decision. |
| F5 | Approved order creates a Sales Document and later a refund | The resolved tax context is propagated to the Sales Document and inherited by the refund. |

## AI evaluation

AI evaluations cover representative US and Canadian jurisdiction naming, abbreviations, regional terminology, multilingual titles, geographic ambiguity, distractors, and valid no-match outcomes. They include both curated scenarios and broader generated datasets.

Evaluation emphasizes false-positive avoidance: leaving an uncertain line unmatched is safer than confidently assigning the wrong jurisdiction because unresolved lines are held for review.

Security and Responsible AI evaluations are maintained in restricted test infrastructure. Exact prompts, adversarial inputs, datasets, and mitigation details are intentionally not described in this public document.

| ID | Evaluation family | Focus |
|----|-------------------|-------|
| AIT-1 | Clear and abbreviated titles | Exact, common abbreviation, and semantic matching. |
| AIT-2 | Geographic ambiguity | State, province, county, city, and district disambiguation using coarse location context. |
| AIT-3 | Multilingual terminology | Representative English and French Canadian tax terminology. |
| AIT-4 | Distractors and similar names | Avoiding attractive but incorrect jurisdiction candidates. |
| AIT-5 | Valid no-match cases | Preferring an unresolved result over a false-positive assignment. |
| AIT-6 | Broad regression datasets | Matching quality across a larger generated and representative scenario set. |

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
