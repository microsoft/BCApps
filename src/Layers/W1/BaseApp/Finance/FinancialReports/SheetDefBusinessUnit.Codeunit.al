// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 8364 SheetDefBusinessUnit implements ISheetDefinition
{
    var
        SheetDefMgt: Codeunit SheetDefMgt;

    procedure PopulateLineBufferForReporting(SheetDefName: Record "Sheet Definition Name"; var TempSheetDefLine: Record "Sheet Definition Line")
    var
        BusUnit: Record "Business Unit";
        TempBusUnit: Record "Business Unit" temporary;
    begin
        if not TempSheetDefLine.IsTemporary() then
            exit;
        if BusUnit.FindSet() then
            repeat
                TempSheetDefLine.Init();
                TempSheetDefLine.Name := SheetDefName.Name;
                TempSheetDefLine."Line No." += 10000;
                TempSheetDefLine."Sheet Header" := CopyStr(BusUnit.Name, 1, MaxStrLen(TempSheetDefLine."Sheet Header"));
                TempBusUnit := BusUnit;
                TempBusUnit.SetRecFilter();
                TempSheetDefLine."Business Unit Totaling" := CopyStr(TempBusUnit.GetFilter(Code), 1, MaxStrLen(TempSheetDefLine."Business Unit Totaling"));
                TempSheetDefLine.Insert();
            until BusUnit.Next() = 0;
    end;

    procedure FilterGLEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var GLEntry: Record "G/L Entry")
    begin
        SheetDefMgt.FilterGLEntryByBusinessUnit(SheetDefLine, GLEntry);
    end;

    procedure FilterGLBudgetEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var GLBudgetEntry: Record "G/L Budget Entry")
    begin
        SheetDefMgt.FilterGLBudgetEntryByBusinessUnit(SheetDefLine, GLBudgetEntry);
    end;

    procedure FilterCFEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var CFForecastEntry: Record "Cash Flow Forecast Entry")
    begin
    end;

    procedure FilterAnalysisViewEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var AnalysisViewEntry: Record "Analysis View Entry")
    begin
        SheetDefMgt.FilterAnalysisViewEntryByBusinessUnit(SheetDefLine, AnalysisViewEntry);
    end;

    procedure FilterAnalysisViewBudgetEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var AnalysisViewBudgetEntry: Record "Analysis View Budget Entry")
    begin
        SheetDefMgt.FilterAnalysisViewBudgetEntryByBusinessUnit(SheetDefLine, AnalysisViewBudgetEntry);
    end;

    procedure SheetTypeToText(SheetDefName: Record "Sheet Definition Name"; Type: Enum "Sheet Type"; var Text: Text): Boolean
    begin
        if (SheetDefName."Analysis View Name" = '') and (Type = Type::BusinessUnit) then begin
            Text := Format(Enum::"Sheet Type"::BusinessUnit);
            exit(true);
        end;
    end;

    procedure TextToSheetType(SheetDefName: Record "Sheet Definition Name"; Text: Text; var Type: Enum "Sheet Type"): Boolean
    begin
        if (SheetDefName."Analysis View Name" = '') and (Text = UpperCase(Format(Enum::"Sheet Type"::BusinessUnit))) then begin
            Type := Type::BusinessUnit;
            exit(true);
        end;
    end;

    procedure InsertBufferForSheetTotalingLookup(SheetDefName: Record "Sheet Definition Name"; Type: Enum "Sheet Type"; var DimSelection: Page "Dimension Selection")
    begin
        if SheetDefName."Analysis View Name" <> '' then
            exit;
        DimSelection.InsertDimSelBuf(false, Format(Enum::"Sheet Type"::BusinessUnit), Format(Enum::"Sheet Type"::BusinessUnit));
    end;
}