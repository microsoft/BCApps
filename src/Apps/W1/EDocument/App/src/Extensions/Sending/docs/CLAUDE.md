# Extensions Sending

The Extensions/Sending subdirectory extends Business Central's standard Document Sending Profile infrastructure to support E-Document workflows. It adds E-Document service flow selection to sending profiles, validates workflow configuration, and integrates with the E-Mail Attachment options to enable automatic E-Document processing when documents are posted. This layer bridges the gap between BC's native send-to-email functionality and the E-Document Core processing pipeline.

## Quick reference

- **Files:** 5 extensions (1 table, 2 pages, 2 enums)
- **Base objects:** Document Sending Profile table/page, Electronic Document format enums
- **Integration:** E-Document workflows via "Electronic Service Flow" field
- **Trigger:** Post-and-send actions on sales documents

## What it does

E-Document Sending Profile extends the Document Sending Profile table with an "Electronic Service Flow" field that stores a Workflow Code reference. This field appears when the user selects "Extended E-Document Service Flow" in the Electronic Document dropdown, enabling them to choose which E-Document workflow should process the document when it's posted. The field is validated to ensure the selected workflow exists, is enabled, and has Category 'EDOC'.

The page extension modifies the Document Sending Profile page UI to show the workflow selection field only when "Extended E-Document Service Flow" is selected, hiding the legacy "Through Document Exchange Service" fields. It also controls visibility of electronic document format email options based on the E-Mail Attachment selection, preventing format selection when E-Document or PDF+E-Document are chosen (since E-Document workflows control format, not sending profile).

When a user posts a sales invoice and chooses "Post and Send" with an E-Document-enabled sending profile, the system validates that a workflow is assigned and enabled. The workflow then processes the document through export, format, and send steps based on the service configuration. This eliminates manual document submission -- posting automatically triggers E-Document creation and service transmission.

The enum extensions add "E-Document" and "PDF & E-Document" values to the E-Mail Attachment format enum, and "Extended E-Document Service Flow" to the Electronic Document enum. These values enable users to select E-Document processing in the sending profile configuration UI, with appropriate validation triggers to ensure workflow consistency.

## Key files

**EDocumentSendingProfile.TableExt.al** (2KB, 43 lines) -- Extends "Document Sending Profile" table (ID 60) with field 6102 "Electronic Service Flow" (Code 20, TableRelation to Workflow where Category = 'EDOC'). OnAfterValidate trigger on "E-Mail Attachment" field calls ValidateThatEDocumentWorkflow when user selects E-Document or PDF & E-Document attachment types. ValidateThatEDocumentWorkflow checks that Electronic Document = "Extended E-Document Service Flow", validates Electronic Service Flow is assigned, retrieves Workflow record, and tests that Enabled = true.

**EDocumentSendingProfile.PageExt.al** (3KB, 85 lines) -- Extends "Document Sending Profile" page (ID 60). Adds EDocumentFlow group with "E-Document Workflow" field (Caption, bound to "Electronic Service Flow"), visible only when Electronic Document = "Extended E-Document Service Flow". OnValidate trigger logs feature telemetry (FeatureTelemetry.LogUptake with status "Set Up"). Modifies Electronic Document field visibility based on whether any Electronic Document Format or E-Document Service records exist. Controls email format field visibility (hides when E-Mail Attachment is PDF, E-Document, or PDF & E-Document).

**EDocSendingProfAttType.EnumExt.al** (722 bytes, 22 lines) -- Extends "E-Mail Attachment Type" enum (ID 60) with two values: "E-Document" (ordinal 3, Caption 'Electronic Document') and "PDF & E-Document" (ordinal 4, Caption 'PDF & Electronic Document'). These options appear in the E-Mail Attachment dropdown on Document Sending Profile setup, allowing users to specify that posted documents should generate E-Documents instead of or in addition to PDF email attachments.

**EDocSendProfileElecDoc.EnumExt.al** (658 bytes, 20 lines) -- Extends "Electronic Document Format Usage" enum (ID 61) with value "Extended E-Document Service Flow" (ordinal 2, Caption). This option appears in the Electronic Document dropdown, enabling E-Document workflow selection. When selected, the page shows the "E-Document Workflow" field for workflow assignment.

**EDocSelectSendingOptions.PageExt.al** (3KB, 138 lines) -- Extends "Select Sending Options" page (ID 60) which appears when user clicks "Post and Send" on sales documents. No visible changes to UI; extension is placeholder for future customization of send options dialog specific to E-Documents (e.g., service-specific parameters, batch send options).

## Send profile configuration flow

1. **User opens Document Sending Profile setup** (via Customer Card, Vendor Card, or standalone page)

2. **User configures electronic document:**
   - Set "Electronic Document" = "Extended E-Document Service Flow"
   - "Electronic Service Flow Code" field becomes visible
   - User selects workflow from dropdown (filtered to Category = 'EDOC', Enabled = true)

3. **User configures email attachment:**
   - Set "E-Mail Attachment" = "E-Document" or "PDF & E-Document"
   - System validates that Electronic Document = "Extended E-Document Service Flow"
   - System validates that Electronic Service Flow is assigned and enabled
   - If validation fails, error message displayed

4. **User saves sending profile:**
   - Profile stored with workflow reference
   - Telemetry event logged (E-Document feature uptake: "Set Up")

5. **User assigns profile to customer:**
   - Open Customer Card → Sending tab
   - Set "Document Sending Profile" to configured profile
   - Now all sales documents for this customer will use E-Document workflow

## Post-and-send execution flow

1. **User posts sales invoice with "Post and Send" action**

2. **BC post processing:**
   - Sales Invoice Header created
   - Posting complete (ledger entries, customer balance updated)

