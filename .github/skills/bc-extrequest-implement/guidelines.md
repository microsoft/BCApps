# Extension fix guidelines

These guidelines supplement the code surgery rules in
`.github/skills/bc-extrequest-implement/code-guidelines.md`.
They contain both general AL declaration rules and integration-event-specific rules. Apply the
general rules to every extensibility change and the event-specific rules only when adding or
changing integration events.

## Integration event syntax

### Integration event declaration

```al
[IntegrationEvent(IncludeSender: Boolean, GlobalVarAccess: Boolean)]
local procedure EventName(Parameters)
begin
end;
```

**Parameters:**

- `IncludeSender`: Usually `false`. Set to `true` only when subscribers need the sender object.
- `GlobalVarAccess`: Usually `false`. Set to `true` only when subscribers must access globals.

### Event publisher pattern

```al
local procedure DoSomething(var SalesHeader: Record "Sales Header")
var
	IsHandled: Boolean;
begin
	IsHandled := false;
	OnBeforeDoSomething(SalesHeader, IsHandled);
	if IsHandled then
		exit;

	// Standard logic here

	OnAfterDoSomething(SalesHeader);
end;
```

## Integration event naming

### Event name format

All events must follow the standard naming pattern based on where they are raised, regardless of
any suggested name.

**Pattern components:**

- Prefix: Always `On`
- Procedure or trigger name: The containing procedure or trigger
- Timing: `OnBefore` or `OnAfter`
- Action context: The specific action when the event is in the middle of the flow

### Events at the beginning or end of a procedure or trigger

Use `OnBefore[ProcedureOrTriggerName]` or `OnAfter[ProcedureOrTriggerName]` when the event fires
at the very start or very end.

| Location | Event name |
|----------|------------|
| `PostSalesLine` procedure, beginning | `OnBeforePostSalesLine` |
| `PostSalesLine` procedure, end | `OnAfterPostSalesLine` |
| `OnInsert` trigger, beginning | `OnBeforeOnInsert` |
| `OnModify` trigger, end | `OnAfterOnModify` |
| `Sell-to Customer No.` `OnValidate`, beginning | `OnBeforeValidateSellToCustomerNo` |
| `Quantity` `OnValidate`, end | `OnAfterValidateQuantity` |

```al
procedure PostSalesLine(var SalesLine: Record "Sales Line")
begin
	OnBeforePostSalesLine(SalesLine);

	ValidateLine(SalesLine);
	CalculateAmounts(SalesLine);
	InsertEntries(SalesLine);

	OnAfterPostSalesLine(SalesLine);
end;
```

### Events in the middle of a procedure or trigger

Use `On[ProcedureOrTriggerName]OnBefore[ActionContext]` or
`On[ProcedureOrTriggerName]OnAfter[ActionContext]` when the event is raised around a specific step
inside the flow.

| Location | Event name |
|----------|------------|
| `PostSalesLine` before validation | `OnPostSalesLineOnBeforeValidateLine` |
| `PostSalesLine` after calculation | `OnPostSalesLineOnAfterCalculateAmounts` |
| `Code` procedure before check | `OnCodeOnBeforeCheck` |
| `OnInsert` after init defaults | `OnOnInsertOnAfterInitDefaults` |
| `OnModify` before location validation | `OnOnModifyOnBeforeValidateLocationCode` |

```al
procedure PostSalesLine(var SalesLine: Record "Sales Line")
begin
	OnPostSalesLineOnBeforeValidateLine(SalesLine);
	ValidateLine(SalesLine);

	OnPostSalesLineOnAfterValidateLine(SalesLine);

	CalculateAmounts(SalesLine);

	OnPostSalesLineOnAfterCalculateAmounts(SalesLine);

	InsertEntries(SalesLine);
end;
```

### The same requested hook at multiple action points

When a request asks for one conceptual event at two or more distinct action points, create a
separate event for each action point. Do not publish the same event from semantically different
locations.

- Keep the parameter contract and publisher attributes consistent when each location needs the same
  subscriber context.
- Name each event from its exact placement and operation so the difference is visible.
- Raise each event at its own anchor. Do not move multiple calls to a shared later location.
- Treat operations such as `Insert`, `Modify`, `Delete`, and `Validate` as distinct action points,
  even when the request describes them as one hook.

For example, a request for the same subscriber context after either modifying or inserting a
temporary line requires two events:

```al
if TempSalesLine.IsTemporaryUpdate then begin
	TempSalesLine.Modify();
	OnCreateLinesOnAfterModifyTempSalesLine(TempSalesLine, SalesHeader);
end else begin
	TempSalesLine.Insert();
	OnCreateLinesOnAfterInsertTempSalesLine(TempSalesLine, SalesHeader);
end;

[IntegrationEvent(false, false)]
local procedure OnCreateLinesOnAfterModifyTempSalesLine(var TempSalesLine: Record "Sales Line" temporary; SalesHeader: Record "Sales Header")
begin
end;

[IntegrationEvent(false, false)]
local procedure OnCreateLinesOnAfterInsertTempSalesLine(var TempSalesLine: Record "Sales Line" temporary; SalesHeader: Record "Sales Header")
begin
end;
```

