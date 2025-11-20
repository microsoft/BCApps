// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Utilities;

report 37 "Balance Comp. - Prev. Year"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/GeneralLedger/Reports/BalanceCompPrevYear.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Balance Comp. - Prev. Year';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
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
            column(STRSUBSTNO_Text016_Indent_; StrSubstNo(IndentationLevelCap, SelectStr(Indent + 1, IndentTxt)))
            {
            }
            column(Text016; IndentationLevelCap)
            {
            }
            column(G_L_Account__TABLECAPTION__________GLFilter; TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(LastPage; LastPageCap)
            {
            }
            column(Conitnued; ContinuedCap)
            {
            }
            column("Page"; PageCap)
            {
            }
            column(RoundingText; RoundingText)
            {
            }
            column(RoundingFactor; RoundingFactor)
            {
            }
            column(PeriodEndingDate; Format(PeriodEndingDate))
            {
            }
            column(PreviousEndingDate; Format(PreviousEndingDate))
            {
            }
            column(STRSUBSTNO___1___2__PeriodStartingDate_PeriodEndingDate_; StrSubstNo('%1..%2', PeriodStartingDate, PeriodEndingDate))
            {
            }
            column(STRSUBSTNO___1___2__PreviousStartingDate_PreviousEndingDate_; StrSubstNo('%1..%2', PreviousStartingDate, PreviousEndingDate))
            {
            }
            column(Balance_Comparison___Previous_YearCaption; Balance_Comparison___Previous_YearCaptionLbl)
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
            column(This_periodCaption; This_periodCaptionLbl)
            {
            }
            column(This_Year_toCaption; This_Year_toCaptionLbl)
            {
            }
            column(Previous_Year_toCaption; Previous_Year_toCaptionLbl)
            {
            }
            column(Previous_Year_PeriodCaption; Previous_Year_PeriodCaptionLbl)
            {
            }
            column(IndentTxtML; SelectStr(Indent + 1, IndentTxt))
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
                column(ColumnValuesAsText_7_; ColumnValuesAsText[7])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_8_; ColumnValuesAsText[8])
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
                column(G_L_Account___No__of_Blank_Lines_; "G/L Account"."No. of Blank Lines")
                {
                }
                column(G_L_Account___Account_Type_; Format("G/L Account"."Account Type", 0, 2))
                {
                }
                column(PageGroupNo; PageGroupNo)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                PageGroupNo := NextPageGroupNo;
                if "New Page" then
                    NextPageGroupNo := PageGroupNo + 1;

                Clear(ColumnValuesAsText);

                // FY Balans
                SetRange("Date Filter", PeriodStartingDate, PeriodEndingDate);
                CalcFields("Debit Amount", "Credit Amount");
                ColumnValuesAsText[1] := RoundAmount("Debit Amount");
                ColumnValuesAsText[2] := RoundAmount(Abs("Credit Amount"));

                // Saldo
                SetRange("Date Filter", 0D, PeriodEndingDate);
                CalcFields("Balance at Date");
                if "Balance at Date" > 0 then
                    ColumnValuesAsText[3] := RoundAmount("Balance at Date")
                else
                    ColumnValuesAsText[4] := RoundAmount(Abs("Balance at Date"));

                // PreviousPeriod
                SetRange("Date Filter", PreviousStartingDate, PreviousEndingDate);
                CalcFields("Debit Amount", "Credit Amount");
                ColumnValuesAsText[5] := RoundAmount("Debit Amount");
                ColumnValuesAsText[6] := RoundAmount(Abs("Credit Amount"));

                // PreviousYear
                SetRange("Date Filter", 0D, PreviousEndingDate);
                CalcFields("Balance at Date");
                if "Balance at Date" > 0 then
                    ColumnValuesAsText[7] := RoundAmount("Balance at Date")
                else
                    ColumnValuesAsText[8] := RoundAmount(Abs("Balance at Date"));
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
                end;

                CompanyInfo.CalcFields(Picture);

                if PeriodStartingDate = 0D then
                    Error(Text004);
                if PeriodEndingDate = 0D then
                    Error(Text005);

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
        AboutTitle = 'About Balance Comp. - Prev. Year';
        AboutText = 'The **Balance Comp. - Prev. Year** report provides a side-by-side view of account balances across two fiscal years for easy comparison. Use it for analyzing year-over-year financial performance, identifying major variances, and spotting trends across accounts.';
        SaveValues = true;

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
                            SetPreviousDates();
                        end;
                    }
                    field(PeriodEndingDate; PeriodEndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';

                        trigger OnValidate()
                        begin
                            SetPreviousDates();
                        end;
                    }
                    field(PreviousStartingDate; PreviousStartingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Previous Starting Date';
                        ToolTip = 'Specifies the first date of the previous accounting period that you want to compare with.';

                        trigger OnValidate()
                        begin
                            CheckDates();
                        end;
                    }
                    field(PreviousEndingDate; PreviousEndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Previous Ending Date';
                        ToolTip = 'Specifies the last date of the previous accounting period that you want to compare with.';

                        trigger OnValidate()
                        begin
                            CheckDates();
                        end;
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
                            CheckIndent();
                        end;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GLFilter := "G/L Account".GetFilters();
    end;

    var
        CompanyInfo: Record "Company Information";
        AccountingPeriod: Record "Accounting Period";
        GLIndent: Record "G/L Account";
        MatrixMgt: Codeunit "Matrix Management";
        RoundingFactor: Enum "Analysis Rounding Factor";
        ColumnValuesAsText: array[13] of Text[30];
        RoundingText: Text[80];
        PeriodStartingDate: Date;
        PeriodEndingDate: Date;
        PreviousStartingDate: Date;
        PreviousEndingDate: Date;
        FYStartingDate: Date;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Period: %1..%2';
        Text002: Label 'Fiscal Year Starting Date: %1';
#pragma warning restore AA0470
        Text004: Label 'Enter the starting date for the first period.';
        Text005: Label 'Enter the ending date for the first period.';
        Text006: Label '<-1Y>', Locked = true;
        Text011: Label 'Amounts are rounded to 1';
        Text012: Label 'Amounts are in whole 1000s.';
        Text013: Label 'Amounts are in whole 1000000s.';
#pragma warning disable AA0470
        Text014: Label '%1 and %2 do not belong to the same fiscal year.';
        Text015: Label 'Indentation Level %1 is not used in the Chart of Accounts. This Chart of Accounts uses max. %2 levels.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        IndentTxt: Label 'None,0,1,2,3,4,5';
        Indent: Option "None","0","1","2","3","4","5";
        MaxIndent: Text[5];
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        IndentationLevelCap: Label 'Indentation Level : %1';
#pragma warning restore AA0470
        LastPageCap: Label '/ Last Page';
        ContinuedCap: Label '/ Continued';
        PageCap: Label 'Page {0} {1}';
#pragma warning restore AA0074
        Balance_Comparison___Previous_YearCaptionLbl: Label 'Balance Comparison - Previous Year';
#pragma warning disable AA0074
        NameCap: Label 'Name';
#pragma warning restore AA0074
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        This_periodCaptionLbl: Label 'This period';
        This_Year_toCaptionLbl: Label 'This Year to';
        Previous_Year_toCaptionLbl: Label 'Previous Year to';
        Previous_Year_PeriodCaptionLbl: Label 'Previous Year Period';

    protected var
        GLFilter: Text;

    procedure SetEndingDate()
    begin
        AccountingPeriod.Reset();
        AccountingPeriod.SetFilter("Starting Date", '>%1', PeriodStartingDate);
        AccountingPeriod.FindFirst();
        PeriodEndingDate := AccountingPeriod."Starting Date" - 1;
    end;

    procedure SetPreviousDates()
    begin
        PreviousStartingDate := CalcDate(Text006, PeriodStartingDate);
        PreviousEndingDate := CalcDate(Text006, PeriodEndingDate);
        CheckDates();
    end;

    local procedure CheckDates()
    var
        AccountingPeriod2: Record "Accounting Period";
        AccountingPeriod3: Record "Accounting Period";
    begin
        AccountingPeriod2.SetRange("New Fiscal Year", true);
        AccountingPeriod2.SetFilter("Starting Date", '<=%1', PeriodStartingDate);
        AccountingPeriod2.FindLast();

        AccountingPeriod3.SetRange("New Fiscal Year", true);
        AccountingPeriod3.SetFilter("Starting Date", '<=%1', PeriodEndingDate);
        AccountingPeriod3.FindLast();
        if AccountingPeriod2."Starting Date" <> AccountingPeriod3."Starting Date" then
            Error(Text014, PeriodStartingDate, PeriodEndingDate);

        AccountingPeriod2.Reset();
        AccountingPeriod3.Reset();

        AccountingPeriod2.SetRange("New Fiscal Year", true);
        AccountingPeriod2.SetFilter("Starting Date", '<=%1', PreviousStartingDate);
        AccountingPeriod2.FindLast();

        AccountingPeriod3.SetRange("New Fiscal Year", true);
        AccountingPeriod3.SetFilter("Starting Date", '<=%1', PreviousEndingDate);
        AccountingPeriod3.FindLast();
        if AccountingPeriod2."Starting Date" <> AccountingPeriod3."Starting Date" then
            Error(Text014, PreviousStartingDate, PreviousEndingDate);
    end;

    procedure RoundAmount(Value: Decimal): Text[30]
    begin
        exit(MatrixMgt.FormatAmount(Value, RoundingFactor, false));
    end;

    procedure InitializeRequest(NewPeriodStartingDate: Date; NewPeriodEndingDate: Date; NewPreviousStartingDate: Date; NewPreviousEndingDate: Date; NewRoundingFactor: Option; NewIndent: Option)
    begin
        if NewPeriodStartingDate <> 0D then begin
            PeriodStartingDate := NewPeriodStartingDate;
            SetEndingDate();
            SetPreviousDates();
        end;

        if NewPeriodEndingDate <> 0D then begin
            PeriodEndingDate := NewPeriodEndingDate;
            SetPreviousDates();
        end;

        if NewPreviousStartingDate <> 0D then begin
            PreviousStartingDate := NewPreviousStartingDate;
            CheckDates();
        end;

        if NewPreviousEndingDate <> 0D then begin
            PreviousEndingDate := NewPreviousEndingDate;
            CheckDates();
        end;

        RoundingFactor := "Analysis Rounding Factor".FromInteger(NewRoundingFactor);
        if NewIndent <> Indent::None then begin
            Indent := NewIndent;
            CheckIndent();
        end;
    end;

    local procedure CheckIndent()
    begin
        GLIndent.Reset();
        MaxIndent := '';
        if GLIndent.FindSet() then
            repeat
                if Format(GLIndent.Indentation) > MaxIndent then
                    MaxIndent := Format(GLIndent.Indentation);
            until GLIndent.Next() = 0;

        if Format(Indent) > MaxIndent then
            if Indent <> Indent::None then
                Error(Text015, SelectStr(Indent + 1, IndentTxt), MaxIndent);
    end;
}

