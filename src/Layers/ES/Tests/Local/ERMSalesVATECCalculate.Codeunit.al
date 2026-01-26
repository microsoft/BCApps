codeunit 144123 "ERM Sales VAT EC Calculate"
{
    //  // [FEATURE] [Sales] [VAT] [EC]
    //  1. Test to verify VAT Entry - Base, Amount and G/L Entry - Amount on Posted Sales Credit memo.
    //  2. Test to verify VAT Entry - Base, Amount and G/L Entry - Amount on Posted Sales Invoice.
    //  3. Test to verify VAT Entry - Base, Amount and G/L Entry - Amount on Posted Sales Credit memo with Currency.
    //  4. Test to verify Amounts on Sales Credit Memo Statistics Page on Posted Sales Credit Memo with multiple lines.
    //  5. Test to verify Amounts on Sales Invoice Statistics Page on Posted Sales Order with multiple lines.
    //  6. Test to verify Amounts on Sales Statistics Page on Created Sales Invoice.
    //  7. Test to verify VAT Entry - Base, Amount and G/L Entry - Amount on Posted Sales Invoice on General Journal with Currency.
    //  8. Test to verify G/L entry and VAT entry after posting Gen Journal Line with Currency and Reverse Charge VAT.
    //  9. Test to verify G/L entry and VAT entry after posting Gen Journal Line without Currency and Reverse Charge VAT.
    //  10.Test to verify G/L entry and VAT entry after posting Sales Credit Memo with Currency and Reverse Charge VAT.
    //  11.Test to verify G/L entry and VAT entry after posting Sales Credit Memo without Currency and Reverse Charge VAT.
    //  12.Test to verify G/L entry and VAT entry after posting Sales Credit Memo without Currency and Normal VAT.
    //  13.Test to verify Report ID - 205 Order Confirmation is displaying the correct output without generating any error message.
    //
    //    Covers Test Cases for WI - 352253.
    //   ----------------------------------------------------------------------------------
    //   Test Function Name                                                          TFS ID
    //   ----------------------------------------------------------------------------------
    //   VATEntryGLEntryAmountsOnPostedSalesCreditMemo                               217453
    //   VATEntryGLEntryAmountsOnPostedSalesInvoice,                                 217452
    //   LineAmountAndVATAmountOnSalesStatistics
    //   VATEntryGLEntryValueOnPostedSalesCreditMemoWithCurrency                     282937
    //   LineAmountAndVATAmountOnSalesCreditMemoStatistics                           219961
    //   LineAmountAndVATAmountOnSalesInvoiceStatistics                              219962
    //   VATEntryGLEntryValueOnPostedGeneralJournalWithCurrency               158894,158896
    //
    //   Covers Test Cases for WI - 352250
    //   ----------------------------------------------------------------------------------
    //   Test Function Name                                                          TFS ID
    //   -----------------------------------------------------------------------------------
    //   GenJournalLineReverseChargeVATWithCurrency                                  158898
    //   GenJournalLineReverseChargeVATWithoutCurrency                               158900
    //   PostedSalesCreditMemoReverseChargeVATWithCurrency                           282941
    //   PostedSalesCreditMemoReverseChargeVATWithoutCurr                            282940
    //   PostedSalesCreditMemoNormalVATWithoutCurrency                               282938
    //
    //   Covers Test Cases for WI - 352352.
    //   ----------------------------------------------------------------------------------
    //   Test Function Name                                                          TFS ID
    //   ----------------------------------------------------------------------------------
    //   SalesOrderConfirmation                                                      152713

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmountMustBeEqualMsg: Label 'Amount Must Be Equal';
        DiscAccountGLEntryCreatedErr: Label 'G/L Entry with Sales Line Disc. Account should not be created.';
        TotalFromSevPrepmtAmtErr: Label 'Total amount from several prepayments must be equal to original document amount';
        CountryCodeLbl: Label '%1 must be %2', Comment = '%1 Field ,%2 = Expected Value';

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryGLEntryAmountsOnPostedSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test to verify VAT Entry - Base, Amount and G/L Entry - Amount on Posted Sales Credit memo.
        VATEntryGLEntryAmountsOnPostedSalesDocument(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryGLEntryAmountsOnPostedSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test to verify VAT Entry - Base, Amount and G/L Entry - Amount on Posted Sales Invoice.
        VATEntryGLEntryAmountsOnPostedSalesDocument(SalesHeader."Document Type"::Invoice);
    end;

    local procedure VATEntryGLEntryAmountsOnPostedSalesDocument(DocumentType: Enum "Sales Document Type")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostLineDiscount: Boolean;
        DocumentNo: Code[20];
    begin
        // Setup: Create Sales Document.
        Initialize();
        PostLineDiscount := UpdatePostLineDiscountOnSalesReceivablesSetup(true);  // True used for Post Line Discount.
        CreateSalesDocument(SalesLine, DocumentType, '');  // Blank - Currency Code.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify VAT Entry - Base, Amount and G/L Entry - Amount on Posted Sales Document.
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyVATAndGLEntry(
          DocumentType, DocumentNo, GeneralPostingSetup."Sales Inv. Disc. Account", SalesLine."Line Discount Amount",
          0, SalesLine."VAT %");  // 0 for Additional Currency Amount.

        // Tear Down.
        UpdatePostLineDiscountOnSalesReceivablesSetup(PostLineDiscount);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger.', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure LineAmountAndVATAmountOnStatistics()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        PostLineDiscount: Boolean;
    begin
        // Test to verify Amounts on Sales Statistics Page on Created Sales Invoice.

        // Setup: Create Sales Invoice, Open Sales Invoice page and Enqueue values for SalesStatisticsModalPageHandler.
        Initialize();
        PostLineDiscount := UpdatePostLineDiscountOnSalesReceivablesSetup(true);  // True used for Post Line Discount.
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, '');  // Blank - Currency Code.
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesLine."Document No.");
        LibraryVariableStorage.Enqueue(SalesLine.Amount);
        LibraryVariableStorage.Enqueue(SalesLine.Amount * SalesLine."VAT %" / 100);
        LibraryVariableStorage.Enqueue(SalesLine.Amount * SalesLine."EC %" / 100);

        // Exercise.
        SalesInvoice.Statistics.Invoke();  // Opens SalesStatisticsModalPageHandler.

        // Verify: Verification of Amounts is done in SalesStatisticsModalPageHandler.

        // Tear Down.
        SalesInvoice.Close();
        UpdatePostLineDiscountOnSalesReceivablesSetup(PostLineDiscount);
    end;
