// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Sales.Customer;

report 10045 "Customer Listing"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CustomerListing.rdlc';
    ApplicationArea = Basic, Suite, Advanced;
    Caption = 'Customer Listing';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "No.", "Search Name", "Customer Posting Group", "Currency Code", "Salesperson Code";
            column(Customer_Listing_; 'Customer Listing')
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(PrintAmountsInLocal; PrintAmountsInLocal)
            {
            }
            column(AllHavingBalance; AllHavingBalance)
            {
            }
            column(Customer_TABLECAPTION__________FilterString; Customer.TableCaption + ': ' + FilterString)
            {
            }
            column(FilterString_____; FilterString <> '')
            {
            }
            column(Customer__No__; "No.")
            {
            }
            column(Customer_Name; Name)
            {
            }
            column(Customer__Customer_Posting_Group_; "Customer Posting Group")
            {
            }
            column(Customer__Invoice_Disc__Code_; "Invoice Disc. Code")
            {
            }
            column(Customer__Customer_Price_Group_; "Customer Price Group")
            {
            }
            column(PaymentTerms__Due_Date_Calculation_; PaymentTerms."Due Date Calculation")
            {
            }
            column(Customer__Salesperson_Code_; "Salesperson Code")
            {
            }
            column(Customer__Credit_Limit__LCY__; "Credit Limit (LCY)")
            {
                DecimalPlaces = 2 : 2;
            }
            column(Customer_Blocked; Blocked)
            {
            }
            column(Customer__Name_2_; "Name 2")
            {
            }
            column(Name_2______; "Name 2" = '')
            {
            }
            column(Customer_Address; Address)
            {
            }
            column(Customer__Customer_Disc__Group_; "Customer Disc. Group")
            {
            }
            column(Customer__Tax_Area_Code_; "Tax Area Code")
            {
            }
            column(Customer__Fin__Charge_Terms_Code_; "Fin. Charge Terms Code")
            {
            }
            column(Customer__Currency_Code_; "Currency Code")
            {
            }
            column(Customer__Balance__LCY__; "Balance (LCY)")
            {
            }
            column(Customer_Comment; Format(Comment))
            {
            }
            column(Customer__Address_2_; "Address 2")
            {
            }
            column(Address_2______; "Address 2" = '')
            {
            }
            column(Address3; Address3)
            {
            }
            column(OverLimitMsg; OverLimitMsg)
            {
            }
            column(NOT__Address3_______OR_NOT__OverLimitMsg______; not (Address3 = '') or not (OverLimitMsg = ''))
            {
            }
            column(Customer_Contact; Contact)
            {
            }
            column(Contact______; Contact <> '')
            {
            }
            column(Customer__Phone_No__; "Phone No.")
            {
            }
            column(Phone_No________; "Phone No." <> '')
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Amounts_are_in_customer_s_local_currency_Caption; Amounts_are_in_customer_s_local_currency_CaptionLbl)
            {
            }
            column(Control9Caption; CaptionClassTranslate('101,1,' + Text000))
            {
            }
            column(Customers_without_balances_are_not_listed_Caption; Customers_without_balances_are_not_listed_CaptionLbl)
            {
            }
            column(Name_and_AddressCaption; Name_and_AddressCaptionLbl)
            {
            }
            column(Customer__Customer_Posting_Group_Caption; FieldCaption("Customer Posting Group"))
            {
            }
            column(Customer_CommentCaption; Customer_CommentCaptionLbl)
            {
            }
            column(Customer__Invoice_Disc__Code_Caption; Customer__Invoice_Disc__Code_CaptionLbl)
            {
            }
            column(Customer__Customer_Price_Group_Caption; FieldCaption("Customer Price Group"))
            {
            }
            column(PaymentTerms__Due_Date_Calculation_Caption; PaymentTerms__Due_Date_Calculation_CaptionLbl)
            {
            }
            column(Customer__Salesperson_Code_Caption; FieldCaption("Salesperson Code"))
            {
            }
            column(Customer__Credit_Limit__LCY__Caption; FieldCaption("Credit Limit (LCY)"))
            {
            }
            column(Customer__No__Caption; FieldCaption("No."))
            {
            }
            column(Contact_and_Phone_NumberCaption; Contact_and_Phone_NumberCaptionLbl)
            {
            }
            column(Customer_BlockedCaption; FieldCaption(Blocked))
            {
            }
            column(Customer__Tax_Area_Code_Caption; FieldCaption("Tax Area Code"))
            {
            }
            column(Customer__Fin__Charge_Terms_Code_Caption; Customer__Fin__Charge_Terms_Code_CaptionLbl)
            {
            }
            column(Customer__Currency_Code_Caption; FieldCaption("Currency Code"))
            {
            }
            column(Customer__Balance__LCY__Caption; FieldCaption("Balance (LCY)"))
            {
            }
            column(Customer__Customer_Disc__Group_Caption; Customer__Customer_Disc__Group_CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if "Payment Terms Code" <> '' then
                    PaymentTerms.Get("Payment Terms Code")
                else
                    Clear(PaymentTerms);

                CalcFields("Balance (LCY)", Comment);
                if AllHavingBalance and ("Balance (LCY)" = 0) then
                    CurrReport.Skip();

                if ("Credit Limit (LCY)" <> 0) and ("Balance (LCY)" > "Credit Limit (LCY)") then
                    OverLimitMsg := '*** Over Limit ***'
                else
                    OverLimitMsg := '';

                if (City <> '') and (County <> '') then
                    Address3 := CopyStr(City + ', ' + County + '  ' + "Post Code", 1, MaxStrLen(Address3))
                else
                    Address3 := CopyStr(DelChr(City + ' ' + County + ' ' + "Post Code", '<>'), 1, MaxStrLen(Address3));
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
                    field(CustWithBalancesOnly; AllHavingBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cust. with Balances Only';
                        ToolTip = 'Specifies that only customers with outstanding balances are shown.';
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
        CompanyInformation.Get();
        FilterString := Customer.GetFilters();
        PrintAmountsInLocal := false;  // until FlowFields work for this
    end;

    var
        PrintAmountsInLocal: Boolean;
        AllHavingBalance: Boolean;
        FilterString: Text;
        OverLimitMsg: Text[18];
        Address3: Text[80];
        PaymentTerms: Record "Payment Terms";
        CompanyInformation: Record "Company Information";
        Text000: Label 'All amounts are in %1.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Amounts_are_in_customer_s_local_currency_CaptionLbl: Label 'Amounts are in customer''s local currency.';
        Customers_without_balances_are_not_listed_CaptionLbl: Label 'Customers without balances are not listed.';
        Name_and_AddressCaptionLbl: Label 'Name and Address';
        Customer_CommentCaptionLbl: Label 'Comment';
        Customer__Invoice_Disc__Code_CaptionLbl: Label 'Discounts';
        PaymentTerms__Due_Date_Calculation_CaptionLbl: Label 'Terms';
        Contact_and_Phone_NumberCaptionLbl: Label 'Contact and Phone Number';
        Customer__Fin__Charge_Terms_Code_CaptionLbl: Label 'Fin Chrg';
        Customer__Customer_Disc__Group_CaptionLbl: Label 'Inv. / Item';
}

