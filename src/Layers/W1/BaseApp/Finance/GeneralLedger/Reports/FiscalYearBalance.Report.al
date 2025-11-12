// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Utilities;

report 36 "Fiscal Year Balance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/GeneralLedger/Reports/FiscalYearBalance.rdlc';
    AdditionalSearchTerms = 'closing balance';
    ApplicationArea = Basic, Suite;
    Caption = 'Fiscal Year Balance';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Account Type", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(STRSUBSTNO_Text000_PeriodStartingDate_PeriodEndingDate_; StrSubstNo(Text000, PeriodStartingDate, PeriodEndingDate))
            {
            }
            column(STRSUBSTNO_Text002_FYStartingDate_; StrSubstNo(Text002, FYStartingDate))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO_Text015_Indent_; StrSubstNo(Text015, SelectStr(Indent + 1, IndentTxt)))
            {
            }
            column(G_L_Account__TABLECAPTION__________GLFilter; TableCaption + ': ' + GLFilter)
            {
            }
            column(ShowResults; ShowResults)
            {
            }
            column(GLFilters; GLFilter)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(Text_LastPage; LastPageCap)
            {
            }
            column(Text_Continued; ContinuedCap)
            {
            }
            column(NoBlankLines; "No. of Blank Lines")
            {
            }
            column(RoundingText; RoundingText)
            {
            }
            column(FYStartingDate___1; Format(FYStartingDate - 1))
            {
            }
            column(STRSUBSTNO___1___2__PeriodStartingDate_PeriodEndingDate_; StrSubstNo('%1..%2', PeriodStartingDate, PeriodEndingDate))
            {
            }
            column(PeriodEndingDate; Format(PeriodEndingDate))
            {
            }
            column(AccountType; "Account Type")
            {
            }
            column(AccountTypePosting; GLAccountTypePosting)
            {
            }
            column(Fiscal_Year_BalanceCaption; Fiscal_Year_BalanceCaptionLbl)
            {
            }
            column(G_L_Account___No__Caption; FieldCaption("No."))
            {
            }
            column(NameCaption; NameCap)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(Closing_BalanceCaption; Closing_BalanceCaptionLbl)
            {
            }
            column(Fiscal_Year_untilCaption; Fiscal_Year_untilCaptionLbl)
            {
            }
            column(This_periodCaption; This_periodCaptionLbl)
            {
            }
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            column(Profit___LossCaption; Profit___LossCaptionLbl)
            {
            }
            column(ProfitCaption; ProfitCaptionLbl)
            {
            }
            column(ResultCaption; ResultCaptionLbl)
            {
            }
            column(IndentTxtML; SelectStr(Indent + 1, IndentTxt))
            {
            }
            column(ProfitValue1; ProfitValueAsText[1])
            {
            }
            column(ProfitValue2; ProfitValueAsText[2])
            {
            }
            column(ProfitValue3; ProfitValueAsText[3])
            {
            }
            column(ProfitValue4; ProfitValueAsText[4])
            {
            }
            column(ProfitValue5; ProfitValueAsText[5])
            {
            }
            column(ProfitValue6; ProfitValueAsText[6])
            {
            }
            column(ProfitValue7; ProfitValueAsText[7])
            {
            }
            column(ProfitValue8; ProfitValueAsText[8])
            {
            }
            column(ProfitValue9; ProfitValueAsText[9])
            {
            }
            column(ProfitValue10; ProfitValueAsText[10])
            {
            }
            column(SumValue1; SumValueAsText[1])
            {
            }
            column(SumValue2; SumValueAsText[2])
            {
            }
            column(SumValue3; SumValueAsText[3])
            {
            }
            column(SumValue4; SumValueAsText[4])
            {
            }
            column(SumValue5; SumValueAsText[5])
            {
            }
            column(SumValue6; SumValueAsText[6])
            {
            }
            column(SumValue7; SumValueAsText[7])
            {
            }
            column(SumValue8; SumValueAsText[8])
            {
            }
            column(SumValue9; SumValueAsText[9])
            {
            }
            column(SumValue10; SumValueAsText[10])
            {
            }
            column(FinalTotal1; FinalTotalAsText[1])
            {
            }
            column(FinalTotal2; FinalTotalAsText[2])
            {
            }
            column(FinalTotal3; FinalTotalAsText[3])
            {
            }
            column(FinalTotal4; FinalTotalAsText[4])
            {
            }
            column(FinalTotal5; FinalTotalAsText[5])
            {
            }
            column(FinalTotal6; FinalTotalAsText[6])
            {
            }
            column(FinalTotal7; FinalTotalAsText[7])
            {
            }
            column(FinalTotal8; FinalTotalAsText[8])
            {
            }
            column(FinalTotal9; FinalTotalAsText[9])
            {
            }
            column(FinalTotal10; FinalTotalAsText[10])
            {
            }
            dataitem(BlankLineCounter; "Integer")
            {
                DataItemTableView = sorting(Number);

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, "G/L Account"."No. of Blank Lines");
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(G_L_Account___No__; "G/L Account"."No.")
                {
                }
                column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(ColumnValuesAsText_1_; ColumnValuesAsText[1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_2_; ColumnValuesAsText[2])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_3_; ColumnValuesAsText[3])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_4_; ColumnValuesAsText[4])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_5_; ColumnValuesAsText[5])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_6_; ColumnValuesAsText[6])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_7_; ColumnValuesAsText[7])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_8_; ColumnValuesAsText[8])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_9_; ColumnValuesAsText[9])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_10_; ColumnValuesAsText[10])
                {
                    AutoCalcField = false;
                }
            }

            trigger OnAfterGetRecord()
            var
                I: Integer;
            begin
                PageGroupNo := NextPageGroupNo;
                if "New Page" then
                    NextPageGroupNo := PageGroupNo + 1;

                Clear(ColumnValuesAsText);
                Clear(ColumnValuesAsTot);
                GLAccount2.Copy("G/L Account");
                // Opening Balance
                GLAccount2.SetRange("Date Filter", 0D, ClosingDate(FYStartingDate - 1));
                GLAccount2.CalcFields("Net Change");
                if GLAccount2."Net Change" > 0 then begin
                    ColumnValuesAsText[1] := RoundAmount(GLAccount2."Net Change");
                    ColumnValuesAsTot[1] := GLAccount2."Net Change";
                end else begin
                    ColumnValuesAsText[2] := RoundAmount(Abs(GLAccount2."Net Change"));
                    ColumnValuesAsTot[2] := Abs(GLAccount2."Net Change");
                end;
                // Fiscal YTD
                if FYStartingDate <> PeriodStartingDate then begin
                    GLAccount2.SetRange("Date Filter", FYStartingDate, PeriodStartingDate - 1);
                    GLAccount2.CalcFields("Debit Amount", "Credit Amount");
                    ColumnValuesAsText[3] := RoundAmount(GLAccount2."Debit Amount");
                    ColumnValuesAsTot[3] := GLAccount2."Debit Amount";
                    ColumnValuesAsText[4] := RoundAmount(GLAccount2."Credit Amount");
                    ColumnValuesAsTot[4] := GLAccount2."Credit Amount";
                end;
                // This period
                GLAccount2.SetRange("Date Filter", PeriodStartingDate, PeriodEndingDate);
                GLAccount2.CalcFields("Debit Amount", "Credit Amount");
                ColumnValuesAsText[5] := RoundAmount(GLAccount2."Debit Amount");
                ColumnValuesAsTot[5] := GLAccount2."Debit Amount";
                ColumnValuesAsText[6] := RoundAmount(GLAccount2."Credit Amount");
                ColumnValuesAsTot[6] := GLAccount2."Credit Amount";
                // Fiscal Year Cumulative Balance
                GLAccount2.SetRange("Date Filter", 0D, PeriodEndingDate);
                GLAccount2.CalcFields("Balance at Date");
                case GLAccount2."Income/Balance" of
                    GLAccount2."Income/Balance"::"Balance Sheet":
                        if GLAccount2."Balance at Date" > 0 then begin
                            ColumnValuesAsText[7] := RoundAmount(GLAccount2."Balance at Date");
                            ColumnValuesAsTot[7] := GLAccount2."Balance at Date";
                        end
                        else begin
                            ColumnValuesAsText[8] := RoundAmount(Abs(GLAccount2."Balance at Date"));
                            ColumnValuesAsTot[8] := Abs(GLAccount2."Balance at Date");
                        end;
                    GLAccount2."Income/Balance"::"Income Statement":
                        if GLAccount2."Balance at Date" > 0 then begin
                            ColumnValuesAsText[9] := RoundAmount(GLAccount2."Balance at Date");
                            ColumnValuesAsTot[9] := GLAccount2."Balance at Date";
                        end
                        else begin
                            ColumnValuesAsText[10] := RoundAmount(Abs(GLAccount2."Balance at Date"));
                            ColumnValuesAsTot[10] := Abs(GLAccount2."Balance at Date");
                        end;
                end;

                for I := 1 to 10 do
                    SummTotals[I] += ColumnValuesAsTot[I];
                for I := 1 to 10 do
                    if I mod 2 <> 0 then
                        SummProfit[I] := SummTotals[I + 1] - SummTotals[I]
                    else
                        SummProfit[I] := SummTotals[I - 1] - SummTotals[I];

                FillTotals();
                GLAccountTypePosting := "Account Type" = "Account Type"::Posting;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
                NextPageGroupNo := 1;

                // Indentation Level
                case Indent of
                    Indent::"0":
                        begin
                            SetFilter("Account Type", '%1|%2', "Account Type"::Posting,
                              "Account Type"::"End-Total");
                            SetRange(Indentation, 0);
                        end;
                    Indent::"1":
                        begin
                            SetFilter("Account Type", '%1|%2', "Account Type"::Posting,
                              "Account Type"::"End-Total");
                            SetRange(Indentation, 1);
                        end;
                    Indent::"2":
                        begin
                            SetFilter("Account Type", '%1|%2', "Account Type"::Posting,
                              "Account Type"::"End-Total");
                            SetRange(Indentation, 2);
                        end;
                    Indent::"3":
                        begin
                            SetFilter("Account Type", '%1|%2', "Account Type"::Posting,
                              "Account Type"::"End-Total");
                            SetRange(Indentation, 3);
                        end;
                    Indent::"4":
                        begin
                            SetFilter("Account Type", '%1|%2', "Account Type"::Posting,
                              "Account Type"::"End-Total");
                            SetRange(Indentation, 4);
                        end;
                    Indent::"5":
                        begin
                            SetFilter("Account Type", '%1|%2', "Account Type"::Posting,
                              "Account Type"::"End-Total");
                            SetRange(Indentation, 5);
                        end;
                    Indent::None:
                        if ShowResults = true then
                            SetFilter("Account Type", '%1', "Account Type"::Posting);
                end;

                if PeriodStartingDate = 0D then
                    Error(Text003);

                if not AccountingPeriod.Get(PeriodStartingDate) then
                    Error(Text004);

                case RoundingFactor of
                    RoundingFactor::"1":
                        RoundingText := Text011;
                    RoundingFactor::"1000":
                        RoundingText := Text012;
                    RoundingFactor::"1000000":
                        RoundingText := Text013;
                end;

                AccountingPeriod.SetFilter("Starting Date", '<=%1', PeriodStartingDate);
                AccountingPeriod.SetRange("New Fiscal Year", true);
                AccountingPeriod.FindLast();
                FYStartingDate := AccountingPeriod."Starting Date";
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Fiscal Year Balance';
        AboutText = 'The **Fiscal Year Balance** report displays the opening and closing balances for each general ledger account within a selected fiscal year. Use it for fiscal year-end closing or financial analysis to verify that balances are correctly carried forward and to support reconciliation and trend review.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; PeriodStartingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';

                        trigger OnValidate()
                        begin
                            SetEndingDate();
                        end;
                    }
                    field(EndingDate; PeriodEndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(RoundingFactor; RoundingFactor)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Rounding Factor';
                        ToolTip = 'Specifies a rounding factor that will be used in the balance.';
                    }
                    field(Indent; Indent)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Indentation Level';
                        OptionCaption = 'None,0,1,2,3,4,5';
                        ToolTip = 'Specifies the indentation level that sets the range filter for the accounts you want to be displayed or printed. For example, if you select Indentation Level 1, you filter all Level 1 accounts ranging from Begin-Total to End-Total. If there is both a Begin-Total and an End-Total account in the selected range, the report only shows the End-Total.';

                        trigger OnValidate()
                        begin
                            CheckIndentationLevel();
                        end;
                    }
                    field(ShowResults; ShowResults)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Totals';
                        ToolTip = 'Specifies if you want to show totals at the end of the report. If you select None in the Indentation Level field, and you select this field, the report will only show the posting account types.';

                        trigger OnValidate()
                        begin
                            if (Indent = Indent::None) and ShowResults then
                                Message(Text016);
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            AccountingPeriod.SetFilter("Starting Date", '<=%1', WorkDate());
            AccountingPeriod.SetRange("New Fiscal Year", true);
            if AccountingPeriod.FindLast() then
                PeriodStartingDate := AccountingPeriod."Starting Date";

            SetEndingDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GLFilter := "G/L Account".GetFilters();
    end;

    var
        AccountingPeriod: Record "Accounting Period";
        GLIndent: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        MatrixMgt: Codeunit "Matrix Management";
        RoundingFactor: Enum "Analysis Rounding Factor";
        GLFilter: Text;
        ColumnValuesAsText: array[13] of Text[30];
        ProfitValueAsText: array[10] of Text;
        SumValueAsText: array[10] of Text;
        FinalTotalAsText: array[10] of Text;
        RoundingText: Text[80];
        PeriodStartingDate: Date;
        PeriodEndingDate: Date;
        FYStartingDate: Date;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Period : %1..%2';
        Text002: Label 'Fiscal Year Starting Date : %1';
