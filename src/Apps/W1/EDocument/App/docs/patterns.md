# Patterns

E-Document Core uses several architectural patterns specific to electronic document processing. These patterns enable extensibility, maintain audit trails, and handle the complexity of bidirectional workflows.

## Interface-driven processing pipeline

**File reference:** `src/Service Integration/`

The core architecture registers processing implementations via enum-based interface resolution. Instead of hardcoding which codeunit handles PEPPOL or UBL, the system:

1. **Defines interfaces** -- IEDocFileFormat, IDocumentSender, IStructureReceivedEDocument, etc.
2. **Creates enum extensions** -- Each service/format adds an enum value
3. **Implements interfaces** -- Service codeunits implement relevant interfaces
4. **Registers via enum** -- At runtime, system queries enum value → interface mapping

Example: When exporting a document, the system reads the service's "Document Format" enum value, resolves the implementing codeunit, and calls `IEDocFileFormat.CreateDocument()`. This allows partners to add formats without modifying dispatch logic.

**Gotcha:** Interface implementations must be registered in enum extensions. Simply implementing the interface isn't enough; the enum value binding connects the dots. Missing enum registration causes "No implementation found" errors.

## State machine for import

**File reference:** `src/Processing/ImportEDocumentProcess.Codeunit.al`

Inbound documents progress through a 4-step state machine tracked by boolean flags on the E-Document record:

- `Structure Done` -- Document parsed and type identified
- `Read Done` -- Data extracted into Imported Line records
- `Prepare Done` -- Order matches suggested/applied
- `Finish Done` -- Purchase Header/Line created

Each step is idempotent: running "Read" twice produces the same Imported Lines. Steps can be undone, resetting subsequent steps' flags. For example, "Undo Prepare" clears both `Prepare Done` and `Finish Done`, allowing users to re-match with different parameters.

**Status calculation:** The overall E-Document Status is derived from flags, not stored:
- No flags set → "In Progress"
- Structure/Read done, Prepare/Finish not done → "In Progress"
- All flags set → "Processed"
- Any Service Status has errors → "Error"

**Gotcha:** Don't store derived status in the E-Document table. Always calculate from flags and Service Status records. Storing status creates sync issues when statuses change.

## AOAI Function pattern

**File reference:** `src/Copilot/`, `src/AI/AOAIFunction.Interface.al`

The AOAI Function pattern implements OpenAI's function calling protocol for structured LLM outputs. The system:

1. **Defines functions** -- Codeunits implement `AOAI Function` interface with `GetPrompt()` and `Execute()` methods
2. **Builds request** -- Calls `GetPrompt()` to get system prompt + function definitions JSON
3. **Sends to AOAI** -- Posts JSON to Azure OpenAI with `tools` array
4. **Parses response** -- Extracts `function_call` objects from response
5. **Invokes handlers** -- Looks up function by name, calls `Execute(arguments)` with extracted parameters
6. **Returns result** -- Sends function result back to AOAI for final answer

Example: Order matching defines a `match_purchase_line` function. AOAI receives imported line data, decides which function to call, and returns `{"name": "match_purchase_line", "arguments": {"item_no": "1000", "quantity": 5}}`. The system invokes the handler, which queries purchase orders and returns match suggestions.

**Activity log session:** All AOAI calls append to a single "E-Document Activity Log" session, creating conversation history. This allows multi-turn interactions where later prompts reference earlier results.

**Gotcha:** Function arguments are JSON, not strongly typed. Parse carefully and validate before executing logic. Invalid JSON or missing parameters cause runtime errors, not compile errors.

## Context pattern for HTTP operations

**File reference:** `src/Processing/SendContext.Codeunit.al`, `ReceiveContext.Codeunit.al`

HTTP operations bundle multiple objects into a single context codeunit:

- **SendContext** -- Contains TempBlob (formatted document), HttpRequestMessage, HttpResponseMessage, send options
- **ReceiveContext** -- Contains TempBlob (received document), HttpRequestMessage, HttpResponseMessage, receive options
- **ActionContext** -- Contains TempBlob, HttpRequestMessage, HttpResponseMessage, action parameters

