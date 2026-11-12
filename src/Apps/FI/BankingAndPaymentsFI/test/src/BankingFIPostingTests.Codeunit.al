// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

codeunit 148232 "Banking FI Posting Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        LibraryBanking: Codeunit "Library - Banking FI";
        RequestSentToBank: Boolean;
        RequestSummarize: Boolean;
        RequestUseDueDate: Boolean;
        RequestBankNo: Code[20];
        CapturedJournal: Record "Gen. Journal Line";
        CapturedPayable: Record "Payable Vendor Ledger Entry" temporary;
        CapturedBuffer: Record "Vendor Payment Buffer" temporary;
        FailOnSave: Boolean;

    [Test]
    procedure PurchaseMessagesCopyToJournal()
    var
        Header: Record "Purchase Header";
        Journal: Record "Gen. Journal Line";
    begin
        EnableFeature();
        Header."Bank Message Type" := Header."Bank Message Type"::"Long Message";
        Header."Payment Message" := 'Payment part one';
        Header."Payment Message 2" := 'Payment part two';
        Header."Due Date" := WorkDate();
        Journal.CopyFromPurchHeader(Header);
        Assert.AreEqual(Header."Bank Message Type", Journal."Bank Message Type", 'The message ordinal must be copied.');
        Assert.AreEqual(Header."Payment Message", Journal."Payment Message", 'The first message must be copied.');
        Assert.AreEqual(Header."Payment Message 2", Journal."Payment Message 2", 'The second message must be copied.');
        Assert.AreEqual(Header."Due Date", Journal."Planned Payment Date", 'The due date must initialize the payment date.');
        DisableFeature();
    end;

    [Test]
    procedure PostedJournalRetainsReferenceAndMessageFields()
    var
        Journal: Record "Gen. Journal Line";
        PostedJournal: Record "Posted Gen. Journal Line";
    begin
        EnableFeature();
        Journal."Payment Reference No." := '268745';
        Journal."Bank Message Type" := Journal."Bank Message Type"::Message;
        Journal."Payment Message" := 'Posted message';
        Journal."Payment Message 2" := 'Continuation';
        Journal."Planned Payment Date" := WorkDate();
        PostedJournal.TransferFields(Journal);
        Assert.AreEqual(Journal."Payment Reference No.", PostedJournal."Payment Reference No.", 'Posted history must retain the payment reference.');
        Assert.AreEqual(Journal."Payment Message", PostedJournal."Payment Message", 'Posted history must retain the message.');
        Assert.AreEqual(Journal."Planned Payment Date", PostedJournal."Planned Payment Date", 'Posted history must retain the payment date.');
        DisableFeature();
    end;

    [Test]
    procedure SuggestedPaymentRetainsNonSummarizedMessages()
    begin
        VerifySuggestedPaymentMessages(false);
    end;

    [Test]
    procedure SuggestedPaymentRetainsSummarizedMessages()
    begin
        VerifySuggestedPaymentMessages(true);
    end;

    [Test]
    [HandlerFunctions('SuggestionRequestPage,SuggestionMessage')]
    procedure SentToBankUsesFirstDateAndLastAmount()
    var
        Entry: Record "Vendor Ledger Entry";
        Journal: Record "Gen. Journal Line";
        Bank: Record "Bank Account";
        OtherBank: Record "Bank Account";
        Payable: Record "Payable Vendor Ledger Entry" temporary;
        Buffer: Record "Vendor Payment Buffer" temporary;
        CalculatedJournal: Record "Gen. Journal Line";
        Observer: Codeunit "Banking FI Posting Tests";
        LibraryERM: Codeunit "Library - ERM";
    begin
        EnableFeature();
        CreateSuggestionInvoice(Entry, Journal, Bank);
        LibraryERM.CreateBankAccount(OtherBank);
        CreateExport(Entry, OtherBank."No.", WorkDate() + 4, 91, true, false);
        CreateExport(Entry, Bank."No.", WorkDate() + 2, 11, true, false);
        CreateExport(Entry, Bank."No.", WorkDate() + 20, 37, true, false);
        CreateExport(Entry, OtherBank."No.", WorkDate() + 3, 99, true, false);
        CreateExport(Entry, Bank."No.", WorkDate() + 5, 101, false, false);
        CreateExport(Entry, Bank."No.", WorkDate() + 6, 102, true, true);
        BindSubscription(Observer);

        RunSuggestion(Entry, Journal, Bank."No.", true, false, true, false);

        Observer.GetCapturedAmounts(CalculatedJournal, Payable, Buffer);
        Assert.AreEqual(WorkDate() + 2, CalculatedJournal."Posting Date", 'Selection must use the first eligible bank/date/status match before calculation.');
        Assert.AreEqual(37, Payable.Amount, 'The last bank/status match wins, without a date cutoff or summation.');
        Entry.CalcFields("Remaining Amt. (LCY)");
        Assert.AreEqual(-Entry."Remaining Amt. (LCY)", Payable."Amount (LCY)", 'The override must not recalculate the already validated LCY amount.');
        Assert.AreEqual(Bank."No.", Buffer."Payment Bal. Account No.", 'The non-summary buffer must retain the bank from the last matching export.');
        AssertSuggestedLine(Journal, 37, WorkDate() + 3);
        Assert.AreEqual(WorkDate() + 20, Journal."Planned Payment Date", 'The non-summary buffer must use the last bank/status match without a date cutoff.');
        Entry.Get(Entry."Entry No.");
        Assert.AreEqual(0, Entry."Accepted Payment Tolerance", 'A selected entry must have its tolerance cleared.');
        UnbindSubscription(Observer);
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('SuggestionRequestPage')]
    procedure SentToBankSkipsUnavailableExports()
    var
        Entry: Record "Vendor Ledger Entry";
        OtherEntry: Record "Vendor Ledger Entry";
        Journal: Record "Gen. Journal Line";
        Bank: Record "Bank Account";
        OtherBank: Record "Bank Account";
        LibraryERM: Codeunit "Library - ERM";
    begin
        EnableFeature();
        CreateSuggestionInvoice(Entry, Journal, Bank);
        LibraryERM.CreateBankAccount(OtherBank);
        CreateExport(Entry, OtherBank."No.", WorkDate() + 2, 11, true, false);
        CreateExport(Entry, Bank."No.", WorkDate() + 20, 12, true, false);
        CreateExport(Entry, Bank."No.", WorkDate() + 2, 13, false, false);
        CreateExport(Entry, Bank."No.", WorkDate() + 2, 14, true, true);
        OtherEntry."Entry No." := Entry."Entry No." + 1;
        CreateExport(OtherEntry, Bank."No.", WorkDate() + 2, 15, true, false);

        RunSuggestion(Entry, Journal, Bank."No.", true, false, true, false);

        Assert.IsTrue(Journal.IsEmpty(), 'Wrong bank, date, status or ledger entry must not be suggested.');
        Entry.Get(Entry."Entry No.");
        Assert.AreEqual(1, Entry."Accepted Payment Tolerance", 'Skipping must not clear tolerance.');
        DisableFeature();
    end;

    [Test]
    procedure UnselectedUsesNormalAmountAndDomesticDate()
    var
        Entry: Record "Vendor Ledger Entry";
        Journal: Record "Gen. Journal Line";
        Bank: Record "Bank Account";
    begin
        EnableFeature();
        CreateSuggestionInvoice(Entry, Journal, Bank);
        CreateExport(Entry, Bank."No.", WorkDate() + 3, 37, true, false);
        RunSuggestion(Entry, Journal, '', false, false, false, false);
        Entry.CalcFields("Remaining Amount");
        AssertSuggestedLine(Journal, -Entry."Remaining Amount", WorkDate() + 3);
        Assert.AreEqual(WorkDate() + 3, Journal."Planned Payment Date", 'Unselected, request-page-free runs must still populate the non-summary export date.');
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('SuggestionRequestPage,SuggestionMessage')]
    procedure SentToBankSummaryUsesRequestedFallback()
    var
        Entry: Record "Vendor Ledger Entry";
        Journal: Record "Gen. Journal Line";
        Bank: Record "Bank Account";
        Exported: Record "Ref. Payment - Exported FI";
    begin
        EnableFeature();
        CreateSuggestionInvoice(Entry, Journal, Bank);
        Exported.SetRange("Entry No.", 0);
        Exported.SetRange(Transferred, true);
        Exported.SetRange("Posted to G/L", false);
        Exported.DeleteAll();
        CreateExport(Entry, Bank."No.", WorkDate() + 2, 11, true, false);
        CreateExport(Entry, Bank."No.", WorkDate() + 20, 37, true, false);
        RunSuggestion(Entry, Journal, Bank."No.", true, true, true, false);
        AssertSuggestedLine(Journal, 37, WorkDate() + 2);
        Assert.AreEqual(Entry."Planned Payment Date", Journal."Planned Payment Date", 'Summary fields must retain the vendor ledger date, not the non-summary export date.');
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('SuggestionMessage')]
    procedure ZeroDomesticDateFallsBackToPostingDate()
    var
        Entry: Record "Vendor Ledger Entry";
        Journal: Record "Gen. Journal Line";
        Bank: Record "Bank Account";
    begin
        EnableFeature();
        CreateSuggestionInvoice(Entry, Journal, Bank);
        CreateExport(Entry, Bank."No.", WorkDate() + 3, 11, true, false);
        CreateExport(Entry, Bank."No.", 0D, 37, true, false);
        RunSuggestion(Entry, Journal, Bank."No.", false, false, false, false);
        Entry.CalcFields("Remaining Amount");
        AssertSuggestedLine(Journal, -Entry."Remaining Amount", WorkDate() + 1);
        Assert.AreEqual(0D, Journal."Planned Payment Date", 'A zero date in the last export must not retain an earlier export date.');
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('SuggestionRequestPage,SuggestionMessage')]
    procedure ZeroDomesticDatePreservesDueDateOffset()
    var
        Entry: Record "Vendor Ledger Entry";
        Journal: Record "Gen. Journal Line";
        Bank: Record "Bank Account";
    begin
        EnableFeature();
        CreateSuggestionInvoice(Entry, Journal, Bank);
        CreateExport(Entry, Bank."No.", 0D, 37, true, false);
        RunSuggestion(Entry, Journal, Bank."No.", false, false, true, true);
        Entry.CalcFields("Remaining Amount");
        AssertSuggestedLine(Journal, -Entry."Remaining Amount", Entry."Due Date" + 2);
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('SuggestionRequestPage,SuggestionMessage')]
    procedure SuccessiveReportsDoNotShareSentToBank()
    var
        Entry: Record "Vendor Ledger Entry";
        Journal: Record "Gen. Journal Line";
        Bank: Record "Bank Account";
    begin
        EnableFeature();
        CreateSuggestionInvoice(Entry, Journal, Bank);
        RunSuggestion(Entry, Journal, Bank."No.", true, false, true, false);
        Assert.IsTrue(Journal.IsEmpty(), 'Selected must exclude an entry with no export.');
        RunSuggestion(Entry, Journal, Bank."No.", false, false, false, false);
        Entry.CalcFields("Remaining Amount");
        AssertSuggestedLine(Journal, -Entry."Remaining Amount", WorkDate() + 1);
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('SuggestionRequestPage,SuggestionMessage')]
    procedure FailedReportDoesNotLeakSentToBank()
    var
        Entry: Record "Vendor Ledger Entry";
        Journal: Record "Gen. Journal Line";
        Bank: Record "Bank Account";
        Exported: Record "Ref. Payment - Exported FI";
        Observer: Codeunit "Banking FI Posting Tests";
    begin
        EnableFeature();
        CreateSuggestionInvoice(Entry, Journal, Bank);
        CreateExport(Entry, Bank."No.", WorkDate() + 2, 37, true, false);
        Observer.SetFailOnSave();
        BindSubscription(Observer);
        asserterror RunSuggestion(Entry, Journal, Bank."No.", true, false, true, false);
        Assert.ExpectedError('Stop the suggestion after amount calculation.');
        UnbindSubscription(Observer);
        Exported.SetRange("Entry No.", Entry."Entry No.");
        Exported.DeleteAll();

        RunSuggestion(Entry, Journal, Bank."No.", false, false, false, false);

        Entry.CalcFields("Remaining Amount");
        AssertSuggestedLine(Journal, -Entry."Remaining Amount", WorkDate() + 1);
        DisableFeature();
    end;

