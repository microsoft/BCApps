// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.Reporting;
using System.Utilities;

/// <summary>
/// Generates closing trial balance for fiscal year-end procedures and audit requirements.
/// Displays account balances as of fiscal year end with options for additional currency amounts and closing period analysis.
/// </summary>
/// <remarks>
/// Data source: G/L Account table with fiscal year-end date filtering and balance calculations.
/// Supports additional currency display option and comprehensive dimension filtering.
/// Used primarily for year-end closing procedures, audit trail documentation, and regulatory reporting requirements.
/// </remarks>
report 10 "Closing Trial Balance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/GeneralLedger/Reports/ClosingTrialBalance.rdlc';
    AdditionalSearchTerms = 'year closing balance,close accounting period balance,close fiscal year balance';
    ApplicationArea = Basic, Suite;
    Caption = 'Closing Trial Balance';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Account Type", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(PeriodText; StrSubstNo(Text001, PeriodText))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(HeaderText; HeaderText)
            {
            }
            column(Rounding; Rounding)
            {
            }
            column(ReptMgmntDescRounding; ReportMgmnt.RoundDescription(Rounding))
            {
            }
            column(RepIncSimulationEntries; RepIncSimulationEntriesLbl)
            {
            }
            column(GLAccTableCaptGLFilter; "G/L Account".TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(EmptyString; '')
            {
            }
            column(No_GLAccount; "No.")
            {
            }
            column(ClosingTrialBalCaption; ClosingTrialBalCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(ThisYearCaption; ThisYearCaptionLbl)
            {
            }
            column(LastYearCaption; LastYearCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(FiscalYearBalDebitCaption; FiscalYearBalDebitCaptionLbl)
            {
            }
            column(FiscalYearBalCreditCaption; FiscalYearBalCreditCaptionLbl)
            {
            }
            column(LastYearBalDebitCaption; LastYearBalDebitCaptionLbl)
            {
            }
            column(LastYearBalCreditCaption; LastYearBalCreditCaptionLbl)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(No1_GLAccount; "G/L Account"."No.")
                {
                    IncludeCaption = true;
                }
                column(PadstrGLAccAccName; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(FiscalYearBalance; FiscalYearBalance)
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(NegFiscalYearBalance; -FiscalYearBalance)
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(LastYearBalance; LastYearBalance)
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(LastYearBalance1; -LastYearBalance)
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(NoBlankLines; "G/L Account"."No. of Blank Lines")
                {
                }
                column(AccountType; "G/L Account"."Account Type")
                {
                }
                column(AccountTypePosting; GLAccountTypePosting)
                {
                }
                column(LCYcode; GLSetup."LCY Code")
                {
                }
                column(AddreportingCurrency; GLSetup."Additional Reporting Currency")
                {
                }
                column(AllAmtAreIn; AllAmtAreInLbl)
                {
                }
                column(UseAmtsInAddCurr; UseAmtsInAddCurr)
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

                if "Income/Balance" = "Income/Balance"::"Income Statement" then
                    SetRange("Date Filter", FiscalYearStartDate, FiscalYearEndDate)
                else
                    SetRange("Date Filter", 0D, ClosingDate(FiscalYearEndDate));
                CalcFields("Net Change", "Additional-Currency Net Change");
                if UseAmtsInAddCurr then
                    FiscalYearBalance := "Additional-Currency Net Change"
                else
                    FiscalYearBalance := "Net Change";
                if "Income/Balance" = "Income/Balance"::"Income Statement" then
                    SetRange("Date Filter", 0D, FiscalYearStartDate - 1)
                else
                    SetRange("Date Filter", 0D, ClosingDate(FiscalYearStartDate - 1));
                CalcFields("Net Change", "Additional-Currency Net Change");
                if UseAmtsInAddCurr then
                    LastYearBalance := "Additional-Currency Net Change"
                else
                    LastYearBalance := "Net Change";

                FiscalYearBalance := ReportMgmnt.RoundAmount(FiscalYearBalance, Rounding);
                LastYearBalance := ReportMgmnt.RoundAmount(LastYearBalance, Rounding);

                GLAccountTypePosting := "Account Type" = "Account Type"::Posting;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
                NextPageGroupNo := 1;
                GLSetup.Get();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'About Closing Trial Balance';
        AboutText = 'Report and verify your end of financial year figures, excluding closing entries, comparing this year to the previous year.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; FiscalYearStartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Fiscal Year Starting Date';
                        ToolTip = 'Specifies the last date in the closed trial balance. This date is used to determine the closing date.';
                    }
                    field(AmtsInAddCurr; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if the reported amounts are shown in the additional reporting currency.';
                    }
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

        if FiscalYearStartDate = 0D then
            Error(Text000);
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod."Starting Date" := FiscalYearStartDate;
        AccountingPeriod.Find();
        AccountingPeriod.Next(1);
        FiscalYearEndDate := AccountingPeriod."Starting Date" - 1;

        "G/L Account".SetRange("Date Filter", FiscalYearStartDate, FiscalYearEndDate);
        PeriodText := "G/L Account".GetFilter("Date Filter");
    end;

    var
        AccountingPeriod: Record "Accounting Period";
        GLSetup: Record "General Ledger Setup";
        ReportMgmnt: Codeunit "Report Management APAC";
        Rounding: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
        FiscalYearStartDate: Date;
        FiscalYearEndDate: Date;
        PeriodText: Text;
        GLFilter: Text;
        FiscalYearBalance: Decimal;
        LastYearBalance: Decimal;
        UseAmtsInAddCurr: Boolean;
        HeaderText: Text[50];
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;

#pragma warning disable AA0074
        Text000: Label 'Enter the starting date for the fiscal year.';
#pragma warning disable AA0470
        Text001: Label 'Period: %1';
        RepIncSimulationEntriesLbl: Label 'This report includes simulation entries.';
        ClosingTrialBalCaptionLbl: Label 'Closing Trial Balance';
        PageCaptionLbl: Label 'Page';
        ThisYearCaptionLbl: Label 'This Year';
        LastYearCaptionLbl: Label 'Last Year';
        NameCaptionLbl: Label 'Name';
        FiscalYearBalDebitCaptionLbl: Label 'Debit';
        FiscalYearBalCreditCaptionLbl: Label 'Credit';
        LastYearBalDebitCaptionLbl: Label 'Debit';
        LastYearBalCreditCaptionLbl: Label 'Credit';
        AllAmtAreInLbl: Label 'All amounts are in';
        GLAccountTypePosting: Boolean;
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure GetCurrency(): Code[10]
    begin
        if UseAmtsInAddCurr then
            exit(GLSetup."Additional Reporting Currency")
        else
            exit('');
    end;

    /// <summary>
    /// Initializes report parameters for programmatic execution with fiscal year and currency options.
    /// Sets fiscal year starting date and additional currency display option for automated closing trial balance generation.
    /// </summary>
    /// <param name="NewFiscalYearStartDate">Starting date of fiscal year for closing balance calculation</param>
    /// <param name="NewUseAmtsInAddCurr">Whether to display amounts in additional reporting currency</param>
    procedure InitializeRequest(NewFiscalYearStartDate: Date; NewUseAmtsInAddCurr: Boolean)
    begin
        FiscalYearStartDate := NewFiscalYearStartDate;
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
    end;
}

