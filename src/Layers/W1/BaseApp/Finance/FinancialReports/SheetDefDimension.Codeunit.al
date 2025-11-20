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

codeunit 8367 SheetDefDimension implements ISheetDefinition
{
    var
        SheetDefMgt: Codeunit SheetDefMgt;

    procedure PopulateLineBufferForReporting(SheetDefName: Record "Sheet Definition Name"; var TempSheetDefLine: Record "Sheet Definition Line")
    var
        AnalysisView: Record "Analysis View";
        DimValue: Record "Dimension Value";
        TempDimValue: Record "Dimension Value" temporary;
        GLSetup: Record "General Ledger Setup";
    begin
        if not TempSheetDefLine.IsTemporary() then
            exit;

        if SheetDefName."Analysis View Name" <> '' then begin
            AnalysisView.Get(SheetDefName."Analysis View Name");
            case SheetDefName."Sheet Type" of
                "Sheet Type"::Dimension1:
                    DimValue.SetRange("Dimension Code", AnalysisView."Dimension 1 Code");
                "Sheet Type"::Dimension2:
                    DimValue.SetRange("Dimension Code", AnalysisView."Dimension 2 Code");
                "Sheet Type"::Dimension3:
                    DimValue.SetRange("Dimension Code", AnalysisView."Dimension 3 Code");
                "Sheet Type"::Dimension4:
                    DimValue.SetRange("Dimension Code", AnalysisView."Dimension 4 Code");
                else
                    exit;
            end;
        end else begin
            GLSetup.Get();
            case SheetDefName."Sheet Type" of
                "Sheet Type"::Dimension1:
                    DimValue.SetRange("Dimension Code", GLSetup."Global Dimension 1 Code");
                "Sheet Type"::Dimension2:
                    DimValue.SetRange("Dimension Code", GLSetup."Global Dimension 2 Code");
                "Sheet Type"::Dimension3:
                    DimValue.SetRange("Dimension Code", GLSetup."Shortcut Dimension 3 Code");
                "Sheet Type"::Dimension4:
                    DimValue.SetRange("Dimension Code", GLSetup."Shortcut Dimension 4 Code");
                "Sheet Type"::Dimension5:
                    DimValue.SetRange("Dimension Code", GLSetup."Shortcut Dimension 5 Code");
                "Sheet Type"::Dimension6:
                    DimValue.SetRange("Dimension Code", GLSetup."Shortcut Dimension 6 Code");
                "Sheet Type"::Dimension7:
                    DimValue.SetRange("Dimension Code", GLSetup."Shortcut Dimension 7 Code");
                "Sheet Type"::Dimension8:
                    DimValue.SetRange("Dimension Code", GLSetup."Shortcut Dimension 8 Code");
                else
                    exit;
            end;
        end;

        if DimValue.FindSet() then
            repeat
                TempSheetDefLine.Init();
                TempSheetDefLine.Name := SheetDefName.Name;
                TempSheetDefLine."Line No." += 10000;
                TempSheetDefLine."Sheet Header" := CopyStr(DimValue.Name, 1, MaxStrLen(TempSheetDefLine."Sheet Header"));
                TempDimValue := DimValue;
                TempDimValue.SetRecFilter();
                case SheetDefName."Sheet Type" of
                    "Sheet Type"::Dimension1:
                        SetDimTotalingFilter(TempSheetDefLine."Dimension 1 Totaling", TempDimValue.GetFilter(Code));
                    "Sheet Type"::Dimension2:
                        SetDimTotalingFilter(TempSheetDefLine."Dimension 2 Totaling", TempDimValue.GetFilter(Code));
                    "Sheet Type"::Dimension3:
                        SetDimTotalingFilter(TempSheetDefLine."Dimension 3 Totaling", TempDimValue.GetFilter(Code));
                    "Sheet Type"::Dimension4:
                        SetDimTotalingFilter(TempSheetDefLine."Dimension 4 Totaling", TempDimValue.GetFilter(Code));
                    "Sheet Type"::Dimension5:
                        SetDimTotalingFilter(TempSheetDefLine."Dimension 5 Totaling", TempDimValue.GetFilter(Code));
                    "Sheet Type"::Dimension6:
                        SetDimTotalingFilter(TempSheetDefLine."Dimension 6 Totaling", TempDimValue.GetFilter(Code));
                    "Sheet Type"::Dimension7:
                        SetDimTotalingFilter(TempSheetDefLine."Dimension 7 Totaling", TempDimValue.GetFilter(Code));
                    "Sheet Type"::Dimension8:
                        SetDimTotalingFilter(TempSheetDefLine."Dimension 8 Totaling", TempDimValue.GetFilter(Code));
                end;
                TempSheetDefLine.Insert();
            until DimValue.Next() = 0;
    end;

    local procedure SetDimTotalingFilter(var DimTotaling: Text[80]; FilterText: Text)
    begin
        DimTotaling := CopyStr(FilterText, 1, MaxStrLen(DimTotaling));
    end;

    procedure FilterGLEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var GLEntry: Record "G/L Entry")
    begin
        SheetDefMgt.FilterGLEntryByDimension(SheetDefLine, GLEntry);
    end;

    procedure FilterGLBudgetEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var GLBudgetEntry: Record "G/L Budget Entry")
    begin
        SheetDefMgt.FilterGLBudgetEntryByDimension(SheetDefLine, GLBudgetEntry);
    end;

    procedure FilterCFEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var CFForecastEntry: Record "Cash Flow Forecast Entry")
    begin
        SheetDefMgt.FilterCFEntryByDimension(SheetDefLine, CFForecastEntry);
    end;

    procedure FilterAnalysisViewEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var AnalysisViewEntry: Record "Analysis View Entry")
    begin
        SheetDefMgt.FilterAnalysisViewEntryByDimension(SheetDefLine, AnalysisViewEntry);
    end;

    procedure FilterAnalysisViewBudgetEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var AnalysisViewBudgetEntry: Record "Analysis View Budget Entry")
    begin
        SheetDefMgt.FilterAnalysisViewBudgetEntryByDimension(SheetDefLine, AnalysisViewBudgetEntry);
    end;

    procedure SheetTypeToText(SheetDefName: Record "Sheet Definition Name"; Type: Enum "Sheet Type"; var Text: Text): Boolean
    var
        AnalysisView: Record "Analysis View";
        GLSetup: Record "General Ledger Setup";
    begin
        if SheetDefName."Analysis View Name" = '' then begin
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
            AnalysisView.Get(SheetDefName."Analysis View Name");
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

    procedure TextToSheetType(SheetDefName: Record "Sheet Definition Name"; Text: Text; var Type: Enum "Sheet Type"): Boolean
    var
        AnalysisView: Record "Analysis View";
        GLSetup: Record "General Ledger Setup";
    begin
        if SheetDefName."Analysis View Name" = '' then begin
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
            AnalysisView.Get(SheetDefName."Analysis View Name");
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

    procedure InsertBufferForSheetTotalingLookup(SheetDefName: Record "Sheet Definition Name"; Type: Enum "Sheet Type"; var DimSelection: Page "Dimension Selection")
    var
        AnalysisView: Record "Analysis View";
        GLSetup: Record "General Ledger Setup";
    begin
        if SheetDefName."Analysis View Name" = '' then begin
            GLSetup.Get();
            case Type of
                "Sheet Type"::Dimension1:
                    if GLSetup."Global Dimension 1 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLSetup."Global Dimension 1 Code", '');
                "Sheet Type"::Dimension2:
                    if GLSetup."Global Dimension 2 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLSetup."Global Dimension 2 Code", '');
                "Sheet Type"::Dimension3:
                    if GLSetup."Shortcut Dimension 3 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLSetup."Shortcut Dimension 3 Code", '');
                "Sheet Type"::Dimension4:
                    if GLSetup."Shortcut Dimension 4 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLSetup."Shortcut Dimension 4 Code", '');
                "Sheet Type"::Dimension5:
                    if GLSetup."Shortcut Dimension 5 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLSetup."Shortcut Dimension 5 Code", '');
                "Sheet Type"::Dimension6:
                    if GLSetup."Shortcut Dimension 6 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLSetup."Shortcut Dimension 6 Code", '');
                "Sheet Type"::Dimension7:
                    if GLSetup."Shortcut Dimension 7 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLSetup."Shortcut Dimension 7 Code", '');
                "Sheet Type"::Dimension8:
                    if GLSetup."Shortcut Dimension 8 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLSetup."Shortcut Dimension 8 Code", '');
            end;
        end else begin
            AnalysisView.Get(SheetDefName."Analysis View Name");
            case Type of
                "Sheet Type"::Dimension1:
                    if AnalysisView."Dimension 1 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 1 Code", '');
                "Sheet Type"::Dimension2:
                    if AnalysisView."Dimension 2 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 2 Code", '');
                "Sheet Type"::Dimension3:
                    if AnalysisView."Dimension 3 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 3 Code", '');
                "Sheet Type"::Dimension4:
                    if AnalysisView."Dimension 4 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 4 Code", '');
            end;
        end;
    end;
}