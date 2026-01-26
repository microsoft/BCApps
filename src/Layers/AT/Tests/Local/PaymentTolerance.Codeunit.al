codeunit 142076 "Payment Tolerance"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Discount] [Payment Tolerance]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPmtDiscountDateWhenUseZeroPmtDisc()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        ExpectedPmtDiscDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 378178] Payment Discount Date should be calculated according to "Discount Date Calculation" of Payment Terms
        Initialize();

        // [GIVEN] Payment Terms "X" with "Discount %" = 0, "Due Date Calculation" = 10 days, "Pmt. Discount Date Calculation" = 5 days
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        PaymentTerms.Validate("Discount %", 0);
        PaymentTerms.Modify(true);

        // [GIVEN] Sales Invoice with "Posting Date" = 01.01
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        ExpectedPmtDiscDate := CalcDate(PaymentTerms."Discount Date Calculation", SalesHeader."Posting Date");

        // [WHEN] Assign Payment Terms "X" to Sales Invoice
        SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);

        // [THEN] "Pmt. Discount Date" = 06.01 in Sales Invoice
        SalesHeader.TestField("Pmt. Discount Date", ExpectedPmtDiscDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPmtDiscountDateWhenUseZeroPmtDisc()
    var
        PaymentTerms: Record "Payment Terms";
        PurchHeader: Record "Purchase Header";
        ExpectedPmtDiscDate: Date;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 378178] Payment Discount Date should be calculated according to "Discount Date Calculation" of Payment Terms
        Initialize();

        // [GIVEN] Payment Terms "X" with "Discount %" = 0, "Due Date Calculation" = 10 days, "Pmt. Discount Date Calculation" = 5 days
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        PaymentTerms.Validate("Discount %", 0);
        PaymentTerms.Modify(true);

        // [GIVEN] Purchase Invoice with "Posting Date" = 01.01
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        ExpectedPmtDiscDate := CalcDate(PaymentTerms."Discount Date Calculation", PurchHeader."Posting Date");

        // [WHEN] Assign Payment Terms "X" to Purchase Invoice
        PurchHeader.Validate("Payment Terms Code", PaymentTerms.Code);

        // [THEN] "Pmt. Discount Date" = 06.01 in Purchase Invoice
        PurchHeader.TestField("Pmt. Discount Date", ExpectedPmtDiscDate);
    end;

    [Test]
    [HandlerFunctions('GenJnlTemplateModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesPmtDiscOnCashReceiptJournalFactboxWhenUseAppliesToID()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        PmtGenJnlLine: Record "Gen. Journal Line";
        CustLedgerEntry: array[2] of Record "Cust. Ledger Entry";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        OldPmtDiscToleranceWarning: Boolean;
        OldPaymentDiscountGracePeriod: DateFormula;
    begin
        // [FEATURE] [Sales] [Payment Discount Tolerance]
        // [SCENARIO 211536] Payment Discount is calculated on "Cash Receipt Journal Factbox" page when Payment applies to multiple invoices by "Applies-To ID"

        Initialize();

        // [GIVEN] Payment Discount Grace Period is 5 days
        UpdateGeneralLedgerSetup(OldPmtDiscToleranceWarning, OldPaymentDiscountGracePeriod, false, '<5D>'); // Payment Discount Grace Period - 5D.

        // [GIVEN] Two Posted Sales Invoices with "Posting Date" = 01.01, "Due Date" = 11.01, "Amount" = 100 and "Payment Discount" = 2.00
        PostSalesInvoiceWithPmtDisc(CustLedgerEntry[1]);
        PostSalesInvoiceWithPmtDisc(CustLedgerEntry[2]);

        // [GIVEN] Payment with "Posting Date" = 12.01 (within Payment Discount Grace Period) applies to Invoice with "Applies-To ID"
        CreateGenJnlBatchWithType(GenJournalBatch, GenJournalTemplate.Type::"Cash Receipts");
        CreateGenJnlLineWithBatch(
          PmtGenJnlLine, GenJournalBatch, PmtGenJnlLine."Account Type"::Customer, CustLedgerEntry[1]."Customer No.",
          PmtGenJnlLine."Document Type"::Payment, 0, CustLedgerEntry[1]."Pmt. Discount Date" + 1);
        PmtGenJnlLine.Validate("Applies-to ID", UserId);
        PmtGenJnlLine.Modify(true);

        // [WHEN] Open Payment in "Cash Receipt Journal" page
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        CashReceiptJournal.GotoRecord(PmtGenJnlLine);

        // [THEN] "Payment Discount" on "Cash Receipt Journal Factbox" page is 4.00
        CashReceiptJournal.Control1906888607.PMTDiscount.AssertEquals(
          CustLedgerEntry[1]."Remaining Pmt. Disc. Possible" + CustLedgerEntry[2]."Remaining Pmt. Disc. Possible");

        // [THEN] All information related to specific document is blank on "Cash Receipt Journal Factbox" page since there is an application to multiple entries
        CashReceiptJournal.Control1906888607.PostingDate.AssertEquals('');
        CashReceiptJournal.Control1906888607.DueDate.AssertEquals('');
        CashReceiptJournal.Control1906888607.PmtDiscDate.AssertEquals('');
        CashReceiptJournal.Control1906888607.AgeDays.AssertEquals('');
        CashReceiptJournal.Control1906888607.PaymDiscDays.AssertEquals('');
        CashReceiptJournal.Control1906888607.DueDays.AssertEquals('');

        CashReceiptJournal.Close();
    end;

    [Test]
    [HandlerFunctions('GenJnlTemplateModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesPmtDiscOnCashReceiptJournalFactboxWhenUseAppliesToDocNo()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        PmtGenJnlLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        OldPmtDiscToleranceWarning: Boolean;
        OldPaymentDiscountGracePeriod: DateFormula;
    begin
        // [FEATURE] [Sales] [Payment Discount Tolerance]
        // [SCENARIO 211536] Payment Discount is calculated on "Cash Receipt Journal Factbox" page when Payment applies to Invoice by "Applies-To Doc. No"

        Initialize();

        // [GIVEN] Payment Discount Grace Period is 5 days
        UpdateGeneralLedgerSetup(OldPmtDiscToleranceWarning, OldPaymentDiscountGracePeriod, false, '<5D>'); // Payment Discount Grace Period - 5D.

        // [GIVEN] Posted Sales Invoice with "Posting Date" = 01.01, "Due Date" = 11.01, "Amount" = 100 and "Payment Discount" = 2.00
        PostSalesInvoiceWithPmtDisc(CustLedgerEntry);

        // [GIVEN] Payment with "Posting Date" = 12.01 (within Payment Discount Grace Period) applies to Invoice with "Applies-To Doc. No"
        CreateGenJnlBatchWithType(GenJournalBatch, GenJournalTemplate.Type::"Cash Receipts");
        CreateGenJnlLineWithBatch(
          PmtGenJnlLine, GenJournalBatch, PmtGenJnlLine."Account Type"::Customer, CustLedgerEntry."Customer No.",
          PmtGenJnlLine."Document Type"::Payment, 0, CustLedgerEntry."Pmt. Discount Date" + 1);
        PmtGenJnlLine.Validate("Applies-to Doc. Type", PmtGenJnlLine."Applies-to Doc. Type"::Invoice);
        PmtGenJnlLine.Validate("Applies-to Doc. No.", CustLedgerEntry."Document No.");
        PmtGenJnlLine.Modify(true);

        // [WHEN] Open Payment in "Cash Receipt Journal" page
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        CashReceiptJournal.GotoRecord(PmtGenJnlLine);

        // [THEN] "Payment Discount" on "Cash Receipt Journal Factbox" page is 2.00
        CashReceiptJournal.Control1906888607.PMTDiscount.AssertEquals(CustLedgerEntry."Remaining Pmt. Disc. Possible");
    end;

    [Test]
    [HandlerFunctions('GenJnlTemplateModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchPmtDiscOnPmtJournalFactboxWhenUseAppliesToID()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        PmtGenJnlLine: Record "Gen. Journal Line";
        VendorLedgerEntry: array[2] of Record "Vendor Ledger Entry";
        PaymentJournal: TestPage "Payment Journal";
        OldPmtDiscToleranceWarning: Boolean;
        OldPaymentDiscountGracePeriod: DateFormula;
    begin
        // [FEATURE] [Purchase] [Payment Discount Tolerance]
        // [SCENARIO 211536] Payment Discount is calculated on "Payment Journal Factbox" page when Payment applies to multiple invoices by "Applies-To ID"

        Initialize();

        // [GIVEN] Payment Discount Grace Period is 5 days
        UpdateGeneralLedgerSetup(OldPmtDiscToleranceWarning, OldPaymentDiscountGracePeriod, false, '<5D>'); // Payment Discount Grace Period - 5D.

        // [GIVEN] Two Posted Purchase Invoices with "Posting Date" = 01.01, "Due Date" = 11.01, "Amount" = 100 and "Payment Discount" = 2.00
        PostPurchInvoiceWithPmtDisc(VendorLedgerEntry[1]);
        PostPurchInvoiceWithPmtDisc(VendorLedgerEntry[2]);

        // [GIVEN] Payment with "Posting Date" = 12.01 (within Payment Discount Grace Period) applies to Invoice with "Applies-To ID"
        CreateGenJnlBatchWithType(GenJournalBatch, GenJournalTemplate.Type::Payments);
        CreateGenJnlLineWithBatch(
          PmtGenJnlLine, GenJournalBatch, PmtGenJnlLine."Account Type"::Vendor, VendorLedgerEntry[1]."Vendor No.",
          PmtGenJnlLine."Document Type"::Payment, 0, VendorLedgerEntry[1]."Pmt. Discount Date" + 1);
        PmtGenJnlLine.Validate("Applies-to ID", UserId);
        PmtGenJnlLine.Modify(true);

        // [WHEN] Open Payment in "Payment Journal" page
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.GotoRecord(PmtGenJnlLine);

        // [THEN] "Payment Discount" on "Payment Journal Factbox" page is 4.00
        PaymentJournal.Control1906888707.PmtDiscount.AssertEquals(
          -VendorLedgerEntry[1]."Remaining Pmt. Disc. Possible" - VendorLedgerEntry[2]."Remaining Pmt. Disc. Possible");

        // [THEN] All information related to specific document is blank on "Payment Journal Factbox" page since there is an application to multiple entries
        PaymentJournal.Control1906888707.PostingDate.AssertEquals('');
        PaymentJournal.Control1906888707.DueDate.AssertEquals('');
        PaymentJournal.Control1906888707.PmtDiscDate.AssertEquals('');
        PaymentJournal.Control1906888707.AgeDays.AssertEquals('');
        PaymentJournal.Control1906888707.PaymDiscDays.AssertEquals('');
        PaymentJournal.Control1906888707.DueDays.AssertEquals('');

        PaymentJournal.Close();
    end;

    [Test]
    [HandlerFunctions('GenJnlTemplateModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchPmtDiscOnPmtJournalFactboxWhenUseAppliesToDocNo()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        PmtGenJnlLine: Record "Gen. Journal Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        PaymentJournal: TestPage "Payment Journal";
        OldPmtDiscToleranceWarning: Boolean;
        OldPaymentDiscountGracePeriod: DateFormula;
    begin
        // [FEATURE] [Purchase] [Payment Discount Tolerance]
        // [SCENARIO 211536] Payment Discount is calculated on "Paymene Journal Factbox" page when Payment applies to Invoice by "Applies-To Doc. No"

        Initialize();

        // [GIVEN] Payment Discount Grace Period is 5 days
        UpdateGeneralLedgerSetup(OldPmtDiscToleranceWarning, OldPaymentDiscountGracePeriod, false, '<5D>'); // Payment Discount Grace Period - 5D.

        // [GIVEN] Posted Purchase Invoice with "Posting Date" = 01.01, "Due Date" = 11.01, "Amount" = 100 and "Payment Discount" = 2.00
        PostPurchInvoiceWithPmtDisc(VendLedgerEntry);

        // [GIVEN] Payment with "Posting Date" = 12.01 (within Payment Discount Grace Period) applies to Invoice with "Applies-To Doc. No"
        CreateGenJnlBatchWithType(GenJournalBatch, GenJournalTemplate.Type::Payments);
        CreateGenJnlLineWithBatch(
          PmtGenJnlLine, GenJournalBatch, PmtGenJnlLine."Account Type"::Vendor, VendLedgerEntry."Vendor No.",
          PmtGenJnlLine."Document Type"::Payment, 0, VendLedgerEntry."Pmt. Discount Date" + 1);
        PmtGenJnlLine.Validate("Applies-to Doc. Type", PmtGenJnlLine."Applies-to Doc. Type"::Invoice);
        PmtGenJnlLine.Validate("Applies-to Doc. No.", VendLedgerEntry."Document No.");
        PmtGenJnlLine.Modify(true);

        // [WHEN] Open Payment in "Payment Journal" page
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.GotoRecord(PmtGenJnlLine);

        // [THEN] "Payment Discount" on "Payment Journal Factbox" page is 2.00
        PaymentJournal.Control1906888707.PmtDiscount.AssertEquals(-VendLedgerEntry."Remaining Pmt. Disc. Possible");
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Payment Tolerance");

        LibrarySetupStorage.Restore();
        LibraryRandom.SetSeed(1);  // Use Random Number to generate the seed for RANDOM function.
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Payment Tolerance");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Payment Tolerance");
    end;

    local procedure CreateCustomer(var Customer: Record Customer; PaymentTermsCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        UpdateCustomerPaymentTermsCode(Customer, PaymentTermsCode);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; PaymentTermsCode: Code[10])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Modify(true);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGenJnlLineWithBatch(GenJournalLine, GenJournalBatch, AccountType, AccountNo, DocumentType, Amount, PostingDate);
    end;

    local procedure CreateGenJnlLineWithBatch(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; PostingDate: Date)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePaymentTerms(var PaymentTerms: Record "Payment Terms"; DiscountDateCalculationDays: Integer; DiscountPercent: Decimal)
    begin
        // Evaluate to calculate Dateformula.
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(2)) + 'M>');
        Evaluate(PaymentTerms."Discount Date Calculation", '<' + Format(DiscountDateCalculationDays) + 'D>');
        PaymentTerms.Validate("Due Date Calculation", PaymentTerms."Due Date Calculation");
        PaymentTerms.Validate("Discount Date Calculation", PaymentTerms."Discount Date Calculation");
        PaymentTerms.Validate("Discount %", DiscountPercent);
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify(true);
    end;

    local procedure CreateGenJnlBatchWithType(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, Type);
        GenJournalTemplate.Modify(true);
        LibraryVariableStorage.Enqueue(GenJournalTemplate.Name);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure UpdateGeneralLedgerSetup(var OldPmtDiscToleranceWarning: Boolean; var OldPaymentDiscountGracePeriod: DateFormula; NewPmtDiscToleranceWarning: Boolean; NewPaymentDiscountGracePeriod: Variant)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldPaymentDiscountGracePeriod := GeneralLedgerSetup."Payment Discount Grace Period";
        OldPmtDiscToleranceWarning := GeneralLedgerSetup."Pmt. Disc. Tolerance Warning";
        Evaluate(GeneralLedgerSetup."Payment Discount Grace Period", NewPaymentDiscountGracePeriod);
        GeneralLedgerSetup.Validate("Payment Discount Grace Period", GeneralLedgerSetup."Payment Discount Grace Period");
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Warning", NewPmtDiscToleranceWarning);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateCustomerPaymentTermsCode(var Customer: Record Customer; PaymentTermsCode: Code[10])
    begin
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
    end;

    local procedure PostSalesInvoiceWithPmtDisc(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CreateCustomer(Customer, PaymentTerms.Code);
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.",
          GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(100, 2), WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
    end;

    local procedure PostPurchInvoiceWithPmtDisc(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CreateVendor(Vendor, PaymentTerms.Code);
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.",
          GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandDec(100, 2), WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GenJnlTemplateModalPageHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.FILTER.SetFilter(Name, LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateList.OK().Invoke();
    end;
}

