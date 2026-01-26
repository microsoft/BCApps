codeunit 147501 "Cartera Paym. Settlement"
{
    // Cartera scenarios having as setup posted payment orders.
    // The scenarios exercise closing payment orders with opened cartera documents.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryCarteraCommon: Codeunit "Library - Cartera Common";
        LibraryCarteraPayables: Codeunit "Library - Cartera Payables";
        LibraryCarteraReceivables: Codeunit "Library - Cartera Receivables";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LocalCurrencyCode: Code[10];
        IsInitialized: Boolean;
        NotPrintedPaymentOrderQst: Label 'This %1 has not been printed. Do you want to continue?';
        PaymentOrderSuccessfullyPostedMsg: Label 'The %1 %2 was successfully posted.', Comment = '%1=Table,%2=Field';
        BatchSettlementPOMsg: Label '%1 Documents in %2 Payment Orders totaling %3 (LCY) have been settled.';
        PartialSettlementPOMsg: Label '%1 payable documents totaling %2 have been partially settled in Payment Order %3 by an amount of %4.';
        UnexpectedCartDocStatusErr: Label 'Unexpected closed Cartera Document status.';
        InvalidStatusPartiallySettledCarteraDocErr: Label 'Invalid status of partially settled Cartera document.';
        UnexpectedCartDocRemAmountErr: Label 'Unexpected remaining amount for closed Cartera Document.';
        UnexpectedPartSettledCartDocRemAmountErr: Label 'Unexpected remaining amount on partially settled payable Cartera doc.';
        BillGroupNotPrintedMsg: Label 'This %1 has not been printed. Do you want to continue?';
        RejectBillTxt: Label '%1 documents have been rejected.';
        SettlementCompletedSuccessfullyMsg: Label '%1 documents totaling %2 have been settled.';
        RecipientErr: Label '%1 must be %2 in %3.', Comment = '%1=Vendor Bank Account Code in Vendor Ledger Entry,%2=Vendor bank account,%3=Table Caption';

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentOrderTest()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        PostedPaymentOrder: Record "Posted Payment Order";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        Initialize();

        // Setup - Exercise
        PreparePaymentOrder(Vendor, BankAccount, CarteraDoc, PaymentOrder, LocalCurrencyCode);
        PostPaymentOrderLCY(PaymentOrder);

        // Pre-Verify
        LibraryCarteraPayables.FindInvoiceVendorLedgerEntry(
          VendorLedgerEntry, Vendor."No.", CarteraDoc."Document No.", VendorLedgerEntry."Document Situation"::"Posted BG/PO");

        // Verify
        PostedPaymentOrder.SetRange("Bank Account No.", BankAccount."No.");
        PostedPaymentOrder.FindLast();
        VendorLedgerEntry.TestField(Amount, PostedPaymentOrder.Amount);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CarteraDocumnets,ConfirmHandlerCartera,MessageHandlerCartera,SettleDocsInPostedPOModalPageHandler')]
    procedure PassReciptBankAccountIntoVenodrLedgerAsPerSelectedVendorBankAccount()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        VendorBankAccount: array[2] of Record "Vendor Bank Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentOrder: Record "Payment Order";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentMethod: Record "Payment Method";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 506309] he Vendor Bank Account is incorrect in the Payment entry generated from a Payment Order in case it is different than the Preferred Vendor Bank Account on the Vendor Card in the Spanish version.
        Initialize();

        // [GIVEN] Create Vendor with Cartera Payment.
        LibraryCarteraPayables.CreateCarteraVendorUseBillToCarteraPayment(Vendor, '');

        // [GIVEN] Create Cartera Vendor Bank Account for the Vendor.
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, '');

        // [GIVEN] Create two different Vendor Bank Account.
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount[1], Vendor."No.");
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount[2], Vendor."No.");

        // [GIVEN] Add to Prefered Vendor Bank Account to Vendor.
        Vendor.Validate("Preferred Bank Account Code", VendorBankAccount[1].Code);
        Vendor.Modify(true);

        // [GIVEN] Validate Credit bills as false and and Invoice to Cartera to true and bill type to blank.
        PaymentMethod.Get(Vendor."Payment Method Code");
        PaymentMethod.Validate("Create Bills", false);
        PaymentMethod.Validate("Invoices to Cartera", true);
        PaymentMethod.Validate("Bill Type", PaymentMethod."Bill Type"::" ");
        PaymentMethod.Modify(true);

        // [GIVEN] Create Bank Account.
        LibraryCarteraPayables.CreateBankAccount(BankAccount, '');

        // [GIVEN] Create Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] Add VAT Posting Setup of the Vendor.
        CreateVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group", LibraryRandom.RandInt(9));

        // [GIVEN] Validate Venfor Bank Acc Code to different from Preffered Bank Account in Vendor.
        PurchaseHeader.Validate("Vendor Bank Acc. Code", VendorBankAccount[2].Code);
        PurchaseHeader.Modify(true);

        // [GIVEN] Add Purchase Line into Purchase Header.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        // [GIVEN] Post Purchase Order and store Invoice No. 
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create Cartera Payment Order.
        LibraryCarteraPayables.CreateCarteraPaymentOrder(BankAccount, PaymentOrder, '');

        // [GIVEN] Add the document into Payment Order.
        AddCarteraDocumentToPaymentOrder(PaymentOrder."No.", DocumentNo);
        PaymentOrder.Validate("Export Electronic Payment", false);
        PaymentOrder.Modify(true);

        // [GIVEN] Post Cartera Payment Order.
        LibraryCarteraPayables.PostCarteraPaymentOrder(PaymentOrder);

        // [GIVEN] Invoke Settlement and Settle
        InvokeTotalSettlementOnPaymentOrder(PaymentOrder."No.");

        // [THEN] Check if Vendor ledger entry Recipient Bank Account matches to the changed one.
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.SetRange("Document No.", PaymentOrder."No.");
        VendorLedgerEntry.FindLast();
        Assert.AreEqual(
            VendorLedgerEntry."Recipient Bank Account",
            VendorBankAccount[2].Code,
            StrSubstNo(
                RecipientErr,
                VendorLedgerEntry."Recipient Bank Account",
                VendorBankAccount[2].Code,
                VendorLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,PartialSettlPayableRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPOPartialSettlementLCY()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        PostedPaymentOrdersTestPage: TestPage "Posted Payment Orders";
        InitialAmount: Decimal;
        SettledAmount: Decimal;
    begin
        Initialize();

        // Setup
        PreparePaymentOrder(Vendor, BankAccount, CarteraDoc, PaymentOrder, LocalCurrencyCode);
        PostPaymentOrderLCY(PaymentOrder);

        // Exercise - Invoke partial settlement
        InvokePartialSettlementOnPaymentOrder(PostedPaymentOrdersTestPage, PaymentOrder."No.", CarteraDoc, SettledAmount, InitialAmount, 0);

        // Verify
        VerifyPartialSettlementOnPaymentOrder(CarteraDoc, InitialAmount, SettledAmount, PaymentOrder);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,ConfirmHandlerYes,MessageHandler,PartialSettlPayableRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPOPartialSettlementNonLCY()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        PostedPaymentOrdersTestPage: TestPage "Posted Payment Orders";
        CurrencyCode: Code[10];
        InitialAmount: Decimal;
        SettledAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        CurrencyCode := LibraryCarteraCommon.CreateCarteraCurrency(false, false, true);

        // Setup
        PreparePaymentOrder(Vendor, BankAccount, CarteraDoc, PaymentOrder, CurrencyCode);
        PostPaymentOrderNonLCY(PaymentOrder."No.");

        // Exercise - Invoke partial settlement
        InvokePartialSettlementOnPaymentOrder(PostedPaymentOrdersTestPage, PaymentOrder."No.", CarteraDoc, SettledAmount, InitialAmount, 0);

        // Verify
        VerifyPartialSettlementOnPaymentOrder(CarteraDoc, InitialAmount, SettledAmount, PaymentOrder);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,BatchSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPOBatchSettlementLCY()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        PostedPaymentOrder: Record "Posted Payment Order";
        PostedPaymentOrdersTestPage: TestPage "Posted Payment Orders Select.";
    begin
        Initialize();

        // Pre-Setup
        PreparePaymentOrder(Vendor, BankAccount, CarteraDoc, PaymentOrder, LocalCurrencyCode);
        PostPaymentOrderLCY(PaymentOrder);

        // Setup - Open Posted Payment Orders page, from Cartera - Periodic Activities section and invoke 'Batch Settlement' action
        PostedPaymentOrdersTestPage.OpenView();

        PostedPaymentOrder.Get(PaymentOrder."No.");
        PostedPaymentOrdersTestPage.GotoRecord(PostedPaymentOrder);

        LibraryVariableStorage.Enqueue(StrSubstNo(BatchSettlementPOMsg, 1, 1, CarteraDoc."Remaining Amt. (LCY)"));

        // Exercise - Verify
        PostedPaymentOrdersTestPage.BatchSettlement.Invoke();
        VerifyCarteraDocIsClosedAsHonored(CarteraDoc);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,ConfirmHandlerYes,MessageHandler,BatchSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPOBatchSettlementNonLCY()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        PostedPaymentOrder: Record "Posted Payment Order";
        PostedPaymentOrdersTestPage: TestPage "Posted Payment Orders Select.";
        CurrencyCode: Code[10];
    begin
        Initialize();

        // Pre-Setup
        CurrencyCode := LibraryCarteraCommon.CreateCarteraCurrency(false, false, true);
        PreparePaymentOrder(Vendor, BankAccount, CarteraDoc, PaymentOrder, CurrencyCode);
        PostPaymentOrderNonLCY(PaymentOrder."No.");

        // Setup - Open Posted Payment Orders page, from Cartera - Periodic Activities section and invoke 'Batch Settlement' action
        PostedPaymentOrdersTestPage.OpenView();
        PostedPaymentOrder.Get(PaymentOrder."No.");
        PostedPaymentOrdersTestPage.GotoRecord(PostedPaymentOrder);

        LibraryVariableStorage.Enqueue(StrSubstNo(BatchSettlementPOMsg, 1, 1, CarteraDoc."Remaining Amt. (LCY)"));

        // Exercise - Verify
        PostedPaymentOrdersTestPage.BatchSettlement.Invoke();
        VerifyCarteraDocIsClosedAsHonored(CarteraDoc);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,PartialSettlPayableRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPOPartialSettlementWithUnrealizedVAT()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        PostedPaymentOrdersTestPage: TestPage "Posted Payment Orders";
        InitialAmount: Decimal;
        SettledAmount: Decimal;
        ExpectedVATAmount: Decimal;
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        PostPaymentOrderWithUnrealizedVAT(
          Vendor, BankAccount, CarteraDoc, PaymentOrder, InitialAmount, ExpectedVATAmount, DocumentNo, LocalCurrencyCode);
        LibraryCarteraPayables.ValidatePostedInvoiceUnrVATGLEntries(DocumentNo, PurchUnrVATAccount, InitialAmount);

        // Exercise - Invoke partial settlement
        InvokePartialSettlementOnPaymentOrder(PostedPaymentOrdersTestPage, PaymentOrder."No.", CarteraDoc, SettledAmount, InitialAmount, 0);
        ExpectedVATAmount := Round(ExpectedVATAmount * SettledAmount / InitialAmount, LibraryERM.GetAmountRoundingPrecision());

        // Verify
        VerifyPartialSettlementOnPaymentOrder(CarteraDoc, InitialAmount, SettledAmount, PaymentOrder);

        LibraryCarteraPayables.ValidatePaymentUnrVATGLEntries(
          CarteraDoc."Bill Gr./Pmt. Order No.", PurchUnrVATAccount, InitialAmount, ExpectedVATAmount, SettledAmount);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,BatchSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPOBatchSettlementWithUnrealizedVAT()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        PostedPaymentOrder: Record "Posted Payment Order";
        PostedPaymentOrdersTestPage: TestPage "Posted Payment Orders Select.";
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
        TotalAmount: Decimal;
        ExpectedVATAmount: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        PostPaymentOrderWithUnrealizedVAT(
          Vendor, BankAccount, CarteraDoc, PaymentOrder, TotalAmount, ExpectedVATAmount, DocumentNo, LocalCurrencyCode);

        LibraryCarteraPayables.ValidatePostedInvoiceUnrVATGLEntries(DocumentNo, PurchUnrVATAccount, TotalAmount);

        // Setup - Open Posted Payment Orders page, from Cartera - Periodic Activities section and invoke 'Batch Settlement' action
        PostedPaymentOrdersTestPage.OpenView();
        PostedPaymentOrder.Get(PaymentOrder."No.");
        PostedPaymentOrdersTestPage.GotoRecord(PostedPaymentOrder);

        LibraryVariableStorage.Enqueue(StrSubstNo(BatchSettlementPOMsg, 1, 1, CarteraDoc."Remaining Amt. (LCY)"));

        // Exercise - Verify
        PostedPaymentOrdersTestPage.BatchSettlement.Invoke();

        VerifyCarteraDocIsClosedAsHonored(CarteraDoc);

        LibraryCarteraPayables.ValidatePaymentUnrVATGLEntries(
          CarteraDoc."Bill Gr./Pmt. Order No.", PurchUnrVATAccount, TotalAmount, ExpectedVATAmount, TotalAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,PartialSettlPayableRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PartialSettlementOfPrepaymentOrderWithAdjustForPaymentDisc()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        PostedPaymentOrdersTestPage: TestPage "Posted Payment Orders";
        InitialAmount: Decimal;
        SettledAmount: Decimal;
        DiscountAmount: Decimal;
        InvoiceAmount: Decimal;
        RemainingAmount: Decimal;
    begin
        Initialize();

        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();

        // Setup
        PreparePaymentOrderWithPaymentTermsDiscountLCY(Vendor, BankAccount, CarteraDoc, PaymentOrder, DiscountAmount, InitialAmount);
        PostPaymentOrderLCY(PaymentOrder);

        // Exercise - Invoke partial settlement
        InvokePartialSettlementOnPaymentOrder(
          PostedPaymentOrdersTestPage, PaymentOrder."No.", CarteraDoc, SettledAmount, InitialAmount, DiscountAmount);
        InvoiceAmount := InitialAmount - DiscountAmount;
        RemainingAmount := InvoiceAmount - SettledAmount;

        // Verify
        VerifyPartialSettlementOnPaymentOrder(CarteraDoc, InitialAmount, SettledAmount, PaymentOrder);

        // Excercise - Settle Remaining part
        LibraryVariableStorage.Enqueue(RemainingAmount);
        LibraryVariableStorage.Enqueue(StrSubstNo(PartialSettlementPOMsg, 1, RemainingAmount, PaymentOrder."No.", RemainingAmount));
        PostedPaymentOrdersTestPage.Docs.PartialSettlement.Invoke();

        VerifyGLEntriesForPartialSettlementsWithDiscount(
          PaymentOrder."No.", DiscountAmount, InitialAmount, SettledAmount, false, 0);
        VerifyCarteraDocIsClosedAsHonored(CarteraDoc);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,PartialSettlPayableRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PartialSettlementOfPrepaymentOrderWithAdjustForPaymentDiscWithUnrealizedVAT()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        PostedPaymentOrdersTestPage: TestPage "Posted Payment Orders";
        InitialAmount: Decimal;
        SettledAmount: Decimal;
        DiscountAmount: Decimal;
        InvoiceAmount: Decimal;
        RemainingAmount: Decimal;
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
        ExpectedVATAmount: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();

        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();

        // Setup
        PostPaymentOrderWithUnrealizedVATAndDiscountLCY(
          Vendor, BankAccount, CarteraDoc, PaymentOrder, InitialAmount, ExpectedVATAmount, DocumentNo, DiscountAmount);

        // Exercise - Invoke partial settlement
        InvokePartialSettlementOnPaymentOrder(
          PostedPaymentOrdersTestPage, PaymentOrder."No.", CarteraDoc, SettledAmount, InitialAmount, DiscountAmount);
        InvoiceAmount := InitialAmount - DiscountAmount;
        RemainingAmount := InvoiceAmount - SettledAmount;

        // Verify
        VerifyPartialSettlementOnPaymentOrder(CarteraDoc, InitialAmount, SettledAmount, PaymentOrder);

        // Excercise - Settle Remaining part
        LibraryVariableStorage.Enqueue(RemainingAmount);
        LibraryVariableStorage.Enqueue(StrSubstNo(PartialSettlementPOMsg, 1, RemainingAmount, PaymentOrder."No.", RemainingAmount));

        PostedPaymentOrdersTestPage.Docs.PartialSettlement.Invoke();

        VerifyGLEntriesForPartialSettlementsWithDiscount(
          PaymentOrder."No.", DiscountAmount, InitialAmount, SettledAmount, true, ExpectedVATAmount);
        VerifyCarteraDocIsClosedAsHonored(CarteraDoc);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SettleDocsInPostedPOModalPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementOfOrderWithAdjustForPaymentDiscount()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        TotalAmount: Decimal;
        DiscountAmount: Decimal;
    begin
        Initialize();

        // Setup
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        PreparePaymentOrderWithPaymentTermsDiscountLCY(Vendor, BankAccount, CarteraDoc, PaymentOrder, DiscountAmount, TotalAmount);
        PostPaymentOrderLCY(PaymentOrder);

        InvokeTotalSettlementOnPaymentOrder(PaymentOrder."No.");

        // Verify
        LibraryCarteraPayables.CheckIfCarteraDocIsClosed(PaymentOrder."No.");
        VerifyGLEntriesForTotalSettlementWithDiscount(PaymentOrder."No.", DiscountAmount, TotalAmount, false, 0);
        VerifyCarteraDocIsClosedAsHonored(CarteraDoc);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SettleDocsInPostedPOModalPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementOfOrderWithAdjustForPaymentDiscountAndUnrealizedVAT()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
        TotalAmount: Decimal;
        DiscountAmount: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        Initialize();

        // Setup
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);

        PostPaymentOrderWithUnrealizedVATAndDiscountLCY(
          Vendor, BankAccount, CarteraDoc, PaymentOrder, TotalAmount, ExpectedVATAmount, DocumentNo, DiscountAmount);

        InvokeTotalSettlementOnPaymentOrder(PaymentOrder."No.");

        // Verify
        LibraryCarteraPayables.CheckIfCarteraDocIsClosed(PaymentOrder."No.");
        VerifyGLEntriesForTotalSettlementWithDiscount(PaymentOrder."No.", DiscountAmount, TotalAmount, true, ExpectedVATAmount);
        VerifyCarteraDocIsClosedAsHonored(CarteraDoc);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,SettleDocsinPostedPORequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementBillGroupWithUnrealizedVATPositiveNegativeLinesInDocument()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CarteraDoc: Record "Cartera Doc.";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PaymentOrder: Record "Payment Order";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 416820] Stan can settle Payment Order for Invoice containing NO VAT self balancing zero VAT Entries within Cash Regime and Unrealized VAT
        Initialize();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Cash Regime", true);
        GeneralLedgerSetup.Modify(true);

        LibraryCarteraPayables.CreateCarteraVendorUseBillToCarteraPayment(Vendor, '');
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, '');
        LibraryCarteraPayables.CreateBankAccount(BankAccount, '');

        LibraryCarteraPayables.SetPaymentTermsVatDistribution(
          Vendor."Payment Terms Code", PaymentTerms."VAT distribution"::Proportional);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        CreateVATPostingSetupVATCashRegime(VATPostingSetup, Vendor."VAT Bus. Posting Group", 0);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type, PurchaseLine."No.", -1);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        CreateVATPostingSetupVATCashRegime(VATPostingSetup, Vendor."VAT Bus. Posting Group", 21);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", 1000);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        PurchaseHeader.TestField("Special Scheme Code", PurchaseHeader."Special Scheme Code"::"01 General");

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        CreatePaymentOrder(BankAccount, PaymentOrder, CarteraDoc, DocumentNo, Vendor, '');

        PostPaymentOrderLCY(PaymentOrder);

        InvokeTotalSettlementOnPaymentOrder(PaymentOrder."No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,SettleDocsinPostedPORequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementBillGroupWithUnrealizedVATRealizesAllVATEntries()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CarteraDoc: Record "Cartera Doc.";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PaymentOrder: Record "Payment Order";
        VATEntry: Record "VAT Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 427600] System settles all VAT entries associated with a Cartera document.
        Initialize();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Cash Regime", true);
        GeneralLedgerSetup.Modify(true);

        LibraryERM.SetUnrealizedVAT(true);

        LibraryCarteraPayables.CreateCarteraVendorUseBillToCarteraPayment(Vendor, '');
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, '');
        LibraryCarteraPayables.CreateBankAccount(BankAccount, '');

        LibraryCarteraPayables.SetPaymentTermsVatDistribution(
            Vendor."Payment Terms Code", PaymentTerms."VAT distribution"::Proportional);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        CreateVATPostingSetupVATCashRegime(VATPostingSetup, Vendor."VAT Bus. Posting Group", 10);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        CreateVATPostingSetupVATCashRegime(VATPostingSetup, Vendor."VAT Bus. Posting Group", 21);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", 1000);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        PurchaseHeader.TestField("Special Scheme Code", PurchaseHeader."Special Scheme Code"::"01 General");

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetFilter("Unrealized Base", '>0');
        Assert.RecordCount(VATEntry, 2);

        CreatePaymentOrder(BankAccount, PaymentOrder, CarteraDoc, DocumentNo, Vendor, '');

        PostPaymentOrderLCY(PaymentOrder);

        InvokeTotalSettlementOnPaymentOrder(PaymentOrder."No.");

        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.FindLast();
        VendorLedgerEntry.TestField(Open, false);

        VATEntry.Reset();
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.SetRange("Document No.", VendorLedgerEntry."Document No.");
        Assert.RecordCount(VATEntry, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,SettleDocsinPostedPORequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementBillGroupWithFixedAssetWithUnrealizedVATRealizesAllVATEntries()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FixedAsset: Record "Fixed Asset";
        VATPostingSetup: Record "VAT Posting Setup";
        CarteraDoc: Record "Cartera Doc.";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PaymentOrder: Record "Payment Order";
        VATEntry: Record "VAT Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Fixed Asset]
        // [SCENARIO 425781] Stan can totally settle payment order applied to purchase invoice with Fixed Asset and Item lines. Settlement realizes VAT Entries posted from purchase invoice.
        Initialize();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Cash Regime", true);
        GeneralLedgerSetup.Modify(true);

        LibraryERM.SetUnrealizedVAT(true);

        LibraryCarteraPayables.CreateCarteraVendorUseBillToCarteraPayment(Vendor, '');
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, '');
        LibraryCarteraPayables.CreateBankAccount(BankAccount, '');

        LibraryCarteraPayables.SetPaymentTermsVatDistribution(
            Vendor."Payment Terms Code", PaymentTerms."VAT distribution"::Proportional);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        CreateVATPostingSetupVATCashRegime(VATPostingSetup, Vendor."VAT Bus. Posting Group", 10);

        CreateFixedAssetWithGroup(FixedAsset, VATPostingSetup);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FixedAsset."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        CreateVATPostingSetupVATCashRegime(VATPostingSetup, Vendor."VAT Bus. Posting Group", 21);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", 1000);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        PurchaseHeader.TestField("Special Scheme Code", PurchaseHeader."Special Scheme Code"::"01 General");

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetFilter("Unrealized Base", '>0');
        Assert.RecordCount(VATEntry, 2);

        CreatePaymentOrder(BankAccount, PaymentOrder, CarteraDoc, DocumentNo, Vendor, '');

        PostPaymentOrderLCY(PaymentOrder);

        InvokeTotalSettlementOnPaymentOrder(PaymentOrder."No.");

        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.FindLast();
        VendorLedgerEntry.TestField(Open, false);

        VATEntry.Reset();
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.SetRange("Document No.", VendorLedgerEntry."Document No.");
        Assert.RecordCount(VATEntry, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,SettleDocsinPostedPORequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementBillGroupWithSingleFixedAssetWithUnrealizedVATRealizesAllVATEntries()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FixedAsset: Record "Fixed Asset";
        VATPostingSetup: Record "VAT Posting Setup";
        CarteraDoc: Record "Cartera Doc.";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PaymentOrder: Record "Payment Order";
        VATEntry: Record "VAT Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Fixed Asset]
        // [SCENARIO 425781] Stan can totally settle payment order applied to purchase invoice with the single Fixed Asset line. Settlement realizes VAT Entry posted from purchase invoice.
        Initialize();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Cash Regime", true);
        GeneralLedgerSetup.Modify(true);

        LibraryERM.SetUnrealizedVAT(true);

        LibraryCarteraPayables.CreateCarteraVendorUseBillToCarteraPayment(Vendor, '');
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, '');
        LibraryCarteraPayables.CreateBankAccount(BankAccount, '');

        LibraryCarteraPayables.SetPaymentTermsVatDistribution(
            Vendor."Payment Terms Code", PaymentTerms."VAT distribution"::Proportional);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        CreateVATPostingSetupVATCashRegime(VATPostingSetup, Vendor."VAT Bus. Posting Group", 10);

        CreateFixedAssetWithGroup(FixedAsset, VATPostingSetup);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FixedAsset."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        PurchaseHeader.TestField("Special Scheme Code", PurchaseHeader."Special Scheme Code"::"01 General");

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetFilter("Unrealized Base", '>0');
        Assert.RecordCount(VATEntry, 1);

        CreatePaymentOrder(BankAccount, PaymentOrder, CarteraDoc, DocumentNo, Vendor, '');

        PostPaymentOrderLCY(PaymentOrder);

        InvokeTotalSettlementOnPaymentOrder(PaymentOrder."No.");

        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.FindLast();
        VendorLedgerEntry.TestField(Open, false);

        VATEntry.Reset();
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.SetRange("Document No.", VendorLedgerEntry."Document No.");
        Assert.RecordCount(VATEntry, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,RejectDocsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithRejectedBillAndTwoPurchaseInvoicesWithUnrealizedVATAppliedToPayments()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        BillGroup: Record "Bill Group";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[4] of Record "Gen. Journal Line";
        CarteraDoc: Record "Cartera Doc.";
        VATEntry: Record "VAT Entry";
        BGPOPostAndPrint: Codeunit "BG/PO-Post and Print";
        TotalAmount: Decimal;
        PostedSalesInvoiceWithBillNo: Code[20];
        PostedPurchaseInvoiceNo: array[2] of Code[20];
    begin
        // [SCENARIO 427600] System settles all VAT entries associated with a Cartera document.
        Initialize();

        // [GIVEN] Posted Sales Invoice[1] => Posted Bill => Rejected.
        UpdateVATCashRegimeOnGLSetup(false);
        LibraryERM.SetUnrealizedVAT(false);

        PrePostBillGroupSetup(BankAccount, Customer);

        CreateVATPostingSetup(VATPostingSetup, Customer."VAT Bus. Posting Group", 21);

        PaymentMethod.Get(Customer."Payment Method Code");
        LibraryCarteraReceivables.UpdatePaymentMethodForBillsWithUnrealizedVAT(PaymentMethod);

        LibraryCarteraReceivables.SetPaymentTermsVatDistribution(
          Customer."Payment Terms Code", PaymentTerms."VAT distribution"::Proportional);

        PostedSalesInvoiceWithBillNo := CreateAndPostSalesInvoiceWithItem(Customer, VATPostingSetup, 1, 1000);

        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, PostedSalesInvoiceWithBillNo, Customer."No.", BillGroup."No.");

        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption));
        BGPOPostAndPrint.ReceivablePostOnly(BillGroup);

        LibraryVariableStorage.Enqueue(StrSubstNo(RejectBillTxt, 1)); // Reject bill
        InvokeRejectOnBillGroup(Customer."No.", PostedSalesInvoiceWithBillNo, BillGroup."No.", TotalAmount);

        // [GIVEN] Two Purchase Invoices with Unrealized VAT (without Bills)
        UpdateVATCashRegimeOnGLSetup(true);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, '');
        LibraryCarteraPayables.CreateBankAccount(BankAccount, '');

        CreateVATPostingSetupVATCashRegime(VATPostingSetup, Vendor."VAT Bus. Posting Group", 21);
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Last);
        VATPostingSetup.Modify(true);

        LibraryCarteraPayables.SetPaymentTermsVatDistribution(
            Vendor."Payment Terms Code", PaymentTerms."VAT distribution"::Proportional);

        PostedPurchaseInvoiceNo[1] := CreateAndPostPurchaseInvoiceWithItem(Vendor, VATPostingSetup, 1, 1000);
        PostedPurchaseInvoiceNo[2] := CreateAndPostPurchaseInvoiceWithItem(Vendor, VATPostingSetup, 1, 1000);

        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetFilter("Document No.", '%1|%2', PostedPurchaseInvoiceNo[1], PostedPurchaseInvoiceNo[2]);
        VATEntry.SetFilter("Remaining Unrealized Base", '>0');
        Assert.RecordCount(VATEntry, ArrayLen(PostedPurchaseInvoiceNo));

        // [GIVEN] General Journal with 3 payment lines:
        // [GIVEN] Purchase Payment[1] applied to Purchase Invoice[1]
        // [GIVEN] Sales Payment[1] applied to Bill[1] (that rejected and 'closed')
        // [GIVEN] Purchase Payment[2] applied to Purchase Invoice[2]
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalBatch.Modify(true);

        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[1], GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine[1]."Document Type"::Payment, GenJournalLine[1]."Account Type"::Vendor, Vendor."No.", 0);
        GenJournalLine[1].Validate("External Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine[1].Validate("Applies-to Doc. Type", GenJournalLine[1]."Applies-to Doc. Type"::Invoice);
        GenJournalLine[1].Validate("Applies-to Doc. No.", PostedPurchaseInvoiceNo[1]);
        GenJournalLine[1].Validate("Debit Amount", 1210);
        GenJournalLine[1].Modify(true);

        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[2], GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine[2]."Document Type"::Payment, GenJournalLine[2]."Account Type"::Customer, Customer."No.", 0);
        GenJournalLine[2].Validate("Applies-to Doc. Type", GenJournalLine[2]."Applies-to Doc. Type"::Bill);
        GenJournalLine[2].Validate("Applies-to Doc. No.", PostedSalesInvoiceWithBillNo);
        GenJournalLine[2].Validate("Applies-to Bill No.", '1');
        GenJournalLine[2].Validate("Credit Amount", 1210);
        GenJournalLine[2].Modify(true);

        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[3], GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine[3]."Document Type"::Payment, GenJournalLine[3]."Account Type"::Vendor, Vendor."No.", 0);
        GenJournalLine[3].Validate("External Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine[3].Validate("Applies-to Doc. Type", GenJournalLine[3]."Applies-to Doc. Type"::Invoice);
        GenJournalLine[3].Validate("Applies-to Doc. No.", PostedPurchaseInvoiceNo[2]);
        GenJournalLine[3].Validate("Debit Amount", 1210);
        GenJournalLine[3].Modify(true);

        GenJournalLine[1].SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalLine[1].SetRange("Journal Batch Name", GenJournalBatch.Name);

        LibraryERM.PostGeneralJnlLine(GenJournalLine[1]);

        // [THEN] Unrealized VAT realized. 
        // [THEN] Invoices' Unrealized Amount reset
        Assert.RecordIsEmpty(VATEntry);

        // [THEN] VAT posted within payment
        VATEntry.Reset();
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Assert.RecordCount(VATEntry, ArrayLen(PostedPurchaseInvoiceNo));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,RejectDocsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithRejectedBillAndTwoSalesInvoicesWithUnrealizedVATAppliedToPayments()
    var
        BankAccount: Record "Bank Account";
        CustomerBankAccount: Record "Customer Bank Account";
        Customer: array[2] of Record Customer;
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        BillGroup: Record "Bill Group";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[4] of Record "Gen. Journal Line";
        CarteraDoc: Record "Cartera Doc.";
        VATEntry: Record "VAT Entry";
        BGPOPostAndPrint: Codeunit "BG/PO-Post and Print";
        TotalAmount: Decimal;
        PostedSalesInvoiceWithBillNo: Code[20];
        PostedSalesInvoiceNo: array[2] of Code[20];
    begin
        // [SCENARIO 427600] xxxxxx
        Initialize();

        // [GIVEN] Posted Sales Invoice[1] => Posted Bill => Rejected.
        UpdateVATCashRegimeOnGLSetup(false);
        LibraryERM.SetUnrealizedVAT(false);

        PrePostBillGroupSetup(BankAccount, Customer[1]);

        CreateVATPostingSetup(VATPostingSetup, Customer[1]."VAT Bus. Posting Group", 21);

        PaymentMethod.Get(Customer[1]."Payment Method Code");
        LibraryCarteraReceivables.UpdatePaymentMethodForBillsWithUnrealizedVAT(PaymentMethod);

        LibraryCarteraReceivables.SetPaymentTermsVatDistribution(
          Customer[1]."Payment Terms Code", PaymentTerms."VAT distribution"::Proportional);

        PostedSalesInvoiceWithBillNo := CreateAndPostSalesInvoiceWithItem(Customer[1], VATPostingSetup, 1, 1000);

        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, PostedSalesInvoiceWithBillNo, Customer[1]."No.", BillGroup."No.");

        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption));
        BGPOPostAndPrint.ReceivablePostOnly(BillGroup);

        LibraryVariableStorage.Enqueue(StrSubstNo(RejectBillTxt, 1)); // reject Bill
        InvokeRejectOnBillGroup(Customer[1]."No.", PostedSalesInvoiceWithBillNo, BillGroup."No.", TotalAmount);

        // [GIVEN] Two Sales Invoices with Unrealized VAT (without Bills)

        UpdateVATCashRegimeOnGLSetup(true);

        LibrarySales.CreateCustomer(Customer[2]);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer[2], CustomerBankAccount);
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, '');

        CreateVATPostingSetupVATCashRegime(VATPostingSetup, Customer[2]."VAT Bus. Posting Group", 21);
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Last);
        VATPostingSetup.Modify(true);

        PostedSalesInvoiceNo[1] := CreateAndPostSalesInvoiceWithItem(Customer[2], VATPostingSetup, 1, 1000);
        PostedSalesInvoiceNo[2] := CreateAndPostSalesInvoiceWithItem(Customer[2], VATPostingSetup, 1, 1000);

        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetFilter("Document No.", '%1|%2', PostedSalesInvoiceNo[1], PostedSalesInvoiceNo[2]);
        VATEntry.SetFilter("Remaining Unrealized Base", '<0');
        Assert.RecordCount(VATEntry, ArrayLen(PostedSalesInvoiceNo));

        // [GIVEN] General Journal with 3 payment lines:
        // [GIVEN] Sales Payment[1] applied to Sales Invoice[1]
        // [GIVEN] Sales Payment[2] applied to Bill[1] (that rejected and 'closed')
        // [GIVEN] Sales Payment[3] applied to Sales Invoice[2]
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalBatch.Modify(true);

        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[1], GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine[1]."Document Type"::Payment, GenJournalLine[1]."Account Type"::Customer, Customer[2]."No.", 0);
        GenJournalLine[1].Validate("External Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine[1].Validate("Applies-to Doc. Type", GenJournalLine[1]."Applies-to Doc. Type"::Invoice);
        GenJournalLine[1].Validate("Applies-to Doc. No.", PostedSalesInvoiceNo[1]);
        GenJournalLine[1].Validate("Credit Amount", 1210);
        GenJournalLine[1].Modify(true);

        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[2], GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine[2]."Document Type"::Payment, GenJournalLine[2]."Account Type"::Customer, Customer[1]."No.", 0);
        GenJournalLine[2].Validate("Applies-to Doc. Type", GenJournalLine[2]."Applies-to Doc. Type"::Bill);
        GenJournalLine[2].Validate("Applies-to Doc. No.", PostedSalesInvoiceWithBillNo);
        GenJournalLine[2].Validate("Applies-to Bill No.", '1');
        GenJournalLine[2].Validate("Credit Amount", 1210);
        GenJournalLine[2].Modify(true);

        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[3], GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine[3]."Document Type"::Payment, GenJournalLine[3]."Account Type"::Customer, Customer[2]."No.", 0);
        GenJournalLine[3].Validate("External Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine[3].Validate("Applies-to Doc. Type", GenJournalLine[3]."Applies-to Doc. Type"::Invoice);
        GenJournalLine[3].Validate("Applies-to Doc. No.", PostedSalesInvoiceNo[2]);
        GenJournalLine[3].Validate("Credit Amount", 1210);
        GenJournalLine[3].Modify(true);

        GenJournalLine[1].SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalLine[1].SetRange("Journal Batch Name", GenJournalBatch.Name);

        LibraryERM.PostGeneralJnlLine(GenJournalLine[1]);

        // [THEN] Unrealized VAT realized. 
        // [THEN] Invoices' Unrealized Amount reset
        Assert.RecordIsEmpty(VATEntry);

        // [THEN] VAT posted within payment
        VATEntry.Reset();
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Assert.RecordCount(VATEntry, ArrayLen(PostedSalesInvoiceNo));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CreatePaymentModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePaymentsForPostedVendorBills()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        PaymentJournal: TestPage "Payment Journal";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Create Payment]
        // [SCENARIO 429148] System creates Payment journal line for the posted Vendor's Bill when user invokes "Create Payment" action on Vendor Ledger Entries page
        Initialize();

        UpdateVATCashRegimeOnGLSetup(true);

        LibraryERM.SetUnrealizedVAT(true);

        LibraryCarteraPayables.CreateCarteraVendorUseBillToCarteraPayment(Vendor, '');
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, '');
        LibraryCarteraPayables.CreateBankAccount(BankAccount, '');

        LibraryCarteraPayables.SetPaymentTermsVatDistribution(
          Vendor."Payment Terms Code", PaymentTerms."VAT distribution"::Proportional);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        CreateVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group", 10);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        PurchaseHeader.TestField("Special Scheme Code", PurchaseHeader."Special Scheme Code"::"01 General");

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Bill, DocumentNo);

        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());

        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.FILTER.SetFilter("Entry No.", Format(VendorLedgerEntry."Entry No."));
        VendorLedgerEntries.First();
        PaymentJournal.Trap();

        VendorLedgerEntries."Create Payment".Invoke();
        PaymentJournal.OK().Invoke();

        VendorLedgerEntries.Close();

        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Account No.", Vendor."No.");
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Payment);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,BatchSettlementRequestPageHandler')]
    procedure DimesionSetIdMustBeSameWhilePaymentOrderBatchSettlement()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        PostedPaymentOrder: Record "Posted Payment Order";
        PostedPaymentOrdersTestPage: TestPage "Posted Payment Orders Select.";
    begin
        // [SCENIRIO 523854] Issue when selecting Dimension Value Code for Dim Code XX for Bank Acc. XX..." error if you try to Batch Settlement a Payment Order posted with Code Mandatory/Same Code Dim.
        Initialize();

        // [GIVEN] Payment Order is created with Vendor, Bank Account and Currency.
        PreparePaymentOrderWithDimension(Vendor, BankAccount, CarteraDoc, PaymentOrder, LocalCurrencyCode);

        // [GIVEN] The Payment Order is then Posted.
        PostPaymentOrderLCY(PaymentOrder);

        // [GIVEN] Open Posted Payment Orders page from Cartera - Periodic Activities section.
        PostedPaymentOrdersTestPage.OpenView();
        PostedPaymentOrder.Get(PaymentOrder."No.");
        PostedPaymentOrdersTestPage.GotoRecord(PostedPaymentOrder);

        // [GIVEN] Batch Settlement Message is Enqueued.
        LibraryVariableStorage.Enqueue(StrSubstNo(BatchSettlementPOMsg, 1, 1, CarteraDoc."Remaining Amt. (LCY)"));

        // [GIVEN] Batch Settlement action is invoked.
        PostedPaymentOrdersTestPage.BatchSettlement.Invoke();

        // [THEN] Verify the Cartera Document is posted.
        VerifyCarteraDocIsClosedAsHonored(CarteraDoc);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerCartera,MessageHandlerCartera,OpenBankCatPostPayBillsMatrix,OpenPostedBills')]
    procedure PostBillPayablePaymentMatrixFiltersBankAccountNo()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        POPostAndPrint: Codeunit "BG/PO-Post and Print";
        BankAccountCard: TestPage "Bank Account Card";
        BankCatPostedPayableBills: TestPage "Bank Cat. Posted Payable Bills";
        AnalysisPeriodType: Enum "Analysis Period Type";
    begin
        // [SCENARIO 554713] The Posted Payable Bills Matrix show correct information as there is filter to Bank Account.
        Initialize();

        // [GIVEN] Prepare Payment Order.
        PreparePaymentOrder(Vendor, BankAccount, CarteraDoc, PaymentOrder, LocalCurrencyCode);

        // [GIVEN] Post Payable Account.
        POPostAndPrint.PayablePostOnly(PaymentOrder);

        // [GIVEN] Store Bank Account.
        LibraryVariableStorage.Enqueue(BankAccount."No.");

        // [GIVEN] Open Bank Account Card and go to Posted Payables Bills.
        BankAccountCard.OpenEdit();
        BankAccountCard.GoToRecord(BankAccount);
        BankAccountCard."Posted Pa&yable Bills".Invoke();

        // [GIVEN] Store Bank Account.
        LibraryVariableStorage.Enqueue(BankAccount."No.");

        // [THEN] Bank Account filter is added when Matrix is invoked.
        BankCatPostedPayableBills.OpenEdit();
        BankCatPostedPayableBills.GoToRecord(BankAccount);
        BankCatPostedPayableBills.PeriodType.SetValue(AnalysisPeriodType::Year);
        BankCatPostedPayableBills."&Show Matrix".Invoke();
    end;

    local procedure Initialize()
    begin
        LibraryReportDataset.Reset();
        LibraryVariableStorage.Clear();

        LibraryCarteraCommon.RevertUnrealizedVATPostingSetup();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(false);

        if IsInitialized then
            exit;

        LibrarySetupStorage.SaveGeneralLedgerSetup();

        LocalCurrencyCode := '';
        IsInitialized := true;
    end;

    local procedure PostPaymentOrderLCY(var PaymentOrder: Record "Payment Order")
    var
        POPostAndPrint: Codeunit "BG/PO-Post and Print";
    begin
        LibraryVariableStorage.Enqueue(StrSubstNo(NotPrintedPaymentOrderQst, PaymentOrder.TableCaption()));
        LibraryVariableStorage.Enqueue(StrSubstNo(PaymentOrderSuccessfullyPostedMsg, PaymentOrder.TableCaption(), PaymentOrder."No."));
        POPostAndPrint.PayablePostOnly(PaymentOrder);
    end;

    local procedure PostPaymentOrderNonLCY(PaymentOrderNo: Code[20])
    var
        PaymentOrder: Record "Payment Order";
        PaymentOrders: TestPage "Payment Orders";
    begin
        LibraryVariableStorage.Enqueue(StrSubstNo(NotPrintedPaymentOrderQst, PaymentOrder.TableCaption()));
        LibraryVariableStorage.Enqueue(StrSubstNo(PaymentOrderSuccessfullyPostedMsg, PaymentOrder.TableCaption(), PaymentOrderNo));

        PaymentOrders.OpenEdit();
        PaymentOrders.GotoKey(PaymentOrderNo);
        PaymentOrders.Post.Invoke();
    end;

    local procedure PostPaymentOrderWithUnrealizedVAT(var Vendor: Record Vendor; var BankAccount: Record "Bank Account"; var CarteraDoc: Record "Cartera Doc."; var PaymentOrder: Record "Payment Order"; var TotalAmount: Decimal; var ExpectedVATAmount: Decimal; var DocumentNo: Code[20]; CurrencyCode: Code[10])
    var
        PaymentTerms: Record "Payment Terms";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryCarteraPayables.CreateCarteraVendorForUnrealizedVAT(Vendor, CurrencyCode);
        LibraryCarteraPayables.SetPaymentTermsVatDistribution(Vendor."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);

        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, CurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);
        TotalAmount :=
          -1 * LibraryCarteraPayables.GetPostedPurchaseInvoiceAmount(Vendor."No.", DocumentNo, VendorLedgerEntry."Document Type"::Invoice);

        CalculateExpectedVATAmount(DocumentNo, TotalAmount, ExpectedVATAmount);

        CreatePaymentOrder(BankAccount, PaymentOrder, CarteraDoc, DocumentNo, Vendor, CurrencyCode);
        PostPaymentOrderLCY(PaymentOrder);
    end;

    local procedure PostPaymentOrderWithUnrealizedVATAndDiscountLCY(var Vendor: Record Vendor; var BankAccount: Record "Bank Account"; var CarteraDoc: Record "Cartera Doc."; var PaymentOrder: Record "Payment Order"; var TotalAmount: Decimal; var ExpectedVATAmount: Decimal; var DocumentNo: Code[20]; var DiscountAmount: Decimal)
    var
        PaymentTerms: Record "Payment Terms";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DiscountPct: Decimal;
    begin
        LibraryCarteraPayables.CreateCarteraVendorForUnrealizedVAT(Vendor, LocalCurrencyCode);
        DiscountPct := LibraryRandom.RandIntInRange(10, 90);
        AddDiscountToPaymentTerms(PaymentTerms, Vendor, DiscountPct);

        LibraryCarteraPayables.SetPaymentTermsVatDistribution(Vendor."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);

        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, LocalCurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        TotalAmount :=
          -1 * LibraryCarteraPayables.GetPostedPurchaseInvoiceAmount(Vendor."No.", DocumentNo, VendorLedgerEntry."Document Type"::Invoice);
        CalculateExpectedVATAmount(DocumentNo, TotalAmount, ExpectedVATAmount);

        DiscountAmount := Round(TotalAmount * DiscountPct / 100, LibraryERM.GetAmountRoundingPrecision());

        CreatePaymentOrder(BankAccount, PaymentOrder, CarteraDoc, DocumentNo, Vendor, LocalCurrencyCode);
        PostPaymentOrderLCY(PaymentOrder);
    end;

    local procedure PreparePaymentOrderWithPaymentTermsDiscountLCY(var Vendor: Record Vendor; var BankAccount: Record "Bank Account"; var CarteraDoc: Record "Cartera Doc."; var PaymentOrder: Record "Payment Order"; var DiscountAmount: Decimal; var TotalAmount: Decimal)
    var
        PaymentTerms: Record "Payment Terms";
        DocumentNo: Code[20];
        DiscountPct: Decimal;
    begin
        LibraryCarteraPayables.CreateCarteraVendorUseInvoicesToCarteraPayment(Vendor, LocalCurrencyCode);
        DiscountPct := LibraryRandom.RandIntInRange(10, 90);
        AddDiscountToPaymentTerms(PaymentTerms, Vendor, DiscountPct);

        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, LocalCurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        CreatePaymentOrder(BankAccount, PaymentOrder, CarteraDoc, DocumentNo, Vendor, LocalCurrencyCode);

        TotalAmount := CarteraDoc."Remaining Amount";
        DiscountAmount := Round(TotalAmount * DiscountPct / 100, LibraryERM.GetAmountRoundingPrecision());
    end;

    local procedure PreparePaymentOrder(var Vendor: Record Vendor; var BankAccount: Record "Bank Account"; var CarteraDoc: Record "Cartera Doc."; var PaymentOrder: Record "Payment Order"; CurrencyCode: Code[10])
    var
        DocumentNo: Code[20];
    begin
        LibraryCarteraPayables.CreateCarteraVendorUseInvoicesToCarteraPayment(Vendor, CurrencyCode);
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, CurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        CreatePaymentOrder(BankAccount, PaymentOrder, CarteraDoc, DocumentNo, Vendor, CurrencyCode);
    end;

    local procedure PrePostBillGroupSetup(var BankAccount: Record "Bank Account"; var Customer: Record Customer)
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, LocalCurrencyCode);
    end;

    local procedure CreateAndPostPurchaseInvoiceWithItem(var Vendor: Record Vendor; var VATPostingSetup: Record "VAT Posting Setup"; LineQuantity: Decimal; UnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LineQuantity);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        PurchaseHeader.TestField("Special Scheme Code", PurchaseHeader."Special Scheme Code"::"01 General");

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoiceWithItem(var Customer: Record Customer; var VATPostingSetup: Record "VAT Posting Setup"; LineQuantity: Decimal; UnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Special Scheme Code", SalesHeader."Special Scheme Code"::"07 Special Cash");
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LineQuantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePaymentOrder(var BankAccount: Record "Bank Account"; var PaymentOrder: Record "Payment Order"; var CarteraDoc: Record "Cartera Doc."; DocumentNo: Code[20]; Vendor: Record Vendor; CurrencyCode: Code[10])
    begin
        if CurrencyCode = LocalCurrencyCode then
            LibraryCarteraPayables.CreateCarteraPaymentOrder(BankAccount, PaymentOrder, LocalCurrencyCode)
        else begin
            LibraryCarteraPayables.CreateBankAccount(BankAccount, CurrencyCode);
            CreatePaymentOrderThroughPage(CurrencyCode, BankAccount."No.", PaymentOrder);
        end;

        LibraryCarteraPayables.AddPaymentOrderToCarteraDocument(CarteraDoc, DocumentNo, Vendor."No.", PaymentOrder."No.");

        PaymentOrder.Validate("Export Electronic Payment", true);
        PaymentOrder.Validate("Elect. Pmts Exported", true);
        PaymentOrder.Modify(true);
    end;

    local procedure CreatePaymentOrderThroughPage(CurrencyCode: Code[10]; BankAccountNo: Code[20]; var PaymentOrder: Record "Payment Order")
    var
        PaymentOrders: TestPage "Payment Orders";
        PaymentOrderNo: Text;
    begin
        PaymentOrders.OpenNew();

        LibraryVariableStorage.Enqueue(CurrencyCode);
        PaymentOrders."Currency Code".Activate();
        PaymentOrders."Currency Code".Lookup();

        LibraryVariableStorage.Enqueue(BankAccountNo);
        PaymentOrders."Bank Account No.".Activate();
        PaymentOrders."Bank Account No.".Lookup();

        PaymentOrderNo := PaymentOrders."No.".Value();

        PaymentOrders.OK().Invoke();

        PaymentOrder.Get(PaymentOrderNo);
    end;

    local procedure CreateVATPostingSetupVATCashRegime(var VATPostingSetup: Record "VAT Posting Setup"; VATBusinessPostingGroupCode: Code[20]; VATPercent: Decimal)
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", VATPercent);
        VATPostingSetup.Validate("VAT Identifier", LibraryUtility.GenerateGUID());
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("VAT Cash Regime", true);
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusinessPostingGroupCode: Code[20]; VATPercent: Decimal)
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", VATPercent);
        VATPostingSetup.Validate("VAT Identifier", LibraryUtility.GenerateGUID());
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateFixedAssetWithGroup(var FixedAsset: Record "Fixed Asset"; VATPostingSetup: Record "VAT Posting Setup")
    var
        FAPostingGroup: Record "FA Posting Group";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        UpdateFAPostingGroup(FAPostingGroup, VATPostingSetup);
        FixedAsset.Validate("FA Posting Group", FAPostingGroup.Code);
        FixedAsset.Modify(true);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FixedAsset: Record "Fixed Asset")
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", LibraryFixedAsset.GetDefaultDeprBook());
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());

        // Random Number Generator for Ending date.
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandIntInRange(2, 5)) + 'Y>', WorkDate()));
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Modify(true);
    end;

    local procedure UpdateFAPostingGroup(FAPostingGroup: Record "FA Posting Group"; VATPostingSetup: Record "VAT Posting Setup")
    var
        FAPostingGroup2: Record "FA Posting Group";
        GLAccount: Record "G/L Account";
    begin
        FAPostingGroup2.SetFilter("Acquisition Cost Account", '<>''''');
        FAPostingGroup2.FindFirst();
        FAPostingGroup.TransferFields(FAPostingGroup2, false);

        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);

        FAPostingGroup.Validate("Acquisition Cost Account", GLAccount."No.");
        FAPostingGroup.Modify(true);
    end;

    local procedure CalculateExpectedVATAmount(DocumentNo: Code[20]; TotalAmount: Decimal; var ExpectedVATAmount: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();

        VATPostingSetup.Get(PurchInvLine."VAT Bus. Posting Group", PurchInvLine."VAT Prod. Posting Group");
        ExpectedVATAmount :=
          Round(TotalAmount - TotalAmount * 100 / (VATPostingSetup."VAT %" + 100), LibraryERM.GetAmountRoundingPrecision());
    end;

    local procedure AddDiscountToPaymentTerms(var PaymentTerms: Record "Payment Terms"; Vendor: Record Vendor; var DiscountPct: Decimal)
    begin
        PaymentTerms.Get(Vendor."Payment Terms Code");
        PaymentTerms.Validate("Discount Date Calculation", PaymentTerms."Due Date Calculation");
        DiscountPct := LibraryRandom.RandIntInRange(5, 90);
        PaymentTerms.Validate("Discount %", DiscountPct);
        PaymentTerms.Modify(true);
    end;

    local procedure InvokeRejectOnBillGroup(CustomerNo: Code[20]; DocumentNo: Code[20]; BillGroupNo: Code[20]; var TotalAmount: Decimal)
    var
        PostedBillGroup: Record "Posted Bill Group";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostedBillGroupTestPage: TestPage "Posted Bill Groups";
    begin
        TotalAmount := LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(
            CustomerNo, DocumentNo, CustLedgerEntry."Document Type"::Invoice);

        // Open View - Posted Bill Groups page
        PostedBillGroupTestPage.OpenView();

        PostedBillGroup.SetFilter("No.", BillGroupNo);
        PostedBillGroup.FindFirst();

        PostedBillGroupTestPage.GotoRecord(PostedBillGroup);

        // Exercise
        Commit();
        //LibraryVariableStorage.Enqueue(SettlePostingDate);
        //LibraryVariableStorage.Enqueue(StrSubstNo(TotalSettlementBillGroupMsg, 1, TotalAmount));
        PostedBillGroupTestPage.Docs.Reject.Invoke();
    end;

    local procedure InvokeTotalSettlementOnPaymentOrder(PostedPaymentOrderNo: Code[20])
    var
        PostedPaymentOrderTestPage: TestPage "Posted Payment Orders";
    begin
        PostedPaymentOrderTestPage.OpenEdit();
        PostedPaymentOrderTestPage.FILTER.SetFilter("No.", PostedPaymentOrderNo);

        LibraryVariableStorage.Enqueue(
          StrSubstNo(SettlementCompletedSuccessfullyMsg, 1, PostedPaymentOrderTestPage.Docs."Remaining Amount".AsDecimal()));

        PostedPaymentOrderTestPage.Docs.TotalSettlement.Invoke();
    end;

    local procedure InvokePartialSettlementOnPaymentOrder(var PostedPaymentOrdersTestPage: TestPage "Posted Payment Orders"; PostedPaymentOrderNo: Code[20]; CarteraDoc: Record "Cartera Doc."; var SettledAmount: Decimal; var InitialAmount: Decimal; DiscountAmount: Decimal)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        PostedPaymentOrdersTestPage.OpenView();
        PostedPaymentOrdersTestPage.GotoKey(PostedPaymentOrderNo);

        GLSetup.Get();
        InitialAmount := CarteraDoc."Remaining Amount";
        SettledAmount := LibraryRandom.RandDecInDecimalRange(0, InitialAmount / 2,
            LibraryCarteraPayables.GetRandomAllowedNumberOfDecimals(GLSetup."Amount Decimal Places"));

        LibraryVariableStorage.Enqueue(SettledAmount);
        LibraryVariableStorage.Enqueue(
          StrSubstNo(PartialSettlementPOMsg, 1, InitialAmount - DiscountAmount, PostedPaymentOrderNo, SettledAmount));

        PostedPaymentOrdersTestPage.Docs.PartialSettlement.Invoke();
    end;

    local procedure UpdateVATCashRegimeOnGLSetup(VATCashRegime: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Cash Regime", VATCashRegime);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyPartialSettlementOnPaymentOrder(CarteraDoc: Record "Cartera Doc."; InitialAmount: Decimal; SettledAmount: Decimal; PaymentOrder: Record "Payment Order")
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedPaymentOrder: Record "Closed Payment Order";
    begin
        PostedCarteraDoc.SetFilter("Document No.", CarteraDoc."Document No.");
        PostedCarteraDoc.SetFilter(Type, Format(CarteraDoc.Type));
        PostedCarteraDoc.FindFirst();

        Assert.AreNearlyEqual(InitialAmount - SettledAmount, PostedCarteraDoc."Remaining Amount", LibraryERM.GetAmountRoundingPrecision(),
          UnexpectedPartSettledCartDocRemAmountErr);
        Assert.AreEqual(PostedCarteraDoc.Status::Open, PostedCarteraDoc.Status, InvalidStatusPartiallySettledCarteraDocErr);

        ClosedPaymentOrder.SetFilter("No.", PaymentOrder."No.");
        Assert.IsTrue(ClosedPaymentOrder.IsEmpty, 'Payment order should not be closed');
    end;

    local procedure VerifyCarteraDocIsClosedAsHonored(CarteraDoc: Record "Cartera Doc.")
    var
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        ClosedCarteraDoc.SetRange("Document No.", CarteraDoc."Document No.");
        ClosedCarteraDoc.FindFirst();
        Assert.AreEqual(ClosedCarteraDoc.Status::Honored, ClosedCarteraDoc.Status, UnexpectedCartDocStatusErr);
        Assert.AreEqual(0, ClosedCarteraDoc."Remaining Amt. (LCY)", UnexpectedCartDocRemAmountErr);

        VendorLedgerEntry.SetRange("Entry No.", ClosedCarteraDoc."Entry No.");
        Assert.IsFalse(VendorLedgerEntry.IsEmpty, 'There should be vendor ledger entries present in the system');
    end;

    local procedure VerifyGLEntriesForPartialSettlementsWithDiscount(DocumentNo: Code[20]; DiscountAmount: Decimal; InitialAmount: Decimal; SettledAmount: Decimal; HasUnrealizedVAT: Boolean; ExpectedVATamount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        FirstSettlementVATAmount: Decimal;
    begin
        GLEntry.SetRange("Document No.", DocumentNo);

        GLEntry.Find('-');
        Assert.AreNearlyEqual(InitialAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount on G/L Line');

        GLEntry.Next();
        Assert.AreNearlyEqual(InitialAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount on G/L Line');

        if HasUnrealizedVAT then begin
            FirstSettlementVATAmount := ExpectedVATamount * SettledAmount / InitialAmount;

            GLEntry.Next();
            Assert.AreNearlyEqual(
              FirstSettlementVATAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(),
              'Wrong amount for Unrealized VAT Amount');

            GLEntry.Next();
            Assert.AreNearlyEqual(
              FirstSettlementVATAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(),
              'Wrong amount for Unrealized VAT Amount');
        end;

        // Check Settlement Amount
        GLEntry.Next();
        Assert.AreNearlyEqual(
          SettledAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount on G/L Line for Settlement Amount');

        GLEntry.Next();
        Assert.AreNearlyEqual(
          SettledAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount on G/L Line for Settlement Amount');

        if HasUnrealizedVAT then begin
            FirstSettlementVATAmount := ExpectedVATamount * SettledAmount / InitialAmount;

            GLEntry.Next();
            Assert.AreNearlyEqual(
              ExpectedVATamount - FirstSettlementVATAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(),
              'Wrong amount for Unrealized VAT Amount');

            GLEntry.Next();
            Assert.AreNearlyEqual(
              ExpectedVATamount - FirstSettlementVATAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(),
              'Wrong amount for Unrealized VAT Amount');
        end;

        // Check invoice Discount Amount
        GLEntry.Next();
        Assert.AreNearlyEqual(
          DiscountAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount on G/L Line for Settlement Amount');

        // Check Remaining Amount with Discount
        GLEntry.Next();
        Assert.AreNearlyEqual(
          InitialAmount - SettledAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(),
          'Wrong amount on G/L Line for Remaining Amount');

        // Check remainging amount without discount
        GLEntry.Next();
        Assert.AreNearlyEqual(
          InitialAmount - SettledAmount - DiscountAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(),
          'Wrong amount on G/L line without discount');

        Assert.IsTrue(GLEntry.Next() = 0, 'There should not be any more G/L Entries');
    end;

    local procedure VerifyGLEntriesForTotalSettlementWithDiscount(DocumentNo: Code[20]; DiscountAmount: Decimal; TotalAmount: Decimal; HasUnrealizedVAT: Boolean; ExpectedVATamount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);

        GLEntry.Find('-');
        Assert.AreNearlyEqual(TotalAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount on G/L Line');

        GLEntry.Next();
        Assert.AreNearlyEqual(TotalAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount on G/L Line');

        if HasUnrealizedVAT then begin
            GLEntry.Next();
            Assert.AreNearlyEqual(
              ExpectedVATamount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount for Unrealized VAT Amount');

            GLEntry.Next();
            Assert.AreNearlyEqual(
              ExpectedVATamount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount for Unrealized VAT Amount');
        end;

        // Check invoice Discount Amount
        GLEntry.Next();
        Assert.AreNearlyEqual(
          DiscountAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount on G/L Line for Settlement Amount');

        // Check Remaining Amount with Discount
        GLEntry.Next();
        Assert.AreNearlyEqual(
          TotalAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount on G/L Line for Remaining Amount');

        // Check remainging amount without discount
        GLEntry.Next();
        Assert.AreNearlyEqual(
          TotalAmount - DiscountAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(),
          'Wrong amount on G/L line without discount');

        Assert.IsTrue(GLEntry.Next() = 0, 'There should not be any more G/L Entries');
    end;

    local procedure AddCarteraDocumentToPaymentOrder(PaymentOrderNo: Code[20]; DocumentNo: Code[20])
    var
        PaymentOrders: TestPage "Payment Orders";
    begin
        LibraryVariableStorage.Enqueue(DocumentNo); // for CarteraDocumentsActionModalPageHandler

        // Open the PaymentOrder page pointing to the created Payment Order record
        PaymentOrders.OpenEdit();
        PaymentOrders.GotoKey(PaymentOrderNo);

        // Insert a Payable Cartera Document using the Page Part 'Docs'
        PaymentOrders.Docs.Insert.Invoke();

        // Save the changes, as the cartera document has been added to the Payment Order
        PaymentOrders.OK().Invoke();
    end;

    local procedure PreparePaymentOrderWithDimension(var Vendor: Record Vendor; var BankAccount: Record "Bank Account"; var CarteraDoc: Record "Cartera Doc."; var PaymentOrder: Record "Payment Order"; CurrencyCode: Code[10])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        DocumentNo: Code[20];
    begin
        // [GIVEN] Venodr is created with Curreny Code.
        LibraryCarteraPayables.CreateCarteraVendorUseInvoicesToCarteraPayment(Vendor, CurrencyCode);

        // [GIVEN] Dimension is created , Dimension Value is added and Default dimension is added into Vendor.
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Vendor, Vendor."No.", Dimension.Code, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Same Code");
        DefaultDimension.Modify(true);
        Vendor.Modify(true);

        // [GIVEN] Vendor Bank Account is created with Currency Code.
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, CurrencyCode);

        // [GIVEN] Payable Cartera Order is created and stored in Variable.
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // [THEN] Payment Order is Created with Default dimesion.
        CreatePaymentOrderWithDimension(BankAccount, PaymentOrder, CarteraDoc, DocumentNo, Vendor, CurrencyCode);
    end;

    local procedure CreatePaymentOrderWithDimension(var BankAccount: Record "Bank Account"; var PaymentOrder: Record "Payment Order"; var CarteraDoc: Record "Cartera Doc."; DocumentNo: Code[20]; Vendor: Record Vendor; CurrencyCode: Code[10])
    begin
        // [GIVEN] Cartera Payment Order is made with Bank Account And Currency.
        if CurrencyCode = LocalCurrencyCode then begin
            LibraryCarteraPayables.CreateCarteraPaymentOrder(BankAccount, PaymentOrder, LocalCurrencyCode);
            UpdateDefaultDimensionIntoBankAccount(BankAccount);
        end else begin
            LibraryCarteraPayables.CreateBankAccount(BankAccount, CurrencyCode);
            UpdateDefaultDimensionIntoBankAccount(BankAccount);
            CreatePaymentOrderThroughPage(CurrencyCode, BankAccount."No.", PaymentOrder);
        end;

        // [GIVEN] Payment Order is added to cartera Document and Validated Export Electronic Payment and Elect Pmts Exported to true.
        LibraryCarteraPayables.AddPaymentOrderToCarteraDocument(CarteraDoc, DocumentNo, Vendor."No.", PaymentOrder."No.");

        PaymentOrder.Validate("Export Electronic Payment", true);
        PaymentOrder.Validate("Elect. Pmts Exported", true);
        PaymentOrder.Modify(true);
    end;

    local procedure UpdateDefaultDimensionIntoBankAccount(BankAccount: Record "Bank Account")
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // [GIVEN] Bank Account is Created with Default dimesion.
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::"Bank Account", BankAccount."No.", Dimension.Code, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);
        BankAccount.Modify(true);
    end;


    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SettleDocsInPostedPOModalPageHandler(var SettleDocsInPostedPOModalPageHandler: TestRequestPage "Settle Docs. in Posted PO")
    begin
        SettleDocsInPostedPOModalPageHandler.OK().Invoke();
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
    procedure CurrenciesPageHandler(var Currencies: TestPage Currencies)
    var
        CurrencyCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(CurrencyCode);
        Currencies.GotoKey(CurrencyCode);
        Currencies.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountListPageHandler(var BankAccountList: TestPage "Bank Account List")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        BankAccountList.GotoKey(BankAccountNo);
        BankAccountList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessageText: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessageText);
        Assert.ExpectedMessage(Format(ExpectedMessageText), Question);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessageText: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessageText);
        Assert.ExpectedMessage(Format(ExpectedMessageText), Message);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchSettlementRequestPageHandler(var BatchSettlPostedPO: TestRequestPage "Batch Settl. Posted POs")
    begin
        BatchSettlPostedPO.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PartialSettlPayableRequestPageHandler(var PartialSettlPayable: TestRequestPage "Partial Settl. - Payable")
    var
        SettledAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(SettledAmount);

        // Set applied amount
        PartialSettlPayable.AppliedAmt.SetValue(SettledAmount);
        PartialSettlPayable.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SettleDocsinPostedPORequestPageHandler(var SettleDocsinPostedPO: TestRequestPage "Settle Docs. in Posted PO")
    begin
        SettleDocsinPostedPO.PostingDate.SetValue(WorkDate());

        SettleDocsinPostedPO.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RejectDocsRequestPageHandler(var RejectDocs: TestRequestPage "Reject Docs.")
    begin
        RejectDocs.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CarteraDocumnets(var CarteraDocuments: TestPage "Cartera Documents")
    begin
        CarteraDocuments.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure OpenBankCatPostPayBillsMatrix(var BankCatPostPayBillsMatrix: TestPage "Bank Cat.Post.Pay.Bills Matrix")
    begin
        BankCatPostPayBillsMatrix.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Assert.AreEqual(BankCatPostPayBillsMatrix."No.".Value(), LibraryVariableStorage.DequeueText(), '');
        BankCatPostPayBillsMatrix.Field1.Drilldown();
    end;

    [ModalPageHandler]
    procedure OpenPostedBills(var PostedBills: TestPage "Posted Bills")
    begin
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerCartera(Question: Text[1024]; var Reply: Boolean)
    var
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandlerCartera(Message: Text[1024])
    var
    begin
    end;

}

