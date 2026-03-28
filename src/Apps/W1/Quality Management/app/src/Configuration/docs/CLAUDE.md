# Configuration

Defines the entire quality inspection configuration hierarchy: what to measure (tests), how to group measurements (templates), when to auto-create inspections (generation rules), and how to evaluate outcomes (results and conditions). This is where all the "blueprints" live -- actual inspections are created from these definitions.

## How it works

The hierarchy flows upward: **Quality Tests** define individual measurements with value types (decimal, boolean, text, table lookup, expression, etc.) and default allowable values. Tests are grouped into **Quality Inspection Templates** with sampling strategies (fixed quantity or percentage of source quantity). **Inspection Generation Rules** connect templates to business events via intent + trigger enums and item/attribute filters, enabling automatic inspection creation.

**Result evaluation** is configured through **Quality Inspection Results** (codes like PASS, FAIL, INPROGRESS) and **Result Conditions** that map value ranges/expressions to result codes. Conditions exist at three levels -- test defaults, template overrides, and inspection-specific overrides. The most specific level wins. Each result has an `Evaluation Sequence` that determines priority when multiple conditions match.

## Things to know

- **Test Value Types are rich** -- beyond simple decimal/text, there are Table Lookup (picks from any BC table/field with filters), Text Expression (formulas referencing other inspection lines), Option (from lookup values), and Value Type Label (display-only).
- **QltyTestLookupValue** stores custom picklist values for tests -- alternative to Table Lookup when you don't want to reference a real BC table.
- **Sampling is template-level** -- `Sample Source` (Fixed Quantity or Percent of Quantity) determines how many units to inspect. This is inherited by the inspection header's `Sample Size`.
- **Generation rules match by Intent** -- the `Intent` enum (Purchase, Production, Transfer, Assembly, Warehouse, Sales Return, Warehouse Receipt) determines which BC events trigger the rule. Each intent has its own trigger enum (e.g., `Purchase Order Trigger: On Receipt | On Invoice`).
- **Result conditions support complex expressions** -- ranges (`10..20`), comparisons (`>=80`), lists (`RED|GREEN|BLUE`), boolean combinations. The `QltyBooleanParsing` codeunit in Utilities handles parsing.
- **Generation rules have a Schedule Group** for job-queue-based scheduled inspection creation, separate from event-driven automatic creation.
