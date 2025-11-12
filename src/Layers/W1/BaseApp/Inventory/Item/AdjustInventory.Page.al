// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;

page 1327 "Adjust Inventory"
{
    Caption = 'Adjust Inventory';
    DataCaptionExpression = Item."No." + ' - ' + Item.Description;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    SourceTable = Location;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Visible = LocationCount <= 1;
                field(BaseUnitofMeasureNoLocation; Item."Base Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Base Unit of Measure';
                    Editable = false;
                    ToolTip = 'Specifies the unit in which the item is held in inventory. The base unit of measure also serves as the conversion basis for alternate units of measure.';
                }
                field(CurrentInventoryNoLocation; TempItemJournalLine."Qty. (Calculated)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Current Inventory';
                    Editable = false;
                    ToolTip = 'Specifies how many units, such as pieces, boxes, or cans, of the item are in inventory.';
                }
                field(NewInventoryNoLocation; TempItemJournalLine.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New Inventory';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the inventory quantity that will be recorded for the item when you choose the OK button.';

                    trigger OnValidate()
                    begin
                        GetStyle();
                        TempItemJournalLine.Modify();
                    end;
                }
                field(QtyToAdjustNoLocation; TempItemJournalLine.Quantity - TempItemJournalLine."Qty. (Calculated)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Qty. to Adjust';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    StyleExpr = ColumnStyle;
                    ToolTip = 'Specifies the quantity that will be added to or subtracted from the current inventory quantity when you choose the OK button.';
                }
            }
            repeater(Control5)
            {
                ShowCaption = false;
                Visible = LocationCount > 1;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Location;
                    Editable = false;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Location;
                    Editable = false;
                }
                field(CurrentInventory; TempItemJournalLine."Qty. (Calculated)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Current Inventory';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity on hand for the item at location.';
                }
                field(NewInventory; TempItemJournalLine.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New Inventory';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the inventory quantity that will be recorded for the item when you choose the OK button.';

                    trigger OnValidate()
                    begin
                        GetStyle();
                        TempItemJournalLine.Modify();
                    end;
                }
                field(QtyToAdjust; TempItemJournalLine.Quantity - TempItemJournalLine."Qty. (Calculated)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Qty. to Adjust';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    StyleExpr = ColumnStyle;
                    ToolTip = 'Specifies the quantity that will be added to or subtracted from the current inventory quantity when you choose the OK button.';
                }
                field(BaseUnitofMeasure; Item."Base Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Base Unit of Measure';
                    Editable = false;
                    ToolTip = 'Specifies the unit in which the item is held in inventory. The base unit of measure also serves as the conversion basis for alternate units of measure.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        TempItemJournalLine.SetRange("Location Code", Rec.Code);
        TempItemJournalLine.FindFirst();
        GetStyle();
    end;

    trigger OnOpenPage()
    var
        LineNo: Integer;
    begin
        Rec.GetLocationsIncludingUnspecifiedLocation(false, true);
        Rec.SetRange("Bin Mandatory", false);
        LocationCount := Rec.Count;

        LineNo := 0;
        Rec.FindSet();
        repeat
            TempItemJournalLine.Init();
            Item.SetFilter("Location Filter", '%1', Rec.Code);
            Item.CalcFields(Inventory);
            TempItemJournalLine."Line No." := LineNo;
            TempItemJournalLine.Quantity := Item.Inventory;
            TempItemJournalLine."Qty. (Calculated)" := Item.Inventory;
            TempItemJournalLine."Item No." := Item."No.";
            TempItemJournalLine."Location Code" := Rec.Code;
            OnOpenPageOnBeforeInsertTempItemJournalLine(TempItemJournalLine, Rec);
            TempItemJournalLine.Insert();
            LineNo := LineNo + 1;
        until Rec.Next() = 0;

        Rec.FindFirst();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        AdjustItemInventory: Codeunit "Adjust Item Inventory";
        ErrorText: Text;
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then begin
            TempItemJournalLine.Reset();
            ErrorText := AdjustItemInventory.PostMultipleAdjustmentsToItemLedger(TempItemJournalLine);
            if ErrorText <> '' then
                Message(ErrorText);
        end;
    end;

    protected var
        Item: Record Item;
        TempItemJournalLine: Record "Item Journal Line" temporary;
        LocationCount: Integer;
        ColumnStyle: Text;

    procedure SetItem(ItemNo: Code[20])
    begin
        Item.Get(ItemNo);
    end;

    local procedure GetStyle()
    begin
        if TempItemJournalLine.Quantity - TempItemJournalLine."Qty. (Calculated)" >= 0 then
            ColumnStyle := 'Strong'
        else
            ColumnStyle := 'Unfavorable';
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnBeforeInsertTempItemJournalLine(var TempItemJournalLine: Record "Item Journal Line" temporary; var Location: Record Location)
    begin
    end;
}

