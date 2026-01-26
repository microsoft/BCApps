// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;

report 14309 "WHT PND 3"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/WithholdingTax/WHTPND3.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'WHT Report - PND3';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(WHTEntry; "WHT Entry")
        {
            DataItemTableView = sorting("Posting Date", Settled, "WHT Certificate No.") where(Settled = const(true), "WHT Report" = const("Por Ngor Dor 3"));
            RequestFilterFields = "Bill-to/Pay-to No.", "WHT Bus. Posting Group", "WHT Prod. Posting Group";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CompanyInfo__Registration_No__; CompanyInfo."Registration No.")
            {
            }
            column(CompanyInfo__WHT_Registration_ID_; CompanyInfo."WHT Registration ID")
            {
            }
            column(Text001; Text001Lbl)
            {
            }
            column(WHTEntry__WHT_Report_Line_No_; "WHT Report Line No")
            {
            }
            column(WHTEntry__Amount__LCY__; "Amount (LCY)")
            {
            }
            column(WHTEntry__Base__LCY__; "Base (LCY)")
            {
            }
            column(STRSUBSTNO___1_____WHT____; StrSubstNo('%1 %', "WHT %"))
            {
            }
            column(WHTEntry__WHT_Revenue_Type_; "WHT Revenue Type")
            {
            }
            column(FORMAT__Posting_Date__; Format("Posting Date"))
            {
            }
            column(Address_2_; Address[2])
            {
            }
            column(Address_4_; Address[4])
            {
            }
            column(Address_5_; Address[5])
            {
            }
            column(RegNo; RegNo)
            {
            }
            column(Address_1_; Address[1])
            {
            }
            column(WHTEntry__Bill_to_Pay_to_No__; "Bill-to/Pay-to No.")
            {
            }
            column(WHTEntry__Base__LCY___Control1500045; "Base (LCY)")
            {
            }
            column(WHTEntry__Amount__LCY___Control1500046; "Amount (LCY)")
            {
            }
            column(WHTEntry_Entry_No_; "Entry No.")
            {
            }
            column(WHTEntry_WHT_Certificate_No_; "WHT Certificate No.")
            {
            }
            column(Pon_Ngor_Dor_3Caption; Pon_Ngor_Dor_3CaptionLbl)
            {
            }
            column(ONRIC_NumberCaption; ONRIC_NumberCaptionLbl)
            {
            }
            column(Regular_tax_payerCaption; Regular_tax_payerCaptionLbl)
            {
            }
            column(tax_payerCaption; tax_payerCaptionLbl)
            {
            }
            column(WHT_Registration_IDCaption; WHT_Registration_IDCaptionLbl)
            {
            }
            column(Branch_codeCaption; Branch_codeCaptionLbl)
            {
            }
            column(page______Caption; page______CaptionLbl)
            {
            }
            column(ofCaption; ofCaptionLbl)
            {
            }
            column(pagesCaption; pagesCaptionLbl)
            {
            }
            column(WHT_Report_Line_NoCaption; WHT_Report_Line_NoCaptionLbl)
            {
            }
            column(Total_base_amonutCaption; Total_base_amonutCaptionLbl)
            {
            }
            column(Amount__LCY_Caption; Amount__LCY_CaptionLbl)
            {
            }
            column(Payment_DateCaption; Payment_DateCaptionLbl)
            {
            }
            column(NRIC_NumberCaption; NRIC_NumberCaptionLbl)
            {
            }
            column(Please_fill_in_the_name_and_clearly_indicate_the_titleCaption; Please_fill_in_the_name_and_clearly_indicate_the_titleCaptionLbl)
            {
            }
            column(Payment_detailsCaption; Payment_detailsCaptionLbl)
            {
            }
            column(BahtCaption; BahtCaptionLbl)
            {
            }
            column(SatangCaption; SatangCaptionLbl)
            {
            }
            column(BahtCaption_Control1500022; BahtCaption_Control1500022Lbl)
            {
            }
            column(SatangCaption_Control1500023; SatangCaption_Control1500023Lbl)
            {
            }
            column(Condition__2Caption; Condition__2CaptionLbl)
            {
            }
            column(WHT__Caption; WHT__CaptionLbl)
            {
            }
            column(Address_detailsCaption; Address_detailsCaptionLbl)
            {
            }
            column(V1_WHT_Revenue_TypeCaption; V1_WHT_Revenue_TypeCaptionLbl)
            {
            }
            column(Amount__LCY_Caption_Control1500028; Amount__LCY_Caption_Control1500028Lbl)
            {
            }
            column(SurnameCaption; SurnameCaptionLbl)
            {
            }
            column(AddressCaption; AddressCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(please_indicate_the_line_number_if_there_is_any_continuing_page_according_to_the_tax_type_Caption; please_indicate_the_line_number_if_there_is_any_continuing_page_according_to_the_tax_type_CaptionLbl)
            {
            }
            column(Total_income_and_tax_paying__including_with_Phor_Ngor_Dor_3_if_any_Caption; Total_income_and_tax_paying__including_with_Phor_Ngor_Dor_3_if_any_CaptionLbl)
            {
            }
            column(V1_purpose_of_payment_eg_rental__audit__lawyer__knowledge_of_doctor__building_expenses; V1_PurposeOfPaymentLbl)
            {
            }
            column(V2_indicate_the_number_accordinglyCaption; V2_indicate_the_number_accordinglyCaptionLbl)
            {
            }
            column(Pay_at_the_point_indicate_1Caption; Pay_at_the_point_indicate_1CaptionLbl)
            {
            }
            column(Issued_forever_indicate_2Caption; Issued_forever_indicate_2CaptionLbl)
            {
            }
            column(Issue_only_once_indicate_3Caption; Issue_only_once_indicate_3CaptionLbl)
            {
            }
            column(MonthCaption; MonthCaptionLbl)
            {
            }
            column(NameCaption_Control1500054; NameCaption_Control1500054Lbl)
            {
            }
            column(PayerCaption; PayerCaptionLbl)
            {
            }
            column(DesignationCaption; DesignationCaptionLbl)
            {
            }
            column(Application_dateCaption; Application_dateCaptionLbl)
            {
            }
            column(YearCaption; YearCaptionLbl)
            {
            }
            column(EmptyStringCaption; EmptyStringCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if "Transaction Type" = "Transaction Type"::Purchase then begin
                    if "Actual Vendor No." <> '' then
                        Vendor.Get("Actual Vendor No.")
                    else
                        Vendor.Get("Bill-to/Pay-to No.");
                    Address[1] := Vendor.Name;
                    Address[2] := Vendor."Name 2";
                    Address[3] := Vendor.Contact;
                    Address[4] := Vendor.Address;
                    Address[5] := Vendor."Address 2";
                    Address[6] := Vendor.City;
                    Address[7] := Vendor."Post Code";
                    Address[8] := Vendor."Country/Region Code";
                    RegNo := Vendor."WHT Registration ID";
                    FormatAddr.Vendor(Address, Vendor);
                end else
                    Clear(Address);
            end;

            trigger OnPreDataItem()
            begin
                LastFieldNo := FieldNo("WHT Prod. Posting Group");
                CompanyInfo.Get();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

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
        CompanyInfo: Record "Company Information";
        Vendor: Record Vendor;
        FormatAddr: Codeunit "Format Address";
        LastFieldNo: Integer;
        Address: array[8] of Text[100];
        RegNo: Text[20];
        Text001Lbl: Label 'WHT Registration No.';
        Pon_Ngor_Dor_3CaptionLbl: Label 'Pon Ngor Dor 3';
        ONRIC_NumberCaptionLbl: Label 'Ã½NRIC Number';
        Regular_tax_payerCaptionLbl: Label 'Regular tax payer';
        tax_payerCaptionLbl: Label 'Tax payer';
        WHT_Registration_IDCaptionLbl: Label 'WHT Registration ID';
        Branch_codeCaptionLbl: Label 'Branch code';
        page______CaptionLbl: Label 'page      ', Comment = 'page X of Y pages';
        ofCaptionLbl: Label 'of', Comment = 'X of Y';
        pagesCaptionLbl: Label 'pages', Comment = 'page X of Y pages';
        WHT_Report_Line_NoCaptionLbl: Label 'WHT Report Line No';
        Total_base_amonutCaptionLbl: Label 'Total base amount';
        Amount__LCY_CaptionLbl: Label 'Amount (LCY)';
        Payment_DateCaptionLbl: Label 'Payment Date';
        NRIC_NumberCaptionLbl: Label 'NRIC Number';
        Please_fill_in_the_name_and_clearly_indicate_the_titleCaptionLbl: Label 'Please fill in the name and clearly indicate the title';
        Payment_detailsCaptionLbl: Label 'Payment details';
        BahtCaptionLbl: Label 'ÃˆBaht';
        SatangCaptionLbl: Label 'Satang';
        BahtCaption_Control1500022Lbl: Label 'ÃˆBaht';
        SatangCaption_Control1500023Lbl: Label 'Satang';
        Condition__2CaptionLbl: Label 'Condition *2';
        WHT__CaptionLbl: Label 'WHT %';
        Address_detailsCaptionLbl: Label 'Address details';
        V1_WHT_Revenue_TypeCaptionLbl: Label '1 WHT Revenue Type';
        Amount__LCY_Caption_Control1500028Lbl: Label 'Amount (LCY)';
        SurnameCaptionLbl: Label 'Surname';
        AddressCaptionLbl: Label 'Address';
        NameCaptionLbl: Label 'Name';
        please_indicate_the_line_number_if_there_is_any_continuing_page_according_to_the_tax_type_CaptionLbl: Label 'Please indicate the line number if there is any continuing page according to the tax type).';
        Total_income_and_tax_paying__including_with_Phor_Ngor_Dor_3_if_any_CaptionLbl: Label 'Total income and tax paying (including with Phor Ngor Dor 3 if any)';
        V1_PurposeOfPaymentLbl: Label '1 indicate the purpose of payment eg rental, audit, lawyer, knowledge of doctor, building expenses, prize, discount or any other benefit for promoting the product, prize winning from competition, racing,prize from coupon, pay for actor, song, music, pay for custom made products, advertisement, transportation etc.';
        V2_indicate_the_number_accordinglyCaptionLbl: Label '2 indicate the number accordingly';
        Pay_at_the_point_indicate_1CaptionLbl: Label 'Pay at the point indicate 1';
        Issued_forever_indicate_2CaptionLbl: Label 'Issued forever indicate 2';
        Issue_only_once_indicate_3CaptionLbl: Label 'Issue only once indicate 3';
        MonthCaptionLbl: Label 'Month';
        NameCaption_Control1500054Lbl: Label 'Name';
        PayerCaptionLbl: Label 'Payer';
        DesignationCaptionLbl: Label 'Designation';
        Application_dateCaptionLbl: Label 'Application date';
        YearCaptionLbl: Label 'Year';
        EmptyStringCaptionLbl: Label '.', Locked = true;
}

