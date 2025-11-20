// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 399 "Remittance Advice - Journal"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/RemittanceAdviceJournal.rdlc';
    Caption = 'Remittance Advice - Journal';
    WordMergeDataItem = VendLoop;

    dataset
    {
        dataitem(FindVendors; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
            RequestFilterFields = "Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.";

            trigger OnAfterGetRecord()
            begin
                if ("Account Type" = "Account Type"::Vendor) and
                   ("Account No." <> '')
                then
                    if not TempVend.Get("Account No.") then begin
                        Vend.Get("Account No.");
                        TempVend := Vend;
                        TempVend.Insert();
                    end;
            end;
        }
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";

            trigger OnPreDataItem()
            begin
                // Dataitem is here just to display request form - filters set by the user will be used later.
                CurrReport.Break();
            end;
        }
        dataitem(VendLoop; "Integer")
        {
            DataItemTableView = sorting(Number);
            column(VendAddr1; VendorAddr[1])
            {
            }
            column(VendAddr2; VendorAddr[2])
            {
            }
            column(CompAddr1; CompanyAddr[1])
            {
            }
            column(CompAddr2; CompanyAddr[2])
            {
            }
            column(VendAddr3; VendorAddr[3])
            {
            }
            column(CompAddr3; CompanyAddr[3])
            {
            }
            column(VendorAddr4; VendorAddr[4])
            {
            }
            column(CompAddr4; CompanyAddr[4])
            {
            }
            column(VendAddr5; VendorAddr[5])
            {
            }
            column(CompAddr5; CompanyAddr[5])
            {
            }
            column(VendAddr6; VendorAddr[6])
            {
            }
            column(CompAddr6; CompanyAddr[6])
            {
            }
            column(CompAddr7; CompanyAddr[7])
            {
            }
            column(CompAddr8; CompanyAddr[8])
            {
            }
            column(VendAddr7; VendorAddr[7])
            {
            }
            column(CompInfoPhoneNo; CompanyInfo."Phone No.")
            {
            }
            column(VendAddr8; VendorAddr[8])
            {
            }
            column(CompInfoFaxNo; CompanyInfo."Fax No.")
            {
            }
            column(CompInfoVATRegNo; CompanyInfo."VAT Registration No.")
            {
            }
            column(CompInfoBankName; CompanyInfo."Bank Name")
            {
            }
            column(CompInfoBankBranchNo; CompanyInfo."Bank Branch No.")
            {
            }
            column(CompInfoBankAccNo; CompanyInfo."Bank Account No.")
            {
            }
            column(VendLoopNumber; Number)
            {
            }
            column(RemittanceAdviceCaption; RemittanceAdviceCaptionLbl)
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
            column(BankCaption; BankCaptionLbl)
            {
            }
            column(SortCodeCaption; SortCodeCaptionLbl)
            {
            }
            column(AccNoCaption; AccNoCaptionLbl)
            {
            }
            column(OriginalAmtCaption; OriginalAmtCaptionLbl)
            {
            }
            column(DocDateCaption; DocumentDateCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl) { }
            column(DocNoCaption; YourDocumentNoCaptionLbl)
            {
            }
            column(DocTypeCaption; DocTypeCaptionLbl)
            {
            }
            column(CheckNoCaption; OurDocumentNoCaptionLbl)
            {
            }
            column(RemainingAmtCaption; RemainingAmountCaptionLbl)
            {
            }
            column(PmdDiscRecCaption; PmtDiscReceivedCaptionLbl)
            {
            }
            column(PaidAmtCaption; PaymentCurrAmtCaptionLbl)
            {
            }
            column(CurrCodeCaption; CurrCodeCaptionLbl)
            {
            }
            dataitem("Gen. Journal Line"; "Gen. Journal Line")
            {
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.") where("Account Type" = const(Vendor));
                column(CheckNo; CheckNo)
                {
                }
                column(Amt_GenJournalLine; Amount)
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(CurrCode; CurrencyCode("Currency Code"))
                {
                }
                column(JnlBatchName_GenJournalLine; "Journal Batch Name")
                {
                }
                column(DocNo_GenJnlLine; "Document No.")
                {
                }
                column(AccNo_GenJournalLine; "Account No.")
                {
                }
                column(AppliestoDocType_GenJnlLine; "Applies-to Doc. Type")
                {
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
                dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
                {
                    DataItemLink = "Applies-to ID" = field("Applies-to ID"), "Vendor No." = field("Account No.");
                    DataItemTableView = sorting("Vendor No.", Open, Positive, "Due Date", "Currency Code") where(Open = const(true));
                    dataitem("Detailed Vendor Ledg. Entry"; "Detailed Vendor Ledg. Entry")
                    {
                        DataItemLink = "Vendor Ledger Entry No." = field("Entry No."), "Initial Document Type" = field("Document Type");
                        DataItemTableView = sorting("Vendor Ledger Entry No.", "Entry Type", "Posting Date") where("Entry Type" = const(Application), "Document Type" = const("Credit Memo"));

                        trigger OnAfterGetRecord()
                        begin
                            VendLedgEntry3.Get("Applied Vend. Ledger Entry No.");
                            if "Vendor Ledger Entry No." <> "Applied Vend. Ledger Entry No." then
                                InsertTempEntry(VendLedgEntry3);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        InsertTempEntry("Vendor Ledger Entry")
                    end;

                    trigger OnPreDataItem()
                    begin
                        if "Gen. Journal Line"."Applies-to ID" = '' then
                            CurrReport.Break();
                    end;
                }
                dataitem(VendLedgEntry2; "Vendor Ledger Entry")
                {
                    DataItemLink = "Document No." = field("Applies-to Doc. No."), "Vendor No." = field("Account No."), "Document Type" = field("Applies-to Doc. Type");
                    DataItemTableView = sorting("Vendor No.", Open, Positive, "Due Date") where(Open = const(true));
                    dataitem(DetailVendLedgEntry2; "Detailed Vendor Ledg. Entry")
                    {
                        DataItemLink = "Vendor Ledger Entry No." = field("Entry No."), "Initial Document Type" = field("Document Type");
                        DataItemTableView = sorting("Vendor Ledger Entry No.", "Entry Type", "Posting Date") where("Entry Type" = const(Application), "Document Type" = const("Credit Memo"));

                        trigger OnAfterGetRecord()
                        begin
                            VendLedgEntry3.Get("Applied Vend. Ledger Entry No.");
                            if "Vendor Ledger Entry No." <> "Applied Vend. Ledger Entry No." then
                                InsertTempEntry(VendLedgEntry3);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        InsertTempEntry(VendLedgEntry2);
                    end;
                }
                dataitem(PrintLoop; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(AppliedVendLedgEntryTempDocType; Format(TempAppliedVendLedgEntry."Document Type"))
                    {
                    }
                    column(AppliedVendLedgEntryTempExternalDocNo; TempAppliedVendLedgEntry."External Document No.")
                    {
                    }
                    column(AppliedVendLedgEntryTempDocDate; Format(TempAppliedVendLedgEntry."Document Date"))
                    {
                    }
                    column(AppliedVendLedgEntryTempPostingDate; Format(TempAppliedVendLedgEntry."Posting Date")) { }
                    column(AppliedVendLedgEntryTempCurrCode; TempAppliedVendLedgEntry."Currency Code")
                    {
                    }
                    column(AppliedVendLedgEntryTempOriginalAmt; -TempAppliedVendLedgEntry."Original Amount")
                    {
                    }
                    column(AppliedVendLedgEntryTempRemainingAmt; -TempAppliedVendLedgEntry."Remaining Amount")
                    {
                    }
                    column(PmdDiscRec; PmdDiscRec)
                    {
                    }
                    column(PaidAmount; PaidAmount)
                    {
                    }
                    column(PrintLoopNumber; Number)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then
                            TempAppliedVendLedgEntry.Find('-')
                        else
                            TempAppliedVendLedgEntry.Next();
                        if JnlLineRemainingAmount < 0 then
                            CurrReport.Skip();
                        TempAppliedVendLedgEntry.CalcFields("Remaining Amount", "Original Amount");

                        // Currency
                        if TempAppliedVendLedgEntry."Currency Code" <> "Gen. Journal Line"."Currency Code" then begin
                            TempAppliedVendLedgEntry."Remaining Amount" :=
                              CurrExchRate.ExchangeAmtFCYToFCY(
                                "Gen. Journal Line"."Posting Date",
                                TempAppliedVendLedgEntry."Currency Code",
                                "Gen. Journal Line"."Currency Code",
                                TempAppliedVendLedgEntry."Remaining Amount");
                            TempAppliedVendLedgEntry."Remaining Amount" := Round(TempAppliedVendLedgEntry."Remaining Amount", AmountRoundingPrecision);

                            TempAppliedVendLedgEntry."Amount to Apply" :=
                              CurrExchRate.ExchangeAmtFCYToFCY(
                                "Gen. Journal Line"."Posting Date",
                                TempAppliedVendLedgEntry."Currency Code",
                                "Gen. Journal Line"."Currency Code",
                                TempAppliedVendLedgEntry."Amount to Apply");
                            TempAppliedVendLedgEntry."Amount to Apply" := Round(TempAppliedVendLedgEntry."Amount to Apply", AmountRoundingPrecision);

                            PmtDiscInvCurr := TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
                            TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible" :=
                              CurrExchRate.ExchangeAmtFCYToFCY(
                                "Gen. Journal Line"."Posting Date",
                                TempAppliedVendLedgEntry."Currency Code", "Gen. Journal Line"."Currency Code",
                                TempAppliedVendLedgEntry."Original Pmt. Disc. Possible");
                            TempAppliedVendLedgEntry."Original Pmt. Disc. Possible" :=
                              Round(TempAppliedVendLedgEntry."Original Pmt. Disc. Possible", AmountRoundingPrecision);
                        end;

                        // Payment Discount
                        if ("Gen. Journal Line"."Document Type" = "Gen. Journal Line"."Document Type"::Payment) and
                           (TempAppliedVendLedgEntry."Document Type" in
                            [TempAppliedVendLedgEntry."Document Type"::Invoice, TempAppliedVendLedgEntry."Document Type"::"Credit Memo"]) and
                           ("Gen. Journal Line"."Posting Date" <= TempAppliedVendLedgEntry."Pmt. Discount Date") and
                           (Abs(TempAppliedVendLedgEntry."Remaining Amount") >= Abs(TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible"))
                        then
                            PmdDiscRec := TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible"
                        else
                            PmdDiscRec := 0;

                        TempAppliedVendLedgEntry."Remaining Amount" := TempAppliedVendLedgEntry."Remaining Amount" - PmdDiscRec;
                        TempAppliedVendLedgEntry."Amount to Apply" := TempAppliedVendLedgEntry."Amount to Apply" - PmdDiscRec;

                        if TempAppliedVendLedgEntry."Remaining Amount" > 0 then
                            if TempAppliedVendLedgEntry."Amount to Apply" < 0 then begin
                                PaidAmount := -TempAppliedVendLedgEntry."Amount to Apply";
                                TempAppliedVendLedgEntry."Remaining Amount" := TempAppliedVendLedgEntry."Remaining Amount" - PaidAmount;
                            end else begin
                                PaidAmount := -TempAppliedVendLedgEntry."Amount to Apply";
                                TempAppliedVendLedgEntry."Remaining Amount" := TempAppliedVendLedgEntry."Remaining Amount" + PaidAmount;
                            end
                        else begin
                            if Abs(TempAppliedVendLedgEntry."Remaining Amount") > Abs(JnlLineRemainingAmount) then
                                if TempAppliedVendLedgEntry."Amount to Apply" < 0 then
                                    PaidAmount := Abs(TempAppliedVendLedgEntry."Amount to Apply")
                                else
                                    PaidAmount := Abs(JnlLineRemainingAmount)
                            else
                                if TempAppliedVendLedgEntry."Amount to Apply" < 0 then
                                    PaidAmount := Abs(TempAppliedVendLedgEntry."Amount to Apply")
                                else
                                    PaidAmount := Abs(TempAppliedVendLedgEntry."Remaining Amount");
                            TempAppliedVendLedgEntry."Remaining Amount" := TempAppliedVendLedgEntry."Remaining Amount" + PaidAmount;
                            JnlLineRemainingAmount := JnlLineRemainingAmount - PaidAmount;
                            if JnlLineRemainingAmount < 0 then begin
                                TempAppliedVendLedgEntry."Remaining Amount" := TempAppliedVendLedgEntry."Remaining Amount" + JnlLineRemainingAmount;
                                PaidAmount := PaidAmount + TempAppliedVendLedgEntry."Remaining Amount";
                                JnlLineRemainingAmount := 0;
                            end;
                        end;

                        // Numbers to print
                        if TempAppliedVendLedgEntry."Currency Code" <> "Gen. Journal Line"."Currency Code" then
                            if PmdDiscRec <> 0 then
                                PmdDiscRec := PmtDiscInvCurr;
                        TempAppliedVendLedgEntry."Remaining Amount" :=
                          CurrExchRate.ExchangeAmtFCYToFCY(
                            "Gen. Journal Line"."Posting Date",
                            "Gen. Journal Line"."Currency Code",
                            TempAppliedVendLedgEntry."Currency Code",
                            TempAppliedVendLedgEntry."Remaining Amount");
                    end;

                    trigger OnPostDataItem()
                    begin
                        TempAppliedVendLedgEntry.DeleteAll();
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, TempAppliedVendLedgEntry.Count);
                        JnlLineRemainingAmount := JnlLineRemainingAmount + AppliedDebitAmounts;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if "Document No." <> CheckNo then begin
                        JnlLineRemainingAmount := 0;
                        AppliedDebitAmounts := 0;
                    end;

                    CheckNo := "Document No.";
                    JnlLineRemainingAmount := JnlLineRemainingAmount + Amount;

                    FindAmountRounding();
                    AppliedDebitAmounts := 0;

                    VendorTotal += Amount;
                end;

                trigger OnPreDataItem()
                begin
                    CopyFilters(FindVendors);
                    SetRange("Account No.", TempVend."No.");
                end;
            }
            dataitem(PrintTotal; "Integer")
            {
                DataItemTableView = where(Number = const(1));
                column(TotalAmount; VendorTotal)
                {
                }
                column(TotalCurrCode; CurrencyCode("Gen. Journal Line"."Currency Code"))
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    TempVend.Find('-')
                else
                    TempVend.Next();

                FormatAddr.Vendor(VendorAddr, TempVend);

                JnlLineRemainingAmount := 0;
                VendorTotal := 0;
            end;

            trigger OnPreDataItem()
            begin
                TempVend.CopyFilters(Vendor);
                SetRange(Number, 1, TempVend.Count);
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
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Vend: Record Vendor;
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        VendLedgEntry3: Record "Vendor Ledger Entry";
        FormatAddr: Codeunit "Format Address";
        JnlLineRemainingAmount: Decimal;
        AmountRoundingPrecision: Decimal;
        PmdDiscRec: Decimal;
        PmtDiscInvCurr: Decimal;
        AppliedDebitAmounts: Decimal;
        VendorTotal: Decimal;
        CheckNo: Code[20];
        RemittanceAdviceCaptionLbl: Label 'Remittance Advice';
        PhoneNoCaptionLbl: Label 'Phone No.';
        FaxNoCaptionLbl: Label 'Fax No.';
        VATRegNoCaptionLbl: Label 'VAT Reg. No.';
        BankCaptionLbl: Label 'Bank';
        SortCodeCaptionLbl: Label 'Sort Code';
        AccNoCaptionLbl: Label 'Account No.';
        OriginalAmtCaptionLbl: Label 'Original Amount';
        DocumentDateCaptionLbl: Label 'Document Date';
        PostingDateCaptionLbl: Label 'Posting Date';
        YourDocumentNoCaptionLbl: Label 'Your Document No.';
        DocTypeCaptionLbl: Label 'Doc. Type';
        OurDocumentNoCaptionLbl: Label 'Our Document No.';
        RemainingAmountCaptionLbl: Label 'Remaining Amount';
        PmtDiscReceivedCaptionLbl: Label 'Pmt. Disc. Received';
        PaymentCurrAmtCaptionLbl: Label 'Payment Curr. Amount';
        CurrCodeCaptionLbl: Label 'Curr. Code';
        TotalCaptionLbl: Label 'Total';

    protected var
        CompanyInfo: Record "Company Information";
        TempAppliedVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        TempVend: Record Vendor temporary;
        VendorAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        PaidAmount: Decimal;

    local procedure CurrencyCode(SrcCurrCode: Code[10]): Code[10]
    begin
        if SrcCurrCode = '' then
            exit(GLSetup."LCY Code");

        exit(SrcCurrCode);
    end;

    local procedure FindAmountRounding()
    begin
        if "Gen. Journal Line"."Currency Code" = '' then begin
            Currency.Init();
            Currency.Code := '';
            Currency.InitRoundingPrecision();
        end else
            if "Gen. Journal Line"."Currency Code" <> Currency.Code then
                Currency.Get("Gen. Journal Line"."Currency Code");

        AmountRoundingPrecision := Currency."Amount Rounding Precision";
    end;

    local procedure InsertTempEntry(VendLedgEntryToInsert: Record "Vendor Ledger Entry")
    var
        AppAmt: Decimal;
    begin
        TempAppliedVendLedgEntry := VendLedgEntryToInsert;
        if TempAppliedVendLedgEntry.Insert() then begin
            // Find Debit amounts, e.g. credit memos
            TempAppliedVendLedgEntry.CalcFields("Remaining Amt. (LCY)");
            if TempAppliedVendLedgEntry."Remaining Amt. (LCY)" > 0 then begin
                JnlLineRemainingAmount += TempAppliedVendLedgEntry."Amount to Apply";
                AppAmt := TempAppliedVendLedgEntry."Remaining Amt. (LCY)";
                if "Gen. Journal Line"."Currency Code" <> '' then begin
                    AppAmt :=
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        "Gen. Journal Line"."Posting Date",
                        "Gen. Journal Line"."Currency Code",
                        AppAmt,
                        "Gen. Journal Line"."Currency Factor");
                    AppAmt := Round(AppAmt, AmountRoundingPrecision);
                end;
                AppliedDebitAmounts := AppliedDebitAmounts + AppAmt;
            end;
        end;
    end;
}

