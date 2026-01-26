// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

report 3010531 "Customer ESR Journal"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/CustomerESRJournal.rdlc';
    Caption = 'Customer ESR Journal';
    Permissions = TableData "Cust. Ledger Entry" = rm;

    dataset
    {
        dataitem("Gen. Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.") where(Amount = filter(<> 0));
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Today_GenJournalLine; Format(Today, 0, 4))
            {
            }
            column(IntLayout; IntLayout)
            {
            }
            column(Amount; -Amount)
            {
            }
            column(CurrencyCode_GenJournalLine; "Currency Code")
            {
            }
            column(RestAfterPmt; RestAfterPmt)
            {
            }
            column(OpenRemAmtFC; OpenRemAmtFC)
            {
            }
            column(CashDeductAmt; CashDeductAmt)
            {
            }
            column(PmtDiscToleranceDays; PmtDiscToleranceDays)
            {
            }
            column(AgeDays; AgeDays)
            {
            }
            column(CashDiscDays; CashDiscDays)
            {
            }
            column(CustLedgEntry_DueDate; Format(CustLedgEntry."Due Date", 0, 1))
            {
            }
            column(DueDays; DueDays)
            {
            }
            column(AppliestoDocNo_GenJournalLine; "Applies-to Doc. No.")
            {
            }
            column(Customer_Name; Customer.Name)
            {
            }
            column(AccountNo_GenJournalLine; "Account No.")
            {
            }
            column(PmtToleranceAmount; PmtToleranceAmount)
            {
            }
            column(Microfilm; Microfilm)
            {
            }
            column(ProcessingDate; ProcessingDate)
            {
            }
            column(PaymentCharges_GenJournalLine; Format(PaymentCharges))
            {
            }
            column(ReferenceNo_GenJournalLine; "Reference No.")
            {
            }
            column(TA; TA)
            {
            }
            column(Comment; Comment)
            {
            }
            column(BalAccountNo_GenJournalLine; "Bal. Account No.")
            {
            }
            column(CustomerPostCodeCustomerCity; Customer."Post Code" + ' ' + Customer.City)
            {
            }
            column(PaymentCharges; PaymentCharges)
            {
            }
            column(PostingDate_GenJournalLine; Format("Posting Date", 0, 4))
            {
            }
            column(AmountLCY_GenJournalLine; -"Amount (LCY)")
            {
            }
            column(DocumentNo_GenJournalLine; "Document No.")
            {
            }
            column(ESRJournalCaption; ESRJournalCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(PaymentCaption; PaymentCaptionLbl)
            {
            }
            column(AfterPmtCaption; AfterPmtCaptionLbl)
            {
            }
            column(BeforePmtCaption; BeforePmtCaptionLbl)
            {
            }
            column(DedCaption; DedCaptionLbl)
            {
            }
            column(TolDaysCaption; TolDaysCaptionLbl)
            {
            }
            column(CDisCaption; CDisCaptionLbl)
            {
            }
            column(AgeCaption; AgeCaptionLbl)
            {
            }
            column(CashDiscCaption; CashDiscCaptionLbl)
            {
            }
            column(OpenRemAmountCaption; OpenRemAmountCaptionLbl)
            {
            }
            column(DateDaysCaption; DateDaysCaptionLbl)
            {
            }
            column(DueCaption; DueCaptionLbl)
            {
            }
            column(ApplicationCaption; ApplicationCaptionLbl)
            {
            }
            column(CustomerCaption; CustomerCaptionLbl)
            {
            }
            column(DeduCaption; DeduCaptionLbl)
            {
            }
            column(ToleranceCaption; ToleranceCaptionLbl)
            {
            }
            column(FilmCaption; FilmCaptionLbl)
            {
            }
            column(ProcessDateCaption; ProcessDateCaptionLbl)
            {
            }
            column(ChargesCaption; ChargesCaptionLbl)
            {
            }
            column(ReferenceNoCaption; ReferenceNoCaptionLbl)
            {
            }
            column(TACaption; TACaptionLbl)
            {
            }
            column(CommentCaption; CommentCaptionLbl)
            {
            }
            column(PostCodeCityCaption; PostCodeCityCaptionLbl)
            {
            }
            column(BalAccCaption; BalAccCaptionLbl)
            {
            }
            column(TotalChargesCaption; TotalChargesCaptionLbl)
            {
            }
            column(DebitDateCaption; DebitDateCaptionLbl)
            {
            }
            column(TotalCHFCaption; TotalCHFCaptionLbl)
            {
            }
            column(DocumentNoCaption; DocumentNoCaptionLbl)
            {
            }
            column(JournalTemplateName_GenJournalLine; "Journal Template Name")
            {
            }
            column(JournalBatchName_GenJournalLine; "Journal Batch Name")
            {
            }
            column(LineNo_GenJournalLine; "Line No.")
            {
            }

            trigger OnAfterGetRecord()
            begin
                if ("Account No." = '') and (Amount = 0) then
                    CurrReport.Skip();

                Clear(CustLedgEntry);
                Clear(Customer);
                Comment := '';
                AgeDays := 0;
                CashDiscDays := 0;
                DueDays := 0;
                CashDeductAmt := 0;
                RestAfterPmt := 0;
                OpenRemAmtFC := 0;
                PmtToleranceAmount := 0;
                PmtDiscToleranceDays := 0;

                Customer.Get("Account No.");

                // Get Cust. Ledger Entry
                if "Applies-to Doc. No." <> '' then begin
                    CustLedgEntry.SetCurrentKey("Document No.");
                    CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                    CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                    CustLedgEntry.SetRange("Customer No.", "Account No.");
                    if not CustLedgEntry.FindFirst() then begin
                        Comment := Text000;
                        exit;
                    end;

                    CustLedgEntry.CalcFields("Remaining Amount");

                    // Calc day for age, due date and cash disc.
                    if CustLedgEntry."Posting Date" > 0D then
                        AgeDays := "Posting Date" - CustLedgEntry."Posting Date";
                    if CustLedgEntry."Pmt. Discount Date" > 0D then
                        CashDiscDays := CustLedgEntry."Pmt. Discount Date" - "Posting Date";
                    if CustLedgEntry."Due Date" > 0D then
                        DueDays := CustLedgEntry."Due Date" - "Posting Date";

                    OpenRemAmtFC := CustLedgEntry."Remaining Amount";

                    // Open entry and remaining for multicurrency. Convert to pmt currency
                    if CustLedgEntry."Currency Code" <> "Currency Code" then
                        OpenRemAmtFC :=
                          ExchRate.ExchangeAmtFCYToFCY(
                            "Posting Date", CustLedgEntry."Currency Code", "Currency Code", CustLedgEntry."Remaining Amount");

                    // Amounts and Cash Disc in FC
                    if ((CustLedgEntry."Pmt. Disc. Tolerance Date" >= "Posting Date") and
                        CustLedgEntry."Accepted Pmt. Disc. Tolerance") or
                       (CustLedgEntry."Pmt. Discount Date" >= "Posting Date")
                    then
                        CashDeductAmt := CustLedgEntry."Remaining Pmt. Disc. Possible";

                    if (CustLedgEntry."Pmt. Discount Date" <> 0D) and
                       (CustLedgEntry."Pmt. Disc. Tolerance Date" <> 0D)
                    then
                        PmtDiscToleranceDays :=
                          CustLedgEntry."Pmt. Disc. Tolerance Date" - CustLedgEntry."Pmt. Discount Date";

                    PmtToleranceAmount := CustLedgEntry."Accepted Payment Tolerance";

                    // Calc rest after pmt (and evtl. cash disc)
                    RestAfterPmt := OpenRemAmtFC - -Amount - CashDeductAmt - PmtToleranceAmount;
                    if RestAfterPmt > 0 then begin
                        RestAfterPmt := RestAfterPmt + CashDeductAmt;
                        CashDeductAmt := 0;
                    end;
                end;

                if (Layout = Layout::"ESR Information") and ("ESR Information" <> '') then begin
                    TA := CopyStr("ESR Information", 47, 3);
                    "Reference No." := CopyStr("ESR Information", 5, 27);
                    Evaluate(Francs, CopyStr("ESR Information", 33, 2));
                    Evaluate(Cents, CopyStr("ESR Information", 35, 2));
                    ProcessingDate := CopyStr("ESR Information", 38, 8);

                    Microfilm := CopyStr("External Document No.", 1, MaxStrLen(Microfilm));
                    PaymentCharges := Francs + Cents / 100;

                    if CopyStr(TA, 3, 1) = '5' then begin
                        Comment := Text001;
                        exit;
                    end;

                    if CopyStr(TA, 3, 1) = '8' then begin
                        Comment := Text002;
                        exit;
                    end;

                    if "Account No." = '' then begin
                        Comment := Text003;
                        exit;
                    end;

                    if not Customer.Get("Account No.") then begin
                        Comment := Text003;
                        exit;
                    end;

                    if not CustLedgEntry.Open then begin
                        Comment := Text004;
                        exit;
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Account Type", "Account Type"::Customer);
                SetRange("Document Type", "Document Type"::Payment);
                Clear(PaymentCharges);

                IntLayout := Layout;
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
                        OptionCaption = 'Amounts,ESR Information';
                        ToolTip = 'Specifies the layout for the report. Options include Amounts and ESR Information.';
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

    var
        Text000: Label 'Customer ledger entry not found';
        Text001: Label 'Correction posting';
        Text002: Label 'Correction';
        Text003: Label 'Customer not found';
        Text004: Label 'Entry no longer open';
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        ExchRate: Record "Currency Exchange Rate";
        TA: Code[3];
        Microfilm: Code[10];
        Francs: Decimal;
        Cents: Decimal;
        PaymentCharges: Decimal;
        ProcessingDate: Code[8];
        "Layout": Option Amount,"ESR Information";
        AgeDays: Integer;
        CashDiscDays: Integer;
        DueDays: Integer;
        OpenRemAmtFC: Decimal;
        CashDeductAmt: Decimal;
        RestAfterPmt: Decimal;
        PmtDiscToleranceDays: Integer;
        PmtToleranceAmount: Decimal;
        IntLayout: Integer;
        ESRJournalCaptionLbl: Label 'ESR Journal';
        PageNoCaptionLbl: Label 'Page';
        PaymentCaptionLbl: Label 'Payment';
        AfterPmtCaptionLbl: Label 'after Pmt.';
        BeforePmtCaptionLbl: Label 'before Pmt.';
        DedCaptionLbl: Label 'Ded.';
        TolDaysCaptionLbl: Label 'Tol. Days';
        CDisCaptionLbl: Label 'C Dis.';
        AgeCaptionLbl: Label 'Age';
        CashDiscCaptionLbl: Label 'Cash Disc.';
        OpenRemAmountCaptionLbl: Label 'Open Rem. Amount';
        DateDaysCaptionLbl: Label 'Date / Days';
        DueCaptionLbl: Label 'Due';
        ApplicationCaptionLbl: Label 'Application';
        CustomerCaptionLbl: Label 'Customer';
        DeduCaptionLbl: Label 'Dedu.';
        ToleranceCaptionLbl: Label 'Tolerance';
        FilmCaptionLbl: Label 'Film';
        ProcessDateCaptionLbl: Label 'Process Date';
        ChargesCaptionLbl: Label 'Charges';
        ReferenceNoCaptionLbl: Label 'Reference No.';
        TACaptionLbl: Label 'TA';
        CommentCaptionLbl: Label 'Comment / Error';
        PostCodeCityCaptionLbl: Label 'Post Code / City';
        BalAccCaptionLbl: Label 'Bal. Acc.';
        TotalChargesCaptionLbl: Label 'Total Charges';
        DebitDateCaptionLbl: Label 'Debit Date';
        TotalCHFCaptionLbl: Label 'Total CHF';
        DocumentNoCaptionLbl: Label 'Doc. No.';
}

