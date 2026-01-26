// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.Address;

/// <summary>
/// Generates comprehensive list of bank accounts with balance and contact information.
/// Displays bank account details, balances, address information, and account settings.
/// </summary>
/// <remarks>
/// Data Sources: Bank Account. 
/// Features: Address formatting, currency balance options, contact details, account configuration display.
/// Usage: Bank account directory, account overview reporting, balance verification, setup documentation.
/// </remarks>
report 1402 "Bank Account - List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Bank/Reports/BankAccountList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Account - List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {
            RequestFilterFields = "No.", "Search Name", "Bank Acc. Posting Group", "Currency Code";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PrintAmountsInLCY; PrintAmountsInLCY)
            {
            }
            column(BankAccountCaption; "Bank Account".TableCaption + ': ' + BankAccFilter)
            {
            }
            column(BankAccFilter; BankAccFilter)
            {
            }
            column(No_BankAccount; "No.")
            {
                IncludeCaption = true;
            }
            column(BankAccPostingGr_BankAcc; "Bank Acc. Posting Group")
            {
            }
            column(OurContactCode_BankAcc; "Our Contact Code")
            {
                IncludeCaption = true;
            }
            column(CurrencyCode_BankAcc; "Currency Code")
            {
                IncludeCaption = true;
            }
            column(MinBalance_BankAcc; "Min. Balance")
            {
                DecimalPlaces = 0 : 0;
                IncludeCaption = true;
            }
            column(BankAccBalance; BankAccBalance)
            {
                AutoFormatExpression = "Currency Code";
                AutoFormatType = 1;
            }
            column(BankAccAddr1; BankAccAddr[1])
            {
            }
            column(BankAccAddr2; BankAccAddr[2])
            {
            }
            column(BankAccAddr3; BankAccAddr[3])
            {
            }
            column(BankAccAddr4; BankAccAddr[4])
            {
            }
            column(BankAccAddr5; BankAccAddr[5])
            {
            }
            column(Contact_BankAccount; Contact)
            {
                IncludeCaption = true;
            }
            column(PhoneNo_BankAccount; "Phone No.")
            {
                IncludeCaption = true;
            }
            column(BankAccAddr6; BankAccAddr[6])
            {
            }
            column(BankAccAddr7; BankAccAddr[7])
            {
            }
            column(LastCheckNo_BankAccount; "Last Check No.")
            {
                IncludeCaption = true;
            }
            column(BalLastStatement_BankAcc; "Balance Last Statement")
            {
                IncludeCaption = true;
            }
            column(BankAccNoCCCBankAccNo_BankAcc; "Bank Account No." + "CCC Bank Account No.")
            {
            }
            column(BalanceLCY_BankAcc; "Balance (LCY)")
            {
            }
            column(BankAccountListCaption; BankAccountListCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(ThebalanceisinLCYCaption; ThebalanceisinLCYCaptionLbl)
            {
            }
            column(BankAccBankAccPostGrCptn; BankAccBankAccPostGrCptnLbl)
            {
            }
            column(BankAccBalanceCaption; BankAccBalanceCaptionLbl)
            {
            }
            column(BankAccBankAccNoCaption; BankAccBankAccNoCaptionLbl)
            {
            }
            column(TotalLCYCaption; TotalLCYCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields(Balance, "Balance (LCY)");
                if PrintAmountsInLCY then
                    BankAccBalance := "Balance (LCY)"
                else
                    BankAccBalance := Balance;
                FormatAddr.FormatAddr(
                  BankAccAddr, Name, "Name 2", '', Address, "Address 2",
                  City, "Post Code", County, "Country/Region Code");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintAmountsInLCY; PrintAmountsInLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Balance in LCY';
                        ToolTip = 'Specifies if the reported balance is shown in the local currency.';
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
        BankAccFilter := "Bank Account".GetFilters();
    end;

    var
        FormatAddr: Codeunit "Format Address";
        PrintAmountsInLCY: Boolean;
        BankAccFilter: Text;
        BankAccBalance: Decimal;
        BankAccAddr: array[8] of Text[100];
        BankAccountListCaptionLbl: Label 'Bank Account - List';
        CurrReportPageNoCaptionLbl: Label 'Page';
        ThebalanceisinLCYCaptionLbl: Label 'The balance is in LCY.';
        BankAccBankAccPostGrCptnLbl: Label 'Bank Acc. Posting Group';
        BankAccBalanceCaptionLbl: Label 'Balance';
        BankAccBankAccNoCaptionLbl: Label 'Bank Account No.';
        TotalLCYCaptionLbl: Label 'Total (LCY)';
}

