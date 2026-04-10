// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Ledger;
using System.Utilities;

codeunit 5848 "Avg. Cost Entry Point Mgt." implements "Average Cost Entry Point"
{
    Permissions = TableData "Avg. Cost Adjmt. Entry Point" = rimd;

    procedure GetMaxValuationDate(ItemLedgEntry: Record "Item Ledger Entry"; ValueEntry: Record "Value Entry") MaxValuationDate: Date
    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        MaxValuationDate := 0D;
        AvgCostAdjmtEntryPoint.SetRange("Item No.", ItemLedgEntry."Item No.");
        if not AvgCostAdjmtEntryPoint.IsAvgCostCalcTypeItem(ValueEntry."Valuation Date") then begin
            AvgCostAdjmtEntryPoint.SetRange("Variant Code", ItemLedgEntry."Variant Code");
            AvgCostAdjmtEntryPoint.SetRange("Location Code", ItemLedgEntry."Location Code");
        end;
        AvgCostAdjmtEntryPoint.SetRange("Valuation Date", ValueEntry."Valuation Date", DMY2Date(31, 12, 9999));
        if AvgCostAdjmtEntryPoint.FindFirst() then
            MaxValuationDate := AvgCostAdjmtEntryPoint."Valuation Date";
    end;

    procedure LockBuffer()
    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        AvgCostAdjmtEntryPoint.LockTable();
    end;

    procedure UpdateValuationDate(ValueEntry: Record "Value Entry")
    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        AvgCostAdjmtEntryPoint.UpdateValuationDate(ValueEntry);
    end;

    procedure IsEntriesAdjusted(ItemNo: Code[20]; EndingDate: Date): Boolean
    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        AvgCostAdjmtEntryPoint.Reset();
        AvgCostAdjmtEntryPoint.SetCurrentKey("Item No.", "Cost Is Adjusted", "Valuation Date");
        if ItemNo <> '' then
            AvgCostAdjmtEntryPoint.SetRange("Item No.", ItemNo);
        AvgCostAdjmtEntryPoint.SetRange("Cost Is Adjusted", false);
        if EndingDate <> 0D then
            AvgCostAdjmtEntryPoint.SetRange("Valuation Date", 0D, EndingDate);
        exit(AvgCostAdjmtEntryPoint.IsEmpty());
    end;

    procedure GetValuationPeriod(var CalendarPeriod: Record Date; PostingDate: Date)
    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        AvgCostAdjmtEntryPoint."Valuation Date" := PostingDate;
        AvgCostAdjmtEntryPoint.GetValuationPeriod(CalendarPeriod);
    end;

    procedure DeleteBuffer(ItemNo: Code[20]; FromValuationDate: Date)
    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        AvgCostAdjmtEntryPoint.Reset();
        AvgCostAdjmtEntryPoint.SetRange("Item No.", ItemNo);
        if FromValuationDate <> 0D then
            AvgCostAdjmtEntryPoint.SetFilter("Valuation Date", '>=%1', FromValuationDate);
        AvgCostAdjmtEntryPoint.DeleteAll();
    end;
}