### Naming examples

Incorrect:

```al
[IntegrationEvent(false, false)]
local procedure OnBeforePost(var SalesLine: Record "Sales Line")
begin
end;
```

Correct:

```al
[IntegrationEvent(false, false)]
local procedure OnBeforePostSalesLine(var SalesLine: Record "Sales Line")
begin
end;

[IntegrationEvent(false, false)]
local procedure OnPostSalesLineOnBeforeValidation(var SalesLine: Record "Sales Line")
begin
end;
```

### Quick reference

- Beginning or end: `OnBefore` or `OnAfter` + procedure or trigger name
- Middle of flow: `On` + procedure or trigger name + `OnBefore` or `OnAfter` + action context

## Integration event parameter naming

### Record parameters

Use the AL table name with spaces removed. Do not abbreviate record parameter names.

| Table name | Correct parameter | Avoid |
|------------|-------------------|-------|
| `Sales Header` | `SalesHeader` | `SalesHdr`, `SH` |
| `Sales Line` | `SalesLine` | `SalesLn`, `SL` |
| `Item Ledger Entry` | `ItemLedgerEntry` | `ItemLedgEntry`, `ILE` |
| `G/L Entry` | `GLEntry` | `GLE`, `GenLedgEntry` |
| `Purchase Header` | `PurchaseHeader` | `PurchHdr`, `PH` |
| `Customer` | `Customer` | `Cust`, `C` |
| `Vendor` | `Vendor` | `Vend`, `V` |

Incorrect:

```al
[IntegrationEvent(false, false)]
local procedure OnBeforePost(var SalesHdr: Record "Sales Header"; var ItemLedgEntry: Record "Item Ledger Entry")
begin
end;
```

Correct:

```al
[IntegrationEvent(false, false)]
local procedure OnBeforePost(var SalesHeader: Record "Sales Header"; var ItemLedgerEntry: Record "Item Ledger Entry")
begin
end;
```

### Simple type parameters

Use descriptive names for simple types. Do not abbreviate them.

| Avoid | Correct |
|-------|---------|
| `DocNo` | `DocumentNo` |
| `Amt` | `Amount` or `TotalAmount` |
| `Qty` | `Quantity` |
| `Desc` | `Description` |
| `Date` | `PostingDate`, `DocumentDate`, or another precise name |

Incorrect:

```al
[IntegrationEvent(false, false)]
local procedure OnBeforePost(DocNo: Code[20]; Amt: Decimal; Qty: Decimal)
begin
end;
```

Correct:

```al
[IntegrationEvent(false, false)]
local procedure OnBeforePost(DocumentNo: Code[20]; TotalAmount: Decimal; Quantity: Decimal)
begin
end;
```

### Temporary record parameters

All temporary record parameters in event signatures must use the `Temp` prefix.

Rationale:

- It makes the temporary nature explicit to subscribers.
- It prevents confusion about persistence.
- It follows standard BC naming conventions.

Incorrect:

```al
[IntegrationEvent(false, false)]
local procedure OnAfterProcess(var InvtOrderTracking: Record "Invt. Order Tracking" temporary)
begin
end;
```

```al
[IntegrationEvent(false, false)]
local procedure OnBeforeCalculate(var Buffer: Record Item temporary)
begin
end;
```

Correct:

```al
[IntegrationEvent(false, false)]
local procedure OnAfterProcess(var TempInvtOrderTracking: Record "Invt. Order Tracking" temporary)
begin
end;
```

```al
[IntegrationEvent(false, false)]
local procedure OnBeforeCalculate(var TempItem: Record Item temporary)
begin
end;
```

Common temporary prefixes:

- `TempBuffer`
- `TempItem`
- `TempCustomer`
- `TempInteger`

## General AL variable declaration order

Use the same type-group order when placing new variables in local procedure `var` sections and
global variable sections:

1. Record variables
2. `RecordRef` and `FieldRef`
3. Codeunit variables
4. Enums
5. Other complex types
6. Code
7. Text
8. Numeric types such as `Integer` and `Decimal`
9. Boolean variables

This rule determines where to insert a newly required variable. Do not reorder existing variables
solely to make an existing declaration section comply. When the surrounding declarations are not
already ordered, place the new variable beside the nearest matching type group without moving
unrelated declarations.

Example for a local procedure:

```al
procedure ProcessDocument()
var
	SalesHeader: Record "Sales Header";
	ItemLedgerEntry: Record "Item Ledger Entry";
	RecRef: RecordRef;
	FldRef: FieldRef;
	NoSeriesMgt: Codeunit NoSeriesManagement;
	DocumentType: Enum "Gen. Journal Document Type";
	JsonObject: JsonObject;
	DocumentNo: Code[20];
	Description: Text[100];
	LineNo: Integer;
	Amount: Decimal;
	IsHandled: Boolean;
begin
end;
```

