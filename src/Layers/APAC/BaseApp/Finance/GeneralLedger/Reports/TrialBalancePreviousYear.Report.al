// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Reporting;
using System.Utilities;

/// <summary>
/// Generates trial balance with previous year comparison showing current period balances against prior year amounts.
/// Provides year-over-year analysis with current and previous year balance comparisons for trend analysis.
/// </summary>
/// <remarks>
/// Data source: G/L Account table with current and previous year balance calculations.
/// Automatically calculates previous year dates and displays comparative balance information.
/// Used for year-over-year financial analysis, trend reporting, and comparative financial statement preparation.
/// </remarks>
report 7 "Trial Balance/Previous Year"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/GeneralLedger/Reports/TrialBalancePreviousYear.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Trial Balance/Previous Year';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Account Type", "Date Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(LongTextLongText4; LongText[1] + LongText[2] + LongText[3] + LongText[4])
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(RoundingText; RoundingText)
            {
            }
            column(RoundingNo; RoundingNO)
            {
            }
            column(GLAccTableCaptFilter; TableCaption + ': ' + GLFilter)
            {
            }
            column(LongText; LongText1[1] + LongText1[2] + LongText1[3] + LongText1[4])
            {
            }
            column(SimulationGl; SimulationGlLbl)
            {
            }
            column(No_GLAcc; "No.")
            {
            }
            column(TrialBalancePreviousYearCaption; TrialBalancePreviousYearCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(NetChangeCaption; NetChangeCaptionLbl)
            {
            }
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(DebitNetChangeCaption; DebitNetChangeCaptionLbl)
            {
            }
            column(CreditNetChangeCaption; CreditNetChangeCaptionLbl)
            {
            }
            column(NetChangeIncreasePctCaption; NetChangeIncreasePctCaptionLbl)
            {
            }
            column(LastYearNetChangeCaption; LastYearNetChangeCaptionLbl)
            {
            }
            column(DebitBalanceCaption; DebitBalanceCaptionLbl)
            {
            }
            column(CreditBalanceCaption; CreditBalanceCaptionLbl)
            {
            }
            column(BalanceIncreasePctCaption; BalanceIncreasePctCaptionLbl)
            {
            }
            column(LastYearBalanceCaption; LastYearBalanceCaptionLbl)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(GLAccountNo1; "G/L Account"."No.")
                {
                    IncludeCaption = true;
                }
                column(AccIndentGLAccName; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(FiscalYearNetChange; FiscalYearNetChange)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(FiscalYearNetChange1; -FiscalYearNetChange)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(NetChangeIncreasePct; NetChangeIncreasePct)
                {
                    DecimalPlaces = 1 : 1;
                }
                column(LastYearNetChange; LastYearNetChange)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(FiscalYearBalance; FiscalYearBalance)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(FiscalYearBalance1; -FiscalYearBalance)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(BalanceIncreasePct; BalanceIncreasePct)
                {
                    DecimalPlaces = 1 : 1;
                }
                column(LastYearBalance; LastYearBalance)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(PageGroupNo; PageGroupNo)
                {
                }
                column(Type_GLAcc; GLAccountType)
                {
                }
                column(NoOfBlankLines_GLAcc; "G/L Account"."No. of Blank Lines")
                {
                }
                column(AccountType_GLAcc; "G/L Account"."Account Type")
                {
                }
                dataitem(BlankLineRepeater; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(BlankLineNo; BlankLineNo)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if BlankLineNo = 0 then
                            CurrReport.Break();

                        BlankLineNo -= 1;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    BlankLineNo := "G/L Account"."No. of Blank Lines" + 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                RoundingNO := Rounding;
                RoundingText := ReportMgmnt.RoundDescription(Rounding);
                ReqFormDateFilter := GetFilter("Date Filter");

                SetRange("Date Filter", FiscalYearStartDate, FiscalYearEndDate);
                CalcFields("Net Change", "Balance at Date");
                "Net Change" := ReportMgmnt.RoundAmount("Net Change", Rounding);
                "Balance at Date" := ReportMgmnt.RoundAmount("Balance at Date", Rounding);
                FiscalYearBalance := "Balance at Date";
                FiscalYearNetChange := "Net Change";
                SetRange("Date Filter", LastYearStartDate, LastYearEndDate);
                CalcFields("Net Change", "Balance at Date");
                "Net Change" := ReportMgmnt.RoundAmount("Net Change", Rounding);
                "Balance at Date" := ReportMgmnt.RoundAmount("Balance at Date", Rounding);
                LastYearBalance := "Balance at Date";
                LastYearNetChange := "Net Change";
                if LastYearNetChange <> 0 then
                    NetChangeIncreasePct := Round(FiscalYearNetChange / LastYearNetChange * 100, 0.1)
                else
                    NetChangeIncreasePct := 0;

                if LastYearBalance <> 0 then
                    BalanceIncreasePct := Round(FiscalYearBalance / LastYearBalance * 100, 0.1)
                else
                    BalanceIncreasePct := 0;

                SetFilter("Date Filter", ReqFormDateFilter);

                LongText1[1] :=
                  StrSubstNo(
                    Text001,
                    FiscalYearStartDate, FiscalYearEndDate, LastYearStartDate, LastYearEndDate);
                LongText1[2] := '';
                LongText1[3] := '';
                LongText1[4] := '';

                GLAccountType := "Account Type".AsInteger();

                if IsNewPage then begin
                    PageGroupNo := PageGroupNo + 1;
                    IsNewPage := false;
                end;
                if "New Page" then
                    IsNewPage := true;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
            end;
        }
    }

    requestpage
    {

        AboutTitle = 'About Trial Balance/Previous Year';
        AboutText = 'View a snapshot of your chart of accounts to check the debit and credit net change and closing balance compared to the same period last year. Shows the percentage of actual vs. last year.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AmountsInWhole; Rounding)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amounts in whole';
                        ToolTip = 'Specifies if the amounts in the report are shown in whole 1000s.';
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
        FiscalYearStartDate := "G/L Account".GetRangeMin("Date Filter");
        FiscalYearEndDate := "G/L Account".GetRangeMax("Date Filter");
        LastYearStartDate := CalcDate('<-1Y>', NormalDate(FiscalYearStartDate) + 1) - 1;
        LastYearEndDate := CalcDate('<-1Y>', NormalDate(FiscalYearEndDate) + 1) - 1;
        if FiscalYearStartDate <> NormalDate(FiscalYearStartDate) then
            LastYearStartDate := ClosingDate(LastYearStartDate);
        if FiscalYearEndDate <> NormalDate(FiscalYearEndDate) then
            LastYearEndDate := ClosingDate(LastYearEndDate);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Period: %1..%2 versus %3..%4';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ReportMgmnt: Codeunit "Report Management APAC";
        NetChangeIncreasePct: Decimal;
        BalanceIncreasePct: Decimal;
        LongText: array[4] of Text[132];
        LongText1: array[4] of Text[132];
        ReqFormDateFilter: Text[250];
        PageGroupNo: Integer;
        GLAccountType: Integer;
        IsNewPage: Boolean;
        Rounding: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
        RoundingText: Text[50];
        RoundingNO: Integer;
        SimulationGlLbl: Label 'These report include simulation''s G/L.';
        TrialBalancePreviousYearCaptionLbl: Label 'Trial Balance/Previous Year';
        PageCaptionLbl: Label 'Page';
        NetChangeCaptionLbl: Label 'Net Change';
        BalanceCaptionLbl: Label 'Balance';
        NameCaptionLbl: Label 'Name';
        DebitNetChangeCaptionLbl: Label 'Debit';
        CreditNetChangeCaptionLbl: Label 'Credit';
        NetChangeIncreasePctCaptionLbl: Label '% of';
        LastYearNetChangeCaptionLbl: Label 'Last Year';
        DebitBalanceCaptionLbl: Label 'Debit';
        CreditBalanceCaptionLbl: Label 'Credit';
        BalanceIncreasePctCaptionLbl: Label '% of';
        LastYearBalanceCaptionLbl: Label 'Last Year';
        BlankLineNo: Integer;

    protected var
        GLFilter: Text;
        LastYearNetChange: Decimal;
        LastYearBalance: Decimal;
        LastYearStartDate: Date;
        LastYearEndDate: Date;
        FiscalYearNetChange: Decimal;
        FiscalYearBalance: Decimal;
        FiscalYearStartDate: Date;
        FiscalYearEndDate: Date;
}

