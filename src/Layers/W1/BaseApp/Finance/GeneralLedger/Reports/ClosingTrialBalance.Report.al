// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using System.Utilities;

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
            column(GLAccGLFilter; TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(UseAmtsInAddCurr; UseAmtsInAddCurr)
            {
            }
            column(AllAmountsIn; AllAmountsInLbl)
            {
            }
            column(LCYcode; GLSetup."LCY Code")
            {
            }
            column(AddreportingCurrency; GLSetup."Additional Reporting Currency")
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(No_GLAccount; "G/L Account"."No.")
                {
                    IncludeCaption = true;
                }
                column(GLAccName; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
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
                column(NegLastYearBalance; -LastYearBalance)
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(NoBlankLines_GLAccount; "G/L Account"."No. of Blank Lines")
                {
                }
                column(AccountType_GLAccount; "G/L Account"."Account Type")
                {
                }
                column(AccountTypePosting; GLAccountTypePosting)
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
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
        ClosingTrialBalanceCaption = 'Closing Trial Balance';
        PageNoCaption = 'Page';
        ThisYearCaption = 'This Year';
        LastYearCaption = 'Last Year';
        NameCaption = 'Name';
        DebitCaption = 'Debit';
        CreditCaption = 'Credit';
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
        FiscalYearStartDate: Date;
        FiscalYearEndDate: Date;
        PeriodText: Text;
        GLFilter: Text;
        FiscalYearBalance: Decimal;
        LastYearBalance: Decimal;
        UseAmtsInAddCurr: Boolean;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        AllAmountsInLbl: Label 'All amounts are in';
        GLAccountTypePosting: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Enter the starting date for the fiscal year.';
#pragma warning disable AA0470
        Text001: Label 'Period: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure GetCurrency(): Code[10]
    begin
        if UseAmtsInAddCurr then
            exit(GLSetup."Additional Reporting Currency");

        exit('');
    end;

    procedure InitializeRequest(NewFiscalYearStartDate: Date; NewUseAmtsInAddCurr: Boolean)
    begin
        FiscalYearStartDate := NewFiscalYearStartDate;
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
    end;
}

