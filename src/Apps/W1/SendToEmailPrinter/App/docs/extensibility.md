# Extensibility

This document describes the extensibility model of the Send To Email Printer feature.

## Extension architecture

The Send To Email Printer feature is designed as a **closed functional feature**. It is not intended to be extended by partners or ISVs. Instead, it demonstrates a pattern that partners can follow to implement their own printer types.

## Platform integration points

The feature integrates with Business Central through two platform event subscriptions:

### SetupPrinters event

- **Purpose**: Registers available email printers with the platform
- **Handler**: Codeunit 2650 "Email Printer Setup"
- **Behavior**: Iterates through Email Printer Settings records and builds JSON descriptors for each printer

### OnDocumentPrintReady event

- **Purpose**: Handles print jobs directed to email printers
- **Handler**: Codeunit 2651 "Email Printer Document Ready"
- **Behavior**: Processes the document stream and sends it via email

## Enum extensions

### Email Printer Scenario

The feature extends the base Email Scenario enum to register a new scenario type:

- **Enum value**: 202 ("Email Printer")
- **Purpose**: Identifies which email account to use when sending printed documents
- **ID range**: Uses a value outside the normal range with suppressed warnings to avoid conflicts

## Page extensions

### Printer Management extension

The feature extends the Printer Management page to add discoverability:

- **Action**: "Add an email printer" in the creation area
- **Purpose**: Provides a clear entry point for users to configure email printers

## API surface

All codeunit procedures are marked as **internal**. There is no public API surface for ISVs or partners to call. This is an intentional design decision that reinforces the feature's purpose as a complete, self-contained printer implementation rather than an extensible framework.

## Enum extensibility

The Email Printer Paper Unit enum is **not extensible**. It is locked to two values:

- Inches
- Millimeters

This restriction ensures consistent paper dimension handling across the platform.

## Pattern for partners

While this feature itself is not extensible, it demonstrates an **event-driven architecture** that partners can replicate:

1. Subscribe to the `SetupPrinters` event to register custom printer types
2. Subscribe to the `OnDocumentPrintReady` event to handle print jobs
3. In the event handler, check if the printer belongs to your implementation (by name or other identifier)
4. Exit early if the printer is not yours, allowing other subscribers to handle it
5. Set the `Success` parameter to true if you successfully handle the job

This pattern allows **multiple printer extensions to coexist** peacefully. Each subscriber checks whether the print job is directed at "their" printer type and exits if not, creating a cooperative chain of handlers.

## Design philosophy

The closed design reflects these principles:

- **Completeness**: The feature provides a complete, working printer implementation out of the box
- **Pattern demonstration**: It serves as a reference implementation for partners building their own printer types
- **Stability**: By not exposing internal APIs, the implementation can evolve without breaking partner code
- **Coexistence**: The event-driven model allows multiple printer types to work together without conflicts
