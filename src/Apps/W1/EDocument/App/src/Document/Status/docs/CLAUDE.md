# Status

The Status folder implements the State pattern for E-Document status management through interface implementations. It defines the status enum with 30+ values and three status behavior codeunits that categorize states as In Progress, Processed, or Error.

## Quick reference

- **Files:** 5 AL files (3 codeunits, 2 enums)
- **ID range:** 6106 (status enum/codeunits), 6107 (document status enum)
- **Interface:** IEDocumentStatus with 3 implementations
- **Extension model:** Extensible enum allows partner-defined status values

## How it works

The E-Document Service Status enum implements **IEDocumentStatus** interface, mapping each enum value to one of three behavior implementations: In Progress, Processed, or Error. When E-Document Core calculates overall status, it queries all Service Status records, calls GetEDocumentStatus() on each enum value's interface implementation, and applies precedence rules (Error > In Progress > Processed).

This pattern decouples status representation (enum values) from status behavior (interface implementations), allowing partners to add custom status values without modifying core logic. The default implementation is "In Progress", so new enum values automatically get safe behavior unless explicitly overridden.

## Structure

- `EDocumentServiceStatus.Enum.al` -- 30+ status values with interface mappings
- `EDocumentStatus.Enum.al` -- Overall document status (In Progress, Processed, Error)
- `EDocInProgressStatus.Codeunit.al` -- Returns "In Progress" (default)
- `EDocProcessedStatus.Codeunit.al` -- Returns "Processed"
- `EDocErrorStatus.Codeunit.al` -- Returns "Error"

## Documentation

- [Extensibility](extensibility.md) -- Adding custom status values, interface patterns

## Things to know

- **Interface implementation per value:** Each enum value can specify its own IEDocumentStatus implementation via `Implementation = IEDocumentStatus = "Codeunit Name"` syntax.
- **Default implementation:** If not specified, enum values use the default implementation set in `DefaultImplementation = IEDocumentStatus = "E-Doc In Progress Status"`.
- **Status precedence:** Error > In Progress > Processed. If any service has Error status, overall E-Document status is Error.
- **Clearance model values:** Values 30-40 are reserved for clearance-related statuses (Not Cleared, Cleared) used in QR code validation flows.
- **Extensible enum:** Partners can add enum values like `value(100; "Custom Status") { Implementation = IEDocumentStatus = "Custom Status Codeunit"; }` without forking.
- **AssignmentCompatibility:** The enum uses `AssignmentCompatibility = true` to allow assignment between base and extended enum values.
- **Minimal interface:** IEDocumentStatus has only one method: `GetEDocumentStatus(): Enum "E-Document Status"`, keeping implementations simple.
- **No state storage:** Status codeunits are stateless; they simply return the appropriate E-Document Status enum value.
- **Service Status vs Document Status:** E-Document Service Status (this folder) tracks per-service state; E-Document Status (parent enum) represents overall document state.
- **Version 1 vs 2 status values:** Some values (e.g., "Journal Line Created") are used only in Version 1 import process; Version 2 uses different status progression.
