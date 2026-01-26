codeunit 142072 "UT PAG SWS46"
{
    // // [FEATURE] [UI]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnNewRecordCashReceiptJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [FEATURE] [Cash Receipt Journal]
        // [SCENARIO] Validate OnNewRecord Trigger of Page ID - 255 Cash Receipt Journal.
        // [GIVEN] Gen. Journal Batch "X" with in "Cash Receipts" template
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::"Cash Receipts");
        CashReceiptJournal.OpenEdit();

        // [WHEN] "X" is set in Cash Receipt Journal
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Default value of Document Type and Account Type on Page Cash Receipt Journal is Payment and Customer respectively.
        CashReceiptJournal."Document Type".AssertEquals(GenJournalLine."Document Type"::Payment);
        CashReceiptJournal."Document Type".AssertEquals(GenJournalLine."Account Type"::Customer);
        CashReceiptJournal.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpdateInfoBoxAgeDaysCashReceiptJournal()
    var
        FactBoxFieldValue: Option AgeDays,PaymDiscDays,DueDays,PMTDiscount;
    begin
        // [FEATURE] [Cash Receipt Journal]
        // [SCENARIO] Age Days on Cash Receipt Journal FactBox is updated according to Posting Date on Customer Ledger Entry.
        UpdateInfoBoxPaymentJournal(CalcDate('<-CM>', WorkDate()), 0D, 0D, 0, FactBoxFieldValue::AgeDays);  // Posting Date of Customer Ledger Entry Less than Payment Journal Posting Date.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpdateInfoBoxPaymDiscDaysCashReceiptJournal()
    var
        FactBoxFieldValue: Option AgeDays,PaymDiscDays,DueDays,PMTDiscount;
    begin
        // [FEATURE] [Cash Receipt Journal]
        // [SCENARIO] Payment Discount Days on Cash Receipt Journal FactBox is updated according to Payment Discount Date on Customer Ledger Entry.
        UpdateInfoBoxPaymentJournal(WorkDate(), CalcDate('<+CM>', WorkDate()), 0D, 0, FactBoxFieldValue::PaymDiscDays);  // Posting Date - WORKDATE and Payment Discount Date of Customer Ledger Entry greater than Payment Journal Posting Date.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpdateInfoBoxDueDaysCashReceiptJournal()
    var
        FactBoxFieldValue: Option AgeDays,PaymDiscDays,DueDays,PMTDiscount;
    begin
        // [FEATURE] [Cash Receipt Journal]
        // [SCENARIO] Due Days on Cash Receipt Journal FactBox is updated according to Due Date on Customer Ledger Entry.
        UpdateInfoBoxCashReceiptJournal(WorkDate(), 0D, CalcDate('<+CM>', WorkDate()), 0, FactBoxFieldValue::DueDays);  // Posting Date - WORKDATE and Due Date of Customer Ledger Entry greater than Payment Journal Posting Date.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpdateInfoBoxPMTDiscountCashReceiptJournal()
    var
        FactBoxFieldValue: Option AgeDays,PaymDiscDays,DueDays,PMTDiscount;
    begin
        // [FEATURE] [Cash Receipt Journal]
        // [SCENARIO] Payment Discount on Cash Receipt Journal FactBox is updated according to Remaining Payment Discount Possible on Customer Ledger Entry.
        UpdateInfoBoxCashReceiptJournal(WorkDate(), 0D, 0D, 1, FactBoxFieldValue::PMTDiscount);  // Posting Date - WORKDATE and Remaining Payment Discount Possible is not zero on Customer Ledger Entry.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnNewRecordPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO] Validate OnNewRecord Trigger of Page ID - 256 Payment Journal.
        // [GIVEN] Gen. Journal Batch "X" with in "Payments" template
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        PaymentJournal.OpenEdit();

        // [WHEN] "X" is set in Payment Journal
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Default value of Document Type and Account Type on Page Payment Journal is Payment and Vendor respectively.
        PaymentJournal."Document Type".AssertEquals(GenJournalLine."Document Type"::Payment);
        PaymentJournal."Account Type".AssertEquals(GenJournalLine."Account Type"::Vendor);
        PaymentJournal.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpdateInfoBoxAgeDaysPaymentJournal()
    var
        FactBoxFieldValue: Option AgeDays,PaymDiscDays,DueDays,PmtDiscount;
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO] Age Days on Payment Journal FactBox is updated according to Posting Date on Vendor Ledger Entry.
        UpdateInfoBoxPaymentJournal(CalcDate('<-CM>', WorkDate()), 0D, 0D, 0, FactBoxFieldValue::AgeDays);  // Posting Date of Vendor Ledger Entry Less than Payment Journal Posting Date.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpdateInfoBoxPaymDiscDaysPaymentJournal()
    var
        FactBoxFieldValue: Option AgeDays,PaymDiscDays,DueDays,PmtDiscount;
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO] Payment Discount Days on Payment Journal FactBox is updated according to Payment Discount Date on Vendor Ledger Entry.
        UpdateInfoBoxPaymentJournal(WorkDate(), CalcDate('<+CM>', WorkDate()), 0D, 0, FactBoxFieldValue::PaymDiscDays);  // Posting Date - WORKDATE and Payment Discount Date of Vendor Ledger Entry greater than Payment Journal Posting Date.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpdateInfoBoxDueDaysPaymentJournal()
    var
        FactBoxFieldValue: Option AgeDays,PaymDiscDays,DueDays,PmtDiscount;
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO] Due Days on Payment Journal FactBox is updated according to Payment Discount Date on Vendor Ledger Entry.
        UpdateInfoBoxPaymentJournal(WorkDate(), 0D, CalcDate('<+CM>', WorkDate()), 0, FactBoxFieldValue::DueDays);  // Posting Date - WORKDATE and Due Date of Vendor Ledger Entry greater than Payment Journal Posting Date.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpdateInfoBoxPmtDiscountPaymentJournal()
    var
        FactBoxFieldValue: Option AgeDays,PaymDiscDays,DueDays,PmtDiscount;
    begin
        // [FEATURE] [Cash Receipt Journal]
        // [SCENARIO] Payment Discount on Payment Journal FactBox is updated according to Remaining Payment Discount Possible on Vendor Ledger Entry.
        UpdateInfoBoxPaymentJournal(WorkDate(), 0D, 0D, 1, FactBoxFieldValue::PmtDiscount);  // Posting Date - WORKDATE and Remaining Payment Discount Possible is 1 on Vendor Ledger Entry.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateInfoBoxAmountsCashReceiptJournalCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Cash Receipt Journal]
        // [SCENARIO 364296] Calclulate Payment and Remaining After Payment amounts in "Cash Receipt Journal FactBox" when Customer as Account
        // [GIVEN] Posted Invoice "I" with Amount "X" for Customer "C"
        CustomerNo := LibrarySales.CreateCustomerNo();
        InvoiceNo := PostGenJournalInvoice(GenJournalLine."Account Type"::Customer, CustomerNo, LibraryRandom.RandDec(100, 2));
        FindCustomerLedgerEntry(InvoiceNo, CustomerNo, CustLedgerEntry);

        // [GIVEN] Cash Receipt Journal "J" with "C" in "Account No."
        CreateGeneralJournalLine(GenJournalLine, GenJournalTemplate.Type::"Cash Receipts");
        CustLedgerEntry.CalcFields(Amount);
        UpdateGenJournalLineAmountAndAccount(
          GenJournalLine, -CustLedgerEntry.Amount, GenJournalLine."Account Type"::Customer, CustomerNo);

        // [WHEN] "I" is applied to "J"
        UpdateAppliesToDocCashReceiptJournal(CustLedgerEntry, GenJournalLine."Journal Batch Name");

        // [THEN] "Payment" = -"X" and "Remaining After Payment" = 0 in "Cash Receipt Journal Fact Box"
        VerifyPaymentAmountsCashReceiptJournal(GenJournalLine, -GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateInfoBoxAmountsPaymentJournalVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO 364296] Calclulate Payment and Remaining After Payment amounts in "Payment Journal FactBox" when Vendor as Account
        // [GIVEN] Posted Invoice "I" with Amount "X" for Vendor "V"
        VendorNo := LibraryPurchase.CreateVendorNo();
        InvoiceNo := PostGenJournalInvoice(GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandDec(100, 2));
        FindVendorLedgerEntry(InvoiceNo, VendorNo, VendorLedgerEntry);

        // [GIVEN] Payment Journal "J" with "V" in "Account No."
        CreateGeneralJournalLine(GenJournalLine, GenJournalTemplate.Type::Payments);
        VendorLedgerEntry.CalcFields(Amount);
        UpdateGenJournalLineAmountAndAccount(
          GenJournalLine, -VendorLedgerEntry.Amount, GenJournalLine."Account Type"::Vendor, VendorNo);

        // [WHEN] "I" is applied to "J"
        UpdateAppliesToDocPaymentJournal(VendorLedgerEntry, GenJournalLine."Journal Batch Name");

        // [THEN] "Payment" = -"X" and "Remaining After Payment" = 0 in Payment Journal Fact Box"
        VerifyPaymentAmountsPaymentJournal(GenJournalLine, -GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateInfoBoxAmountsCashReceiptJournalCustomerAsBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Cash Receipt Journal]
        // [SCENARIO 364296] Calclulate Payment and Remaining After Payment amounts in "Cash Receipt Journal FactBox" when Customer as Balance Account
        // [GIVEN] Posted Invoice "I" with Amount "X" for Customer "C"
        CustomerNo := LibrarySales.CreateCustomerNo();
        InvoiceNo := PostGenJournalInvoice(GenJournalLine."Account Type"::Customer, CustomerNo, LibraryRandom.RandDec(100, 2));
        FindCustomerLedgerEntry(InvoiceNo, CustomerNo, CustLedgerEntry);

        // [GIVEN] Cash Receipt Journal "J" with "C" in "Bal. Account No."
        CreateGeneralJournalLine(GenJournalLine, GenJournalTemplate.Type::"Cash Receipts");
        CustLedgerEntry.CalcFields(Amount);
        UpdateGenJournalLineAmountAndBalAccount(
          GenJournalLine, CustLedgerEntry.Amount, GenJournalLine."Bal. Account Type"::Customer, CustomerNo);

        // [WHEN] "I" is applied to "J"
        UpdateAppliesToDocCashReceiptJournal(CustLedgerEntry, GenJournalLine."Journal Batch Name");

        // [THEN] "Payment" = "X" and "Remaining After Payment" = 0 in "Cash Receipt Journal Fact Box"
        VerifyPaymentAmountsCashReceiptJournal(GenJournalLine, GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateInfoBoxAmountsPaymentJournalVendorAsBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO 364296] Calclulate Payment and Remaining After Payment amounts in "Payment Journal FactBox" when Vendor as Balance Account
        // [GIVEN] Posted Invoice "I" with Amount "X" for Vendor "V"
        VendorNo := LibraryPurchase.CreateVendorNo();
        InvoiceNo := PostGenJournalInvoice(GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandDec(100, 2));
        FindVendorLedgerEntry(InvoiceNo, VendorNo, VendorLedgerEntry);
        // [GIVEN] Payment Journal "J" with "V" in "Bal. Account No."
        CreateGeneralJournalLine(GenJournalLine, GenJournalTemplate.Type::Payments);
        VendorLedgerEntry.CalcFields(Amount);
        UpdateGenJournalLineAmountAndBalAccount(
          GenJournalLine, VendorLedgerEntry.Amount, GenJournalLine."Bal. Account Type"::Vendor, VendorNo);

        // [WHEN] "I" is applied to "J"
        UpdateAppliesToDocPaymentJournal(VendorLedgerEntry, GenJournalLine."Journal Batch Name");

        // [THEN] "Payment" = "X" and "Remaining After Payment" = 0 in "Payment Journal Fact Box"
        VerifyPaymentAmountsPaymentJournal(GenJournalLine, GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectHandler')]
    [Scope('OnPrem')]
    procedure PaymentJournalInfoBoxForPaymentAndRefund()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
        PaymentAmount: Decimal;
        RefundAmount: Decimal;
        BalanceLCYPmt: Decimal;
        BalanceLCYRefund: Decimal;
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO 381522] Show correct "Totals" values when both payment and refund records in Payment Journal

        // [GIVEN] Gen. Journal Line of "Document Type" = Payment, Amount = 300 and "Balance (LCY)" = 30
        // [GIVEN] Gen. Journal Line of "Document Type" = Refund, Amount = -100 and "Balance (LCY)" = 10
        PaymentAmount := LibraryRandom.RandDec(10, 2);
        RefundAmount := -LibraryRandom.RandDec(10, 2);
        BalanceLCYPmt := LibraryRandom.RandDec(10, 2);
        BalanceLCYRefund := LibraryRandom.RandDec(10, 2);

        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        GenJournalLine."Account No." := LibraryPurchase.CreateVendorNo();
        CreatePaymentAndRefund(
          GenJournalLine, PaymentAmount, RefundAmount, BalanceLCYPmt, BalanceLCYRefund, GenJournalTemplate.Type::Payments);

        // [WHEN] Open Payment Journal page
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        OpenPaymentJournal(PaymentJournal, GenJournalLine."Journal Batch Name");

        // [THEN] Payment Journal FactBox Payments = -200, Payment = -300, Total Balance = 40
        PaymentJournal.Control1906888707.TotalPayment.AssertEquals(-PaymentAmount - RefundAmount);
        PaymentJournal.Control1906888707.TotalBalance.AssertEquals(BalanceLCYPmt + BalanceLCYRefund);
        PaymentJournal.Control1906888707.PaymentAmt.AssertEquals(-PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectHandler')]
    [Scope('OnPrem')]
    procedure CashReceipJournalInfoBoxForPaymentAndRefund()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        PaymentAmount: Decimal;
        RefundAmount: Decimal;
        BalanceLCYPmt: Decimal;
        BalanceLCYRefund: Decimal;
    begin
        // [FEATURE] [Cash Receipt Journal]
        // [SCENARIO 381522] Show correct "Totals" values when both payment and refund records in Cash receipt Journal

        // [GIVEN] Gen. Journal Line of "Document Type" = Payment, Amount = -300 and "Balance (LCY)" = 30
        // [GIVEN] Gen. Journal Line of "Document Type" = Refund, Amount = 100 and "Balance (LCY)" = 10
        PaymentAmount := -LibraryRandom.RandDec(10, 2);
        RefundAmount := LibraryRandom.RandDec(10, 2);
        BalanceLCYPmt := LibraryRandom.RandDec(10, 2);
        BalanceLCYRefund := LibraryRandom.RandDec(10, 2);

        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Account No." := LibrarySales.CreateCustomerNo();
        CreatePaymentAndRefund(
          GenJournalLine, PaymentAmount, RefundAmount, BalanceLCYPmt, BalanceLCYRefund, GenJournalTemplate.Type::"Cash Receipts");

        // [WHEN] Open Cash Receipt Journal page
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        OpenCashReceiptJournal(CashReceiptJournal, GenJournalLine."Journal Batch Name");

        // [THEN] Cash Receipt Journal FactBox Payments = 200, Payment = 300, Total Balance = 40
        CashReceiptJournal.Control1906888607.TotalPayment.AssertEquals(-PaymentAmount - RefundAmount);
        CashReceiptJournal.Control1906888607.TotalBalance.AssertEquals(BalanceLCYPmt + BalanceLCYRefund);
        CashReceiptJournal.Control1906888607.PaymentAmt.AssertEquals(-PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectHandler')]
    [Scope('OnPrem')]
    procedure BalancePaymentJournalInfoBoxForPaymentAndRefund()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
        PaymentAmount: Decimal;
        RefundAmount: Decimal;
        BalanceLCYPmt: Decimal;
        BalanceLCYRefund: Decimal;
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO 381522] Show correct "Totals" values when both payment and refund records as Balance in Payment Journal

        // [GIVEN] Gen. Journal Line of "Document Type" = Payment, Amount = 300 and "Balance (LCY)" = 30
        // [GIVEN] Gen. Journal Line of "Document Type" = Refund, Amount = -100 and "Balance (LCY)" = 10
        PaymentAmount := LibraryRandom.RandDec(10, 2);
        RefundAmount := -LibraryRandom.RandDec(10, 2);
        BalanceLCYPmt := LibraryRandom.RandDec(10, 2);
        BalanceLCYRefund := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Vendor as Balance Account in Payment Journal
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::Vendor;
        GenJournalLine."Bal. Account No." := LibraryPurchase.CreateVendorNo();
        CreatePaymentAndRefundOnBalAccount(
          GenJournalLine, PaymentAmount, RefundAmount, BalanceLCYPmt, BalanceLCYRefund, GenJournalTemplate.Type::Payments);

        // [WHEN] Open Payment Journal page
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        OpenPaymentJournal(PaymentJournal, GenJournalLine."Journal Batch Name");

        // [THEN] Payment Journal FactBox Payments = -200, Payment = -300, Total Balance = 40
        PaymentJournal.Control1906888707.TotalPayment.AssertEquals(PaymentAmount + RefundAmount);
        PaymentJournal.Control1906888707.TotalBalance.AssertEquals(BalanceLCYPmt + BalanceLCYRefund);
        PaymentJournal.Control1906888707.PaymentAmt.AssertEquals(PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectHandler')]
    [Scope('OnPrem')]
    procedure BalanceCashReceipJournalInfoBoxForPaymentAndRefund()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        PaymentAmount: Decimal;
        RefundAmount: Decimal;
        BalanceLCYPmt: Decimal;
        BalanceLCYRefund: Decimal;
    begin
        // [FEATURE] [Cash Receipt Journal]
        // [SCENARIO 381522] Show correct "Totals" values when both payment and refund records as Balance in Cash receipt Journal

        // [GIVEN] Gen. Journal Line of "Document Type" = Payment, Amount = -300 and "Balance (LCY)" = 30
        // [GIVEN] Gen. Journal Line of "Document Type" = Refund, Amount = 100 and "Balance (LCY)" = 10
        PaymentAmount := -LibraryRandom.RandDec(10, 2);
        RefundAmount := LibraryRandom.RandDec(10, 2);
        BalanceLCYPmt := LibraryRandom.RandDec(10, 2);
        BalanceLCYRefund := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Customer as Balance Account in Cash Receipt Journal
        GenJournalLine."Bal. Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Bal. Account No." := LibrarySales.CreateCustomerNo();
        CreatePaymentAndRefundOnBalAccount(
          GenJournalLine, PaymentAmount, RefundAmount, BalanceLCYPmt, BalanceLCYRefund, GenJournalTemplate.Type::"Cash Receipts");

        // [WHEN] Open Cash Receipt Journal page
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        OpenCashReceiptJournal(CashReceiptJournal, GenJournalLine."Journal Batch Name");

        // [THEN] Cash Receipt Journal FactBox Payments = 200, Payment = 300, Total Balance = 40
        CashReceiptJournal.Control1906888607.TotalPayment.AssertEquals(PaymentAmount + RefundAmount);
        CashReceiptJournal.Control1906888607.TotalBalance.AssertEquals(BalanceLCYPmt + BalanceLCYRefund);
        CashReceiptJournal.Control1906888607.PaymentAmt.AssertEquals(PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler')]
    [Scope('OnPrem')]
    procedure UpdateInfoBoxAmountsCashReceiptJournalCustomerWithAppliedEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Cash Receipt Journal]
        // [SCENARIO 331818] Calclulate Payment and Remaining After Payment amounts in "Cash Receipt Journal FactBox" when Customer as Account, Entry is applied by ID.
        // [GIVEN] Cleared the Gen. Journal Template
        ResetGenJnlTemplate();
        // [GIVEN] Posted Invoice "I" with Amount "X" for Customer "C"
        CustomerNo := LibrarySales.CreateCustomerNo();
        InvoiceNo := PostGenJournalInvoice(GenJournalLine."Account Type"::Customer, CustomerNo, LibraryRandom.RandDec(100, 2));
        FindCustomerLedgerEntry(InvoiceNo, CustomerNo, CustLedgerEntry);

        // [GIVEN] Cash Receipt Journal "J" with "C" in "Account No."
        CreateGeneralJournalLine(GenJournalLine, GenJournalTemplate.Type::"Cash Receipts");
        CustLedgerEntry.CalcFields(Amount);
        UpdateGenJournalLineAmountAndAccount(
          GenJournalLine, -CustLedgerEntry.Amount, GenJournalLine."Account Type"::Customer, CustomerNo);

        // [WHEN] "I" is applied to "J"
        UpdateAppliesToDocCashReceiptJournalWithAppliedEntries(GenJournalLine."Journal Batch Name");

        // [THEN] "Payment" = -"X" and "Remaining After Payment" = 0 in "Cash Receipt Journal Fact Box"
        VerifyPaymentAmountsCashReceiptJournalWithAppliedEntries(GenJournalLine, -GenJournalLine.Amount);

        // [THEN] All Variable were used in test.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler')]
    [Scope('OnPrem')]
    procedure UpdateInfoBoxAmountsPaymentJournalVendorWithAppliedEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO 331818] Calclulate Payment and Remaining After Payment amounts in "Payment Journal FactBox" when Vendor as Account, Entry is applied by ID.
        // [GIVEN] Cleared the Gen. Journal Template
        ResetGenJnlTemplate();
        // [GIVEN] Posted Invoice "I" with Amount "X" for Vendor "V"
        VendorNo := LibraryPurchase.CreateVendorNo();
        InvoiceNo := PostGenJournalInvoice(GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandDec(100, 2));
        FindVendorLedgerEntry(InvoiceNo, VendorNo, VendorLedgerEntry);

        // [GIVEN] Payment Journal "J" with "V" in "Account No."
        CreateGeneralJournalLine(GenJournalLine, GenJournalTemplate.Type::Payments);
        VendorLedgerEntry.CalcFields(Amount);
        UpdateGenJournalLineAmountAndAccount(
          GenJournalLine, -VendorLedgerEntry.Amount, GenJournalLine."Account Type"::Vendor, VendorNo);

        // [WHEN] "I" is applied to "J"
        UpdateAppliesToDocPaymentJournalWithAppliedEntries(GenJournalLine."Journal Batch Name");

        // [THEN] "Payment" = -"X" and "Remaining After Payment" = 0 in Payment Journal Fact Box"
        VerifyPaymentAmountsPaymentJournalWithAppliedEntries(GenJournalLine, -GenJournalLine.Amount);

        // [THEN] All Variable were used in test.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler')]
    [Scope('OnPrem')]
    procedure UpdateInfoBoxAmountsCashReceiptJournalCustomerAsBalanceWithAppliedEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Cash Receipt Journal]
        // [SCENARIO 331818] Calclulate Payment and Remaining After Payment amounts in "Cash Receipt Journal FactBox" when Customer as Balance Account, Entry is applied by ID.
        // [GIVEN] Cleared the Gen. Journal Template
        ResetGenJnlTemplate();

        // [GIVEN] Posted Invoice "I" with Amount "X" for Customer "C"
        CustomerNo := LibrarySales.CreateCustomerNo();
        InvoiceNo := PostGenJournalInvoice(GenJournalLine."Account Type"::Customer, CustomerNo, LibraryRandom.RandDec(100, 2));
        FindCustomerLedgerEntry(InvoiceNo, CustomerNo, CustLedgerEntry);

        // [GIVEN] Cash Receipt Journal "J" with "C" in "Bal. Account No."
        CreateGeneralJournalLine(GenJournalLine, GenJournalTemplate.Type::"Cash Receipts");
        CustLedgerEntry.CalcFields(Amount);
        UpdateGenJournalLineAmountAndBalAccount(
          GenJournalLine, CustLedgerEntry.Amount, GenJournalLine."Bal. Account Type"::Customer, CustomerNo);

        // [WHEN] "I" is applied to "J"
        UpdateAppliesToDocCashReceiptJournalWithAppliedEntries(GenJournalLine."Journal Batch Name");

        // [THEN] "Payment" = "X" and "Remaining After Payment" = 0 in "Cash Receipt Journal Fact Box"
        VerifyPaymentAmountsCashReceiptJournalWithAppliedEntries(GenJournalLine, GenJournalLine.Amount);

        // [THEN] All Variable were used in test.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler')]
    [Scope('OnPrem')]
    procedure UpdateInfoBoxAmountsPaymentJournalVendorAsBalanceWithAppliedEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO 331818] Calclulate Payment and Remaining After Payment amounts in "Payment Journal FactBox" when Vendor as Balance Account, Entry is applied by ID.
        // [GIVEN] Cleared the Gen. Journal Template
        ResetGenJnlTemplate();

        // [GIVEN] Posted Invoice "I" with Amount "X" for Vendor "V"
        VendorNo := LibraryPurchase.CreateVendorNo();
        InvoiceNo := PostGenJournalInvoice(GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandDec(100, 2));
        FindVendorLedgerEntry(InvoiceNo, VendorNo, VendorLedgerEntry);
        // [GIVEN] Payment Journal "J" with "V" in "Bal. Account No."
        CreateGeneralJournalLine(GenJournalLine, GenJournalTemplate.Type::Payments);
        VendorLedgerEntry.CalcFields(Amount);
        UpdateGenJournalLineAmountAndBalAccount(
          GenJournalLine, VendorLedgerEntry.Amount, GenJournalLine."Bal. Account Type"::Vendor, VendorNo);

        // [WHEN] "I" is applied to "J"
        UpdateAppliesToDocPaymentJournalWithAppliedEntries(GenJournalLine."Journal Batch Name");

        // [THEN] "Payment" = "X" and "Remaining After Payment" = 0 in "Payment Journal Fact Box"
        VerifyPaymentAmountsPaymentJournalWithAppliedEntries(GenJournalLine, GenJournalLine.Amount);

        // [THEN] All Variable were used in test.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPaymentDiscountDeductionOnPaymentJournalDetailFactfox()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO 469089] The "Payment Journal Details factbox displays incorrect figures for Payment Discount Deduction
        ResetGenJnlTemplate();

        // [GIVEN] Create new Vendor "V" and Posted Invoice "I" with Amount "X"
        VendorNo := CreateVendorWithPmtTerms();
        InvoiceNo := PostGenJournalInvoice(GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandDec(1000, 2));

        // [THEN] Find Posted Vendor Ledger Entry based on Posted "I"
        FindVendorLedgerEntry(InvoiceNo, VendorNo, VendorLedgerEntry);

        // [GIVEN] Payment Journal "J" with "V" in "Account No."
        CreateGeneralJournalLine(GenJournalLine, GenJournalTemplate.Type::Payments);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        UpdateGenJournalLineAmountAndAccount(
            GenJournalLine,
            -(VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry."Remaining Pmt. Disc. Possible"),
            GenJournalLine."Account Type"::Vendor,
            VendorNo);

        // [WHEN] "I" is applied to "J"
        UpdateAppliesToDocPaymentJournal(VendorLedgerEntry, GenJournalLine."Journal Batch Name");

        // [THEN] "Payment" = -"X" and "Remaining After Payment" = 0 in Payment Journal Fact Box"
        VerifyPaymentAmountsPaymentJournalWithAppliedEntries(GenJournalLine, -GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentDiscountDeductionOnPaymentJournalDetailFactfoxWithAppliedEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO 469089] The "Payment Journal Details factbox displays incorrect figures for Payment Discount Deduction
        // [GIVEN] Posted Invoice "I" with Amount "X" for Vendor "V"
        ResetGenJnlTemplate();

        // [GIVEN] Create new Vendor "V" and Posted Invoice "I" with Amount "X"
        VendorNo := CreateVendorWithPmtTerms();
        InvoiceNo := PostGenJournalInvoice(GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandDec(100, 2));

        // [THEN] Find Posted Vendor Ledger Entry based on Posted "I"
        FindVendorLedgerEntry(InvoiceNo, VendorNo, VendorLedgerEntry);

        // [GIVEN] Payment Journal "J" with "V" in "Account No."
        CreateGeneralJournalLine(GenJournalLine, GenJournalTemplate.Type::Payments);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        UpdateGenJournalLineAmountAndAccount(
            GenJournalLine,
            -(VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry."Remaining Pmt. Disc. Possible"),
            GenJournalLine."Account Type"::Vendor,
            VendorNo);

        // [WHEN] "I" is applied to "J"
        UpdateAppliesToDocPaymentJournalWithAppliedEntries(GenJournalLine."Journal Batch Name");

        // [THEN] "Payment" = -"X" and "Remaining After Payment" = 0 in Payment Journal Fact Box"
        VerifyPaymentAmountsPaymentJournalWithAppliedEntries(GenJournalLine, -GenJournalLine.Amount);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, Type);
        GenJournalTemplate.FindFirst();

        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := LibraryUTUtility.GetNewCode10();
        GenJournalBatch.Insert();
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; Type: Enum "Gen. Journal Template Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch, Type);
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Line No." := 1;
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode();
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine.Insert();
    end;

    local procedure CreateCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; AppliesToDocNo: Code[20]; PostingDate: Date; PmtDiscountDate: Date; DueDate: Date; RemainingPmtDiscPossible: Decimal)
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry2.FindLast();
        CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1;
        CustLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Payment;
        CustLedgerEntry."Customer No." := LibraryUTUtility.GetNewCode();
        CustLedgerEntry."Applies-to Doc. No." := AppliesToDocNo;
        CustLedgerEntry."Applies-to Doc. Type" := CustLedgerEntry."Applies-to Doc. Type"::Payment;
        CustLedgerEntry."Posting Date" := PostingDate;
        CustLedgerEntry."Pmt. Discount Date" := PmtDiscountDate;
        CustLedgerEntry."Due Date" := DueDate;
        CustLedgerEntry."Remaining Pmt. Disc. Possible" := RemainingPmtDiscPossible;
        CustLedgerEntry.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AppliesToDocNo: Code[20]; PostingDate: Date; PmtDiscountDate: Date; DueDate: Date; RemainingPmtDiscPossible: Decimal)
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry2.FindLast();
        VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Payment;
        VendorLedgerEntry."Applies-to Doc. No." := AppliesToDocNo;
        VendorLedgerEntry."Vendor No." := LibraryUTUtility.GetNewCode();
        VendorLedgerEntry."Applies-to Doc. Type" := VendorLedgerEntry."Applies-to Doc. Type"::Payment;
        VendorLedgerEntry."Posting Date" := PostingDate;
        VendorLedgerEntry."Pmt. Discount Date" := PmtDiscountDate;
        VendorLedgerEntry."Due Date" := DueDate;
        VendorLedgerEntry."Remaining Pmt. Disc. Possible" := RemainingPmtDiscPossible;
        VendorLedgerEntry.Insert();
    end;

    local procedure CreatePaymentAndRefund(var GenJournalLine: Record "Gen. Journal Line"; PaymentAmount: Decimal; RefundAmount: Decimal; BalanceLCYPmt: Decimal; BalanceLCYRefund: Decimal; TemplateType: Enum "Gen. Journal Template Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, TemplateType);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type", GenJournalLine."Account No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), PaymentAmount);
        GenJournalLine.Validate("Balance (LCY)", BalanceLCYPmt);
        GenJournalLine.Modify(true);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type", GenJournalLine."Account No.",
          GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No.", RefundAmount);
        GenJournalLine.Validate("Balance (LCY)", BalanceLCYRefund);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePaymentAndRefundOnBalAccount(var GenJournalLine: Record "Gen. Journal Line"; PaymentAmount: Decimal; RefundAmount: Decimal; BalanceLCYPmt: Decimal; BalanceLCYRefund: Decimal; TemplateType: Enum "Gen. Journal Template Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, TemplateType);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No.", PaymentAmount);
        GenJournalLine.Validate("Balance (LCY)", BalanceLCYPmt);
        GenJournalLine.Modify(true);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type", GenJournalLine."Account No.",
          GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No.", RefundAmount);
        GenJournalLine.Validate("Balance (LCY)", BalanceLCYRefund);
        GenJournalLine.Modify(true);
    end;

    local procedure FindCustomerLedgerEntry(DocumentNo: Code[20]; CustomerNo: Code[20]; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
    end;

    local procedure FindVendorLedgerEntry(DocumentNo: Code[20]; VendorNo: Code[20]; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure OpenCashReceiptJournal(var CashReceiptJournal: TestPage "Cash Receipt Journal"; JournalBatchName: Code[10])
    begin
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(JournalBatchName);
    end;

    local procedure OpenPaymentJournal(var PaymentJournal: TestPage "Payment Journal"; JournalBatchName: Code[10])
    begin
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(JournalBatchName);
    end;

    local procedure PostGenJournalInvoice(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, AccountType, AccountNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure UpdateAppliesToDocCashReceiptJournal(CustLedgerEntry: Record "Cust. Ledger Entry"; JournalBatchName: Code[10])
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        OpenCashReceiptJournal(CashReceiptJournal, JournalBatchName);
        CashReceiptJournal."Applies-to Doc. Type".SetValue(CustLedgerEntry."Document Type");
        CashReceiptJournal."Applies-to Doc. No.".SetValue(CustLedgerEntry."Document No.");
        CashReceiptJournal.OK().Invoke();
    end;

    local procedure UpdateAppliesToDocPaymentJournal(VendorLedgerEntry: Record "Vendor Ledger Entry"; JournalBatchName: Code[10])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        OpenPaymentJournal(PaymentJournal, JournalBatchName);
        PaymentJournal."Posting Date".SetValue(WorkDate());
        PaymentJournal."Applies-to Doc. Type".SetValue(VendorLedgerEntry."Document Type");
        PaymentJournal.AppliesToDocNo.SetValue(VendorLedgerEntry."Document No.");
        PaymentJournal.OK().Invoke();
    end;

    local procedure UpdateGenJournalLineAmountAndAccount(var GenJournalLine: Record "Gen. Journal Line"; NewAmount: Decimal; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    begin
        GenJournalLine.Validate(Amount, NewAmount);
        GenJournalLine.Validate("Account Type", AccountType);
        GenJournalLine.Validate("Account No.", AccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateGenJournalLineAmountAndBalAccount(var GenJournalLine: Record "Gen. Journal Line"; NewAmount: Decimal; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20])
    begin
        GenJournalLine.Validate(Amount, NewAmount);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateInfoBoxCashReceiptJournal(PostingDate: Date; PmtDiscountDate: Date; DueDate: Date; RemainingPMTDiscPossible: Decimal; FactBoxFieldValue: Option)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Create Cash Receipt Journal.
        CreateGeneralJournalLine(GenJournalLine, GenJournalTemplate.Type::"Cash Receipts");
        CreateCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document No.", PostingDate, PmtDiscountDate, DueDate, RemainingPMTDiscPossible);

        // Exercise: Open and Update Applies To Document Type and Applies to Document No on Cash Receipt Journal.
        UpdateAppliesToDocCashReceiptJournal(CustLedgerEntry, GenJournalLine."Journal Batch Name");

        // Verify: Verify various fields on Cash Receipt Journal FactBox Page.
        VerifyCashReceiptJournal(GenJournalLine, CustLedgerEntry, FactBoxFieldValue);
    end;

    local procedure UpdateInfoBoxPaymentJournal(PostingDate: Date; PmtDiscountDate: Date; DueDate: Date; RemainingPmtDiscPossible: Decimal; FactBoxFieldValue: Option)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Create Payment Journal.
        CreateGeneralJournalLine(GenJournalLine, GenJournalTemplate.Type::Payments);
        CreateVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document No.", PostingDate, PmtDiscountDate, DueDate, RemainingPmtDiscPossible);

        // Exercise: Open and Update Applies To Document Type and Applies to Document No on Payment Journal.
        UpdateAppliesToDocPaymentJournal(VendorLedgerEntry, GenJournalLine."Journal Batch Name");

        // Verify: Verify various fields on Payment Journal FactBox.
        VerifyPaymentJournal(GenJournalLine, VendorLedgerEntry, FactBoxFieldValue);
    end;

    local procedure VerifyCashReceiptJournal(GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry"; FactBox: Option)
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        FactBoxField: Option AgeDays,PaymDiscDays,DueDays,PMTDiscount;
    begin
        OpenCashReceiptJournal(CashReceiptJournal, GenJournalLine."Journal Batch Name");
        case FactBox of
            FactBoxField::AgeDays:
                CashReceiptJournal.Control1906888607.AgeDays.AssertEquals(GenJournalLine."Posting Date" - CustLedgerEntry."Posting Date");
            FactBoxField::PaymDiscDays:
                CashReceiptJournal.Control1906888607.PaymDiscDays.AssertEquals(CustLedgerEntry."Pmt. Discount Date" - GenJournalLine."Posting Date");
            FactBoxField::DueDays:
                CashReceiptJournal.Control1906888607.DueDays.AssertEquals(CustLedgerEntry."Due Date" - GenJournalLine."Posting Date");
            FactBoxField::PMTDiscount:
                CashReceiptJournal.Control1906888607.PMTDiscount.AssertEquals(CustLedgerEntry."Remaining Pmt. Disc. Possible");
        end;
        CashReceiptJournal.Close();
    end;

    local procedure VerifyPaymentJournal(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; FactBox: Option)
    var
        PaymentJournal: TestPage "Payment Journal";
        FactBoxField: Option AgeDays,PaymDiscDays,DueDays,PmtDiscount;
    begin
        OpenPaymentJournal(PaymentJournal, GenJournalLine."Journal Batch Name");
        case FactBox of
            FactBoxField::AgeDays:
                PaymentJournal.Control1906888707.AgeDays.AssertEquals(GenJournalLine."Posting Date" - VendorLedgerEntry."Posting Date");
            FactBoxField::PaymDiscDays:
                PaymentJournal.Control1906888707.PaymDiscDays.AssertEquals(VendorLedgerEntry."Pmt. Discount Date" - GenJournalLine."Posting Date");
            FactBoxField::DueDays:
                PaymentJournal.Control1906888707.DueDays.AssertEquals(VendorLedgerEntry."Due Date" - GenJournalLine."Posting Date");
            FactBoxField::PmtDiscount:
                PaymentJournal.Control1906888707.PmtDiscount.AssertEquals(-VendorLedgerEntry."Remaining Pmt. Disc. Possible");
        end;
        PaymentJournal.Close();
    end;

    local procedure VerifyPaymentAmountsCashReceiptJournal(GenJournalLine: Record "Gen. Journal Line"; PaymentAmount: Decimal)
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        OpenCashReceiptJournal(CashReceiptJournal, GenJournalLine."Journal Batch Name");
        Assert.AreNotEqual(0, GenJournalLine.Amount, GenJournalLine.FieldCaption(Amount));
        CashReceiptJournal.Control1906888607.PaymentAmt.AssertEquals(PaymentAmount);
        Assert.AreEqual(
          0,
          CashReceiptJournal.Control1906888607.RemainAfterPaymentText.AsDecimal(),
          CashReceiptJournal.Control1906888607.RemainAfterPaymentText.Caption);
        CashReceiptJournal.Close();
    end;

    local procedure VerifyPaymentAmountsPaymentJournal(GenJournalLine: Record "Gen. Journal Line"; PaymentAmount: Decimal)
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        OpenPaymentJournal(PaymentJournal, GenJournalLine."Journal Batch Name");
        Assert.AreNotEqual(0, GenJournalLine.Amount, GenJournalLine.FieldCaption(Amount));
        PaymentJournal.Control1906888707.PaymentAmt.AssertEquals(PaymentAmount);
        Assert.AreEqual(
          0,
          PaymentJournal.Control1906888707.RemainAfterPayment.AsDecimal(),
          PaymentJournal.Control1906888707.RemainAfterPayment.Caption);
        PaymentJournal.Close();
    end;

    local procedure UpdateAppliesToDocCashReceiptJournalWithAppliedEntries(JournalBatchName: Code[10])
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        OpenCashReceiptJournal(CashReceiptJournal, JournalBatchName);
        LibraryVariableStorage.Enqueue(CashReceiptJournal."Document No.".Value);
        CashReceiptJournal."Apply Entries".Invoke();
        CashReceiptJournal.OK().Invoke();
    end;

    local procedure UpdateAppliesToDocPaymentJournalWithAppliedEntries(JournalBatchName: Code[10])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        OpenPaymentJournal(PaymentJournal, JournalBatchName);
        LibraryVariableStorage.Enqueue(PaymentJournal."Document No.".Value);
        PaymentJournal.ApplyEntries.Invoke();
        PaymentJournal.OK().Invoke();
    end;

    local procedure VerifyPaymentAmountsCashReceiptJournalWithAppliedEntries(GenJournalLine: Record "Gen. Journal Line"; PaymentAmount: Decimal)
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        OpenCashReceiptJournal(CashReceiptJournal, GenJournalLine."Journal Batch Name");
        Assert.AreNotEqual(0, GenJournalLine.Amount, GenJournalLine.FieldCaption(Amount));
        CashReceiptJournal.Control1906888607.PaymentAmt.AssertEquals(PaymentAmount);
        Assert.AreEqual(
          0,
          CashReceiptJournal.Control1906888607.RemainAfterPaymentText.AsDecimal(),
          CashReceiptJournal.Control1906888607.RemainAfterPaymentText.Caption);
        CashReceiptJournal.Close();
    end;

    local procedure VerifyPaymentAmountsPaymentJournalWithAppliedEntries(GenJournalLine: Record "Gen. Journal Line"; PaymentAmount: Decimal)
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        OpenPaymentJournal(PaymentJournal, GenJournalLine."Journal Batch Name");
        Assert.AreNotEqual(0, GenJournalLine.Amount, GenJournalLine.FieldCaption(Amount));
        PaymentJournal.Control1906888707.PaymentAmt.AssertEquals(PaymentAmount);
        Assert.AreEqual(
          0,
          PaymentJournal.Control1906888707.RemainAfterPayment.AsDecimal(),
          PaymentJournal.Control1906888707.RemainAfterPayment.Caption);
        PaymentJournal.Close();
    end;

    local procedure ResetGenJnlTemplate();
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange("No. Series", '');
        GenJournalTemplate.DeleteAll();
    end;

    local procedure CreateVendorWithPmtTerms(): Code[20]
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", '<1M>');
        Evaluate(PaymentTerms."Discount Date Calculation", '<8D>');
        PaymentTerms.Validate("Discount %", LibraryRandom.RandInt(90));
        PaymentTerms.Modify();

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TemplateSelectHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.FILTER.SetFilter(Name, LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.AppliesToID.SetValue(LibraryVariableStorage.DequeueText());
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.AppliesToID.SetValue(LibraryVariableStorage.DequeueText());
        ApplyVendorEntries.OK().Invoke();
    end;
}

