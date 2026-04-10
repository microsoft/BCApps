codeunit 134103 "ERM Prepayment IV"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Prepayment]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryResource: Codeunit "Library - Resource";
        isInitialized: Boolean;
        AmountErr: Label '%1 must be %2 in %3.';
        PrepaymentCMErr: Label 'Posted Prepayment Credit Memo must exist.';
        UnbalancedAccountErr: Label 'Balance is wrong for G/L Account: %1 filterd on document no.: %2.';
        RoundingACYAmountErr: Label 'Wrong ACY amount on rounding entry.';

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtAmountAfterPostingPartialShipmentSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Amount: Decimal;
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
        SalesPrepmtAccount: Code[20];
    begin
        // Check Prepayment Amount on GL Entry after Posting Partial Shipment from Sales Order.

        // Setup.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        SalesPrepmtAccount := CreateAndPostSalesPrepaymentInvoice(SalesHeader, SalesLine, GLAccountNo);
        Amount := Round((SalesLine."Qty. to Ship" * SalesLine."Unit Price") * SalesLine."Prepayment %" / 100);

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Prepayment Amount on GL Entry after Posting Partial Shipment.
        VerifyGLEntry(DocumentNo, Amount, GLAccountNo, LibraryERM.GetAmountRoundingPrecision());

        // Tear Down.
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtAmountAfterPostingPartialShipmentSalesOrderSetQtyBeforePrepayment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Amount: Decimal;
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
        SalesPrepmtAccount: Code[20];
    begin
        // Check Prepayment Amount on GL Entry after Posting Partial Shipment from Sales Order., change Qty. to Ship before posting Prepayment.

        // Setup.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        SalesPrepmtAccount := CreateSalesOrder(SalesHeader, SalesLine, GLAccountNo);
        ModifyQtyToShipOnSalesLine(SalesLine);
        PostSalesPrepaymentInvoice(SalesHeader);
        Amount := Round((SalesLine."Qty. to Ship" * SalesLine."Unit Price") * SalesLine."Prepayment %" / 100);

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Prepayment Amount on GL Entry after Posting Partial Shipment.
        VerifyGLEntry(DocumentNo, Amount, GLAccountNo, LibraryERM.GetAmountRoundingPrecision());

        // Tear Down.
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtAmountAfterPostingSecondPartialShipmentSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Amount: Decimal;
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
        SalesPrepmtAccount: Code[20];
    begin
        // Check Prepayment Amount on GL Entry after Posting second, final Partial Shipment from Sales Order.

        // Setup.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        SalesPrepmtAccount := CreateAndPostSalesPrepaymentInvoice(SalesHeader, SalesLine, GLAccountNo);
        Amount := Round(((SalesLine.Quantity - SalesLine."Qty. to Ship") * SalesLine."Unit Price") * SalesLine."Prepayment %" / 100);

        // Exercise.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Prepayment Amount on GL Entry after Posting Partial Shipment.
        VerifyGLEntry(DocumentNo, Amount, GLAccountNo, LibraryERM.GetAmountRoundingPrecision());

        // Tear Down.
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('PrepaymentConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepmtAmountAfterModifyPrepmtPctSalesHeader()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Amount: Decimal;
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
        PrepaymentPct: Decimal;
        FirstPrePaymentPct: Decimal;
        SalesPrepmtAccount: Code[20];
    begin
        // Check Prepayment Amount on GL Entry after Posting Partial Shipment and Modify Prepayment % on Sales Header.

        // Setup: Create Sales Order and Post it.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        SalesPrepmtAccount := CreateAndPostSalesPrepaymentInvoice(SalesHeader, SalesLine, GLAccountNo);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Modify Sales Header for Prepayment % with Greater Random Value.
        PrepaymentPct := LibraryRandom.RandIntInRange(10, 40);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        FirstPrePaymentPct := SalesHeader."Prepayment %";
        ModifySalesHeaderForPrepaymentPct(SalesHeader, SalesHeader."Prepayment %" + PrepaymentPct);

        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        Amount := Round(((Salesline.Quantity - SalesLine."Quantity Invoiced") * SalesLine."Unit Price") * (SalesHeader."Prepayment %" - FirstPrePaymentPct) / 100);
        DocumentNo := GetPostedDocumentNo(SalesHeader."Prepayment No. Series");

        // Exercise: Post Prepayment Invoice through Page.
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.PostPrepaymentInvoice.Invoke();

        // Verify: Verify Prepayment Amount after Modify Prepayment % on Sales Header with GL Entry.
        VerifyGLEntry(DocumentNo, -Amount, GLAccountNo, LibraryERM.GetAmountRoundingPrecision());

        // Tear Down.
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtAmountAfterPostingPartialReceivePurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Amount: Decimal;
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
        PurchasePrepmtAccount: Code[20];
    begin
        // Check Prepayment Amount on GL Entry after Posting Partial Shipment Purchase Order.

        // Setup: Create Purchase Order and Post Prepayment Invoice.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();
        PurchasePrepmtAccount := CreateAndPostPurchasePrepaymentInvoice(PurchaseHeader, PurchaseLine, GLAccountNo);

        // Exercise: Post Purchase Order with Partial Qty. to Receive after Posting Prepayment Invoice.
        Amount := Round((PurchaseLine."Qty. to Receive" * PurchaseLine."Direct Unit Cost") * PurchaseHeader."Prepayment %" / 100);
        DocumentNo := PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Prepayment Amount on GL Entry after Posting Partial Shipment.
        VerifyGLEntry(DocumentNo, -Amount, GLAccountNo, LibraryERM.GetAmountRoundingPrecision());

        // Tear Down.
        UpdatePurchasePrepmtAccount(
          PurchasePrepmtAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtAmountAfterPostingPartialReceivePurchaseOrderSetQtyBeforePrepayment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Amount: Decimal;
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
        PurchasePrepmtAccount: Code[20];
    begin
        // Check Prepayment Amount on GL Entry after Posting Partial Shipment Purchase Order, change Qty. to Receive before posting Prepayment.

        // Setup: Create Purchase Order and Post Prepayment Invoice.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();
        PurchasePrepmtAccount := CreatePurchaseOrder(PurchaseHeader, PurchaseLine, GLAccountNo);
        ModifyQtyToReceiveOnPurchaseLine(PurchaseLine);
        PostPurchasePrepaymentInvoice(PurchaseHeader);

        // Exercise: Post Purchase Order with Partial Qty. to Receive after Posting Prepayment Invoice.
        Amount := Round((PurchaseLine."Qty. to Receive" * PurchaseLine."Direct Unit Cost") * PurchaseHeader."Prepayment %" / 100);
        DocumentNo := PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Prepayment Amount on GL Entry after Posting Partial Shipment.
        VerifyGLEntry(DocumentNo, -Amount, GLAccountNo, LibraryERM.GetAmountRoundingPrecision());

        // Tear Down.
        UpdatePurchasePrepmtAccount(
          PurchasePrepmtAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtAmountAfterPostingSecondPartialReceivePurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Amount: Decimal;
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
        PurchasePrepmtAccount: Code[20];
    begin
        // Check Prepayment Amount on GL Entry after Posting second, final Partial Shipment Purchase Order.

        // Setup: Create Purchase Order and Post Prepayment Invoice.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();
        PurchasePrepmtAccount := CreateAndPostPurchasePrepaymentInvoice(PurchaseHeader, PurchaseLine, GLAccountNo);

        // Exercise: Post Purchase Order with Partial Qty. to Receive after Posting Prepayment Invoice.
        Amount :=
          Round(
            ((PurchaseLine.Quantity - PurchaseLine."Qty. to Receive") * PurchaseLine."Direct Unit Cost") *
            PurchaseHeader."Prepayment %" / 100);

        PostPurchaseDocument(PurchaseHeader, true, true);
        DocumentNo := PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Prepayment Amount on GL Entry after Posting Partial Shipment.
        VerifyGLEntry(DocumentNo, -Amount, GLAccountNo, LibraryERM.GetAmountRoundingPrecision());

        // Tear Down.
        UpdatePurchasePrepmtAccount(
          PurchasePrepmtAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('PrepaymentConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepmtAmountAfterModifyPrepmtPctPurchaseHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        Amount: Decimal;
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
        PurchasePrepmtAccount: Code[20];
        PrepaymentPct: Decimal;
        FirstPrePaymentPct: Decimal;
    begin
        // Check Prepayment Amount on GL Entry after Posting Partial Receive and Modify Prepayment % on Purchase Header.

        // Setup: Create Purchase Order, Post Prepayment Invoice and Modify Purchase Line for Partial Shipment.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();
        PurchasePrepmtAccount := CreateAndPostPurchasePrepaymentInvoice(PurchaseHeader, PurchaseLine, GLAccountNo);

        // Modify Purchase Line for Partial Receive and Post.
        PostPurchaseDocument(PurchaseHeader, true, true);

        // Modify Purchase Header for Prepayment % with Greater Random Value.
        PrepaymentPct := LibraryRandom.RandIntInRange(10, 40);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        FirstPrePaymentPct := PurchaseHeader."Prepayment %";
        PurchaseHeader.Validate("Prepayment %", PurchaseHeader."Prepayment %" + PrepaymentPct);
        PurchaseHeader.Modify(true);

        // Update Purchase Line with Modified Prepayment %.
        PurchaseLine.get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Prepayment No. Series");
        Amount := Round(PurchaseLine."Line Amount" * PrepaymentPct / 100);
        Amount := Round(((PurchaseLine.Quantity - PurchaseLine."Quantity Invoiced") * PurchaseLine."Direct Unit Cost") * (PurchaseHeader."Prepayment %" - FirstPrePaymentPct) / 100);
        ModifyVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);

        // Exercise: Post Prepayment Invoice through Page.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PostPrepaymentInvoice.Invoke();

        // Verify: Verify Prepayment Amount after Modify Prepayment % on Purchase Header with GL Entry.
        VerifyGLEntry(DocumentNo, Amount, GLAccountNo, LibraryERM.GetAmountRoundingPrecision());

        // Tear Down.
        UpdatePurchasePrepmtAccount(
          PurchasePrepmtAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('PrepaymentConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepaymentAmountWithCurrencyOnPurchaseOrder()
    var
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Amount: Decimal;
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
        PurchasePrepmtAccount: Code[20];
        CurrencyCode: Code[10];
    begin
        // Check Prepayment Amount and Source Type on GL Entry after Posting Purchase Order with Currency.

        // Setup: Create Purchase Order, Post Prepayment Invoice and Modify Purchase Line for Partial Shipment.
        Initialize();
        CurrencyCode := CreateCurrency();
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();
        CreateExchangeRate(CurrencyCode, WorkDate());
        PurchasePrepmtAccount := CreatePurchaseOrder(PurchaseHeader, PurchaseLine, GLAccountNo);
        ModifyCurrencyOnPurchaseHeader(PurchaseHeader, CurrencyCode);

        // Update Purchase Prepayment Account and Modify Purchase Order.
        ModifyPurchaseLine(PurchaseLine, CurrencyCode);

        Amount := PurchaseLine."Prepmt. Line Amount";

        // Exercise:
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Prepayment No. Series");
        PostPurchasePrepaymentInvoice(PurchaseHeader);

        // Verify: Verify GL Entry for Prepayment Amount and Source Type for Vendor.
        Currency.Get(CurrencyCode);
        VerifyGLEntryInFCY(DocumentNo, Amount, GLAccountNo, CurrencyCode, WorkDate());
        VerifyGLEntryForSourceType(DocumentNo, GLAccountNo);

        // Tear Down.
        UpdatePurchasePrepmtAccount(
          PurchasePrepmtAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('PrepaymentConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepaymentAmountWithModifyCurrencyOnPurchaseOrder()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Amount: Decimal;
        Amount2: Decimal;
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
        PurchasePrepmtAccount: Code[20];
        StartingDate: Date;
        CurrencyCode: Code[10];
    begin
        // Check Prepayment Amount and Source Type on GL Entry after Posting Purchase Order with multiple Currency Exchange Rate.

        // Setup: Create Purchase Order and Currency with New Starting Date. Take Random Date for New Starting Date.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();
        StartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        CurrencyCode := CreateCurrency();
        CreateExchangeRate(CurrencyCode, WorkDate());
        CreateExchangeRate(CurrencyCode, StartingDate);
        PurchasePrepmtAccount := CreatePurchaseOrder(PurchaseHeader, PurchaseLine, GLAccountNo);
        ModifyCurrencyOnPurchaseHeader(PurchaseHeader, CurrencyCode);

        ModifyPurchaseLine(PurchaseLine, CurrencyCode);

        PostPurchasePrepaymentInvoice(PurchaseHeader);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        ModifyPostingDateOnPurchaseHeader(PurchaseHeader, StartingDate);

        Amount :=
          Round(
            LibraryERM.ConvertCurrency(PurchaseLine."Line Amount" * PurchaseHeader."Prepayment %" / 100, CurrencyCode, '', StartingDate));
        Amount2 := LibraryERM.ConvertCurrency(PurchaseLine."Line Amount", CurrencyCode, '', StartingDate);

        // Exercise:
        DocumentNo := PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify GL Entry for Prepayment Amount and Source Type for Vendor.
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyGLEntry(DocumentNo, -Amount, GLAccountNo, LibraryERM.GetAmountRoundingPrecision());
        VerifyGLEntry(DocumentNo, Amount2, GeneralPostingSetup."Purch. Account", LibraryERM.GetAmountRoundingPrecision());
        VerifyGLEntryForSourceType(DocumentNo, GLAccountNo);

        // Tear Down.
        UpdatePurchasePrepmtAccount(
          PurchasePrepmtAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceAndShipSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepmtAccount: Code[20];
    begin
        // Check Item Ledger Entry after Posting Partial Shipment of Sales Order with Posting Prepayment Invoice.

        // Setup. Create Sales Order and Post Prepayment Invoice.
        Initialize();
        SalesPrepmtAccount := CreateAndPostSalesPrepaymentInvoice(SalesHeader, SalesLine, LibraryERM.CreateGLAccountWithSalesSetup());

        // Exercise: Post Sales Order as Ship.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Verify: Verify Item Ledger Entry for Remaining Quantity.
        VerifyItemLedgerEntry(SalesLine."No.", -SalesLine."Qty. to Ship");

        // Tear Down.
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceAndModifyQuantityOnSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepmtAccount: Code[20];
    begin
        // Check Sales Line after Posting Ship, Prepayment Invoice and Modify Quantity with More values.

        // Setup. Create Sales Order and Post Prepayment Invoice.
        Initialize();
        SalesPrepmtAccount := CreateAndPostSalesPrepaymentInvoice(SalesHeader, SalesLine, LibraryERM.CreateGLAccountWithSalesSetup());
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Exercise: Reopen Posted Sales Order and Modify Quantity on Sales Line with more value previous one.
        LibrarySales.ReopenSalesDocument(SalesHeader);
        ModifyQuantityOnSalesLine(SalesLine);

        // Verify: Verify that Quantity to Ship has been updated after Modify Quantity on Sales Line.
        SalesLine.TestField("Qty. to Ship", SalesLine.Quantity - SalesLine."Quantity Shipped");

        // Tear Down.
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceAndPostSalesOrder()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
        PrepaymentAmount: Decimal;
        SalesPrepmtAccount: Code[20];
    begin
        // Check GL Entry for Posted Values after Posting Sales Order with Partial Ship and Modify Quantity.

        // Setup. Create Sales Order and Post Prepayment Invoice and Post as Ship.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        SalesPrepmtAccount := CreateAndPostSalesPrepaymentInvoice(SalesHeader, SalesLine, GLAccountNo);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // Exercise: Reopen Posted Sales Order and Modify Quantity on Sales Line with more value previous one and Post.
        ModifyQuantityOnSalesLine(SalesLine);
        PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        PrepaymentAmount := Round(SalesLine."Line Amount" * SalesHeader."Prepayment %" / 100);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify that Quantity to Ship has been updated after Modify Quantity on Sales Line.
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyGLEntry(DocumentNo, -SalesLine."Line Amount", GeneralPostingSetup."Sales Account", LibraryERM.GetAmountRoundingPrecision());
        VerifyGLEntry(DocumentNo, PrepaymentAmount, GLAccountNo, LibraryERM.GetAmountRoundingPrecision());

        // Tear Down.
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceAndReceivePurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasePrepmtAccount: Code[20];
    begin
        // Check Item Ledger Entry after Posting Partial Receive of Purchase Order with Posting Prepayment Invoice.

        // Setup. Create Purchase Order and Post Prepayment Invoice.
        Initialize();
        PurchasePrepmtAccount :=
          CreateAndPostPurchasePrepaymentInvoice(PurchaseHeader, PurchaseLine, LibraryERM.CreateGLAccountWithPurchSetup());

        // Exercise: Post Purchase Order as Receive.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify: Verify Item Ledger Entry for Remaining Quantity.
        VerifyItemLedgerEntry(PurchaseLine."No.", PurchaseLine."Qty. to Receive");

        // Tear Down.
        UpdateSalesPrepmtAccount(PurchasePrepmtAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceAndModifyQuantityOnPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasePrepmtAccount: Code[20];
    begin
        // Check Purchase Line after Posting Receive, Prepayment Invoice and Modify Quantity with More values.

        // Setup. Create Purchase Order and Post with Receive.
        Initialize();
        PurchasePrepmtAccount :=
          CreateAndPostPurchasePrepaymentInvoice(PurchaseHeader, PurchaseLine, LibraryERM.CreateGLAccountWithPurchSetup());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Exercise: Reopen Posted Purchase Order and Modify Quantity on Purchase Line with more value previous one.
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        ModifyQuantityOnPurchaseLine(PurchaseLine);

        // Verify: Verify that Quantity to Receive has been updated after Modify Quantity on Purchase Line.
        PurchaseLine.TestField("Qty. to Receive", PurchaseLine.Quantity - PurchaseLine."Quantity Received");

        // Tear Down.
        UpdateSalesPrepmtAccount(PurchasePrepmtAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceAndPostPurchaseOrder()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
        PrepaymentAmount: Decimal;
        PurchasePrepmtAccount: Code[20];
    begin
        // Check GL Entry for Posted Values after Posting Purchase Order with Partial Receive and Modify Quantity.

        // Setup. Create Purchase Order and Post Prepayment Invoice and Post as Receive.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();
        PurchasePrepmtAccount := CreateAndPostPurchasePrepaymentInvoice(PurchaseHeader, PurchaseLine, GLAccountNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // Exercise: Reopen Posted Purchase Order and Modify Quantity on Purchase Line with more value previous one and Post.
        ModifyQuantityOnPurchaseLine(PurchaseLine);
        PostPurchasePrepaymentInvoice(PurchaseHeader);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PrepaymentAmount := Round(PurchaseLine."Line Amount" * PurchaseHeader."Prepayment %" / 100);
        DocumentNo := PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify that Quantity to Receive has been updated after Modify Quantity on Purchase Line.
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyGLEntry(DocumentNo, PurchaseLine."Line Amount", GeneralPostingSetup."Purch. Account", LibraryERM.GetAmountRoundingPrecision());
        VerifyGLEntry(DocumentNo, -PrepaymentAmount, GLAccountNo, LibraryERM.GetAmountRoundingPrecision());

        // Tear Down.
        UpdateSalesPrepmtAccount(PurchasePrepmtAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineForPrepaymentPct()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Prepayment % field on Purchase Line as same as Purchase Header.

        // Create Purchase Order with Prepayment %.
        Initialize();
        CreateAndUpdatePrepaymentPctOnPurchaseOrder(PurchaseHeader);

        // Verify: Verify Purchase Line for Prepayment % field has correct Prepayment % value as Purchase Header.
        VerifyPurchaseLineForPrepaymentPct(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineForPrepaymentPctAfterUpdatePurchaseHeader()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Prepayment % field on Purchase Line after Modifying on Purchase Header.

        // Create And Update Purchase Order with Prepayment % Random Values.
        Initialize();
        CreateAndUpdatePrepaymentPctOnPurchaseOrder(PurchaseHeader);

        // Exercise.
        ModifyPrepaymentPctOnPurchaseHeader(PurchaseHeader, LibraryRandom.RandDec(10, 2));

        // Verify: Verify Purchase Line Prepayment % field with Updated Value.
        VerifyPurchaseLineForPrepaymentPct(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NullPrepaymentPctOnPurchaseOrderAfterUpdateVendorNo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Prepayment % field should be Zero on Purchase Header and Purchase Line after modify Same Vendor No. on Purchase Header.

        // Setup. Create and Update Purchase Header with Prepayment %.
        Initialize();
        CreateAndUpdatePrepaymentPctOnPurchaseOrder(PurchaseHeader);

        // Exericse: Modify Same Vendor No. on Purchase Header to update of Prepayment %.
        ModifyVendorNoOnPurchaseHeader(PurchaseHeader);

        // Verify: Verify Purchase Header and Line for Zero Prepayment %.
        PurchaseHeader.TestField("Prepayment %", 0);
        VerifyPurchaseLineForPrepaymentPct(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineForPrepaymentPct()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check Prepayment % field on Sales Line as same as Sales Header.

        // Create and Update Sales Header with Prepayment % Random Values.
        Initialize();
        CreateAndUpdatePrepaymentPctOnSalesOrder(SalesHeader);

        // Verify: Verify Sales Line for Prepayment % field has correct Prepayment % value as Sales Header.
        VerifySalesLineForPrepaymentPct(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineForPrepaymentPctAfterUpdateSalesHeader()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check Prepayment % field on Purchase Line after Modifying on Purchase Header.

        // Create And Update Sales Order with Prepayment % Random values.
        Initialize();
        CreateAndUpdatePrepaymentPctOnSalesOrder(SalesHeader);

        // Exercise: Modify Sales Header for Prepayment % with Random Values.
        ModifySalesHeaderForPrepaymentPct(SalesHeader, LibraryRandom.RandIntInRange(10, 90));

        // Verify: Verify Sales Line Prepayment % field with Updated Value.
        VerifySalesLineForPrepaymentPct(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NullPrepaymentPctOnSalesOrderAfterUpdateCustomerNo()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check Prepayment % field should be Zero on Sales Header and Line after modify Same Customer No. on Sales Header.

        // Create and Update Sales Header with Prepayment % Random Values.
        Initialize();
        CreateAndUpdatePrepaymentPctOnSalesOrder(SalesHeader);

        // Exericse: Modify Same Customer No. on Sales Header to update of Prepayment %.
        ModifyCustomerNoOnSalesHeader(SalesHeader);

        // Verify: Verify Sales Line and Sales Header Prepayment % field with Zero.
        SalesHeader.TestField("Prepayment %", 0);
        VerifySalesLineForPrepaymentPct(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('PrepaymentConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchasePrepamentInvoiceUsingCopyDocument()
    var
        Currency: Record Currency;
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        GLAccountNo: Code[20];
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        StartingDate: Date;
        PurchasePrepmtAccount: Code[20];
        Amount: Decimal;
    begin
        // Check GL Entry for Posted Prepayment Invoice after Copy document from Purchase Order.

        // Setup: Create Currency with Multiple Exchange rate. 1M is required for difference only 1 Month in each exchange Rate.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();
        CurrencyCode := CreateCurrency();
        StartingDate := CalcDate('<1M>', WorkDate());
        CreateExchangeRate(CurrencyCode, WorkDate());
        CreateExchangeRate(CurrencyCode, StartingDate);

        // Create Purchase Order with Currency.
        PurchasePrepmtAccount := CreatePurchaseOrder(PurchaseHeader, PurchaseLine, GLAccountNo);
        ModifyCurrencyOnPurchaseHeader(PurchaseHeader, CurrencyCode);
        ModifyPurchaseLine(PurchaseLine, CurrencyCode);

        // Post Prepayment Invoice with Purchase Order Page.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseLine."Document No.");
        PurchaseOrder.PostPrepaymentInvoice.Invoke();
        PurchaseOrder.OK().Invoke();

        // Copy Document on New Purchase Order Page with Modify Vendor Invoice No and Posting Date then Post Prepayment Invoice.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader2, PurchaseHeader."Document Type", PurchaseHeader."Buy-from Vendor No.");
        Commit();  // COMMIT is required here.
        PurchaseCopyDocument(PurchaseHeader2, PurchaseHeader."No.", "Purchase Document Type From"::Order);

        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader2."No.");
        PurchaseOrder."Vendor Invoice No.".SetValue(PurchaseOrder."No.".Value);
        PurchaseOrder."Posting Date".SetValue(StartingDate);
        DocumentNo := GetPostedDocumentNo(PurchaseHeader2."Prepayment No. Series");
        PurchaseOrder.PostPrepaymentInvoice.Invoke();
        PurchaseOrder.OK().Invoke();

        // Exercise.
        PurchaseLine.Get(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        Amount := PurchaseLine."Prepmt. Line Amount";

        // Verify: Verify GL Entry for Posted Prepayment Invoice after Copy document.
        Currency.Get(CurrencyCode);
        VerifyGLEntryInFCY(DocumentNo, Amount, GLAccountNo, CurrencyCode, StartingDate);

        // Tear Down:
        UpdatePurchasePrepmtAccount(
          PurchasePrepmtAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('PrepaymentConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesPrepaymentInvoiceUsingCopyDocument()
    var
        Currency: Record Currency;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        GLAccountNo: Code[20];
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        StartingDate: Date;
        SalesPrepmtAccount: Code[20];
        Amount: Decimal;
    begin
        // Check GL Entry for Posted Prepayment Invoice after Copy document from Sales Order.

        // Setup: Create Currency with Multiple Exchange rate. 1M is required for difference only 1 Month in each exchange Rate.
        Initialize();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        CurrencyCode := CreateCurrency();
        StartingDate := CalcDate('<1M>', WorkDate());
        CreateExchangeRate(CurrencyCode, WorkDate());
        CreateExchangeRate(CurrencyCode, StartingDate);

        // Create Sales Order with Currency.
        SalesPrepmtAccount := CreateSalesOrder(SalesHeader, SalesLine, GLAccountNo);
        ModifyCurrencyOnSalesHeader(SalesHeader, CurrencyCode);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);

        // Post Prepayment Invoice with Sales Order Page.
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.PostPrepaymentInvoice.Invoke();
        SalesOrder.OK().Invoke();

        // Copy Document on New Sales Order Page with Modify Posting Date then Post Prepayment Invoice.
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader."Document Type", SalesHeader."Sell-to Customer No.");
        Commit();  // COMMIT is required here.
        SalesCopyDocument(SalesHeader2, SalesHeader."No.", "Sales Document Type From"::Order);

        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader2."No.");
        SalesOrder."Posting Date".SetValue(StartingDate);
        DocumentNo := GetPostedDocumentNo(SalesHeader2."Prepayment No. Series");
        SalesOrder.PostPrepaymentInvoice.Invoke();
        SalesOrder.OK().Invoke();

        // Exercise.
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        Amount := SalesLine."Prepmt. Line Amount";

        // Verify: Verify GL Entry for Posted Prepayment Invoice after Copy document.
        Currency.Get(CurrencyCode);
        VerifyGLEntryInFCY(DocumentNo, -Amount, GLAccountNo, CurrencyCode, StartingDate);

        // Tear Down:
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('PrepaymentConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostedPrepaymenInvoiceLinesOrder()
    var
        SalesHeader: Record "Sales Header";
        Item: array[2] of Record Item;
        SalesOrder: TestPage "Sales Order";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // Check lines in Posted Prepayment Invoice are in the same order as they were in Sales Order.

        // Setup.
        Initialize();
        LibrarySales.SetStockoutWarning(false);

        // Create Sales Order with two lines.
        CreateSOWithTwoPrepmtLines(SalesHeader, Item);

        // Post Prepayment Invoice with Sales Order Page.
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.PostPrepaymentInvoice.Invoke();

        // Verify: Verify lines order in Prepayment Invoice.
        PostedSalesInvoice.Trap();
        SalesOrder.PagePostedSalesPrepaymentInvoices.Invoke();

        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.FILTER.SetFilter("Prepayment Order No.", SalesHeader."No.");
        PostedSalesInvoice.SalesInvLines.First();
        PostedSalesInvoice.SalesInvLines.Description.AssertEquals(Item[1].Description);
        PostedSalesInvoice.SalesInvLines.Next();
        PostedSalesInvoice.SalesInvLines.Description.AssertEquals(Item[2].Description);
    end;

    [Test]
    [HandlerFunctions('PrepaymentConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostedPrepaymentCreditMemoOnSalesOrder()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos";
        SalesOrder: TestPage "Sales Order";
        SalesPrepmtAccount: Code[20];
    begin
        // Check Posted Prepayment Credit Memo exist on Sales Order Page after Posting Prepayment Invoice and Credit Memo from Sales order.

        // Setup: Create Sales Order and Update Sales Prepayment Account.
        Initialize();
        SalesPrepmtAccount := CreateSalesOrder(SalesHeader, SalesLine, LibraryERM.CreateGLAccountWithSalesSetup());

        // Exercise: Post Prepayment Invoice and Prepayment Credit Memo from Sales Order page.
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.PostPrepaymentInvoice.Invoke();
        SalesOrder.PostPrepaymentCreditMemo.Invoke();
        PostedSalesCreditMemos.Trap();
        SalesOrder.PagePostedSalesPrepaymentCrMemos.Invoke();
        PostedSalesCreditMemos.FILTER.SetFilter("Sell-to Customer No.", SalesLine."Sell-to Customer No.");

        // Verify: Verify that Posted Prepayment Credit Memo exist on Posted Sales Credit Memo Page from Sales Order.
        Assert.IsTrue(PostedSalesCreditMemos.First(), PrepaymentCMErr);

        // Tear Down.
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('PrepaymentConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostedPrepaymentCreditMemoOnPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedPurchaseCreditMemos: TestPage "Posted Purchase Credit Memos";
        PurchaseOrder: TestPage "Purchase Order";
        PurchasePrepmtAccount: Code[20];
    begin
        // Check Posted Prepayment Credit Memo exist on Purchase Order Page after Posting Prepayment Invoice and Credit Memo from Purchase order.

        // Setup: Create Purchase Order and Update Purchase Prepayment Account.
        Initialize();
        PurchasePrepmtAccount := CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LibraryERM.CreateGLAccountWithPurchSetup());
        ModifyVendorCreditMemoNoOnPurchaseHeader(PurchaseHeader);

        // Exercise: Post Prepayment Invoice and Prepayment Credit Memo from Purchase Order page.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseLine."Document No.");
        PurchaseOrder.PostPrepaymentInvoice.Invoke();
        PurchaseOrder.PostPrepaymentCreditMemo.Invoke();
        PostedPurchaseCreditMemos.Trap();
        PurchaseOrder.PostedPrepaymentCrMemos.Invoke();
        PostedPurchaseCreditMemos.FILTER.SetFilter("Buy-from Vendor No.", PurchaseLine."Buy-from Vendor No.");

        // Verify: Verify that Posted Prepayment Credit Memo exist on Posted Purchase Credit Memo Page from Purchase Order.
        Assert.IsTrue(PostedPurchaseCreditMemos.First(), PrepaymentCMErr);

        // Tear Down.
        UpdatePurchasePrepmtAccount(
          PurchasePrepmtAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('PrepaymentConfirmHandler')]
    [Scope('OnPrem')]
    procedure ZeroSalesPrePmtAccBalanceAfterPostingMultiplePrePmtInvWithExchRateChange()
    var
        SalesHeader: Record "Sales Header";
        GeneralPostingSetup: Record "General Posting Setup";
        FinalInvoiceNo: Code[20];
        PrepmtInvoice1: Code[20];
        PrepmtInvoice2: Code[20];
        OldSalesPrepaymentsAccount: Code[20];
        ExchangeRateChangeDate: Date;
    begin
        // Verify Prepayment account is balanced out correctly after posting multiple sales prepayment invoices
        // where the currency exchange rate changes before posting the final invoice

        // Setup
        Initialize();
        OldSalesPrepaymentsAccount := CreateSOWithTwoPrepmtLinesAndUpdateGenPostingSetup(SalesHeader, GeneralPostingSetup);
        ExchangeRateChangeDate := CreateExchangeRateOnRndDate(SalesHeader."Currency Code");

        // Exercise
        PrepmtInvoice1 := PostSalesPrepaymentInvoiceForSingleLine(SalesHeader);
        PrepmtInvoice2 := PostSalesPrepaymentInvoiceForSingleLine(SalesHeader);
        FinalInvoiceNo := PostSalesHeader(SalesHeader, ExchangeRateChangeDate);

        // Verify
        VerifyGLAccountBalance(
          GeneralPostingSetup."Sales Prepayments Account", StrSubstNo('%1|%2|%3', PrepmtInvoice1, PrepmtInvoice2, FinalInvoiceNo), 0);

        // Tear Down.
        UpdateSalesPrepmtAccount(
          OldSalesPrepaymentsAccount, GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroSalesPrePmtAccBalanceAfterPostingPrePmtInvWithFCY()
    var
        SalesHeader: Record "Sales Header";
        GeneralPostingSetup: Record "General Posting Setup";
        FinalInvoiceNo: Code[20];
        PrepmtInvoice: Code[20];
        OldSalesPrepaymentsAccount: Code[20];
    begin
        // Verify Prepayment account is balanced out correctly after posting a sales prepayment invoice for multiple lines
        // followed by the final sales invoice in FCY

        // Setup
        Initialize();
        OldSalesPrepaymentsAccount := CreateSOWithTwoPrepmtLinesAndUpdateGenPostingSetup(SalesHeader, GeneralPostingSetup);

        // Exercise
        PrepmtInvoice := PostSalesPrepaymentInvoice(SalesHeader);
        FinalInvoiceNo := PostSalesHeader(SalesHeader, WorkDate());

        // Verify
        VerifyGLAccountBalance(GeneralPostingSetup."Sales Prepayments Account", StrSubstNo('%1|%2', PrepmtInvoice, FinalInvoiceNo), 0);

        // Tear Down.
        UpdateSalesPrepmtAccount(
          OldSalesPrepaymentsAccount, GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('PrepaymentConfirmHandler')]
    [Scope('OnPrem')]
    procedure ZeroSalesPrePmtAccBalanceAfterPostingPrePmtInvAndPrePmtCreditMemoWithFCY()
    var
        SalesHeader: Record "Sales Header";
        GeneralPostingSetup: Record "General Posting Setup";
        PrepmtInvoice1: Code[20];
        PrepmtInvoice2: Code[20];
        PrepmtCreditMemo: Code[20];
        OldSalesPrepaymentsAccount: Code[20];
        ExchangeRateChangeDate: Date;
    begin
        // Verify Prepayment account is balanced out correctly after posting multiple purchase prepayment invoices
        // and a final prepayment credit memo where the currency exchange rate changes before posting the credit memo

        // Setup
        Initialize();
        OldSalesPrepaymentsAccount := CreateSOWithTwoPrepmtLinesAndUpdateGenPostingSetup(SalesHeader, GeneralPostingSetup);
        ExchangeRateChangeDate := CreateExchangeRateOnRndDate(SalesHeader."Currency Code");

        // Exercise
        PrepmtInvoice1 := PostSalesPrepaymentInvoiceForSingleLine(SalesHeader);
        PrepmtInvoice2 := PostSalesPrepaymentInvoiceForSingleLine(SalesHeader);
        PrepmtCreditMemo := PostSalesPrepaymentCreditMemo(SalesHeader, ExchangeRateChangeDate);

        // Verify
        VerifyGLAccountBalance(
          GeneralPostingSetup."Sales Prepayments Account", StrSubstNo('%1|%2|%3', PrepmtInvoice1, PrepmtInvoice2, PrepmtCreditMemo), 0);

        // Tear Down.
        UpdateSalesPrepmtAccount(
          OldSalesPrepaymentsAccount, GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('PrepaymentConfirmHandler')]
    [Scope('OnPrem')]
    procedure ZeroPurchPrePmtAccBalanceAfterPostingMultiplePrePmtInvWithExchRateChange()
    var
        PurchaseHeader: Record "Purchase Header";
        GeneralPostingSetup: Record "General Posting Setup";
        FinalInvoiceNo: Code[20];
        PrepmtInvoice1: Code[20];
        PrepmtInvoice2: Code[20];
        OldPurchPrepaymentsAccount: Code[20];
        ExchangeRateChangeDate: Date;
    begin
        // Verify Prepayment account is balanced out correctly after posting multiple purchase prepayment invoices
        // where the currency exchange rate changes before posting the final invoice

        // Setup
        Initialize();
        OldPurchPrepaymentsAccount := CreatePOWithTwoPrepmtLinesAndUpdateGenPostingSetup(PurchaseHeader, GeneralPostingSetup);
        ExchangeRateChangeDate := CreateExchangeRateOnRndDate(PurchaseHeader."Currency Code");

        // Exercise
        PrepmtInvoice1 := PostPurchPrepaymentInvoiceForSingleLine(PurchaseHeader);
        PrepmtInvoice2 := PostPurchPrepaymentInvoiceForSingleLine(PurchaseHeader);
        FinalInvoiceNo := PostPurchaseHeader(PurchaseHeader, ExchangeRateChangeDate);

        // Verify
        VerifyGLAccountBalance(GeneralPostingSetup."Purch. Prepayments Account",
          StrSubstNo('%1|%2|%3', PrepmtInvoice1, PrepmtInvoice2, FinalInvoiceNo), 0);

        // Tear Down
        UpdatePurchasePrepmtAccount(
          OldPurchPrepaymentsAccount, GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroPurchPrePmtAccBalanceAfterPostingPrePmtInvWithFCY()
    var
        PurchaseHeader: Record "Purchase Header";
        GeneralPostingSetup: Record "General Posting Setup";
        OldPurchPrepaymentsAccount: Code[20];
        FinalInvoiceNo: Code[20];
        PrepmtInvoice: Code[20];
    begin
        // Verify Prepayment account is balanced out correctly after posting a sales prepayment invoice for multiple lines
        // followed by the final sales invoice in FCY

        // Setup
        Initialize();
        OldPurchPrepaymentsAccount := CreatePOWithTwoPrepmtLinesAndUpdateGenPostingSetup(PurchaseHeader, GeneralPostingSetup);

        // Exercise
        PrepmtInvoice := PostPurchasePrepaymentInvoice(PurchaseHeader);
        FinalInvoiceNo := PostPurchaseHeader(PurchaseHeader, WorkDate());

        // Verify
        VerifyGLAccountBalance(GeneralPostingSetup."Purch. Prepayments Account", StrSubstNo('%1|%2', PrepmtInvoice, FinalInvoiceNo), 0);

        // Tear Down
        UpdatePurchasePrepmtAccount(
          OldPurchPrepaymentsAccount, GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('PrepaymentConfirmHandler')]
    [Scope('OnPrem')]
    procedure ZeroPurchPrePmtAccBalanceAfterPostingPrePmtInvAndPrePmtCreditMemoWithFCY()
    var
        PurchaseHeader: Record "Purchase Header";
        GeneralPostingSetup: Record "General Posting Setup";
        PrepmtInvoice1: Code[20];
        PrepmtInvoice2: Code[20];
        PrepmtCreditMemo: Code[20];
        OldPurchPrepaymentsAccount: Code[20];
        ExchangeRateChangeDate: Date;
    begin
        // Verify Prepayment account is balanced out correctly after posting multiple Purchase prepayment invoices
        // and a final prepayment credit memo where the currency exchange rate changes before posting the credit memo

        // Setup
        Initialize();
        OldPurchPrepaymentsAccount := CreatePOWithTwoPrepmtLinesAndUpdateGenPostingSetup(PurchaseHeader, GeneralPostingSetup);
        ExchangeRateChangeDate := CreateExchangeRateOnRndDate(PurchaseHeader."Currency Code");

        // Exercise
        PrepmtInvoice1 := PostPurchPrepaymentInvoiceForSingleLine(PurchaseHeader);
        PrepmtInvoice2 := PostPurchPrepaymentInvoiceForSingleLine(PurchaseHeader);
        PrepmtCreditMemo := PostPurchasePrepaymentCreditMemo(PurchaseHeader, ExchangeRateChangeDate);

        // Verify
        VerifyGLAccountBalance(GeneralPostingSetup."Purch. Prepayments Account",
          StrSubstNo('%1|%2|%3', PrepmtInvoice1, PrepmtInvoice2, PrepmtCreditMemo), 0);

        // Tear Down
        UpdatePurchasePrepmtAccount(
          OldPurchPrepaymentsAccount, GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntriesAfterPurchasePrepaymentInvoice()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        CurrencyCode: Code[10];
        PrepaymentAmountInLCY: Decimal;
    begin
        // Check GL Entry for Posted Purchase Prepayment Invoice with Currency.

        // 1. Setup: Create Prepayment Account on General Posting Setup.
        Initialize();
        CurrencyCode := UpdateAdditionalReportingCurrency();

        // 2. Exercise: Create and Post Purchase Prepayment Invoice with CurrencyExchangeRate.
        PrepaymentAmountInLCY := CreateAndPostPurchasePrepaymentInvoiceWithCurrency(GLAccount, PurchaseHeader, CurrencyCode);

        // 3. Verify: Verify Prepayment Amount on G/L Entry after posting Prepayment.
        FindPurchaseInvoiceHeader(PurchInvHeader, PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Vendor Invoice No.");
        VerifyPrepaymentAmountOnGLEntry(PurchInvHeader."No.", PrepaymentAmountInLCY, GLAccount."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntriesAfterPurchaseInvoice()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        CurrencyCode: Code[10];
        PostedPurchaseDocumentNo: Code[20];
        PrepaymentAmountInLCY: Decimal;
    begin
        // Check GL Entry for Posted Invoice is Posted with Currency after Prepayment Invoice.

        // 1. Setup: Create Prepayment Account and Post Purchase Order.
        Initialize();
        CurrencyCode := UpdateAdditionalReportingCurrency();
        PrepaymentAmountInLCY := CreateAndPostPurchasePrepaymentInvoiceWithCurrency(GLAccount, PurchaseHeader, CurrencyCode);

        // 2. Exercise: Post Purchase Invoice after modifing Vendor Invoice No.
        PostedPurchaseDocumentNo := PostPurchaseDocument(PurchaseHeader, true, true);

        // 3. Verify: Verify Prepayment Amount on G/L Entry after posting Invoice.
        VerifyPrepaymentAmountOnGLEntry(PostedPurchaseDocumentNo, -1 * PrepaymentAmountInLCY, GLAccount."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntriesAfterSalesPrepaymentInvoice()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CurrencyCode: Code[10];
        PrepaymentAmountInLCY: Decimal;
    begin
        // Check GL Entry for Posted Sales Prepayment Invoice with Currency.

        // 1. Setup: Create Prepayment Account on General Posting Setup.
        Initialize();
        CurrencyCode := UpdateAdditionalReportingCurrency();

        // 2. Exercise: Create and Post Sales Prepayment Invoice with CurrencyExchangeRate.
        PrepaymentAmountInLCY := CreateAndPostSalesPrepaymentInvoiceWithCurrency(GLAccount, SalesHeader, CurrencyCode);

        // 3. Verify: Verify Prepayment Amount on G/L Entry after posting Prepayment.
        FindSalesInvoiceHeader(SalesInvoiceHeader, SalesHeader."External Document No.", SalesHeader."Sell-to Customer No.");
        VerifyPrepaymentAmountOnGLEntry(SalesInvoiceHeader."No.", -1 * PrepaymentAmountInLCY, GLAccount."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntriesAfterSalesInvoice()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        PostedSalesDocumentNo: Code[20];
        CurrencyCode: Code[10];
        PrepaymentAmountInLCY: Decimal;
    begin
        // Check GL Entry for Sales Invoice with Currency after Prepayment Invoice.

        // 1. Setup: Create Prepayment Account and Post Purchase Prepayment Invoice.
        Initialize();
        CurrencyCode := UpdateAdditionalReportingCurrency();
        PrepaymentAmountInLCY := CreateAndPostSalesPrepaymentInvoiceWithCurrency(GLAccount, SalesHeader, CurrencyCode);

        // 2. Exercise: Post Purchase Invoice.
        PostedSalesDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 3. Verify: Verify Prepayment Amount on G/L Entry after posting Invoice.
        VerifyPrepaymentAmountOnGLEntry(PostedSalesDocumentNo, PrepaymentAmountInLCY, GLAccount."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepaymentInvoiceACY()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorPostingGroup: Record "Vendor Posting Group";
        CurrencyCode: Code[10];
        PostedPurchaseDocumentNo: Code[20];
        PrepaymentAmountInLCY: Decimal;
    begin
        // Check GL Entry for Posted Purchase Prepayment Invoice with Currency.

        // 1. Setup: Create Prepayment Account on General Posting Setup.
        Initialize();
        CurrencyCode := UpdateAdditionalReportingCurrency();

        // 2. Exercise: Create and Post Purchase Prepayment Invoice with CurrencyExchangeRate.
        PrepaymentAmountInLCY :=
          CreateAndPostPurchasePrepaymentInvoiceWith100Pct(PurchaseHeader, CurrencyCode);
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        SimulatePurchaseRounding(PurchaseHeader."No.", PrepaymentAmountInLCY);
        VendorPostingGroup.Get(PurchaseHeader."Vendor Posting Group");
        PostedPurchaseDocumentNo := PostPurchaseDocument(PurchaseHeader, true, true);

        // 3. Verify: Verify ACY amount is zero on rounding G/L Entry after posting final Invoice.
        VerifyACYAmountOnGLEntry(PostedPurchaseDocumentNo, VendorPostingGroup."Invoice Rounding Account");

        // Tear down.
        UpdateSalesPrepmtAccount('', PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepaymentInvoiceACY()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerPostingGroup: Record "Customer Posting Group";
        CurrencyCode: Code[10];
        PostedSalesDocumentNo: Code[20];
        PrepaymentAmountInLCY: Decimal;
    begin
        // Check GL Entry for Posted Purchase Prepayment Invoice with Currency.

        // 1. Setup: Create Prepayment Account on General Posting Setup.
        Initialize();
        CurrencyCode := UpdateAdditionalReportingCurrency();

        // 2. Exercise: Create and Post Purchase Prepayment Invoice with CurrencyExchangeRate.
        PrepaymentAmountInLCY :=
          CreateAndPostSalesPrepaymentInvoiceWith100Pct(SalesHeader, CurrencyCode);
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        SimulateSalesRounding(SalesHeader."No.", PrepaymentAmountInLCY);
        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");
        PostedSalesDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 3. Verify: Verify ACY amount is zero on rounding G/L Entry after posting final Invoice.
        VerifyACYAmountOnGLEntry(PostedSalesDocumentNo, CustomerPostingGroup."Invoice Rounding Account");

        // Tear down.
        UpdateSalesPrepmtAccount('', SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseFullVATLineAndPrepmtNormalVAT()
    var
        LineGLAccount: Record "G/L Account";
        PrepmtGLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Full VAT] [Purchase]
        // [SCENARIO 361548] Purch. Prepayment Account should have "Full VAT" setup to set "Prepayment %" for "Full VAT" Purchase line
        Initialize();

        // [GIVEN] G/L Account "A" has "Full VAT" setup, G/L Account "PA" is used as Prepayment Account and has "Normal VAT" setup
        LibraryERM.CreatePrepaymentVATSetup(
          LineGLAccount, PrepmtGLAccount, LineGLAccount."Gen. Posting Type"::Purchase,
          "Tax Calculation Type"::"Full VAT", "Tax Calculation Type"::"Normal VAT");
        // [GIVEN] Created Purchase Order line with G/L Account = "A"
        CreatePurchaseOrderWithAccount(PurchaseHeader, PurchaseLine, LineGLAccount, 0);

        // [WHEN] Set "Prepayment %" > 0 on the Purchase Line
        asserterror PurchaseLine.Validate("Prepayment %", 1);
        // [THEN] Error: "VAT Calculation Type" must be "Full VAT" on VAT Posting Setup for prepayment
        Assert.ExpectedTestFieldError(VATPostingSetup.FieldCaption("VAT Calculation Type"), Format(VATPostingSetup."VAT Calculation Type"::"Full VAT"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseNormalVATLineAndPrepmtFullVAT()
    var
        LineGLAccount: Record "G/L Account";
        PrepmtGLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Full VAT] [Purchase]
        // [SCENARIO 361548] Purch. Prepayment Account should have "Normal VAT" setup to set "Prepayment %" for "Normal VAT" Purchase line
        Initialize();

        // [GIVEN] G/L Account "A" has "Normal VAT" setup, G/L Account "PA" is used as Prepayment Account and has "Full VAT" setup
        LibraryERM.CreatePrepaymentVATSetup(
          LineGLAccount, PrepmtGLAccount, LineGLAccount."Gen. Posting Type"::Purchase,
          "Tax Calculation Type"::"Normal VAT", "Tax Calculation Type"::"Full VAT");
        // [GIVEN] Created Purchase Order line with G/L Account = "A"
        CreatePurchaseOrderWithAccount(PurchaseHeader, PurchaseLine, LineGLAccount, 0);

        // [WHEN] Set "Prepayment %" > 0 on the Purchase Line
        asserterror PurchaseLine.Validate("Prepayment %", 1);
        // [THEN] Error: "VAT Calculation Type" must be "Normal VAT" on VAT Posting Setup for prepayment
        Assert.ExpectedTestFieldError(VATPostingSetup.FieldCaption("VAT Calculation Type"), Format(VATPostingSetup."VAT Calculation Type"::"Normal VAT"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmtCrMemoWithFullVATLine()
    var
        LineGLAccount: Record "G/L Account";
        PrepmtGLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Full VAT] [Purchase]
        // [SCENARIO 361548] Purchase Prepayment Credit Memo reverts 100 % Prepayment Invoice for "Full VAT" line
        Initialize();

        // [GIVEN] G/L Account "A" has "Full VAT" setup, G/L Account "PA" is used as Prepayment Account and has "Full VAT" setup
        LibraryERM.CreatePrepaymentVATSetup(
          LineGLAccount, PrepmtGLAccount, LineGLAccount."Gen. Posting Type"::Purchase,
          "Tax Calculation Type"::"Full VAT", "Tax Calculation Type"::"Full VAT");
        // [GIVEN] Created Purchase Order line with G/L Account = "A", "Line Amount" = "X", "Prepayment %" = 100
        CreatePurchaseOrderWithAccount(PurchaseHeader, PurchaseLine, LineGLAccount, 100);

        // [GIVEN] Prepayment Invoice is posted
        PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Prepayment Credit Memo is posted
        PurchaseHeader."Vendor Cr. Memo No." := LibraryPurchase.GegVendorLedgerEntryUniqueExternalDocNo();
        PostPurchasePrepaymentCreditMemo(PurchaseHeader, WorkDate());

        // [THEN] Purchase Order Line: "Prepmt. Amount Inv. (LCY)" = 0, "Prepmt. VAT Amount Inv. (LCY)" = 0
        PurchaseLine.Find();
        Assert.AreEqual(
          0, PurchaseLine."Prepmt. VAT Amount Inv. (LCY)", PurchaseLine.FieldName("Prepmt. VAT Amount Inv. (LCY)"));
        Assert.AreEqual(
          0, PurchaseLine."Prepmt. Amount Inv. (LCY)", PurchaseLine.FieldName("Prepmt. Amount Inv. (LCY)"));
        // [THEN] Posted VAT Entries have "VAT Calculation Type" = "Full VAT", and balance on: Amount = 0, Base = 0
        VerifyVATEntryBalanceWithCalcType(PurchaseLine."Buy-from Vendor No.", "General Posting Type"::Purchase, "Tax Calculation Type"::"Full VAT", 0, 0);
        // [THEN] Balance on Prepayment Account "PA" is zero
        VerifyGLAccountBalance(PrepmtGLAccount."No.", '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmtFinalInvoiceWithFullVATLine()
    var
        LineGLAccount: Record "G/L Account";
        PrepmtGLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Full VAT] [Purchase]
        // [SCENARIO 361548] Fully invoiced Purchase Order reverts 100 % Prepayment Invoice for "Full VAT" line.
        Initialize();

        // [GIVEN] G/L Account "A" has "Full VAT" setup, G/L Account "PA" is used as Prepayment Account and has "Full VAT" setup
        LibraryERM.CreatePrepaymentVATSetup(
          LineGLAccount, PrepmtGLAccount, LineGLAccount."Gen. Posting Type"::Purchase,
          "Tax Calculation Type"::"Full VAT", "Tax Calculation Type"::"Full VAT");
        // [GIVEN] Created Purchase Order line with G/L Account = "A", "Line Amount" = "X", "Prepayment %" = 100
        CreatePurchaseOrderWithAccount(PurchaseHeader, PurchaseLine, LineGLAccount, 100);
        // [GIVEN] Prepayment Invoice is posted
        PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Purchase Order is fully invoiced
        PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Posted VAT Entries have "VAT Calculation Type" = "Full VAT", and balance on: Amount = "X", Base = 0
        VerifyVATEntryBalanceWithCalcType(
          PurchaseLine."Buy-from Vendor No.", "General Posting Type"::Purchase, "Tax Calculation Type"::"Full VAT", 0, PurchaseLine."Prepmt. Line Amount");
        // [THEN] Balance on Prepayment Account "PA" is 0
        VerifyGLAccountBalance(PrepmtGLAccount."No.", '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmtInvoiceWithFullVATLine()
    var
        LineGLAccount: Record "G/L Account";
        PrepmtGLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Full VAT] [Purchase]
        // [SCENARIO 361548] Purchase Prepayment Invoice for "Full VAT" line should post "Full VAT" VAT Entry
        Initialize();

        // [GIVEN] G/L Account "A" has "Full VAT" setup, G/L Account "PA" is used as Prepayment Account and has "Full VAT" setup
        LibraryERM.CreatePrepaymentVATSetup(
          LineGLAccount, PrepmtGLAccount, LineGLAccount."Gen. Posting Type"::Purchase,
          "Tax Calculation Type"::"Full VAT", "Tax Calculation Type"::"Full VAT");
        // [GIVEN] Created Purchase Order line with G/L Account = "A", "Line Amount" = "X", "Prepayment %" = 100
        CreatePurchaseOrderWithAccount(PurchaseHeader, PurchaseLine, LineGLAccount, 100);

        // [WHEN] Prepayment Invoice is posted
        PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] Purchase Line: "Prepmt. Amount Inv. (LCY)" = 0, "Prepmt. VAT Amount Inv. (LCY)" = "X"
        PurchaseLine.Find();
        Assert.AreEqual(
          PurchaseLine."Prepmt. VAT Amount Inv. (LCY)", PurchaseLine."Prepmt. Line Amount",
          PurchaseLine.FieldName("Prepmt. VAT Amount Inv. (LCY)"));
        Assert.AreEqual(
          0, PurchaseLine."Prepmt. Amount Inv. (LCY)", PurchaseLine.FieldName("Prepmt. Amount Inv. (LCY)"));
        // [THEN] Posted VAT Entry has "VAT Calculation Type" = "Full VAT", Amount = "X"
        VerifyVATEntryBalanceWithCalcType(
          PurchaseLine."Buy-from Vendor No.", "General Posting Type"::Purchase, "Tax Calculation Type"::"Full VAT", 0, PurchaseLine."Prepmt. Line Amount");
        // [THEN] Balance on Prepayment Account "PA" is "X"
        VerifyGLAccountBalance(PrepmtGLAccount."No.", '', PurchaseLine."Prepmt. Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmtInvoiceWithFullAndNormalVATLines()
    var
        LineGLAccount: array[2] of Record "G/L Account";
        PrepmtGLAccount: array[2] of Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
    begin
        // [FEATURE] [Full VAT] [Purchase]
        // [SCENARIO 361548] Purchase Prepayment Invoice with "Full VAT" and "Normal VAT" lines should post "Full VAT" and "Normal VAT" VAT entries respectively.
        Initialize();

        // [GIVEN] G/L Account "FA" has "Full VAT" setup, G/L Account "FPA" is used as Prepayment Account and has "Full VAT" setup
        LibraryERM.CreatePrepaymentVATSetup(
          LineGLAccount[1], PrepmtGLAccount[1], LineGLAccount[1]."Gen. Posting Type"::Purchase,
          "Tax Calculation Type"::"Full VAT", "Tax Calculation Type"::"Full VAT");
        // [GIVEN] G/L Account "A" has "Normal VAT" setup, G/L Account "PA" is used as Prepayment Account and has "Normal VAT" setup
        LineGLAccount[2]."Gen. Bus. Posting Group" := PrepmtGLAccount[1]."Gen. Bus. Posting Group";
        LineGLAccount[2]."VAT Bus. Posting Group" := PrepmtGLAccount[1]."VAT Bus. Posting Group";
        LibraryERM.CreatePrepaymentVATSetup(
          LineGLAccount[2], PrepmtGLAccount[2], LineGLAccount[2]."Gen. Posting Type"::Purchase,
          "Tax Calculation Type"::"Normal VAT", "Tax Calculation Type"::"Normal VAT");
        // [GIVEN] Purchase Order, where "Prices Including VAT" = Yes
        PurchaseHeader."Prices Including VAT" := true;
        // [GIVEN] The first line with G/L Account = "FA", "Prepmt. Line Amount" = "X1", "Prepayment %" < 100
        CreatePurchaseOrderWithAccount(PurchaseHeader, PurchaseLine[1], LineGLAccount[1], LibraryRandom.RandIntInRange(10, 90));
        // [GIVEN] The second line with G/L Account = "A", "Prepmt. Line Amount" = "X2", "Prepayment %" < 100
        PurchaseLine[2] := PurchaseLine[1];
        PurchaseLine[2]."Line No." += 10000;
        PurchaseLine[2].Validate("No.", LineGLAccount[2]."No.");
        PurchaseLine[2].Validate("Prepayment %", LibraryRandom.RandIntInRange(10, 90));
        PurchaseLine[2].Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine[2].Insert(true);

        // [WHEN] Prepayment Invoice is posted
        PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] Posted VAT Entry has "VAT Calculation Type" = "Full VAT", Base = 0, Amount = "X1"
        PurchaseLine[1].Find();
        VerifyVATEntryBalanceWithCalcType(
          PurchaseLine[1]."Buy-from Vendor No.", "General Posting Type"::Purchase, "Tax Calculation Type"::"Full VAT",
          PurchaseLine[1]."Prepmt. Amount Inv. (LCY)", PurchaseLine[1]."Prepmt. VAT Amount Inv. (LCY)");
        // [THEN] Posted VAT Entry has "VAT Calculation Type" = "Normal VAT", Base + Amount = "X2"
        PurchaseLine[2].Find();
        VerifyVATEntryBalanceWithCalcType(
          PurchaseLine[2]."Buy-from Vendor No.", "General Posting Type"::Purchase, "Tax Calculation Type"::"Normal VAT",
          PurchaseLine[2]."Prepmt. Amount Inv. (LCY)", PurchaseLine[2]."Prepmt. VAT Amount Inv. (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesFullVATLineAndPrepmtNormalVAT()
    var
        LineGLAccount: Record "G/L Account";
        PrepmtGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Full VAT] [Sales]
        // [SCENARIO 361548] Sales Prepayment Account should have "Full VAT" setup to set "Prepayment %" for "Full VAT" Sales line
        Initialize();

        // [GIVEN] G/L Account "A" has "Full VAT" setup, G/L Account "PA" is used as Prepayment Account and has "Normal VAT" setup
        LibraryERM.CreatePrepaymentVATSetup(
          LineGLAccount, PrepmtGLAccount, LineGLAccount."Gen. Posting Type"::Sale,
          "Tax Calculation Type"::"Full VAT", "Tax Calculation Type"::"Normal VAT");
        // [GIVEN] Created Sales Order line with G/L Account = "A"
        CreateSalesOrderWithAccount(SalesHeader, SalesLine, LineGLAccount, 0);

        // [WHEN] Set "Prepayment %" > 0 on the Sales Line
        asserterror SalesLine.Validate("Prepayment %", 1);
        // [THEN] Error: "VAT Calculation Type" must be "Full VAT" on VAT Posting Setup for prepayment
        Assert.ExpectedTestFieldError(VATPostingSetup.FieldCaption("VAT Calculation Type"), Format(VATPostingSetup."VAT Calculation Type"::"Full VAT"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesNormalVATLineAndPrepmtFullVAT()
    var
        LineGLAccount: Record "G/L Account";
        PrepmtGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Full VAT] [Sales]
        // [SCENARIO 361548] Sales Prepayment Account should have "Normal VAT" setup to set "Prepayment %" for "Normal VAT" Sales line
        Initialize();

        // [GIVEN] G/L Account "A" has "Normal VAT" setup, G/L Account "PA" is used as Prepayment Account and has "Full VAT" setup
        LibraryERM.CreatePrepaymentVATSetup(
          LineGLAccount, PrepmtGLAccount, LineGLAccount."Gen. Posting Type"::Sale,
          "Tax Calculation Type"::"Normal VAT", "Tax Calculation Type"::"Full VAT");
        // [GIVEN] Created Sales Order line with G/L Account = "A"
        CreateSalesOrderWithAccount(SalesHeader, SalesLine, LineGLAccount, 0);

        // [WHEN] Set "Prepayment %" > 0 on the Sales Line
        asserterror SalesLine.Validate("Prepayment %", 1);
        // [THEN] Error: "VAT Calculation Type" must be "Normal VAT" on VAT Posting Setup for prepayment
        Assert.ExpectedTestFieldError(VATPostingSetup.FieldCaption("VAT Calculation Type"), Format(VATPostingSetup."VAT Calculation Type"::"Normal VAT"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtCrMemoWithFullVATLine()
    var
        LineGLAccount: Record "G/L Account";
        PrepmtGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Full VAT] [Sales]
        // [SCENARIO 361548] Sales Prepayment Credit Memo reverts 100 % Prepayment Invoice for "Full VAT" line
        Initialize();

        // [GIVEN] G/L Account "A" has "Full VAT" setup, G/L Account "PA" is used as Prepayment Account and has "Full VAT" setup
        LibraryERM.CreatePrepaymentVATSetup(
          LineGLAccount, PrepmtGLAccount, LineGLAccount."Gen. Posting Type"::Sale,
          "Tax Calculation Type"::"Full VAT", "Tax Calculation Type"::"Full VAT");
        // [GIVEN] Created Sales Order line with G/L Account = "A", "Line Amount" = "X", "Prepayment %" = 100
        CreateSalesOrderWithAccount(SalesHeader, SalesLine, LineGLAccount, 100);

        // [GIVEN] Prepayment Invoice is posted
        PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Prepayment Credit Memo is posted
        PostSalesPrepaymentCreditMemo(SalesHeader, WorkDate());

        // [THEN] Sales Line: "Prepmt. Amount Inv. (LCY)" = 0 , "Prepmt. VAT Amount Inv. (LCY)" = 0
        SalesLine.Find();
        Assert.AreEqual(
          0, SalesLine."Prepmt. VAT Amount Inv. (LCY)", SalesLine.FieldName("Prepmt. VAT Amount Inv. (LCY)"));
        Assert.AreEqual(
          0, SalesLine."Prepmt. Amount Inv. (LCY)", SalesLine.FieldName("Prepmt. Amount Inv. (LCY)"));
        // [THEN] Posted VAT Entries have "VAT Calculation Type" = "Full VAT", and balance on: Amount = 0, Base = 0
        VerifyVATEntryBalanceWithCalcType(SalesLine."Sell-to Customer No.", "General Posting Type"::Sale, "Tax Calculation Type"::"Full VAT", 0, 0);
        // [THEN] Balance on Prepayment Account "PA" is zero
        VerifyGLAccountBalance(PrepmtGLAccount."No.", '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtFinalInvoiceWithFullVATLine()
    var
        LineGLAccount: Record "G/L Account";
        PrepmtGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Full VAT] [Sales]
        // [SCENARIO 361548] Fully invoiced Sales Order reverts 100 % Prepayment Invoice for "Full VAT" line.
        Initialize();

        // [GIVEN] G/L Account "A" has "Full VAT" setup, G/L Account "PA" is used as Prepayment Account and has "Full VAT" setup
        LibraryERM.CreatePrepaymentVATSetup(
          LineGLAccount, PrepmtGLAccount, LineGLAccount."Gen. Posting Type"::Sale,
          "Tax Calculation Type"::"Full VAT", "Tax Calculation Type"::"Full VAT");
        // [GIVEN] Created Sales Order line with G/L Account = "A", "Line Amount" = "X", "Prepayment %" = 100
        CreateSalesOrderWithAccount(SalesHeader, SalesLine, LineGLAccount, 100);
        // [GIVEN] Prepayment Invoice is posted
        PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Sales Order is fully invoiced
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted VAT Entries have "VAT Calculation Type" = "Full VAT", and balance on: Amount = "-X", Base = 0
        VerifyVATEntryBalanceWithCalcType(
          SalesLine."Sell-to Customer No.", "General Posting Type"::Sale, "Tax Calculation Type"::"Full VAT", 0, -SalesLine."Prepmt. Line Amount");
        // [THEN] Balance on Prepayment Account "PA" is 0
        VerifyGLAccountBalance(PrepmtGLAccount."No.", '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtInvoiceWithFullVATLine()
    var
        LineGLAccount: Record "G/L Account";
        PrepmtGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Full VAT] [Sales]
        // [SCENARIO 361548] Sales Prepayment Invoice for "Full VAT" line should post "Full VAT" VAT Entry.
        Initialize();

        // [GIVEN] G/L Account "A" has "Full VAT" setup, G/L Account "PA" is used as Prepayment Account and has "Full VAT" setup
        LibraryERM.CreatePrepaymentVATSetup(
          LineGLAccount, PrepmtGLAccount, LineGLAccount."Gen. Posting Type"::Sale,
          "Tax Calculation Type"::"Full VAT", "Tax Calculation Type"::"Full VAT");
        // [GIVEN] Created Sales Order line with G/L Account = "A", "Line Amount" = "X", "Prepayment %" = 100
        CreateSalesOrderWithAccount(SalesHeader, SalesLine, LineGLAccount, 100);

        // [WHEN] Prepayment Invoice is posted
        PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Sales Line: "Prepmt. Amount Inv. (LCY)" = 0, "Prepmt. VAT Amount Inv. (LCY)" = "X"
        SalesLine.Find();
        Assert.AreEqual(
          SalesLine."Prepmt. VAT Amount Inv. (LCY)", SalesLine."Prepmt. Line Amount",
          SalesLine.FieldName("Prepmt. VAT Amount Inv. (LCY)"));
        Assert.AreEqual(
          0, SalesLine."Prepmt. Amount Inv. (LCY)", SalesLine.FieldName("Prepmt. Amount Inv. (LCY)"));
        // [THEN] Posted VAT Entry has "VAT Calculation Type" = "Full VAT", Amount = "-X"
        VerifyVATEntryBalanceWithCalcType(
          SalesLine."Sell-to Customer No.", "General Posting Type"::Sale, "Tax Calculation Type"::"Full VAT", 0, -SalesLine."Prepmt. Line Amount");
        // [THEN] Balance on Prepayment Account "PA" is "-X"
        VerifyGLAccountBalance(PrepmtGLAccount."No.", '', -SalesLine."Prepmt. Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtInvoiceWithFullAndNormalVATLines()
    var
        LineGLAccount: array[2] of Record "G/L Account";
        PrepmtGLAccount: array[2] of Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
    begin
        // [FEATURE] [Full VAT] [Sales]
        // [SCENARIO 361548] Sales Prepayment Invoice with "Full VAT" and "Normal VAT" lines should post "Full VAT" and "Normal VAT" VAT entries respectively.
        Initialize();

        // [GIVEN] G/L Account "FA" has "Full VAT" setup, G/L Account "FPA" is used as Prepayment Account and has "Full VAT" setup
        LibraryERM.CreatePrepaymentVATSetup(
          LineGLAccount[1], PrepmtGLAccount[1], LineGLAccount[1]."Gen. Posting Type"::Sale,
          "Tax Calculation Type"::"Full VAT", "Tax Calculation Type"::"Full VAT");
        // [GIVEN] G/L Account "A" has "Normal VAT" setup, G/L Account "PA" is used as Prepayment Account and has "Normal VAT" setup
        LineGLAccount[2]."Gen. Bus. Posting Group" := PrepmtGLAccount[1]."Gen. Bus. Posting Group";
        LineGLAccount[2]."VAT Bus. Posting Group" := PrepmtGLAccount[1]."VAT Bus. Posting Group";
        LibraryERM.CreatePrepaymentVATSetup(
          LineGLAccount[2], PrepmtGLAccount[2], LineGLAccount[2]."Gen. Posting Type"::Sale,
          "Tax Calculation Type"::"Normal VAT", "Tax Calculation Type"::"Normal VAT");
        // [GIVEN] Sales Order, where "Prices Including VAT" = Yes
        SalesHeader."Prices Including VAT" := true;
        // [GIVEN] The first line with G/L Account = "FA", "Prepmt. Line Amount" = "X1", "Prepayment %" < 100
        CreateSalesOrderWithAccount(SalesHeader, SalesLine[1], LineGLAccount[1], LibraryRandom.RandIntInRange(10, 90));
        // [GIVEN] The second line with G/L Account = "A", "Prepmt. Line Amount" = "X2", "Prepayment %" < 100
        SalesLine[2] := SalesLine[1];
        SalesLine[2]."Line No." += 10000;
        SalesLine[2].Validate("No.", LineGLAccount[2]."No.");
        SalesLine[2].Validate("Prepayment %", LibraryRandom.RandIntInRange(10, 90));
        SalesLine[2].Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine[2].Insert(true);

        // [WHEN] Prepayment Invoice is posted
        PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Posted VAT Entry has "VAT Calculation Type" = "Full VAT", Base = 0, Amount = "-X1"
        SalesLine[1].Find();
        VerifyVATEntryBalanceWithCalcType(
          SalesLine[1]."Sell-to Customer No.", "General Posting Type"::Sale, "Tax Calculation Type"::"Full VAT",
          -SalesLine[1]."Prepmt. Amount Inv. (LCY)", -SalesLine[1]."Prepmt. VAT Amount Inv. (LCY)");
        // [THEN] Posted VAT Entry has "VAT Calculation Type" = "Normal VAT", Base + Amount = "-X2"
        SalesLine[2].Find();
        VerifyVATEntryBalanceWithCalcType(
          SalesLine[2]."Sell-to Customer No.", "General Posting Type"::Sale, "Tax Calculation Type"::"Normal VAT",
          -SalesLine[2]."Prepmt. Amount Inv. (LCY)", -SalesLine[2]."Prepmt. VAT Amount Inv. (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmt100PctWithSeveralLinesAndDiscount()
    var
        SalesHeader: Record "Sales Header";
        LineGLAccount: Record "G/L Account";
        CurrencyCode: Code[10];
        CustomerNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Currency] [Prices. Incl. VAT] [Rounding]
        // [SCENARIO 361868] Sales Order's partial post produces GLEntry with 0.01 on Receivables Account No.
        Initialize();

        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        SetVATPostingSetupCustomPct(LineGLAccount, 25);
        // [GIVEN] Foreign Customer with currency FCY (3.33FCY = 1 LCY)
        CurrencyCode := CreateCurrency();
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate(), 3.33, 3.33);
        CustomerNo :=
          CreateCustomerWithCurrencyAnd100PrepmtPct(
            LineGLAccount."VAT Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group", CurrencyCode);
        // [GIVEN] Sales Order with 100% prepayment
        CreateSalesHeader(SalesHeader, CustomerNo, true);
        // [GIVEN] Two Sales Order Lines with "Unit Price Incl. VAT" = 50, "VAT %" =  25
        // [GIVEN] Set "Qty. To Ship" = 0 in the first Sales Order Line
        CreateSalesLineWithCustomAmount(SalesHeader, LineGLAccount."No.", 50, 0);
        CreateSalesLineWithCustomAmount(SalesHeader, LineGLAccount."No.", 50, 1);
        // [GIVEN] Post prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post Sales Order
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] GLEntry with Customer's Receivables Account has Amount = 0.01
        VerifyCustomerReceivablesAccountAmount(SalesHeader."Customer Posting Group", DocumentNo, 0.01);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmt100PctWithSeveralLinesAndDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        LineGLAccount: Record "G/L Account";
        CurrencyCode: Code[10];
        VendorNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Currency] [Prices. Incl. VAT] [Rounding]
        // [SCENARIO 361868] Purchase Order's partial post produces GLEntry with -0.01 on Payables Account No.
        Initialize();

        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        SetVATPostingSetupCustomPct(LineGLAccount, 25);
        // [GIVEN] Foreign Vendor with currency FCY (3.33FCY = 1 LCY)
        CurrencyCode := CreateCurrency();
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate(), 3.33, 3.33);
        VendorNo :=
          CreateVendorWithCurrencyAnd100PrepmtPct(
            LineGLAccount."VAT Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group", CurrencyCode);
        // [GIVEN] Purchase Order with 100% prepayment
        CreatePurchaseHeader(PurchaseHeader, VendorNo, true);
        // [GIVEN] Two Purchase Order Lines with "Unit Price Incl. VAT" = 50, "VAT %" =  25
        // [GIVEN] Set "Qty. To Receive" = 0 in the first Purchase Order Line
        CreatePurchaseLineWithCustomAmount(PurchaseHeader, LineGLAccount."No.", 50, 0);
        CreatePurchaseLineWithCustomAmount(PurchaseHeader, LineGLAccount."No.", 50, 1);
        // [GIVEN] Post prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post Purchase Order
        DocumentNo := PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] GLEntry with Vendor's Payables Account has Amount = -0.01
        VerifyVendorPayablesAccountAmount(PurchaseHeader."Vendor Posting Group", DocumentNo, -0.01);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmt100PctWithDiscountSevLinesAndPartialInv()
    var
        SalesHeader: Record "Sales Header";
        LineGLAccount: Record "G/L Account";
        DocumentNo: array[2] of Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Discount] [Prices Incl. VAT] [Rounding]
        // [SCENARIO 363330] Sales Order's partial and final posts produce zero GLEntry "Sales VAT Account" balance in case of 100% Prepayment, Prices Incl. VAT, Discount
        Initialize();
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        SetVATPostingSetupCustomPct(LineGLAccount, 19);

        // [GIVEN] Customer with 100% Prepayment
        CustomerNo :=
          CreateCustomerWithCurrencyAnd100PrepmtPct(
            LineGLAccount."VAT Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group", '');

        // [GIVEN] Sales Order with Prices Incl. VAT, Discount = 3%, VAT = 19% and several lines:
        CreateSalesHeader(SalesHeader, CustomerNo, true);

        // [GIVEN] Line1: Qty = 1, "Unit Price Incl. VAT" = 8.9, QtyToShip = 1
        // [GIVEN] Line2: Qty = 1, "Unit Price Incl. VAT" = 21.9, QtyToShip = 1
        // [GIVEN] Line3: Qty = 2, "Unit Price Incl. VAT" = 24.9, QtyToShip = 1
        // [GIVEN] Line4: Qty = 1, "Unit Price Incl. VAT" = 31.6, QtyToShip = 1
        // [GIVEN] Line5: Qty = 1, "Unit Price Incl. VAT" = 9.6, QtyToShip = 0
        // [GIVEN] Line6: Qty = 1, "Unit Price Incl. VAT" = 185.8, QtyToShip = 1
        CreateCustomSalesLinesScenario363330(SalesHeader, LineGLAccount."No.");

        // [GIVEN] Post prepayment Invoice
        PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Make Partial Post (DocNo1). Post Final Invoice (DocNo2).
        DocumentNo[1] := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        DocumentNo[2] := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] GLEntry "Sales VAT Account" has zero balance filtered by DocNo1
        // [THEN] GLEntry "Sales VAT Account" has zero balance filtered by DocNo2
        VerifySalesVATAccountBalance(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group", DocumentNo[1], 0);
        VerifySalesVATAccountBalance(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group", DocumentNo[2], 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmt100PctWithDiscountSevLinesAndPartialInv()
    var
        PurchaseHeader: Record "Purchase Header";
        LineGLAccount: Record "G/L Account";
        DocumentNo: array[2] of Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Discount] [Prices Incl. VAT] [Rounding]
        // [SCENARIO 363330] Purchase Order's partial and final posts produce zero GLEntry "Purchase VAT Account" balance in case of 100% Prepayment, Prices Incl. VAT, Discount
        Initialize();
        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        SetVATPostingSetupCustomPct(LineGLAccount, 19);

        // [GIVEN] Vendor with 100% Prepayment
        VendorNo :=
          CreateVendorWithCurrencyAnd100PrepmtPct(
            LineGLAccount."VAT Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group", '');

        // [GIVEN] Purchase Order with Prices Incl. VAT, Discount = 3%, VAT = 19% and several lines:
        CreatePurchaseHeader(PurchaseHeader, VendorNo, true);

        // [GIVEN] Line1: Qty = 1, "Unit Price Incl. VAT" = 8.9, QtyToShip = 1
        // [GIVEN] Line2: Qty = 1, "Unit Price Incl. VAT" = 21.9, QtyToShip = 1
        // [GIVEN] Line3: Qty = 2, "Unit Price Incl. VAT" = 24.9, QtyToShip = 1
        // [GIVEN] Line4: Qty = 1, "Unit Price Incl. VAT" = 31.6, QtyToShip = 1
        // [GIVEN] Line5: Qty = 1, "Unit Price Incl. VAT" = 9.6, QtyToShip = 0
        // [GIVEN] Line6: Qty = 1, "Unit Price Incl. VAT" = 185.8, QtyToShip = 1
        CreateCustomPurchaseLinesScenario363330(PurchaseHeader, LineGLAccount."No.");

        // [GIVEN] Post prepayment Invoice
        PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Make Partial Post (DocNo1). Post Final Invoice (DocNo2).
        DocumentNo[1] := PostPurchaseDocument(PurchaseHeader, true, true);
        DocumentNo[2] := PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] GLEntry "Purchase VAT Account" has zero balance filtered by DocNo1
        // [THEN] GLEntry "Purchase VAT Account" has zero balance filtered by DocNo2
        VerifyPurchaseVATAccountBalance(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group", DocumentNo[1], 0);
        VerifyPurchaseVATAccountBalance(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group", DocumentNo[2], 0);
    end;

    [Test]
    [HandlerFunctions('PrepaymentConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesPrepmt100PctWithCurrencySevLinesAndSevExchRates()
    var
        SalesHeader: Record "Sales Header";
        LineGLAccount: Record "G/L Account";
        CurrencyCode: Code[10];
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        NewPostingDate: Date;
    begin
        // [FEATURE] [Sales] [Currency] [Prices Incl. VAT] [Rounding]
        // [SCENARIO 363330] Sales Order's post after Exch. Rate changing produces zero GLEntry "Sales VAT Account" balance in case of 100% Prepayment, Prices Incl. VAT
        Initialize();
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        SetVATPostingSetupCustomPct(LineGLAccount, 8);

        // [GIVEN] Currency with two Exchange Rates. Frmo date "D1": 1.2024, from date "D2": 1.2010.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1.2024, 1.2024);
        NewPostingDate := LibraryRandom.RandDate(10);
        LibraryERM.CreateExchangeRate(CurrencyCode, NewPostingDate, 1.201, 1.201);

        // [GIVEN] Foreign Customer with currency
        CustomerNo :=
          CreateCustomerWithCurrencyAnd100PrepmtPct(
            LineGLAccount."VAT Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group", CurrencyCode);

        // [GIVEN] Sales Order with "Posting Date" = "D1", 100% prepayment
        CreateSalesHeader(SalesHeader, CustomerNo, true);

        // [GIVEN] Two Sales Order Lines with "Unit Price Incl. VAT" = (170.9; 12) "VAT %" =  8
        CreateSalesLineWithCustomAmount(SalesHeader, LineGLAccount."No.", 170.9, 1);
        CreateSalesLineWithCustomAmount(SalesHeader, LineGLAccount."No.", 12, 1);

        // [GIVEN] Post prepayment Invoice
        PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Post Sales Order (Ship)
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Reopen Sales Order. Change "Posting Date" = "D2"
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesHeader.Validate("Posting Date", NewPostingDate);
        SalesHeader.Modify();

        // [WHEN] Post Sales Order (Invoice)
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] GLEntry "Sales VAT Account" has zero balance
        VerifySalesVATAccountBalance(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group", DocumentNo, 0);
    end;

    [Test]
    [HandlerFunctions('PrepaymentConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchPrepmt100PctWithCurrencySevLinesAndSevExchRates()
    var
        PurchaseHeader: Record "Purchase Header";
        LineGLAccount: Record "G/L Account";
        CurrencyCode: Code[10];
        VendorNo: Code[20];
        DocumentNo: Code[20];
        NewPostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Currency] [Prices Incl. VAT] [Rounding]
        // [SCENARIO 363330] Purchase Order's post after Exch. Rate changing produces zero GLEntry "Purchase VAT Account" balance in case of 100% Prepayment, Prices Incl. VAT
        Initialize();
        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        SetVATPostingSetupCustomPct(LineGLAccount, 8);

        // [GIVEN] Currency with two Exchange Rates. Frmo date "D1": 1.2024, from date "D2": 1.2010.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1.2024, 1.2024);
        NewPostingDate := LibraryRandom.RandDate(10);
        LibraryERM.CreateExchangeRate(CurrencyCode, NewPostingDate, 1.201, 1.201);

        // [GIVEN] Foreign Vendor with currency
        VendorNo :=
          CreateVendorWithCurrencyAnd100PrepmtPct(
            LineGLAccount."VAT Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group", CurrencyCode);

        // [GIVEN] Purchase Order with "Posting Date" = "D1", 100% Prepayment
        CreatePurchaseHeader(PurchaseHeader, VendorNo, true);

        // [GIVEN] Two Purchase Order Lines with "Unit Price Incl. VAT" = (170.9; 12) "VAT %" =  8
        CreatePurchaseLineWithCustomAmount(PurchaseHeader, LineGLAccount."No.", 170.9, 1);
        CreatePurchaseLineWithCustomAmount(PurchaseHeader, LineGLAccount."No.", 12, 1);

        // [GIVEN] Post prepayment Invoice
        PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Post Purchase Order (Receipt)
        PostPurchaseDocument(PurchaseHeader, true, false); // Receipt

        // [GIVEN] Reopen Purchase Order, change "Posting Date" = D2
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Validate("Posting Date", NewPostingDate);
        PurchaseHeader.Modify();

        // [WHEN] Post Purchase Order (Invoice)
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true); // Invoice

        // [THEN] GLEntry "Purchase VAT Account" has zero balance
        VerifyPurchaseVATAccountBalance(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group", DocumentNo, 0);
    end;

    [Test]
    [HandlerFunctions('PrepaymentConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesPrepmt100PctWithCurrencySevExchRatesAndNegativeLine()
    var
        SalesHeader: Record "Sales Header";
        LineGLAccount: Record "G/L Account";
        CurrencyCode: Code[10];
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        NewPostingDate: Date;
    begin
        // [FEATURE] [Sales] [Currency] [Prices Incl. VAT] [Discount] [Rounding]
        // [SCENARIO 364573] Final Invoice of Sales Order in FCY with 100% prepayment, where is line discount, a negative line, and changed exch. rate should post zero G/L Entry to "Sales VAT Account"
        Initialize();
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        SetVATPostingSetupCustomPct(LineGLAccount, 8);

        // [GIVEN] Currency with two Exchange Rates. Frmo date "D1": 1.0745, from date "D2": 1.07.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1.0745, 1.0745);
        NewPostingDate := LibraryRandom.RandDate(10);
        LibraryERM.CreateExchangeRate(CurrencyCode, NewPostingDate, 1.07, 1.07);

        // [GIVEN] Foreign Customer with currency
        CustomerNo :=
          CreateCustomerWithCurrencyAnd100PrepmtPct(
            LineGLAccount."VAT Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group", CurrencyCode);

        // [GIVEN] Sales Order with "Posting Date" = "D1", Prices Incl. VAT and several lines:
        CreateSalesHeader(SalesHeader, CustomerNo, true);
        ModifySalesHeaderForPrepaymentPct(SalesHeader, 0);

        // [GIVEN] Line1: Qty = 2, "Unit Price Incl. VAT" = 157.9, "Line Discount %" = 3, "Prepmt. Line Amount" = 256.33
        // [GIVEN] Line2: Qty = 1, "Unit Price Incl. VAT" = 284.9, "Line Discount %" = 3, "Prepmt. Line Amount" = 276.35
        // [GIVEN] Line3: Qty = 1, "Unit Price Incl. VAT" = 11.9, "Line Discount %" = 3, "Prepmt. Line Amount" = 11.54
        // [GIVEN] Line4: Qty = 1, "Unit Price Incl. VAT" = -50, "Line Discount %" = 0, "Prepmt. Line Amount" = 0
        CreateCustomSalesLinesScenario364573(SalesHeader, LineGLAccount."No.");

        // [GIVEN] Post prepayment Invoice
        PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Reopen Sales Order. Change "Posting Date" = "D2"
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesHeader.Validate("Posting Date", NewPostingDate);
        SalesHeader.Modify();

        // [WHEN] Post Sales Order
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] GLEntry "Sales VAT Account" has zero balance
        VerifySalesVATAccountBalance(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group", DocumentNo, 0);
    end;

    [Test]
    [HandlerFunctions('PrepaymentConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchPrepmt100PctWithCurrencySevExchRatesAndNegativeLine()
    var
        PurchaseHeader: Record "Purchase Header";
        LineGLAccount: Record "G/L Account";
        CurrencyCode: Code[10];
        VendorNo: Code[20];
        DocumentNo: Code[20];
        NewPostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Currency] [Prices Incl. VAT] [Discount] [Rounding]
        // [SCENARIO 364573] Final Invoice of Purchase Order in FCY with 100% prepayment, where is line discount, a negative line, and changed exch. rate should post zero G/L Entry to "Purchase VAT Account"
        Initialize();
        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        SetVATPostingSetupCustomPct(LineGLAccount, 8);

        // [GIVEN] Currency with two Exchange Rates. Frmo date "D1": 1.0745, from date "D2": 1.07.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1.0745, 1.0745);
        NewPostingDate := LibraryRandom.RandDate(10);
        LibraryERM.CreateExchangeRate(CurrencyCode, NewPostingDate, 1.07, 1.07);

        // [GIVEN] Foreign Vendor with currency
        VendorNo :=
          CreateVendorWithCurrencyAnd100PrepmtPct(
            LineGLAccount."VAT Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group", CurrencyCode);

        // [GIVEN] Purchase Order with "Posting Date" = "D1", Prices Incl. VAT and several lines:
        CreatePurchaseHeader(PurchaseHeader, VendorNo, true);
        ModifyPrepaymentPctOnPurchaseHeader(PurchaseHeader, 0);

        // [GIVEN] Line1: Qty = 2, "Unit Price Incl. VAT" = 157.9, "Line Discount %" = 3, "Prepmt. Line Amount" = 256.33
        // [GIVEN] Line2: Qty = 1, "Unit Price Incl. VAT" = 289.9, "Line Discount %" = 3, "Prepmt. Line Amount" = 276.35
        // [GIVEN] Line3: Qty = 1, "Unit Price Incl. VAT" = 11.9, "Line Discount %" = 3, "Prepmt. Line Amount" = 11.54
        // [GIVEN] Line4: Qty = 1, "Unit Price Incl. VAT" = -50, "Line Discount %" = 0, "Prepmt. Line Amount" = 0
        CreateCustomPurchaseLinesScenario364573(PurchaseHeader, LineGLAccount."No.");

        // [GIVEN] Post prepayment Invoice
        PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Reopen Purchase Order, change "Posting Date" = D2
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Validate("Posting Date", NewPostingDate);
        PurchaseHeader.Modify();

        // [WHEN] Post Purchase Order
        DocumentNo := PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] GLEntry "Purchase VAT Account" has zero balance
        VerifyPurchaseVATAccountBalance(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group", DocumentNo, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLinePrepaymentAmountAfterPostPrepmt100PctInvAndCrMemo()
    var
        SalesHeader: Record "Sales Header";
        LineGLAccount: Record "G/L Account";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 371514] SalesLine."Prepayment Amount" = 0 after posting 100% Prepayment Invoice and Credit Memo
        Initialize();
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        SetVATPostingSetupCustomPct(LineGLAccount, LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Sales Order with 100% Prepayment Pct.
        CustomerNo :=
          CreateCustomerWithCurrencyAnd100PrepmtPct(
            LineGLAccount."VAT Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group", '');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLineWithCustomAmount(SalesHeader, LineGLAccount."No.", LibraryRandom.RandDecInRange(100, 200, 2), 1);

        // [GIVEN] Post prepayment Invoice
        PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post prepayment Credit Memo
        PostSalesPrepaymentCreditMemo(SalesHeader, WorkDate());

        // [THEN] SalesLine."Prepayment Amount" = 0
        // [THEN] SalesLine."Prepmt. Amt. Incl. VAT" = 0
        VerifySalesLinePrepmtAmt(SalesHeader."Document Type", SalesHeader."No.", 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchLinePrepaymentAmountAfterPostPrepmt100PctInvAndCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        LineGLAccount: Record "G/L Account";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 371514] PurchaseLine."Prepayment Amount" = 0 after posting prepayment 100% Invoice and Credit Memo
        Initialize();
        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        SetVATPostingSetupCustomPct(LineGLAccount, LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Purchase Order with 100% Prepayment Pct.
        VendorNo :=
          CreateVendorWithCurrencyAnd100PrepmtPct(
            LineGLAccount."VAT Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group", '');
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        CreatePurchaseLineWithCustomAmount(PurchaseHeader, LineGLAccount."No.", LibraryRandom.RandDecInRange(100, 200, 2), 1);

        // [GIVEN] Post prepayment Invoice
        PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post prepayment Credit Memo
        PostPurchasePrepaymentCreditMemo(PurchaseHeader, WorkDate());

        // [THEN] PurchaseLine."Prepayment Amount" = 0
        // [THEN] PurchaseLine."Prepmt. Amt. Incl. VAT" = 0
        VerifyPurchLinePrepmtAmt(PurchaseHeader."Document Type", PurchaseHeader."No.", 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmt100PctPostInvCrMemoInvCrMemo()
    var
        SalesHeader: Record "Sales Header";
        LineGLAccount: Record "G/L Account";
        CustomerNo: Code[20];
        PrepmtInvNo: Code[20];
        PrepmtCrMemoNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 371514] Prepayment 100% Invoice and Credit Memo have the same amounts as source Sales Order after posting Invoice -> Credit Memo -> Invoice -> Credit Memo
        Initialize();
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        SetVATPostingSetupCustomPct(LineGLAccount, LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Sales Order with 100% Prepayment Pct. and document Amount = "X", Amount Incl. VAT = "Y"
        CustomerNo :=
          CreateCustomerWithCurrencyAnd100PrepmtPct(
            LineGLAccount."VAT Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group", '');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLineWithCustomAmount(SalesHeader, LineGLAccount."No.", LibraryRandom.RandDecInRange(100, 200, 2), 1);

        // [GIVEN] Post prepayment Invoice[1], Credit Memo[1]
        PostSalesPrepaymentInvoice(SalesHeader);
        PostSalesPrepaymentCreditMemo(SalesHeader, WorkDate());

        // [WHEN] Post prepayment Invoice[2], Credit Memo[2]
        PrepmtInvNo := PostSalesPrepaymentInvoice(SalesHeader);
        PrepmtCrMemoNo := PostSalesPrepaymentCreditMemo(SalesHeader, WorkDate());

        // [THEN] Prepayment Invoice[2] has document Amount = "X", Amount Incl. VAT = "Y"
        // [THEN] Prepayment Cr. Memo[2] has document Amount = "X", Amount Incl. VAT = "Y"
        SalesHeader.CalcFields(Amount, "Amount Including VAT");
        VerifySalesPrepmtInvAmounts(PrepmtInvNo, SalesHeader.Amount, SalesHeader."Amount Including VAT");
        VerifySalesPrepmtCrMemoAmounts(PrepmtCrMemoNo, SalesHeader.Amount, SalesHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmt100PctPostInvCrMemoInvCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        LineGLAccount: Record "G/L Account";
        VendorNo: Code[20];
        PrepmtInvNo: Code[20];
        PrepmtCrMemoNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 371514] Prepayment 100% Invoice and Credit Memo have the same amounts as source Purchase Order after posting Invoice -> Credit Memo -> Invoice -> Credit Memo
        Initialize();
        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        SetVATPostingSetupCustomPct(LineGLAccount, LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Purchase Order with 100% Prepayment Pct. and document Amount = "X", Amount Incl. VAT = "Y"
        VendorNo :=
          CreateVendorWithCurrencyAnd100PrepmtPct(
            LineGLAccount."VAT Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group", '');
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        CreatePurchaseLineWithCustomAmount(PurchaseHeader, LineGLAccount."No.", LibraryRandom.RandDecInRange(100, 200, 2), 1);

        // [GIVEN] Post prepayment Invoice[1], Credit Memo[1]
        PostPurchasePrepaymentInvoice(PurchaseHeader);
        PostPurchasePrepaymentCreditMemo(PurchaseHeader, WorkDate());

        // [WHEN] Post prepayment Invoice[2], Credit Memo[2]
        PrepmtInvNo := PostPurchasePrepaymentInvoice(PurchaseHeader);
        PrepmtCrMemoNo := PostPurchasePrepaymentCreditMemo(PurchaseHeader, WorkDate());

        // [THEN] Prepayment Invoice[2] has document Amount = "X", Amount Incl. VAT = "Y"
        // [THEN] Prepayment Cr. Memo[2] has document Amount = "X", Amount Incl. VAT = "Y"
        PurchaseHeader.CalcFields(Amount, "Amount Including VAT");
        VerifyPurchPrepmtInvAmounts(PrepmtInvNo, PurchaseHeader.Amount, PurchaseHeader."Amount Including VAT");
        VerifyPurchPrepmtCrMemoAmounts(PrepmtCrMemoNo, PurchaseHeader.Amount, PurchaseHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceAndSalesHeaderStatus()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Sales] [Release Document]
        // [SCENARIO 371945] Status of Sales Order should remain "Pending Prepayment" after document posting error when prepayment is posted and "External Document No." is empty.
        Initialize();

        // [GIVEN] Sales & Receivable Setup has option "Ext. Doc. No. Mandatory" set to TRUE.
        LibrarySales.SetExtDocNo(true);

        LibrarySales.CreatePrepaymentVATSetup(GLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesOrderWithAccount(SalesHeader, SalesLine, GLAccount, LibraryRandom.RandIntInRange(10, 90));

        // [GIVEN] Posted Prepayment Invoice. Sales Header has Status "Pending Prepayment".
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Cleared "External Document No." in Sales Header.
        SalesHeader.Validate("External Document No.", '');
        SalesHeader.Modify(true);

        // [WHEN] Post Sales Order (Ship and Invoice). Posting error raises.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales Header has Status "Pending Prepayment".
        SalesHeader.TestField(Status, SalesHeader.Status::"Pending Prepayment");
    end;

    [Test]
    procedure OrderWithPricesInclVAT_CalcInvDiscEnabled_PrepaymentInvoice_Test()
    var
        Customer: Record Customer;
        LineGLAccount: Record "G/L Account";
        Item: Record Item;
        OrderSalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OrderSalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales Prepayment]
        // [SCENARIO] It must be possible to post a prepayment for sales order with an Invoice Discount.
        // The recalculation of the invoice discount must not prevent the posting of the prepayment invoice.
        Initialize();

        // [GIVEN] Calc. Inv. Discount enabled
        SetCalcInvDiscount(true);

        // [GIVEN] G/L Account "A" has "Full VAT" setup, G/L Account "PA" is used as Prepayment Account and has "Full VAT" setup
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, Enum::"Tax Calculation Type"::"Normal VAT");

        // [GIVEN] General Posting Setup is prepared for Inv. Discount 
        UpdateGeneralPostingSetupForSalesInvDiscount(LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."Gen. Prod. Posting Group");

        // [GIVEN] Customer with Inv. Disc. Setup
        CreateCustomerWithInvDiscount(LineGLAccount, Customer);

        // [GIVEN] Item with correct posting setup
        Item.Get(CreateItemWithPostingSetup(LineGLAccount));

        // [GIVEN] Created Sales Order line with Item and "Prepayment %" = 100
        CreatePrepmtSalesOrderFoprItemWith100Percent(Customer, true, Item, OrderSalesHeader, OrderSalesLine);

        // [GIVEN]
        OrderSalesHeader.CalcFields("Recalculate Invoice Disc.");
        Assert.IsTrue(OrderSalesHeader."Recalculate Invoice Disc.", 'The value for the field "Recalculate Invoice Disc." should be true');

        // [WHEN] When Prepayment Invoice is posted
        SalesInvoiceHeader.Get(LibrarySales.PostSalesPrepaymentInvoice(OrderSalesHeader));

        // [THEN] We're happy when there's no error
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmt100PctWithSevLinesAndPartialInv()
    var
        SalesHeader: Record "Sales Header";
        LineGLAccount: Record "G/L Account";
        DocumentNo: array[2] of Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Prices Incl. VAT] [Rounding]
        // [SCENARIO 376112] Sales Order's partial and final posts produce zero GLEntry "Sales VAT Account" balance in case of 100% Prepayment, Prices Incl. VAT
        Initialize();
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        SetVATPostingSetupCustomPct(LineGLAccount, 22);

        // [GIVEN] Customer with 100% Prepayment
        CustomerNo :=
          CreateCustomerWithCurrencyAnd100PrepmtPct(
            LineGLAccount."VAT Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group", '');

        // [GIVEN] Sales Order with Prices Incl. VAT, VAT = 22% and several lines:
        CreateSalesHeader(SalesHeader, CustomerNo, true);
        ModifySalesHeaderCompressPrepmt(SalesHeader, false);

        // [GIVEN] Line1: Qty = 2, "Unit Price Incl. VAT" = 65, QtyToReceipt = 1
        // [GIVEN] Line2: Qty = 1, "Unit Price Incl. VAT" = 6.9, QtyToShip = 1
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, LineGLAccount."No.", 2, 1, 65, 0);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, LineGLAccount."No.", 1, 1, 6.9, 0);

        // [GIVEN] Post prepayment Invoice
        PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Make Partial Post. Post Final Invoice.
        DocumentNo[1] := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        DocumentNo[2] := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] GLEntry "Sales VAT Account" has zero balance
        VerifySalesVATAccountBalance(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group", DocumentNo[1], 0);
        VerifySalesVATAccountBalance(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group", DocumentNo[2], 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmt100PctWithSevLinesAndPartialInv()
    var
        PurchaseHeader: Record "Purchase Header";
        LineGLAccount: Record "G/L Account";
        DocumentNo: array[2] of Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Prices Incl. VAT] [Rounding]
        // [SCENARIO 376112] Purchase Order's partial and final posts produce zero GLEntry "Purchase VAT Account" balance in case of 100% Prepayment, Prices Incl. VAT
        Initialize();
        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        SetVATPostingSetupCustomPct(LineGLAccount, 22);

        // [GIVEN] Vendor with 100% Prepayment
        VendorNo :=
          CreateVendorWithCurrencyAnd100PrepmtPct(
            LineGLAccount."VAT Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group", '');

        // [GIVEN] Purchase Order with Prices Incl. VAT, VAT = 22% and several lines:
        CreatePurchaseHeader(PurchaseHeader, VendorNo, true);
        ModifyPurchHeaderCompressPrepmt(PurchaseHeader, false);

        // [GIVEN] Line1: Qty = 2, "Unit Price Incl. VAT" = 65, QtyToReceipt = 1
        // [GIVEN] Line2: Qty = 1, "Unit Price Incl. VAT" = 6.9, QtyToShip = 1
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, LineGLAccount."No.", 2, 1, 65, 0);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, LineGLAccount."No.", 1, 1, 6.9, 0);

        // [GIVEN] Post prepayment Invoice
        PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Make Partial Post. Post Final Invoice.
        DocumentNo[1] := PostPurchaseDocument(PurchaseHeader, true, true);
        DocumentNo[2] := PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] GLEntry "Purchase VAT Account" has zero balance
        VerifyPurchaseVATAccountBalance(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group", DocumentNo[1], 0);
        VerifyPurchaseVATAccountBalance(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group", DocumentNo[2], 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoCurrAdjmtWhenPostSalesPrepmtWithExchangedLCYDiffMoreThanAmtRoundingPrecision()
    var
        LineGLAccount: Record "G/L Account";
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales] [FCY] [Rounding]
        // [SCENARIO 378671] There is no "Currency Exchange Difference" when post Sales Order with prepayment and exchanged LCY difference more than "Amount Rounding Precision"

        // [GIVEN] Currency Exchange Rate is 1 / 14650.00
        Initialize();
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        SetVATPostingSetupCustomPct(LineGLAccount, 10);
        Currency.Get(CreateCurrency());
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 1 / 14650, 1 / 14650);

        // [GIVEN] Sales Order with FCY, "VAT %" = 10, "Prepayment %" = 33
        CustNo := CreateCustomerWithPostingGroupsAndCurrency(LineGLAccount, Currency.Code, 33);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustNo);

        // [GIVEN] Sales Line with "Quantity" = 1, "Unit Price" = 123.45
        CreateSalesLineWithCustomAmount(SalesHeader, LineGLAccount."No.", 123.45, 1);

        // [GIVEN] Posted prepayment with LCY amount = "Amount Incl. VAT (LCY)"  / (1 + "VAT %" / 100) =  596787.73
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post Sales Order (Prepayment LCY Amount calculated for rounding = "Amount (FCY)" * "Currency Factor" =  596841.00)
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] No G/L Entry posted with "G/L Account No." = "Realized Losses Acc."
        VerifyGLEntryDoesNotExist(DocNo, Currency."Realized Losses Acc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoCurrAdjmtWhenPostPurchPrepmtWithExchangedLCYDiffMoreThanAmtRoundingPrecision()
    var
        LineGLAccount: Record "G/L Account";
        Currency: Record Currency;
        PurchHeader: Record "Purchase Header";
        VendNo: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [FCY] [Rounding]
        // [SCENARIO 378671] There is no "Currency Exchange Difference" when post Purchase Order with prepayment and exchanged LCY difference more than "Amount Rounding Precision"

        // [GIVEN] Currency Exchange Rate is 1 / 14650.00
        Initialize();
        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        SetVATPostingSetupCustomPct(LineGLAccount, 10);
        Currency.Get(CreateCurrency());
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 1 / 14650, 1 / 14650);

        // [GIVEN] Purchase Order with FCY, "VAT %" = 10, "Prepayment %" = 33
        VendNo := CreateVendorWithPostingGroupsAndCurrency(LineGLAccount, Currency.Code, 33);
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendNo);

        // [GIVEN] Purchase Line with "Quantity" = 1, "Unit Price" = 123.45
        CreatePurchaseLineWithCustomAmount(PurchHeader, LineGLAccount."No.", 123.45, 1);

        // [GIVEN] Posted prepayment with LCY amount = "Amount Incl. VAT (LCY)"  / (1 + "VAT %" / 100) =  596787.73
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);

        // [WHEN] Post Purchase Order (Prepayment LCY Amount calculated for rounding = "Amount (FCY)" * "Currency Factor" =  596841.00)
        DocNo := PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] No G/L Entry posted with "G/L Account No." = "Realized Losses Acc."
        VerifyGLEntryDoesNotExist(DocNo, Currency."Realized Losses Acc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmt100PctWithSevLinesPartialInvAndTwoVATSetupsHavingTheSameVATPct()
    var
        SalesHeader: Record "Sales Header";
        GLAccount: array[2] of Record "G/L Account";
        DocumentNo: array[2] of Code[20];
    begin
        // [FEATURE] [Sales] [Prices Incl. VAT] [Rounding]
        // [SCENARIO 205117] Sales Order's partial and final post produce zero GLEntry "Sales VAT Account" balance in case of
        // [SCENARIO 205117] custom several lines, 100% Prepayment, Prices Incl. VAT, two VAT Setups having the same VAT %
        Initialize();

        // [GIVEN] Two VAT Posting Setup both having the same "VAT %"
        CreateSalesPrepaymentVATSetup(GLAccount[1], 19);
        CreatePairedVATPostingSetup(GLAccount[2], GLAccount[1], 19);

        // [GIVEN] Sales order with "Prepayment %" = 100, "Prices Including VAT" = TRUE
        // [GIVEN] Several sales with the first VAT Posting Setup with custom amounts and partial quantity to invoice
        // [GIVEN] Several sales with the second VAT Posting Setup with custom amounts and partial quantity to invoice
        CreateSalesHeader(SalesHeader, CreateCustomerWith100PrepmtPct(GLAccount[1]), true);
        CreateCustomSalesLines_ScenarioSMB205117(SalesHeader, GLAccount[1]."No.", GLAccount[2]."No.");

        // [GIVEN] Post prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        // [GIVEN] Post partial invoice
        DocumentNo[1] := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Post final invoice
        DocumentNo[2] := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] GLEntry "Sales VAT Account" has zero balance for the first partial invoice
        // [THEN] GLEntry "Sales VAT Account" has zero balance for the second final invoice
        VerifySalesVATAccountBalance(GLAccount[1]."VAT Bus. Posting Group", GLAccount[1]."VAT Prod. Posting Group", DocumentNo[1], 0);
        VerifySalesVATAccountBalance(GLAccount[1]."VAT Bus. Posting Group", GLAccount[1]."VAT Prod. Posting Group", DocumentNo[2], 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmt100PctWithSevLinesPartialInvAndTwoVATSetupsHavingTheSameVATPct()
    var
        PurchaseHeader: Record "Purchase Header";
        GLAccount: array[2] of Record "G/L Account";
        DocumentNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase] [Prices Incl. VAT] [Rounding]
        // [SCENARIO 205117] Purchase Order's partial and final post produce zero GLEntry "Purchase VAT Account" balance in case of
        // [SCENARIO 205117] custom several lines, 100% Prepayment, Prices Incl. VAT, two VAT Setups having the same VAT %
        Initialize();

        // [GIVEN] Two VAT Posting Setup both having the same "VAT %"
        CreatePurchasePrepaymentVATSetup(GLAccount[1], 19);
        CreatePairedVATPostingSetup(GLAccount[2], GLAccount[1], 19);

        // [GIVEN] Purchase order with "Prepayment %" = 100, "Prices Including VAT" = TRUE
        // [GIVEN] Several purchase with the first VAT Posting Setup with custom amounts and partial quantity to invoice
        // [GIVEN] Several purchase with the second VAT Posting Setup with custom amounts and partial quantity to invoice
        CreatePurchaseHeader(PurchaseHeader, CreateVendorWith100PrepmtPct(GLAccount[1]), true);
        CreateCustomPurchaseLines_ScenarioSMB205117(PurchaseHeader, GLAccount[1]."No.", GLAccount[2]."No.");

        // [GIVEN] Post prepayment invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        // [GIVEN] Post partial invoice
        DocumentNo[1] := PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Post final invoice
        DocumentNo[2] := PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] GLEntry "Purchase VAT Account" has zero balance for the first partial invoice
        // [THEN] GLEntry "Purchase VAT Account" has zero balance for the second final invoice
        VerifyPurchaseVATAccountBalance(GLAccount[1]."VAT Bus. Posting Group", GLAccount[1]."VAT Prod. Posting Group", DocumentNo[1], 0);
        VerifyPurchaseVATAccountBalance(GLAccount[1]."VAT Bus. Posting Group", GLAccount[1]."VAT Prod. Posting Group", DocumentNo[2], 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmt100PctWithSevLinesPartialInvAndTwoVATSetupsHavingDiffVATPct()
    var
        SalesHeader: Record "Sales Header";
        GLAccount: array[2] of Record "G/L Account";
        DocumentNo: array[2] of Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Prices Incl. VAT] [Rounding]
        // [SCENARIO 205117] Sales Order can be partially and finally posted in case of
        // [SCENARIO 205117] custom several lines, 100% Prepayment, Prices Incl. VAT, two VAT Setups having different VAT %
        Initialize();

        // [GIVEN] Two VAT Posting Setup having different "VAT %"
        CreateSalesPrepaymentVATSetup(GLAccount[1], 19);
        CreatePairedVATPostingSetup(GLAccount[2], GLAccount[1], 10);
        CustomerNo := CreateCustomerWith100PrepmtPct(GLAccount[1]);

        // [GIVEN] Sales order with "Prepayment %" = 100, "Prices Including VAT" = TRUE
        // [GIVEN] Several sales with the first VAT Posting Setup with custom amounts and partial quantity to invoice
        // [GIVEN] Several sales with the second VAT Posting Setup with custom amounts and partial quantity to invoice
        CreateSalesHeader(SalesHeader, CustomerNo, true);
        CreateCustomSalesLines_ScenarioSMB205117(SalesHeader, GLAccount[1]."No.", GLAccount[2]."No.");

        // [GIVEN] Post prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        // [GIVEN] Post partial invoice
        DocumentNo[1] := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Post final invoice
        DocumentNo[2] := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Prepayment/Partial/Final invoices are posted
        // [THEN] Known failure: GLEntry "Sales VAT Account" has non-zero balance for the posted invoices
        asserterror
          VerifySalesVATAccountBalance(GLAccount[1]."VAT Bus. Posting Group", GLAccount[1]."VAT Prod. Posting Group", DocumentNo[1], 0);
        asserterror
          VerifySalesVATAccountBalance(GLAccount[1]."VAT Bus. Posting Group", GLAccount[1]."VAT Prod. Posting Group", DocumentNo[2], 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmt100PctWithSevLinesPartialInvAndTwoVATSetupsHavingDiffVATPct()
    var
        PurchaseHeader: Record "Purchase Header";
        GLAccount: array[2] of Record "G/L Account";
        DocumentNo: array[2] of Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Prices Incl. VAT] [Rounding]
        // [SCENARIO 205117] Purchase Order can be partially and finally posted in case of
        // [SCENARIO 205117] custom several lines, 100% Prepayment, Prices Incl. VAT, two VAT Setups having different VAT %
        Initialize();

        // [GIVEN] Two VAT Posting Setup having different "VAT %"
        CreatePurchasePrepaymentVATSetup(GLAccount[1], 19);
        CreatePairedVATPostingSetup(GLAccount[2], GLAccount[1], 10);
        VendorNo := CreateVendorWith100PrepmtPct(GLAccount[1]);

        // [GIVEN] Purchase order with "Prepayment %" = 100, "Prices Including VAT" = TRUE
        // [GIVEN] Several purchase with the first VAT Posting Setup with custom amounts and partial quantity to invoice
        // [GIVEN] Several purchase with the second VAT Posting Setup with custom amounts and partial quantity to invoice
        CreatePurchaseHeader(PurchaseHeader, VendorNo, true);
        CreateCustomPurchaseLines_ScenarioSMB205117(PurchaseHeader, GLAccount[1]."No.", GLAccount[2]."No.");

        // [GIVEN] Post prepayment invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        // [GIVEN] Post partial invoice
        DocumentNo[1] := PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Post final invoice
        DocumentNo[2] := PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Prepayment/Partial/Final invoices are posted
        // [THEN] Known failure: GLEntry "Purchase VAT Account" has non-zero balance for the posted invoices
        asserterror
          VerifyPurchaseVATAccountBalance(GLAccount[1]."VAT Bus. Posting Group", GLAccount[1]."VAT Prod. Posting Group", DocumentNo[1], 0);
        asserterror
          VerifyPurchaseVATAccountBalance(GLAccount[1]."VAT Bus. Posting Group", GLAccount[1]."VAT Prod. Posting Group", DocumentNo[2], 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmt100PctWithSevLinesPartialInvAndLineDisc()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        DocumentNo: array[2] of Code[20];
    begin
        // [FEATURE] [Sales] [Prices Incl. VAT] [Discount] [Rounding]
        // [SCENARIO 209019] Sales Order can be partially and finally posted in case of
        // [SCENARIO 209019] custom several lines, 100% Prepayment, Prices Incl. VAT, line discount
        Initialize();

        // [GIVEN] Sales Order with "Prepayment %" = 100, "Prices Including VAT" = TRUE, several lines with line discount and custom amounts
        CreateSalesPrepaymentVATSetup(GLAccount, 19);
        CreateSalesHeader(SalesHeader, CreateCustomerWith100PrepmtPct(GLAccount), true);
        CreateCustomSalesLines_ScenarioSMB209019(SalesHeader, GLAccount."No.");

        // [GIVEN] Post prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Post partial invoice
        DocumentNo[1] := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Post final invoice
        DocumentNo[2] := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] GLEntry "Sales VAT Account" has zero balance for both partial and final invoices
        // TFS 217968: Line Discount Amount is recalculated based on current Quantity, Unit Price and Line Discount % on partial posting
        VerifySalesVATAccountBalance(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group", DocumentNo[1], 0);
        VerifySalesVATAccountBalance(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group", DocumentNo[2], 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmt100PctWithSevLinesPartialInvAndLineDisc()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase] [Prices Incl. VAT] [Discount] [Rounding]
        // [SCENARIO 209019] Purchase Order can be partially and finally posted in case of
        // [SCENARIO 209019] custom several lines, 100% Prepayment, Prices Incl. VAT, line discount
        Initialize();

        // [GIVEN] Purchase Order with "Prepayment %" = 100, "Prices Including VAT" = TRUE, several lines with line discount and custom amounts
        CreatePurchasePrepaymentVATSetup(GLAccount, 19);
        CreatePurchaseHeader(PurchaseHeader, CreateVendorWith100PrepmtPct(GLAccount), true);
        CreateCustomPurchaseLines_ScenarioSMB209019(PurchaseHeader, GLAccount."No.");

        // [GIVEN] Post prepayment invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Post partial invoice
        DocumentNo[1] := PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Post final invoice
        DocumentNo[2] := PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] GLEntry "Purchase VAT Account" has zero balance for both partial and final invoices
        // TFS 217968: Line Discount Amount is recalculated based on current Quantity, Unit Price and Line Discount % on partial posting
        VerifyPurchaseVATAccountBalance(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group", DocumentNo[1], 0);
        VerifyPurchaseVATAccountBalance(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group", DocumentNo[2], 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmt100PctWithSevLinesPartialInvAndLineDisc_TwoCentsVATRounding()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        DocumentNo: array[2] of Code[20];
    begin
        // [FEATURE] [Sales] [Prices Excl. VAT] [Discount] [Rounding]
        // [SCENARIO 222044] Sales Order can be partially and finally posted in case of
        // [SCENARIO 222044] custom several lines, 100% Prepayment, Prices Excl. VAT, line discount (Amount rounding = 0, VAT rounding = 0.02)
        Initialize();

        // [GIVEN] Sales Order with "Prepayment %" = 100, "Prices Including VAT" = TRUE, several lines with line discount and custom amounts
        CreateSalesPrepaymentVATSetup(GLAccount, 19);
        CreateSalesHeader(SalesHeader, CreateCustomerWith100PrepmtPct(GLAccount), false);
        CreateCustomSalesLines_ScenarioSMB222044(SalesHeader, GLAccount."No.");

        // [GIVEN] Post prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Post partial invoice
        DocumentNo[1] := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Post final invoice
        DocumentNo[2] := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] GLEntry "Sales VAT Account" has zero balance for both partial and final invoices
        VerifySalesVATAccountBalance(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group", DocumentNo[1], 0.02);
        VerifySalesVATAccountBalance(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group", DocumentNo[2], -0.02);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmt100PctWithSevLinesPartialInvAndLineDisc_TwoCentsVATRounding()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase] [Prices Excl. VAT] [Discount] [Rounding]
        // [SCENARIO 222044] Purchase Order can be partially and finally posted in case of
        // [SCENARIO 222044] custom several lines, 100% Prepayment, Prices Excl. VAT, line discount (Amount rounding = 0, VAT rounding = 0.02)
        Initialize();

        // [GIVEN] Purchase Order with "Prepayment %" = 100, "Prices Including VAT" = FALSE, several lines with line discount and custom amounts
        CreatePurchasePrepaymentVATSetup(GLAccount, 19);
        CreatePurchaseHeader(PurchaseHeader, CreateVendorWith100PrepmtPct(GLAccount), false);
        CreateCustomPurchaseLines_ScenarioSMB222044(PurchaseHeader, GLAccount."No.");

        // [GIVEN] Post prepayment invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Post partial invoice
        DocumentNo[1] := PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Post final invoice
        DocumentNo[2] := PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] GLEntry "Purchase VAT Account" has zero balance for both partial and final invoices
        VerifyPurchaseVATAccountBalance(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group", DocumentNo[1], -0.02);
        VerifyPurchaseVATAccountBalance(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group", DocumentNo[2], 0.02);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmt100PctPartialPostWithLineDiscountAndCustomPrepmtToDeduct()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineGLAccount: Record "G/L Account";
        CustomerNo: Code[20];
        Invoice1: Code[20];
        Invoice2: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 316171] Partially posted sales order with 100% prepayment and line discount has 0 remaining amount in posted sales invoices
        Initialize();

        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        SetVATPostingSetupCustomPct(LineGLAccount, 25);

        // [GIVEN] Sales Order with Prepayment 100%, "Unit Price",261.9547, Quantity = 2 and "Line Discount %" = 1%, VAT % = 25
        // [GIVEN] Amount = 518.67, VAT Amount = 129.67
        CustomerNo := CreateCustomerWith100PrepmtPct(LineGLAccount);
        CreateSalesHeader(SalesHeader, CustomerNo, false);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, LineGLAccount."No.", 2, 2, 261.9547, 1);
        SalesHeader.CalcFields(Amount, "Amount Including VAT");

        // [GIVEN] Post prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Sales Order is posted partially with "Qty. to Ship" = "Qty. to Invoice" = 1, "Prepmt Amt to Deduct" = 259.33
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        SalesLine.Validate("Qty. to Ship", 1);
        SalesLine.Validate("Prepmt Amt to Deduct", 259.33);
        SalesLine.Modify(true);
        Invoice1 := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Post final invoice for the Sales Order
        Invoice2 := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted Sales Invoices has Amount = 0 and Amount Including VAT = 0
        VerifySalesPrepmtInvAmounts(Invoice1, 0, 0);
        VerifySalesPrepmtInvAmounts(Invoice2, 0, 0);
        // [THEN] VAT Entries balance for Base = 518.67, Amount = 129.67
        VerifyVATEntryBalanceWithCalcType(
          CustomerNo, "General Posting Type"::Sale, "Tax Calculation Type"::"Normal VAT",
          -SalesHeader.Amount, -SalesHeader."Amount Including VAT" + SalesHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmt100PctpartialPostWithLineDiscountAndCustomPrepmtToDeduct()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineGLAccount: Record "G/L Account";
        VendorNo: Code[20];
        Invoice1: Code[20];
        Invoice2: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 316171] Partially posted purchase order with 100% prepayment and line discount has 0 remaining amount in posted purchase invoices
        Initialize();

        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        SetVATPostingSetupCustomPct(LineGLAccount, 25);

        // [GIVEN] Purchase Order with Prepayment 100%, "Unit Price",261.9547, Quantity = 2 and "Line Discount %" = 1%, VAT % = 25
        // [GIVEN] Amount = 518.67, VAT Amount = 129.67
        VendorNo := CreateVendorWith100PrepmtPct(LineGLAccount);
        CreatePurchaseHeader(PurchaseHeader, VendorNo, false);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, LineGLAccount."No.", 2, 2, 261.9547, 1);
        PurchaseHeader.CalcFields(Amount, "Amount Including VAT");

        // [GIVEN] Post prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Purchase Order is posted partially with "Qty. to Ship" = "Qty. to Invoice" = 1, "Prepmt Amt to Deduct" = 259.33
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLine.Validate("Qty. to Receive", 1);
        PurchaseLine.Validate("Prepmt Amt to Deduct", 259.33);
        PurchaseLine.Modify(true);
        Invoice1 := PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Post final invoice for the Purchase Order
        Invoice2 := PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Posted Purchase Invoices has Amount = 0 and Amount Including VAT = 0
        VerifyPurchPrepmtInvAmounts(Invoice1, 0, 0);
        VerifyPurchPrepmtInvAmounts(Invoice2, 0, 0);
        // [THEN] VAT Entries balance for Base = 518.67, Amount = 129.67
        VerifyVATEntryBalanceWithCalcType(
          VendorNo, "General Posting Type"::Purchase, "Tax Calculation Type"::"Normal VAT",
          PurchaseHeader.Amount, PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletingSalesInvoiceLineCreatedWithGetShipmentLinesWhenPremptPosted()
    var
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLineOrder: Record "Sales Line";
        SalesLineInvoice: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        SalesShipmentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Order] [Invoice] [Get Shipment Lines]
        // [SCENARIO 335549] You can delete sales invoice line created with "Get Shipment Line" for the shipped order with posted prepayment.
        Initialize();

        // [GIVEN] Sales order set up for 100% prepayment.
        CreateSalesOrder(SalesHeaderOrder, SalesLineOrder, LibraryERM.CreateGLAccountWithSalesSetup());

        // [GIVEN] Post the prepayment invoice.
        PostSalesPrepaymentInvoice(SalesHeaderOrder);

        // [GIVEN] Ship the sales order.
        SalesShipmentNo := LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        // [GIVEN] Create a new sales invoice.
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeaderOrder."Sell-to Customer No.");

        // [GIVEN] Create a sales invoice line from the shipped line via "Get Shipment Lines".
        SalesShipmentLine.SetRange("Document No.", SalesShipmentNo);
        SalesGetShipment.SetSalesHeader(SalesHeaderInvoice);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
        SalesLineInvoice.SetRange("No.", SalesLineOrder."No.");
        LibrarySales.FindFirstSalesLine(SalesLineInvoice, SalesHeaderInvoice);

        // [WHEN] Delete the sales invoice line.
        SalesLineInvoice.Delete(true);

        // [THEN] The sales invoice line has been deleted.
        Assert.RecordIsEmpty(SalesLineInvoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletingPurchaseInvoiceLineCreatedWithGetReceiptLinesWhenPremptPosted()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        PurchRcptNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Order] [Invoice] [Get Receipt Lines]
        // [SCENARIO 335549] You can delete purchase invoice line created with "Get Receipt Line" for the received order with posted prepayment.
        Initialize();

        // [GIVEN] Purchase order set up for 100% prepayment.
        CreatePurchaseOrder(PurchaseHeaderOrder, PurchaseLineOrder, LibraryERM.CreateGLAccountWithPurchSetup());

        // [GIVEN] Post the prepayment invoice.
        PostPurchasePrepaymentInvoice(PurchaseHeaderOrder);

        // [GIVEN] Receive the purchase order.
        PurchRcptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // [GIVEN] Create a new purchase invoice.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, PurchaseHeaderOrder."Buy-from Vendor No.");

        // [GIVEN] Create a purchase invoice line from the received line via "Get Receipt Lines".
        PurchRcptLine.SetRange("Document No.", PurchRcptNo);
        PurchGetReceipt.SetPurchHeader(PurchaseHeaderInvoice);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
        PurchaseLineInvoice.SetRange("No.", PurchaseLineOrder."No.");
        LibraryPurchase.FindFirstPurchLine(PurchaseLineInvoice, PurchaseHeaderInvoice);

        // [WHEN] Delete the purchase invoice line.
        PurchaseLineInvoice.Delete(true);

        // [THEN] The purchase invoice line has been deleted.
        Assert.RecordIsEmpty(PurchaseLineInvoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourcePurchaseLineForPrepaymentPct()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Resource: Record Resource;
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Verify prepayment % for resource purchase line
        Initialize();

        // [GIVEN] Purchase order with prepayment %
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(10, 90));
        PurchaseHeader.Modify(true);

        // [WHEN] Add resource purchase order line
        Resource.Get(LibraryResource.CreateResourceNo());
        UpdatePrepmtPostGroups(
            PurchaseHeader."Gen. Bus. Posting Group", Resource."Gen. Prod. Posting Group", Resource."VAT Prod. Posting Group");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, Resource."No.", 1);

        // [THEN] Resource purchase line has the same prepayment % as purchase header
        VerifyPurchaseLineForPrepaymentPct(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPrepaymentForResourcePurchaseLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Post purchase order and prepayment invoice for resource purchase line
        Initialize();

        // [GIVEN] Purchase order with resource line and posted preapyment invoice
        CreatePurchaseOrderWithResourceLineAndPrepayment(PurchaseHeader, PurchaseLine, GLAccountNo);

        // [WHEN] Finally post purchase order
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L entry with GLAccountNo exists
        VerifyGLEntry(DocumentNo, -(PurchaseLine.Amount / 100 * PurchaseLine."Prepayment %"), GLAccountNo, LibraryERM.GetAmountRoundingPrecision());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPrepaymentInvoiceContainsOrderNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PrepmtInvoiceNo: Code[20];
    begin
        // [SCENARIO 556205] The Order No. field is not being transferred to the Prepayment Invoices as it gets transferred to the Posted Invoices.
        Initialize();

        // [GIVEN] Create Purchase Order
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LibraryERM.CreateGLAccountWithPurchSetup());

        // [WHEN] Post Prepayment Invoice
        PrepmtInvoiceNo := PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] Oreder No. should be filled on posted prepayment invoice.
        PurchInvHeader.Get(PrepmtInvoiceNo);
        Assert.AreEqual(PurchaseHeader."No.", PurchInvHeader."Order No.", PurchInvHeader.FieldName("Order No."));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Prepayment IV");
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Prepayment IV");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Prepayment IV");
    end;

    local procedure SetCalcInvDiscount(CalcInvDiscount: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", CalcInvDiscount);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateGeneralPostingSetupForSalesInvDiscount(GenBusPosingGroup: Code[20]; GenProdPosingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPosingGroup, GenProdPosingGroup);
        if GeneralPostingSetup."Sales Inv. Disc. Account" = '' then
            GeneralPostingSetup.Validate("Sales Inv. Disc. Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateCustomerWithInvDiscount(LineGLAccount: Record "G/L Account"; var Customer: Record Customer)
    begin
        Customer.Get(CreateCustomerWithPostingGroups(LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group"));
        CreateCustomerInvDiscount(Customer."No.");
    end;

    local procedure CreateCustomerInvDiscount(CustomerNo: Code[20]): Code[20]
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', 0);  // Set Zero for Charge Amount.
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));  // Take Random Discount.
        CustInvoiceDisc.Modify(true);
        exit(CustomerNo);
    end;

    local procedure CreateItemWithPostingSetup(LineGLAccount: Record "G/L Account"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", 10 * LibraryRandom.RandDec(99, 3));
        Item.Validate("Gen. Prod. Posting Group", LineGLAccount."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePrepmtSalesOrderFoprItemWith100Percent(Customer: Record Customer; PriceInclVat: Boolean; Item: Record Item; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        CreatePrepmtSalesOrder(Customer, PriceInclVat, 100, SalesLine.Type::Item, Item."No.", SalesHeader, SalesLine);
    end;

    local procedure CreatePrepmtSalesOrder(Customer: Record Customer; PriceInclVat: Boolean; PrepaymentPercent: Decimal; SalesLineType: Enum "Sales Line Type"; No: Code[20]; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Prices Including VAT", PriceInclVat);
        SalesHeader.Validate("Prepayment %", PrepaymentPercent);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLineType, No, LibraryRandom.RandInt(50));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateCustomSalesLinesScenario363330(SalesHeader: Record "Sales Header"; LineGLAccountNo: Code[20])
    begin
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, LineGLAccountNo, 1, 1, 8.9, 3);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, LineGLAccountNo, 1, 1, 21.9, 3);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, LineGLAccountNo, 2, 1, 24.9, 3);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, LineGLAccountNo, 1, 1, 31.6, 3);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, LineGLAccountNo, 1, 0, 9.6, 3);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, LineGLAccountNo, 1, 1, 185.8, 3);
    end;

    local procedure CreateCustomPurchaseLinesScenario363330(PurchaseHeader: Record "Purchase Header"; LineGLAccountNo: Code[20])
    begin
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, LineGLAccountNo, 1, 1, 8.9, 3);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, LineGLAccountNo, 1, 1, 21.9, 3);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, LineGLAccountNo, 2, 1, 24.9, 3);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, LineGLAccountNo, 1, 1, 31.6, 3);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, LineGLAccountNo, 1, 0, 9.9, 3);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, LineGLAccountNo, 1, 1, 185.8, 3);
    end;

    local procedure CreateCustomSalesLinesScenario364573(SalesHeader: Record "Sales Header"; LineGLAccountNo: Code[20])
    begin
        CreateSalesLineWithCustomDiscountAndPrepmtAmount(SalesHeader, LineGLAccountNo, 2, 157.9, 3, 256.33);
        CreateSalesLineWithCustomDiscountAndPrepmtAmount(SalesHeader, LineGLAccountNo, 1, 284.9, 3, 276.35);
        CreateSalesLineWithCustomDiscountAndPrepmtAmount(SalesHeader, LineGLAccountNo, 1, 11.9, 3, 11.54);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, LineGLAccountNo, 1, 1, -50, 0);
    end;

    local procedure CreateCustomPurchaseLinesScenario364573(PurchaseHeader: Record "Purchase Header"; LineGLAccountNo: Code[20])
    begin
        CreatePurchaseLineWithCustomDiscountAndPrepmtAmount(PurchaseHeader, LineGLAccountNo, 2, 157.9, 3, 256.33);
        CreatePurchaseLineWithCustomDiscountAndPrepmtAmount(PurchaseHeader, LineGLAccountNo, 1, 284.9, 3, 276.35);
        CreatePurchaseLineWithCustomDiscountAndPrepmtAmount(PurchaseHeader, LineGLAccountNo, 1, 11.9, 3, 11.54);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, LineGLAccountNo, 1, 1, -50, 0);
    end;

    local procedure CreateCustomSalesLines_ScenarioSMB205117(SalesHeader: Record "Sales Header"; GLAccountNo1: Code[20]; GLAccountNo2: Code[20])
    begin
        CreateSalesLineWithCustomAmount(SalesHeader, GLAccountNo1, 101.5189, 1);
        CreateSalesLineWithCustomAmount(SalesHeader, GLAccountNo1, 71.1858, 1);
        CreateSalesLineWithCustomAmount(SalesHeader, GLAccountNo1, 387.8448, 0.5);
        CreateSalesLineWithCustomAmount(SalesHeader, GLAccountNo1, 215.4495, 1);
        CreateSalesLineWithCustomAmount(SalesHeader, GLAccountNo1, 139.3252, 1);
        CreateSalesLineWithCustomAmount(SalesHeader, GLAccountNo2, 9.9, 1);
        CreateSalesLineWithCustomAmount(SalesHeader, GLAccountNo2, 9.9, 0);
    end;

    local procedure CreateCustomPurchaseLines_ScenarioSMB205117(PurchaseHeader: Record "Purchase Header"; GLAccountNo1: Code[20]; GLAccountNo2: Code[20])
    begin
        CreatePurchaseLineWithCustomAmount(PurchaseHeader, GLAccountNo1, 101.5189, 1);
        CreatePurchaseLineWithCustomAmount(PurchaseHeader, GLAccountNo1, 71.1858, 1);
        CreatePurchaseLineWithCustomAmount(PurchaseHeader, GLAccountNo1, 387.8448, 0.5);
        CreatePurchaseLineWithCustomAmount(PurchaseHeader, GLAccountNo1, 215.4495, 1);
        CreatePurchaseLineWithCustomAmount(PurchaseHeader, GLAccountNo1, 139.3252, 1);
        CreatePurchaseLineWithCustomAmount(PurchaseHeader, GLAccountNo2, 9.9, 1);
        CreatePurchaseLineWithCustomAmount(PurchaseHeader, GLAccountNo2, 9.9, 0);
    end;

    local procedure CreateCustomSalesLines_ScenarioSMB209019(SalesHeader: Record "Sales Header"; GLAccountNo: Code[20])
    begin
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 4, 4, 231.2765, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 4, 4, 93.3079, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 15.9341, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 252.1967, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 131.0071, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 293.7396, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 3, 3, 199.2417, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 4, 4, 211.939, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 2, 2, 80.6344, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 4, 1, 226.3975, 4);

        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 2, 2, 2.3443, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 4, 4, 75.8863, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 4.9504, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 377.0872, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 37.5445, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 85.8585, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 13.1257, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 71.6856, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 94.5336, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 78.0283, 4);

        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 122.094, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 5, 1, 186.9252, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 224.2198, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 3, 3, 16.5529, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 2, 2, 15.0059, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 364.5803, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 3, 3, 72.6733, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 4, 3, 107.1238, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 423.0688, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 171.9312, 4);

        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 172.4786, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 129.8766, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 2, 2, 136.3978, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 2, 2, 132.447, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 2, 2, 150.4398, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 893.9042, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 480.3435, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 2, 2, 36.3902, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 151.6655, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 157.0919, 4);

        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 152.1772, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 46.1482, 4);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 4, 4, 5.95, 4);
    end;

    local procedure CreateCustomPurchaseLines_ScenarioSMB209019(PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20])
    begin
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 4, 4, 231.2765, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 4, 4, 93.3079, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 15.9341, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 252.1967, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 131.0071, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 293.7396, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 3, 3, 199.2417, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 4, 4, 211.939, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 2, 2, 80.6344, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 4, 1, 226.3975, 4);

        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 2, 2, 2.3443, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 4, 4, 75.8863, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 4.9504, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 377.0872, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 37.5445, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 85.8585, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 13.1257, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 71.6856, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 94.5336, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 78.0283, 4);

        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 122.094, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 5, 1, 186.9252, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 224.2198, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 3, 3, 16.5529, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 2, 2, 15.0059, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 364.5803, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 3, 3, 72.6733, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 4, 3, 107.1238, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 423.0688, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 171.9312, 4);

        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 172.4786, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 129.8766, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 2, 2, 136.3978, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 2, 2, 132.447, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 2, 2, 150.4398, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 893.9042, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 480.3435, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 2, 2, 36.3902, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 151.6655, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 157.0919, 4);

        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 152.1772, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 46.1482, 4);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 4, 4, 5.95, 4);
    end;

    local procedure CreateCustomSalesLines_ScenarioSMB222044(SalesHeader: Record "Sales Header"; GLAccountNo: Code[20])
    begin
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 16, 0, 22.95, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 16, 13, 10.43, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 16, 16, 11.85, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 16, 6, 38.98, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 16, 6, 68.26, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 16, 16, 15.52, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 16, 6, 573.2, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 16, 16, 43.22, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 16, 16, 18.75, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 18, 18, 2.99, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 18, 18, 106.17, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 18, 18, 201.94, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 16, 0, 129.2, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 22, 8, 41.04, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 17, 17, 50.82, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 16, 16, 2.8, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 16, 9, 247.92, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 29, 0);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 7.5, 0);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 3.23, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 28.18, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 2, 2, 85.9, 0);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 0, 259, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 4.03, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 109.31, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 248.45, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 1, 144.57, 5);
        CreateSalesLineWithCustomDiscountAmount(SalesHeader, GLAccountNo, 1, 0, 122.4, 5);
    end;

    local procedure CreateCustomPurchaseLines_ScenarioSMB222044(PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20])
    begin
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 16, 0, 22.95, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 16, 13, 10.43, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 16, 16, 11.85, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 16, 6, 38.98, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 16, 6, 68.26, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 16, 16, 15.52, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 16, 6, 573.2, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 16, 16, 43.22, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 16, 16, 18.75, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 18, 18, 2.99, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 18, 18, 106.17, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 18, 18, 201.94, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 16, 0, 129.2, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 22, 8, 41.04, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 17, 17, 50.82, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 16, 16, 2.8, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 16, 9, 247.92, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 29, 0);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 7.5, 0);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 3.23, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 28.18, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 2, 2, 85.9, 0);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 0, 259, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 4.03, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 109.31, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 248.45, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 1, 144.57, 5);
        CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader, GLAccountNo, 1, 0, 122.4, 5);
    end;

    local procedure CreateAndPostSalesPrepaymentInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; AccountNo: Code[20]) SalesPrepmtAccount: Code[20]
    begin
        SalesPrepmtAccount := CreateSalesOrder(SalesHeader, SalesLine, AccountNo);
        PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        ModifyQtyToShipOnSalesLine(SalesLine);
    end;

    local procedure CreateAndPostPurchasePrepaymentInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; AccountNo: Code[20]) PurchasePrepmtAccount: Code[20]
    begin
        PurchasePrepmtAccount := CreatePurchaseOrder(PurchaseHeader, PurchaseLine, AccountNo);
        PostPurchasePrepaymentInvoice(PurchaseHeader);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        ModifyQtyToReceiveOnPurchaseLine(PurchaseLine);
    end;

    local procedure CreateAndUpdatePrepaymentPctOnSalesOrder(var SalesHeader: Record "Sales Header")
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        // Setup. Create Sales Header with Prepayment % Random Values.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        ModifySalesHeaderForPrepaymentPct(SalesHeader, LibraryRandom.RandIntInRange(10, 90));

        // Exercise: Create Sales Line with Zero Quantity.
        Item.Get(LibraryInventory.CreateItemNo());
        UpdatePrepmtPostGroups(SalesHeader."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group", Item."VAT Prod. Posting Group");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);
    end;

    local procedure CreateAndUpdatePrepaymentPctOnPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // Setup: Create and Modify Purchase Header for Prepayment %.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        ModifyPrepaymentPctOnPurchaseHeader(PurchaseHeader, LibraryRandom.RandIntInRange(10, 90));

        // Exercise: Create Purchase Line with Zero Quantity.
        Item.Get(LibraryInventory.CreateItemNo());
        UpdatePrepmtPostGroups(PurchaseHeader."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group", Item."VAT Prod. Posting Group");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 0);
    end;

    local procedure CreateAndModifyCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithPostingGroups(GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendorWithPostingGroups(GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateCustWithCurrencyAndVATBusPostingGroup(CurrencyCode: Code[10]; VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendorWithCurrencyAndVATBusPostingGroup(CurrencyCode: Code[10]; VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; GLAccountNo: Code[20]) SalesPrepmtAccount: Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
    begin
        // Taken Random Values for Quantity, Unit Price and Prepayment %.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CreateAndModifyCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(10, 40)); // make sure values are big enough, so amounts are not close to rounding precision
        SalesHeader.Modify(true);
        LibraryInventory.CreateItem(Item);
        CreateNewGenProductPostingGroupOnItem(SalesHeader."Gen. Bus. Posting Group", Item);
        SalesPrepmtAccount :=
          UpdateSalesPrepmtAccount(GLAccountNo, SalesHeader."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        CreateSalesLineItem(SalesLine, SalesHeader, Item."No.");
        exit(SalesPrepmtAccount);
    end;

    local procedure CreateSalesOrderWithAccount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LineGLAccount: Record "G/L Account"; LinePrepmtPct: Decimal)
    var
        CustomerNo: Code[20];
        PricesIncludingVAT: Boolean;
    begin
        CustomerNo :=
          CreateCustomerWithPostingGroups(
            LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");

        PricesIncludingVAT := SalesHeader."Prices Including VAT";
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        SalesHeader.Modify(true);

        CreateSalesLineGL(SalesLine, SalesHeader, LineGLAccount."No.");
        if LinePrepmtPct <> 0 then
            SalesLine.Validate("Prepayment %", LinePrepmtPct);
        SalesLine.Modify(true);
    end;

    local procedure CreateSOWithTwoPrepmtLinesAndUpdateGenPostingSetup(var SalesHeader: Record "Sales Header"; var GeneralPostingSetup: Record "General Posting Setup") OldSalesPrepaymentsAccountNo: Code[20]
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CurrencyCode: Code[10];
    begin
        // Create Sales Order with two prepayment lines
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Item.Get(LibraryInventory.CreateItemNo());
        CurrencyCode := CreateCurrency();
        CreateExchangeRate(CurrencyCode, WorkDate());
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order,
          CreateCustWithCurrencyAndVATBusPostingGroup(CurrencyCode, VATPostingSetup."VAT Bus. Posting Group"));
        UpdatePrepmtPostGroups(SalesHeader."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group", Item."VAT Prod. Posting Group");
        CreateSalesLineWithPrepmtPercentage(SalesLine, SalesHeader, Item."No.", LibraryRandom.RandIntInRange(10, 40));
        CreateSalesLineWithPrepmtPercentage(SalesLine, SalesHeader, Item."No.", SalesLine."Prepayment %" + LibraryRandom.RandIntInRange(10, 40));

        // Update Sales Prepayment Account
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        OldSalesPrepaymentsAccountNo := GeneralPostingSetup."Sales Prepayments Account";
        GeneralPostingSetup."Sales Prepayments Account" :=
          CreateBalanceSheetAccount(
            SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreatePOWithTwoPrepmtLinesAndUpdateGenPostingSetup(var PurchaseHeader: Record "Purchase Header"; var GeneralPostingSetup: Record "General Posting Setup") OldPurchasePrepaymentsAccountNo: Code[20]
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CurrencyCode: Code[10];
    begin
        // Create Purchase Order with two prepayment lines
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Item.Get(LibraryInventory.CreateItemNo());
        CurrencyCode := CreateCurrency();
        CreateExchangeRate(CurrencyCode, WorkDate());
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          CreateVendorWithCurrencyAndVATBusPostingGroup(CurrencyCode, VATPostingSetup."VAT Bus. Posting Group"));
        UpdatePrepmtPostGroups(PurchaseHeader."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group", Item."VAT Prod. Posting Group");
        CreatePurchaseLineWithPrepmtPercentage(PurchaseLine, PurchaseHeader, Item."No.", LibraryRandom.RandIntInRange(10, 40));
        CreatePurchaseLineWithPrepmtPercentage(
          PurchaseLine, PurchaseHeader, Item."No.", PurchaseLine."Prepayment %" + LibraryRandom.RandIntInRange(10, 40));

        // Update Purchase Prepayment Account
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        OldPurchasePrepaymentsAccountNo := GeneralPostingSetup."Purch. Prepayments Account";
        GeneralPostingSetup."Purch. Prepayments Account" :=
          CreateBalanceSheetAccount(
            PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateSOWithTwoPrepmtLines(var SalesHeader: Record "Sales Header"; var Item: array[2] of Record Item)
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        i: Integer;
    begin
        // Create Sales Order with two prepayment lines
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CreateAndModifyCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        SalesHeader.Validate("Compress Prepayment", false);
        SalesHeader.Modify(true);

        for i := 1 to ArrayLen(Item) do begin
            Item[i].Get(LibraryInventory.CreateItemNo());
            UpdatePrepmtPostGroups(
                SalesHeader."Gen. Bus. Posting Group", Item[i]."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            CreateSalesLineWithPrepmtPercentage(SalesLine, SalesHeader, Item[i]."No.", LibraryRandom.RandIntInRange(10, 40));
        end;
    end;

    local procedure CreateSalesLineWithPrepmtPercentage(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; PrepaymentPercentage: Integer)
    begin
        // Take Quantity and Unit Price with Random values.
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo,
          LibraryRandom.RandInt(10), LibraryRandom.RandDecInRange(2000, 3000, 2)); // hard coded values used for more complex calculation scenarios
        SalesLine.Validate("Prepayment %", PrepaymentPercentage);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseLineWithPrepmtPercentage(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; PrepaymentPercentage: Integer)
    begin
        // Take Quantity and Unit Price with Random values.
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo,
          LibraryRandom.RandInt(10), LibraryRandom.RandDecInRange(2000, 3000, 2)); // hard coded values used for more complex calculation scenarios
        PurchaseLine.Validate("Prepayment %", PrepaymentPercentage);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateCurrency(): Code[10]
    begin
        exit(LibraryERM.CreateCurrencyWithGLAccountSetup());
    end;

    local procedure CreateExchangeRate(CurrencyCode: Code[10]; StartingDate: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Take Random Value for Exchange Rate Fields.
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDec(100, 2));
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount" + LibraryRandom.RandDec(100, 2));
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateExchangeRateOnRndDate(CurrencyCode: Code[10]) ExchangeRateChangeDate: Date
    begin
        ExchangeRateChangeDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(5)), WorkDate());
        CreateExchangeRate(CurrencyCode, ExchangeRateChangeDate);
    end;

    local procedure CreateBalanceSheetAccount(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate(Blocked, false);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateAndModifyVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; GLAccountNo: Code[20]) PurchasePrepmtAccount: Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
    begin
        // Using Random for Quantity, Direct Unit Cost and Prepayment %.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateAndModifyVendor(VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(10, 40)); // make sure values are big enough, so amounts are not close to rounding precision
        PurchaseHeader.Modify(true);
        Item.Get(LibraryInventory.CreateItemNo());
        CreateNewGenProductPostingGroupOnItem(PurchaseHeader."Gen. Bus. Posting Group", Item);
        PurchasePrepmtAccount :=
          UpdatePurchasePrepmtAccount(GLAccountNo, PurchaseHeader."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        CreatePurchaseLineItem(PurchaseLine, PurchaseHeader, Item."No.");
        exit(PurchasePrepmtAccount);
    end;

    local procedure CreatePurchaseOrderWithAccount(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LineGLAccount: Record "G/L Account"; LinePrepmtPct: Decimal)
    var
        VendorNo: Code[20];
        PricesIncludingVAT: Boolean;
    begin
        VendorNo :=
          CreateVendorWithPostingGroups(
            LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");

        PricesIncludingVAT := PurchaseHeader."Prices Including VAT";
        CreatePurchaseHeader(PurchaseHeader, VendorNo, PricesIncludingVAT);

        CreatePurchaseLineGL(PurchaseLine, PurchaseHeader, LineGLAccount."No.");
        if LinePrepmtPct <> 0 then
            PurchaseLine.Validate("Prepayment %", LinePrepmtPct);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateCustomerWithCurrencyAndPrepaymentPct(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Prepayment %", LibraryRandom.RandIntInRange(10, 40));
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithCurrencyAnd100PrepmtPct(VATBusPostingGroup: Code[20]; GenBusPostingGroup: Code[20]; CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Prepayment %", 100);
        CreateVATPostingSetupForCustRndgAcc(Customer."Customer Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithPostingGroupsAndCurrency(LineGLAccount: Record "G/L Account"; CurrencyCode: Code[10]; PrepmtPct: Decimal): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(
          CreateCustomerWithPostingGroups(LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group"));
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Prepayment %", PrepmtPct);
        Customer.Modify(true);
        CreateVATPostingSetupForCustRndgAcc(Customer."Customer Posting Group", LineGLAccount."VAT Bus. Posting Group");
        CreateGenPostingSetupForCustRndgAcc(Customer."Customer Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWith100PrepmtPct(GLAccount: Record "G/L Account"): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(LibrarySales.CreateCustomerWithBusPostingGroups(GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group"));
        Customer.Validate("Prepayment %", 100);
        Customer.Modify(true);
        exit(Customer."No.")
    end;

    local procedure CreateVendorWithCurrencyAndPrepaymentPct(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Validate("Prepayment %", LibraryRandom.RandIntInRange(10, 40));
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithCurrencyAnd100PrepmtPct(VATBusPostingGroup: Code[20]; GenBusPostingGroup: Code[20]; CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Validate("Prepayment %", 100);
        CreateVATPostingSetupForVendRndgAcc(Vendor."Vendor Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithPostingGroupsAndCurrency(LineGLAccount: Record "G/L Account"; CurrencyCode: Code[10]; PrepmtPct: Decimal): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(
          CreateVendorWithPostingGroups(LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group"));
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Validate("Prepayment %", PrepmtPct);
        Vendor.Modify(true);
        CreateVATPostingSetupForVendRndgAcc(Vendor."Vendor Posting Group", LineGLAccount."VAT Bus. Posting Group");
        CreateGenPostingSetupForVendRndgAcc(Vendor."Vendor Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWith100PrepmtPct(GLAccount: Record "G/L Account"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(LibraryPurchase.CreateVendorWithBusPostingGroups(GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group"));
        Vendor.Validate("Prepayment %", 100);
        Vendor.Modify(true);
        exit(Vendor."No.")
    end;

    local procedure CreatePurchaseOrderWithCurrency(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; CurrencyCode: Code[10]; VendorNo: Code[20]): Decimal
    var
        Item: Record Item;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        PrepaymentAmount: Decimal;
    begin
        CurrencyExchangeRate.Get(CurrencyCode, LibraryERM.FindEarliestDateForExhRate());
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        Item.Get(LibraryInventory.CreateItemNo());
        UpdatePrepmtPostGroups(PurchaseHeader."Gen. Bus. Posting Group", item."Gen. Prod. Posting Group", item."VAT Prod. Posting Group");
        CreatePurchaseLineItem(PurchaseLine, PurchaseHeader, item."No.");
        PrepaymentAmount := Round(PurchaseLine."Line Amount" * PurchaseHeader."Prepayment %" / 100);
        exit((PrepaymentAmount * CurrencyExchangeRate."Relational Exch. Rate Amount") / CurrencyExchangeRate."Exchange Rate Amount");
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; PricesInclVAT: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Prices Including VAT", PricesInclVAT);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; LineType: Enum "Purchase Line Type"; LineNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, LineType, LineNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineItem(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    begin
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo,
          LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandDecInRange(1000, 2000, 2));
    end;

    local procedure CreatePurchaseLineGL(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20])
    begin
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo,
          LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandDecInRange(1000, 2000, 2));
    end;

    local procedure CreatePurchaseLineWithCustomAmount(PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; UnitPriceInclVAT: Decimal; QtyToReceive: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1, UnitPriceInclVAT);
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineWithCustomDiscountAmount(PurchaseHeader: Record "Purchase Header"; LineGLAccountNo: Code[20]; Qty: Decimal; QtyToReceive: Decimal; UnitPriceInclVAT: Decimal; DiscountPct: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LineGLAccountNo, Qty, UnitPriceInclVAT);
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Validate("Line Discount %", DiscountPct);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineWithCustomDiscountAndPrepmtAmount(PurchaseHeader: Record "Purchase Header"; LineGLAccountNo: Code[20]; Qty: Decimal; UnitPriceInclVAT: Decimal; DiscountPct: Decimal; PrepmtLineAmount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LineGLAccountNo, Qty, UnitPriceInclVAT);
        PurchaseLine.Validate("Line Discount %", DiscountPct);
        PurchaseLine.Validate("Prepmt. Line Amount", PrepmtLineAmount);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateAdditionalReportingCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(CreateCurrency());
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        Currency.Validate("Appln. Rounding Precision", LibraryRandom.RandDec(0, 2));
        Currency.Validate("Invoice Rounding Precision", LibraryRandom.RandDec(0, 2));
        Currency.Modify(true);
        exit(Currency.Code);
        LibraryERM.SetAddReportingCurrency(Currency.Code);
    end;

    local procedure CreateSalesDocumentWithCurrency(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CurrencyCode: Code[10]; CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"): Decimal
    var
        Item: Record Item;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        PrepaymentAmount: Decimal;
    begin
        CurrencyExchangeRate.Get(CurrencyCode, LibraryERM.FindEarliestDateForExhRate());
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        Item.Get(LibraryInventory.CreateItemNo());
        UpdatePrepmtPostGroups(SalesHeader."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group", Item."VAT Prod. Posting Group");
        CreateSalesLineItem(SalesLine, SalesHeader, Item."No.");
        PrepaymentAmount := Round(SalesLine."Line Amount" * SalesHeader."Prepayment %" / 100);
        exit((PrepaymentAmount * CurrencyExchangeRate."Relational Exch. Rate Amount") / CurrencyExchangeRate."Exchange Rate Amount");
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; PricesInclVAT: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Prices Including VAT", PricesInclVAT);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LineType: Enum "Sales Line Type"; LineNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, LineType, LineNo, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineItem(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    begin
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo,
          LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandDecInRange(1000, 2000, 2));
    end;

    local procedure CreateSalesLineGL(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; GLAccountNo: Code[20])
    begin
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo,
          LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandDecInRange(1000, 2000, 2));
    end;

    local procedure CreateSalesLineWithCustomAmount(SalesHeader: Record "Sales Header"; GLAccountNo: Code[20]; UnitPriceInclVAT: Decimal; QtyToShip: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, 1);
        SalesLine.Validate("Unit Price", UnitPriceInclVAT);
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithCustomDiscountAmount(SalesHeader: Record "Sales Header"; LineGLAccountNo: Code[20]; Qty: Decimal; QtyToShip: Decimal; UnitPriceInclVAT: Decimal; DiscountPct: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LineGLAccountNo, Qty);
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Validate("Unit Price", UnitPriceInclVAT);
        SalesLine.Validate("Line Discount %", DiscountPct);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithCustomDiscountAndPrepmtAmount(SalesHeader: Record "Sales Header"; LineGLAccountNo: Code[20]; Qty: Decimal; UnitPriceInclVAT: Decimal; DiscountPct: Decimal; PrepmtLineAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LineGLAccountNo, Qty);
        SalesLine.Validate("Unit Price", UnitPriceInclVAT);
        SalesLine.Validate("Line Discount %", DiscountPct);
        SalesLine.Validate("Prepmt. Line Amount", PrepmtLineAmount);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostPurchasePrepaymentInvoiceWithCurrency(var GLAccount: Record "G/L Account"; var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10]) PrepaymentAmount: Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PrepaymentAmount :=
          CreatePurchaseOrderWithCurrency(
            PurchaseHeader, PurchaseLine, CurrencyCode, CreateVendorWithCurrencyAndPrepaymentPct(CurrencyCode));
        LibraryERM.FindGLAccount(GLAccount);
        UpdatePurchasePrepmtAccount(GLAccount."No.", PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PostPurchasePrepaymentInvoice(PurchaseHeader);
    end;

    local procedure CreateAndPostSalesPrepaymentInvoiceWithCurrency(var GLAccount: Record "G/L Account"; var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10]) PrepaymentAmount: Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        PrepaymentAmount :=
          CreateSalesDocumentWithCurrency(
            SalesHeader, SalesLine, CurrencyCode, CreateCustomerWithCurrencyAndPrepaymentPct(CurrencyCode),
            SalesHeader."Document Type"::Order);
        LibraryERM.FindGLAccount(GLAccount);
        UpdateSalesPrepmtAccount(GLAccount."No.", SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        PostSalesPrepaymentInvoice(SalesHeader);
    end;

    local procedure CreateAndPostPurchasePrepaymentInvoiceWith100Pct(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10]) PrepaymentAmount: Decimal
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        // zero VAT % setup is required to avoid prepayment VAT rounding
        CreateVATPostingSetupZeroPct(VATPostingSetup);

        Vendor.Get(CreateVendorWithCurrencyAndPrepaymentPct(CurrencyCode));
        Vendor.Validate("Prepayment %", 100);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify();

        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" ");
        GLAccount.Get(GLAccountNo);
        UpdatePurchasePrepmtAccount(
          GLAccountNo, Vendor."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group");

        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" ");
        PrepaymentAmount :=
          CreatePurchaseOrderWithCurrencyAndGLAcc(PurchaseHeader, PurchaseLine, CurrencyCode, Vendor."No.", GLAccountNo);

        PostPurchasePrepaymentInvoice(PurchaseHeader);
    end;

    local procedure CreateAndPostSalesPrepaymentInvoiceWith100Pct(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10]) PrepaymentAmount: Decimal
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        // zero VAT % setup is required to avoid prepayment VAT rounding
        CreateVATPostingSetupZeroPct(VATPostingSetup);

        Customer.Get(CreateCustomerWithCurrencyAndPrepaymentPct(CurrencyCode));
        Customer.Validate("Prepayment %", 100);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify();

        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" ");
        GLAccount.Get(GLAccountNo);
        UpdateSalesPrepmtAccount(
          GLAccountNo, Customer."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group");

        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" ");
        PrepaymentAmount :=
          CreateSalesOrderWithCurrencyAndGLAcc(SalesHeader, SalesLine, CurrencyCode, Customer."No.", GLAccountNo);
        PostSalesPrepaymentInvoice(SalesHeader);
    end;

    local procedure CreateVATPostingSetupZeroPct(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);
    end;

    local procedure CreateVATPostingSetupForCustRndgAcc(CustPostingGroupCode: Code[20]; VATBusPostingGroupCode: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CustomerPostingGroup.Get(CustPostingGroupCode);
        GLAccount.Get(CustomerPostingGroup."Invoice Rounding Account");
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroupCode, GLAccount."VAT Prod. Posting Group");
    end;

    local procedure CreateVATPostingSetupForVendRndgAcc(VendorPostingGroupCode: Code[20]; VATBusPostingGroupCode: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VendorPostingGroup.Get(VendorPostingGroupCode);
        GLAccount.Get(VendorPostingGroup."Invoice Rounding Account");
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroupCode, GLAccount."VAT Prod. Posting Group");
    end;

    local procedure CreateSalesPrepaymentVATSetup(var GLAccount: Record "G/L Account"; VATPct: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibrarySales.CreatePrepaymentVATSetup(GLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreatePurchasePrepaymentVATSetup(var GLAccount: Record "G/L Account"; VATPct: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryPurchase.CreatePrepaymentVATSetup(GLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreatePairedVATPostingSetup(var GLAccount2: Record "G/L Account"; GLAccount1: Record "G/L Account"; VATPct: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup.Get(GLAccount1."VAT Bus. Posting Group", GLAccount1."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Identifier", VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Insert(true);

        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        GeneralPostingSetup.Get(GLAccount1."Gen. Bus. Posting Group", GLAccount1."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GeneralPostingSetup.Insert(true);

        GLAccount2.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount2."Gen. Posting Type"::" "));
        GLAccount2.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount2.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        GLAccount2.Modify(true);
    end;

    local procedure CreateGenPostingSetupForCustRndgAcc(CustPostingGroupCode: Code[20]; GenBusPostingGroupCode: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
        GenPostingSetup: Record "General Posting Setup";
    begin
        CustomerPostingGroup.Get(CustPostingGroupCode);
        GLAccount.Get(CustomerPostingGroup."Invoice Rounding Account");
        LibraryERM.CreateGeneralPostingSetup(GenPostingSetup, GenBusPostingGroupCode, GLAccount."Gen. Prod. Posting Group");
    end;

    local procedure CreateGenPostingSetupForVendRndgAcc(VendPostingGroupCode: Code[20]; GenBusPostingGroupCode: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLAccount: Record "G/L Account";
        GenPostingSetup: Record "General Posting Setup";
    begin
        VendorPostingGroup.Get(VendPostingGroupCode);
        GLAccount.Get(VendorPostingGroup."Invoice Rounding Account");
        LibraryERM.CreateGeneralPostingSetup(GenPostingSetup, GenBusPostingGroupCode, GLAccount."Gen. Prod. Posting Group");
    end;

    local procedure CreatePurchaseOrderWithCurrencyAndGLAcc(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; CurrencyCode: Code[10]; VendorNo: Code[20]; GLAccountNo: Code[20]): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        PrepaymentAmount: Decimal;
    begin
        CurrencyExchangeRate.Get(CurrencyCode, LibraryERM.FindEarliestDateForExhRate());
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        CreatePurchaseLineGL(PurchaseLine, PurchaseHeader, GLAccountNo);
        PrepaymentAmount := Round(PurchaseLine."Line Amount" * PurchaseHeader."Prepayment %" / 100);
        exit((PrepaymentAmount * CurrencyExchangeRate."Relational Exch. Rate Amount") / CurrencyExchangeRate."Exchange Rate Amount");
    end;

    local procedure CreateSalesOrderWithCurrencyAndGLAcc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CurrencyCode: Code[10]; CustomerNo: Code[20]; GLAccountNo: Code[20]): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        PrepaymentAmount: Decimal;
    begin
        CurrencyExchangeRate.Get(CurrencyCode, LibraryERM.FindEarliestDateForExhRate());
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLineGL(SalesLine, SalesHeader, GLAccountNo);
        PrepaymentAmount := Round(SalesLine."Line Amount" * SalesHeader."Prepayment %" / 100);
        exit((PrepaymentAmount * CurrencyExchangeRate."Relational Exch. Rate Amount") / CurrencyExchangeRate."Exchange Rate Amount");
    end;

    local procedure PostSalesPrepaymentInvoiceForSingleLine(var SalesHeader: Record "Sales Header") PrepmtInvoice: Code[20]
    var
        SalesLine: Record "Sales Line";
        ResetPrepaymentPercentage: Boolean;
    begin
        // init local vars
        ResetPrepaymentPercentage := false;
        PrepmtInvoice := '';

        // Filter on unposted prepayment lines
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Prepmt. Amt. Inv.", 0); // consider only unposted lines
        if not SalesLine.FindSet() then
            exit; // no more unposted prepayment lines available

        // Enable only one line to be posted with prepayment. Looping strategy should be fine since the expected amount of lines is < 5
        repeat
            if ResetPrepaymentPercentage then
                SalesLine.Validate("Prepayment %", 0) // reset prepayment percentage
            else begin
                SalesLine.Validate("Prepayment %", LibraryRandom.RandIntInRange(10, 25)); // set a prepayment percentage for a single line only
                ResetPrepaymentPercentage := true;
            end;
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;

        // Post prepayment and r-open order
        PrepmtInvoice := PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);
    end;

    local procedure PostPurchPrepaymentInvoiceForSingleLine(var PurchaseHeader: Record "Purchase Header") PrepmtInvoice: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        ResetPrepaymentPercentage: Boolean;
    begin
        // init local vars
        ResetPrepaymentPercentage := false;
        PrepmtInvoice := '';

        // Filter on unposted prepayment lines
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Prepmt. Amt. Inv.", 0); // consider only unposted lines
        if not PurchaseLine.FindSet() then
            exit; // no more unposted prepayment lines available

        // Enable only one line to be posted with prepayment. Looping strategy should be fine since the expected amount of lines is < 5
        repeat
            if ResetPrepaymentPercentage then
                PurchaseLine.Validate("Prepayment %", 0)
            else begin
                PurchaseLine.Validate("Prepayment %", LibraryRandom.RandIntInRange(10, 25));
                ResetPrepaymentPercentage := true;
            end;
            PurchaseLine.Modify(true);
        until PurchaseLine.Next() = 0;

        // Post prepayment and r-open order
        PrepmtInvoice := PostPurchasePrepaymentInvoice(PurchaseHeader);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
    end;

    local procedure PostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; Receive: Boolean; Invoice: Boolean): Code[20]
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, Receive, Invoice));
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure FindPurchaseInvoiceHeader(var PurchInvHeader: Record "Purch. Inv. Header"; BuyFromVendorNo: Code[20]; VendorInvoiceNo: Code[35])
    begin
        PurchInvHeader.SetCurrentKey("Buy-from Vendor No.");
        PurchInvHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchInvHeader.SetRange("Vendor Invoice No.", VendorInvoiceNo);
        PurchInvHeader.FindFirst();
    end;

    local procedure FindSalesInvoiceHeader(var SalesInvoiceHeader: Record "Sales Invoice Header"; ExternalDocumentNo: Code[35]; SellToCustomerNo: Code[20])
    begin
        SalesInvoiceHeader.SetCurrentKey("Sell-to Customer No.", "External Document No.");
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        SalesInvoiceHeader.SetRange("External Document No.", ExternalDocumentNo);
        SalesInvoiceHeader.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
    end;

    local procedure GetPostedDocumentNo(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.PeekNextNo(NoSeriesCode));
    end;

    local procedure ModifyCustomerNoOnSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesHeader.Modify(true);
    end;

    local procedure ModifyCurrencyOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10])
    begin
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure ModifyCurrencyOnSalesHeader(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10])
    begin
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure ModifyPurchaseLine(var PurchaseLine: Record "Purchase Line"; CurrenyCode: Code[10])
    begin
        // Take Random Value of Direct Unit Cost.
        PurchaseLine.Validate("Currency Code", CurrenyCode);
        PurchaseLine.Modify(true);
    end;

    local procedure ModifyPrepaymentPctOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; NewPrepaymentPct: Decimal)
    begin
        // Take Random Values of Prepayment %.
        PurchaseHeader.Validate("Prepayment %", NewPrepaymentPct);
        PurchaseHeader.Modify(true);
    end;

    local procedure ModifyPostingDateOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; PostingDate: Date)
    begin
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
    end;

    local procedure ModifyQtyToReceiveOnPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Find();
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine."Qty. to Receive" / LibraryRandom.RandIntInRange(2, 5));
        PurchaseLine.Modify(true);
    end;

    local procedure ModifyQtyToShipOnSalesLine(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", SalesLine."Qty. to Ship" / LibraryRandom.RandIntInRange(2, 5));
        SalesLine.Modify(true);
    end;

    local procedure ModifyQuantityOnSalesLine(var SalesLine: Record "Sales Line")
    begin
        // Take Random Values for quantity.
        SalesLine.Find();
        SalesLine.Validate(Quantity, SalesLine.Quantity + LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
    end;

    local procedure ModifyQuantityOnPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        // Take Random Values for quantity.
        PurchaseLine.Find();
        PurchaseLine.Validate(Quantity, PurchaseLine.Quantity + LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);
    end;

    local procedure ModifySalesHeaderForPrepaymentPct(var SalesHeader: Record "Sales Header"; PrepaymentPct: Decimal)
    begin
        SalesHeader.Validate("Prepayment %", PrepaymentPct);
        SalesHeader.Modify(true);
    end;

    local procedure ModifySalesHeaderCompressPrepmt(var SalesHeader: Record "Sales Header"; NewCompressPrepmt: Boolean)
    begin
        SalesHeader.Validate("Compress Prepayment", NewCompressPrepmt);
        SalesHeader.Modify(true);
    end;

    local procedure ModifyPurchHeaderCompressPrepmt(var PurchaseHeader: Record "Purchase Header"; NewCompressPrepmt: Boolean)
    begin
        PurchaseHeader.Validate("Compress Prepayment", NewCompressPrepmt);
        PurchaseHeader.Modify(true);
    end;

    local procedure ModifyVendorCreditMemoNoOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure ModifyVendorNoOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure ModifyVendorInvoiceNoOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        // Used Random Values for Vendor Invoice No to make Unique.
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."Vendor Invoice No." + Format(LibraryRandom.RandInt(100)));
        PurchaseHeader.Modify(true);
    end;

    local procedure PostSalesHeader(var SalesHeader: Record "Sales Header"; PostingDate: Date): Code[20]
    begin
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; PostingDate: Date): Code[20]
    begin
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        exit(PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostSalesPrepaymentInvoice(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        PrepmtInvoiceNo: Code[20];
    begin
        PrepmtInvoiceNo := GetPostedDocumentNo(SalesHeader."Prepayment No. Series");
        SalesPostPrepayments.Invoice(SalesHeader);
        exit(PrepmtInvoiceNo);
    end;

    local procedure PostPurchasePrepaymentInvoice(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        PrepmtInvoiceNo: Code[20];
    begin
        PrepmtInvoiceNo := GetPostedDocumentNo(PurchaseHeader."Prepayment No. Series");
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify();
        PurchasePostPrepayments.Invoice(PurchaseHeader);
        exit(PrepmtInvoiceNo);
    end;

    local procedure PostSalesPrepaymentCreditMemo(var SalesHeader: Record "Sales Header"; PostingDate: Date): Code[20]
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        PrepmtCrMemoNo: Code[20];
    begin
        PrepmtCrMemoNo := GetPostedDocumentNo(SalesHeader."Prepmt. Cr. Memo No. Series");
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        SalesPostPrepayments.CreditMemo(SalesHeader);
        exit(PrepmtCrMemoNo);
    end;

    local procedure PostPurchasePrepaymentCreditMemo(var PurchaseHeader: Record "Purchase Header"; PostingDate: Date): Code[20]
    var
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        PrepmtCrMemoNo: Code[20];
    begin
        PrepmtCrMemoNo := GetPostedDocumentNo(PurchaseHeader."Prepmt. Cr. Memo No. Series");
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryPurchase.GegVendorLedgerEntryUniqueExternalDocNo()); // Ensure posting doesnt break on error when this field is empty
        PurchaseHeader.Modify(true);
        PurchasePostPrepayments.CreditMemo(PurchaseHeader);
        exit(PrepmtCrMemoNo);
    end;

    local procedure PurchaseCopyDocument(PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type From")
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters(DocumentType, DocumentNo, true, false);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.Run();
    end;

    local procedure SalesCopyDocument(SalesHeader: Record "Sales Header"; DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type From")
    var
        CopySalesDocument: Report "Copy Sales Document";
    begin
        CopySalesDocument.SetSalesHeader(SalesHeader);
        CopySalesDocument.SetParameters(DocumentType, DocumentNo, true, false);
        CopySalesDocument.UseRequestPage(false);
        CopySalesDocument.Run();
    end;

    local procedure SetVATPostingSetupCustomPct(LineGLAccount: Record "G/L Account"; Pct: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", Pct);
        VATPostingSetup.Modify(true);
    end;

    local procedure SimulatePurchaseRounding(DocNo: Code[20]; PrepaymentAmountInLCY: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocNo);
        PurchaseLine.FindFirst();
        if PrepaymentAmountInLCY = PurchaseLine."Prepmt. Amount Inv. (LCY)" then
            PurchaseLine."Prepmt. Amount Inv. (LCY)" -= 0.01;
        PurchaseLine.Modify();
    end;

    local procedure SimulateSalesRounding(DocNo: Code[20]; PrepaymentAmountInLCY: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocNo);
        SalesLine.FindFirst();
        if PrepaymentAmountInLCY = SalesLine."Prepmt. Amount Inv. (LCY)" then
            SalesLine."Prepmt. Amount Inv. (LCY)" -= 0.01;
        SalesLine.Modify();
    end;

    local procedure UpdatePurchasePrepmtAccount(PurchPrepaymentsAccount: Code[20]; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]) OldPurchPrepaymentsAccount: Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        OldPurchPrepaymentsAccount := GeneralPostingSetup."Purch. Prepayments Account";
        GeneralPostingSetup."Purch. Prepayments Account" := PurchPrepaymentsAccount;
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateSalesPrepmtAccount(SalesPrepaymentsAccount: Code[20]; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]) OldSalesPrepaymentsAccount: Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        OldSalesPrepaymentsAccount := GeneralPostingSetup."Sales Prepayments Account";
        GeneralPostingSetup."Sales Prepayments Account" := SalesPrepaymentsAccount;
        GeneralPostingSetup.Modify(true);
    end;

    local procedure VerifyVATEntryBalanceWithCalcType(CVNo: Code[20]; Type: Enum "General Posting Type"; VATCalcType: Enum "Tax Calculation Type"; VATBase: Decimal; VATAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", CVNo);
        VATEntry.SetRange(Type, Type);
        VATEntry.SetRange("VAT Calculation Type", VATCalcType);
        VATEntry.FindFirst();
        VATEntry.CalcSums(Base, Amount);
        Assert.AreEqual(VATAmount, VATEntry.Amount, VATEntry.FieldName(Amount));
        Assert.AreEqual(VATBase, VATEntry.Base, VATEntry.FieldName(Base));
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; RemainingQuantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Remaining Quantity", RemainingQuantity);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; Amount: Decimal; GLAccountNo: Code[20]; RoundingPrecision: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, GLAccountNo);
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, RoundingPrecision, StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntryDoesNotExist(DocNo: Code[20]; GLAccNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        Assert.RecordIsEmpty(GLEntry);
    end;

    local procedure VerifyGLEntryInFCY(DocumentNo: Code[20]; Amount: Decimal; GLAccountNo: Code[20]; CurrencyCode: Code[10]; CurrencyExchangeDate: Date)
    var
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
        FCYAmount: Decimal;
    begin
        FindGLEntry(GLEntry, DocumentNo, GLAccountNo);
        Currency.Get(CurrencyCode);
        FCYAmount :=
          Round(LibraryERM.ConvertCurrency(GLEntry.Amount, '', CurrencyCode, CurrencyExchangeDate),
            Currency."Invoice Rounding Precision");

        Assert.AreNearlyEqual(
          Amount, FCYAmount, Currency."Invoice Rounding Precision",
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntryForSourceType(DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, GLAccountNo);
        GLEntry.TestField("Source Type", GLEntry."Source Type"::Vendor);
    end;

    local procedure VerifyGLAccountBalance(GLAccountNo: Code[20]; DocumentNoFilter: Text[128]; ExpectedBalance: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        if DocumentNoFilter <> '' then
            GLEntry.SetFilter("Document No.", DocumentNoFilter);
        GLEntry.SetFilter(Amount, '<>0');
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(ExpectedBalance, GLEntry.Amount, StrSubstNo(UnbalancedAccountErr, GLAccountNo, DocumentNoFilter));
    end;

    local procedure VerifyPurchaseLineForPrepaymentPct(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Prepayment %", PurchaseHeader."Prepayment %");
    end;

    local procedure VerifySalesLineForPrepaymentPct(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.TestField("Prepayment %", SalesHeader."Prepayment %");
    end;

    local procedure VerifyPrepaymentAmountOnGLEntry(DocumentNo: Code[20]; Amount: Decimal; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, GLAccountNo);
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyACYAmountOnGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, GLAccountNo);
        Assert.AreEqual(0, GLEntry."Additional-Currency Amount", RoundingACYAmountErr);
    end;

    local procedure VerifyCustomerReceivablesAccountAmount(CustomerPostingGroupCode: Code[20]; DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GLEntry: Record "G/L Entry";
    begin
        CustomerPostingGroup.Get(CustomerPostingGroupCode);
        FindGLEntry(GLEntry, DocumentNo, CustomerPostingGroup."Receivables Account");
        Assert.AreEqual(ExpectedAmount, GLEntry.Amount, CustomerPostingGroup.FieldCaption("Receivables Account"));
    end;

    local procedure VerifyVendorPayablesAccountAmount(VendorPostingGroupCode: Code[20]; DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLEntry: Record "G/L Entry";
    begin
        VendorPostingGroup.Get(VendorPostingGroupCode);
        FindGLEntry(GLEntry, DocumentNo, VendorPostingGroup."Payables Account");
        Assert.AreEqual(ExpectedAmount, GLEntry.Amount, VendorPostingGroup.FieldCaption("Payables Account"));
    end;

    local procedure VerifySalesVATAccountBalance(VATBusPostingGroupCode: Code[20]; VATProdPostingGroupcode: Code[20]; DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroupCode, VATProdPostingGroupcode);
        VerifyGLAccountBalance(VATPostingSetup."Sales VAT Account", DocumentNo, ExpectedAmount);
    end;

    local procedure VerifyPurchaseVATAccountBalance(VATBusPostingGroupCode: Code[20]; VATProdPostingGroupcode: Code[20]; DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroupCode, VATProdPostingGroupcode);
        VerifyGLAccountBalance(VATPostingSetup."Purchase VAT Account", DocumentNo, ExpectedAmount);
    end;

    local procedure VerifySalesLinePrepmtAmt(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; ExpectedPrepmtAmt: Decimal; ExpectedPrepmtAmtInclVAT: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, DocumentType, DocumentNo);
        Assert.AreEqual(ExpectedPrepmtAmt, SalesLine."Prepayment Amount", SalesLine.FieldCaption("Prepayment Amount"));
        Assert.AreEqual(ExpectedPrepmtAmtInclVAT, SalesLine."Prepmt. Amt. Incl. VAT", SalesLine.FieldCaption("Prepmt. Amt. Incl. VAT"));
    end;

    local procedure VerifyPurchLinePrepmtAmt(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; ExpectedPrepmtAmt: Decimal; ExpectedPrepmtAmtInclVAT: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchaseLine, DocumentType, DocumentNo);
        Assert.AreEqual(ExpectedPrepmtAmt, PurchaseLine."Prepayment Amount", PurchaseLine.FieldCaption("Prepayment Amount"));
        Assert.AreEqual(ExpectedPrepmtAmtInclVAT, PurchaseLine."Prepmt. Amt. Incl. VAT", PurchaseLine.FieldCaption("Prepmt. Amt. Incl. VAT"));
    end;

    local procedure VerifySalesPrepmtInvAmounts(PrepmtInvNo: Code[20]; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(PrepmtInvNo);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        Assert.AreEqual(ExpectedAmount, SalesInvoiceHeader.Amount, SalesInvoiceHeader.FieldCaption(Amount));
        Assert.AreEqual(ExpectedAmountInclVAT, SalesInvoiceHeader."Amount Including VAT", SalesInvoiceHeader.FieldCaption("Amount Including VAT"));
    end;

    local procedure VerifyPurchPrepmtInvAmounts(PrepmtInvNo: Code[20]; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(PrepmtInvNo);
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        Assert.AreEqual(ExpectedAmount, PurchInvHeader.Amount, PurchInvHeader.FieldCaption(Amount));
        Assert.AreEqual(ExpectedAmountInclVAT, PurchInvHeader."Amount Including VAT", PurchInvHeader.FieldCaption("Amount Including VAT"));
    end;

    local procedure VerifySalesPrepmtCrMemoAmounts(PrepmtCrMemoNo: Code[20]; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.Get(PrepmtCrMemoNo);
        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT");
        Assert.AreEqual(ExpectedAmount, SalesCrMemoHeader.Amount, SalesCrMemoHeader.FieldCaption(Amount));
        Assert.AreEqual(ExpectedAmountInclVAT, SalesCrMemoHeader."Amount Including VAT", SalesCrMemoHeader.FieldCaption("Amount Including VAT"));
    end;

    local procedure VerifyPurchPrepmtCrMemoAmounts(PrepmtCrMemoNo: Code[20]; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal)
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.Get(PrepmtCrMemoNo);
        PurchCrMemoHdr.CalcFields(Amount, "Amount Including VAT");
        Assert.AreEqual(ExpectedAmount, PurchCrMemoHdr.Amount, PurchCrMemoHdr.FieldCaption(Amount));
        Assert.AreEqual(ExpectedAmountInclVAT, PurchCrMemoHdr."Amount Including VAT", PurchCrMemoHdr.FieldCaption("Amount Including VAT"));
    end;

    local procedure CreatePurchaseOrderWithResourceLineAndPrepayment(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var GLAccountNo: Code[20])
    var
        Resource: Record Resource;
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(10, 90));
        PurchaseHeader.Modify(true);

        Resource.Get(LibraryResource.CreateResourceNo());
        UpdatePrepmtPostGroups(
            PurchaseHeader."Gen. Bus. Posting Group", Resource."Gen. Prod. Posting Group", Resource."VAT Prod. Posting Group");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, Resource."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify();

        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GeneralPostingSetup."Purch. Prepayments Account" := LibraryERM.CreateGLAccountWithPurchSetup();
        GeneralPostingSetup.Modify(true);

        GLAccountNo := GeneralPostingSetup."Purch. Prepayments Account";

        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
    end;

    local procedure CreateNewGenProductPostingGroupOnItem(GenBusPostingGroupCode: Code[20]; var Item: Record Item)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        GenProductPostingGroup.Get(Item."Gen. Prod. Posting Group");
        GenProductPostingGroup.Code := LibraryUtility.GenerateGUID();
        GenProductPostingGroup.Insert(true);
        GeneralPostingSetup.Get(GenBusPostingGroupCode, Item."Gen. Prod. Posting Group");
        GeneralPostingSetup."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;
        GeneralPostingSetup.Insert();
        Item."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;
        Item.Modify();
    end;

    local procedure UpdatePrepmtPostGroups(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        SetProdPostingGroupsOnGLAccount(GeneralPostingSetup."Sales Prepayments Account", GenProdPostingGroup, VATProdPostingGroup);
        SetProdPostingGroupsOnGLAccount(GeneralPostingSetup."Purch. Prepayments Account", GenProdPostingGroup, VATProdPostingGroup);
    end;

    local procedure SetProdPostingGroupsOnGLAccount(GLAccountNo: Code[20]; GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccountNo <> '' then begin
            GLAccount.Get(GLAccountNo);
            GLAccount."Gen. Prod. Posting Group" := GenProdPostingGroup;
            GLAccount."VAT Prod. Posting Group" := VATProdPostingGroup;
            GLAccount.Modify();
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure PrepaymentConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
