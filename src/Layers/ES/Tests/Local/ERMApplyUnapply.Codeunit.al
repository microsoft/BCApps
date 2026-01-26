codeunit 147310 "ERM Apply Unapply"
{
    // // [FEATURE] [Cartera]
    // 1. Test G/L Entry generated posting an Sales Invoice which creates Bills, create a single Payment,
    //    Apply Payment and Bill from Cust Ledger Entries, Unapply and Re-apply.
    // 2. Test G/L Entry generated posting an Sales Invoice which creates Bills, Apply with a Payment
    //    using "Applies-to Doc. No.", Unapply and Re-apply.
    // 3. Verify G/L Entry generated posting Invoice to Cartera, Converting it to Bill from Cartera Journal,
    //    create a single Payment, Apply Payment and Bill from Cust Ledger Entries, Unapply and Re-apply
    // 4. Test G/L Entry generated posting an Sales Invoice which creates Bills, Apply with a Payment
    //    using "Applies-to Doc. No.", Unapply, create Credit Memo and apply it to Bill.
    // 5. Test G/L Entry generated posting an Invoice which creates Bills, create a single Payment,
    //    Apply Payment and Bill from Vend Ledger Entries, Unapply and Re-apply
    // 6. Test G/L Entry generated posting an Purchase Invoice which creates Bills, Apply with a Payment
    //    using "Applies-to Doc. No.", Unapply and Re-apply.
    // 7. Verify G/L Entry generated posting Invoice to Cartera, Converting it to Bill from Cartera Journal,
    //    create a single Payment, Apply Payment and Bill from Vend Ledger Entries, Unapply and Re-apply
    // 8. Test G/L Entry generated posting an Purchase Invoice which creates Bills, Apply with a Payment
    //    using "Applies-to Doc. No.", Unapply, create Credit Memo and apply it to Bill.
    // 
    // Covers Test Cases for WI - 346852
    //   -----------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                          TFS ID
    //   -----------------------------------------------------------------------------------------------------
    //   ApplyUnapplyCustScenario2,ApplyUnapplyCustScenario3,ApplyUnapplyCustScenario4,
    //   ApplyUnapplyVendScenario2,ApplyUnapplyVendScenario3,ApplyUnapplyVendScenario4               346852
    // 
    // Covers Test Cases for WI - 353489
    //   -----------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                          TFS ID
    //   -----------------------------------------------------------------------------------------------------
    //   ApplyUnapplyVendScenarioCreditMemo,ApplyUnapplyVendScenarioCreditMemo                       353489

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryHR: Codeunit "Library - Human Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        ApplnTypeRef: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund,,,,,,,,,,,,,,,Bill;
        IsInitialized: Boolean;
        UnapplyBlankedDocTypeErr: Label 'You cannot unapply the entries because one entry has a blank document type.';
        UnAppliedErr: Label 'Entries are  still applied.';
        GLEntryMustBeFound: Label 'GL Entry must be found.';

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyCustScenario2()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
        TransactionNo: Integer;
    begin
        // [FEATURE] [Sales] [Unapply] [Reapply]
        // [SCENARIO 346852] Payment and a Bill posted then Applied, Unapplied Payment from the Bill, and Reapplied
        // [GIVEN] Sales Bill, Payment with Amount = "X"
        CustomerNo := CreateCustomer(true, '');
        CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, Amount);

        DocumentNo :=
          CreateAndPostGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer, CustomerNo, Amount);

        // [GIVEN] Bill Applied to Payment
        ApplySalesDocuments(
          CustLedgEntry."Document Type"::Payment, DocumentNo, CustLedgEntry."Document Type"::Bill, -Amount);
        TransactionNo := FindLastTransactionNo();

        // [GIVEN] Unapply Payment from the Bill
        UnapplySalesDocument(CustomerNo, DocumentNo);

        // [WHEN] Reapply Payment to the Bill
        ApplySalesDocuments(
          CustLedgEntry."Document Type"::Payment, DocumentNo, CustLedgEntry."Document Type"::Bill, -Amount);

        // [THEN] Reapply G/L Entries are posted to "Receivables Account" with Amount = "X", "Bills Account" with Amount = -"X"
        VerifyCustGLReapply(CustomerNo, DocumentNo, Amount, TransactionNo);
        // [THEN] Unapplication G/L Entries are posted to "Receivables Account" with 'Debit Amount' = -"X", "Bills Account" with 'Credit Amount' = -"X"
        VerifyCustGLUnapplication(CustomerNo, DocumentNo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyCustScenario3()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        DocumentNo: Code[20];
        TransactionNo: Integer;
        Amount: Decimal;
    begin
        // [FEATURE] [Sales] [Unapply] [Reapply]
        // [SCENARIO 346852] Payment and a Bill posted with apply, then Unapplied and Reapplied
        // [GIVEN] Sales Bill, Payment applied to the Bill with Amount = "X"
        CustomerNo := CreateCustomer(true, '');
        CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, Amount);
        InvoiceNo := FindLastPostedSalesDocumentBill(CustomerNo);
        DocumentNo :=
          CreatePostApplyGenJnlLine(GenJournalLine, InvoiceNo, '', GenJournalLine."Account Type"::Customer, CustomerNo, Amount);

        // [GIVEN] Unapply Payment from the Bill
        UnapplySalesDocument(CustomerNo, DocumentNo);
        TransactionNo := FindLastTransactionNo();

        // [WHEN] Reapply Payment to the Bill
        ApplySalesDocuments(
          CustLedgEntry."Document Type"::Payment, DocumentNo, CustLedgEntry."Document Type"::Bill, -Amount);

        // [THEN] Reapply G/L Entries are posted to "Receivables Account" with Amount = "X", "Bills Account" with Amount = -"X"
        VerifyCustGLReapply(CustomerNo, DocumentNo, Amount, TransactionNo);
        // [THEN] Unapplication G/L Entries are posted to "Receivables Account" with 'Debit Amount' = -"X", "Bills Account" with 'Credit Amount' = -"X"
        VerifyCustGLUnapplication(CustomerNo, DocumentNo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyCustScenario4()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
        TransactionNo: Integer;
    begin
        // [FEATURE] [Sales] [Reapply]
        // [SCENARIO 346852] Invoice posted, Payment with apply and a Bill posted via Cartera Jnl., Unapplied and Reapplied
        // [GIVEN] Sales Invoice with Amount = "X"
        CustomerNo := CreateCustomer(false, '');
        DocumentNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, Amount);

        // [GIVEN] Posted Cartera lines with a Payment that applied to Invoice, and a Bill
        CreateCarteraJournalLines(GenJournalLine, DocumentNo, GenJournalLine."Account Type"::Customer,
          CustomerNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        DocumentNo :=
          CreateAndPostGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        ApplySalesDocuments(
          CustLedgEntry."Document Type"::Payment, DocumentNo, CustLedgEntry."Document Type"::Bill, -Amount);

        // [GIVEN] // [GIVEN] Unapply Payment from the Invoice
        UnapplySalesDocument(CustomerNo, DocumentNo);
        TransactionNo := FindLastTransactionNo();

        // [WHEN] Reapply Payment to the Bill
        ApplySalesDocuments(
          CustLedgEntry."Document Type"::Payment, DocumentNo, CustLedgEntry."Document Type"::Bill, -Amount);

        // [THEN] Reapply G/L Entries are posted to "Receivables Account" with Amount = "X", "Bills Account" with Amount = -"X"
        VerifyCustGLReapply(CustomerNo, DocumentNo, Amount, TransactionNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyCustScenarioCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        DocumentNo: Code[20];
        CreditMemoNo: Code[20];
        Amount: Decimal;
        Amount2: Decimal;
        TransactionNo: Integer;
    begin
        // [FEATURE] [Sales] [Unapply] [Reapply]
        // [SCENARIO 353489] Payment and a Bill with apply, then Unapplied and Credit Memo posted and then Applied
        // [GIVEN] Sales Bill with Amount = "X"
        CustomerNo := CreateCustomer(true, '');
        Amount := LibraryRandom.RandDec(100, 2);
        Amount2 := Amount;
        CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, Amount);
        InvoiceNo := FindLastPostedSalesDocumentBill(CustomerNo);

        // [GIVEN] Create and apply Payment to the Bill
        DocumentNo :=
          CreatePostApplyGenJnlLine(GenJournalLine, InvoiceNo, '', GenJournalLine."Account Type"::Customer, CustomerNo, Amount);

        // [GIVEN] Unapply Payment from the Bill
        UnapplySalesDocument(CustomerNo, DocumentNo);

        // [GIVEN] Create and post Credit Memo with the same amount = "X"
        CreditMemoNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo, Amount2);
        TransactionNo := FindLastTransactionNo();

        // [WHEN] Reapply Credit Memo to the Bill
        ApplySalesDocuments(
          CustLedgEntry."Document Type"::"Credit Memo", CreditMemoNo, CustLedgEntry."Document Type"::Bill, -Amount2);

        // [THEN] Reapply G/L Entries are posted to "Receivables Account" with Amount = "X", "Bills Account" with Amount = -"X"
        VerifyCustGLReapply(CustomerNo, CreditMemoNo, Amount, TransactionNo);
        // [THEN] Unapplication G/L Entries are posted to "Receivables Account" with 'Debit Amount' = -"X", "Bills Account" with 'Credit Amount' = -"X"
        VerifyCustGLUnapplication(CustomerNo, DocumentNo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyVendScenario2()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
        TransactionNo: Integer;
    begin
        // [FEATURE] [Purchases] [Unapply] [Reapply]
        // [SCENARIO 346852] Vendor Bill and individual Payment applied, then Unapplied and Reapplied
        // [GIVEN] Sales Bill, Payment with Amount = "X"
        VendorNo := CreateVendor(true, '');
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, Amount);

        DocumentNo :=
          CreateAndPostGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, VendorNo, -Amount);

        // [GIVEN] Bill Applied to Payment
        ApplyPurchDocuments(
          VendLedgEntry."Document Type"::Payment, DocumentNo, VendLedgEntry."Document Type"::Bill, Amount);
        TransactionNo := FindLastTransactionNo();

        // [GIVEN] Unapply Payment from the Bill
        UnapplyPurchDocument(VendorNo, DocumentNo);

        // [WHEN] Reapply Payment to the Bill
        ApplyPurchDocuments(
          VendLedgEntry."Document Type"::Payment, DocumentNo, VendLedgEntry."Document Type"::Bill, Amount);

        // [THEN] Reapply G/L Entries are posted to "Payables Account" with Amount = -"X", "Bills Account" with Amount = "X"
        VerifyVendGLReapply(VendorNo, DocumentNo, Amount, TransactionNo);
        // [THEN] Unapplication G/L Entries are posted to "Payables Account" with 'Credit Amount' = -"X", "Bills Account" with 'Debit Amount' = -"X"
        VerifyVendGLUnapplication(VendorNo, DocumentNo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyVendScenario3()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        DocumentNo: Code[20];
        TransactionNo: Integer;
        Amount: Decimal;
    begin
        // [FEATURE] [Purchases] [Unapply] [Reapply]
        // [SCENARIO 346852] Vendor Bill and a Payment directly applied, then Unapplied and Reapplied
        // [GIVEN] Vendor Bill, Payment applied to the Bill with Amount = "X"
        VendorNo := CreateVendor(true, '');
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, Amount);
        InvoiceNo := FindLastPostedPurchDocumentBill(VendorNo);

        DocumentNo :=
          CreatePostApplyGenJnlLine(GenJournalLine, InvoiceNo, '', GenJournalLine."Account Type"::Vendor, VendorNo, -Amount);
        TransactionNo := FindLastTransactionNo();

        // [GIVEN] Unapply Payment from the Bill
        UnapplyPurchDocument(VendorNo, DocumentNo);

        // [WHEN] Reapply Payment to the Bill
        ApplyPurchDocuments(
          VendLedgEntry."Document Type"::Payment, DocumentNo, VendLedgEntry."Document Type"::Bill, Amount);

        // [THEN] Reapply G/L Entries are posted to "Payables Account" with Amount = -"X", "Bills Account" with Amount = "X"
        VerifyVendGLReapply(VendorNo, DocumentNo, Amount, TransactionNo);
        // [THEN] Unapplication G/L Entries are posted to "Payables Account" with 'Credit Amount' = -"X", "Bills Account" with 'Debit Amount' = -"X"
        VerifyVendGLUnapplication(VendorNo, DocumentNo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyVendScenario4()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
        TransactionNo: Integer;
    begin
        // [FEATURE] [Purchases] [Reapply]
        // [SCENARIO 346852] Purch. Invoice posted, Payment with application and a Bill posted via Cartera Jnl., Unapplied then Reapplied
        // [GIVEN] Purchase Invoice with Amount = "X"
        VendorNo := CreateVendor(false, '');
        InvoiceNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, Amount);

        // [GIVEN] Posted Cartera lines with a Payment that applied to Invoice, and a Bill
        CreateCarteraJournalLines(GenJournalLine, InvoiceNo, GenJournalLine."Account Type"::Vendor,
          VendorNo, -Amount);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        DocumentNo :=
          CreateAndPostGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, VendorNo, -Amount);

        ApplyPurchDocuments(
          VendLedgEntry."Document Type"::Payment, DocumentNo, VendLedgEntry."Document Type"::Bill, Amount);
        TransactionNo := FindLastTransactionNo();

        // [GIVEN] Unapply Payment from the Bill
        UnapplyPurchDocument(VendorNo, DocumentNo);

        // [WHEN] Reapply Payment to the Bill
        ApplyPurchDocuments(
          VendLedgEntry."Document Type"::Payment, DocumentNo, VendLedgEntry."Document Type"::Bill, Amount);

        // [THEN] G/L Entries are posted to "Payables Account" with Amount = -"X", "Bills Account" with Amount = "X"
        VerifyVendGLReapply(VendorNo, DocumentNo, Amount, TransactionNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyVendScenarioCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        DocumentNo: Code[20];
        CreditMemoNo: Code[20];
        Amount: Decimal;
        Amount2: Decimal;
        TransactionNo: Integer;
    begin
        // [FEATURE] [Purchases] [Unapply] [Reapply]
        // [SCENARIO 353489] Vendor Bill with Payment directly applied, Unapplied, then Reapplied to Credit Memo
        // [GIVEN] Vendor Bill with Amount = "X"
        VendorNo := CreateVendor(true, '');
        Amount := LibraryRandom.RandDec(100, 2);
        Amount2 := Amount;
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, Amount);
        InvoiceNo := FindLastPostedPurchDocumentBill(VendorNo);

        DocumentNo :=
          CreatePostApplyGenJnlLine(GenJournalLine, InvoiceNo, '', GenJournalLine."Account Type"::Vendor, VendorNo, -Amount);

        // [GIVEN] Unapply Payment from the Bill
        UnapplyPurchDocument(VendorNo, DocumentNo);

        // [GIVEN] Create and post Credit Memo with the same amount = "X"
        CreditMemoNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo, Amount2);
        TransactionNo := FindLastTransactionNo();

        // [WHEN] Reapply Credit Memo to the Bill
        ApplyPurchDocuments(
          VendorLedgEntry."Document Type"::"Credit Memo", CreditMemoNo, VendorLedgEntry."Document Type"::Bill, Amount2);

        // [THEN] Reapply G/L Entries are posted to "Payables Account" with Amount = -"X", "Bills Account" with Amount = "X"
        VerifyVendGLReapply(VendorNo, CreditMemoNo, Amount, TransactionNo);
        // [THEN] Unapplication G/L Entries are posted to "Payables Account" with 'Credit Amount' = -"X", "Bills Account" with 'Debit Amount' = -"X"
        VerifyVendGLUnapplication(VendorNo, DocumentNo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyVendCreditMemoPostWithApply()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        BillNo: Code[20];
        CreditMemoNo: Code[20];
        AmountBill: Decimal;
        AmountCrMemo: Decimal;
        TransactionNo: Integer;
    begin
        // [FEATURE] [Purchases] [Apply]
        // [SCENARIO 375020] Post and Apply at one time Purchase Credit Memo with greater amount
        // [GIVEN] Posted Bill for Vendor with Amount = "X"
        VendorNo := CreateVendor(true, '');
        AmountBill := LibraryRandom.RandDecInRange(1000, 2000, 2);
        BillNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, AmountBill);

        // [GIVEN] Credit Memo with Amount = "Y" > amount of the Bill = "X"
        AmountCrMemo := AmountBill + LibraryRandom.RandDecInRange(100, 200, 2);

        // [WHEN] Post and Apply Credit Memo to the Bill
        CreditMemoNo := CreatePostApplyPurchaseDocument(
            PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo, AmountCrMemo, ApplnTypeRef::Bill, BillNo);
        TransactionNo := FindLastTransactionNo();

        // [THEN] Entry for remaining amount is created for "Vendor Posting Group"."Payables Account" with Amount = "Y" - "X"
        // [THEN] Entry of application is created for "Vendor Posting Group"."Bills Account" with Amount = "X"
        VerifyVendorApplnGLEntries(VendorNo, CreditMemoNo, TransactionNo, AmountBill, AmountCrMemo - AmountBill);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyVendCreditMemoPostThenApply()
    var
        PurchaseHeader: Record "Purchase Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        CreditMemoNo: Code[20];
        AmountBill: Decimal;
        AmountCrMemo: Decimal;
        TransactionNo: Integer;
    begin
        // [FEATURE] [Purchases] [Apply]
        // [SCENARIO 375020] Post then Apply separately Purchase Credit Memo with greater amount
        // [GIVEN] Posted Bill for Vendor with Amount = "X"
        VendorNo := CreateVendor(true, '');
        AmountBill := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, AmountBill);

        // [GIVEN] Posted Credit Memo with Amount = "Y" > amount of the Bill = "X"
        AmountCrMemo := AmountBill + LibraryRandom.RandDecInRange(100, 200, 2);
        CreditMemoNo :=
          CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo, AmountCrMemo);

        // [WHEN] Apply Credit Memo to the Bill
        ApplyPurchDocuments(
          VendLedgEntry."Document Type"::"Credit Memo", CreditMemoNo, VendLedgEntry."Document Type"::Bill, AmountBill);
        TransactionNo := FindLastTransactionNo();

        // [THEN] Entry of application for "Vendor Posting Group"."Payables Account" is created with Amount = "X"
        // [THEN] Entry of application is created for "Vendor Posting Group"."Bills Account" with Amount = -"X"
        VerifyVendorApplnGLEntries(VendorNo, CreditMemoNo, TransactionNo, AmountBill, -AmountBill);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyVendPaymentPostApply()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        BillNo: Code[20];
        PaymentNo: Code[20];
        AmountBill: Decimal;
        AmountPmt: Decimal;
        TransactionNo: Integer;
    begin
        // [FEATURE] [Purchases] [Apply]
        // [SCENARIO 375020] Post and Apply at one time Purchase Payment with greater amount
        // [GIVEN] Posted Bill for Vendor with Amount = "X"
        VendorNo := CreateVendor(true, '');
        AmountBill := LibraryRandom.RandDecInRange(1000, 2000, 2);
        BillNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, AmountBill);
        FindLastPostedPurchDocumentBill(VendorNo);

        // [GIVEN] Payment with Amount = "Y" > amount of the Bill = "X"
        AmountPmt := AmountBill + LibraryRandom.RandDecInRange(100, 200, 2);

        // [WHEN] Post and Apply Payment to the Bill
        PaymentNo := CreatePostApplyGenJnlLine(GenJournalLine, BillNo, '', GenJournalLine."Account Type"::Vendor, VendorNo, -AmountPmt);
        TransactionNo := FindLastTransactionNo();

        // [THEN] Entry for remaining amount is created for "Vendor Posting Group"."Payables Account" with Amount = "Y" - "X"
        // [THEN] Entry of application is created for "Vendor Posting Group"."Bills Account" with Amount = "X"
        VerifyVendorApplnGLEntries(VendorNo, PaymentNo, TransactionNo, AmountBill, AmountPmt - AmountBill);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCustCreditMemoPostWithApply()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        BillNo: Code[20];
        CreditMemoNo: Code[20];
        AmountBill: Decimal;
        AmountCrMemo: Decimal;
        TransactionNo: Integer;
    begin
        // [FEATURE] [Sales] [Apply]
        // [SCENARIO 375020] Post and Apply at one time Sales Credit Memo with greater amount
        // [GIVEN] Posted Bill for Customer with Amount = "X"
        CustomerNo := CreateCustomer(true, '');
        AmountBill := LibraryRandom.RandDecInRange(1000, 2000, 2);
        BillNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, AmountBill);

        // [GIVEN] Credit Memo with Amount = "Y" > amount of the Bill = "X"
        AmountCrMemo := AmountBill + LibraryRandom.RandDecInRange(100, 200, 2);

        // [WHEN] Post and Apply Credit Memo to the Bill
        CreditMemoNo := CreatePostApplySalesDocument(
            SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo, AmountCrMemo, ApplnTypeRef::Bill, BillNo);
        TransactionNo := FindLastTransactionNo();

        // [THEN] Entry for remaining amount is created for "Customer Posting Group"."Receivables Account" with Amount = -"Y" + "X"
        // [THEN] Entry of application is created for "Customer Posting Group"."Bills Account" with Amount = -"X"
        VerifyCustomerApplnGLEntries(CustomerNo, CreditMemoNo, TransactionNo, -AmountBill, -AmountCrMemo + AmountBill);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCustCreditMemoPostThenApply()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        CreditMemoNo: Code[20];
        AmountBill: Decimal;
        AmountCrMemo: Decimal;
        TransactionNo: Integer;
    begin
        // [FEATURE] [Sales] [Apply]
        // [SCENARIO 375020] Post and Apply separately Sales Credit Memo with greater amount
        // [GIVEN] Posted Bill for Customer with Amount = "X"
        CustomerNo := CreateCustomer(true, '');
        AmountBill := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, AmountBill);

        // [GIVEN] Posted Credit Memo with Amount = "Y" > amount of the Bill = "X"
        AmountCrMemo := AmountBill + LibraryRandom.RandDecInRange(100, 200, 2);
        CreditMemoNo :=
          CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo, AmountCrMemo);

        // [WHEN] Apply Credit Memo to the Bill
        ApplySalesDocuments(
          CustLedgerEntry."Document Type"::"Credit Memo", CreditMemoNo, CustLedgerEntry."Document Type"::Bill, -AmountBill);
        TransactionNo := FindLastTransactionNo();

        // [THEN] Entry of application for "Customer Posting Group"."Receivables Account" is created with Amount = -"X"
        // [THEN] Entry of application is created for "Customer Posting Group"."Bills Account" with Amount = "X"
        VerifyCustomerApplnGLEntries(CustomerNo, CreditMemoNo, TransactionNo, -AmountBill, AmountBill);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCustPaymentPostApply()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        BillNo: Code[20];
        PaymentNo: Code[20];
        AmountBill: Decimal;
        AmountPmt: Decimal;
        TransactionNo: Integer;
    begin
        // [FEATURE] [Sales] [Apply]
        // [SCENARIO 375020] Post and Apply at one time Sales Payment with greater amount
        // [GIVEN] Posted Bill for Customer with Amount = "X"
        CustomerNo := CreateCustomer(true, '');
        AmountBill := LibraryRandom.RandDecInRange(1000, 2000, 2);
        BillNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, AmountBill);
        FindLastPostedSalesDocumentBill(CustomerNo);

        // [GIVEN] Payment with Amount = "Y" > amount of the Bill = "X"
        AmountPmt := AmountBill + LibraryRandom.RandDecInRange(100, 200, 2);

        // [WHEN] Post and Apply Payment to the Bill
        PaymentNo := CreatePostApplyGenJnlLine(GenJournalLine, BillNo, '', GenJournalLine."Account Type"::Customer, CustomerNo, AmountPmt);
        TransactionNo := FindLastTransactionNo();

        // [THEN] Entry for remaining amount is created for "Customer Posting Group"."Receivables Account" with Amount = -"Y" + "X"
        // [THEN] Entry of application is created for "Customer Posting Group"."Bills Account" with Amount = -"X"
        VerifyCustomerApplnGLEntries(CustomerNo, PaymentNo, TransactionNo, -AmountBill, -AmountPmt + AmountBill);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceApplyToPaymentThenUnapplyBill()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
        InvNo: Code[20];
    begin
        // [FEATURE] [Sales] [Unapply]
        // [SCENARIO 375035] Payment and a Bill posted then Applied, Unapplied Bill
        // Unapplied from different CustDtldLedgerEntry then in ApplyUnapplyCustScenario2
        // [GIVEN] Sales Bill and a Payment with Amount = "X"
        CustomerNo := CreateCustomer(true, '');
        InvNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, Amount);

        DocumentNo :=
          CreateAndPostGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer, CustomerNo, Amount);

        // [GIVEN] Apply Payment to the Bill
        ApplySalesDocuments(
          CustLedgEntry."Document Type"::Payment, DocumentNo, CustLedgEntry."Document Type"::Bill, -Amount);

        // [WHEN] Unapply Bill from the Payment
        UnapplySalesDocument(CustomerNo, InvNo);

        // [THEN] G/L Entries are posted to "Receivables Account" with 'Debit Amount' = -"X", "Bills Account" with 'Credit Amount' = -"X"
        VerifyCustGLUnapplication(CustomerNo, InvNo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceApplyToCrMemoThenUnapply()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        CreditMemoNo: Code[20];
        Amount: Decimal;
        LineAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Unapply]
        // [SCENARIO 375020] Sales Bill and Credit Memo, then Apply and Unapply
        // [GIVEN] Sales Bill and Credit Memo with Amount = "X"
        CustomerNo := CreateCustomer(true, '');
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        LineAmount := Amount;
        CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, Amount);

        CreditMemoNo :=
          CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo, LineAmount);

        // [GIVEN] Apply Credit Memo to the Bill
        ApplySalesDocuments(
          CustLedgerEntry."Document Type"::"Credit Memo", CreditMemoNo, CustLedgerEntry."Document Type"::Bill, -Amount);

        // [WHEN] Unapply Credit Memo from the Bill
        UnapplySalesDocument(CustomerNo, CreditMemoNo);

        // [THEN] G/L Entries are posted to "Receivables Account" with 'Debit Amount' = -"X", "Bills Account" with 'Credit Amount' = -"X"
        VerifyCustGLUnapplication(CustomerNo, CreditMemoNo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceApplyToLowerPmtThenUnapplyAndReapplyToEqualPmt()
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        LowerPmtNo: Code[20];
        EqualPmtNo: Code[20];
        LowerAmount: Decimal;
        Amount: Decimal;
        TransactionNo: Integer;
    begin
        // [FEATURE] [Sales] [Unapply] [Reapply]
        // [SCENARIO 375035] TFS 374800. Sales Bill, Payment of lower amount Apply - Unapply, Payment with the same amount Reapply
        // [GIVEN] Sales Bill with Amount = "X"
        CustomerNo := CreateCustomer(true, '');
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, Amount);

        LowerAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());
        LowerPmtNo :=
          CreateAndPostGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer, CustomerNo, LowerAmount);

        // [GIVEN] Bill Applied to Payment then Unapplied
        ApplySalesDocuments(
          CustLedgerEntry."Document Type"::Payment, LowerPmtNo, CustLedgerEntry."Document Type"::Bill, -LowerAmount);
        UnapplySalesDocument(CustomerNo, LowerPmtNo);
        EqualPmtNo :=
          CreateAndPostGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer, CustomerNo, Amount);

        // [WHEN] Reapply Payment to the Bill
        TransactionNo := FindLastTransactionNo();
        ApplySalesDocuments(
          CustLedgerEntry."Document Type"::Payment, EqualPmtNo, CustLedgerEntry."Document Type"::Bill, -Amount);

        // [THEN] Unapplication G/L Entries are posted to "Receivables Account" with 'Debit Amount' = -"X", "Bills Account" with 'Credit Amount' = -"X"
        VerifyCustGLUnapplication(CustomerNo, LowerPmtNo, LowerAmount);
        // [THEN] G/L Entries are posted to "Receivables Account" with Amount = "X", "Bills Account" with Amount = -"X"
        VerifyCustGLReapply(CustomerNo, EqualPmtNo, Amount, TransactionNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesBillAndInvoiceApplyToPaymentThenUnapply()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        AmountX: Decimal;
        AmountY: Decimal;
        TransactionNoX: Integer;
        TransactionNoY: Integer;
    begin
        // [FEATURE] [Sales] [Unapply]
        // [SCENARIO 375035] Sales Bill and simple Invoice, apply to the Payment, then Unapply one by one
        // [GIVEN] Sales Bill with Amount = "X", applied to the Payment
        CustomerNo := CreateCustomer(true, '');
        CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, AmountX);

        DocumentNo :=
          CreateAndPostGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer, CustomerNo, AmountX * 4);

        ApplySalesDocuments(
          CustLedgEntry."Document Type"::Payment, DocumentNo, CustLedgEntry."Document Type"::Bill, -AmountX);

        // [GIVEN] Simple Sales Invoice with Amount = "Y", applied to the Payment
        AmountY := AmountX * 2;
        CreateAndPostSalesDocumentWOutBill(SalesHeader."Document Type"::Invoice, CustomerNo, AmountY);
        ApplySalesDocuments(
          CustLedgEntry."Document Type"::Payment, DocumentNo, CustLedgEntry."Document Type"::Invoice, -AmountY);

        // [WHEN] Payment unapplied from Bill, then from Invoice
        TransactionNoX := FindLastTransactionNo();
        UnapplySalesDocument(CustomerNo, DocumentNo);
        TransactionNoY := FindLastTransactionNo();
        UnapplySalesDocument(CustomerNo, DocumentNo);

        // [THEN] G/L Entries are posted to CustomerPostingGroup."Receivables Account", CustomerPostingGroup."Bills Account" with Amount = "X"
        // [THEN] Same G/L Entries are posted to CustomerPostingGroup."Receivables Account" with Amount = "Y"
        VerifyCustUnappliedGLWithTransaction(CustomerNo, DocumentNo, AmountX, AmountY, TransactionNoX, TransactionNoY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceApplyToPaymentThenUnapplyBill()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
        InvNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Unapply]
        // [SCENARIO 375035] Payment and a Bill posted then Applied, Unapplied Bill
        // Unapplied from different CustDtldLedgerEntry then in ApplyUnapplyVendScenario2
        // [GIVEN] Vendor Bill and a Payment with Amount = "X"
        VendorNo := CreateVendor(true, '');
        InvNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, Amount);

        DocumentNo :=
          CreateAndPostGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, VendorNo, -Amount);

        // [GIVEN] Apply Payment to the Bill
        ApplyPurchDocuments(
          VendorLedgerEntry."Document Type"::Payment, DocumentNo, VendorLedgerEntry."Document Type"::Bill, Amount);

        // [WHEN] Unapply Bill from the Payment
        UnapplyPurchDocument(VendorNo, InvNo);

        // [THEN] Unapplication G/L Entries are posted to "Payables Account" with 'Credit Amount' = -"X", "Bills Account" with 'Debit Amount' = -"X"
        VerifyVendGLUnapplication(VendorNo, InvNo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceApplyToCrMemoThenUnapply()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        CreditMemoNo: Code[20];
        Amount: Decimal;
        LineAmount: Decimal;
    begin
        // [FEATURE] [Purchases] [Unapply]
        // [SCENARIO 375020] Vendor Bill and Credit Memo, then Apply and Unapply
        // [GIVEN] Vendor Bill and Credit Memo with Amount = "X"
        VendorNo := CreateVendor(true, '');
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        LineAmount := Amount;
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, Amount);

        CreditMemoNo :=
          CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo, LineAmount);

        // [GIVEN] Apply Credit Memo to the Bill
        ApplyPurchDocuments(
          VendorLedgerEntry."Document Type"::"Credit Memo", CreditMemoNo, VendorLedgerEntry."Document Type"::Bill, Amount);

        // [WHEN] Unapply Credit Memo from the Bill
        UnapplyPurchDocument(VendorNo, CreditMemoNo);

        // [THEN] Unapplication G/L Entries are posted to "Payables Account" with 'Credit Amount' = -"X", "Bills Account" with 'Debit Amount' = -"X"
        VerifyVendGLUnapplication(VendorNo, CreditMemoNo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceApplyToLowerPmtThenUnapplyAndReapplyToEqualPmt()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        LowerPmtNo: Code[20];
        EqualPmtNo: Code[20];
        LowerAmount: Decimal;
        Amount: Decimal;
        TransactionNo: Integer;
    begin
        // [FEATURE] [Purchases] [Unapply] [Reapply]
        // [SCENARIO 375035] TFS 374800. Vendor Bill, Payment of lower amount Apply - Unapply, Payment with the same amount Reapply
        // [GIVEN] Vendor Bill with Amount = "X"
        VendorNo := CreateVendor(true, '');
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, Amount);

        LowerAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());
        LowerPmtNo :=
          CreateAndPostGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, VendorNo, -LowerAmount);

        // [GIVEN] Bill Applied to Payment then Unapplied
        ApplyPurchDocuments(
          VendorLedgerEntry."Document Type"::Payment, LowerPmtNo, VendorLedgerEntry."Document Type"::Bill, LowerAmount);
        UnapplyPurchDocument(VendorNo, LowerPmtNo);
        EqualPmtNo :=
          CreateAndPostGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, VendorNo, -Amount);

        // [WHEN] Reapply Payment to the Bill
        TransactionNo := FindLastTransactionNo();
        ApplyPurchDocuments(
          VendorLedgerEntry."Document Type"::Payment, EqualPmtNo, VendorLedgerEntry."Document Type"::Bill, Amount);

        // [THEN] Unapplication G/L Entries are posted to "Payables Account" with 'Credit Amount' = -"X", "Bills Account" with 'Debit Amount' = -"X"
        VerifyVendGLUnapplication(VendorNo, LowerPmtNo, LowerAmount);
        // [THEN] Reapply G/L Entries are posted to "Payables Account" with Amount = -"X", "Bills Account" with Amount = "X"
        VerifyVendGLReapply(VendorNo, EqualPmtNo, Amount, TransactionNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchBillAndInvoiceApplyToPaymentThenUnapply()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        AmountX: Decimal;
        AmountY: Decimal;
        TransactionNoX: Integer;
        TransactionNoY: Integer;
    begin
        // [FEATURE] [Purchases] [Unapply]
        // [SCENARIO 375035] Vendor Bill and simple Invoice, apply to the Payment, then Unapply one by one
        // [GIVEN] Vendor Bill with Amount = "X", applied to the Payment
        VendorNo := CreateVendor(true, '');
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, AmountX);

        DocumentNo :=
          CreateAndPostGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, VendorNo, -AmountX * 4);

        ApplyPurchDocuments(
          VendorLedgerEntry."Document Type"::Payment, DocumentNo, VendorLedgerEntry."Document Type"::Bill, AmountX);

        // [GIVEN] Simple Purchase Invoice with Amount = "Y", applied to the Payment
        AmountY := AmountX * 2;
        CreateAndPostPurchaseDocumentWOutBill(PurchaseHeader."Document Type"::Invoice, VendorNo, AmountY);
        ApplyPurchDocuments(
          VendorLedgerEntry."Document Type"::Payment, DocumentNo, VendorLedgerEntry."Document Type"::Invoice, AmountY);

        // [WHEN] Payment unapplied from Bill, then from Invoice
        TransactionNoX := FindLastTransactionNo();
        UnapplyPurchDocument(VendorNo, DocumentNo);
        TransactionNoY := FindLastTransactionNo();
        UnapplyPurchDocument(VendorNo, DocumentNo);

        // [THEN] G/L Entries are posted to VendorPostingGroup."Payables Account", VendorPostingGroup."Bills Account" with Amount = "X"
        // [THEN] Same G/L Entries are posted to VendorPostingGroup."Payables Account" with Amount = "Y"
        VerifyVendUnappliedGLWithTransaction(VendorNo, DocumentNo, AmountX, AmountY, TransactionNoX, TransactionNoY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCustPaymentWithCurrency()
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        CarteraDoc: Record "Cartera Doc.";
        CustomerNo: Code[20];
        BillDocumentNo: Code[20];
        CurrencyCode: Code[10];
        AmountBill: Decimal;
    begin
        // [FEATURE] [Sales] [Apply] [Currency] [Rounding]
        // [SCENARIO 376662] Rounding G/L Entry is posted to Customer Bills Account for partial Payment with Currency.

        // [GIVEN] Currency with fractional exchange rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1.2368, 1.2368); // specific values

        // [GIVEN] Customer with currency, Sales Bill with Amount = "X"
        CustomerNo := CreateCustomer(true, CurrencyCode);

        AmountBill := 2000; // specific value
        BillDocumentNo := CreateAndPostSalesDocument(
            SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, AmountBill);

        // [WHEN] Post Payment with Amount = "S" < "X" applied to Bill
        CreatePostApplyGenJnlLine(
          GenJournalLine, BillDocumentNo, GetFirstBillNo(BillDocumentNo, CarteraDoc.Type::Receivable),
          GenJournalLine."Account Type"::Customer, CustomerNo, 100);

        // [THEN] Payment G/L Entry for rounding is posted to Bills Account
        VerifyPaymentGLEntryCount(
          GenJournalLine."Document No.", GetCustomerBillsAccount(CustomerNo), 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyVendPaymentWithCurrency()
    var
        PurchHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        CarteraDoc: Record "Cartera Doc.";
        VendorNo: Code[20];
        BillDocumentNo: Code[20];
        CurrencyCode: Code[10];
        AmountBill: Decimal;
    begin
        // [FEATURE] [Purchase] [Apply] [Currency] [Rounding]
        // [SCENARIO 376662] Rounding G/L Entry is posted to Vendor Bills Account for partial Payment with Currency.

        // [GIVEN] Currency with fractional exchange rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1.2368, 1.2368); // specific values

        // [GIVEN] Vendor with currency, Purchase Bill with Amount = "X"
        VendorNo := CreateVendor(true, CurrencyCode);

        AmountBill := 2000; // specific value
        BillDocumentNo := CreateAndPostPurchaseDocument(
            PurchHeader, PurchHeader."Document Type"::Invoice, VendorNo, AmountBill);

        // [WHEN] Post Payment with Amount = "S" < "X" applied to Bill
        CreatePostApplyGenJnlLine(
          GenJournalLine, BillDocumentNo, GetFirstBillNo(BillDocumentNo, CarteraDoc.Type::Payable),
          GenJournalLine."Account Type"::Vendor, VendorNo, -100);

        // [THEN] Payment G/L Entry for rounding is posted to Bills Account
        VerifyPaymentGLEntryCount(
          GenJournalLine."Document No.", GetVendorBillsAccount(VendorNo), 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseUnappliedCustPaymentWithInvDocNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        Amount: Decimal;
        InvNo: Code[20];
    begin
        // [FEATURE] [Sales] [Reverse]
        // [SCENARIO 377495] Reverse unapplied customer payment with Cartera and the same "Document No." as previously applied Invoice

        // [GIVEN] Posted Invoice "X". Payment Terms "Invoices to Cartera" is on.
        CustomerNo := CreateCustWithPmtMethod(CreatePaymentMethodWithInvoicesToCartera());
        InvNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, Amount);

        // [GIVEN] Posted Payment with "Document No." = "X"
        CreateAndPostGenJnlLineWithSpecificDocNo(GenJournalLine, InvNo, GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, CustLedgEntry."Document Type"::Payment, InvNo);

        // [GIVEN] Invoice applied to Payment
        ApplySalesDocuments(
          CustLedgEntry."Document Type"::Payment, InvNo, CustLedgEntry."Document Type"::Invoice, -Amount);

        // [GIVEN] Unapply Payment from Invoice
        UnapplySalesDocument(CustomerNo, InvNo);

        // [WHEN] Reverse Payment
        ReverseTransaction(CustLedgEntry."Transaction No.");

        // [THEN] Payment Customer Ledger Entry is reversed
        CustLedgEntry.Find();
        CustLedgEntry.TestField(Reversed, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseUnappliedVendtPaymentWithInvDocNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchHeader: Record "Purchase Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        Amount: Decimal;
        InvNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Cartera] [Reverse]
        // [SCENARIO 377495] Reverse unapplied vendor payment with Cartera and the same "Document No." as previously applied Invoice

        // [GIVEN] Posted Invoice "X" Payment Terms "Invoices to Cartera" is on.
        VendorNo := CreateVendWithPmtMethod(CreatePaymentMethodWithInvoicesToCartera());
        InvNo := CreateAndPostPurchaseDocument(PurchHeader, PurchHeader."Document Type"::Invoice, VendorNo, Amount);

        // [GIVEN] Posted Payment with "Document No." = "X"
        CreateAndPostGenJnlLineWithSpecificDocNo(GenJournalLine, InvNo, GenJournalLine."Account Type"::Vendor, VendorNo, -Amount);
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Payment, InvNo);

        // [GIVEN] Invoice applied to Payment
        ApplyPurchDocuments(
          VendLedgEntry."Document Type"::Payment, InvNo, VendLedgEntry."Document Type"::Invoice, Amount);

        // [GIVEN] Unapply Payment from Invoice
        UnapplyPurchDocument(VendorNo, InvNo);

        // [WHEN] Reverse Payment
        ReverseTransaction(VendLedgEntry."Transaction No.");

        // [THEN] Payment Vendor Ledger Entry is reversed
        VendLedgEntry.Find();
        VendLedgEntry.TestField(Reversed, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnapplyBillAndInvoice()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        InvoiceAmount: Decimal;
        BillAmount: Decimal;
        InvNo: Code[20];
        BillNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Unapply]
        // [SCENARIO 379060] Sales Posted Bill (first) and Invoice (second) applied to payment then all unapplied

        // [GIVEN] Posted Bill (first) and Invoice (second)
        CustomerNo := CreateCustomer(true, '');
        BillNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, BillAmount);
        InvoiceAmount := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        InvNo := CreateAndPostSalesDocumentWOutBill(SalesHeader."Document Type"::Invoice, CustomerNo, InvoiceAmount);
        InvoiceAmount := GetSalesInvoiceAmount(InvNo);

        // [GIVEN] Payment journal line applied to Invoice and Bill posted
        PaymentNo := CreateAndPostSalesPaymentAppliedToInvoiceAndBill(CustomerNo, InvNo, BillNo, InvoiceAmount + BillAmount);

        // [WHEN] Unapply Payment from Invoice and Bill
        UnapplySalesDocument(CustomerNo, PaymentNo);

        // [THEN] G/L Entries are posted to "Bills Account"
        VerifyCustPaymentUnappliedGLEntries(PaymentNo, CustomerNo, BillAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnapplyInvoiceAndBill()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        InvoiceAmount: Decimal;
        BillAmount: Decimal;
        InvNo: Code[20];
        BillNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Unapply]
        // [SCENARIO 379060] Sales Posted Invoice (first) and Bill (second) applied to payment then all unapplied

        // [GIVEN] Posted Invoice (first) and Bill (second)
        CustomerNo := CreateCustomer(true, '');
        InvoiceAmount := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        InvNo := CreateAndPostSalesDocumentWOutBill(SalesHeader."Document Type"::Invoice, CustomerNo, InvoiceAmount);
        InvoiceAmount := GetSalesInvoiceAmount(InvNo);
        BillNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, BillAmount);

        // [GIVEN] Payment journal line applied to Invoice and Bill posted
        PaymentNo := CreateAndPostSalesPaymentAppliedToInvoiceAndBill(CustomerNo, InvNo, BillNo, InvoiceAmount + BillAmount);

        // [WHEN] Unapply Payment from Invoice and Bill
        UnapplySalesDocument(CustomerNo, PaymentNo);

        // [THEN] G/L Entries are posted to "Bills Account"
        VerifyCustPaymentUnappliedGLEntries(PaymentNo, CustomerNo, BillAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnapplyBillAndInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        InvoiceAmount: Decimal;
        BillAmount: Decimal;
        InvNo: Code[20];
        BillNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Unapply]
        // [SCENARIO 379060] Purchases Posted Bill (first) and Invoice (second) applied to payment then all unapplied

        // [GIVEN] Posted Bill (first) and Invoice (second)
        VendorNo := CreateVendor(true, '');
        BillNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, BillAmount);
        InvoiceAmount := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        InvNo := CreateAndPostPurchaseDocumentWOutBill(PurchaseHeader."Document Type"::Invoice, VendorNo, InvoiceAmount);
        InvoiceAmount := GetPurchaseInvoiceAmount(InvNo);

        // [GIVEN] Payment journal line applied to Invoice and Bill posted
        PaymentNo := CreateAndPostPurchasePaymentAppliedToInvoiceAndBill(VendorNo, InvNo, BillNo, -(InvoiceAmount + BillAmount));

        // [WHEN] Unapply Payment from Invoice and Bill
        UnapplyPurchDocument(VendorNo, PaymentNo);

        // [THEN] G/L Entries are posted to "Bills Account"
        VerifyVendPaymentUnappliedGLEntries(PaymentNo, VendorNo, BillAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnapplyInvoiceAndBill()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        InvoiceAmount: Decimal;
        BillAmount: Decimal;
        InvNo: Code[20];
        BillNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Unapply]
        // [SCENARIO 379060] Purchases Posted Invoice (first) and Bill (second) applied to payment then all unapplied

        // [GIVEN] Posted Invoice (first) and Bill (second)
        VendorNo := CreateVendor(true, '');
        InvoiceAmount := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        InvNo := CreateAndPostPurchaseDocumentWOutBill(PurchaseHeader."Document Type"::Invoice, VendorNo, InvoiceAmount);
        InvoiceAmount := GetPurchaseInvoiceAmount(InvNo);
        BillNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, BillAmount);

        // [GIVEN] Payment journal line applied to Invoice and Bill posted
        PaymentNo := CreateAndPostPurchasePaymentAppliedToInvoiceAndBill(VendorNo, InvNo, BillNo, -(InvoiceAmount + BillAmount));

        // [WHEN] Unapply Payment from Invoice and Bill
        UnapplyPurchDocument(VendorNo, PaymentNo);

        // [THEN] G/L Entries are posted to "Bills Account"
        VerifyVendPaymentUnappliedGLEntries(PaymentNo, VendorNo, BillAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnapplyRefundToPaymentWithCreateBills()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustNo: Code[20];
        PaymentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Sales] [Unapply]
        // [SCENARIO 201795] Receivables Account is used when unapply Payment from Refund for Customer with Payment Method "Create Bills"

        // [GIVEN] Customer "X" with Payment Method "Create Bills"
        CustNo := CreateCustomer(true, '');
        Amount := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Payment with Customer "X" and Amount = 100
        PaymentNo :=
          CreateAndPostGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer, CustNo, Amount);

        // [GIVEN] Refund with Customer "X" and Amount = -100
        CreateAndPostGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Refund,
          GenJournalLine."Account Type"::Customer, CustNo, -Amount);

        // [GIVEN] Payment applied to Refund
        ApplySalesDocuments(
          CustLedgEntry."Document Type"::Payment, PaymentNo, CustLedgEntry."Document Type"::Refund, -Amount);

        // [WHEN] Unapply Payment from Refund
        UnapplySalesDocument(CustNo, PaymentNo);

        // [THEN] Two G/L Entries are created with "G/L Account" = "Receivables Account" and opposite amount
        VerifyReceivablesAccountInGLEntryOfPmtToRefUnapplication(CustNo, PaymentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnapplyRefundToPaymentWithCreateBills()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendNo: Code[20];
        PaymentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Purchases] [Unapply]
        // [SCENARIO 201795] Payables Account is used when unapply Payment from Refund for Vendor with Payment Method "Create Bills"

        // [GIVEN] Vendor "X" with Payment Method "Create Bills"
        VendNo := CreateVendor(true, '');
        Amount := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Payment with Vendor "X" and Amount = 100
        PaymentNo :=
          CreateAndPostGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, VendNo, -Amount);

        // [GIVEN] Refund with Vendor "X" and Amount = -100
        CreateAndPostGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Refund,
          GenJournalLine."Account Type"::Vendor, VendNo, Amount);

        // [GIVEN] Payment applied to Refund
        ApplyPurchDocuments(
          VendLedgEntry."Document Type"::Payment, PaymentNo, VendLedgEntry."Document Type"::Refund, Amount);

        // [WHEN] Unapply Payment from Refund
        UnapplyPurchDocument(VendNo, PaymentNo);

        // [THEN] Two G/L Entries are created with "G/L Account" = "Payables Account" and opposite amount
        VerifyPayablesAccountInGLEntryOfPmtToRefUnapplication(VendNo, PaymentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCrMemoToBillWithAddCurrency()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Amount: Decimal;
        ExpectedAmountACY: Decimal;
        CustomerNo: Code[20];
        CurrencyCode: Code[10];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Sales] [Apply]
        // [SCENARIO 293328] Credit memo can be applied to bill when their currency code = additional currency
        Initialize();

        // [GIVEN] Create currency "CURR" with specific exchange rate
        CurrencyCode :=
          LibraryERM.CreateCurrencyWithExchangeRate(CalcDate('<-CM>', WorkDate()), 1.13306, 1.13306);

        // [GIVEN] Set "CURR" as additional reporting currency
        LibraryERM.SetAddReportingCurrency(CurrencyCode);

        // [GIVEN] Create customer with local currency and create bill Payment Method
        CustomerNo := CreateCustomer(true, '');

        // [GIVEN] Create and post invoice with currency "CURR" and amount 1000
        Amount := LibraryRandom.RandDecInRange(500, 1000, 2);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("Unit Price", Amount);
        ExpectedAmountACY := SalesLine."Amount Including VAT";
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Create and post credit memo with currency "CURR" and amount 1000
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        SalesHeader.Validate("Posting Date", WorkDate() + 2);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify();
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Credit memo is being applied to bill
        ApplySalesDocuments(
          CustLedgEntry."Document Type"::"Credit Memo", CrMemoNo, CustLedgEntry."Document Type"::Bill, -Amount);

        // [THEN] Application G/L entries have additional currency amount 1160
        VerifyCustAppliedGLEntriesAddCurrAmountNotEmpty(CustomerNo, ExpectedAmountACY);
    end;

    [Test]
    [HandlerFunctions('UnapplyCustomerEntriesMPH,ConfirmHandler')]
    procedure ErrorOnTryingUnapplyPmtWithBlankedDocTypeToInvSales()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        PaymentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Sales] [Unapply]
        // [SCENARIO 385952] An error message is shown trying to unapply customer payment with blanked document type to invoice
        Initialize();

        // [GIVEN] Posted customer payment with blanked document type
        CustomerNo := CreateCustomer(false, '');
        Amount := LibraryRandom.RandDec(1000, 2);
        PaymentNo :=
          CreateAndPostGenJnlLine(
            GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer, CustomerNo, Amount);

        // [GIVEN] Posted customer invoice
        CreateAndPostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo, -Amount);

        // [GIVEN] Apply payment to invoice
        ApplySalesDocuments(
          CustLedgerEntry."Document Type"::" ", PaymentNo, CustLedgerEntry."Document Type"::Invoice, -Amount);

        // [WHEN] Try to unapply
        asserterror UnapplySalesViaPage(CustomerNo, CustLedgerEntry."Document Type"::" ", PaymentNo);

        // [THEN] An error is shown: "You cannot unapply the entries because one entry has a blank Document Type."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(UnapplyBlankedDocTypeErr);
    end;

    [Test]
    [HandlerFunctions('UnapplyCustomerEntriesMPH,ConfirmHandler')]
    procedure ErrorOnTryingUnapplyInvToPmtWithBlankedDocTypeSales()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Sales] [Unapply]
        // [SCENARIO 385952] An error message is shown trying to unapply customer invoice to payment with blanked document type
        Initialize();

        // [GIVEN] Posted customer invoice
        CustomerNo := CreateCustomer(false, '');
        Amount := LibraryRandom.RandDec(1000, 2);
        InvoiceNo :=
          CreateAndPostGenJnlLine(
            GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo, -Amount);

        // [GIVEN] Posted customer payment with blanked document type
        CreateAndPostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer, CustomerNo, Amount);

        // [GIVEN] Apply invoice to payment
        ApplySalesDocuments(
          CustLedgerEntry."Document Type"::Invoice, InvoiceNo, CustLedgerEntry."Document Type"::" ", Amount);

        // [WHEN] Try to unapply
        asserterror UnapplySalesViaPage(CustomerNo, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);

        // [THEN] An error is shown: "You cannot unapply the entries because one entry has a blank Document Type."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(UnapplyBlankedDocTypeErr);
    end;

    [Test]
    [HandlerFunctions('UnapplyVendorEntriesMPH,ConfirmHandler')]
    procedure ErrorOnTryingUnapplyPmtWithBlankedDocTypeToInvPurchase()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        PaymentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Purchases] [Unapply]
        // [SCENARIO 385952] An error message is shown trying to unapply vendor payment with blanked document type to invoice
        Initialize();

        // [GIVEN] Posted vendor payment with blanked document type
        VendorNo := CreateVendor(false, '');
        Amount := LibraryRandom.RandDec(1000, 2);
        PaymentNo :=
          CreateAndPostGenJnlLine(
            GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Vendor, VendorNo, -Amount);

        // [GIVEN] Posted vendor invoice
        CreateAndPostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, VendorNo, Amount);

        // [GIVEN] Apply payment to invoice
        ApplyPurchDocuments(
          VendorLedgerEntry."Document Type"::" ", PaymentNo, VendorLedgerEntry."Document Type"::Invoice, Amount);

        // [WHEN] Try to unapply
        asserterror UnapplyPurchaseViaPage(VendorNo, VendorLedgerEntry."Document Type"::" ", PaymentNo);

        // [THEN] An error is shown: "You cannot unapply the entries because one entry has a blank Document Type."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(UnapplyBlankedDocTypeErr);
    end;

    [Test]
    [HandlerFunctions('UnapplyVendorEntriesMPH,ConfirmHandler')]
    procedure ErrorOnTryingUnapplyInvToPmtWithBlankedDocTypePurchase()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Purchases] [Unapply]
        // [SCENARIO 385952] An error message is shown trying to unapply vendor invoice to payment with blanked document type
        Initialize();

        // [GIVEN] Posted vendor invoice
        VendorNo := CreateVendor(false, '');
        Amount := LibraryRandom.RandDec(1000, 2);
        InvoiceNo :=
          CreateAndPostGenJnlLine(
            GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, VendorNo, Amount);

        // [GIVEN] Posted vendor payment with blanked document type
        CreateAndPostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Vendor, VendorNo, -Amount);

        // [GIVEN] Apply invoice to payment
        ApplyPurchDocuments(
          VendorLedgerEntry."Document Type"::Invoice, InvoiceNo, VendorLedgerEntry."Document Type"::" ", -Amount);

        // [WHEN] Try to unapply
        asserterror UnapplyPurchaseViaPage(VendorNo, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);

        // [THEN] An error is shown: "You cannot unapply the entries because one entry has a blank Document Type."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(UnapplyBlankedDocTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJournalLinesAppliedToBillAndEmployee()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchaseHeader: Record "Purchase Header";
        EmployeeNo: Code[20];
        VendorNo: Code[20];
        BillNo: Code[20];
        DocNo: Code[20];
        AmountBill: Decimal;
    begin
        // [FEATURE] [Sales] [Apply]
        // [SCENARIO 449080] When posting an Employee Gen. Journal Line after a line applied to a bill, everything is posted correctly
        Initialize();

        // [GIVEN] Prepare Vendor and Employee with posting setups
        VendorNo := CreateVendor(true, '');
        EmployeeNo := LibraryHR.CreateEmployeeNoWithBankAccount();

        // [WHEN] Prepare General Journal Template and Batch
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] Posted Invoice to Bill for Vendor with Amount = "X"
        AmountBill := LibraryRandom.RandDecInRange(1000, 2000, 2);
        BillNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, AmountBill);

        // [WHEN] Create Vendor Gen. Journal Line and apply it to the bill, for full amount X
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Vendor, VendorNo, AmountBill);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Bill);
        GenJournalLine.Validate("Applies-to Bill No.", BillNo);
        GenJournalLine.Modify(true);
        DocNo := GenJournalLine."Document No.";

        // [WHEN] Create Employee Gen Journal Line with same Document No and Amount -X to balance
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Employee, EmployeeNo, -AmountBill);
        GenJournalLine.Validate("Document No.", DocNo);
        GenJournalLine.Modify(true);

        // [WHEN] Post lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] No inconsistency error. The created entry for employee has the correct amount -X
        VerifyEmployeeLedgerEntry(EmployeeNo, -AmountBill);
    end;

    [Test]
    [HandlerFunctions('ApplyEmployeeEntriesHandler,UnApplyEmployeeEntriesHandler,PostApplicationHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnApplyEmpLedgerEntryWithoutAnyError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        GLAccountNo: Record "G/L Account";
        DocumentNo: Code[20];
        EmployeeNo: Code[20];
        Payment: Decimal;
        InvoiceAmount: Decimal;
    begin
        // [SCENARIO 482731] Unable to unapply employee ledger entry the second time on both Saas and On-Prem environment
        Initialize();

        // [GIVEN] Create Employee with Bank Account
        EmployeeNo := LibraryHR.CreateEmployeeNoWithBankAccount();

        // [GIVEN] Create G/L Account
        LibraryERM.CreateGLAccount(GLAccountNo);

        // [WHEN] Prepare General Journal Template and Batch
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] Save Payment and Invoice Amount.
        Payment := LibraryRandom.RandDecInRange(1000, 2000, 2);
        InvoiceAmount := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] Create General Journal Line for Payment Entry
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
         GenJournalLine,
         GenJournalTemplate.Name,
         GenJournalBatch.Name,
         GenJournalLine."Document Type"::Payment,
         GenJournalLine."Account Type"::Employee,
         EmployeeNo,
         GenJournalLine."Bal. Account Type"::"G/L Account",
         GLAccountNo."No.",
         Payment);

        // [GIVEN] Post the General Journal Line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Save the Payment Document No.
        DocumentNo := GenJournalLine."Document No.";

        // [GIVEN] Create General Journal Line for Invoice Entry
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
        GenJournalLine,
        GenJournalTemplate.Name,
        GenJournalBatch.Name,
        GenJournalLine."Document Type"::" ",
        GenJournalLine."Account Type"::Employee,
        EmployeeNo,
        GenJournalLine."Bal. Account Type"::"G/L Account",
        GLAccountNo."No.",
        -InvoiceAmount);

        // [GIVEN] Post the Invoice entry for the Employee x
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Apply the Payment Employee Ledger Entry with Invoice 
        ApplyEmployeeLedgerEntries(EmployeeNo, DocumentNo, EmployeeLedgerEntry."Document Type"::Payment);

        // [WHEN] UnApply the Payment Employee Ledger Entry 
        UnApplyEmployeeLedgerEntries(EmployeeNo, DocumentNo, EmployeeLedgerEntry."Document Type"::Payment);

        // [GIVEN] Find the last Employee Ledger Entry and CalcFiled the Remaining Amount
        EmployeeLedgerEntry.FindLast();
        EmployeeLedgerEntry.CalcFields("Remaining Amount");

        // [VERIFY] Verify the Invoice Employee Ledger Entry has successfully unapplied and remaining amount equal to Invoice Amount
        Assert.AreEqual(-InvoiceAmount, EmployeeLedgerEntry."Remaining Amount", UnAppliedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPaymentWithInvToCarteraVLEUsingAllowMultiPostingGrpsCreatesGLEntries()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendorPostingGroup: array[2] of Record "Vendor Posting Group";
        GLEntry: Record "G/L Entry";
        Amount: Decimal;
    begin
        // [SCENARIO 539768] When Apply Payment Vendor Ledger Entry with Invoice to Cartera Vendor Ledger Entry then GL Entries are created with 
        // "GL Account No." of "Payables Account" of Vendor Posting Groups when "Allow Multiple Posting Groups" is true in Purchases & Payables Setup.
        Initialize();

        // [GIVEN] Set Allow Multiple Posting Groups as true in Purchases & Payables Setup.
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Allow Multiple Posting Groups" := true;
        PurchasesPayablesSetup.Modify();

        // [GIVEN] Create two Vendor Posting Groups.
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup[1]);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup[2]);

        // [GIVEN] Create Alternate Vendor Posting Group.
        LibraryPurchase.CreateAltVendorPostingGroup(VendorPostingGroup[1].Code, VendorPostingGroup[2].Code);

        // [GIVEN] Create Vendor and Validate Allow Multiple Groups and Vendor Posting Group.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Validate("Vendor Posting Group", VendorPostingGroup[1].Code);
        Vendor.Modify(true);

        // [GIVEN] Find Payment Method and Validate Invoices to Cartera.
        PaymentMethod.Get(Vendor."Payment Method Code");
        PaymentMethod.Validate("Invoices to Cartera", true);
        PaymentMethod.Modify(true);

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Header and Validate Prices Including VAT.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);

        // [GIVEN] Create Purchase Line and Validate Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(0));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(1000, 1000));
        PurchaseLine.Modify(true);

        // [GIVEN] Generate and sav Amount in a Variable.
        Amount := PurchaseLine."Direct Unit Cost";

        // [GIVEN] Post Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Create General Journal Line and Validate Posting Group and Debit Amount.
        CreateGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandIntInRange(1000, 1000));
        GenJournalLine.Validate("Posting Group", VendorPostingGroup[2].Code);
        GenJournalLine.Validate("Debit Amount", LibraryRandom.RandIntInRange(1000, 1000));
        GenJournalLine.Modify(true);

        // [GIVEN] Post General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Apply Payment Vendor Ledger Entry with Invoice Vendor Ledger Entry.
        ApplyPurchDocuments(
            VendLedgEntry."Document Type"::Payment,
            GenJournalLine."Document No.",
            VendLedgEntry."Document Type"::Invoice,
            LibraryRandom.RandIntInRange(1000, 1000));

        // [WHEN] Find GL Entry.
        GLEntry.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GLEntry.SetRange("G/L Account No.", VendorPostingGroup[2]."Payables Account");
        GLEntry.SetRange(Amount, -Amount);

        // [THEN] GL Entry is found.
        Assert.IsFalse(GLEntry.IsEmpty(), GLEntryMustBeFound);

        // [WHEN] Find GL Entry.
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("G/L Account No.", VendorPostingGroup[1]."Payables Account");
        GLEntry.SetRange(Amount, Amount);

        // [THEN] GL Entry is found.
        Assert.IsFalse(GLEntry.IsEmpty(), GLEntryMustBeFound);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPaymentWithBillVLEUsingAllowMultiPostingGrpsCreatesGLEntries()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendorPostingGroup: array[2] of Record "Vendor Posting Group";
        GLEntry: Record "G/L Entry";
        Amount: Decimal;
    begin
        // [SCENARIO 539772] When Apply Payment Vendor Ledger Entry with Bill Vendor Ledger Entry then GL Entries are created with 
        // "GL Account No." of "Payables Account" of Vendor Posting Groups when "Allow Multiple Posting Groups" is true in Purchases & Payables Setup.
        Initialize();

        // [GIVEN] Set Allow Multiple Posting Groups as true in Purchases & Payables Setup.
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Allow Multiple Posting Groups" := true;
        PurchasesPayablesSetup.Modify();

        // [GIVEN] Create two Vendor Posting Groups.
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup[1]);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup[2]);

        // [GIVEN] Create Alternate Vendor Posting Group.
        LibraryPurchase.CreateAltVendorPostingGroup(VendorPostingGroup[1].Code, VendorPostingGroup[2].Code);

        // [GIVEN] Create Vendor and Validate Allow Multiple Groups and Vendor Posting Group.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Validate("Vendor Posting Group", VendorPostingGroup[1].Code);
        Vendor.Modify(true);

        // [GIVEN] Find Payment Method and Validate Create Bills.
        PaymentMethod.Get(Vendor."Payment Method Code");
        PaymentMethod.Validate("Create Bills", true);
        PaymentMethod.Modify(true);

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Header and Validate Prices Including VAT.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);

        // [GIVEN] Create Purchase Line and Validate Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(0));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(1000, 1000));
        PurchaseLine.Modify(true);

        // [GIVEN] Generate and sav Amount in a Variable.
        Amount := PurchaseLine."Direct Unit Cost";

        // [GIVEN] Post Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        CreateGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandIntInRange(1000, 1000));
        GenJournalLine.Validate("Applies-to Bill No.", PurchaseHeader."No.");
        GenJournalLine.Validate("Posting Group", VendorPostingGroup[2].Code);
        GenJournalLine.Validate("Debit Amount", LibraryRandom.RandIntInRange(1000, 1000));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Apply Payment Vendor Ledger Entry with Bill Vendor Ledger Entry.
        ApplyPurchDocuments(
            VendLedgEntry."Document Type"::Payment,
            GenJournalLine."Document No.",
            VendLedgEntry."Document Type"::Bill,
            LibraryRandom.RandIntInRange(1000, 1000));

        // [WHEN] Find GL Entry.
        GLEntry.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GLEntry.SetRange("G/L Account No.", VendorPostingGroup[2]."Payables Account");
        GLEntry.SetRange(Amount, -Amount);

        // [THEN] GL Entry is found.
        Assert.IsFalse(GLEntry.IsEmpty(), GLEntryMustBeFound);

        // [WHEN] Find GL Entry.
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("G/L Account No.", VendorPostingGroup[1]."Bills Account");
        GLEntry.SetRange(Amount, Amount);

        // [THEN] GL Entry is found.
        Assert.IsFalse(GLEntry.IsEmpty(), GLEntryMustBeFound);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTwoPurchInvoicesApplyPmtWithDifferentVendorsAndPostingGroups()
    var
        Vendor1, Vendor2 : Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorPostingGroup2: Record "Vendor Posting Group";
        GenJournalLine, GenJournalLine2 : Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchaseHeader, PurchaseHeader2 : Record "Purchase Header";
        PaymentMethod: Record "Payment Method";
        VendorLedgerEntry, VendorLedgerEntry2 : Record "Vendor Ledger Entry";
        LibraryCarteraCommon: Codeunit "Library - Cartera Common";
        LibraryCarteraPayables: Codeunit "Library - Cartera Payables";
        InvoiceNo, Invoice2No : Code[20];
        PaymentNo, Payment2No : Code[20];
        TotalAmount, TotalAmount2, SumOfAmountLCY : Decimal;
        PayablesAccountCodes: List of [Code[20]];
        CountOfGLEntries: Integer;
    begin
        // [SCENARIO 556900][ES] Posting a payment to a Cartera invoice that is not using bills fails - it is looking for a bills account
        Initialize();

        // [GIVEN] Posting two Cartera invoices for two vendors with different posting groups (vendors don't allow multiple posting groups)
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, false, true);
        LibraryCarteraPayables.CreateCarteraVendor(Vendor1, '', PaymentMethod.Code);
        Vendor1.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        Vendor1.Modify();
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader, Vendor1."No.");
        PurchaseHeader.CalcFields("Amount Including VAT");
        TotalAmount := PurchaseHeader."Amount Including VAT";
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryCarteraPayables.CreateCarteraVendor(Vendor2, '', PaymentMethod.Code);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup2);
        Vendor2.Validate("Vendor Posting Group", VendorPostingGroup2.Code);
        Vendor2.Modify();
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader2, Vendor2."No.");
        PurchaseHeader2.CalcFields("Amount Including VAT");
        TotalAmount2 := PurchaseHeader2."Amount Including VAT";
        Invoice2No := LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // [GIVEN] Two payments are entered in journal for that vendor with main posting group, pointing to two invoices with 'Applies-to Doc. No'
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, Vendor1."No.", TotalAmount);
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalLine.Validate("Posting Group", VendorPostingGroup.Code);
        GenJournalLine.Validate("Applies-to ID", UserId);
        GenJournalLine.Modify();
        ApplyVendEntryToGenJnlLine(InvoiceNo, VendorLedgerEntry."Document Type"::Invoice);
        PaymentNo := GenJournalLine."Document No.";
        VendorLedgerEntry.SetRange("Vendor No.", Vendor1."No.");
        VendorLedgerEntry.SetRange(Open, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, "Gen. Journal Document Type"::Invoice, InvoiceNo);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine2, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine2."Document Type"::Payment,
            GenJournalLine2."Account Type"::Vendor, Vendor2."No.", TotalAmount2);
        GenJournalLine2.Validate("Document No.", PaymentNo);
        GenJournalLine2.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalLine2.Validate("Posting Group", VendorPostingGroup2.Code);
        GenJournalLine2.Validate("Applies-to ID", UserId);
        GenJournalLine2.Modify(true);
        ApplyVendEntryToGenJnlLine(Invoice2No, VendorLedgerEntry2."Document Type"::Invoice);
        Payment2No := PaymentNo;
        VendorLedgerEntry2.SetRange("Vendor No.", Vendor2."No.");
        VendorLedgerEntry2.SetRange(Open, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry2, "Gen. Journal Document Type"::Invoice, Invoice2No);
        // [WHEN] Posting of the journal line (it doesn't fail saying that bills account must be specified)
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);

        // [THEN] The two vendor ledger entries should be closed (applied)
        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry2.Get(VendorLedgerEntry2."Entry No.");
        Assert.IsFalse(VendorLedgerEntry.Open, '');
        Assert.IsFalse(VendorLedgerEntry2.Open, '');

        // [THEN] The Amount on G/L Entries for payables accounts of the two posting groups should balance out
        PayablesAccountCodes.Add(VendorPostingGroup."Payables Account");
        PayablesAccountCodes.Add(VendorPostingGroup2."Payables Account");
        SumOfAmountLCY := SumGLEntryAmountsForPayablesAccounts(PayablesAccountCodes);
        CountOfGLEntries := CountGLEntryAmountsForPayablesAccounts(PayablesAccountCodes);
        Assert.AreEqual(0, SumOfAmountLCY, '');
        Assert.AreEqual(4, CountOfGLEntries, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTwoPurchInvoicesApplyBillPmtsWithDifferentPostingGroups()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorPostingGroup2: Record "Vendor Posting Group";
        GenJournalLine, GenJournalLine2 : Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchaseHeader, PurchaseHeader2 : Record "Purchase Header";
        PaymentMethod: Record "Payment Method";
        VendorLedgerEntry, VendorLedgerEntry2 : Record "Vendor Ledger Entry";
        LibraryCarteraCommon: Codeunit "Library - Cartera Common";
        LibraryCarteraPayables: Codeunit "Library - Cartera Payables";
        InvoiceNo, Invoice2No : Code[20];
        PaymentNo, Payment2No : Code[20];
        TotalAmount, TotalAmount2, SumOfAmountLCY : Decimal;
        PayablesAccountCodes, BillsAccountCodes : List of [Code[20]];
        CountGLEntries: Integer;
    begin
        // [SCENARIO 557674][ES] Issues with applying payments to  Bills
        Initialize();

        // [GIVEN] Posting two Cartera invoices for one vendor with different posting groups (vendors allow multiple posting groups, payent method is using Bills)
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, true, false);
        LibraryCarteraPayables.CreateCarteraVendor(Vendor, '', PaymentMethod.Code);
        Vendor.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Modify();
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");
        PurchaseHeader.CalcFields("Amount Including VAT");
        TotalAmount := PurchaseHeader."Amount Including VAT";
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup2);
        LibraryPurchase.CreateAltVendorPostingGroup(VendorPostingGroup.Code, VendorPostingGroup2.Code);
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader2, Vendor."No.");
        PurchaseHeader2.Validate("Vendor Posting Group", VendorPostingGroup2.Code);
        PurchaseHeader2.CalcFields("Amount Including VAT");
        TotalAmount2 := PurchaseHeader2."Amount Including VAT";
        Invoice2No := LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // [GIVEN] Two payments are entered in journal for that vendor with main posting group, pointing to two invoices with 'Applies-to ID'
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, Vendor."No.", TotalAmount);
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalLine.Validate("Posting Group", VendorPostingGroup.Code);
        GenJournalLine.Validate("Applies-to ID", UserId);
        GenJournalLine.Modify();
        ApplyVendEntryToGenJnlLine(InvoiceNo, VendorLedgerEntry."Document Type"::Bill);
        PaymentNo := GenJournalLine."Document No.";
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.SetRange(Open, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, "Gen. Journal Document Type"::Bill, InvoiceNo);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine2, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine2."Document Type"::Payment,
            GenJournalLine2."Account Type"::Vendor, Vendor."No.", TotalAmount2);
        GenJournalLine2.Validate("Document No.", PaymentNo);
        GenJournalLine2.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalLine2.Validate("Posting Group", VendorPostingGroup.Code);
        GenJournalLine2.Validate("Applies-to ID", UserId);
        GenJournalLine2.Modify(true);
        ApplyVendEntryToGenJnlLine(Invoice2No, VendorLedgerEntry2."Document Type"::Bill);
        Payment2No := PaymentNo;
        VendorLedgerEntry2.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry2.SetRange(Open, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry2, "Gen. Journal Document Type"::Bill, Invoice2No);
        // [WHEN] Posting of the journal line (it doesn't fail saying that bills account must be specified)
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);

        // [THEN] The two vendor ledger entries should be closed (applied)
        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry2.Get(VendorLedgerEntry2."Entry No.");
        Assert.IsFalse(VendorLedgerEntry.Open, '');
        Assert.IsFalse(VendorLedgerEntry2.Open, '');

        // [THEN] The Amount on G/L Entries for payables accounts of the two posting groups should balance out
        PayablesAccountCodes.Add(VendorPostingGroup."Payables Account");
        PayablesAccountCodes.Add(VendorPostingGroup2."Payables Account");
        SumOfAmountLCY := SumGLEntryAmountsForPayablesAccounts(PayablesAccountCodes);
        CountGLEntries := CountGLEntryAmountsForPayablesAccounts(PayablesAccountCodes);
        Assert.AreEqual(0, SumOfAmountLCY, '');
        Assert.AreEqual(6, CountGLEntries, '');

        // [THEN] The Amount on G/L Entries for bills accounts of the two posting groups should balance out
        BillsAccountCodes.Add(VendorPostingGroup."Bills Account");
        BillsAccountCodes.Add(VendorPostingGroup2."Bills Account");
        SumOfAmountLCY := SumGLEntryAmountsForPayablesAccounts(BillsAccountCodes);
        CountGLEntries := CountGLEntryAmountsForPayablesAccounts(BillsAccountCodes);
        Assert.AreEqual(0, SumOfAmountLCY, '');
        Assert.AreEqual(4, CountGLEntries, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTwoPurchInvoicesApplyBillPmtsWithDifferentPostingGroupsAppliesToDocNo()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorPostingGroup2: Record "Vendor Posting Group";
        GenJournalLine, GenJournalLine2 : Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchaseHeader, PurchaseHeader2 : Record "Purchase Header";
        PaymentMethod: Record "Payment Method";
        VendorLedgerEntry, VendorLedgerEntry2 : Record "Vendor Ledger Entry";
        LibraryCarteraCommon: Codeunit "Library - Cartera Common";
        LibraryCarteraPayables: Codeunit "Library - Cartera Payables";
        InvoiceNo, Invoice2No : Code[20];
        PaymentNo, Payment2No : Code[20];
        TotalAmount, TotalAmount2, SumOfAmountLCY : Decimal;
        PayablesAccountCodes, BillsAccountCodes : List of [Code[20]];
        CountGLEntries: Integer;
    begin
        // [SCENARIO 557674][ES] Issues with applying payments to Bills
        Initialize();

        // [GIVEN] Posting two Cartera invoices for one vendor with different posting groups (vendors allow multiple posting groups, payent method is using Bills)
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, true, false);
        LibraryCarteraPayables.CreateCarteraVendor(Vendor, '', PaymentMethod.Code);
        Vendor.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Modify();
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");
        PurchaseHeader.CalcFields("Amount Including VAT");
        TotalAmount := PurchaseHeader."Amount Including VAT";
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup2);
        LibraryPurchase.CreateAltVendorPostingGroup(VendorPostingGroup.Code, VendorPostingGroup2.Code);
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader2, Vendor."No.");
        PurchaseHeader2.Validate("Vendor Posting Group", VendorPostingGroup2.Code);
        PurchaseHeader2.CalcFields("Amount Including VAT");
        TotalAmount2 := PurchaseHeader2."Amount Including VAT";
        Invoice2No := LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // [GIVEN] Two payments are entered in journal for that vendor with main posting group, pointing to two invoices with 'Applies-to Doc. No.'
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.SetRange(Open, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, "Gen. Journal Document Type"::Bill, InvoiceNo);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, Vendor."No.", TotalAmount);
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalLine.Validate("Posting Group", VendorPostingGroup.Code);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Bill);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);
        GenJournalLine.Validate("Applies-to Bill No.", VendorLedgerEntry."Bill No.");
        GenJournalLine.Modify();
        PaymentNo := GenJournalLine."Document No.";
        VendorLedgerEntry2.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry2.SetRange(Open, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry2, "Gen. Journal Document Type"::Bill, Invoice2No);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine2, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine2."Document Type"::Payment,
            GenJournalLine2."Account Type"::Vendor, Vendor."No.", TotalAmount2);
        GenJournalLine2.Validate("Document No.", PaymentNo);
        GenJournalLine2.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalLine2.Validate("Posting Group", VendorPostingGroup.Code);
        GenJournalLine2.Validate("Applies-to Doc. Type", GenJournalLine2."Applies-to Doc. Type"::Bill);
        GenJournalLine2.Validate("Applies-to Doc. No.", Invoice2No);
        GenJournalLine2.Validate("Applies-to Bill No.", VendorLedgerEntry2."Bill No.");
        GenJournalLine2.Modify(true);
        Payment2No := PaymentNo;
        // [WHEN] Posting of the journal line (it doesn't fail saying that bills account must be specified)
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);

        // [THEN] The two vendor ledger entries should be closed (applied)
        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry2.Get(VendorLedgerEntry2."Entry No.");
        Assert.IsFalse(VendorLedgerEntry.Open, '');
        Assert.IsFalse(VendorLedgerEntry2.Open, '');

        // [THEN] The Amount on G/L Entries for payables accounts of the two posting groups should balance out
        PayablesAccountCodes.Add(VendorPostingGroup."Payables Account");
        PayablesAccountCodes.Add(VendorPostingGroup2."Payables Account");
        SumOfAmountLCY := SumGLEntryAmountsForPayablesAccounts(PayablesAccountCodes);
        CountGLEntries := CountGLEntryAmountsForPayablesAccounts(PayablesAccountCodes);
        Assert.AreEqual(0, SumOfAmountLCY, '');
        Assert.AreEqual(6, CountGLEntries, '');

        // [THEN] The Amount on G/L Entries for bills accounts of the two posting groups should balance out
        BillsAccountCodes.Add(VendorPostingGroup."Bills Account");
        BillsAccountCodes.Add(VendorPostingGroup2."Bills Account");
        SumOfAmountLCY := SumGLEntryAmountsForPayablesAccounts(BillsAccountCodes);
        CountGLEntries := CountGLEntryAmountsForPayablesAccounts(BillsAccountCodes);
        Assert.AreEqual(0, SumOfAmountLCY, '');
        Assert.AreEqual(4, CountGLEntries, '');
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler,PostApplicationHandler,MessageHandler')]
    procedure CheckTwoGeneralJouranlApplyBillPmtsWithDifferentPostingGroups()
    var
        DetailedVendorLedgerEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentMethod: Record "Payment Method";
        Vendor: Record Vendor;
        VendorPostingGroup: array[2] of Record "Vendor Posting Group";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        LibraryCarteraCommon: Codeunit "Library - Cartera Common";
        LibraryCarteraPayables: Codeunit "Library - Cartera Payables";
        VendorLedgerEntryPage: TestPage "Vendor Ledger Entries";
        TotalAmount: Decimal;
    begin
        // [SCENARIO 576372] Application of Vendor Ledger Entries with Alternative Posting Groups using Blank Document Type creates General Ledger Entries.
        Initialize();

        // [GIVEN] Create two Vendor Posting Groups and a Payment Method.
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup[1]);

        // [GIVEN] Create a Payment Method with Invoices to Cartera.
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, true, false);

        // [GIVEN] Create a Vendor with Allow Multiple Posting Groups and Vendor Posting Group.
        LibraryCarteraPayables.CreateCarteraVendor(Vendor, '', PaymentMethod.Code);
        Vendor.Validate("Vendor Posting Group", VendorPostingGroup[1].Code);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Modify();

        // [GIVEN] Create and store a random Total Amount.
        TotalAmount := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Create a second Vendor Posting Group and an Alternate Vendor Posting Group.
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup[2]);
        LibraryPurchase.CreateAltVendorPostingGroup(VendorPostingGroup[1].Code, VendorPostingGroup[2].Code);

        // [GIVEN] Create a General Journal Batch.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);

        // [GIVEN] Create two General Journal Lines with the same Document No. and different Vendor Posting Groups.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[1],
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine[1]."Document Type"::" ",
            GenJournalLine[1]."Account Type"::Vendor,
            Vendor."No.",
            TotalAmount);
        GenJournalLine[1].Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalLine[1].Validate("Posting Group", VendorPostingGroup[1].Code);
        GenJournalLine[1].Modify();

        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[2],
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine[2]."Document Type"::" ",
            GenJournalLine[2]."Account Type"::Vendor,
            Vendor."No.",
            -TotalAmount);
        GenJournalLine[2].Validate("Document No.", GenJournalLine[1]."Document No.");
        GenJournalLine[2].Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalLine[2].Validate("Posting Group", VendorPostingGroup[2].Code);
        GenJournalLine[2].Modify(true);

        // [GIVEN] Post the two General Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine[1]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine[2]);

        // [GIVEN] Apply the two Vendor Ledger Entries using the Vendor Ledger Entries page.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, "Gen. Journal Document Type"::" ", GenJournalLine[1]."Document No.");
        VendorLedgerEntryPage.OpenEdit();
        VendorLedgerEntryPage.GoToRecord(VendorLedgerEntry);
        VendorLedgerEntryPage.ActionApplyEntries.Invoke();

        // [THEN] Detailed Vendor Ledger Entry is created for the Vendor with the Application Type as 'Application'.
        DetailedVendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        DetailedVendorLedgerEntry.SetRange("Entry Type", DetailedVendorLedgerEntry."Entry Type"::Application);
        DetailedVendorLedgerEntry.FindFirst();
        Assert.RecordIsNotEmpty(DetailedVendorLedgerEntry);
    end;

    local procedure SumGLEntryAmountsForPayablesAccounts(var PayablesAccountCodes: List of [Code[20]]): Decimal
    var
        GLEntry: Record "G/L Entry";
        AccountCode: Code[20];
        Started: Boolean;
        FilterString: Text;
    begin
        foreach AccountCode in PayablesAccountCodes do begin
            if Started then
                FilterString += '|'
            else
                Started := true;
            FilterString += Format(AccountCode);
        end;
        GLEntry.SetFilter("G/L Account No.", FilterString);
        GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::"G/L Account");
        GLEntry.CalcSums(Amount);
        exit(GLEntry.Amount);
    end;

    local procedure CountGLEntryAmountsForPayablesAccounts(var PayablesAccountCodes: List of [Code[20]]): Integer
    var
        GLEntry: Record "G/L Entry";
        AccountCode: Code[20];
        Started: Boolean;
        FilterString: Text;
    begin
        foreach AccountCode in PayablesAccountCodes do begin
            if Started then
                FilterString += '|'
            else
                Started := true;
            FilterString += Format(AccountCode);
        end;
        GLEntry.SetFilter("G/L Account No.", FilterString);
        GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::"G/L Account");
        exit(GLEntry.Count());
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure ApplyCustEntryToGenJnlLine(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Amount (LCY)");
    end;

    local procedure ApplyVendEntryToGenJnlLine(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Amount (LCY)");
    end;

    local procedure ApplySalesDocuments(DocType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; ApplDocType: Enum "Gen. Journal Document Type"; AmountToApply: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocType, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
        CustLedgerEntry2.SetRange("Document Type", ApplDocType);
        CustLedgerEntry2.SetRange("Customer No.", CustLedgerEntry."Customer No.");
        CustLedgerEntry2.SetRange(Open, true);
        CustLedgerEntry2.FindSet();
        repeat
            CustLedgerEntry2.CalcFields("Remaining Amount");
            CustLedgerEntry2.Validate("Amount to Apply", -AmountToApply);
            CustLedgerEntry2.Modify(true);
        until CustLedgerEntry2.Next() = 0;

        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure ApplyPurchDocuments(DocType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; ApplDocType: Enum "Gen. Journal Document Type"; AmountToApply: Decimal)
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgerEntry, DocType, DocumentNo);
        LibraryERM.SetApplyVendorEntry(VendLedgerEntry, AmountToApply);
        VendLedgerEntry2.SetRange("Document Type", ApplDocType);
        VendLedgerEntry2.SetRange("Vendor No.", VendLedgerEntry."Vendor No.");
        VendLedgerEntry2.SetRange(Open, true);
        VendLedgerEntry2.FindSet();
        repeat
            VendLedgerEntry2.CalcFields("Remaining Amount");
            VendLedgerEntry2.Validate("Amount to Apply", -AmountToApply);
            VendLedgerEntry2.Modify(true);
        until VendLedgerEntry2.Next() = 0;

        LibraryERM.SetAppliestoIdVendor(VendLedgerEntry2);
        LibraryERM.PostVendLedgerApplication(VendLedgerEntry);
    end;

    local procedure ClearCustApplyingEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Applying Entry", true);
        if CustLedgerEntry.FindSet() then
            repeat
                CustLedgerEntry.Validate("Applying Entry", false);
                CustLedgerEntry.Modify(true);
            until CustLedgerEntry.Next() = 0;

        CustLedgerEntry.Reset();
        CustLedgerEntry.SetFilter("Applies-to ID", '<>%1', '');
        if CustLedgerEntry.FindSet() then
            repeat
                CustLedgerEntry.Validate("Applies-to ID", '');
                CustLedgerEntry.Modify(true);
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure ClearVendApplyingEntries()
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgerEntry.SetRange("Applying Entry", true);
        if VendLedgerEntry.FindSet() then
            repeat
                VendLedgerEntry.Validate("Applying Entry", false);
                VendLedgerEntry.Modify(true);
            until VendLedgerEntry.Next() = 0;

        VendLedgerEntry.Reset();
        VendLedgerEntry.SetFilter("Applies-to ID", '<>%1', '');
        if VendLedgerEntry.FindSet() then
            repeat
                VendLedgerEntry.Validate("Applies-to ID", '');
                VendLedgerEntry.Modify(true);
            until VendLedgerEntry.Next() = 0;
    end;

    local procedure CreateCustomer(PaymentMethodCreatesBill: Boolean; CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Method Code", CreatePaymentMethodCode(PaymentMethodCreatesBill));
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustWithPmtMethod(PaymentMethodCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Method Code", PaymentMethodCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(PaymentMethodCreatesBill: Boolean; CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Method Code", CreatePaymentMethodCode(PaymentMethodCreatesBill));
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendWithPmtMethod(PaymentTermsCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Method Code", PaymentTermsCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal): Code[20]
    begin
        CreateGenJnlLine(GenJournalLine, DocType, AccountType, AccountNo, -Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostGenJnlLineWithSpecificDocNo(var GenJournalLine: Record "Gen. Journal Line"; DocNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, -Amount);
        GenJournalLine.Validate("Document No.", DocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostApplyGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; InvoiceNo: Code[20]; BillNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal): Code[20]
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, -Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Bill);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);
        GenJournalLine.Validate("Applies-to Bill No.", BillNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreatePaymentGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal): Code[20]
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, -Amount);
        exit(GenJournalLine."Document No.");
    end;

    local procedure UnapplySalesDocument(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure UnapplyPurchDocument(VendorNo: Code[20]; DocumentNo: Code[20])
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgerEntry.SetRange("Document No.", DocumentNo);
        VendLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendLedgerEntry.FindFirst();
        LibraryERM.UnapplyVendorLedgerEntry(VendLedgerEntry);
    end;

    local procedure UnapplySalesViaPage(CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustEntryApplyPostedEntries.UnApplyCustLedgEntry(CustLedgerEntry."Entry No.");
    end;

    local procedure UnapplyPurchaseViaPage(VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendEntryApplyPostedEntries.UnApplyVendLedgEntry(VendorLedgerEntry."Entry No.");
    end;

    local procedure CreateAndPostSalesDocument(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; CustomerNo: Code[20]; var Amount: Decimal): Code[20]
    begin
        CreateSalesDocument(SalesHeader, DocType, CustomerNo, Amount);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesDocumentWOutBill(DocType: Enum "Sales Document Type"; CustomerNo: Code[20]; Amount: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustomerNo);
        SalesHeader.Validate("Payment Method Code", CreatePaymentMethodCode(false));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostApplySalesDocument(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; CustomerNo: Code[20]; var Amount: Decimal; ApplType: Option; ApplDocNo: Code[20]): Code[20]
    begin
        CreateSalesDocument(SalesHeader, DocType, CustomerNo, Amount);
        SalesHeader.Validate("Applies-to Doc. Type", ApplType);
        SalesHeader.Validate("Applies-to Doc. No.", ApplDocNo);
        SalesHeader.Validate("Applies-to Bill No.", '1');
        SalesHeader.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesPaymentAppliedToInvoiceAndBill(CustomerNo: Code[20]; InvNo: Code[20]; BillNo: Code[20]; PaymentAmount: Decimal) PaymentNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        RefCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        PaymentNo := CreatePaymentGenJnlLine(GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, PaymentAmount);
        ClearCustApplyingEntries();
        ApplyCustEntryToGenJnlLine(InvNo, RefCustLedgerEntry."Document Type"::Invoice);
        ApplyCustEntryToGenJnlLine(BillNo, RefCustLedgerEntry."Document Type"::Bill);

        GenJournalLine."Applies-to ID" := UserId;
        GenJournalLine.Modify();

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; CustomerNo: Code[20]; var Amount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), 1);
        if Amount <> 0 then begin
            SalesLine.Validate("Unit Price", Amount);
            SalesLine.Modify(true);
        end;
        SalesHeader.CalcFields(Amount, "Amount Including VAT");
        Amount := SalesHeader."Amount Including VAT";
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"; VendorNo: Code[20]; var Amount: Decimal): Code[20]
    begin
        CreatePurchaseDocument(PurchaseHeader, DocType, VendorNo, Amount);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseDocumentWOutBill(DocType: Enum "Purchase Document Type"; VendorNo: Code[20]; Amount: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, VendorNo);
        PurchaseHeader.Validate("Payment Method Code", CreatePaymentMethodCode(false));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePostApplyPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"; VendorNo: Code[20]; var Amount: Decimal; ApplType: Option; ApplDocNo: Code[20]): Code[20]
    begin
        CreatePurchaseDocument(PurchaseHeader, DocType, VendorNo, Amount);
        PurchaseHeader.Validate("Applies-to Doc. Type", ApplType);
        PurchaseHeader.Validate("Applies-to Doc. No.", ApplDocNo);
        PurchaseHeader.Validate("Applies-to Bill No.", '1');
        PurchaseHeader.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostPurchasePaymentAppliedToInvoiceAndBill(VendorNo: Code[20]; InvNo: Code[20]; BillNo: Code[20]; PaymentAmount: Decimal) PaymentNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        RefVendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        PaymentNo := CreatePaymentGenJnlLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, PaymentAmount);
        ClearVendApplyingEntries();
        ApplyVendEntryToGenJnlLine(InvNo, RefVendorLedgerEntry."Document Type"::Invoice);
        ApplyVendEntryToGenJnlLine(BillNo, RefVendorLedgerEntry."Document Type"::Bill);

        GenJournalLine."Applies-to ID" := UserId;
        GenJournalLine.Modify();

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"; VendorNo: Code[20]; var Amount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), 1);
        if Amount <> 0 then begin
            PurchaseLine.Validate("Direct Unit Cost", Amount);
            PurchaseLine.Modify(true);
        end;
        PurchaseHeader.CalcFields(Amount, "Amount Including VAT");
        Amount := PurchaseHeader."Amount Including VAT";
    end;

    local procedure GetFirstBillNo(DocumentNo: Code[20]; CarteraDocType: Enum "Cartera Document Type"): Code[20]
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.SetRange(Type, CarteraDocType);
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.FindFirst();
        exit(CarteraDoc."No.");
    end;

    local procedure FindLastPostedSalesDocumentBill(CustomerNo: Code[20]): Code[20]
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Bill);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.FindLast();
        CustLedgerEntry.Validate("Bill No.", '');
        CustLedgerEntry.Modify(true);
        exit(CustLedgerEntry."Document No.");
    end;

    local procedure FindLastPostedPurchDocumentBill(VendorNo: Code[20]): Code[20]
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgerEntry.SetRange("Document Type", VendLedgerEntry."Document Type"::Bill);
        VendLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendLedgerEntry.SetRange(Open, true);
        VendLedgerEntry.FindLast();
        VendLedgerEntry.Validate("Bill No.", '');
        VendLedgerEntry.Modify(true);
        exit(VendLedgerEntry."Document No.");
    end;

    local procedure CreateCarteraJournalLines(var GenJournalLine: Record "Gen. Journal Line"; InvoiceNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Cartera);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        GenJournalBatch.SetRange("Template Type", GenJournalBatch."Template Type"::Cartera);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, AccountType, AccountNo, -Amount);

        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Modify(true);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Bill, AccountType, AccountNo, Amount);

        GenJournalLine.Validate("Payment Method Code", CreatePaymentMethodCode(true));
        GenJournalLine.Validate("Bill No.", '1');
        GenJournalLine.Validate("Document No.", InvoiceNo);
        GenJournalLine.Modify(true);
    end;

    local procedure FindLastTransactionNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.FindLast();
        exit(GLEntry."Transaction No.");
    end;

    local procedure CreatePaymentMethodCode(CreateBills: Boolean): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Create Bills", CreateBills);
        PaymentMethod.Modify(true);
        exit(PaymentMethod.Code);
    end;

    local procedure CreatePaymentMethodWithInvoicesToCartera(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Invoices to Cartera", true);
        PaymentMethod.Modify(true);
        exit(PaymentMethod.Code);
    end;

    local procedure ReverseTransaction(TransactionNo: Integer)
    var
        ReversalEntry: Record "Reversal Entry";
    begin
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(TransactionNo);
    end;

    local procedure GetCustomerBillsAccount(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        exit(CustomerPostingGroup."Bills Account");
    end;

    local procedure GetCustomerReceivablesAccount(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        exit(CustomerPostingGroup."Receivables Account");
    end;

    local procedure GetSalesInvoiceAmount(InvoiceNo: Code[20]): Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", InvoiceNo);
        SalesInvoiceLine.CalcSums("Amount Including VAT");
        exit(SalesInvoiceLine."Amount Including VAT");
    end;

    local procedure GetPurchaseInvoiceAmount(InvoiceNo: Code[20]): Decimal
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", InvoiceNo);
        PurchInvLine.CalcSums("Amount Including VAT");
        exit(PurchInvLine."Amount Including VAT");
    end;

    local procedure GetVendorBillsAccount(VendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendorNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        exit(VendorPostingGroup."Bills Account");
    end;

    local procedure GetVendorPayablesAccount(VendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendorNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        exit(VendorPostingGroup."Payables Account");
    end;

    local procedure SetApplyCustomerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; AmountToApply: Decimal)
    begin
        CustLedgerEntry.Validate("Applying Entry", true);
        CustLedgerEntry.Validate("Applies-to ID", UserId);
        CustLedgerEntry.Validate("Amount to Apply", AmountToApply);
        CustLedgerEntry.Modify(true);
        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgerEntry);
    end;

    local procedure SetApplyVendorEntry(var VendLedgerEntry: Record "Vendor Ledger Entry"; AmountToApply: Decimal)
    begin
        VendLedgerEntry.Validate("Applying Entry", true);
        VendLedgerEntry.Validate("Applies-to ID", UserId);
        VendLedgerEntry.Validate("Amount to Apply", AmountToApply);
        VendLedgerEntry.Modify(true);
        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgerEntry);
    end;

    local procedure VerifyVendorApplnGLEntries(VendorNo: Code[20]; DocumentNo: Code[20]; LastTransactionNo: Integer; AmountBill: Decimal; AmountPayables: Decimal)
    var
        GLEntry: Record "G/L Entry";
        VendPostingGr: Record "Vendor Posting Group";
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        VendPostingGr.Get(Vendor."Vendor Posting Group");
        FindLastGLEntry(GLEntry, DocumentNo, LastTransactionNo);

        GLEntry.TestField("G/L Account No.", VendPostingGr."Bills Account");
        GLEntry.TestField(Amount, AmountBill);

        GLEntry.Next(-1);
        GLEntry.TestField("G/L Account No.", VendPostingGr."Payables Account");
        GLEntry.TestField(Amount, AmountPayables);
    end;

    local procedure VerifyEmployeeLedgerEntry(EmployeeNo: Code[20]; ExpectedAmount: Decimal)
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeLedgerEntry.FindFirst();
        EmployeeLedgerEntry.CalcFields(Amount);
        EmployeeLedgerEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyCustomerApplnGLEntries(CustomerNo: Code[20]; DocumentNo: Code[20]; LastTransactionNo: Integer; AmountBill: Decimal; AmountReceivables: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindLastGLEntry(GLEntry, DocumentNo, LastTransactionNo);

        GLEntry.TestField("G/L Account No.", GetCustomerBillsAccount(CustomerNo));
        GLEntry.TestField(Amount, AmountBill);

        GLEntry.Next(-1);
        GLEntry.TestField("G/L Account No.", GetCustomerReceivablesAccount(CustomerNo));
        GLEntry.TestField(Amount, AmountReceivables);
    end;

    local procedure VerifyCustGLUnapplication(CustomerNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        VerifyUnappliedGLEntries(
          DocumentNo, SourceCodeSetup."Unapplied Sales Entry Appln.",
          GetCustomerReceivablesAccount(CustomerNo), GetCustomerBillsAccount(CustomerNo), Amount);
    end;

    local procedure VerifyVendGLUnapplication(VendorNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        VerifyUnappliedGLEntries(
          DocumentNo, SourceCodeSetup."Unapplied Purch. Entry Appln.",
          GetVendorBillsAccount(VendorNo), GetVendorPayablesAccount(VendorNo), Amount);
    end;

    local procedure VerifyCustGLReapply(CustomerNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal; TransactionNo: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        VerifyGLEntriesWithTransaction(
          DocumentNo, SourceCodeSetup."Sales Entry Application",
          GetCustomerReceivablesAccount(CustomerNo), GetCustomerBillsAccount(CustomerNo), Amount, TransactionNo);
    end;

    local procedure VerifyVendGLReapply(VendorNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal; TransactionNo: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        VerifyGLEntriesWithTransaction(
          DocumentNo, SourceCodeSetup."Purchase Entry Application",
          GetVendorPayablesAccount(VendorNo), GetVendorBillsAccount(VendorNo), -Amount, TransactionNo);
    end;

    local procedure VerifyCustUnappliedGLWithTransaction(CustomerNo: Code[20]; DocumentNo: Code[20]; Amount1: Decimal; Amount2: Decimal; TransactionNo1: Integer; TransactionNo2: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();

        VerifyGLEntriesWithTransaction(
          DocumentNo, SourceCodeSetup."Unapplied Sales Entry Appln.",
          GetCustomerBillsAccount(CustomerNo), GetCustomerReceivablesAccount(CustomerNo), Amount1, TransactionNo1);

        VerifyGLEntriesSameAccountWithTransaction(
          DocumentNo, SourceCodeSetup."Unapplied Sales Entry Appln.",
          GetCustomerReceivablesAccount(CustomerNo), Amount2, TransactionNo2);
    end;

    local procedure VerifyVendUnappliedGLWithTransaction(VendorNo: Code[20]; DocumentNo: Code[20]; Amount1: Decimal; Amount2: Decimal; TransactionNo1: Integer; TransactionNo2: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();

        VerifyGLEntriesWithTransaction(
          DocumentNo, SourceCodeSetup."Unapplied Purch. Entry Appln.",
          GetVendorBillsAccount(VendorNo), GetVendorPayablesAccount(VendorNo), -Amount1, TransactionNo1);

        VerifyGLEntriesSameAccountWithTransaction(
          DocumentNo, SourceCodeSetup."Unapplied Purch. Entry Appln.",
          GetVendorPayablesAccount(VendorNo), Amount2, TransactionNo2);
    end;

    local procedure VerifyCustPaymentUnappliedGLEntries(DocumentNo: Code[20]; CustomerNo: Code[20]; BillAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GLEntry: Record "G/L Entry";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();

        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.FindLast();

        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Transaction No.", DetailedCustLedgEntry."Transaction No.");
        GLEntry.SetRange("G/L Account No.", CustomerPostingGroup.GetBillsAccount(false));
        Assert.RecordCount(GLEntry, 1);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, BillAmount);
    end;

    local procedure VerifyVendPaymentUnappliedGLEntries(DocumentNo: Code[20]; VendorNo: Code[20]; BillAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GLEntry: Record "G/L Entry";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendorNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();

        DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
        DetailedVendorLedgEntry.FindLast();

        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Transaction No.", DetailedVendorLedgEntry."Transaction No.");
        GLEntry.SetRange("G/L Account No.", VendorPostingGroup.GetBillsAccount());
        Assert.RecordCount(GLEntry, 1);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -BillAmount);
    end;

    local procedure VerifyUnappliedGLEntries(DocumentNo: Code[20]; SourceCode: Code[10]; GLAccNo: Code[20]; BalGLAccNo: Code[20]; GLAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Source Code", SourceCode);

        GLEntry.SetRange("G/L Account No.", BalGLAccNo);
        GLEntry.FindFirst();
        GLEntry.TestField("Credit Amount", -GLAmount);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.FindFirst();
        GLEntry.TestField("Debit Amount", -GLAmount);
    end;

    local procedure VerifyGLEntriesWithTransaction(DocumentNo: Code[20]; SourceCode: Code[10]; GLAccNo: Code[20]; BalGLAccNo: Code[20]; GLAmount: Decimal; TransactionNo: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetFilter("Transaction No.", '>%1', TransactionNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Source Code", SourceCode);

        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, GLAmount);
        GLEntry.SetRange("G/L Account No.", BalGLAccNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -GLAmount);
    end;

    local procedure VerifyGLEntriesSameAccountWithTransaction(DocumentNo: Code[20]; SourceCode: Code[10]; GLAccNo: Code[20]; GLAmount: Decimal; TransactionNo: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetFilter("Transaction No.", '>%1', TransactionNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Source Code", SourceCode);

        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.FindSet();
        GLEntry.TestField(Amount);
        GLAmount := GLAmount * (GLEntry.Amount / Abs(GLEntry.Amount));

        GLEntry.Next();
        GLEntry.TestField(Amount, -GLAmount);
    end;

    local procedure VerifyReceivablesAccountInGLEntryOfPmtToRefUnapplication(CustNo: Code[20]; DocNo: Code[20])
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Customer No.", CustNo);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange(Unapplied, true);
        DetailedCustLedgEntry.FindLast();

        VerifyPairedGLEntriesWithSameTransaction(
          DocNo, DetailedCustLedgEntry."Transaction No.", GetCustomerReceivablesAccount(CustNo));
    end;

    local procedure VerifyPayablesAccountInGLEntryOfPmtToRefUnapplication(VendNo: Code[20]; DocNo: Code[20])
    var
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendLedgEntry.SetRange("Entry Type", DetailedVendLedgEntry."Entry Type"::Application);
        DetailedVendLedgEntry.SetRange("Vendor No.", VendNo);
        DetailedVendLedgEntry.SetRange(Unapplied, true);
        DetailedVendLedgEntry.FindLast();

        VerifyPairedGLEntriesWithSameTransaction(
          DocNo, DetailedVendLedgEntry."Transaction No.", GetVendorPayablesAccount(VendNo));
    end;

    local procedure VerifyPairedGLEntriesWithSameTransaction(DocNo: Code[20]; TransactionNo: Integer; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("Transaction No.", TransactionNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        Assert.RecordCount(GLEntry, 2);
    end;

    local procedure VerifyCustAppliedGLEntriesAddCurrAmountNotEmpty(CustomerNo: Code[20]; AddCurrAmount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GLEntry: Record "G/L Entry";
    begin
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.FindFirst();

        GLEntry.SetRange("Transaction No.", DetailedCustLedgEntry."Transaction No.");
        GLEntry.FindSet();
        repeat
            if GLEntry.Amount > 0 then
                GLEntry.TestField("Additional-Currency Amount", AddCurrAmount)
            else
                GLEntry.TestField("Additional-Currency Amount", -AddCurrAmount);
        until GLEntry.Next() = 0;
    end;

    local procedure FindLastGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; LastTransactionNo: Integer)
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Transaction No.", LastTransactionNo);
        GLEntry.FindLast();
    end;

    local procedure VerifyPaymentGLEntryCount(DocumentNo: Code[20]; GLAccount: Code[20]; ExpectedCount: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccount);
        Assert.RecordCount(GLEntry, ExpectedCount);
    end;

    local procedure ApplyEmployeeLedgerEntries(EmployeeNo: Code[20]; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        EmployeeLedgerEntriesPage: TestPage "Employee Ledger Entries";
    begin
        EmployeeLedgerEntriesPage.OpenView();
        EmployeeLedgerEntriesPage.FILTER.SetFilter("Employee No.", EmployeeNo);
        EmployeeLedgerEntriesPage.FILTER.SetFilter("Document No.", DocumentNo);
        EmployeeLedgerEntriesPage.FILTER.SetFilter("Document Type", Format(DocumentType));
        EmployeeLedgerEntriesPage.ActionApplyEntries.Invoke();
    end;

    local procedure UnApplyEmployeeLedgerEntries(EmployeeNo: Code[20]; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        EmployeeLedgerEntriesPage: TestPage "Employee Ledger Entries";
    begin
        EmployeeLedgerEntriesPage.OpenView();
        EmployeeLedgerEntriesPage.FILTER.SetFilter("Employee No.", EmployeeNo);
        EmployeeLedgerEntriesPage.FILTER.SetFilter("Document No.", DocumentNo);
        EmployeeLedgerEntriesPage.FILTER.SetFilter("Document Type", Format(DocumentType));
        EmployeeLedgerEntriesPage.UnapplyEntries.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [ModalPageHandler]
    procedure UnapplyCustomerEntriesMPH(var UnapplyCustomerEntries: TestPage "Unapply Customer Entries")
    begin
        UnapplyCustomerEntries.Unapply.Invoke();
    end;

    [ModalPageHandler]
    procedure UnapplyVendorEntriesMPH(var UnapplyVendorEntries: TestPage "Unapply Vendor Entries")
    begin
        UnapplyVendorEntries.Unapply.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyEmployeeEntriesHandler(var ApplyEmployeeEntries: TestPage "Apply Employee Entries")
    begin
        ApplyEmployeeEntries.ActionSetAppliesToID.Invoke();
        ApplyEmployeeEntries.ActionPostApplication.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnApplyEmployeeEntriesHandler(var UnApplyEmployeeEntries: TestPage "Unapply Employee Entries")
    begin
        UnApplyEmployeeEntries.Unapply.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationHandler(var PostApplication: TestPage "Post Application")
    begin
        PostApplication.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.ActionPostApplication.Invoke();
    end;
}

