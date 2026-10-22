// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

#if not CLEAN30
using Microsoft.Finance.FinancialReports;
#endif
using Microsoft.Finance.GeneralLedger.Account;
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
    ApplicationArea = Basic, Suite;
    Caption = 'Trial Balance/Previous Year';
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = RDLCLayout;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Account Type", "Date Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
#if not CLEAN30
            column(GLFilter_GLAccount; "G/L Account".TableCaption + ': ' + GLFilter)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to the French financial reporting capability in the Reports FR app.';
                ObsoleteTag = '30.0';
            }
            column(GLFilter; GLFilter)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to the French financial reporting capability in the Reports FR app.';
                ObsoleteTag = '30.0';
            }
            column(Period; LongText1[1] + LongText1[2] + LongText1[3] + LongText1[4])
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to the French financial reporting capability in the Reports FR app.';
                ObsoleteTag = '30.0';
            }
            column(EmptyString; '')
            {
            }
            column(No_GLAccount; "No.")
            {
            }
            column(TrialBalancePreviousYearCaption; TrialBalancePreviousYearCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to the French financial reporting capability in the Reports FR app.';
                ObsoleteTag = '30.0';
            }
            column(NetChangeCaption; NetChangeCaptionLbl)
            {
            }
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            column(PADSTRGLAccountIndentation2GLAccountNameCaption; PADSTRGLAccountIndentation2GLAccountNameCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to the French financial reporting capability in the Reports FR app.';
                ObsoleteTag = '30.0';
            }
            column(FiscalYearDebitChangeCaption; FiscalYearDebitChangeCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to the French financial reporting capability in the Reports FR app.';
                ObsoleteTag = '30.0';
            }
            column(FiscalYearCreditChangeCaption; FiscalYearCreditChangeCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to the French financial reporting capability in the Reports FR app.';
                ObsoleteTag = '30.0';
            }
            column(NetChangeIncreasePctCaption; NetChangeIncreasePctCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to the French financial reporting capability in the Reports FR app.';
                ObsoleteTag = '30.0';
            }
            column(LastYearNetChangeCaption; LastYearNetChangeCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to the French financial reporting capability in the Reports FR app.';
                ObsoleteTag = '30.0';
            }
