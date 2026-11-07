// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Document;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;

report 5885 "Calc. Phys. Invt. Order (Bins)"
{
    Caption = 'Calc. Phys. Invt. Order (Bins)';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Bin; Bin)
        {
            DataItemTableView = sorting("Location Code", Code);
            RequestFilterFields = "Location Code", "Code";

            trigger OnAfterGetRecord()
            var
                Item: Record Item;
                ItemVariant: Record "Item Variant";
                PhysInvtOrderLineArgs: Record "Phys. Invt. Order Line";
                ItemVariantBlocked: Boolean;
                IsHandled: Boolean;
            begin
                Location.Get("Location Code");
                Location.TestField("Bin Mandatory");

                OnAfterGetRecordBinOnAfterCheckLocation(PhysInvtOrderHeader, Bin);

                if (not HideValidationDialog) and GuiAllowed() then begin
                    WindowDialog.Update(1, "Location Code");
                    WindowDialog.Update(2, Code);
                end;

                Clear(LastWarehouseEntry);

                WarehouseEntry.Reset();
                WarehouseEntry.SetCurrentKey("Location Code", "Bin Code", "Item No.", "Variant Code");
                WarehouseEntry.SetRange("Location Code", "Location Code");
                WarehouseEntry.SetRange("Bin Code", Code);
                OnAfterGetRecordBinOnAfterWarehouseEntrySetFilters(PhysInvtOrderHeader, Bin, WarehouseEntry);
                if WarehouseEntry.Find('-') then
                    repeat
                        if Item.Get(WarehouseEntry."Item No.") then
                            if not Item.Blocked then begin
                                ItemVariantBlocked := false;
                                if WarehouseEntry."Variant Code" <> '' then begin
                                    ItemVariant.SetLoadFields(Blocked);
                                    if ItemVariant.Get(WarehouseEntry."Item No.", WarehouseEntry."Variant Code") and ItemVariant.Blocked then begin
                                        ItemVariantBlocked := true;
                                        ItemsBlocked := true;
                                    end;
                                end;

                                if not ItemVariantBlocked then
                                    if IsNewWhseEntryGroup(Item) then begin
                                        LastWarehouseEntry := WarehouseEntry;
                                        IsHandled := false;
                                        OnBeforeCreateNewPhysInvtOrderLineForWhseEntry(
                                          Item, WarehouseEntry, PhysInvtOrderHeader, PhysInvtOrderLine, ErrorText, NextLineNo,
                                          CalcQtyExpectedReq, LastItemLedgEntryNo, LineCount, IsHandled);
                                        if not IsHandled then begin
                                            PhysInvtOrderLineArgs.PrepareLineArgs(WarehouseEntry);
                                            if PhysInvtOrderHeader.GetSamePhysInvtOrderLine(
                                                 PhysInvtOrderLineArgs,
                                                 ErrorText,
                                                 PhysInvtOrderLine) = 0
                                            then
                                                CreateNewPhysInvtOrderLine();
                                        end;
                                    end;
                            end else
                                ItemsBlocked := true;
                    until WarehouseEntry.Next() = 0;
            end;

            trigger OnPostDataItem()
            begin
                if (not HideValidationDialog) and GuiAllowed() then begin
                    WindowDialog.Close();
                    if ItemsBlocked then
                        Message(BlockedItemMsg);
                    Message(
                      StrSubstNo(LinesCreatedMsg, LineCount));
                end;
            end;

            trigger OnPreDataItem()
            begin
                PhysInvtOrderHeader.TestField("No.");
                PhysInvtOrderHeader.TestField(Status, PhysInvtOrderHeader.Status::Open);

                PhysInvtOrderHeader.LockTable();
                PhysInvtOrderLine.LockTable();

                PhysInvtOrderLine.Reset();
                PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
                if PhysInvtOrderLine.FindLast() then
                    NextLineNo := PhysInvtOrderLine."Line No." + 10000
                else
                    NextLineNo := 10000;

                if (not HideValidationDialog) and GuiAllowed() then
                    WindowDialog.Open(CalculatingLinesMsg + LocationAndBinMsg);

                LineCount := 0;
                ItemsBlocked := false;
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
                    field(CalcQtyExpected; CalcQtyExpectedReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calculate Qty. Expected';
                        ToolTip = 'Specifies if you want the program to calculate and insert the contents of the field quantity expected for new created physical inventory order lines.';
                    }
                    field(ZeroQty; ZeroQtyReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Items Not on Inventory';
                        ToolTip = 'Specifies if journal lines should be created for items that are not on inventory, that is, items where the value in the Qty. (Calculated) field is 0.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        CalculatingLinesMsg: Label 'Calculating the order lines...\\';
        LocationAndBinMsg: Label 'Location #1########   Bin #2############', Comment = '%1,%2 = counters';
        LinesCreatedMsg: Label '%1 new lines have been created.', Comment = '%1 = counter';
        BlockedItemMsg: Label 'There is at least one blocked item or item variant that was skipped.';

    protected var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        Location: Record Location;
        WarehouseEntry: Record "Warehouse Entry";
        LastWarehouseEntry: Record "Warehouse Entry";
        WindowDialog: Dialog;
        ErrorText: Text[250];
        QtyExp: Decimal;
        LastItemLedgEntryNo: Integer;
        NextLineNo: Integer;
        LineCount: Integer;
        ZeroQtyReq: Boolean;
        CalcQtyExpectedReq: Boolean;
        ItemsBlocked: Boolean;
        HideValidationDialog: Boolean;

    procedure SetPhysInvtOrderHeader(NewPhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        PhysInvtOrderHeader := NewPhysInvtOrderHeader;

        OnAfterSetPhysInvtOrderHeader(PhysInvtOrderHeader, Location, Bin);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure CreateNewPhysInvtOrderLine()
    var
        PhysInvtOrderLineArgs: Record "Phys. Invt. Order Line";
        InsertLine: Boolean;
    begin
        PhysInvtOrderLineArgs.PrepareLineArgs(WarehouseEntry);
        PhysInvtOrderLine.PrepareLine(
            PhysInvtOrderHeader."No.", NextLineNo, PhysInvtOrderLineArgs, '', 0);
        PhysInvtOrderLine.CalcQtyAndLastItemLedgExpected(QtyExp, LastItemLedgEntryNo);
        InsertLine := false;
        OnCreateNewPhysInvtOrderLineOnAfterCalcQtyAndLastItemLedgExpected(QtyExp, LastItemLedgEntryNo, WarehouseEntry, PhysInvtOrderLine, InsertLine);
        if (QtyExp <> 0) or ZeroQtyReq or InsertLine then begin
            PhysInvtOrderLine.Insert(true);
            PhysInvtOrderLine.CreateDimFromDefaultDim();
            if CalcQtyExpectedReq then
                PhysInvtOrderLine.CalcQtyAndTrackLinesExpected();
            OnBeforePhysInvtOrderLineModify(PhysInvtOrderLine, CalcQtyExpectedReq);
            PhysInvtOrderLine.Modify();
            NextLineNo := NextLineNo + 10000;
            LineCount := LineCount + 1;
        end;
    end;

    local procedure IsNewWhseEntryGroup(Item: Record Item) Result: Boolean
    begin
        Result :=
            (LastWarehouseEntry."Location Code" <> WarehouseEntry."Location Code") or
            (LastWarehouseEntry."Bin Code" <> WarehouseEntry."Bin Code") or
            (LastWarehouseEntry."Item No." <> WarehouseEntry."Item No.") or
            (LastWarehouseEntry."Variant Code" <> WarehouseEntry."Variant Code");
        OnAfterIsNewWhseEntryGroup(WarehouseEntry, LastWarehouseEntry, Result, Item);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNewPhysInvtOrderLineForWhseEntry(Item: Record Item; WarehouseEntry: Record "Warehouse Entry"; PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var ErrorText: Text; var NextLineNo: Integer; CalcQtyExpected: Boolean; var LastItemLedgEntryNo: Integer; var LineCount: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePhysInvtOrderLineModify(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; CalcQtyExpected: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateNewPhysInvtOrderLineOnAfterCalcQtyAndLastItemLedgExpected(QtyExpected: Decimal; LastItemLedgEntryNo: Integer; WarehouseEntry: Record "Warehouse Entry"; PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var InsertLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordBinOnAfterCheckLocation(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPhysInvtOrderHeader(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var Location: Record Location; var Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsNewWhseEntryGroup(WhseEntry: Record "Warehouse Entry"; LastWhseEntry: Record "Warehouse Entry"; var Result: Boolean; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordBinOnAfterWarehouseEntrySetFilters(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var Bin: Record "Bin"; var WarehouseEntry: Record "Warehouse Entry")
    begin
    end;
}
