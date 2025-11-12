// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

page 99000902 "Item Availability Line List"
{
    Caption = 'Item Availability Line List';
    Editable = false;
    PageType = List;
    SourceTable = "Item Availability Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name for this entry.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity for this entry.';

                    trigger OnDrillDown()
                    begin
                        LookupEntries();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.DeleteAll();
        MakeWhat();
    end;

    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        AvailType: Option "Gross Requirement","Planned Order Receipt","Scheduled Order Receipt","Planned Order Release",All;
        Sign: Integer;
        QtyByUnitOfMeasure: Decimal;

    protected var
        Item: Record Item;

    procedure Init(NewType: Option "Gross Requirement","Planned Order Receipt","Scheduled Order Receipt","Planned Order Release",All; var NewItem: Record Item)
    begin
        AvailType := NewType;
        Item.Copy(NewItem);
        OnAfterInit(NewItem, AvailType);
    end;

    local procedure MakeEntries()
    begin
        case AvailType of
        end;

        OnAfterMakeEntries(Item, Rec, AvailType, Sign, QtyByUnitOfMeasure);
    end;

    local procedure MakeWhat()
    begin
        Sign := 1;
        if AvailType <> AvailType::All then
            MakeEntries()
        else begin
            Item.SetRange("Date Filter", 0D, Item.GetRangeMax("Date Filter"));
            OnItemSetFilter(Item);
            Item.CalcFields(
              "Qty. on Purch. Order",
              "Qty. on Sales Order",
              "Qty. on Job Order",
              "Net Change",
              "Purch. Req. Receipt (Qty.)",
              "Planning Issues (Qty.)",
              "Purch. Req. Release (Qty.)",
              "Qty. in Transit",
              "Trans. Ord. Shipment (Qty.)",
              "Trans. Ord. Receipt (Qty.)",
              "Qty. on Assembly Order",
              "Qty. on Asm. Component",
              "Qty. on Purch. Return",
              "Qty. on Sales Return");

            OnItemCalcFields(Item);

            if Item.Inventory <> 0 then
                Rec.InsertEntry(
                    Database::"Item Ledger Entry", Item.FieldNo(Inventory),
                    ItemLedgerEntry.TableCaption(), Item.Inventory, QtyByUnitOfMeasure, Sign);

            AvailType := AvailType::"Gross Requirement";
            Sign := -1;
            MakeEntries();
            AvailType := AvailType::"Planned Order Receipt";
            Sign := 1;
            MakeEntries();
            AvailType := AvailType::"Scheduled Order Receipt";
            Sign := 1;
            MakeEntries();
            AvailType := AvailType::All;
        end;
    end;

    local procedure LookupEntries()
    var
#if not CLEAN25
        SalesLine: Record Microsoft.Sales.Document."Sales Line";
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupEntries(Rec, Item, IsHandled);
        if IsHandled then
            exit;

        case Rec."Table No." of
            Database::"Item Ledger Entry":
                begin
                    ItemLedgerEntry.SetCurrentKey("Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date");
                    ItemLedgerEntry.SetRange("Item No.", Item."No.");
                    ItemLedgerEntry.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                    ItemLedgerEntry.SetFilter("Drop Shipment", Item.GetFilter("Drop Shipment Filter"));
                    ItemLedgerEntry.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                    ItemLedgerEntry.SetFilter("Global Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
                    ItemLedgerEntry.SetFilter("Global Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
                    ItemLedgerEntry.SetFilter("Unit of Measure Code", Item.GetFilter("Unit of Measure Filter"));
                    OnItemLedgerEntrySetFilter(ItemLedgerEntry);
                    PAGE.RunModal(0, ItemLedgerEntry);
                end;
#if not CLEAN25
            else
                OnLookupExtensionTable(Item, Rec."Table No.", Rec.QuerySource, SalesLine);
#endif
        end;

        OnAfterLookupEntries(Item, Rec."Table No.", Rec);
    end;

#if not CLEAN25
    [Obsolete('Procedure moved to table Item Availability Line scope', '25.0')]
    procedure InsertEntry(TableNo: Integer; FieldNo: Integer; TableName: Text[100]; Qty: Decimal)
    begin
        Rec.InsertEntry(TableNo, FieldNo, TableName, Qty, QtyByUnitOfMeasure, Sign);
    end;
#endif

    procedure SetQtyByUnitOfMeasure(NewQtyByUnitOfMeasure: Decimal);
    begin
        QtyByUnitOfMeasure := NewQtyByUnitOfMeasure;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemCalcFields(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemSetFilter(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemLedgerEntrySetFilter(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMakeEntries(var Item: Record Item; var ItemAvailabilityLine: Record "Item Availability Line"; AvailabilityType: Option; Sign: Decimal; QtyByUnitOfMeasure: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupEntries(var Item: Record Item; TableID: Integer; ItemAvailabilityLine: Record "Item Availability Line")
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnAfterLookupEntries()', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnLookupExtensionTable(var Item: Record Item; TableID: Integer; QuerySource: Integer; SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupEntries(ItemAvailabilityLine: Record "Item Availability Line"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInit(var Item: Record Item; var AvailType: Option "Gross Requirement","Planned Order Receipt","Scheduled Order Receipt","Planned Order Release",All)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnLookupEntriesOnAfterPurchLineSetFilters(var Item: Record Item; var PurchLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
        OnLookupEntriesOnAfterPurchLineSetFilters(Item, PurchLine);
    end;

    [Obsolete('Replaced by same event on codeunit PurchAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnLookupEntriesOnAfterPurchLineSetFilters(var Item: Record Item; var PurchLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
    end;
#endif
}
