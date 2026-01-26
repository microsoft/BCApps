codeunit 141037 "ERM VAT For SEA"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT] [WHT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryAPACLocalization: Codeunit "Library - APAC Localization";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        ValueMatchMsg: Label 'Value must be same.';
        WHTCertErr: Label 'WHT Certificate No. Series must have a value in Purchases & Payables Setup';

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPaymentAfterPostSalesInvoice()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Amount after create and post Sales Invoice and apply payment.

        // [GIVEN] Create General Posting Setup and WHT Posting Setup. Find VAT Posting Setup.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateGeneralPostingSetup(GeneralPostingSetup, VATPostingSetup);
        CreateWHTPostingSetup(WHTPostingSetup, GeneralPostingSetup);
        CustomerNo := CreateCustomer(GeneralPostingSetup."Gen. Bus. Posting Group", WHTPostingSetup."WHT Business Posting Group");

        // Exercise & Verify.
        PostSalesInvoiceAndApplyPayment(
          CustomerNo, CustomerNo, CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group",
            WHTPostingSetup."WHT Product Posting Group"), SalesHeader."Document Type"::Order, WHTPostingSetup."WHT %");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure ApplyPaymentAfterPostSalesInvWithDiffBillToCustNo()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        // [SCENARIO] Amount after create and post Sales Invoice and apply payment with different Bill to Customer No.

        // [GIVEN] Create General Posting Setup and WHT Posting Setup. Find VAT Posting Setup.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateGeneralPostingSetup(GeneralPostingSetup, VATPostingSetup);
        CreateWHTPostingSetup(WHTPostingSetup, GeneralPostingSetup);

        // Exercise & Verify.
        PostSalesInvoiceAndApplyPayment(
          CreateCustomer(GeneralPostingSetup."Gen. Bus. Posting Group", WHTPostingSetup."WHT Business Posting Group"),
          CreateCustomer(GeneralPostingSetup."Gen. Bus. Posting Group", WHTPostingSetup."WHT Business Posting Group"),
          CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group", WHTPostingSetup."WHT Product Posting Group"),
          SalesHeader."Document Type"::Invoice, WHTPostingSetup."WHT %");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure ApplyPartialPmtAfterPostSOWithDiffBillToCustNo()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        // [SCENARIO] Amount after create and post Sales Order and apply partial payments with different Bill to Customer No.

        // [GIVEN] Create General Posting Setup and WHT Posting Setup. Find VAT Posting Setup.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateGeneralPostingSetup(GeneralPostingSetup, VATPostingSetup);
        CreateWHTPostingSetup(WHTPostingSetup, GeneralPostingSetup);

        // Exercise & Verify.
        PostSalesOrderAndApplyPartialPayment(
          CreateCustomer(GeneralPostingSetup."Gen. Bus. Posting Group", WHTPostingSetup."WHT Business Posting Group"),
          CreateCustomer(GeneralPostingSetup."Gen. Bus. Posting Group", WHTPostingSetup."WHT Business Posting Group"),
          CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group", WHTPostingSetup."WHT Product Posting Group"),
          WHTPostingSetup."WHT %", VATPostingSetup."VAT %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPartialPaymentAfterPostSalesOrder()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Amount after create and post Sales Order and apply partial payments.

        // [GIVEN] Create General Posting Setup and WHT Posting Setup. Find VAT Posting Setup.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateGeneralPostingSetup(GeneralPostingSetup, VATPostingSetup);
        CreateWHTPostingSetup(WHTPostingSetup, GeneralPostingSetup);
        CustomerNo := CreateCustomer(GeneralPostingSetup."Gen. Bus. Posting Group", WHTPostingSetup."WHT Business Posting Group");

        // Exercise & Verify.
        PostSalesOrderAndApplyPartialPayment(
          CustomerNo, CustomerNo, CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group",
            WHTPostingSetup."WHT Product Posting Group"), WHTPostingSetup."WHT %", VATPostingSetup."VAT %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyRefundAfterPostSalesCreditMemo()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
        VATAmount: Decimal;
    begin
        // [SCENARIO] Amount after create and post Sales Credit Memo and apply refund.

        // [GIVEN] Create Customer, create and post Sales Credit Memo.
        Initialize();
        UpdateSalesReceivablesSetup();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateGeneralPostingSetup(GeneralPostingSetup, VATPostingSetup);
        CreateWHTPostingSetup(WHTPostingSetup, GeneralPostingSetup);
        CustomerNo := CreateCustomer(GeneralPostingSetup."Gen. Bus. Posting Group", WHTPostingSetup."WHT Business Posting Group");
        CreateAndPostSalesDocument(
          SalesLine, SalesLine."Document Type"::"Credit Memo", CustomerNo, CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group",
            WHTPostingSetup."WHT Product Posting Group"), CustomerNo);
        Amount := SalesLine."Amount Including VAT" - (SalesLine.Amount * WHTPostingSetup."WHT %" / 100);  // Calculate Amount excluding WHT Amount.
        VATAmount := (SalesLine.Amount * VATPostingSetup."VAT %") / 100;  // Calculate VAT Amount.

        // Exercise.
        DocumentNo :=
          CreateAndPostGeneralJournalLine(
            SalesLine."Sell-to Customer No.", FindPostedSalesCreditMemo(SalesLine."No."), Amount, GenJournalLine."Account Type"::Customer,
            GenJournalLine."Document Type"::Refund, GenJournalLine."Applies-to Doc. Type"::"Credit Memo",
            GenJournalTemplate.Type::"Cash Receipts");

        // Verify.
        VerifyVATEntry(
          GenJournalLine."Document Type"::"Credit Memo", FindPostedSalesCreditMemo(SalesLine."No."), VATAmount, SalesLine.Amount);
        VerifyWHTEntry(
          GenJournalLine."Document Type"::"Credit Memo", FindPostedSalesCreditMemo(SalesLine."No."),
          SalesLine.Amount * WHTPostingSetup."WHT %" / 100, SalesLine.Amount);
        VerifyGLEntry(GenJournalLine."Document Type"::Refund, DocumentNo, -Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure ApplyPaymentAfterPostPOWithDiffPayToVendNo()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        // [SCENARIO] Amount after create and post Purchase Order and apply Payments with different Pay to Vendor No.

        // [GIVEN] Create General Posting Setup and WHT Posting Setup. Find VAT Posting Setup.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateGeneralPostingSetup(GeneralPostingSetup, VATPostingSetup);
        CreateWHTPostingSetup(WHTPostingSetup, GeneralPostingSetup);

        // Exercise & Verify.
        PostPurchaseInvoiceAndApplyPayment(
          CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", WHTPostingSetup."WHT Business Posting Group"),
          CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", WHTPostingSetup."WHT Business Posting Group"), CreateGLAccount(
            GeneralPostingSetup."Gen. Prod. Posting Group", WHTPostingSetup."WHT Product Posting Group"),
          PurchaseLine."Document Type"::Order, WHTPostingSetup."WHT %", VATPostingSetup."VAT %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPaymentAfterPostPurchaseInvoice()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        VendorNo: Code[20];
    begin
        // [SCENARIO] Amount after create and post Purchase Invoice and apply Payments.

        // [GIVEN] Create General Posting Setup and WHT Posting Setup. Find VAT Posting Setup.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateGeneralPostingSetup(GeneralPostingSetup, VATPostingSetup);
        CreateWHTPostingSetup(WHTPostingSetup, GeneralPostingSetup);
        VendorNo := CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", WHTPostingSetup."WHT Business Posting Group");

        // Exercise & Verify.
        PostPurchaseInvoiceAndApplyPayment(
          VendorNo, VendorNo, CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group", WHTPostingSetup."WHT Product Posting Group"),
          PurchaseLine."Document Type"::Invoice, WHTPostingSetup."WHT %", VATPostingSetup."VAT %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyRefundAfterPostPurchaseCreditMemo()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        VendorNo: Code[20];
        Amount: Decimal;
        VATAmount: Decimal;
    begin
        // [SCENARIO] after create and post a Purchase Credit Memo and apply partial refund.

        // [GIVEN] Create and post Purchase Credit Memo and partially post Gen. Journal Line.
        Initialize();
        UpdatePurchasesPayableSetup();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateGeneralPostingSetup(GeneralPostingSetup, VATPostingSetup);
        CreateWHTPostingSetup(WHTPostingSetup, GeneralPostingSetup);
        VendorNo := CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", WHTPostingSetup."WHT Business Posting Group");
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", PurchaseLine.Type::Item, VendorNo, CreateItem(
            GeneralPostingSetup."Gen. Prod. Posting Group", WHTPostingSetup."WHT Product Posting Group",
            VATPostingSetup."VAT Prod. Posting Group"), VendorNo);
        Amount := PurchaseLine."Amount Including VAT" - (PurchaseLine.Amount * WHTPostingSetup."WHT %" / 100);  // Calculate Amount excluding WHT Amount.
        VATAmount := (PurchaseLine.Amount / 2) + (PurchaseLine.Amount * VATPostingSetup."VAT %" / 200);  // Calculate Partial Amount including VAT.
        DocumentNo :=
          CreateAndPostGeneralJournalLine(
            PurchaseLine."Buy-from Vendor No.", FindPostedPurchaseCreditMemo(PurchaseLine."No."),
            -PurchaseLine."Amount Including VAT" / 2, GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Refund,
            GenJournalLine."Applies-to Doc. Type"::"Credit Memo", GenJournalTemplate.Type::Payments);

        // Exercise.
        DocumentNo2 :=
          CreateAndPostGeneralJournalLine(
            PurchaseLine."Buy-from Vendor No.", FindPostedPurchaseCreditMemo(PurchaseLine."No."), VATAmount - Amount,
            GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Refund,
            GenJournalLine."Applies-to Doc. Type"::"Credit Memo", GenJournalTemplate.Type::Payments);

        // Verify.
        VerifyVATEntry(
          GenJournalLine."Document Type"::"Credit Memo", FindPostedPurchaseCreditMemo(
            PurchaseLine."No."), -PurchaseLine.Amount * VATPostingSetup."VAT %" / 100, -PurchaseLine.Amount);
        VerifyWHTEntry(
          GenJournalLine."Document Type"::"Credit Memo", FindPostedPurchaseCreditMemo(
            PurchaseLine."No."), -PurchaseLine.Amount * WHTPostingSetup."WHT %" / 100, -PurchaseLine.Amount);
        VerifyGLEntry(GenJournalLine."Document Type"::Refund, DocumentNo, VATAmount);
        VerifyGLEntry(GenJournalLine."Document Type"::Refund, DocumentNo2, Amount - VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWHTEntryWithoutAnyError()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        VendorNo: Code[20];
    begin
        // [SCENARIO] No Error message is displayed when a Purchase Invoice with WHT calculation is posted - AU
        Initialize();

        // [GIVEN] Find VAT Posting Setup.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        //[GIVEN] Create General Posting Setup 
        CreateGeneralPostingSetup(GeneralPostingSetup, VATPostingSetup);

        // [GIVEN] Create WHT Posting Setup
        CreateWHTPostingSetup(WHTPostingSetup, GeneralPostingSetup);

        // [GIVEN] Create Vendor
        VendorNo := CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", WHTPostingSetup."WHT Business Posting Group");

        // [VERIFY] Post and Verify the WHT Entry created successfully
        PostPurchaseInvoiceAndVerifyWHTEntry(
        VendorNo, VendorNo, CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group", WHTPostingSetup."WHT Product Posting Group"),
          PurchaseLine."Document Type"::Invoice, WHTPostingSetup."WHT %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyErrorOnWHTCertificateNoSeries()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [SCENARIO] No Error message is displayed when a Purchase Invoice with WHT calculation is posted - AU
        Initialize();

        // [GIVEN] Find VAT Posting Setup.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        //[GIVEN] Create General Posting Setup 
        CreateGeneralPostingSetup(GeneralPostingSetup, VATPostingSetup);

        // [GIVEN] Create WHT Posting Setup
        CreateWHTPostingSetup(WHTPostingSetup, GeneralPostingSetup);

        // [GIVEN] Update WHT Certificate No. Series as blank on Purchase & Payable Setup
        UpdateWHTCertificateNoSerOnPurchSetup();

        // [GIVEN] Create Vendor
        VendorNo := CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", WHTPostingSetup."WHT Business Posting Group");

        // [GIVEN] Create G/l Account
        GLAccountNo := CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group", WHTPostingSetup."WHT Product Posting Group");

        // [VERIFY] Create and Post the Purchase Invoice
        asserterror CreateAndPostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, PurchaseLine.Type::"G/L Account", VendorNo, GLAccountNo, VendorNo);

        // [GIVEN] Verify the WHT Certificate No. series error
        Assert.IsSubstring(GetLastErrorText(), WHTCertErr);
    end;

    local procedure Initialize()
    begin
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        UpdateGeneralLedgerSetup();
    end;

    local procedure CreateAndPostGeneralJournalLine(AccountNo: Code[20]; AppliesToDocNo: Code[20]; Amount: Decimal; AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type"; AppliesToDocType: Enum "Gen. Journal Document Type"; Type: Enum "Gen. Journal Template Type"): Code[20]
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.FindBankAccount(BankAccount);
        CreateGeneralJournalBatch(GenJournalBatch, Type);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; BillToCustomerNo: Code[20]; No: Code[20]; SellToCustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, SellToCustomerNo);
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomerNo);
        SalesHeader.Validate("Tax Document Marked", true);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", No, LibraryRandom.RandDec(10, 2));  // Take random Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Invoice.
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Type: Enum "Purchase Line Type"; BuyFromVendorNo: Code[20]; No: Code[20]; PayToVendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Pay-to Vendor No.", PayToVendorNo);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2)); // Take random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Invoice.
    end;

    local procedure CreateCustomer(GenBusPostingGroup: Code[20]; WHTBusinessPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
    begin
        GenBusinessPostingGroup.Get(GenBusPostingGroup);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        Customer.Validate("Tax Document Type", Customer."Tax Document Type"::"Document Post");
        Customer.Validate("WHT Business Posting Group", WHTBusinessPostingGroup);
        Customer.Validate("VAT Bus. Posting Group", GenBusinessPostingGroup."Def. VAT Bus. Posting Group");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Enum "Gen. Journal Template Type")
    var
        BankAccount: Record "Bank Account";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, Type);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindBankAccount(BankAccount);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGenBusPostingGroup(DefVATBusPostingGroup: Code[20]): Code[20]
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        GenBusinessPostingGroup.Validate("Def. VAT Bus. Posting Group", DefVATBusPostingGroup);
        GenBusinessPostingGroup.Modify(true);
        exit(GenBusinessPostingGroup.Code)
    end;

    local procedure CreateGenProdPostingGroup(DefVATProdPostingGroup: Code[20]): Code[20]
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", DefVATProdPostingGroup);
        GenProductPostingGroup.Modify(true);
        exit(GenProductPostingGroup.Code);
    end;

    local procedure CreateGLAccount(GenProdPostingGroup: Code[20]; WHTProductPostingGroup: Code[20]): Code[20]
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        GenProductPostingGroup.Get(GenProdPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("WHT Product Posting Group", WHTProductPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", GenProductPostingGroup."Def. VAT Prod. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(GenProdPostingGroup: Code[20]; WHTProductPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("WHT Product Posting Group", WHTProductPostingGroup);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateVendor(GenBusPostingGroup: Code[20]; WHTBusinessPostingGroup: Code[20]): Code[20]
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        Vendor: Record Vendor;
    begin
        GenBusinessPostingGroup.Get(GenBusPostingGroup);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(ABN, '');
        Vendor.Validate("WHT Business Posting Group", WHTBusinessPostingGroup);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        Vendor.Validate("VAT Bus. Posting Group", GenBusinessPostingGroup."Def. VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateWHTPostingSetup(var WHTPostingSetup: Record "WHT Posting Setup"; GeneralPostingSetup: Record "General Posting Setup")
    var
        WHTBusinessPostingGroup: Record "WHT Business Posting Group";
        WHTProductPostingGroup: Record "WHT Product Posting Group";
        WHTRevenueTypes: Record "WHT Revenue Types";
    begin
        LibraryAPACLocalization.CreateWHTBusinessPostingGroup(WHTBusinessPostingGroup);
        LibraryAPACLocalization.CreateWHTProductPostingGroup(WHTProductPostingGroup);
        LibraryAPACLocalization.CreateWHTPostingSetup(WHTPostingSetup, WHTBusinessPostingGroup.Code, WHTProductPostingGroup.Code);
        LibraryAPACLocalization.CreateWHTRevenueTypes(WHTRevenueTypes);
        WHTPostingSetup.Validate("Revenue Type", WHTRevenueTypes.Code);
        WHTPostingSetup.Validate("WHT %", LibraryRandom.RandInt(5));
        WHTPostingSetup.Validate("Realized WHT Type", WHTPostingSetup."Realized WHT Type"::Invoice);
        WHTPostingSetup.Validate("Prepaid WHT Account Code", CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group", ''));   // WHT Prod. Posting Group as blank.
        WHTPostingSetup.Validate("Payable WHT Account Code", WHTPostingSetup."Prepaid WHT Account Code");
        WHTPostingSetup.Modify(true);
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.CreateGeneralPostingSetup(
          GeneralPostingSetup, CreateGenBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          CreateGenProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        GeneralPostingSetup.Validate("Direct Cost Applied Account", CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group", ''));  // WHT Prod. Posting Group as blank.
        GeneralPostingSetup.Validate("Purch. Credit Memo Account", GeneralPostingSetup."Direct Cost Applied Account");
        GeneralPostingSetup.Modify(true);
    end;

    local procedure FindPostedPurchaseCreditMemo(No: Code[20]): Code[20]
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange(Type, PurchCrMemoLine.Type::Item);
        PurchCrMemoLine.SetRange("No.", No);
        PurchCrMemoLine.FindFirst();
        exit(PurchCrMemoLine."Document No.");
    end;

    local procedure FindPostedPurchaseInvoice(No: Code[20]): Code[20]
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange(Type, PurchInvLine.Type::"G/L Account");
        PurchInvLine.SetRange("No.", No);
        PurchInvLine.FindFirst();
        exit(PurchInvLine."Document No.");
    end;

    local procedure FindPostedSalesCreditMemo(No: Code[20]): Code[20]
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::"G/L Account");
        SalesCrMemoLine.SetRange("No.", No);
        SalesCrMemoLine.FindFirst();
        exit(SalesCrMemoLine."Document No.");
    end;

    local procedure FindPostedSalesInvoice(No: Code[20]): Code[20]
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::"G/L Account");
        SalesInvoiceLine.SetRange("No.", No);
        SalesInvoiceLine.FindFirst();
        exit(SalesInvoiceLine."Document No.");
    end;

    local procedure PostPurchaseInvoiceAndApplyPayment(BuyFromVendorNo: Code[20]; PayToVendorNo: Code[20]; No: Code[20]; DocumentType: Enum "Purchase Document Type"; WHTPct: Decimal; VATPct: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Create and post Purchase Document.
        UpdatePurchasesPayableSetup();
        CreateAndPostPurchaseDocument(PurchaseLine, DocumentType, PurchaseLine.Type::"G/L Account", BuyFromVendorNo, No, PayToVendorNo);
        Amount := PurchaseLine."Amount Including VAT" - (PurchaseLine.Amount * WHTPct / 100);  // Calculate Amount excluding WHT Amount.

        // Exercise.
        DocumentNo :=
          CreateAndPostGeneralJournalLine(
            PurchaseLine."Pay-to Vendor No.", FindPostedPurchaseInvoice(No), Amount, GenJournalLine."Account Type"::Vendor,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice, GenJournalTemplate.Type::Payments);

        // Verify.
        VerifyVATEntry(
          GenJournalLine."Document Type"::Invoice, FindPostedPurchaseInvoice(No), PurchaseLine.Amount * VATPct / 100, PurchaseLine.Amount);
        VerifyWHTEntry(
          GenJournalLine."Document Type"::Invoice, FindPostedPurchaseInvoice(No), PurchaseLine.Amount * WHTPct / 100, PurchaseLine.Amount);
        VerifyGLEntry(GenJournalLine."Document Type"::Payment, DocumentNo, -Amount);
    end;

    local procedure PostPurchaseInvoiceAndVerifyWHTEntry(BuyFromVendorNo: Code[20]; PayToVendorNo: Code[20]; No: Code[20]; DocumentType: Enum "Purchase Document Type"; WHTPct: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        Amount: Decimal;
        WHTAmount: Decimal;
    begin
        // Create and post Purchase Document.
        UpdatePurchasesPayableSetup();
        CreateAndPostPurchaseDocument(PurchaseLine, DocumentType, PurchaseLine.Type::"G/L Account", BuyFromVendorNo, No, PayToVendorNo);
        WHTAmount := PurchaseLine.Amount * WHTPct / 100;
        Amount := PurchaseLine."Amount Including VAT" - WHTAmount;  // Calculate Amount excluding WHT Amount.

        // Verify.
        VerifyWHTEntry(
         GenJournalLine."Document Type"::Invoice, FindPostedPurchaseInvoice(No), PurchaseLine.Amount * WHTPct / 100, PurchaseLine.Amount);
    end;

    local procedure PostSalesInvoiceAndApplyPayment(BillToCustomerNo: Code[20]; SellToCustomerNo: Code[20]; No: Code[20]; DocumentType: Enum "Sales Document Type"; WHTPct: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Create and post Sales Document.
        UpdateSalesReceivablesSetup();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateAndPostSalesDocument(SalesLine, DocumentType, BillToCustomerNo, No, SellToCustomerNo);
        Amount := SalesLine."Amount Including VAT" - (SalesLine.Amount * WHTPct / 100); // Calculate Amount excluding WHT Amount.

        // Exercise.
        DocumentNo :=
          CreateAndPostGeneralJournalLine(
            SalesLine."Bill-to Customer No.", FindPostedSalesInvoice(SalesLine."No."), -Amount, GenJournalLine."Account Type"::Customer,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
            GenJournalTemplate.Type::"Cash Receipts");

        // Verify.
        VerifyVATEntry(
          GenJournalLine."Document Type"::Invoice, FindPostedSalesInvoice(SalesLine."No."),
          -SalesLine.Amount * VATPostingSetup."VAT %" / 100, -SalesLine.Amount);
        VerifyWHTEntry(
          GenJournalLine."Document Type"::Invoice, FindPostedSalesInvoice(SalesLine."No."),
          -(SalesLine.Amount * WHTPct / 100), -SalesLine.Amount);
        VerifyGLEntry(GenJournalLine."Document Type"::Payment, DocumentNo, Amount);
    end;

    local procedure PostSalesOrderAndApplyPartialPayment(BillToCustomerNo: Code[20]; SellToCustomerNo: Code[20]; No: Code[20]; WHTPct: Decimal; VATPct: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        Amount: Decimal;
        VATAmount: Decimal;
    begin
        // Create and post Sales Order and partially post Gen. Journal Line.
        UpdateSalesReceivablesSetup();
        CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::Order, BillToCustomerNo, No, SellToCustomerNo);
        Amount := SalesLine."Amount Including VAT" - (SalesLine.Amount * WHTPct / 100);  // Calculate Amount excluding WHT Amount.
        VATAmount := (SalesLine.Amount / 2) + (SalesLine.Amount * VATPct / 200);  // Calculate Partial Amount including VAT.
        DocumentNo :=
          CreateAndPostGeneralJournalLine(SalesLine."Bill-to Customer No.", FindPostedSalesInvoice(SalesLine."No."),
            -SalesLine."Amount Including VAT" / 2, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Applies-to Doc. Type"::Invoice, GenJournalTemplate.Type::"Cash Receipts");

        // Exercise.
        DocumentNo2 :=
          CreateAndPostGeneralJournalLine(
            SalesLine."Bill-to Customer No.", FindPostedSalesInvoice(SalesLine."No."), VATAmount - Amount,
            GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Applies-to Doc. Type"::Invoice, GenJournalTemplate.Type::"Cash Receipts");

        // Verify.
        VerifyVATEntry(
          GenJournalLine."Document Type"::Invoice, FindPostedSalesInvoice(SalesLine."No."), -SalesLine.Amount * VATPct / 100,
          -SalesLine.Amount);
        VerifyWHTEntry(
          GenJournalLine."Document Type"::Invoice, FindPostedSalesInvoice(SalesLine."No."), -(SalesLine.Amount * WHTPct / 100),
          -SalesLine.Amount);
        VerifyGLEntry(GenJournalLine."Document Type"::Payment, DocumentNo, VATAmount);
        VerifyGLEntry(GenJournalLine."Document Type"::Payment, DocumentNo2, Amount - VATAmount);
    end;

    local procedure UpdateGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Enable WHT", true);
        GeneralLedgerSetup.Validate("Enable Tax Invoices", true);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePurchasesPayableSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("WHT Certificate No. Series", LibraryERM.CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Tax Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Tax Credit Memo Nos", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure VerifyGLEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(GLEntry.Amount, Amount, LibraryERM.GetAmountRoundingPrecision(), ValueMatchMsg);
    end;

    local procedure VerifyVATEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Amount: Decimal; Base: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(VATEntry.Amount, Amount, LibraryERM.GetAmountRoundingPrecision(), ValueMatchMsg);
        Assert.AreNearlyEqual(VATEntry.Base, Base, LibraryERM.GetAmountRoundingPrecision(), ValueMatchMsg);
    end;

    local procedure VerifyWHTEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Amount: Decimal; Base: Decimal)
    var
        WHTEntry: Record "WHT Entry";
    begin
        WHTEntry.SetRange("Document Type", DocumentType);
        WHTEntry.SetRange("Document No.", DocumentNo);
        WHTEntry.FindFirst();
        Assert.AreNearlyEqual(WHTEntry.Amount, Amount, LibraryERM.GetAmountRoundingPrecision(), ValueMatchMsg);
        Assert.AreNearlyEqual(WHTEntry.Base, Base, LibraryERM.GetAmountRoundingPrecision(), ValueMatchMsg);
    end;

    local procedure UpdateWHTCertificateNoSerOnPurchSetup()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        PurchSetup.Validate("WHT Certificate No. Series", '');
        PurchSetup.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}

