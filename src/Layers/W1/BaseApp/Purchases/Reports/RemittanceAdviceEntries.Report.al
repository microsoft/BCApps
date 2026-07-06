// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 400 "Remittance Advice - Entries"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/RemittanceAdviceEntries.rdlc';
    Caption = 'Remittance Advice - Entries';
    WordMergeDataItem = "Vendor Ledger Entry";

    dataset
    {
        dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
        {
            DataItemTableView = sorting("Vendor No.") where("Document Type" = const(Payment));
            RequestFilterFields = "Vendor No.", "Posting Date", "Currency Code", "Entry No.";
            column(CompanyAddr1; CompanyAddr[1])
            {
            }
            column(VendorAddr1; VendorAddr[1])
            {
            }
            column(CompanyAddr2; CompanyAddr[2])
            {
            }
            column(VendorAddr2; VendorAddr[2])
            {
            }
            column(CompanyAddr3; CompanyAddr[3])
            {
            }
            column(VendorAddr3; VendorAddr[3])
            {
            }
            column(CompanyAddr4; CompanyAddr[4])
            {
            }
            column(VendorAddr4; VendorAddr[4])
            {
            }
            column(CompanyAddr5; CompanyAddr[5])
            {
            }
            column(CompanyAddr6; CompanyAddr[6])
            {
            }
            column(CompanyAddr7; CompanyAddr[7])
            {
            }
            column(CompanyAddr8; CompanyAddr[8])
            {
            }
            column(VendorAddr5; VendorAddr[5])
            {
            }
            column(VendorAddr6; VendorAddr[6])
            {
            }
            column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
            {
            }
            column(VendorAddr7; VendorAddr[7])
            {
            }
            column(CompanyInfoVATRegNo; CompanyInfo."VAT Registration No.")
            {
            }
            column(CompanyInfoFaxNo; CompanyInfo."Fax No.")
            {
            }
            column(VendorAddr8; VendorAddr[8])
            {
            }
            column(CompanyInfoBankName; CompanyInfo."Bank Name")
            {
            }
            column(CompanyInfoBankAccNo; CompanyInfo."Bank Account No.")
            {
            }
            column(CompanyInfoBankBranchNo; CompanyInfo."Bank Branch No.")
            {
            }
            column(DocNo_VendLedgEntry; "Document No.")
            {
            }
            column(EntryNo_VendLedgEntry; "Entry No.")
            {
            }
            column(VendorLedgerEntryVendorNo; "Vendor No.")
            {
            }
            column(RemittanceAdviceCaption; RemittanceAdvCaptionLbl)
            {
            }
            column(PhoneNoCaption; PhoneNoCaptionLbl)
            {
            }
            column(FaxNoCaption; FaxNoCaptionLbl)
            {
            }
            column(VATRegNoCaption; VATRegNoCaptionLbl)
            {
            }
            column(BankNameCaption; BankCaptionLbl)
            {
            }
            column(BankAccountNoCaption; AccNoCaptionLbl)
            {
            }
            column(SortCodeCaption; SortCodeCaptionLbl)
            {
            }
            column(AmountCaption; AmtCaptionLbl)
            {
            }
            column(PmtDiscTakenCaption; PmtDiscTakenCaptionLbl)
            {
            }
            column(RemainingAmtCaption; RemAmtCaptionLbl)
            {
            }
            column(OriginalAmountCaption; OriginalAmtCaptionLbl)
            {
            }
            column(YourDocNoCaption; YourDocNoCaptionLbl)
            {
            }
            column(DocTypeCaption_VendLedgEntry2; VendLedgEntry2.FieldCaption("Document Type"))
            {
            }
            column(OurDocNoCaption; OurDocNoCaptionLbl)
            {
            }
            column(CurrCodeCaption; CurrCodeCaptionLbl)
            {
            }
            column(DocumentDateCaption; DocDateCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl) { }
            dataitem(VendLedgEntry2; "Vendor Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(LineAmtLineDiscCurr; -LineAmount - LineDiscount)
                {
                    AutoFormatExpression = "Vendor Ledger Entry"."Currency Code";
                    AutoFormatType = 1;
                }
                column(NegAmount_VendLedgEntry2; -Amount)
                {
                    AutoFormatExpression = "Vendor Ledger Entry"."Currency Code";
                    AutoFormatType = 1;
                }
                column(RemAmt_VendLedgEntry2; -"Remaining Amount")
                {
                    AutoFormatExpression = "Vendor Ledger Entry"."Currency Code";
                    AutoFormatType = 1;
                }
                column(DocType_VendLedgEntry2; "Document Type")
                {
                }
                column(ExtDocNo_VendLedgEntry2; "External Document No.")
                {
                }
                column(LineDiscount_VendLedgEntry2; -LineDiscount)
                {
                    AutoFormatExpression = "Vendor Ledger Entry"."Currency Code";
                    AutoFormatType = 1;
                }
                column(CurrCode_VendLedgEntry2; CurrencyCode("Currency Code"))
                {
                }
                column(DocDateFormat_VendLedgEntry2; Format("Document Date"))
                {
                }
                column(PostingDateFormat_VendLedgEntry2; Format(VendLedgEntry2."Posting Date")) { }
                column(LAmountWDiscCur; LAmountWDiscCur)
                {
                }
                column(EntryNo_VendLedgEntry2; "Entry No.")
                {
                }
                dataitem("Detailed Vendor Ledg. Entry"; "Detailed Vendor Ledg. Entry")
                {
                    DataItemLink = "Vendor Ledger Entry No." = field("Entry No."), "Initial Document Type" = field("Document Type");
                    DataItemTableView = sorting("Vendor Ledger Entry No.", "Entry Type", "Posting Date") where("Entry Type" = const(Application), "Document Type" = const("Credit Memo"));
                    column(LineDisc_DtldVendLedgEntry; -LineDiscount)
                    {
                        AutoFormatExpression = "Vendor Ledger Entry"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VendLedgEntry3RemAmt; -VendLedgEntry3."Remaining Amount")
                    {
                        AutoFormatExpression = "Vendor Ledger Entry"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Amt_DtldVendLedgEntry; -Amount)
                    {
                        AutoFormatExpression = "Vendor Ledger Entry"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VendLedgEntry3CurrCode; CurrencyCode(VendLedgEntry3."Currency Code"))
                    {
                    }
                    column(VendLedgEntry3DocDateFormat; Format(VendLedgEntry3."Document Date"))
                    {
                    }
                    column(VendLedgEntry3PostingDateFormat; Format(VendLedgEntry3."Posting Date"))
                    {
                    }
                    column(VendLedgEntry3ExtDocNo; VendLedgEntry3."External Document No.")
                    {
                    }
                    column(DocType_DtldVendLedgEntry; "Document Type")
                    {
                    }
                    column(VendLedgerEntryNo_DtldVendLedgEntry; "Vendor Ledger Entry No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        VendLedgEntry3.Get("Applied Vend. Ledger Entry No.");
                        if "Vendor Ledger Entry No." = "Applied Vend. Ledger Entry No." then
                            CurrReport.Skip();
                        VendLedgEntry3.CalcFields(Amount, "Remaining Amount");
                        LineAmount := VendLedgEntry3.Amount - VendLedgEntry3."Remaining Amount";
                        LineDiscount :=
                          CurrExchRate.ExchangeAmtFCYToFCY(
                            "Posting Date", '', "Currency Code",
                            VendLedgEntry3."Pmt. Disc. Rcd.(LCY)");
                        LineDiscountCurr :=
                          CurrExchRate.ExchangeAmtFCYToFCY(
                            VendLedgEntry3."Posting Date", '', "Vendor Ledger Entry"."Currency Code",
                            VendLedgEntry3."Pmt. Disc. Rcd.(LCY)");

                        VendLedgEntry3.Amount :=
                          VendLedgEntry3.Amount + LineDiscountCurr;
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
                begin
                    CalcFields(Amount, "Remaining Amount");
                    DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", "Entry No.");
                    DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
                    DtldVendLedgEntry.SetRange("Document Type", DtldVendLedgEntry."Document Type"::Payment);
                    DtldVendLedgEntry.SetRange("Document No.", "Vendor Ledger Entry"."Document No.");
                    DtldVendLedgEntry.SetRange(Unapplied, false);
                    if DtldVendLedgEntry.IsEmpty() then
                        CurrReport.Skip();
                    DtldVendLedgEntry.CalcSums(Amount, "Remaining Pmt. Disc. Possible");
                    LineAmount := DtldVendLedgEntry.Amount;

                    if "Currency Code" <> '' then begin
                        if IsDiscountAppliedToPayment("Vendor Ledger Entry"."Entry No.", "Vendor Ledger Entry"."Document No.") then
                            LineDiscount := DtldVendLedgEntry."Remaining Pmt. Disc. Possible"
                    end else
                        LineDiscount := CurrExchRate.ExchangeAmtFCYToFCY("Posting Date", '', "Currency Code", "Pmt. Disc. Rcd.(LCY)");

                    "Vendor Ledger Entry".Amount += LineDiscount;

                    LAmountWDiscCur := -LineAmount - LineDiscount;
                end;

                trigger OnPreDataItem()
                begin
                    CreateVendLedgEntry := "Vendor Ledger Entry";
                    FindApplnEntriesDtldtLedgEntry();
                    SetCurrentKey("Entry No.");
                    SetRange("Entry No.");

                    if CreateVendLedgEntry."Closed by Entry No." <> 0 then begin
                        "Entry No." := CreateVendLedgEntry."Closed by Entry No.";
                        Mark(true);
                    end;

                    SetCurrentKey("Closed by Entry No.");
                    SetRange("Closed by Entry No.", CreateVendLedgEntry."Entry No.");
                    if Find('-') then
                        repeat
                            Mark(true);
                        until Next() = 0;

                    SetCurrentKey("Entry No.");
                    SetRange("Closed by Entry No.");
                    MarkedOnly(true);
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(Amount_VendLedgEntry; "Vendor Ledger Entry".Amount)
                {
                    AutoFormatExpression = "Vendor Ledger Entry"."Currency Code";
                    AutoFormatType = 1;
                }
                column(CurrCode_VendLedgEntry; CurrencyCode("Vendor Ledger Entry"."Currency Code"))
                {
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                Vend.Get("Vendor No.");
                FormatAddr.Vendor(VendorAddr, Vend);
                CalcFields(Amount);
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
        CompanyInfo.Get();
        FormatAddr.Company(CompanyAddr, CompanyInfo);
        GLSetup.Get();
        GLSetup.TestField("LCY Code");
    end;

    var
        Vend: Record Vendor;
        GLSetup: Record "General Ledger Setup";
        CurrExchRate: Record "Currency Exchange Rate";
        CreateVendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry3: Record "Vendor Ledger Entry";
        FormatAddr: Codeunit "Format Address";
        LineAmount: Decimal;
        LineDiscount: Decimal;
        LineDiscountCurr: Decimal;
        LAmountWDiscCur: Decimal;
        RemittanceAdvCaptionLbl: Label 'Remittance Advice';
        PhoneNoCaptionLbl: Label 'Phone No.';
        FaxNoCaptionLbl: Label 'Fax No.';
        VATRegNoCaptionLbl: Label 'VAT Reg. No.';
        BankCaptionLbl: Label 'Bank';
        AccNoCaptionLbl: Label 'Account No.';
        SortCodeCaptionLbl: Label 'Sort Code';
        AmtCaptionLbl: Label 'Amount';
        PmtDiscTakenCaptionLbl: Label 'Pmt. Disc. Taken';
        RemAmtCaptionLbl: Label 'Remaining Amount';
        OriginalAmtCaptionLbl: Label 'Original Amount';
        YourDocNoCaptionLbl: Label 'Your Document No.';
        OurDocNoCaptionLbl: Label 'Our Document No.';
        CurrCodeCaptionLbl: Label 'Curr. Code';
        DocDateCaptionLbl: Label 'Document Date';
        PostingDateCaptionLbl: Label 'Posting Date';
        TotalCaptionLbl: Label 'Total';

    protected var
        CompanyInfo: Record "Company Information";
        VendorAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];

    procedure CurrencyCode(SrcCurrCode: Code[10]): Code[10]
    begin
        if SrcCurrCode = '' then
            exit(GLSetup."LCY Code");

        exit(SrcCurrCode);
    end;

    local procedure FindApplnEntriesDtldtLedgEntry()
    var
        DtldVendLedgEntry1: Record "Detailed Vendor Ledg. Entry";
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry1.Reset();
        DtldVendLedgEntry1.SetCurrentKey("Vendor Ledger Entry No.");
        DtldVendLedgEntry1.SetRange("Vendor Ledger Entry No.", CreateVendLedgEntry."Entry No.");
        DtldVendLedgEntry1.SetRange(Unapplied, false);
        if DtldVendLedgEntry1.Find('-') then
            repeat
                if DtldVendLedgEntry1."Vendor Ledger Entry No." =
                   DtldVendLedgEntry1."Applied Vend. Ledger Entry No."
                then begin
                    DtldVendLedgEntry2.Reset();
                    DtldVendLedgEntry2.SetCurrentKey("Applied Vend. Ledger Entry No.", "Entry Type");
                    DtldVendLedgEntry2.SetRange(
                      "Applied Vend. Ledger Entry No.", DtldVendLedgEntry1."Applied Vend. Ledger Entry No.");
                    DtldVendLedgEntry2.SetRange("Entry Type", DtldVendLedgEntry2."Entry Type"::Application);
                    DtldVendLedgEntry2.SetRange(Unapplied, false);
                    if DtldVendLedgEntry2.Find('-') then
                        repeat
                            if DtldVendLedgEntry2."Vendor Ledger Entry No." <>
                               DtldVendLedgEntry2."Applied Vend. Ledger Entry No."
                            then begin
                                VendLedgEntry2.SetCurrentKey("Entry No.");
                                VendLedgEntry2.SetRange("Entry No.", DtldVendLedgEntry2."Vendor Ledger Entry No.");
                                if VendLedgEntry2.Find('-') then
                                    VendLedgEntry2.Mark(true);
                            end;
                        until DtldVendLedgEntry2.Next() = 0;
                end else begin
                    VendLedgEntry2.SetCurrentKey("Entry No.");
                    VendLedgEntry2.SetRange("Entry No.", DtldVendLedgEntry1."Applied Vend. Ledger Entry No.");
                    if VendLedgEntry2.Find('-') then
                        VendLedgEntry2.Mark(true);
                end;
            until DtldVendLedgEntry1.Next() = 0;
    end;

    local procedure IsDiscountAppliedToPayment(VendLedgEntryNo: Integer; DocNo: Code[20]): Boolean
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.LoadFields("Vendor Ledger Entry No.", "Entry Type", "Document Type", "Document No.", "Currency Code", Unapplied);
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntryNo);
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::"Payment Discount");
        DtldVendLedgEntry.SetRange("Document Type", DtldVendLedgEntry."Document Type"::Payment);
        DtldVendLedgEntry.SetRange("Document No.", DocNo);
        DtldVendLedgEntry.SetFilter("Currency Code", '<>%1', '');
        DtldVendLedgEntry.SetRange(Unapplied, false);
        if not DtldVendLedgEntry.IsEmpty() then
            exit(true);
    end;
}

