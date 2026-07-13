// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.API.V2;

using Microsoft.Inventory.Counting.History;

page 30235 "APIV2 - P. Phys. Inv. O. Lines"
{
    DelayedInsert = true;
    APIVersion = 'v2.0';
    EntityCaption = 'Posted Physical Inventory Order Line';
    EntitySetCaption = 'Posted Physical Inventory Order Lines';
    PageType = API;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    ODataKeyFields = SystemId;
    EntityName = 'postedPhysicalInventoryOrderLine';
    EntitySetName = 'postedPhysicalInventoryOrderLines';
    SourceTable = "Pstd. Phys. Invt. Order Line";
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
                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(binCode; Rec."Bin Code")
                {
                    Caption = 'Bin Code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(description2; Rec."Description 2")
                {
                    Caption = 'Description 2';
                }
                field(baseUnitOfMeasureCode; Rec."Base Unit of Measure Code")
                {
                    Caption = 'Base Unit of Measure Code';
                    Editable = false;
                }
                field(qtyExpectedBase; Rec."Qty. Expected (Base)")
                {
                    Caption = 'Qty. Expected (Base)';
                    Editable = false;
                }
                field(qtyRecordedBase; Rec."Qty. Recorded (Base)")
                {
                    Caption = 'Qty. Recorded (Base)';
                    Editable = false;
                }
                field(quantityBase; Rec."Quantity (Base)")
                {
                    Caption = 'Quantity (Base)';
                    Editable = false;
                }
                field(entryType; Rec."Entry Type")
                {
                    Caption = 'Entry Type';
                    Editable = false;
                }
                field(posQtyBase; Rec."Pos. Qty. (Base)")
                {
                    Caption = 'Pos. Qty. (Base)';
                    Editable = false;
                }
                field(negQtyBase; Rec."Neg. Qty. (Base)")
                {
                    Caption = 'Neg. Qty. (Base)';
                    Editable = false;
                }
                field(withoutDifference; Rec."Without Difference")
                {
                    Caption = 'Without Difference';
                    Editable = false;
                }
                field(unitAmount; Rec."Unit Amount")
                {
                    Caption = 'Unit Amount';
                }
                field(unitCost; Rec."Unit Cost")
                {
                    Caption = 'Unit Cost';
                }
                field(useItemTracking; Rec."Use Item Tracking")
                {
                    Caption = 'Use Item Tracking';
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';
                }
                field(shelfNumber; Rec."Shelf No.")
                {
                    Caption = 'Shelf No.';
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
                    SubPageLink = "Parent Id" = field(SystemId), "Parent Type" = const("Posted Physical Inventory Order Line");
                }
            }
        }
    }
}
