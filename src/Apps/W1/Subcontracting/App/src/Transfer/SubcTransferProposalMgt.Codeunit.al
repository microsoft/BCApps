// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;

codeunit 20583 "Subc. Transfer Proposal Mgt."
{
    Access = Internal;
    var
        TempRows: Record "Subc. Transfer Proposal" temporary;
        TempFilters: Record "Subc. Transfer Proposal" temporary;
        Availability: Codeunit "Subc. WIP Availability";
        IncludeComponents: Boolean;
        IncludeUnprocessed: Boolean;
        IncludeProcessed: Boolean;
        IsReturn: Boolean;
        AllOffErr: Label 'Select at least one type of quantity to include.';
        EmptyErr: Label 'There are no components or WIP quantities to transfer for the selected filters.';
        CategoryErr: Label 'No available quantity was found for: %1.', Comment = '%1 = selected quantity categories';
        ChangedErr: Label 'The available quantity has changed. Close the proposal and calculate it again.';
        CreatedMsg: Label '%1 transfer order(s) with %2 line(s) were created.', Comment = '%1 = transfer order count, %2 = transfer line count';
        ComponentsLbl: Label 'Components';
        UnprocessedLbl: Label 'Unprocessed WIP';
        ProcessedLbl: Label 'Processed WIP';

    internal procedure Configure(ReturnOrder: Boolean; Components: Boolean; Unprocessed: Boolean; Processed: Boolean; OrderFilter: Text; LineFilter: Text; OperationFilter: Text; WorkCenterFilter: Text; ItemFilter: Text; VariantFilter: Text)
    begin
        IsReturn := ReturnOrder;
        IncludeComponents := Components;
        IncludeUnprocessed := Unprocessed;
        IncludeProcessed := Processed;
        if not (Components or Unprocessed or Processed) then
            Error(AllOffErr);
        TempFilters.SetFilter("Production Order No.", OrderFilter);
        TempFilters.SetFilter("Production Order Line No.", LineFilter);
        TempFilters.SetFilter("Operation No.", OperationFilter);
        TempFilters.SetFilter("Work Center No.", WorkCenterFilter);
        TempFilters.SetFilter("Item No.", ItemFilter);
        TempFilters.SetFilter("Variant Code", VariantFilter);
    end;

    internal procedure ClearRows()
    begin
        TempRows.Reset();
        TempRows.DeleteAll();
    end;

    internal procedure ProposedWIPBase(PurchaseLine: Record "Purchase Line"): Decimal
    begin
        TempRows.Reset();
        TempRows.SetRange("Purchase Order No.", PurchaseLine."Document No.");
        TempRows.SetRange("Purchase Line No.", PurchaseLine."Line No.");
        TempRows.SetRange("WIP Item", true);
        TempRows.CalcSums("Available Quantity (Base)");
        exit(TempRows."Available Quantity (Base)");
    end;

    internal procedure AddComponent(PurchaseLine: Record "Purchase Line"; Component: Record "Prod. Order Component"; FromLocation: Code[10]; ToLocation: Code[10]; QuantityBase: Decimal; ClaimedBase: Decimal)
    var
        Row: Record "Subc. Transfer Proposal" temporary;
        Item: Record Item;
    begin
        InitializeRow(Row, PurchaseLine, Component."Item No.", Component."Variant Code", FromLocation, ToLocation);
        Row."Component Line No." := Component."Line No.";
        Row."Unit of Measure Code" := Component."Unit of Measure Code";
        Row."Qty. per Unit of Measure" := Component."Qty. per Unit of Measure";
        Item.Get(Component."Item No.");
        AddRow(Row, QuantityBase, ClaimedBase, Item."Rounding Precision", '>');
    end;

    internal procedure AddWIP(PurchaseLine: Record "Purchase Line"; ProductionLine: Record "Prod. Order Line"; FromLocation: Code[10]; ToLocation: Code[10]; PreviousOperation: Code[10]; QuantityBase: Decimal; UOMCode: Code[10])
    var
        Entry: Record "Subcontractor WIP Ledger Entry";
        Row: Record "Subc. Transfer Proposal" temporary;
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
        CohortMgt: Codeunit "Subc. WIP Cohort Mgt.";
        Seen: Dictionary of [Text, Boolean];
        Identity: Text;
        OperationNo: Code[10];
        AvailableBase: Decimal;
        ClaimedBase: Decimal;
        Remaining: Decimal;
        PreviousRouting: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PhysicalSource: Boolean;
    begin
        InitializeRow(Row, PurchaseLine, ProductionLine."Item No.", ProductionLine."Variant Code", FromLocation, ToLocation);
        Row."WIP Item" := true;
        Row."Previous Operation No." := PreviousOperation;
        Row."Unit of Measure Code" := UOMCode;
        Item.Get(ProductionLine."Item No.");
        Row."Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, UOMCode);
        Row."State Tracked" := CohortMgt.IsTracked(ProductionLine.Status, ProductionLine."Prod. Order No.");
        ProductionOrder.Get(ProductionLine.Status, ProductionLine."Prod. Order No.");
        Row."WIP Cohort" := CopyStr(Format(ProductionOrder."Subc. WIP Cohort"), 1, MaxStrLen(Row."WIP Cohort"));
        if PreviousOperation <> '' then
            if PreviousRouting.Get(PreviousRouting.Status::Released, ProductionLine."Prod. Order No.",
                PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PreviousOperation)
            then
                PhysicalSource := PreviousRouting."Transfer WIP Item";
        if not Row."State Tracked" or (not IsReturn and not PhysicalSource) then begin
            ClaimedBase := 0;
            if not Row."State Tracked" and (IsReturn or PhysicalSource) then begin
                OperationNo := PreviousOperation;
                if IsReturn then
                    OperationNo := PurchaseLine."Operation No.";
                Entry.SetRange("Prod. Order Status", ProductionLine.Status);
                Entry.SetRange("Prod. Order No.", ProductionLine."Prod. Order No.");
                Entry.SetRange("Prod. Order Line No.", ProductionLine."Line No.");
                Entry.SetRange("Routing Reference No.", PurchaseLine."Routing Reference No.");
                Entry.SetRange("Routing No.", PurchaseLine."Routing No.");
                Entry.SetRange("Operation No.", OperationNo);
                Entry.SetRange("Location Code", FromLocation);
                Entry.SetRange("Item No.", ProductionLine."Item No.");
                Entry.SetRange("Variant Code", ProductionLine."Variant Code");
                Entry.SetRange("In Transit", false);
                Entry.CalcSums("Quantity (Base)");
                ClaimedBase := LegacyClaim(Row, OperationNo);
                AvailableBase := Entry."Quantity (Base)" - ClaimedBase;
                if QuantityBase > AvailableBase then
                    QuantityBase := AvailableBase;
            end;
            if Row."State Tracked" then begin
                AvailableBase := Availability.InitialAvailable(CohortMgt.GetLineage(ProductionLine.Status, ProductionLine."Prod. Order No."),
                    ProductionLine."Line No.", ProductionLine."Quantity (Base)", '', 0);
                if QuantityBase > AvailableBase then
                    QuantityBase := AvailableBase;
                Row."WIP Status" := CopyStr(Format(Row."WIP State"), 1, MaxStrLen(Row."WIP Status"));
            end;
            AddRow(Row, QuantityBase, ClaimedBase, UOMMgt.QtyRndPrecision(), '=');
            exit;
        end;
        OperationNo := PurchaseLine."Operation No.";
        if not IsReturn then
            OperationNo := PreviousOperation;
        Entry.SetRange("Lineage ID", CohortMgt.GetLineage(ProductionLine.Status, ProductionLine."Prod. Order No."));
        Entry.SetRange("Prod. Order Line No.", ProductionLine."Line No.");
        Entry.SetRange("Routing Reference No.", PurchaseLine."Routing Reference No.");
        Entry.SetRange("Routing No.", PurchaseLine."Routing No.");
        Entry.SetRange("Operation No.", OperationNo);
        Entry.SetRange("Item No.", ProductionLine."Item No.");
        Entry.SetRange("Variant Code", ProductionLine."Variant Code");
        Entry.SetRange("Location Code", FromLocation);
        Entry.SetRange("In Transit", false);
        Entry.SetRange("State Tracked", true);
        Remaining := QuantityBase;
        if Entry.FindSet() then
            repeat
                Identity := Format(Entry."Source Position No.") + '/' + Format(Entry."WIP State".AsInteger()) + '/' + Format(Entry."Supply Lot ID");
                if not Seen.ContainsKey(Identity) then begin
                    Seen.Add(Identity, true);
                    AvailableBase := Availability.Available(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0);
                    ClaimedBase := Availability.OpenClaim(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0);
                    if not IsReturn and (AvailableBase > Remaining) then
                        AvailableBase := Remaining;
                    if AvailableBase > 0 then begin
                        Row."Source Position No." := Entry."Source Position No.";
                        Row."Supply Lot ID" := Entry."Supply Lot ID";
                        Row."WIP State" := Entry."WIP State";
                        Row."WIP Status" := CopyStr(Format(Entry."WIP State"), 1, MaxStrLen(Row."WIP Status"));
                        AddRow(Row, AvailableBase, ClaimedBase, UOMMgt.QtyRndPrecision(), '=');
                        Remaining -= AvailableBase;
                    end;
                end;
            until Entry.Next() = 0;
    end;

    local procedure LegacyClaim(Row: Record "Subc. Transfer Proposal" temporary; SourceOperation: Code[10]): Decimal
    var
        Line: Record "Transfer Line";
        Result: Decimal;
    begin
        Line.SetRange("Subc. Prod. Order No.", Row."Production Order No.");
        Line.SetRange("Subc. Prod. Order Line No.", Row."Production Order Line No.");
        Line.SetRange("Subc. Routing Reference No.", Row."Routing Reference No.");
        Line.SetRange("Subc. Routing No.", Row."Routing No.");
        Line.SetRange("Item No.", Row."Item No.");
        Line.SetRange("Variant Code", Row."Variant Code");
        Line.SetRange("Transfer-from Code", Row."Transfer-from Code");
        Line.SetRange("Transfer WIP Item", true);
        Line.SetRange("Subc. State Tracked", false);
        Line.SetRange("Derived From Line No.", 0);
        if Line.FindSet() then
            repeat
                if (Line."Subc. Return Order" and (Line."Subc. Operation No." = SourceOperation)) or
                   (not Line."Subc. Return Order" and (Line."Prev. Operation No." = SourceOperation))
                then
                    if Line.Quantity > Line."Quantity Shipped" then
                        Result += Line.CalcBaseQty(Line.Quantity - Line."Quantity Shipped");
            until Line.Next() = 0;
        exit(Result);
    end;

    local procedure InitializeRow(var Row: Record "Subc. Transfer Proposal" temporary; PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; VariantCode: Code[10]; FromLocation: Code[10]; ToLocation: Code[10])
    begin
        Row.Init();
        Row."Purchase Order No." := PurchaseLine."Document No.";
        Row."Purchase Line No." := PurchaseLine."Line No.";
        Row."Production Order No." := PurchaseLine."Prod. Order No.";
        Row."Production Order Line No." := PurchaseLine."Prod. Order Line No.";
        Row."Operation No." := PurchaseLine."Operation No.";
        Row."Work Center No." := PurchaseLine."Work Center No.";
        Row."Routing No." := PurchaseLine."Routing No.";
        Row."Routing Reference No." := PurchaseLine."Routing Reference No.";
        Row."Item No." := ItemNo;
        Row."Variant Code" := VariantCode;
        Row."Transfer-from Code" := FromLocation;
        Row."Transfer-to Code" := ToLocation;
    end;

    local procedure AddRow(var Row: Record "Subc. Transfer Proposal" temporary; QuantityBase: Decimal; ClaimedBase: Decimal; Precision: Decimal; Direction: Text[1])
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        if (QuantityBase <= 0) or (Row."Transfer-from Code" = Row."Transfer-to Code") then
            exit;
        if Row."Qty. per Unit of Measure" <= 0 then
            exit;
        if Precision = 0 then
            Precision := UOMMgt.QtyRndPrecision();
        Row."Available Quantity (Base)" := QuantityBase;
        Row."Available Quantity" := QuantityBase / Row."Qty. per Unit of Measure";
        Row."Quantity on Transfer" := ClaimedBase / Row."Qty. per Unit of Measure";
        Row."Quantity to Transfer" := Round(Row."Available Quantity", Precision, Direction);
        if Row."WIP Item" and
           (Round(Row."Quantity to Transfer" * Row."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()) > QuantityBase)
        then
            Row."Quantity to Transfer" := Round(Row."Available Quantity", Precision, '<');
        if not Row."WIP Item" then begin
            Row."Available Quantity" := Row."Quantity to Transfer";
            Row."Available Quantity (Base)" := Row.QuantityBase();
        end;
        TempRows.Reset();
        if TempRows.FindLast() then
            Row."Entry No." := TempRows."Entry No." + 1
        else
            Row."Entry No." := 1;
        TempRows := Row;
        TempRows.Insert();
    end;

    internal procedure SelectRows(var Selected: Record "Subc. Transfer Proposal" temporary): Boolean
    var
        Proposal: Page "Subc. Transfer Proposal";
        Categories: Text;
    begin
        ApplyFilters();
        if TempRows.IsEmpty() then
            Error(EmptyErr);
        TempRows.FindSet();
        repeat
            if CategorySelected(TempRows) then begin
                Selected := TempRows;
                Selected.Insert();
            end;
        until TempRows.Next() = 0;
        if Selected.IsEmpty() then begin
            if IncludeComponents then
                Categories := ComponentsLbl;
            if IncludeUnprocessed then
                Categories += ' ' + UnprocessedLbl;
            if IncludeProcessed then
                Categories += ' ' + ProcessedLbl;
            Error(CategoryErr, Categories);
        end;
        Proposal.SetRows(Selected);
        Proposal.LookupMode(true);
        exit(Proposal.RunModal() = Action::LookupOK);
    end;

    local procedure ApplyFilters()
    begin
        TempRows.Reset();
        TempRows.CopyFilters(TempFilters);
    end;

    local procedure CategorySelected(Row: Record "Subc. Transfer Proposal" temporary): Boolean
    begin
        if not Row."WIP Item" then
            exit(IncludeComponents);
        if not IsReturn then
            exit(IncludeUnprocessed);
        if not Row."State Tracked" or (Row."WIP State" = Row."WIP State"::Unprocessed) then
            exit(IncludeUnprocessed);
        exit(IncludeProcessed);
    end;

    internal procedure LockSources(var Selected: Record "Subc. Transfer Proposal" temporary)
    var
        ProductionLine: Record "Prod. Order Line";
        Component: Record "Prod. Order Component";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.LockTable();
        if Selected.FindSet() then
            repeat
                PurchaseLine.Get(PurchaseLine."Document Type"::Order, Selected."Purchase Order No.", Selected."Purchase Line No.");
            until Selected.Next() = 0;
        Selected.SetCurrentKey("Production Order No.", "Production Order Line No.", "Entry No.");
        if Selected.FindSet() then
            repeat
                ProductionLine.LockTable();
                ProductionLine.Get(ProductionLine.Status::Released, Selected."Production Order No.", Selected."Production Order Line No.");
                if not Selected."WIP Item" then begin
                    Component.LockTable();
                    Component.Get(ProductionLine.Status, Selected."Production Order No.", Selected."Production Order Line No.", Selected."Component Line No.");
                end;
            until Selected.Next() = 0;
        Selected.SetCurrentKey("Source Position No.", "Entry No.");
        if Selected.FindSet() then
            repeat
                Availability.LockPosition(Selected."Source Position No.");
            until Selected.Next() = 0;
        Selected.SetCurrentKey("Entry No.");
    end;

    internal procedure Revalidate(var Selected: Record "Subc. Transfer Proposal" temporary)
    begin
        Selected.SetFilter("Quantity to Transfer", '>0');
        if Selected.FindSet() then
            repeat
                if not CategorySelected(Selected) then
                    Error(ChangedErr);
                Selected.CheckQuantity();
                TempRows.Reset();
                TempRows.SetRange("Purchase Order No.", Selected."Purchase Order No.");
                TempRows.SetRange("Purchase Line No.", Selected."Purchase Line No.");
                TempRows.SetRange("Component Line No.", Selected."Component Line No.");
                TempRows.SetRange("WIP Item", Selected."WIP Item");
                TempRows.SetRange("Transfer-from Code", Selected."Transfer-from Code");
                TempRows.SetRange("Transfer-to Code", Selected."Transfer-to Code");
                TempRows.SetRange("Previous Operation No.", Selected."Previous Operation No.");
                TempRows.SetRange("Source Position No.", Selected."Source Position No.");
                TempRows.SetRange("Supply Lot ID", Selected."Supply Lot ID");
                TempRows.SetRange("WIP State", Selected."WIP State");
                TempRows.SetRange("Production Order No.", Selected."Production Order No.");
                TempRows.SetRange("Production Order Line No.", Selected."Production Order Line No.");
                TempRows.SetRange("Routing Reference No.", Selected."Routing Reference No.");
                TempRows.SetRange("Routing No.", Selected."Routing No.");
                TempRows.SetRange("Operation No.", Selected."Operation No.");
                TempRows.SetRange("Work Center No.", Selected."Work Center No.");
                TempRows.SetRange("Item No.", Selected."Item No.");
                TempRows.SetRange("Variant Code", Selected."Variant Code");
                TempRows.SetRange("Unit of Measure Code", Selected."Unit of Measure Code");
                TempRows.SetRange("Qty. per Unit of Measure", Selected."Qty. per Unit of Measure");
                TempRows.SetRange("State Tracked", Selected."State Tracked");
                if not TempRows.FindFirst() then
                    Error(ChangedErr);
                if Selected.QuantityBase() > TempRows."Available Quantity (Base)" then
                    Error(ChangedErr);
            until Selected.Next() = 0;
        Selected.Reset();
        Selected.SetFilter("Quantity to Transfer", '>0');
    end;

    internal procedure ShowResult(OrderCount: Integer; LineCount: Integer)
    begin
        Message(CreatedMsg, OrderCount, LineCount);
    end;
}
