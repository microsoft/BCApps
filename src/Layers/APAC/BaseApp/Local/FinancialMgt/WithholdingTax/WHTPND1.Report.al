// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;

report 14307 "WHT PND 1"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/WithholdingTax/WHTPND1.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'WHT Report - PND1';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(WHTEntry; "WHT Entry")
        {
            DataItemTableView = sorting("Posting Date", Settled, "WHT Certificate No.") where(Settled = const(true), "WHT Report" = const("Por Ngor Dor 1"));
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
            column(FORMAT__Posting_Date__; Format("Posting Date"))
            {
            }
            column(Address_2_; Address[2])
            {
            }
            column(RegNo; RegNo)
            {
            }
            column(Address_1_; Address[1])
            {
            }
            column(ICNo; ICNo)
            {
            }
            column(WHTEntry__Base__LCY___Control1500052; "Base (LCY)")
            {
            }
            column(WHTEntry__Amount__LCY___Control1500053; "Amount (LCY)")
            {
            }
            column(WHTEntry_Entry_No_; "Entry No.")
            {
            }
            column(WHTEntry_WHT_Certificate_No_; "WHT Certificate No.")
            {
            }
            column(Pon_Ngor_Dor_1Caption; Pon_Ngor_Dor_1CaptionLbl)
            {
            }
            column(NRIC_NumberCaption; NRIC_NumberCaptionLbl)
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
            column(Please_tickCaption; Please_tickCaptionLbl)
            {
            }
            column(Income_rule_No_40__1___2_Caption; Income_rule_No_40__1___2_CaptionLbl)
            {
            }
            column(Income_typeCaption; Income_typeCaptionLbl)
            {
            }
            column(Income_rule_no__40_1___general_categoryCaption; Income_rule_no__40_1___general_categoryCaptionLbl)
            {
            }
            column(Income_rule_No_40__1__Special_categoryCaption; Income_rule_No_40__1__Special_categoryCaptionLbl)
            {
            }
            column(Income_rule_No__40__2__for_Thai_residentCaption; Income_rule_No__40__2__for_Thai_residentCaptionLbl)
            {
            }
            column(one_option_onlyCaption; one_option_onlyCaptionLbl)
            {
            }
            column(inCaption; inCaptionLbl)
            {
            }
            column(Income_rule_No_40__2__for_resident_not_in_ThailandCaption; Income_rule_No_40__2__for_resident_not_in_ThailandCaptionLbl)
            {
            }
            column(X_Caption; X_CaptionLbl)
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
            column(NRIC_NumberCaption_Control1500033; NRIC_NumberCaption_Control1500033Lbl)
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
            column(BahtCaption_Control1500038; BahtCaption_Control1500038Lbl)
            {
            }
            column(SatangCaption_Control1500039; SatangCaption_Control1500039Lbl)
            {
            }
            column(Condition__Caption; Condition__CaptionLbl)
            {
            }
            column(SurnameCaption; SurnameCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(please_indicate_the_line_number_if_there_is_any_continuing_page_according_to_the_tax_type_Caption; please_indicate_the_line_number_if_there_is_any_continuing_page_according_to_the_tax_type_CaptionLbl)
            {
            }
            column(Total_income_and_tax_paying__including_with_Phor_Ngor_Dor_1_if_any_Caption; Total_income_and_tax_paying__including_with_Phor_Ngor_Dor_1_if_any_CaptionLbl)
            {
            }
            column(conditions___indicate_the_number_accordinglyCaption; conditions___indicate_the_number_accordinglyCaptionLbl)
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
            column(NameCaption_Control1500060; NameCaption_Control1500060Lbl)
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
                    ICNo := Vendor."ID No.";
                    FormatAddr.Vendor(Address, Vendor);
                end else
                    Clear(Address);
            end;

            trigger OnPreDataItem()
            begin
                LastFieldNo := FieldNo("WHT Prod. Posting Group");
                CompanyInfo.Get();
                Clear(Address);
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
        ICNo: Text[20];
        Text001Lbl: Label 'WHT Registration No.';
        Pon_Ngor_Dor_1CaptionLbl: Label 'Pon Ngor Dor 1';
        NRIC_NumberCaptionLbl: Label 'NRIC Number';
        Regular_tax_payerCaptionLbl: Label 'Regular tax payer';
        tax_payerCaptionLbl: Label 'Tax payer';
        WHT_Registration_IDCaptionLbl: Label 'WHT Registration ID';
        Branch_codeCaptionLbl: Label 'Branch code';
        page______CaptionLbl: Label 'page', Comment = 'page X of Y pages';
        ofCaptionLbl: Label 'of', Comment = 'X of Y';
        pagesCaptionLbl: Label 'pages', Comment = 'page X of Y pages';
        Please_tickCaptionLbl: Label 'Please tick';
        Income_rule_No_40__1___2_CaptionLbl: Label 'Income rule No.40 (1) (2)';
        Income_typeCaptionLbl: Label 'Income type';
        Income_rule_no__40_1___general_categoryCaptionLbl: Label 'Income rule no. 40(1), general category';
        Income_rule_No_40__1__Special_categoryCaptionLbl: Label 'Income rule No.40 (1) Special category';
        Income_rule_No__40__2__for_Thai_residentCaptionLbl: Label 'Income rule No. 40 (2) for Thai resident';
        one_option_onlyCaptionLbl: Label 'one option only', Comment = '(X) in one option only ';
        inCaptionLbl: Label 'in', Comment = '(X) in one option only.';
        Income_rule_No_40__2__for_resident_not_in_ThailandCaptionLbl: Label 'Income rule No.40 (2) for resident not in Thailand';
        X_CaptionLbl: Label '(X)';
        WHT_Report_Line_NoCaptionLbl: Label 'WHT Report Line No';
        Total_base_amonutCaptionLbl: Label 'Total base amount';
        Amount__LCY_CaptionLbl: Label 'Amount (LCY)';
        Payment_DateCaptionLbl: Label 'Payment Date';
        NRIC_NumberCaption_Control1500033Lbl: Label 'NRIC Number';
        Please_fill_in_the_name_and_clearly_indicate_the_titleCaptionLbl: Label 'Please fill in the name and clearly indicate the title';
        Payment_detailsCaptionLbl: Label 'Payment details';
        BahtCaptionLbl: Label 'Baht';
        SatangCaptionLbl: Label 'Satang';
        BahtCaption_Control1500038Lbl: Label 'Baht';
        SatangCaption_Control1500039Lbl: Label 'Satang';
        Condition__CaptionLbl: Label 'Condition *';
        SurnameCaptionLbl: Label 'Surname';
        NameCaptionLbl: Label 'Name';
        please_indicate_the_line_number_if_there_is_any_continuing_page_according_to_the_tax_type_CaptionLbl: Label 'Please indicate the line number if there is any continuing page according to the tax type)';
        Total_income_and_tax_paying__including_with_Phor_Ngor_Dor_1_if_any_CaptionLbl: Label 'Total income and tax paying (including with Phor Ngor Dor 1 if any)';
        conditions___indicate_the_number_accordinglyCaptionLbl: Label 'Conditions * indicate the number accordingly.';
        Pay_at_the_point_indicate_1CaptionLbl: Label 'Pay at the point indicate 1';
        Issued_forever_indicate_2CaptionLbl: Label 'Issued forever indicate 2';
        Issue_only_once_indicate_3CaptionLbl: Label 'Issue only once indicate 3';
        MonthCaptionLbl: Label 'Month';
        NameCaption_Control1500060Lbl: Label 'Name';
        PayerCaptionLbl: Label 'Payer';
        DesignationCaptionLbl: Label 'Designation';
        Application_dateCaptionLbl: Label 'Application date';
        YearCaptionLbl: Label 'Year';
}

