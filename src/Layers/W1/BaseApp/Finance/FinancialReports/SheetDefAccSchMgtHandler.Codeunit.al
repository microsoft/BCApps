// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 8363 SheetDefAccSchMgtHandler
{
    EventSubscriberInstance = Manual;

    var
        SheetDefName: Record "Sheet Definition Name";
        SheetDefLine: Record "Sheet Definition Line";

    procedure SetSheetDefName(SheetDefName: Record "Sheet Definition Name")
    begin
        this.SheetDefName := SheetDefName;
    end;

    procedure SetSheetDefLine(SheetDefLine: Record "Sheet Definition Line")
    begin
        this.SheetDefLine := SheetDefLine;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AccSchedManagement, OnAfterSetGLAccGLEntryFilters, '', false, false)]
    local procedure OnAfterSetGLAccGLEntryFilters(var GLEntry: Record "G/L Entry")
    var
        ISheetDefinition: Interface ISheetDefinition;
        LastFilterGroup: Integer;
    begin
        ISheetDefinition := SheetDefName."Sheet Type";
        LastFilterGroup := GLEntry.FilterGroup();
        GLEntry.FilterGroup(9);
        ISheetDefinition.FilterGLEntryBySheetTotaling(SheetDefLine, GLEntry);
        GLEntry.FilterGroup(LastFilterGroup);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AccSchedManagement, OnAfterSetGLAccGLBudgetEntryFilters, '', false, false)]
    local procedure OnAfterSetGLAccGLBudgetEntryFilters(var GLBudgetEntry: Record "G/L Budget Entry")
    var
        ISheetDefinition: Interface ISheetDefinition;
        LastFilterGroup: Integer;
    begin
        ISheetDefinition := SheetDefName."Sheet Type";
        LastFilterGroup := GLBudgetEntry.FilterGroup();
        GLBudgetEntry.FilterGroup(9);
        ISheetDefinition.FilterGLBudgetEntryBySheetTotaling(SheetDefLine, GLBudgetEntry);
        GLBudgetEntry.FilterGroup(LastFilterGroup);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AccSchedManagement, OnSetCFEntryFiltersOnAfterAccShedLineCopyFilter, '', false, false)]
    local procedure OnSetCFEntryFiltersOnAfterAccShedLineCopyFilter(var CFForecastEntry: Record "Cash Flow Forecast Entry")
    var
        ISheetDefinition: Interface ISheetDefinition;
        LastFilterGroup: Integer;
    begin
        ISheetDefinition := SheetDefName."Sheet Type";
        LastFilterGroup := CFForecastEntry.FilterGroup();
        CFForecastEntry.FilterGroup(9);
        ISheetDefinition.FilterCFEntryBySheetTotaling(SheetDefLine, CFForecastEntry);
        CFForecastEntry.FilterGroup(LastFilterGroup);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AccSchedManagement, OnAfterSetGLAccAnalysisViewEntryFilters, '', false, false)]
    local procedure OnAfterSetGLAccAnalysisViewEntryFilters(var AnalysisViewEntry: Record "Analysis View Entry")
    var
        ISheetDefinition: Interface ISheetDefinition;
        LastFilterGroup: Integer;
    begin
        ISheetDefinition := SheetDefName."Sheet Type";
        LastFilterGroup := AnalysisViewEntry.FilterGroup();
        AnalysisViewEntry.FilterGroup(9);
        ISheetDefinition.FilterAnalysisViewEntryBySheetTotaling(SheetDefLine, AnalysisViewEntry);
        AnalysisViewEntry.FilterGroup(LastFilterGroup);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AccSchedManagement, OnAfterSetCFAnalysisViewEntryFilters, '', false, false)]
    local procedure OnAfterSetCFAnalysisViewEntryFilters(var AnalysisViewEntry: Record "Analysis View Entry")
    var
        ISheetDefinition: Interface ISheetDefinition;
        LastFilterGroup: Integer;
    begin
        ISheetDefinition := SheetDefName."Sheet Type";
        LastFilterGroup := AnalysisViewEntry.FilterGroup();
        AnalysisViewEntry.FilterGroup(9);
        ISheetDefinition.FilterAnalysisViewEntryBySheetTotaling(SheetDefLine, AnalysisViewEntry);
        AnalysisViewEntry.FilterGroup(LastFilterGroup);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AccSchedManagement, OnAfterSetGLAccAnalysisViewBudgetEntries, '', false, false)]
    local procedure OnAfterSetGLAccAnalysisViewBudgetEntries(var AnalysisViewBudgetEntry: Record "Analysis View Budget Entry")
    var
        ISheetDefinition: Interface ISheetDefinition;
        LastFilterGroup: Integer;
    begin
        ISheetDefinition := SheetDefName."Sheet Type";
        LastFilterGroup := AnalysisViewBudgetEntry.FilterGroup();
        AnalysisViewBudgetEntry.FilterGroup(9);
        ISheetDefinition.FilterAnalysisViewBudgetEntryBySheetTotaling(SheetDefLine, AnalysisViewBudgetEntry);
        AnalysisViewBudgetEntry.FilterGroup(LastFilterGroup);
    end;

    procedure FilterGLEntryByDimensions(var AccSchedLine: Record "Acc. Schedule Line"; var GLEntry: Record "G/L Entry")
    begin
        GLEntry.SetFilter("Global Dimension 1 Code", AccSchedLine.GetFilter("Dimension 1 Filter"));
        GLEntry.SetFilter("Global Dimension 2 Code", AccSchedLine.GetFilter("Dimension 2 Filter"));
        GLEntry.SetFilter("Shortcut Dimension 3 Code", AccSchedLine.GetFilter("Dimension 3 Filter"));
        GLEntry.SetFilter("Shortcut Dimension 4 Code", AccSchedLine.GetFilter("Dimension 4 Filter"));
        GLEntry.SetFilter("Shortcut Dimension 5 Code", AccSchedLine.GetFilter("Dimension 5 Filter"));
        GLEntry.SetFilter("Shortcut Dimension 6 Code", AccSchedLine.GetFilter("Dimension 6 Filter"));
        GLEntry.SetFilter("Shortcut Dimension 7 Code", AccSchedLine.GetFilter("Dimension 7 Filter"));
        GLEntry.SetFilter("Shortcut Dimension 8 Code", AccSchedLine.GetFilter("Dimension 8 Filter"));
    end;
}