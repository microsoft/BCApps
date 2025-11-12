// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;
using System.Utilities;

codeunit 8365 SheetDefCustom implements ISheetDefinition
{
    var
        SheetDefMgt: Codeunit SheetDefMgt;
        CustomTypeDescTxt: Label 'Custom totaling per sheet', MaxLength = 30;
        DeleteLinesQst: Label 'Changing away from sheet type custom will delete all lines for this sheet definition. \Do you want to continue?';

    procedure PopulateLineBufferForReporting(SheetDefName: Record "Sheet Definition Name"; var TempSheetDefLine: Record "Sheet Definition Line")
    var
        SheetDefLine: Record "Sheet Definition Line";
    begin
        if not TempSheetDefLine.IsTemporary() then
            exit;
        SheetDefLine.SetRange(Name, SheetDefName.Name);
        if SheetDefLine.FindSet() then
            repeat
                TempSheetDefLine := SheetDefLine;
                TempSheetDefLine.Insert();
            until SheetDefLine.Next() = 0;
    end;

    procedure FilterGLEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var GLEntry: Record "G/L Entry")
    begin
        SheetDefMgt.FilterGLEntryByDimension(SheetDefLine, GLEntry);
        SheetDefMgt.FilterGLEntryByBusinessUnit(SheetDefLine, GLEntry);
    end;

    procedure FilterGLBudgetEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var GLBudgetEntry: Record "G/L Budget Entry")
    begin
        SheetDefMgt.FilterGLBudgetEntryByDimension(SheetDefLine, GLBudgetEntry);
        SheetDefMgt.FilterGLBudgetEntryByBusinessUnit(SheetDefLine, GLBudgetEntry);
    end;

    procedure FilterCFEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var CFForecastEntry: Record "Cash Flow Forecast Entry")
    begin
        SheetDefMgt.FilterCFEntryByDimension(SheetDefLine, CFForecastEntry);
    end;

    procedure FilterAnalysisViewEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var AnalysisViewEntry: Record "Analysis View Entry")
    begin
        SheetDefMgt.FilterAnalysisViewEntryByDimension(SheetDefLine, AnalysisViewEntry);
        SheetDefMgt.FilterAnalysisViewEntryByBusinessUnit(SheetDefLine, AnalysisViewEntry);
    end;

    procedure FilterAnalysisViewBudgetEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var AnalysisViewBudgetEntry: Record "Analysis View Budget Entry")
    begin
        SheetDefMgt.FilterAnalysisViewBudgetEntryByDimension(SheetDefLine, AnalysisViewBudgetEntry);
        SheetDefMgt.FilterAnalysisViewBudgetEntryByBusinessUnit(SheetDefLine, AnalysisViewBudgetEntry);
    end;

    procedure SheetTypeToText(SheetDefName: Record "Sheet Definition Name"; Type: Enum "Sheet Type"; var Text: Text): Boolean
    begin
        if Type = Type::Custom then begin
            Text := Format(Enum::"Sheet Type"::Custom);
            exit(true);
        end;
    end;

    procedure TextToSheetType(SheetDefName: Record "Sheet Definition Name"; Text: Text; var Type: Enum "Sheet Type"): Boolean
    begin
        if Text = UpperCase(Format(Enum::"Sheet Type"::Custom)) then begin
            Type := Type::Custom;
            exit(true);
        end;
    end;

    procedure InsertBufferForSheetTotalingLookup(SheetDefName: Record "Sheet Definition Name"; Type: Enum "Sheet Type"; var DimSelection: Page "Dimension Selection")
    begin
        DimSelection.InsertDimSelBuf(false, Format(Enum::"Sheet Type"::Custom), CustomTypeDescTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sheet Definition Name", OnAfterValidateEvent, "Sheet Type", false, false)]
    local procedure AfterValidateSheetType(var Rec: Record "Sheet Definition Name"; var xRec: Record "Sheet Definition Name")
    var
        SheetDefLine: Record "Sheet Definition Line";
        ConfirmMgt: Codeunit "Confirm Management";
    begin
        if (xRec."Sheet Type" <> xRec."Sheet Type"::Custom) or (xRec."Sheet Type" = Rec."Sheet Type") then
            exit;

        SheetDefLine.SetRange(Name, Rec.Name);
        if SheetDefLine.IsEmpty() then
            exit;

        if not ConfirmMgt.GetResponseOrDefault(DeleteLinesQst, true) then
            Error('');

        SheetDefLine.DeleteAll(true);
    end;
}