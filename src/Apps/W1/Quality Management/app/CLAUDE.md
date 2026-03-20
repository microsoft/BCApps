# Quality Management

A comprehensive quality inspection framework for Business Central. Enables organizations to define quality tests, group them into reusable templates, configure rules that auto-generate inspections from business transactions (purchase receipts, production output, assembly, warehouse, transfers), record measurement results, and take disposition actions on non-conforming items. Currently an early-access feature available to partners.

## Quick reference

- **ID range**: 20400--20600
- **Namespace**: `Microsoft.Inventory.QualityManagement` (and sub-namespaces)
- **Dependencies**: None (extends base application directly)
- **Experience**: Essential for most features; Premium required for production output inspections

## How it works

The app follows a multi-level configuration hierarchy. At the base are **Quality Tests** -- individual measurements or checks with a value type (decimal, integer, boolean, text, option, table lookup, text expression). Tests are grouped into **Quality Inspection Templates**, which define sampling strategies (fixed quantity or percentage). **Inspection Generation Rules** connect templates to business events with item/vendor/location filters, so inspections are auto-created when specific transactions occur.

When an inspection is created (automatically, manually, or on schedule), the system clones the template's tests into inspection lines. Each line records a measured value that is evaluated against **Result Conditions** -- configurable rules that map value ranges or expressions to result codes (PASS, FAIL, INPROGRESS, or custom). Results have an **Evaluation Sequence** that determines priority: the system picks the highest-priority matching result. Conditions can be overridden at three levels: test defaults, template overrides, and inspection-specific overrides.

The inspection integrates deeply with BC's item tracking system. Results can block or allow specific transaction types per lot/serial/package -- a FAIL result can block sales, transfers, picks, and movements while still allowing put-away to quarantine. The system supports re-inspections (numbered chain) and workflow integration for approval, lot blocking, and automated disposition actions.

After finishing an inspection, **Dispositions** handle non-conforming items: change item tracking codes, create negative adjustments (scrap), move inventory (quarantine), create purchase returns, warehouse put-aways, or transfer orders. These can be triggered manually or via workflow responses.

## Structure

- `src/Configuration/` -- Tests, templates, results, conditions, generation rules, lookup values (46 files, the config hierarchy)
- `src/Integration/` -- Event subscribers and page extensions that hook QM into BC domains: purchasing, production, assembly, warehouse, sales, transfers, item tracking (67 files)
- `src/Dispositions/` -- Post-inspection actions: item tracking changes, negative adjustments, inventory moves, purchase returns, warehouse put-aways, transfer orders (22 files)
- `src/Document/` -- Inspection header/line tables and card/list pages
- `src/Utilities/` -- Expression evaluation, value parsing, boolean parsing, source field traversal helpers
- `src/Workflow/` -- BC workflow integration (approval events, lot blocking responses)
- `src/Setup/` -- Global setup table, guided experience, application area registration
- `src/Reports/` -- Certificate of Analysis, non-conformance report, bulk creation/scheduling reports
- `src/RoleCenters/` -- Quality Manager role center and cue table

## Documentation

- [docs/data-model.md](docs/data-model.md) -- Inspection hierarchy, configuration tables, result evaluation, item tracking blocking
- [docs/business-logic.md](docs/business-logic.md) -- Inspection creation, result evaluation, finishing, re-inspection, dispositions
- [docs/extensibility.md](docs/extensibility.md) -- 28+ integration events for customizing inspections, results, and workflows
- [src/Configuration/docs/CLAUDE.md](src/Configuration/docs/CLAUDE.md) -- Test, template, and generation rule configuration
- [src/Integration/docs/CLAUDE.md](src/Integration/docs/CLAUDE.md) -- Per-domain BC integration hooks
- [src/Dispositions/docs/CLAUDE.md](src/Dispositions/docs/CLAUDE.md) -- Post-inspection disposition actions
- [src/Utilities/docs/CLAUDE.md](src/Utilities/docs/CLAUDE.md) -- Expression and value evaluation
- [src/Workflow/docs/CLAUDE.md](src/Workflow/docs/CLAUDE.md) -- Workflow integration

## Things to know

- **Three creation modes** -- automatic (event-driven from posting), manual (from document lines or standalone), and scheduled (job queue with generation rules). The "intent" on a generation rule determines which BC event triggers creation.
- **Three-level condition override** -- result conditions can be set at the test level (defaults), overridden at the template level, and overridden again at the inspection level. The most specific wins.
- **Evaluation sequence determines result** -- when multiple conditions match, the result with the lowest evaluation sequence number wins. This is how FAIL overrides PASS when both conditions are met.
- **RecordId-based source tracking** -- inspections store up to 5 RecordIds plus 10 custom fields for source tracking. This allows attaching inspections to any BC table without schema changes.
- **Item tracking blocking is per-transaction-type** -- a result can block sales but allow put-away (quarantine scenario). Nine independent boolean fields control this per result code.
- **Re-inspection is a numbered chain** -- each re-inspection increments `Re-inspection No.` on the same `No.`. Only the most recent re-inspection is flagged as active for transaction blocking.
- **Expression tests reference other lines** -- a test with `Test Value Type = Text Expression` can reference other line values via formulas, creating computed fields within an inspection.
- **Table Lookup tests** -- tests can reference any BC table/field for dropdown values, with configurable filters. This avoids hardcoding option lists.
- **Feature is early access** -- as of 2025/2026, available only in partner sandbox environments. Auto-installs on new environments; manual install from AppSource for existing ones.
- **`_Obsolete` note** -- there is no _Obsolete folder in this app; it's a clean, modern codebase.
