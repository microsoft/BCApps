// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 8366 SheetDefMgt
{
    procedure FilterGLEntryByDimension(SheetDefLine: Record "Sheet Definition Line"; var GLEntry: Record "G/L Entry")
    begin
        GLEntry.SetFilter("Global Dimension 1 Code", SheetDefLine."Dimension 1 Totaling");
        GLEntry.SetFilter("Global Dimension 2 Code", SheetDefLine."Dimension 2 Totaling");
        GLEntry.SetFilter("Shortcut Dimension 3 Code", SheetDefLine."Dimension 3 Totaling");
        GLEntry.SetFilter("Shortcut Dimension 4 Code", SheetDefLine."Dimension 4 Totaling");
        GLEntry.SetFilter("Shortcut Dimension 5 Code", SheetDefLine."Dimension 5 Totaling");
        GLEntry.SetFilter("Shortcut Dimension 6 Code", SheetDefLine."Dimension 6 Totaling");
        GLEntry.SetFilter("Shortcut Dimension 7 Code", SheetDefLine."Dimension 7 Totaling");
        GLEntry.SetFilter("Shortcut Dimension 8 Code", SheetDefLine."Dimension 8 Totaling");
    end;

    procedure FilterGLBudgetEntryByDimension(SheetDefLine: Record "Sheet Definition Line"; var GLBudgetEntry: Record "G/L Budget Entry")
    begin
        GLBudgetEntry.SetFilter("Global Dimension 1 Code", SheetDefLine."Dimension 1 Totaling");
        GLBudgetEntry.SetFilter("Global Dimension 2 Code", SheetDefLine."Dimension 2 Totaling");
    end;

    procedure FilterCFEntryByDimension(SheetDefLine: Record "Sheet Definition Line"; var CFForecastEntry: Record "Cash Flow Forecast Entry")
    begin
        CFForecastEntry.SetFilter("Global Dimension 1 Code", SheetDefLine."Dimension 1 Totaling");
        CFForecastEntry.SetFilter("Global Dimension 2 Code", SheetDefLine."Dimension 2 Totaling");
    end;

    procedure FilterAnalysisViewEntryByDimension(SheetDefLine: Record "Sheet Definition Line"; var AnalysisViewEntry: Record "Analysis View Entry")
    begin
        AnalysisViewEntry.SetFilter("Dimension 1 Value Code", SheetDefLine."Dimension 1 Totaling");
        AnalysisViewEntry.SetFilter("Dimension 2 Value Code", SheetDefLine."Dimension 2 Totaling");
        AnalysisViewEntry.SetFilter("Dimension 3 Value Code", SheetDefLine."Dimension 3 Totaling");
        AnalysisViewEntry.SetFilter("Dimension 4 Value Code", SheetDefLine."Dimension 4 Totaling");
    end;

    procedure FilterAnalysisViewBudgetEntryByDimension(SheetDefLine: Record "Sheet Definition Line"; var AnalysisViewBudgetEntry: Record "Analysis View Budget Entry")
    begin
        AnalysisViewBudgetEntry.SetFilter("Dimension 1 Value Code", SheetDefLine."Dimension 1 Totaling");
        AnalysisViewBudgetEntry.SetFilter("Dimension 2 Value Code", SheetDefLine."Dimension 2 Totaling");
        AnalysisViewBudgetEntry.SetFilter("Dimension 3 Value Code", SheetDefLine."Dimension 3 Totaling");
        AnalysisViewBudgetEntry.SetFilter("Dimension 4 Value Code", SheetDefLine."Dimension 4 Totaling");
    end;

    procedure FilterGLEntryByBusinessUnit(SheetDefLine: Record "Sheet Definition Line"; var GLEntry: Record "G/L Entry")
    begin
        GLEntry.SetFilter("Business Unit Code", SheetDefLine."Business Unit Totaling");
    end;

    procedure FilterGLBudgetEntryByBusinessUnit(SheetDefLine: Record "Sheet Definition Line"; var GLBudgetEntry: Record "G/L Budget Entry")
    begin
        GLBudgetEntry.SetFilter("Business Unit Code", SheetDefLine."Business Unit Totaling");
    end;

    procedure FilterAnalysisViewEntryByBusinessUnit(SheetDefLine: Record "Sheet Definition Line"; var AnalysisViewEntry: Record "Analysis View Entry")
    begin
        AnalysisViewEntry.SetFilter("Business Unit Code", SheetDefLine."Business Unit Totaling");
    end;

    procedure FilterAnalysisViewBudgetEntryByBusinessUnit(SheetDefLine: Record "Sheet Definition Line"; var AnalysisViewBudgetEntry: Record "Analysis View Budget Entry")
    begin
        AnalysisViewBudgetEntry.SetFilter("Business Unit Code", SheetDefLine."Business Unit Totaling");
    end;
}