// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 8363 DimPerspectiveAccSchMgtHandler
{
    EventSubscriberInstance = Manual;

    var
        DimPerspectiveName: Record "Dimension Perspective Name";
        DimPerspectiveLine: Record "Dimension Perspective Line";

    procedure SetDimPerspectiveName(DimPerspectiveName: Record "Dimension Perspective Name")
    begin
        this.DimPerspectiveName := DimPerspectiveName;
    end;

    procedure SetDimPerspectiveLine(DimPerspectiveLine: Record "Dimension Perspective Line")
    begin
        this.DimPerspectiveLine := DimPerspectiveLine;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AccSchedManagement, OnAfterSetGLAccGLEntryFilters, '', false, false)]
    local procedure OnAfterSetGLAccGLEntryFilters(var GLEntry: Record "G/L Entry")
    var
        IDimPerspective: Interface IDimensionPerspective;
        LastFilterGroup: Integer;
    begin
        IDimPerspective := DimPerspectiveName."Perspective Type";
        LastFilterGroup := GLEntry.FilterGroup();
        GLEntry.FilterGroup(9);
        IDimPerspective.FilterGLEntryByPerspectiveTotaling(DimPerspectiveLine, GLEntry);
        GLEntry.FilterGroup(LastFilterGroup);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AccSchedManagement, OnAfterSetGLAccGLBudgetEntryFilters, '', false, false)]
    local procedure OnAfterSetGLAccGLBudgetEntryFilters(var GLBudgetEntry: Record "G/L Budget Entry")
    var
        IDimPerspective: Interface IDimensionPerspective;
        LastFilterGroup: Integer;
    begin
        IDimPerspective := DimPerspectiveName."Perspective Type";
        LastFilterGroup := GLBudgetEntry.FilterGroup();
        GLBudgetEntry.FilterGroup(9);
        IDimPerspective.FilterGLBudgetEntryByPerspectiveTotaling(DimPerspectiveLine, GLBudgetEntry);
        GLBudgetEntry.FilterGroup(LastFilterGroup);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AccSchedManagement, OnSetCFEntryFiltersOnAfterAccShedLineCopyFilter, '', false, false)]
    local procedure OnSetCFEntryFiltersOnAfterAccShedLineCopyFilter(var CFForecastEntry: Record "Cash Flow Forecast Entry")
    var
        IDimPerspective: Interface IDimensionPerspective;
        LastFilterGroup: Integer;
    begin
        IDimPerspective := DimPerspectiveName."Perspective Type";
        LastFilterGroup := CFForecastEntry.FilterGroup();
        CFForecastEntry.FilterGroup(9);
        IDimPerspective.FilterCFEntryByPerspectiveTotaling(DimPerspectiveLine, CFForecastEntry);
        CFForecastEntry.FilterGroup(LastFilterGroup);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AccSchedManagement, OnAfterSetGLAccAnalysisViewEntryFilters, '', false, false)]
    local procedure OnAfterSetGLAccAnalysisViewEntryFilters(var AnalysisViewEntry: Record "Analysis View Entry")
    var
        IDimPerspective: Interface IDimensionPerspective;
        LastFilterGroup: Integer;
    begin
        IDimPerspective := DimPerspectiveName."Perspective Type";
        LastFilterGroup := AnalysisViewEntry.FilterGroup();
        AnalysisViewEntry.FilterGroup(9);
        IDimPerspective.FilterAnalysisViewEntryByPerspectiveTotaling(DimPerspectiveLine, AnalysisViewEntry);
        AnalysisViewEntry.FilterGroup(LastFilterGroup);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AccSchedManagement, OnAfterSetCFAnalysisViewEntryFilters, '', false, false)]
    local procedure OnAfterSetCFAnalysisViewEntryFilters(var AnalysisViewEntry: Record "Analysis View Entry")
    var
        IDimPerspective: Interface IDimensionPerspective;
        LastFilterGroup: Integer;
    begin
        IDimPerspective := DimPerspectiveName."Perspective Type";
        LastFilterGroup := AnalysisViewEntry.FilterGroup();
        AnalysisViewEntry.FilterGroup(9);
        IDimPerspective.FilterAnalysisViewEntryByPerspectiveTotaling(DimPerspectiveLine, AnalysisViewEntry);
        AnalysisViewEntry.FilterGroup(LastFilterGroup);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AccSchedManagement, OnAfterSetGLAccAnalysisViewBudgetEntries, '', false, false)]
    local procedure OnAfterSetGLAccAnalysisViewBudgetEntries(var AnalysisViewBudgetEntry: Record "Analysis View Budget Entry")
    var
        IDimPerspective: Interface IDimensionPerspective;
        LastFilterGroup: Integer;
    begin
        IDimPerspective := DimPerspectiveName."Perspective Type";
        LastFilterGroup := AnalysisViewBudgetEntry.FilterGroup();
        AnalysisViewBudgetEntry.FilterGroup(9);
        IDimPerspective.FilterAnalysisViewBudgetEntryByPerspectiveTotaling(DimPerspectiveLine, AnalysisViewBudgetEntry);
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