// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.API.V2;

using Microsoft.Inventory.Transfer;

page 30205 "APIV2 - Trans. Order Lines"
{
    DelayedInsert = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    APIVersion = 'v2.0';
    EntityCaption = 'Transfer Order Line';
    EntitySetCaption = 'Transfer Order Lines';
    PageType = API;
    ODataKeyFields = SystemId;
    EntityName = 'transferOrderLine';
    EntitySetName = 'transferOrderLines';
    SourceTable = "Transfer Line";
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(documentNumber; Rec."Document No.")
                {
                    Caption = 'Document No.';
                    Editable = false;
                }
                field(sequence; Rec."Line No.")
                {
                    Caption = 'Sequence';
                }
                field(itemNumber; Rec."Item No.")
                {
                    Caption = 'Item No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(description2; Rec."Description 2")
                {
                    Caption = 'Description 2';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit Of Measure Code';
                }
                field(qtyToShip; Rec."Qty. to Ship")
                {
                    Caption = 'Qty. to Ship';
                }
                field(qtyToReceive; Rec."Qty. to Receive")
                {
                    Caption = 'Qty. to Receive';
                }
                field(quantityShipped; Rec."Quantity Shipped")
                {
                    Caption = 'Quantity Shipped';
                    Editable = false;
                }
                field(quantityReceived; Rec."Quantity Received")
                {
                    Caption = 'Quantity Received';
                    Editable = false;
                }
                field(outstandingQuantity; Rec."Outstanding Quantity")
                {
                    Caption = 'Outstanding Quantity';
                    Editable = false;
                }
                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
                }
                field(transferFromCode; Rec."Transfer-from Code")
                {
                    Caption = 'Transfer-from Code';
                }
                field(transferToCode; Rec."Transfer-to Code")
                {
                    Caption = 'Transfer-to Code';
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
                field(itemCategoryCode; Rec."Item Category Code")
                {
                    Caption = 'Item Category Code';
                }
                field(shippingAgentCode; Rec."Shipping Agent Code")
                {
                    Caption = 'Shipping Agent Code';
                }
                field(shippingAgentServiceCode; Rec."Shipping Agent Service Code")
                {
                    Caption = 'Shipping Agent Service Code';
                }
                field(shippingTime; Rec."Shipping Time")
                {
                    Caption = 'Shipping Time';
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
                    SubPageLink = "Parent Id" = field(SystemId), "Parent Type" = const("Transfer Order Line");
                }
            }
        }
    }
}
