# Quantity Ready to Start - Feature Documentation

## 1. Overview & Business Purpose
Quantity Ready to Start adds a manufacturing readiness value to production routing lines so downstream subcontracting can tell whether an operation can actually begin. The value is calculated from predecessor output and can be surfaced to users in routing views and the subcontracting factbox. The Subcontracting Worksheet's Suggest Lines flow gets an opt-in `Only Ready Operations` toggle, so existing behavior stays unchanged until users enable readiness filtering. The `CreateSubcontracting` action remains unchanged.

## 2. Architecture & Design Decisions
The implementation spans BaseApp manufacturing logic and the Subcontracting app. BaseApp adds field 7308 `Quantity Ready to Start` to table 5409 and exposes it as a hidden column on page 99000817. The readiness algorithm is centralized in `Prod. Order Routing Line`.`RecalculateQuantityReadyToStartForRouting()`, which builds a routing snapshot, uses `Posted Output Quantity` flowfields, treats first operations as ready at their own `Input Quantity`, applies each predecessor's `Send-Ahead Quantity` (or full `Input Quantity` when send-ahead is zero), and stores the minimum qualifying predecessor output for join operations. Table insert/modify/delete triggers call the same snapshot-based recalculation so routing edits reuse the posting rule instead of introducing a second algorithm.

Output posting in codeunit 99000822 recalculates the routing after each posted output update and emits telemetry. Upgrade codeunit 104062 adds a per-company upgrade step guarded by a new upgrade tag, filters to `Released` and `Firm Planned` production orders, recalculates each routing once, and logs completion telemetry. Reopen handling subscribes to `OnTransferReopenProdOrderRtngLineOnAfterInsert` and reuses the same table recalculation after finished orders are reopened.

Subcontracting surfaces the new value in the factbox and in report 20505's request page. Because static symbol visibility for the new BaseApp field was unreliable across the app boundary, the Subcontracting app reads field 7308 through `RecordRef`/`FieldRef` instead of a direct field reference. The real diff also shows one behavior detail worth documenting: telemetry `QRTS-0003` is emitted per skipped routing line when the filter is enabled and readiness is zero, with `RoutingLinesExcludedCount = 1`, rather than once per report run with an aggregated count.

## 3. Object/API Surface Changed
| Object type | Object | Change |
|---|---|---|
| Table | 5409 `Prod. Order Routing Line` | Added field 7308 `Quantity Ready to Start` and snapshot-based recalculation logic reused by posting, routing edits, upgrade, and reopen flows. |
| Page | 99000817 `Prod. Order Routing` | Added hidden-by-default `Quantity Ready to Start` column. |
| Codeunit | 99000822 `Mfg. Item Jnl.-Post Line` | Recalculates routing readiness after output posting and logs `QRTS-0001`. |
| Codeunit | 5407 `Prod. Order Status Management` | Added reopen subscriber that recalculates readiness on transferred reopened routing lines. |
| Codeunit | 104062 `Mfg. Upgrade BaseApp` | Added per-company upgrade recalculation for open production orders and logs `QRTS-0002`. |
| Codeunit | 9998 `Upgrade Tag Definitions` | Defined and registered `QRTS-QuantityReadyToStartUpgradeTag-20261010` in `RegisterPerCompanyTags` for the upgrade step. |
| Page | 20502 `Subc. Routing Info Factbox` | Added visible factbox field that reads `Quantity Ready to Start` via `RecordRef`/`FieldRef`. |
| Report | 20505 `Subc. Calculate Subcontracts` | Added `Only Ready Operations` request-page toggle, skip logic for zero-readiness lines, and `QRTS-0003` telemetry. |
| Test codeunit | 137141 `SCM Quantity Ready to Start` | Added manufacturing tests for field creation, posting thresholds, join/min behavior, and routing-edit recalculation. |
| Test codeunit | 139999 `Subc. Quantity Ready Test` | Added subcontracting tests for toggle-off, toggle-on skip, and toggle-on keep behavior. |
| App manifest | `src\Layers\W1\BaseApp\app.json` | Version bumped to `30.0.0.2` for validated local republish of the modified BaseApp. |
| App manifest | `src\Layers\W1\Tests\SCM-Manufacturing\app.json` | Version bumped to `30.0.0.2` for the manufacturing validation app. |
| App manifest | `src\Apps\W1\Subcontracting\App\app.json` | Version bumped to `30.0.0.1` for validated local republish of the Subcontracting app. |
| App manifest | `src\Apps\W1\Subcontracting\Test\app.json` | Version bumped to `30.0.0.3` and dependency updated to the new Subcontracting app version. |

## 4. Telemetry Events Emitted
| Event id | Event tag | FeatureTelemetry method | Object | When it fires | Custom dimensions |
|---|---|---|---|---|---|
| QRTS-0001 | `Quantity Ready to Start calculated on output posting` | `Session.LogMessage` | Codeunit 99000822 `Mfg. Item Jnl.-Post Line` | After posted output updates a routing line, the routing-wide readiness value is recalculated, and the updated line is re-read. | `TelemetryScope::ExtensionPublisher`; `ProdOrderNo`, `RoutingLineOperationNo`, `QuantityReadyToStart` |
| QRTS-0002 | `Quantity Ready to Start upgrade recalculation completed` | `Session.LogMessage` | Codeunit 104062 `Mfg. Upgrade BaseApp` | Once per company after the upgrade step recalculates open (`Released`/`Firm Planned`) production-order routings and sets the upgrade tag. | `TelemetryScope::ExtensionPublisher`; `CompanyName`, `ProductionOrdersProcessedCount` |
| QRTS-0003 | `Subc. Calculate Subcontracts run with Only Ready Operations filter enabled` | `Session.LogMessage` | Report 20505 `Subc. Calculate Subcontracts` | Each time the request-page toggle is enabled and a routing line with `Quantity Ready to Start = 0` is skipped from Suggest Lines. | `TelemetryScope::ExtensionPublisher`; `ProdOrderNo`, `RoutingLinesExcludedCount` (`1` per skipped line) |

