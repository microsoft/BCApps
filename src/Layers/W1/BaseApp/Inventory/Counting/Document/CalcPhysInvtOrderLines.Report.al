// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Document;

using Microsoft.Inventory.Counting.Tracking;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;

report 5880 "Calc. Phys. Invt. Order Lines"
{
    Caption = 'Calc. Phys. Invt. Order Lines';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Inventory Posting Group", "Gen. Prod. Posting Group", "Item Category Code", "Variant Filter", "Location Filter", "Bin Filter", "Date Filter";

            trigger OnAfterGetRecord()
            var
                ShouldCalcItemPhysInvtOrderLines: Boolean;
            begin
                if not HideValidationDialog then
                    Window.Update(1, "No.");

                Clear(LastItemLedgEntry);

                ShouldCalcItemPhysInvtOrderLines := not Blocked;
                OnAfterGetRecordItemOnAfterCalcShouldCalcItemPhysInvtOrderLines(Item, PhysInvtOrderHeader, ShouldCalcItemPhysInvtOrderLines);
                if ShouldCalcItemPhysInvtOrderLines then
                    CalcItemPhysInvtOrderLines()
                else
                    ItemsBlocked := true;
            end;

            trigger OnPostDataItem()
            begin
                OnAfterCreatePhysInvtOrderLines(PhysInvtOrderHeader, Item, ItemsBlocked, LineCount, NextLineNo);
                if not HideValidationDialog then begin
                    Window.Close();
                    if ItemsBlocked then
                        Message(BlockedItemMsg);
                    Message(StrSubstNo(LinesCreatedMsg, LineCount));
                end;
            end;

            trigger OnPreDataItem()
            begin
                PhysInvtOrderHeader.TestField("No.");
                PhysInvtOrderHeader.TestField(Status, PhysInvtOrderHeader.Status::Open);

                OnBeforeOnPreDataItemItem(PhysInvtOrderHeader, Item);

                PhysInvtOrderHeader.LockTable();
                PhysInvtOrderLine.LockTable();

                PhysInvtOrderLine.Reset();
                PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
                if PhysInvtOrderLine.FindLast() then
                    NextLineNo := PhysInvtOrderLine."Line No." + 10000
                else
                    NextLineNo := 10000;

                if not HideValidationDialog then
                    Window.Open(CalculatingLinesMsg + ItemNoMsg);

                LineCount := 0;
                ItemsBlocked := false;

                if PhysInvtOrderHeader."Location Code" <> '' then
                    SetRange("Location Filter", PhysInvtOrderHeader."Location Code");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CalcQtyExpected; CalcQtyExpected)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calculate Qty. Expected';
                        ToolTip = 'Specifies if you want the program to calculate and insert the contents of the field quantity expected for new created physical inventory order lines.';
                    }
                    field(ZeroQty; ZeroQty)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Items Not on Inventory';
                        ToolTip = 'Specifies if physical inventory order lines should be created for items that are not on inventory, that is, items where the value in the Qty. Expected (Base) field is 0.';

                        trigger OnValidate()
                        begin
                            if not ZeroQty then
                                IncludeItemWithNoTransaction := false;
                        end;
                    }
                    field(IncludeItemWithNoTransactionField; IncludeItemWithNoTransaction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Items without Transactions';
                        ToolTip = 'Specifies if physical inventory order lines should be created for items that are not on inventory and are not used in any transactions.';

                        trigger OnValidate()
                        begin
                            if IncludeItemWithNoTransaction then
                                ZeroQty := true;
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
            OnAfterOpenPage(PhysInvtOrderHeader, Item);
        end;
    }

    labels
    {
    }

    var
        CalculatingLinesMsg: Label 'Calculating the order lines...\\';
        ItemNoMsg: Label 'Item No.  #1##################', Comment = '%1 = Item No.';
        LinesCreatedMsg: Label '%1 new lines have been created.', Comment = '%1 = counter';
        BlockedItemMsg: Label 'There is at least one blocked item that was skipped.';

    protected var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        LastItemLedgEntry: Record "Item Ledger Entry";
        WhseEntry: Record "Warehouse Entry";
        LastWhseEntry: Record "Warehouse Entry";
        PhysInvtTrackingMgt: Codeunit "Phys. Invt. Tracking Mgt.";
        Window: Dialog;
        ErrorText: Text[250];
        CycleSourceType: Option " ",Item,SKU;
        InvtCountCode: Code[10];
        QtyExp: Decimal;
        LastItemLedgEntryNo: Integer;
        NextLineNo: Integer;
        LineCount: Integer;
        ItemsBlocked: Boolean;
        CalcQtyExpected: Boolean;
        HideValidationDialog: Boolean;
        ZeroQty, IncludeItemWithNoTransaction : Boolean;

    procedure SetPhysInvtOrderHeader(NewPhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        PhysInvtOrderHeader := NewPhysInvtOrderHeader;

        OnAfterSetPhysInvtOrderHeader(PhysInvtOrderHeader, Item);
    end;

    procedure InitializeRequest(ZeroQty2: Boolean; CalcQtyExpected2: Boolean)
    begin
        InitializeRequest(ZeroQty2, CalcQtyExpected2, false);
    end;

    procedure InitializeRequest(ZeroQty2: Boolean; CalcQtyExpected2: Boolean; IncludeItemWithNoTransaction2: Boolean)
    begin
        ZeroQty := ZeroQty2;
        CalcQtyExpected := CalcQtyExpected2;
        IncludeItemWithNoTransaction := ZeroQty2 and IncludeItemWithNoTransaction2;
    end;

    procedure InitializeInvtCount(InvtCountCode2: Code[10]; CycleSourceType2: Option " ",Item,SKU)
    begin
        InvtCountCode := InvtCountCode2;
        CycleSourceType := CycleSourceType2;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure CalcItemPhysInvtOrderLines()
    var
        Bin: Record Bin;
        ItemVariant: Record "Item Variant";
        BlankWhseEntry: Record "Warehouse Entry";
        PhysInvtOrderLineArgs: Record "Phys. Invt. Order Line";
        IsHandled, ItemVariantBlocked : Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcItemPhysInvtOrderLines(Item, IsHandled);
        if IsHandled then
            exit;

        SetItemLedgEntryFilters();
        if ItemLedgEntry.Find('-') then
            repeat
                if IsNewItemLedgEntryGroup() then begin
                    ItemVariantBlocked := false;
                    if ItemLedgEntry."Variant Code" <> '' then begin
                        ItemVariant.SetLoadFields(Blocked);
                        ItemVariant.Get(ItemLedgEntry."Item No.", ItemLedgEntry."Variant Code");
                        ItemVariantBlocked := ItemVariant.Blocked;
                        if ItemVariantBlocked then
                            ItemsBlocked := true;
                    end;

                    LastItemLedgEntry := ItemLedgEntry;
                    if not ItemVariantBlocked then
                        if PhysInvtTrackingMgt.LocationIsBinMandatory(ItemLedgEntry."Location Code") then begin
                            Clear(LastWhseEntry);
                            SetWhseEntryFilters();
                            if WhseEntry.Find('-') then
                                repeat
                                    if IsNewWhseEntryGroup() then begin
                                        LastWhseEntry := WhseEntry;
                                        Bin.SetRange("Location Code", WhseEntry."Location Code");
                                        Bin.SetRange(Code, WhseEntry."Bin Code");
                                        IsHandled := false;
                                        OnBeforeCreateNewPhysInvtOrderLineForWhseEntry(
                                          Item, WhseEntry, ItemLedgEntry, PhysInvtOrderHeader, PhysInvtOrderLine, ErrorText,
                                          NextLineNo, InvtCountCode, CycleSourceType, CalcQtyExpected, LastItemLedgEntryNo, LineCount, IsHandled);
                                        if not IsHandled then begin
                                            PhysInvtOrderLineArgs.PrepareLineArgs(WhseEntry, ItemLedgEntry);
                                            if (not Bin.IsEmpty) and
                                               (PhysInvtOrderHeader.GetSamePhysInvtOrderLine(
                                                  PhysInvtOrderLineArgs,
                                                  ErrorText,
                                                  PhysInvtOrderLine) = 0)
                                            then
                                                CreateNewPhysInvtOrderLine();
                                        end;
                                    end;
                                until WhseEntry.Next() = 0;
                        end else begin
                            PhysInvtOrderLineArgs.PrepareLineArgs(BlankWhseEntry, ItemLedgEntry);
                            if PhysInvtOrderHeader.GetSamePhysInvtOrderLine(
                                 PhysInvtOrderLineArgs,
                                 ErrorText,
                                 PhysInvtOrderLine) = 0
                            then begin
                                WhseEntry.Init();
                                CreateNewPhysInvtOrderLine();
                            end;
                        end;
                end;
            until ItemLedgEntry.Next() = 0;
        CalcItemPhysInvtOrderLinesForItemWithNoTransactions();
    end;

    local procedure SetItemLedgEntryFilters()
    begin
        Clear(ItemLedgEntry);
        ItemLedgEntry.SetCurrentKey(
          "Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date", "Entry No.");
        ItemLedgEntry.SetRange("Item No.", Item."No.");
        if Item.GetFilter("Variant Filter") <> '' then
            Item.CopyFilter("Variant Filter", ItemLedgEntry."Variant Code");
        if Item.GetFilter("Location Filter") <> '' then
            Item.CopyFilter("Location Filter", ItemLedgEntry."Location Code");
        if Item.GetFilter("Date Filter") <> '' then
            Item.CopyFilter("Date Filter", ItemLedgEntry."Posting Date");
        OnAfterSetItemLedgEntryFilters(ItemLedgEntry, Item);
    end;

    local procedure IsNewItemLedgEntryGroup() Result: Boolean
    begin
        Result :=
            (LastItemLedgEntry."Item No." <> ItemLedgEntry."Item No.") or
            (LastItemLedgEntry."Variant Code" <> ItemLedgEntry."Variant Code") or
            (LastItemLedgEntry."Location Code" <> ItemLedgEntry."Location Code");
        OnAfterIsNewItemLedgEntryGroup(ItemLedgEntry, LastItemLedgEntry, Result, Item);
    end;

    local procedure SetWhseEntryFilters()
    begin
        WhseEntry.Reset();
        WhseEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Bin Code");
        WhseEntry.SetRange("Item No.", ItemLedgEntry."Item No.");
        WhseEntry.SetRange("Variant Code", ItemLedgEntry."Variant Code");
        WhseEntry.SetRange("Location Code", ItemLedgEntry."Location Code");
        if Item.GetFilter("Bin Filter") <> '' then
            Item.CopyFilter("Bin Filter", WhseEntry."Bin Code");
        OnAfterSetWhseEntryFilters(WhseEntry, ItemLedgEntry, Item);
    end;

    local procedure IsNewWhseEntryGroup() Result: Boolean
    begin
        Result := LastWhseEntry."Bin Code" <> WhseEntry."Bin Code";
        OnAfterIsNewWhseEntryGroup(WhseEntry, LastWhseEntry, Result);
    end;

    local procedure CreatePhysInvtOrderLineForItemsWithoutTransactions(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    var
        PhysInvtOrderLineArgs: Record "Phys. Invt. Order Line";
        BlankItemLedgerEntry: Record "Item Ledger Entry";
    begin
        WhseEntry.Init();
        WhseEntry."Item No." := ItemNo;
        WhseEntry."Variant Code" := VariantCode;
        WhseEntry."Location Code" := LocationCode;

        OnCreatePhysInvtOrderLineForItemsWithoutTransactions(WhseEntry);

        PhysInvtOrderLineArgs.PrepareLineArgs(WhseEntry, BlankItemLedgerEntry);
        if PhysInvtOrderHeader.GetSamePhysInvtOrderLine(PhysInvtOrderLineArgs, ErrorText, PhysInvtOrderLine) = 0 then begin
            OnCreatePhysInvtOrderLineForItemsWithoutTransactionsBeforeCreateNewPhysInvtOrderLine(WhseEntry, ItemLedgEntry);
            CreateNewPhysInvtOrderLine();
        end;
    end;

    procedure CreateNewPhysInvtOrderLine()
    var
        PhysInvtOrderLineArgs: Record "Phys. Invt. Order Line";
        InsertLine: Boolean;
    begin
        PhysInvtOrderLineArgs.PrepareLineArgs(WhseEntry, ItemLedgEntry);
        PhysInvtOrderLine.PrepareLine(
            PhysInvtOrderHeader."No.", NextLineNo, PhysInvtOrderLineArgs, InvtCountCode, CycleSourceType);
        PhysInvtOrderLine.CalcQtyAndLastItemLedgExpected(QtyExp, LastItemLedgEntryNo);
        InsertLine := false;
        OnCreateNewPhysInvtOrderLineOnAfterCalcQtyAndLastItemLedgExpected(QtyExp, LastItemLedgEntryNo, ItemLedgEntry, PhysInvtOrderLine, InsertLine, WhseEntry);
        if (QtyExp <> 0) or ZeroQty or InsertLine then begin
            PhysInvtOrderLine.Insert(true);
            PhysInvtOrderLine.CreateDimFromDefaultDim();
            if CalcQtyExpected then
                PhysInvtOrderLine.CalcQtyAndTrackLinesExpected();
            OnBeforePhysInvtOrderLineModify(PhysInvtOrderLine, CalcQtyExpected);
            PhysInvtOrderLine.Modify();
            NextLineNo := NextLineNo + 10000;
            LineCount := LineCount + 1;
        end;
    end;

    local procedure CalcItemPhysInvtOrderLinesForItemWithNoTransactions()
    var
        Location: Record Location;
        ItemVariant: Record "Item Variant";
    begin
        if not IncludeItemWithNoTransaction then
            exit;

        ItemVariant.SetRange("Item No.", Item."No.");
        if Item.GetFilter("Variant Filter") <> '' then
            Item.CopyFilter("Variant Filter", ItemVariant.Code);
        if Item.GetFilter("Location Filter") <> '' then
            Item.CopyFilter("Location Filter", Location."Code");

        SetItemLedgEntryFilters();
        OnBeforeCreateNewPhysInvtOrderLineForItemWithNoTransactionAfterSetItemVariantFilters(Item, ItemVariant);
        if Location.FindSet() then
            repeat
                CalcItemPhysInvtOrderLinesForItemWithNoTransactionsOnLocation(ItemVariant, Location);
            until Location.Next() = 0;

        if ShouldCalcForBlankLocation() then begin
            Clear(Location);
            CalcItemPhysInvtOrderLinesForItemWithNoTransactionsOnLocation(ItemVariant, Location);
        end;
        SetItemLedgEntryFilters();
    end;

    local procedure CalcItemPhysInvtOrderLinesForItemWithNoTransactionsOnLocation(var ItemVariant: Record "Item Variant"; Location: Record Location)
    var
        ItemVariantExists: Boolean;
    begin
        if PhysInvtTrackingMgt.LocationIsBinMandatory(Location.Code) then
            exit;

        ItemLedgEntry.SetRange("Location Code", Location.Code);

        if ItemVariant.FindSet() then begin
            ItemVariantExists := true;
            repeat
                ItemLedgEntry.SetRange("Variant Code", ItemVariant.Code);
                if ItemLedgEntry.IsEmpty() then
                    CreatePhysInvtOrderLineForItemsWithoutTransactions(Item."No.", ItemVariant.Code, Location.Code);
            until ItemVariant.Next() = 0
        end;

        ItemLedgEntry.SetRange("Variant Code", '');
        OnBeforeCreateNewPhysInvtOrderLineForItemWithNoTransaction(Item, ItemVariantExists, Location);
        if not Item.IsVariantMandatory() or not ItemVariantExists then
            if ItemLedgEntry.IsEmpty() then
                CreatePhysInvtOrderLineForItemsWithoutTransactions(Item."No.", '', Location.Code);

        ItemLedgEntry.SetRange("Location Code");
        ItemLedgEntry.SetRange("Variant Code");
    end;

    local procedure ShouldCalcForBlankLocation(): Boolean
    var
        TempLocation: Record Location temporary;
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.SetLoadFields("Location Mandatory");
        InventorySetup.Get();
        if InventorySetup."Location Mandatory" then
            exit(false);

        if Item.GetFilter("Location Filter") = '' then
            exit(true);

        // Verify empty location not excluded
        TempLocation.DeleteAll();
        TempLocation.Insert(false);
        TempLocation.SetFilter(Code, Item.GetFilter("Location Filter"));
        exit(not TempLocation.IsEmpty());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNewPhysInvtOrderLineForWhseEntry(Item: Record Item; WarehouseEntry: Record "Warehouse Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var ErrorText: Text[250]; var NextLineNo: Integer; InvtCountCode: Code[10]; CycleSourceType: Option " ",Item,SKU; CalcQtyExpected: Boolean; var LastItemLedgEntryNo: Integer; var LineCount: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcItemPhysInvtOrderLines(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePhysInvtOrderLineModify(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; CalcQtyExpected: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateNewPhysInvtOrderLineOnAfterCalcQtyAndLastItemLedgExpected(QtyExpected: Decimal; LastItemLedgEntryNo: Integer; ItemLedgerEntry: Record "Item Ledger Entry"; PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var InsertLine: Boolean; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPhysInvtOrderHeader(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPreDataItemItem(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenPage(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItemLedgEntryFilters(var ItemLedgEntry: Record "Item Ledger Entry"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterIsNewItemLedgEntryGroup(ItemLedgEntry: Record "Item Ledger Entry"; LastItemLedgEntry: Record "Item Ledger Entry"; var Result: Boolean; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsNewWhseEntryGroup(WhseEntry: Record "Warehouse Entry"; LastWhseEntry: Record "Warehouse Entry"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWhseEntryFilters(var WhseEntry: Record "Warehouse Entry"; ItemLedgEntry: Record "Item Ledger Entry"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNewPhysInvtOrderLineForItemWithNoTransactionAfterSetItemVariantFilters(var Item: Record Item; var ItemVariant: Record "Item Variant")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNewPhysInvtOrderLineForItemWithNoTransaction(var Item: Record Item; var ItemVariantExists: Boolean; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePhysInvtOrderLineForItemsWithoutTransactions(var WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePhysInvtOrderLineForItemsWithoutTransactionsBeforeCreateNewPhysInvtOrderLine(var WarehouseEntry: Record "Warehouse Entry"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePhysInvtOrderLines(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var Item: Record Item; var ItemBlocked: Boolean; var LineCount: Integer; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordItemOnAfterCalcShouldCalcItemPhysInvtOrderLines(var Item: Record Item; PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var ShouldCalcItemPhysInvtOrderLines: Boolean)
    begin
    end;
}

