// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 8366 DimensionPerspectiveMgt
{
    procedure FilterGLEntryByDimension(DimPerspectiveLine: Record "Dimension Perspective Line"; var GLEntry: Record "G/L Entry")
    begin
        GLEntry.SetFilter("Global Dimension 1 Code", DimPerspectiveLine."Dimension 1 Totaling");
        GLEntry.SetFilter("Global Dimension 2 Code", DimPerspectiveLine."Dimension 2 Totaling");
        GLEntry.SetFilter("Shortcut Dimension 3 Code", DimPerspectiveLine."Dimension 3 Totaling");
        GLEntry.SetFilter("Shortcut Dimension 4 Code", DimPerspectiveLine."Dimension 4 Totaling");
        GLEntry.SetFilter("Shortcut Dimension 5 Code", DimPerspectiveLine."Dimension 5 Totaling");
        GLEntry.SetFilter("Shortcut Dimension 6 Code", DimPerspectiveLine."Dimension 6 Totaling");
        GLEntry.SetFilter("Shortcut Dimension 7 Code", DimPerspectiveLine."Dimension 7 Totaling");
        GLEntry.SetFilter("Shortcut Dimension 8 Code", DimPerspectiveLine."Dimension 8 Totaling");
    end;

    procedure FilterGLBudgetEntryByDimension(DimPerspectiveLine: Record "Dimension Perspective Line"; var GLBudgetEntry: Record "G/L Budget Entry")
    begin
        GLBudgetEntry.SetFilter("Global Dimension 1 Code", DimPerspectiveLine."Dimension 1 Totaling");
        GLBudgetEntry.SetFilter("Global Dimension 2 Code", DimPerspectiveLine."Dimension 2 Totaling");
    end;

    procedure FilterCFEntryByDimension(DimPerspectiveLine: Record "Dimension Perspective Line"; var CFForecastEntry: Record "Cash Flow Forecast Entry")
    begin
        CFForecastEntry.SetFilter("Global Dimension 1 Code", DimPerspectiveLine."Dimension 1 Totaling");
        CFForecastEntry.SetFilter("Global Dimension 2 Code", DimPerspectiveLine."Dimension 2 Totaling");
    end;

    procedure FilterAnalysisViewEntryByDimension(DimPerspectiveLine: Record "Dimension Perspective Line"; var AnalysisViewEntry: Record "Analysis View Entry")
    begin
        AnalysisViewEntry.SetFilter("Dimension 1 Value Code", DimPerspectiveLine."Dimension 1 Totaling");
        AnalysisViewEntry.SetFilter("Dimension 2 Value Code", DimPerspectiveLine."Dimension 2 Totaling");
        AnalysisViewEntry.SetFilter("Dimension 3 Value Code", DimPerspectiveLine."Dimension 3 Totaling");
        AnalysisViewEntry.SetFilter("Dimension 4 Value Code", DimPerspectiveLine."Dimension 4 Totaling");
    end;

    procedure FilterAnalysisViewBudgetEntryByDimension(DimPerspectiveLine: Record "Dimension Perspective Line"; var AnalysisViewBudgetEntry: Record "Analysis View Budget Entry")
    begin
        AnalysisViewBudgetEntry.SetFilter("Dimension 1 Value Code", DimPerspectiveLine."Dimension 1 Totaling");
        AnalysisViewBudgetEntry.SetFilter("Dimension 2 Value Code", DimPerspectiveLine."Dimension 2 Totaling");
        AnalysisViewBudgetEntry.SetFilter("Dimension 3 Value Code", DimPerspectiveLine."Dimension 3 Totaling");
        AnalysisViewBudgetEntry.SetFilter("Dimension 4 Value Code", DimPerspectiveLine."Dimension 4 Totaling");
    end;

    procedure FilterGLEntryByBusinessUnit(DimPerspectiveLine: Record "Dimension Perspective Line"; var GLEntry: Record "G/L Entry")
    begin
        GLEntry.SetFilter("Business Unit Code", DimPerspectiveLine."Business Unit Totaling");
    end;

    procedure FilterGLBudgetEntryByBusinessUnit(DimPerspectiveLine: Record "Dimension Perspective Line"; var GLBudgetEntry: Record "G/L Budget Entry")
    begin
        GLBudgetEntry.SetFilter("Business Unit Code", DimPerspectiveLine."Business Unit Totaling");
    end;

    procedure FilterAnalysisViewEntryByBusinessUnit(DimPerspectiveLine: Record "Dimension Perspective Line"; var AnalysisViewEntry: Record "Analysis View Entry")
    begin
        AnalysisViewEntry.SetFilter("Business Unit Code", DimPerspectiveLine."Business Unit Totaling");
    end;

    procedure FilterAnalysisViewBudgetEntryByBusinessUnit(DimPerspectiveLine: Record "Dimension Perspective Line"; var AnalysisViewBudgetEntry: Record "Analysis View Budget Entry")
    begin
        AnalysisViewBudgetEntry.SetFilter("Business Unit Code", DimPerspectiveLine."Business Unit Totaling");
    end;
}