#if not CLEAN30
    [Test]
    [HandlerFunctions('SuggestionMessage')]
    procedure FeatureOffIgnoresNewExportedPayments()
    var
        Entry: Record "Vendor Ledger Entry";
        Journal: Record "Gen. Journal Line";
        Bank: Record "Bank Account";
    begin
        EnableFeature();
        CreateSuggestionInvoice(Entry, Journal, Bank);
        CreateExport(Entry, Bank."No.", WorkDate() + 3, 37, true, false);
        LibraryBanking.SetFeatureEnabled(false);
        RunSuggestion(Entry, Journal, Bank."No.", false, false, false, false);
        Entry.CalcFields("Remaining Amount");
        AssertSuggestedLine(Journal, -Entry."Remaining Amount", WorkDate() + 1);
        Assert.AreEqual(0D, Journal."Planned Payment Date", 'Feature OFF must not populate extension payment fields.');
        UnbindSubscription(LibraryBanking);
    end;
#endif

    local procedure CreateSuggestionInvoice(var Entry: Record "Vendor Ledger Entry"; var Journal: Record "Gen. Journal Line"; var Bank: Record "Bank Account")
    var
        Header: Record "Purchase Header";
        Template: Record "Gen. Journal Template";
        Batch: Record "Gen. Journal Batch";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        InvoiceNo: Code[20];
    begin
        LibraryPurchase.CreatePurchaseInvoice(Header);
        Header.SetHideValidationDialog(true);
        Header.Validate("Currency Code", '');
        Header.Validate("Payment Discount %", 0);
        Header."Payment Message" := 'Report instance payment';
        Header.Validate("Due Date", WorkDate());
        Header.Modify(true);
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(Header, true, true);
        Entry.SetRange("Vendor No.", Header."Buy-from Vendor No.");
        Entry.SetRange("Document Type", Entry."Document Type"::Invoice);
        Entry.SetRange("Document No.", InvoiceNo);
        Entry.FindFirst();
        Entry."Accepted Payment Tolerance" := 1;
        Entry.Modify();
        LibraryERM.CreateGenJournalTemplate(Template);
        LibraryERM.CreateGenJournalBatch(Batch, Template.Name);
        LibraryERM.CreateBankAccount(Bank);
        Journal."Journal Template Name" := Batch."Journal Template Name";
        Journal."Journal Batch Name" := Batch.Name;
    end;

    local procedure CreateExport(Entry: Record "Vendor Ledger Entry"; BankNo: Code[20]; PaymentDate: Date; Amount: Decimal; Transferred: Boolean; Posted: Boolean)
    var
        Exported: Record "Ref. Payment - Exported FI";
        No: Integer;
    begin
        if Exported.FindLast() then
            No := Exported."No.";
        Exported.Init();
        Exported."No." := No + 1;
        Exported."Vendor No." := Entry."Vendor No.";
        Exported."Entry No." := Entry."Entry No.";
        Exported."Payment Account" := BankNo;
        Exported."Payment Date" := PaymentDate;
        Exported.Amount := Amount;
        Exported.Transferred := Transferred;
        Exported."Posted to G/L" := Posted;
        Exported.Insert();
    end;

    local procedure RunSuggestion(Entry: Record "Vendor Ledger Entry"; var Journal: Record "Gen. Journal Line"; BankNo: Code[20]; SentToBank: Boolean; Summarize: Boolean; WithRequestPage: Boolean; UseDueDate: Boolean)
    var
        Vendor: Record Vendor;
        Suggestion: Report "Suggest Vendor Payments";
    begin
        RequestSentToBank := SentToBank;
        RequestSummarize := Summarize;
        RequestUseDueDate := UseDueDate;
        RequestBankNo := BankNo;
        Suggestion.SetGenJnlLine(Journal);
        Vendor.SetRange("No.", Entry."Vendor No.");
        Suggestion.SetTableView(Vendor);
        Suggestion.InitializeRequest(
            WorkDate() + 10, false, 0, false, WorkDate() + 1, 'FI-PAYMENT', Summarize,
            "Gen. Journal Account Type"::"Bank Account", BankNo, "Bank Payment Type"::" ");
        Suggestion.UseRequestPage(WithRequestPage);
        Suggestion.Run();
        Journal.SetRange("Journal Template Name", Journal."Journal Template Name");
        Journal.SetRange("Journal Batch Name", Journal."Journal Batch Name");
        Journal.SetRange("Account Type", Journal."Account Type"::Vendor);
        Journal.SetRange("Account No.", Entry."Vendor No.");
    end;

    local procedure AssertSuggestedLine(var Journal: Record "Gen. Journal Line"; Amount: Decimal; PostingDate: Date)
    begin
        Assert.AreEqual(1, Journal.Count(), 'Exactly one vendor payment must be suggested.');
        Journal.FindFirst();
        Assert.AreEqual(Amount, Journal.Amount, 'The actual suggested journal amount must match.');
        Assert.AreEqual(PostingDate, Journal."Posting Date", 'The actual posting date must be selected before journal validation.');
    end;

    procedure SetFailOnSave()
    begin
        FailOnSave := true;
    end;

    procedure GetCapturedAmounts(var Journal: Record "Gen. Journal Line"; var Payable: Record "Payable Vendor Ledger Entry" temporary; var Buffer: Record "Vendor Payment Buffer" temporary)
    begin
        Journal := CapturedJournal;
        Payable := CapturedPayable;
        Buffer := CapturedBuffer;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Suggest Vendor Payments", 'OnInsertGenJournalLineOnBeforeSetPostingDate', '', false, false)]
    local procedure CaptureBuffer(TempVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary)
    begin
        CapturedBuffer := TempVendorPaymentBuffer;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Suggest Vendor Payments", 'OnAfterSaveAmount', '', false, false)]
    local procedure CaptureAmounts(var GenJournalLine: Record "Gen. Journal Line"; var TempPayableVendorLedgerEntry: Record "Payable Vendor Ledger Entry" temporary)
    begin
        CapturedJournal := GenJournalLine;
        CapturedPayable := TempPayableVendorLedgerEntry;
        if FailOnSave then
            Error('Stop the suggestion after amount calculation.');
    end;

    [RequestPageHandler]
    procedure SuggestionRequestPage(var Suggestion: TestRequestPage "Suggest Vendor Payments")
    begin
        Suggestion.LastPaymentDate.SetValue(WorkDate() + 10);
        Suggestion.PostingDate.SetValue(WorkDate() + 1);
        Suggestion.StartingDocumentNo.SetValue('FI-PAYMENT');
        Suggestion.FindPaymentDiscounts.SetValue(false);
        Suggestion.UseVendorPriority.SetValue(false);
        Suggestion."Available Amount (LCY)".SetValue(0);
        Suggestion.SkipExportedPayments.SetValue(false);
        Suggestion.CheckOtherJournalBatches.SetValue(false);
        Suggestion.UseDueDateAsPostingDate.SetValue(false);
        Suggestion.SummarizePerVendor.SetValue(RequestSummarize);
        Suggestion.BalAccountType.SetValue("Gen. Journal Account Type"::"Bank Account");
        Suggestion.BalAccountNo.SetValue(RequestBankNo);
        Suggestion.BankPaymentType.SetValue("Bank Payment Type"::" ");
        Suggestion.SentToBankFI.SetValue(RequestSentToBank);
        Suggestion.UseDueDateAsPostingDate.SetValue(RequestUseDueDate);
        if RequestUseDueDate then
            Suggestion.DueDateOffset.SetValue('<2D>');
        Suggestion.OK().Invoke();
    end;

    [MessageHandler]
    procedure SuggestionMessage(Message: Text[1024])
    begin
    end;

    local procedure VerifySuggestedPaymentMessages(SummarizePerVendor: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        JournalTemplate: Record "Gen. Journal Template";
        JournalBatch: Record "Gen. Journal Batch";
        Journal: Record "Gen. Journal Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
        InvoiceNo: Code[20];
    begin
        EnableFeature();
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader."Bank Message Type" := PurchaseHeader."Bank Message Type"::"Long Message";
        PurchaseHeader."Payment Message" := 'Suggested payment message';
        PurchaseHeader."Payment Message 2" := 'Suggested payment continuation';
        PurchaseHeader.Validate("Due Date", WorkDate());
        PurchaseHeader.Modify(true);
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VendorLedgerEntry.SetRange("Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Document No.", InvoiceNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.TestField("Payment Message", PurchaseHeader."Payment Message");

        LibraryERM.CreateGenJournalTemplate(JournalTemplate);
        LibraryERM.CreateGenJournalBatch(JournalBatch, JournalTemplate.Name);
        Journal."Journal Template Name" := JournalBatch."Journal Template Name";
        Journal."Journal Batch Name" := JournalBatch.Name;
        SuggestVendorPayments.SetGenJnlLine(Journal);
        Vendor.SetRange("No.", PurchaseHeader."Buy-from Vendor No.");
        SuggestVendorPayments.SetTableView(Vendor);
        SuggestVendorPayments.InitializeRequest(
            WorkDate(), false, 0, false, WorkDate(), 'FI-PAYMENT', SummarizePerVendor,
            "Gen. Journal Account Type"::"G/L Account", '', "Bank Payment Type"::" ");
        SuggestVendorPayments.UseRequestPage(false);
        SuggestVendorPayments.Run();

        Journal.SetRange("Journal Template Name", JournalBatch."Journal Template Name");
        Journal.SetRange("Journal Batch Name", JournalBatch.Name);
        Journal.SetRange("Account Type", Journal."Account Type"::Vendor);
        Journal.SetRange("Account No.", PurchaseHeader."Buy-from Vendor No.");
        Journal.FindFirst();
        Assert.AreEqual(VendorLedgerEntry."Bank Message Type", Journal."Bank Message Type", 'The suggested payment must retain the message type.');
        Assert.AreEqual(VendorLedgerEntry."Payment Message", Journal."Payment Message", 'The suggested payment must retain the first message.');
        Assert.AreEqual(VendorLedgerEntry."Payment Message 2", Journal."Payment Message 2", 'The suggested payment must retain the continuation.');
        Assert.AreEqual(VendorLedgerEntry."Planned Payment Date", Journal."Planned Payment Date", 'The suggested payment must retain the payment date.');
        DisableFeature();
    end;

    local procedure EnableFeature()
    begin
#if not CLEAN30
        LibraryBanking.SetFeatureEnabled(true);
        BindSubscription(LibraryBanking);
#endif
    end;

    local procedure DisableFeature()
    begin
#if not CLEAN30
        UnbindSubscription(LibraryBanking);
#endif
    end;
}