3. **Send profile evaluation:**
   - System reads Customer."Document Sending Profile"
   - Reads Sending Profile."Electronic Document" and "Electronic Service Flow"

4. **E-Document workflow trigger:**
   - If Electronic Document = "Extended E-Document Service Flow":
     - Workflow engine starts workflow instance for posted document
     - Workflow Step 1: Create E-Document (via "E-Document Created from Sales" event)
     - E-Document record created with Direction::Outgoing, Status::"In Progress"
     - Workflow continues through configured steps (Export → Send → Wait for response)

5. **Email handling (if configured):**
   - If E-Mail Attachment = "E-Document":
     - Email sent with E-Document format attachment (e.g., PEPPOL XML)
   - If E-Mail Attachment = "PDF & E-Document":
     - Email sent with two attachments: PDF report and E-Document format
   - If E-Mail Attachment = "PDF":
     - Standard BC behavior, no E-Document processing

6. **User sees result:**
   - Sales Invoice posted and visible in Posted Sales Invoices
   - E-Document visible in E-Documents page with Status "In Progress" or "Sent"
   - Email sent if E-Mail option configured
   - User can track service status via E-Document Card

## How it connects

Document Sending Profile is BC standard infrastructure used by sales, purchase, and service documents for post-and-send scenarios. E-Document Core hooks into this via the "Extended E-Document Service Flow" enum value and workflow trigger.

When a document is posted with an E-Document-enabled sending profile, the workflow engine (System.Automation) starts the assigned workflow. The workflow invokes E-Document Workflow Processing codeunits to create the E-Document record and begin processing steps. E-Document Processing reads the workflow configuration to determine which services to use, which formats to apply, and whether to send synchronously or async.

The "Electronic Service Flow" field is a workflow code reference (table relation to Workflow table). Workflows are designed via Workflow Designer page (standard BC feature) with E-Document-specific templates. Templates define event sequence: Create → Validate → Export → Send → Response → Approval. Partners can customize workflows to add approval steps, custom actions, or conditional branching.

E-Mail Attachment integration uses BC's standard email sending infrastructure. When "E-Document" or "PDF & E-Document" is selected, the system generates the E-Document formatted blob (from E-Document Log Data Storage) and attaches it to the email instead of or in addition to the standard PDF report. This allows recipients to receive both human-readable (PDF) and machine-readable (XML/JSON) formats simultaneously.

## Things to know

- **Workflow must be enabled** -- ValidateThatEDocumentWorkflow checks Workflow.Enabled = true. If user disables workflow after assigning to profile, post-and-send will fail with validation error.
- **Category 'EDOC' filter** -- Electronic Service Flow field TableRelation filters to Workflow where Category = 'EDOC'. Only E-Document workflows appear in dropdown, not general approval or notification workflows.
- **Sending profile is per-customer** -- Each customer can have different sending profile. Multi-customer batch posting uses profile from each customer's card, allowing mixed E-Document and standard PDF sends in same batch.
- **Email is optional** -- User can configure Electronic Document = "Extended E-Document Service Flow" without configuring E-Mail. Document will create E-Document and send to service, but no email sent to customer. Useful for EDI-style direct submission.
- **PDF+E-Document generates twice** -- If user selects "PDF & E-Document", system generates PDF report via standard BC reporting engine and E-Document format via E-Document export. Both attached to same email. Increases processing time but provides compatibility for recipients who can't process structured formats.
- **Template field removed** -- Legacy BC had "Electronic Document Format" field for PEPPOL/OIOUBL format selection. This is hidden when "Extended E-Document Service Flow" is selected because workflow controls format via E-Document Service."Document Format" configuration.
- **Telemetry on setup** -- When user validates Electronic Service Flow field, system logs E-Document feature uptake event with status "Set Up". Used by Microsoft telemetry for adoption tracking.

## Extensibility

Partners can extend sending profile behavior via events in E-Document Processing and Workflow Processing codeunits. Common extension scenarios:

**Custom sending profile fields:**

```al
tableextension 50100 "My Sending Profile" extends "Document Sending Profile"
{
    fields
    {
        field(50100; "Custom Service Option"; Option)
        {
            OptionMembers = " ","Option1","Option2";
        }
    }
}

pageextension 50100 "My Sending Profile Page" extends "Document Sending Profile"
{
    layout
    {
        addafter("E-Document Workflow")
        {
            field("Custom Service Option"; Rec."Custom Service Option")
            {
                Visible = Rec."Electronic Document" = Rec."Electronic Document"::"Extended E-Document Service Flow";
            }
        }
    }
}
```

**Custom send validation:**

```al
[EventSubscriber(ObjectType::Table, Database::"Document Sending Profile", OnBeforeValidateElectronicServiceFlow, '', false, false)]
local procedure OnBeforeValidateElectronicServiceFlow(var Rec: Record "Document Sending Profile"; var IsHandled: Boolean)
begin
    // Add custom validation logic
    if Rec."Custom Service Option" = Rec."Custom Service Option"::" " then
        Error('Custom service option must be specified');
end;
```

**Custom post-and-send behavior:**

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Document Processing", OnBeforeCreateEDocument, '', false, false)]
local procedure OnBeforeCreateEDocument(var SourceDocumentHeader: RecordRef; var IsHandled: Boolean)
var
    SalesInvoiceHeader: Record "Sales Invoice Header";
begin
    SourceDocumentHeader.SetTable(SalesInvoiceHeader);

    // Skip E-Document creation for certain customers
    if IsCustomerExempt(SalesInvoiceHeader."Sell-to Customer No.") then begin
        IsHandled := true;
        exit;
    end;
end;
```

No specific extensibility interfaces defined at this layer. Extensions hook into workflow and processing layers where E-Document creation and send logic execute.
