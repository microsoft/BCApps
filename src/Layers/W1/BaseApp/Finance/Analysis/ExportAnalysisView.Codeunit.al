// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.CashFlow.Account;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Utilities;
using System.IO;

codeunit 424 "Export Analysis View"
{

    trigger OnRun()
    begin
    end;

    var
        TempDimValue2: Record "Dimension Value" temporary;
        TempDimValue3: Record "Dimension Value" temporary;
        TempGLAcc2: Record "G/L Account" temporary;
        TempGLAcc3: Record "G/L Account" temporary;
        TempCFAccount2: Record "Cash Flow Account" temporary;
        TempCFAccount3: Record "Cash Flow Account" temporary;
        BusUnit: Record "Business Unit";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        FileMgt: Codeunit "File Management";
        NoOfColumns: Integer;
        MaxLevel: Integer;
        MaxLevelDim: array[4] of Integer;
        HasBusinessUnits: Boolean;
        GLAccountSource: Boolean;
        ServerFileName: Text;
        SkipDownload: Boolean;

#pragma warning disable AA0074
        Text000: Label 'You can only export Actual amounts and Budgeted amounts.\Please change the option in the Show field.';
        Text001: Label 'This combination is not valid. You cannot export Debit and Credit amounts for Budgeted amounts.\Please enter Amount in the Show Amount field.';
        Text002: Label 'General Info._';
        Text003: Label 'None';
        Text004: Label 'Day';
        Text005: Label 'Week';
        Text006: Label 'Month';
        Text007: Label 'Quarter';
        Text008: Label 'Year';
        Text009: Label 'Accounting Period';
        Text011: Label 'Analysis by Dimension ';
        Text012: Label 'Amount Type';
        Text013: Label 'Net Change';
        Text014: Label 'Balance at Date';
        Text015: Label 'Date Filter';
        Text016: Label 'Budget Filter';
        Text116: Label 'Cash Flow Forecast Filter';
        Text018: Label 'G/L Account';
        Text118: Label 'Cash Flow Account';
        Text020: Label 'Budgeted Amount';
        Text022: Label 'Level';
        Text023: Label 'Analysis View Name';
        Text024: Label 'Closing Entries';
        Text025: Label 'Included';
        Text026: Label 'Excluded';
        Text027: Label 'All amounts shown in ';
        Text028: Label 'Show Opposite Sign';
        Text029: Label 'Yes';
        Text030: Label 'No';
        Text031: Label 'Data_';
#pragma warning restore AA0074

    procedure ExportData(var AnalysisViewEntry: Record "Analysis View Entry"; AnalysisByDimParameters: Record "Analysis by Dim. Parameters")
    var
        BusUnitFilter: Text;
        CashFlowFilter: Text;
    begin
        GLAccountSource := AnalysisByDimParameters."Analysis Account Source" = AnalysisByDimParameters."Analysis Account Source"::"G/L Account";

        CheckCombination(AnalysisByDimParameters."Show Actual/Budgets", AnalysisByDimParameters."Show Amount Field");

        BusUnitFilter := '';
        CashFlowFilter := '';

        SetOtherFilterToCorrectFilter(AnalysisByDimParameters."Bus. Unit Filter", BusUnitFilter, CashFlowFilter);

        HasBusinessUnits := not BusUnit.IsEmpty();

        ServerFileName := FileMgt.ServerTempFileName('xlsx');

        CreateFillGeneralInfoSheet(AnalysisViewEntry, AnalysisByDimParameters);

        TempExcelBuffer.CreateBook(ServerFileName, StrSubstNo('%1%2', Text002, AnalysisViewEntry."Analysis View Code"));
        TempExcelBuffer.WriteSheet(StrSubstNo('%1%2', Text002, AnalysisViewEntry."Analysis View Code"), CompanyName, UserId);

        CreateDataSheet(AnalysisViewEntry, AnalysisByDimParameters);

        TempExcelBuffer.SelectOrAddSheet(StrSubstNo('%1%2', Text031, AnalysisViewEntry."Analysis View Code"));
        TempExcelBuffer.WriteAllToCurrentSheet(TempExcelBuffer);

        TempExcelBuffer.CloseBook();
        OnExportDataOnAfterCloseBook(TempExcelBuffer, AnalysisViewEntry, AnalysisByDimParameters);

        if not SkipDownload then
            TempExcelBuffer.OpenExcel();

        OnAfterExportData(TempExcelBuffer, AnalysisViewEntry);
    end;

    local procedure CreateDataSheet(var AnalysisViewEntry: Record "Analysis View Entry"; AnalysisByDimParameters: Record "Analysis by Dim. Parameters")
    var
        AnalysisViewEntry2: Record "Analysis View Entry";
        AnalysisView: Record "Analysis View";
        BusUnit: Record "Business Unit";
        StartDate: Date;
        EndDate: Date;
        WeekNo: Integer;
        Year: Integer;
        SignValue: Integer;
        NoOfLeadingColumns: Integer;
    begin
        TempExcelBuffer.DeleteAll();

        AnalysisViewEntry2.Copy(AnalysisViewEntry);
        AnalysisView.Get(AnalysisByDimParameters."Analysis View Code");
        PopulateTempAccountTable(AnalysisByDimParameters."Account Filter");

        FindDimLevel(AnalysisView."Dimension 1 Code", AnalysisByDimParameters."Dimension 1 Filter", 1);
        FindDimLevel(AnalysisView."Dimension 2 Code", AnalysisByDimParameters."Dimension 2 Filter", 2);
        FindDimLevel(AnalysisView."Dimension 3 Code", AnalysisByDimParameters."Dimension 3 Filter", 3);
        FindDimLevel(AnalysisView."Dimension 4 Code", AnalysisByDimParameters."Dimension 4 Filter", 4);

        SignValue := 1;
        if AnalysisByDimParameters."Show Opposite Sign" then
            SignValue := -1;

        CreateRowWithColumnsCaptions(AnalysisViewEntry2, AnalysisView);

        CreateAnalysisViewEntryPart(
          AnalysisViewEntry2, AnalysisView, StartDate, EndDate, SignValue, AnalysisByDimParameters);

        CreateAnalysisViewBudgetEntryPart(
          AnalysisView, StartDate, EndDate, SignValue, AnalysisByDimParameters);

        NoOfLeadingColumns := 0;
        case AnalysisViewEntry."Account Source" of
            AnalysisViewEntry."Account Source"::"G/L Account":
                begin
                    TempGLAcc2.SetRange("Account Type", TempGLAcc2."Account Type"::Posting);
                    if TempGLAcc2.Find('-') then
                        repeat
                            if not TempGLAcc2.Mark() then begin
                                FillOutGLAcc(TempGLAcc2."No.", AnalysisByDimParameters."Show Column Name");
                                StartNewRow();
                            end;
                        until TempGLAcc2.Next() = 0;
                end;
            AnalysisViewEntry."Account Source"::"Cash Flow Account":
                begin
                    TempCFAccount2.SetRange("Account Type", TempCFAccount2."Account Type"::Entry);
                    if TempCFAccount2.Find('-') then
                        ProcessMarkedTempCFAccountRec(AnalysisByDimParameters."Show Column Name");
                end;
        end;

        NoOfLeadingColumns := MaxLevel + 1;
        if HasBusinessUnits then begin
            if BusUnit.Find('-') then
                repeat
                    if not BusUnit.Mark() then begin
                        FillOutBusUnit(BusUnit.Code, AnalysisByDimParameters."Show Column Name");
                        StartNewRow();
                    end;
                until BusUnit.Next() = 0;
            NoOfLeadingColumns := NoOfLeadingColumns + 1;
            SetStartColumnNo(NoOfLeadingColumns);
        end;

        if AnalysisView."Dimension 1 Code" <> '' then
            WriteDimLine(1, AnalysisByDimParameters."Dimension 1 Filter", AnalysisView."Dimension 1 Code", NoOfLeadingColumns, AnalysisByDimParameters."Show Column Name");
        NoOfLeadingColumns := NoOfLeadingColumns + MaxLevelDim[1] + 1;

        if AnalysisView."Dimension 2 Code" <> '' then
            WriteDimLine(2, AnalysisByDimParameters."Dimension 2 Filter", AnalysisView."Dimension 2 Code", NoOfLeadingColumns, AnalysisByDimParameters."Show Column Name");
        NoOfLeadingColumns := NoOfLeadingColumns + MaxLevelDim[2] + 1;

        if AnalysisView."Dimension 3 Code" <> '' then
            WriteDimLine(3, AnalysisByDimParameters."Dimension 3 Filter", AnalysisView."Dimension 3 Code", NoOfLeadingColumns, AnalysisByDimParameters."Show Column Name");
        NoOfLeadingColumns := NoOfLeadingColumns + MaxLevelDim[3] + 1;

        if AnalysisView."Dimension 4 Code" <> '' then
            WriteDimLine(4, AnalysisByDimParameters."Dimension 4 Filter", AnalysisView."Dimension 4 Code", NoOfLeadingColumns, AnalysisByDimParameters."Show Column Name");
        NoOfLeadingColumns := NoOfLeadingColumns + MaxLevelDim[4] + 1;

        WeekNo := Date2DWY(StartDate, 2);
        Year := Date2DWY(StartDate, 3);
        StartDate := DWY2Date(1, WeekNo, Year);

        while StartDate <= EndDate do begin
            SetStartColumnNo(NoOfLeadingColumns);
            FillNextCellInRow(CalculatePeriodStart(StartDate, 0));
            FillNextCellInRow(CalculatePeriodStart(StartDate, 1));
            FillNextCellInRow(CalculatePeriodStart(StartDate, 2));
            FillNextCellInRow(CalculatePeriodStart(StartDate, 3));
            FillNextCellInRow(CalculatePeriodStart(StartDate, 4));
            StartNewRow();

            StartDate := CalcDate('<1W>', StartDate);
        end;
    end;

    local procedure CreateAnalysisViewEntryPart(var AnalysisViewEntry: Record "Analysis View Entry"; AnalysisView: Record "Analysis View"; var StartDate: Date; var EndDate: Date; SignValue: Integer; AnalysisByDimParameters: Record "Analysis by Dim. Parameters")
    var
        AnalysisViewEntry2: Record "Analysis View Entry";
        MaxDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateAnalysisViewEntryPart(AnalysisViewEntry, AnalysisView, StartDate, EndDate, AnalysisByDimParameters, IsHandled);
        if IsHandled then
            exit;

        StartDate := AnalysisViewEntry."Posting Date";
        AnalysisViewEntry2.SetFilter("Posting Date", AnalysisByDimParameters."Date Filter");
        if (AnalysisByDimParameters."Date Filter" <> '') and (AnalysisByDimParameters."Amount Type" = "Analysis Amount Type"::"Balance at Date") then begin
            MaxDate := AnalysisViewEntry2.GetRangeMax("Posting Date");
            AnalysisViewEntry.SetFilter("Posting Date", '<=%1', MaxDate);
        end;
        if AnalysisByDimParameters."Cash Flow Forecast Filter" <> '' then
            AnalysisViewEntry.SetFilter("Cash Flow Forecast No.", AnalysisByDimParameters."Cash Flow Forecast Filter");

        if AnalysisViewEntry.FindSet() then
            repeat
                if (AnalysisByDimParameters."Closing Entries" = 0) or (AnalysisViewEntry."Posting Date" = NormalDate(AnalysisViewEntry."Posting Date")) then begin
                    if AnalysisViewEntry."Posting Date" >= EndDate then
                        EndDate := AnalysisViewEntry."Posting Date"
                    else
                        if AnalysisViewEntry."Posting Date" <= StartDate then
                            StartDate := AnalysisViewEntry."Posting Date";

                    if GLAccountSource then begin
                        if TempGLAcc2.Get(AnalysisViewEntry."Account No.") then
                            TempGLAcc2.Mark(true);
                        FillOutGLAcc(AnalysisViewEntry."Account No.", AnalysisByDimParameters."Show Column Name");
                    end else begin
                        if TempCFAccount2.Get(AnalysisViewEntry."Account No.") then
                            TempCFAccount2.Mark(true);
                        FillOutCFAccount(AnalysisViewEntry."Account No.", AnalysisByDimParameters."Show Column Name");
                    end;

                    if HasBusinessUnits then
                        FillOutBusUnit(AnalysisViewEntry."Business Unit Code", AnalysisByDimParameters."Show Column Name");
                    if AnalysisView."Dimension 1 Code" <> '' then
                        FillOutDim(AnalysisViewEntry."Dimension 1 Value Code", AnalysisView."Dimension 1 Code", 1, AnalysisByDimParameters."Show Column Name");

                    if AnalysisView."Dimension 2 Code" <> '' then
                        FillOutDim(AnalysisViewEntry."Dimension 2 Value Code", AnalysisView."Dimension 2 Code", 2, AnalysisByDimParameters."Show Column Name");

                    if AnalysisView."Dimension 3 Code" <> '' then
                        FillOutDim(AnalysisViewEntry."Dimension 3 Value Code", AnalysisView."Dimension 3 Code", 3, AnalysisByDimParameters."Show Column Name");

                    if AnalysisView."Dimension 4 Code" <> '' then
                        FillOutDim(AnalysisViewEntry."Dimension 4 Value Code", AnalysisView."Dimension 4 Code", 4, AnalysisByDimParameters."Show Column Name");

                    if not AnalysisByDimParameters."Show In Add. Currency" then begin
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewEntry."Posting Date"), -1));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewEntry."Posting Date"), 0));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewEntry."Posting Date"), 1));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewEntry."Posting Date"), 2));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewEntry."Posting Date"), 3));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewEntry."Posting Date"), 4));
                        FillNextCellInRow(AnalysisViewEntry.Amount * SignValue);
                        FillNextCellInRow(AnalysisViewEntry."Debit Amount" * SignValue);
                        FillNextCellInRow(AnalysisViewEntry."Credit Amount" * SignValue);
                    end else begin
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewEntry."Posting Date"), -1));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewEntry."Posting Date"), 0));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewEntry."Posting Date"), 1));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewEntry."Posting Date"), 2));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewEntry."Posting Date"), 3));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewEntry."Posting Date"), 4));
                        FillNextCellInRow(AnalysisViewEntry."Add.-Curr. Amount" * SignValue);
                        FillNextCellInRow(AnalysisViewEntry."Add.-Curr. Debit Amount" * SignValue);
                        FillNextCellInRow(AnalysisViewEntry."Add.-Curr. Credit Amount" * SignValue);
                    end;
                    OnCreateAnalysisViewEntryPartOnBeforeStartNewRow(TempExcelBuffer, AnalysisViewEntry, AnalysisByDimParameters);
                    StartNewRow();
                end;
            until AnalysisViewEntry.Next() = 0;
    end;

    local procedure CreateAnalysisViewBudgetEntryPart(AnalysisView: Record "Analysis View"; var StartDate: Date; var EndDate: Date; SignValue: Integer; AnalysisByDimParameters: Record "Analysis by Dim. Parameters")
    var
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        CurrExchRate: Record "Currency Exchange Rate";
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
        MaxDate: Date;
        CurrExchDate: Date;
        NoOfRows: Integer;
        AddRepCurrAmount: Decimal;
    begin
        AnalysisViewBudgetEntry.SetFilter("Analysis View Code", AnalysisView.Code);
        AnalysisViewBudgetEntry.SetFilter("Posting Date", AnalysisByDimParameters."Date Filter");
        if (AnalysisByDimParameters."Date Filter" <> '') and (AnalysisByDimParameters."Amount Type" = "Analysis Amount Type"::"Balance at Date") then begin
            MaxDate := AnalysisViewBudgetEntry.GetRangeMax(AnalysisViewBudgetEntry."Posting Date");
            AnalysisViewBudgetEntry.SetFilter("Posting Date", '<= %1', MaxDate);
        end;
        AnalysisViewBudgetEntry.SetFilter("G/L Account No.", AnalysisByDimParameters."Account Filter");
        AnalysisViewBudgetEntry.SetFilter("Business Unit Code", AnalysisByDimParameters."Bus. Unit Filter");
        AnalysisViewBudgetEntry.SetFilter("Budget Name", AnalysisByDimParameters."Budget Filter");
        AnalysisViewBudgetEntry.SetFilter("Dimension 1 Value Code", AnalysisByDimParameters."Dimension 1 Filter");
        AnalysisViewBudgetEntry.SetFilter("Dimension 2 Value Code", AnalysisByDimParameters."Dimension 2 Filter");
        AnalysisViewBudgetEntry.SetFilter("Dimension 3 Value Code", AnalysisByDimParameters."Dimension 3 Filter");
        AnalysisViewBudgetEntry.SetFilter("Dimension 4 Value Code", AnalysisByDimParameters."Dimension 4 Filter");
        if AnalysisViewBudgetEntry.FindSet() then
            repeat
                if (AnalysisByDimParameters."Closing Entries" = 1) or (AnalysisViewBudgetEntry."Posting Date" = NormalDate(AnalysisViewBudgetEntry."Posting Date")) then begin
                    if AnalysisViewBudgetEntry."Posting Date" >= EndDate then
                        EndDate := AnalysisViewBudgetEntry."Posting Date";
                    if (AnalysisViewBudgetEntry."Posting Date" <= StartDate) or (StartDate = 0D) then
                        StartDate := AnalysisViewBudgetEntry."Posting Date";

                    NoOfRows := NoOfRows + 1;

                    if TempGLAcc2.Get(AnalysisViewBudgetEntry."G/L Account No.") then
                        TempGLAcc2.Mark(true);
                    FillOutGLAcc(AnalysisViewBudgetEntry."G/L Account No.", AnalysisByDimParameters."Show Column Name");
                    if HasBusinessUnits then
                        FillOutBusUnit(AnalysisViewBudgetEntry."Business Unit Code", AnalysisByDimParameters."Show Column Name");
                    if AnalysisView."Dimension 1 Code" <> '' then
                        FillOutDim(AnalysisViewBudgetEntry."Dimension 1 Value Code", AnalysisView."Dimension 1 Code", 1, AnalysisByDimParameters."Show Column Name");

                    if AnalysisView."Dimension 2 Code" <> '' then
                        FillOutDim(AnalysisViewBudgetEntry."Dimension 2 Value Code", AnalysisView."Dimension 2 Code", 2, AnalysisByDimParameters."Show Column Name");

                    if AnalysisView."Dimension 3 Code" <> '' then
                        FillOutDim(AnalysisViewBudgetEntry."Dimension 3 Value Code", AnalysisView."Dimension 3 Code", 3, AnalysisByDimParameters."Show Column Name");

                    if AnalysisView."Dimension 4 Code" <> '' then
                        FillOutDim(AnalysisViewBudgetEntry."Dimension 4 Value Code", AnalysisView."Dimension 4 Code", 4, AnalysisByDimParameters."Show Column Name");

                    if not AnalysisByDimParameters."Show In Add. Currency" then begin
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewBudgetEntry."Posting Date"), -1));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewBudgetEntry."Posting Date"), 0));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewBudgetEntry."Posting Date"), 1));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewBudgetEntry."Posting Date"), 2));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewBudgetEntry."Posting Date"), 3));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewBudgetEntry."Posting Date"), 4));
                        FillNextCellInRow('');
                        FillNextCellInRow('');
                        FillNextCellInRow('');
                        FillNextCellInRow(AnalysisViewBudgetEntry.Amount * SignValue);
                    end else begin
                        if AnalysisViewBudgetEntry.GetFilter(AnalysisViewBudgetEntry."Posting Date") = '' then
                            CurrExchDate := WorkDate()
                        else
                            CurrExchDate := AnalysisViewBudgetEntry.GetRangeMin(AnalysisViewBudgetEntry."Posting Date");
                        GLSetup.Get();
                        if AnalysisByDimParameters."Show In Add. Currency" and Currency.Get(GLSetup."Additional Reporting Currency") then
                            AddRepCurrAmount :=
                              Round(
                                CurrExchRate.ExchangeAmtLCYToFCY(
                                  CurrExchDate, GLSetup."Additional Reporting Currency", AnalysisViewBudgetEntry.Amount,
                                  CurrExchRate.ExchangeRate(
                                    CurrExchDate, GLSetup."Additional Reporting Currency")) * SignValue,
                                Currency."Amount Rounding Precision")
                        else
                            AddRepCurrAmount :=
                              Round(
                                CurrExchRate.ExchangeAmtLCYToFCY(
                                  CurrExchDate, GLSetup."Additional Reporting Currency", AnalysisViewBudgetEntry.Amount,
                                  CurrExchRate.ExchangeRate(
                                    CurrExchDate, GLSetup."Additional Reporting Currency")) * SignValue,
                                GLSetup."Amount Rounding Precision");
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewBudgetEntry."Posting Date"), -1));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewBudgetEntry."Posting Date"), 0));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewBudgetEntry."Posting Date"), 1));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewBudgetEntry."Posting Date"), 2));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewBudgetEntry."Posting Date"), 3));
                        FillNextCellInRow(CalculatePeriodStart(NormalDate(AnalysisViewBudgetEntry."Posting Date"), 4));
                        FillNextCellInRow('');
                        FillNextCellInRow('');
                        FillNextCellInRow('');
                        FillNextCellInRow(AddRepCurrAmount);
                    end;
                    StartNewRow();
                end;
            until AnalysisViewBudgetEntry.Next() = 0;
    end;

    local procedure CalculatePeriodStart(PostingDate: Date; DateCompression: Integer): Date
    var
        AccountingPeriod: Record "Accounting Period";
        PrevPostingDate: Date;
        PrevCalculatedPostingDate: Date;
    begin
        if PostingDate = ClosingDate(PostingDate) then
            exit(PostingDate);

        PrevPostingDate := 0D;
        case DateCompression of
            0:
                // Week :
                PostingDate := CalcDate('<CW+1D-1W>', PostingDate);
            1:
                // Month :
                PostingDate := CalcDate('<CM+1D-1M>', PostingDate);
            2:
                // Quarter :
                PostingDate := CalcDate('<CQ+1D-1Q>', PostingDate);
            3:
                // Year :
                PostingDate := CalcDate('<CY+1D-1Y>', PostingDate);
            4:
                // Period :
                begin
                    if PostingDate <> PrevPostingDate then begin
                        PrevPostingDate := PostingDate;
                        AccountingPeriod.SetRange("Starting Date", 0D, PostingDate);
                        if AccountingPeriod.FindLast() then
                            PrevCalculatedPostingDate := AccountingPeriod."Starting Date"
                        else
                            PrevCalculatedPostingDate := PostingDate;
                    end;
                    PostingDate := PrevCalculatedPostingDate;
                end;
        end;
        exit(PostingDate);
    end;

    local procedure CreateFillGeneralInfoSheet(var AnalysisViewEntry: Record "Analysis View Entry"; AnalysisByDimParameters: Record "Analysis by Dim. Parameters")
    var
        GLSetup: Record "General Ledger Setup";
        AnalysisView: Record "Analysis View";
        AnalysisViewFilter: Record "Analysis View Filter";
        RowNoCount: Integer;
    begin
        TempExcelBuffer.Reset();
        TempExcelBuffer.DeleteAll();

        FillCell(1, 1, AnalysisView.TableCaption());
        FillCell(2, 2, AnalysisViewEntry.FieldCaption("Analysis View Code"));
        FillCell(2, 3, AnalysisViewEntry."Analysis View Code");
        FillCell(3, 2, Text023);
        AnalysisView.Get(AnalysisByDimParameters."Analysis View Code");
        FillCell(3, 3, AnalysisView.Name);
        RowNoCount := 3;
        if AnalysisView."Account Filter" <> '' then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, AnalysisView.FieldCaption("Account Filter"));
            FillCell(RowNoCount, 3, AnalysisView."Account Filter");
        end;
        RowNoCount := RowNoCount + 1;
        FillCell(RowNoCount, 2, AnalysisView.FieldCaption("Date Compression"));
        case AnalysisView."Date Compression" of
            0:
                FillCell(RowNoCount, 3, Text003);
            1:
                FillCell(RowNoCount, 3, Text004);
            2:
                FillCell(RowNoCount, 3, Text005);
            3:
                FillCell(RowNoCount, 3, Text006);
            4:
                FillCell(RowNoCount, 3, Text007);
            5:
                FillCell(RowNoCount, 3, Text008);
            6:
                FillCell(RowNoCount, 3, Text009);
        end;
        if AnalysisView."Starting Date" <> 0D then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, AnalysisView.FieldCaption("Starting Date"));
            FillCell(RowNoCount, 3, AnalysisView."Starting Date");
        end;
        RowNoCount := RowNoCount + 1;
        FillCell(RowNoCount, 2, AnalysisView.FieldCaption("Last Date Updated"));
        FillCell(RowNoCount, 3, AnalysisView."Last Date Updated");
        AnalysisViewFilter.SetRange("Analysis View Code", AnalysisViewEntry."Analysis View Code");
        if AnalysisViewFilter.FindSet() then
            repeat
                RowNoCount := RowNoCount + 1;
                FillCell(RowNoCount, 2, AnalysisViewFilter."Dimension Code");
                FillCell(RowNoCount, 3, AnalysisViewFilter."Dimension Value Filter");
            until AnalysisViewFilter.Next() = 0;
        RowNoCount := RowNoCount + 1;
        FillCell(RowNoCount, 1, Text011);
        RowNoCount := RowNoCount + 1;
        FillCell(RowNoCount, 2, Text012);
        case AnalysisByDimParameters."Amount Type" of
            "Analysis Amount Type"::"Net Change":
                FillCell(RowNoCount, 3, Text013);
            "Analysis Amount Type"::"Balance at Date":
                FillCell(RowNoCount, 3, Text014);
        end;
        if AnalysisByDimParameters."Date Filter" <> '' then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, Text015);
            FillCell(RowNoCount, 3, AnalysisByDimParameters."Date Filter");
        end;
        if AnalysisByDimParameters."Account Filter" <> '' then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, AnalysisView.FieldCaption("Account Filter"));
            FillCell(RowNoCount, 3, AnalysisByDimParameters."Account Filter");
        end;
        if AnalysisByDimParameters."Budget Filter" <> '' then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, Text016);
            FillCell(RowNoCount, 3, AnalysisByDimParameters."Budget Filter");
        end;
        if AnalysisByDimParameters."Cash Flow Forecast Filter" <> '' then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, Text116);
            FillCell(RowNoCount, 3, AnalysisByDimParameters."Cash Flow Forecast Filter");
        end;
        if AnalysisByDimParameters."Dimension 1 Filter" <> '' then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, AnalysisView."Dimension 1 Code");
            FillCell(RowNoCount, 3, AnalysisByDimParameters."Dimension 1 Filter");
        end;
        if AnalysisByDimParameters."Dimension 2 Filter" <> '' then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, AnalysisView."Dimension 2 Code");
            FillCell(RowNoCount, 3, AnalysisByDimParameters."Dimension 2 Filter");
        end;
        if AnalysisByDimParameters."Dimension 3 Filter" <> '' then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, AnalysisView."Dimension 3 Code");
            FillCell(RowNoCount, 3, AnalysisByDimParameters."Dimension 3 Filter");
        end;
        if AnalysisByDimParameters."Dimension 4 Filter" <> '' then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, AnalysisView."Dimension 4 Code");
            FillCell(RowNoCount, 3, AnalysisByDimParameters."Dimension 4 Filter");
        end;
        if GLAccountSource then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, Text024);
            case AnalysisByDimParameters."Closing Entries" of
                0:
                    FillCell(RowNoCount, 3, Text025);
                1:
                    FillCell(RowNoCount, 3, Text026);
            end;
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, Text027);
            GLSetup.Get();
            if AnalysisByDimParameters."Show In Add. Currency" then
                FillCell(RowNoCount, 3, GLSetup."Additional Reporting Currency")
            else
                FillCell(RowNoCount, 3, GLSetup."LCY Code");
        end;

        RowNoCount := RowNoCount + 1;
        FillCell(RowNoCount, 2, Text028);
        if AnalysisByDimParameters."Show Opposite Sign" then
            FillCell(RowNoCount, 3, Text029)
        else
            FillCell(RowNoCount, 3, Text030);
    end;

    local procedure CreateRowWithColumnsCaptions(AnalysisViewEntry: Record "Analysis View Entry"; AnalysisView: Record "Analysis View")
    var
        i: Integer;
    begin
        for i := 0 to MaxLevel do begin
            NoOfColumns := NoOfColumns + 1;
            FillCell(1, NoOfColumns, GetPivotFieldAccountIndexValue(i));
        end;
        if HasBusinessUnits then begin
            NoOfColumns := NoOfColumns + 1;
            FillCell(1, NoOfColumns, BusUnit.TableCaption());
        end;
        if AnalysisView."Dimension 1 Code" <> '' then
            for i := 0 to MaxLevelDim[1] do begin
                NoOfColumns := NoOfColumns + 1;
                FillCell(1, NoOfColumns, AnalysisView."Dimension 1 Code" + ' ' + Format(Text022) + ' ' + Format(i));
            end;
        if AnalysisView."Dimension 2 Code" <> '' then
            for i := 0 to MaxLevelDim[2] do begin
                NoOfColumns := NoOfColumns + 1;
                FillCell(1, NoOfColumns, AnalysisView."Dimension 2 Code" + ' ' + Format(Text022) + ' ' + Format(i));
            end;
        if AnalysisView."Dimension 3 Code" <> '' then
            for i := 0 to MaxLevelDim[3] do begin
                NoOfColumns := NoOfColumns + 1;
                FillCell(1, NoOfColumns, AnalysisView."Dimension 3 Code" + ' ' + Format(Text022) + ' ' + Format(i));
            end;
        if AnalysisView."Dimension 4 Code" <> '' then
            for i := 0 to MaxLevelDim[4] do begin
                NoOfColumns := NoOfColumns + 1;
                FillCell(1, NoOfColumns, AnalysisView."Dimension 4 Code" + ' ' + Format(Text022) + ' ' + Format(i));
            end;

        FillNextCellInRow(Text004);
        FillNextCellInRow(Text005);
        FillNextCellInRow(Text006);
        FillNextCellInRow(Text007);
        FillNextCellInRow(Text008);
        FillNextCellInRow(Text009);
        FillNextCellInRow(AnalysisViewEntry.FieldCaption(Amount));
        FillNextCellInRow(AnalysisViewEntry.FieldCaption("Debit Amount"));
        FillNextCellInRow(AnalysisViewEntry.FieldCaption("Credit Amount"));
        FillNextCellInRow(Text020);

        OnCreateRowWithColumnsCaptionsOnBeforeStartNewRow(TempExcelBuffer, AnalysisViewEntry);
        StartNewRow();
    end;

    local procedure FindGLAccountParent(var Account: Code[20])
    begin
        TempGLAcc3.Get(Account);
        if TempGLAcc3.Indentation <> 0 then begin
            TempGLAcc3.SetRange(Indentation, TempGLAcc3.Indentation - 1);
            TempGLAcc3.Next(-1);
        end;
        Account := TempGLAcc3."No.";
    end;

    local procedure FindCFAccountParent(var Account: Code[20])
    begin
        TempCFAccount3.Get(Account);
        if TempCFAccount3.Indentation <> 0 then begin
            TempCFAccount3.SetRange(Indentation, TempCFAccount3.Indentation - 1);
            TempCFAccount3.Next(-1);
        end;
        Account := TempCFAccount3."No.";
    end;

    local procedure FindDimLevel(DimCode: Code[20]; DimFilter: Text; ArrayNo: Integer)
    var
        DimValue: Record "Dimension Value";
    begin
        if DimCode = '' then
            exit;
        DimValue.SetRange("Dimension Code", DimCode);
        if DimValue.Find('-') then
            repeat
                TempDimValue2.Copy(DimValue);
                TempDimValue2.Insert();
                TempDimValue3.Copy(DimValue);
                TempDimValue3.Insert();
            until DimValue.Next() = 0;
        TempDimValue2.SetFilter(Code, DimFilter);
        if TempDimValue2.Find('-') then
            repeat
                if MaxLevelDim[ArrayNo] < TempDimValue2.Indentation then
                    MaxLevelDim[ArrayNo] := TempDimValue2.Indentation;
            until TempDimValue2.Next() = 0;
    end;

    local procedure FindDimParent(var Account: Code[20]; DimensionCode: Code[20])
    begin
        TempDimValue3.Reset();
        TempDimValue3.SetRange("Dimension Code", DimensionCode);
        TempDimValue3.Get(DimensionCode, Account);
        if TempDimValue3.Indentation <> 0 then begin
            TempDimValue3.SetRange(Indentation, TempDimValue3.Indentation - 1);
            TempDimValue3.Next(-1);
        end;
        Account := TempDimValue3.Code;
    end;

    local procedure FillOutDim(DimValueCode: Code[20]; DimCode: Code[20]; DimNo: Integer; ShowName: Boolean)
    var
        TempParentNameValueBuffer: Record "Name/Value Buffer" temporary;
        DimensionValue: Record "Dimension Value";
        Indent: Integer;
        i: Integer;
        DimValueCode2: Code[20];
    begin
        if DimValueCode <> '' then begin
            if TempDimValue2.Get(DimCode, DimValueCode) then
                TempDimValue2.Mark(true)
            else
                TempDimValue2.Init();
            DimValueCode2 := DimValueCode;
            Indent := TempDimValue2.Indentation;
            if (Indent <> 0) and (DimValueCode2 <> '') then
                for i := Indent downto 1 do begin
                    FindDimParent(DimValueCode2, DimCode);
                    TempDimValue2.Get(DimCode, DimValueCode2);
                    AddParentToBuffer(TempParentNameValueBuffer, i, TempDimValue2.Code, TempDimValue2.Name);
                end;

            if TempParentNameValueBuffer.FindSet() then
                repeat
                    AddAcc(ShowName, TempParentNameValueBuffer.Name, TempParentNameValueBuffer.Value);
                until TempParentNameValueBuffer.Next() = 0;

            if DimensionValue.Get(DimCode, DimValueCode) then;

            if DimensionValue.Indentation <> MaxLevelDim[DimNo] then
                for i := DimensionValue.Indentation + 1 to MaxLevelDim[DimNo] do
                    AddAcc(ShowName, DimensionValue.Code, DimensionValue.Name);

            AddAcc(ShowName, DimensionValue.Code, DimensionValue.Name);
        end else
            for i := 0 to MaxLevelDim[DimNo] do
                AddAcc(false, '', '');
    end;

    local procedure FillOutGLAcc(GLAccNo: Code[20]; ShowName: Boolean)
    var
        GLAccount: Record "G/L Account";
        TempParentNameValueBuffer: Record "Name/Value Buffer" temporary;
        i: Integer;
        Indent: Integer;
        Account: Code[20];
    begin
        Account := GLAccNo;
        TempGLAcc3.Get(Account);
        TempGLAcc3.Mark(true);
        Indent := TempGLAcc3.Indentation;
        if Indent <> 0 then
            for i := Indent downto 1 do begin
                FindGLAccountParent(Account);
                TempGLAcc3.Get(Account);
                AddParentToBuffer(TempParentNameValueBuffer, i, TempGLAcc3."No.", TempGLAcc3.Name);
            end;

        if TempParentNameValueBuffer.FindSet() then
            repeat
                AddAcc(ShowName, TempParentNameValueBuffer.Name, TempParentNameValueBuffer.Value);
            until TempParentNameValueBuffer.Next() = 0;

        GLAccount.Get(GLAccNo);
        if GLAccount.Indentation <> MaxLevel then
            for i := GLAccount.Indentation + 1 to MaxLevel do
                AddAcc(ShowName, GLAccount."No.", GLAccount.Name);

        AddAcc(ShowName, GLAccount."No.", GLAccount.Name);
    end;

    local procedure FillOutCFAccount(CFAccNo: Code[20]; ShowName: Boolean)
    var
        CashFlowAccount: Record "Cash Flow Account";
        TempParentNameValueBuffer: Record "Name/Value Buffer" temporary;
        i: Integer;
        Indent: Integer;
        Account: Code[20];
    begin
        Account := CFAccNo;
        TempCFAccount3.Get(Account);
        TempCFAccount3.Mark(true);

        Indent := TempCFAccount2.Indentation;
        if Indent <> 0 then
            for i := Indent downto 1 do begin
                FindCFAccountParent(Account);
                TempCFAccount3.Get(Account);
                AddParentToBuffer(TempParentNameValueBuffer, i, TempCFAccount3."No.", TempCFAccount3.Name);
            end;

        if TempParentNameValueBuffer.FindSet() then
            repeat
                AddAcc(ShowName, TempParentNameValueBuffer.Name, TempParentNameValueBuffer.Value);
            until TempParentNameValueBuffer.Next() = 0;

        CashFlowAccount.Get(CFAccNo);
        if CashFlowAccount.Indentation <> MaxLevel then
            for i := CashFlowAccount.Indentation + 1 to MaxLevel do
                AddAcc(ShowName, CashFlowAccount."No.", CashFlowAccount.Name);

        AddAcc(ShowName, CashFlowAccount."No.", CashFlowAccount.Name);
    end;

    local procedure FillOutBusUnit(BusUnitCode: Code[20]; ShowName: Boolean)
    begin
        if BusUnitCode <> '' then begin
            BusUnit.Get(BusUnitCode);
            BusUnit.Mark(true);
            AddAcc(ShowName, BusUnit.Code, BusUnit.Name);
        end else
            AddAcc(false, '', '');
    end;

    local procedure FillCell(RowNo: Integer; ColumnNo: Integer; Value: Variant)
    begin
        TempExcelBuffer.Init();
        TempExcelBuffer.Validate("Row No.", RowNo);
        TempExcelBuffer.Validate("Column No.", ColumnNo);
        case true of
            Value.IsDecimal or Value.IsInteger:
                TempExcelBuffer.Validate("Cell Type", TempExcelBuffer."Cell Type"::Number);
            Value.IsDate:
                TempExcelBuffer.Validate("Cell Type", TempExcelBuffer."Cell Type"::Date);
            else
                TempExcelBuffer.Validate("Cell Type", TempExcelBuffer."Cell Type"::Text);
        end;
        TempExcelBuffer."Cell Value as Text" := CopyStr(Format(Value), 1, MaxStrLen(TempExcelBuffer."Cell Value as Text"));
        TempExcelBuffer.Insert();
    end;

    local procedure FillNextCellInRow(Value: Variant)
    var
        RowNo: Integer;
        ColumnNo: Integer;
    begin
        RowNo := TempExcelBuffer."Row No.";
        ColumnNo := TempExcelBuffer."Column No." + 1;
        TempExcelBuffer.Init();
        TempExcelBuffer.Validate("Row No.", RowNo);
        TempExcelBuffer.Validate("Column No.", ColumnNo);
        case true of
            Value.IsDecimal or Value.IsInteger:
                TempExcelBuffer.Validate("Cell Type", TempExcelBuffer."Cell Type"::Number);
            Value.IsDate:
                TempExcelBuffer.Validate("Cell Type", TempExcelBuffer."Cell Type"::Date);
            else
                TempExcelBuffer.Validate("Cell Type", TempExcelBuffer."Cell Type"::Text);
        end;
        TempExcelBuffer."Cell Value as Text" := CopyStr(Format(Value), 1, MaxStrLen(TempExcelBuffer."Cell Value as Text"));
        TempExcelBuffer.Insert();
    end;

    local procedure StartNewRow()
    var
        RowNo: Integer;
    begin
        RowNo := TempExcelBuffer."Row No." + 1;
        TempExcelBuffer.Init();
        TempExcelBuffer.Validate("Row No.", RowNo);
        TempExcelBuffer.Validate("Column No.", 0);
    end;

    local procedure SetStartColumnNo(ColumntNo: Integer)
    begin
        TempExcelBuffer."Column No." := ColumntNo;
    end;

    local procedure AddAcc(ShowName: Boolean; Account: Text; AccName: Text)
    var
        CellValueAsText: Text;
    begin
        if Account = '' then
            CellValueAsText := ''
        else
            if ShowName then
                CellValueAsText := Account + ' ' + AccName
            else
                CellValueAsText := Account;

        FillNextCellInRow(CellValueAsText);
    end;

    local procedure AddParentToBuffer(var NameValueBuffer: Record "Name/Value Buffer"; id: Integer; AccountNumber: Text[250]; AccountName: Text[250])
    begin
        NameValueBuffer.Init();
        NameValueBuffer.ID := id;
        NameValueBuffer.Name := AccountNumber;
        NameValueBuffer.Value := AccountName;
        NameValueBuffer.Insert();
    end;

    local procedure GetPivotFieldAccountIndexValue(Level: Integer): Text[250]
    begin
        if GLAccountSource then
            exit(Format(Text018) + ' ' + Format(Text022) + ' ' + Format(Level));

        exit(Format(Text118) + ' ' + Format(Text022) + ' ' + Format(Level));
    end;

    local procedure CheckCombination(Show: Enum "Analysis Show Amount Type"; AmountField: Enum "Analysis Show Amount Field")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCombination(GLAccountSource, Show.AsInteger(), AmountField.AsInteger(), IsHandled);
        if IsHandled then
            exit;

        if not GLAccountSource then
            exit;

        if (Show <> "Analysis Show Amount Type"::"Actual Amounts") and (Show <> "Analysis Show Amount Type"::"Budgeted Amounts") then
            Error(Text000);
        if (Show = "Analysis Show Amount Type"::"Budgeted Amounts") and (AmountField <> "Analysis Show Amount Field"::Amount) then
            Error(Text001);
    end;

    local procedure SetOtherFilterToCorrectFilter(DraftFilter: Text; var BusUnitFilter: Text; var CashFlowFilter: Text)
    begin
        if GLAccountSource then
            BusUnitFilter := DraftFilter
        else
            CashFlowFilter := DraftFilter;
    end;

    local procedure PopulateTempAccountTable(AccFilter: Text)
    var
        GLAcc: Record "G/L Account";
        CFAccount: Record "Cash Flow Account";
    begin
        if GLAccountSource then begin
            if GLAcc.Find('-') then
                repeat
                    TempGLAcc3.Copy(GLAcc);
                    TempGLAcc3.Insert();
                until GLAcc.Next() = 0;

            TempGLAcc3.SetFilter("No.", AccFilter);
            if TempGLAcc3.Find('-') then
                repeat
                    TempGLAcc2.Copy(TempGLAcc3);
                    TempGLAcc2.Insert();
                    if MaxLevel < TempGLAcc2.Indentation then
                        MaxLevel := TempGLAcc2.Indentation;
                until TempGLAcc3.Next() = 0;
            TempGLAcc3.SetRange("No.");
        end else begin
            if CFAccount.Find('-') then
                repeat
                    TempCFAccount3.Copy(CFAccount);
                    TempCFAccount3.Insert();
                until CFAccount.Next() = 0;

            TempCFAccount3.SetFilter("No.", AccFilter);
            if TempCFAccount3.Find('-') then
                repeat
                    TempCFAccount2.Copy(TempCFAccount3);
                    TempCFAccount2.Insert();
                    if MaxLevel < TempCFAccount2.Indentation then
                        MaxLevel := TempCFAccount2.Indentation;
                until TempCFAccount3.Next() = 0;
            TempCFAccount3.SetRange("No.");
        end;
    end;

    local procedure ProcessMarkedTempCFAccountRec(ShowName: Boolean)
    begin
        repeat
            if not TempCFAccount2.Mark() then begin
                FillOutCFAccount(TempCFAccount2."No.", ShowName);
                StartNewRow();
            end;
        until TempCFAccount2.Next() = 0;
    end;

    local procedure WriteDimLine(DimNo: Integer; DimFilter: Text; DimCode: Code[20]; NoOfLeadingColumns: Integer; ShowName: Boolean)
    begin
        SetStartColumnNo(NoOfLeadingColumns);
        TempDimValue2.SetFilter(Code, DimFilter);
        TempDimValue2.SetFilter("Dimension Code", DimCode);
        TempDimValue2.SetRange("Dimension Value Type", TempDimValue2."Dimension Value Type"::Standard);
        if TempDimValue2.Find('-') then
            repeat
                if not TempDimValue2.Mark() then begin
                    FillOutDim(TempDimValue2.Code, DimCode, DimNo, ShowName);
                    StartNewRow();
                    SetStartColumnNo(NoOfLeadingColumns);
                end;
            until TempDimValue2.Next() = 0;
    end;

    procedure GetServerFileName(): Text
    begin
        exit(ServerFileName);
    end;

    procedure SetSkipDownload()
    begin
        SkipDownload := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExportData(var varTempExcelBuffer: Record "Excel Buffer" temporary; var AnalysisViewEntry: Record "Analysis View Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateAnalysisViewEntryPartOnBeforeStartNewRow(var TempExcelBuffer: Record "Excel Buffer" temporary; var AnalysisViewEntry: Record "Analysis View Entry"; AnalysisByDimParameters: Record "Analysis by Dim. Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateRowWithColumnsCaptionsOnBeforeStartNewRow(var TempExcelBuffer: Record "Excel Buffer" temporary; var AnalysisViewEntry: Record "Analysis View Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExportDataOnAfterCloseBook(var TempExcelBuffer: Record "Excel Buffer" temporary; var AnalysisViewEntry: Record "Analysis View Entry"; AnalysisByDimParameters: Record "Analysis by Dim. Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCombination(GLAccountSource: Boolean; Show: Integer; AmountField: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateAnalysisViewEntryPart(var AnalysisViewEntry: Record "Analysis View Entry"; AnalysisView: Record "Analysis View"; var StartDate: Date; var EndDate: Date; AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; var IsHandled: Boolean)
    begin
    end;
}