Example for global variables:

```al
codeunit 50100 "My Processor"
{
	var
		Customer: Record Customer;
		RecRef: RecordRef;
		MyCodeunit: Codeunit "My Helper";
		MyEnum: Enum "Email Scenario";
		JsonObject: JsonObject;
		ReferenceNo: Code[20];
		MessageText: Text[250];
		RetryCount: Integer;
		SuccessRate: Decimal;
		CanPost: Boolean;
}
```

## Integration event signature changes

### Preserve parameter order

Preserve the existing parameter order exactly. When adding a parameter to an existing event, append
it at the end of the signature. Event call arguments must appear in the same order as the publisher
declaration.

Original event:

```al
[IntegrationEvent(false, false)]
local procedure OnBeforeProcess(var Customer: Record Customer; var IsHandled: Boolean)
begin
end;
```

Incorrect:

```al
[IntegrationEvent(false, false)]
local procedure OnBeforeProcess(var Customer: Record Customer; NewParam: Text; var IsHandled: Boolean)
begin
end;
```

Correct:

```al
[IntegrationEvent(false, false)]
local procedure OnBeforeProcess(var Customer: Record Customer; var IsHandled: Boolean; NewParam: Text)
begin
end;
```

### `IsHandled` parameter position

Use these rules together with preserving the order of existing parameters:

- For a new event, place `var IsHandled: Boolean` last, regardless of where a suggested signature
  places it.
- When adding `IsHandled` and other parameters to an existing event that does not already have
  `IsHandled`, append the other new parameters first and append `IsHandled` last.
- When an existing event already has `IsHandled`, do not move it. Append any additional parameters
  after the existing signature, even though `IsHandled` will no longer be last.
- Keep publisher call arguments in exactly the same order as the final event declaration.

Examples:

```al
// Existing event has no IsHandled. Add PreviewMode first and IsHandled last.
OnBeforePostSalesDocument(SalesHeader, PostingDate, PreviewMode, IsHandled);

[IntegrationEvent(false, false)]
local procedure OnBeforePostSalesDocument(var SalesHeader: Record "Sales Header"; PostingDate: Date; PreviewMode: Boolean; var IsHandled: Boolean)
begin
end;

// New event: IsHandled is last even when a suggested signature places it earlier.
OnBeforeCreateItemLedgerEntry(ItemJournalLine, Quantity, PostingDate, IsHandled);

[IntegrationEvent(false, false)]
local procedure OnBeforeCreateItemLedgerEntry(var ItemJournalLine: Record "Item Journal Line"; Quantity: Decimal; PostingDate: Date; var IsHandled: Boolean)
begin
end;

// Existing event already has IsHandled. Preserve its position and append new parameters.
OnBeforeReleasePurchaseDocument(PurchaseHeader, IsHandled, PreviewMode, SuppressCommit);

[IntegrationEvent(false, false)]
local procedure OnBeforeReleasePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; PreviewMode: Boolean; SuppressCommit: Boolean)
begin
end;
```

## IsHandled event rules

### Always initialize `IsHandled`

When adding an event with `IsHandled`, or when adding `IsHandled` to an existing event, set it to
`false` before calling the event.

Correct:

```al
procedure PostDocument(var SalesHeader: Record "Sales Header")
var
	IsHandled: Boolean;
begin
	IsHandled := false;
	OnBeforePostDocument(SalesHeader, IsHandled);
	if IsHandled then
		exit;

	// Standard logic
end;
```

Incorrect:

```al
procedure PostDocument(var SalesHeader: Record "Sales Header")
var
	IsHandled: Boolean;
begin
	OnBeforePostDocument(SalesHeader, IsHandled);
	if IsHandled then
		exit;

	// Standard logic
end;
```

### Adding `IsHandled` to an existing event

Before:

```al
procedure Process(var Customer: Record Customer)
begin
	OnBeforeProcess(Customer);
	// Standard logic
end;

[IntegrationEvent(false, false)]
local procedure OnBeforeProcess(var Customer: Record Customer)
begin
end;
```

After:

```al
procedure Process(var Customer: Record Customer)
var
	IsHandled: Boolean;
begin
	IsHandled := false;
	OnBeforeProcess(Customer, IsHandled);
	if IsHandled then
		exit;

	// Standard logic
end;

[IntegrationEvent(false, false)]
local procedure OnBeforeProcess(var Customer: Record Customer; var IsHandled: Boolean)
begin
end;
```

## Integration event review checklist

Use this checklist when adding or reviewing AL extensibility events:

- Event name matches its exact placement in the procedure or trigger.
- Record parameters use full table names with spaces removed.
- Temporary record parameters use the `Temp` prefix.
- Simple parameters use descriptive, non-abbreviated names.
- New parameters are appended at the end of existing signatures.
- `IsHandled` is explicitly initialized to `false` before the event call.
- `IncludeSender` and `GlobalVarAccess` stay `false` unless there is a concrete need.
