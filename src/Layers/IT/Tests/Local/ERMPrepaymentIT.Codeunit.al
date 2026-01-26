codeunit 144172 "ERM Prepayment IT"
{
    // // [FEATURE] [Prepayment]
    // Test for feature - PREPAY - Prepayment.
    // 1. PREPAY - Verify Report 412 Purchase Prepmt. Doc. - Test when Purchase Prepayment Account is specified.
    // 2. PREPAY - Verify Report 412 Purchase Prepmt. Doc. - Test when Purchase Prepayment Account is blank.
    // 3. PREPAY - Verify Report 212 Sales Prepmt. Document Test when Sales Prepayment Account is specified.
    // 4. PREPAY - Verify Report 212 Sales Prepmt. Document Test when Sales Prepayment Account is blank.
    // 
    // Covers Test Cases for WI - 345519
    // ----------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                               TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------
    // PurchasePrepmtDocumentWithPurchasePrepmtAccount,PurchasePrepmtDocumentWithoutPurchasePrepmtAccount           156005,156006
    // SalesPrepmtDocumentWithSalesPrepmtAccount,SalesPrepmtDocumentWithoutSalesPrepmtAccount                       156003,156004

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        AmountCap: Label 'Prepayment_Inv__Line_Buffer__Amount';
        AmountInclVATAmountCap: Label 'VATBaseAmount___VATAmount';
        DescriptionCap: Label 'Prepayment_Inv__Line_Buffer__Description';
        GLAccountNoCap: Label 'Prepayment_Inv__Line_Buffer___G_L_Account_No__';
        PurchaseWarningCap: Label 'ErrorText_Number__Control104';
        PurchaseWarningCap2: Label 'ErrorText_Number__Control104Caption';
        PurchaseWarningMsg: Label 'Purch. Prepayments Account must be specified.';
        SalesWarningCap: Label 'ErrorText_Number__Control94';
        SalesWarningCap2: Label 'ErrorText_Number__Control94Caption';
        SalesWarningMsg: Label 'Sales Prepayments Account must be specified.';
        SumPrepaymInvLineBufferAmountCap: Label 'SumPrepaymInvLineBufferAmount';
        VATAmountCap: Label 'Prepayment_Inv__Line_Buffer___VAT_Amount_';
        VATAmountCap2: Label 'VATAmount';
        VATPctCap: Label 'Prepayment_Inv__Line_Buffer___VAT___';
        VATIdentifierCap: Label 'Prepayment_Inv__Line_Buffer___VAT_Identifier_';
        WarningMsg: Label 'Warning!';
        WrongAmountErr: Label 'Wrong amount in G/L Accout.';

    [Test]
    [HandlerFunctions('PurchasePrepmtDocTestReportHandler')]
    [Scope('OnPrem')]
    procedure PurchasePrepmtDocumentWithPurchasePrepmtAccount()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify Report 412 Purchase Prepmt. Doc. - Test when Purchase Prepayment Account is specified.
        SetupAndRunPurchasePrepmtDocumentTestReport(PurchaseLine, LibraryERM.CreateGLAccountWithPurchSetup());

        // Verify: Verify Saved Report Data.
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        VerifyReportValues(
          VATPostingSetup."Purch. Prepayments Account", VATPostingSetup."VAT Identifier",
          PurchaseLine."Prepmt. Line Amount", VATPostingSetup."VAT %");
    end;

    [Test]
    [HandlerFunctions('PurchasePrepmtDocTestReportHandler')]
    [Scope('OnPrem')]
    procedure PurchasePrepmtDocumentWithoutPurchasePrepmtAccount()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Report 412 Purchase Prepmt. Doc. - Test when Purchase Prepayment Account is blank.
        SetupAndRunPurchasePrepmtDocumentTestReport(PurchaseLine, '');  // Using blank for Purchase Prepayment Account.

        // Verify: Verify Saved Report Warning Message.
        VerifyWarningMessageOnReport(PurchaseWarningCap, PurchaseWarningCap2, PurchaseWarningMsg);
    end;

    [Test]
    [HandlerFunctions('SalesPrepmtDocumentTestReportHandler')]
    [Scope('OnPrem')]
    procedure SalesPrepmtDocumentWithSalesPrepmtAccount()
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify Report 212 Sales Prepmt. Document Test when Sales Prepayment Account is specified.
        SetupAndRunSalesPrepmtDocumentTestReport(SalesLine, LibraryERM.CreateGLAccountWithSalesSetup());

        // Verify: Verify Saved Report Data.
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        VerifyReportValues(
          VATPostingSetup."Sales Prepayments Account", VATPostingSetup."VAT Identifier",
          SalesLine."Prepmt. Line Amount", VATPostingSetup."VAT %");
    end;

    [Test]
    [HandlerFunctions('SalesPrepmtDocumentTestReportHandler')]
    [Scope('OnPrem')]
    procedure SalesPrepmtDocumentWithoutSalesPrepmtAccount()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Report 212 Sales Prepmt. Document Test when Sales Prepayment Account is blank.
        SetupAndRunSalesPrepmtDocumentTestReport(SalesLine, '');  // Using blank for Sales Prepayment Account.

        // Verify: Verify Saved Report Warning Message.
        VerifyWarningMessageOnReport(SalesWarningCap, SalesWarningCap2, SalesWarningMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryInAppliedSalesOrderWithPrepmtAndUnrealizedVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        PrepmtInvNo: Code[20];
        DocumentNo: Code[20];
    begin
        // Verify that Unrealized Amounts in VAT Entries are correct for a Sales Order with Prepayment
        // after a Payment application.
        EnableUnrealizedVAT(true);

        // Create and post a Sales Order with Prepayment. Create, post and apply Payment to created documents.
        CreatePostSalesOrderWithPrepmt(VATPostingSetup, SalesHeader, PrepmtInvNo, DocumentNo);
        ApplySalesInvoicePayment(
          SalesHeader."Sell-to Customer No.", PrepmtInvNo, -GetCustomerLedgerEntryAmount(PrepmtInvNo));
        ApplySalesInvoicePayment(
          SalesHeader."Sell-to Customer No.", DocumentNo, -GetCustomerLedgerEntryAmount(DocumentNo));

        VerifyGLAccount(VATPostingSetup."Sales Prepayments Account", 0);
        VerifyVATEntry(PrepmtInvNo);
        VerifyVATEntry(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryPurchOrderWithPrepmtAndUnrealizedVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        PrepmtInvNo: Code[20];
        DocumentNo: Code[20];
    begin
        // Verify that Unrealized Amounts in VAT Entries are correct for a Purchase Order with Prepayment
        // after a Payment application.
        EnableUnrealizedVAT(true);

        // Create and post a Purchase Order with Prepayment. Create, post and apply Payment to created documents.
        CreatePostPurchOrderWithPrepmt(VATPostingSetup, PurchHeader, PrepmtInvNo, DocumentNo);
        ApplyPurchInvoicePayment(
          PurchHeader."Buy-from Vendor No.", PrepmtInvNo, -GetVendorLedgerEntryAmount(PrepmtInvNo));
        ApplyPurchInvoicePayment(
          PurchHeader."Buy-from Vendor No.", DocumentNo, -GetVendorLedgerEntryAmount(DocumentNo));

        VerifyGLAccount(VATPostingSetup."Purch. Prepayments Account", 0);
        VerifyVATEntry(PrepmtInvNo);
        VerifyVATEntry(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntrySalesOrderWithPrepmtAndUnrealizedVATPartialApplication()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        PrepmtInvNo: Code[20];
        DocumentNo: Code[20];
        PaymentNo: Code[20];
        TotalPrepmtAmount: Decimal;
        TotalSOAmount: Decimal;
        PrepmtAmount: Decimal;
        SOAmount: Decimal;
    begin
        // Verify that Unrealized Amounts in VAT Entries are correct for a Sales Order with Prepayment
        // after a partial Payment application.
        EnableUnrealizedVAT(true);

        // Create and post a Sales Order with Prepayment.
        CreatePostSalesOrderWithPrepmt(VATPostingSetup, SalesHeader, PrepmtInvNo, DocumentNo);
        TotalPrepmtAmount := GetCustomerLedgerEntryAmount(PrepmtInvNo);
        TotalSOAmount := GetCustomerLedgerEntryAmount(DocumentNo);

        // First patrial application.
        PrepmtAmount := Round(2 * TotalPrepmtAmount / 3);
        SOAmount := Round(2 * TotalSOAmount / 3);
        ApplySalesInvoicePayment(SalesHeader."Sell-to Customer No.", PrepmtInvNo, -PrepmtAmount);
        ApplySalesInvoicePayment(SalesHeader."Sell-to Customer No.", DocumentNo, -SOAmount);

        // Second patrial application.
        PaymentNo :=
          CreateCustLedgerEntry(
            SalesHeader."Sell-to Customer No.", -(TotalPrepmtAmount - PrepmtAmount + TotalSOAmount - SOAmount));
        ApplyAndPostCustomerEntry(GenJournalLine."Document Type"::Payment, PaymentNo, PrepmtInvNo);
        ApplyAndPostCustomerEntry(GenJournalLine."Document Type"::Payment, PaymentNo, DocumentNo);

        VerifyGLAccount(VATPostingSetup."Sales Prepayments Account", 0);
        VerifyVATEntry(PrepmtInvNo);
        VerifyVATEntry(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryPurchOrderWithPrepmtAndUnrealizedVATPartialApplication()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        PrepmtInvNo: Code[20];
        DocumentNo: Code[20];
        PaymentNo: Code[20];
        TotalPrepmtAmount: Decimal;
        TotalPOAmount: Decimal;
        PrepmtAmount: Decimal;
        POAmount: Decimal;
    begin
        // Verify that Unrealized Amounts in VAT Entries are correct for a Purchase Order with Prepayment
        // after a partial Payment application.
        EnableUnrealizedVAT(true);

        // Create and post a Purchase Order with Prepayment.
        CreatePostPurchOrderWithPrepmt(VATPostingSetup, PurchHeader, PrepmtInvNo, DocumentNo);
        TotalPrepmtAmount := GetVendorLedgerEntryAmount(PrepmtInvNo);
        TotalPOAmount := GetVendorLedgerEntryAmount(DocumentNo);

        // First patrial application.
        PrepmtAmount := Round(2 * TotalPrepmtAmount / 3);
        POAmount := Round(2 * TotalPOAmount / 3);
        ApplyPurchInvoicePayment(PurchHeader."Buy-from Vendor No.", PrepmtInvNo, -PrepmtAmount);
        ApplyPurchInvoicePayment(PurchHeader."Buy-from Vendor No.", DocumentNo, -POAmount);

        // Second patrial application.
        PaymentNo :=
          CreateVendLedgerEntry(
            PurchHeader."Buy-from Vendor No.", -(TotalPrepmtAmount - PrepmtAmount + TotalPOAmount - POAmount));
        ApplyAndPostVendorEntry(GenJournalLine."Document Type"::Payment, PaymentNo, PrepmtInvNo);
        ApplyAndPostVendorEntry(GenJournalLine."Document Type"::Payment, PaymentNo, DocumentNo);

        VerifyGLAccount(VATPostingSetup."Purch. Prepayments Account", 0);
        VerifyVATEntry(PrepmtInvNo);
        VerifyVATEntry(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPostedPaymentLines()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        PrepmtInvNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Payment Lines]
        // [SCENARIO 202248] TAB 12171 "Posted Payment Lines" record with "Sales/Purchase" = "Sales" exists for the posted sales prepayment invoice
        Initialize();
        EnableUnrealizedVAT(true);
        FindGenPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(VATPostingSetup, GeneralPostingSetup."Gen. Prod. Posting Group");

        // [GIVEN] Sales order "SO" with prepayment
        CreateSalesDocumentSetPrepmtAccount(SalesHeader, VATPostingSetup, GeneralPostingSetup."Gen. Bus. Posting Group");
        // [GIVEN] TAB 12170 "Payment Lines" record exists for the order: "Sales/Purchase" = "Sales", Type = "Order", Code = "SO"
        VerifySalesPaymentLineExists(SalesHeader."No.");
        // [GIVEN] Post prepayment invoice (posted Document No. = "PI")
        PrepmtInvNo := PostSalesPrepmtInvoice(SalesHeader);
        // [GIVEN] TAB 12171 "Posted Payment Lines" record exists for the prepayment invoice: "Sales/Purchase" = "Sales", Type = "Invoice", Code = "PI"
        VerifySalesPostedPaymentLineExists(PrepmtInvNo);

        // [WHEN] Post order's invoice (posted Document No. = "OI")
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] TAB 12171 "Posted Payment Lines" record exists for the posted invoice: "Sales/Purchase" = "Sales", Type = "Invoice", Code = "OI"
        VerifySalesPostedPaymentLineExists(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPostedPaymentLines()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PrepmtInvNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Payment Lines]
        // [SCENARIO 202248] TAB 12171 "Posted Payment Lines" record with "Sales/Purchase" = "Purchase" exists for the posted purchase prepayment invoice
        Initialize();
        EnableUnrealizedVAT(true);
        FindGenPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(VATPostingSetup, GeneralPostingSetup."Gen. Prod. Posting Group");

        // [GIVEN] Purchase order "PO" with prepayment
        CreatePurchDocumentSetPrepmtAccount(PurchaseHeader, VATPostingSetup, GeneralPostingSetup."Gen. Bus. Posting Group");
        // [GIVEN] TAB 12170 "Payment Lines" record exists for the order: "Sales/Purchase" = "Purchase", Type = "Order", Code = "PO"
        VerifyPurchasePaymentLineExists(PurchaseHeader."No.");
        // [GIVEN] Post prepayment invoice (posted Document No. = "PI")
        PrepmtInvNo := PostPurchPrepmtInvoice(PurchaseHeader);
        // [GIVEN] TAB 12171 "Posted Payment Lines" record exists for the prepayment invoice: "Sales/Purchase" = "Purchase", Type = "Invoice", Code = "PI"
        VerifyPurchasePostedPaymentLineExists(PrepmtInvNo);

        // [WHEN] Post order's invoice (posted Document No. = "OI")
        DocumentNo := PostPurchaseDocument(PurchaseHeader);

        // [THEN] TAB 12171 "Posted Payment Lines" record exists for the posted invoice: "Sales/Purchase" = "Purchase", Type = "Invoice", Code = "OI"
        VerifyPurchasePostedPaymentLineExists(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPaymentLinesUpdateAmountForPurchInvoice()
    var
        PurchHeader: Record "Purchase Header";
        PostedPaymentLines: Record "Posted Payment Lines";
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice] [Payment Lines]
        // [SCENARIO 283787] TAB 12171 "Posted Payment Lines" UpdateAmount works for Purchase Invoice
        Initialize();

        // [GIVEN] Document was created and posted
        LibraryPurchase.CreatePurchaseInvoice(PurchHeader);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [WHEN] Posted Payment Lines are Recalculated using Posted Payments page
        RecalcPostedPaymentsLinesThroughPostedPaymentsPage(
          PostedPaymentLines, PostedPaymentLines."Sales/Purchase"::Purchase, PostedPaymentLines.Type::Invoice, DocumentNo);

        // [THEN] Amount on Posted Payment Line equals "Amount Including VAT" in posted Document
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        PostedPaymentLines.TestField(Amount, PurchInvHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPaymentLinesUpdateAmountForPurchCrMemo()
    var
        PurchHeader: Record "Purchase Header";
        PostedPaymentLines: Record "Posted Payment Lines";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Payment Lines]
        // [SCENARIO 283787] TAB 12171 "Posted Payment Lines" UpdateAmount works for Purchase Credit Memo
        Initialize();

        // [GIVEN] Document was created and posted
        LibraryPurchase.CreatePurchaseCreditMemo(PurchHeader);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [WHEN] Posted Payment Lines are Recalculated using Posted Payments page
        RecalcPostedPaymentsLinesThroughPostedPaymentsPage(
          PostedPaymentLines, PostedPaymentLines."Sales/Purchase"::Purchase, PostedPaymentLines.Type::"Credit Memo", DocumentNo);

        // [THEN] Amount on Posted Payment Line equals "Amount Including VAT" in posted Document
        PurchCrMemoHdr.Get(DocumentNo);
        PurchCrMemoHdr.CalcFields("Amount Including VAT");
        PostedPaymentLines.TestField(Amount, PurchCrMemoHdr."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPaymentLinesUpdateAmountForSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        PostedPaymentLines: Record "Posted Payment Lines";
        SalesInvHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice] [Payment Lines]
        // [SCENARIO 283787] TAB 12171 "Posted Payment Lines" UpdateAmount works for Sales Invoice
        Initialize();

        // [GIVEN] Document was created and posted
        LibrarySales.CreateSalesInvoice(SalesHeader);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Posted Payment Lines are Recalculated using Posted Payments page
        RecalcPostedPaymentsLinesThroughPostedPaymentsPage(
          PostedPaymentLines, PostedPaymentLines."Sales/Purchase"::Sales, PostedPaymentLines.Type::Invoice, DocumentNo);

        // [THEN] Amount on Posted Payment Line equals "Amount Including VAT" in posted Document
        SalesInvHeader.Get(DocumentNo);
        SalesInvHeader.CalcFields("Amount Including VAT");
        PostedPaymentLines.TestField(Amount, SalesInvHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPaymentLinesUpdateAmountForSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        PostedPaymentLines: Record "Posted Payment Lines";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo] [Payment Lines]
        // [SCENARIO 283787] TAB 12171 "Posted Payment Lines" UpdateAmount works for Sales Credit Memo
        Initialize();

        // [GIVEN] Document was created and posted
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Posted Payment Lines are Recalculated using Posted Payments page
        RecalcPostedPaymentsLinesThroughPostedPaymentsPage(
          PostedPaymentLines, PostedPaymentLines."Sales/Purchase"::Sales, PostedPaymentLines.Type::"Credit Memo", DocumentNo);

        // [THEN] Amount on Posted Payment Line equals "Amount Including VAT" in posted Document
        SalesCrMemoHeader.Get(DocumentNo);
        SalesCrMemoHeader.CalcFields("Amount Including VAT");
        PostedPaymentLines.TestField(Amount, SalesCrMemoHeader."Amount Including VAT");
    end;

    [Test]
    procedure ErrorOnMissingSalesPrepaymentAccountInVATPostingSetup()
    VAR
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 403116] An error "Sales Prepayments Account must have a value in VAT Posting Setup" is shown
        // [SCENARIO 403116] in case of blanked account on trying posting prepayment invoice
        Initialize();
        EnableUnrealizedVAT(true);

        FindGenPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(VATPostingSetup, GeneralPostingSetup."Gen. Prod. Posting Group");
        VATPostingSetup.Validate("Sales Prepayments Account", '');
        VATPostingSetup.Modify(true);

        CreateSalesDocumentSetPrepmtAccount(SalesHeader, VATPostingSetup, GeneralPostingSetup."Gen. Bus. Posting Group");
        asserterror PostSalesPrepmtInvoice(SalesHeader);

        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError('Sales Prepayments Account must have a value in VAT Posting Setup');
    end;

    [Test]
    procedure ErrorOnMissingPurchPrepaymentAccountInVATPostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 403116] An error "Purch. Prepayments Account must have a value in VAT Posting Setup" is shown
        // [SCENARIO 403116] in case of blanked account on trying posting prepayment invoice
        Initialize();
        EnableUnrealizedVAT(true);

        FindGenPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(VATPostingSetup, GeneralPostingSetup."Gen. Prod. Posting Group");
        VATPostingSetup.Validate("Purch. Prepayments Account", '');
        VATPostingSetup.Modify(true);

        CreatePurchDocumentSetPrepmtAccount(PurchaseHeader, VATPostingSetup, GeneralPostingSetup."Gen. Bus. Posting Group");
        asserterror PostPurchPrepmtInvoice(PurchaseHeader);

        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError('Purch. Prepayments Account must have a value in VAT Posting Setup');
    end;

    local procedure Initialize()
    begin
        Clear(LibraryReportDataset);
    end;

    local procedure EnableUnrealizedVAT(UnrealVAT: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Unrealized VAT", UnrealVAT);
        GLSetup.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; GenProdPostingGroup: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT Identifier", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Sales VAT Unreal. Account", GLAccount."No.");
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", GLAccount."No.");
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("Sales Prepayments Account",
          CreatePrepaymentAccount(GenProdPostingGroup, VATPostingSetup."VAT Prod. Posting Group"));
        VATPostingSetup.Validate("Purch. Prepayments Account",
          CreatePrepaymentAccount(GenProdPostingGroup, VATPostingSetup."VAT Prod. Posting Group"));
        VATPostingSetup.Modify(true);
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

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePrepaymentAccount(GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandInt(50));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(100, 2));  // Taken RANDOM value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePostSalesOrderWithPrepmt(var VATPostingSetup: Record "VAT Posting Setup"; var SalesHeader: Record "Sales Header"; var PrepmtInvNo: Code[20]; var DocumentNo: Code[20])
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        FindGenPostingSetup(GenPostingSetup);
        CreateVATPostingSetup(VATPostingSetup, GenPostingSetup."Gen. Prod. Posting Group");

        CreateSalesDocumentSetPrepmtAccount(SalesHeader, VATPostingSetup, GenPostingSetup."Gen. Bus. Posting Group");
        PrepmtInvNo := PostSalesPrepmtInvoice(SalesHeader);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreatePostPurchOrderWithPrepmt(var VATPostingSetup: Record "VAT Posting Setup"; var PurchHeader: Record "Purchase Header"; var PrepmtInvNo: Code[20]; var DocumentNo: Code[20])
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        FindGenPostingSetup(GenPostingSetup);
        CreateVATPostingSetup(VATPostingSetup, GenPostingSetup."Gen. Prod. Posting Group");

        CreatePurchDocumentSetPrepmtAccount(PurchHeader, VATPostingSetup, GenPostingSetup."Gen. Bus. Posting Group");
        PrepmtInvNo := PostPurchPrepmtInvoice(PurchHeader);
        DocumentNo := PostPurchaseDocument(PurchHeader);
    end;

    local procedure CreateSalesDocumentSetPrepmtAccount(var SalesHeader: Record "Sales Header"; var VATPostingSetup: Record "VAT Posting Setup"; GenBusPostingGroup: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", GenBusPostingGroup);
        CreateSalesLine(SalesHeader, SalesLine, VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreatePurchDocumentSetPrepmtAccount(var PurchHeader: Record "Purchase Header"; var VATPostingSetup: Record "VAT Posting Setup"; GenBusPostingGroup: Code[20])
    var
        PurchLine: Record "Purchase Line";
        GenLedgSetup: Record "General Ledger Setup";
    begin
        CreatePurchHeader(PurchHeader, VATPostingSetup."VAT Bus. Posting Group", GenBusPostingGroup);
        CreatePurchLine(PurchHeader, PurchLine, VATPostingSetup."VAT Prod. Posting Group");
        UpdateCheckTotalOnPuchaseInvoice(
          PurchHeader, Round(GetTotalPurchPrepmtAmount(PurchHeader), GenLedgSetup."Amount Rounding Precision"));
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandInt(50));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(100, 2));  // Taken RANDOM value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; VATBusPostGroupCode: Code[20]; GenBusPostingGroup: Code[20])
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(VATBusPostGroupCode));
        SalesHeader.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandInt(50));
        SalesHeader.Modify(true);
    end;

    local procedure CreatePurchHeader(var PurchHeader: Record "Purchase Header"; VATBusPostGroupCode: Code[20]; GenBusPostingGroup: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Order, CreateVendor(VATBusPostGroupCode));
        PurchHeader.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        PurchHeader.Validate("Prepayment %", LibraryRandom.RandInt(50));
        PurchHeader.Validate("Prepayment Due Date", PurchHeader."Posting Date");
        PurchHeader.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; VATProdPostGroupCode: Code[20])
    begin
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATProdPostGroupCode),
            LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchLine(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; VATProdPostGroupCode: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::Item, CreateItem(VATProdPostGroupCode),
          LibraryRandom.RandDec(100, 2));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
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

    local procedure CreateCustLedgerEntry(CustomerNo: Code[20]; AmountToApply: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        exit(CreateAndPostGenJournalLine(GenJournalLine."Account Type"::Customer, CustomerNo, AmountToApply));
    end;

    local procedure CreateVendLedgerEntry(VendorNo: Code[20]; AmountToApply: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        exit(CreateAndPostGenJournalLine(GenJournalLine."Account Type"::Vendor, VendorNo, AmountToApply));
    end;

    local procedure CreateAndPostGenJournalLine(AccountType: Enum "Gen. Journal Account Type"; PartnerNo: Code[20]; AmountToApply: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJnlLine(GenJournalLine, AccountType, PartnerNo, AmountToApply);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateGeneralJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; AmountToApply: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectAndClearGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, AmountToApply);
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        ApplyCustomerEntry(CustLedgerEntry, DocumentType, DocumentNo, DocumentNo2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure ApplyAndPostVendorEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        ApplyVendorEntry(VendLedgerEntry, DocumentType, DocumentNo, DocumentNo2);
        LibraryERM.PostVendLedgerApplication(VendLedgerEntry);
    end;

    local procedure ApplyVendorEntry(var VendLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        VendLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgerEntry, DocumentType, DocumentNo);
        VendLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendLedgerEntry, VendLedgerEntry."Remaining Amount");

        VendLedgerEntry2.SetRange("Document No.", DocumentNo2);
        VendLedgerEntry2.FindFirst();

        LibraryERM.SetAppliestoIdVendor(VendLedgerEntry2);
    end;

    local procedure ApplyCustomerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Remaining Amount");

        CustLedgerEntry2.SetRange("Document No.", DocumentNo2);
        CustLedgerEntry2.FindFirst();

        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
    end;

    local procedure ApplySalesInvoicePayment(CustomerNo: Code[20]; InvoiceNoToApply: Code[20]; AmountToApply: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        ApplyInvoicePayment(
          CustomerNo, GenJournalLine."Account Type"::Customer, InvoiceNoToApply, AmountToApply);
    end;

    local procedure ApplyPurchInvoicePayment(VendorNo: Code[20]; InvoiceNoToApply: Code[20]; AmountToApply: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        ApplyInvoicePayment(
          VendorNo, GenJournalLine."Account Type"::Vendor, InvoiceNoToApply, AmountToApply);
    end;

    local procedure ApplyInvoicePayment(AccountNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; InvoiceNoToApply: Code[20]; AmountToApply: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJnlLine(GenJournalLine, AccountType, AccountNo, AmountToApply);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNoToApply);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure SelectAndClearGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure PostPurchaseDocument(var PurchHeader: Record "Purchase Header"): Code[20]
    var
        GenLedgSetup: Record "General Ledger Setup";
    begin
        PurchHeader.Validate("Vendor Invoice No.",
          LibraryUtility.GenerateRandomCode(PurchHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        UpdateCheckTotalOnPuchaseInvoice(
          PurchHeader, Round(GetTotalPurchAmount(PurchHeader), GenLedgSetup."Amount Rounding Precision"));
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure PostSalesPrepmtInvoice(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        SalesPostPrepayments.Invoice(SalesHeader);
        exit(SalesHeader."Last Prepayment No.");
    end;

    local procedure PostPurchPrepmtInvoice(var PurchHeader: Record "Purchase Header"): Code[20]
    var
        PurchPostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        PurchPostPrepayments.Invoice(PurchHeader);
        exit(PurchHeader."Last Prepayment No.");
    end;

    local procedure RecalcPostedPaymentsLinesThroughPostedPaymentsPage(var PostedPaymentLines: Record "Posted Payment Lines"; SalesPurchase: Option; DocumentType: Option; DocumentNo: Code[20])
    var
        PostedPaymentsPage: TestPage "Posted Payments";
    begin
        GetPostedPaymentLineForDocument(PostedPaymentLines, SalesPurchase, DocumentType, DocumentNo);

        PostedPaymentsPage.OpenView();
        PostedPaymentsPage.GotoRecord(PostedPaymentLines);
        PostedPaymentsPage.RecalcAmount.Invoke();

        PostedPaymentLines.Find();
    end;

    local procedure GetCustomerLedgerEntryAmount(DocumentNo: Code[20]): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        exit(CustLedgerEntry."Amount (LCY)");
    end;

    local procedure GetVendorLedgerEntryAmount(DocumentNo: Code[20]): Decimal
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendLedgerEntry.CalcFields("Amount (LCY)");
        exit(VendLedgerEntry."Amount (LCY)");
    end;

    local procedure GetTotalPurchAmount(PurchHeader: Record "Purchase Header"): Decimal
    var
        PurchLine: Record "Purchase Line";
        TotalAmount: Decimal;
        LineAmount: Decimal;
    begin
        TotalAmount := 0;
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.FindSet();
        repeat
            LineAmount := PurchLine."Outstanding Amount (LCY)";
            TotalAmount += LineAmount;
        until PurchLine.Next() = 0;
        exit(TotalAmount);
    end;

    local procedure GetTotalPurchPrepmtAmount(PurchHeader: Record "Purchase Header"): Decimal
    var
        PurchLine: Record "Purchase Line";
        PrepmtVATPct: Decimal;
        PrepmtLineAmount: Decimal;
        PrepmtTotalAmount: Decimal;
    begin
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Prepmt. Amt. Inv.", 0);
        PurchLine.FindSet();

        PrepmtVATPct := PurchLine."Prepayment VAT %";
        PrepmtTotalAmount := 0;
        repeat
            if PurchHeader."Prices Including VAT" then
                PrepmtLineAmount := PurchLine."Prepmt. Line Amount"
            else
                PrepmtLineAmount := PurchLine."Prepmt. Line Amount" * (1 + PrepmtVATPct / 100);
            PrepmtTotalAmount += PrepmtLineAmount;
        until PurchLine.Next() = 0;

        exit(PrepmtTotalAmount);
    end;

    local procedure GetPostedPaymentLineForDocument(var PostedPaymentLines: Record "Posted Payment Lines"; SalesPurchase: Option; DocumentType: Option; DocumentNo: Code[20])
    begin
        PostedPaymentLines.SetRange("Sales/Purchase", SalesPurchase);
        PostedPaymentLines.SetRange(Type, DocumentType);
        PostedPaymentLines.SetRange(Code, DocumentNo);
        PostedPaymentLines.FindFirst();
    end;

    local procedure SetupAndRunPurchasePrepmtDocumentTestReport(var PurchaseLine: Record "Purchase Line"; PurchPrepaymentsAccount: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchasePrepmtDocTest: Report "Purchase Prepmt. Doc. - Test";
    begin
        // Setup.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Purch. Prepayments Account", PurchPrepaymentsAccount);
        VATPostingSetup.Modify();
        CreatePurchaseDocument(PurchaseLine, VATPostingSetup);

        // Exercise: Run Sales Prepmt. Document Test report.
        Clear(PurchasePrepmtDocTest);
        PurchaseHeader.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseHeader.SetRange("No.", PurchaseLine."Document No.");
        PurchasePrepmtDocTest.SetTableView(PurchaseHeader);
        Commit();
        PurchasePrepmtDocTest.Run();
    end;

    local procedure SetupAndRunSalesPrepmtDocumentTestReport(var SalesLine: Record "Sales Line"; SalesPrepaymentsAccount: Code[20])
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesPrepmtDocumentTest: Report "Sales Prepmt. Document Test";
    begin
        // Setup.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Sales Prepayments Account", SalesPrepaymentsAccount);
        VATPostingSetup.Modify();
        CreateSalesDocument(SalesLine, VATPostingSetup);

        // Exercise: Run Purchase Prepmt. Document Test report.
        Clear(SalesPrepmtDocumentTest);
        SalesHeader.SetRange("Document Type", SalesLine."Document Type");
        SalesHeader.SetRange("No.", SalesLine."Document No.");
        SalesPrepmtDocumentTest.SetTableView(SalesHeader);
        Commit();
        SalesPrepmtDocumentTest.Run();
    end;

    local procedure UpdateCheckTotalOnPuchaseInvoice(var PurchHeader: Record "Purchase Header"; CheckTotal: Decimal)
    begin
        PurchHeader.Validate("Check Total", CheckTotal);
        PurchHeader.Modify(true);
    end;

    local procedure FindGenPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    begin
        GeneralPostingSetup.SetFilter("Sales Account", '<>''''');
        GeneralPostingSetup.SetFilter("Purch. Account", '<>''''');
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindSet();
    end;

    local procedure VerifyReportValues(AccountNo: Code[20]; VATIdentifierValue: Code[20]; PrepmtLineAmount: Decimal; VATPctValue: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(AccountNo);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLAccountNoCap, AccountNo);
        LibraryReportDataset.AssertElementWithValueExists(DescriptionCap, GLAccount.Name);
        LibraryReportDataset.AssertElementWithValueExists(AmountCap, PrepmtLineAmount);
        LibraryReportDataset.AssertElementWithValueExists(VATAmountCap, Round(PrepmtLineAmount * VATPctValue / 100));
        LibraryReportDataset.AssertElementWithValueExists(VATPctCap, VATPctValue);
        LibraryReportDataset.AssertElementWithValueExists(VATIdentifierCap, VATIdentifierValue);
        LibraryReportDataset.AssertElementWithValueExists(SumPrepaymInvLineBufferAmountCap, PrepmtLineAmount);
        LibraryReportDataset.AssertElementWithValueExists(VATAmountCap2, Round(PrepmtLineAmount * VATPctValue / 100));
        LibraryReportDataset.AssertElementWithValueExists(
          AmountInclVATAmountCap, Round(PrepmtLineAmount + PrepmtLineAmount * VATPctValue / 100));
    end;

    local procedure VerifyWarningMessageOnReport(WarningCaption: Text; WarningCaption2: Text; WarningMsg2: Text)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(WarningCaption, StrSubstNo(WarningMsg2));
        LibraryReportDataset.AssertElementWithValueExists(WarningCaption2, StrSubstNo(WarningMsg));
    end;

    local procedure VerifyGLAccount(GLAccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccountNo);
        GLAccount.CalcFields("Net Change");
        Assert.AreEqual(ExpectedAmount, GLAccount."Net Change", WrongAmountErr);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::Invoice);
        repeat
            VATEntry.TestField("Remaining Unrealized Amount", 0);
            VATEntry.TestField("Remaining Unrealized Base", 0);
        until VATEntry.Next() = 0;
    end;

    local procedure VerifySalesPaymentLineExists(OrderNo: Code[20])
    var
        PaymentLines: Record "Payment Lines";
    begin
        PaymentLines.SetRange("Sales/Purchase", PaymentLines."Sales/Purchase"::Sales);
        PaymentLines.SetRange(Type, PaymentLines.Type::Order);
        PaymentLines.SetRange("Line No.", 10000);
        PaymentLines.SetRange(Code, OrderNo);
        Assert.RecordIsNotEmpty(PaymentLines);
    end;

    local procedure VerifySalesPostedPaymentLineExists(InvoiceNo: Code[20])
    var
        PostedPaymentLines: Record "Posted Payment Lines";
    begin
        PostedPaymentLines.SetRange("Sales/Purchase", PostedPaymentLines."Sales/Purchase"::Sales);
        PostedPaymentLines.SetRange(Type, PostedPaymentLines.Type::Invoice);
        PostedPaymentLines.SetRange("Line No.", 10000);
        PostedPaymentLines.SetRange(Code, InvoiceNo);
        Assert.RecordIsNotEmpty(PostedPaymentLines);
    end;

    local procedure VerifyPurchasePaymentLineExists(OrderNo: Code[20])
    var
        PaymentLines: Record "Payment Lines";
    begin
        PaymentLines.SetRange("Sales/Purchase", PaymentLines."Sales/Purchase"::Purchase);
        PaymentLines.SetRange(Type, PaymentLines.Type::Order);
        PaymentLines.SetRange("Line No.", 10000);
        PaymentLines.SetRange(Code, OrderNo);
        Assert.RecordIsNotEmpty(PaymentLines);
    end;

    local procedure VerifyPurchasePostedPaymentLineExists(InvoiceNo: Code[20])
    var
        PostedPaymentLines: Record "Posted Payment Lines";
    begin
        PostedPaymentLines.SetRange("Sales/Purchase", PostedPaymentLines."Sales/Purchase"::Purchase);
        PostedPaymentLines.SetRange(Type, PostedPaymentLines.Type::Invoice);
        PostedPaymentLines.SetRange("Line No.", 10000);
        PostedPaymentLines.SetRange(Code, InvoiceNo);
        Assert.RecordIsNotEmpty(PostedPaymentLines);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchasePrepmtDocTestReportHandler(var PurchasePrepmtDocTest: TestRequestPage "Purchase Prepmt. Doc. - Test")
    begin
        PurchasePrepmtDocTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesPrepmtDocumentTestReportHandler(var SalesPrepmtDocumentTest: TestRequestPage "Sales Prepmt. Document Test")
    begin
        SalesPrepmtDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

