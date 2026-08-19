// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.API.V2;

using Microsoft.Inventory.Counting.Recording;

page 30236 "APIV2 - Phys. Invt. Recordings"
{
    APIVersion = 'v2.0';
    EntityCaption = 'Physical Inventory Recording';
    EntitySetCaption = 'Physical Inventory Recordings';
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    EntityName = 'physicalInventoryRecording';
    EntitySetName = 'physicalInventoryRecordings';
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = "Phys. Invt. Record Header";
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
                part(physInventoryRecordingLines; "APIV2 - Phys. Inv. Rec. Lines")
                {
                    Caption = 'Lines';
                    EntityName = 'physicalInventoryRecordingLine';
                    EntitySetName = 'physicalInventoryRecordingLines';
                    SubPageLink = "Order No." = field("Order No."), "Recording No." = field("Recording No.");
                }
                part(pdfDocument; "APIV2 - PDF Document")
                {
                    Caption = 'PDF Document';
                    Multiplicity = ZeroOrOne;
                    EntityName = 'pdfDocument';
                    EntitySetName = 'pdfDocument';
                    SubPageLink = "Document Id" = field(SystemId), "Document Type" = const("Phys. Inventory Recording");
                }
                part(attachments; "APIV2 - Attachments")
                {
                    Caption = 'Attachments';
                    EntityName = 'attachment';
                    EntitySetName = 'attachments';
                    SubPageLink = "Document Id" = field(SystemId), "Document Type" = const("Phys. Inventory Recording");
                }
                part(documentAttachments; "APIV2 - Document Attachments")
                {
                    Caption = 'Document Attachments';
                    EntityName = 'documentAttachment';
                    EntitySetName = 'documentAttachments';
                    SubPageLink = "Document Id" = field(SystemId), "Document Type" = const("Phys. Inventory Recording");
                }
            }
        }
    }
}
