// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.API.V2;

using Microsoft.Inventory.Transfer;

page 30206 "APIV2 - Trans. Shipments"
{
    APIVersion = 'v2.0';
    EntityCaption = 'Transfer Shipment';
    EntitySetCaption = 'Transfer Shipments';
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    EntityName = 'transferShipment';
    EntitySetName = 'transferShipments';
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = "Transfer Shipment Header";
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
                field(transferOrderNumber; Rec."Transfer Order No.")
                {
                    Caption = 'Transfer Order No.';
                }
                field(transferFromCode; Rec."Transfer-from Code")
                {
                    Caption = 'Transfer-from Code';
                }
                field(transferFromName; Rec."Transfer-from Name")
                {
                    Caption = 'Transfer-from Name';
                }
                field(transferFromName2; Rec."Transfer-from Name 2")
                {
                    Caption = 'Transfer-from Name 2';
                }
                field(transferFromAddress; Rec."Transfer-from Address")
                {
                    Caption = 'Transfer-from Address';
                }
                field(transferFromAddress2; Rec."Transfer-from Address 2")
                {
                    Caption = 'Transfer-from Address 2';
                }
                field(transferFromCity; Rec."Transfer-from City")
                {
                    Caption = 'Transfer-from City';
                }
                field(transferFromCounty; Rec."Transfer-from County")
                {
                    Caption = 'Transfer-from County';
                }
                field(transferFromPostCode; Rec."Transfer-from Post Code")
                {
                    Caption = 'Transfer-from Post Code';
                }
                field(transferFromCountryRegionCode; Rec."Trsf.-from Country/Region Code")
                {
                    Caption = 'Transfer-from Country/Region Code';
                }
                field(transferFromContact; Rec."Transfer-from Contact")
                {
                    Caption = 'Transfer-from Contact';
                }
                field(transferToCode; Rec."Transfer-to Code")
                {
                    Caption = 'Transfer-to Code';
                }
                field(transferToName; Rec."Transfer-to Name")
                {
                    Caption = 'Transfer-to Name';
                }
                field(transferToName2; Rec."Transfer-to Name 2")
                {
                    Caption = 'Transfer-to Name 2';
                }
                field(transferToAddress; Rec."Transfer-to Address")
                {
                    Caption = 'Transfer-to Address';
                }
                field(transferToAddress2; Rec."Transfer-to Address 2")
                {
                    Caption = 'Transfer-to Address 2';
                }
                field(transferToCity; Rec."Transfer-to City")
                {
                    Caption = 'Transfer-to City';
                }
                field(transferToCounty; Rec."Transfer-to County")
                {
                    Caption = 'Transfer-to County';
                }
                field(transferToPostCode; Rec."Transfer-to Post Code")
                {
                    Caption = 'Transfer-to Post Code';
                }
                field(transferToCountryRegionCode; Rec."Trsf.-to Country/Region Code")
                {
                    Caption = 'Transfer-to Country/Region Code';
                }
                field(transferToContact; Rec."Transfer-to Contact")
                {
                    Caption = 'Transfer-to Contact';
                }
                field(transferOrderDate; Rec."Transfer Order Date")
                {
                    Caption = 'Transfer Order Date';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
                }
                field(shipmentDate; Rec."Shipment Date")
                {
                    Caption = 'Shipment Date';
                }
                field(receiptDate; Rec."Receipt Date")
                {
                    Caption = 'Receipt Date';
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';
                }
                field(inTransitCode; Rec."In-Transit Code")
                {
                    Caption = 'In-Transit Code';
                }
                field(externalDocumentNumber; Rec."External Document No.")
                {
                    Caption = 'External Document No.';
                }
                field(shippingAgentCode; Rec."Shipping Agent Code")
                {
                    Caption = 'Shipping Agent Code';
                }
                field(shippingAgentServiceCode; Rec."Shipping Agent Service Code")
                {
                    Caption = 'Shipping Agent Service Code';
                }
                field(shipmentMethodCode; Rec."Shipment Method Code")
                {
                    Caption = 'Shipment Method Code';
                }
                field(directTransfer; Rec."Direct Transfer")
                {
                    Caption = 'Direct Transfer';
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
                    SubPageLink = "Parent Id" = field(SystemId), "Parent Type" = const("Transfer Shipment");
                }
                part(transferShipmentLines; "APIV2 - Trans. Shpt. Lines")
                {
                    Caption = 'Lines';
                    EntityName = 'transferShipmentLine';
                    EntitySetName = 'transferShipmentLines';
                    SubPageLink = "Document No." = field("No.");
                }
                part(pdfDocument; "APIV2 - PDF Document")
                {
                    Caption = 'PDF Document';
                    Multiplicity = ZeroOrOne;
                    EntityName = 'pdfDocument';
                    EntitySetName = 'pdfDocument';
                    SubPageLink = "Document Id" = field(SystemId), "Document Type" = const("Transfer Shipment");
                }
                part(attachments; "APIV2 - Attachments")
                {
                    Caption = 'Attachments';
                    EntityName = 'attachment';
                    EntitySetName = 'attachments';
                    SubPageLink = "Document Id" = field(SystemId), "Document Type" = const("Transfer Shipment");
                }
                part(documentAttachments; "APIV2 - Document Attachments")
                {
                    Caption = 'Document Attachments';
                    EntityName = 'documentAttachment';
                    EntitySetName = 'documentAttachments';
                    SubPageLink = "Document Id" = field(SystemId), "Document Type" = const("Transfer Shipment");
                }
            }
        }
    }
}
