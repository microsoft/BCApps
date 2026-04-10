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

codeunit 8365 DimPerspectiveCustom implements IDimensionPerspective
{
    var
        DimPerspectiveMgt: Codeunit DimensionPerspectiveMgt;
        CustomTypeDescTxt: Label 'Custom totaling', MaxLength = 30;
        DeleteLinesQst: Label 'Changing away from perspective type custom will delete all lines for this dimension perspective. \Do you want to continue?';

    procedure PopulateLineBufferForReporting(DimPerspectiveName: Record "Dimension Perspective Name"; var TempDimPerspectiveLine: Record "Dimension Perspective Line")
    var
        DimPerspectiveLine: Record "Dimension Perspective Line";
    begin
        if not TempDimPerspectiveLine.IsTemporary() then
            exit;
        DimPerspectiveLine.SetRange(Name, DimPerspectiveName.Name);
        if DimPerspectiveLine.FindSet() then
            repeat
                TempDimPerspectiveLine := DimPerspectiveLine;
                TempDimPerspectiveLine.Insert();
            until DimPerspectiveLine.Next() = 0;
    end;

    procedure FilterGLEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var GLEntry: Record "G/L Entry")
    begin
        DimPerspectiveMgt.FilterGLEntryByDimension(DimPerspectiveLine, GLEntry);
        DimPerspectiveMgt.FilterGLEntryByBusinessUnit(DimPerspectiveLine, GLEntry);
    end;

    procedure FilterGLBudgetEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var GLBudgetEntry: Record "G/L Budget Entry")
    begin
        DimPerspectiveMgt.FilterGLBudgetEntryByDimension(DimPerspectiveLine, GLBudgetEntry);
        DimPerspectiveMgt.FilterGLBudgetEntryByBusinessUnit(DimPerspectiveLine, GLBudgetEntry);
    end;

    procedure FilterCFEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var CFForecastEntry: Record "Cash Flow Forecast Entry")
    begin
        DimPerspectiveMgt.FilterCFEntryByDimension(DimPerspectiveLine, CFForecastEntry);
    end;

    procedure FilterAnalysisViewEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var AnalysisViewEntry: Record "Analysis View Entry")
    begin
        DimPerspectiveMgt.FilterAnalysisViewEntryByDimension(DimPerspectiveLine, AnalysisViewEntry);
        DimPerspectiveMgt.FilterAnalysisViewEntryByBusinessUnit(DimPerspectiveLine, AnalysisViewEntry);
    end;

    procedure FilterAnalysisViewBudgetEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var AnalysisViewBudgetEntry: Record "Analysis View Budget Entry")
    begin
        DimPerspectiveMgt.FilterAnalysisViewBudgetEntryByDimension(DimPerspectiveLine, AnalysisViewBudgetEntry);
        DimPerspectiveMgt.FilterAnalysisViewBudgetEntryByBusinessUnit(DimPerspectiveLine, AnalysisViewBudgetEntry);
    end;

    procedure PerspectiveTypeToText(DimPerspectiveName: Record "Dimension Perspective Name"; Type: Enum "Dimension Perspective Type"; var Text: Text): Boolean
    begin
        if Type = Type::Custom then begin
            Text := Format(Enum::"Dimension Perspective Type"::Custom);
            exit(true);
        end;
    end;

    procedure TextToPerspectiveType(DimPerspectiveName: Record "Dimension Perspective Name"; Text: Text; var Type: Enum "Dimension Perspective Type"): Boolean
    begin
        if Text = UpperCase(Format(Enum::"Dimension Perspective Type"::Custom)) then begin
            Type := Type::Custom;
            exit(true);
        end;
    end;

    procedure InsertBufferForPerspectiveTotalingLookup(DimPerspectiveName: Record "Dimension Perspective Name"; Type: Enum "Dimension Perspective Type"; var DimSelection: Page "Dimension Selection")
    begin
        DimSelection.InsertDimSelBuf(false, Format(Enum::"Dimension Perspective Type"::Custom), CustomTypeDescTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Dimension Perspective Name", OnAfterValidateEvent, "Perspective Type", false, false)]
    local procedure AfterValidatePerspectiveType(var Rec: Record "Dimension Perspective Name"; var xRec: Record "Dimension Perspective Name")
    var
        DimPerspectiveLine: Record "Dimension Perspective Line";
        ConfirmMgt: Codeunit "Confirm Management";
    begin
        if (xRec."Perspective Type" <> xRec."Perspective Type"::Custom) or (xRec."Perspective Type" = Rec."Perspective Type") then
            exit;

        DimPerspectiveLine.SetRange(Name, Rec.Name);
        if DimPerspectiveLine.IsEmpty() then
            exit;

        if not ConfirmMgt.GetResponseOrDefault(DeleteLinesQst, true) then
            Error('');

        DimPerspectiveLine.DeleteAll(true);
    end;
}