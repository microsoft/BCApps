// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Account;
using System.Visualization;

codeunit 436 "Acc. Sched. BarChart DrillDown"
{
    TableNo = "Bar Chart Buffer";

    trigger OnRun()
    begin
        AccSchedLine."Schedule Name" := DelChr(CopyStr(Rec.Tag, 1, 10), '>');
        case Rec."Series No." of
            1:
                Evaluate(AccSchedLine."Line No.", DelChr(CopyStr(Rec.Tag, 11, 8), '>'));
            2:
                Evaluate(AccSchedLine."Line No.", DelChr(CopyStr(Rec.Tag, 19, 8), '>'));
            3:
                Evaluate(AccSchedLine."Line No.", DelChr(CopyStr(Rec.Tag, 27, 8), '>'));
        end;
        AccSchedLine.Find();
        ColumnLayout."Column Layout Name" := DelChr(CopyStr(Rec.Tag, 35, 10), '>');
        Evaluate(ColumnLayout."Line No.", DelChr(CopyStr(Rec.Tag, 45, 8), '>'));
        ColumnLayout.Find();
        s := DelChr(CopyStr(Rec.Tag, 53, 20), '>');
        if s <> '' then
            AccSchedLine.SetFilter("Date Filter", s);
        s := DelChr(CopyStr(Rec.Tag, 73, 10), '>');
        if s <> '' then
            AccSchedLine.SetFilter("G/L Budget Filter", s);
        s := DelChr(CopyStr(Rec.Tag, 83, 42), '>');
        if s <> '' then
            AccSchedLine.SetFilter("Dimension 1 Filter", s);
        s := DelChr(CopyStr(Rec.Tag, 125, 42), '>');
        if s <> '' then
            AccSchedLine.SetFilter("Dimension 2 Filter", s);
        s := DelChr(CopyStr(Rec.Tag, 167, 42), '>');
        if s <> '' then
            AccSchedLine.SetFilter("Dimension 3 Filter", s);
        s := DelChr(CopyStr(Rec.Tag, 209, 42), '>');
        if s <> '' then
            AccSchedLine.SetFilter("Dimension 4 Filter", s);

        AccSchedManagement.CheckAnalysisView(AccSchedLine."Schedule Name", ColumnLayout."Column Layout Name", true);
        if AccSchedManagement.CalcCell(AccSchedLine, ColumnLayout, false) = 0 then; // init codeunit

        if ColumnLayout."Column Type" = ColumnLayout."Column Type"::Formula then
            Message(Text002, ColumnLayout.Formula)
        else
            if AccSchedLine."Totaling Type" in [AccSchedLine."Totaling Type"::Formula, AccSchedLine."Totaling Type"::"Set Base For Percent"] then
                Message(Text003, AccSchedLine.Totaling)
            else
                if AccSchedLine.Totaling <> '' then begin
                    AccSchedLine.CopyFilter("Business Unit Filter", GLAcc."Business Unit Filter");
                    AccSchedLine.CopyFilter("G/L Budget Filter", GLAcc."Budget Filter");
                    AccSchedManagement.SetGLAccRowFilters(GLAcc, AccSchedLine);
                    OnAfterAccSchedManagementSetGLAccRowFilters(GLAcc, AccSchedLine, ColumnLayout);
                    AccSchedManagement.SetGLAccColumnFilters(GLAcc, AccSchedLine, ColumnLayout);
                    OnAfterAccSchedManagementSetGLAccColumnFilters(GLAcc, AccSchedLine, ColumnLayout);
                    AccSchedName.Get(AccSchedLine."Schedule Name");
                    if AccSchedName."Analysis View Name" = '' then begin
                        AccSchedLine.CopyFilter("Dimension 1 Filter", GLAcc."Global Dimension 1 Filter");
                        AccSchedLine.CopyFilter("Dimension 2 Filter", GLAcc."Global Dimension 2 Filter");
                        AccSchedLine.CopyFilter("Business Unit Filter", GLAcc."Business Unit Filter");
                        GLAcc.FilterGroup(2);
                        GLAcc.SetFilter("Global Dimension 1 Filter", AccSchedManagement.GetDimTotalingFilter(1, AccSchedLine."Dimension 1 Totaling"));
                        GLAcc.SetFilter("Global Dimension 2 Filter", AccSchedManagement.GetDimTotalingFilter(2, AccSchedLine."Dimension 2 Totaling"));
                        GLAcc.FilterGroup(8);
                        GLAcc.SetFilter(
                          "Global Dimension 1 Filter", AccSchedManagement.GetDimTotalingFilter(1, ColumnLayout."Dimension 1 Totaling"));
                        GLAcc.SetFilter(
                          "Global Dimension 2 Filter", AccSchedManagement.GetDimTotalingFilter(2, ColumnLayout."Dimension 2 Totaling"));
                        GLAcc.SetFilter("Business Unit Filter", ColumnLayout."Business Unit Totaling");
                        GLAcc.FilterGroup(0);
                        PAGE.Run(PAGE::"Chart of Accounts (G/L)", GLAcc)
                    end else begin
                        GLAcc.CopyFilter("Date Filter", GLAccAnalysisView."Date Filter");
                        GLAcc.CopyFilter("Budget Filter", GLAccAnalysisView."Budget Filter");
                        GLAcc.CopyFilter("Business Unit Filter", GLAccAnalysisView."Business Unit Filter");
                        GLAccAnalysisView.SetRange("Analysis View Filter", AccSchedName."Analysis View Name");
                        AccSchedLine.CopyFilter("Dimension 1 Filter", GLAccAnalysisView."Dimension 1 Filter");
                        AccSchedLine.CopyFilter("Dimension 2 Filter", GLAccAnalysisView."Dimension 2 Filter");
                        AccSchedLine.CopyFilter("Dimension 3 Filter", GLAccAnalysisView."Dimension 3 Filter");
                        AccSchedLine.CopyFilter("Dimension 4 Filter", GLAccAnalysisView."Dimension 4 Filter");
                        GLAccAnalysisView.FilterGroup(2);
                        GLAccAnalysisView.SetFilter("Dimension 1 Filter", AccSchedManagement.GetDimTotalingFilter(1, AccSchedLine."Dimension 1 Totaling"));
                        GLAccAnalysisView.SetFilter("Dimension 2 Filter", AccSchedManagement.GetDimTotalingFilter(2, AccSchedLine."Dimension 2 Totaling"));
                        GLAccAnalysisView.SetFilter("Dimension 3 Filter", AccSchedManagement.GetDimTotalingFilter(3, AccSchedLine."Dimension 3 Totaling"));
                        GLAccAnalysisView.SetFilter("Dimension 4 Filter", AccSchedManagement.GetDimTotalingFilter(4, AccSchedLine."Dimension 4 Totaling"));
                        GLAccAnalysisView.FilterGroup(8);
                        GLAccAnalysisView.SetFilter(
                          "Dimension 1 Filter",
                          AccSchedManagement.GetDimTotalingFilter(1, ColumnLayout."Dimension 1 Totaling"));
                        GLAccAnalysisView.SetFilter(
                          "Dimension 2 Filter",
                          AccSchedManagement.GetDimTotalingFilter(2, ColumnLayout."Dimension 2 Totaling"));
                        GLAccAnalysisView.SetFilter(
                          "Dimension 3 Filter",
                          AccSchedManagement.GetDimTotalingFilter(3, ColumnLayout."Dimension 3 Totaling"));
                        GLAccAnalysisView.SetFilter(
                          "Dimension 4 Filter",
                          AccSchedManagement.GetDimTotalingFilter(4, ColumnLayout."Dimension 4 Totaling"));
                        GLAccAnalysisView.SetFilter("Business Unit Filter", ColumnLayout."Business Unit Totaling");
                        GLAccAnalysisView.FilterGroup(0);
                        Clear(ChartofAccAnalysisView);
                        ChartofAccAnalysisView.InsertTempGLAccAnalysisViews(GLAcc);
                        ChartofAccAnalysisView.SetTableView(GLAccAnalysisView);
                        ChartofAccAnalysisView.Run();
                    end;
                end;
    end;

    var
        AccSchedLine: Record "Acc. Schedule Line";
        GLAcc: Record "G/L Account";
        GLAccAnalysisView: Record "G/L Account (Analysis View)";
        ColumnLayout: Record "Column Layout";
        AccSchedName: Record "Acc. Schedule Name";
        AccSchedManagement: Codeunit AccSchedManagement;
        ChartofAccAnalysisView: Page "Chart of Accs. (Analysis View)";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'Column formula: %1';
        Text003: Label 'Row formula: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        s: Text[50];

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccSchedManagementSetGLAccRowFilters(var GLAcc: Record "G/L Account"; var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccSchedManagementSetGLAccColumnFilters(var GLAcc: Record "G/L Account"; var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    begin
    end;
}

