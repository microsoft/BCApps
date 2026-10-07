// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Purchases.Vendor;
using System.Reflection;

report 10106 "Vendor - Listing"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/VendorListing.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor - Listing';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            RequestFilterFields = "No.", "Search Name", "Vendor Posting Group", Blocked, "Currency Code";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; TypeHelper.GetFormattedCurrentDateTimeInUserTimeZone('f'))
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(SubTitle; SubTitle)
            {
            }
            column(PrintAmountsInLocal; PrintAmountsInLocal)
            {
            }
            column(AllHavingBalance; AllHavingBalance)
            {
            }
            column(Vendor_TABLECAPTION__________VendFilter; Vendor.TableCaption + ': ' + VendFilter)
            {
            }
            column(VendFilter; VendFilter)
            {
            }
            column(Vendor__No__; "No.")
            {
            }
            column(Vendor__Vendor_Posting_Group_; "Vendor Posting Group")
            {
            }
            column(PaymentTerms__Due_Date_Calculation_; PaymentTerms."Due Date Calculation")
            {
            }
            column(VendBalance; VendBalance)
            {
            }
            column(Vendor__Invoice_Disc__Code_; "Invoice Disc. Code")
            {
            }
            column(Vendor__Purchaser_Code_; "Purchaser Code")
            {
            }
            column(Vendor_Name; Name)
            {
            }
            column(Vendor__Shipment_Method_Code_; "Shipment Method Code")
            {
            }
            column(Vendor_Blocked; Blocked)
            {
            }
            column(Vendor_City; City)
            {
            }
            column(Vendor_County; County)
            {
            }
            column(Vendor__Name_2_; "Name 2")
            {
            }
            column(Vendor_Address; Address)
            {
            }
            column(Vendor__Tax_Area_Code_; "Tax Area Code")
            {
            }
            column(Vendor__Fin__Charge_Terms_Code_; "Fin. Charge Terms Code")
            {
            }
            column(Vendor__Currency_Code_; "Currency Code")
            {
            }
            column(Vendor_Comment; Format(Comment))
            {
            }
            column(Vendor__Address_2_; "Address 2")
            {
            }
            column(Address3; Address3)
            {
            }
            column(City__________County___________Post_Code_; City + ', ' + County + '  ' + "Post Code")
            {
            }
            column(DELCHR_City_________County__________Post_Code_______; DelChr(City + ' ' + County + ' ' + "Post Code", '<>'))
            {
            }
            column(Vendor_Contact; Contact)
            {
            }
            column(Vendor__Phone_No__; "Phone No.")
            {
            }
            column(Vendor___ListingCaption; Vendor___ListingCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Control7Caption; CaptionClassTranslate('101,1,' + Text000))
            {
            }
            column(Vendors_without_balances_are_not_listed_Caption; Vendors_without_balances_are_not_listed_CaptionLbl)
            {
            }
            column(Vendor__No__Caption; FieldCaption("No."))
            {
            }
            column(Vendor_NameCaption; Vendor_NameCaptionLbl)
            {
            }
            column(Vendor__Vendor_Posting_Group_Caption; FieldCaption("Vendor Posting Group"))
            {
            }
            column(PaymentTerms__Due_Date_Calculation_Caption; PaymentTerms__Due_Date_Calculation_CaptionLbl)
            {
            }
            column(Vendor__Shipment_Method_Code_Caption; FieldCaption("Shipment Method Code"))
            {
            }
            column(Vendor__Currency_Code_Caption; Vendor__Currency_Code_CaptionLbl)
            {
            }
            column(VendBalanceCaption; VendBalanceCaptionLbl)
            {
            }
            column(Vendor_BlockedCaption; FieldCaption(Blocked))
            {
            }
            column(Vendor_CommentCaption; Vendor_CommentCaptionLbl)
            {
            }
            column(Vendor_ContactCaption; Vendor_ContactCaptionLbl)
            {
            }
            column(Vendor__Invoice_Disc__Code_Caption; Vendor__Invoice_Disc__Code_CaptionLbl)
            {
            }
            column(Vendor__Tax_Area_Code_Caption; FieldCaption("Tax Area Code"))
            {
            }
            column(Vendor__Fin__Charge_Terms_Code_Caption; Vendor__Fin__Charge_Terms_Code_CaptionLbl)
            {
            }
            column(Vendor__Purchaser_Code_Caption; FieldCaption("Purchaser Code"))
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields(Balance, "Balance (LCY)");
                if PrintAmountsInLocal then
                    VendBalance := Balance
                else
                    VendBalance := "Balance (LCY)";
                if (VendBalance = 0) and AllHavingBalance then
                    CurrReport.Skip();
                if Vendor."Payment Terms Code" <> '' then
                    PaymentTerms.Get("Payment Terms Code")
                else
                    Clear(PaymentTerms);
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
                    field(PrintAmountsinVendorsCurrency; PrintAmountsInLocal)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Print Amounts in Vendor''s Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if amounts are printed in the vendor''s currency. Clear the check box to print all amounts in US dollars.';
                    }
                    field(VendwithBalancesOnly; AllHavingBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vend. with Balances Only';
                        ToolTip = 'Specifies if you want to include only vendor accounts that carry balances.';
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
        VendFilter := Vendor.GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        PaymentTerms: Record "Payment Terms";
        TypeHelper: Codeunit "Type Helper";
        PrintAmountsInLocal: Boolean;
        AllHavingBalance: Boolean;
        VendFilter: Text;
        VendBalance: Decimal;
        SubTitle: Text[132];
        Address3: Text[84];
        Text000: Label 'The balance is in %1.';
        Vendor___ListingCaptionLbl: Label 'Vendor - Listing';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Vendors_without_balances_are_not_listed_CaptionLbl: Label 'Vendors without balances are not listed.';
        Vendor_NameCaptionLbl: Label 'Name and Address';
        PaymentTerms__Due_Date_Calculation_CaptionLbl: Label 'Terms';
        Vendor__Currency_Code_CaptionLbl: Label 'Currency Code';
        VendBalanceCaptionLbl: Label 'Balance';
        Vendor_CommentCaptionLbl: Label 'Vendor Comment';
        Vendor_ContactCaptionLbl: Label 'Contact and Phone No.';
        Vendor__Invoice_Disc__Code_CaptionLbl: Label 'Discount Grp';
        Vendor__Fin__Charge_Terms_Code_CaptionLbl: Label 'Fin Chrg';
}

