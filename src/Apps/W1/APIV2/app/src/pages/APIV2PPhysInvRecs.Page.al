// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.API.V2;

using Microsoft.Inventory.Counting.History;

page 30238 "APIV2 - P. Phys. Inv. Recs."
{
    APIVersion = 'v2.0';
    EntityCaption = 'Posted Physical Inventory Recording';
    EntitySetCaption = 'Posted Physical Inventory Recordings';
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    EntityName = 'postedPhysicalInventoryRecording';
    EntitySetName = 'postedPhysicalInventoryRecordings';
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = "Pstd. Phys. Invt. Record Hdr";
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(orderNumber; Rec."Order No.")
                {
                    Caption = 'Order No.';
                }
                field(recordingNumber; Rec."Recording No.")
                {
                    Caption = 'Recording No.';
                    Editable = false;
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(personResponsible; Rec."Person Responsible")
                {
                    Caption = 'Person Responsible';
                }
                field(allowRecordingWithoutOrder; Rec."Allow Recording Without Order")
                {
                    Caption = 'Allow Recording Without Order';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(binCode; Rec."Bin Code")
                {
                    Caption = 'Bin Code';
                }
                field(dateRecorded; Rec."Date Recorded")
                {
                    Caption = 'Date Recorded';
                }
                field(timeRecorded; Rec."Time Recorded")
                {
                    Caption = 'Time Recorded';
                }
                field(personRecorded; Rec."Person Recorded")
                {
                    Caption = 'Person Recorded';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
                part(postedPhysInvtRecordingLines; "APIV2 - P. Phys. Inv. R. Lines")
                {
                    Caption = 'Lines';
                    EntityName = 'postedPhysicalInventoryRecordingLine';
                    EntitySetName = 'postedPhysicalInventoryRecordingLines';
                    SubPageLink = "Order No." = field("Order No."), "Recording No." = field("Recording No.");
                }
                part(pdfDocument; "APIV2 - PDF Document")
                {
                    Caption = 'PDF Document';
                    Multiplicity = ZeroOrOne;
                    EntityName = 'pdfDocument';
                    EntitySetName = 'pdfDocument';
                    SubPageLink = "Document Id" = field(SystemId), "Document Type" = const("Posted Phys. Inventory Recording");
                }
                part(attachments; "APIV2 - Attachments")
                {
                    Caption = 'Attachments';
                    EntityName = 'attachment';
                    EntitySetName = 'attachments';
                    SubPageLink = "Document Id" = field(SystemId), "Document Type" = const("Posted Phys. Inventory Recording");
                }
                part(documentAttachments; "APIV2 - Document Attachments")
                {
                    Caption = 'Document Attachments';
                    EntityName = 'documentAttachment';
                    EntitySetName = 'documentAttachments';
                    SubPageLink = "Document Id" = field(SystemId), "Document Type" = const("Posted Phys. Inventory Recording");
                }
            }
        }
    }
}
