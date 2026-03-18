# Extensibility

The Status folder demonstrates interface-based extensibility, allowing partners to add custom status values and behaviors without modifying core code.

## Adding custom status values

Partners can extend the E-Document Service Status enum to add custom status values:

```al
enumextension 50100 "My Status Values" extends "E-Document Service Status"
{
    value(50100; "Pending Manager Approval")
    {
        Caption = 'Pending Manager Approval';
        Implementation = IEDocumentStatus = "E-Doc In Progress Status";
    }

    value(50101; "Approved by Manager")
    {
        Caption = 'Approved by Manager';
        Implementation = IEDocumentStatus = "E-Doc Processed Status";
    }

    value(50102; "Approval Rejected")
    {
        Caption = 'Approval Rejected';
        Implementation = IEDocumentStatus = "E-Doc Error Status";
    }
}
```

**Interface mapping:** Each value specifies which behavior codeunit to use. In this example:
- "Pending Manager Approval" uses In Progress behavior (document not finalized)
- "Approved by Manager" uses Processed behavior (final success state)
- "Approval Rejected" uses Error behavior (requires user intervention)

**No core code changes:** E-Document Core's status aggregation logic automatically handles new enum values by calling their interface implementations.

## Custom status behavior

Partners can implement custom status logic by creating a new IEDocumentStatus codeunit:

```al
codeunit 50100 "My Status Behavior" implements IEDocumentStatus
{
    procedure GetEDocumentStatus(): Enum "E-Document Status"
    begin
        // Custom logic to determine overall status
        if SomeCondition() then
            exit(Enum::"E-Document Status"::Processed)
        else
            exit(Enum::"E-Document Status"::"In Progress");
    end;

    local procedure SomeCondition(): Boolean
    begin
        // Custom business logic
        exit(CurrentDateTime > SpecificDeadline);
    end;
}
```

Then reference it in enum extension:

```al
value(50103; "Time-Based Status")
{
    Implementation = IEDocumentStatus = "My Status Behavior";
}
```

**Use case:** Status that changes behavior based on external factors (time, approval count, service response).

## Status precedence customization

Partners can influence status aggregation by choosing interface implementations strategically:

```al
value(50104; "Pending External Validation")
{
    // Treat as error to prevent progression until validation completes
    Implementation = IEDocumentStatus = "E-Doc Error Status";
}
```

**Effect:** If any service has this status, overall E-Document status becomes Error, blocking further processing until validation is resolved.

## Interface pattern benefits

**Separation of concerns:** Status representation (enum) is separate from status behavior (interface implementation).

**Open-closed principle:** New status values can be added without modifying existing code.

**Polymorphic behavior:** Core code calls `IEDocumentStatus.GetEDocumentStatus()` without knowing which codeunit implements it.

**Default safety:** The `DefaultImplementation` ensures new enum values get safe behavior (In Progress) unless explicitly overridden.

## Status transition events

Partners can subscribe to status changes:

```al
[EventSubscriber(ObjectType::Table, Database::"E-Document Service Status", 'OnBeforeModifyEvent', '', false, false)]
local procedure OnStatusChange(var Rec: Record "E-Document Service Status"; var xRec: Record "E-Document Service Status")
begin
    if Rec.Status <> xRec.Status then
        LogStatusTransition(Rec, xRec);
end;
```

**Use case:** Audit trail, notifications, or triggering downstream processes when status changes.

## Workflow integration

Custom status values can trigger Workflow Management actions:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsToLibrary', '', false, false)]
local procedure AddCustomWorkflowEvents()
begin
    WorkflowEventHandling.AddEventToLibrary(
        'EDOC_STATUS_MANAGER_APPROVAL',
        Database::"E-Document Service Status",
        'E-Document reaches Pending Manager Approval status',
        0, false);
end;
```

This allows configuring workflows like "When E-Document Status = Pending Manager Approval, send notification to manager".

## Clearance model extension example

The clearance model values (30-40 range) demonstrate this pattern:

```al
enum 6106 "E-Document Service Status" implements IEDocumentStatus
{
    #region clearance model 30 - 40
    value(30; "Not Cleared")
    {
        Caption = 'Not Cleared';
        // Uses default In Progress implementation
    }
    value(31; "Cleared")
    {
        Caption = 'Cleared';
        Implementation = IEDocumentStatus = "E-Doc Processed Status";
    }
    #endregion
}
```

**Region comment:** Documents that clearance-related values belong to a specific feature set, making it easy to identify purpose.

**Cleared = Processed:** Once a document is cleared by the tax authority, it's treated as fully processed (final state).

## Testing custom status values

Partners should test status aggregation with multiple services:

```al
// Create E-Document with 3 service statuses
EDocument.Create(...);
ServiceStatus1.Status := ServiceStatus1.Status::"Exported";  // Processed
ServiceStatus2.Status := ServiceStatus2.Status::"Pending Manager Approval";  // In Progress
ServiceStatus3.Status := ServiceStatus3.Status::"Approval Rejected";  // Error

// Verify overall status is Error (highest precedence)
Assert.AreEqual(EDocument.Status, EDocument.Status::Error, 'Should prioritize error status');
```

## Best practices

1. **Use existing implementations when possible:** Don't create new codeunits unless custom logic is needed.

2. **Document custom status values:** Add XML comments explaining when each status is used.

3. **Follow numbering convention:** Use 50000+ range for partner extensions to avoid conflicts.

4. **Test status transitions:** Verify that status changes don't break existing logic (especially status precedence).

5. **Consider localization:** Status captions should be translatable via XLIFF files for multi-language support.
