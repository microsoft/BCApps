// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;

report 14310 "WHT Report - PND 53"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/WithholdingTax/WHTReportPND53.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'WHT Report - PND 53';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("WHT Entry"; "WHT Entry")
        {
            DataItemTableView = sorting("Posting Date", "WHT Certificate No.") where(Settled = const(true), "WHT Report" = const("Por Ngor Dor 53"));
            RequestFilterFields = "Posting Date";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_GETFILTER__Posting_Date___; Format(GetFilter("Posting Date")))
            {
            }
            column(CompanyInfo__WHT_Registration_ID_; CompanyInfo."WHT Registration ID")
            {
            }
            column(ReportLineNo; ReportLineNo)
            {
            }
            column(Address_1_; Address[1])
            {
            }
            column(Address_4_; Address[4])
            {
            }
            column(Address_5_; Address[5])
            {
            }
            column(Address_6_; Address[6])
            {
            }
            column(RegNo; RegNo)
            {
            }
            column(Address_7_; Address[7])
            {
            }
            column(TotalAmountLCY; TotalAmountLCY)
            {
            }
            column(TotalBaseLCY; TotalBaseLCY)
            {
            }
            column(WHT_Entry_Entry_No_; "Entry No.")
            {
            }
            column(WHT_Entry_WHT_Certificate_No_; "WHT Certificate No.")
            {
            }
            column(In_Form_Phor_Ngor_Dor_53Caption; In_Form_Phor_Ngor_Dor_53CaptionLbl)
            {
            }
            column(WHT_Registration_IDCaption; WHT_Registration_IDCaptionLbl)
            {
            }
            column(Branch_codeCaption; Branch_codeCaptionLbl)
            {
            }
            column(pagesCaption; pagesCaptionLbl)
            {
            }
            column(ofCaption; ofCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(Line_NumberCaption; Line_NumberCaptionLbl)
            {
            }
            column(Vendor_NameCaption; Vendor_NameCaptionLbl)
            {
            }
            column(WHT_Registration_IDCaption_Control1500010; WHT_Registration_IDCaption_Control1500010Lbl)
            {
            }
            column(AddressCaption; AddressCaptionLbl)
            {
            }
            column(Payment_detailsCaption; Payment_detailsCaptionLbl)
            {
            }
            column(Payment_DateCaption; Payment_DateCaptionLbl)
            {
            }
            column(V1_WHT_Revenue_TypeCaption; V1_WHT_Revenue_TypeCaptionLbl)
            {
            }
            column(WHT__Caption; WHT__CaptionLbl)
            {
            }
            column(Total_base_amonutCaption; Total_base_amonutCaptionLbl)
            {
            }
            column(BahtCaption; BahtCaptionLbl)
            {
            }
            column(SatangCaption; SatangCaptionLbl)
            {
            }
            column(Amount__LCY_Caption; Amount__LCY_CaptionLbl)
            {
            }
            column(BahtCaption_Control1500020; BahtCaption_Control1500020Lbl)
            {
            }
            column(SatangCaption_Control1500021; SatangCaption_Control1500021Lbl)
            {
            }
            column(Condition__2Caption; Condition__2CaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(AddressCaption_Control1500030; AddressCaption_Control1500030Lbl)
            {
            }
            column(YearCaption; YearCaptionLbl)
            {
            }
            column(PayerCaption; PayerCaptionLbl)
            {
            }
            column(MonthCaption; MonthCaptionLbl)
            {
            }
            column(DesignationCaption; DesignationCaptionLbl)
            {
            }
            column(Application_dateCaption; Application_dateCaptionLbl)
            {
            }
            column(NameCaption_Control1500045; NameCaption_Control1500045Lbl)
            {
            }
            column(Total_income_and_tax_paying__including_with_Phor_Ngor_Dor_53_if_any_Caption; Total_income_and_tax_paying__including_with_Phor_Ngor_Dor_53_if_any_CaptionLbl)
            {
            }
            column(V1_purpose_of_payment_Caption; V1_purpose_of_payment_CaptionLbl)
            {
            }
            column(discount_or_any_other_benefit_from_promoting_the_products__winning_prize_in_compitition; DiscountOrAnyOtherBenefitLbl)
            {
            }
            column(Issued_forever_indicate_2Caption; Issued_forever_indicate_2CaptionLbl)
            {
            }
            column(V2_indicate_the_number_accordinglyCaption; V2_indicate_the_number_accordinglyCaptionLbl)
            {
            }
            column(please_indicate_the_line_number_for_all_continuing_pageCaption; please_indicate_the_line_number_for_all_continuing_pageCaptionLbl)
            {
            }
            column(Pay_at_the_point_indicate_1Caption; Pay_at_the_point_indicate_1CaptionLbl)
            {
            }
            dataitem("WHT Revenue Types"; "WHT Revenue Types")
            {
                DataItemTableView = sorting(Sequence);
                column(WHTAmountLCY; WHTAmountLCY)
                {
                }
                column(WHTBaseLCY; WHTBaseLCY)
                {
                }
                column(WHT_Revenue_Types_Description; Description)
                {
                }
                column(WHT__; "WHT%")
                {
                }
                column(FORMAT_WHTDate_; Format(WHTDate))
                {
                }
                column(WHT_Entry___Posting_Date_; "WHT Entry"."Posting Date")
                {
                }
                column(WHT_Revenue_Types_Code; Code)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    WHTAmountLCY := 0;
                    WHTBaseLCY := 0;
                    WHTDate := 0D;
                    "WHT%" := 0;
                    WHTEntry2.SetRange("WHT Certificate No.", "WHT Entry"."WHT Certificate No.");
                    WHTEntry2.SetRange("WHT Revenue Type", Code);
                    WHTEntry2.SetRange("Document Type", WHTEntry2."Document Type"::Payment);
                    WHTEntry2.SetRange("WHT Report", WHTEntry2."WHT Report"::"Por Ngor Dor 53");
                    if WHTEntry2.Find('-') then begin
                        Count1 := WHTEntry2.Count();
                        repeat
                            WHTAmountLCY := WHTAmountLCY + Abs(WHTEntry2."Amount (LCY)");
                            WHTBaseLCY := WHTBaseLCY + Abs(WHTEntry2."Base (LCY)");
                            WHTDate := WHTEntry2."Posting Date";
                            "WHT%" := "WHT%" + WHTEntry2."WHT %";
                        until WHTEntry2.Next() = 0;
                    end;
                    if Count1 <> 0 then
                        "WHT%" := "WHT%" / Count1;
                    TotalAmountLCY := TotalAmountLCY + WHTAmountLCY;
                    TotalBaseLCY := TotalBaseLCY + WHTBaseLCY;
                    if WHTAmountLCY = 0 then
                        CurrReport.Skip();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if LastSlipNo = "WHT Certificate No." then
                    CurrReport.Skip();

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

                ReportLineNo := "WHT Report Line No";
                LastSlipNo := "WHT Certificate No.";
            end;

            trigger OnPreDataItem()
            begin
                LastFieldNo := FieldNo("WHT Certificate No.");
                LastSlipNo := '';
                CompanyInfo.Get();
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
        CompanyInfo: Record "Company Information";
        Vendor: Record Vendor;
        WHTEntry2: Record "WHT Entry";
        FormatAddr: Codeunit "Format Address";
        LastSlipNo: Code[20];
        TotalAmountLCY: Decimal;
        TotalBaseLCY: Decimal;
        WHTAmountLCY: Decimal;
        WHTBaseLCY: Decimal;
        WHTDate: Date;
        LastFieldNo: Integer;
        Address: array[8] of Text[100];
        RegNo: Text[20];
        "WHT%": Decimal;
        Count1: Integer;
        ReportLineNo: Code[20];
        In_Form_Phor_Ngor_Dor_53CaptionLbl: Label 'In Form Phor Ngor Dor 53';
        WHT_Registration_IDCaptionLbl: Label 'WHT Registration ID';
        Branch_codeCaptionLbl: Label 'Branch code';
        pagesCaptionLbl: Label 'pages', Comment = 'page X of Y pages';
        ofCaptionLbl: Label 'of', Comment = 'X of Y';
        PageCaptionLbl: Label 'Page';
        Line_NumberCaptionLbl: Label 'Line Number';
        Vendor_NameCaptionLbl: Label 'Vendor Name';
        WHT_Registration_IDCaption_Control1500010Lbl: Label 'WHT Registration ID';
        AddressCaptionLbl: Label 'Address';
        Payment_detailsCaptionLbl: Label 'Payment details';
        Payment_DateCaptionLbl: Label 'Payment Date';
        V1_WHT_Revenue_TypeCaptionLbl: Label '1 WHT Revenue Type';
        WHT__CaptionLbl: Label 'WHT %';
        Total_base_amonutCaptionLbl: Label 'Total base amount';
        BahtCaptionLbl: Label 'ÃˆBaht';
        SatangCaptionLbl: Label 'Satang';
        Amount__LCY_CaptionLbl: Label 'Amount (LCY)';
        BahtCaption_Control1500020Lbl: Label 'ÃˆBaht';
        SatangCaption_Control1500021Lbl: Label 'Satang';
        Condition__2CaptionLbl: Label 'Condition *2';
        NameCaptionLbl: Label 'Name';
        AddressCaption_Control1500030Lbl: Label 'Address';
        YearCaptionLbl: Label 'Year';
        PayerCaptionLbl: Label 'Payer';
        MonthCaptionLbl: Label 'Month';
        DesignationCaptionLbl: Label 'Designation';
        Application_dateCaptionLbl: Label 'Application date';
        NameCaption_Control1500045Lbl: Label 'Name';
        Total_income_and_tax_paying__including_with_Phor_Ngor_Dor_53_if_any_CaptionLbl: Label 'Total income and tax paying (including with Phor Ngor Dor 53 if any)';
        V1_purpose_of_payment_CaptionLbl: Label '1 Please indicate the purpose of payment eg agency, goodwill, interest from saving account, interest from voucher, shareholder, dividend, from rental, external audit, designer, pay for building the school, buy type writer, consumer goods, pay for custom made product, for advertisement, prize, ';
        DiscountOrAnyOtherBenefitLbl: Label 'Discount or any other benefit from promoting the products, winning prize in competition, racing, coupon, transportation, insurance etc.';
        Issued_forever_indicate_2CaptionLbl: Label 'Issued forever indicate 2';
        V2_indicate_the_number_accordinglyCaptionLbl: Label '2 indicate the number accordingly';
        please_indicate_the_line_number_for_all_continuing_pageCaptionLbl: Label 'Please indicate the line number for all continuing page.';
        Pay_at_the_point_indicate_1CaptionLbl: Label 'Pay at the point indicate 1';
}

