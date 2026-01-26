// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

report 3010545 "DTA Payment Journal"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/DTAPaymentJournal.rdlc';
    Caption = 'DTA Payment Journal';

    dataset
    {
        dataitem("Gen. Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Posting Date", Clearing, "Debit Bank");
            column(JournalBatchName_GenJournalLine; "Journal Batch Name")
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(intLayout; intLayout)
            {
            }
            column(AccountNo_GenJournalLine; "Account No.")
            {
            }
            column(VendorLedgerEntryDueDate; Format(VendorLedgerEntry."Due Date"))
            {
            }
            column(AppliestoDocNo_GenJournalLine; "Applies-to Doc. No.")
            {
            }
            column(CurrencyCode_GenJournalLine; "Currency Code")
            {
            }
            column(Amount_GenJournalLine; Amount)
            {
            }
            column(CashDiscAmtFC; CashDiscAmtFC)
            {
            }
            column(CashDeductAmt; CashDeductAmt)
            {
            }
            column(AgeDays; AgeDays)
            {
            }
            column(CashDiscDays; CashDiscDays)
            {
            }
            column(DueDays; DueDays)
            {
            }
            column(OpenRemAmtFC; OpenRemAmtFC)
            {
            }
            column(RestAfterPmt; RestAfterPmt)
            {
            }
            column(VendorName; Vendor.Name)
            {
            }
            column(PmtToleranceAmount; PmtToleranceAmount)
            {
            }
            column(VendorBankAccountPaymentForm; VendorBankAccount."Payment Form")
            {
                OptionCaption = 'ESR,ESR+,Post Payment Domestic,Bank Payment Domestic,Cash Outpayment Order Domestic,Post Payment Abroad,Bank Payment Abroad,SWIFT Payment Abroad,Cash Outpayment Order Abroad';
                OptionMembers = ESR,"ESR+","Post Payment Domestic","Bank Payment Domestic","Cash Outpayment Order Domestic","Post Payment Abroad","Bank Payment Abroad","SWIFT Payment Abroad","Cash Outpayment Order Abroad";
            }
            column(xAcc; xAcc)
            {
            }
            column(xTxt; xTxt)
            {
            }
            column(BankCode_GenJournalLine; "Recipient Bank Account")
            {
            }
            column(DebitBank_GenJournalLine; "Debit Bank")
            {
            }
            column(VendorLedgerEntryExternalDocumentNo; VendorLedgerEntry."External Document No.")
            {
            }
            column(TotalVendorTxt; TotalVendorTxt)
            {
            }
            column(AmountLCY_GenJournalLine; "Amount (LCY)")
            {
            }
            column(GenJournalLineTotalBankDebitBank; Text006Msg + ' ' + "Debit Bank")
            {
            }
            column(GlSetupLCYCode; GLSetup."LCY Code")
            {
            }
            column(n; n)
            {
            }
            column(LargestAmt; LargestAmt)
            {
            }
            column(PostingDate_GenJournalLine; Format("Posting Date"))
            {
            }
            column(TotalPaymentGlSetupLCYCode; StrSubstNo(Text007Lbl, GLSetup."LCY Code"))
            {
            }
            column(LargestAmtGlSetupLCYCode; StrSubstNo(Text008Lbl, GLSetup."LCY Code"))
            {
            }
            column(BatchNameCaption; BatchNameCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(DTAPaymentJournalCaption; DTAPaymentJournalCaptionLbl)
            {
            }
            column(PaymentCaption; PaymentCaptionLbl)
            {
            }
            column(AgeCaption; AgeCaptionLbl)
            {
            }
            column(PossCaption; PossCaptionLbl)
            {
            }
            column(DeduCaption; DeduCaptionLbl)
            {
            }
            column(VendorCaption; VendorCaptionLbl)
            {
            }
            column(CashDiscCaption; CashDiscCaptionLbl)
            {
            }
            column(BeforePmtCaption; BeforePmtCaptionLbl)
            {
            }
            column(RestAfterPmtCaption; RestAfterPmtCaptionLbl)
            {
            }
            column(OpenRemAmountCaption; OpenRemAmountCaptionLbl)
            {
            }
            column(ApplicationCaption; ApplicationCaptionLbl)
            {
            }
            column(DateDaysCaption; DateDaysCaptionLbl)
            {
            }
            column(DueCaption; DueCaptionLbl)
            {
            }
            column(CashDiscDaysCaption; CashDiscDaysCaptionLbl)
            {
            }
            column(ToleranceCaption; ToleranceCaptionLbl)
            {
            }
            column(CurrencyCodeCaption_GenJournalLine; FieldCaption("Currency Code"))
            {
            }
            column(BankCaption; BankCaptionLbl)
            {
            }
            column(ReferenceCommentCaption; ReferenceCommentCaptionLbl)
            {
            }
            column(PaymentTypeCaption; PaymentTypeCaptionLbl)
            {
            }
            column(AccountCaption; AccountCaptionLbl)
            {
            }
            column(DebitBankCaption; DebitBankCaptionLbl)
            {
            }
            column(ExternalDocumentCaption; ExternalDocumentCaptionLbl)
            {
            }
            column(VendorBankCaption; VendorBankCaptionLbl)
            {
            }
            column(NoOfPaymentsCaption; NoOfPaymentsCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(LineNo_GenJournalLine; "Line No.")
            {
            }
            column(Clearing_GenJournalLine; Clearing)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if ("Account No." = '') and (Amount = 0) then
                    CurrReport.Skip();

                if oldAccNo <> "Account No." then begin
                    oldAccNo := "Account No.";
                    NoOfLinesPerVendor := 0;
                end;

                AgeDays := 0;
                CashDiscDays := 0;
                DueDays := 0;
                CashDeductAmt := 0;
                RestAfterPmt := 0;
                PmtToleranceAmount := 0;
                xTxt := '';
                xAcc := '';
                Clear(VendorLedgerEntry);
                Clear(VendorBankAccount);
                Vendor.Get("Account No.");

                // Vendor Entries
                if "Applies-to Doc. No." = '' then
                    xTxt := Text000Err
                else begin
                    VendorLedgerEntry.SetCurrentKey("Document No.");
                    VendorLedgerEntry.SetRange("Document Type", "Applies-to Doc. Type");
                    VendorLedgerEntry.SetRange("Document No.", "Applies-to Doc. No.");
                    VendorLedgerEntry.SetRange("Vendor No.", "Account No.");
                    if not VendorLedgerEntry.FindFirst() then
                        xTxt := Text001Err
                    else begin
                        if not VendorLedgerEntry.Open then
                            xTxt := Text002Err;

                        VendorLedgerEntry.CalcFields("Remaining Amount");

                        // Calc day for age, due date and cash disc.
                        if VendorLedgerEntry."Posting Date" > 0D then
                            AgeDays := "Posting Date" - VendorLedgerEntry."Posting Date";
                        if VendorLedgerEntry."Pmt. Discount Date" > 0D then
                            CashDiscDays := VendorLedgerEntry."Pmt. Discount Date" - "Posting Date";
                        if VendorLedgerEntry."Due Date" > 0D then
                            DueDays := VendorLedgerEntry."Due Date" - "Posting Date";

                        OpenRemAmtFC := -VendorLedgerEntry."Remaining Amount";
                        CashDiscAmtFC := -VendorLedgerEntry."Remaining Pmt. Disc. Possible";

                        // Open entry and remaining for multicurrency. Convert to pmt currency
                        if VendorLedgerEntry."Currency Code" <> "Currency Code" then begin
                            OpenRemAmtFC :=
                              CurrencyExchangeRate.ExchangeAmtFCYToFCY(
                                "Posting Date", VendorLedgerEntry."Currency Code", "Currency Code", -VendorLedgerEntry."Remaining Amount");
                            CashDiscAmtFC :=
                              CurrencyExchangeRate.ExchangeAmtFCYToFCY(
                                "Posting Date", VendorLedgerEntry."Currency Code", "Currency Code", -VendorLedgerEntry."Original Pmt. Disc. Possible");
                        end;

                        if (VendorLedgerEntry."Pmt. Discount Date" >= "Posting Date") or
                           ((VendorLedgerEntry."Pmt. Disc. Tolerance Date" >= "Posting Date") and
                            VendorLedgerEntry."Accepted Pmt. Disc. Tolerance")
                        then
                            CashDeductAmt := -VendorLedgerEntry."Remaining Pmt. Disc. Possible";

                        PmtToleranceAmount := -VendorLedgerEntry."Accepted Payment Tolerance";

                        // Calc rest after pmt (and evtl. cash disc)
                        RestAfterPmt := OpenRemAmtFC - Amount - CashDeductAmt - PmtToleranceAmount;
                        if RestAfterPmt > 0 then begin
                            RestAfterPmt := RestAfterPmt + CashDeductAmt;
                            CashDeductAmt := 0;
                        end;
                    end;
                end;

                // Vendor Bank Account
                if "Recipient Bank Account" = '' then
                    xTxt := Text003Err
                else
                    if not VendorBankAccount.Get("Account No.", "Recipient Bank Account") then
                        xTxt := Text004Err;

                if xTxt = '' then
                    case VendorBankAccount."Payment Form" of
                        VendorBankAccount."Payment Form"::ESR, VendorBankAccount."Payment Form"::"ESR+":
                            begin
                                xAcc := VendorBankAccount."ESR Account No.";
                                xTxt := VendorLedgerEntry."Reference No.";
                            end;
                        VendorBankAccount."Payment Form"::"Post Payment Domestic":
                            if VendorBankAccount.IBAN <> '' then
                                xAcc := DTAMgt.IBANDELCHR(VendorBankAccount.IBAN)
                            else
                                xAcc := VendorBankAccount."Giro Account No.";
                        VendorBankAccount."Payment Form"::"Bank Payment Domestic":
                            if VendorBankAccount.IBAN <> '' then
                                xAcc := DTAMgt.IBANDELCHR(VendorBankAccount.IBAN)
                            else begin
                                xTxt := VendorBankAccount."Clearing No.";
                                xAcc := VendorBankAccount."Bank Account No.";
                            end;
                        VendorBankAccount."Payment Form"::"Post Payment Abroad":
                            if VendorBankAccount.IBAN <> '' then
                                xAcc := DTAMgt.IBANDELCHR(VendorBankAccount.IBAN)
                            else
                                xAcc := VendorBankAccount."Bank Account No.";
                        VendorBankAccount."Payment Form"::"Bank Payment Abroad":
                            if VendorBankAccount.IBAN <> '' then
                                xAcc := DTAMgt.IBANDELCHR(VendorBankAccount.IBAN)
                            else begin
                                xTxt := VendorBankAccount."Bank Identifier Code";
                                xAcc := VendorBankAccount."Bank Account No.";
                            end;
                        VendorBankAccount."Payment Form"::"SWIFT Payment Abroad":
                            if VendorBankAccount.IBAN <> '' then
                                xAcc := DTAMgt.IBANDELCHR(VendorBankAccount.IBAN)
                            else begin
                                xTxt := VendorBankAccount."SWIFT Code";
                                xAcc := VendorBankAccount."Bank Account No.";
                            end;
                    end;

                n := n + 1;
                if "Amount (LCY)" > LargestAmt then
                    LargestAmt := "Amount (LCY)";

                NoOfLinesPerVendor := NoOfLinesPerVendor + 1;
                if NoOfLinesPerVendor > 1 then
                    TotalVendorTxt := Text005Msg + ' ' + "Account No." + ' ' + Vendor.Name;
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Account Type", "Account Type"::Vendor);
                SetRange("Document Type", "Document Type"::Payment);

                intLayout := Layout;
                oldAccNo := '';
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
                    field("Layout"; Layout)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Layout';
                        OptionCaption = 'Amounts,Bank';
                        ToolTip = 'Specifies the layout of the report. Layout options include Amounts and Bank.';
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
        GLSetup.Get();
    end;

    var
        Text000Err: Label 'No application number';
        Text001Err: Label 'Vendor entry not found';
        Text002Err: Label 'Vendor entry not open';
        Text003Err: Label 'Bankcode not defined';
        Text004Err: Label 'Vendor bank not found';
        Text005Msg: Label 'Total vendor';
        Text006Msg: Label 'Total bank';
        Text007Lbl: Label 'Total Payment in %1';
        Text008Lbl: Label 'Largest Amount in %1';
        VendorBankAccount: Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        DTAMgt: Codeunit DtaMgt;
        n: Integer;
        "Layout": Option Amounts,Bank;
        xTxt: Text[40];
        xAcc: Text;
        LargestAmt: Decimal;
        TotalVendorTxt: Text[80];
        NoOfLinesPerVendor: Integer;
        AgeDays: Integer;
        CashDiscDays: Integer;
        DueDays: Integer;
        OpenRemAmtFC: Decimal;
        CashDiscAmtFC: Decimal;
        CashDeductAmt: Decimal;
        PmtToleranceAmount: Decimal;
        RestAfterPmt: Decimal;
        intLayout: Integer;
        oldAccNo: Code[20];
        BatchNameCaptionLbl: Label 'Batch Name';
        PageCaptionLbl: Label 'Page';
        DTAPaymentJournalCaptionLbl: Label 'DTA - Payment Journal';
        PaymentCaptionLbl: Label 'Payment';
        AgeCaptionLbl: Label 'Age';
        PossCaptionLbl: Label 'Poss.';
        DeduCaptionLbl: Label 'Dedu.';
        VendorCaptionLbl: Label 'Vendor';
        CashDiscCaptionLbl: Label 'Cash Disc.';
        BeforePmtCaptionLbl: Label 'before Pmt.';
        RestAfterPmtCaptionLbl: Label 'after Pmt.';
        OpenRemAmountCaptionLbl: Label 'Open Rem. Amount';
        ApplicationCaptionLbl: Label 'Application';
        DateDaysCaptionLbl: Label 'Date / Days';
        DueCaptionLbl: Label 'Due';
        CashDiscDaysCaptionLbl: Label 'C Dis.';
        ToleranceCaptionLbl: Label 'Tolerance';
        BankCaptionLbl: Label 'Bank';
        ReferenceCommentCaptionLbl: Label 'Reference / Comment';
        PaymentTypeCaptionLbl: Label 'Pmt. Type';
        AccountCaptionLbl: Label 'Account';
        DebitBankCaptionLbl: Label 'Debit Bank';
        ExternalDocumentCaptionLbl: Label 'Ext. Doc.';
        VendorBankCaptionLbl: Label 'Vendor Bank';
        NoOfPaymentsCaptionLbl: Label 'No. of payments';
        PostingDateCaptionLbl: Label 'Posting Date';
}

