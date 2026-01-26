// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Sales.Customer;

report 3010837 "LSV Customerbank List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/LSVCustomerbankList.rdlc';
    Caption = 'LSV Customerbank List';

    dataset
    {
        dataitem("Customer Bank Account"; "Customer Bank Account")
        {
            RequestFilterFields = "Customer No.", "Code", "Currency Code";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CustNo_CustBankAcct; "Customer No.")
            {
            }
            column(Code_CustBankAcct; Code)
            {
            }
            column(Name_CustBankAcct; Name)
            {
            }
            column(PostCode_CustBankAcct; "Post Code")
            {
            }
            column(City_CustBankAcct; City)
            {
            }
            column(BankBranchNo_CustBankAcct; "Bank Branch No.")
            {
            }
            column(BankAccountNo_CustBankAcct; "Bank Account No.")
            {
            }
            column(Name_Cust; Customer.Name)
            {
            }
            column(GiroAccountNo_CustBankAcct; "Giro Account No.")
            {
            }
            column(LSVCustomerBankListCaption; LSVCustomerBankListCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(NameCaption_CustBankAcct; FieldCaption(Name))
            {
            }
            column(PostCodeCaption_CustBankAcct; FieldCaption("Post Code"))
            {
            }
            column(CityCaption_CustBankAcct; FieldCaption(City))
            {
            }
            column(ClearingCaption; ClearingCaptionLbl)
            {
            }
            column(BankAcctNoCaption_CustBankAcct; FieldCaption("Bank Account No."))
            {
            }
            column(CustNoCaption_CustBankAcct; FieldCaption("Customer No."))
            {
            }
            column(BankCodeCaption; BankCodeCaptionLbl)
            {
            }
            column(CustNameCaption; CustNameCaptionLbl)
            {
            }
            column(GiroAcctNoCaption_CustBankAcct; FieldCaption("Giro Account No."))
            {
            }

            trigger OnAfterGetRecord()
            begin
                if not Customer.Get("Customer No.") then
                    Clear(Customer);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Customer: Record Customer;
        LSVCustomerBankListCaptionLbl: Label 'LSV Customerbank List';
        PageNoCaptionLbl: Label 'Page';
        ClearingCaptionLbl: Label 'Clearing';
        BankCodeCaptionLbl: Label 'Bank Code';
        CustNameCaptionLbl: Label 'Customer Name';
}

