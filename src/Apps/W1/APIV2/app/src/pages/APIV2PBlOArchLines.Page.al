// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.API.V2;

using Microsoft.Purchases.Archive;

page 30231 "APIV2 - P. Bl. O. Arch. Lines"
{
    DelayedInsert = true;
    APIVersion = 'v2.0';
    EntityCaption = 'Purchase Blanket Order Archive Line';
    EntitySetCaption = 'Purchase Blanket Order Archive Lines';
    PageType = API;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    ODataKeyFields = SystemId;
    EntityName = 'purchaseBlanketOrderArchiveLine';
    EntitySetName = 'purchaseBlanketOrderArchiveLines';
    SourceTable = "Purchase Line Archive";
    SourceTableView = where("Document Type" = const("Blanket Order"));
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
                field(docNoOccurrence; Rec."Doc. No. Occurrence")
                {
                    Caption = 'Doc. No. Occurrence';
                    Editable = false;
                }
                field(versionNumber; Rec."Version No.")
                {
                    Caption = 'Version No.';
                    Editable = false;
                }
                field(sequence; Rec."Line No.")
                {
                    Caption = 'Sequence';
                }
                field(lineType; Rec.Type)
                {
                    Caption = 'Line Type';
                }
                field(lineObjectNumber; Rec."No.")
                {
                    Caption = 'Line Object No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(description2; Rec."Description 2")
                {
                    Caption = 'Description 2';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit Of Measure Code';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                }
                field(directUnitCost; Rec."Direct Unit Cost")
                {
                    Caption = 'Direct Unit Cost';
                }
                field(lineDiscountPercent; Rec."Line Discount %")
                {
                    Caption = 'Line Discount Percent';
                }
                field(lineDiscountAmount; Rec."Line Discount Amount")
                {
                    Caption = 'Line Discount Amount';
                }
                field(lineAmount; Rec."Line Amount")
                {
                    Caption = 'Line Amount';
                }
                field(amount; Rec.Amount)
                {
                    Caption = 'Amount';
                }
                field(amountIncludingVAT; Rec."Amount Including VAT")
                {
                    Caption = 'Amount Including VAT';
                }
                field(taxPercent; Rec."VAT %")
                {
                    Caption = 'Tax Percent';
                    Editable = false;
                }
                field(outstandingQuantity; Rec."Outstanding Quantity")
                {
                    Caption = 'Outstanding Quantity';
                    Editable = false;
                }
                field(qtyToReceive; Rec."Qty. to Receive")
                {
                    Caption = 'Qty. to Receive';
                }
                field(quantityReceived; Rec."Quantity Received")
                {
                    Caption = 'Quantity Received';
                    Editable = false;
                }
                field(quantityInvoiced; Rec."Quantity Invoiced")
                {
                    Caption = 'Quantity Invoiced';
                    Editable = false;
                }
                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(expectedReceiptDate; Rec."Expected Receipt Date")
                {
                    Caption = 'Expected Receipt Date';
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
                    SubPageLink = "Parent Id" = field(SystemId), "Parent Type" = const("Purchase Blanket Order Archive Line");
                }
            }
        }
    }
}
