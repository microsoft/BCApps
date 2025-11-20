// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Setup;

report 5405 "Calc. Consumption"
{
    Caption = 'Calc. Consumption';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Production Order"; "Production Order")
        {
            DataItemTableView = sorting(Status, "No.") where(Status = const(Released));
            RequestFilterFields = "No.";
            dataitem("Prod. Order Component"; "Prod. Order Component")
            {
                DataItemLink = Status = field(Status), "Prod. Order No." = field("No.");
                RequestFilterFields = "Item No.";

                trigger OnAfterGetRecord()
                var
                    NeededQty: Decimal;
                    IsHandled: Boolean;
                begin
                    Window.Update(2, "Item No.");

                    Clear(ItemJnlLine);
                    Item.Get("Item No.");
                    ProdOrderLine.Get(Status, "Prod. Order No.", "Prod. Order Line No.");

                    IsHandled := false;
                    OnBeforeGetNeededQty(NeededQty, CalcBasedOn, "Prod. Order Component", "Production Order", PostingDate, IsHandled);
                    if not IsHandled then
                        NeededQty := GetNeededQty(CalcBasedOn, true);

                    AdjustQtyToReservedFromInventory(NeededQty, ReservedFromStock);

                    if NeededQty <> 0 then begin
                        if LocationCode <> '' then
                            CreateConsumpJnlLine(LocationCode, '', NeededQty)
                        else
                            CreateConsumpJnlLine("Location Code", "Bin Code", NeededQty);
                        LastItemJnlLine := ItemJnlLine;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("Flushing Method", '<>%1&<>%2', "Flushing Method"::Backward, "Flushing Method"::"Pick + Backward");

                    OnAfterPreDataItemProdOrderComp("Prod. Order Component");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");
            end;

            trigger OnPreDataItem()
            begin
                ItemJnlLine.SetRange("Journal Template Name", ToTemplateName);
                ItemJnlLine.SetRange("Journal Batch Name", ToBatchName);
                if ItemJnlLine.FindLast() then
                    NextConsumpJnlLineNo := ItemJnlLine."Line No." + 10000
                else
                    NextConsumpJnlLineNo := 10000;

                Window.Open(
                  Text000 +
                  Text001 +
                  Text002 +
                  Text003);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date that you want the program to use in the Consumption Journal window.';
                    }
                    field(CalcBasedOn; CalcBasedOn)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Calculation Based on';
                        OptionCaption = 'Actual Output,Expected Output';
                        ToolTip = 'Specifies whether the calculation of the quantity to consume is based on the actual output or on the expected output (the quantity of finished goods that you expect to produce). The default value of this field can be set in the Manufacturing Setup.';
                    }
                    field(LocationCode; LocationCode)
                    {
                        ApplicationArea = Location;
                        Caption = 'Picking Location';
                        ToolTip = 'Specifies the location from where you want the program to post the items.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            Location: Record Location;
                        begin
                            if PAGE.RunModal(0, Location) = ACTION::LookupOK then begin
                                Text := Location.Code;
                                exit(true);
                            end;
                            exit(false);
                        end;
                    }
                    field("Reserved From Stock"; ReservedFromStock)
                    {
                        ApplicationArea = Reservation;
                        Caption = 'Reserved from stock';
                        ToolTip = 'Specifies if you want to calculate only components that are fully or partially reserved from current stock.';
                        ValuesAllowed = " ", "Full and Partial", Full;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            InitializeRequest(WorkDate(), GetDefaultCalcBasedOn());
        end;
    }

    labels
    {
    }

    var
        Item: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        ItemJnlLine: Record "Item Journal Line";
        LastItemJnlLine: Record "Item Journal Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        PostingDate: Date;
        CalcBasedOn: Option "Actual Output","Expected Output";
        ToTemplateName: Code[10];
        ToBatchName: Code[10];
        NextConsumpJnlLineNo: Integer;

#pragma warning disable AA0074
        Text000: Label 'Calculating consumption...\\';
#pragma warning disable AA0470
        Text001: Label 'Prod. Order No.   #1##########\';
        Text002: Label 'Item No.          #2##########\';
        Text003: Label 'Quantity          #3##########';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        LocationCode: Code[10];
        ReservedFromStock: Enum "Reservation From Stock";

    procedure InitializeRequest(NewPostingDate: Date; NewCalcBasedOn: Option)
    begin
        PostingDate := NewPostingDate;
        CalcBasedOn := NewCalcBasedOn;
    end;

    local procedure GetDefaultCalcBasedOn(): Option
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        if ManufacturingSetup.Get() then
            exit(ManufacturingSetup."Default Consum. Calc. Based on");

        exit(ManufacturingSetup."Default Consum. Calc. Based on"::"Expected Output");
    end;

    local procedure CreateConsumpJnlLine(LocationCode: Code[10]; BinCode: Code[20]; OriginalQtyToPost: Decimal)
    var
        Location: Record Location;
#if not CLEAN26
        ManufacturingSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup";
#endif
        QtyToPost: Decimal;
        ShouldModifyItemJnlLine: Boolean;
        ShouldAdjustQty: Boolean;
    begin
        QtyToPost := OriginalQtyToPost;
        OnBeforeCreateConsumpJnlLine(LocationCode, BinCode, QtyToPost);

        Window.Update(3, QtyToPost);

#if not CLEAN26
        if not ManufacturingSetup.IsFeatureKeyFlushingMethodManualWithoutPickEnabled() then
            ShouldAdjustQty := "Prod. Order Component"."Flushing Method" in ["Prod. Order Component"."Flushing Method"::Manual, "Prod. Order Component"."Flushing Method"::"Pick + Manual", "Prod. Order Component"."Flushing Method"::Forward, "Prod. Order Component"."Flushing Method"::"Pick + Forward"]
        else
#endif
            ShouldAdjustQty := "Prod. Order Component"."Flushing Method" in ["Prod. Order Component"."Flushing Method"::"Pick + Manual", "Prod. Order Component"."Flushing Method"::Forward, "Prod. Order Component"."Flushing Method"::"Pick + Forward"];
        if ShouldAdjustQty then begin
            Location.SetLoadFields("Prod. Consump. Whse. Handling");
            if Location.Get(LocationCode) and (Location."Prod. Consump. Whse. Handling" = Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)") then
                "Prod. Order Component".AdjustQtyToQtyPicked(QtyToPost);
        end;

        ShouldModifyItemJnlLine :=
            (ItemJnlLine."Item No." = "Prod. Order Component"."Item No.") and
            (LocationCode = ItemJnlLine."Location Code") and
            (BinCode = ItemJnlLine."Bin Code");
        OnCreateConsumpJnlLineOnAfterCalcShouldModifyItemJnlLine(ItemJnlLine, ShouldModifyItemJnlLine);

        if ShouldModifyItemJnlLine then begin
            ValidateItemJnlLineQuantity(QtyToPost, QtyToPost < OriginalQtyToPost);
            OnBeforeItemJnlLineModify(ItemJnlLine, "Prod. Order Component");
            ItemJnlLine.Modify();
        end else begin
            ItemJnlLine.Init();
            ItemJnlLine."Journal Template Name" := ToTemplateName;
            ItemJnlLine."Journal Batch Name" := ToBatchName;
            ItemJnlLine.SetUpNewLine(LastItemJnlLine);
            ItemJnlLine."Line No." := NextConsumpJnlLineNo;

            ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Consumption);
            ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
            ItemJnlLine.Validate("Order No.", "Prod. Order Component"."Prod. Order No.");
            ItemJnlLine.Validate("Source No.", ProdOrderLine."Item No.");
            ItemJnlLine.Validate("Posting Date", PostingDate);
            ItemJnlLine.Validate("Item No.", "Prod. Order Component"."Item No.");
            ItemJnlLine.Validate("Unit of Measure Code", "Prod. Order Component"."Unit of Measure Code");
            ItemJnlLine.Description := "Prod. Order Component".Description;
            ValidateItemJnlLineQuantity(QtyToPost, QtyToPost < OriginalQtyToPost);
            ItemJnlLine."Variant Code" := "Prod. Order Component"."Variant Code";
            ItemJnlLine.Validate("Location Code", LocationCode);
            if BinCode <> '' then
                ItemJnlLine."Bin Code" := BinCode;
            ItemJnlLine.Validate("Order Line No.", "Prod. Order Component"."Prod. Order Line No.");
            ItemJnlLine.Validate("Prod. Order Comp. Line No.", "Prod. Order Component"."Line No.");

            OnBeforeInsertItemJnlLine(ItemJnlLine, "Prod. Order Component");
            ItemJnlLine.Insert();
            OnAfterInsertItemJnlLine(ItemJnlLine);

            if Item."Item Tracking Code" <> '' then
                AssignItemTracking("Prod. Order Component", ItemJnlLine);
            OnCreateConsumpJnlLineOnAfterAssignItemTracking(ItemJnlLine, NextConsumpJnlLineNo);
        end;

        NextConsumpJnlLineNo := NextConsumpJnlLineNo + 10000;

        OnAfterCreateConsumpJnlLine(LocationCode, BinCode, QtyToPost, ItemJnlLine);
    end;

    local procedure ValidateItemJnlLineQuantity(QtyToPost: Decimal; IgnoreRoundingPrecision: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateItemJnlLineQuantity(ItemJnlLine, "Prod. Order Component", QtyToPost, IsHandled);
        if IsHandled then
            exit;

        if (Item."Rounding Precision" > 0) and not IgnoreRoundingPrecision then
            ItemJnlLine.Validate(Quantity, ItemJnlLine.Quantity + UOMMgt.RoundToItemRndPrecision(QtyToPost, Item."Rounding Precision"))
        else
            ItemJnlLine.Validate(Quantity, ItemJnlLine.Quantity + UOMMgt.RoundQty(QtyToPost));
    end;

    procedure SetTemplateAndBatchName(TemplateName: Code[10]; BatchName: Code[10])
    begin
        ToTemplateName := TemplateName;
        ToBatchName := BatchName;
    end;

    local procedure AssignItemTracking(ProdOrderComponent: Record "Prod. Order Component"; ItemJournalLine: Record "Item Journal Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SourceTrackingSpecification: Record "Tracking Specification";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempReservEntry: Record "Reservation Entry" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
        ItemTrackingLines: Page "Item Tracking Lines";
        Qty: Decimal;
        MinQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignItemTracking(ProdOrderComponent, ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        if ItemJournalLine.Quantity >= 0 then
            ItemTrackingMgt.CopyItemTracking(ProdOrderComponent.RowID1(), ItemJournalLine.RowID1(), false)
        else begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
            ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
            ItemLedgerEntry.SetRange("Order No.", ItemJournalLine."Order No.");
            ItemLedgerEntry.SetRange("Order Line No.", ItemJournalLine."Order Line No.");
            ItemLedgerEntry.SetRange("Prod. Order Comp. Line No.", ItemJournalLine."Prod. Order Comp. Line No.");
            ItemLedgerEntry.SetRange("Item No.", ItemJournalLine."Item No.");
            if ItemLedgerEntry.IsEmpty() then
                exit;

            Qty := 0;
            MinQty := ItemJournalLine."Quantity (Base)";
            ItemLedgerEntry.FindSet();
            repeat
                if Qty + ItemLedgerEntry.Quantity < MinQty then begin
                    ItemLedgerEntry.Quantity := MinQty - Qty;
                    Qty := MinQty;
                end else
                    Qty += ItemLedgerEntry.Quantity;

                TempReservEntry.SetTrackingFilterFromItemLedgEntry(ItemLedgerEntry);
                if TempReservEntry.FindFirst() then begin
                    TempReservEntry."Quantity (Base)" += ItemLedgerEntry.Quantity;
                    OnAssignItemTrackingOnBeforeTempReservEntryModify(TempReservEntry, ItemLedgerEntry);
                    TempReservEntry.Modify();
                end else begin
                    TempReservEntry."Entry No." := ItemLedgerEntry."Entry No.";
                    TempReservEntry.CopyTrackingFromItemLedgEntry(ItemLedgerEntry);
                    TempReservEntry."Quantity (Base)" := ItemLedgerEntry.Quantity;
                    OnAssignItemTrackingOnBeforeTempReservEntryInsert(TempReservEntry, ItemLedgerEntry);
                    TempReservEntry.Insert();
                end;
            until (ItemLedgerEntry.Next() = 0) or (Qty = MinQty);

            TempReservEntry.Reset();
            ItemTrackingMgt.SumUpItemTracking(TempReservEntry, TempTrackingSpecification, false, true);

            ItemJnlLineReserve.InitFromItemJnlLine(SourceTrackingSpecification, ItemJournalLine);
            ItemTrackingLines.RegisterItemTrackingLines(
              SourceTrackingSpecification, ItemJournalLine."Posting Date", TempTrackingSpecification);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertItemJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignItemTracking(var ProdOrderComponent: Record "Prod. Order Component"; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateConsumpJnlLine(LocationCode: Code[10]; BinCode: Code[20]; QtyToPost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemJnlLineModify(var ItemJournalLine: Record "Item Journal Line"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateItemJnlLineQuantity(var ItemJnlLine: Record "Item Journal Line"; ProdOrderComponent: Record "Prod. Order Component"; QtyToPost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateConsumpJnlLine(LocationCode: Code[10]; BinCode: Code[20]; QtyToPost: Decimal; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignItemTrackingOnBeforeTempReservEntryInsert(var TempReservationEntry: Record "Reservation Entry" temporary; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignItemTrackingOnBeforeTempReservEntryModify(var TempReservationEntry: Record "Reservation Entry" temporary; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPreDataItemProdOrderComp(var ProdOrderComponent: Record "Prod. Order Component");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateConsumpJnlLineOnAfterCalcShouldModifyItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; var ShouldModifyItemJnlLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateConsumpJnlLineOnAfterAssignItemTracking(var ItemJnlLine: Record "Item Journal Line"; var NextConsumpJnlLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNeededQty(var NeededQty: Decimal; CalcBasedOn: Option "Actual Output","Expected Output"; ProdOrderComponent: Record "Prod. Order Component"; ProductionOrder: Record "Production Order"; PostingDate: Date; var IsHandled: Boolean)
    begin
    end;
}