#pragma warning restore AA0470
        Text003: Label 'Enter the starting date for the first period.';
        Text004: Label 'The starting date is not the starting date of an Accounting Period.';
        Text011: Label 'Amounts are rounded to 1';
        Text012: Label 'Amounts are in whole 1000s.';
        Text013: Label 'Amounts are in whole 1000000s.';
#pragma warning disable AA0470
        Text014: Label 'Indentation Level %1 is not used in the Chart of Accounts. This Chart of Accounts uses max. %2 levels.';
        Text015: Label 'Indentation Level : %1';
#pragma warning restore AA0470
        Text016: Label 'In case of no indentation, the Chart of Accounts will show only postings.';
#pragma warning restore AA0074
        IndentTxt: Label 'None,0,1,2,3,4,5';
        Indent: Option "None","0","1","2","3","4","5";
        MaxIndent: Text[5];
        ColumnValuesAsTot: array[10] of Decimal;
        ShowResults: Boolean;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
#pragma warning disable AA0074
        LastPageCap: Label '/ Last Page';
        ContinuedCap: Label '/ Continued';
#pragma warning restore AA0074
        Fiscal_Year_BalanceCaptionLbl: Label 'Fiscal Year Balance';
#pragma warning disable AA0074
        NameCap: Label 'Name';
