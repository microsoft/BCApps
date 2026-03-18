# Extensions RoleCenter

The Extensions/RoleCenter subdirectory extends Business Central role center pages to display E-Document activity cues, enabling users to monitor incoming E-Document processing status directly from their home pages. These extensions add cue groups with drill-down actions to role centers for accountants, business managers, invoice/approval managers, and warehouse workers, providing at-a-glance visibility into E-Document processing backlogs and errors.

## Quick reference

- **Files:** 5 page extensions (role center activities)
- **Target roles:** Accountant, Business Manager, Invoice Manager, Warehouse workers
- **Cue types:** Incoming E-Document status counts (Processed, In Progress, Error)
- **Drill-down:** Opens filtered E-Documents page for detail view

## What it does

E-Doc. A/P Admin Activities extends the Acc. Payable Activities page (Accounts Payable admin role center) with an "Incoming E-Document" cue group. This group displays three counters: Processed (documents successfully imported and converted to purchase documents), In Progress (documents currently being structured/matched/drafted), and Error (documents that failed import or matching). Each cue is clickable, opening the E-Documents list filtered to the corresponding status and incoming direction.

The other four role center extensions (Accountant RC, Business Manager RC, Invoice Manager RC, Ship/Rec/Wms RC) add the "E-Document Activities" part to their respective role center pages. This part displays activity cues for both incoming and outgoing E-Documents, providing broader visibility than the A/P-specific extension. The part placement varies by role center layout, typically appearing after approval or activity sections.

Cue counts are calculated on page open, querying E-Document table with filters for Status (Processed, In Progress, Error) and Direction (Incoming). The counts refresh when user navigates back to role center home page or manually refreshes. No automatic refresh occurs; user must re-open page to see updated counts.

Drill-down actions call E-Document Helper.OpenEDocuments(Status, Direction) which opens the E-Documents page with filters applied. User sees filtered list and can navigate to individual E-Document cards for detailed investigation, error messages, and retry actions.

## Key files

**EDocAPAdminActivities.PageExt.al** (3KB, 66 lines) -- Extends "Acc. Payable Activities" page (ID 9027) with "IncomingEDocument" cue group containing three fields: IncomingEDocumentProcessedCount, IncomingEDocumentInProgressCount, IncomingEDocumentErrorCount. Each field has Caption, ToolTip, and OnDrillDown trigger calling E-Document Helper to open filtered page. OnOpenPage trigger queries E-Document table to populate counts via EDocumentHelper.GetEDocumentCount for each status+direction combination.

**EDocAccountantRC.PageExt.al** (338 bytes, 15 lines) -- Extends "Accountant Role Center" page (ID 9022) to add "E-Document Activities" part after "ApprovalsActivities" section. Part references "E-Document Activities" page (not included in this directory; lives in main activities section). Minimal extension, just inserts pre-built activities part into layout.

**EDocBusManagerRC.PageExt.al** (359 bytes, 16 lines) -- Extends "Business Manager Role Center" page (ID 9020) with same pattern: adds "E-Document Activities" part after activities section. Provides E-Document visibility to users in Business Manager role.

**EDocInvManagerRC.PageExt.al** (354 bytes, 15 lines) -- Extends "Invoice Manager Role Center" page (not documented which page ID) with E-Document Activities part. Invoice managers see incoming invoice E-Documents and can drill down to process errors or review matches.

**EDocShipRecWmsRC.PageExt.al** (353 bytes, 15 lines) -- Extends warehouse/shipping role center pages with E-Document Activities part. Less commonly used for E-Documents (typically A/P invoice-focused) but provides visibility for warehouses that receive electronic packing slips or delivery notes.

## Cue calculation algorithm

**OnOpenPage trigger (A/P Admin Activities example):**

```al
trigger OnOpenPage()
begin
    IncomingEDocumentInProgressCount := EDocumentHelper.GetEDocumentCount(
        Enum::"E-Document Status"::"In Progress",
        Enum::"E-Document Direction"::Incoming
    );

    IncomingEDocumentProcessedCount := EDocumentHelper.GetEDocumentCount(
        Enum::"E-Document Status"::Processed,
        Enum::"E-Document Direction"::Incoming
    );

    IncomingEDocumentErrorCount := EDocumentHelper.GetEDocumentCount(
        Enum::"E-Document Status"::Error,
        Enum::"E-Document Direction"::Incoming
    );
end;
```

**E-Document Helper.GetEDocumentCount implementation:**

```al
procedure GetEDocumentCount(Status: Enum "E-Document Status"; Direction: Enum "E-Document Direction"): Integer
var
    EDocument: Record "E-Document";
begin
    EDocument.SetRange(Status, Status);
    EDocument.SetRange(Direction, Direction);
    exit(EDocument.Count());
end;
```

Simple count query with two filters. Executes on page open; result cached in page variable until page closed.

## Drill-down action algorithm

**OnDrillDown trigger:**

```al
field(IncomingEDocumentProcessedCount; IncomingEDocumentProcessedCount)
{
    ApplicationArea = Basic, Suite;
    Caption = 'Processed';
    ToolTip = 'Specifies the number of processed e-document';

    trigger OnDrillDown()
    begin
        EDocumentHelper.OpenEDocuments(
            Enum::"E-Document Status"::Processed,
            Enum::"E-Document Direction"::Incoming
        );
    end;
}
```

**E-Document Helper.OpenEDocuments implementation:**

```al
procedure OpenEDocuments(Status: Enum "E-Document Status"; Direction: Enum "E-Document Direction")
var
    EDocument: Record "E-Document";
    EDocumentsPage: Page "E-Documents";
begin
    EDocument.SetRange(Status, Status);
    EDocument.SetRange(Direction, Direction);
    EDocumentsPage.SetTableView(EDocument);
    EDocumentsPage.Run();
end;
```

