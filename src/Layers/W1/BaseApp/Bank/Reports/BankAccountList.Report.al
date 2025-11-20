// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.Address;

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
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PrintAmountsInLCY; PrintAmountsInLCY)
            {
            }
            column(Bank_Account__TABLECAPTION__________BankAccFilter; TableCaption + ': ' + BankAccFilter)
            {
            }
            column(BankAccFilter; BankAccFilter)
            {
            }
            column(Bank_Account__No__; "No.")
            {
            }
            column(Bank_Account__Bank_Acc__Posting_Group_; "Bank Acc. Posting Group")
            {
            }
            column(Bank_Account__Our_Contact_Code_; "Our Contact Code")
            {
            }
            column(Bank_Account__Currency_Code_; "Currency Code")
            {
            }
            column(Bank_Account__Min__Balance_; "Min. Balance")
            {
                DecimalPlaces = 0 : 0;
            }
            column(BankAccBalance; BankAccBalance)
            {
                AutoFormatExpression = "Currency Code";
                AutoFormatType = 1;
            }
            column(BankAccAddr_1_; BankAccAddr[1])
            {
            }
            column(BankAccAddr_2_; BankAccAddr[2])
            {
            }
            column(BankAccAddr_3_; BankAccAddr[3])
            {
            }
            column(BankAccAddr_4_; BankAccAddr[4])
            {
            }
            column(BankAccAddr_5_; BankAccAddr[5])
            {
            }
            column(Bank_Account_Contact; Contact)
            {
            }
            column(Bank_Account__Phone_No__; "Phone No.")
            {
            }
            column(BankAccAddr_6_; BankAccAddr[6])
            {
            }
            column(BankAccAddr_7_; BankAccAddr[7])
            {
            }
            column(Bank_Account__Last_Check_No__; "Last Check No.")
            {
            }
            column(Bank_Account__Balance_Last_Statement_; "Balance Last Statement")
            {
            }
            column(Bank_Account__Bank_Account_No__; "Bank Account No.")
            {
            }
            column(Bank_Account__Balance__LCY__; "Balance (LCY)")
            {
            }
            column(Bank_Account___ListCaption; Bank_Account___ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(The_balance_is_in_LCY_Caption; The_balance_is_in_LCY_CaptionLbl)
            {
            }
            column(Bank_Account__No__Caption; FieldCaption("No."))
            {
            }
            column(Bank_Account__Bank_Acc__Posting_Group_Caption; Bank_Account__Bank_Acc__Posting_Group_CaptionLbl)
            {
            }
            column(Bank_Account__Our_Contact_Code_Caption; FieldCaption("Our Contact Code"))
            {
            }
            column(Bank_Account__Currency_Code_Caption; Bank_Account__Currency_Code_CaptionLbl)
            {
            }
            column(Bank_Account__Min__Balance_Caption; Bank_Account__Min__Balance_CaptionLbl)
            {
            }
            column(BankAccBalanceCaption; BankAccBalanceCaptionLbl)
            {
            }
            column(Bank_Account__Last_Check_No__Caption; FieldCaption("Last Check No."))
            {
            }
            column(Bank_Account__Balance_Last_Statement_Caption; FieldCaption("Balance Last Statement"))
            {
            }
            column(Bank_Account__Bank_Account_No__Caption; FieldCaption("Bank Account No."))
            {
            }
            column(Bank_Account_ContactCaption; FieldCaption(Contact))
            {
            }
            column(Bank_Account__Phone_No__Caption; FieldCaption("Phone No."))
            {
            }
            column(Total__LCY_Caption; Total__LCY_CaptionLbl)
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
        Bank_Account___ListCaptionLbl: Label 'Bank Account - List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        The_balance_is_in_LCY_CaptionLbl: Label 'The balance is in LCY.';
        Bank_Account__Bank_Acc__Posting_Group_CaptionLbl: Label 'Bank Acc. Posting Group';
        Bank_Account__Currency_Code_CaptionLbl: Label 'Currency Code';
        Bank_Account__Min__Balance_CaptionLbl: Label 'Min. Balance';
        BankAccBalanceCaptionLbl: Label 'Balance';
        Total__LCY_CaptionLbl: Label 'Total (LCY)';
}

