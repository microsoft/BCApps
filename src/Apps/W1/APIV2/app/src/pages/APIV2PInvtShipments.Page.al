// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.API.V2;

using Microsoft.Inventory.History;

page 30244 "APIV2 - P. Invt. Shipments"
{
    APIVersion = 'v2.0';
    EntityCaption = 'Posted Inventory Shipment';
    EntitySetCaption = 'Posted Inventory Shipments';
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    EntityName = 'postedInventoryShipment';
    EntitySetName = 'postedInventoryShipments';
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = "Invt. Shipment Header";
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
                field(number; Rec."No.")
                {
                    Caption = 'No.';
                    Editable = false;
                }
                field(postingDescription; Rec."Posting Description")
                {
                    Caption = 'Posting Description';
                }
                field(documentDate; Rec."Document Date")
                {
                    Caption = 'Document Date';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';
                }
                field(salespersonCode; Rec."Salesperson Code")
                {
                    Caption = 'Salesperson Code';
                }
                field(externalDocumentNumber; Rec."External Document No.")
                {
                    Caption = 'External Document No.';
                }
                field(genBusPostingGroup; Rec."Gen. Bus. Posting Group")
                {
                    Caption = 'Gen. Bus. Posting Group';
                }
                field(shipmentNumber; Rec."Shipment No.")
                {
                    Caption = 'Shipment No.';
                }
                field(correction; Rec.Correction)
                {
                    Caption = 'Correction';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
                part(dimensionSetLines; "APIV2 - Dimension Set Lines")
                {
                    Caption = 'Dimension Set Lines';
                    EntityName = 'dimensionSetLine';
                    EntitySetName = 'dimensionSetLines';
                    SubPageLink = "Parent Id" = field(SystemId), "Parent Type" = const("Posted Inventory Shipment");
                }
                part(postedInvtShipmentLines; "APIV2 - P. Invt. Shpt. Lines")
                {
                    Caption = 'Lines';
                    EntityName = 'postedInventoryShipmentLine';
                    EntitySetName = 'postedInventoryShipmentLines';
                    SubPageLink = "Document No." = field("No.");
                }
                part(pdfDocument; "APIV2 - PDF Document")
                {
                    Caption = 'PDF Document';
                    Multiplicity = ZeroOrOne;
                    EntityName = 'pdfDocument';
                    EntitySetName = 'pdfDocument';
                    SubPageLink = "Document Id" = field(SystemId), "Document Type" = const("Posted Inventory Shipment");
                }
                part(attachments; "APIV2 - Attachments")
                {
                    Caption = 'Attachments';
                    EntityName = 'attachment';
                    EntitySetName = 'attachments';
                    SubPageLink = "Document Id" = field(SystemId), "Document Type" = const("Posted Inventory Shipment");
                }
                part(documentAttachments; "APIV2 - Document Attachments")
                {
                    Caption = 'Document Attachments';
                    EntityName = 'documentAttachment';
                    EntitySetName = 'documentAttachments';
                    SubPageLink = "Document Id" = field(SystemId), "Document Type" = const("Posted Inventory Shipment");
                }
            }
        }
    }
}
