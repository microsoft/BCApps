// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using System.Visualization;

codeunit 7112 "Analysis BarChart DrillDown"
{
    TableNo = "Bar Chart Buffer";

    trigger OnRun()
    begin
        Evaluate(AnalysisLine."Analysis Area", DelChr(CopyStr(Rec.Tag, 1, 1), '>'));
        AnalysisLine."Analysis Line Template Name" := DelChr(CopyStr(Rec.Tag, 2, 10), '>');
        case Rec."Series No." of
            1:
                Evaluate(AnalysisLine."Line No.", DelChr(CopyStr(Rec.Tag, 12, 8), '>'));
            2:
                Evaluate(AnalysisLine."Line No.", DelChr(CopyStr(Rec.Tag, 20, 8), '>'));
            3:
                Evaluate(AnalysisLine."Line No.", DelChr(CopyStr(Rec.Tag, 28, 8), '>'));
        end;
        AnalysisLine.Find();
        AnalysisColumn."Analysis Area" := AnalysisLine."Analysis Area";
        AnalysisColumn."Analysis Column Template" := DelChr(CopyStr(Rec.Tag, 36, 10), '>');
        Evaluate(AnalysisColumn."Line No.", DelChr(CopyStr(Rec.Tag, 46, 8), '>'));
        AnalysisColumn.Find();
        s := DelChr(CopyStr(Rec.Tag, 54, 1), '>');
        Evaluate(CurrSourceTypeFilter, s);
        if CurrSourceTypeFilter <> 0 then
            AnalysisLine.SetRange("Source Type Filter", CurrSourceTypeFilter);
        s := DelChr(CopyStr(Rec.Tag, 55, 20), '>');
        if s <> '' then
            AnalysisLine.SetFilter("Source No. Filter", s);
        s := DelChr(CopyStr(Rec.Tag, 75, 10), '>');
        if s <> '' then
            AnalysisLine.SetFilter("Location Filter", s);
        s := DelChr(CopyStr(Rec.Tag, 85, 20), '>');
        if s <> '' then
            AnalysisLine.SetFilter("Date Filter", s);
        s := DelChr(CopyStr(Rec.Tag, 105, 10), '>');
        if s <> '' then
            AnalysisLine.SetFilter("Item Budget Filter", s);
        s := DelChr(CopyStr(Rec.Tag, 115, 42), '>');
        if s <> '' then
            AnalysisLine.SetFilter("Dimension 1 Filter", s);
        s := DelChr(CopyStr(Rec.Tag, 157, 42), '>');
        if s <> '' then
            AnalysisLine.SetFilter("Dimension 2 Filter", s);
        s := DelChr(CopyStr(Rec.Tag, 199, 42), '>');
        if s <> '' then
            AnalysisLine.SetFilter("Dimension 3 Filter", s);

        if AnalysisReportManagement.CalcCell(AnalysisLine, AnalysisColumn, true) = 0 then; // return value not used
    end;

    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        AnalysisReportManagement: Codeunit "Analysis Report Management";
        s: Text[50];
        CurrSourceTypeFilter: Integer;
}