Opens E-Documents list page with filters applied. User sees filtered view, can edit filters, or navigate to E-Document Card for individual records.

## User workflow

**Accounts Payable coordinator daily routine:**

1. **Open BC client, navigate to Accounts Payable role center**

2. **Check Incoming E-Document cues:**
   - Processed: 15 (documents converted to purchase invoices/orders)
   - In Progress: 3 (documents being matched to orders)
   - Error: 2 (documents failed structure or matching)

3. **Click Error count (2) to drill down:**
   - E-Documents page opens filtered to Status = Error, Direction = Incoming
   - See two documents with error indicators

4. **Click first error document to open E-Document Card:**
   - Review error messages in error list factbox
   - Error: "Vendor not found for Tax ID '12345678'"
   - User creates missing vendor, clicks "Retry" action
   - Document status changes to In Progress

5. **Click second error document:**
   - Error: "Purchase order not found for Order No 'PO-2024-001'"
   - User determines order was not created yet, clicks "Create Draft Purchase Invoice" action
   - Document status changes to Processed

6. **Return to role center:**
   - Refresh page to see updated counts
   - Error count now 0
   - In Progress count increased to 4 (one document moved from Error)
   - Processed count increased to 16 (one document finalized)

## How it connects

Role center extensions are pure UI additions; they don't modify business logic. Cue calculations call E-Document Processing helper methods which query E-Document table. Drill-downs open E-Documents page which is the standard list page for E-Document records.

E-Document Activities part (referenced by 4 of the 5 extensions) is a separate page defined in Activities directory (not in this subdirectory). The part displays multiple cue groups: incoming status cues, outgoing status cues, service error counts. Role center extensions insert this part into their layouts, inheriting all functionality.

Cue counts are snapshots at page open time. If background jobs process E-Documents while role center is open, counts don't update until user navigates away and back. Consider this for busy environments where documents process continuously.

E-Document Helper (in Processing directory) provides the OpenEDocuments method used by drill-downs. This centralizes filter logic, ensuring consistent behavior across all role center drill-downs and other places that open filtered E-Document lists.

## Things to know

- **Cue counts are read-only** -- Users cannot edit counts; they reflect database state at page open time. To reduce counts, user must process E-Documents (clear errors, complete matching).
- **No automatic refresh** -- Counts don't update while role center page is open. User must close and re-open page or use refresh action if available. Consider adding refresh action for busy environments.
- **Incoming direction only for A/P** -- A/P Admin Activities shows only incoming counts (purchase invoices received from vendors). Outgoing E-Documents (sales invoices sent to customers) are not relevant to A/P role.
- **Activities part is shared** -- Four role centers use same "E-Document Activities" part. Changes to that part affect all role centers. A/P Admin uses custom embedded cues instead of shared part.
- **Role-based visibility** -- Cues only appear for users assigned to corresponding roles. User must have permission set for Accountant RC, Business Manager RC, etc. to see E-Document cues.
- **ApplicationArea Basic, Suite** -- Cue fields use ApplicationArea = Basic, Suite, making them visible in all BC editions (Essentials, Premium). E-Document is not edition-restricted.

## Extensibility

Partners can add E-Document cues to additional role centers or customize existing cue groups:

**Add cues to custom role center:**

```al
pageextension 50100 "My Role Center E-Doc" extends "My Custom Role Center"
{
    layout
    {
        addlast(Control1)
        {
            part(EDocumentActivities; "E-Document Activities")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }
}
```

**Add custom cues to existing role center:**

```al
pageextension 50101 "Custom E-Doc Cues" extends "Acc. Payable Activities"
{
    layout
    {
        addafter(IncomingEDocumentErrorCount)
        {
            field(IncomingEDocumentPendingApproval; PendingApprovalCount)
            {
                Caption = 'Pending Approval';
                ToolTip = 'E-Documents waiting for approval';

                trigger OnDrillDown()
                begin
                    OpenPendingApprovalEDocuments();
                end;
            }
        }
    }

    var
        PendingApprovalCount: Integer;

    trigger OnOpenPage()
    begin
        // Calculate custom cue
        PendingApprovalCount := GetPendingApprovalCount();
    end;

    local procedure GetPendingApprovalCount(): Integer
    var
        EDocument: Record "E-Document";
    begin
        // Custom filter logic
        EDocument.SetRange(Direction, EDocument.Direction::Incoming);
        EDocument.SetRange("Approval Status", "Approval Status"::"Pending Approval");
        exit(EDocument.Count());
    end;
}
```

**Add background refresh:**

```al
pageextension 50102 "E-Doc Auto Refresh" extends "Acc. Payable Activities"
{
    actions
    {
        addlast(Processing)
        {
            action(RefreshEDocCues)
            {
                Caption = 'Refresh E-Document Counts';
                Image = Refresh;

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
```

Or use page background tasks (BC 2021+) for automatic refresh:

```al
trigger OnOpenPage()
begin
    CurrPage.EnqueueBackgroundTask(RefreshTaskId, Codeunit::"E-Doc Cue Refresh", '', 30000); // 30 second refresh
end;

trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
begin
    if TaskId = RefreshTaskId then begin
        IncomingEDocumentInProgressCount := Results.Get('InProgressCount');
        IncomingEDocumentProcessedCount := Results.Get('ProcessedCount');
        IncomingEDocumentErrorCount := Results.Get('ErrorCount');
        CurrPage.Update(false);
        CurrPage.EnqueueBackgroundTask(RefreshTaskId, Codeunit::"E-Doc Cue Refresh", '', 30000);
    end;
end;
```

No events are provided at this layer; extensibility is via standard BC page extension patterns.
