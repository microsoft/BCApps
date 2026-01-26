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
using Microsoft.Sales.Customer;
using System.Environment;

report 28040 "WHT Certificate - Other"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/WithholdingTax/WHTCertificateOther.rdlc';
    Caption = 'WHT Certificate';
    ApplicationArea = Basic, Suite;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("WHT Entry"; "WHT Entry")
        {
            // Entry no. is added here because this report gets printed during background posting of GL lines inside a background task
            // When information for GL lines is seralized we only know the entry no. for the GL lines so we have to use it for this to print. 
            // Look at SchedulePrintJobQueueEntry function in BatchPostingPrintMgt codeunit, this function is seralizes the RecordID (which only contains) primary key (entry no.)
            DataItemTableView = sorting("Entry No.", "Bill-to/Pay-to No.", "Original Document No.", "WHT Revenue Type") where("Document Type" = filter(Payment | Refund | Invoice | "Credit Memo"));
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
            column("page"; StrSubstNo(Text1500001, ' '))
            {
            }
            column(transactionType; "Transaction Type")
            {
            }
            column(CompanyInfo__Bank_Name__Control1500052; CompanyInfo."Bank Name")
            {
            }
            column(CompanyInfo__Bank_Account_No___Control1500054; CompanyInfo."Bank Account No.")
            {
            }
            column(CompanyInfo__Giro_No___Control1500056; CompanyInfo."Giro No.")
            {
            }
            column(CompanyInfo__VAT_Registration_No___Control1500058; CompanyInfo."VAT Registration No.")
            {
            }
            column(CustAddr_7_; CustAddr[7])
            {
            }
            column(CompanyInfo__Fax_No___Control1500061; CompanyInfo."Fax No.")
            {
            }
            column(CustAddr_8_; CustAddr[8])
            {
            }
            column(Customer__VAT_Registration_No__; Customer."VAT Registration No.")
            {
            }
            column(CustAddr_6_; CustAddr[6])
            {
            }
            column(CompanyInfo__Phone_No___Control1500066; CompanyInfo."Phone No.")
            {
            }
            column(CustAddr_5_; CustAddr[5])
            {
            }
            column(CompanyAddr_6__Control1500068; CompanyAddr[6])
            {
            }
            column(CustAddr_4_; CustAddr[4])
            {
            }
            column(CompanyAddr_5__Control1500070; CompanyAddr[5])
            {
            }
            column(CustAddr_3_; CustAddr[3])
            {
            }
            column(CompanyAddr_4__Control1500072; CompanyAddr[4])
            {
            }
            column(CustAddr_2_; CustAddr[2])
            {
            }
            column(CompanyAddr_3__Control1500074; CompanyAddr[3])
            {
            }
            column(CustAddr_1_; CustAddr[1])
            {
            }
            column(CompanyAddr_2__Control1500077; CompanyAddr[2])
            {
            }
            column(CompanyAddr_1__Control1500078; CompanyAddr[1])
            {
            }
            column(Text1500000_Control1500079; Text1500000Lbl)
            {
            }
            column(Customer__No__; Customer."No.")
            {
            }
            column(WHT_Entry__Original_Document_No___Control1500083; "Original Document No.")
            {
            }
            column(Customer_ABN; Customer.ABN)
            {
            }
            column(CompanyInfo_ABN_Control1500088; CompanyInfo.ABN)
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
            column(CompanyInfo__Bank_Name__Control1500052Caption; CompanyInfo__Bank_Name__Control1500052CaptionLbl)
            {
            }
            column(CompanyInfo__Bank_Account_No___Control1500054Caption; CompanyInfo__Bank_Account_No___Control1500054CaptionLbl)
            {
            }
            column(CompanyInfo__Giro_No___Control1500056Caption; CompanyInfo__Giro_No___Control1500056CaptionLbl)
            {
            }
            column(CompanyInfo__VAT_Registration_No___Control1500058Caption; CompanyInfo__VAT_Registration_No___Control1500058CaptionLbl)
            {
            }
            column(CompanyInfo__Fax_No___Control1500061Caption; CompanyInfo__Fax_No___Control1500061CaptionLbl)
            {
            }
            column(CompanyInfo__Phone_No___Control1500066Caption; CompanyInfo__Phone_No___Control1500066CaptionLbl)
            {
            }
            column(Customer__VAT_Registration_No__Caption; Customer__VAT_Registration_No__CaptionLbl)
            {
            }
            column(Customer__No__Caption; Customer__No__CaptionLbl)
            {
            }
            column(WHT_Entry__Original_Document_No___Control1500083Caption; WHT_Entry__Original_Document_No___Control1500083CaptionLbl)
            {
            }
            column(Customer_ABNCaption; Customer_ABNCaptionLbl)
            {
            }
            column(CompanyInfo_ABN_Control1500088Caption; CompanyInfo_ABN_Control1500088CaptionLbl)
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
                if "Actual Vendor No." <> '' then begin
                    if "Actual Vendor No." <> "Bill-to/Pay-to No." then
                        Vendor.Get("Actual Vendor No.")
                    else
                        Vendor.Get("Bill-to/Pay-to No.");
                end else
                    if "Transaction Type" = "Transaction Type"::Purchase then
                        Vendor.Get("Bill-to/Pay-to No.")
                    else
                        Customer.Get("Bill-to/Pay-to No.");
                if "Transaction Type" = "Transaction Type"::Purchase then
                    FormatAddr.Vendor(VendAddr, Vendor)
                else
                    FormatAddr.Customer(CustAddr, Customer);
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
            column(FORMAT_WHTDate_; Format(WHTDate))
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
                WHTEntry3.CopyFilters("WHT Entry");
                WHTEntry3.SetRange("WHT Revenue Type", Code);
                WHTEntry3.SetRange("Document Type", WHTEntry3."Document Type"::Invoice);
                if WHTEntry3.FindSet() then
                    repeat
                        WHTBaseLCY := WHTBaseLCY + WHTEntry3."Base (LCY)";
                        WHTAmountLCY := WHTAmountLCY + WHTEntry3."Amount (LCY)";
                        WHTDate := WHTEntry3."Posting Date";
                    until WHTEntry3.Next() = 0;
                WHTEntry4.CopyFilters("WHT Entry");
                WHTEntry4.SetRange("WHT Revenue Type", Code);
                WHTEntry4.SetRange("Document Type", WHTEntry4."Document Type"::Refund);
                if WHTEntry4.FindSet() then
                    repeat
                        WHTBaseLCY := WHTBaseLCY + WHTEntry4."Base (LCY)";
                        WHTAmountLCY := WHTAmountLCY + WHTEntry4."Amount (LCY)";
                        WHTDate := WHTEntry4."Posting Date";
                    until WHTEntry4.Next() = 0;

                WHTEntry5.CopyFilters("WHT Entry");
                WHTEntry5.SetRange("WHT Revenue Type", Code);
                WHTEntry5.SetRange("Document Type", WHTEntry5."Document Type"::"Credit Memo");
                if WHTEntry5.FindSet() then
                    repeat
                        WHTBaseLCY := WHTBaseLCY + WHTEntry5."Base (LCY)";
                        WHTAmountLCY := WHTAmountLCY + WHTEntry5."Amount (LCY)";
                        WHTDate := WHTEntry5."Posting Date";
                    until WHTEntry5.Next() = 0;
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
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        // We only want to show error if this report is not running in background and if it is then we check the value if GL posting is set to run in background.        
        GeneralLedgerSetup.Get();
        if (ClientTypeManagement.GetCurrentClientType() <> CLIENTTYPE::Background) then
            ShowValidationError()
        else
            if not GeneralLedgerSetup."Post with Job Queue" then
                ShowValidationError();
    end;

    local procedure ShowValidationError()
    begin
        if ("WHT Entry".GetFilter("Original Document No.") = '') or ("WHT Entry".GetFilter("Bill-to/Pay-to No.") = '') then
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
        Text1500001: Label 'Page %1';
        Text1500003: Label 'Please enter Bill-to/Pay-to Vendor No. and Original Document No. ';
        GLSetup: Record "General Ledger Setup";
        WHTEntry3: Record "WHT Entry";
        WHTEntry4: Record "WHT Entry";
        WHTEntry5: Record "WHT Entry";
        Customer: Record Customer;
        CustAddr: array[8] of Text[100];
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
        CompanyInfo__Bank_Name__Control1500052CaptionLbl: Label 'Bank';
        CompanyInfo__Bank_Account_No___Control1500054CaptionLbl: Label 'Account No.';
        CompanyInfo__Giro_No___Control1500056CaptionLbl: Label 'Giro No.';
        CompanyInfo__VAT_Registration_No___Control1500058CaptionLbl: Label 'VAT Reg. No.';
        CompanyInfo__Fax_No___Control1500061CaptionLbl: Label 'Fax No.';
        CompanyInfo__Phone_No___Control1500066CaptionLbl: Label 'Phone No.';
        Customer__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        Customer__No__CaptionLbl: Label 'Customer No.';
        WHT_Entry__Original_Document_No___Control1500083CaptionLbl: Label 'Doc. No.';
        Customer_ABNCaptionLbl: Label 'ABN/Division Part No.';
        CompanyInfo_ABN_Control1500088CaptionLbl: Label 'ABN No.';
        WHT_Entry__WHT_Certificate_No__CaptionLbl: Label 'WHT Slip No.';
        Revenue_TypeCaptionLbl: Label 'Revenue Type';
        AmountCaptionLbl: Label 'Amount';
        WHT_AmountCaptionLbl: Label 'WHT Amount';
        DateCaptionLbl: Label 'Date';
        Text1500002Lbl: Label 'To be retained by payee for taxation purposes.';
}

