// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Inventory.Item;

page 342 "Check Availability"
{
    Caption = 'Check Availability';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    InstructionalText = 'The available inventory is lower than the entered quantity. Do you still want to record the quantity?';
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ConfirmationDialog;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            field(AvailableInventory; InventoryQty)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Available Inventory';
                DecimalPlaces = 0 : 5;
                Editable = false;
                ToolTip = 'Specifies the quantity of the item that is currently in inventory and not reserved for other demand.';
            }
            field(InventoryShortage; TotalQuantity)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Inventory Shortage';
                DecimalPlaces = 0 : 5;
                Editable = false;
                ToolTip = 'Specifies the quantity that is missing from inventory to fulfil the quantity on the line.';
            }
            part(ItemAvailabilityCheckDet; "Item Availability Check Det.")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
            }
        }
    }

    actions
    {
    }

    var
        InventoryQty: Decimal;
        TotalQuantity: Decimal;

    procedure SetValues(ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; InventoryQty2: Decimal; GrossReq: Decimal; ReservedReq: Decimal; SchedRcpt: Decimal; ReservedRcpt: Decimal; CurrentQuantity: Decimal; CurrentReservedQty: Decimal; TotalQuantity2: Decimal; EarliestAvailDate: Date)
    begin
        Rec.Get(ItemNo);
        CurrPage.ItemAvailabilityCheckDet.PAGE.SetUnitOfMeasureCode(UnitOfMeasureCode);
        InventoryQty := InventoryQty2;
        CurrPage.ItemAvailabilityCheckDet.PAGE.SetGrossReq(GrossReq);
        CurrPage.ItemAvailabilityCheckDet.PAGE.SetReservedReq(ReservedReq);
        CurrPage.ItemAvailabilityCheckDet.PAGE.SetSchedRcpt(SchedRcpt);
        CurrPage.ItemAvailabilityCheckDet.PAGE.SetReservedRcpt(ReservedRcpt);
        CurrPage.ItemAvailabilityCheckDet.PAGE.SetCurrentQuantity(CurrentQuantity);
        CurrPage.ItemAvailabilityCheckDet.PAGE.SetCurrentReservedQty(CurrentReservedQty);
        TotalQuantity := TotalQuantity2;
        CurrPage.ItemAvailabilityCheckDet.PAGE.SetEarliestAvailDate(EarliestAvailDate);
    end;
}

