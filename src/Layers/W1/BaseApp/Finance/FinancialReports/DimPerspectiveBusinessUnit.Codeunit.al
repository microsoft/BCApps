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

codeunit 8364 DimPerspectiveBusinessUnit implements IDimensionPerspective
{
    var
        DimPerspectiveMgt: Codeunit DimensionPerspectiveMgt;

    procedure PopulateLineBufferForReporting(DimPerspectiveName: Record "Dimension Perspective Name"; var TempDimPerspectiveLine: Record "Dimension Perspective Line")
    var
        BusUnit: Record "Business Unit";
        TempBusUnit: Record "Business Unit" temporary;
    begin
        if not TempDimPerspectiveLine.IsTemporary() then
            exit;
        if BusUnit.FindSet() then
            repeat
                TempDimPerspectiveLine.Init();
                TempDimPerspectiveLine.Name := DimPerspectiveName.Name;
                TempDimPerspectiveLine."Line No." += 10000;
                TempDimPerspectiveLine."Perspective Header" := CopyStr(BusUnit.Name, 1, MaxStrLen(TempDimPerspectiveLine."Perspective Header"));
                TempBusUnit := BusUnit;
                TempBusUnit.SetRecFilter();
                TempDimPerspectiveLine."Business Unit Totaling" := CopyStr(TempBusUnit.GetFilter(Code), 1, MaxStrLen(TempDimPerspectiveLine."Business Unit Totaling"));
                TempDimPerspectiveLine.Insert();
            until BusUnit.Next() = 0;
    end;

    procedure FilterGLEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var GLEntry: Record "G/L Entry")
    begin
        DimPerspectiveMgt.FilterGLEntryByBusinessUnit(DimPerspectiveLine, GLEntry);
    end;

    procedure FilterGLBudgetEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var GLBudgetEntry: Record "G/L Budget Entry")
    begin
        DimPerspectiveMgt.FilterGLBudgetEntryByBusinessUnit(DimPerspectiveLine, GLBudgetEntry);
    end;

    procedure FilterCFEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var CFForecastEntry: Record "Cash Flow Forecast Entry")
    begin
    end;

    procedure FilterAnalysisViewEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var AnalysisViewEntry: Record "Analysis View Entry")
    begin
        DimPerspectiveMgt.FilterAnalysisViewEntryByBusinessUnit(DimPerspectiveLine, AnalysisViewEntry);
    end;

    procedure FilterAnalysisViewBudgetEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var AnalysisViewBudgetEntry: Record "Analysis View Budget Entry")
    begin
        DimPerspectiveMgt.FilterAnalysisViewBudgetEntryByBusinessUnit(DimPerspectiveLine, AnalysisViewBudgetEntry);
    end;

    procedure PerspectiveTypeToText(DimPerspectiveName: Record "Dimension Perspective Name"; Type: Enum "Dimension Perspective Type"; var Text: Text): Boolean
    begin
        if (DimPerspectiveName."Analysis View Name" = '') and (Type = Type::BusinessUnit) then begin
            Text := Format(Enum::"Dimension Perspective Type"::BusinessUnit);
            exit(true);
        end;
    end;

    procedure TextToPerspectiveType(DimPerspectiveName: Record "Dimension Perspective Name"; Text: Text; var Type: Enum "Dimension Perspective Type"): Boolean
    begin
        if (DimPerspectiveName."Analysis View Name" = '') and (Text = UpperCase(Format(Enum::"Dimension Perspective Type"::BusinessUnit))) then begin
            Type := Type::BusinessUnit;
            exit(true);
        end;
    end;

    procedure InsertBufferForPerspectiveTotalingLookup(DimPerspectiveName: Record "Dimension Perspective Name"; Type: Enum "Dimension Perspective Type"; var DimSelection: Page "Dimension Selection")
    begin
        if DimPerspectiveName."Analysis View Name" <> '' then
            exit;
        DimSelection.InsertDimSelBuf(false, Format(Enum::"Dimension Perspective Type"::BusinessUnit), Format(Enum::"Dimension Perspective Type"::BusinessUnit));
    end;
}