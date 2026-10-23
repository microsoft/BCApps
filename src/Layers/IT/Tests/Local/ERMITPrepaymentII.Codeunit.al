codeunit 144173 "ERM IT Prepayment II"
{
    //  1. Test to verify values on VAT Entry after applying Sales Prepayment Invoice to Payment with Unrealized VAT.
    //  2. Test to verify values on VAT Entry after Posting Sales Order when Sales Prepayment Invoice applied to payment with Unrealized VAT.
    //  3. Test to verify values on GL Book Entry after posting Sales Invoice with full Prepayment.
    //  4. Test to verify values on Sales Invoice Header and VAT Entry after posting Sales Order without Prepayment.
    //  5. Test to verify values on Sales Invoice Header and VAT Entry after posting Sales Order with Unrealized VAT.
    //  6. Test to verify values on Sales Credit Memo Header and VAT Entry after posting Sales Credit Memo Prepayment.
    //  7. Test to verify values on VAT Entry after posting Sales Prepayment Invoice with Unrealized VAT.
    //  8. Test to verify error message while posting Sales Prepayment Invoice with blank Prepayment Due Date.
    //  9. Test to verify values on Sales Invoice Header and VAT Entry after posting Sales Prepayment Invoice with multiple Sales lines with different VAT Product Posting Group.
    // 10. Test to verify Sales Invoice Header and VAT Entry after posting Prepayment with updated VAT Posting Groups.
    // 11. Test to verify Sales Invoice Header and VAT Entry after posting Prepayment with Unrealized and VAT Posting Groups.
    // 12. Test to verify values on VAT Entry after posting Sales Invoice with Prepayment.
    // 13. Test to verify values on Sales Invoice Header and VAT Entry after posting Sales Prepayment Invoice.
    // 14. Test to verify that the line referred to customer debit amount should appear in GL Book Entry.
    // 15. Test to verify that the line referred to Vendor debit amount 0 should appear in GL Book Entry.
    // 16. Test to verify post Purchase Prepayment Invoice without Prepayment Due Date on Purchase Order.
    // 17. Test to verify post Purchase Invoice without Prepayment % and with Unrealized VAT.
    // 18. Test to verify post Purchase Prepayment Invoice with Unrealized VAT.
    // 19. Test to verify post Payment with application Purchase Prepayment Invoice.
    // 20. Test to verify post Purchase Invoice after Payment with application Purchase Prepayment Invoice.
    // 21. Test to verify post Purchase Prepayment Invoice with multiple Purchase Lines.
    // 22. Test to verify post Purchase Prepayment Cr. Memo with after post Purchase Prepayment Invoice.
    // 23. Test to verify Operation Type after Posting Purchase Order.
    // 24. Test to verify Quantity after Posting Purchase Prepayment Order.
    // 25. Test to verify Operation Type after Posting Purchase Credit Memo.
    // 26. Test to verify post Purchase Prepayment Invoice with multiple Purchase Lines.
    // 27. Test to verify VAT Entry after Posting Purchase Prepayment when VAT is changed on Purchase Line.
    // 28. Test to verify that the VAT Entry is Zero, When Purch Invoice is posted after Prepayment.
    // 29. Test to verify values on GL Book Entry after Apply Cust Ledger Entry.
    // 30. Test to verify values on GL Book Entry after Unapply Cust Ledger Entry.
    // 
    // Covers Test Cases for WI - 348313
    // ------------------------------------------------------------------------------------
    // Test Function Name                                                        TFS ID
    // ------------------------------------------------------------------------------------
    // ApplyPaymentToSalesPrepaymentInvoice                                      153294
    // SalesInvoiceAfterApplyPaymentToSalesPrepmtInvoice                         153295
    // SalesInvoiceWithFullPrepayment                                     153275,154594
    // SalesInvoiceWithoutUnrealizedVAT                                          153278
    // SalesInvoiceWithUnrealizedVAT                                             153292
    // SalesPrepaymentCreditMemo                                          153283,153297
    // SalesPrepaymentInvoiceWithUnrealizedVAT                                   153293
    // SalesPrepaymentInvWithBlankPrepmtDueDateError                             153284
    // SalesPrepaymentInvWithMultipleSalesLines                                  153296
    // SalesPrepmtInvWithUpdVATPostingGroup                                      153282
    // SalesPrepmtInvWithUpdVATPostingGroupWithUnrealVAT                         153281
    // VATEntryAfterPostSalesOrderWithPrepayment                                 153280
    // VATEntryAndNoSeriesAfterSalesPrepmtInvoice                                153279
    // 
    // Covers Test Cases for WI - 329607
    // ------------------------------------------------------------------------------------
    // Test Function Name                                                        TFS ID
    // ------------------------------------------------------------------------------------
    // LineRefferredToCustomerEntryInGLBookEntry                                 152683
    // VendorEntryWithZeroAmountInGLBookEntry                                    153276
    // 
    // Covers Test Cases for WI - 349775
    // ------------------------------------------------------------------------------------
    // Test Function Name                                                        TFS ID
    // ------------------------------------------------------------------------------------
    // PurchPrepaymentInvoiceWithoutPrepaymentDueDate                            153291
    // PurchInvoiceWithUnrealizedVAT                                             153298
    // PurchPrepaymentInvoiceWithUnrealizedVAT                                   153299
    // ApplyPaymentToPurchPrepaymentInvoice                                      153300
    // PurchInvoiceAfterApplyPaymentToPurchPrepmtInvoice                         153302
    // PurchPrepaymentInvoiceWithMultiplePurchaseLines                           153303
    // PurchPrepaymentCreditMemo                                                 153304
    // 
    // Covers Test Cases for WI - 349774
    // ------------------------------------------------------------------------------------
    // Test Function Name                                                        TFS ID
    // ------------------------------------------------------------------------------------
    // OperationTypeOnPostedPurchaseOrder                                        153285
    // OperationTypeOnPostedPrePmtInvoice                                        153286
    // OperationTypeOnPostedPurchaseCreditMemo                                   153290
    // MultiplePurchPrepmtWithDiffVATProdPostingGroup                            153288
    // PurchPrepmtInvWithUpdatedVATPostingGroup                                  153289
    // PostPurchInvAfterPrepmt                                                   153287
    // GLBookEntryApplyCustLedgerEntry                                           155509
    // GLBookEntryUnapplyCustLedgerEntry                                         155510

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        QuantityMustBeRevertedErr: Label 'Quantity Received and Invoiced must be reverted to 0';
        QuantityMustBeRestoredErr: Label 'Qty. to Receive and Invoice must be restored to original values';
        AmountErr: Label 'Amount must be equal.';
        ConfirmPurchaseChangeVATBusPostingGroupTxt: Label 'If you change VAT Bus. Posting Group, the existing purchase lines will be deleted and new purchase lines based on the new information in the header will be created.';
        ConfirmSalesChangeVATBusPostingGroupTxt: Label 'If you change VAT Bus. Posting Group, the existing sales lines will be deleted and new sales lines based on the new information on the header will be created.';
        OperationTypeErr: Label 'Operation Type must be %1 in %2.', Comment = '%1 =Operation Type Value, %2=Table Name.';

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPaymentToSalesPrepaymentInvoice()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        OldUnrealizedVAT: Boolean;
    begin
        // Test to verify values on VAT Entry after applying Sales Prepayment Invoice to Payment with Unrealized VAT.

        // Setup: Update General Ledger Setup and create Sales Order with Prepayment %.
        LibraryERM.CreateGLAccount(GLAccount);
        OldUnrealizedVAT := UpdateUnrealizedVATOnGeneralLedgerSetup(true);  // True for Unrealized VAT.
        CreateSalesOrderWithVATPostingSetup(
          SalesLine, LibraryRandom.RandDec(10, 2), VATPostingSetup."Unrealized VAT Type"::Percentage);  // Random value for Prepayment %.
        PostSalesPrepaymentInvoice(SalesHeader, SalesLine."Document No.");

        // Exercise.
        ApplyAndPostGeneralJournalLine(
          GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", GLAccount."No.",
          -SalesLine."Line Amount" * SalesHeader."Prepayment %" / 100,
          GenJournalLine."Applies-to Doc. Type"::Invoice, SalesHeader."Prepayment No.");

        // Verify: Verify values on VAT Entry.
        VerifyVATEntry(
          SalesHeader."Last Prepayment No.", SalesLine."VAT Prod. Posting Group", 0, 0, CalculateAmount(SalesLine), CalculateBase(SalesLine));  // Value 0 required for VAT Entry Amount and VAT Entry Base.

        // Tear Down.
        DeleteVATPostingSetup(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        UpdateUnrealizedVATOnGeneralLedgerSetup(OldUnrealizedVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceAfterApplyPaymentToSalesPrepmtInvoice()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        OldUnrealizedVAT: Boolean;
    begin
        // Test to verify values on VAT Entry after Posting Sales Order when Sales Prepayment Invoice applied to payment with Unrealized VAT.

        // Setup: Update General Ledger Setup, create Sales Order with Prepayment % and apply Prepayment Invoice to Payment.
        LibraryERM.CreateGLAccount(GLAccount);
        OldUnrealizedVAT := UpdateUnrealizedVATOnGeneralLedgerSetup(true);  // True for Unrealized VAT.
        CreateSalesOrderWithVATPostingSetup(
          SalesLine, LibraryRandom.RandDec(10, 2), VATPostingSetup."Unrealized VAT Type"::Percentage);  // Random value for Prepayment %.
        PostSalesPrepaymentInvoice(SalesHeader, SalesLine."Document No.");
        ApplyAndPostGeneralJournalLine(
          GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", GLAccount."No.",
          -SalesLine."Line Amount" * SalesLine."Prepayment %" / 100,
          GenJournalLine."Applies-to Doc. Type"::Invoice, SalesHeader."Prepayment No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post Sales Order with Ship and Invoice.

        // Verify: Verify values on VAT Entry.
        VerifyVATEntry(
          DocumentNo, SalesLine."VAT Prod. Posting Group", 0, 0, SalesLine."Line Amount" * SalesLine."VAT %" / 100, SalesLine."Line Amount");  // Value 0 required for VAT Entry Amount and VAT Entry Base.

        // Tear Down.
        DeleteVATPostingSetup(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        UpdateUnrealizedVATOnGeneralLedgerSetup(OldUnrealizedVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithFullPrepayment()
    var
        GLBookEntry: Record "GL Book Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Test to verify values on GL Book Entry after posting Sales Invoice with full Prepayment.

        // Setup: Create and post Sales Prepayment.
        CreateSalesOrderWithVATPostingSetup(SalesLine, 100, VATPostingSetup."Unrealized VAT Type"::" ");  // Using 100 for Prepayment % as required to test the scenario.
        PostSalesPrepaymentInvoice(SalesHeader, SalesLine."Document No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post Sales Order with Ship and Invoice.

        // Verify: Verify values on GL Book Entry.
        GLBookEntry.SetRange("Document No.", DocumentNo);
        GLBookEntry.FindFirst();
        Assert.AreEqual(0, GLBookEntry.Amount, AmountErr);  // Value 0 required for GL Book Entry Amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithoutUnrealizedVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Test to verify values on Sales Invoice Header and VAT Entry after posting Sales Order without Prepayment.

        // Setup.
        CreateSalesOrderWithVATPostingSetup(SalesLine, 0, VATPostingSetup."Unrealized VAT Type"::" ");  // Using 0 for Prepayment %.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post Sales Order with Ship and Invoice.

        // Verify: Verify values on Sales Invoice Header and VAT Entry.
        VerifySalesInvoiceHeader(SalesHeader, false);  // False for Prepayment Invoice.
        VerifyVATEntry(
          DocumentNo, SalesLine."VAT Prod. Posting Group", SalesLine."Line Amount" * SalesLine."VAT %" / 100, SalesLine."Line Amount", 0, 0);  // Value 0 required for VAT Entry Unrealized Amount and VAT Entry Unrealized Base.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithUnrealizedVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        OldUnrealizedVAT: Boolean;
    begin
        // Test to verify values on Sales Invoice Header and VAT Entry after posting Sales Order with Unrealized VAT.

        // Setup.
        OldUnrealizedVAT := UpdateUnrealizedVATOnGeneralLedgerSetup(true);
        CreateSalesOrderWithVATPostingSetup(SalesLine, 0, VATPostingSetup."Unrealized VAT Type"::Percentage);  // Using 0 for Prepayment %.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post Sales Order with Ship and Invoice.

        // Verify: Verify values on Sales Invoice Header and VAT Entry.
        VerifySalesInvoiceHeader(SalesHeader, false);  // False for Prepayment Invoice.
        VerifyVATEntry(
          DocumentNo, SalesLine."VAT Prod. Posting Group", 0, 0, SalesLine."Line Amount" * SalesLine."VAT %" / 100, SalesLine."Line Amount");  // Value 0 required for VAT Entry Amount and VAT Entry Base.

        // Tear Down.
        DeleteVATPostingSetup(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        UpdateUnrealizedVATOnGeneralLedgerSetup(OldUnrealizedVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepaymentCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Test to verify values on Sales Credit Memo Header and VAT Entry after posting Sales Credit Memo Prepayment.

        // Setup: Create and post Sales Invoice Prepayment.
        CreateSalesOrderWithVATPostingSetup(SalesLine, LibraryRandom.RandDec(10, 2), VATPostingSetup."Unrealized VAT Type"::" ");  // Random value for Prepayment %.
        PostSalesPrepaymentInvoice(SalesHeader, SalesLine."Document No.");

        // Exercise.
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);

        // Verify: Verify Sales Credit Memo Header and VAT Entry.
        VerifySalesCreditMemoHeader(SalesHeader);
        VerifyVATEntry(
          SalesHeader."Last Prepayment No.", SalesLine."VAT Prod. Posting Group", CalculateAmount(SalesLine), CalculateBase(SalesLine), 0, 0);  // Value 0 required for VAT Entry Unrealized Amount and VAT Entry Unrealized Base.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepaymentInvoiceWithUnrealizedVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        OldUnrealizedVAT: Boolean;
    begin
        // Test to verify values on VAT Entry after posting Sales Prepayment Invoice with Unrealized VAT.

        // Setup: Update General Ledger Setup and create Sales Order with Prepayment %.
        OldUnrealizedVAT := UpdateUnrealizedVATOnGeneralLedgerSetup(true);  // True for Unrealized VAT.
        CreateSalesOrderWithVATPostingSetup(
          SalesLine, LibraryRandom.RandDec(10, 2), VATPostingSetup."Unrealized VAT Type"::Percentage);  // Random value for Prepayment %.

        // Exercise.
        PostSalesPrepaymentInvoice(SalesHeader, SalesLine."Document No.");

        // Verify: Verify values on VAT Entry.
        VerifyVATEntry(
          SalesHeader."Last Prepayment No.", SalesLine."VAT Prod. Posting Group", 0, 0, CalculateAmount(SalesLine), CalculateBase(SalesLine));  // Value 0 required for VAT Entry Amount and VAT Entry Base.

        // Tear Down.
        DeleteVATPostingSetup(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        UpdateUnrealizedVATOnGeneralLedgerSetup(OldUnrealizedVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepaymentInvWithBlankPrepmtDueDateError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Test to verify error message while posting Sales Prepayment Invoice with blank Prepayment Due Date.

        // Setup: Create Sales Order with Prepayment and blank Prepayment Due date.
        CreateSalesOrderWithVATPostingSetup(SalesLine, LibraryRandom.RandDec(10, 2), VATPostingSetup."Unrealized VAT Type"::" ");  // Random value for Prepayment %.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.Validate("Prepayment Due Date", 0D);  // Using 0D to generate required error.
        SalesHeader.Modify(true);

        // Exercise.
        asserterror LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Verify: Verify error on while posting Prepayment Invoice.
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption("Prepayment Due Date"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepaymentInvWithMultipleSalesLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Test to verify values on Sales Invoice Header and VAT Entry after posting Sales Prepayment Invoice with multiple Sales lines with different VAT Product Posting Group.

        // Setup: Create Sales Order with different VAT prod. Posting Groups on Sales lines.
        CreateSalesOrderWithVATPostingSetup(SalesLine, LibraryRandom.RandDec(10, 2), VATPostingSetup."Unrealized VAT Type"::" ");  // Random value for Prepayment %.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::" ");
        CreateSalesLine(SalesLine2, SalesHeader, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));

        // Exercise.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Verify: Verify values on Sales Invoice Header and VAT Entries for different Sales Lines.
        VerifySalesInvoiceHeader(SalesHeader, true);  // True for Prepayment Invoice.
        VerifyVATEntry(
          SalesHeader."Last Prepayment No.", SalesLine."VAT Prod. Posting Group", CalculateAmount(SalesLine), CalculateBase(SalesLine), 0, 0);  // Value 0 required for VAT Entry Unrealized Amount and VAT Entry Unrealized Base.
        VerifyVATEntry(
          SalesHeader."Last Prepayment No.",
          SalesLine2."VAT Prod. Posting Group", CalculateAmount(SalesLine2), CalculateBase(SalesLine2), 0, 0);  // Value 0 required for VAT Entry Unrealized Amount and VAT Entry Unrealized Base.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtInvWithUpdVATPostingGroup()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Test to verify Sales Invoice Header and VAT Entry after posting Prepayment with VAT Posting Groups.

        // Setup.
        CreateSalesOrderWithVATPostingSetup(SalesLine, LibraryRandom.RandDec(10, 2), VATPostingSetup."Unrealized VAT Type"::" ");  // Random value for Prepayment %.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        UpdateVATPostingGroupsOnSalesLine(SalesLine);

        // Exercise.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Verify: Verify Sales Invoice Header and VAT Entry.
        VerifySalesInvoiceHeader(SalesHeader, true);  // True for Prepayment Invoice.
        VerifyVATEntry(
          SalesHeader."Last Prepayment No.", SalesLine."VAT Prod. Posting Group", CalculateAmount(SalesLine), CalculateBase(SalesLine), 0, 0);  // Value 0 required for VAT Entry Unrealized Amount and VAT Entry Unrealized Base.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtInvWithUpdVATPostingGroupWithUnrealVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        OldUnrealizedVAT: Boolean;
    begin
        // Test to verify Sales Invoice Header and VAT Entry after posting Prepayment with Unrealized VAT and VAT Posting Groups.

        // Setup.
        OldUnrealizedVAT := UpdateUnrealizedVATOnGeneralLedgerSetup(true);  // True for Unrealized VAT.
        CreateSalesOrderWithVATPostingSetup(
          SalesLine, LibraryRandom.RandDec(10, 2), VATPostingSetup."Unrealized VAT Type"::Percentage);  // Random value for Prepayment %.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        UpdateVATPostingGroupsOnSalesLine(SalesLine);

        // Exercise.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Verify: Verify Sales Invoice Header and VAT Entry.
        VerifySalesInvoiceHeader(SalesHeader, true);  // True for Prepayment Invoice.
        VerifyVATEntry(
          SalesHeader."Last Prepayment No.", SalesLine."VAT Prod. Posting Group", CalculateAmount(SalesLine), CalculateBase(SalesLine), 0, 0);  // Value 0 required for VAT Entry Unrealized Amount and VAT Entry Unrealized Base.

        // Tear Down.
        VATPostingSetup.Delete(true);
        UpdateUnrealizedVATOnGeneralLedgerSetup(OldUnrealizedVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryAfterPostSalesOrderWithPrepayment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Test to verify values on VAT Entry after posting Sales Invoice with Prepayment.

        // Setup: Create and Post Sales Prepayment.
        CreateSalesOrderWithVATPostingSetup(SalesLine, LibraryRandom.RandDec(10, 2), VATPostingSetup."Unrealized VAT Type"::" ");  // Random value for Prepayment %.
        PostSalesPrepaymentInvoice(SalesHeader, SalesLine."Document No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post Sales Order with Ship and Invoice.

        // Verify: Verify values on VAT Entry.
        VerifyVATEntry(
          DocumentNo, SalesLine."VAT Prod. Posting Group", SalesLine."Line Amount" * SalesLine."VAT %" / 100, SalesLine."Line Amount", 0, 0);  // Value 0 required for VAT Entry Unrealized Amount and VAT Entry Unrealized Base.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryAndNoSeriesAfterSalesPrepmtInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Test to verify values on Sales Invoice Header and VAT Entry after posting Sales Prepayment Invoice.

        // Setup.
        CreateSalesOrderWithVATPostingSetup(SalesLine, LibraryRandom.RandDec(10, 2), VATPostingSetup."Unrealized VAT Type"::" ");  // Random value for Prepayment %.

        // Exercise.
        PostSalesPrepaymentInvoice(SalesHeader, SalesLine."Document No.");

        // Verify: Verify values on Sales Invoice Header and VAT Entry.
        VerifySalesInvoiceHeader(SalesHeader, true);  // True for Prepayment Invoice.
        VerifyVATEntry(
          SalesHeader."Last Prepayment No.", SalesLine."VAT Prod. Posting Group", CalculateAmount(SalesLine), CalculateBase(SalesLine), 0, 0);  // Value 0 required for VAT Entry Unrealized Amount and VAT Entry Unrealized Base.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineRefferredToCustomerEntryInGLBookEntry()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Test to verify that the line referred to customer debit amount should appear in GL Book Entry.

        // Setup.
        CreateSalesOrderWithVATPostingSetup(SalesLine, 100, VATPostingSetup."Unrealized VAT Type"::" ");  // Using 100 for Prepayment % as required to test the scenario.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DocumentNo := GetPostedDocumentNo(SalesHeader."Posting No. Series");

        // Exercise.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Verify.
        VerifyDebitAmountInGLBookEntry(DocumentNo, true, SalesLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorEntryWithZeroAmountInGLBookEntry()
    var
        GLBookEntry: Record "GL Book Entry";
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Test to verify that the line referred to Vendor debit amount 0 should appear in GL Book Entry.

        // Setup.
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          100, CalcDate('<1M>', WorkDate()), VATPostingSetup."Unrealized VAT Type"::" ");  // Using 100 for Prepayment %.
        LibraryPurchase.PostPrepaymentInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post Purchase Order as Ship & Invoice.

        // Verify.
        GLBookEntry.SetRange(Amount, 0);
        VerifyDebitAmountInGLBookEntry(DocumentNo, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepaymentInvoiceWithoutPrepaymentDueDate()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        OldUnrealizedVAT: Boolean;
    begin
        // Test to verify post Purchase Prepayment Invoice without Prepayment Due Date on Purchase Order.

        // Setup: Create Purchase Order with VAT Prod. Posting Group.
        OldUnrealizedVAT := UpdateUnrealizedVATOnGeneralLedgerSetup(true);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2),
          0D, VATPostingSetup."Unrealized VAT Type"::Percentage);  // Using Random for Prepayment % and 0D for Prepayment Due Date.

        // Exercise.
        asserterror LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // Verify.
        Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption("Prepayment Due Date"), '');

        // Tear Down.
        UpdateUnrealizedVATOnGeneralLedgerSetup(OldUnrealizedVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithUnrealizedVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        OldUnrealizedVAT: Boolean;
    begin
        // Test to verify post Purchase Invoice without Prepayment % and with Unrealized VAT.

        // Setup: Create Purchase Order with VAT Prod. Posting Group.
        OldUnrealizedVAT := UpdateUnrealizedVATOnGeneralLedgerSetup(true);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, 0, 0D,
          VATPostingSetup."Unrealized VAT Type"::Percentage);  // Using 0 for Prepayment % and 0D for Prepayment Due Date.
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post Purchase Order as Ship & Invoice.

        // Verify: Verify values on Purchase Invoice Header and VAT Entry.
        VerifyPurchaseInvoiceHeader(PurchaseHeader, false);  // False for Prepayment Invoice.
        VerifyVATEntry(
          DocumentNo, PurchaseLine."VAT Prod. Posting Group", 0, 0, -PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100,
          -PurchaseLine."Line Amount");  // Value 0 required for VAT Entry Amount and VAT Entry Base.

        // Tear Down.
        DeleteVATPostingSetup(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        UpdateUnrealizedVATOnGeneralLedgerSetup(OldUnrealizedVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepaymentInvoiceWithUnrealizedVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        OldUnrealizedVAT: Boolean;
    begin
        // Test to verify post Purchase Prepayment Invoice with Unrealized VAT.

        // Setup: Create Purchase Order with VAT Prod. Posting Group
        OldUnrealizedVAT := UpdateUnrealizedVATOnGeneralLedgerSetup(true);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2), CalcDate('<1M>', WorkDate()),
          VATPostingSetup."Unrealized VAT Type"::Percentage);  // Using Random for Prepayment %.

        // Exercise.
        LibraryPurchase.PostPrepaymentInvoice(PurchaseHeader);

        // Verify: Verify values on VAT Entry.
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        VerifyVATEntry(
          PurchaseHeader."Last Prepayment No.", PurchaseLine."VAT Prod. Posting Group", 0, 0, CalculateAmountPurchase(
            PurchaseLine), CalculateBasePurchase(PurchaseLine));  // Value 0 required for VAT Entry Amount and VAT Entry Base.

        // Tear Down.
        DeleteVATPostingSetup(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        UpdateUnrealizedVATOnGeneralLedgerSetup(OldUnrealizedVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPaymentToPurchPrepaymentInvoice()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        OldUnrealizedVAT: Boolean;
    begin
        // Test to verify post Payment with application Purchase Prepayment Invoice.

        // Setup: Create Purchase Order with VAT Prod. Posting Group, post Prepayment Invoice.
        LibraryERM.CreateGLAccount(GLAccount);
        OldUnrealizedVAT := UpdateUnrealizedVATOnGeneralLedgerSetup(true);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2), CalcDate('<1M>', WorkDate()),
          VATPostingSetup."Unrealized VAT Type"::Percentage);  // Using Random for Prepayment %.
        LibraryPurchase.PostPrepaymentInvoice(PurchaseHeader);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");

        // Exercise.
        ApplyAndPostGeneralJournalLine(
          GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", GLAccount."No.",
          PurchaseLine."Line Amount" * PurchaseHeader."Prepayment %" / 100,
          GenJournalLine."Applies-to Doc. Type"::Invoice, PurchaseHeader."Prepayment No.");

        // Verify: Verify values on VAT Entry.
        VerifyVATEntry(
          PurchaseHeader."Last Prepayment No.", PurchaseLine."VAT Prod. Posting Group", 0, 0, CalculateAmountPurchase(
            PurchaseLine), CalculateBasePurchase(PurchaseLine));  // Value 0 required for VAT Entry Amount and VAT Entry Base.

        // Tear Down.
        DeleteVATPostingSetup(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        UpdateUnrealizedVATOnGeneralLedgerSetup(OldUnrealizedVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceAfterApplyPaymentToPurchPrepmtInvoice()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        OldUnrealizedVAT: Boolean;
    begin
        // Test to verify post Purchase Invoice after Payment with application Purchase Prepayment Invoice.

        // Setup: Create Purchase Order with VAT Prod. Posting Group, post Payment and apply Prepayment Invoice.
        LibraryERM.CreateGLAccount(GLAccount);
        OldUnrealizedVAT := UpdateUnrealizedVATOnGeneralLedgerSetup(true);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2), CalcDate('<1M>', WorkDate()),
          VATPostingSetup."Unrealized VAT Type"::Percentage);  // Using Random for Prepayment %.
        LibraryPurchase.PostPrepaymentInvoice(PurchaseHeader);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        ApplyAndPostGeneralJournalLine(
          GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", GLAccount."No.",
          PurchaseLine."Line Amount" * PurchaseHeader."Prepayment %" / 100,
          GenJournalLine."Applies-to Doc. Type"::Invoice, PurchaseHeader."Prepayment No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post Purchase Order as Receive and Invoice.

        // Verify: Verify values on VAT Entry.
        VerifyVATEntry(
          DocumentNo, PurchaseLine."VAT Prod. Posting Group", 0, 0, -PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100,
          -PurchaseLine."Line Amount");  // Value 0 required for VAT Entry Amount and VAT Entry Base.

        // Tear Down.
        DeleteVATPostingSetup(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        UpdateUnrealizedVATOnGeneralLedgerSetup(OldUnrealizedVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepaymentInvoiceWithMultiplePurchaseLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        OldUnrealizedVAT: Boolean;
    begin
        // Test to verify post Purchase Prepayment Invoice with multiple Purchase Lines.

        // Setup: Create Purchase Order with multiple line with different VAT Prod. Posting Group.
        OldUnrealizedVAT := UpdateUnrealizedVATOnGeneralLedgerSetup(true);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2), CalcDate('<1M>', WorkDate()),
          VATPostingSetup."Unrealized VAT Type"::Percentage);  // Using Random for Prepayment %.
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::" ");
        CreatePurchaseLine(PurchaseLine2, PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group");

        // Exercise.
        LibraryPurchase.PostPrepaymentInvoice(PurchaseHeader);

        // Verify: Verify values on Purchase Invoice Header and VAT Entry.
        VerifyPurchaseInvoiceHeader(PurchaseHeader, true);  // True for Prepayment Invoice.
        VerifyVATEntry(
          PurchaseHeader."Last Prepayment No.", PurchaseLine."VAT Prod. Posting Group", 0, 0, CalculateAmountPurchase(
            PurchaseLine), CalculateBasePurchase(PurchaseLine));  // Value 0 required for VAT Entry Amount and VAT Entry Base.
        VerifyVATEntry(
          PurchaseHeader."Last Prepayment No.", PurchaseLine2."VAT Prod. Posting Group", CalculateAmountPurchase(
            PurchaseLine2), CalculateBasePurchase(PurchaseLine2), 0, 0);  // Value 0 required for Unrealized VAT and Base Amount.

        // Tear Down.
        DeleteVATPostingSetup(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        UpdateUnrealizedVATOnGeneralLedgerSetup(OldUnrealizedVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepaymentCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        OldUnrealizedVAT: Boolean;
    begin
        // Test to verify post Purchase Prepayment Cr. Memo with after post Purchase Prepayment Invoice.

        // Setup: Create Purchase Order with VAT Prod. Posting Group, post Prepayment Invoice and Cr. Memo, update Check Total on Purchase Cr. Memo.
        OldUnrealizedVAT := UpdateUnrealizedVATOnGeneralLedgerSetup(true);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2), CalcDate('<1M>', WorkDate()),
          VATPostingSetup."Unrealized VAT Type"::Percentage);  // Using Random for Prepayment %.
        LibraryPurchase.PostPrepaymentInvoice(PurchaseHeader);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        PurchaseHeader.Validate("Check Total", PurchaseLine."Prepmt. Amt. Incl. VAT");
        PurchaseHeader.Modify(true);

        // Exercise.
        PurchasePostPrepayments.CreditMemo(PurchaseHeader);

        // Verify: Verify values on Purch. Cr. Memo Header and Vat Entry.
        VerifyPurchCreditMemoHeader(PurchaseHeader);
        VerifyVATEntry(
          PurchaseHeader."Last Prepayment No.", PurchaseLine."VAT Prod. Posting Group", 0, 0, CalculateAmountPurchase(
            PurchaseLine), CalculateBasePurchase(PurchaseLine));  // Value 0 required for VAT Entry Amount and VAT Entry Base.

        // Tear Down.
        DeleteVATPostingSetup(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        UpdateUnrealizedVATOnGeneralLedgerSetup(OldUnrealizedVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler')]
    procedure CancelInvoiceFromGetReceiptLinesWithPrepaymentRevertsOrderLineWhenRestoreQtyEnabled()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        PurchaseHeaderCrMemo: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        Quantity: Decimal;
        NetCheckTotal: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 635874] Cancelling a posted purchase invoice created via Get Receipt Lines from a PO with prepayment fully reverts the PO line quantities
        InitializePurchaseInvoiceCancellation(LibrarySetupStorage);
        SetRestoreOrderQtyOnReturn(true);

        // [GIVEN] General and VAT Posting Setup with Purch. Prepayments Account configured
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPrepAccounts(GeneralPostingSetup);
        GeneralPostingSetup."Direct Cost Applied Account" := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup."Purch. Credit Memo Account" := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup.Modify(true);
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));
        SetupPrepmtGLAccountPostingGroups(GeneralPostingSetup, VATPostingSetup);
        VATPostingSetup."Purch. Prepayments Account" := GeneralPostingSetup."Purch. Prepayments Account";
        VATPostingSetup.Modify(true);

        // [GIVEN] Item "I" with matching posting groups
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        // [GIVEN] Vendor "V" with matching posting groups
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        // [GIVEN] Purchase Order with Prepayment % and one line for Item "I"
        Quantity := LibraryRandom.RandIntInRange(1, 10);
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        PurchaseHeaderOrder.Validate("Prepayment %", LibraryRandom.RandIntInRange(10, 50));
        PurchaseHeaderOrder.Validate("Prepayment Due Date", WorkDate());
        PurchaseHeaderOrder.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeaderOrder, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 500, 2));
        PurchaseLine.Modify(true);

        // [GIVEN] Posted prepayment invoice
        LibraryPurchase.PostPrepaymentInvoice(PurchaseHeaderOrder);

        // [GIVEN] Purchase Order posted with Receive only
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // [GIVEN] Purchase Invoice created via Get Receipt Lines from the receipt
        PurchRcptHeader.SetRange("Order No.", PurchaseHeaderOrder."No.");
        PurchRcptHeader.FindFirst();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeaderInvoice);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        // [GIVEN] Check Total on Purchase Order is IT-mandatory and is based on the net amount
        PurchaseHeaderOrder.Find();
        PurchaseHeaderOrder.Validate(Invoice, true);
        PurchaseHeaderOrder.Modify(true);
        LibraryPurchase.SetCheckTotalOnPurchaseDocument(PurchaseHeaderOrder, false, false, true);
        NetCheckTotal := PurchaseHeaderOrder."Check Total";

        // [GIVEN] Purchase Invoice posted with the IT-mandatory net "Check Total"
        PurchInvHeader.Get(PostPurchaseDocWithNetCheckTotal(PurchaseHeaderInvoice, NetCheckTotal));

        // [WHEN] Cancel the Posted Purchase Invoice
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvHeader, PurchaseHeaderCrMemo);
        PurchCrMemoHdr.Get(PostPurchaseDocWithNetCheckTotal(PurchaseHeaderCrMemo, NetCheckTotal));
        CorrectPostedPurchInvoice.UpdatePurchaseOrderLineIfExist(PurchCrMemoHdr."No.");

        // [THEN] Purchase Order line is fully reverted: Qty. Received = 0, Qty. Invoiced = 0
        PurchaseLine.Find();
        Assert.AreEqual(0, PurchaseLine."Quantity Received", QuantityMustBeRevertedErr);
        Assert.AreEqual(0, PurchaseLine."Quantity Invoiced", QuantityMustBeRevertedErr);
        Assert.AreEqual(Quantity, PurchaseLine."Qty. to Receive", QuantityMustBeRestoredErr);
        Assert.AreEqual(Quantity, PurchaseLine."Qty. to Invoice", QuantityMustBeRestoredErr);
        PurchaseLine.TestField("Prepmt Amt Deducted", 0);
        PurchaseLine.TestField("Prepmt Amt to Deduct", PurchaseLine."Prepmt. Amt. Inv.");
        LibrarySetupStorage.Restore();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelInvoiceWithPrepaymentReconcilesPrepaymentWhenRestoreQtyDisabled()
    begin
        CancelInvoiceWithPrepaymentAndVerify(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelPartialInvoiceRecalculatesPrepaymentWhenRestoreQtyDisabled()
    begin
        CancelInvoiceWithPrepaymentAndVerify(true);
    end;

    local procedure CancelInvoiceWithPrepaymentAndVerify(PartiallyInvoice: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        PrepaidPurchaseLine: Record "Purchase Line";
        PurchaseCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderCrMemo: Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        PurchasePrepaymentInvoiceHeader: Record "Purch. Inv. Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        RemainingPurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        ExpectedPrepmtToDeduct: Decimal;
        InvoicedQuantity: Decimal;
        NetCheckTotal: Decimal;
        OrderQuantity: Decimal;
        PrepaymentCreditMemoNo: Code[20];
        PrepaymentInvoiceNo: Code[20];
    begin
        // [SCENARIO 649626] Cancelling an invoice reconciles its prepayment when order quantity restoration is disabled.
        InitializePurchaseInvoiceCancellation(LibrarySetupStorage);
        InvoicedQuantity := 1;
        OrderQuantity := 1;
        if PartiallyInvoice then begin
            InvoicedQuantity := LibraryRandom.RandIntInRange(1, 5);
            // Keep the remaining line amount above the full 50% prepayment.
            OrderQuantity := 2 * InvoicedQuantity + LibraryRandom.RandIntInRange(1, 5);
            ExpectedPrepmtToDeduct := OrderQuantity * 50;
            PurchasesPayablesSetup.Get();
            PurchasesPayablesSetup.Validate("Default Qty. to Receive", PurchasesPayablesSetup."Default Qty. to Receive"::Remainder);
            PurchasesPayablesSetup.Modify(true);
        end;

        // [GIVEN] A Purchase Order with a paid 50% prepayment on the line that will be posted.
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPrepAccounts(GeneralPostingSetup);
        GeneralPostingSetup."Direct Cost Applied Account" := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup."Purch. Credit Memo Account" := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup.Modify(true);
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));
        SetupPrepmtGLAccountPostingGroups(GeneralPostingSetup, VATPostingSetup);
        VATPostingSetup."Purch. Prepayments Account" := GeneralPostingSetup."Purch. Prepayments Account";
        VATPostingSetup.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Prepayment %", 50);
        PurchaseHeader.Validate("Prepayment Due Date", WorkDate());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PrepaidPurchaseLine, PurchaseHeader, PrepaidPurchaseLine.Type::Item, Item."No.", OrderQuantity);
        PrepaidPurchaseLine.Validate("Direct Unit Cost", 100);
        PrepaidPurchaseLine.Validate("Qty. to Receive", InvoicedQuantity);
        PrepaidPurchaseLine.Modify(true);
        LibraryPurchase.CreatePurchaseLine(RemainingPurchaseLine, PurchaseHeader, RemainingPurchaseLine.Type::Item, Item."No.", OrderQuantity);
        RemainingPurchaseLine.Validate("Direct Unit Cost", 100);
        RemainingPurchaseLine.Validate("Prepayment %", 0);
        RemainingPurchaseLine.Validate("Qty. to Receive", 0);
        RemainingPurchaseLine.Validate("Qty. to Invoice", 0);
        RemainingPurchaseLine.Modify(true);

        LibraryPurchase.SetCheckTotalOnPurchaseDocument(PurchaseHeader, true, false, false);
        PrepaymentInvoiceNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        PurchasePrepaymentInvoiceHeader.Get(PrepaymentInvoiceNo);
        PurchasePrepaymentInvoiceHeader.CalcFields("Amount Including VAT");
        PostPaymentToInvoice(
            "Gen. Journal Account Type"::Vendor, Vendor."No.", PrepaymentInvoiceNo,
            PurchasePrepaymentInvoiceHeader."Amount Including VAT");

        // [GIVEN] The prepaid line is received and invoiced, and quantity restoration is disabled.
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate(Receive, true);
        PurchaseHeader.Validate(Invoice, true);
        PurchaseHeader.Modify(true);
        LibraryPurchase.SetCheckTotalOnPurchaseDocument(PurchaseHeader, false, true, true);
        NetCheckTotal := PurchaseHeader."Check Total";
        PurchaseInvoiceHeader.Get(PostPurchaseDocWithNetCheckTotal(PurchaseHeader, NetCheckTotal));
        if PartiallyInvoice then begin
            PrepaidPurchaseLine.Find();
            PrepaidPurchaseLine.TestField("Prepmt Amt Deducted", ExpectedPrepmtToDeduct * InvoicedQuantity / OrderQuantity);
            PrepaidPurchaseLine.TestField("Prepmt Amt to Deduct", ExpectedPrepmtToDeduct * (OrderQuantity - InvoicedQuantity) / OrderQuantity);
        end;
        SetRestoreOrderQtyOnReturn(false);
        Commit();

        // [WHEN] The posted invoice is cancelled.
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchaseInvoiceHeader, PurchaseHeaderCrMemo);
        PurchaseCrMemoHeader.Get(PostPurchaseDocWithNetCheckTotal(PurchaseHeaderCrMemo, NetCheckTotal));
        CorrectPostedPurchInvoice.UpdatePurchaseOrderLineIfExist(PurchaseCrMemoHeader."No.");

        // [THEN] The order quantities remain posted, but its deducted prepayment is released.
        PrepaidPurchaseLine.Find();
        PrepaidPurchaseLine.TestField("Quantity Received", InvoicedQuantity);
        PrepaidPurchaseLine.TestField("Quantity Invoiced", InvoicedQuantity);
        PrepaidPurchaseLine.TestField(Quantity, OrderQuantity);
        PrepaidPurchaseLine.TestField("Qty. to Receive", OrderQuantity - InvoicedQuantity);
        PrepaidPurchaseLine.TestField("Qty. to Invoice", OrderQuantity - InvoicedQuantity);
        PrepaidPurchaseLine.TestField("Prepmt Amt Deducted", 0);
        PrepaidPurchaseLine.TestField("Prepmt Amt to Deduct", ExpectedPrepmtToDeduct);

        if PartiallyInvoice then begin
            // [THEN] The remaining quantity consumes the full released prepayment.
            // Posting resets pending quantities on the other line, which must remain unposted.
            RemainingPurchaseLine.Find();
            RemainingPurchaseLine.Validate("Qty. to Receive", 0);
            RemainingPurchaseLine.Validate("Qty. to Invoice", 0);
            RemainingPurchaseLine.Modify(true);
            PurchaseHeader.Find();
            PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
            PurchaseHeader.Validate(Receive, true);
            PurchaseHeader.Validate(Invoice, true);
            PurchaseHeader.Modify(true);
            LibraryPurchase.SetCheckTotalOnPurchaseDocument(PurchaseHeader, false, true, true);
            PurchaseInvoiceHeader.Get(PostPurchaseDocWithNetCheckTotal(PurchaseHeader, PurchaseHeader."Check Total"));
            PurchaseInvoiceHeader.CalcFields(Amount);
            PurchaseInvoiceHeader.TestField(Amount, (OrderQuantity - InvoicedQuantity) * PrepaidPurchaseLine."Direct Unit Cost" - ExpectedPrepmtToDeduct);
            PrepaidPurchaseLine.Find();
            PrepaidPurchaseLine.TestField(Quantity, OrderQuantity);
            PrepaidPurchaseLine.TestField("Quantity Received", OrderQuantity);
            PrepaidPurchaseLine.TestField("Quantity Invoiced", OrderQuantity);
            PrepaidPurchaseLine.TestField("Qty. to Receive", 0);
            PrepaidPurchaseLine.TestField("Qty. to Invoice", 0);
            PrepaidPurchaseLine.TestField("Prepmt Amt Deducted", ExpectedPrepmtToDeduct);
            PrepaidPurchaseLine.TestField("Prepmt Amt to Deduct", 0);
            RemainingPurchaseLine.Find();
            RemainingPurchaseLine.TestField("Quantity Received", 0);
            RemainingPurchaseLine.TestField("Quantity Invoiced", 0);
            LibrarySetupStorage.Restore();
            exit;
        end;

        // [THEN] The released prepayment can be credited from the original order.
        PurchaseHeader.Find();
        LibraryPurchase.SetCheckTotalOnPurchaseDocument(PurchaseHeader, true, false, false);
        PrepaymentCreditMemoNo := LibraryPurchase.PostPurchasePrepaymentCreditMemo(PurchaseHeader);
        PurchaseCrMemoHeader.Get(PrepaymentCreditMemoNo);
        PurchaseCrMemoHeader.CalcFields("Amount Including VAT");
        PurchaseCrMemoHeader.TestField("Amount Including VAT", PurchasePrepaymentInvoiceHeader."Amount Including VAT");
        LibrarySetupStorage.Restore();
    end;

    local procedure InitializePurchaseInvoiceCancellation(var LibrarySetupStorage: Codeunit "Library - Setup Storage")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Ext. Doc. No. Mandatory" := false;
        PurchasesPayablesSetup."Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Posted Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Vendor Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure PostPaymentToInvoice(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure SetupPrepmtGLAccountPostingGroups(GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GeneralPostingSetup."Purch. Prepayments Account");
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure SetRestoreOrderQtyOnReturn(RestoreOrderQtyOnReturn: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Restore Order Qty. on Return", RestoreOrderQtyOnReturn);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure PostPurchaseDocWithNetCheckTotal(var PurchaseHeader: Record "Purchase Header"; CheckTotal: Decimal): Code[20]
    var
        PurchPost: Codeunit "Purch.-Post";
    begin
        // Posts a purchase document with an explicit net "Check Total"
        PurchPost.SetPostingFlags(PurchaseHeader);
        if (PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo") and (PurchaseHeader."Vendor Cr. Memo No." = '') then
            PurchaseHeader."Vendor Cr. Memo No." := PurchaseHeader."No.";
        PurchaseHeader.Validate("Check Total", CheckTotal);
        PurchaseHeader.Modify(true);
        Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeader);
        exit(PurchaseHeader."Last Posting No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelSalesInvoiceWithPrepaymentReconcilesPrepaymentWhenRestoreQtyDisabled()
    begin
        CancelSalesInvoiceWithPrepaymentAndVerify(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelPartialSalesInvoiceRecalculatesPrepaymentWhenRestoreQtyDisabled()
    begin
        CancelSalesInvoiceWithPrepaymentAndVerify(true);
    end;

    local procedure CancelSalesInvoiceWithPrepaymentAndVerify(PartiallyInvoice: Boolean)
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        Item: Record Item;
        PrepaidSalesLine: Record "Sales Line";
        RemainingSalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesPrepaymentInvoiceHeader: Record "Sales Invoice Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        ExpectedPrepmtToDeduct: Decimal;
        InvoicedQuantity: Decimal;
        OrderQuantity: Decimal;
        PrepaymentCreditMemoNo: Code[20];
        PrepaymentInvoiceNo: Code[20];
    begin
        // [SCENARIO 649626] Cancelling an invoice reconciles its prepayment when order quantity restoration is disabled.
        InitializeSalesInvoiceCancellation(LibrarySetupStorage);
        InvoicedQuantity := 1;
        OrderQuantity := 1;
        if PartiallyInvoice then begin
            InvoicedQuantity := LibraryRandom.RandIntInRange(1, 5);
            // Keep the remaining line amount above the full 50% prepayment.
            OrderQuantity := 2 * InvoicedQuantity + LibraryRandom.RandIntInRange(1, 5);
            ExpectedPrepmtToDeduct := OrderQuantity * 50;
            SalesReceivablesSetup.Get();
            SalesReceivablesSetup.Validate("Default Quantity to Ship", SalesReceivablesSetup."Default Quantity to Ship"::Remainder);
            SalesReceivablesSetup.Modify(true);
        end;

        // [GIVEN] A Sales Order with a paid 50% prepayment on the line that will be posted.
        LibrarySales.CreatePrepaymentVATSetup(GLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GeneralPostingSetup.Get(GLAccount."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group");
        LibraryERM.SetGeneralPostingSetupInvtAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPrepAccounts(GeneralPostingSetup);
        GeneralPostingSetup."Sales Credit Memo Account" := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup.Modify(true);
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandIntInRange(10, 20));
        VATPostingSetup.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Prepayment %", 50);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(PrepaidSalesLine, SalesHeader, PrepaidSalesLine.Type::Item, Item."No.", OrderQuantity);
        PrepaidSalesLine.Validate("Unit Price", 100);
        PrepaidSalesLine.Validate("Qty. to Ship", InvoicedQuantity);
        PrepaidSalesLine.Modify(true);
        LibrarySales.CreateSalesLine(RemainingSalesLine, SalesHeader, RemainingSalesLine.Type::Item, Item."No.", OrderQuantity);
        RemainingSalesLine.Validate("Unit Price", 100);
        RemainingSalesLine.Validate("Prepayment %", 0);
        RemainingSalesLine.Validate("Qty. to Ship", 0);
        RemainingSalesLine.Validate("Qty. to Invoice", 0);
        RemainingSalesLine.Modify(true);

        PrepaymentInvoiceNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        SalesPrepaymentInvoiceHeader.Get(PrepaymentInvoiceNo);
        SalesPrepaymentInvoiceHeader.CalcFields("Amount Including VAT");
        LibrarySales.CreatePaymentAndApplytoInvoice(
            GenJournalLine, Customer."No.", PrepaymentInvoiceNo, -SalesPrepaymentInvoiceHeader."Amount Including VAT");

        // [GIVEN] The prepaid line is shipped and invoiced, and quantity restoration is disabled.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        if PartiallyInvoice then begin
            PrepaidSalesLine.Find();
            PrepaidSalesLine.TestField("Prepmt Amt Deducted", ExpectedPrepmtToDeduct * InvoicedQuantity / OrderQuantity);
            PrepaidSalesLine.TestField("Prepmt Amt to Deduct", ExpectedPrepmtToDeduct * (OrderQuantity - InvoicedQuantity) / OrderQuantity);
        end;
        SetRestoreSalesOrderQtyOnReturn(false);
        Commit();

        // [WHEN] The posted invoice is cancelled.
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [THEN] The order quantities remain posted, but its deducted prepayment is released.
        PrepaidSalesLine.Find();
        PrepaidSalesLine.TestField("Quantity Shipped", InvoicedQuantity);
        PrepaidSalesLine.TestField("Quantity Invoiced", InvoicedQuantity);
        PrepaidSalesLine.TestField(Quantity, OrderQuantity);
        PrepaidSalesLine.TestField("Qty. to Ship", OrderQuantity - InvoicedQuantity);
        PrepaidSalesLine.TestField("Qty. to Invoice", OrderQuantity - InvoicedQuantity);
        PrepaidSalesLine.TestField("Prepmt Amt Deducted", 0);
        PrepaidSalesLine.TestField("Prepmt Amt to Deduct", ExpectedPrepmtToDeduct);

        if PartiallyInvoice then begin
            // [THEN] The remaining quantity consumes the full released prepayment.
            // Posting resets pending quantities on the other line, which must remain unposted.
            RemainingSalesLine.Find();
            RemainingSalesLine.Validate("Qty. to Ship", 0);
            RemainingSalesLine.Validate("Qty. to Invoice", 0);
            RemainingSalesLine.Modify(true);
            SalesHeader.Find();
            SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
            SalesInvoiceHeader.CalcFields(Amount);
            SalesInvoiceHeader.TestField(Amount, (OrderQuantity - InvoicedQuantity) * PrepaidSalesLine."Unit Price" - ExpectedPrepmtToDeduct);
            PrepaidSalesLine.Find();
            PrepaidSalesLine.TestField(Quantity, OrderQuantity);
            PrepaidSalesLine.TestField("Quantity Shipped", OrderQuantity);
            PrepaidSalesLine.TestField("Quantity Invoiced", OrderQuantity);
            PrepaidSalesLine.TestField("Qty. to Ship", 0);
            PrepaidSalesLine.TestField("Qty. to Invoice", 0);
            PrepaidSalesLine.TestField("Prepmt Amt Deducted", ExpectedPrepmtToDeduct);
            PrepaidSalesLine.TestField("Prepmt Amt to Deduct", 0);
            RemainingSalesLine.Find();
            RemainingSalesLine.TestField("Quantity Shipped", 0);
            RemainingSalesLine.TestField("Quantity Invoiced", 0);
            LibrarySetupStorage.Restore();
            exit;
        end;

        // [THEN] The released prepayment can be credited from the original order.
        SalesHeader.Find();
        PrepaymentCreditMemoNo := LibrarySales.PostSalesPrepaymentCreditMemo(SalesHeader);
        SalesCrMemoHeader.Get(PrepaymentCreditMemoNo);
        SalesCrMemoHeader.CalcFields("Amount Including VAT");
        SalesCrMemoHeader.TestField("Amount Including VAT", SalesPrepaymentInvoiceHeader."Amount Including VAT");
        LibrarySetupStorage.Restore();
    end;

    local procedure InitializeSalesInvoiceCancellation(var LibrarySetupStorage: Codeunit "Library - Setup Storage")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Posted Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Customer Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure SetRestoreSalesOrderQtyOnReturn(RestoreOrderQtyOnReturn: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Restore Order Qty. on Return", RestoreOrderQtyOnReturn);
        SalesReceivablesSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OperationTypeOnPostedPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Test to verify Operation Type after Posting Purchase Order.

        // Setup.
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, 0, CalcDate('<1M>', WorkDate()),
          VATPostingSetup."Unrealized VAT Type"::" ");  // Using 0 for Prepayment %.

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // True for receive and invoice.

        // Verify.
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.TestField("Operation Type", PurchaseHeader."Operation Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OperationTypeOnPostedPrePmtInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATpostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Test to verify Quantity after Posting Purchase Prepayment Order.

        // Setup.
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2), CalcDate('<1M>', WorkDate()),
          VATpostingSetup."Unrealized VAT Type"::" ");  // Using Random for Prepayment %.
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Posting No. Series");

        // Exercise.
        LibraryPurchase.PostPrepaymentInvoice(PurchaseHeader);

        // Verify.
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.TestField("Operation Type", PurchaseHeader."Operation Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OperationTypeOnPostedPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Test to verify Operation Type after Posting Purchase Credit Memo.

        // Setup.
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", 0, CalcDate('<1M>', WorkDate()),
          VATPostingSetup."Unrealized VAT Type"::" ");  // Using 0 for Prepayment %.

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // True for receive and invoice.

        // Verify.
        PurchCrMemoHdr.Get(DocumentNo);
        PurchCrMemoHdr.TestField("Operation Type", PurchaseHeader."Operation Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiplePurchPrepmtWithDiffVATProdPostingGroup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Test to verify post Purchase Prepayment Invoice with multiple Purchase Lines.

        // Setup: Create Purchase Order with multiple line with different VAT Prod. Posting Group.
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2), CalcDate('<1M>', WorkDate()),
          VATPostingSetup."Unrealized VAT Type"::" ");  // Using Random for Prepayment %.
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::" ");
        CreatePurchaseLine(PurchaseLine2, PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group");

        // Exercise.
        LibraryPurchase.PostPrepaymentInvoice(PurchaseHeader);

        // Verify: Verify values on Purchase Invoice Header and VAT Entry.
        VerifyPurchaseInvoiceHeader(PurchaseHeader, true);  // True for Prepayment Invoice.
        VerifyVATEntry(
          PurchaseHeader."Last Prepayment No.", PurchaseLine."VAT Prod. Posting Group", CalculateAmountPurchase(
            PurchaseLine), CalculateBasePurchase(PurchaseLine), 0, 0);  // Value 0 required Base Amount.

        VerifyVATEntry(
          PurchaseHeader."Last Prepayment No.", PurchaseLine2."VAT Prod. Posting Group", CalculateAmountPurchase(
            PurchaseLine2), CalculateBasePurchase(PurchaseLine2), 0, 0);  // Value 0 required Base Amount.

        // Tear Down.
        DeleteVATPostingSetup(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmtInvWithUpdatedVATPostingGroup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Test to verify VAT Entry after Posting Purchase Prepayment when VAT is changed on Purchase Line.

        // Setup: Create Purchase Order with VAT Prod. Posting Group
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2), CalcDate('<1M>', WorkDate()),
          VATPostingSetup."Unrealized VAT Type"::" ");  // Using Random for Prepayment %.
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::" ");
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        PurchaseLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        // Exercise.
        LibraryPurchase.PostPrepaymentInvoice(PurchaseHeader);

        //Verify: Verify Purchase Invoice Header and VAT Entry.
        VerifyPurchaseInvoiceHeader(PurchaseHeader, true);  // True for Prepayment Invoice.
        VerifyVATEntry(
          PurchaseHeader."Last Prepayment No.", PurchaseLine."VAT Prod. Posting Group", CalculateAmountPurchase(PurchaseLine), CalculateBasePurchase(PurchaseLine), 0, 0);  // Value 0 required for VAT Entry Unrealized Amount and VAT Entry Unrealized Base.

        // Tear Down.
        DeleteVATPostingSetup(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvAfterPrepmt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Test to verify that the VAT Entry is Zero, When Purch Invoice is posted after Prepayment.

        // Setup.
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, 100, CalcDate('<1M>', WorkDate()),
          VATPostingSetup."Unrealized VAT Type"::" ");  // Using 100 for Prepayment %.
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        LibraryPurchase.PostPrepaymentInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post Purchase Order as Ship & Invoice.

        // Verify.
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        VATEntry.TestField(Amount, Round(PurchaseLine."VAT Base Amount" * PurchaseLine."VAT %" / 100));
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLBookEntryApplyCustLedgerEntry()
    var
        GLAccount: Record "G/L Account";
        DocumentNo: Code[20];
    begin
        // Test to verify values on GL Book Entry after Apply Cust Ledger Entry.

        // Setup.
        LibraryERM.CreateGLAccount(GLAccount);
        DocumentNo := PostSalesInvoiceAndGeneralJournalLine(GLAccount."No.");

        // Exercise.
        ApplyCustomerLedgerEntries(DocumentNo);

        // Verify.
        VerifyGLBookEntry(GLAccount."No.");
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,UnapplyCustomerEntriesHandler,PostApplicationHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GLBookEntryUnapplyCustLedgerEntry()
    var
        GLAccount: Record "G/L Account";
        DocumentNo: Code[20];
    begin
        // Test to verify values on GL Book Entry after Unapply Cust Ledger Entry.

        // Setup.
        LibraryERM.CreateGLAccount(GLAccount);
        DocumentNo := PostSalesInvoiceAndGeneralJournalLine(GLAccount."No.");
        ApplyCustomerLedgerEntries(DocumentNo);

        // Exercise.
        UnApplyCustomerLedgerEntries(DocumentNo);

        // Verify.
        VerifyGLBookEntry(GLAccount."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OperationTypeOnPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 388656] Operation Type is correctly populated on new Purchase Credit Memos.

        // [WHEN] Create Purchase Credit Memo
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());

        // [THEN] Operation Type on Purchase Header is populated and correct
        PurchaseHeader.TestField(
          "Operation Type", LibraryERM.GetDefaultOperationType(PurchaseHeader."Buy-from Vendor No.", DATABASE::Vendor));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OperationTypeOnSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 388656] Operation Type is populated on new Sales Credit Memos.

        // [WHEN] Create Sales Credit Memo
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());

        // [THEN] Operation Type on Sales Header is populated and correct
        SalesHeader.TestField(
          "Operation Type", LibraryERM.GetDefaultOperationType(SalesHeader."Sell-to Customer No.", DATABASE::Customer));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetOperationTypeOnPurchaseCreditMemoAfterVendorValidate()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Credit Memo] [UT]
        // [SCENARIO 402089] System sets "Posting No. Series" and "Operation Type" from vendor's business posting group when it inserts new credit memo with specified vendor
        CreateVATPostingSetupWithCustomOperationTypes(VATPostingSetup);
        VATBusinessPostingGroup.Get(VATPostingSetup."VAT Bus. Posting Group");

        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusinessPostingGroup.Code));

        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Insert(true);

        PurchaseHeader.TestField("Operation Type", VATBusinessPostingGroup."Default Purch. Operation Type");
        PurchaseHeader.TestField("Posting No. Series", VATBusinessPostingGroup."Default Purch. Operation Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetOperationTypeOnSalesCreditMemoAfterCustomerValidate()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Credit Memo] [UT]
        // [SCENARIO 402089] System sets "Posting No. Series" and "Operation Type" from customer's business posting group when it inserts new credit memo with specified customer
        CreateVATPostingSetupWithCustomOperationTypes(VATPostingSetup);
        VATBusinessPostingGroup.Get(VATPostingSetup."VAT Bus. Posting Group");

        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATBusinessPostingGroup.Code));

        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Insert(true);

        SalesHeader.TestField("Operation Type", VATBusinessPostingGroup."Default Sales Operation Type");
        SalesHeader.TestField("Posting No. Series", VATBusinessPostingGroup."Default Sales Operation Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetOperationTypeOnPurchaseInvoiceAfterVendorValidate()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 402089] System sets "Posting No. Series" and "Operation Type" from vendor's business posting group when it inserts new invoice with specified vendor
        CreateVATPostingSetupWithCustomOperationTypes(VATPostingSetup);
        VATBusinessPostingGroup.Get(VATPostingSetup."VAT Bus. Posting Group");

        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusinessPostingGroup.Code));

        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Insert(true);

        PurchaseHeader.TestField("Operation Type", VATBusinessPostingGroup."Default Purch. Operation Type");
        PurchaseHeader.TestField("Posting No. Series", VATBusinessPostingGroup."Default Purch. Operation Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetOperationTypeOnSalesInvoiceAfterCustomerValidate()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 402089] System sets "Posting No. Series" and "Operation Type" from customer's business posting group when it inserts new invoice with specified customer
        CreateVATPostingSetupWithCustomOperationTypes(VATPostingSetup);
        VATBusinessPostingGroup.Get(VATPostingSetup."VAT Bus. Posting Group");

        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATBusinessPostingGroup.Code));

        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Insert(true);

        SalesHeader.TestField("Operation Type", VATBusinessPostingGroup."Default Sales Operation Type");
        SalesHeader.TestField("Posting No. Series", VATBusinessPostingGroup."Default Sales Operation Type");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ValidatingConfirmHandler')]
    procedure SetOperationTypeWhenVATBusPostingGroupValidateOnPurchaseCreditMemoHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        VATBusinessPostingGroup: array[2] of Record "VAT Business Posting Group";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Credit Memo] [UT]
        // [SCENARIO 436558] System sets "Posting No. Series" and "Operation Type" from VAT Business Posting Group validated on Purchase Credit Memo with vendor.
        CreateVATPostingSetupWithCustomOperationTypes(VATPostingSetup[1]);
        VATBusinessPostingGroup[1].Get(VATPostingSetup[1]."VAT Bus. Posting Group");
        CreateVATPostingSetupWithCustomOperationTypes(VATPostingSetup[2], VATPostingSetup[1]."VAT Prod. Posting Group");
        VATBusinessPostingGroup[2].Get(VATPostingSetup[2]."VAT Bus. Posting Group");

        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusinessPostingGroup[1].Code));

        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Insert(true);

        PurchaseHeader.TestField("Operation Type", VATBusinessPostingGroup[1]."Default Purch. Operation Type");
        PurchaseHeader.TestField("Posting No. Series", VATBusinessPostingGroup[1]."Default Purch. Operation Type");

        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader,
            PurchaseLine.Type::Item, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup[1]."VAT Prod. Posting Group"), 1);

        LibraryVariableStorage.Enqueue(ConfirmPurchaseChangeVATBusPostingGroupTxt);
        LibraryVariableStorage.Enqueue(true);
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup[2].Code);
        PurchaseHeader.Modify(true);

        PurchaseHeader.TestField("Operation Type", VATBusinessPostingGroup[2]."Default Purch. Operation Type");
        PurchaseHeader.TestField("Posting No. Series", VATBusinessPostingGroup[2]."Default Purch. Operation Type");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ValidatingConfirmHandler')]
    procedure SetOperationTypeWhenVATBusPostingGroupValidateOnSalesCreditMemoHeader()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        VATBusinessPostingGroup: array[2] of Record "VAT Business Posting Group";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Credit Memo] [UT]
        // [SCENARIO 436558] System sets "Posting No. Series" and "Operation Type" from VAT Business Posting Group validated on Sales Credit Memo with customer.
        CreateVATPostingSetupWithCustomOperationTypes(VATPostingSetup[1]);
        VATBusinessPostingGroup[1].Get(VATPostingSetup[1]."VAT Bus. Posting Group");
        CreateVATPostingSetupWithCustomOperationTypes(VATPostingSetup[2], VATPostingSetup[1]."VAT Prod. Posting Group");
        VATBusinessPostingGroup[2].Get(VATPostingSetup[2]."VAT Bus. Posting Group");

        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATBusinessPostingGroup[1].Code));

        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Insert(true);

        SalesHeader.TestField("Operation Type", VATBusinessPostingGroup[1]."Default Sales Operation Type");
        SalesHeader.TestField("Posting No. Series", VATBusinessPostingGroup[1]."Default Sales Operation Type");

        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader,
            SalesLine.Type::Item, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup[1]."VAT Prod. Posting Group"), 1);

        LibraryVariableStorage.Enqueue(ConfirmSalesChangeVATBusPostingGroupTxt);
        LibraryVariableStorage.Enqueue(true);
        SalesHeader.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup[2].Code);
        SalesHeader.Modify(true);

        SalesHeader.TestField("Operation Type", VATBusinessPostingGroup[2]."Default Sales Operation Type");
        SalesHeader.TestField("Posting No. Series", VATBusinessPostingGroup[2]."Default Sales Operation Type");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ValidatingConfirmHandler')]
    procedure SetOperationTypeWhenVATBusPostingGroupValidateOnPurchaseInvoiceHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        VATBusinessPostingGroup: array[2] of Record "VAT Business Posting Group";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 436558] System sets "Posting No. Series" and "Operation Type" from VAT Business Posting Group validated on Purchase Invoice with vendor.
        CreateVATPostingSetupWithCustomOperationTypes(VATPostingSetup[1]);
        VATBusinessPostingGroup[1].Get(VATPostingSetup[1]."VAT Bus. Posting Group");
        CreateVATPostingSetupWithCustomOperationTypes(VATPostingSetup[2], VATPostingSetup[1]."VAT Prod. Posting Group");
        VATBusinessPostingGroup[2].Get(VATPostingSetup[2]."VAT Bus. Posting Group");

        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusinessPostingGroup[1].Code));

        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Insert(true);

        PurchaseHeader.TestField("Operation Type", VATBusinessPostingGroup[1]."Default Purch. Operation Type");
        PurchaseHeader.TestField("Posting No. Series", VATBusinessPostingGroup[1]."Default Purch. Operation Type");

        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader,
            PurchaseLine.Type::Item, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup[1]."VAT Prod. Posting Group"), 1);

        LibraryVariableStorage.Enqueue(ConfirmPurchaseChangeVATBusPostingGroupTxt);
        LibraryVariableStorage.Enqueue(true);
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup[2].Code);
        PurchaseHeader.Modify(true);

        PurchaseHeader.TestField("Operation Type", VATBusinessPostingGroup[2]."Default Purch. Operation Type");
        PurchaseHeader.TestField("Posting No. Series", VATBusinessPostingGroup[2]."Default Purch. Operation Type");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ValidatingConfirmHandler')]
    procedure SetOperationTypeWhenVATBusPostingGroupValidateOnSalesInvoiceHeader()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        VATBusinessPostingGroup: array[2] of Record "VAT Business Posting Group";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 436558] System sets "Posting No. Series" and "Operation Type" from VAT Business Posting Group validated on Sales Invoice with customer.
        CreateVATPostingSetupWithCustomOperationTypes(VATPostingSetup[1]);
        VATBusinessPostingGroup[1].Get(VATPostingSetup[1]."VAT Bus. Posting Group");
        CreateVATPostingSetupWithCustomOperationTypes(VATPostingSetup[2], VATPostingSetup[1]."VAT Prod. Posting Group");
        VATBusinessPostingGroup[2].Get(VATPostingSetup[2]."VAT Bus. Posting Group");

        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATBusinessPostingGroup[1].Code));

        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Insert(true);

        SalesHeader.TestField("Operation Type", VATBusinessPostingGroup[1]."Default Sales Operation Type");
        SalesHeader.TestField("Posting No. Series", VATBusinessPostingGroup[1]."Default Sales Operation Type");

        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader,
            SalesLine.Type::Item, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup[1]."VAT Prod. Posting Group"), 1);

        LibraryVariableStorage.Enqueue(ConfirmSalesChangeVATBusPostingGroupTxt);
        LibraryVariableStorage.Enqueue(true);
        SalesHeader.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup[2].Code);
        SalesHeader.Modify(true);

        SalesHeader.TestField("Operation Type", VATBusinessPostingGroup[2]."Default Sales Operation Type");
        SalesHeader.TestField("Posting No. Series", VATBusinessPostingGroup[2]."Default Sales Operation Type");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetOperationTypeOnPurchaseCreditMemoAfterVatBusinessPostingGroupUpdate()
    var
        PurchaseHeader: Record "Purchase Header";
        VATBusinessPostingGroup: array[2] of Record "VAT Business Posting Group";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 555768] Operation Type is updated in Purchase Credit Memos when VAT Business Posting Setup is updated.

        // [GIVEN] Create VAT Posting Setup "1" with Operation Types.
        CreateVATPostingSetupWithCustomOperationTypes(VATPostingSetup[1]);
        VATBusinessPostingGroup[1].Get(VATPostingSetup[1]."VAT Bus. Posting Group");

        // [GIVEN] Create VAT Posting Setup "2" with Operation Types.
        CreateVATPostingSetupWithCustomOperationTypes(VATPostingSetup[2], VATPostingSetup[1]."VAT Prod. Posting Group");
        VATBusinessPostingGroup[2].Get(VATPostingSetup[2]."VAT Bus. Posting Group");

        // [GIVEN] Create Vendor with VAT Business Posting Group.
        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusinessPostingGroup[1].Code));

        // [GIVEN] Create Purchase Credit Memo.
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Insert(true);

        // [WHEN] Validate VAT Bus. Posting Group in Purchase Header.
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup[2].Code);
        PurchaseHeader.Modify(true);

        // [THEN] Operation Type is updated in Purchase Header as per VAT Bus. Posting Group.
        Assert.AreEqual(
            VATBusinessPostingGroup[2]."Default Purch. Operation Type",
            PurchaseHeader."Operation Type",
            StrSubstNo(
                OperationTypeErr,
                VATBusinessPostingGroup[2]."Default Purch. Operation Type",
                PurchaseHeader.TableCaption()));
    end;

    local procedure ApplyAndPostGeneralJournalLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountNo: Code[20]; Amount: Decimal; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ApplyCustomerLedgerEntries(DocumentNo: Code[20])
    var
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.FILTER.SetFilter("Document No.", DocumentNo);
        CustomerLedgerEntries."Apply Entries".Invoke();
        CustomerLedgerEntries.Close();
    end;

    local procedure CalculateAmount(SalesLine: Record "Sales Line"): Decimal
    begin
        exit(SalesLine."Line Amount" * SalesLine."Prepayment %" / 100 * SalesLine."VAT %" / 100);
    end;

    local procedure CalculateAmountPurchase(PurchaseLine: Record "Purchase Line"): Decimal
    begin
        exit(-PurchaseLine."Line Amount" * PurchaseLine."Prepayment %" / 100 * PurchaseLine."VAT %" / 100);
    end;

    local procedure CalculateBase(SalesLine: Record "Sales Line"): Decimal
    begin
        exit(SalesLine."Line Amount" * SalesLine."Prepayment %" / 100);
    end;

    local procedure CalculateBasePurchase(PurchaseLine: Record "Purchase Line"): Decimal
    begin
        exit(-PurchaseLine."Line Amount" * PurchaseLine."Prepayment %" / 100);
    end;

    local procedure CreateVATPostingSetupWithCustomOperationTypes(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VATBusinessPostingGroup.Validate("Default Purch. Operation Type", LibraryERM.CreateNoSeriesPurchaseCode());
        VATBusinessPostingGroup.Validate("Default Sales Operation Type", LibraryERM.CreateNoSeriesSalesCode());
        VATBusinessPostingGroup.Modify(true);
        CreateVATPostingSetupWithCustomOperationTypes(VATPostingSetup, VATProductPostingGroup.Code);
    end;

    local procedure CreateVATPostingSetupWithCustomOperationTypes(var VATPostingSetup: Record "VAT Posting Setup"; VATProductPostingGroupCode: Code[20])
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VATBusinessPostingGroup.Validate("Default Purch. Operation Type", LibraryERM.CreateNoSeriesPurchaseCode());
        VATBusinessPostingGroup.Validate("Default Sales Operation Type", LibraryERM.CreateNoSeriesSalesCode());
        VATBusinessPostingGroup.Modify(true);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroupCode);
    end;

    local procedure PostSalesInvoiceAndGeneralJournalLine(GLAccountNo: Code[20]) DocumentNo: Code[20]
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        CreateSalesLine(SalesLine, SalesHeader, LibraryInventory.CreateItem(Item));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // True for ship and invoice.
        ApplyAndPostGeneralJournalLine(
          GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          GLAccountNo, -SalesLine.Amount, GenJournalLine."Applies-to Doc. Type"::" ", '');
        exit(DocumentNo);
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGLAccountWithProdPostingGroup(VATProdPostingGroup: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        FindAndUpdateGenPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; PrepaymentPct: Decimal; PrepaymentDueDate: Date; UnrealizedVATType: Option)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindAndUpdateGenPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(VATPostingSetup, UnrealizedVATType);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, DocumentType, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Prepayment %", PrepaymentPct);
        PurchaseHeader.Validate("Prepayment Due Date", PrepaymentDueDate);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATProdPostingGroup: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATProdPostingGroup), LibraryRandom.RandDec(10, 2));  // Using Random for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithVATPostingSetup(var SalesLine: Record "Sales Line"; PrepaymentPct: Decimal; UnrealizedVATType: Option)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindAndUpdateGenPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(VATPostingSetup, UnrealizedVATType);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        SalesHeader.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        SalesHeader.Validate("Prepayment %", PrepaymentPct);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVATType: Option)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATIdentifier: Record "VAT Identifier";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("Unrealized VAT Type", UnrealizedVATType);
        VATPostingSetup.Validate(
          "Sales VAT Unreal. Account", CreateGLAccountWithProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        VATPostingSetup.Validate("Sales VAT Account", CreateGLAccountWithProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDec(10, 2));
        VATPostingSetup.Validate(
          "Sales Prepayments Account", CreateGLAccountWithProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        VATPostingSetup.Validate(
          "Purch. VAT Unreal. Account", CreateGLAccountWithProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        VATPostingSetup.Validate(
          "Purch. Prepayments Account", CreateGLAccountWithProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        VATPostingSetup.Validate("Purchase VAT Account", CreateGLAccountWithProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        VATIdentifier.FindFirst();
        VATPostingSetup.Validate("VAT Identifier", VATIdentifier.Code);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure DeleteVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        VATPostingSetup.Delete();
    end;

    local procedure FindAndUpdateGenPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Sales Account", GLAccount."No.");
        GeneralPostingSetup.Modify(true);
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
    end;

    local procedure GetLastNoUsed(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.SetRange("Last Date Used", WorkDate());
        NoSeriesLine.FindFirst();
        exit(NoSeriesLine."Last No. Used");
    end;

    local procedure GetPostedDocumentNo(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.PeekNextNo(NoSeriesCode));
    end;

    local procedure PostSalesPrepaymentInvoice(var SalesHeader: Record "Sales Header"; DocumentNo: Code[20])
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
    end;

    local procedure UnApplyCustomerLedgerEntries(DocumentNo: Code[20])
    var
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.FILTER.SetFilter("Document No.", DocumentNo);
        CustomerLedgerEntries.UnapplyEntries.Invoke();
        CustomerLedgerEntries.Close();
    end;

    local procedure UpdateUnrealizedVATOnGeneralLedgerSetup(UnrealizedVAT: Boolean) OldUnrealizedVAT: Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldUnrealizedVAT := GeneralLedgerSetup."Unrealized VAT";
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateVATPostingGroupsOnSalesLine(var SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::" ");
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesLine.Modify(true);
    end;

    local procedure VerifyDebitAmountInGLBookEntry(DocumentNo: Code[20]; Positive: Boolean; DebitAmount: Decimal)
    var
        GLBookEntry: Record "GL Book Entry";
    begin
        GLBookEntry.SetRange("Document No.", DocumentNo);
        GLBookEntry.SetRange(Positive, Positive);
        GLBookEntry.FindFirst();
        GLBookEntry.CalcFields("Debit Amount");
        GLBookEntry.TestField("Debit Amount", DebitAmount);
    end;

    local procedure VerifyGLBookEntry(GLAccountNo: Code[20])
    var
        GLBookEntry: Record "GL Book Entry";
    begin
        GLBookEntry.SetRange("G/L Account No.", GLAccountNo);
        GLBookEntry.FindFirst();
        Assert.AreEqual(0, GLBookEntry.Amount, AmountErr);  // Value 0 required for GL Book Entry Amount.
    end;

    local procedure VerifyPurchaseInvoiceHeader(PurchaseHeader: Record "Purchase Header"; PrepaymentInvoice: Boolean)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchInvHeader.FindFirst();
        PurchInvHeader.TestField("No.", GetLastNoUsed(PurchaseHeader."Operation Type"));
        PurchInvHeader.TestField("Operation Type", PurchaseHeader."Operation Type");
        PurchInvHeader.TestField("Prepayment Invoice", PrepaymentInvoice);
    end;

    local procedure VerifyPurchCreditMemoHeader(PurchaseHeader: Record "Purchase Header")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchCrMemoHdr.FindFirst();
        PurchCrMemoHdr.TestField("No.", GetLastNoUsed(PurchaseHeader."Operation Type"));
        PurchCrMemoHdr.TestField("Operation Type", PurchaseHeader."Operation Type");
        PurchCrMemoHdr.TestField("Prepayment Credit Memo", true);
    end;

    local procedure VerifySalesCreditMemoHeader(SalesHeader: Record "Sales Header")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesCrMemoHeader.FindFirst();
        SalesCrMemoHeader.TestField("No.", GetLastNoUsed(SalesHeader."Operation Type"));
        SalesCrMemoHeader.TestField("Operation Type", SalesHeader."Operation Type");
        SalesCrMemoHeader.TestField("Prepayment Credit Memo", true);
    end;

    local procedure VerifySalesInvoiceHeader(SalesHeader: Record "Sales Header"; PrepaymentInvoice: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.TestField("No.", GetLastNoUsed(SalesHeader."Operation Type"));
        SalesInvoiceHeader.TestField("Operation Type", SalesHeader."Operation Type");
        SalesInvoiceHeader.TestField("Prepayment Invoice", PrepaymentInvoice);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; VATProdPostingGroup: Code[20]; Amount: Decimal; Base: Decimal; UnrealizedAmount: Decimal; UnrealizedBase: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(-Amount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountErr);
        Assert.AreNearlyEqual(-Base, VATEntry.Base, LibraryERM.GetAmountRoundingPrecision(), AmountErr);
        Assert.AreNearlyEqual(-UnrealizedAmount, VATEntry."Unrealized Amount", LibraryERM.GetAmountRoundingPrecision(), AmountErr);
        Assert.AreNearlyEqual(-UnrealizedBase, VATEntry."Unrealized Base", LibraryERM.GetAmountRoundingPrecision(), AmountErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries."Post Application".Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ValidatingConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationHandler(var PostApplication: TestPage "Post Application")
    begin
        PostApplication.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyCustomerEntriesHandler(var UnapplyCustomerEntries: TestPage "Unapply Customer Entries")
    begin
        UnapplyCustomerEntries.Unapply.Invoke();
    end;
}

