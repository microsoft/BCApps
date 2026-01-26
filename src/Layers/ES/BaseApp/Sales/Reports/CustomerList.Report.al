// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Foundation.Address;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;

report 101 "Customer - List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Customer List';
    DefaultRenderingLayout = "CustomerList.rdlc";
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "No.", "Search Name", "Customer Posting Group";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Customer_TABLECAPTION__________CustFilter; TableCaption + ': ' + CustFilter)
            {
            }
            column(CustFilter; CustFilter)
            {
            }
            column(Customer__No__; "No.")
            {
            }
            column(Customer__Customer_Posting_Group_; "Customer Posting Group")
            {
            }
            column(Customer__Customer_Disc__Group_; "Customer Disc. Group")
            {
            }
            column(Customer__Invoice_Disc__Code_; "Invoice Disc. Code")
            {
            }
            column(Customer__Customer_Price_Group_; "Customer Price Group")
            {
            }
            column(Customer__Fin__Charge_Terms_Code_; "Payment Method Code")
            {
            }
            column(Customer__Payment_Terms_Code_; "Payment Terms Code")
            {
            }
            column(Customer__Salesperson_Code_; "Salesperson Code")
            {
            }
            column(Customer__Currency_Code_; "Currency Code")
            {
            }
            column(Customer__Credit_Limit__LCY__; "Credit Limit (LCY)")
            {
                DecimalPlaces = 0 : 0;
            }
            column(Customer__Balance__LCY__; "Balance (LCY)")
            {
            }
            column(CustAddr_1_; CustAddr[1])
            {
            }
            column(CustAddr_2_; CustAddr[2])
            {
            }
            column(CustAddr_3_; CustAddr[3])
            {
            }
            column(CustAddr_4_; CustAddr[4])
            {
            }
            column(CustAddr_5_; CustAddr[5])
            {
            }
            column(Customer_Contact; Contact)
            {
            }
            column(Customer__Phone_No__; "Phone No.")
            {
            }
            column(CustAddr_6_; CustAddr[6])
            {
            }
            column(CustAddr_7_; CustAddr[7])
            {
            }
            column(Customer___ListCaption; Customer___ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Customer__No__Caption; FieldCaption("No."))
            {
            }
            column(Customer__Customer_Posting_Group_Caption; Customer__Customer_Posting_Group_CaptionLbl)
            {
            }
            column(Customer__Customer_Disc__Group_Caption; Customer__Customer_Disc__Group_CaptionLbl)
            {
            }
            column(Customer__Invoice_Disc__Code_Caption; Customer__Invoice_Disc__Code_CaptionLbl)
            {
            }
            column(Customer__Customer_Price_Group_Caption; Customer__Customer_Price_Group_CaptionLbl)
            {
            }
            column(Customer__Fin__Charge_Terms_Code_Caption; FieldCaption("Payment Method Code"))
            {
            }
            column(Customer__Payment_Terms_Code_Caption; Customer__Payment_Terms_Code_CaptionLbl)
            {
            }
            column(Customer__Salesperson_Code_Caption; FieldCaption("Salesperson Code"))
            {
            }
            column(Customer__Currency_Code_Caption; Customer__Currency_Code_CaptionLbl)
            {
            }
            column(Customer__Credit_Limit__LCY__Caption; FieldCaption("Credit Limit (LCY)"))
            {
            }
            column(Customer__Balance__LCY__Caption; FieldCaption("Balance (LCY)"))
            {
            }
            column(Customer_ContactCaption; FieldCaption(Contact))
            {
            }
            column(Customer__Phone_No__Caption; FieldCaption("Phone No."))
            {
            }
            column(Total__LCY_Caption; Total__LCY_CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Balance (LCY)");
                FormatAddr.FormatAddr(
                  CustAddr, Name, "Name 2", '', Address, "Address 2",
                  City, "Post Code", County, "Country/Region Code");
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Customer List';
        AboutText = 'Get an overview of basic information for your customers.';
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    rendering
    {
        layout("CustomerList.rdlc")
        {
            Type = RDLC;
            LayoutFile = './Sales/Reports/CustomerList.rdlc';
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        CustFilter := FormatDocument.GetRecordFiltersWithCaptions(Customer);
    end;

    var
        FormatAddr: Codeunit "Format Address";
        CustFilter: Text;
        CustAddr: array[8] of Text[100];
        Customer___ListCaptionLbl: Label 'Customer - List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Customer__Customer_Posting_Group_CaptionLbl: Label 'Customer Posting Group';
        Customer__Customer_Disc__Group_CaptionLbl: Label 'Cust./Item Disc. Gr.';
        Customer__Invoice_Disc__Code_CaptionLbl: Label 'Invoice Disc. Code';
        Customer__Customer_Price_Group_CaptionLbl: Label 'Price Group Code';
        Customer__Payment_Terms_Code_CaptionLbl: Label 'Payment Terms Code';
        Customer__Currency_Code_CaptionLbl: Label 'Currency Code';
        Total__LCY_CaptionLbl: Label 'Total (LCY)';
}

