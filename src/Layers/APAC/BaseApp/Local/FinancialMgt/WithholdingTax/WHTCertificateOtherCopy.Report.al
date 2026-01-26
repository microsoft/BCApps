// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;

report 28043 "WHT Certificate - Other Copy"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/WithholdingTax/WHTCertificateOtherCopy.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'WHT Certificate';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("WHT Entry"; "WHT Entry")
        {
            DataItemTableView = sorting("Bill-to/Pay-to No.", "Original Document No.", "WHT Revenue Type") where("Document Type" = filter(Payment | Refund));
            RequestFilterFields = "Transaction Type", "Bill-to/Pay-to No.", "Original Document No.";
            column(CompanyInfo__Bank_Name_; CompanyInfo."Bank Name")
            {
            }
            column(CompanyInfo__Bank_Account_No__; CompanyInfo."Bank Account No.")
            {
            }
            column(CompanyInfo__Giro_No__; CompanyInfo."Giro No.")
            {
            }
            column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
            {
            }
            column(VendAddr_7_; VendAddr[7])
            {
            }
            column(CompanyInfo__Fax_No__; CompanyInfo."Fax No.")
            {
            }
            column(VendAddr_8_; VendAddr[8])
            {
            }
            column(Vendor__VAT_Registration_No__; Vendor."VAT Registration No.")
            {
            }
            column(VendAddr_6_; VendAddr[6])
            {
            }
            column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
            {
            }
            column(VendAddr_5_; VendAddr[5])
            {
            }
            column(CompanyAddr_6_; CompanyAddr[6])
            {
            }
            column(VendAddr_4_; VendAddr[4])
            {
            }
            column(CompanyAddr_5_; CompanyAddr[5])
            {
            }
            column(VendAddr_3_; VendAddr[3])
            {
            }
            column(CompanyAddr_4_; CompanyAddr[4])
            {
            }
            column(VendAddr_2_; VendAddr[2])
            {
            }
            column(CompanyAddr_3_; CompanyAddr[3])
            {
            }
            column(VendAddr_1_; VendAddr[1])
            {
            }
            column(CompanyAddr_2_; CompanyAddr[2])
            {
            }
            column(CompanyAddr_1_; CompanyAddr[1])
            {
            }
            column(Text1500000; Text1500000Lbl)
            {
            }
            column(Vendor__No__; Vendor."No.")
            {
            }
            column(WHT_Entry__Original_Document_No__; "Original Document No.")
            {
            }
            column(Vendor_ABN; Vendor.ABN)
            {
            }
            column(CompanyInfo_ABN; CompanyInfo.ABN)
            {
            }
            column(WHT_Entry__WHT_Certificate_No__; "WHT Certificate No.")
            {
            }
            column(WHT_Entry_Entry_No_; "Entry No.")
            {
            }
            column(CompanyInfo__Bank_Name_Caption; CompanyInfo__Bank_Name_CaptionLbl)
            {
            }
            column(CompanyInfo__Bank_Account_No__Caption; CompanyInfo__Bank_Account_No__CaptionLbl)
            {
            }
            column(CompanyInfo__Giro_No__Caption; CompanyInfo__Giro_No__CaptionLbl)
            {
            }
            column(CompanyInfo__VAT_Registration_No__Caption; CompanyInfo__VAT_Registration_No__CaptionLbl)
            {
            }
            column(CompanyInfo__Fax_No__Caption; CompanyInfo__Fax_No__CaptionLbl)
            {
            }
            column(CompanyInfo__Phone_No__Caption; CompanyInfo__Phone_No__CaptionLbl)
            {
            }
            column(Vendor__VAT_Registration_No__Caption; Vendor__VAT_Registration_No__CaptionLbl)
            {
            }
            column(Vendor__No__Caption; Vendor__No__CaptionLbl)
            {
            }
            column(WHT_Entry__Original_Document_No__Caption; WHT_Entry__Original_Document_No__CaptionLbl)
            {
            }
            column(Vendor_ABNCaption; Vendor_ABNCaptionLbl)
            {
            }
            column(CompanyInfo_ABNCaption; CompanyInfo_ABNCaptionLbl)
            {
            }
            column(WHT_Entry__WHT_Certificate_No__Caption; WHT_Entry__WHT_Certificate_No__CaptionLbl)
            {
            }
            column(Revenue_TypeCaption; Revenue_TypeCaptionLbl)
            {
            }
            column(AmountCaption; AmountCaptionLbl)
            {
            }
            column(WHT_AmountCaption; WHT_AmountCaptionLbl)
            {
            }
            column(DateCaption; DateCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if "Actual Vendor No." <> '' then
                    Vendor.Get("Actual Vendor No.")
                else
                    Vendor.Get("Bill-to/Pay-to No.");
                FormatAddr.Vendor(VendAddr, Vendor);
            end;

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
                PurchSetup.Get();
                PurchSetup.TestField("WHT Certificate No. Series");
                CompanyInfo.Get();
                FormatAddr.Company(CompanyAddr, CompanyInfo);
                TotalAmountLCY := 0;
                TotalBaseLCY := 0;
            end;
        }
        dataitem("WHT Revenue Types"; "WHT Revenue Types")
        {
            DataItemTableView = sorting(Sequence);
            column(WHTBaseLCY; WHTBaseLCY)
            {
            }
            column(WHT_Revenue_Types_Description; Description)
            {
            }
            column(WHTAmountLCY; WHTAmountLCY)
            {
            }
            column(WHTDate; Format(WHTDate))
            {
            }
            column(TotalBaseLCY; TotalBaseLCY)
            {
            }
            column(TotalAmountLCY; TotalAmountLCY)
            {
            }
            column(Text1500002; Text1500002Lbl)
            {
            }
            column(WHT_Revenue_Types_Code; Code)
            {
            }

            trigger OnAfterGetRecord()
            var
                WHTManagement: Codeunit WHTManagement;
            begin
                if not "WHT Entry".Find('-') then
                    CurrReport.Skip();
                WHTAmountLCY := 0;
                WHTBaseLCY := 0;
                WHTDate := 0D;
                WHTEntry2.CopyFilters("WHT Entry");
                WHTEntry2.SetRange("WHT Revenue Type", Code);
                WHTEntry2.SetRange("Document Type", WHTEntry2."Document Type"::Payment);
                if WHTEntry2.Find('-') then
                    repeat
                        if GLSetup."Enable GST (Australia)" then
                            WHTBaseLCY := WHTBaseLCY + WHTEntry2."Payment Amount"
                        else
                            WHTBaseLCY := WHTBaseLCY + WHTEntry2."Base (LCY)";
                        WHTAmountLCY := WHTAmountLCY + WHTEntry2."Amount (LCY)";
                        WHTDate := WHTEntry2."Posting Date";
                    until WHTEntry2.Next() = 0;
                if GLSetup."Round Amount for WHT Calc" then
                    WHTAmountLCY := WHTManagement.RoundWHTAmount(WHTAmountLCY);
                TotalAmountLCY := TotalAmountLCY + WHTAmountLCY;
                TotalBaseLCY := TotalBaseLCY + WHTBaseLCY;
            end;

            trigger OnPreDataItem()
            begin
                WHTEntry2.Reset();
                WHTEntry2.SetCurrentKey("Bill-to/Pay-to No.", "Original Document No.", "WHT Revenue Type");
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

    trigger OnPreReport()
    begin
        if ("WHT Entry".GetFilter("Original Document No.") = '') or
           ("WHT Entry".GetFilter("Bill-to/Pay-to No.") = '')
        then
            Error(Text1500003);
    end;

    var
        CompanyInfo: Record "Company Information";
        Vendor: Record Vendor;
        PurchSetup: Record "Purchases & Payables Setup";
        WHTEntry2: Record "WHT Entry";
        FormatAddr: Codeunit "Format Address";
        TotalAmountLCY: Decimal;
        TotalBaseLCY: Decimal;
        WHTAmountLCY: Decimal;
        WHTBaseLCY: Decimal;
        WHTDate: Date;
        VendAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        Text1500003: Label 'Please enter Bill-to/Pay-to Vendor No. and Original Document No. ';
        GLSetup: Record "General Ledger Setup";
        Text1500000Lbl: Label 'Withholding Certificate';
        CompanyInfo__Bank_Name_CaptionLbl: Label 'Bank';
        CompanyInfo__Bank_Account_No__CaptionLbl: Label 'Account No.';
        CompanyInfo__Giro_No__CaptionLbl: Label 'Giro No.';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax No.';
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone No.';
        Vendor__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        Vendor__No__CaptionLbl: Label 'Vendor No.';
        WHT_Entry__Original_Document_No__CaptionLbl: Label 'Doc. No.';
        Vendor_ABNCaptionLbl: Label 'ABN/Division Part No.';
        CompanyInfo_ABNCaptionLbl: Label 'ABN No.';
        WHT_Entry__WHT_Certificate_No__CaptionLbl: Label 'WHT Slip No.';
        Revenue_TypeCaptionLbl: Label 'Revenue Type';
        AmountCaptionLbl: Label 'Amount';
        WHT_AmountCaptionLbl: Label 'WHT Amount';
        DateCaptionLbl: Label 'Date';
        Text1500002Lbl: Label 'To be retained by payee for taxation purposes.';
}

