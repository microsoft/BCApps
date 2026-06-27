// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using Microsoft.Utilities;

/// <summary>
/// Codeunit 980 "Payment Registration Mgt." manages payment registration functionality including posting, 
/// document search, balance calculations, and preview operations. Handles the business logic for the
/// payment registration workspace and integrates with general journal posting.
/// </summary>
/// <remarks>
/// Supports both individual and lump payment posting modes. Provides document search capabilities
/// with tolerance checking and balance validation. Includes extensibility through integration events
/// for custom posting logic and document filtering.
/// </remarks>
codeunit 980 "Payment Registration Mgt."
{
    EventSubscriberInstance = Manual;
    TableNo = "Payment Registration Buffer";

    trigger OnRun()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.SetPreviewMode(PreviewMode);
        if PreviewMode then
            RunPreview(Rec, AsLumpPreviewContext);
    end;

    var
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
#pragma warning disable AA0470
        EmptyDateReceivedErr: Label 'Date Received is missing for line with Document No. %1.';
#pragma warning restore AA0470
        ConfirmPostPaymentsQst: Label 'Do you want to post the %1 payments?', Comment = '%1=number of payments to post';
#pragma warning disable AA0470
        CloseQst: Label 'The %1 check box is selected on one or more lines. Do you want to close the window without posting these lines?';
#pragma warning restore AA0470
        TempTableErr: Label 'The table passed as a parameter must be temporary.';
        SalesOrderTxt: Label 'Sales Order';
        SalesBlanketOrderTxt: Label 'Sales Blanket Order';
        SalesQuoteTxt: Label 'Sales Quote';
        SalesInvoiceTxt: Label 'Sales Invoice';
        SalesReturnOrderTxt: Label 'Sales Return Order';
        SalesCreditMemoTxt: Label 'Sales Credit Memo';
        ReminderTxt: Label 'Reminder';
        FinChrgMemoTxt: Label 'Finance Charge Memo ';
#pragma warning disable AA0470
        DistinctDateReceivedErr: Label 'To post as a lump payment, the %1 field must have the same value in all lines where the %2 check box is selected.';
        DistinctCustomerErr: Label 'To post as lump payment, the customer must be same value on all lines where the %1 check box is selected.';
#pragma warning restore AA0470
        ConfirmLumpPaymentQst: Label 'Do you want to post the %1 payments as a lump sum of %2?', Comment = '%1=number of payments to post, %2 sum of amount received.';
        ForeignCurrNotSuportedErr: Label 'The document with type %1 and description %2 must have the same currency code as the payment you are registering.\\To register the payment, you must change %3 to use a balancing account with the same currency as the document. Alternatively, use the Cash Receipt Journal page to process the payment.', Comment = '%1 = Document Type; %2 = Description; %3 = Payment Registration Setup; Cash Receipt Journal should have the same translation as the pages with the same name.';
        PreviewMode: Boolean;
        AsLumpPreviewContext: Boolean;

    /// <summary>
    /// Runs the payment registration setup wizard to configure payment registration defaults.
    /// This procedure checks if setup is complete and guides users through configuration if needed.
    /// </summary>
    procedure RunSetup()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        SetupOK: Boolean;
        RunFullSetup: Boolean;
    begin
        if not PaymentRegistrationSetup.Get(UserId) then
            RunFullSetup := true
        else
            RunFullSetup := not PaymentRegistrationSetup.ValidateMandatoryFields(false);

        if RunFullSetup then
            SetupOK := PAGE.RunModal(PAGE::"Payment Registration Setup") = ACTION::LookupOK
        else
            if PaymentRegistrationSetup."Use this Account as Def." then
                SetupOK := true
            else
                SetupOK := PAGE.RunModal(PAGE::"Balancing Account Setup") = ACTION::LookupOK;

        if not SetupOK then
            Error('');
    end;

    /// <summary>
    /// Posts payment registration entries to the general ledger.
    /// This procedure creates and posts general journal entries based on payment registration buffer data.
    /// </summary>
    /// <param name="TempPaymentRegistrationBuffer">The temporary payment registration buffer containing payment data to post.</param>
    /// <param name="LumpPayment">Indicates whether this is a lump payment posting or individual payment posting.</param>
    [Scope('OnPrem')]
    procedure Post(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary; LumpPayment: Boolean)
    var
        BankAcc: Record "Bank Account";
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlTemplate: Record "Gen. Journal Template";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        PaymentToleranceManagement: Codeunit "Payment Tolerance Management";
    begin
        OnBeforePost(TempPaymentRegistrationBuffer);
        PaymentRegistrationSetup.Get(UserId);
        PaymentRegistrationSetup.ValidateMandatoryFields(true);
        GenJnlTemplate.Get(PaymentRegistrationSetup."Journal Template Name");
        GenJnlBatch.Get(PaymentRegistrationSetup."Journal Template Name", PaymentRegistrationSetup."Journal Batch Name");

        GenJournalLine.SetRange("Journal Template Name", PaymentRegistrationSetup."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", PaymentRegistrationSetup."Journal Batch Name");
        if GenJournalLine.FindLast() then
            GenJournalLine.SetFilter("Line No.", '>%1', GenJournalLine."Line No.");

        PaymentToleranceManagement.SetSuppressCommit(PreviewMode);
        TempPaymentRegistrationBuffer.FindSet();
        repeat
            if TempPaymentRegistrationBuffer."Date Received" = 0D then
                Error(EmptyDateReceivedErr, TempPaymentRegistrationBuffer."Document No.");
            if not LumpPayment then
                UpdatePmtDiscountDateOnCustLedgerEntry(TempPaymentRegistrationBuffer);
            GenJournalLine.Init();
            GenJournalLine.SetSuppressCommit(PreviewMode);

            GenJournalLine."Journal Template Name" := PaymentRegistrationSetup."Journal Template Name";
            GenJournalLine."Journal Batch Name" := PaymentRegistrationSetup."Journal Batch Name";
            GenJournalLine."Line No." += 10000;

            GenJournalLine."Source Code" := GenJnlTemplate."Source Code";
            GenJournalLine."Reason Code" := GenJnlBatch."Reason Code";
            GenJournalLine."Posting No. Series" := GenJnlBatch."Posting No. Series";

            GenJournalLine.Validate("Posting Date", TempPaymentRegistrationBuffer."Date Received");
            GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
            if TempPaymentRegistrationBuffer."Document Type" = TempPaymentRegistrationBuffer."Document Type"::"Credit Memo" then
                GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Refund)
            else
                GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
            GenJournalLine."Document No." := NoSeriesBatch.GetNextNo(GenJnlBatch."No. Series", GenJournalLine."Posting Date");
            GenJournalLine.Validate("Bal. Account Type", PaymentRegistrationSetup.GetGLBalAccountType());
            GenJournalLine.Validate("Account No.", TempPaymentRegistrationBuffer."Source No.");
            GenJournalLine.Validate(Amount, -TempPaymentRegistrationBuffer."Amount Received");
            GenJournalLine.Validate("Bal. Account No.", PaymentRegistrationSetup."Bal. Account No.");
            GenJournalLine.Validate("Payment Method Code", TempPaymentRegistrationBuffer."Payment Method Code");
            if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"Bank Account" then begin
                BankAcc.Get(GenJournalLine."Bal. Account No.");
                GenJournalLine.Validate("Currency Code", BankAcc."Currency Code");
            end;
            CheckCurrencyCode(TempPaymentRegistrationBuffer, GenJournalLine, PaymentRegistrationSetup, LumpPayment);
            if LumpPayment then begin
                GenJournalLine."Applies-to ID" := GenJournalLine."Document No.";
                PaymentToleranceManagement.PmtTolGenJnl(GenJournalLine);
            end else begin
                GenJournalLine.Validate("Applies-to Doc. Type", TempPaymentRegistrationBuffer."Document Type");
                GenJournalLine.Validate("Applies-to Doc. No.", TempPaymentRegistrationBuffer."Document No.");
            end;
            GenJournalLine.Validate("External Document No.", TempPaymentRegistrationBuffer."External Document No.");
            OnBeforeGenJnlLineInsert(GenJournalLine, TempPaymentRegistrationBuffer);
            GenJournalLine.Insert(true);
        until TempPaymentRegistrationBuffer.Next() = 0;

        if not PreviewMode then begin
            CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);
            OnAfterPostPaymentRegistration(TempPaymentRegistrationBuffer);
        end else
            GenJnlPostBatch.Preview(GenJournalLine);
    end;

    /// <summary>
    /// Confirms whether to close the payment registration page when there are unsaved payments.
    /// This procedure checks for pending payments and prompts the user for confirmation before closing.
    /// </summary>
    /// <param name="PaymentRegistrationBuffer">The payment registration buffer to check for pending payments.</param>
    /// <returns>True if the user confirms closing or there are no pending payments, false otherwise.</returns>
    procedure ConfirmClose(var PaymentRegistrationBuffer: Record "Payment Registration Buffer"): Boolean
    begin
        PaymentRegistrationBuffer.Reset();
        PaymentRegistrationBuffer.SetRange(PaymentRegistrationBuffer."Payment Made", true);
        if not PaymentRegistrationBuffer.IsEmpty() then
            exit(Confirm(StrSubstNo(CloseQst, PaymentRegistrationBuffer.FieldCaption("Payment Made"))));

        exit(true);
    end;

    /// <summary>
    /// Confirms and posts payment registrations after validation.
    /// This procedure validates payment entries and posts them after user confirmation.
    /// </summary>
    /// <param name="PaymentRegistrationBuffer">The payment registration buffer containing payments to post.</param>
    procedure ConfirmPost(var PaymentRegistrationBuffer: Record "Payment Registration Buffer")
    var
        PaymentRegistrationBuffer2: Record "Payment Registration Buffer";
        Confirmed: Boolean;
    begin
        PaymentRegistrationBuffer2.CopyFilters(PaymentRegistrationBuffer);
        CheckPaymentsToPost(PaymentRegistrationBuffer);
        if not PreviewMode then
            Confirmed := Confirm(StrSubstNo(ConfirmPostPaymentsQst, PaymentRegistrationBuffer.Count), true);

        if PreviewMode or Confirmed then begin
            Post(PaymentRegistrationBuffer, false);
            PaymentRegistrationBuffer.PopulateTable();
        end;
        PaymentRegistrationBuffer.CopyFilters(PaymentRegistrationBuffer2);
    end;

    /// <summary>
    /// Finds document records that match the specified search criteria.
    /// This procedure searches for sales documents, reminders, and finance charge memos based on document number and amount filters.
    /// </summary>
    /// <param name="TempDocumentSearchResult">Temporary table to store the search results.</param>
    /// <param name="DocNoFilter">Document number filter for the search.</param>
    /// <param name="AmountFilter">Amount filter for the search.</param>
    /// <param name="AmountTolerancePerc">Percentage tolerance for amount matching.</param>
    procedure FindRecords(var TempDocumentSearchResult: Record "Document Search Result" temporary; DocNoFilter: Code[20]; AmountFilter: Decimal; AmountTolerancePerc: Decimal)
    begin
        if not TempDocumentSearchResult.IsTemporary then
            Error(TempTableErr);

        TempDocumentSearchResult.Reset();
        TempDocumentSearchResult.DeleteAll();
        DocNoFilter := StrSubstNo('*%1*', DocNoFilter);

        FindSalesHeaderRecords(TempDocumentSearchResult, DocNoFilter, AmountFilter, AmountTolerancePerc);
        FindReminderHeaderRecords(TempDocumentSearchResult, DocNoFilter, AmountFilter, AmountTolerancePerc);
        FindFinChargeMemoHeaderRecords(TempDocumentSearchResult, DocNoFilter, AmountFilter, AmountTolerancePerc);

        OnAfterFindRecords(TempDocumentSearchResult, DocNoFilter, AmountFilter, AmountTolerancePerc);
    end;

    local procedure FindSalesHeaderRecords(var TempDocumentSearchResult: Record "Document Search Result" temporary; DocNoFilter: Code[20]; AmountFilter: Decimal; AmountTolerancePerc: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        if SalesHeader.ReadPermission then begin
            SalesHeader.Reset();
            SalesHeader.SetFilter("No.", DocNoFilter);
            if SalesHeader.FindSet() then
                repeat
                    SalesHeader.CalcFields("Amount Including VAT");
                    OnFindSalesHeaderRecordsOnBeforeToleranceCheck(SalesHeader);
                    if IsWithinTolerance(SalesHeader."Amount Including VAT", AmountFilter, AmountTolerancePerc) then
                        InsertDocSearchResult(TempDocumentSearchResult, SalesHeader."No.", SalesHeader."Document Type".AsInteger(), DATABASE::"Sales Header",
                          GetSalesHeaderDescription(SalesHeader), SalesHeader."Amount Including VAT");
                until SalesHeader.Next() = 0;
        end;
    end;

    local procedure FindReminderHeaderRecords(var TempDocumentSearchResult: Record "Document Search Result" temporary; DocNoFilter: Code[20]; AmountFilter: Decimal; AmountTolerancePerc: Decimal)
    var
        ReminderHeader: Record "Reminder Header";
    begin
        if ReminderHeader.ReadPermission then begin
            ReminderHeader.Reset();
            ReminderHeader.SetFilter("No.", DocNoFilter);
            if ReminderHeader.FindSet() then
                repeat
                    ReminderHeader.CalcFields("Remaining Amount", "Interest Amount");
                    if IsWithinTolerance(ReminderHeader."Remaining Amount", AmountFilter, AmountTolerancePerc) or
                       IsWithinTolerance(ReminderHeader."Interest Amount", AmountFilter, AmountTolerancePerc)
                    then
                        InsertDocSearchResult(TempDocumentSearchResult, ReminderHeader."No.", 0, DATABASE::"Reminder Header",
                          ReminderTxt, ReminderHeader."Remaining Amount");
                until ReminderHeader.Next() = 0;
        end;
    end;

    local procedure FindFinChargeMemoHeaderRecords(var TempDocumentSearchResult: Record "Document Search Result" temporary; DocNoFilter: Code[20]; AmountFilter: Decimal; AmountTolerancePerc: Decimal)
    var
        FinChargeMemoHeader: Record "Finance Charge Memo Header";
    begin
        if FinChargeMemoHeader.ReadPermission then begin
            FinChargeMemoHeader.Reset();
            FinChargeMemoHeader.SetFilter("No.", DocNoFilter);
            if FinChargeMemoHeader.FindSet() then
                repeat
                    FinChargeMemoHeader.CalcFields("Remaining Amount", "Interest Amount");
                    if IsWithinTolerance(FinChargeMemoHeader."Remaining Amount", AmountFilter, AmountTolerancePerc) or
                       IsWithinTolerance(FinChargeMemoHeader."Interest Amount", AmountFilter, AmountTolerancePerc)
                    then
                        InsertDocSearchResult(TempDocumentSearchResult, FinChargeMemoHeader."No.", 0, DATABASE::"Finance Charge Memo Header",
                          FinChrgMemoTxt, FinChargeMemoHeader."Remaining Amount");
                until FinChargeMemoHeader.Next() = 0;
        end;
    end;

    /// <summary>
    /// Shows the detailed records for a selected document search result.
    /// This procedure opens the appropriate page to display the full document details based on the search result type.
    /// </summary>
    /// <param name="TempDocumentSearchResult">The temporary document search result record to show details for.</param>
    procedure ShowRecords(var TempDocumentSearchResult: Record "Document Search Result" temporary)
    var
        ReminderHeader: Record "Reminder Header";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
    begin
        case TempDocumentSearchResult."Table ID" of
            DATABASE::"Sales Header":
                ShowSalesHeaderRecords(TempDocumentSearchResult);
            DATABASE::"Reminder Header":
                begin
                    ReminderHeader.Get(TempDocumentSearchResult."Doc. No.");
                    PAGE.Run(PAGE::Reminder, ReminderHeader);
                end;
            DATABASE::"Finance Charge Memo Header":
                begin
                    FinanceChargeMemoHeader.Get(TempDocumentSearchResult."Doc. No.");
                    PAGE.Run(PAGE::"Finance Charge Memo", FinanceChargeMemoHeader);
                end;
            else
                OnShowRecords(TempDocumentSearchResult);
        end;
    end;

    local procedure ShowSalesHeaderRecords(var TempDocumentSearchResult: Record "Document Search Result" temporary)
    var
        SalesHeader: Record "Sales Header";
        IsHandled: Boolean;
    begin
        TempDocumentSearchResult.TestField("Table ID", DATABASE::"Sales Header");
        SalesHeader.SetRange("Document Type", TempDocumentSearchResult."Doc. Type");
        SalesHeader.SetRange("No.", TempDocumentSearchResult."Doc. No.");

        OnShowSalesHeaderRecordsOnBeforeOpenPage(TempDocumentSearchResult, SalesHeader, IsHandled);
        if IsHandled then
            exit;

        case TempDocumentSearchResult."Doc. Type" of
            SalesHeader."Document Type"::Quote.AsInteger():
                PAGE.Run(PAGE::"Sales Quote", SalesHeader);
            SalesHeader."Document Type"::"Blanket Order".AsInteger():
                PAGE.Run(PAGE::"Blanket Sales Order", SalesHeader);
            SalesHeader."Document Type"::Order.AsInteger():
                PAGE.Run(PAGE::"Sales Order", SalesHeader);
            SalesHeader."Document Type"::Invoice.AsInteger():
                PAGE.Run(PAGE::"Sales Invoice", SalesHeader);
            SalesHeader."Document Type"::"Return Order".AsInteger():
                PAGE.Run(PAGE::"Sales Return Order", SalesHeader);
            SalesHeader."Document Type"::"Credit Memo".AsInteger():
                PAGE.Run(PAGE::"Sales Credit Memo", SalesHeader);
            else
                PAGE.Run(0, SalesHeader);
        end;
    end;

    procedure ConfirmPostLumpPayment(var SourcePaymentRegistrationBuffer: Record "Payment Registration Buffer")
    var
        CopyPaymentRegistrationBuffer: Record "Payment Registration Buffer";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        Confirmed: Boolean;
    begin
        CopyPaymentRegistrationBuffer.Copy(SourcePaymentRegistrationBuffer);

        SourcePaymentRegistrationBuffer.Reset();
        if SourcePaymentRegistrationBuffer.FindSet() then
            repeat
                TempPaymentRegistrationBuffer := SourcePaymentRegistrationBuffer;
                TempPaymentRegistrationBuffer.Insert();
            until SourcePaymentRegistrationBuffer.Next() = 0;

        CheckPaymentsToPost(TempPaymentRegistrationBuffer);
        CreateLumpPayment(TempPaymentRegistrationBuffer);
        if not PreviewMode then
            Confirmed := Confirm(
                StrSubstNo(
                  ConfirmLumpPaymentQst,
                  TempPaymentRegistrationBuffer.Count,
                  Format(TempPaymentRegistrationBuffer."Amount Received", 0, '<Precision,2><Standard Format,0>')), true);

        if PreviewMode or Confirmed then begin
            TempPaymentRegistrationBuffer.Modify();
            TempPaymentRegistrationBuffer.SetRange(TempPaymentRegistrationBuffer."Ledger Entry No.", TempPaymentRegistrationBuffer."Ledger Entry No.");
            Post(TempPaymentRegistrationBuffer, true);
            SourcePaymentRegistrationBuffer.PopulateTable();
        end else
            ClearApplicationFieldsOnCustLedgerEntry(TempPaymentRegistrationBuffer);

        SourcePaymentRegistrationBuffer.Copy(CopyPaymentRegistrationBuffer);
    end;

    local procedure UpdatePmtDiscountDateOnCustLedgerEntry(TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.LockTable();
        CustLedgerEntry.Get(TempPaymentRegistrationBuffer."Ledger Entry No.");
        if CustLedgerEntry."Pmt. Discount Date" <> TempPaymentRegistrationBuffer."Pmt. Discount Date" then begin
            CustLedgerEntry."Pmt. Discount Date" := TempPaymentRegistrationBuffer."Pmt. Discount Date";
            CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgerEntry);
        end;
    end;

    /// <summary>
    /// Inserts a document search result record into the temporary search result table.
    /// This procedure creates a new search result entry for documents found during payment registration searches.
    /// </summary>
    /// <param name="TempDocumentSearchResult">The temporary table to insert the search result into.</param>
    /// <param name="DocNo">The document number of the found document.</param>
    /// <param name="DocType">The document type identifier.</param>
    /// <param name="TableID">The table ID of the source document.</param>
    /// <param name="DocTypeDescription">A descriptive text for the document type.</param>
    /// <param name="Amount">The amount associated with the found document.</param>
    procedure InsertDocSearchResult(var TempDocumentSearchResult: Record "Document Search Result" temporary; DocNo: Code[20]; DocType: Integer; TableID: Integer; DocTypeDescription: Text[50]; Amount: Decimal)
    begin
        if not TempDocumentSearchResult.Get(DocType, DocNo, TableID) then begin
            TempDocumentSearchResult.Init();
            TempDocumentSearchResult."Doc. No." := DocNo;
            TempDocumentSearchResult."Doc. Type" := DocType;
            TempDocumentSearchResult."Table ID" := TableID;
            TempDocumentSearchResult.Description := DocTypeDescription;
            TempDocumentSearchResult.Amount := Amount;
            TempDocumentSearchResult.Insert(true);
        end;
    end;

    /// <summary>
    /// Sets tolerance limits for amount matching and returns formatted tolerance information.
    /// This procedure calculates and displays tolerance ranges for payment amount matching.
    /// </summary>
    /// <param name="Amount">The base amount for tolerance calculation.</param>
    /// <param name="AmountTolerance">The tolerance percentage to apply.</param>
    /// <param name="ToleranceTxt">The tolerance text template to format.</param>
    /// <returns>Formatted text showing the tolerance limits for the specified amount.</returns>
    procedure SetToleranceLimits(Amount: Decimal; AmountTolerance: Decimal; ToleranceTxt: Text): Text
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        if (AmountTolerance > 0) and (AmountTolerance <= 100) and (Amount <> 0) then
            exit(StrSubstNo(ToleranceTxt, Format((1 - AmountTolerance / 100) * Amount, 0, '<Precision,2><Standard Format,0>'),
                Format((1 + AmountTolerance / 100) * Amount, 0, '<Precision,2><Standard Format,0>')));

        exit('');
    end;

    /// <summary>
    /// Determines whether an amount is within the specified tolerance range of a filter amount.
    /// This procedure is used for amount matching during document searches and payment registration.
    /// </summary>
    /// <param name="Amount">The amount to check against the tolerance range.</param>
    /// <param name="FilterAmount">The base amount for tolerance calculation.</param>
    /// <param name="TolerancePct">The tolerance percentage (0-100) to apply.</param>
    /// <returns>True if the amount is within tolerance, false otherwise.</returns>
    procedure IsWithinTolerance(Amount: Decimal; FilterAmount: Decimal; TolerancePct: Decimal): Boolean
    begin
        if FilterAmount = 0 then
            exit(true);

        exit((Amount >= (1 - TolerancePct / 100) * FilterAmount) and
          (Amount <= (1 + TolerancePct / 100) * FilterAmount));
    end;

    local procedure GetSalesHeaderDescription(SalesHeader: Record "Sales Header"): Text[50]
    begin
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Quote:
                exit(SalesQuoteTxt);
            SalesHeader."Document Type"::"Blanket Order":
                exit(SalesBlanketOrderTxt);
            SalesHeader."Document Type"::Order:
                exit(SalesOrderTxt);
            SalesHeader."Document Type"::Invoice:
                exit(SalesInvoiceTxt);
            SalesHeader."Document Type"::"Return Order":
                exit(SalesReturnOrderTxt);
            SalesHeader."Document Type"::"Credit Memo":
                exit(SalesCreditMemoTxt);
            else
                exit(SalesOrderTxt);
        end;
    end;

    local procedure UpdateApplicationFieldsOnCustLedgerEntry(TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary)
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJnlBatch: Record "Gen. Journal Batch";
        NoSeries: Codeunit "No. Series";
    begin
        PaymentRegistrationSetup.Get(UserId);
        GenJnlBatch.Get(PaymentRegistrationSetup."Journal Template Name", PaymentRegistrationSetup."Journal Batch Name");

        CustLedgerEntry.LockTable();
        CustLedgerEntry.Get(TempPaymentRegistrationBuffer."Ledger Entry No.");
        CustLedgerEntry."Applies-to ID" :=
          NoSeries.PeekNextNo(GenJnlBatch."No. Series", TempPaymentRegistrationBuffer."Date Received");
        CustLedgerEntry.CalcFields("Remaining Amount");
        OnUpdateApplicationFieldsOnCustLedgerEntryOnAfterCalcRemainingAmount(CustLedgerEntry);
        if (TempPaymentRegistrationBuffer."Amount Received" > CustLedgerEntry."Remaining Amount") then
            CustLedgerEntry."Amount to Apply" := CustLedgerEntry."Remaining Amount"
        else
            CustLedgerEntry."Amount to Apply" := TempPaymentRegistrationBuffer."Amount Received";
        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgerEntry);
    end;

    local procedure ClearApplicationFieldsOnCustLedgerEntry(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if TempPaymentRegistrationBuffer.FindSet() then
            repeat
                CustLedgerEntry.Get(TempPaymentRegistrationBuffer."Ledger Entry No.");
                CustLedgerEntry."Applies-to ID" := '';
                CustLedgerEntry."Amount to Apply" := 0;
                CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgerEntry);
            until TempPaymentRegistrationBuffer.Next() = 0;
    end;

    local procedure CreateLumpPayment(var PaymentRegistrationBuffer: Record "Payment Registration Buffer")
    var
        AmountReceived: Decimal;
    begin
        CheckDistinctSourceNo(PaymentRegistrationBuffer);
        CheckDistinctDateReceived(PaymentRegistrationBuffer);
        if PaymentRegistrationBuffer.FindSet() then
            repeat
                UpdatePmtDiscountDateOnCustLedgerEntry(PaymentRegistrationBuffer);
                UpdateApplicationFieldsOnCustLedgerEntry(PaymentRegistrationBuffer);
                AmountReceived += PaymentRegistrationBuffer."Amount Received";
            until PaymentRegistrationBuffer.Next() = 0;

        PaymentRegistrationBuffer."Amount Received" := AmountReceived;
        if AmountReceived > 0 then
            PaymentRegistrationBuffer."Document Type" := PaymentRegistrationBuffer."Document Type"::Invoice
        else
            PaymentRegistrationBuffer."Document Type" := PaymentRegistrationBuffer."Document Type"::"Credit Memo";
    end;

    local procedure CheckDistinctSourceNo(var PaymentRegistrationBuffer: Record "Payment Registration Buffer")
    begin
        PaymentRegistrationBuffer.SetFilter("Source No.", '<>%1', PaymentRegistrationBuffer."Source No.");
        if not PaymentRegistrationBuffer.IsEmpty() then
            Error(DistinctCustomerErr, PaymentRegistrationBuffer.FieldCaption("Payment Made"));

        PaymentRegistrationBuffer.SetRange("Source No.");
    end;

    local procedure CheckDistinctDateReceived(var PaymentRegistrationBuffer: Record "Payment Registration Buffer")
    begin
        PaymentRegistrationBuffer.SetFilter("Date Received", '<>%1', PaymentRegistrationBuffer."Date Received");
        if not PaymentRegistrationBuffer.IsEmpty() then
            Error(DistinctDateReceivedErr, PaymentRegistrationBuffer.FieldCaption("Date Received"),
              PaymentRegistrationBuffer.FieldCaption("Payment Made"));

        PaymentRegistrationBuffer.SetRange("Date Received");
    end;

    local procedure CheckPaymentsToPost(var PaymentRegistrationBuffer: Record "Payment Registration Buffer")
    begin
        PaymentRegistrationBuffer.Reset();
        PaymentRegistrationBuffer.SetRange("Payment Made", true);
        PaymentRegistrationBuffer.SetFilter("Amount Received", '<>0');
        if not PaymentRegistrationBuffer.FindSet() then
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    local procedure CheckCurrencyCode(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary; GenJnlLine: Record "Gen. Journal Line"; PaymentRegistrationSetup: Record "Payment Registration Setup"; LumpPayment: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if LumpPayment then
            CustLedgerEntry.SetRange("Applies-to ID", GenJnlLine."Document No.")
        else
            CustLedgerEntry.SetRange("Entry No.", TempPaymentRegistrationBuffer."Ledger Entry No.");

        CustLedgerEntry.SetFilter("Currency Code", '<>%1', GenJnlLine."Currency Code");
        if not CustLedgerEntry.IsEmpty() then
            Error(ForeignCurrNotSuportedErr, TempPaymentRegistrationBuffer."Document Type", TempPaymentRegistrationBuffer.Description,
              PaymentRegistrationSetup.TableCaption());
    end;

    procedure CalculateBalance(var PostedBalance: Decimal; var UnpostedBalance: Decimal)
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        PaymentRegistrationSetup.Get(UserId);

        case PaymentRegistrationSetup."Bal. Account Type" of
            PaymentRegistrationSetup."Bal. Account Type"::"G/L Account":
                begin
                    if GLAccount.Get(PaymentRegistrationSetup."Bal. Account No.") then
                        GLAccount.CalcFields(Balance);
                    PostedBalance := GLAccount.Balance;
                    GenJnlLine.SetRange("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
                end;
            PaymentRegistrationSetup."Bal. Account Type"::"Bank Account":
                begin
                    if BankAccount.Get(PaymentRegistrationSetup."Bal. Account No.") then
                        BankAccount.CalcFields(Balance);
                    PostedBalance := BankAccount.Balance;
                    GenJnlLine.SetRange("Bal. Account Type", GenJnlLine."Bal. Account Type"::"Bank Account");
                end;
        end;
        OnCalculateBalanceOnAfterSetPostedBalance(PostedBalance, GLAccount, BankAccount);

        GenJnlLine.SetRange("Bal. Account No.", PaymentRegistrationSetup."Bal. Account No.");
        GenJnlLine.CalcSums(Amount);
        UnpostedBalance := GenJnlLine.Amount;
    end;

    procedure OpenGenJnl()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        PaymentRegistrationSetup.Get(UserId);

        GenJnlLine.FilterGroup := 2;
        GenJnlLine.SetRange("Journal Template Name", PaymentRegistrationSetup."Journal Template Name");
        GenJnlLine.FilterGroup := 0;

        GenJnlLine."Journal Template Name" := '';
        GenJnlLine."Journal Batch Name" := PaymentRegistrationSetup."Journal Batch Name";
        PAGE.Run(PAGE::"General Journal", GenJnlLine);
    end;

    procedure Preview(var PaymentRegistrationBuffer: Record "Payment Registration Buffer"; AsLump: Boolean)
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        BindSubscription(PaymentRegistrationMgt);
        PaymentRegistrationMgt.SetPreviewContext(AsLump);
        GenJnlPostPreview.Preview(PaymentRegistrationMgt, PaymentRegistrationBuffer);
    end;

    local procedure RunPreview(var PaymentRegistrationBuffer: Record "Payment Registration Buffer"; AsLump: Boolean)
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        // Copy checked payments to a temp table so that we can restore the checked state after the preview.
        CheckPaymentsToPost(PaymentRegistrationBuffer);
        repeat
            TempPaymentRegistrationBuffer := PaymentRegistrationBuffer;
            TempPaymentRegistrationBuffer.Insert();
        until PaymentRegistrationBuffer.Next() = 0;

        if AsLump then
            ConfirmPostLumpPayment(PaymentRegistrationBuffer)
        else
            ConfirmPost(PaymentRegistrationBuffer);

        // Populate the table so that all records show. Then restore the checked state of the originally checked records.
        PaymentRegistrationBuffer.PopulateTable();
        CheckPaymentsToPost(TempPaymentRegistrationBuffer);
        repeat
            // Check to see if the record already exists before updating
            PaymentRegistrationBuffer := TempPaymentRegistrationBuffer;
            if PaymentRegistrationBuffer.Find('=') then begin
                PaymentRegistrationBuffer := TempPaymentRegistrationBuffer;
                PaymentRegistrationBuffer.Modify();
            end else begin
                PaymentRegistrationBuffer := TempPaymentRegistrationBuffer;
                PaymentRegistrationBuffer.Insert();
            end;
        until TempPaymentRegistrationBuffer.Next() = 0;
    end;

    procedure SetPreviewContext(AsLump: Boolean)
    begin
        AsLumpPreviewContext := AsLump;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        PaymentRegistrationMgt := Subscriber;
        PreviewMode := true;
        Result := PaymentRegistrationMgt.Run(RecVar);
    end;

    /// <summary>
    /// Integration event raised after payment registration entries have been posted.
    /// This event allows external extensions to perform additional processing after payments are posted.
    /// </summary>
    /// <param name="TempPaymentRegistrationBuffer">The temporary payment registration buffer containing the posted payment data.</param>
    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnAfterPostPaymentRegistration(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterFindRecords(var TempDocumentSearchResult: Record "Document Search Result" temporary; DocNoFilter: Code[20]; AmountFilter: Decimal; AmountTolerancePerc: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateBalanceOnAfterSetPostedBalance(var PostedBalance: Decimal; GLAccount: Record "G/L Account"; BankAccount: Record "Bank Account")
    begin
    end;

    /// <summary>
    /// Integration event raised before posting payment registration entries.
    /// This event allows external extensions to validate or modify payment data before posting.
    /// </summary>
    /// <param name="TempPaymentRegistrationBuffer">The temporary payment registration buffer containing the payment data to be posted.</param>
    [IntegrationEvent(false, false)]
    procedure OnBeforePost(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnFindSalesHeaderRecordsOnBeforeToleranceCheck(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowSalesHeaderRecordsOnBeforeOpenPage(var TempDocumentSearchResult: Record "Document Search Result" temporary; var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowRecords(var TempDocumentSearchResult: Record "Document Search Result" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateApplicationFieldsOnCustLedgerEntryOnAfterCalcRemainingAmount(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;
}