#pragma warning restore AA0074
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        Closing_BalanceCaptionLbl: Label 'Closing Balance';
        Fiscal_Year_untilCaptionLbl: Label 'Fiscal Year until';
        This_periodCaptionLbl: Label 'This period';
        BalanceCaptionLbl: Label 'Balance';
        Profit___LossCaptionLbl: Label 'Profit & Loss';
        ProfitCaptionLbl: Label 'Profit';
        ResultCaptionLbl: Label 'Result';
        SummProfit: array[10] of Decimal;
        SummTotals: array[10] of Decimal;
        GLAccountTypePosting: Boolean;

    procedure SetEndingDate()
    begin
        AccountingPeriod.Reset();
        AccountingPeriod.SetFilter("Starting Date", '>%1', PeriodStartingDate);
        AccountingPeriod.FindFirst();
        PeriodEndingDate := AccountingPeriod."Starting Date" - 1;
    end;

    procedure RoundAmount(Value: Decimal): Text[30]
    begin
        exit(MatrixMgt.FormatAmount(Value, RoundingFactor, false));
    end;

    procedure InitializeRequest(NewPeriodStartingDate: Date; NewPeriodEndingDate: Date; NewRoundingFactor: Option; NewIndent: Option; NewShowResults: Boolean)
    begin
        PeriodStartingDate := NewPeriodStartingDate;
        PeriodEndingDate := NewPeriodEndingDate;
        RoundingFactor := "Analysis Rounding Factor".FromInteger(NewRoundingFactor);
        Indent := NewIndent;
        CheckIndentationLevel();
        ShowResults := NewShowResults;
    end;

    local procedure CheckIndentationLevel()
    begin
        GLIndent.Reset();
        MaxIndent := '';
        if GLIndent.Find('-') then
            repeat
                if Format(GLIndent.Indentation) > MaxIndent then
                    MaxIndent := Format(GLIndent.Indentation);
            until GLIndent.Next() = 0;

        if Format(Indent) > MaxIndent then
            if Indent <> Indent::None then
                Error(Text014, SelectStr(Indent + 1, IndentTxt), MaxIndent);
    end;

    local procedure FillTotals()
    var
        I: Integer;
    begin
        Clear(ProfitValueAsText);
        Clear(SumValueAsText);
        Clear(FinalTotalAsText);
        for I := 1 to 10 do begin
            if SummProfit[I] > 0 then
                ProfitValueAsText[I] := Format(NonNegative(SummProfit[I]));
            if SummTotals[I] > 0 then
                SumValueAsText[I] := Format(SummTotals[I]);
            if NonNegative(SummProfit[I]) + SummTotals[I] > 0 then
                FinalTotalAsText[I] := Format(NonNegative(SummProfit[I]) + SummTotals[I]);
        end;
    end;

    local procedure NonNegative(Value: Decimal): Decimal
    begin
        if Value < 0 then
            exit(0);
        exit(Value);
    end;
}