#endif
    [Test]
    [HandlerFunctions('SalesStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure LineAmountAndVATAmountOnSalesStatistics()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        PostLineDiscount: Boolean;
    begin
        // Test to verify Amounts on Sales Statistics Page on Created Sales Invoice.

        // Setup: Create Sales Invoice, Open Sales Invoice page and Enqueue values for SalesStatisticsPageHandler.
        Initialize();
        PostLineDiscount := UpdatePostLineDiscountOnSalesReceivablesSetup(true);  // True used for Post Line Discount.
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, '');  // Blank - Currency Code.
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesLine."Document No.");
        LibraryVariableStorage.Enqueue(SalesLine.Amount);
        LibraryVariableStorage.Enqueue(SalesLine.Amount * SalesLine."VAT %" / 100);
        LibraryVariableStorage.Enqueue(SalesLine.Amount * SalesLine."EC %" / 100);

        // Exercise.
        SalesInvoice.SalesStatistics.Invoke();  // Opens SalesStatisticsPageHandler.

        // Verify: Verification of Amounts is done in SalesStatisticsPageHandler.

        // Tear Down.
        SalesInvoice.Close();
        UpdatePostLineDiscountOnSalesReceivablesSetup(PostLineDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryGLEntryValueOnPostedSalesCreditMemoWithCurrency()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        OldCurrencyCode: Code[10];
        PostLineDiscount: Boolean;
    begin
        // Test to verify VAT Entry - Base, Amount and G/L Entry - Amount on Posted Sales Credit memo with Currency.

        // Setup: Create Sales Credit Memo with Currency.
        Initialize();
        PostLineDiscount := UpdatePostLineDiscountOnSalesReceivablesSetup(true);
        CurrencyCode := CreateCurrencyWithExchangeRate();
        OldCurrencyCode := UpdateAdditionalReportingCurrencyOnGeneralLedgerSetup(CurrencyCode);
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo", CurrencyCode);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify VAT Entry - Base, Amount and G/L Entry - Amount on Posted Sales Credit memo.
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyVATAndGLEntry(
          SalesHeader."Document Type"::"Credit Memo", DocumentNo, GeneralPostingSetup."Sales Inv. Disc. Account",
          SalesLine."Line Discount Amount", LibraryERM.ConvertCurrency(-SalesLine."Line Discount Amount", '', CurrencyCode, WorkDate()),
          SalesLine."VAT %");

        // Tear Down.
        UpdateAdditionalReportingCurrencyOnGeneralLedgerSetup(OldCurrencyCode);
        UpdatePostLineDiscountOnSalesReceivablesSetup(PostLineDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineAmountAndVATAmountOnSalesCreditMemoStatistics()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCreditMemoStatistics: TestPage "Sales Credit Memo Statistics";
        PostLineDiscount: Boolean;
        DocumentNo: Code[20];
    begin
        // Test to verify Amounts on Sales Credit Memo Statistics Page on Posted Sales Credit Memo with multiple lines.

        // Setup: Create and Post Sales Credit Memo with multiple lines.
        Initialize();
        PostLineDiscount := UpdatePostLineDiscountOnSalesReceivablesSetup(true);  // True used for Post Line Discount.
        DocumentNo := CreateAndPostSalesDocumentWithMultipleLine(SalesLine, SalesHeader."Document Type"::"Credit Memo");
        SalesCrMemoHeader.Get(DocumentNo);
        SalesCrMemoHeader.CalcFields(Amount);

        // Exercise: Invoke Sales Credit Memo Statistics.
        InvokeSalesCreditMemoStatistics(SalesCreditMemoStatistics, DocumentNo);

        // Verify: Verify Line Amount and VAT Amount on Page - Sales Credit Memo Statistics.
        SalesCreditMemoStatistics.Subform."Line Amount".AssertEquals(SalesCrMemoHeader.Amount);
        SalesCreditMemoStatistics.Subform."VAT Amount".AssertEquals(SalesCrMemoHeader.Amount * SalesLine."VAT %" / 100);

        // Tear Down.
        SalesCreditMemoStatistics.Close();
        UpdatePostLineDiscountOnSalesReceivablesSetup(PostLineDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineAmountAndVATAmountOnSalesInvoiceStatistics()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceStatistics: TestPage "Sales Invoice Statistics";
        PostLineDiscount: Boolean;
        DocumentNo: Code[20];
    begin
        // Test to verify Amounts on Sales Invoice Statistics Page on Posted Sales Order with multiple lines.

        // Setup: Create and Post Sales Order with multiple lines.
        Initialize();
        PostLineDiscount := UpdatePostLineDiscountOnSalesReceivablesSetup(true);  // True used for Post Line Discount.
        DocumentNo := CreateAndPostSalesDocumentWithMultipleLine(SalesLine, SalesHeader."Document Type"::Order);
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.CalcFields(Amount);

        // Exercise: Invoke Sales Invoice Statistics.
        InvokeSalesInvoiceStatistics(SalesInvoiceStatistics, DocumentNo);

        // Verify: Verify Line Amount and VAT Amount on Page - Sales Invoice Statistics.
        SalesInvoiceStatistics.Subform."Line Amount".AssertEquals(SalesInvoiceHeader.Amount);
        SalesInvoiceStatistics.Subform."VAT Amount".AssertEquals(SalesInvoiceHeader.Amount * SalesLine."VAT %" / 100);

        // Tear Down.
        SalesInvoiceStatistics.Close();
        UpdatePostLineDiscountOnSalesReceivablesSetup(PostLineDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryGLEntryValueOnPostedGeneralJournalWithCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        OldCurrencyCode: Code[10];
    begin
        // Test to verify VAT Entry - Base, Amount and G/L Entry - Amount on Posted Sales Invoice on General Journal with Currency.

        // Setup.
        Initialize();
        CurrencyCode := CreateCurrencyWithExchangeRate();
        OldCurrencyCode := UpdateAdditionalReportingCurrencyOnGeneralLedgerSetup(CurrencyCode);

        // Exercise: Create and Post Sales Invoice on General Journal with Currency.
        CreateAndPostGeneralJournalLine(GenJournalLine, CurrencyCode, LibraryRandom.RandDec(100, 2));  // Random - Amount.

        // Verify: Verify VAT Entry - Base, Amount and G/L Entry - Amount on Posted Invoice on General Journal.
        VerifyGLEntry(
          GenJournalLine."Document No.", GetReceivableAccount(GenJournalLine."Account No."),
          LibraryERM.ConvertCurrency(GenJournalLine.Amount, CurrencyCode, '', WorkDate()), GenJournalLine.Amount);

        // Tear Down.
        UpdateAdditionalReportingCurrencyOnGeneralLedgerSetup(OldCurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJournalLineReverseChargeVATWithCurrency()
    var
        Amount: Decimal;
    begin
        // Test to verify G/L entry and VAT entry after posting Gen Journal Line with Currency and Reverse Charge VAT.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        PostGenJournalLineAndVerifyGLVATEntry(CreateCurrencyWithExchangeRate(), Amount, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJournalLineReverseChargeVATWithoutCurrency()
    begin
        // Test to verify G/L entry and VAT entry after posting Gen Journal Line without Currency and Reverse Charge VAT.
        Initialize();
        PostGenJournalLineAndVerifyGLVATEntry('', LibraryRandom.RandDec(100, 2), 0);  // Blank for Currency Code, random value for Amount, 0 for Additional Currency Base.
    end;

    local procedure PostGenJournalLineAndVerifyGLVATEntry(CurrencyCode: Code[10]; Amount: Decimal; AdditionalCurrencyBase: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        OldAdditionalReportingCurrency: Code[10];
    begin
        // Setup: Create Gen. Posting Setup, VAT Posting Setup. Create two Gen. Journal Lines
        OldAdditionalReportingCurrency := UpdateAdditionalReportingCurrencyOnGeneralLedgerSetup(CurrencyCode);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        CustomerNo :=
          CreateCustomerWithPostingGroup(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, Amount, CurrencyCode);
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", CreateGLAccount(
            GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group",
            VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group"), -Amount, CurrencyCode);

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Amount, Additional Currency Base, VAT Amount and Additional Currency Amount on G/L Entry and VAT Entry.
        VerifyGLEntry(
          GenJournalLine."Document No.", GenJournalLine."Account No.", LibraryERM.ConvertCurrency(
            -Amount, CurrencyCode, '', WorkDate()), -AdditionalCurrencyBase);  // Blank for To Currency.
        VerifyGLEntry(
          GenJournalLine."Document No.", GetReceivableAccount(CustomerNo), LibraryERM.ConvertCurrency(
            Amount, CurrencyCode, '', WorkDate()), AdditionalCurrencyBase);  // Blank for To Currency.
        VerifyVATEntry(
          GenJournalLine."Document No.", LibraryERM.ConvertCurrency(-Amount, CurrencyCode, '', WorkDate()), -AdditionalCurrencyBase, 0);  // Blank for To Currency, 0 for VAT Amount.

        // Tear down.
        UpdateAdditionalReportingCurrencyOnGeneralLedgerSetup(OldAdditionalReportingCurrency);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesCreditMemoReverseChargeVATWithCurrency()
    var
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // Test to verify G/L entry and VAT entry after posting Sales Credit Memo with Currency and Reverse Charge VAT.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        UnitPrice := LibraryRandom.RandDec(100, 2);
        PostSalesCreditMemoAndVerifyGLVATEntry(CreateCurrencyWithExchangeRate(), Quantity, UnitPrice, Quantity * UnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesCreditMemoReverseChargeVATWithoutCurr()
    var
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // Test to verify G/L entry and VAT entry after posting Sales Credit Memo without Currency and Reverse Charge VAT.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        UnitPrice := LibraryRandom.RandDec(100, 2);
        PostSalesCreditMemoAndVerifyGLVATEntry('', Quantity, UnitPrice, 0);  // Blank for Currency Code, 0 for Additional Currency Base.
    end;

    local procedure PostSalesCreditMemoAndVerifyGLVATEntry(CurrencyCode: Code[10]; Quantity: Decimal; UnitPrice: Decimal; AdditionalCurrencyBase: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        OldAdditionalReportingCurrency: Code[10];
        OldInvoiceRounding: Boolean;
    begin
        // Setup: Create Sales Credit Memo.
        OldAdditionalReportingCurrency := UpdateAdditionalReportingCurrencyOnGeneralLedgerSetup(CurrencyCode);
        OldInvoiceRounding := UpdateInvRoundingSalesReceivablesSetup(false);  // FALSE for Invoice Rounding.
        CreateSalesCreditMemo(SalesLine, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", CurrencyCode, Quantity, UnitPrice);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify: Verify Amount, Additional Currency Base, VAT Amount and Additional Currency Amount on G/L Entry and VAT Entry.
        VerifyGLEntry(
          DocumentNo, SalesLine."No.", LibraryERM.ConvertCurrency(Quantity * UnitPrice, CurrencyCode, '', WorkDate()), AdditionalCurrencyBase);
        VerifyGLEntry(
          DocumentNo, GetReceivableAccount(SalesLine."Sell-to Customer No."), LibraryERM.ConvertCurrency(
            -Quantity * UnitPrice, CurrencyCode, '', WorkDate()), -AdditionalCurrencyBase);  // Blank for To Currency.
        VerifyVATEntry(DocumentNo, LibraryERM.ConvertCurrency(Quantity * UnitPrice, CurrencyCode, '', WorkDate()), AdditionalCurrencyBase, 0);  // 0 for VAT Amount.

        // Tear down.
        UpdateAdditionalReportingCurrencyOnGeneralLedgerSetup(OldAdditionalReportingCurrency);
        UpdateInvRoundingSalesReceivablesSetup(OldInvoiceRounding);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesCreditMemoNormalVATWithoutCurrency()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        OldInvoiceRounding: Boolean;
        DocumentNo: Code[20];
        VATAmount: Decimal;
        PostLineDiscount: Boolean;
    begin
        // Test to verify G/L entry and VAT entry after posting Sales Credit Memo without Currency and Normal VAT.

        // Setup: Create Sales Credit Memo.
        Initialize();
        OldInvoiceRounding := UpdateInvRoundingSalesReceivablesSetup(false);  // FALSE for Invoice Rounding.
        PostLineDiscount := UpdatePostLineDiscountOnSalesReceivablesSetup(true);

        CreateSalesCreditMemo(
          SalesLine, VATPostingSetup."VAT Calculation Type"::"Normal VAT", '',
          LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));  // Blank for Currency Code, random value for Quantity and Unit Price.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify: Verify Amount, Additional Currency Base, VAT Amount and Additional Currency Amount on G/L Entry and VAT Entry.
        VATAmount := SalesLine.Amount * (SalesLine."VAT %" + SalesLine."EC %") / 100;
        VerifyGLEntry(DocumentNo, SalesLine."No.", SalesLine.Amount, 0);  // 0 for Additional Currency Amount.
        VerifyGLEntry(
          DocumentNo, GetReceivableAccount(
            SalesLine."Sell-to Customer No."), -(SalesLine.Amount + VATAmount), 0);  // 0 for Additional Currency Amount.
        VerifyVATEntry(DocumentNo, SalesLine.Amount, 0, VATAmount);  // 0 for Additional Currency Amount.

        // Tear down.
        UpdateInvRoundingSalesReceivablesSetup(OldInvoiceRounding);
        UpdatePostLineDiscountOnSalesReceivablesSetup(PostLineDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDiscAccOnPostedSalesInvoice()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostLineDiscount: Boolean;
        DocumentNo: Code[20];
    begin
        // Setup.
        Initialize();
        PostLineDiscount := UpdatePostLineDiscountOnSalesReceivablesSetup(false);

        // Exercise.
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, '');  // Blank - Currency Code.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify.
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyGLEntryWithDiscAccount(DocumentNo, GeneralPostingSetup."Sales Line Disc. Account");

        // Tear Down.
        UpdatePostLineDiscountOnSalesReceivablesSetup(PostLineDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneSalesDocWithSeveralPrepaymentsGiving100Pct()
    var
        SalesHeader: Record "Sales Header";
        DocAmount: Decimal;
        PrepmtInvoicesCnt: Integer;
        i: Integer;
    begin
        // [FEATURE] [Prepayment]
        // [SCENARIO 123180] Several prepayments from one sales document gives full document amount
        Initialize();

        // [GIVEN] Sales document with 50% prepayment
        PrepmtInvoicesCnt := LibraryRandom.RandIntInRange(3, 5);
        DocAmount := CreateSalesDocWithPostingSetup(SalesHeader);

        // [GIVEN] Post first prepayment invoice
        for i := 1 to PrepmtInvoicesCnt - 1 do begin
            UpdateSalesDocPrepaymentPct(
              SalesHeader, SalesHeader."Prepayment %" + LibraryRandom.RandIntInRange(10, 20));
            LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
            LibrarySales.ReopenSalesDocument(SalesHeader);
        end;

        // [GIVEN] Modify sales document prepayment to 100%
        UpdateSalesDocPrepaymentPct(SalesHeader, 100);

        // [WHEN] Post second prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Total amount from two posted prepayment invoices = document amount
        Assert.AreEqual(
          DocAmount,
          GetPrepaymentInvoicesAmt(SalesHeader."Sell-to Customer No."),
          TotalFromSevPrepmtAmtErr);
    end;

    [Test]
    [HandlerFunctions('SalesPrepmtDocTestRPH')]
    [Scope('OnPrem')]
    procedure ECAmountOnSalesPrepmtDocumentTestReportForSecondPrepayment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstPrepmtPct: Decimal;
        ExpectedECAmount: Decimal;
    begin
        // [FEATURE] [Prepayment]
        // [SCENARIO 123350] "Sales Prepmt. Document Test" EC Amount = prepayment EC amount for second prepayment
        Initialize();

        // [GIVEN] Sales document with Amount = "A", Prepayment % = "P", "EC %" = "E"
        CreateSalesDocWithPostingSetup(SalesHeader);
        UpdateSalesDocPrepaymentPct(SalesHeader, LibraryRandom.RandIntInRange(10, 90));
        FirstPrepmtPct := SalesHeader."Prepayment %";

        // [GIVEN] Post prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Modify sales document prepayment to 100%
        LibrarySales.ReopenSalesDocument(SalesHeader);
        UpdateSalesDocPrepaymentPct(SalesHeader, 100);

        // [WHEN] Run "Sales Prepmt. Doc. - Test" report
        RunSalesPrepmtDocTestReport(SalesHeader."No.");

        // [THEN] "EC Amount" = "A" * (100 - "P") * "E"
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        ExpectedECAmount := Round(SalesLine."VAT Base Amount" * SalesLine."EC %" / 100);
        ExpectedECAmount := Round(ExpectedECAmount * (100 - FirstPrepmtPct) / 100);
        VerifySalesPrepmtDocTestReportECAmount(ExpectedECAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryGLEntryAmountsOnPostedSalesInvoicePriceInclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        ItemNo: Code[20];
        ItemUnitPrice: Decimal;
    begin
        // [SCENARIO 363582] Sales Document Posting with EC % and Prices Incl. VAT = TRUE
        Initialize();

        // [GIVEN] General Posting Setup with EC % = 4 and VAT % = 18 specified
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] Item with Unit Price = 100
        ItemUnitPrice := LibraryRandom.RandDec(100, 2);
        ItemNo :=
          CreateItemWithUnitPriceProdPostingGroups(
            ItemUnitPrice, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        CustomerNo :=
          CreateCustomerWithPostingGroup(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Posted Sales Invoice with Item Quantity = 1, Unit Price = 100, Prices Including VAT = TRUE
        CreateSalesDocumentWithPriceInclVAT(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          CustomerNo, SalesLine.Type::Item, ItemNo, true, 0);

        // [WHEN] Post Sales Document
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales Account GL Entry Amount = 100.
        VerifyGLEntry(
          DocumentNo, GeneralPostingSetup."Sales Account", -ItemUnitPrice * SalesLine.Quantity, 0);
        // [THEN] VAT GL Entry Amount = 22.
        VerifyGLEntry(
          DocumentNo, VATPostingSetup."Sales VAT Account",
          -ItemUnitPrice * SalesLine.Quantity * (SalesLine."VAT %" + SalesLine."EC %") / 100, 0);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger.', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoicePriceInclVATECStatistics()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesInvoice: TestPage "Sales Invoice";
        ItemNo: Code[20];
        CustomerNo: Code[20];
        ItemUnitPrice: Decimal;
    begin
        // [SCENARIO 363582] Sales Statistics with EC % and Prices Incl. VAT = TRUE
        Initialize();

        // [GIVEN] General Posting Setup with EC % = 4 and VAT % = 18 specified
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] Item with Unit Price = 100
        ItemUnitPrice := LibraryRandom.RandDec(100, 2);
        ItemNo :=
          CreateItemWithUnitPriceProdPostingGroups(
            ItemUnitPrice, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        CustomerNo :=
          CreateCustomerWithPostingGroup(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Sales Invoice with Item Quantity = 1, Unit Price = 100, Prices Including VAT = TRUE
        CreateSalesDocumentWithPriceInclVAT(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          CustomerNo, SalesLine.Type::Item, ItemNo, true, 0);

        // [WHEN] Open Sales Statistics Page
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");

        // [THEN] "Line Amount" = 122, "VAT Amount" = 18, "EC Amount" = 4
        LibraryVariableStorage.Enqueue(
          ItemUnitPrice * SalesLine.Quantity * (1 + (SalesLine."VAT %" + SalesLine."EC %") / 100));
        LibraryVariableStorage.Enqueue(
          ItemUnitPrice * SalesLine.Quantity * (SalesLine."VAT %" / 100));
        LibraryVariableStorage.Enqueue(
          ItemUnitPrice * SalesLine.Quantity * (SalesLine."EC %" / 100));
        SalesInvoice.Statistics.Invoke();
    end;
#endif
    [Test]
    [HandlerFunctions('SalesStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoicePriceInclVATECSalesStatistics()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesInvoice: TestPage "Sales Invoice";
        ItemNo: Code[20];
        CustomerNo: Code[20];
        ItemUnitPrice: Decimal;
    begin
        // [SCENARIO 363582] Sales Statistics with EC % and Prices Incl. VAT = TRUE
        Initialize();

        // [GIVEN] General Posting Setup with EC % = 4 and VAT % = 18 specified
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] Item with Unit Price = 100
        ItemUnitPrice := LibraryRandom.RandDec(100, 2);
        ItemNo :=
          CreateItemWithUnitPriceProdPostingGroups(
            ItemUnitPrice, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        CustomerNo :=
          CreateCustomerWithPostingGroup(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Sales Invoice with Item Quantity = 1, Unit Price = 100, Prices Including VAT = TRUE
        CreateSalesDocumentWithPriceInclVAT(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          CustomerNo, SalesLine.Type::Item, ItemNo, true, 0);

        // [WHEN] Open Sales Statistics Page
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");

        // [THEN] "Line Amount" = 122, "VAT Amount" = 18, "EC Amount" = 4
        LibraryVariableStorage.Enqueue(
          ItemUnitPrice * SalesLine.Quantity * (1 + (SalesLine."VAT %" + SalesLine."EC %") / 100));
        LibraryVariableStorage.Enqueue(
          ItemUnitPrice * SalesLine.Quantity * (SalesLine."VAT %" / 100));
        LibraryVariableStorage.Enqueue(
          ItemUnitPrice * SalesLine.Quantity * (SalesLine."EC %" / 100));
        SalesInvoice.SalesStatistics.Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoicePriceInclVATWithPrepayment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        LineGLAccount: Record "G/L Account";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        PrepmtGLAccNo: Code[20];
    begin
        // [FEATURE] [Prepayment]
        // [SCENARIO 375571] Sales Document Posting with EC %; Prices Incl. VAT = TRUE and Prepayment
        Initialize();

        // [GIVEN] General Posting Setup with EC % = 4 and VAT % = 18 specified
        PrepmtGLAccNo :=
          LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Get(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        VATPostingSetup.Validate("EC %", LibraryRandom.RandDecInRange(5, 10, 2));
        VATPostingSetup.Modify(true);
        CustomerNo :=
          CreateCustomerWithPostingGroup(
            LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");

        // [GIVEN] Sales Order with Prices Including VAT = TRUE, "Amount Including VAT" = 100, Prepayment = 50%
        CreateSalesDocumentWithPriceInclVAT(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CustomerNo,
          SalesLine.Type::"G/L Account", LineGLAccount."No.",
          true, LibraryRandom.RandIntInRange(20, 50));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 100, 2));
        SalesLine.Modify(true);

        // [GIVEN] Posted Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post Sales Order
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales Account GL Entry Amount = -100
        VerifyGLEntry(DocumentNo, LineGLAccount."No.", -SalesLine.Amount, 0);
        // [THEN] VAT GL Entry Amount = -22 (= -100 * (18 + 4) / 100)
        VerifyGLEntry(
          DocumentNo, VATPostingSetup."Sales VAT Account", -SalesLine.Amount * (SalesLine."VAT %" + SalesLine."EC %") / 100, 0);
        // [THEN] Prepayment GL Entry Amount = 50 (= 100 * 50%)
        VerifyGLEntry(
          DocumentNo, PrepmtGLAccNo, SalesLine.Amount * SalesHeader."Prepayment %" / 100, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcVATAmountVATPct()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [SCENARIO 379514] VAT %  of VAT Amount Line record is copied from sales line in the SalesLine.CalcVATAmountLines function
        Initialize();

        // [GIVEN] VAT Posting Setup with "Reverse Charge VAT" and VAT %
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup,
          VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT",
          LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Sales Quote with VAT Posting Setup
        CreateSalesQuoteWithVATPostingSetup(
          SalesHeader,
          SalesLine,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          VATPostingSetup);

        // [WHEN] Run funciton SalesLine.CalcVATAmountLines
        SalesLine.CalcVATAmountLines(0, SalesHeader, SalesLine, VATAmountLine);

        // [THEN] VATAmountLine.VAT % is copied from sales line
        VATAmountLine.TestField("VAT %", SalesLine."VAT %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcVATAndECWithPmtDiscountAndPriceIncl()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 295191] "EC Amount" is calculated incorrectly by CalcVATAmountLines function when one of the lines has negative quantity
        Initialize();

        // [GIVEN] Created Sales Header with "Prices Including VAT" = TRUE
        LibrarySales.CreateSalesHeader(SalesHeader, SalesLine."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);

        // [GIVEN] Created two SalesLines with prepayment (2,1) positive and negative quantity (1,-1)
        AddSalesLine(SalesLine, SalesHeader, 14, 10, 5, 2, 1);
        AddSalesLine(SalesLine, SalesHeader, 10, 10, 5, 1, -1);

        // [WHEN] Calculate VATAmountLines
        SalesLine.CalcVATAmountLines(0, SalesHeader, SalesLine, VATAmountLine);

        // [THEN] The values "VAT Amount" and "EC Amount" are 1.04 and 0.53 as expected
        VATAmountLine.TestField("VAT Amount", 1.04);
        VATAmountLine.TestField("EC Amount", 0.53);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcVATAndECWithPmtDiscountAndPriceExcl()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 295191] "EC Amount" is calculated incorrectly by CalcVATAmountLines function when one of the lines has negative quantity
        Initialize();

        // [GIVEN] Created Sales Header with "Prices Including VAT" = FALSE
        LibrarySales.CreateSalesHeader(SalesHeader, SalesLine."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Prices Including VAT", false);
        SalesHeader.Modify(true);

        // [GIVEN] Created two SalesLines with prepayment (2.13,1.52) positive and negative quantity (1,-1)
        AddSalesLine(SalesLine, SalesHeader, 14, 8.9, 2.4, 2.13, 1);
        AddSalesLine(SalesLine, SalesHeader, 10, 8.9, 2.4, 1.52, -1);

        // [WHEN] Calculate VATAmountLines
        SalesLine.CalcVATAmountLines(0, SalesHeader, SalesLine, VATAmountLine);

        // [THEN] The values "VAT Amount" and "EC Amount" are 1.06 and 0.29 as expected
        VATAmountLine.TestField("VAT Amount", 1.06);
        VATAmountLine.TestField("EC Amount", 0.29);
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler,ConfirmHandlerNo,MessageHandler')]
    [Scope('OnPrem')]
    procedure ECAmountShouldBeCalculatedCorrectly()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        ItemNo: array[2] of Code[20];
        ItemUnitPrice: Decimal;
        ExpectedECAmount: Decimal;
    begin
        // [SCENARIO 537969] TotalVatMinusECAmount and TotalECAmount columns are incorrectly calculated if you Send to Excel a Posted Sales Invoice including Equivalence Charge in the Spanish version.
        Initialize();

        // [GIVEN] General Posting Setup with EC % = 4 and VAT % = 18 specified
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] Item with Unit Price = 100
        ItemUnitPrice := LibraryRandom.RandDec(100, 2);
        ItemNo[1] :=
          CreateItemWithUnitPriceProdPostingGroups(
            ItemUnitPrice, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        ItemNo[2] :=
          CreateItemWithUnitPriceProdPostingGroups(
            ItemUnitPrice, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        CustomerNo :=
          CreateCustomerWithPostingGroup(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Posted Sales Invoice with Item Quantity = 1, Unit Price = 100, Prices Including VAT = TRUE
        CreateSalesDocumentWithPriceInclVAT(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          CustomerNo, SalesLine.Type::Item, ItemNo[1], true, 0);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo[2], LibraryRandom.RandDec(10, 0));

        // [WHEN] Post Sales Document
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] Run report "Standard Sales - Invoice" for Posted Sales Invoice
        Report.Run(Report::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Verify: TotalECAmount in Report
        ExpectedECAmount := FindSalesInvoiceLine(SalesInvoiceLine, DocumentNo);
        VerifyTotalECAmountInStandardSalesInvoiceReport(ExpectedECAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure VATCountryRegionUpdatedIfCustomerIsChangedInSalesDocumentWhenGLSetupBilltoSellIsSellTo()
    var
        Customer: array[2] of Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        DocumentType: Enum "Sales Document Type";
    begin
        // [SCENARIO 549137] VAT Country/Region Code is updated if Sell-to Customer No. is changed in a Sales document.
        Initialize();

        // [GIVEN] Update "Bill-to/Sell-to VAT Calc." in General Ledger Setup.
        SetBillToSellToVATCalcInGenLedgSetup(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");

        // [GIVEN] Create Two Customers.
        Customer[1].Get(LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo());
        Customer[2].Get(LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo());

        // [GIVEN] Create Sales Invoice.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType::Invoice, Customer[1]."No.");

        // [WHEN] Change Validate "Sell-to Customer No." with another customer.
        SalesHeader.Validate("Sell-to Customer No.", Customer[2]."No.");

        // [THEN] Verify Fields "VAT Country/Region Code","Bill-to Country/Region Code","Sell-to Country/Region Code","Ship-to Country/Region Code"
        VerifyCountryCodes(Customer[2], SalesHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure VATCountryRegionUpdatedIfCustomerIsChangedInSalesDocumentWhenGLSetupBilltoSellIsBillTo()
    var
        Customer: array[2] of Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        DocumentType: Enum "Sales Document Type";
    begin
        // [SCENARIO 549137] VAT Country/Region Code is updated if Sell-to Customer No. is changed in a Sales document.
        Initialize();

        // [GIVEN] Update "Bill-to/Sell-to VAT Calc." in General Ledger Setup.
        SetBillToSellToVATCalcInGenLedgSetup(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");

        // [GIVEN] Create Two Customers.
        Customer[1].Get(LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo());
        Customer[2].Get(LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo());

        // [GIVEN] Create Sales Invoice.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType::Invoice, Customer[1]."No.");

        // [WHEN] Change Validate "Sell-to Customer No." with another customer.
        SalesHeader.Validate("Sell-to Customer No.", Customer[2]."No.");

        // [THEN] Verify Fields "VAT Country/Region Code","Bill-to Country/Region Code","Sell-to Country/Region Code","Ship-to Country/Region Code"
        VerifyCountryCodes(Customer[2], SalesHeader);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure AddSalesLine(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; UnitPrice: Decimal; VATPct: Decimal; ECPct: Decimal; PmtDiscountAmount: Decimal; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("VAT %", VATPct);
        SalesLine.Validate("EC %", ECPct);
        SalesLine.Validate("Pmt. Discount Amount", PmtDiscountAmount);
        SalesLine.Modify(true);
    end;


    local procedure CreateCustomerWithPostingGroup(GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer(''));  // Blank for Currency Code.
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomer(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        exit(Customer."No.");
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Invoice Rounding Precision", LibraryERM.GetInvoiceRoundingPrecisionLCY());
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);

        // Create Currency Exchange Rate.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
        GeneralPostingSetup.Validate("Sales Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("COGS Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10])
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; Amount: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", Amount, CurrencyCode);
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomer(CurrencyCode), Amount, CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGLAccount(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateSalesCreditMemo(var SalesLine: Record "Sales Line"; VATCalculationType: Enum "Tax Calculation Type"; CurrencyCode: Code[10]; Quantity: Decimal; UnitPrice: Decimal)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(VATPostingSetup, VATCalculationType);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomerWithPostingGroup(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          CreateGLAccount(
            GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group",
            VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group"), Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type")
    var
        GLAccount: Record "G/L Account";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDec(10, 2));
        VATPostingSetup.Validate("EC %", LibraryRandom.RandDec(10, 2));
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateAndPostSalesDocumentWithMultipleLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(SalesLine, DocumentType, '');  // Blank - Currency Code.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLine(SalesLine, SalesHeader);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesDocWithPostingSetup(var SalesHeader: Record "Sales Header"): Decimal
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdatePrepmtAccGenPostingSetup(GeneralPostingSetup, VATPostingSetup);

        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order,
          CreateCustomerWithPostingGroup(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          CreateGLAccount(
            GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group",
            VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);

        exit(SalesLine."Amount Including VAT");
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(CurrencyCode));
        CreateSalesLine(SalesLine, SalesHeader);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        Item: Record Item;
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(50, 100));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithPriceInclVAT(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; LineType: Enum "Sales Line Type"; LineNo: Code[20]; PricesInclVAT: Boolean; PrepmtPct: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Prepayment %", PrepmtPct);
        SalesHeader.Validate("Prices Including VAT", PricesInclVAT);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
SalesLine, SalesHeader, LineType, LineNo, LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateSalesQuoteWithVATPostingSetup(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup")
    var
        RefGLAccount: Record "G/L Account";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, RefGLAccount."Gen. Posting Type"::Sale),
          LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify();
    end;

    local procedure CreateItemWithUnitPriceProdPostingGroups(UnitPrice: Decimal; GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, UnitPrice, UnitPrice);
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure GetReceivableAccount(No: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(No);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        exit(CustomerPostingGroup."Receivables Account");
    end;

    local procedure GetPrepaymentInvoicesAmt(CustomerNo: Code[20]) Result: Decimal
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesInvoiceHeader.SetRange("Prepayment Invoice", true);
        SalesInvoiceHeader.FindSet();
        repeat
            Result += GetPrepaymentInvoiceAmt(SalesInvoiceHeader."No.");
        until SalesInvoiceHeader.Next() = 0;
    end;

    local procedure GetPrepaymentInvoiceAmt(DocumentNo: Code[20]) Result: Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindSet();
        repeat
            Result += SalesInvoiceLine."Amount Including VAT";
        until SalesInvoiceLine.Next() = 0;
    end;

    local procedure InvokeSalesCreditMemoStatistics(var SalesCreditMemoStatistics: TestPage "Sales Credit Memo Statistics"; DocumentNo: Code[20])
    var
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        SalesCreditMemoStatistics.Trap();
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.FILTER.SetFilter("No.", DocumentNo);
        PostedSalesCreditMemo.Statistics.Invoke();
        PostedSalesCreditMemo.Close();
    end;

    local procedure InvokeSalesInvoiceStatistics(var SalesInvoiceStatistics: TestPage "Sales Invoice Statistics"; DocumentNo: Code[20])
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        SalesInvoiceStatistics.Trap();
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.FILTER.SetFilter("No.", DocumentNo);
        PostedSalesInvoice.Statistics.Invoke();
        PostedSalesInvoice.Close();
    end;

    local procedure RunSalesPrepmtDocTestReport(SalesHeaderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("No.", SalesHeaderNo);
        Commit();
        REPORT.Run(REPORT::"Sales Prepmt. Document Test", true, false, SalesHeader);
    end;

    local procedure UpdateAdditionalReportingCurrencyOnGeneralLedgerSetup(AdditionalReportingCurrency: Code[10]) OldAdditionalReportingCurrency: Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldAdditionalReportingCurrency := GeneralLedgerSetup."Additional Reporting Currency";
        GeneralLedgerSetup."Additional Reporting Currency" := AdditionalReportingCurrency;  // To Avoid Report Handler - Additional Reporting Currency.
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateInvRoundingSalesReceivablesSetup(InvoiceRounding: Boolean) OldInvoiceRounding: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldInvoiceRounding := SalesReceivablesSetup."Invoice Rounding";
        SalesReceivablesSetup.Validate("Invoice Rounding", InvoiceRounding);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdatePostLineDiscountOnSalesReceivablesSetup(PostLineDiscount: Boolean) OldPostLineDiscount: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldPostLineDiscount := SalesReceivablesSetup."Post Line Discount";
        SalesReceivablesSetup.Validate("Post Line Discount", PostLineDiscount);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateSalesDocPrepaymentPct(var SalesHeader: Record "Sales Header"; NewPrepaymentPct: Decimal)
    begin
        SalesHeader.Validate("Prepayment %", NewPrepaymentPct);
        SalesHeader.Modify();
    end;

    local procedure UpdatePrepmtAccGenPostingSetup(var GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.UpdateGLAccountWithPostingSetup(GLAccount, GLAccount."Gen. Posting Type"::Sale, GeneralPostingSetup, VATPostingSetup);
        GeneralPostingSetup.Validate("Sales Prepayments Account", GLAccount."No.");
        GeneralPostingSetup.Modify();
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal; AdditionalCurrencyAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualMsg);
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, GLEntry."Additional-Currency Amount", LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualMsg);
    end;

    local procedure VerifyGLEntryWithDiscAccount(DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        Assert.IsTrue(GLEntry.IsEmpty, DiscAccountGLEntryCreatedErr);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; Base: Decimal; AdditionalCurrencyBase: Decimal; Amount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(Base, VATEntry.Base, LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualMsg);
        Assert.AreNearlyEqual(
          AdditionalCurrencyBase, VATEntry."Additional-Currency Base", LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualMsg);
        Assert.AreNearlyEqual(Amount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualMsg);
    end;

    local procedure VerifyVATAndGLEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GLAccount: Code[20]; Base: Decimal; AdditionalCurrencyAmount: Decimal; VATPct: Decimal)
    begin
        if DocumentType = DocumentType::"Credit Memo" then
            Base := -Base;
        VerifyVATEntry(DocumentNo, Base, AdditionalCurrencyAmount, Base * VATPct / 100);
        VerifyGLEntry(DocumentNo, GLAccount, Base, AdditionalCurrencyAmount);
    end;

    local procedure VerifySalesPrepmtDocTestReportECAmount(ExpectedECAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetLastRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('VATAmountLine__EC_Amount__Control1100006', ExpectedECAmount)
    end;

    local procedure FindSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; DocumentNo: Code[20]) ECAmount: Decimal
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindSet();
        repeat
            ECAmount += Round(SalesInvoiceLine."VAT Base Amount" * SalesInvoiceLine."EC %" / 100);
        until SalesInvoiceLine.Next() = 0;
    end;

    local procedure VerifyTotalECAmountInStandardSalesInvoiceReport(ExpectedECAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetLastRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalECAmount', ExpectedECAmount)
    end;

    local procedure VerifyCountryCodes(Customer: Record Customer; SalesHeader: Record "Sales Header")
    begin
        Assert.AreEqual(
            Customer."Country/Region Code",
            SalesHeader."VAT Country/Region Code",
            StrSubstNo(CountryCodeLbl, SalesHeader.FieldCaption("VAT Country/Region Code"), Customer."Country/Region Code"));
        Assert.AreEqual(
            Customer."Country/Region Code",
            SalesHeader."Bill-to Country/Region Code",
            StrSubstNo(CountryCodeLbl, SalesHeader.FieldCaption("Bill-to Country/Region Code"), Customer."Country/Region Code"));
        Assert.AreEqual(
            Customer."Country/Region Code",
            SalesHeader."Sell-to Country/Region Code",
            StrSubstNo(CountryCodeLbl, SalesHeader.FieldCaption("Sell-to Country/Region Code"), Customer."Country/Region Code"));
        Assert.AreEqual(
            Customer."Country/Region Code",
            SalesHeader."Ship-to Country/Region Code",
            StrSubstNo(CountryCodeLbl, SalesHeader.FieldCaption("Ship-to Country/Region Code"), Customer."Country/Region Code"));
    end;

    local procedure SetBillToSellToVATCalcInGenLedgSetup(NewBillToSellToVATCalcType: Enum "G/L Setup VAT Calculation")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", NewBillToSellToVATCalcType);
        GeneralLedgerSetup.Modify(true);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsModalPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        LineAmount: Variant;
        VATAmount: Variant;
        ECAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(LineAmount);
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(ECAmount);
        Assert.AreNearlyEqual(
          LineAmount, SalesStatistics.SubForm."Line Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualMsg);
        Assert.AreNearlyEqual(
          VATAmount, SalesStatistics.SubForm."VAT Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualMsg);
        Assert.AreNearlyEqual(
          ECAmount, SalesStatistics.SubForm."EC Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualMsg);
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        LineAmount: Variant;
        VATAmount: Variant;
        ECAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(LineAmount);
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(ECAmount);
        Assert.AreNearlyEqual(
          LineAmount, SalesStatistics.SubForm."Line Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualMsg);
        Assert.AreNearlyEqual(
          VATAmount, SalesStatistics.SubForm."VAT Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualMsg);
        Assert.AreNearlyEqual(
          ECAmount, SalesStatistics.SubForm."EC Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualMsg);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesPrepmtDocTestRPH(var SalesPrepmtDocumentTest: TestRequestPage "Sales Prepmt. Document Test")
    begin
        SalesPrepmtDocumentTest.ShowDimensions.SetValue(true);
        SalesPrepmtDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}