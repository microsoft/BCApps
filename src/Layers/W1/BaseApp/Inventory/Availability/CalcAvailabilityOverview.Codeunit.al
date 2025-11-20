// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Ledger;

codeunit 5830 "Calc. Availability Overview"
{
    TableNo = "Availability Calc. Overview";

    trigger OnRun()
    var
        CopyOfAvailabilityCalcOverview: Record "Availability Calc. Overview";
    begin
        CopyOfAvailabilityCalcOverview.Copy(Rec);
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Copy(CopyOfAvailabilityCalcOverview);

        OpenWindow(Text000, Rec.Count);

        Item.Reset();
        Item.SetFilter("No.", CopyOfAvailabilityCalcOverview.GetFilter("Item No."));
        Item.SetFilter("Location Filter", Rec.GetFilter("Location Code"));
        Item.SetFilter("Variant Filter", Rec.GetFilter("Variant Code"));
        Item.SetFilter("Date Filter", Rec.GetFilter(Date));
        Item.SetRange("Drop Shipment Filter", false);
        Item.SetRange(Type, Item.Type::Inventory);
        if Item.Find('-') then begin
            OpenWindow(Text000, Item.Count);
            repeat
                UpdateWindow();
                Rec.SetRange("Matches Criteria");
                Rec."Item No." := Item."No.";
                if CheckItemInRange(Rec) then
                    if EntriesExist(Rec) then begin
                        Rec.Reset();
                        if Rec.FindLast() then;
                        SetEntryNo(Rec."Entry No.");
                        InsertAvailabilityEntry(Rec, Rec.Type::Item, 0D, '', '', 0, 0, 0, 0, '', Item.Description, DemandType::"All Demands");
                    end;
                Rec.Copy(CopyOfAvailabilityCalcOverview);
            until Item.Next() = 0;
        end;
        Window.Close();
    end;

    var
        Item: Record Item;
        Window: Dialog;
        StartDate: Date;
        EndDate: Date;
        AttachedToEntryNo: Integer;
        EntryNo: Integer;
        DemandType: Enum "Demand Order Source Type";
        DemandNo: Code[20];
        WindowUpdateDateTime: DateTime;
        NoOfRecords: Integer;
        i: Integer;
#pragma warning disable AA0074
        Text000: Label 'Calculating Availability Dates @1@@@@@@@';
#pragma warning restore AA0074

    procedure CalculateItem(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        CopyOfAvailabilityCalcOverview: Record "Availability Calc. Overview";
        CopyOfItem: Record Item;
        FirstEntryNo: Integer;
    begin
        CopyOfItem.Copy(Item);
        CopyOfAvailabilityCalcOverview.Copy(AvailabilityCalcOverview);
        StartDate := 0D;
        EndDate := DMY2Date(31, 12, 9999);
        if AvailabilityCalcOverview.GetFilter(Date) <> '' then begin
            StartDate := AvailabilityCalcOverview.GetRangeMin(Date);
            EndDate := AvailabilityCalcOverview.GetRangeMax(Date);
        end;

        Item.Reset();
        Item.SetFilter("No.", CopyOfAvailabilityCalcOverview.GetFilter("Item No."));
        Item.SetFilter("Location Filter", AvailabilityCalcOverview.GetFilter("Location Code"));
        Item.SetFilter("Variant Filter", AvailabilityCalcOverview.GetFilter("Variant Code"));
        Item.SetRange("Drop Shipment Filter", false);

        AvailabilityCalcOverview.SetRange("Matches Criteria");
        Item.Get(AvailabilityCalcOverview."Item No.");
        AvailabilityCalcOverview.Reset();
        AvailabilityCalcOverview.SetCurrentKey("Item No.");
        AvailabilityCalcOverview.SetRange("Item No.", Item."No.");
        AvailabilityCalcOverview.DeleteAll();

        AvailabilityCalcOverview.Reset();
        if AvailabilityCalcOverview.FindLast() then;
        SetEntryNo(AvailabilityCalcOverview."Entry No.");

        InsertAvailabilityEntry(
            AvailabilityCalcOverview, AvailabilityCalcOverview.Type::Item, 0D, '', '', 0, 0, 0, 0, '', Item.Description, DemandType::"All Demands");
        CopyOfAvailabilityCalcOverview := AvailabilityCalcOverview;

        FirstEntryNo := AvailabilityCalcOverview."Entry No.";
        AvailabilityCalcOverview.CopyFilters(CopyOfAvailabilityCalcOverview);
        GetInventoryDates(AvailabilityCalcOverview);
        GetSupplyDates(AvailabilityCalcOverview);
        GetDemandDates(AvailabilityCalcOverview);

        AvailabilityCalcOverview.Reset();
        AvailabilityCalcOverview.SetCurrentKey("Item No.");
        AvailabilityCalcOverview.SetRange("Item No.", Item."No.");
        AvailabilityCalcOverview.SetFilter(Date, CopyOfAvailabilityCalcOverview.GetFilter(Date));
        AvailabilityCalcOverview.SetFilter("Location Code", CopyOfAvailabilityCalcOverview.GetFilter("Location Code"));
        AvailabilityCalcOverview.SetFilter("Variant Code", CopyOfAvailabilityCalcOverview.GetFilter("Variant Code"));
        if not AvailabilityCalcOverview.FindFirst() then begin
            AvailabilityCalcOverview.SetRange(Date);
            AvailabilityCalcOverview.SetRange("Location Code");
            AvailabilityCalcOverview.SetRange("Variant Code");
            AvailabilityCalcOverview.DeleteAll();
        end else
            if DemandType = DemandType::"All Demands" then
                AvailabilityCalcOverview.ModifyAll(AvailabilityCalcOverview."Matches Criteria", true);
        AvailabilityCalcOverview.Reset();
        if AvailabilityCalcOverview.Get(FirstEntryNo) then
            if AvailabilityCalcOverview.Next() = 0 then
                AvailabilityCalcOverview.Delete();
        Item.Copy(CopyOfItem);
        AvailabilityCalcOverview.Copy(CopyOfAvailabilityCalcOverview);
    end;

    procedure CalculateDate(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        CopyOfAvailabilityCalcOverview: Record "Availability Calc. Overview";
        FirstEntryNo: Integer;
    begin
        CopyOfAvailabilityCalcOverview.Copy(AvailabilityCalcOverview);
        AttachedToEntryNo := AvailabilityCalcOverview."Attached to Entry No.";

        Item.Get(AvailabilityCalcOverview."Item No.");

        AvailabilityCalcOverview.Reset();
        AvailabilityCalcOverview.SetRange("Item No.", AvailabilityCalcOverview."Item No.");
        AvailabilityCalcOverview.SetRange("Location Code", AvailabilityCalcOverview."Location Code");
        AvailabilityCalcOverview.SetRange("Variant Code", AvailabilityCalcOverview."Variant Code");
        AvailabilityCalcOverview.SetRange(Date, AvailabilityCalcOverview.Date);
        AvailabilityCalcOverview.SetRange(Level, 2, 3);
        AvailabilityCalcOverview.DeleteAll();

        AvailabilityCalcOverview.Reset();
        if AvailabilityCalcOverview.FindLast() then;
        SetEntryNo(AvailabilityCalcOverview."Entry No.");
        AvailabilityCalcOverview.TransferFields(CopyOfAvailabilityCalcOverview, false);
        FirstEntryNo := AvailabilityCalcOverview."Entry No.";

        Item.SetRange("Location Filter", AvailabilityCalcOverview."Location Code");
        Item.SetRange("Variant Filter", AvailabilityCalcOverview."Variant Code");
        Item.SetRange("Date Filter", AvailabilityCalcOverview.Date);
        GetSupplyEntries(AvailabilityCalcOverview);
        GetDemandEntries(AvailabilityCalcOverview);

        AvailabilityCalcOverview.Get(FirstEntryNo);
        if AvailabilityCalcOverview.Next() = 0 then;
        UpdateRunningTotals(AvailabilityCalcOverview);

        AvailabilityCalcOverview.Get(FirstEntryNo);
        if AvailabilityCalcOverview.Next() = 0 then;
    end;

    local procedure GetInventoryDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.FilterLinesWithItemToPlan(Item, false);
        if ItemLedgEntry.FindFirst() then
            repeat
                ItemLedgEntry.SetRange("Location Code", ItemLedgEntry."Location Code");
                ItemLedgEntry.SetRange("Variant Code", ItemLedgEntry."Variant Code");
                ItemLedgEntry.CalcSums(ItemLedgEntry."Remaining Quantity");
                ItemLedgEntry.SetRange(Positive, ItemLedgEntry.Positive);
                InsertAvailabilityEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::Inventory, 0D, ItemLedgEntry."Location Code", ItemLedgEntry."Variant Code",
                  ItemLedgEntry."Remaining Quantity", 0,
                  0, 0, '', '', DemandType::"All Demands");

                ItemLedgEntry.FindLast();
                ItemLedgEntry.SetFilter(ItemLedgEntry."Location Code", AvailabilityCalcOverview.GetFilter("Location Code"));
                ItemLedgEntry.SetFilter(ItemLedgEntry."Variant Code", AvailabilityCalcOverview.GetFilter("Variant Code"));
                ItemLedgEntry.SetRange(Positive);
            until ItemLedgEntry.Next() = 0;
    end;

    local procedure GetSupplyDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    begin
        OnGetSupplyDates(AvailabilityCalcOverview, Item);
    end;

    local procedure GetDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    begin
        OnGetDemandDates(AvailabilityCalcOverview, Item);
    end;

    local procedure GetSupplyEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        CopyOfItem: Record Item;
    begin
        CopyOfItem.Copy(Item);
        Item.SetRange("Location Filter", AvailabilityCalcOverview."Location Code");
        Item.SetRange("Variant Filter", AvailabilityCalcOverview."Variant Code");
        Item.SetRange("Date Filter", AvailabilityCalcOverview.Date);

        OnGetSupplyEntries(AvailabilityCalcOverview, Item);

        Item.Copy(CopyOfItem);
    end;

    local procedure GetDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        CopyOfItem: Record Item;
    begin
        CopyOfItem.Copy(Item);
        Item.SetRange("Location Filter", AvailabilityCalcOverview."Location Code");
        Item.SetRange("Variant Filter", AvailabilityCalcOverview."Variant Code");
        Item.SetRange("Date Filter", AvailabilityCalcOverview.Date);

        OnGetDemandEntries(AvailabilityCalcOverview, Item);

        Item.Copy(CopyOfItem);
    end;

    procedure EntriesExist(var AvailabilityCalcOverview: Record "Availability Calc. Overview"): Boolean
    var
        Item: Record Item;
    begin
        Item.Get(AvailabilityCalcOverview."Item No.");
        Item.SetFilter("Location Filter", AvailabilityCalcOverview.GetFilter("Location Code"));
        Item.SetFilter("Variant Filter", AvailabilityCalcOverview.GetFilter("Variant Code"));
        Item.SetFilter("Date Filter", AvailabilityCalcOverview.GetFilter(Date));

        exit(true in
          [InventoryExists(Item),
           SupplyExists(Item),
           DemandExists(Item)]);
    end;

    local procedure InventoryExists(var Item: Record Item): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        exit(ItemLedgEntry.LinesWithItemToPlanExist(Item, false));
    end;

    local procedure SupplyExists(var Item: Record Item) Exists: Boolean
    begin
        OnSupplyExist(Item, Exists);
    end;

    local procedure DemandExists(var Item: Record Item) Exists: Boolean
    begin
        OnDemandExist(Item, Exists);
    end;

    local procedure ClosingEntryExists(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; NewType: Option; LocationCode: Code[20]; VariantCode: Code[20]; ClosingDate: Date) Found: Boolean
    var
        CopyOfAvailabilityCalcOverview: Record "Availability Calc. Overview";
    begin
        CopyOfAvailabilityCalcOverview.Copy(AvailabilityCalcOverview);
        AvailabilityCalcOverview.SetRange("Item No.", Item."No.");
        AvailabilityCalcOverview.SetRange("Location Code", LocationCode);
        AvailabilityCalcOverview.SetRange("Variant Code", VariantCode);
        AvailabilityCalcOverview.SetRange(Date, ClosingDate);
        AvailabilityCalcOverview.SetRange(Type, NewType);
        Found := AvailabilityCalcOverview.FindFirst();
        AvailabilityCalcOverview.CopyFilters(CopyOfAvailabilityCalcOverview);
    end;

    local procedure CheckItemInRange(var AvailabilityCalcOverview: Record "Availability Calc. Overview"): Boolean
    var
        Item: Record Item;
        Found: Boolean;
    begin
        Item.Get(AvailabilityCalcOverview."Item No.");
        Item.SetFilter("Location Filter", AvailabilityCalcOverview.GetFilter("Location Code"));
        Item.SetFilter("Variant Filter", AvailabilityCalcOverview.GetFilter("Variant Code"));
        Item.SetFilter("Date Filter", AvailabilityCalcOverview.GetFilter(Date));

        OnCheckItemInRange(Item, DemandType, DemandNo, Found);
        if Found then
            exit(true);

        if DemandType = DemandType::"All Demands" then
            Found := DemandExists(Item);

        exit(Found);
    end;

    local procedure CheckDemandInDate(AvailCalcOverview: Record "Availability Calc. Overview"): Boolean
    begin
        AvailCalcOverview.SetRange("Location Code", AvailCalcOverview."Location Code");
        AvailCalcOverview.SetRange("Variant Code", AvailCalcOverview."Variant Code");
        AvailCalcOverview.SetRange(Date, AvailCalcOverview.Date);
        exit(CheckItemInRange(AvailCalcOverview));
    end;

#if not CLEAN25
    [Obsolete('Replaced by InsertAvailabilityEntry()', '25.0')]
    procedure InsertEntry(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; NewType: Integer; NewDate: Date; NewLocation: Code[10]; NewVariantCode: Code[10]; NewQuantityBase: Decimal; NewReservQtyBase: Decimal; NewSourceType: Integer; NewSourceOrderStatus: Integer; NewSourceID: Code[20]; NewDescription: Text[100]; NewDemandType: Option)
    begin
        InsertAvailabilityEntry(
            AvailabilityCalcOverview, NewType, NewDate, NewLocation, NewVariantCode, NewQuantityBase, NewReservQtyBase,
            NewSourceType, NewSourceOrderStatus, NewSourceID, NewDescription, TransformDemandTypeOptionToEnum(NewDemandType));
    end;

    [Obsolete('Temporary procedure used by InsertEntry() and SetParam()', '25.0')]
    local procedure TransformDemandTypeOptionToEnum(DemandTypeOption: Option): Enum "Demand Order Source Type"
    begin
        case DemandTypeOption of
            0: // " "
                exit("Demand Order Source Type"::"All Demands");
            1: // Sales
                exit("Demand Order Source Type"::"Sales Demand");
            2: // Production
                exit("Demand Order Source Type"::"Production Demand");
            3: // Job
                exit("Demand Order Source Type"::"Job Demand");
            4: // Service  
                exit("Demand Order Source Type"::"Service Demand");
            5: // Assembly
                exit("Demand Order Source Type"::"Assembly Demand");
        end;
    end;
#endif

    procedure InsertAvailabilityEntry(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; NewType: Integer; NewDate: Date; NewLocation: Code[10]; NewVariantCode: Code[10])
    begin
        InsertAvailabilityEntry(AvailabilityCalcOverview, NewType, NewDate, NewLocation, NewVariantCode, 0, 0, 0, 0, '', '', "Demand Order Source Type"::"All Demands");
    end;

    procedure InsertAvailabilityEntry(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; NewType: Integer; NewDate: Date; NewLocation: Code[10]; NewVariantCode: Code[10]; NewQuantityBase: Decimal; NewReservQtyBase: Decimal; NewSourceType: Integer; NewSourceOrderStatus: Integer; NewSourceID: Code[20]; NewDescription: Text[100]; NewDemandType: Enum "Demand Order Source Type")
    var
        CopyOfItem: Record Item;
    begin
        if (NewDate <> 0D) and not (NewDate in [StartDate .. EndDate]) then
            exit;
        CopyOfItem.Copy(Item);
        if NewType in [AvailabilityCalcOverview.Type::"As of Date", AvailabilityCalcOverview.Type::Inventory] then
            if ClosingEntryExists(AvailabilityCalcOverview, NewType, NewLocation, NewVariantCode, NewDate) then begin
                if not AvailabilityCalcOverview."Matches Criteria" then begin
                    AvailabilityCalcOverview."Matches Criteria" := CheckDemandInDate(AvailabilityCalcOverview);
                    AvailabilityCalcOverview.Modify();
                end;
                exit;
            end;

        if not (NewType in [AvailabilityCalcOverview.Type::Item, AvailabilityCalcOverview.Type::"As of Date"]) then
            if NewQuantityBase = 0 then
                exit;
        AvailabilityCalcOverview.Init();
        AvailabilityCalcOverview."Entry No." := GetEntryNo();
        AvailabilityCalcOverview.Type := NewType;
        AvailabilityCalcOverview."Item No." := Item."No.";
        AvailabilityCalcOverview.Date := NewDate;
        AvailabilityCalcOverview."Location Code" := NewLocation;
        AvailabilityCalcOverview."Variant Code" := NewVariantCode;
        AvailabilityCalcOverview.Quantity := NewQuantityBase;
        AvailabilityCalcOverview."Reserved Quantity" := NewReservQtyBase;

        if (DemandType = DemandType::"All Demands") or
           (AvailabilityCalcOverview.Type = AvailabilityCalcOverview.Type::"As of Date") or
           ((DemandType = NewDemandType) and (DemandNo in ['', NewSourceID]))
        then
            AvailabilityCalcOverview."Matches Criteria" := NewDate in [StartDate .. EndDate];

        case NewType of
            AvailabilityCalcOverview.Type::Item:
                begin
                    AvailabilityCalcOverview.Level := 0;
                    AvailabilityCalcOverview."Matches Criteria" := true;
                end;
            AvailabilityCalcOverview.Type::Inventory:
                begin
                    AvailabilityCalcOverview."Attached to Entry No." := AvailabilityCalcOverview."Entry No.";
                    AvailabilityCalcOverview.Level := 1;
                    AvailabilityCalcOverview."Inventory Running Total" := AvailabilityCalcOverview.Quantity;
                    AvailabilityCalcOverview."Running Total" := AvailabilityCalcOverview.Quantity;
                end;
            AvailabilityCalcOverview.Type::"As of Date":
                begin
                    AvailabilityCalcOverview."Attached to Entry No." := AvailabilityCalcOverview."Entry No.";
                    AvailabilityCalcOverview.Level := 1;
                    CalcRunningTotals(
                      Item."No.", NewLocation, NewVariantCode, NewDate,
                      AvailabilityCalcOverview."Running Total", AvailabilityCalcOverview."Inventory Running Total", AvailabilityCalcOverview."Supply Running Total", AvailabilityCalcOverview."Demand Running Total");
                    AllocateToDemand(AvailabilityCalcOverview."Inventory Running Total", AvailabilityCalcOverview."Supply Running Total", AvailabilityCalcOverview."Demand Running Total");
                    if AvailabilityCalcOverview."Matches Criteria" then
                        AvailabilityCalcOverview."Matches Criteria" := CheckDemandInDate(AvailabilityCalcOverview);
                end;
            else
                AvailabilityCalcOverview."Attached to Entry No." := AttachedToEntryNo;
                AvailabilityCalcOverview.Level := 2;
        end;
        AvailabilityCalcOverview."Source Type" := NewSourceType;
        AvailabilityCalcOverview."Source Order Status" := NewSourceOrderStatus;
        AvailabilityCalcOverview."Source ID" := NewSourceID;
        AvailabilityCalcOverview.Description := NewDescription;

        OnInsertEntryOnBeforeInsert(AvailabilityCalcOverview);
        AvailabilityCalcOverview.Insert();
        Item.Copy(CopyOfItem);
    end;

    local procedure CalcRunningTotals(NewItem: Code[20]; NewLocation: Code[10]; NewVariant: Code[10]; NewDate: Date; var RunningTotal: Decimal; var InventoryRunningTotal: Decimal; var SupplyRunningTotal: Decimal; var DemandRunningTotal: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(NewItem);
        Item.SetRange("Location Filter", NewLocation);
        Item.SetRange("Variant Filter", NewVariant);
        Item.SetRange("Date Filter", 0D, NewDate);
        Item.CalcFields(
          Item."Reserved Qty. on Purch. Orders",
          Item."Res. Qty. on Inbound Transfer",
          Item."Reserved Qty. on Sales Orders",
          Item."Res. Qty. on Job Order",
          Item."Res. Qty. on Outbound Transfer",
          Item."Reserved Qty. on Inventory",
          Item."Res. Qty. on Assembly Order",
          Item."Res. Qty. on  Asm. Comp.",
          Item."Res. Qty. on Sales Returns",
          Item."Res. Qty. on Purch. Returns");
        Item.CalcFields(
          Item."Qty. on Purch. Order",
          Item."Trans. Ord. Receipt (Qty.)",
          Item."Qty. on Sales Order",
          Item."Qty. on Job Order",
          Item."Trans. Ord. Shipment (Qty.)",
          Item.Inventory,
          Item."Qty. on Assembly Order",
          Item."Qty. on Asm. Component",
          Item."Qty. on Purch. Return",
          Item."Qty. on Sales Return");

        SupplyRunningTotal :=
          Item."Qty. on Purch. Order" - Item."Reserved Qty. on Purch. Orders" +
          Item."Qty. on Sales Return" - Item."Res. Qty. on Sales Returns" +
          Item.CalcScheduledReceiptQty() + Item.CalcPlannedOrderReceiptQty() - Item.CalcReservedQtyOnProdOrder() +
          Item."Trans. Ord. Receipt (Qty.)" - Item."Res. Qty. on Inbound Transfer" +
          Item."Qty. on Assembly Order" - Item."Res. Qty. on Assembly Order";

        DemandRunningTotal :=
          -Item."Qty. on Sales Order" + Item."Reserved Qty. on Sales Orders" -
          Item."Qty. on Purch. Return" + Item."Res. Qty. on Purch. Returns" -
          Item.CalcQtyOnComponentLines() + Item.CalcResQtyonProdOrderComp() -
          Item."Qty. on Job Order" + Item."Res. Qty. on Job Order" -
          Item."Trans. Ord. Shipment (Qty.)" + Item."Res. Qty. on Outbound Transfer" -
          Item."Qty. on Asm. Component" + Item."Res. Qty. on  Asm. Comp.";

        OnAfterCalcDemandRunningTotal(Item, DemandRunningTotal);

        InventoryRunningTotal := Item.Inventory - Item."Reserved Qty. on Inventory";

        RunningTotal := InventoryRunningTotal + SupplyRunningTotal + DemandRunningTotal;

        OnAfterCalcRunningTotals(Item, RunningTotal, InventoryRunningTotal, SupplyRunningTotal, DemandRunningTotal);
    end;

    local procedure UpdateRunningTotals(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        CopyOfAvailCalcOverview: Record "Availability Calc. Overview";
        FirstEntryNo: Integer;
        RunningTotal: Decimal;
        SupplyRunningTotal: Decimal;
        DemandRunningTotal: Decimal;
        InventoryRunningTotal: Decimal;
    begin
        CopyOfAvailCalcOverview.Copy(AvailabilityCalcOverview);
        FirstEntryNo := AvailabilityCalcOverview."Entry No.";
        if AvailabilityCalcOverview.Date <> 0D then
            CalcRunningTotals(
              AvailabilityCalcOverview."Item No.", AvailabilityCalcOverview."Location Code", AvailabilityCalcOverview."Variant Code", CalcDate('<-1D>', AvailabilityCalcOverview.Date),
              RunningTotal, InventoryRunningTotal, SupplyRunningTotal, DemandRunningTotal);

        repeat
            RunningTotal += AvailabilityCalcOverview.Quantity - AvailabilityCalcOverview."Reserved Quantity";
            case AvailabilityCalcOverview.Type of
                AvailabilityCalcOverview.Type::Inventory:
                    InventoryRunningTotal += AvailabilityCalcOverview.Quantity - AvailabilityCalcOverview."Reserved Quantity";
                AvailabilityCalcOverview.Type::Supply,
              AvailabilityCalcOverview.Type::"Supply Forecast":
                    SupplyRunningTotal += AvailabilityCalcOverview.Quantity - AvailabilityCalcOverview."Reserved Quantity";
                AvailabilityCalcOverview.Type::Demand:
                    DemandRunningTotal += AvailabilityCalcOverview.Quantity - AvailabilityCalcOverview."Reserved Quantity";
            end;

            AvailabilityCalcOverview."Running Total" := RunningTotal;
            AvailabilityCalcOverview."Inventory Running Total" := InventoryRunningTotal;
            AvailabilityCalcOverview."Supply Running Total" := SupplyRunningTotal;
            AvailabilityCalcOverview."Demand Running Total" := DemandRunningTotal;
            AllocateToDemand(AvailabilityCalcOverview."Inventory Running Total", AvailabilityCalcOverview."Supply Running Total", AvailabilityCalcOverview."Demand Running Total");
            if DemandType = DemandType::"All Demands" then
                AvailabilityCalcOverview."Matches Criteria" := CopyOfAvailCalcOverview."Matches Criteria";

            OnUpdateRunningTotalsOnBeforeModify(AvailabilityCalcOverview);
            AvailabilityCalcOverview.Modify();
        until AvailabilityCalcOverview.Next() = 0;
        AvailabilityCalcOverview.Get(FirstEntryNo);
        if AvailabilityCalcOverview.Next() = 0 then;
    end;

    local procedure AllocateToDemand(var InventoryRunningTotal: Decimal; var SupplyRunningTotal: Decimal; var DemandRunningTotal: Decimal)
    var
        RemQty: Decimal;
    begin
        RemQty := DemandRunningTotal;
        if RemQty < 0 then
            if InventoryRunningTotal > 0 then
                if -RemQty > InventoryRunningTotal then begin
                    RemQty += InventoryRunningTotal;
                    InventoryRunningTotal := 0;
                end else begin
                    InventoryRunningTotal += RemQty;
                    RemQty := 0;
                end;
        if RemQty < 0 then
            if SupplyRunningTotal > 0 then
                if -RemQty > SupplyRunningTotal then begin
                    RemQty += SupplyRunningTotal;
                    SupplyRunningTotal := 0;
                end else begin
                    SupplyRunningTotal += RemQty;
                    RemQty := 0;
                end;
        DemandRunningTotal := RemQty;
    end;

    local procedure GetEntryNo(): Integer
    begin
        EntryNo += 1;
        exit(EntryNo);
    end;

    local procedure SetEntryNo(NewEntryNo: Integer)
    begin
        EntryNo := NewEntryNo;
    end;

#if not CLEAN25 
    [Obsolete('Replaced by SetParameters() with enum', '25.0')]
    procedure SetParam(NewDemandType: Option; NewDemandNo: Code[20])
    begin
        SetParameters(TransformDemandTypeOptionToEnum(NewDemandType), NewDemandNo);
    end;
#endif

    procedure SetParameters(NewDemandType: Enum "Demand Order Source Type"; NewDemandNo: Code[20])
    begin
        DemandType := NewDemandType;
        DemandNo := NewDemandNo;
    end;

    local procedure OpenWindow(DisplayText: Text[250]; NoOfRecords2: Integer)
    begin
        i := 0;
        NoOfRecords := NoOfRecords2;
        WindowUpdateDateTime := CurrentDateTime;
        Window.Open(DisplayText);
    end;

    local procedure UpdateWindow()
    begin
        i := i + 1;
        if CurrentDateTime - WindowUpdateDateTime >= 1000 then begin
            WindowUpdateDateTime := CurrentDateTime;
            Window.Update(1, Round(i / NoOfRecords * 10000, 1));
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcRunningTotals(var Item: Record Item; var RunningTotal: Decimal; var InventoryRunningTotal: Decimal; var SupplyRunningTotal: Decimal; var DemandRunningTotal: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertEntryOnBeforeInsert(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateRunningTotalsOnBeforeModify(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetSupplyDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetSupplyEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemInRange(var Item: Record Item; DemandType: Enum "Demand Order Source Type"; DemandNo: Code[20]; var Found: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDemandExist(var Item: Record Item; var Exists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSupplyExist(var Item: Record Item; var Exists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcDemandRunningTotal(var Item: Record Item; var DemandRunningTotal: Decimal)
    begin
    end;
}