#else
            column(GLAccTableCaptionGLFilter; TableCaption + ': ' + GLFilter)
            {
            }
            column(LongText; LongText1[1] + LongText1[2] + LongText1[3] + LongText1[4])
            {
            }
            column(EmptyString; '')
            {
            }
            column(TrialBalancePreviousYearCaption; TrialBalancePreviousYearCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
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
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(PercentCaption; PercentCaptionLbl)
            {
            }
            column(LastYearCaption; LastYearCaptionLbl)
            {
            }
#endif
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
#if not CLEAN30
                column(No1_GLAccount; "G/L Account"."No.")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to the French financial reporting capability in the Reports FR app.';
                    ObsoleteTag = '30.0';
                    IncludeCaption = true;
                }
                column(GLAccountNameIndented; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to the French financial reporting capability in the Reports FR app.';
                    ObsoleteTag = '30.0';
                }
                column(FiscalYearNetChange; GetFiscalYearNetChange())
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(FiscalYearCreditChange; FiscalYearCreditChange)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to the French financial reporting capability in the Reports FR app.';
                    ObsoleteTag = '30.0';
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
#else
                column(No_GLAccount; "G/L Account"."No.")
                {
                    IncludeCaption = true;
                }
                column(GLAccIndentationGLAccName; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(FiscalYearNetChange; FiscalYearNetChange)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(NegFiscalYearNetChange; -FiscalYearNetChange)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
#endif
                column(NetChangeIncreasePct; NetChangeIncreasePct)
                {
                    DecimalPlaces = 1 : 1;
                }
                column(LastYearNetChange; LastYearNetChange)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
#if not CLEAN30
                column(FiscalYearDebitBalance; FiscalYearDebitBalance)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to the French financial reporting capability in the Reports FR app.';
                    ObsoleteTag = '30.0';
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(FiscalYearCreditBalance; FiscalYearCreditBalance)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to the French financial reporting capability in the Reports FR app.';
                    ObsoleteTag = '30.0';
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
#else
                column(FiscalYearBalance; FiscalYearBalance)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(NegFiscalYearBalance; -FiscalYearBalance)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
#endif
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
                column(GLAccountType; GLAccountType)
                {
                }
#if not CLEAN30
                column(NoofBlankLines_GLAccount; "G/L Account"."No. of Blank Lines")
                {
                }
#endif
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
                ReqFormDateFilter := GetFilter("Date Filter");

#if not CLEAN30
                SetFilter("Date Filter", '<=%1', FiscalYearEndDate);
                CalcFields("Debit Amount", "Credit Amount");
                FiscalYearDebitBalance := "Debit Amount";
                FiscalYearCreditBalance := "Credit Amount";
#endif
                SetRange("Date Filter", FiscalYearStartDate, FiscalYearEndDate);
#if not CLEAN30
                CalcFields("Debit Amount", "Credit Amount", "Net Change", "Balance at Date");
#else
                CalcFields("Net Change", "Balance at Date");
#endif
                FiscalYearBalance := "Balance at Date";
                FiscalYearNetChange := "Net Change";
#if not CLEAN30
                FiscalYearDebitChange := "Debit Amount";
                FiscalYearCreditChange := "Credit Amount";
#endif
                SetRange("Date Filter", LastYearStartDate, LastYearEndDate);
#if not CLEAN30
                CalcFields("Debit Amount", "Credit Amount", "Net Change", "Balance at Date");
#else
                CalcFields("Net Change", "Balance at Date");
#endif
                LastYearBalance := "Balance at Date";
                LastYearNetChange := "Net Change";
#if not CLEAN30
                LastYearDebitChange := "Debit Amount";
                LastYearCreditChange := "Credit Amount";
#endif
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
        }

        actions
        {
        }
    }

    rendering
    {
        layout(RDLCLayout)
        {
            Type = RDLC;
#if not CLEAN30
            LayoutFile = './Finance/GeneralLedger/Reports/TrialBalancePreviousYear.rdlc';
#else
            LayoutFile = './Finance/GeneralLedger/Reports/TrialBalancePreviousYearW1.rdlc';
#endif
            Summary = 'Report layout made in the legacy RDLC format. Use an RDLC editor to modify the layout.';
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        "G/L Account".SecurityFiltering(SecurityFilter::Filtered);
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
        NetChangeIncreasePct: Decimal;
        BalanceIncreasePct: Decimal;
        LongText1: array[4] of Text[132];
        ReqFormDateFilter: Text[250];
        PageGroupNo: Integer;
        GLAccountType: Integer;
        IsNewPage: Boolean;
#if not CLEAN30
        FiscalYearDebitChange: Decimal;
        FiscalYearCreditChange: Decimal;
        FiscalYearDebitBalance: Decimal;
        FiscalYearCreditBalance: Decimal;
        LastYearDebitChange: Decimal;
        LastYearCreditChange: Decimal;
#endif
        TrialBalancePreviousYearCaptionLbl: Label 'Trial Balance/Previous Year';
#if not CLEAN30
        CurrReportPageNoCaptionLbl: Label 'Page';
#else
        PageNoCaptionLbl: Label 'Page';
#endif
        NetChangeCaptionLbl: Label 'Net Change';
        BalanceCaptionLbl: Label 'Balance';
#if not CLEAN30
        PADSTRGLAccountIndentation2GLAccountNameCaptionLbl: Label 'Name';
        FiscalYearDebitChangeCaptionLbl: Label 'Debit';
        FiscalYearCreditChangeCaptionLbl: Label 'Credit';
        NetChangeIncreasePctCaptionLbl: Label '% of';
        LastYearNetChangeCaptionLbl: Label 'Last Year';
#else
        NameCaptionLbl: Label 'Name';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        PercentCaptionLbl: Label '% of';
        LastYearCaptionLbl: Label 'Last Year';
#endif
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

#if not CLEAN30
    local procedure GetFiscalYearNetChange(): Decimal
    var
        FinancialScheduleMgt: Codeunit "FR AccSchedManagement";
    begin
        if FinancialScheduleMgt.IsReportsFREnabled() then
            exit(FiscalYearNetChange);
        exit(FiscalYearDebitChange);
    end;
#endif
}
