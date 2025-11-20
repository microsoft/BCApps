codeunit 134076 "ERM Suggest Vendor Payment"
{
    Permissions = TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension] [Suggest Vendor Payments] [Purchase]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryJournals: Codeunit "Library - Journals";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        AmountErrorMessageMsg: Label '%1 must be %2 in Gen. Journal Line Template Name=''''%3'''',Journal Batch Name=''''%4'''',Line No.=''''%5''''.';
        SumErrorMessageMsg: Label 'Suggested amount is incorrect.';
        RecordExistsMessageMsg: Label 'Report shouldn''t suggest any payments.';
        ValidateErrorErr: Label '%1 must be %2 in %3 %4 = %5.';
        SuggestVendorAmountErr: Label 'The available amount of suggest vendor payment is always greater then gen. journal line amount.';
        NoOfPaymentErr: Label 'No of payment is incorrect.';
        MessageToRecipientMsg: Label 'Payment of %1 %2 ', Comment = '%1 document type, %2 Document No.';
        AmountMustBeNegativeErr: Label 'Amount must be negative in Gen. Journal Line';
        PaymentsLineErr: Label 'There are payments in %1 %2, %3 %4, %5 %6', Comment = 'There are payments in Journal Template Name PAYMENT, Journal Batch Name GENERAL, Applies-to Doc. No. 101321';
        EarlierPostingDateErr: Label 'You cannot create a payment with an earlier posting date for %1 %2.';
        AppliesToIdErr: Label 'Applies-to ID is not blank.';
        OrFilterStringTxt: Label '%1|%2', Locked = true;
        JournalBatchNameErr: Label 'Journal Batch Name must be %1 in %2';
        AppliesToIDNotSetErr: Label 'Applies-to ID is not set on Vendor Ledger Entry';
        AppliesToIDNotRemovedErr: Label 'Applies-to ID is not removed on Vendor Ledger Entry';
        SuggestToVendorRefundErr: Label 'Document No. must be blank.';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorPaymentWithManualCheck()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create and Post General Journal Lines and Suggest Vendor Payments with Manual Check.
        Initialize();
        VendorPayment(GenJournalLine."Bank Payment Type"::"Manual Check");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorPaymentWithComputerCheck()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create and Post General Journal Lines and Suggest Vendor Payments with Computer Check.
        Initialize();
        VendorPayment(GenJournalLine."Bank Payment Type"::"Computer Check");
    end;

    local procedure VendorPayment(BankPaymentType: Enum "Bank Payment Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Code[20];
    begin
        // Create Setup, Post General Journal Lines, Suggest Vendor Payment and Verify Posted Entries.
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        BankAccountNo := SetupAndCreateGenJournalLines(GenJournalLine, GenJournalBatch);

        // Exercise: Post General Journal Lines and Run Report Suggest Vendor Payment.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        SuggestVendorPayment(
          GenJournalBatch, GenJournalLine."Account No.", WorkDate(), false, GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo,
          BankPaymentType, true);

        // Verify: Verify General Journal Lines Amount is same after Posting General journal Lines.
        VerifyGenJournalEntriesAmount(GenJournalLine."Account No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorPaymentWithAllVendors()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
        VendorNo2: Code[20];
        NoOfLines: Integer;
    begin
        // Create Setup, Post General Journal Lines, Suggest Vendor Payment for Multi Vendor with Computer Check and Verify Posted Entries.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        BankAccountNo := SetupAndCreateGenJournalLines(GenJournalLine, GenJournalBatch);
        VendorNo := GenJournalLine."Account No.";
        NoOfLines := 2 * LibraryRandom.RandInt(5);  // Use Random Number to generate more than two lines.
        VendorNo2 := CreateVendor(GenJournalLine."Currency Code", Vendor."Application Method"::"Apply to Oldest");
        CreateMultipleGenJournalLine(
          GenJournalLine, GenJournalBatch, NoOfLines, WorkDate(), VendorNo2,
          GenJournalLine."Document Type"::Invoice, -1);

        // Exercise: Post General Journal Lines and Run Report Suggest Vendor Payment.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        SuggestVendorPayment(
          GenJournalBatch, VendorNo, WorkDate(), false, GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo,
          GenJournalLine."Bank Payment Type"::"Computer Check", true);
        SuggestVendorPayment(
          GenJournalBatch, VendorNo2, WorkDate(), false, GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo,
          GenJournalLine."Bank Payment Type"::"Computer Check", true);

        // Verify: Verify General Journal Lines Amount is same after Posting General journal Lines.
        VerifyGenJournalEntriesAmount(VendorNo);
        VerifyGenJournalEntriesAmount(VendorNo2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPaymentWithDiscTrue()
    begin
        // Should suggest payment for Invoices, for which discount can be applied.
        VendorPaymentWithDiscounts(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPaymentWithDiscFalse()
    begin
        // Should not suggest payment for Invoices, for which discount can be applied.
        VendorPaymentWithDiscounts(false);
    end;

    local procedure VendorPaymentWithDiscounts(FindDiscounts: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        DiscountedInvoices: Decimal;
        Result: Boolean;
    begin
        // Suggest Vendor payments with Discounts.

        // Setup: Create Payment Terms and Vendor, Create Invoices and post them
        Initialize();
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        CreateVendorWithPaymentTerms(Vendor, PaymentTerms.Code);
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        CreateMultipleGenJournalLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandInt(2), CalcDate('<-1D>', WorkDate()),
          Vendor."No.", GenJournalLine."Document Type"::Invoice, -1);
        DiscountedInvoices := CreateMultipleGenJournalLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandInt(2), WorkDate(),
            Vendor."No.", GenJournalLine."Document Type"::Invoice, -1);
        DiscountedInvoices := DiscountedInvoices * (1 - PaymentTerms."Discount %" / 100);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Run Suggest Vendor Payments report
        // Only Invoices for which discount is applied should be suggested for payment,
        // because of payment due date defined in Payment Terms.
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        SuggestVendorPayment(
          GenJournalBatch, Vendor."No.", CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), FindDiscounts,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), GenJournalLine."Bank Payment Type", true);

        // Verify Description is set to the vendor name
        GenJournalLine.TestField(Description, Vendor.Name);

        // Verify: Suggested Amount
        GenJournalLine.SetRange("Account No.", Vendor."No.");
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        Result := GenJournalLine.FindLast();
        if FindDiscounts then
            Assert.AreEqual(-DiscountedInvoices, GenJournalLine.Amount, SumErrorMessageMsg)
        else
            Assert.IsFalse(Result, RecordExistsMessageMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentWithLineRemovedAndReadded()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        DiscountedInvoices: Decimal;
        RecordCountBefore: Integer;
        RecordCountAfterDelete: Integer;
        RecordCountAfterResuggest: Integer;
        PreCount: Integer;
        PostCount: Integer;
    begin
        // Suggest Vendor payments with Discounts.

        // Setup: Create Payment Terms and Vendor, Create Invoices and post them
        Initialize();
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        CreateVendorWithPaymentTerms(Vendor, PaymentTerms.Code);
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        CreateMultipleGenJournalLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandInt(2), CalcDate('<-1D>', WorkDate()),
          Vendor."No.", GenJournalLine."Document Type"::Invoice, -1);
        DiscountedInvoices := CreateMultipleGenJournalLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandInt(2), WorkDate(),
            Vendor."No.", GenJournalLine."Document Type"::Invoice, -1);
        DiscountedInvoices := DiscountedInvoices * (1 - PaymentTerms."Discount %" / 100);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Run Suggest Vendor Payments report
        // Only Invoices for which discount is applied should be suggested for payment,
        // because of payment due date defined in Payment Terms.
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        PreCount := GenJournalLine.Count();
        SuggestVendorPayment(
          GenJournalBatch, '', WorkDate(), false,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), GenJournalLine."Bank Payment Type", false);
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        PostCount := GenJournalLine.Count();

        Assert.IsTrue(PreCount < PostCount, 'Suggest Vendor Payments should have added records.');

        RecordCountBefore := GenJournalLine.Count();
        GenJournalLine.FindLast();
        GenJournalLine.Delete();
        Commit();

        // Verify: Record was removed
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        RecordCountAfterDelete := GenJournalLine.Count();
        Assert.AreNotEqual(RecordCountBefore, RecordCountAfterDelete, 'General Journal record should have been removed.');

        SuggestVendorPayment(
          GenJournalBatch, '', WorkDate(), false,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), GenJournalLine."Bank Payment Type", false);
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        RecordCountAfterResuggest := GenJournalLine.Count();

        // Verify: Record was recreated, i.e.  Before and After record counts are equal
        Assert.AreEqual(RecordCountBefore, RecordCountAfterResuggest, 'Suggest vendor payments did not add the line.');
        Assert.IsTrue(RecordCountAfterDelete < RecordCountAfterResuggest, 'Suggest Vendor Payments should have added payment.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentToInvoiceWithApplyEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Apply Payment against the Invoices and show Only Applied Entries.
        Initialize();
        SetApplyIdToDocument(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefundCreditMemoWithApplyEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Apply Refund against the Credit Memo and Show Only Applied Entries.
        Initialize();
        SetApplyIdToDocument(GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, 1);
    end;

    local procedure SetApplyIdToDocument(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; AmountSign: Integer)
    var
        Vendor: Record Vendor;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        NumberOfLines: Integer;
    begin
        // Setup: Create Vendor and General Journal Lines.
        NumberOfLines := 1 + LibraryRandom.RandInt(5);  // Use Random Number to generate more than one line.
        VendorNo := CreateVendor('', Vendor."Application Method"::Manual);
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        CreateMultipleGenJournalLine(GenJournalLine, GenJournalBatch, NumberOfLines, WorkDate(), VendorNo, DocumentType, AmountSign);
        CreateMultipleGenJournalLine(GenJournalLine, GenJournalBatch, 1, WorkDate(), VendorNo, DocumentType2, -AmountSign);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Set Applies to ID to all invoices.
        ApplyPaymentToVendor(GenJournalLine."Account No.", NumberOfLines, DocumentType, DocumentType2);

        // Verify: Verify Vendor Ledger Entry.
        VerifyVendorLedgerEntry(VendorNo, NumberOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Check Error while posting General Journal Line for Vendor and when External Document No. is not given.

        // Setup: Create General Journal Lines with random values.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, WorkDate(), LibraryPurchase.CreateVendorNo(), GenJournalLine."Document Type"::Invoice,
          -LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("External Document No.", '');
        GenJournalLine.Modify(true);

        // Exercise.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify error on General Journal posting.
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("External Document No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentBySuggestVendorPayment()
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceAmount: Decimal;
        InvoiceNo: Code[20];
    begin
        // Test Vendor Ledger Entry after Posting Payment Journal with running Suggest Vendor Payment.

        // 1. Setup: Create Payment Terms with Discount Date and Calc. Pmt. Disc. on Cr. Memos as True, Vendor with Payment Terms Code,
        // Create and Post General Journal Lines with Document Type as Invoice, Payment and Credit Memo.
        Initialize();
        CreatePaymentTermsWithDiscount(PaymentTerms);
        CreateVendorWithPaymentTerms(Vendor, PaymentTerms.Code);
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        InvoiceAmount := LibraryRandom.RandDec(1000, 2);  // Use Random for Invoice Amount.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, WorkDate(), Vendor."No.", GenJournalLine."Document Type"::Invoice, -InvoiceAmount);
        InvoiceNo := GenJournalLine."Document No.";
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, WorkDate(), Vendor."No.", GenJournalLine."Document Type"::Payment,
          LibraryRandom.RandDecInDecimalRange(100, 200, 2));
        ApplyGenJnlLineEntryToInvoice(GenJournalLine, InvoiceNo);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, WorkDate(), Vendor."No.", GenJournalLine."Document Type"::"Credit Memo",
          (InvoiceAmount - GenJournalLine.Amount) / 2); // 2 is required for Partial Amount.
        ApplyGenJnlLineEntryToInvoice(GenJournalLine, InvoiceNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Run Suggest Vendor Payment and Post the Payment Journal.
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        SuggestVendorPayment(
          GenJournalBatch, Vendor."No.", CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), true,
          GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No.", GenJournalLine."Bank Payment Type"::" ", true);
        FindAndPostPaymentJournalLine(GenJournalBatch);

        // 3. Verify: Verify Remaining Amount on Vendor Ledger Entry.
        VerifyRemainingOnVendorLedger(Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentForInvoice()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Test Vendor Ledger Entry after Posting Payment Journal with running Suggest Vendor Payment against Invoice.

        // 1. Setup: Create and post General Journal with Document Type as Invoice.
        Initialize();
        DocumentNo := CreateAndPostGeneralJournal(GenJournalLine, GenJournalLine."Document Type"::Invoice);

        // 2. Exercise: Create General Journal Batch for Payment and Run Suggest Vendor Payment with Random Last Payment Date.
        // Post the Payment Journal.
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        SuggestVendorPayment(
          GenJournalBatch, GenJournalLine."Account No.", AddRandomDaysToWorkDate(), true, GenJournalLine."Account Type"::"G/L Account",
          GenJournalLine."Bal. Account No.", GenJournalLine."Bank Payment Type"::" ", true);
        DocumentNo2 := FindAndPostPaymentJournalLine(GenJournalBatch);

        // 3. Verify: Verify values on Vendor Ledger Entry after post the Payment Journal.
        VerifyValuesOnVendLedgerEntry(
          GenJournalLine."Document No.", GenJournalLine."Document Type"::Invoice, GenJournalLine."Account No.", GenJournalLine.Amount,
          GenJournalLine.Amount, true, GenJournalLine."On Hold");
        VerifyValuesOnVendLedgerEntry(
          DocumentNo, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account No.", GenJournalLine.Amount / 2, 0, false, '');
        VerifyValuesOnVendLedgerEntry(
          DocumentNo2, GenJournalLine."Document Type"::Payment, GenJournalLine."Account No.", -GenJournalLine.Amount / 2, 0, false, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentForRefund()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Test Vendor Ledger Entry after Posting Payment Journal with running Suggest Vendor Payment against Refund.

        // 1. Setup: Create and post General Journal with Document Type as Refund.
        Initialize();
        DocumentNo := CreateAndPostGeneralJournal(GenJournalLine, GenJournalLine."Document Type"::Refund);

        // 2. Exercise: Create General Journal Batch for Payment and Run Suggest Vendor Payment with Random Last Payment Date.
        // Post the Payment Journal.
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        SuggestVendorPayment(
          GenJournalBatch, GenJournalLine."Account No.", AddRandomDaysToWorkDate(), true, GenJournalLine."Account Type"::"G/L Account",
          GenJournalLine."Bal. Account No.", GenJournalLine."Bank Payment Type"::" ", true);

        // 3. Verify: Verify values on Vendor Ledger Entry after post the Payment Journal.
        DocumentNo2 := FindAndPostPaymentJournalLineRefund(GenJournalBatch);

        // 4. Verify: Verify values of Document No. in Payment Journal.
        Assert.AreEqual(DocumentNo2, '', SuggestToVendorRefundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPaymentForBlockedVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that no General Journal Line generated After doing Suggest Vendor Payment for a Vendor having Payment Blocked.

        // Setup: Create and Post Purchase Invoice for a Vendor who has Blocked Payment. Take Random Quantity.
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendorWithPaymentBlocked());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalBatch."Template Type"::Payments);

        // Exercise: Try to Suggest Vendor Payment for the Vendor for which Payment is Blocked.
        SuggestVendorPayment(
          GenJournalBatch, PurchaseHeader."Buy-from Vendor No.", WorkDate(), false, GenJournalLine."Bal. Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(), GenJournalLine."Bank Payment Type"::" ", true);

        // Verify: Verify that no General Journal Line created for the Vendor having Payment Blocked.
        VerifyJournalLinesNotSuggested(GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestPaymentForVendorWithDebitBalanceAndPriorityTrue()
    begin
        Initialize();
        // [GIVEN] Vendor with Negative Balance
        // [GIVEN] Use Vendor Priority is TRUE
        // [WHEN] Suggest Vendor Payment
        // [THEN] Payment is not suggested
        SuggestPaymentForVendorWithUseVendorPriority(true);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestPaymentForVendorWithDebitBalanceAndPriorityFalse()
    begin
        Initialize();
        // [GIVEN] Vendor with Negative Balance
        // [GIVEN] Use Vendor Priority is FALSE
        // [WHEN] Suggest Vendor Payment
        // [THEN] Payment is not suggested
        SuggestPaymentForVendorWithUseVendorPriority(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntriesWithDimensionValues()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        ShortcutDimension1Code: Code[20];
        ShortcutDimension2Code: Code[20];
    begin
        // Setup: Create & Post General Journal Lines.
        Initialize();
        VendorNo := CreateVendor(Vendor."Currency Code", Vendor."Application Method"::"Apply to Oldest");
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        CreateGeneralJournalWithAccountTypeGLAccount(GenJournalLine, GLAccountNo);
        UpdateGenJournalLine(GenJournalLine, VendorNo);
        ShortcutDimension1Code := GenJournalLine."Shortcut Dimension 1 Code";
        ShortcutDimension2Code := GenJournalLine."Shortcut Dimension 2 Code";
        CopyTempGenJournalLine(GenJournalLine, TempGenJournalLine); // Insert Temp General Journal Line for verification.

        // Exercise: Post General Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verification of GL Entry with Dimension.
        VerifyValuesOnGLEntry(TempGenJournalLine, '', '');
        VerifyValuesOnGLEntry(TempGenJournalLine, ShortcutDimension1Code, ShortcutDimension2Code);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsWithDimensionAndBalAccRequestPageHandler,SelectDimensionHandlerOnSuggesvendorPayment')]
    [Scope('OnPrem')]
    procedure DimensionAfterSuggestVendorPaymentOnGeneralJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // 1. Setup: Create and Post General Journal Lines.
        VendorNo := LibraryPurchase.CreateVendorNo();
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(GLAccountNo);
        CreateGeneralJournalWithAccountTypeGLAccount(GenJournalLine, GLAccountNo);
        UpdateGenJournalLine(GenJournalLine, VendorNo);

        // Post General Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Suggest Vendor Payment using PageHandler SelectDimensionHandlerOnSuggesvendorPayment.
        SuggestVendorPaymentUsingPage(GenJournalLine);

        // 3. Verify: Verify that General Journal line exist with blank Dimensions.
        VerifyDimensionOnGeneralJournalLine(GenJournalLine, VendorNo, GLAccountNo);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsWithoutBalAccountRequestPageHandler,ClearDimensionHandlerOnSuggesvendorPayment')]
    [Scope('OnPrem')]
    procedure DimensionOnPaymnetJournalFromGeneralJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        ShDim1Code: Code[20];
        ShDim2Code: Code[20];
    begin
        // Test the dimension valued posted with invoice are retrived when performing suggest vendor payment.

        // Setup:
        Initialize();

        // Exercise: Create GenJournalLine with Dimesnion and Post it. Run Suggest Vendor Payment.
        VendorNo := CreateGenJnlLineWithVendorBalAcc(GenJournalLine);
        LibraryVariableStorage.Enqueue(VendorNo);
        UpdateDimensionOnGeneralJournalLine(GenJournalLine);
        ShDim1Code := GenJournalLine."Shortcut Dimension 1 Code";
        ShDim2Code := GenJournalLine."Shortcut Dimension 2 Code";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        SetupGenJnlLine(GenJournalLine);
        SuggestVendorPaymentUsingPage(GenJournalLine);

        // Verify:
        VerifyDimensionOnGeneralJournalLineFromInvoice(GenJournalLine, ShDim1Code, ShDim2Code);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsWithAvailableAmtRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckGenJnlLineWhenSumOfInvoicesGreaterThanLimit()
    var
        InvoiceAmount: Decimal;
    begin
        // Verify that after two invoices each smaller than the limit and sum of them is exceeds the limit and after running suggest vendor payment report then one payment exist.
        InvoiceAmount := LibraryRandom.RandIntInRange(15, 20);
        CheckGenJnlLineAfterSuggestVendorPayment(LibraryRandom.RandIntInRange(21, 25), 1, InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsWithAvailableAmtRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckGenJnlLineWhenLimitMoreThanSumOfInvoices()
    var
        InvoiceAmount: Decimal;
    begin
        // Verify that after two invoices each smaller than the limit and Sum of them is smaller then limit and after running suggest vendor payment report then two payment exist.
        InvoiceAmount := LibraryRandom.RandIntInRange(15, 20);
        CheckGenJnlLineAfterSuggestVendorPayment(LibraryRandom.RandIntInRange(50, 100), 2, InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsWithAvailableAmtRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckGenJnlLineWhenOneInvoiceBiggerThanLimit()
    var
        InvoiceAmount: Decimal;
    begin
        // Verify that after two invoices one is smaller, second is bigger than the limit and after running suggest vendor payment report then one payment exist.
        InvoiceAmount := LibraryRandom.RandIntInRange(200, 300);
        CheckGenJnlLineAfterSuggestVendorPayment(LibraryRandom.RandIntInRange(100, 200), 1, InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsWithAvailableAmtRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckGenJnlLineWhenBothInviceMoreThanLimit()
    var
        InvoiceAmount: Decimal;
    begin
        // Verify that after two invoices both are bigger than the limit and after running suggest vendor payment report then no payment exist.
        InvoiceAmount := LibraryRandom.RandIntInRange(400, 500);
        CheckGenJnlLineAfterSuggestVendorPayment(LibraryRandom.RandIntInRange(1, 10), 0, InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsWithAvailableAmtRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckGenJnlLineWithTwoInvoicesWithoutLimit()
    var
        InvoiceAmount: Decimal;
    begin
        // Verify that after two invoices are posted and after running suggest vendor payment report without limit and then 2 payment exist.
        InvoiceAmount := LibraryRandom.RandIntInRange(400, 500);
        CheckGenJnlLineAfterSuggestVendorPayment(0, 2, InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsWithDimensionRequestPageHandler,SelectDimensionHandlerOnSuggesvendorPayment')]
    [Scope('OnPrem')]
    procedure DimensionOnPaymentJournalFromGenJournalWithSums()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        ShDim1Code: Code[20];
        ShDim2Code: Code[20];
    begin
        // Test the dimension valued posted with invoice are retrived when performing suggest vendor payment with 'Summarize per Vendor' checked.

        // Setup:
        Initialize();

        // Exercise: Create GenJournalLine with Dimesnion and Post it. Create Default dimension for Vendor, Run Suggest Vendor Payment.
        VendorNo := CreateGenJnlLineWithVendorBalAcc(GenJournalLine);
        LibraryVariableStorage.Enqueue(VendorNo);
        UpdateDimensionOnGeneralJournalLine(GenJournalLine);
        ShDim1Code := GenJournalLine."Shortcut Dimension 1 Code";
        ShDim2Code := GenJournalLine."Shortcut Dimension 2 Code";
        UpdateDiffDimensionOnVendor(VendorNo, ShDim1Code, ShDim2Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        SetupGenJnlLine(GenJournalLine);
        SuggestVendorPaymentUsingPage(GenJournalLine);

        // Verify:
        VerifyDimensionOnGeneralJournalLineFromInvoice(GenJournalLine, ShDim1Code, ShDim2Code);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsWithDimensionRequestPageHandler,SelectNoDimensionHandlerOnSuggesvendorPayment')]
    [Scope('OnPrem')]
    procedure DimensionOnPaymnetJournalSummarizeVendorNoSelection()
    begin
        // Test the dimension valued posted with invoice are retrived when performing suggest vendor payment with 'Summarize per Vendor' checked.
        VerifyDimOnGeneralJournalLineSummarizePerVend(false);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsWithDimensionRequestPageHandler,SelectFirstDimensionHandlerOnSuggesvendorPayment')]
    [Scope('OnPrem')]
    procedure DimensionOnPaymnetJournalSummarizeVendorOneSelected()
    begin
        // Test the dimension valued posted with invoice are retrived when performing suggest vendor payment with 'Summarize per Vendor' checked.
        VerifyDimOnGeneralJournalLineSummarizePerVend(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultVendDimUsedWhenNoSelectedDimAndSummarizePerVendor()
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendNo: Code[20];
        DimSetID: Integer;
    begin
        // [FEATURE] [Default Dimension]
        // [SCENARIO 371674] Default Dimensions should be used for Payment Journal when Suggest Vendor Payments with no selected dimensions and "Summarize Per Vendor" option

        Initialize();
        // [GIVEN] Vendor with Default Dimension Set ID = "X" combined from "Global Dimension 1 Code" = "A" and "Global Dimension 2 Code" = "B"
        CreateVendWithDimensions(VendNo, DimSetID);
        // [GIVEN] Posted Invoice
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJnlLine, GenJnlLine."Document Type"::Invoice, GenJnlLine."Account Type"::Vendor, VendNo,
          -LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        CreateGeneralJournalBatch(GenJnlBatch, GenJnlTemplate.Type::Payments);

        // [WHEN] Run Suggest Vendor Payments with "Summarize Per Vendor" option
        SuggestVendorPayment(
          GenJnlBatch, GenJnlLine."Account No.", WorkDate(), false,
          GenJnlLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), GenJnlLine."Bank Payment Type"::"Computer Check", true);

        // [THEN] General Journal Line is created with "Dimension Set ID" = "X", "Global Dimension 1 Code" = "A", "Global Dimension 2 Code" = "B"
        VerifyGenJnlLineDimSetID(GenJnlBatch, VendNo, DimSetID);
    end;

    local procedure SuggestPaymentForVendorWithUseVendorPriority(VendorPriority: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // 1. Setup: Creat and Post Invoice and Credit Memo Entries for Vendor.
        VendorNo := LibraryPurchase.CreateVendorNo();
        GLAccountNo := LibraryERM.CreateGLAccountNo();

        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(GLAccountNo);
        LibraryVariableStorage.Enqueue(VendorPriority);

        CreateInvoiceAndCreditMemoEntryForVendor(GenJournalLine, VendorNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Suggest Vendor Payment using Page. Using Page is because InitializeRequest of Report does not have the option to set value in "Use Vendor Priority" Field.
        SuggestVendorPaymentUsingPage(GenJournalLine);

        // 3. Verify: Verify that Payment is not suggested for the Vendor with Debit Balance.
        VerifyJournalLinesNotSuggested(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsWithAvailableAmtRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestedTotalAmountLCYWithSeveralFCYAndNegativeLines()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: array[3] of Code[20];
        CurrencyCode: array[3] of Code[10];
        i: Integer;
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 372005] Total Amount (LCY) of suggested payments is less or equal than Available Amount (LCY) when using Vendor Priority in case of several FCY Vendors and negative lines
        Initialize();

        for i := 1 to 3 do begin
            CurrencyCode[i] := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
            VendorNo[i] := CreateVendorWithPriority();
        end;

        // [GIVEN] Create and post several General Journal Lines:
        // [GIVEN] Vendor1 Invoice Currency1 Amount(LCY)=575
        // [GIVEN] Vendor2 Invoice Currency1 Amount(LCY)=1000
        // [GIVEN] Vendor2 Credit Memo Currency2 Amount(LCY)=-750
        // [GIVEN] Vendor3 Invoice Currency2 Amount(LCY)=400
        // [GIVEN] Vendor3 Invoice Currency2 Amount(LCY)=250
        CreatePostGenJnlLineWithCurrency(VendorNo[1], GenJournalLine."Document Type"::Invoice, CurrencyCode[1], 575);
        CreatePostGenJnlLineWithCurrency(VendorNo[2], GenJournalLine."Document Type"::Invoice, CurrencyCode[1], 1000);
        CreatePostGenJnlLineWithCurrency(VendorNo[2], GenJournalLine."Document Type"::"Credit Memo", CurrencyCode[2], -750);
        CreatePostGenJnlLineWithCurrency(VendorNo[3], GenJournalLine."Document Type"::Invoice, CurrencyCode[2], 400);
        CreatePostGenJnlLineWithCurrency(VendorNo[3], GenJournalLine."Document Type"::Invoice, CurrencyCode[2], 250);

        // [WHEN] Run Suggest Vendor Payments with "Use Vendor Priority"=TRUE, "Available Amount (LCY)"=600
        LibraryVariableStorage.Enqueue(StrSubstNo('%1|%2|%3', VendorNo[1], VendorNo[2], VendorNo[3]));
        LibraryVariableStorage.Enqueue(600);
        SuggestVendorPaymentUsingPage(GenJournalLine);

        // [THEN] Number of suggested payments = 1 with total Amount(LCY) = 575 < 600
        VerifyAmountDoesNotExceedLimit(GenJournalLine, 575, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BatchPostPaymentToCreditMemoCustomerNegativeAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        CrMemoNo: Code[20];
        CrMemoAmount: Decimal;
    begin
        // [FEATURE] [Payment Applied to Credit Memo] [Sales] [Payment] [Credit Memo] [Application]
        // [SCENARIO 378643] Post Customer Payment with negative amount applied to Credit Memo from Payment Journal
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CrMemoAmount := LibraryRandom.RandIntInRange(50, 100);

        // [GIVEN] Posted sales credit memo with Amount = 100
        PostCreditMemoCustomer(GenJournalLine, Customer."No.", -CrMemoAmount);
        CrMemoNo := GenJournalLine."Document No.";

        // [GIVEN] Payment journal with the line applied to credit memo and Amount = -100
        CreatePaymentLineAppliedToCrMemoCustomer(GenJournalLine, Customer."No.", -CrMemoAmount, CrMemoNo);

        // [WHEN] Post payment with Amount = -100 and applied to credit memo
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Error 'Positive must be equal to ''Yes''  in Cust. Ledger Entry' thrown
        Assert.ExpectedTestFieldError(CustLedgEntry.FieldCaption(Positive), Format(true));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BatchPostPaymentToCreditMemoCustomerPositiveAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CrMemoNo: Code[20];
        CrMemoAmount: Decimal;
    begin
        // [FEATURE] [Payment Applied to Credit Memo] [Sales] [Payment] [Credit Memo] [Application]
        // [SCENARIO 378643] Post Customer Payment with positive amount applied to Credit Memo from Payment Journal
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CrMemoAmount := LibraryRandom.RandIntInRange(50, 100);

        // [GIVEN] Payment journal
        // [GIVEN] Posted sales credit memo with Amount = 100
        PostCreditMemoCustomer(GenJournalLine, Customer."No.", -CrMemoAmount);
        CrMemoNo := GenJournalLine."Document No.";

        // [GIVEN] Payment journal with the line applied to credit memo and Amount = 100
        CreatePaymentLineAppliedToCrMemoCustomer(GenJournalLine, Customer."No.", CrMemoAmount, CrMemoNo);

        // [WHEN] Post payment
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Error 'Amount must be negative in Gen. Journal Line' thrown
        Assert.ExpectedError('Amount must be negative in Gen. Journal Line');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BatchPostPaymentToCreditMemoVendorNegativeAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        GLEntry: Record "G/L Entry";
        CrMemoNo: Code[20];
        CrMemoAmount: Decimal;
    begin
        // [FEATURE] [Payment Applied to Credit Memo] [Payment] [Credit Memo] [Application]
        // [SCENARIO 378643] Post Vendor Payment with negative amount applied to Credit Memo from Payment Journal
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CrMemoAmount := LibraryRandom.RandIntInRange(50, 100);

        // [GIVEN] Payment journal
        // [GIVEN] Posted purchase credit memo with Amount = 100
        PostCreditMemoVendor(GenJournalLine, Vendor."No.", CrMemoAmount);
        CrMemoNo := GenJournalLine."Document No.";

        // [GIVEN] Payment journal with the line applied to credit memo and Amount = -100
        CreatePaymentLineAppliedToCrMemoVendor(GenJournalLine, Vendor."No.", -CrMemoAmount, CrMemoNo);

        // [WHEN] Post payment "P"
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] GLEntry for "P" has Amount = 100;
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, CrMemoAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BatchPostPaymentToCreditMemoVendorPositiveAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        CrMemoNo: Code[20];
        CrMemoAmount: Decimal;
    begin
        // [FEATURE] [Payment Applied to Credit Memo] [Payment] [Credit Memo] [Application]
        // [SCENARIO 378643] Post Vendor Payment with positive amount applied to Credit Memo from Payment Journal
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CrMemoAmount := LibraryRandom.RandIntInRange(50, 100);

        // [GIVEN] Payment journal
        // [GIVEN] Posted purchase credit memo with Amount = 100
        PostCreditMemoVendor(GenJournalLine, Vendor."No.", CrMemoAmount);
        CrMemoNo := GenJournalLine."Document No.";

        // [GIVEN] Payment journal with the line applied to credit memo and Amount = 100
        CreatePaymentLineAppliedToCrMemoVendor(GenJournalLine, Vendor."No.", CrMemoAmount, CrMemoNo);

        // [WHEN] Post payment
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Error 'Amount must be negative in Gen. Journal Line' thrown
        Assert.ExpectedError(AmountMustBeNegativeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostVendorPaymentsWithoutBalAccountAppliedToInvoiceAndCrMemo()
    var
        Vendor: Record Vendor;
        GenJournalLineInv: Record "Gen. Journal Line";
        GenJournalLineCrM: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        PmtAmount: array[2] of Decimal;
    begin
        // [FEATURE] [Payment Applied to Credit Memo] [Payment] [Credit Memo] [Application]
        // [SCENARIO 230943,290200] It is allowed to post and apply payment of two balanced lines to Purchase Credit Memo
        Initialize();

        // [GIVEN] Vendor with posted purchase invoice and credit memo
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGeneralJournalLine(
          GenJournalLineInv, GenJournalLine."Account Type"::Vendor, Vendor."No.", GenJournalLine."Document Type"::Invoice, -1);
        CreateAndPostGeneralJournalLine(
          GenJournalLineCrM, GenJournalLine."Account Type"::Vendor, Vendor."No.", GenJournalLine."Document Type"::"Credit Memo", 1);

        // [GIVEN] Balanced payment of 2 lines applied to the invoice and credit memo
        PmtAmount[1] := LibraryRandom.RandDec(100, 2);
        PmtAmount[2] := -PmtAmount[1];
        CreateBalancedPaymentWithApplication(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.",
          GenJournalLineInv."Document No.", GenJournalLineCrM."Document No.", PmtAmount);

        // [WHEN] Post the payment
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Two payment vendor ledger entries are posted, fully applied.
        VerifyVenderLedgerEntryFullyClosed(GenJournalLineInv."Document No.", Vendor."No.", Enum::"Gen. Journal Document Type"::Invoice);
        VerifyVenderLedgerEntryFullyClosed(GenJournalLineCrM."Document No.", Vendor."No.", Enum::"Gen. Journal Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostVendorPaymentAppliedToInvoiceAndCrMemoAndThirdBankAccLine()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        Vendor: Record Vendor;
        GenJournalLineInv: Record "Gen. Journal Line";
        GenJournalLineCrM: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        PmtAmount: array[2] of Decimal;
    begin
        // [FEATURE] [Payment Applied to Credit Memo] [Payment] [Credit Memo] [Application]
        // [SCENARIO 290200] It is allowed to post payment of two lines applied to Invoice and Credit Memo balanced by the third line.
        Initialize();

        // [GIVEN] Vendor with posted purchase invoice and credit memo
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGeneralJournalLine(
          GenJournalLineInv, GenJournalLine."Account Type"::Vendor, Vendor."No.", GenJournalLine."Document Type"::Invoice, -20);
        CreateAndPostGeneralJournalLine(
          GenJournalLineCrM, GenJournalLine."Account Type"::Vendor, Vendor."No.", GenJournalLine."Document Type"::"Credit Memo", 1);

        // [GIVEN] Payment of 2 lines applied to the invoice and credit memo balanced with bank account line
        PmtAmount[1] := -GenJournalLineInv.Amount;
        PmtAmount[2] := -GenJournalLineCrM.Amount;
        CreateBalancedPaymentWithApplication(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.",
          GenJournalLineInv."Document No.", GenJournalLineCrM."Document No.", PmtAmount);

        // [WHEN] Post the payment
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Two payment vendor ledger entries are posted, fully applied.
        GenJournalLine."Account No." := Vendor."No.";
        VerifyTwoPaymentEntriesFullyClosed(GenJournalLine);
        // [THEN] One Bank Account Ledger Entry is posted
        BankAccountLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        Assert.RecordCount(BankAccountLedgerEntry, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostCustomerPaymentsWithoutBalAccountAppliedToInvoiceAndCrMemo()
    var
        Customer: Record Customer;
        GenJournalLineInv: Record "Gen. Journal Line";
        GenJournalLineCrM: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        PmtAmount: array[2] of Decimal;
    begin
        // [FEATURE] [Payment Applied to Credit Memo] [Payment] [Credit Memo] [Application]
        // [SCENARIO 230943] It is not allowed to post and apply payment of two balanced lines to Sales Credit Memo
        Initialize();

        // [GIVEN] Customer with posted sales invoice and credit memo
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostGeneralJournalLine(
          GenJournalLineInv, GenJournalLine."Account Type"::Customer, Customer."No.", GenJournalLine."Document Type"::Invoice, 1);
        CreateAndPostGeneralJournalLine(
          GenJournalLineCrM, GenJournalLine."Account Type"::Customer, Customer."No.", GenJournalLine."Document Type"::"Credit Memo", -1);

        // [GIVEN] Balanced payment of 2 lines applied to the invoice and credit memo
        PmtAmount[1] := -LibraryRandom.RandDec(100, 2);
        PmtAmount[2] := -PmtAmount[1];
        CreateBalancedPaymentWithApplication(
          GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.",
          GenJournalLineInv."Document No.", GenJournalLineCrM."Document No.", PmtAmount);

        // [WHEN] Post the payment
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Error 'Amount must be negative in Gen. Journal Line' thrown
        Assert.ExpectedError(AmountMustBeNegativeErr);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsCheckUpdateValuesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentWithSavedValuesWhenNoBalAccountInBatch()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ActionType: Option Update,Verify;
        PostingDate: Date;
        LastPaymentDate: Date;
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Suggest Vendor Payments] [UI]
        // [SCENARIO 224171] Run Suggest Vendor Payments with saved values on Batch where Bal. Account No. is not defined
        Initialize();

        PostingDate := LibraryRandom.RandDate(5);
        LastPaymentDate := LibraryRandom.RandDate(5);
        GLAccountNo := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Gen. Journal Batch without Bal. Account No.
        SetupGenJnlLine(GenJournalLine);

        // [GIVEN] Run Suggest Vendor Payment with Posting Date = 10.01.18, Last Payment Date = 20.01.18
        // [GIVEN] Bal. Account Type = G/L Account, Bal. Account No. = "A"
        SuggestVendorPaymentsEnqueueValues(
          ActionType::Update, PostingDate, LastPaymentDate, GenJournalLine."Account Type"::"G/L Account", GLAccountNo);
        SuggestVendorPaymentForGenJournal(GenJournalLine);

        // [WHEN] Run Suggest Vendor Payments second time
        SuggestVendorPaymentsEnqueueValues(
          ActionType::Verify, PostingDate, LastPaymentDate, GenJournalLine."Account Type"::"G/L Account", GLAccountNo);
        SuggestVendorPaymentForGenJournal(GenJournalLine);

        // [THEN] Request Page has Posting Date = 10.01.18, Last Payment Date = 20.01.18
        // [THEN] Bal. Account Type = G/L Account, Bal. Account No. = "A"
        // Verification is done in SuggestVendorPaymentsCheckUpdateValuesRequestPageHandler
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsCheckUpdateValuesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentWithSavedValuesWhenBatchHasBalAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ActionType: Option Update,Verify;
        PostingDate: Date;
        LastPaymentDate: Date;
    begin
        // [FEATURE] [Suggest Vendor Payments] [UI]
        // [SCENARIO 224171] Run Suggest Vendor Payments with saved values on Batch with Bal. Account No. defined
        Initialize();

        PostingDate := LibraryRandom.RandDate(5);
        LastPaymentDate := LibraryRandom.RandDate(5);

        // [GIVEN] Gen. Journal Batch with Bal. Account No.= "B"
        SetupGenJnlLine(GenJournalLine);
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateBankAccountNo());
        GenJournalBatch.Modify(true);

        // [GIVEN] Run Suggest Vendor Payment with Posting Date = 10.01.18, Last Payment Date = 20.01.18
        // [GIVEN] Bal. Account Type = G/L Account, Bal. Account No. = "A"
        SuggestVendorPaymentsEnqueueValues(
          ActionType::Update, PostingDate, LastPaymentDate,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        SuggestVendorPaymentForGenJournal(GenJournalLine);

        // [WHEN] Run Suggest Vendor Payments second time
        SuggestVendorPaymentsEnqueueValues(
          ActionType::Verify, PostingDate, LastPaymentDate,
          GenJournalLine."Account Type"::"Bank Account", GenJournalBatch."Bal. Account No.");
        SuggestVendorPaymentForGenJournal(GenJournalLine);

        // [THEN] Request Page has Posting Date = 10.01.18, Last Payment Date = 20.01.18
        // [THEN] Bal. Account Type = Bank Account, Bal. Account No. = "B"
        // Verification is done in SuggestVendorPaymentsCheckUpdateValuesRequestPageHandler
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentMessageToRecipientStandard()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 225334] Suggest Vendor Payment of Vendor Lendger Entry with blank Message To Recipient
        Initialize();

        // [GIVEN] Vendor Ledger Entry of Invoice "INV" with blank Message To Recipient
        CreatePostVendorEntryWithMsgToRecipient(VendorLedgerEntry, '');

        // [WHEN] Run Suggest Vendor Payment
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        SuggestVendorPayment(
          GenJournalBatch, VendorLedgerEntry."Vendor No.", WorkDate(), false,
          GenJournalLine."Bal. Account Type"::"Bank Account", LibraryERM.CreateBankAccountNo(), "Bank Payment Type"::" ", false);

        // [THEN] Gen. Journal Line is created with Message To Recipient = 'Payment of Invoice "INV"'
        VerifyMessageToRecipientStandard(
          GenJournalLine, GenJournalBatch.Name,
          StrSubstNo(
            MessageToRecipientMsg,
            VendorLedgerEntry."Document Type",
            VendorLedgerEntry."Document No."));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentMessageToRecipientFromVendorLedgEntry()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 225334] Suggest Vendor Payment of Vendor Lendger Entry with updated Message To Recipient
        Initialize();

        // [GIVEN] Vendor Ledger Entry of Invoice "INV" with Message To Recipient = 'custom invoice 123'
        CreatePostVendorEntryWithMsgToRecipient(
          VendorLedgerEntry,
          CopyStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(VendorLedgerEntry."Message to Recipient")),
            1, MaxStrLen(VendorLedgerEntry."Message to Recipient")));

        // [WHEN] Run Suggest Vendor Payment
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        SuggestVendorPayment(
          GenJournalBatch, VendorLedgerEntry."Vendor No.", WorkDate(), false,
          GenJournalLine."Bal. Account Type"::"Bank Account", LibraryERM.CreateBankAccountNo(), "Bank Payment Type"::" ", false);

        // [THEN] Gen. Journal Line is created with Message To Recipient = 'custom invoice 123'
        VerifyMessageToRecipientStandard(
          GenJournalLine, GenJournalBatch.Name, VendorLedgerEntry."Message to Recipient");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SuggestVendorPaymentsRequestWithBnkPmtTypePageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentWithElectronicPaymentIAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Bank Payment Type]
        // [SCENARIO] Stan can set "Electronic Payment-IAT" as "Bank Payment Type" on request page of "Suggest Vendor Payments" report
        Initialize();

        // [GIVEN] Posted Invoice for Vendor A for Amount = -100
        BankAccountNo := LibraryERM.CreateBankAccountNo();
        CreateAndPostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Document Type"::Invoice, -1);
        VendorNo := GenJournalLine."Account No.";

        // [WHEN] Run Report "Suggest Vendor Payment" for Vendor A with "Bank Payment Type" set to "Electronic Payment-IAT"
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account Type"::"Bank Account");
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(GenJournalLine."Bank Payment Type"::"Electronic Payment-IAT");
        SuggestVendorPayments.Run();

        // [THEN] Payment Journal Line created for Vendor A with Ammout 100 with "Bank Payment Type" = "Electronic Payment-IAT"
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment-IAT");
        GenJournalLine.SetRange("Account No.", VendorNo);
        GenJournalLine.SetRange(Amount, -GenJournalLine.Amount);
        Assert.RecordIsNotEmpty(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SuggestVendorPaymentsRequestWithBnkPmtTypePageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentWithElectronicPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Bank Payment Type]
        // [SCENARIO] Stan can set "Electronic Payment" as "Bank Payment Type" on request page of "Suggest Vendor Payments" report
        Initialize();

        // [GIVEN] Posted Invoice for Vendor A for Amount = 100
        BankAccountNo := LibraryERM.CreateBankAccountNo();
        CreateAndPostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Document Type"::Invoice, -1);
        VendorNo := GenJournalLine."Account No.";

        // [WHEN] Run Report "Suggest Vendor Payment" for Vendor A with "Bank Payment Type" set to "Electronic Payment"
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account Type"::"Bank Account");
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(GenJournalLine."Bank Payment Type"::"Electronic Payment");
        SuggestVendorPayments.Run();

        // [THEN] Payment Journal Line created for Vendor A with Ammout 100 with "Bank Payment Type" = "Electronic Payment"
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
        GenJournalLine.SetRange("Account No.", VendorNo);
        GenJournalLine.SetRange(Amount, -GenJournalLine.Amount);
        Assert.RecordIsNotEmpty(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsCheckOtherBatchesRequestPageHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DontSuggestLinesExistingInOtherJnlBatchesWhenEnabled()
    var
        GenJournalBatch: array[3] of Record "Gen. Journal Batch";
        ErrorMessages: TestPage "Error Messages";
        VendorNo: Code[20];
        BankAccountNo: Code[20];
        Amount: array[3] of Decimal;
        i: Decimal;
    begin
        // [FEATURE] [UI] [Payment Journal]
        // [SCENARIO 279398] Previously suggested lines existing in the different journal batches are not suggested and Error Message page is invoked
        Initialize();

        // [GIVEN] Three Posted Vendor Invoices for Amounts of "A1" = 50, "A2" = 100 and "A3" = 200
        PostThreeInvoicesForVendor(VendorNo, BankAccountNo, Amount);

        // [GIVEN] Three Payment Journal Batches "B1" "B2" "B3" from single Gen. Journal Template
        PrepareThreePaymentJournalBatches(GenJournalBatch, BankAccountNo);

        // [GIVEN] Two payment lines for amounts of "A1" and "A2" suggested in B1 and B2 batches respectively
        for i := 1 to ArrayLen(GenJournalBatch) - 1 do begin
            LibraryVariableStorage.Enqueue(VendorNo);
            LibraryVariableStorage.Enqueue(false);
            Commit();
            SuggestVendorPaymentFromJournalBatch(GenJournalBatch[i]."Journal Template Name", GenJournalBatch[i].Name);
            RemoveNonrelatedAmounts(GenJournalBatch[i]."Journal Template Name", GenJournalBatch[i].Name, Amount[i]);
        end;

        // [WHEN] Open B3 and run Report 393 "Suggest Vendor Payment" with "Check Other Journal Batches" checkbox enabled
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(true);
        Commit();
        ErrorMessages.Trap();
        SuggestVendorPaymentFromJournalBatch(GenJournalBatch[3]."Journal Template Name", GenJournalBatch[3].Name);

        // [THEN] Confirmation is invoked with text and TRUE is returned in ConfirmHandlerTrue
        // [THEN] ErrorMessages page is opened containing information from B1 and B2 lines that were not suggested
        ErrorMessages.First();
        VerifyExpectedErrorMessageLine(ErrorMessages, GenJournalBatch[1]."Journal Template Name", GenJournalBatch[1].Name);
        ErrorMessages.Last();
        VerifyExpectedErrorMessageLine(ErrorMessages, GenJournalBatch[2]."Journal Template Name", GenJournalBatch[2].Name);
        ErrorMessages.Close();

        // [THEN] The line with "A3" is the only suggested line
        VerifyOnlySuggestedLineWithAmount(GenJournalBatch[3]."Journal Template Name", GenJournalBatch[3].Name, Amount[3]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsCheckOtherBatchesRequestPageHandler,MessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure SuggestLinesExistingInOtherJnlBatchesSkippedWhenEnabledAndNotConfirmed()
    var
        GenJournalBatch: array[3] of Record "Gen. Journal Batch";
        ErrorMessages: TestPage "Error Messages";
        VendorNo: Code[20];
        BankAccountNo: Code[20];
        Amount: array[3] of Decimal;
        i: Decimal;
    begin
        // [FEATURE] [UI] [Payment Journal]
        // [SCENARIO 279398] Previously suggested lines existing in the different journal batches are not suggested and Error Message page is not invoked
        Initialize();

        // [GIVEN] Three Posted Vendor Invoices for Amounts of "A1" = 50, "A2" = 100 and "A3" = 200
        PostThreeInvoicesForVendor(VendorNo, BankAccountNo, Amount);

        // [GIVEN] Three Payment Journal Batches "B1" "B2" "B3" from single Gen. Journal Template
        PrepareThreePaymentJournalBatches(GenJournalBatch, BankAccountNo);

        // [GIVEN] Two payment lines for amounts of "A1" and "A2" suggested in B1 and B2 batches respectively
        for i := 1 to ArrayLen(GenJournalBatch) - 1 do begin
            LibraryVariableStorage.Enqueue(VendorNo);
            LibraryVariableStorage.Enqueue(false);
            Commit();
            SuggestVendorPaymentFromJournalBatch(GenJournalBatch[i]."Journal Template Name", GenJournalBatch[i].Name);
            RemoveNonrelatedAmounts(GenJournalBatch[i]."Journal Template Name", GenJournalBatch[i].Name, Amount[i]);
        end;

        // [WHEN] Open B3 and run Report 393 "Suggest Vendor Payment" with "Check Other Journal Batches" checkbox enabled
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(true);
        Commit();
        ErrorMessages.Trap();
        SuggestVendorPaymentFromJournalBatch(GenJournalBatch[3]."Journal Template Name", GenJournalBatch[3].Name);

        // [THEN] Confirmation is invoked with text and FALSE is returned in ConfirmHandlerFalse
        // [THEN] ErrorMessages page is not opened
        // [THEN] The line with "A3" is the only suggested line
        VerifyOnlySuggestedLineWithAmount(GenJournalBatch[3]."Journal Template Name", GenJournalBatch[3].Name, Amount[3]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsCheckOtherBatchesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestLinesExistingInOtherJnlBatchesNotSkippedWhenDisabled()
    var
        GenJournalBatch: array[3] of Record "Gen. Journal Batch";
        ErrorMessages: TestPage "Error Messages";
        VendorNo: Code[20];
        BankAccountNo: Code[20];
        Amount: array[3] of Decimal;
        i: Decimal;
    begin
        // [FEATURE] [UI] [Payment Journal]
        // [SCENARIO 279398] Previously suggested lines existing in the different journal batches are suggested with no dialogs when the CheckOtherJournalBatches is FALSE
        Initialize();

        // [GIVEN] Three Posted Vendor Invoices for Amounts of "A1" = 50, "A2" = 100 and "A3" = 200
        PostThreeInvoicesForVendor(VendorNo, BankAccountNo, Amount);

        // [GIVEN] Three Payment Journal Batches "B1" "B2" "B3" from single Gen. Journal Template
        PrepareThreePaymentJournalBatches(GenJournalBatch, BankAccountNo);

        // [GIVEN] Two payment lines for amounts of "A1" and "A2" suggested in B1 and B2 batches respectively
        for i := 1 to ArrayLen(GenJournalBatch) - 1 do begin
            LibraryVariableStorage.Enqueue(VendorNo);
            LibraryVariableStorage.Enqueue(false);
            Commit();
            SuggestVendorPaymentFromJournalBatch(GenJournalBatch[i]."Journal Template Name", GenJournalBatch[i].Name);
            RemoveNonrelatedAmounts(GenJournalBatch[i]."Journal Template Name", GenJournalBatch[i].Name, Amount[i]);
        end;

        // [WHEN] Open B3 and run Report 393 "Suggest Vendor Payment" with "Check Other Journal Batches" checkbox disabled
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(false);
        Commit();
        ErrorMessages.Trap();
        SuggestVendorPaymentFromJournalBatch(GenJournalBatch[3]."Journal Template Name", GenJournalBatch[3].Name);

        // [THEN] Confirmation is not invoked
        // [THEN] ErrorMessages page is not opened
        // [THEN] The lines with "A1", "A2" and "A3" are suggested line
        VerifySuggestedLineWithAmount(GenJournalBatch[3]."Journal Template Name", GenJournalBatch[3].Name, Amount[1]);
        VerifySuggestedLineWithAmount(GenJournalBatch[3]."Journal Template Name", GenJournalBatch[3].Name, Amount[2]);
        VerifySuggestedLineWithAmount(GenJournalBatch[3]."Journal Template Name", GenJournalBatch[3].Name, Amount[3]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePaymentWhenBatchNotExists()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        TempGenJournalTemplate: Record "Gen. Journal Template" temporary;
        CreatePayment: TestPage "Create Payment";
    begin
        // [FEATURE] [UI] [Create Payment]
        // [SCENARIO 294543] When run page Create Payment for non-existent Batch, then no error and Batch Name is cleared on page
        Initialize();

        // [GIVEN] Gen. Journal Template of type Payment has Gen. Journal Batch "B"
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        SaveGeneralTemplates(GenJournalTemplate, TempGenJournalTemplate);
        GenJournalTemplate.DeleteAll();
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::Payments);

        // [GIVEN] Ran page Create Payment, set Batch Name and pushed OK
        CreatePayment.OpenEdit();
        CreatePayment."Batch Name".SetValue(GenJournalBatch.Name);
        CreatePayment."Starting Document No.".SetValue(LibraryRandom.RandInt(100));
        CreatePayment.OK().Invoke();

        // [GIVEN] Deleted Gen Journal Batch
        GenJournalBatch.Delete();

        // [WHEN] Run page Create Payment
        CreatePayment.OpenEdit();

        // [THEN] Page Create Payment shows Batch Name = Blank
        GenJournalBatch.FindFirst();
        Assert.AreEqual(GenJournalBatch.Name, Format(CreatePayment."Batch Name"), '');

        CreatePayment.Close();
        RestoreGeneralTemplates(TempGenJournalTemplate, GenJournalTemplate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePaymentWhenTemplateNotExists()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        TempGenJournalTemplate: Record "Gen. Journal Template" temporary;
        CreatePayment: TestPage "Create Payment";
    begin
        // [FEATURE] [UI] [Create Payment]
        // [SCENARIO 294543] When run page Create Payment and no Gen. Journal Templates exist, then no error and Batch Name is cleared on page
        Initialize();

        // [GIVEN] Gen. Journal Templates don't exist
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        SaveGeneralTemplates(GenJournalTemplate, TempGenJournalTemplate);
        GenJournalTemplate.DeleteAll();

        // [WHEN] Run page Create Payment
        CreatePayment.OpenEdit();

        // [THEN] Page Create Payment shows Batch Name = Blank
        GenJournalBatch.FindFirst();
        Assert.AreEqual(GenJournalBatch.Name, Format(CreatePayment."Batch Name"), '');

        CreatePayment.Close();
        RestoreGeneralTemplates(TempGenJournalTemplate, GenJournalTemplate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePaymentStartingDocumentNo()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        CreatePayment: TestPage "Create Payment";
    begin
        // [FEATURE] [UI] [Create Payment]
        // [SCENARIO 297928] Choosing Batch name on Create Payment page leads to "Starting Document No." being equal to increment of last Gen. Journal Line's "Document No."
        Initialize();

        // [GIVEN] Gen. Journal Template of type Payment has Gen. Journal Batch "B" with No. Series
        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        GenJournalBatch.Validate("No. Series", NoSeries.Code);
        GenJournalBatch.Modify(true);

        // [GIVEN] Gen. Journal line in Batch "B" with "Document No." equal to 100
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, WorkDate(), LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Document Type"::Payment, -LibraryRandom.RandInt(10));

        // [WHEN] On Create Payment page "Batch name" is set to "B"
        CreatePayment.OpenEdit();
        CreatePayment."Template Name".SetValue(GenJournalBatch."Journal Template Name");
        CreatePayment."Batch Name".SetValue(GenJournalBatch.Name);

        // [THEN] "Starting Document No." is equal to 101
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindLast();
        CreatePayment."Starting Document No.".AssertEquals(IncStr(GenJournalLine."Document No."));
        CreatePayment.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure SuggestVendorPaymentSummarizedWhenThereIsFirstLineLinkedWithVLE()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        BankAccountNo: Code[20];
        InvoiceAmount: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO 308150] Suggest Payment with Summarized option exclude already existing first suggested Payment Line linked with Vendor Ledger Entry
        Initialize();

        // [GIVEN] Three posted Vendor invoices with amounts of "A1" = 50, "A2" = 100 and "A3" = 200
        PostThreeInvoicesForVendor(VendorNo, BankAccountNo, InvoiceAmount);

        // [GIVEN] Payment Journal Batch with Template
        PreparePaymentJournalBatch(GenJournalBatch, BankAccountNo);

        // [GIVEN] Suggest Vendor Payment for Vendor creates three payment journal lines for each vendor invoice
        SuggestVendorPayment(
          GenJournalBatch, VendorNo, WorkDate(), false,
          GenJournalLine."Bal. Account Type"::"Bank Account",
          GenJournalBatch."Bal. Account No.", "Bank Payment Type"::" ", false);
        for i := 1 to ArrayLen(InvoiceAmount) do
            VerifySuggestedLineWithAmount(GenJournalBatch."Journal Template Name", GenJournalBatch.Name, InvoiceAmount[i]);

        // [GIVEN] Two payment journal lines were removed leaving only First Line with amount = A1
        FindGeneralJournalLineFromBatchAndAmount(
          GenJournalLine, GenJournalBatch.Name, GenJournalBatch."Journal Template Name", InvoiceAmount[1]);
        GenJournalLine.SetFilter(Amount, '<>%1', GenJournalLine.Amount);
        GenJournalLine.DeleteAll();

        // [WHEN] Suggest Vendor Payment with SummarizePerVendor option for Vendor
        SuggestVendorPayment(
          GenJournalBatch, VendorNo, WorkDate(), false,
          GenJournalLine."Bal. Account Type"::"Bank Account",
          GenJournalBatch."Bal. Account No.", "Bank Payment Type"::" ", true);

        // [THEN] First payment journal line exist with amount = A1
        VerifySuggestedLineWithAmount(GenJournalBatch."Journal Template Name", GenJournalBatch.Name, InvoiceAmount[1]);

        // [THEN] Second payment journal line created with summarized amount = A2 + A3
        VerifySuggestedLineWithAmount(GenJournalBatch."Journal Template Name", GenJournalBatch.Name, InvoiceAmount[2] + InvoiceAmount[3]);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure SuggestVendorPaymentSummarizedWhenThereIsLastLineLinkedWithVLE()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        BankAccountNo: Code[20];
        InvoiceAmount: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO 308150] Suggest Payment with Summarized option exclude already existing last suggested Payment Line linked with Vendor Ledger Entry
        Initialize();

        // [GIVEN] Three posted Vendor invoices with amounts of "A1" = 50, "A2" = 100 and "A3" = 200
        PostThreeInvoicesForVendor(VendorNo, BankAccountNo, InvoiceAmount);

        // [GIVEN] Payment Journal Batch with Template
        PreparePaymentJournalBatch(GenJournalBatch, BankAccountNo);

        // [GIVEN] Suggest Vendor Payment for Vendor creates three payment journal lines for each vendor invoice
        SuggestVendorPayment(
          GenJournalBatch, VendorNo, WorkDate(), false,
          GenJournalLine."Bal. Account Type"::"Bank Account",
          GenJournalBatch."Bal. Account No.", "Bank Payment Type"::" ", false);
        for i := 1 to ArrayLen(InvoiceAmount) do
            VerifySuggestedLineWithAmount(GenJournalBatch."Journal Template Name", GenJournalBatch.Name, InvoiceAmount[i]);

        // [GIVEN] Two payment journal lines were removed leaving only First Line with amount = A1
        FindGeneralJournalLineFromBatchAndAmount(
          GenJournalLine, GenJournalBatch.Name, GenJournalBatch."Journal Template Name", InvoiceAmount[3]);
        GenJournalLine.SetFilter(Amount, '<>%1', GenJournalLine.Amount);
        GenJournalLine.DeleteAll();

        // [WHEN] Suggest Vendor Payment with SummarizePerVendor option for Vendor
        SuggestVendorPayment(
          GenJournalBatch, VendorNo, WorkDate(), false,
          GenJournalLine."Bal. Account Type"::"Bank Account",
          GenJournalBatch."Bal. Account No.", "Bank Payment Type"::" ", true);

        // [THEN] First payment journal line created with with summarized amount = A1 + A2
        VerifySuggestedLineWithAmount(GenJournalBatch."Journal Template Name", GenJournalBatch.Name, InvoiceAmount[1] + InvoiceAmount[2]);

        // [THEN] Second payment journal line exist with amount = A3
        VerifySuggestedLineWithAmount(GenJournalBatch."Journal Template Name", GenJournalBatch.Name, InvoiceAmount[3]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePaymentWithOneLineInGeneralTemplate()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        TempGenJournalTemplate: Record "Gen. Journal Template" temporary;
        CreatePayment: TestPage "Create Payment";
    begin
        // [FEATURE] [UI] [Create Payment]
        // [SCENARIO 332052] Run page Create Payment for one General Template
        Initialize();

        // [GIVEN] Gen. Journal Template of type Payment has Gen. Journal Batch "B"
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        SaveGeneralTemplates(GenJournalTemplate, TempGenJournalTemplate);
        GenJournalTemplate.DeleteAll();
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::Payments);

        // [WHEN] Run page Create Payment
        CreatePayment.OpenEdit();

        // [THEN] Page Create Payment shows "B" in field Batch Name
        Assert.AreEqual(GenJournalBatch.Name, Format(CreatePayment."Batch Name"), '');

        CreatePayment.Close();
        RestoreGeneralTemplates(TempGenJournalTemplate, GenJournalTemplate);
    end;

    [Test]
    [HandlerFunctions('GetFirstLineFromTemlateListHandler')]
    [Scope('OnPrem')]
    procedure CreatePaymentWithTwoLineInGeneralTemplateFirstLine()
    var
        GenJournalBatch: array[2] of Record "Gen. Journal Batch";
        GenJournalTemplate: array[2] of Record "Gen. Journal Template";
        TempGenJournalTemplate: Record "Gen. Journal Template" temporary;
        CreatePayment: TestPage "Create Payment";
    begin
        // [FEATURE] [UI] [Create Payment]
        // [SCENARIO 332052] Select first template on Create Payment page when two Gen. Journal Templates exist with  one batch for each.
        Initialize();

        // [GIVEN] Created Gen. Journal Batches "B1" and "B2" with different General Templates "T1" and "T2" with type Payments
        GenJournalTemplate[1].SetRange(Type, GenJournalTemplate[1].Type::Payments);
        SaveGeneralTemplates(GenJournalTemplate[1], TempGenJournalTemplate);
        GenJournalTemplate[1].DeleteAll();
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch[1], GenJournalBatch[1]."Template Type"::Payments);
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch[2], GenJournalBatch[2]."Template Type"::Payments);
        GenJournalTemplate[1].Get(GenJournalBatch[1]."Journal Template Name");
        GenJournalTemplate[2].Get(GenJournalBatch[2]."Journal Template Name");

        // [WHEN] Ran page Create Payment with "T1" Template selection
        CreatePayment.OpenEdit();

        // [THEN] Page Create Payment shows "T1" in field Template Name
        Assert.AreEqual(GenJournalBatch[1]."Journal Template Name", Format(CreatePayment."Template Name"), '');

        // [THEN] Page Create Payment shows "B1" in field Batch Name
        Assert.AreEqual(GenJournalBatch[1].Name, Format(CreatePayment."Batch Name"), '');

        CreatePayment.Close();
        RestoreGeneralTemplates(TempGenJournalTemplate, GenJournalTemplate[1]);
    end;

    [Test]
    [HandlerFunctions('GetLastLineFromTemlateListHandler')]
    [Scope('OnPrem')]
    procedure CreatePaymentWithTwoLineInGeneralTemplateSecondLine()
    var
        GenJournalBatch: array[2] of Record "Gen. Journal Batch";
        GenJournalTemplate: array[2] of Record "Gen. Journal Template";
        TempGenJournalTemplate: Record "Gen. Journal Template" temporary;
        CreatePayment: TestPage "Create Payment";
    begin
        // [FEATURE] [UI] [Create Payment]
        // [SCENARIO 332052] Select second template on Create Payment page when two Gen. Journal Templates exist with  one batch for each.
        Initialize();

        // [GIVEN] Created Gen. Journal Batches "B1" and "B2" with different General Templates "T1" and "T2" with type Payments
        GenJournalTemplate[1].SetRange(Type, GenJournalTemplate[1].Type::Payments);
        SaveGeneralTemplates(GenJournalTemplate[1], TempGenJournalTemplate);
        GenJournalTemplate[1].DeleteAll();
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch[1], GenJournalBatch[1]."Template Type"::Payments);
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch[2], GenJournalBatch[2]."Template Type"::Payments);
        GenJournalTemplate[1].Get(GenJournalBatch[1]."Journal Template Name");
        GenJournalTemplate[2].Get(GenJournalBatch[2]."Journal Template Name");

        // [GIVEN] Ran page Create Payment with "T2" Template selection
        CreatePayment.OpenEdit();

        // [THEN] Page Create Payment shows "T2" in field Template Name
        Assert.AreEqual(GenJournalBatch[2]."Journal Template Name", Format(CreatePayment."Template Name"), '');

        // [THEN] Page Create Payment shows "B2" in field Batch Name
        Assert.AreEqual(GenJournalBatch[2].Name, Format(CreatePayment."Batch Name"), '');

        CreatePayment.Close();
        RestoreGeneralTemplates(TempGenJournalTemplate, GenJournalTemplate[1]);
    end;

    [Test]
    [HandlerFunctions('CreatePaymentModalPageHandler,GetLastLineFromTemlateListHandler')]
    [Scope('OnPrem')]
    procedure CreatePaymentWithTwoLineInGeneralTemplateFirstLineCompleted()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: array[2] of Record "Gen. Journal Batch";
        GenJournalTemplate: array[2] of Record "Gen. Journal Template";
        TempGenJournalTemplate: Record "Gen. Journal Template" temporary;
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [UI] [Create Payment]
        // [SCENARIO 332052] Run page Create Payment for second General Template
        Initialize();

        // [GIVEN] Created Gen. Journal Batches "B1" and "B2" with different General Templates "T1" and "T2" with type Payments
        GenJournalTemplate[1].SetRange(Type, GenJournalTemplate[1].Type::Payments);
        SaveGeneralTemplates(GenJournalTemplate[1], TempGenJournalTemplate);
        GenJournalTemplate[1].DeleteAll();
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch[1], GenJournalBatch[1]."Template Type"::Payments);
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch[2], GenJournalBatch[2]."Template Type"::Payments);
        GenJournalTemplate[1].Get(GenJournalBatch[1]."Journal Template Name");
        GenJournalTemplate[2].Get(GenJournalBatch[2]."Journal Template Name");

        // [GIVEN] Created and posted Vendor's invoice
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine,
          GenJournalBatch[2]."Journal Template Name",
          GenJournalBatch[2].Name,
          GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor,
          LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Bal. Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(),
          -LibraryRandom.RandDecInRange(10, 100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Document No.");

        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.FILTER.SetFilter("Vendor No.", Format(GenJournalLine."Account No."));
        VendorLedgerEntries.First();
        PaymentJournal.Trap();

        // [WHEN] Run page Create Payment for the posted invoice
        VendorLedgerEntries."Create Payment".Invoke();
        PaymentJournal.OK().Invoke();

        // [THEN] Payment Gen Journal Line was created
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch[2]."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch[2].Name);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Payment);

        VendorLedgerEntries.Close();
        RestoreGeneralTemplates(TempGenJournalTemplate, GenJournalTemplate[1]);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetLastLineFromTemlateListHandler')]
    [Scope('OnPrem')]
    procedure CreatePaymentCheckSaveValue()
    var
        GenJournalBatch: array[2] of Record "Gen. Journal Batch";
        GenJournalTemplate: array[2] of Record "Gen. Journal Template";
        TempGenJournalTemplate: Record "Gen. Journal Template" temporary;
        CreatePayment: TestPage "Create Payment";
    begin
        // [FEATURE] [UI] [Create Payment]
        // [SCENARIO 332052] When run page Create Payment, value fill automatically
        Initialize();

        // [GIVEN] Created Gen. Journal Batches "B1" and "B2" with different General Templates "T1" and "T2" with type Payments
        GenJournalTemplate[1].SetRange(Type, GenJournalTemplate[1].Type::Payments);
        SaveGeneralTemplates(GenJournalTemplate[1], TempGenJournalTemplate);
        GenJournalTemplate[1].DeleteAll();
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch[1], GenJournalBatch[1]."Template Type"::Payments);
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch[2], GenJournalBatch[2]."Template Type"::Payments);
        GenJournalTemplate[1].Get(GenJournalBatch[1]."Journal Template Name");
        GenJournalTemplate[2].Get(GenJournalBatch[2]."Journal Template Name");

        // [GIVEN] Ran page Create Payment, set Batch Name and pushed OK
        CreatePayment.OpenEdit();
        CreatePayment."Template Name".SetValue(GenJournalBatch[2]."Journal Template Name");
        CreatePayment."Batch Name".SetValue(GenJournalBatch[2].Name);
        CreatePayment."Starting Document No.".SetValue(LibraryRandom.RandInt(100));
        CreatePayment.OK().Invoke();

        // [WHEN] Run page Create Payment
        CreatePayment.OpenEdit();

        // [THEN] Page Create Payment shows the previous value
        CreatePayment."Batch Name".AssertEquals(GenJournalBatch[2].Name);

        CreatePayment.Close();
        RestoreGeneralTemplates(TempGenJournalTemplate, GenJournalTemplate[1]);
    end;

    [Test]
    [HandlerFunctions('CreatePaymentWithPostingModalPageHandler')]
    [Scope('OnPrem')]
    procedure CheckCorrectCopyDimensionToVendorLedgerEntry()
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        PaymentJournal: TestPage "Payment Journal";
        DimSetID: Integer;
        PostedDocNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [UI] [Create Payment]
        // [SCENARIO 337935] When run page Create Payment for posted purchase invoice with Dimansions, Dimansions copy automatically
        Initialize();

        // [GIVEN] Dimension and Dimension Value was found
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);

        // [GIVEN] Created Vendor "V" with Default Dimension
        VendorNo := CreateVendorWithDimension(DefaultDimension, DefaultDimension."Value Posting"::"Code Mandatory", DimensionValue."Dimension Code");
        DefaultDimension.Validate("Dimension Value Code", '');
        DefaultDimension.Modify(true);

        // [GIVEN] Created and Posted Purchase Invoice "PI" with Dimensions "D" for "V" 
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue."Dimension Code", DimensionValue.Code);
        PurchaseHeader.Validate("Dimension Set ID", DimSetID);
        PurchaseHeader.Modify(true);

        PurchaseLine.Validate("Dimension Set ID", DimSetID);
        PurchaseLine.Modify(true);

        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);

        LibraryERM.FindBankAccount(BankAccount);

        LibraryVariableStorage.Enqueue(PostedDocNo);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(WorkDate());

        // [WHEN] Run "Create Payment" for Vendor Ledger Entry, created for "PI"
        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.filter.SetFilter("Vendor No.", VendorNo);
        VendorLedgerEntries.filter.SetFilter("Document No.", PostedDocNo);
        VendorLedgerEntries.First();
        PaymentJournal.Trap();
        VendorLedgerEntries."Create Payment".Invoke();
        PaymentJournal.Close();

        // [THEN] "D" successfully transfer to Gen. Journal Line
        GenJournalLine.SetRange("Document No.", PostedDocNo);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Dimension Set ID", DimSetID);

        GenJournalLine.Delete();
    end;

    [Test]
    [HandlerFunctions('CreatePaymentWithPostingModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePaymentWithDateEarlierThanInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        BankAccount: Record "Bank Account";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Create Payment] [Applicaition]
        // [SCENARIO 344051] Stan can't create payment with an earlier posting date.
        Initialize();

        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryERM.FindBankAccount(BankAccount);

        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(WorkDate() - 1);
        Commit();

        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.FILTER.SetFilter("Vendor No.", PurchaseHeader."Buy-from Vendor No.");

        asserterror VendorLedgerEntries."Create Payment".Invoke();

        Assert.ExpectedError(StrSubstNo(EarlierPostingDateErr, PurchaseHeader."Document Type", PostedInvoiceNo));

        LibraryVariableStorage.AssertEmpty();

        // Bug 415621
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(WorkDate() - 1);

        asserterror VendorLedgerEntries."Create Payment".Invoke();

        Assert.ExpectedError(StrSubstNo(EarlierPostingDateErr, PurchaseHeader."Document Type", PostedInvoiceNo));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CreatePaymentWithPostingModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreateAndPostRefundForCrediteMemoViaCreatePaymentPage()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccount: Record "Bank Account";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Create Payment] [Applicaition] [Credit Memo] [Refund]
        // [SCENARIO 343320] Stan can create and post refund for credit memo via "Create Payment" page
        Initialize();

        GenJournalLine.DeleteAll();
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryERM.FindBankAccount(BankAccount);

        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(WorkDate());

        PaymentJournal.Trap();
        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.FILTER.SetFilter("Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        VendorLedgerEntries."Create Payment".Invoke();
        PaymentJournal.Filter.SetFilter("Account No.", PurchaseHeader."Buy-from Vendor No.");
        PaymentJournal."Document Type".AssertEquals(GenJournalLine."Document Type"::Refund);
        PaymentJournal.Close();
        Commit();

        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Account No.", PurchaseHeader."Buy-from Vendor No.");
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Refund);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        VendorLedgerEntry.SetRange("Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        VendorLedgerEntry.SetRange(Open, false);
        Assert.RecordCount(VendorLedgerEntry, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CreatePaymentWithPostingModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreateAndPostPaymentForInvoiceViaCreatePaymentPage()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccount: Record "Bank Account";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Create Payment] [Applicaition] [Invoice] [Payment]
        // [SCENARIO 349127] Stan can create and post payment for invoice via "Create Payment" page
        Initialize();

        GenJournalLine.DeleteAll();
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryERM.FindBankAccount(BankAccount);

        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(WorkDate());

        PaymentJournal.Trap();
        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.FILTER.SetFilter("Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        VendorLedgerEntries."Create Payment".Invoke();
        PaymentJournal."Account No.".AssertEquals(PurchaseHeader."Buy-from Vendor No.");
        PaymentJournal."Document Type".AssertEquals(GenJournalLine."Document Type"::Payment);
        PaymentJournal.Close();

        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Account No.", PurchaseHeader."Buy-from Vendor No.");
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Payment);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        VendorLedgerEntry.SetRange("Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        VendorLedgerEntry.SetRange(Open, false);
        Assert.RecordCount(VendorLedgerEntry, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsStartingDocNoRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsTwoVendorsNoSeriesIncrBy10()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        NoSeriesLine: Record "No. Series Line";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Index: Integer;
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 342243] "Suggest Vendor Payments" report considers "Increment by No." setup in number series of general journal batch
        Initialize();

        for Index := 1 to ArrayLen(PurchaseHeader) do begin
            LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader[Index]);
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader[Index], true, true);
        end;

        CreateNoSeriesWithIncrementByNo(NoSeriesLine, 10, 'A0001', 'A9999');
        LibraryERM.FindBankAccount(BankAccount);
        SetupGenJournalLineForSuggestVendorPayments(GenJournalLine, NoSeriesLine);

        LibraryVariableStorage.Enqueue(StrSubstNo(OrFilterStringTxt, PurchaseHeader[1]."Buy-from Vendor No.", PurchaseHeader[2]."Buy-from Vendor No."));
        LibraryVariableStorage.Enqueue(NoSeriesLine."Starting No.");
        LibraryVariableStorage.Enqueue(false); // Summarize - FALSE
        LibraryVariableStorage.Enqueue(false); // New Doc. No. per Line - FALSE
        LibraryVariableStorage.Enqueue(BankAccount."No.");

        SuggestVendorPaymentForGenJournal(GenJournalLine);

        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Document No.", 'A0001');

        GenJournalLine.Next();
        GenJournalLine.TestField("Document No.", 'A0011');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsStartingDocNoRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsTwoVendorsNoSeriesIncrBy10SummarizedByVendor()
    var
        Vendor: array[2] of Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        NoSeriesLine: Record "No. Series Line";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        VendorIndex: Integer;
        DocIndex: Integer;
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 342243] "Suggest Vendor Payments" report considers "Increment by No." setup in number series of general journal batch when "Summarized per Vendor" = TRUE
        Initialize();

        for VendorIndex := 1 to ArrayLen(Vendor) do begin
            LibraryPurchase.CreateVendor(Vendor[VendorIndex]);
            for DocIndex := 1 to ArrayLen(PurchaseHeader) do begin
                Clear(PurchaseHeader[DocIndex]);
                LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader[DocIndex], Vendor[VendorIndex]."No.");
                LibraryPurchase.PostPurchaseDocument(PurchaseHeader[DocIndex], true, true);
            end;
        end;

        CreateNoSeriesWithIncrementByNo(NoSeriesLine, 10, 'A0001', 'A9999');
        LibraryERM.FindBankAccount(BankAccount);
        SetupGenJournalLineForSuggestVendorPayments(GenJournalLine, NoSeriesLine);

        LibraryVariableStorage.Enqueue(StrSubstNo(OrFilterStringTxt, Vendor[1]."No.", Vendor[2]."No."));
        LibraryVariableStorage.Enqueue(NoSeriesLine."Starting No.");
        LibraryVariableStorage.Enqueue(true); // Summarize - TRUE
        LibraryVariableStorage.Enqueue(true); // New Doc. No. per Line - TRUE
        LibraryVariableStorage.Enqueue(BankAccount."No.");

        SuggestVendorPaymentForGenJournal(GenJournalLine);

        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Document No.", 'A0001');
        GenJournalLine.TestField("Account No.", Vendor[1]."No.");

        GenJournalLine.Next();
        GenJournalLine.TestField("Document No.", 'A0011');
        GenJournalLine.TestField("Account No.", Vendor[2]."No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsStartingDocNoRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsTwoVendorsNoSeriesIncrBy10DocNoPerLine()
    var
        Vendor: array[2] of Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        NoSeriesLine: Record "No. Series Line";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        VendorIndex: Integer;
        DocIndex: Integer;
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 342243] "Suggest Vendor Payments" report considers "Increment by No." setup in number series of general journal batch when "New Doc. No. per Line" = TRUE
        Initialize();

        for VendorIndex := 1 to ArrayLen(Vendor) do begin
            LibraryPurchase.CreateVendor(Vendor[VendorIndex]);
            for DocIndex := 1 to ArrayLen(PurchaseHeader) do begin
                Clear(PurchaseHeader[DocIndex]);
                LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader[DocIndex], Vendor[VendorIndex]."No.");
                LibraryPurchase.PostPurchaseDocument(PurchaseHeader[DocIndex], true, true);
            end;
        end;

        CreateNoSeriesWithIncrementByNo(NoSeriesLine, 10, 'A0001', 'A9999');
        LibraryERM.FindBankAccount(BankAccount);
        SetupGenJournalLineForSuggestVendorPayments(GenJournalLine, NoSeriesLine);

        LibraryVariableStorage.Enqueue(StrSubstNo(OrFilterStringTxt, Vendor[1]."No.", Vendor[2]."No."));
        LibraryVariableStorage.Enqueue(NoSeriesLine."Starting No.");
        LibraryVariableStorage.Enqueue(false); // Summarize - FALSE
        LibraryVariableStorage.Enqueue(true); // New Doc. No. per Line - TRUE
        LibraryVariableStorage.Enqueue(BankAccount."No.");

        SuggestVendorPaymentForGenJournal(GenJournalLine);

        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Document No.", 'A0001');
        GenJournalLine.TestField("Account No.", Vendor[1]."No.");

        GenJournalLine.Next();
        GenJournalLine.TestField("Document No.", 'A0011');
        GenJournalLine.TestField("Account No.", Vendor[1]."No.");

        GenJournalLine.Next();
        GenJournalLine.TestField("Document No.", 'A0021');
        GenJournalLine.TestField("Account No.", Vendor[2]."No.");

        GenJournalLine.Next();
        GenJournalLine.TestField("Document No.", 'A0031');
        GenJournalLine.TestField("Account No.", Vendor[2]."No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CreatePaymentWithPostingModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreateAndPostPaymentAndRefundForInvoiceAndCreeditMemoViaCreatePaymentPage()
    var
        Vendor: array[2] of Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccount: Record "Bank Account";
        PaymentJournal: TestPage "Payment Journal";
        IndexDoc: Integer;
        IndexVendor: Integer;
        CountPerVendor: Integer;
    begin
        // [FEATURE] [Create Payment] [Applicaition] [Invoice] [Payment] [Credit Memo] [Refund]
        // [SCENARIO 351229] Stan can create and post payments and refunds for several vendors and several invoices and credit memos.
        Initialize();

        GenJournalLine.DeleteAll();
        CountPerVendor := 2;

        for IndexVendor := 1 to ArrayLen(Vendor) do begin
            LibraryPurchase.CreateVendor(Vendor[IndexVendor]);
            for IndexDoc := 1 to CountPerVendor do begin
                LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor[IndexVendor]."No.");
                LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
                CreatePurchaseCreditMemoForVendorNo(PurchaseHeader, Vendor[IndexVendor]."No.");
                LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
            end;
        end;

        LibraryERM.FindBankAccount(BankAccount);

        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(WorkDate());

        PaymentJournal.Trap();

        VendorLedgerEntry.SetFilter("Vendor No.", '%1|%2', Vendor[1]."No.", Vendor[2]."No.");
        InvokeCreatePayment(VendorLedgerEntry);

        for IndexVendor := 1 to ArrayLen(Vendor) do begin
            PaymentJournal."Account No.".AssertEquals(Vendor[IndexVendor]."No.");
            PaymentJournal."Document Type".AssertEquals(GenJournalLine."Document Type"::Payment);
            PaymentJournal.Next();
            PaymentJournal."Account No.".AssertEquals(Vendor[IndexVendor]."No.");
            PaymentJournal."Document Type".AssertEquals(GenJournalLine."Document Type"::Refund);
            PaymentJournal.Next();
        end;
        PaymentJournal.Close();

        for IndexVendor := 1 to ArrayLen(Vendor) do begin
            GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
            GenJournalLine.SetRange("Account No.", Vendor[IndexVendor]."No.");
            GenJournalLine.FindSet();
            GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Payment);
            GenJournalLine.Next();
            GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Refund);
        end;
        GenJournalLine.SetRange("Account No.");
        Assert.RecordCount(GenJournalLine, 4);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        VendorLedgerEntry.SetRange(Open, false);
        Assert.RecordCount(VendorLedgerEntry, 6 * ArrayLen(Vendor)); // (2(Invoice) + 1(Payment) + 2(Credit Memo) + 1(Refund)) * 2(No. of Vendors) = 6 * 2 = 12

        VerifyAppliedVendorLedgerEntries(
          Vendor[1], VendorLedgerEntry."Document Type"::Invoice, VendorLedgerEntry."Document Type"::Payment, 2);
        VerifyAppliedVendorLedgerEntries(
          Vendor[2], VendorLedgerEntry."Document Type"::Invoice, VendorLedgerEntry."Document Type"::Payment, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,PickReportModalPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestPaymentNewSavedReportOption()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        ObjectOptions: Record "Object Options";
        ReportSettings: TestPage "Report Settings";
        ParameterName: Text[50];
    begin
        // [FEATURE] [Object Options]
        // [SCENARIO 357515] Create new saved report option for Suggest Vendor Payment Report
        Initialize();

        // [GIVEN] Report option is saved for the report 'Suggest Vendor Payment' for selected General Journal
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryVariableStorage.Enqueue(LibraryPurchase.CreateVendorNo());
        LibraryVariableStorage.Enqueue(LibraryERM.CreateGLAccountNo());
        LibraryVariableStorage.Enqueue(false);
        ParameterName := LibraryUtility.GenerateGUID();

        // request page is opened again when new object option is created
        LibraryVariableStorage.Enqueue(ParameterName);
        LibraryVariableStorage.Enqueue(LibraryPurchase.CreateVendorNo());
        LibraryVariableStorage.Enqueue(LibraryERM.CreateGLAccountNo());
        LibraryVariableStorage.Enqueue(false);
        Commit();

        SuggestVendorPaymentFromJournalBatch(GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
        ObjectOptions.SetRange("Object Type", ObjectOptions."Object Type"::Report);
        ObjectOptions.SetRange("Object ID", REPORT::"Suggest Vendor Payments");
        Assert.RecordIsNotEmpty(ObjectOptions);

        // [GIVEN] 'Report Settings' page is opened
        ReportSettings.OpenEdit();

        // [WHEN] Invoke 'New' on the 'Report settings' page for the 'Suggest Vendor Payment' report
        ReportSettings.NewSettings.Invoke();

        // [THEN] New saved report option is created
        ObjectOptions.SetRange("Parameter Name", ParameterName);
        Assert.RecordIsNotEmpty(ObjectOptions);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetStartingDocumentNo()
    var
        GenJournalBatch: array[3] of Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        CreatePayment: TestPage "Create Payment";
    begin
        // [FEATURE] [UI] [Create Payment]
        // [SCENARIO 357623] System populates next series no. in "Starting Document No." field on "Create Payment" page when specified batch has specified "No. Series"
        Initialize();

        CreateGenJournalBatchWithNoSeries(GenJournalBatch[1], GenJournalTemplate.Type::Payments, 'A0001', 'A9999');
        CreateGenJournalBatchWithNoSeries(GenJournalBatch[2], GenJournalTemplate.Type::Payments, 'B0001', 'B9999');
        CreateGeneralJournalBatch(GenJournalBatch[3], GenJournalTemplate.Type::Payments);
        GenJournalBatch[3].TestField("No. Series", '');

        CreatePayment.OpenEdit();
        CreatePayment."Template Name".SetValue(GenJournalBatch[2]."Journal Template Name");
        CreatePayment."Batch Name".SetValue(GenJournalBatch[2].Name);
        CreatePayment."Posting Date".AssertEquals(WorkDate());
        CreatePayment."Starting Document No.".AssertEquals('B0001');
        CreatePayment."Posting Date".SetValue(WorkDate() - 1);
        CreatePayment."Starting Document No.".AssertEquals('');
        CreatePayment."Starting Document No.".SetValue(LibraryUtility.GenerateGUID());
        CreatePayment.OK().Invoke();

        CreatePayment.OpenEdit();

        CreatePayment."Template Name".AssertEquals(GenJournalBatch[2]."Journal Template Name");
        CreatePayment."Batch Name".AssertEquals(GenJournalBatch[2].Name);
        CreatePayment."Starting Document No.".AssertEquals('B0001');
        CreatePayment."Template Name".SetValue(GenJournalBatch[1]."Journal Template Name");
        CreatePayment."Batch Name".SetValue(GenJournalBatch[1].Name);
        CreatePayment."Starting Document No.".AssertEquals('A0001');
        CreatePayment."Template Name".SetValue(GenJournalBatch[3]."Journal Template Name");
        CreatePayment."Batch Name".SetValue(GenJournalBatch[3].Name);
        CreatePayment."Starting Document No.".AssertEquals('');

        CreatePayment.Close();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsUseDueDateAsPostingDateRPH')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentUseDueDateActivityOnRequestPage()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        // [FEATURE] [UI] [REPORT]
        // [SCENARIO 370135] Switching UseDueDateAsPostingDate to TRUE enables DueDateOffset field and disables PostingDate field
        Initialize();

        // [GIVEN] Created and posted Gen. Journal Line
        CreateAndPostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Document Type"::Invoice, -1);

        // [WHEN] Run Report "Suggest Vendor Payment" for this Gen. Journal Line
        // [THEN] PostingDate is not editable, DueDateOffset is enabled and editable on RPH
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");
        SuggestVendorPayments.Run();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsUseDueDateAsPostingDateAndFindPaymentDiscountsRequestPageHandler')]
    procedure SuggestVendorPaymentUseDueDateAsPostingDateAndFindPaymentDiscount()
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        GenJournalLineWithPaymentDiscount: Record "Gen. Journal Line";
        GenJournalLineWithoutPaymentDiscount: Record "Gen. Journal Line";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
        DueDate, PaymentDiscountDate : Date;
    begin
        // [FEATURE] [UI] [REPORT]
        // [SCENARIO] Suggesting vendor payments with both UseDueDateAsPostingDate and FindPaymentDiscount set to TRUE
        Initialize();

        // [GIVEN] Created and posted vendor invoice with due date for vendor without payment discount
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLineWithoutPaymentDiscount, GenJournalLineWithoutPaymentDiscount."Document Type"::Invoice, GenJournalLineWithoutPaymentDiscount."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), -LibraryRandom.RandDec(100, 2));
        DueDate := CalcDate('<+1M>', GenJournalLineWithoutPaymentDiscount."Posting Date");
        GenJournalLineWithoutPaymentDiscount.Validate("Due Date", DueDate);
        GenJournalLineWithoutPaymentDiscount.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLineWithoutPaymentDiscount);

        // [GIVEN] Created and posted vendor invoice with due date for vendor with payment discount
        CreatePaymentTermsWithDiscount(PaymentTerms);
        CreateVendorWithPaymentTerms(Vendor, PaymentTerms.Code);
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLineWithPaymentDiscount, GenJournalLineWithPaymentDiscount."Document Type"::Invoice, GenJournalLineWithPaymentDiscount."Account Type"::Vendor, Vendor."No.", -LibraryRandom.RandDec(100, 2));
        PaymentDiscountDate := GenJournalLineWithPaymentDiscount."Pmt. Discount Date";
        LibraryERM.PostGeneralJnlLine(GenJournalLineWithPaymentDiscount);

        // [WHEN] Run Report "Suggest Vendor Payment" for the invoice without payment discount
        SuggestVendorPayments.SetGenJnlLine(GenJournalLineWithoutPaymentDiscount);
        LibraryVariableStorage.Enqueue(GenJournalLineWithoutPaymentDiscount."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLineWithoutPaymentDiscount."Document No.");
        LibraryVariableStorage.Enqueue(DueDate);
        SuggestVendorPayments.Run();

        // [THEN] The payment line is created with due date as posting date
        VerifyDocumentNoAndPostingDateOnGeneralJournal(GenJournalLineWithoutPaymentDiscount."Account No.", GenJournalLineWithoutPaymentDiscount."Document No.", DueDate);

        // [WHEN] Run Report "Suggest Vendor Payment" for the invoice with payment discount
        SuggestVendorPayments.SetGenJnlLine(GenJournalLineWithPaymentDiscount);
        LibraryVariableStorage.Enqueue(GenJournalLineWithPaymentDiscount."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLineWithPaymentDiscount."Document No.");
        LibraryVariableStorage.Enqueue(PaymentDiscountDate);
        SuggestVendorPayments.Run();

        // [THEN] The payment line is created with payment discount date as posting date
        VerifyDocumentNoAndPostingDateOnGeneralJournal(GenJournalLineWithPaymentDiscount."Account No.", GenJournalLineWithPaymentDiscount."Document No.", PaymentDiscountDate);
    end;


    [Test]
    [HandlerFunctions('CreatePaymentModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyAppliesToidforBlockedVendorPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        VendorNoFilter: Text[40];
    begin
        // [SCENARIO 440630] The Applies-to ID does not get removed in certain circumstances if you get an error during the Create Payment routine.
        Initialize();

        // [GIVEN] Create Gen Journal Template and Batch.
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::Payments);
        GenJournalTemplate.Get(GenJournalBatch."Journal Template Name");

        // [GIVEN] Created and posted Vendor's invoice
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor,
          LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Bal. Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(),
          -LibraryRandom.RandDecInRange(10, 100, 2));

        // [THEN] Modify the Posting Date of First Vendor.
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Modify();

        // [THEN] Modify Vendor Status to Blocked Payment
        VendorNoFilter := GenJournalLine."Account No.";
        Vendor.Get(VendorNoFilter);
        Vendor.Validate(Blocked, Vendor.Blocked::Payment);
        Vendor.Modify();

        // [THEN] Post Fisrt vendor Ledger Entry with blocked Payment.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Created 2nd Vendor's invoice
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor,
          LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Bal. Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(),
          -LibraryRandom.RandDecInRange(10, 100, 2));

        // [THEN] Saveboth Vendor in a variable.
        VendorNoFilter := VendorNoFilter + '|' + GenJournalLine."Account No.";

        // [THEN] Post 2nd Vendor Ledger entry with block Status "".
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Open VEndor LEdger Entries page and Create Payment.
        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.FILTER.SetFilter("Vendor No.", VendorNoFilter);

        // [VERIFY] Vendor Payment blocked for Vendor 1 error will come.
        asserterror VendorLedgerEntries."Create Payment".Invoke();

        // [VERIFY] Vendor Ledger entry of blocked vendor have blank Applies-To ID.
        VendorLedgerEntry.SetFilter("Vendor No.", Vendor."No.");
        VendorLedgerEntry.FindFirst();
        Assert.AreEqual('', VendorLedgerEntry."Applies-to ID", AppliesToIdErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDocNoWhenBalAccNoIsBlankOnSuggestVendorPayment()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorNo: Code[20];
        VendorNo2: Code[20];
        NoOfLines: Integer;
        DocumentNo: Code[20];
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 441558] Document No. on payment Journals from 'Suggest Vendor Payments' is different even if New Doc. No. per Line is No
        Initialize();

        // [GIVEN] Create GenJournal Batch  and bank account
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        BankAccountNo := SetupAndCreateGenJournalLines(GenJournalLine, GenJournalBatch);

        // [GIVEN] Create two vendors and multiple invoices.
        VendorNo := GenJournalLine."Account No.";
        NoOfLines := 2 * LibraryRandom.RandInt(5);
        VendorNo2 := CreateVendor(GenJournalLine."Currency Code", Vendor."Application Method"::"Apply to Oldest");
        CreateMultipleGenJournalLine(
          GenJournalLine, GenJournalBatch, NoOfLines, WorkDate(), VendorNo2,
          GenJournalLine."Document Type"::Invoice, -1);

        // [THEN] Create Document No. and save in a variable.
        DocumentNo := Format(LibraryRandom.RandInt(100));

        // [THEN] Post the invoices.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create General Journal Batch for posting payment.
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);

        // [THEN] Suggest vendor payment with saved document no
        SuggestVendorPaymentWithDocNo(
          GenJournalBatch, VendorNo, VendorNo2, CalcDate('2Y', WorkDate()), false, GenJournalLine."Bal. Account Type"::"Bank Account", '',
          GenJournalLine."Bank Payment Type"::" ", false, DocumentNo);

        // [VERIFY] Verfiy Document No. on general journal line.
        VerifySameDocumentNoOnGenJournal(VendorNo, DocumentNo);
        VerifySameDocumentNoOnGenJournal(VendorNo2, DocumentNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentSummarizedWithAllDifferentRemitAddress()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RemitAddress: array[3] of Record "Remit Address";
        Amount: array[3] of Decimal;
        VendorNo: Code[20];
        BankAccountNo: Code[20];
    begin
        // [SCENARIO] Suggest Payment with Summarized option enable when working with three invoices with different remit addresses.
        Initialize();

        // [GIVEN] A Vendor with three different remit addresses
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreateRemitToAddress(RemitAddress[1], VendorNo);
        LibraryPurchase.CreateRemitToAddress(RemitAddress[2], VendorNo);
        LibraryPurchase.CreateRemitToAddress(RemitAddress[3], VendorNo);

        // [GIVEN] Three posted Vendor invoices with remit address of "RA 1" = Code1, "RA 2" = Code2 and "RA 3" = Code3
        PostInvoiceWithProvidedVendorAndRemitAddress(VendorNo, BankAccountNo, Amount[1], RemitAddress[1].Code);
        PostInvoiceWithProvidedVendorAndRemitAddress(VendorNo, BankAccountNo, Amount[2], RemitAddress[2].Code);
        PostInvoiceWithProvidedVendorAndRemitAddress(VendorNo, BankAccountNo, Amount[3], RemitAddress[3].Code);

        // [GIVEN] Payment Journal Batch with Template
        PreparePaymentJournalBatch(GenJournalBatch, BankAccountNo);

        // [WHEN] Suggest Vendor Payment for Vendor creates three payment journal lines
        SuggestVendorPayment(
          GenJournalBatch, VendorNo, WorkDate(), false,
          GenJournalLine."Bal. Account Type"::"Bank Account",
          GenJournalBatch."Bal. Account No.", "Bank Payment Type"::" ", true);

        // [THEN] First Payment journal line created with amount from "RA 1"
        VerifySuggestedLineWithAmount(GenJournalBatch."Journal Template Name", GenJournalBatch.Name, Amount[1]);

        // [THEN] Second Payment journal line created with amount from "RA 2"
        VerifySuggestedLineWithAmount(GenJournalBatch."Journal Template Name", GenJournalBatch.Name, Amount[2]);

        // [THEN] Third Payment journal line created with amount from "RA 3"
        VerifySuggestedLineWithAmount(GenJournalBatch."Journal Template Name", GenJournalBatch.Name, Amount[2]);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentSummarizedWithSameRemitAddress()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RemitAddress: Record "Remit Address";
        Amount: array[3] of Decimal;
        VendorNo: Code[20];
        BankAccountNo: Code[20];
    begin
        // [SCENARIO] Suggest Payment with Summarized option enable when working with three invoices with same remit addresses.
        Initialize();

        // [GIVEN] A Vendor with one remit addresses
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreateRemitToAddress(RemitAddress, VendorNo);

        // [GIVEN] Three posted Vendor invoices with the same remit address
        PostInvoiceWithProvidedVendorAndRemitAddress(VendorNo, BankAccountNo, Amount[1], RemitAddress.Code);
        PostInvoiceWithProvidedVendorAndRemitAddress(VendorNo, BankAccountNo, Amount[2], RemitAddress.Code);
        PostInvoiceWithProvidedVendorAndRemitAddress(VendorNo, BankAccountNo, Amount[3], RemitAddress.Code);

        // [GIVEN] Payment Journal Batch with Template
        PreparePaymentJournalBatch(GenJournalBatch, BankAccountNo);

        // [WHEN] Suggest Vendor Payment for Vendor creates one payment journal lines
        SuggestVendorPayment(
          GenJournalBatch, VendorNo, WorkDate(), false,
          GenJournalLine."Bal. Account Type"::"Bank Account",
          GenJournalBatch."Bal. Account No.", "Bank Payment Type"::" ", true);

        // [THEN] First Payment journal line created with summarize amount from "RA 1", "RA 2" and "RA 3"
        VerifySuggestedLineWithAmount(GenJournalBatch."Journal Template Name", GenJournalBatch.Name, Amount[1] + Amount[2] + Amount[3]);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentSummarizedWithMultipleRemitAddress()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RemitAddress: array[2] of Record "Remit Address";
        Amount: array[3] of Decimal;
        VendorNo: Code[20];
        BankAccountNo: Code[20];
    begin
        // [SCENARIO] Suggest Payment with Summarized option enable when working with three invoices. Only some share the same remit address.
        Initialize();

        // [GIVEN] A Vendor with two different remit addresses
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreateRemitToAddress(RemitAddress[1], VendorNo);
        LibraryPurchase.CreateRemitToAddress(RemitAddress[2], VendorNo);

        // [GIVEN] Three posted Vendor invoices with remit address of "RA 1" = Code1, "RA 2" = Code2 and "RA 3" = Code1
        PostInvoiceWithProvidedVendorAndRemitAddress(VendorNo, BankAccountNo, Amount[1], RemitAddress[1].Code);
        PostInvoiceWithProvidedVendorAndRemitAddress(VendorNo, BankAccountNo, Amount[2], RemitAddress[2].Code);
        PostInvoiceWithProvidedVendorAndRemitAddress(VendorNo, BankAccountNo, Amount[3], RemitAddress[1].Code);

        // [GIVEN] Payment Journal Batch with Template
        PreparePaymentJournalBatch(GenJournalBatch, BankAccountNo);

        // [WHEN] Suggest Vendor Payment for Vendor creates two payment journal lines
        SuggestVendorPayment(
          GenJournalBatch, VendorNo, WorkDate(), false,
          GenJournalLine."Bal. Account Type"::"Bank Account",
          GenJournalBatch."Bal. Account No.", "Bank Payment Type"::" ", true);

        // [THEN] First Payment journal line created with summarize amount from "RA 1" and "RA 3"
        VerifySuggestedLineWithAmount(GenJournalBatch."Journal Template Name", GenJournalBatch.Name, Amount[1] + Amount[3]);

        // [THEN] Second Payment journal line created with amount from "RA 2"
        VerifySuggestedLineWithAmount(GenJournalBatch."Journal Template Name", GenJournalBatch.Name, Amount[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsNewDocNoPerLine()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorNo: Code[20];
        VendorNo2: Code[20];
        NoOfLines: Integer;
        DocumentNo: Code[20];
    begin
        // [SCENARIO 471718] Document No. on payment Journals from 'Suggest Vendor Payments' is different even if New Doc. No. per Line is No
        Initialize();

        // [GIVEN] Create General Journal Batch 
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);

        // [GIVEN] Create First Vendor
        VendorNo := CreateVendor(GenJournalLine."Currency Code", Vendor."Application Method"::"Apply to Oldest");

        // [GIVEN] Create No. of General Journal Lines and save in a variable.
        NoOfLines := 2 * LibraryRandom.RandInt(5);

        // [GIVEN] Create Multiple Invoices for First Vendor
        CreateMultipleGenJournalLine(
            GenJournalLine,
            GenJournalBatch,
            NoOfLines,
            WorkDate(),
            VendorNo,
            GenJournalLine."Document Type"::Invoice,
            -1);

        // [GIVEN] Create Second Vendor
        VendorNo2 := CreateVendor(GenJournalLine."Currency Code", Vendor."Application Method"::"Apply to Oldest");

        // [GIVEN] Create Multiple Invoices for Second Vendor
        CreateMultipleGenJournalLine(
            GenJournalLine,
            GenJournalBatch,
            NoOfLines,
            WorkDate(),
            VendorNo2,
            GenJournalLine."Document Type"::Invoice,
            -1);

        // [THEN] Create Document No. and save in a variable.
        DocumentNo := Format(LibraryRandom.RandInt(100));

        // [THEN] Post the invoices.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create General Journal Batch for posting payment.
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);

        // [THEN] Suggest Vendor Payment with saved Document No and both vendors.
        SuggestVendorPaymentWithDocNo(
            GenJournalBatch,
            VendorNo,
            VendorNo2,
            CalcDate('2Y', WorkDate()),
            false,
            GenJournalLine."Bal. Account Type"::"Bank Account",
            '',
            GenJournalLine."Bank Payment Type"::" ",
            true,
            DocumentNo);

        // [VERIFY] Verfiy Document No. on General Journal Line for both vendors.
        VerifySameDocumentNoOnGenJournal(VendorNo, DocumentNo);
        VerifySameDocumentNoOnGenJournal(VendorNo2, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue,GetSpecificLineFromTemlateListHandler')]
    procedure AppliesToIDShouldRemovedWhenPaymentAmountSetToZeroBySuggestVendorPayment()
    var
        Vendor: Record Vendor;
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralJournalTemplate: Record "Gen. Journal Template";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
        PaymentJournal: TestPage "Payment Journal";
        PaymentAmount: Decimal;
        PageIDUpdated: Integer;
    begin
        // [SCENARIO 522685] Applies-to ID not removed from payment journal when more than one line is applied and line amount is changed to 0
        Initialize();

        // [GIVEN] set new vendor, batch and posting amounts
        Vendor.Get(CreateVendor('', Vendor."Application Method"::Manual));
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);

        // [GIVEN] Create and Post General Journal Lines with Document Type as Invoice
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, WorkDate(), Vendor."No.", GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandDec(1000, 2));
        PaymentAmount := -GenJournalLine.Amount;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Clear(GenJournalLine);

        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, WorkDate(), Vendor."No.", GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandDec(1000, 2));
        if -GenJournalLine.Amount < PaymentAmount then
            PaymentAmount := -GenJournalLine.Amount;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] prepare payment amount which is lower then smallest amount from invoices
        PaymentAmount := PaymentAmount * LibraryUtility.GenerateRandomFraction();

        // [GIVEN] Suggest Vendor Payments
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);

        Vendor.SetRange("No.", Vendor."No.");
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.SetTableView(Vendor);
        SuggestVendorPayments.UseRequestPage(false);
        SuggestVendorPayments.InitializeRequest(WorkDate(), false, 0, true, WorkDate(), LibraryRandom.RandText(5), true, GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No.", GenJournalLine."Bank Payment Type");
        SuggestVendorPayments.RunModal();

        GeneralJournalTemplate.SetRange(Name, GenJournalBatch."Journal Template Name");
        GeneralJournalTemplate.FindFirst();
        if GeneralJournalTemplate."Page ID" <> 256 then begin
            PageIDUpdated := GeneralJournalTemplate."Page ID";
            GeneralJournalTemplate."Page ID" := 256;
            GeneralJournalTemplate.Modify();
        end;

        // [WHEN] Open Payment Journal
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.Last();

        // [THEN] Vendor Ledger entries should have "Applies-to ID" set
        VendorLedgerEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive, "Due Date");
        VendorLedgerEntry.SetRange("Vendor No.", PaymentJournal."Account No.".Value);
        VendorLedgerEntry.SetRange("Applies-to ID", PaymentJournal."Document No.".Value);
        Assert.AreEqual(false, VendorLedgerEntry.IsEmpty(), AppliesToIDNotSetErr);

        // [WHEN] Update amount on payment line (to be zero)
        PaymentJournal.Amount.SetValue(0);
        PaymentJournal.Close();

        // [THEN] System should remove "Applies-to ID" from all VendLedgerEntries
        Assert.AreEqual(true, VendorLedgerEntry.IsEmpty(), AppliesToIDNotRemovedErr);
    end;

    local procedure Initialize()
    var
        ObjectOptions: Record "Object Options";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Suggest Vendor Payment");
        ClearSelectedDim();
        LibraryVariableStorage.Clear();
        ObjectOptions.DeleteAll();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Suggest Vendor Payment");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGenJournalTemplate();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Suggest Vendor Payment");
    end;

    local procedure AddRandomDaysToWorkDate(): Date
    begin
        exit(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
    end;

    local procedure ApplyPaymentToVendor(AccountNo: Code[20]; NumberOfLines: Integer; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        FindVendorLedgerEntry(VendorLedgerEntry, AccountNo, DocumentType2);
        FindVendorLedgerEntry(VendorLedgerEntry2, AccountNo, DocumentType);
        repeat
            VendorLedgerEntry2.Validate("Amount to Apply", -VendorLedgerEntry.Amount / NumberOfLines);
            VendorLedgerEntry2.Modify(true);
        until VendorLedgerEntry2.Next() = 0;
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);
    end;

    local procedure ApplyGenJnlLineEntryToInvoice(var GenJournalLine: Record "Gen. Journal Line"; InvoiceNo: Code[20])
    begin
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CheckGenJnlLineAfterSuggestVendorPayment(Limit: Decimal; NoOfPayment: Integer; SecondInvoiceAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // Setup: Create vendor and Create and post Gen journal line with document type invoice.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostMultipleGenJnlLine(GenJournalLine, Vendor."No.", LibraryRandom.RandIntInRange(15, 20), SecondInvoiceAmount);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        LibraryVariableStorage.Enqueue(Limit);

        // Exercise: Run report suggest vendor payment
        SuggestVendorPaymentUsingPage(GenJournalLine);

        // Verify:
        VerifyAmountDoesNotExceedLimit(GenJournalLine, Limit, NoOfPayment);
    end;

    local procedure CreateAndPostMultipleGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; FirstInvoiceAmount: Decimal; SecondInvoiceAmount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, WorkDate(), VendorNo, GenJournalLine."Document Type"::Invoice,
          -FirstInvoiceAmount);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, WorkDate(), VendorNo, GenJournalLine."Document Type"::Invoice,
          -SecondInvoiceAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; TemplateType: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, TemplateType);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreatePaymentLineAppliedToCrMemoCustomer(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; PaymentAmount: Decimal; CrMemoNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        CreatePaymentLineWithAppliedTo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, CustomerNo,
          GenJournalLine."Applies-to Doc. Type"::"Credit Memo", CrMemoNo, PaymentAmount, LibraryERM.CreateGLAccountNo());
    end;

    local procedure CreatePaymentLineAppliedToCrMemoVendor(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; PaymentAmount: Decimal; CrMemoNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        CreatePaymentLineWithAppliedTo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Applies-to Doc. Type"::"Credit Memo", CrMemoNo, PaymentAmount, LibraryERM.CreateGLAccountNo());
    end;

    local procedure CreatePaymentLineWithAppliedTo(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; ApplnDocType: Enum "Gen. Journal Document Type"; ApplnDocNo: Code[20]; PaymentAmount: Decimal; BalAccountNo: Code[20])
    begin
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, AccountType, AccountNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", BalAccountNo, PaymentAmount);
        GenJournalLine.Validate("Applies-to Doc. Type", ApplnDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", ApplnDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateBalancedPaymentWithApplication(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; InvNo: Code[20]; CrMemoNo: Code[20]; PaymentAmt: array[2] of Decimal)
    var
        BankAccount: Record "Bank Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentNo: Code[20];
    begin
        PaymentNo := LibraryUtility.GenerateGUID();
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        CreatePaymentLineWithAppliedTo(
          GenJournalLine, GenJournalBatch, AccountType, AccountNo,
          GenJournalLine."Applies-to Doc. Type"::Invoice, InvNo, PaymentAmt[1], '');
        GenJournalLine."Document No." := PaymentNo;
        GenJournalLine.Modify();

        CreatePaymentLineWithAppliedTo(
          GenJournalLine, GenJournalBatch, AccountType, AccountNo,
          GenJournalLine."Applies-to Doc. Type"::"Credit Memo", CrMemoNo, PaymentAmt[2], '');
        GenJournalLine."Document No." := PaymentNo;
        GenJournalLine.Modify();

        if (PaymentAmt[1] + PaymentAmt[2]) <> 0 then begin
            GenJournalLine."Line No." += 10000;
            GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"Bank Account");
            LibraryERM.FindBankAccount(BankAccount);
            GenJournalLine.Validate("Account No.", BankAccount."No.");
            GenJournalLine.Validate(Amount, -(PaymentAmt[1] + PaymentAmt[2]));
            GenJournalLine.Validate("Applies-to Doc. No.", '');
            GenJournalLine.Insert();
        end;
    end;

    local procedure CreateInvoiceAndCreditMemoEntryForVendor(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Take Random Amout for Invoice and Amount greater than Invoice Amount for Credit Memo. Adding 1 to make amount larger than Invoice Amount.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandDec(100, 2));
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Vendor, VendorNo, -GenJournalLine.Amount + 1);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; GenJournalTemplateType: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Type := GenJournalTemplateType;
        GenJournalTemplate.Modify();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGenJournalBatchWithNoSeries(var GenJournalBatch: Record "Gen. Journal Batch"; GenJournalTemplateType: Enum "Gen. Journal Template Type"; StartingNo: Code[20]; EndingNo: Code[20])
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        CreateGenJournalBatch(GenJournalBatch, GenJournalTemplateType);

        CreateNoSeriesWithIncrementByNo(NoSeriesLine, 1, StartingNo, EndingNo);

        GenJournalBatch.Validate("No. Series", NoSeriesLine."Series Code");
        GenJournalBatch.Modify(true);
    end;

    local procedure CreatePaymentTermsWithDiscount(var PaymentTerms: Record "Payment Terms")
    begin
        // Input any random Due Date, Discount Date Calculation and Discount %.
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(10)) + 'M>');
        Evaluate(PaymentTerms."Discount Date Calculation", '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        PaymentTerms.Validate("Due Date Calculation", PaymentTerms."Due Date Calculation");
        PaymentTerms.Validate("Discount Date Calculation", PaymentTerms."Discount Date Calculation");
        PaymentTerms.Validate("Discount %", LibraryRandom.RandDec(99, 2));
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify(true);
    end;

    local procedure CreateVendorWithPriority(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Priority, 1);
        Vendor.Modify();
        exit(Vendor."No.");
    end;

    local procedure CreateVendor(CurrencyCode: Code[10]; ApplicationMethod: Enum "Application Method"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Application Method", ApplicationMethod);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithPaymentBlocked(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Blocked, Vendor.Blocked::Payment);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithPaymentTerms(var Vendor: Record Vendor; PaymentTermsCode: Code[10])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Modify(true);
    end;

    local procedure CreateVendWithDimensions(var VendNo: Code[20]; var DimSetID: Integer)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        VendNo := LibraryPurchase.CreateVendorNo();
        GLSetup.Get();
        DimSetID :=
          LibraryDimension.CreateDimSet(
            0, GLSetup."Global Dimension 1 Code",
            CreateDefDimWithFoundDimValue(GLSetup."Global Dimension 1 Code", DATABASE::Vendor, VendNo));
        DimSetID :=
          LibraryDimension.CreateDimSet(
            DimSetID, GLSetup."Global Dimension 2 Code",
            CreateDefDimWithFoundDimValue(GLSetup."Global Dimension 2 Code", DATABASE::Vendor, VendNo));
    end;

    local procedure CreateBankAccount(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        BankAccountPostingGroup.FindFirst();
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateMultipleGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; NumberOfLines: Integer; PostingDate: Date; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; AmountSign: Integer) AmountSum: Integer
    var
        Counter: Integer;
    begin
        for Counter := 1 to NumberOfLines do begin
            // Required value for Amount field is not important
            CreateGeneralJournalLine(
              GenJournalLine, GenJournalBatch, PostingDate, VendorNo, DocumentType, AmountSign * LibraryRandom.RandInt(100));
            AmountSum := AmountSum + GenJournalLine.Amount;
        end;
    end;

    local procedure CreateAndPostGeneralJournal(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type") DocumentNo: Code[20]
    var
        Vendor: Record Vendor;
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, WorkDate(), Vendor."No.", DocumentType, -LibraryRandom.RandDec(100, 2));
        DocumentNo := GenJournalLine."Document No.";

        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, WorkDate(), Vendor."No.", DocumentType, GenJournalLine.Amount * 2);
        UpdateOnHoldOnGenJournalLine(GenJournalLine, GetOnHold());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20];
                                                                                                                     DocumentType: Enum "Gen. Journal Document Type";
                                                                                                                     Sign: Integer)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, DocumentType, AccountType, AccountNo, Sign * LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        GenJournalLine.Validate("Document No.", GenJournalBatch.Name + Format(GenJournalLine."Line No."));
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePostGenJnlLineRunSuggestVendorPayments(var GenJournalLine: Record "Gen. Journal Line"; var ShortcutDim1Code: Code[20])
    var
        VendorNo: Code[20];
        ShortcutDim2Code: Code[20];
    begin
        VendorNo := CreateGenJnlLineWithVendorBalAcc(GenJournalLine);
        LibraryVariableStorage.Enqueue(VendorNo);
        UpdateDimensionOnGeneralJournalLine(GenJournalLine);
        ShortcutDim1Code := GenJournalLine."Shortcut Dimension 1 Code";
        ShortcutDim2Code := GenJournalLine."Shortcut Dimension 2 Code";
        UpdateDiffDimensionOnVendor(VendorNo, ShortcutDim1Code, ShortcutDim2Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        SetupGenJnlLine(GenJournalLine);
        SuggestVendorPaymentUsingPage(GenJournalLine);
        FindGeneralJournalLines(GenJournalLine);
    end;

    local procedure CreatePostGenJnlLineWithCurrency(VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; CurrencyCode: Code[10];
                                                                                           LineAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, DocumentType, GenJournalLine."Account Type"::Vendor, VendorNo, -LineAmount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateDefDimWithFoundDimValue(DimensionCode: Code[20]; TableID: Integer; VendorNo: Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, TableID, VendorNo, DimensionValue."Dimension Code", DimensionValue.Code);
        exit(DimensionValue.Code);
    end;

    local procedure CreatePostVendorEntryWithMsgToRecipient(var VendorLedgerEntry: Record "Vendor Ledger Entry"; MsgToRecipient: Text[140])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), -LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        VendorLedgerEntry.Validate("Message to Recipient", MsgToRecipient);
        VendorLedgerEntry.Modify(true);
    end;

    local procedure CreateVendorWithDimension(var DefaultDimension: Record "Default Dimension"; ValuePosting: Enum "Default Dimension Value Posting Type"; DimensionCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        if DimensionCode = '' then
            exit(Vendor."No.");
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, Vendor."No.", DimensionCode, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", ValuePosting);
        DefaultDimension.Modify(true);

        exit(Vendor."No.");
    end;

    local procedure CreateNoSeriesWithIncrementByNo(var NoSeriesLine: Record "No. Series Line"; IncrementByNo: Integer; StartingNo: Code[20]; EndingNo: Code[20])
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Get(LibraryERM.CreateNoSeriesCode());
        NoSeriesLine.SetRange("Series Code", NoSeries.Code);
        NoSeriesLine.FindFirst();
        NoSeriesLine."Starting Date" := WorkDate();
        NoSeriesLine."Starting No." := StartingNo;
        NoSeriesLine."Ending No." := EndingNo;
        NoSeriesLine."Increment-by No." := IncrementByNo;
        NoSeriesLine.Modify();
    end;

    procedure CreatePurchaseCreditMemoForVendorNo(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure GetOnHold(): Code[3]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        exit(
          CopyStr(
            LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("On Hold"), DATABASE::"Gen. Journal Line"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("On Hold"))));
    end;

    local procedure FindAndPostPaymentJournalLine(GenJournalBatch: Record "Gen. Journal Batch"): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindSet();
    end;

    local procedure PrepareThreePaymentJournalBatches(var GenJournalBatch: array[3] of Record "Gen. Journal Batch"; BankAccountNo: Code[20])
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(GenJournalBatch) do
            PreparePaymentJournalBatch(GenJournalBatch[i], BankAccountNo);
    end;

    local procedure PreparePaymentJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; BankAccountNo: Code[20])
    var
        DummyGenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, DummyGenJournalTemplate.Type::Payments);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccountNo);
        GenJournalBatch.Modify(true);
    end;

    local procedure PostCreditMemoVendor(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; CrMemoAmount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Purchases);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), CrMemoAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostCreditMemoCustomer(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; CrMemoAmount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Sales);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer, CustomerNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), CrMemoAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure SetupAndCreateGenJournalLines(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch") BankAccountNo: Code[20]
    var
        Vendor: Record Vendor;
        VendorNo: Code[20];
        CurrencyCode: Code[10];
        NoOfLines: Integer;
    begin
        // Setup: Create Currency, Bank Account, Vendor and General Journal Lines.
        CurrencyCode := CreateCurrency();
        BankAccountNo := CreateBankAccount(CurrencyCode);

        // Create 2 to 10 Gen. Journal Lines Boundary 2 is important to test Suggest Vendor Payment for multiple lines.
        NoOfLines := 2 * LibraryRandom.RandInt(5);
        VendorNo := CreateVendor(CurrencyCode, Vendor."Application Method"::"Apply to Oldest");
        CreateMultipleGenJournalLine(
          GenJournalLine, GenJournalBatch, NoOfLines, WorkDate(), VendorNo, GenJournalLine."Document Type"::Invoice, -1);
    end;

    local procedure SetupGenJournalLineForSuggestVendorPayments(var GenJournalLine: Record "Gen. Journal Line"; NoSeriesLine: Record "No. Series Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("No. Series", NoSeriesLine."Series Code");
        GenJournalBatch.Modify(true);

        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
    end;

    local procedure SuggestVendorPayment(GenJournalBatch: Record "Gen. Journal Batch"; VendorNo: Code[20]; LastPaymentDate: Date; FindPaymentDiscounts: Boolean; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20];
                                                                                                                                                                                     BankPaymentType: Enum "Bank Payment Type";
                                                                                                                                                                                     SummarizePerVendor: Boolean)
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        GenJournalLine.Init();  // INIT is mandatory for Gen. Journal Line to Set the General Template and General Batch Name.
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);

        if VendorNo = '' then
            Vendor.SetRange("No.")
        else
            Vendor.SetRange("No.", VendorNo);
        SuggestVendorPayments.SetTableView(Vendor);

        // Required Random Value for "Document No." field value is not important.
        SuggestVendorPayments.InitializeRequest(
          LastPaymentDate, FindPaymentDiscounts, 0, false, LastPaymentDate, Format(LibraryRandom.RandInt(100)),
          SummarizePerVendor, BalAccountType, BalAccountNo, BankPaymentType);
        SuggestVendorPayments.UseRequestPage(false);
        SuggestVendorPayments.RunModal();
    end;

    local procedure SuggestVendorPaymentUsingPage(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        GenJournalLine.Init();  // INIT is mandatory for Gen. Journal Line to Set the General Template and General Batch Name.
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);

        Commit();  // Commit required to avoid test failure.
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");

        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.Run();
    end;

    local procedure SuggestVendorPaymentsEnqueueValues(ActionType: Option Update,Verify; PostingDate: Date; LastPaymentDate: Date; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(ActionType);
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(LastPaymentDate);
        LibraryVariableStorage.Enqueue(BalAccountType);
        LibraryVariableStorage.Enqueue(BalAccountNo);
    end;

    local procedure SuggestVendorPaymentForGenJournal(var GenJournalLine: Record "Gen. Journal Line")
    var
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        Commit();
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.Run();
    end;

    local procedure UpdateOnHoldOnGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; OnHold: Code[3])
    begin
        GenJournalLine.Validate("On Hold", OnHold);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20])
    begin
        FindGeneralJournalLines(GenJournalLine);
        GenJournalLine.ModifyAll("Bal. Account Type", GenJournalLine."Bal. Account Type"::Vendor, true);
        GenJournalLine.ModifyAll("Bal. Account No.", VendorNo, true);
        UpdateDimensionOnGeneralJournalLine(GenJournalLine);
    end;

    local procedure UpdateDimensionOnGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get();
        FindGeneralJournalLines(GenJournalLine); // Find General Journal Line to update Dimension on first record.
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 1 Code");
        GenJournalLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        LibraryDimension.FindDimensionValue(DimensionValue2, GeneralLedgerSetup."Shortcut Dimension 2 Code");
        GenJournalLine.Validate("Shortcut Dimension 2 Code", DimensionValue2.Code);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateDiffDimensionOnVendor(VendorNo: Code[20]; GlobalDimValueCode1: Code[20]; GlobalDimValueCode2: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DefaultDimension: Record "Default Dimension";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Vendor, VendorNo, GeneralLedgerSetup."Shortcut Dimension 1 Code",
          LibraryDimension.FindDifferentDimensionValue(GeneralLedgerSetup."Shortcut Dimension 1 Code", GlobalDimValueCode1));
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Vendor, VendorNo, GeneralLedgerSetup."Shortcut Dimension 2 Code",
          LibraryDimension.FindDifferentDimensionValue(GeneralLedgerSetup."Shortcut Dimension 2 Code", GlobalDimValueCode2));
    end;

    local procedure ClearSelectedDim()
    var
        SelectedDim: Record "Selected Dimension";
    begin
        SelectedDim.SetRange("User ID", UserId);
        SelectedDim.SetRange("Object Type", 3);
        SelectedDim.SetRange("Object ID", REPORT::"Suggest Vendor Payments");
        SelectedDim.DeleteAll(true);
    end;

    local procedure CreateGeneralJournalWithAccountTypeGLAccount(var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Create General Journal Lines & Take Random Amount for Invoice.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, LibraryRandom.RandDec(100, 2));
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Document No.", IncStr(GenJournalLine."Document No."));
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJnlLineWithVendorBalAcc(var GenJournalLine: Record "Gen. Journal Line"): Code[20]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDecInRange(10, 1000, 2));
        LibraryPurchase.CreateVendor(Vendor);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::Vendor);
        GenJournalLine.Validate("Bal. Account No.", Vendor."No.");
        GenJournalLine.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure FindGeneralJournalLines(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.FindSet();
    end;

    local procedure FindGeneralJournalLineFromBatchAndAmount(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatchName: Code[10]; GenJournaTemplateName: Code[10]; ExpectedAmount: Decimal)
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournaTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
        GenJournalLine.SetRange(Amount, ExpectedAmount);
        GenJournalLine.FindFirst();
    end;

    local procedure GetDimensionFilterText(): Text
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionSelectionBuffer: Record "Dimension Selection Buffer";
    begin
        GeneralLedgerSetup.Get();
        DimensionSelectionBuffer.SetFilter(Code, '%1|%2', GeneralLedgerSetup."Shortcut Dimension 1 Code", GeneralLedgerSetup."Shortcut Dimension 2 Code");
        exit(DimensionSelectionBuffer.GetFilter(Code));
    end;

    local procedure GetVendDefaultDim(VendNo: Code[20]; DimensionCode: Code[20]): Code[20]
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.Get(DATABASE::Vendor, VendNo, DimensionCode);
        exit(DefaultDimension."Dimension Value Code");
    end;

    local procedure InvokeCreatePayment(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJnlManagement: Codeunit GenJnlManagement;
        CreatePayment: Page "Create Payment";
    begin
        // Simulate invocation of "Create Payment" action button on "Vendor Ledger Entries" page
        if CreatePayment.RunModal() = ACTION::OK then begin
            CreatePayment.MakeGenJnlLines(VendorLedgerEntry);
            GenJournalBatch.Get(CreatePayment.GetTemplateName(), CreatePayment.GetBatchNumber());
            GenJnlManagement.TemplateSelectionFromBatch(GenJournalBatch);
        end;
        Clear(CreatePayment);
    end;

    local procedure CopyTempGenJournalLine(GenJournalLine: Record "Gen. Journal Line"; var GenJournalLine2: Record "Gen. Journal Line")
    begin
        FindGeneralJournalLines(GenJournalLine);
        repeat
            GenJournalLine2 := GenJournalLine;
            GenJournalLine2.Insert();
        until GenJournalLine.Next() = 0;
    end;

    local procedure PostThreeInvoicesForVendor(var VendorNo: Code[20]; var BankAccountNo: Code[20]; var Amount: array[3] of Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        i: Integer;
    begin
        VendorNo := LibraryPurchase.CreateVendorNo();
        BankAccountNo := LibraryERM.CreateBankAccountNo();
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::General);
        for i := 1 to ArrayLen(Amount) do begin
            Amount[i] := LibraryRandom.RandDec(1000, 2);
            LibraryJournals.CreateGenJournalLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
              GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, VendorNo,
              GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo, -Amount[i]);
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure RemoveNonrelatedAmounts(GenJournalTemplateName: Code[10]; GenJournalBatchName: Code[10]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
        GenJournalLine.SetFilter(Amount, '<>%1', Amount);
        GenJournalLine.DeleteAll();
    end;

    local procedure VerifyAmountDoesNotExceedLimit(GenJournalLine: Record "Gen. Journal Line"; Limit: Integer; NoOfPayment: Integer)
    var
        SuggestVendorGenJnlLine: Record "Gen. Journal Line";
    begin
        SuggestVendorGenJnlLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        SuggestVendorGenJnlLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        SuggestVendorGenJnlLine.CalcSums(Amount);
        if Limit <> 0 then
            Assert.IsTrue(SuggestVendorGenJnlLine.Amount <= Limit, SuggestVendorAmountErr);
        Assert.AreEqual(NoOfPayment, SuggestVendorGenJnlLine.Count, NoOfPaymentErr);
    end;

    local procedure VerifyGenJournalEntriesAmount(VendorNo: Code[20])
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Assert: Codeunit Assert;
        TotalAmountLCY: Decimal;
    begin
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Account No.", VendorNo);
        GenJournalLine.FindFirst();
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry.CalcFields("Amount (LCY)");
            TotalAmountLCY += Abs(VendorLedgerEntry."Amount (LCY)");
        until VendorLedgerEntry.Next() = 0;

        Currency.Get(GenJournalLine."Currency Code");
        Assert.AreNearlyEqual(
          TotalAmountLCY, GenJournalLine."Amount (LCY)", Currency."Amount Rounding Precision",
          StrSubstNo(AmountErrorMessageMsg, GenJournalLine.FieldCaption("Amount (LCY)"),
            TotalAmountLCY, GenJournalLine."Journal Template Name",
            GenJournalLine."Journal Batch Name", GenJournalLine."Line No."));
    end;

    local procedure VerifyJournalLinesNotSuggested(JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.Init();
        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        Assert.RecordIsEmpty(GenJournalLine);
    end;

    local procedure VerifyRemainingOnVendorLedger(VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry.CalcFields("Remaining Amount");
            VendorLedgerEntry.TestField("Remaining Amount", 0);
        until VendorLedgerEntry.Next() = 0;
    end;

    local procedure VerifyVendorLedgerEntry(VendorNo: Code[20]; VendorLedgerEntryCount: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetFilter("Applies-to ID", '<>''''');
        Assert.RecordCount(VendorLedgerEntry, VendorLedgerEntryCount);
    end;

    local procedure VerifyValuesOnVendLedgerEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20];
                                                                                          Amount2: Decimal;
                                                                                          RemainingAmount: Decimal;
                                                                                          Open2: Boolean;
                                                                                          OnHold: Code[3])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount, "Remaining Amount");
        Assert.AreNearlyEqual(Amount2, VendorLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidateErrorErr, VendorLedgerEntry.FieldCaption(Amount), Amount2, VendorLedgerEntry.TableCaption(), VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));
        VendorLedgerEntry.TestField("Remaining Amount", RemainingAmount);
        VendorLedgerEntry.TestField(Open, Open2);
        VendorLedgerEntry.TestField("On Hold", OnHold);
    end;

    local procedure VerifyValuesOnGLEntry(GenJournalLine: Record "Gen. Journal Line"; ShortcutDimension1Code: Code[20]; ShortcutDimension2Code: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange(Description, GenJournalLine.Description);
        GLEntry.SetRange("Global Dimension 1 Code", ShortcutDimension1Code);
        GLEntry.SetRange("Global Dimension 2 Code", ShortcutDimension2Code);
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Document Type", GLEntry."Document Type"::Invoice);
            GLEntry.TestField("Global Dimension 1 Code", ShortcutDimension1Code);
            GLEntry.TestField("Global Dimension 2 Code", ShortcutDimension2Code);
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyDimensionOnGeneralJournalLine(GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; GLAccountNo: Code[20])
    var
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        GenJournalLine2.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine2.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine2.TestField("Shortcut Dimension 1 Code", '');
        GenJournalLine2.TestField("Shortcut Dimension 2 Code", '');
        GenJournalLine2.FindLast();
        GenJournalLine2.TestField("Account Type", GenJournalLine2."Account Type"::Vendor);
        GenJournalLine2.TestField("Account No.", VendorNo);
        GenJournalLine2.TestField("Bal. Account Type", GenJournalLine2."Bal. Account Type"::"G/L Account");
        GenJournalLine2.TestField("Bal. Account No.", GLAccountNo);
    end;

    local procedure VerifyDimensionOnGeneralJournalLineFromInvoice(GenJournalLine: Record "Gen. Journal Line"; DimValue1Code: Code[20]; DimValue2Code: Code[20])
    var
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        GenJournalLine2.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine2.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine2.FindLast();
        GenJournalLine2.TestField("Shortcut Dimension 1 Code", DimValue1Code);
        GenJournalLine2.TestField("Shortcut Dimension 2 Code", DimValue2Code);
    end;

    local procedure VerifyDimOnGeneralJournalLineSummarizePerVend(FirstDim: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        ShortcutDim1Code: Code[20];
        ShortcutDim2Code: Code[20];
    begin
        Initialize();
        CreatePostGenJnlLineRunSuggestVendorPayments(GenJournalLine, ShortcutDim1Code);
        GetDefaultVendGlobalDimCode(ShortcutDim1Code, ShortcutDim2Code, GenJournalLine."Account No.", FirstDim);
        VerifyDimensionOnGeneralJournalLineFromInvoice(GenJournalLine, ShortcutDim1Code, ShortcutDim2Code);
        VerifyMessageToRecipientSummarizePerVendor(GenJournalLine); // TFS 225334
    end;

    local procedure GetDefaultVendGlobalDimCode(var ShortcutDim1Code: Code[20]; var ShortcutDim2Code: Code[20]; AccountNo: Code[20]; FirstDim: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if FirstDim then
            ShortcutDim2Code := ''
        else begin
            GLSetup.Get();
            ShortcutDim1Code := GetVendDefaultDim(AccountNo, GLSetup."Global Dimension 1 Code");
            ShortcutDim2Code := GetVendDefaultDim(AccountNo, GLSetup."Global Dimension 2 Code");
        end;
    end;

    local procedure VerifyGenJnlLineDimSetID(GenJnlBatch: Record "Gen. Journal Batch"; VendNo: Code[20]; DimSetID: Integer)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.SetRange("Account No.", VendNo);
        GenJnlLine.FindFirst();
        Assert.AreEqual(DimSetID, GenJnlLine."Dimension Set ID", GenJnlLine.FieldCaption("Dimension Set ID"));
    end;

    local procedure VerifyMessageToRecipientSummarizePerVendor(var GenJournalLine: Record "Gen. Journal Line")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        GenJournalLine.TestField("Message to Recipient", CompanyInformation.Name);
    end;

    local procedure VerifyMessageToRecipientStandard(var GenJournalLine: Record "Gen. Journal Line"; BatchName: Code[10]; ExpectedMessage: Text)
    begin
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Message to Recipient", ExpectedMessage);
    end;

    local procedure VerifyExpectedErrorMessageLine(var ErrorMessages: TestPage "Error Messages"; GenJournalTemplateName: Code[10]; GenJournalBatchName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Assert.ExpectedMessage(
          StrSubstNo(PaymentsLineErr,
            GenJournalLine.FieldCaption("Journal Template Name"),
            GenJournalTemplateName,
            GenJournalLine.FieldCaption("Journal Batch Name"),
            GenJournalBatchName,
            GenJournalLine.FieldCaption("Applies-to Doc. No."), ''),
          Format(ErrorMessages.Description.Value));
    end;

    local procedure VerifySuggestedLineWithAmount(GenJournalTemplateName: Code[10]; GenJournalBatchName: Code[10]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FindGeneralJournalLineFromBatchAndAmount(GenJournalLine, GenJournalBatchName, GenJournalTemplateName, Amount);
        Assert.RecordIsNotEmpty(GenJournalLine);
    end;

    local procedure VerifyOnlySuggestedLineWithAmount(GenJournalTemplateName: Code[10]; GenJournalBatchName: Code[10]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FindGeneralJournalLineFromBatchAndAmount(GenJournalLine, GenJournalBatchName, GenJournalTemplateName, Amount);
        Assert.RecordIsNotEmpty(GenJournalLine);
        GenJournalLine.SetFilter(Amount, '<>%1', Amount);
        Assert.RecordIsEmpty(GenJournalLine);
    end;

    local procedure VerifyTwoPaymentEntriesFullyClosed(GenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        Assert.RecordCount(VendorLedgerEntry, 2);
        VendorLedgerEntry.Find('-');
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", 0);
        VendorLedgerEntry.Next();
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", 0);
    end;

    local procedure VerifyVenderLedgerEntryFullyClosed(DocumentNo: Code[20]; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        Assert.RecordCount(VendorLedgerEntry, 1);
        VendorLedgerEntry.Find('-');
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", 0);
    end;

    local procedure VerifyAppliedVendorLedgerEntries(Vendor: Record Vendor; ApplyingDocumentType: Enum "Gen. Journal Document Type"; AppliedDocumentType: Enum "Gen. Journal Document Type";
                                                                                                      ApplyingDocCount: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntryApplied: Record "Vendor Ledger Entry";
        ApplyingAmount: Decimal;
    begin
        // Verify 1 Payment to 2 Invoices full application
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.SetRange("Document Type", ApplyingDocumentType);

        Assert.RecordCount(VendorLedgerEntry, ApplyingDocCount);

        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry.CalcFields(Amount);
            VendorLedgerEntry.TestField(Amount);
            ApplyingAmount += VendorLedgerEntry.Amount;
        until VendorLedgerEntry.Next() = 0;

        VendorLedgerEntryApplied.Copy(VendorLedgerEntry);
        VendorLedgerEntryApplied.SetRange("Document Type", AppliedDocumentType);

        Assert.RecordCount(VendorLedgerEntryApplied, 1);

        VendorLedgerEntryApplied.FindFirst();
        VendorLedgerEntryApplied.CalcFields(Amount);
        VendorLedgerEntryApplied.TestField(Amount, -ApplyingAmount);
    end;

    local procedure SaveGeneralTemplates(var GenJournalTemplate: Record "Gen. Journal Template"; var ToGenJournalTemplate: Record "Gen. Journal Template")
    begin
        GenJournalTemplate.FindSet();
        repeat
            ToGenJournalTemplate.Init();
            ToGenJournalTemplate := GenJournalTemplate;
            ToGenJournalTemplate.Insert();
        until GenJournalTemplate.Next() = 0;
    end;

    local procedure RestoreGeneralTemplates(var FromGenJournalTemplate: Record "Gen. Journal Template"; var GenJournalTemplate: Record "Gen. Journal Template")
    begin
        FromGenJournalTemplate.FindSet();
        repeat
            GenJournalTemplate.Init();
            GenJournalTemplate := FromGenJournalTemplate;
            GenJournalTemplate.Insert();
        until FromGenJournalTemplate.Next() = 0;
    end;

    local procedure VerifySameDocumentNoOnGenJournal(VendorNo: Text[100]; DocumentNo: Code[20])
    begin
        VerifyDocumentNoAndPostingDateOnGeneralJournal(VendorNo, DocumentNo, 0D)
    end;

    local procedure VerifyDocumentNoAndPostingDateOnGeneralJournal(VendorNo: Text[100]; DocumentNo: Code[20]; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Account No.", VendorNo);
        GenJournalLine.FindSet();
        repeat
            Assert.AreEqual(DocumentNo, GenJournalLine."Document No.", GenJournalLine.FieldCaption("Document No."));
            if PostingDate <> 0D then
                Assert.AreEqual(PostingDate, GenJournalLine."Posting Date", GenJournalLine.FieldCaption("Posting Date"));
        until GenJournalLine.Next() = 0;
    end;

    local procedure SuggestVendorPaymentWithDocNo(
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorNo: Code[20];
        VendorNo2: Code[20];
        LastPaymentDate: Date;
        FindPaymentDiscounts: Boolean;
        BalAccountType: Enum "Gen. Journal Account Type";
        BalAccountNo: Code[20];
        BankPaymentType: Enum "Bank Payment Type";
        SummarizePerVendor: Boolean;
        FirstDocNo: Code[20])
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        GenJournalLine.Init();  // INIT is mandatory for Gen. Journal Line to Set the General Template and General Batch Name.
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);

        Vendor.Setfilter("No.", '%1|%2', VendorNo, VendorNo2);
        SuggestVendorPayments.SetTableView(Vendor);

        // Required Random Value for "Document No." field value is not important.
        SuggestVendorPayments.InitializeRequest(
          LastPaymentDate, FindPaymentDiscounts, 0, false, LastPaymentDate, FirstDocNo,
          SummarizePerVendor, BalAccountType, BalAccountNo, BankPaymentType);
        SuggestVendorPayments.UseRequestPage(false);
        SuggestVendorPayments.RunModal();
    end;

    local procedure PostInvoiceWithProvidedVendorAndRemitAddress(var VendorNo: Code[20]; var BankAccountNo: Code[20]; var Amount: Decimal; RemitAddressNo: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        BankAccountNo := LibraryERM.CreateBankAccountNo();
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::General);
        Amount := LibraryRandom.RandDec(1000, 2);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo, -Amount);
        GenJournalLine.Validate("Remit-to Code", RemitAddressNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue,GetSpecificLineFromTemlateListHandler')]
    procedure CheckRemovedAppliesToIDWhenPaymentBySuggestVendorPayment()
    var
        Vendor: Record Vendor;
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralJournalTemplate: Record "Gen. Journal Template";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
        PaymentJournal: TestPage "Payment Journal";
        PaymentAmount: Decimal;
        PageIDUpdated: Integer;
    begin
        // [FEATURE] [Payment Journal], [Vendor Ledger Entry], [Applied-to ID]
        // [SCENARIO 467514] When posting a Payment Journal the Applies-to ID, is not removed when a partial Amount is posted
        Initialize();

        // [GIVEN] set new vendor, batch and posting amounts
        Vendor.Get(CreateVendor('', Vendor."Application Method"::Manual));
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);

        // [GIVEN] Create and Post General Journal Lines with Document Type as Invoice
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, WorkDate(), Vendor."No.", GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandDec(1000, 2));
        PaymentAmount := -GenJournalLine.Amount;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Clear(GenJournalLine);

        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, WorkDate(), Vendor."No.", GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandDec(1000, 2));
        if -GenJournalLine.Amount < PaymentAmount then
            PaymentAmount := -GenJournalLine.Amount;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] prepare payment amount which is lower then smallest amount from invoices
        PaymentAmount := PaymentAmount * LibraryUtility.GenerateRandomFraction();

        // [GIVEN] Suggest Vendor Payments
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);

        Vendor.SetRange("No.", Vendor."No.");
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.SetTableView(Vendor);
        SuggestVendorPayments.UseRequestPage(false);
        SuggestVendorPayments.InitializeRequest(WorkDate(), false, 0, true, WorkDate(), LibraryRandom.RandText(5), true, GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No.", GenJournalLine."Bank Payment Type");
        SuggestVendorPayments.RunModal();

        GeneralJournalTemplate.SetRange(Name, GenJournalBatch."Journal Template Name");
        GeneralJournalTemplate.FindFirst();
        if GeneralJournalTemplate."Page ID" <> 256 then begin
            PageIDUpdated := GeneralJournalTemplate."Page ID";
            GeneralJournalTemplate."Page ID" := 256;
            GeneralJournalTemplate.Modify();
        end;

        // [WHEN] Open Payment Journal
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.Last();

        // [THEN] Vendor Ledger entries should have "Applies-to ID" set
        VendorLedgerEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive, "Due Date");
        VendorLedgerEntry.SetRange("Vendor No.", PaymentJournal."Account No.".Value);
        VendorLedgerEntry.SetRange("Applies-to ID", PaymentJournal."Document No.".Value);
        Assert.AreEqual(false, VendorLedgerEntry.IsEmpty(), 'Applied-to ID is not set on Vendor Ledger Entry');

        // [WHEN] Update amount on payment line (to be lower)
        PaymentJournal.Amount.SetValue(PaymentAmount);
        PaymentJournal.Close();

        // [THEN] System should remove "Applies-to ID" from all VendLedgerEntries
        Assert.AreEqual(true, VendorLedgerEntry.IsEmpty(), 'Applied-to ID is not removed on Vendor Ledger Entry');

        if PageIDUpdated <> 0 then begin
            GeneralJournalTemplate.Get(GenJournalBatch."Journal Template Name");
            GeneralJournalTemplate."Page ID" := PageIDUpdated;
            GeneralJournalTemplate.Modify();
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SuggestVendorPmtsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPmtsShouldCreateGenJnlLinesInSelectedBatchWhenUseSavedValuesInRequestPage()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
        VendorNo: Code[20];
        BankAccountNo: Code[20];
        JournalBatchName: Code[10];
        JournalBatchName2: Code[10];
    begin
        // [SCENARIO 495872] Suggest Vendor Payments going to different Batches
        Initialize();

        // [GIVEN] Generate and save Bank Account No. in a Variable.
        BankAccountNo := LibraryERM.CreateBankAccountNo();

        // [GIVEN] Create and Post Gen Journal Line.
        CreateAndPostGeneralJournalLine(
            GenJournalLine,
            GenJournalLine."Account Type"::Vendor,
            LibraryPurchase.CreateVendorNo(),
            GenJournalLine."Document Type"::Invoice,
            -LibraryRandom.RandInt(0));

        // [GIVEN] Save Journal Batch Name and Vendor No. in a Variable.
        JournalBatchName := GenJournalLine."Journal Batch Name";
        VendorNo := GenJournalLine."Account No.";

        // [GIVEN] Run Suggest Vendor Payments Report for Gen Journal Line.
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account Type"::"Bank Account");
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        SuggestVendorPayments.Run();

        // [WHEN] Find the generated Gen Journal Line.
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Account No.", VendorNo);
        GenJournalLine.FindFirst();

        // [VERIFY] Verify JournalBatchName and Gen Journal Line Journal Batch Name are same.
        Assert.AreEqual(
            JournalBatchName,
            GenJournalLine."Journal Batch Name",
            StrSubstNo(JournalBatchNameErr, JournalBatchName, GenJournalLine.TableCaption()));

        // [GIVEN] Create and Post Gen Journal Line 2.
        CreateAndPostGeneralJournalLine(
            GenJournalLine2,
            GenJournalLine2."Account Type"::Vendor,
            LibraryPurchase.CreateVendorNo(),
            GenJournalLine2."Document Type"::Invoice,
            -LibraryRandom.RandInt(0));

        // [GIVEN] Save Journal Batch Name and Vendor No. in a Variable.
        JournalBatchName2 := GenJournalLine2."Journal Batch Name";
        VendorNo := GenJournalLine2."Account No.";

        // [GIVEN] Run Suggest Vendor Payments Report for Gen Journal Line 2,
        // with Gen Journal Line Request Page saved values.
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine2);
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(GenJournalLine2."Bal. Account Type"::"Bank Account");
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        SuggestVendorPayments.Run();

        // [WHEN] Find the generated Gen Journal Line 2.
        GenJournalLine2.SetRange("Journal Batch Name", GenJournalLine2."Journal Batch Name");
        GenJournalLine2.SetRange("Journal Template Name", GenJournalLine2."Journal Template Name");
        GenJournalLine2.SetRange("Account No.", VendorNo);
        GenJournalLine2.FindFirst();

        // [VERIFY] Verify JournalBatchName2 and Gen Journal Line 2 Journal Batch Name are same.
        Assert.AreEqual(
            JournalBatchName2,
            GenJournalLine2."Journal Batch Name",
            StrSubstNo(JournalBatchNameErr, JournalBatchName2, GenJournalLine2.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentForRefundUsingSummarizePerVenodr()
    var
        Vendor: Record Vendor;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 495872] Journal Lines will not be suggested by Suggest Vendor Payments routine if Summarize per Vendor is enabled.
        Initialize();

        // [GIVEN] Create a vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Journal Batch using Journal Template General.
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);

        // [GIVEN] Create Journal Line using Document Type Refund.
        CreateGeneralJournalLine(
            GenJournalLine,
            GenJournalBatch,
            WorkDate(),
            Vendor."No.",
            GenJournalLine."Document Type"::Refund,
            -LibraryRandom.RandDec(100, 2));

        // [GIVEN] Post the General Journal line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create a General Journal Batch using Journal Template Payments.
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);

        // [GIVEN] Suggest Vendor Payment is invoked with Summarize Per Vendor set to true.
        SuggestVendorPayment(
            GenJournalBatch,
            GenJournalLine."Account No.",
            AddRandomDaysToWorkDate(),
            true,
            GenJournalLine."Account Type"::"G/L Account",
            GenJournalLine."Bal. Account No.",
            GenJournalLine."Bank Payment Type"::" ",
            true);

        // [GIVEN] Get the value of Document No. of Suggested Line. 
        DocumentNo := FindAndPostPaymentJournalLineRefund(GenJournalBatch);

        // [THEN] The General Journal line should not be created.
        Assert.AreEqual(DocumentNo, '', SuggestToVendorRefundErr);
    end;

    local procedure FindAndPostPaymentJournalLineRefund(GenJournalBatch: Record "Gen. Journal Batch"): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        if GenJournalLine.FindFirst() then
            exit(GenJournalLine."Document No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetSpecificLineFromTemlateListHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.Filter.SetFilter(Name, LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateList.Last();
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Message: Text[1024]; var Response: Boolean)
    begin
        Response := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Message: Text[1024]; var Response: Boolean)
    begin
        Response := false;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    begin
        SuggestVendorPayments.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.BalAccountNo.SetValue(LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.LastPaymentDate.SetValue(WorkDate());
        SuggestVendorPayments.UseVendorPriority.SetValue(LibraryVariableStorage.DequeueBoolean());
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));  // Setting a Random Document No., value is not important.
        SuggestVendorPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsWithDimensionRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    begin
        SuggestVendorPayments.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.LastPaymentDate.SetValue(WorkDate());
        SuggestVendorPayments.SummarizePerVendor.SetValue(true);
        SuggestVendorPayments.SummarizePerDimText.AssistEdit();
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));  // Setting a Random Document No., value is not important.
        SuggestVendorPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsWithDimensionAndBalAccRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    begin
        SuggestVendorPayments.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.LastPaymentDate.SetValue(WorkDate());
        SuggestVendorPayments.SummarizePerVendor.SetValue(true);
        SuggestVendorPayments.SummarizePerDimText.AssistEdit();
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));  // Setting a Random Document No., value is not important.
        SuggestVendorPayments.BalAccountNo.SetValue(LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.OK().Invoke();
    end;

    local procedure SuggestVendorPaymentFromJournalBatch(GenJournalTemplateName: Code[10]; GenJournalBatchName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", GenJournalTemplateName);
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatchName);
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.Run();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectDimensionHandlerOnSuggesvendorPayment(var DimensionSelectionMultiple: TestPage "Dimension Selection-Multiple")
    begin
        DimensionSelectionMultiple.FILTER.SetFilter(Code, GetDimensionFilterText());
        DimensionSelectionMultiple.First();
        repeat
            DimensionSelectionMultiple.Selected.SetValue(true);
        until not DimensionSelectionMultiple.Next();
        DimensionSelectionMultiple.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectNoDimensionHandlerOnSuggesvendorPayment(var DimensionSelectionMultiple: TestPage "Dimension Selection-Multiple")
    begin
        DimensionSelectionMultiple.FILTER.SetFilter(Code, GetDimensionFilterText());
        DimensionSelectionMultiple.First();
        repeat
            DimensionSelectionMultiple.Selected.SetValue(false);
        until not DimensionSelectionMultiple.Next();
        DimensionSelectionMultiple.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectFirstDimensionHandlerOnSuggesvendorPayment(var DimensionSelectionMultiple: TestPage "Dimension Selection-Multiple")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionSelectionBuffer: Record "Dimension Selection Buffer";
    begin
        GeneralLedgerSetup.Get();
        DimensionSelectionBuffer.SetRange(Code, GeneralLedgerSetup."Shortcut Dimension 1 Code");
        DimensionSelectionMultiple.FILTER.SetFilter(Code, DimensionSelectionBuffer.GetFilter(Code));
        DimensionSelectionMultiple.First();
        DimensionSelectionMultiple.Selected.SetValue(true);
        DimensionSelectionMultiple.OK().Invoke();
    end;

    local procedure SetupGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        GenJournalLine.Init();  // INIT is mandatory for Gen. Journal Line to Set the General Template and General Batch Name.
        GenJournalLine.Validate("Journal Template Name", GenJournalTemplate.Name);
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsWithoutBalAccountRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    begin
        SuggestVendorPayments.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.LastPaymentDate.SetValue(WorkDate());
        SuggestVendorPayments.SummarizePerVendor.SetValue(false);
        SuggestVendorPayments.SummarizePerDimText.AssistEdit();
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));  // Setting a Random Document No., value is not important.
        SuggestVendorPayments.BalAccountNo.SetValue('');
        SuggestVendorPayments.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ClearDimensionHandlerOnSuggesvendorPayment(var DimensionSelectionMultiple: TestPage "Dimension Selection-Multiple")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionSelectionBuffer: Record "Dimension Selection Buffer";
    begin
        GeneralLedgerSetup.Get();
        DimensionSelectionBuffer.SetFilter(Code, '%1|%2', GeneralLedgerSetup."Shortcut Dimension 1 Code", GeneralLedgerSetup."Shortcut Dimension 2 Code");
        DimensionSelectionMultiple.FILTER.SetFilter(Code, DimensionSelectionBuffer.GetFilter(Code));
        DimensionSelectionMultiple.FILTER.SetFilter(Selected, 'yes');
        DimensionSelectionMultiple.First();
        repeat
            DimensionSelectionMultiple.Selected.SetValue(false);
        until not DimensionSelectionMultiple.Next();
        DimensionSelectionMultiple.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsWithAvailableAmtRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    begin
        SuggestVendorPayments.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.LastPaymentDate.SetValue(WorkDate());
        SuggestVendorPayments."Available Amount (LCY)".SetValue(LibraryVariableStorage.DequeueDecimal());
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));
        SuggestVendorPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsCheckUpdateValuesRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    var
        ActionType: Option Update,Verify;
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ActionType::Update:
                begin
                    SuggestVendorPayments.PostingDate.SetValue(LibraryVariableStorage.DequeueDate());
                    SuggestVendorPayments.LastPaymentDate.SetValue(LibraryVariableStorage.DequeueDate());
                    SuggestVendorPayments.BalAccountType.SetValue(LibraryVariableStorage.DequeueInteger());
                    SuggestVendorPayments.BalAccountNo.SetValue(LibraryVariableStorage.DequeueText());
                    SuggestVendorPayments.StartingDocumentNo.SetValue('1');
                    SuggestVendorPayments.Vendor.SetFilter("No.", '''''');
                    SuggestVendorPayments.OK().Invoke();
                end;
            ActionType::Verify:
                begin
                    SuggestVendorPayments.PostingDate.AssertEquals(LibraryVariableStorage.DequeueDate());
                    SuggestVendorPayments.LastPaymentDate.AssertEquals(LibraryVariableStorage.DequeueDate());
                    SuggestVendorPayments.BalAccountType.AssertEquals(LibraryVariableStorage.DequeueInteger());
                    SuggestVendorPayments.BalAccountNo.AssertEquals(LibraryVariableStorage.DequeueText());
                    SuggestVendorPayments.Cancel().Invoke();
                end;
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsRequestWithBnkPmtTypePageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    begin
        SuggestVendorPayments.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.BalAccountType.SetValue(LibraryVariableStorage.DequeueInteger());
        SuggestVendorPayments.BalAccountNo.SetValue(LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.BankPaymentType.SetValue(LibraryVariableStorage.DequeueInteger());
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));  // Setting a Random Document No., value is not important.
        SuggestVendorPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsCheckOtherBatchesRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    begin
        SuggestVendorPayments.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.LastPaymentDate.SetValue(WorkDate());
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));
        SuggestVendorPayments.CheckOtherJournalBatches.SetValue(LibraryVariableStorage.DequeueBoolean());
        SuggestVendorPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsStartingDocNoRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    begin
        SuggestVendorPayments.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.LastPaymentDate.SetValue(WorkDate());
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.SummarizePerVendor.SetValue(LibraryVariableStorage.DequeueBoolean());
        SuggestVendorPayments.NewDocNoPerLine.SetValue(LibraryVariableStorage.DequeueBoolean());
        SuggestVendorPayments.BalAccountType.SetValue(3);
        SuggestVendorPayments.BalAccountNo.SetValue(LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsUseDueDateAsPostingDateRPH(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    begin
        SuggestVendorPayments.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.UseDueDateAsPostingDate.SetValue(true);
        Assert.IsFalse(SuggestVendorPayments.PostingDate.Editable(), '');
        Assert.IsTrue(SuggestVendorPayments.DueDateOffset.Enabled(), '');
        Assert.IsTrue(SuggestVendorPayments.DueDateOffset.Editable(), '');
    end;

    [RequestPageHandler]
    procedure SuggestVendorPaymentsUseDueDateAsPostingDateAndFindPaymentDiscountsRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    begin
        SuggestVendorPayments.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.LastPaymentDate.SetValue(LibraryVariableStorage.DequeueDate());
        SuggestVendorPayments.UseDueDateAsPostingDate.SetValue(true);
        SuggestVendorPayments.FindPaymentDiscounts.SetValue(true);
        SuggestVendorPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPmtsRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    begin
        SuggestVendorPayments.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.BalAccountType.SetValue(LibraryVariableStorage.DequeueInteger());
        SuggestVendorPayments.BalAccountNo.SetValue(LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));
        SuggestVendorPayments.JournalTemplateName.SetValue(LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.JournalBatchName.SetValue(LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetLastLineFromTemlateListHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.Last();
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetFirstLineFromTemlateListHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.First();
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreatePaymentModalPageHandler(var CreatePayment: TestPage "Create Payment")
    begin
        CreatePayment."Template Name".SetValue(LibraryVariableStorage.DequeueText());
        CreatePayment."Batch Name".SetValue(LibraryVariableStorage.DequeueText());
        CreatePayment."Starting Document No.".SetValue(LibraryVariableStorage.DequeueText());
        CreatePayment.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreatePaymentWithPostingModalPageHandler(var CreatePayment: TestPage "Create Payment")
    var
        StartingDocumentNo: Text;
    begin
        StartingDocumentNo := LibraryVariableStorage.DequeueText();
        CreatePayment."Bank Account".SetValue(LibraryVariableStorage.DequeueText());
        CreatePayment."Posting Date".SetValue(LibraryVariableStorage.DequeueDate());
        CreatePayment."Starting Document No.".SetValue(StartingDocumentNo);
        CreatePayment.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PickReportModalPageHandler(var PickReport: TestPage "Pick Report")
    begin
        PickReport.Name.SetValue(LibraryVariableStorage.DequeueText());
        PickReport."Report ID".SetValue(REPORT::"Suggest Vendor Payments");
        PickReport.OK().Invoke();
    end;
}