## 5. Test Coverage Summary
- `add-quantity-ready-to-start-field` — test `SCM Quantity Ready to Start:QuantityReadyToStartFieldExistsWithDefaultValue`; evidence: `C:\Repos\FeatureBuilderState\quantity-ready-to-start\artifacts\build\add-quantity-ready-to-start-field\tests\results-green-d11\ALTest_20261010_195308.xml` and `C:\Repos\FeatureBuilderState\quantity-ready-to-start\artifacts\build\quantity-ready-to-start-tests-results\ALTest_20261010_202317.xml`.
- `compute-quantity-ready-to-start-on-posting` — tests `SCM Quantity Ready to Start:QuantityReadyToStartRemainsZeroUntilPredecessorThresholdReached` and `SCM Quantity Ready to Start:QuantityReadyToStartUsesMinimumAcrossImmediatePredecessors`; evidence: `C:\Repos\FeatureBuilderState\quantity-ready-to-start\artifacts\build\quantity-ready-to-start-tests-results\ALTest_20261010_202317.xml`.
- `recalculate-quantity-ready-to-start-on-routing-edit` — tests `SCM Quantity Ready to Start:InsertingNewFirstOperationRecalculatesQuantityReadyToStart` and `SCM Quantity Ready to Start:DeletingFirstOperationPromotesNextOperationReadiness`; evidence: `C:\Repos\FeatureBuilderState\quantity-ready-to-start\artifacts\build\quantity-ready-to-start-tests-results\ALTest_20261010_202317.xml`.
- `upgrade-recalculate-quantity-ready-to-start` — evidence: `C:\Repos\FeatureBuilderState\quantity-ready-to-start\artifacts\build\quantity-ready-to-start-tests-results\ALTest_20261010_202317.xml`; Base Application `30.0.0.2` publish/sync/upgrade succeeded on NST NAV as recorded in `backlog.md`.
- `recompute-quantity-ready-to-start-on-reopen` — evidence: `C:\Repos\FeatureBuilderState\quantity-ready-to-start\artifacts\build\quantity-ready-to-start-tests-results\ALTest_20261010_202317.xml`; Base Application `30.0.0.2` publish/sync/upgrade succeeded on NST NAV as recorded in `backlog.md`.
- `subc-routing-info-factbox-field` — no dedicated factbox-only test is recorded in the backlog; review evidence: `C:\Repos\FeatureBuilderState\quantity-ready-to-start\artifacts\build\quantity-ready-to-start-subc-tests-results-v3\ALTest_20261010_204111.xml`.
- `subc-calc-subcontracts-readiness-toggle` — tests `Subc. Quantity Ready Test:CalculateSubcontractsKeepsZeroReadinessLinesWhenToggleDisabled`, `Subc. Quantity Ready Test:CalculateSubcontractsSkipsZeroReadinessLinesWhenToggleEnabled`, and `Subc. Quantity Ready Test:CalculateSubcontractsKeepsReadyLinesWhenToggleEnabled`; evidence: `C:\Repos\FeatureBuilderState\quantity-ready-to-start\artifacts\build\quantity-ready-to-start-subc-tests-results-v3\ALTest_20261010_204111.xml`.

## 6. Known Limitations / Follow-ups
No blocked deliverables were recorded in `backlog.md`. One round of Good Sense Reviewer feedback
(review-gh-pr) was addressed before merge-readiness:
- Fixed a join-operation minimum-across-predecessors calculation bug where a legitimate zero
  readiness value from one predecessor could be overwritten by a later, larger predecessor value
  (the `0` sentinel was ambiguous with "not yet set"). Added a dedicated regression test
  (`QuantityReadyToStartUsesMinimumAcrossImmediatePredecessorsIncludingZero`).
- Registered the new per-company upgrade tag in `RegisterPerCompanyTags` so new companies are
  correctly bypassed by the standard upgrade-tag framework instead of relying on the upgrade
  codeunit's own `IsEmpty` check.
- Marked field 7308 `Quantity Ready to Start` `Editable = false` since it is a derived/computed
  value, consistent with sibling accumulated fields on the same table.

Remaining suggestions from that review round (moderate/minor severity, not blocking) are tracked
for a future iteration: clarifying that the posting/routing-edit/upgrade/reopen recomputation runs
unconditionally for all manufacturing customers regardless of the Subcontracting toggle; centralizing
the hardcoded field number `7308` used via `RecordRef`/`FieldRef` in the Subcontracting app;
aggregating the `QRTS-0003` telemetry event per report run instead of per skipped line; and aligning
the new upgrade tag's naming convention with the `MS-<workitem>-...` pattern used by sibling tags.