Interfaces receive a context parameter rather than individual objects. This:
- **Reduces parameter counts** -- Pass one context instead of 5 objects
- **Enables versioning** -- Add new context fields without breaking interfaces
- **Bundles related data** -- TempBlob and HTTP messages travel together

Example: `IDocumentSender.Send(SendContext)` receives the formatted document blob, HTTP client config, and status callback in one object.

**Gotcha:** Context codeunits are reference types. Modifying a context inside an interface implementation affects the caller's view. Don't accidentally overwrite blobs or HTTP messages that other implementations need.

## RecordRef generic mapping

**File reference:** `src/Mapping/EDocMapping.Codeunit.al`

The mapping engine uses RecordRef to transform data between arbitrary tables without hardcoded field references. This enables:
- **Generic inbound mapping** -- Map external XML/JSON to any Business Central table
- **Cross-extension mapping** -- Map between tables without direct dependencies
- **Runtime configuration** -- Users define mappings via UI, not code

The 3-pass algorithm:

**Pass 1: Direct fields** -- For each mapping rule, read source field by number, write to target field by number. Handle type conversions (text → decimal, text → date).

**Pass 2: Formulas** -- Evaluate formula expressions (e.g., `Field(5) * Field(6)` for line amount). Use AL formula engine to parse and compute.

**Pass 3: Transformation rules** -- Apply Transformation Rule references for complex mappings (external codes → Business Central codes). Transformation rules can call codeunits for custom logic.

**Context preservation:** Operate on temporary RecordRef first. Only after all mappings succeed, insert real records. This ensures atomicity -- either all fields map successfully or none persist.

**Gotcha:** RecordRef field access is runtime-checked, not compile-time. Field numbers must exist on the target table. Missing fields cause runtime errors. Always validate mapping definitions before executing.

## Temporary record staging

**File reference:** `src/Draft/EDocPurchaseHeader.Table.al`, `EDocPurchaseLine.Table.al`

Inbound purchase drafts populate temporary E-Document Purchase Header/Line records before creating real Purchase Header/Line records. This:
- **Enables multi-step transformation** -- Structure step → Read step → Mapping step each add fields
- **Allows user review** -- User sees drafted data before committing
- **Simplifies rollback** -- Discard temp records if user cancels

The temporary tables mirror Purchase Header/Line schemas but add e-document-specific fields (Source SystemId, Import Status, Confidence Score). The Finish step copies temp records to real tables, applying validation and defaults.

**Gotcha:** Temporary records don't trigger standard Purchase Header/Line validation. Re-validate when inserting real records, or discrepancies appear (e.g., blank "Buy-from Vendor No." passes temp insert but fails real insert).

## Legacy patterns

**File reference:** `src/Service Integration V1/` (obsolete interfaces)

### Obsolete interfaces

Three interfaces are marked obsolete with CLEAN26/CLEAN27 tags:

- **IBlobToStructuredDataConverter** -- Replaced by IStructureReceivedEDocument (simpler contract, no ADI dependency)
- **IBlobType** -- Replaced by format enum + IStructuredFormatReader (better discoverability)
- **IPurchaseLineAccountProvider** -- Replaced by IPurchaseLineProvider (more flexible, supports non-account fields)

These remain in the codebase for backward compatibility but should not be used in new code. The replacement interfaces provide cleaner contracts and better integration with the 4-step state machine.

### Service Integration V1

The original service integration model used direct codeunit coupling: E-Document Service table stored codeunit IDs for send/receive/format operations. V2 replaced this with interface-driven enum registration.

V1 code paths still exist for services that haven't migrated. When `Send Codeunit ID` is populated, the system invokes the legacy codeunit directly. When blank, it resolves the service's format enum to an interface implementation.

**Migration path:** Services should implement IDocumentSender/IDocumentReceiver interfaces, register enum values, and clear legacy codeunit ID fields. The system auto-detects V2 implementations and uses them preferentially.

**Gotcha:** Don't mix V1 and V2. A service using V1 send + V2 format causes confusion because send passes blobs in a different structure than format produces. Migrate all three operations (send, receive, format) together.
