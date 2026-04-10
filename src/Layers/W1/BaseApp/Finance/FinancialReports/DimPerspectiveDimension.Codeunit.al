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
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 8367 DimPerspectiveDimension implements IDimensionPerspective
{
    var
        DimPerspectiveMgt: Codeunit DimensionPerspectiveMgt;

    procedure PopulateLineBufferForReporting(DimPerspectiveName: Record "Dimension Perspective Name"; var TempDimPerspectiveLine: Record "Dimension Perspective Line")
    var
        AnalysisView: Record "Analysis View";
        DimValue: Record "Dimension Value";
        TempDimValue: Record "Dimension Value" temporary;
        GLSetup: Record "General Ledger Setup";
    begin
        if not TempDimPerspectiveLine.IsTemporary() then
            exit;

        if DimPerspectiveName."Analysis View Name" <> '' then begin
            AnalysisView.Get(DimPerspectiveName."Analysis View Name");
            case DimPerspectiveName."Perspective Type" of
                "Dimension Perspective Type"::Dimension1:
                    DimValue.SetRange("Dimension Code", AnalysisView."Dimension 1 Code");
                "Dimension Perspective Type"::Dimension2:
                    DimValue.SetRange("Dimension Code", AnalysisView."Dimension 2 Code");
                "Dimension Perspective Type"::Dimension3:
                    DimValue.SetRange("Dimension Code", AnalysisView."Dimension 3 Code");
                "Dimension Perspective Type"::Dimension4:
                    DimValue.SetRange("Dimension Code", AnalysisView."Dimension 4 Code");
                else
                    exit;
            end;
        end else begin
            GLSetup.Get();
            case DimPerspectiveName."Perspective Type" of
                "Dimension Perspective Type"::Dimension1:
                    DimValue.SetRange("Dimension Code", GLSetup."Global Dimension 1 Code");
                "Dimension Perspective Type"::Dimension2:
                    DimValue.SetRange("Dimension Code", GLSetup."Global Dimension 2 Code");
                "Dimension Perspective Type"::Dimension3:
                    DimValue.SetRange("Dimension Code", GLSetup."Shortcut Dimension 3 Code");
                "Dimension Perspective Type"::Dimension4:
                    DimValue.SetRange("Dimension Code", GLSetup."Shortcut Dimension 4 Code");
                "Dimension Perspective Type"::Dimension5:
                    DimValue.SetRange("Dimension Code", GLSetup."Shortcut Dimension 5 Code");
                "Dimension Perspective Type"::Dimension6:
                    DimValue.SetRange("Dimension Code", GLSetup."Shortcut Dimension 6 Code");
                "Dimension Perspective Type"::Dimension7:
                    DimValue.SetRange("Dimension Code", GLSetup."Shortcut Dimension 7 Code");
                "Dimension Perspective Type"::Dimension8:
                    DimValue.SetRange("Dimension Code", GLSetup."Shortcut Dimension 8 Code");
                else
                    exit;
            end;
        end;

        if DimValue.FindSet() then
            repeat
                TempDimPerspectiveLine.Init();
                TempDimPerspectiveLine.Name := DimPerspectiveName.Name;
                TempDimPerspectiveLine."Line No." += 10000;
                TempDimPerspectiveLine."Perspective Header" := CopyStr(DimValue.Name, 1, MaxStrLen(TempDimPerspectiveLine."Perspective Header"));
                TempDimValue := DimValue;
                TempDimValue.SetRecFilter();
                case DimPerspectiveName."Perspective Type" of
                    "Dimension Perspective Type"::Dimension1:
                        SetDimTotalingFilter(TempDimPerspectiveLine."Dimension 1 Totaling", TempDimValue.GetFilter(Code));
                    "Dimension Perspective Type"::Dimension2:
                        SetDimTotalingFilter(TempDimPerspectiveLine."Dimension 2 Totaling", TempDimValue.GetFilter(Code));
                    "Dimension Perspective Type"::Dimension3:
                        SetDimTotalingFilter(TempDimPerspectiveLine."Dimension 3 Totaling", TempDimValue.GetFilter(Code));
                    "Dimension Perspective Type"::Dimension4:
                        SetDimTotalingFilter(TempDimPerspectiveLine."Dimension 4 Totaling", TempDimValue.GetFilter(Code));
                    "Dimension Perspective Type"::Dimension5:
                        SetDimTotalingFilter(TempDimPerspectiveLine."Dimension 5 Totaling", TempDimValue.GetFilter(Code));
                    "Dimension Perspective Type"::Dimension6:
                        SetDimTotalingFilter(TempDimPerspectiveLine."Dimension 6 Totaling", TempDimValue.GetFilter(Code));
                    "Dimension Perspective Type"::Dimension7:
                        SetDimTotalingFilter(TempDimPerspectiveLine."Dimension 7 Totaling", TempDimValue.GetFilter(Code));
                    "Dimension Perspective Type"::Dimension8:
                        SetDimTotalingFilter(TempDimPerspectiveLine."Dimension 8 Totaling", TempDimValue.GetFilter(Code));
                end;
                TempDimPerspectiveLine.Insert();
            until DimValue.Next() = 0;
    end;

    local procedure SetDimTotalingFilter(var DimTotaling: Text[80]; FilterText: Text)
    begin
        DimTotaling := CopyStr(FilterText, 1, MaxStrLen(DimTotaling));
    end;

    procedure FilterGLEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var GLEntry: Record "G/L Entry")
    begin
        DimPerspectiveMgt.FilterGLEntryByDimension(DimPerspectiveLine, GLEntry);
    end;

    procedure FilterGLBudgetEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var GLBudgetEntry: Record "G/L Budget Entry")
    begin
        DimPerspectiveMgt.FilterGLBudgetEntryByDimension(DimPerspectiveLine, GLBudgetEntry);
    end;

    procedure FilterCFEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var CFForecastEntry: Record "Cash Flow Forecast Entry")
    begin
        DimPerspectiveMgt.FilterCFEntryByDimension(DimPerspectiveLine, CFForecastEntry);
    end;

    procedure FilterAnalysisViewEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var AnalysisViewEntry: Record "Analysis View Entry")
    begin
        DimPerspectiveMgt.FilterAnalysisViewEntryByDimension(DimPerspectiveLine, AnalysisViewEntry);
    end;

    procedure FilterAnalysisViewBudgetEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var AnalysisViewBudgetEntry: Record "Analysis View Budget Entry")
    begin
        DimPerspectiveMgt.FilterAnalysisViewBudgetEntryByDimension(DimPerspectiveLine, AnalysisViewBudgetEntry);
    end;

    procedure PerspectiveTypeToText(DimPerspectiveName: Record "Dimension Perspective Name"; Type: Enum "Dimension Perspective Type"; var Text: Text): Boolean
    var
        AnalysisView: Record "Analysis View";
        GLSetup: Record "General Ledger Setup";
    begin
        if DimPerspectiveName."Analysis View Name" = '' then begin
            GLSetup.Get();
            case Type of
                Type::Dimension1:
                    Text := GLSetup."Global Dimension 1 Code";
                Type::Dimension2:
                    Text := GLSetup."Global Dimension 2 Code";
                Type::Dimension3:
                    Text := GLSetup."Shortcut Dimension 3 Code";
                Type::Dimension4:
                    Text := GLSetup."Shortcut Dimension 4 Code";
                Type::Dimension5:
                    Text := GLSetup."Shortcut Dimension 5 Code";
                Type::Dimension6:
                    Text := GLSetup."Shortcut Dimension 6 Code";
                Type::Dimension7:
                    Text := GLSetup."Shortcut Dimension 7 Code";
                Type::Dimension8:
                    Text := GLSetup."Shortcut Dimension 8 Code";
                else
                    exit(false);
            end;
        end else begin
            AnalysisView.Get(DimPerspectiveName."Analysis View Name");
            case Type of
                Type::Dimension1:
                    Text := AnalysisView."Dimension 1 Code";
                Type::Dimension2:
                    Text := AnalysisView."Dimension 2 Code";
                Type::Dimension3:
                    Text := AnalysisView."Dimension 3 Code";
                Type::Dimension4:
                    Text := AnalysisView."Dimension 4 Code";
                else
                    exit(false);
            end;
        end;

        exit(true);
    end;

    procedure TextToPerspectiveType(DimPerspectiveName: Record "Dimension Perspective Name"; Text: Text; var Type: Enum "Dimension Perspective Type"): Boolean
    var
        AnalysisView: Record "Analysis View";
        GLSetup: Record "General Ledger Setup";
    begin
        if DimPerspectiveName."Analysis View Name" = '' then begin
            GLSetup.Get();
            case Text of
                GLSetup."Global Dimension 1 Code":
                    Type := Type::Dimension1;
                GLSetup."Global Dimension 2 Code":
                    Type := Type::Dimension2;
                GLSetup."Shortcut Dimension 3 Code":
                    Type := Type::Dimension3;
                GLSetup."Shortcut Dimension 4 Code":
                    Type := Type::Dimension4;
                GLSetup."Shortcut Dimension 5 Code":
                    Type := Type::Dimension5;
                GLSetup."Shortcut Dimension 6 Code":
                    Type := Type::Dimension6;
                GLSetup."Shortcut Dimension 7 Code":
                    Type := Type::Dimension7;
                GLSetup."Shortcut Dimension 8 Code":
                    Type := Type::Dimension8;
                else
                    exit(false);
            end;
        end else begin
            AnalysisView.Get(DimPerspectiveName."Analysis View Name");
            case Text of
                AnalysisView."Dimension 1 Code":
                    Type := Type::Dimension1;
                AnalysisView."Dimension 2 Code":
                    Type := Type::Dimension2;
                AnalysisView."Dimension 3 Code":
                    Type := Type::Dimension3;
                AnalysisView."Dimension 4 Code":
                    Type := Type::Dimension4;
                else
                    exit(false);
            end;
        end;

        exit(true);
    end;

    procedure InsertBufferForPerspectiveTotalingLookup(DimPerspectiveName: Record "Dimension Perspective Name"; Type: Enum "Dimension Perspective Type"; var DimSelection: Page "Dimension Selection")
    var
        AnalysisView: Record "Analysis View";
        GLSetup: Record "General Ledger Setup";
    begin
        if DimPerspectiveName."Analysis View Name" = '' then begin
            GLSetup.Get();
            case Type of
                "Dimension Perspective Type"::Dimension1:
                    if GLSetup."Global Dimension 1 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLSetup."Global Dimension 1 Code", '');
                "Dimension Perspective Type"::Dimension2:
                    if GLSetup."Global Dimension 2 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLSetup."Global Dimension 2 Code", '');
                "Dimension Perspective Type"::Dimension3:
                    if GLSetup."Shortcut Dimension 3 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLSetup."Shortcut Dimension 3 Code", '');
                "Dimension Perspective Type"::Dimension4:
                    if GLSetup."Shortcut Dimension 4 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLSetup."Shortcut Dimension 4 Code", '');
                "Dimension Perspective Type"::Dimension5:
                    if GLSetup."Shortcut Dimension 5 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLSetup."Shortcut Dimension 5 Code", '');
                "Dimension Perspective Type"::Dimension6:
                    if GLSetup."Shortcut Dimension 6 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLSetup."Shortcut Dimension 6 Code", '');
                "Dimension Perspective Type"::Dimension7:
                    if GLSetup."Shortcut Dimension 7 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLSetup."Shortcut Dimension 7 Code", '');
                "Dimension Perspective Type"::Dimension8:
                    if GLSetup."Shortcut Dimension 8 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLSetup."Shortcut Dimension 8 Code", '');
            end;
        end else begin
            AnalysisView.Get(DimPerspectiveName."Analysis View Name");
            case Type of
                "Dimension Perspective Type"::Dimension1:
                    if AnalysisView."Dimension 1 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 1 Code", '');
                "Dimension Perspective Type"::Dimension2:
                    if AnalysisView."Dimension 2 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 2 Code", '');
                "Dimension Perspective Type"::Dimension3:
                    if AnalysisView."Dimension 3 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 3 Code", '');
                "Dimension Perspective Type"::Dimension4:
                    if AnalysisView."Dimension 4 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 4 Code", '');
            end;
        end;
    end;
}