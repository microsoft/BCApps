// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using System.Utilities;

codeunit 5847 "Get Average Cost Calc Overview"
{
    TableNo = "Average Cost Calc. Overview";

    trigger OnRun()
    begin
        AvgCostAdjmtEntryPoint.SetRange("Item No.", Rec."Item No.");
        AvgCostAdjmtEntryPoint.SetFilter("Location Code", Rec.GetFilter("Location Code"));
        AvgCostAdjmtEntryPoint.SetFilter("Variant Code", Rec.GetFilter("Variant Code"));
        AvgCostAdjmtEntryPoint.SetFilter("Valuation Date", Rec.GetFilter("Valuation Date"));
        OnRunOnSetAvgCostAdjmtEntryPointFilters(AvgCostAdjmtEntryPoint, Rec);

        Rec.Reset();
        Rec.DeleteAll();
        if AvgCostAdjmtEntryPoint.FindSet() then
            repeat
                Rec.Init();
                Rec.Type := Rec.Type::"Closing Entry";
                Rec."Entry No." := Rec."Entry No." + 1;
                CopyAvgCostAdjmtEntryPointFieldsToAverageCostCalcOverview(AvgCostAdjmtEntryPoint, Rec);
                Rec."Attached to Valuation Date" := Rec."Valuation Date";
                Rec."Attached to Entry No." := Rec."Entry No.";
                if EntriesExist(Rec) then begin
                    OnBeforeAvgCostAdjmtEntryPointInsert(Rec, AvgCostAdjmtEntryPoint);
                    Rec.Insert();
                end else
                    AvgCostAdjmtEntryPoint.Delete();
            until AvgCostAdjmtEntryPoint.Next() = 0;
    end;

    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        ValueEntry: Record "Value Entry";
        Item: Record Item;
        CalendarPeriod: Record Date;
        AttachedToEntryNo: Integer;

    procedure Calculate(var AvgCostCalcOverview: Record "Average Cost Calc. Overview")
    var
        AvgCostCalcOverview2: Record "Average Cost Calc. Overview";
        FirstEntryNo: Integer;
    begin
        AvgCostCalcOverview2 := AvgCostCalcOverview;
        AvgCostCalcOverview.Find();
        AvgCostCalcOverview.TestField("Item No.");
        AvgCostCalcOverview.TestField(Type, AvgCostCalcOverview.Type::"Closing Entry");

        AttachedToEntryNo := AvgCostCalcOverview."Entry No.";

        Item.Get(ValueEntry."Item No.");
        OnCalculateOnAfterGetItem(Item, AvgCostCalcOverview);
        if Item."Costing Method" = Item."Costing Method"::Average then begin
            CalendarPeriod."Period Start" := AvgCostCalcOverview."Valuation Date";
            AvgCostAdjmtEntryPoint."Valuation Date" := AvgCostCalcOverview."Valuation Date";
            AvgCostAdjmtEntryPoint.GetValuationPeriod(CalendarPeriod);
            AvgCostCalcOverview.SetRange("Valuation Date", CalendarPeriod."Period Start", CalendarPeriod."Period End");
        end else
            AvgCostCalcOverview.SetRange("Valuation Date", AvgCostCalcOverview2."Valuation Date");

        if not (Item."Costing Method" = Item."Costing Method"::Average) or
           not AvgCostAdjmtEntryPoint.IsAvgCostCalcTypeItem(AvgCostCalcOverview."Valuation Date")
        then begin
            AvgCostCalcOverview.SetRange("Variant Code", AvgCostCalcOverview."Variant Code");
            AvgCostCalcOverview.SetRange("Location Code", AvgCostCalcOverview."Location Code");
        end;
        AvgCostCalcOverview.SetRange(Level, 1, 2);
        AvgCostCalcOverview.DeleteAll();
        AvgCostCalcOverview.Reset();
        AvgCostCalcOverview.Find('+');

        FirstEntryNo := 0;
        if EntriesExist(AvgCostCalcOverview2) then
            repeat
                InsertAvgCostCalcOvervwFromILE(AvgCostCalcOverview, ValueEntry, AvgCostCalcOverview2."Valuation Date");
                if FirstEntryNo = 0 then
                    FirstEntryNo := AvgCostCalcOverview."Entry No.";
            until ValueEntry.Next() = 0;

        if AvgCostCalcOverview.Get(FirstEntryNo) then;
    end;

    local procedure InsertAvgCostCalcOvervwFromILE(var AvgCostCalcOverview: Record "Average Cost Calc. Overview"; ValueEntry: Record "Value Entry"; ValuationDate: Date)
    var
        CopyOfAvgCostCalcOverview: Record "Average Cost Calc. Overview";
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
        ModifyLine: Boolean;
    begin
        CopyOfAvgCostCalcOverview.Copy(AvgCostCalcOverview);

        AvgCostCalcOverview.SetCurrentKey("Item Ledger Entry No.");
        AvgCostCalcOverview.SetRange("Item Ledger Entry No.", ValueEntry."Item Ledger Entry No.");
        AvgCostCalcOverview.SetRange("Attached to Entry No.", AttachedToEntryNo);
        AvgCostCalcOverview.SetRange("Attached to Valuation Date", ValuationDate);
        if ValueEntry."Partial Revaluation" then
            AvgCostCalcOverview.SetRange(Type, AvgCostCalcOverview.Type::Revaluation);
        ModifyLine := AvgCostCalcOverview.Find('-');
        if not ModifyLine then begin
            ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.");
            AvgCostCalcOverview.Init();
            CopyItemLedgerEntryFieldsToAverageCostCalcOverview(ItemLedgEntry, AvgCostCalcOverview);
            AvgCostCalcOverview."Entry No." := CopyOfAvgCostCalcOverview."Entry No." + 1;
            case true of
                ValueEntry."Partial Revaluation":
                    AvgCostCalcOverview.Type := AvgCostCalcOverview.Type::Revaluation;
                ItemLedgEntry.Positive:
                    if ItemApplnEntry.IsAppliedFromIncrease(ItemLedgEntry."Entry No.") then
                        AvgCostCalcOverview.Type := AvgCostCalcOverview.Type::"Applied Increase"
                    else
                        AvgCostCalcOverview.Type := AvgCostCalcOverview.Type::Increase;
                ItemLedgEntry."Applies-to Entry" <> 0:
                    AvgCostCalcOverview.Type := AvgCostCalcOverview.Type::"Applied Decrease";
                else
                    AvgCostCalcOverview.Type := AvgCostCalcOverview.Type::Decrease;
            end;
            AvgCostCalcOverview."Attached to Entry No." := AttachedToEntryNo;
            AvgCostCalcOverview."Attached to Valuation Date" := ValuationDate;
            AvgCostCalcOverview."Valuation Date" := ValueEntry."Valuation Date";
            AvgCostCalcOverview.Quantity := 0;
            AvgCostCalcOverview.Level := 1;
        end;

        AvgCostCalcOverview.Quantity := AvgCostCalcOverview.Quantity + ValueEntry."Item Ledger Entry Quantity";
        AvgCostCalcOverview."Cost Amount (Actual)" := AvgCostCalcOverview."Cost Amount (Actual)" + ValueEntry."Cost Amount (Actual)";
        AvgCostCalcOverview."Cost Amount (Expected)" := AvgCostCalcOverview."Cost Amount (Expected)" + ValueEntry."Cost Amount (Expected)";

        OnBeforeModifyAvgCostCalcOverview(AvgCostCalcOverview, ValueEntry, ModifyLine);
        if ModifyLine then
            AvgCostCalcOverview.Modify()
        else begin
            AvgCostCalcOverview.Insert();
            CopyOfAvgCostCalcOverview := AvgCostCalcOverview;
        end;
        AvgCostCalcOverview.Copy(CopyOfAvgCostCalcOverview);
    end;

    local procedure CopyItemLedgerEntryFieldsToAverageCostCalcOverview(var ItemLedgerEntry: Record "Item Ledger Entry"; var AverageCostCalcOverview: Record "Average Cost Calc. Overview")
    begin
        AverageCostCalcOverview."Item No." := ItemLedgerEntry."Item No.";
        AverageCostCalcOverview."Location Code" := ItemLedgerEntry."Location Code";
        AverageCostCalcOverview."Variant Code" := ItemLedgerEntry."Variant Code";
        AverageCostCalcOverview."Posting Date" := ItemLedgerEntry."Posting Date";
        AverageCostCalcOverview."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
        AverageCostCalcOverview."Entry Type" := ItemLedgerEntry."Entry Type";
        AverageCostCalcOverview."Document Type" := ItemLedgerEntry."Document Type".AsInteger();
        AverageCostCalcOverview."Document No." := ItemLedgerEntry."Document No.";
        AverageCostCalcOverview."Document Line No." := ItemLedgerEntry."Document Line No.";
        AverageCostCalcOverview.Description := ItemLedgerEntry.Description;

        OnAfterCopyItemLedgerEntryFieldsToAverageCostCalcOverview(ItemLedgerEntry, AverageCostCalcOverview);
    end;

    local procedure CopyAvgCostAdjmtEntryPointFieldsToAverageCostCalcOverview(var AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point"; var AverageCostCalcOverview: Record "Average Cost Calc. Overview")
    begin
        AverageCostCalcOverview."Item No." := AvgCostAdjmtEntryPoint."Item No.";
        AverageCostCalcOverview."Variant Code" := AvgCostAdjmtEntryPoint."Variant Code";
        AverageCostCalcOverview."Location Code" := AvgCostAdjmtEntryPoint."Location Code";
        AverageCostCalcOverview."Valuation Date" := AvgCostAdjmtEntryPoint."Valuation Date";
        AverageCostCalcOverview."Cost is Adjusted" := AvgCostAdjmtEntryPoint."Cost Is Adjusted";

        OnAfterCopyAvgCostAdjmtEntryPointFieldsToAverageCostCalcOverview(AvgCostAdjmtEntryPoint, AverageCostCalcOverview)
    end;

    procedure EntriesExist(var AvgCostCalcOverview: Record "Average Cost Calc. Overview"): Boolean
    begin
        Item.Get(AvgCostCalcOverview."Item No.");
        OnEntriesExistOnAfterGetItem(Item, AvgCostCalcOverview);

        ValueEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        ValueEntry.SetLoadFields("Item No.", "Item Ledger Entry No.", "Partial Revaluation", "Valuation Date", "Item Ledger Entry Quantity", "Cost Amount (Actual)", "Cost Amount (Expected)");
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item No.", "Valuation Date", "Location Code", "Variant Code", "Entry No.");
        ValueEntry.SetRange("Item No.", AvgCostCalcOverview."Item No.");

        if Item."Costing Method" = Item."Costing Method"::Average then begin
            CalendarPeriod."Period Start" := AvgCostCalcOverview."Valuation Date";
            AvgCostAdjmtEntryPoint."Valuation Date" := AvgCostCalcOverview."Valuation Date";
            AvgCostAdjmtEntryPoint.GetValuationPeriod(CalendarPeriod);
            ValueEntry.SetRange("Valuation Date", CalendarPeriod."Period Start", CalendarPeriod."Period End");
        end else
            ValueEntry.SetRange("Valuation Date", AvgCostCalcOverview."Valuation Date");

        if not AvgCostAdjmtEntryPoint.IsAvgCostCalcTypeItem(AvgCostCalcOverview."Valuation Date") or
           not (Item."Costing Method" = Item."Costing Method"::Average)
        then begin
            ValueEntry.SetRange("Location Code", AvgCostCalcOverview."Location Code");
            ValueEntry.SetRange("Variant Code", AvgCostCalcOverview."Variant Code");
        end;
        OnEntriesExistOnBeforeFind(ValueEntry, Item, AvgCostCalcOverview);
        exit(ValueEntry.FindSet());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyAvgCostAdjmtEntryPointFieldsToAverageCostCalcOverview(var AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point"; var AverageCostCalcOverview: Record "Average Cost Calc. Overview")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemLedgerEntryFieldsToAverageCostCalcOverview(var ItemLedgerEntry: Record "Item Ledger Entry"; var AverageCostCalcOverview: Record "Average Cost Calc. Overview")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAvgCostAdjmtEntryPointInsert(var AverageCostCalcOverview: Record "Average Cost Calc. Overview"; AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyAvgCostCalcOverview(var AverageCostCalcOverview: Record "Average Cost Calc. Overview"; ValueEntry: Record "Value Entry"; ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnAfterGetItem(var Item: Record Item; var AvgCostCalcOverview: Record "Average Cost Calc. Overview")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEntriesExistOnAfterGetItem(var Item: Record Item; var AvgCostCalcOverview: Record "Average Cost Calc. Overview")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEntriesExistOnBeforeFind(var ValueEntry: Record "Value Entry"; var Item: Record Item; var AverageCostCalcOverview: Record "Average Cost Calc. Overview")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnSetAvgCostAdjmtEntryPointFilters(var AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point"; var AverageCostCalcOverview: Record "Average Cost Calc. Overview")
    begin
    end;
}

