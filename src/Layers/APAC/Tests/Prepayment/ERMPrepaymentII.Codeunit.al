codeunit 134101 "ERM Prepayment II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Prepayment]
        isInitialized := false;
    end;

    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryJob: Codeunit "Library - Job";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        isInitialized: Boolean;
        ValidationErr: Label '%1 must be %2.', Comment = '.';
        PurchasePrepaymentErr: Label '%1 cannot be less than %2. in %3 %4=''%5'',%6=''%7'',%8=''%9''.', Comment = '.';
        ErrorValidateMsg: Label 'Error must be same.';
        AmountErr: Label '%1 must be %2 in %3.', Comment = '.';
        SalesPrepaymentErr: Label '%1 cannot be less than %2 in %3 %4=''%5'',%6=''%7'',%8=''%9''.', Comment = '.';
        ShipmentLinesErr: Label 'Wrong number of shipment lines in "Get Shipment Lines" page.';
        ReceiptLinesErr: Label 'Wrong number of receipt lines in "Get Receipt Lines" page.';
        ShipmentLinesDocNoErr: Label 'Wrong Document No. in shipment line in "Get Shipment Lines" page.';
        ReceiptLinesDocNoErr: Label 'Wrong Document No. in receipt line in "Get Receipt Lines" page.';
        VATCalculationType: Enum "Tax Calculation Type";
        BaseAmountNotMatchedErr: Label 'VAT Base must be equal to %1.', Comment = '%1= VAT Base';

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceWithJob()
    var
        LineGLAccount: Record "G/L Account";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        JobTask: Record "Job Task";
        ItemNo: Code[20];
        VendorNo: Code[20];
        PurchPrepaymentsAccount: Code[20];
        DocumentNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Job]
        // [SCENARIO 241983] Job No. is generated in G/L entries, Job No. and Job Task No. in Purch Inv. Line when prepayment Invoice with Job No. is posted.

        // [GIVEN] Find Job, Create Item, Vendor and Create Purchase Order with Random Prepayment Percent.
        Initialize();
        FindJobTask(JobTask);
        PurchPrepaymentsAccount :=
          LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType::"Normal VAT");
        VendorNo := CreateVendorWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);

        // [GIVEN] Set "Job No." = X, "Job Task No." = Y on Purchase Line.
        CreatePurchaseOrderWithJob(
          PurchaseLine, VendorNo, ItemNo, LibraryRandom.RandDec(20, 2), JobTask."Job No.", JobTask."Job Task No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        ExpectedAmount := Round(PurchaseLine."Line Amount" * (PurchaseHeader."Prepayment %" / 100));
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Prepayment No. Series");

        // [WHEN] Post Prepayment Invoice.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] Verify G/L entries for Prepayment. "Job No." = X
        // [THEN] Prepayment Purch. Inv. Line "Job No." = X, "Job Task No." = Y
        VerifyGLEntry(DocumentNo, PurchPrepaymentsAccount, ExpectedAmount);
        VerifyJobNoInGLEntry(DocumentNo, PurchPrepaymentsAccount, JobTask."Job No.");
        VerifyPurchInvLineJobNoJobTaskNo(DocumentNo, JobTask."Job No.", JobTask."Job Task No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtOnPurchaseLine()
    var
        PurchaseLine: Record "Purchase Line";
        PrepmtAmtInclVAT: Decimal;
        PrepaymentAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Prepayment Amount]
        // [SCENARIO 243338] Check Prepayment Amount and VAT Amount in GL Entry and on Purchase Line after posting Prepayment Invoice for Purchase Order.

        // [GIVEN] Create Purchase Order with Random Prepayment Percent and Post Prepayment Invoice.
        Initialize();
        CreateAndVerifyPurchPrepayment(PurchaseLine, PrepaymentAmount, LibraryRandom.RandDec(10, 2));
        PrepmtAmtInclVAT := Round(PrepaymentAmount + (PrepaymentAmount * PurchaseLine."VAT %" / 100));

        // [THEN] Verify Prepayment Line Amount and Prepayment Amount Including VAT on Purchase Line.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.TestField("Prepmt. Line Amount", PrepaymentAmount);
        PurchaseLine.TestField("Prepmt. Amt. Incl. VAT", PrepmtAmtInclVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtOnSalesLine()
    var
        SalesLine: Record "Sales Line";
        PrepaymentAmount: Decimal;
        PrepmtAmtInclVAT: Decimal;
    begin
        // [FEATURE] [Sales] [Prepayment Amount]
        // [SCENARIO 243338] Check Prepayment Amount and VAT Amount in GL Entry and on Sales Line after posting Prepayment Invoice for Sales Order.

        // Create Sales Order and Post Prepayment Invoice. Take Random Prepayment Percent.
        Initialize();
        CreateAndVerifySalesPrepayment(SalesLine, PrepaymentAmount, LibraryRandom.RandDec(10, 2));
        PrepmtAmtInclVAT := Round(PrepaymentAmount + (PrepaymentAmount * SalesLine."VAT %" / 100));

        // [WHEN] Verify Prepayment Line Amount and Prepayment Amount Including VAT on Sales Line.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Prepmt. Line Amount", PrepaymentAmount);
        SalesLine.TestField("Prepmt. Amt. Incl. VAT", PrepmtAmtInclVAT);
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntryPageHandler')]
    [Scope('OnPrem')]
    procedure PrepmtWithApplyInvoice()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        LineGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Apply]
        // [SCENARIO 257200] Check GL Entry after Posting Prepayment Invoice and Payment with Apply Posted Invoice from General Journal Line.

        // [GIVEN] Update Sales and Receivable Setup with Check Prepayment boolean and Create Setup for Prepayment Value.
        Initialize();
        UpdateCheckPrepmtInSalesReceivableSetup(true);
        SetupPrepaymentOrder(SalesHeader, LineGLAccount);
        ModifySalesHeader(SalesHeader);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Create Payment Journal Line.
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", 0);

        // [WHEN] Apply Posted Invoice with above Payment General Line.
        ApplyGeneralJournal(GenJournalLine."Document Type"::Payment, SalesHeader."Sell-to Customer No.");
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify GL Entry with Posted Payment Amount,
        GeneralLedgerSetup.Get();
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          -GenJournalLine.Amount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), -GenJournalLine.Amount, GLEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtWithModifySalesHeader()
    var
        LineGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Prepayment %]
        // [SCENARIO 257200] Prepayment Line amount should be modified on Sales Line after Modifying Sales Header Prepayment %.

        // [GIVEN] Update Sales and Receivable Setup with Check Prepayment boolean and Create Setup for Prepayment Value.
        Initialize();
        UpdateCheckPrepmtInSalesReceivableSetup(true);
        SetupPrepaymentOrder(SalesHeader, LineGLAccount);

        // [WHEN].
        ModifySalesHeader(SalesHeader);

        // [THEN] Verify each created Sales Line with Prepayment Line Amount.
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        repeat
            SalesLine.TestField("Prepmt. Line Amount", Round(SalesHeader."Prepayment %" * SalesLine."Line Amount" / 100));
        until SalesLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtWithPostedInvoice()
    var
        LineGLAccount: Record "G/L Account";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        PrePaymentLineAmount: Decimal;
        SalesPrepaymentsAccount: Code[20];
    begin
        // [FEATURE] [Sales] [Prepayment %]
        // [SCENARIO 257200] Check each Prepayment Line amount on Sales Line after Modifying Sales Header Prepayment % and Post Prepayment Invoice.

        // [GIVEN] Update Sales and Receivable Setup with Check Prepayment boolean and Create Setup for Prepayment Value.
        Initialize();
        UpdateCheckPrepmtInSalesReceivableSetup(true);
        SalesPrepaymentsAccount := SetupPrepaymentOrder(SalesHeader, LineGLAccount);
        ModifySalesHeader(SalesHeader);

        // Find Prepayment Line Amount before Posting Prepayment.
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        repeat
            PrePaymentLineAmount += SalesLine."Prepmt. Line Amount";
        until SalesLine.Next() = 0;

        // [WHEN] Post Prepayment Invoice on Sales Header.
        DocumentNo := GetPostedDocumentNo(SalesHeader."Prepayment No. Series");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Verify Posted Sales Invoice Line with Prepayment Line Amount, 1 is required because every time it will post with 1 Quantity.
        VerifySalesInvoiceLine(DocumentNo, SalesInvoiceLine.Type::"G/L Account", SalesPrepaymentsAccount, 1, PrePaymentLineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrerpmtWithSalesOrder()
    var
        LineGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        NewPrePaymentAmount: Decimal;
        TotalLineAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Prepayment Amount]
        // [SCENARIO 257200] Check each Prepayment Line amount on Sales Line after Modifying with Random Values.

        // [GIVEN] Update Sales and Receivable Setup with Check Prepayment boolean and Create Setup for Prepayment Value.
        Initialize();
        UpdateCheckPrepmtInSalesReceivableSetup(true);
        SetupPrepaymentOrder(SalesHeader, LineGLAccount);

        // [WHEN] Modify Sales Line PrePayment Amount field with Random values.
        NewPrePaymentAmount := LibraryRandom.RandDec(10, 2);
        SalesPostPrepayments.UpdatePrepmtAmountOnSaleslines(SalesHeader, NewPrePaymentAmount);

        // [THEN] Verify each created Sales Line with Prepayment Line Amount.
        TotalLineAmount := FindSalesLineAmount(SalesHeader."Document Type", SalesHeader."No.");
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        repeat
            SalesLine.TestField("Prepmt. Line Amount", Round(NewPrePaymentAmount * SalesLine."Line Amount" / TotalLineAmount));
        until SalesLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceGetReceiptLine()
    var
        LineGLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        VATAmount: Decimal;
        DocumentNo: Code[20];
        PurchPrepaymentsAccount: Code[20];
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Purchase] [VAT]
        // [SCENARIO 234368] Post Prepayment Purchase Order as Receive. Post Invoice using Get Receipt Line functionality and Verify VAT and Prepayment Entry.

        // [GIVEN] Create Order and Post as Receive. Setup Prepayments Accounts for Purchase and Post Prepayment Invoice.
        // [GIVEN] 100 is required for Purchase Header as Prepayment %.
        Initialize();

        PurchPrepaymentsAccount :=
          LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType::"Normal VAT");

        VendorNo := CreateVendorWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, VendorNo, ItemNo, 100, '');

        VATAmount := PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100;
        PurchasePostPrepayments.Invoice(PurchaseHeader);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Get Posted Purchase Receipt and Post Invoice.
        DocumentNo := InvoicePostedPurchaseOrder(PurchaseHeader, PurchaseHeader."Buy-from Vendor No.", DocumentNo, '', WorkDate());

        // [THEN] Verify Prepayment and VAT Amount in G/L Entry.
        VerifyGLEntry(DocumentNo, PurchPrepaymentsAccount, -PurchaseLine."Line Amount");
        VATPostingSetup.Get(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        VerifyGLEntryPrepayment(DocumentNo, VATPostingSetup."Purchase VAT Account", VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithJob()
    var
        LineGLAccount: Record "G/L Account";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        JobTask: Record "Job Task";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        DocumentNo: Code[20];
        PurchPrepaymentsAccount: Code[20];
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Job]
        // [SCENARIO 241983] Job No. should be generated in G/L entries when Purchase Order with Job No. is posted as Receive & Invoice.

        // [GIVEN] Find Job, Create Item, Vendor and Create Purchase Order with Random Prepayment Percent. Update Job No on Purchase Line.
        Initialize();
        FindJobTask(JobTask);
        PurchPrepaymentsAccount :=
          LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        UpdateInventoryAdjmtAccount(
          PurchPrepaymentsAccount, LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."Gen. Prod. Posting Group");

        VendorNo := CreateVendorWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);

        CreatePurchaseOrderWithJob(
          PurchaseLine, VendorNo, ItemNo, LibraryRandom.RandDec(20, 2), JobTask."Job No.", JobTask."Job Task No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchasePostPrepayments.Invoice(PurchaseHeader);
        UpdateVendorInvoiceNo(PurchaseHeader);

        // [WHEN] Post Purchase Order as Receive & Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify G/L entries for Posted Purchase order.
        GeneralPostingSetup.Get(LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."Gen. Prod. Posting Group");
        VerifyGLEntry(DocumentNo, GeneralPostingSetup."Purch. Account", PurchaseLine."Line Amount");
        VerifyJobNoInGLEntry(DocumentNo, GeneralPostingSetup."Purch. Account", JobTask."Job No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithPrepmtPct()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        LineGLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PrepaymentPercent: Decimal;
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Prepayment %]
        // [SCENARIO 203803] Setting up a Prepayment % on Purchase Header and Verify Prepayment % change while Prepayment Line Amount field change on Purchase Line.

        // [GIVEN] 100 is required for Purchase Header as Prepayment %.
        Initialize();
        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        VendorNo := CreateVendorWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, VendorNo, ItemNo, 100, '');

        // [WHEN] Update Purchase Line. Dividing Line Amount by 2 to change Prepmt. Line Amount.
        PurchaseLine.Validate("Prepmt. Line Amount", PurchaseLine."Line Amount" / 2);
        PurchaseLine.Modify(true);
        PrepaymentPercent := (PurchaseLine."Prepmt. Line Amount" / PurchaseLine."Line Amount") * 100;

        // [THEN] Verify Purchase Line "Prepayment %" field.
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          PrepaymentPercent, PurchaseLine."Prepayment %", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(ValidationErr, PurchaseLine.FieldCaption("Prepayment %"), PrepaymentPercent));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithVAT()
    var
        PurchaseLine: Record "Purchase Line";
        PrepaymentAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [VAT]
        // [SCENARIO 203803] VAT Amount and Prepayment Amount in G/L Entry for Prepayment Purchase Order.

        // [GIVEN] Create Purchase Order and Post Prepayment Invoice. Take 100 as Prepayment Percent. Value Required for Test.
        Initialize();
        // [WHEN] Post Prepayment Invoice.
        // [THEN] Verify Posted Prepayment and VAT Amount in G/L Entry.
        CreateAndVerifyPurchPrepayment(PurchaseLine, PrepaymentAmount, 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtLineAmountErrorOnPartialPostedInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        // [FEATURE] [Purchase] [Prepayment %]
        // [SCENARIO 301615] Prepayment Line Amount Error while updating the Prepayment% on the Partial Posted Purchase Invoice.

        // [GIVEN] Update Quantity to Receive after Posting Prepayment Invoice and Post Purchase Order.
        Initialize();

        CreatePurchaseOrderWithPrepaymentVAT(PurchaseHeader, PurchaseLine, LibraryRandom.RandDec(50, 2));
        PurchasePostPrepayments.Invoice(PurchaseHeader);
        ModifyPurchaseQtyToReceive(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        UpdateVendorInvoiceNo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Reopen partially posted Purchase Order and Modify Prepayment %.
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        asserterror PurchaseHeader.Validate("Prepayment %", 100 - PurchaseHeader."Prepayment %" + LibraryRandom.RandInt(5));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderWithModifyUnitCost()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        LineGLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Receipt]
        // [SCENARIO 243217] GL Entry after Posting Prepayment Invoice with Purchase Order after modify Direct Unit Cost.

        // [GIVEN] Create and Post Purchase Order with Receive Option.
        Initialize();
        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        VendorNo := CreateVendorWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, VendorNo, ItemNo, 0, '');
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // [WHEN] Modify Purchase Receipt for Direct Unit Cost and Post with Invoice Option and Random Values.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost" + LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Verify GL Entry with Modified Amount.
        GeneralLedgerSetup.Get();
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          PurchaseLine."Line Amount", GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), PurchaseLine."Line Amount", GLEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmtCrMemoWithPaymentCode()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Payment Method]
        // [SCENARIO 375017] 100% Prepayment Credit Memo with Payment Method should reverse Prepayment Invoice with Payment Method

        // [GIVEN] Purchase Order, where "Prepayment %" is 100, "Payment Method" is "CASH"
        CreatePurchaseOrderWithPrepaymentVAT(PurchHeader, PurchLine, 100);
        PurchHeader.Validate("Payment Method Code", CreatePaymentMethodToGlAcc());
        PurchHeader.Modify(true);

        // [GIVEN] Posted Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);

        // [WHEN] Posted Prepayment Credit Memo
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchHeader);

        // [THEN] Prepayment Credit Memo Purch ledger entry is closed
        VendLedgEntry.SetRange("Vendor No.", PurchHeader."Buy-from Vendor No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");
        VendLedgEntry.FindLast();
        VendLedgEntry.TestField(Open, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmtInvoice()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        VendorPostingGroup: Record "Vendor Posting Group";
        LineGLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Amount: Decimal;
        AmountInclVAT: Decimal;
        DocumentNo: Code[20];
        VendorNo: Code[20];
        ItemNo: Code[20];
        PurchPrepaymentsAccount: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 242330] GL Entry and Posted Purchase Line with Prepayment Amount after Posting Prepayment Invoice.

        // [GIVEN] Update General Posting Setup and Create Purchase Order with Prepayment % with Random values.
        Initialize();
        PurchPrepaymentsAccount :=
          LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        VendorNo := CreateVendorWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);

        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, VendorNo, ItemNo, LibraryRandom.RandDec(10, 2), '');

        Amount := Round(PurchaseLine."Line Amount" * PurchaseLine."Prepayment %" / 100);
        AmountInclVAT := Round(Amount * (1 + PurchaseLine."Prepayment VAT %" / 100));

        // [WHEN] Post Purchase Order with Prepayment Invoice.
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Prepayment No. Series");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] Verify GL Entry and Posted Purchase Line with Prepayment Quantity and Amount.
        VendorPostingGroup.Get(PurchaseHeader."Vendor Posting Group");
        VerifyGLEntry(DocumentNo, PurchPrepaymentsAccount, Amount);
        VerifyGLEntry(DocumentNo, VendorPostingGroup."Payables Account", -AmountInclVAT);
        VerifyPurchInvLine(DocumentNo, PurchInvLine.Type::"G/L Account", PurchPrepaymentsAccount, 1, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmtInvoiceError()
    var
        LineGLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        Amount: Decimal;
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Prepayment Amount]
        // [SCENARIO 242330] Prepayment Amount Error on Purchase Order after Posting Prepayment Invoice and Purchase Invoice.

        // [GIVEN] Update General Posting Setup and Create Purchase Order with Prepayment % and Random Values.
        Initialize();
        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        VendorNo := CreateVendorWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, VendorNo, ItemNo, LibraryRandom.RandDec(10, 2), '');
        PurchasePostPrepayments.Invoice(PurchaseHeader);
        ModifyPurchaseQtyToInvoice(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");

        // Taking Vendor Invoice No. with Qty. to Invoice to make it Unique every time.
        UpdateVendorInvoiceNo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Try to Validate Prepayment Amount on Purchase Line with Less values.
        // Customized Formula is required to match the amount on Raised Error.
        PurchaseLine.Get(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        Amount :=
          PurchaseLine."Prepmt. Amt. Inv." - PurchaseLine."Prepmt Amt Deducted" -
          (PurchaseLine.Quantity - PurchaseLine."Qty. to Invoice" - PurchaseLine."Quantity Invoiced") * PurchaseLine."Direct Unit Cost";
        asserterror PurchaseLine.Validate(
            "Prepmt Amt to Deduct", PurchaseLine."Prepmt Amt to Deduct" - LibraryRandom.RandDec(10, 2));

        // [THEN] Verify Error during validate of Prepayment Amount to Deduct on Purchase Order after Posting Purchase Invoice.
        Assert.AreEqual(
          StrSubstNo(PurchasePrepaymentErr, PurchaseLine.FieldCaption("Prepmt Amt to Deduct"), Amount,
            PurchaseLine.TableCaption(), PurchaseLine.FieldCaption("Document Type"), PurchaseLine."Document Type",
            PurchaseLine.FieldCaption("Document No."), PurchaseLine."Document No.", PurchaseLine.FieldCaption("Line No."),
            PurchaseLine."Line No."), GetLastErrorText, ErrorValidateMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmtInvoiceWithCurrency()
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        LineGLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        PrepaymentAmount: Decimal;
        VendorNo: Code[20];
        ItemNo: Code[20];
        PurchPrepaymentsAccount: Code[20];
    begin
        // [FEATURE] [Purchase] [FCY]
        // [SCENARIO 240175] GL Entry for Prepayment Amount after Posting Purchase Prepayment Invoice with Currency.

        // [GIVEN] Update General Posting Setup and Create Purchase Order with Prepayment % and Currency with Random values.
        Initialize();
        LibraryERM.FindCurrency(Currency);
        PurchPrepaymentsAccount :=
          LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        VendorNo := CreateVendorWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);

        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, VendorNo, ItemNo, LibraryRandom.RandDec(10, 2), Currency.Code);
        PrepaymentAmount :=
          Round(LibraryERM.ConvertCurrency(PurchaseLine."Line Amount" * PurchaseLine."Prepayment %" / 100,
              PurchaseHeader."Currency Code", '', PurchaseHeader."Posting Date"));
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Prepayment No. Series");

        // [WHEN] Post Purchase Order with Prepayment Invoice.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] Verify Prepayment Amount in G/L Entry.
        FindGLEntry(GLEntry, DocumentNo, PurchPrepaymentsAccount);
        Assert.AreNearlyEqual(
          PrepaymentAmount, GLEntry.Amount, Currency."Invoice Rounding Precision",
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), PrepaymentAmount, GLEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmtInvoiceWithPartial()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorPostingGroup: Record "Vendor Posting Group";
        LineGLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        Amount: Decimal;
        AmountInclVAT: Decimal;
        PrepaymentAmount: Decimal;
        PrepaymentAmountInclVAT: Decimal;
        VendorNo: Code[20];
        ItemNo: Code[20];
        PurchPrepaymentsAccount: Code[20];
    begin
        // [FEATURE] [Purchase] [Final Invoice]
        // [SCENARIO 242330] GL Entry and Posted Purchase Line with Prepayment Amount after Posting Prepayment Invoice and Partial Qty. to Invoice.

        // [GIVEN] Update General Posting Setup and Create Purchase Order with Prepayment % with Random Values.
        Initialize();
        PurchPrepaymentsAccount :=
          LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        VendorNo := CreateVendorWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);

        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, VendorNo, ItemNo, LibraryRandom.RandDec(10, 2), '');
        PurchasePostPrepayments.Invoice(PurchaseHeader);
        ModifyPurchaseQtyToInvoice(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");

        Amount := Round(PurchaseLine."Qty. to Invoice" * PurchaseLine."Direct Unit Cost");
        PrepaymentAmount := Round(Amount * PurchaseLine."Prepayment %" / 100);
        AmountInclVAT := Round(PurchaseLine."Qty. to Invoice" * PurchaseLine."Direct Unit Cost" * (1 + PurchaseLine."VAT %" / 100));
        PrepaymentAmountInclVAT := Round(PrepaymentAmount * (1 + PurchaseLine."Prepayment VAT %" / 100));

        // Taking Vendor Invoice No. with Amount to make it Unique every time.
        UpdateVendorInvoiceNo(PurchaseHeader);
        // [WHEN] Post Purchase Order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify GL Entry and Posted Purchase Line with Partial PrePayment Amount and Quantity.
        PurchInvHeader.SetRange("Order No.", PurchaseLine."Document No.");
        PurchInvHeader.SetRange("Prepayment Invoice", false);
        PurchInvHeader.FindFirst();
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst();
        VerifyPurchInvLine(PurchInvLine."Document No.", PurchInvLine.Type::"G/L Account", PurchPrepaymentsAccount, -1, -PrepaymentAmount);
        VerifyPurchInvLine(PurchInvLine."Document No.", PurchInvLine.Type::Item, ItemNo, PurchaseLine."Qty. to Invoice", Amount);

        GeneralPostingSetup.Get(LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."Gen. Prod. Posting Group");
        VendorPostingGroup.Get(PurchaseHeader."Vendor Posting Group");
        VerifyGLEntry(PurchInvLine."Document No.", PurchPrepaymentsAccount, -PrepaymentAmount);
        VerifyGLEntry(PurchInvLine."Document No.", VendorPostingGroup."Payables Account", -(AmountInclVAT - PrepaymentAmountInclVAT));
        VerifyGLEntry(PurchInvLine."Document No.", GeneralPostingSetup."Purch. Account", Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmtPartialReceipt()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorPostingGroup: Record "Vendor Posting Group";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        DocumentNo: Code[20];
        Amount: Decimal;
        PrepaymentAmount: Decimal;
        PrepaymentVATAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Final Invoice]
        // [SCENARIO 243338] GL Entry for Prepayment Amount, VAT Amount after Posting Prepayment Invoice and Partial Qty. to Receive.

        // [GIVEN] Update Quantity to Receive after Posting Prepayment Invoice for Purchase Order.
        Initialize();
        CreatePurchaseOrderWithPrepaymentVAT(PurchaseHeader, PurchaseLine, LibraryRandom.RandDec(10, 2));
        PurchasePostPrepayments.Invoice(PurchaseHeader);
        ModifyPurchaseQtyToReceive(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        Amount := Round(PurchaseLine."Qty. to Receive" * PurchaseLine."Direct Unit Cost");
        PrepaymentAmount := Round(Amount * PurchaseHeader."Prepayment %" / 100);
        PrepaymentVATAmount := Round(PrepaymentAmount * PurchaseLine."VAT %" / 100);
        VATAmount := Round(Amount * PurchaseLine."VAT %" / 100);
        UpdateVendorInvoiceNo(PurchaseHeader);  // Updating new Invoice No.

        // [WHEN] Post Purchase Order
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify GL Entry for Prepayment Amount, VAT Amount and Partial Amount, Partial VAT Amount.
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VendorPostingGroup.Get(PurchaseHeader."Vendor Posting Group");
        VerifyAmountAndVATInGLEntry(DocumentNo, GeneralPostingSetup."Purch. Prepayments Account", -PrepaymentAmount, -PrepaymentVATAmount);
        VerifyAmountAndVATInGLEntry(DocumentNo, GeneralPostingSetup."Purch. Account", Amount, VATAmount);
        VerifyGLEntry(DocumentNo, VendorPostingGroup."Payables Account", -(Amount + VATAmount - PrepaymentAmount - PrepaymentVATAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceGetShipmentLine()
    var
        LineGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        VATAmount: Decimal;
        SalesPrepaymentsAccount: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Get Shipment Lines] [VAT]
        // [SCENARIO] Post Prepayment Sales Order as Ship. Post Invoice using Get Shipment Line functionality and Verify VAT and Prepayment Entry.

        // [GIVEN] Create Order and Post as Ship.
        // 100 is required for Purchase Header as Prepayment %.
        Initialize();

        SalesPrepaymentsAccount := LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType::"Normal VAT");
        CustomerNo := CreateCustomerWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);
        CreateSalesDocument(SalesHeader, SalesLine, CustomerNo, SalesLine.Type::Item, ItemNo, 100, '');
        VATAmount := SalesLine."Line Amount" * SalesLine."VAT %" / 100;
        // [GIVEN] Post Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Get Posted Sales Shipment and Post Invoice.
        DocumentNo := InvoicePostedSalesOrder(SalesHeader, SalesHeader."Sell-to Customer No.", DocumentNo, '', WorkDate());

        // [THEN] Verify Prepayment and VAT Amount in G/L Entry.
        VerifyGLEntry(DocumentNo, SalesPrepaymentsAccount, SalesLine."Line Amount");
        VATPostingSetup.Get(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        VerifyGLEntryPrepayment(DocumentNo, VATPostingSetup."Sales VAT Account", -VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceGetShipmentLines()
    var
        LineGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        VATAmount: Decimal;
        VATAmount2: Decimal;
        SalesPrepaymentsAccount: Code[20];
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // [FEATURE] [Sales] [Get Shipment Lines] [VAT]
        // [SCENARIO] Post Prepayment Sales Order as Ship. Post Invoice using Get Shipment Lines functionality and Verify VAT and Prepayment Entry.
        Initialize();

        SalesPrepaymentsAccount := LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType::"Normal VAT");
        CustomerNo := CreateCustomerWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);

        // [GIVEN] Create Order "A"  with 100% prepayment.
        CreateSalesDocument(SalesHeader, SalesLine, CustomerNo, SalesLine.Type::Item, ItemNo, 100, '');
        VATAmount := SalesLine."Line Amount" * SalesLine."VAT %" / 100;

        // [GIVEN] Create Order "B" with 100% prepayment.
        CreateSalesDocument(SalesHeader2, SalesLine2, CustomerNo, SalesLine.Type::Item, ItemNo, 100, '');
        VATAmount2 := SalesLine2."Line Amount" * SalesLine2."VAT %" / 100;

        // [GIVEN] Post Prepayment Invoice for Order "A".
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        // [GIVEN] Ship Sales Order "A"
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Post Prepayment Invoice for Order "B".
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader2);
        // [GIVEN] Ship Sales Order "B"
        DocumentNo2 := LibrarySales.PostSalesDocument(SalesHeader2, true, false);

        // [WHEN] Get Posted Sales Shipment and Post Invoice.
        DocumentNo :=
          InvoicePostedSalesOrder(SalesHeader, SalesHeader."Sell-to Customer No.", StrSubstNo('%1|%2', DocumentNo, DocumentNo2), '', WorkDate());

        // [THEN] Verify Prepayment and VAT Amount in G/L Entry.
        VerifyGLEntry(DocumentNo, SalesPrepaymentsAccount, SalesLine."Line Amount" + SalesLine2."Line Amount");
        VATPostingSetup.Get(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        VerifyGLEntryPrepayment(DocumentNo, VATPostingSetup."Sales VAT Account", -VATAmount - VATAmount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithPrepmtPct()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        LineGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PrepaymentPercent: Decimal;
        CustomerNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Prepayment %]
        // [SCENARIO 203803] Setting up a Prepayment % on Sales Header and Verify Prepayment % change while Prepayment Line Amount field change on Sales Line.

        // [GIVEN] 100 is required for Purchase Header as Prepayment %.
        Initialize();
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        CustomerNo := CreateCustomerWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);
        CreateSalesDocument(SalesHeader, SalesLine, CustomerNo, SalesLine.Type::Item, ItemNo, 100, '');

        // [WHEN] Update Sales Line. Dividing Line Amount by 2 to change Prepmt. Line Amount.
        SalesLine.Validate("Prepmt. Line Amount", SalesLine."Line Amount" / 2);
        SalesLine.Modify(true);
        PrepaymentPercent := (SalesLine."Prepmt. Line Amount" / SalesLine."Line Amount") * 100;

        // [THEN] Verify Sales Line "Prepayment %" field.
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          PrepaymentPercent, SalesLine."Prepayment %", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(ValidationErr, SalesLine.FieldCaption("Prepayment %"), PrepaymentPercent));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithVAT()
    var
        SalesLine: Record "Sales Line";
        PrepaymentAmount: Decimal;
    begin
        // [FEATURE] [Sales] [VAT]
        // [SCENARIO 203803] VAT Amount and Prepayment Amount in G/L Entry for Prepayment Sales Order.

        // [GIVEN] Create Sales Order and Post Prepayment Invoice. Take 100 as Prepayment Percent. Value Required for Test.
        Initialize();
        // [WHEN] Post Prepayment Invoice.
        // [THEN] Verify Posted Prepayment and VAT Amount in G/L Entry.
        CreateAndVerifySalesPrepayment(SalesLine, PrepaymentAmount, 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtCrMemoWithPaymentCode()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Credit Memo] [Payment Method]
        // [SCENARIO 375017] 100% Prepayment Credit Memo with Payment Method should reverse Prepayment Invoice with Payment Method
        Initialize();
        // [GIVEN] Sales Order, where "Prepayment %" is 100, "Payment Method" is "CASH"
        CreateSalesOrderWithPrepaymentVAT(SalesHeader, SalesLine, 100);
        SalesHeader.Validate("Payment Method Code", CreatePaymentMethodToGlAcc());
        SalesHeader.Modify(true);

        // [GIVEN] Posted Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Posted Prepayment Credit Memo
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);

        // [THEN] Prepayment Credit Memo sales ledger entry is closed
        CustLedgEntry.SetRange("Customer No.", SalesHeader."Sell-to Customer No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::"Credit Memo");
        CustLedgEntry.FindLast();
        CustLedgEntry.TestField(Open, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtInvoice()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        CustomerPostingGroup: Record "Customer Posting Group";
        LineGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        Amount: Decimal;
        AmountInclVAT: Decimal;
        PrepmtGLAccountNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Prepayment Invoice]
        // [SCENARIO 242329] GL Entry and Posted Sales Line with Prepayment Amount after Posting Prepayment Invoice.

        // [GIVEN] Update General Posting Setup and Create Sales Order with Prepayment %.
        Initialize();
        PrepmtGLAccountNo := LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        CustomerNo :=
          LibrarySales.CreateCustomerWithBusPostingGroups(
            LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        CreateSalesDocument(
          SalesHeader, SalesLine, CustomerNo, SalesLine.Type::"G/L Account", LineGLAccount."No.", LibraryRandom.RandDec(10, 2), '');
        Amount := Round(SalesLine."Line Amount" * SalesLine."Prepayment %" / 100);
        AmountInclVAT := Round(Amount * (1 + SalesLine."Prepayment VAT %" / 100));
        DocumentNo := GetPostedDocumentNo(SalesHeader."Prepayment No. Series");

        // [WHEN] Post Prepayment Invoice on Sales Order.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Verify GL Entry and Sales Invoice Line with GL Account Entry and prepayment Amount.
        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");
        VerifyGLEntry(DocumentNo, PrepmtGLAccountNo, -Amount);
        VerifyGLEntry(DocumentNo, CustomerPostingGroup."Receivables Account", AmountInclVAT);
        VerifySalesInvoiceLine(DocumentNo, SalesInvoiceLine.Type::"G/L Account", PrepmtGLAccountNo, 1, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtInvoiceError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineGLAccount: Record "G/L Account";
        Amount: Decimal;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Prepayment Amount]
        // [SCENARIO 242329] Prepayment Amount Error on Sales Order after Posting Prepayment Invoice and Invoice.

        // [GIVEN] Update General Posting Setup and Create Sales Order with Prepayment %.
        Initialize();
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        CustomerNo :=
          LibrarySales.CreateCustomerWithBusPostingGroups(
            LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        CreateSalesDocument(
          SalesHeader, SalesLine, CustomerNo, SalesLine.Type::"G/L Account", LineGLAccount."No.", LibraryRandom.RandDec(10, 2), '');
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        ModifySalesQtyToInvoice(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Try to Validate Prepayment Amount on Sales Line with Less Values.
        // Customized Formula is required to match the amount on Raised Error.
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        Amount :=
          SalesLine."Prepmt. Amt. Inv." - SalesLine."Prepmt Amt Deducted" -
          (SalesLine.Quantity - SalesLine."Qty. to Invoice" - SalesLine."Quantity Invoiced") * SalesLine."Unit Price";
        asserterror SalesLine.Validate("Prepmt Amt to Deduct", SalesLine."Prepmt Amt to Deduct" - LibraryRandom.RandDec(10, 2));

        // [THEN] Verify Error during validate of Prepayment Amount to Deduct on Sales Order after Posting Sales Invoice.
        Assert.AreEqual(
          StrSubstNo(SalesPrepaymentErr, SalesLine.FieldCaption("Prepmt Amt to Deduct"), Amount, SalesLine.TableCaption(),
            SalesLine.FieldCaption("Document Type"), SalesLine."Document Type", SalesLine.FieldCaption("Document No."), SalesLine.
            "Document No.", SalesLine.FieldCaption("Line No."), SalesLine."Line No."), GetLastErrorText, 'Error must be same');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtInvoiceWithCurrency()
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        LineGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        PrepaymentAmount: Decimal;
        CustomerNo: Code[20];
        PrepmtGLAccountNo: Code[20];
    begin
        // [FEATURE] [Sales] [FCY]
        // [SCENARIO 240175] GL Entry for Prepayment Amount after Posting Sales Prepayment Invoice with Currency.

        // [GIVEN] Update General Posting Setup and Create Sales Order with Prepayment % and Currency with Random values.
        Initialize();
        LibraryERM.FindCurrency(Currency);
        PrepmtGLAccountNo := LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        CustomerNo :=
          LibrarySales.CreateCustomerWithBusPostingGroups(
            LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        CreateSalesDocument(
          SalesHeader, SalesLine, CustomerNo, SalesLine.Type::"G/L Account", LineGLAccount."No.", LibraryRandom.RandDec(10, 2), Currency.Code);
        PrepaymentAmount :=
          Round(LibraryERM.ConvertCurrency(SalesLine."Line Amount" * SalesHeader."Prepayment %" / 100,
              SalesHeader."Currency Code", '', SalesHeader."Posting Date"));
        DocumentNo := GetPostedDocumentNo(SalesHeader."Prepayment No. Series");

        // [WHEN] Post Prepayment Invoice on Sales Order.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Verify G/L Entry for posted Prepayment Invoice.
        FindGLEntry(GLEntry, DocumentNo, PrepmtGLAccountNo);
        Assert.AreNearlyEqual(
          -PrepaymentAmount, GLEntry.Amount, Currency."Invoice Rounding Precision",
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), -PrepaymentAmount, GLEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtInvoiceWithPartial()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CustomerPostingGroup: Record "Customer Posting Group";
        LineGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        Amount: Decimal;
        AmountInclVAT: Decimal;
        PrepmtGLAccountNo: Code[20];
        PrepaymentAmount: Decimal;
        PrepaymentAmountInclVAT: Decimal;
    begin
        // [FEATURE] [Sales] [Final Invoice]
        // [SCENARIO 242329] GL Entry and Posted Sales Line with Prepayment Amount after Posting Prepayment Invoice and Partial Qty. to Invoice.

        // [GIVEN] Update General Posting Setup and Create Sales Order with Prepayment %.
        Initialize();
        PrepmtGLAccountNo := LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        CustomerNo :=
          LibrarySales.CreateCustomerWithBusPostingGroups(
            LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        CreateSalesDocument(
          SalesHeader, SalesLine, CustomerNo, SalesLine.Type::"G/L Account", LineGLAccount."No.", LibraryRandom.RandDec(10, 2), '');
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        ModifySalesQtyToInvoice(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");

        Amount := Round(SalesLine."Qty. to Invoice" * SalesLine."Unit Price");
        PrepaymentAmount := Round(Amount * SalesLine."Prepayment %" / 100);
        AmountInclVAT := Round(SalesLine."Qty. to Invoice" * SalesLine."Unit Price" * (1 + SalesLine."VAT %" / 100));
        PrepaymentAmountInclVAT := Round(PrepaymentAmount * (1 + SalesLine."Prepayment VAT %" / 100));

        // [WHEN] Post Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify GL Entry and Sales Invoice Line for Prepayment Amount after Posting Sales Order with Partial Qty. to Invoice.
        SalesInvoiceHeader.SetRange("Order No.", SalesLine."Document No.");
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        VerifySalesInvoiceLine(
          SalesInvoiceLine."Document No.", SalesInvoiceLine.Type::"G/L Account", PrepmtGLAccountNo, -1, -PrepaymentAmount);
        VerifySalesInvoiceLine(
          SalesInvoiceLine."Document No.", SalesInvoiceLine.Type::"G/L Account", LineGLAccount."No.", SalesLine."Qty. to Invoice", Amount);

        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");
        VerifyGLEntry(SalesInvoiceLine."Document No.", PrepmtGLAccountNo, PrepaymentAmount);
        VerifyGLEntry(
          SalesInvoiceLine."Document No.", CustomerPostingGroup."Receivables Account",
          AmountInclVAT - PrepaymentAmountInclVAT);
        VerifyGLEntry(SalesInvoiceLine."Document No.", LineGLAccount."No.", -Amount);
    end;

    [Test]
    [HandlerFunctions('VerifyNoOfGetShipmentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesPrepmtLinesInGetShpmtLines()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Get Shipment Lines]
        // [SCENARIO] Get Shipment Lines shows lines from Sales Order that has prepayment.

        // [GIVEN] Ship twice Sales Order with non-zero Prepayment %
        Initialize();
        LibraryVariableStorage.Enqueue(2);
        PrepareShptLinesWithPrepmtPerc(SalesLine, LibraryRandom.RandIntInRange(1, 99), true);

        // [WHEN] "Get Shipment Lines" on the new Invoice
        CODEUNIT.Run(CODEUNIT::"Sales-Get Shipment", SalesLine);

        // [THEN] 2 Shipment Lines are in the list
        // Verification in VerifyNoOfGetShipmentLinesPageHandler
    end;

    [Test]
    [HandlerFunctions('VerifyNoOfGetShipmentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesLinesInGetShpmtLinesNoPrepmt()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Get Shipment Lines]
        // [SCENARIO 341471] Get Shipment Lines shows lines from Sales Order that doesn't have prepayment.

        // [GIVEN] Ship twice Sales Order with zero Prepayment %
        Initialize();
        LibraryVariableStorage.Enqueue(2);
        PrepareShptLinesWithPrepmtPerc(SalesLine, 0, true);

        // [WHEN] "Get Shipment Lines" on the new Invoice
        CODEUNIT.Run(CODEUNIT::"Sales-Get Shipment", SalesLine);

        // [THEN] 2 Shipment Lines are in the list
        // Verification in VerifyNoOfGetShipmentLinesPageHandler
    end;

    [Test]
    [HandlerFunctions('VerifyNoOfGetReceiptLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchPrepmtLinesInGetRcptLines()
    var
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Get Receipt Lines]
        // [SCENARIO] Get Receipt Lines shows lines from Purchase Order that has prepayment.

        // [GIVEN] Receive twice Purchase Order with non-zero Prepayment %
        Initialize();
        LibraryVariableStorage.Enqueue(2);
        PrepareRcptLinesWithPrepmtPerc(PurchLine, LibraryRandom.RandIntInRange(1, 99), true);

        // [WHEN] "Get Receipt Lines" on the new Invoice
        CODEUNIT.Run(CODEUNIT::"Purch.-Get Receipt", PurchLine);

        // [THEN] 2 Receipt Lines are in the list
        // Verification in VerifyNoOfGetReceiptLinesPageHandler
    end;

    [Test]
    [HandlerFunctions('VerifyNoOfGetReceiptLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchLinesInGetRcptLinesNoPrepmt()
    var
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Get Receipt Lines]
        // [SCENARIO 341471] Get Receipt Lines shows lines from Purchase Order that doesn't have prepayment.

        // [GIVEN] Receive twice Purchase Order with zero Prepayment %
        Initialize();
        LibraryVariableStorage.Enqueue(2);
        PrepareRcptLinesWithPrepmtPerc(PurchLine, 0, true);

        // [WHEN] "Get Receipt Lines" on the new Invoice
        CODEUNIT.Run(CODEUNIT::"Purch.-Get Receipt", PurchLine);

        // [THEN] 2 Receipt Lines are in the list
        // Verification in VerifyNoOfGetReceiptLinesPageHandler
    end;

    [Test]
    [HandlerFunctions('VerifyNoOfGetShipmentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesLinesInGetShpmtLinesWithPrepmtAndFullShip()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Get Shipment Lines]
        // [SCENARIO 352832] Get Shipment Lines shows lines from Sales Order that has prepayment and fully shipped.

        // [GIVEN] Ship once Sales Order with non-zero Prepayment %
        Initialize();
        LibraryVariableStorage.Enqueue(1);
        PrepareShptLinesWithPrepmtPerc(SalesLine, LibraryRandom.RandIntInRange(1, 50), false);

        // [WHEN] "Get Shipment Lines" on the new Invoice
        LibrarySales.GetShipmentLines(SalesLine);
        // [THEN] Shipment Line is in the list
        // Verification in VerifyNoOfGetShipmentLinesPageHandler
    end;

    [Test]
    [HandlerFunctions('VerifyNoOfGetReceiptLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchLinesInGetRcptLinesWithPrepmtAndFullRecpt()
    var
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Get Receipt Lines]
        // [SCENARIO 352832] Get Receipt Lines shows lines from Purchase Order that has prepayment and fully received.

        // [GIVEN] Receive once Purchase Order with non-zero Prepayment %
        Initialize();
        LibraryVariableStorage.Enqueue(1);
        PrepareRcptLinesWithPrepmtPerc(PurchLine, LibraryRandom.RandIntInRange(1, 50), false);

        // [WHEN] "Get Receipt Lines" on the new Invoice
        CODEUNIT.Run(CODEUNIT::"Purch.-Get Receipt", PurchLine);
        // [THEN] Receipt Line is in the list
        // Verification in VerifyNoOfGetShipmentLinesPageHandler
    end;

    [Test]
    [HandlerFunctions('VerifyDocNoInGetReceiptLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CheckDocNoInGetRcptLines()
    var
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Get Receipt Lines]
        // [SCENARIO 351945] Lines in Get receipt Lines have non-empty Document No.

        // [GIVEN] Receive twice Purchase Order with zero Prepayment %
        Initialize();
        PrepareSeveralRcptLinesWithPrepmtPerc(PurchLine, 0, 2);

        // [WHEN] "Get Receipt Lines" on the new Invoice
        CODEUNIT.Run(CODEUNIT::"Purch.-Get Receipt", PurchLine);

        // [THEN] Lines in the list have no non-empty "Document No."
        // Verification is in VerifyDocNoInGetReceiptLinesPageHandler
    end;

    [Test]
    [HandlerFunctions('VerifyDocNoInGetShipmentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CheckDocNoInGetShptLines()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Get Shipment Lines]
        // [SCENARIO 351945] Lines in Get Shipment Lines have non-empty Document No.

        // [GIVEN] Ship twice Sales Order with zero Prepayment %
        Initialize();
        PrepareSeveralShptLinesWithPrepmtPerc(SalesLine, 0, 2);

        // [WHEN] "Get Shipment Lines" on the new Invoice
        CODEUNIT.Run(CODEUNIT::"Sales-Get Shipment", SalesLine);

        // [THEN] Lines in the list have no non-empty "Document No."
        // Verification is in VerifyDocNoInGetShipmentLinesPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtLineAmountErrorOnPartialPostedInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Prepayment %]
        // [SCENARIO 301615] Prepayment Line Amount Error while updating the Prepayment% on the Partial Posted Sales Invoice.

        // [GIVEN] Update Quantity to Ship after Posting Prepayment Invoice and Post Sales Order.
        Initialize();
        CreateSalesOrderWithPrepaymentVAT(SalesHeader, SalesLine, LibraryRandom.RandDec(50, 2));
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        ModifySalesQtyToShip(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Open Partial Posted Sales Order.
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [THEN] Error will pop-up after updating Prepayment %.
        asserterror SalesHeader.Validate("Prepayment %", 100 - SalesHeader."Prepayment %" + LibraryRandom.RandInt(5));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtPartialShipment()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepmtAccount: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
        PrepaymentAmount: Decimal;
        PrepaymentVATAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Sales] [VAT]
        // [SCENARIO 243338] GL Entry for Prepayment Amount, VAT Amount after Posting Prepayment Invoice and Partial Qty. to Ship.

        // [GIVEN] Update Quantity to Ship after Posting Prepayment Invoice for Sales Order.
        Initialize();
        SalesPrepmtAccount := CreateSalesOrderWithPrepaymentVAT(SalesHeader, SalesLine, LibraryRandom.RandDec(10, 2));
        SalesHeader.Get(SalesLine."Document Type"::Order, SalesLine."Document No.");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        ModifySalesQtyToShip(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        DocumentNo := GetPostedDocumentNo(SalesHeader."Posting No. Series");
        Amount := Round(SalesLine."Qty. to Ship" * SalesLine."Unit Price");
        VATAmount := Round(Amount * SalesLine."VAT %" / 100);
        PrepaymentAmount := Round(Amount * SalesHeader."Prepayment %" / 100);
        PrepaymentVATAmount := Round(PrepaymentAmount * SalesLine."VAT %" / 100);

        // [WHEN] Post Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify different GL Entries for Amount and VAT Amount.
        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");
        VerifyAmountAndVATInGLEntry(DocumentNo, SalesPrepmtAccount, PrepaymentAmount, PrepaymentVATAmount);
        VerifyAmountAndVATInGLEntry(DocumentNo, SalesLine."No.", -Amount, -VATAmount);
        VerifyGLEntry(
          DocumentNo, CustomerPostingGroup."Receivables Account", (Amount + VATAmount - PrepaymentAmount - PrepaymentVATAmount));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesPrepmtWithCurrency()
    var
        InventorySetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        AmountLCY: Decimal;
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Sales] [FCY]
        // [SCENARIO 243217] GL Entry after Posting Prepayment Sales Invoice with Currency.

        // [GIVEN] Update General Ledger, Inventory Setup and Create Sales Prepayment Invoice.
        Initialize();
        InventorySetup.Get();
        UpdateInventorySetup(true, InventorySetup."Automatic Cost Adjustment"::Always);
        GLAccountNo := SetupAndCreateSalesPrepayment(SalesLine, LibraryRandom.RandDec(10, 2));

        // [WHEN] Post Sales Prepayment Invoice
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        AmountLCY := Round(LibraryERM.ConvertCurrency(SalesLine."Prepmt. Line Amount", SalesHeader."Currency Code", '', WorkDate()));
        DocumentNo := GetPostedDocumentNo(SalesHeader."Prepayment No. Series");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Verify GL Entry Amount after Conversion with Currency Exchange Rate.
        VerifyGLEntry(DocumentNo, GLAccountNo, -AmountLCY);

        // Tear Down.
        UpdateInventorySetup(InventorySetup."Automatic Cost Posting", InventorySetup."Automatic Cost Adjustment");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesPrepmtWithModifyCurrency()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InventorySetup: Record "Inventory Setup";
        SalesOrder: TestPage "Sales Order";
        SalesPrepaymentsAccount: Code[20];
        DocumentNo: Code[20];
        AmountLCY: Decimal;
        PrePaymentAmount: Decimal;
    begin
        // [FEATURE] [Sales] [FCY]
        // [SCENARIO 243217] GL Entry after Posting Prepayment Sales Invoice and Post as Invoice after modify Currency exchange rate.

        // [GIVEN] Update General Ledger, Inventory Setup and Create Sales Prepayment Invoice.
        Initialize();
        InventorySetup.Get();
        UpdateInventorySetup(true, InventorySetup."Automatic Cost Adjustment"::Always);
        SalesPrepaymentsAccount := SetupAndCreateSalesPrepayment(SalesLine, LibraryRandom.RandDec(10, 2));
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Reopen Posted Prepayment Inovice and Modify Exchange Rate.
        LibrarySales.ReopenSalesDocument(SalesHeader);
        ModifyExchangeRate(SalesHeader."Currency Code");
        AmountLCY := Round(LibraryERM.ConvertCurrency(SalesLine."Line Amount", SalesHeader."Currency Code", '', WorkDate()));
        PrePaymentAmount := Round(LibraryERM.ConvertCurrency(SalesLine."Prepmt. Line Amount", SalesHeader."Currency Code", '', WorkDate()));

        // [GIVEN] Modify Currency again on Sales Header through page.
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder."Currency Code".SetValue(SalesHeader."Currency Code");

        // [WHEN] Post Sales Order.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DocumentNo := GetPostedDocumentNo(SalesHeader."Posting No. Series");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify GL Entry Amount and Prepayment amount with Different GL Account No.
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyGLEntry(DocumentNo, GeneralPostingSetup."Sales Account", -AmountLCY);
        VerifyGLEntry(DocumentNo, SalesPrepaymentsAccount, PrePaymentAmount);

        // Tear Down.
        UpdateInventorySetup(InventorySetup."Automatic Cost Posting", InventorySetup."Automatic Cost Adjustment");
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchaseHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderwithPartialReceiveAndInv()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        LineGLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        DocumentNo: Code[20];
        ExpectedAmount: Decimal;
        Quantity: Decimal;
    begin
        // [FEATURE] [Purchase] [Item Charges]
        // [SCENARIO 327577] Purchase line for Item Charges is posted with prepayment
        Initialize();

        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        // [GIVEN] Create Vendor Purchase Order with prepayment
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Vendor.Modify(true);
        CreatePurchHeaderPrepaymentPercentage(PurchHeader, Vendor."No.");
        CreatePurchLineQtyToReceive(PurchLine, PurchHeader, LineGLAccount);
        // [GIVEN] Create Purchase Line or Item Charges
        Quantity := CreatePurchLineWithItemCharge(PurchLine, PurchHeader, LineGLAccount);
        // [GIVEN] Post Purchase Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);
        // [GIVEN] Receive Purchase Order
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);
        ExpectedAmount := UpdateItemChargeQtyToAssign(PurchLine, Quantity);
        PurchHeader.Validate("Vendor Invoice No.", PurchHeader."Buy-from Vendor No.");
        PurchHeader.Modify(true);
        // [WHEN] Post Purchase Order
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, false, true);

        // [THEN] Verify balance on "Purch. Account" in G/L
        GeneralPostingSetup.Get(LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."Gen. Prod. Posting Group");
        VerifyGLEntryAmountForPurch(DocumentNo, GeneralPostingSetup."Purch. Account", ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentCreditMemoWithJobJobTask()
    var
        GLAccount: Record "G/L Account";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        JobTask: Record "Job Task";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Job]
        // [SCENARIO 363786] Job No. and Job Task No. filled in Purch. Cr. Memo Line when prepayment Credit Memo with Job No. is posted.
        Initialize();

        // [GIVEN] Job = X, Job Task = Y.
        CreateJobTask(JobTask);

        // [GIVEN] Purchase Order with "Job No." = X, "Job Task No." = Y on Purchase Line.
        LibraryPurchase.CreatePrepaymentVATSetup(GLAccount, VATCalculationType);
        CreatePurchaseOrderWithJob(
          PurchaseLine, CreateVendorWithPostingSetup(GLAccount),
          CreateItemWithPostingSetup(GLAccount), LibraryRandom.RandInt(10), JobTask."Job No.", JobTask."Job Task No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post Prepayment Credit Memo.
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Prepmt. Cr. Memo No. Series");
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchaseHeader);

        // [THEN] Prepayment Purch. Cr. Memo Line "Job No." = X, "Job Task No." = Y
        VerifyPurchCrMemoLineJobNoJobTaskNo(DocumentNo, JobTask."Job No.", JobTask."Job Task No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GainLossOfPurchaseInvoiceForPartialReceiptWith100PctPrepaymentInFCY()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Currency: Record Currency;
        InvoiceNo: Code[20];
        ReceiptNo1: Code[20];
        ReceiptNo2: Code[20];
        AmountLCYPrepmt: Decimal;
        AmountLCYInvoice: Decimal;
        InvPostingDate: Date;
    begin
        // [FEATURE] [Purchase] [FCY]
        // [SCENARIO 380692] Gain/Loss Entries of Purchase Invoice for partially received FCY Purchase Order with Full Prepayment
        Initialize();

        // [GIVEN] Currency with Exch.Rates on 01-10-16 and 15-10-16
        SetupAndCreatePurchasePrepayment(PurchaseLine, 100);
        InvPostingDate := LibraryRandom.RandDate(5);
        CreateCurrencyExchRateOnDate(PurchaseLine."Currency Code", InvPostingDate);

        // [GIVEN] 100% Prepayment Invoice posted on 01-10-16 with Amount LCY = 100
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        AmountLCYPrepmt :=
          Round(LibraryERM.ConvertCurrency(PurchaseLine."Prepmt. Line Amount", PurchaseHeader."Currency Code", '', WorkDate()));
        AmountLCYInvoice :=
          Round(LibraryERM.ConvertCurrency(PurchaseLine."Prepmt. Line Amount", PurchaseHeader."Currency Code", '', InvPostingDate));
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Partially received Purchase Order
        ModifyPurchaseQtyToReceive(PurchaseLine, PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        ReceiptNo1 := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        ReceiptNo2 := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Get Posted Purchase Receipt and Post Invoice on 15-10-16 with Amount LCY = 150
        InvoiceNo :=
          InvoicePostedPurchaseOrder(
            PurchaseHeader, PurchaseHeader."Buy-from Vendor No.", StrSubstNo('%1|%2', ReceiptNo1, ReceiptNo2),
            PurchaseHeader."Currency Code", InvPostingDate);

        // [THEN] "Realized Gains Acc." in G/L Entry has Amount = -50
        Currency.Get(PurchaseHeader."Currency Code");
        VerifyGLEntry(InvoiceNo, Currency."Realized Gains Acc.", AmountLCYPrepmt - AmountLCYInvoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GainLossOfSalesInvoiceForPartialShipmentWith100PctPrepaymentInFCY()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Currency: Record Currency;
        InvoiceNo: Code[20];
        ShipmentNo1: Code[20];
        ShipmentNo2: Code[20];
        AmountLCYPrepmt: Decimal;
        AmountLCYInvoice: Decimal;
        InvPostingDate: Date;
    begin
        // [FEATURE] [Sales] [FCY]
        // [SCENARIO 380692] Gain/Loss Entries of Sales Invoice for partially received FCY Sales Order with Full Prepayment
        Initialize();

        // [GIVEN] Currency with Exch.Rates on 01-10-16 and 15-10-16
        SetupAndCreateSalesPrepayment(SalesLine, 100);
        InvPostingDate := LibraryRandom.RandDate(5);
        CreateCurrencyExchRateOnDate(SalesLine."Currency Code", InvPostingDate);

        // [GIVEN] 100% Prepayment Invoice posted on 01-10-16 with Amount LCY = 100
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        AmountLCYPrepmt :=
          Round(LibraryERM.ConvertCurrency(SalesLine."Prepmt. Line Amount", SalesHeader."Currency Code", '', WorkDate()));
        AmountLCYInvoice :=
          Round(LibraryERM.ConvertCurrency(SalesLine."Prepmt. Line Amount", SalesHeader."Currency Code", '', InvPostingDate));
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Partially shipped Sales Order
        ModifySalesQtyToShip(SalesLine, SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        ShipmentNo1 := LibrarySales.PostSalesDocument(SalesHeader, true, false);
        ShipmentNo2 := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Get Posted Sales Shipment and Post Invoice on 15-10-16 with Amount LCY = 150
        InvoiceNo :=
          InvoicePostedSalesOrder(
            SalesHeader, SalesHeader."Sell-to Customer No.", StrSubstNo('%1|%2', ShipmentNo1, ShipmentNo2),
            SalesHeader."Currency Code", InvPostingDate);

        // [THEN] "Realized Losses Acc." in G/L Entry has Amount = 50
        Currency.Get(SalesHeader."Currency Code");
        VerifyGLEntry(InvoiceNo, Currency."Realized Losses Acc.", -AmountLCYPrepmt + AmountLCYInvoice);
    end;


    [Test]
    [Scope('OnPrem')]
    procedure CalculateInvoiceDisAutomaticWith100PctPrepayment()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Customer: Record Customer;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        LineGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        Salesline: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
        PrepmtGLAccountNo: Code[20];
        ItemNo: Code[20];
        CustomerNo: Code[20];
        CalcInvDiscountValues: Boolean;
    begin
        // Initialize
        Initialize();
        SalesReceivablesSetup.Get();
        CalcInvDiscountValues := SalesReceivablesSetup."Calc. Inv. Discount";
        SalesReceivablesSetup."Calc. Inv. Discount" := true;
        SalesReceivablesSetup.Modify();

        // [FEATURE] [Sales] [Invocie Discount]
        // [SCENARIO 453057] Given a Sales order for a customer with automatic invoice calclulation set up.
        PrepmtGLAccountNo := LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        CustomerNo :=
          LibrarySales.CreateCustomerWithBusPostingGroups(
            LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);
        CreateSalesDocument(
          SalesHeader, SalesLine, CustomerNo, SalesLine.Type::Item, ItemNo, 100, ''); // Full prepayment
        GeneralPostingSetup.get(Salesline."Gen. Bus. Posting Group", Salesline."Gen. Prod. Posting Group");
        GeneralPostingSetup."Sales Inv. Disc. Account" := GeneralPostingSetup."Sales Account";
        GeneralPostingSetup.Modify();
        Customer.get(CustomerNo);
        If not CustInvoiceDisc.Get(Customer."Invoice Disc. Code", Customer."Currency Code") then begin
            CustInvoiceDisc.Code := Customer."No.";
            CustInvoiceDisc."Currency Code" := Customer."Currency Code";
            CustInvoiceDisc.Insert();
        end;
        CustInvoiceDisc."Discount %" := 10; // Value is not important
        CustInvoiceDisc.Modify();

        // When Post the prepayment order 
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Then Sales order should be posted 
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Restore
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Calc. Inv. Discount" := CalcInvDiscountValues;
        SalesReceivablesSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseSalesOrderWithNotPostedPrepayment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 217427] User cannot release Sales Order when Prepayment Invoice is not posted
        Initialize();

        // [GIVEN] Sales Order with prepayment
        SetupAndCreateSalesPrepayment(SalesLine, LibraryRandom.RandDec(100, 2));
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        Commit();

        // [WHEN] Release Sales Order
        asserterror LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [THEN] Status of Sales Order is Open
        SalesHeader.Find();
        SalesHeader.TestField(Status, SalesHeader.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedSalesOrderWithPostedPrepayment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 217427] Sales Order has Status 'Pending Prepayment' when Prepayment Invoice is posted
        Initialize();
        SetupAndCreateSalesPrepayment(SalesLine, LibraryRandom.RandDec(100, 2));
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // [WHEN] Post Sales Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Status of Sales Order is 'Pending Prepayment'
        SalesHeader.Find();
        SalesHeader.TestField(Status, SalesHeader.Status::"Pending Prepayment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasePurchaseOrderWithNotPostedPrepayment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 217427] User cannot release Purchase Order when Prepayment Invoice is not posted
        Initialize();

        // [GIVEN] Purchase Order with prepayment
        SetupAndCreatePurchasePrepayment(PurchaseLine, LibraryRandom.RandDec(100, 2));
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        Commit();

        // [WHEN] Release Purchase Order
        asserterror LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [THEN] Status of Purchase Order is Open
        PurchaseHeader.Find();
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedPurchaseOrderWithPostedPrepayment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 217427]
        Initialize();
        SetupAndCreatePurchasePrepayment(PurchaseLine, LibraryRandom.RandDec(100, 2));
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [WHEN] Post Sales Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] Status of Purchase Order is 'Pending Prepayment'
        PurchaseHeader.Find();
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::"Pending Prepayment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtAutoUpdateFrequencyOnSalesSetup()
    var
        SalesReceivablesSetup: TestPage "Sales & Receivables Setup";
    begin
        // [FEATURE] [UT] [UI] [Sales] [Prepmt. Auto Update]
        // [SCENARIO 273807] Prepmt. Auto Update Frequency is accessible and editable on Sales & Receivables Setup page
        Initialize();
        LibraryApplicationArea.EnablePrepaymentsSetup();
        SalesReceivablesSetup.OpenEdit();
        Assert.IsTrue(
          SalesReceivablesSetup."Prepmt. Auto Update Frequency".Enabled(), '');
        Assert.IsTrue(
          SalesReceivablesSetup."Prepmt. Auto Update Frequency".Editable(), '');
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtAutoUpdateFrequencyOnPurchaseSetup()
    var
        PurchasesPayablesSetup: TestPage "Purchases & Payables Setup";
    begin
        // [FEATURE] [UT] [UI] [Purchase] [Prepmt. Auto Update]
        // [SCENARIO 273807] Prepmt. Auto Update Frequency is accessible and editable on Purchases & Payables Setup page
        Initialize();
        LibraryApplicationArea.EnablePrepaymentsSetup();
        PurchasesPayablesSetup.OpenEdit();
        Assert.IsTrue(
          PurchasesPayablesSetup."Prepmt. Auto Update Frequency".Enabled(), '');
        Assert.IsTrue(
          PurchasesPayablesSetup."Prepmt. Auto Update Frequency".Editable(), '');
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePendingPrepmtSalesWithCheckPrepmtWhenPostingNo()
    var
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        PrepmtInvoiceNo1: Code[20];
        PrepmtInvoiceNo2: Code[20];
    begin
        // [FEATURE] [Sales] [Prepmt. Auto Update]
        // [SCENARIO 273807] Status in sales order with paid and not paid prepayments is changed to 'Released' from 'Pending Prepayment'
        // [SCENARIO 273807] when "Check Prepmt. when Posting" is No in Sales Setup
        Initialize();

        // [GIVEN] "Check Prepmt. when Posting" is No in Sales Setup
        UpdateCheckPrepmtInSalesReceivableSetup(false);

        // [GIVEN] Sales Order "SO1" with prepayment invoice
        // [GIVEN] Sales Order "SO2" with paid prepayment invoice
        CreateSalesOrderWithPostedPrepmtInvoice(SalesHeader1, PrepmtInvoiceNo1);
        CreateSalesOrderWithPostedPrepmtInvoice(SalesHeader2, PrepmtInvoiceNo2);
        PostPaymentToPrepaymentInvoiceSales(SalesHeader2."Sell-to Customer No.", PrepmtInvoiceNo2);

        // [WHEN] Update Pending Prepayments for sales
        CODEUNIT.Run(CODEUNIT::"Upd. Pending Prepmt. Sales");

        // [THEN] Status is changed to Released in sales orders "SO1" and "SO2"
        VerifyStatusOnSalesHeader(SalesHeader1, SalesHeader1.Status::Released);
        VerifyStatusOnSalesHeader(SalesHeader2, SalesHeader2.Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePendingPrepmtSalesWithCheckPrepmtWhenPostingYes()
    var
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        PrepmtInvoiceNo1: Code[20];
        PrepmtInvoiceNo2: Code[20];
    begin
        // [FEATURE] [Sales] [Prepmt. Auto Update]
        // [SCENARIO 273807] Status in sales order is changed to 'Released' from 'Pending Prepayment' only when prepayment is paid
        // [SCENARIO 273807] when "Check Prepmt. when Posting" is Yes in Sales Setup
        Initialize();

        // [GIVEN] "Check Prepmt. when Posting" is No in Sales Setup
        UpdateCheckPrepmtInSalesReceivableSetup(true);

        // [GIVEN] Sales Order "SO1" with prepayment invoice
        // [GIVEN] Sales Order "SO2" with paid prepayment invoice
        CreateSalesOrderWithPostedPrepmtInvoice(SalesHeader1, PrepmtInvoiceNo1);
        CreateSalesOrderWithPostedPrepmtInvoice(SalesHeader2, PrepmtInvoiceNo2);
        PostPaymentToPrepaymentInvoiceSales(SalesHeader2."Sell-to Customer No.", PrepmtInvoiceNo2);

        // [WHEN] Update Pending Prepayments for sales
        CODEUNIT.Run(CODEUNIT::"Upd. Pending Prepmt. Sales");

        // [THEN] Status stayed 'Pending Prepayment' in sales orders "SO1"
        // [THEN] Status is changed to Released in sales orders "SO2"
        VerifyStatusOnSalesHeader(SalesHeader1, SalesHeader1.Status::"Pending Prepayment");
        VerifyStatusOnSalesHeader(SalesHeader2, SalesHeader2.Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePendingPrepmtPurchaseWithCheckPrepmtWhenPostingNo()
    var
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PrepmtInvoiceNo1: Code[20];
        PrepmtInvoiceNo2: Code[20];
    begin
        // [FEATURE] [Purchase] [Prepmt. Auto Update]
        // [SCENARIO 273807] Status in purchase order with paid and not paid prepayments is changed to 'Released' from 'Pending Prepayment'
        // [SCENARIO 273807] when "Check Prepmt. when Posting" is No in Purchase Setup
        Initialize();

        // [GIVEN] "Check Prepmt. when Posting" is No in Purchase Setup
        UpdateCheckPrepmtInPurchaseReceivableSetup(false);

        // [GIVEN] Purchase Order "PO1" with prepayment invoice
        // [GIVEN] Purchase Order "PO2" with paid prepayment invoice
        CreatePurchaseOrderWithPostedPrepmtInvoice(PurchaseHeader1, PrepmtInvoiceNo1);
        CreatePurchaseOrderWithPostedPrepmtInvoice(PurchaseHeader2, PrepmtInvoiceNo2);
        PostPaymentToPrepaymentInvoicePurchase(PurchaseHeader2."Buy-from Vendor No.", PrepmtInvoiceNo2);

        // [WHEN] Update Pending Prepayments for purchases
        CODEUNIT.Run(CODEUNIT::"Upd. Pending Prepmt. Purchase");

        // [THEN] Status is changed to Released in purchase orders "PO1" and "PO2"
        VerifyStatusOnPurchaseHeader(PurchaseHeader1, PurchaseHeader1.Status::Released);
        VerifyStatusOnPurchaseHeader(PurchaseHeader2, PurchaseHeader2.Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePendingPrepmtPurchaseWithCheckPrepmtWhenPostingYes()
    var
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PrepmtInvoiceNo1: Code[20];
        PrepmtInvoiceNo2: Code[20];
    begin
        // [FEATURE] [Purchase] [Prepmt. Auto Update]
        // [SCENARIO 273807] Status in purchase order is changed to 'Released' from 'Pending Prepayment' only when prepayment is paid
        // [SCENARIO 273807] when "Check Prepmt. when Posting" is Yes in Purchase Setup
        Initialize();

        // [GIVEN] "Check Prepmt. when Posting" is No in Purchase Setup
        UpdateCheckPrepmtInPurchaseReceivableSetup(true);

        // [GIVEN] Purchase Order "PO1" with prepayment invoice
        // [GIVEN] Purchase Order "PO2" with paid prepayment invoice
        CreatePurchaseOrderWithPostedPrepmtInvoice(PurchaseHeader1, PrepmtInvoiceNo1);
        CreatePurchaseOrderWithPostedPrepmtInvoice(PurchaseHeader2, PrepmtInvoiceNo2);
        PostPaymentToPrepaymentInvoicePurchase(PurchaseHeader2."Buy-from Vendor No.", PrepmtInvoiceNo2);

        // [WHEN] Update Pending Prepayments for purchases
        CODEUNIT.Run(CODEUNIT::"Upd. Pending Prepmt. Purchase");

        // [THEN] Status stayed 'Pending Prepayment' in purchase orders "PO1"
        // [THEN] Status is changed to Released in purchase orders "PO2"
        VerifyStatusOnPurchaseHeader(PurchaseHeader1, PurchaseHeader1.Status::"Pending Prepayment");
        VerifyStatusOnPurchaseHeader(PurchaseHeader2, PurchaseHeader2.Status::Released);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    procedure PrepmtOnSalesLineWithFirstInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        PrepaymentAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Prepayment Amount]
        // [SCENARIO 598768] Check "Prepayment Line Amount" is not changed on Sales Line after posting Prepayment Invoice and release sales order
        // [SCENARIO 598769] Prepayment Line Amount is inserted after invoice discount is applied

        // [GIVEN] Create Sales Order X with invoice discount 10 and one item line
        // [GIVEN] Insert "Prepayment Line Amount" 100 and post prepayment invoice

        Initialize();

        LibrarySales.CreatePrepaymentVATSetup(GLAccount, VATCalculationType);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerWithPostingSetup(GLAccount));

        CreateSalesLine(SalesLine, SalesHeader, Enum::"Sales Line Type"::Item, CreateItemWithPostingSetup(GLAccount));
        SalesLine.Validate("Prepayment %", 0);
        SalesLine.Modify(true);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(LibraryRandom.RandDec(100, 2), SalesHeader);
        SalesHeader.Modify(true);

        PrepaymentAmount := LibraryRandom.RandDec(10, 2);
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate("Prepmt. Line Amount", PrepaymentAmount);
        SalesLine.Modify(true);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Release Sales Document
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [THEN] Verify Prepayment Line Amount on Sales Line is not changed after release
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Prepmt. Line Amount", PrepaymentAmount);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    procedure PrepmtOnSalesLineWithSecondInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        PrepaymentAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Prepayment Amount]
        // [SCENARIO 598768] Check "Prepayment Line Amount" is not changed on Sales Line after posting Prepayment Invoice and release sales order
        // [SCENARIO 598769] Prepayment Line Amount is inserted before invoice discount is applied

        // [GIVEN] Create Sales Order X with one item line
        // [GIVEN] Insert "Prepayment Line Amount" 100
        // [GIVEN] Insert invoice discount 10
        // [GIVEN] Post prepayment invoice
        Initialize();

        LibrarySales.CreatePrepaymentVATSetup(GLAccount, VATCalculationType);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerWithPostingSetup(GLAccount));

        CreateSalesLine(SalesLine, SalesHeader, Enum::"Sales Line Type"::Item, CreateItemWithPostingSetup(GLAccount));

        SalesLine.Validate("Prepayment %", 0);
        SalesLine.Validate("Prepmt. Line Amount", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(LibraryRandom.RandDec(10, 2), SalesHeader);
        SalesHeader.Modify(true);
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        PrepaymentAmount := SalesLine."Prepmt. Line Amount";
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Release Sales Document
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [THEN] Verify Prepayment Line Amount on Sales Line is not changed after release
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Prepmt. Line Amount", PrepaymentAmount);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyBaseAmountOnGSTEntrieswithPrepayment()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        Item: array[3] of Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[3] of Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        CurrencyCode: Code[10];
        PurchaseInvoiceNo: Code[20];
        ExpectedVATBaseAmount: Decimal;
    begin
        //[SCENARIO 567355] Verify Base Amount on the GST Entries with Posted Prepayment Invoice.
        Initialize();

        // [GIVEN] Create General Posting Setup and VAT Posting Setup with VAT% as 0.
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);

        // [GIVEN] Create G/L Account and assign Gen. Prod. Posting Group and VAT Prod. Posting Group. 
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        GeneralPostingSetup.Validate("Direct Cost Applied Account", GLAccount."No.");
        GeneralPostingSetup.Validate("Purch. Prepayments Account", GLAccount."No.");
        GeneralPostingSetup.Modify(true);

        // [GIVEN] Create Currency with Exchange Rates.
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Create Vendor with Gen. Bus. Posting Group, VAT Bus. Posting Group and Currency.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);

        // [GIVEN] create 3 Items with Dimensions, Gen. Prod. Posting Group and VAT Prod. Posting Group.
        CreateItemWithDimensions(Item, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Create Purchase Header
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [GIVEN] Create first Purchase Line with Direct Unit Cost as 56.40.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[1], PurchaseHeader, PurchaseLine[1].Type::Item, Item[1]."No.", 8);
        PurchaseLine[1].Validate("Direct Unit Cost", 56.40);
        PurchaseLine[1].Modify(true);

        // [GIVEN] Create second Purchase Line with Direct Unit Cost as 38.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[2], PurchaseHeader, PurchaseLine[2].Type::Item, Item[2]."No.", 10);
        PurchaseLine[2].Validate("Direct Unit Cost", 38);
        PurchaseLine[2].Modify(true);

        // [GIVEN] Create third Purchase Line with Direct Unit Cost as 19.60.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[3], PurchaseHeader, PurchaseLine[3].Type::Item, Item[3]."No.", 20);
        PurchaseLine[3].Validate("Direct Unit Cost", 19.60);
        PurchaseLine[3].Modify(true);

        // [GIVEN] Post Purchase Order Receive only.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Reopen the Purchase Document.
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // [GIVEN] Update Prepayment % as 100 for all three Purchase Lines.
        PurchaseLine2.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine2.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine2.FindSet() then
            repeat
                ExpectedVATBaseAmount += PurchaseLine2."VAT Base (ACY)";
                PurchaseLine2.Validate("Prepayment %", 100);
                PurchaseLine2.Modify(true);
            until PurchaseLine2.Next() = 0;

        // [GIVEN] Post Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Vendor Invoice No.", IncStr(PurchaseHeader."Vendor Invoice No."));
        PurchaseHeader.Modify(true);

        // [WHEN] Post Purchase Order Invoice.
        PurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Verify GST Base Amount on GST Entries.
        VATEntry.SetRange("Document No.", PurchaseInvoiceNo);
        VATEntry.SetFilter(Base, '<%1', 0);
        VATEntry.CalcSums(Base);
        Assert.AreEqual(ExpectedVATBaseAmount, Abs(VATEntry.Base),
            StrSubstNo(BaseAmountNotMatchedErr, ExpectedVATBaseAmount));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Prepayment II");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Prepayment II");

        LibraryPurchase.SetInvoiceRounding(false);
        LibrarySales.SetInvoiceRounding(false);
        VATCalculationType := LibraryERMCountryData.GetVATCalculationType();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePrepaymentAccounts();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryInventory.UpdateGenProdPostingSetup();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        UpdateInventorySetupCostPosting();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        DisableGST(false);
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Prepayment II");
    end;

    local procedure ApplyGeneralJournal(DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20])
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenView();
        GeneralJournal.FILTER.SetFilter("Document Type", Format(DocumentType));
        GeneralJournal.FILTER.SetFilter("Account No.", AccountNo);
        GeneralJournal."Apply Entries".Invoke();
    end;

    local procedure CreateAndVerifyPurchPrepayment(var PurchaseLine: Record "Purchase Line"; var PrepaymentAmount: Decimal; PrepaymentPct: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        PrepaymentVATAmount: Decimal;
        PrepaymentAccount: Code[20];
    begin
        // [GIVEN] Create Purchase Order.
        PrepaymentAccount := CreatePurchaseOrderWithPrepaymentVAT(PurchaseHeader, PurchaseLine, PrepaymentPct);
        PrepaymentAmount := Round(PurchaseLine."Line Amount" * PurchaseHeader."Prepayment %" / 100);
        PrepaymentVATAmount := Round(PrepaymentAmount * PurchaseLine."VAT %" / 100);
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Prepayment No. Series");

        // [WHEN] Post Prepayment Invoice.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] Verify Posted Prepayment and VAT Amount in G/L Entry.
        VerifyAmountAndVATInGLEntry(DocumentNo, PrepaymentAccount, PrepaymentAmount, PrepaymentVATAmount);
    end;

    local procedure CreateAndVerifySalesPrepayment(var SalesLine: Record "Sales Line"; var PrepaymentAmount: Decimal; PrepaymentPct: Decimal)
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        PrepaymentVATAmount: Decimal;
        PrepaymentAccount: Code[20];
    begin
        // [GIVEN] Create Sales Order.
        PrepaymentAccount := CreateSalesOrderWithPrepaymentVAT(SalesHeader, SalesLine, PrepaymentPct);
        PrepaymentAmount := Round(SalesLine."Line Amount" * SalesHeader."Prepayment %" / 100);
        PrepaymentVATAmount := Round(PrepaymentAmount * SalesLine."VAT %" / 100);
        DocumentNo := GetPostedDocumentNo(SalesHeader."Prepayment No. Series");

        // [WHEN] Post Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Verify Posted Prepayment and VAT Amount in G/L Entry.
        VerifyAmountAndVATInGLEntry(DocumentNo, PrepaymentAccount, -PrepaymentAmount, -PrepaymentVATAmount);
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);

        // Create Currency Exchange Rate.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCurrencyExchRateOnDate(CurrencyCode: Code[10]; PostingDate: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyExchangeRateCopy: Record "Currency Exchange Rate";
        Currency: Record Currency;
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRateCopy := CurrencyExchangeRate;
        CurrencyExchangeRateCopy."Starting Date" := PostingDate;
        CurrencyExchangeRateCopy."Exchange Rate Amount" := CurrencyExchangeRate."Exchange Rate Amount" / 2;
        CurrencyExchangeRateCopy."Adjustment Exch. Rate Amount" := CurrencyExchangeRate."Adjustment Exch. Rate Amount" / 2;
        CurrencyExchangeRateCopy.Insert();
        Currency.Get(CurrencyCode);
        Currency.Validate("Realized Gains Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Realized Losses Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Modify(true);
    end;

    local procedure CreateCustomerWithPostingSetup(LineGLAccount: Record "G/L Account"): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Customer.Validate("Prepayment %", LibraryRandom.RandDec(99, 5));  // Random Number Generator for Prepayment Percent.
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
    end;

    local procedure CreateItemWithPostingSetup(LineGLAccount: Record "G/L Account"): Code[20]
    var
        Item: Record Item;
    begin
        CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", LineGLAccount."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemChargeWithPostingSetup(LineGLAccount: Record "G/L Account"): Code[20]
    var
        ItemCharge: Record "Item Charge";
    begin
        ItemCharge.Init();
        ItemCharge."No." := LibraryUtility.GenerateGUID();
        ItemCharge."Gen. Prod. Posting Group" := LineGLAccount."Gen. Prod. Posting Group";
        ItemCharge."VAT Prod. Posting Group" := LineGLAccount."VAT Prod. Posting Group";
        ItemCharge.Insert(true);
        exit(ItemCharge."No.");
    end;

    local procedure CreateJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreatePaymentMethodToGlAcc(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod."Bal. Account Type" := PaymentMethod."Bal. Account Type"::"G/L Account";
        PaymentMethod."Bal. Account No." := LibraryERM.CreateGLAccountNo();
        PaymentMethod.Modify(true);
        exit(PaymentMethod.Code);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; BuyFromVendorNo: Code[20]; No: Code[20]; PrePaymentPct: Decimal; CurrencyCode: Code[10])
    begin
        // Using Random for Quantity and Direct Unit Cost. Taking Direct Unit Cost more than 100. Value is important for test.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, BuyFromVendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Validate("Prepayment %", PrePaymentPct);
        UpdateVendorInvoiceNo(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, No, LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", 100 + LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithJob(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ItemNo: Code[20]; PrepaymentPct: Decimal; JobNo: Code[20]; JobTaskNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, VendorNo, ItemNo, PrepaymentPct, '');
        PurchaseLine.Validate("Job No.", JobNo);
        PurchaseLine.Validate("Job Task No.", JobTaskNo);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithPrepaymentVAT(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PrepaymentPct: Decimal): Code[20]
    var
        LineGLAccount: Record "G/L Account";
        VendorNo: Code[20];
        ItemNo: Code[20];
        PurchPrepaymentsAccount: Code[20];
    begin
        PurchPrepaymentsAccount := LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        VendorNo := CreateVendorWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, VendorNo, ItemNo, PrepaymentPct, '');
        exit(PurchPrepaymentsAccount);
    end;

    local procedure CreatePurchaseOrderWithPostedPrepmtInvoice(var PurchaseHeader: Record "Purchase Header"; var DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        SetupAndCreatePurchasePrepayment(PurchaseLine, LibraryRandom.RandDec(100, 2));
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        DocumentNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
    end;

    local procedure CreateResourceWithPostingSetup(LineGLAccount: Record "G/L Account"): Code[20]
    var
        Resource: Record Resource;
    begin
        LibraryResource.CreateResource(Resource, LineGLAccount."VAT Bus. Posting Group");
        Resource.Validate("Gen. Prod. Posting Group", LineGLAccount."Gen. Prod. Posting Group");
        Resource.Validate("VAT Prod. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        Resource.Modify(true);
        exit(Resource."No.");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SellToCustomerNo: Code[20]; Type: Enum "Sales Line Type"; No: Code[20]; PrePaymentPct: Decimal; CurrencyCode: Code[10])
    begin
        // Using Random for Quantity and Unit Price.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Prepayment %", PrePaymentPct);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, Type, No);
    end;

    local procedure CreateSalesDocumentWithResource(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LineGLAccount: Record "G/L Account"; CustomerNo: Code[20]; PrepmtPct: Decimal): Code[20]
    begin
        // Using Random for Quantity and Unit Price.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Prepayment %", PrepmtPct);
        SalesHeader.Modify(true);
        exit(CreateSalesLineWithResource(SalesLine, SalesHeader, LineGLAccount));
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20])
    begin
        // Take Quantity and Unit Price with Random values. Lower bound is important for test.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, 10);
        SalesLine.Validate("Unit Price", 1000);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithResource(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LineGLAccount: Record "G/L Account") ResourceNo: Code[20]
    begin
        // Take Quantity and Unit Price with Random values.
        ResourceNo := CreateResourceWithPostingSetup(LineGLAccount);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Resource,
          ResourceNo, 2 * LibraryRandom.RandIntInRange(1, 50));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 1000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithPrepaymentVAT(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; PrepaymentPct: Decimal): Code[20]
    var
        LineGLAccount: Record "G/L Account";
        CustomerNo: Code[20];
        PrepaymentsAccount: Code[20];
    begin
        PrepaymentsAccount := LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        CustomerNo := CreateCustomerWithPostingSetup(LineGLAccount);
        CreateSalesDocument(SalesHeader, SalesLine, CustomerNo, SalesLine.Type::"G/L Account", LineGLAccount."No.", PrepaymentPct, '');
        exit(PrepaymentsAccount);
    end;

    local procedure CreateSalesOrderWithPostedPrepmtInvoice(var SalesHeader: Record "Sales Header"; var DocumentNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        SetupPrepaymentOrder(SalesHeader, GLAccount);
        DocumentNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
    end;

    local procedure CreateVendorWithPostingSetup(LineGLAccount: Record "G/L Account"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure DisableGST(DisableGST: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Enable GST (Australia)", DisableGST);
        GLSetup.Validate("Full GST on Prepayment", DisableGST);
        GLSetup.Validate("GST Report", DisableGST);
        GLSetup.Validate("Adjustment Mandatory", DisableGST);
        GLSetup.Modify(true);
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure FindGLEntryPrepayment(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        // There are 2 G/L Entries for the same account with the same Document No., so additional filter is needed
        GLEntry.SetFilter(Amount, '<=%1&>=%2', Amount + LibraryERM.GetAmountRoundingPrecision(), Amount - LibraryERM.GetAmountRoundingPrecision());
        GLEntry.FindFirst();
    end;

    local procedure FindJobTask(var JobTask: Record "Job Task")
    begin
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        JobTask.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindSet();
    end;

    local procedure FindSalesLineAmount(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]) TotalLineAmount: Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, DocumentType, DocumentNo);
        repeat
            TotalLineAmount += SalesLine."Line Amount";
        until SalesLine.Next() = 0;
    end;

    local procedure GetPostedDocumentNo(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.PeekNextNo(NoSeriesCode));
    end;

    local procedure GetSalesInvAmount(DocumentNo: Code[20]): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        exit(CustLedgerEntry."Amount (LCY)");
    end;

    local procedure GetPurchaseInvAmount(DocumentNo: Code[20]): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document No.");
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        exit(VendorLedgerEntry."Amount (LCY)");
    end;

    local procedure InvoicePostedPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; BuyFromVendorNo: Code[20]; DocumentNoFilter: Text; CurrencyCode: Code[10]; PostingDate: Date): Code[20]
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        // Create a Purchase Invoice for the given posted Purchase Order, finally the Order and the Invoice will be linked.

        // Create Invoice for Posted Receipt Line.
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, BuyFromVendorNo);
        UpdateVendorInvoiceNo(PurchaseHeader);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);

        // Link Purchase Order with Purchase Invoice
        PurchRcptLine.SetFilter("Document No.", DocumentNoFilter);
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure InvoicePostedSalesOrder(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20]; DocumentNoFilter: Text; CurrencyCode: Code[10]; PostingDate: Date): Code[20]
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        // Creates a Sales Invoice for the given posted Sales Order, finally the order and the invoice will be linked.
        // Create Invoice for Posted Shipment Line.
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, SellToCustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);

        // Link Sales Order with Sales Invoice
        SalesShipmentLine.SetFilter("Document No.", DocumentNoFilter);
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure ModifyExchangeRate(CurrencyCode: Code[10]): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount", CurrencyExchangeRate."Relational Exch. Rate Amount" + LibraryRandom.RandDec(10, 2));
        CurrencyExchangeRate.Modify(true);
        exit(CurrencyExchangeRate."Relational Exch. Rate Amount");
    end;

    local procedure ModifyPurchaseQtyToInvoice(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; LineNo: Integer)
    begin
        PurchaseLine.Get(DocumentType, DocumentNo, LineNo);
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine."Qty. to Invoice" / 2);
        PurchaseLine.Modify(true);
    end;

    local procedure ModifyPurchaseQtyToReceive(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; LineNo: Integer)
    begin
        PurchaseLine.Get(DocumentType, DocumentNo, LineNo);
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity / 2);
        PurchaseLine.Modify(true);
    end;

    local procedure ModifySalesHeader(var SalesHeader: Record "Sales Header")
    begin
        // Modify Prepayment % with Random Values.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));
        SalesHeader.Modify(true);
    end;

    local procedure ModifySalesQtyToInvoice(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; LineNo: Integer)
    begin
        SalesLine.Get(DocumentType, DocumentNo, LineNo);
        SalesLine.Validate("Qty. to Invoice", SalesLine."Qty. to Invoice" / 2);
        SalesLine.Modify(true);
    end;

    local procedure ModifySalesQtyToShip(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; LineNo: Integer)
    begin
        SalesLine.Get(DocumentType, DocumentNo, LineNo);
        SalesLine.Validate("Qty. to Ship", SalesLine."Qty. to Ship" / 2);
        SalesLine.Modify(true);
    end;

    local procedure PostPaymentToPrepaymentInvoiceSales(AccountNo: Code[20]; PrepmtInvoiceNo: Code[20])
    var
        DummyGenJournalLine: Record "Gen. Journal Line";
    begin
        PostPaymentToInvoice(
          DummyGenJournalLine."Account Type"::Customer, AccountNo, PrepmtInvoiceNo, -GetSalesInvAmount(PrepmtInvoiceNo));
    end;

    local procedure PostPaymentToPrepaymentInvoicePurchase(AccountNo: Code[20]; PrepmtInvoiceNo: Code[20])
    begin
        PostPaymentToInvoice(
          "Gen. Journal Account Type"::Vendor, AccountNo, PrepmtInvoiceNo, -GetPurchaseInvAmount(PrepmtInvoiceNo));
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

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and clear General Journal Lines to make sure that no line exist before creating
        // General Journal Lines.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure SetupAndCreateSalesPrepayment(var SalesLine: Record "Sales Line"; PrepmtPct: Decimal) SalesPrepaymentsAccount: Code[20]
    var
        LineGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        ItemNo: Code[20];
    begin
        SalesPrepaymentsAccount :=
          LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);
        CustomerNo := CreateCustomerWithPostingSetup(LineGLAccount);
        CreateSalesDocument(
          SalesHeader, SalesLine, CustomerNo, SalesLine.Type::Item, ItemNo,
          PrepmtPct, CreateCurrencyAndExchangeRate());
    end;

    local procedure SetupPrepaymentOrder(var SalesHeader: Record "Sales Header"; var LineGLAccount: Record "G/L Account") SalesPrepaymentsAccount: Code[20]
    var
        SalesLine: Record "Sales Line";
        SalesPrepaymentPct: Record "Sales Prepayment %";
        ItemNo: array[2] of Code[20];
        CustomerNo: Code[20];
    begin
        SalesPrepaymentsAccount :=
          LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        // Create Prepayment % for Customer.
        ItemNo[1] := CreateItemWithPostingSetup(LineGLAccount);
        CustomerNo := CreateCustomerWithPostingSetup(LineGLAccount);
        LibrarySales.CreateSalesPrepaymentPct(
          SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::Customer, CustomerNo, ItemNo[1], WorkDate());
        SalesPrepaymentPct.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));
        SalesPrepaymentPct.Modify(true);

        // Create Sales Order with Two Item Lines with different Prepayment Amount field.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesPrepaymentPct."Sales Code");
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo[1]);
        ItemNo[2] := CreateItemWithPostingSetup(LineGLAccount);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo[2]);
        exit(SalesPrepaymentsAccount);
    end;

    local procedure SetupAndCreatePurchasePrepayment(var PurchaseLine: Record "Purchase Line"; PrepmtPct: Decimal) PurchasePrepaymentsAccount: Code[20]
    var
        LineGLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        PurchasePrepaymentsAccount :=
          LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType::"Normal VAT");
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);
        VendorNo := CreateVendorWithPostingSetup(LineGLAccount);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, VendorNo, ItemNo, PrepmtPct, CreateCurrencyAndExchangeRate());
    end;

    local procedure UpdateInventoryAdjmtAccount(InventoryAdjmtAccount: Code[20]; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]) OldInventoryAdjmtAccount: Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        OldInventoryAdjmtAccount := GeneralPostingSetup."Inventory Adjmt. Account";
        GeneralPostingSetup.Validate("Inventory Adjmt. Account", InventoryAdjmtAccount);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateInventorySetup(AutomaticCostPosting: Boolean; AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", AutomaticCostPosting);
        InventorySetup.Validate("Automatic Cost Adjustment", AutomaticCostAdjustment);
        InventorySetup.Modify(true);
    end;

    local procedure UpdateCheckPrepmtInSalesReceivableSetup(CheckPrepmtwhenPosting: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Check Prepmt. when Posting", CheckPrepmtwhenPosting);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateCheckPrepmtInPurchaseReceivableSetup(CheckPrepmtwhenPosting: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Check Prepmt. when Posting", CheckPrepmtwhenPosting);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateVendorInvoiceNo(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure VerifyAmountAndVATInGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal; VATAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
    begin
        GeneralLedgerSetup.Get();
        FindGLEntry(GLEntry, DocumentNo, GLAccountNo);
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(ValidationErr, GLEntry.FieldCaption(Amount), Amount));

        Assert.AreNearlyEqual(
          VATAmount, GLEntry."VAT Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(ValidationErr, GLEntry.FieldCaption("VAT Amount"), VATAmount));
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
    begin
        GeneralLedgerSetup.Get();
        FindGLEntry(GLEntry, DocumentNo, GLAccountNo);
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(ValidationErr, GLEntry.FieldCaption(Amount), Amount));
    end;

    local procedure VerifyGLEntryPrepayment(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
    begin
        GeneralLedgerSetup.Get();
        FindGLEntryPrepayment(GLEntry, DocumentNo, GLAccountNo, Amount);
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(ValidationErr, GLEntry.FieldCaption(Amount), Amount));
    end;

    local procedure VerifyJobNoInGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; JobNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, GLAccountNo);
        Assert.AreEqual(JobNo, GLEntry."Job No.", StrSubstNo(ValidationErr, GLEntry.FieldCaption("Job No."), JobNo));
    end;

    local procedure VerifyPurchInvLine(DocumentNo: Code[20]; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal; LineAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        GeneralLedgerSetup.Get();
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.SetRange(Type, Type);
        PurchInvLine.SetRange("No.", No);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField(Quantity, Quantity);
        Assert.AreNearlyEqual(
          LineAmount, PurchInvLine."Line Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, PurchInvLine.FieldCaption("Line Amount"), LineAmount, PurchInvLine.TableCaption()));
    end;

    local procedure VerifyPurchInvLineJobNoJobTaskNo(DocumentNo: Code[20]; JobNo: Code[20]; JobTaskNo: Code[20])
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();
        Assert.AreEqual(JobNo, PurchInvLine."Job No.", PurchInvLine.FieldCaption("Job No."));
        Assert.AreEqual(JobTaskNo, PurchInvLine."Job Task No.", PurchInvLine.FieldCaption("Job Task No."));
    end;

    local procedure VerifyPurchCrMemoLineJobNoJobTaskNo(DocumentNo: Code[20]; JobNo: Code[20]; JobTaskNo: Code[20])
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.FindFirst();
        Assert.AreEqual(JobNo, PurchCrMemoLine."Job No.", PurchCrMemoLine.FieldCaption("Job No."));
        Assert.AreEqual(JobTaskNo, PurchCrMemoLine."Job Task No.", PurchCrMemoLine.FieldCaption("Job Task No."));
    end;

    local procedure VerifySalesInvoiceLine(DocumentNo: Code[20]; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal; LineAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        GeneralLedgerSetup.Get();
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange(Type, Type);
        SalesInvoiceLine.SetRange("No.", No);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField(Quantity, Quantity);
        Assert.AreNearlyEqual(
          LineAmount, SalesInvoiceLine."Line Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, SalesInvoiceLine.FieldCaption("Line Amount"), LineAmount, SalesInvoiceLine.TableCaption()));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustEntryPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure CreatePurchHeaderPrepaymentPercentage(var PurchHeader: Record "Purchase Header"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        PurchHeader.Validate("Prepayment %", LibraryRandom.RandInt(99));
        PurchHeader.Modify(true);
    end;

    local procedure CreatePurchLineQtyToReceive(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; LineGLAccount: Record "G/L Account")
    var
        Item: Record Item;
        Quantity: Decimal;
    begin
        Quantity := LibraryRandom.RandIntInRange(3, 13);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", LineGLAccount."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        Item.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", Quantity);
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchLine.Validate("Qty. to Receive", LibraryRandom.RandIntInRange(3, Quantity));
        PurchLine.Modify(true);
    end;

    local procedure CreatePurchLineWithItemCharge(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; LineGLAccount: Record "G/L Account"): Decimal
    var
        ItemChargeNo: Code[20];
        Quantity: Decimal;
    begin
        Quantity := LibraryRandom.RandIntInRange(3, 13);
        ItemChargeNo := CreateItemChargeWithPostingSetup(LineGLAccount);
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"Charge (Item)", ItemChargeNo, Quantity);
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchLine.Modify(true);
        exit(PurchLine.Quantity);
    end;

    local procedure UpdateItemChargeQtyToAssign(var PurchLine: Record "Purchase Line"; QtyToReceive: Decimal): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        PurchLine.Validate("Qty. to Invoice", QtyToReceive);
        PurchLine.Modify(true);
        LibraryVariableStorage.Enqueue(QtyToReceive);
        PurchLine.ShowItemChargeAssgnt();
        exit(Round(PurchLine."Direct Unit Cost" * PurchLine."Qty. to Invoice", GeneralLedgerSetup."Amount Rounding Precision"));
    end;

    local procedure VerifyGLEntryAmountForPurch(DocumentNo: Code[20]; AccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, AccountNo);
        GLEntry.TestField(Amount, ExpectedAmount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchaseHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    var
        QtytoInvoice: Variant;
    begin
        LibraryVariableStorage.Dequeue(QtytoInvoice);
        ItemChargeAssignmentPurch."Qty. to Assign".SetValue(QtytoInvoice);
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    local procedure PrepareShptLinesWithPrepmtPerc(var SalesLine2: Record "Sales Line"; PrepaymentPct: Integer; PartialShipment: Boolean)
    var
        LineGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        CustomerNo := CreateCustomerWithPostingSetup(LineGLAccount);
        CreateSalesDocumentWithResource(SalesHeader, SalesLine, LineGLAccount, CustomerNo, PrepaymentPct);
        if PrepaymentPct <> 0 then
            LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        if PartialShipment then begin
            ModifySalesQtyToShip(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
            LibrarySales.PostSalesDocument(SalesHeader, true, false);
        end;
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Invoice, CustomerNo);
        SalesLine2."Document Type" := SalesHeader2."Document Type";
        SalesLine2."Document No." := SalesHeader2."No.";
    end;

    local procedure PrepareRcptLinesWithPrepmtPerc(var PurchLine2: Record "Purchase Line"; PrepaymentPct: Integer; PartialReceipt: Boolean)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchHeader2: Record "Purchase Header";
        LineGLAccount: Record "G/L Account";
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        VendorNo := CreateVendorWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);
        CreatePurchaseDocument(PurchHeader, PurchLine, VendorNo, ItemNo, PrepaymentPct, '');
        if PrepaymentPct <> 0 then
            LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);
        if PartialReceipt then begin
            ModifyPurchaseQtyToReceive(PurchLine, PurchHeader."Document Type", PurchHeader."No.", PurchLine."Line No.");
            LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);
        end;
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);
        LibraryPurchase.CreatePurchHeader(PurchHeader2, PurchHeader2."Document Type"::Invoice, VendorNo);
        PurchLine2."Document Type" := PurchHeader2."Document Type";
        PurchLine2."Document No." := PurchHeader2."No.";
    end;

    local procedure PrepareSeveralShptLinesWithPrepmtPerc(var SalesLine2: Record "Sales Line"; PrepaymentPct: Integer; NoOfLines: Integer)
    var
        LineGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        CustomerNo := CreateCustomerWithPostingSetup(LineGLAccount);
        CreateSalesDocumentWithResource(SalesHeader, SalesLine, LineGLAccount, CustomerNo, PrepaymentPct);
        NoOfLines -= 1;
        while NoOfLines > 0 do begin
            CreateSalesLineWithResource(SalesLine, SalesHeader, LineGLAccount);
            NoOfLines -= 1;
        end;
        if PrepaymentPct <> 0 then
            LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Invoice, CustomerNo);
        SalesLine2."Document Type" := SalesHeader2."Document Type";
        SalesLine2."Document No." := SalesHeader2."No.";
    end;

    local procedure PrepareSeveralRcptLinesWithPrepmtPerc(var PurchLine2: Record "Purchase Line"; PrepaymentPct: Integer; NoOfLines: Integer)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchHeader2: Record "Purchase Header";
        LineGLAccount: Record "G/L Account";
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATCalculationType);
        VendorNo := CreateVendorWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);
        CreatePurchaseDocument(PurchHeader, PurchLine, VendorNo, ItemNo, PrepaymentPct, '');
        NoOfLines -= 1;
        while NoOfLines > 0 do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchLine, PurchHeader, PurchLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
            NoOfLines -= 1;
        end;
        if PrepaymentPct <> 0 then
            LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);
        PurchLine.Validate("Qty. to Receive", 0);
        PurchLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);
        LibraryPurchase.CreatePurchHeader(PurchHeader2, PurchHeader2."Document Type"::Invoice, VendorNo);
        PurchLine2."Document Type" := PurchHeader2."Document Type";
        PurchLine2."Document No." := PurchHeader2."No.";
    end;

    local procedure CountLinesInGetShptLines(var GetShptLines: TestPage "Get Shipment Lines"): Integer
    var
        "Count": Integer;
    begin
        if GetShptLines.First() then
            repeat
                Count += 1;
            until not GetShptLines.Next();
        exit(Count);
    end;

    local procedure CountLinesInGetRcptLines(var GetRcptLines: TestPage "Get Receipt Lines"): Integer
    var
        "Count": Integer;
    begin
        if GetRcptLines.First() then
            repeat
                Count += 1;
            until not GetRcptLines.Next();
        exit(Count);
    end;

    local procedure UpdateInventorySetupCostPosting()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", false);
        InventorySetup.Modify(true);
    end;

    local procedure CreateItemWithDimensions(var Item: array[3] of Record Item; GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
        i: Integer;
    begin
        for i := 1 to 3 do begin
            LibraryInventory.CreateItem(Item[i]);
            LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
            Item[i].Validate("Global Dimension 1 Code", DimensionValue.Code);
            LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
            LibraryDimension.CreateDimensionValue(DimensionValue, DimensionValue."Dimension Code");
            Item[i].Validate("Global Dimension 2 Code", DimensionValue.Code);
            Item[i].Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
            Item[i].Validate("VAT Prod. Posting Group", VATProdPostingGroup);
            Item[i].Modify(true);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyNoOfGetShipmentLinesPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    var
        NoOfLines: Variant;
    begin
        LibraryVariableStorage.Dequeue(NoOfLines);
        Assert.AreEqual(NoOfLines, CountLinesInGetShptLines(GetShipmentLines), ShipmentLinesErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyNoOfGetReceiptLinesPageHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    var
        NoOfLines: Variant;
    begin
        LibraryVariableStorage.Dequeue(NoOfLines);
        Assert.AreEqual(NoOfLines, CountLinesInGetRcptLines(GetReceiptLines), ReceiptLinesErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyDocNoInGetShipmentLinesPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        if GetShipmentLines.First() then
            repeat
                Assert.AreNotEqual('', Format(GetShipmentLines."Document No."), ShipmentLinesDocNoErr);
            until not GetShipmentLines.Next();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyDocNoInGetReceiptLinesPageHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    begin
        if GetReceiptLines.First() then
            repeat
                Assert.AreNotEqual('', Format(GetReceiptLines."Document No."), ReceiptLinesDocNoErr);
            until not GetReceiptLines.Next();
    end;

    local procedure VerifyStatusOnSalesHeader(var SalesHeader: Record "Sales Header"; ExpectedStatus: Enum "Sales Document Status")
    begin
        SalesHeader.Find();
        SalesHeader.TestField(Status, ExpectedStatus);
    end;

    local procedure VerifyStatusOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; ExpectedStatus: Enum "Purchase Document Status")
    begin
        PurchaseHeader.Find();
        PurchaseHeader.TestField(Status, ExpectedStatus);
    end;
}