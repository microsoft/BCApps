codeunit 141056 "APAC ERM Prepayments"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Prepayment]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        AmountErr: Label '%1 must be %2 in %3.';

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtInvWithFullPrepmt()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        OldFullGSTOnPrepayment: Boolean;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] G/L entries after posting 100 % Prepayment Sales Invoice.

        // [GIVEN] Update General Ledger Setup and Create General Posting Setup.
        OldFullGSTOnPrepayment := UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(true);  // True for Full GST On Prepayment
        CreateGeneralPostingSetup(GeneralPostingSetup);

        // [WHEN] Create and Post Prepayment Invoice for Sales Order.
        CreateAndPostPrepaymentSalesInvoice(
          SalesLine, GeneralPostingSetup."Gen. Bus. Posting Group", 100, false, SalesLine.Type::"G/L Account", CreateGLAccount(
            GeneralPostingSetup."Gen. Prod. Posting Group"), 0);  // Value 100 required for Prepayment %, 0 for Discount % and False for Prices Including VAT

        // [THEN] G/L entries of posted Sales Invoice.
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
        SalesInvoiceHeader.FindFirst();
        VerifyGLEntriesOfSalesInvoice(
          SalesInvoiceHeader."No.", GeneralPostingSetup."Sales Prepayments Account", -SalesLine."Line Amount",
          -SalesLine."Line Amount" * SalesLine."VAT %" / 100);

        // Tear Down.
        UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(OldFullGSTOnPrepayment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtAmtInclVATOnSalesPrepmtInvoice()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesLine: Record "Sales Line";
        OldFullGSTOnPrepayment: Boolean;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Prepayment Amount Including VAT on Sales Line after posting 100 % Prepayment Sales Invoice.

        // [GIVEN] Update General Ledger Setup and Create General Posting Setup.
        OldFullGSTOnPrepayment := UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(true);  // True for Full GST On Prepayment
        CreateGeneralPostingSetup(GeneralPostingSetup);

        // [WHEN] Create and Post Prepayment Invoice for Sales Order.
        CreateAndPostPrepaymentSalesInvoice(
          SalesLine, GeneralPostingSetup."Gen. Bus. Posting Group", 100, false, SalesLine.Type::Item,
          CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"), 0);  // Value 100 required for Prepayment %, 0 for Discount % and False for Prices Including VAT

        // [THEN] Prepayment Amount Including VAT on Sales Line.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Prepmt. Amt. Incl. VAT", SalesLine."Amount Including VAT");

        // Tear Down.
        UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(OldFullGSTOnPrepayment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtInvWithPricesInclVAT()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OldFullGSTOnPrepayment: Boolean;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] G/L entries after posting Sales Invoice of 100 % Prepayment Invoice with Prices Including VAT.

        // [GIVEN] Update General Ledger Setup and Create General Posting Setup. Create and Post Prepayment Sales Invoice.
        OldFullGSTOnPrepayment := UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(true);  // True for Full GST On Prepayment
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateAndPostPrepaymentSalesInvoice(
          SalesLine, GeneralPostingSetup."Gen. Bus. Posting Group", 100, true, SalesLine.Type::Item,
          CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"), 0);  // Value 100 required for Prepayment %, 0 for Discount % and True for Prices Including VAT
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise, Verify and Tear Down: Post Sales Invoice and verify G/L entries. Update Full GST on Prepayment on General Ledger Setup.
        PostSalesInvoiceAndVerifyGLEntries(
          SalesHeader, GeneralPostingSetup, SalesLine.Amount, SalesLine.Amount * SalesLine."VAT %" / 100, -SalesLine.Amount,
          OldFullGSTOnPrepayment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtCrMemoAfterPrepmtInvWithLineDiscount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OldFullGSTOnPrepayment: Boolean;
        PrepaymentLineAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] G/L entries after posting Prepayment Sales Credit Memo after updating Prepayment % on Posted Prepayment Invoice.

        // [GIVEN] Update General Ledger Setup and Create General Posting Setup. Create and post Prepayment Sales Invoice. Reopen Sales Order, update Prepayment % and post Prepayment Sales Invoice.
        OldFullGSTOnPrepayment := UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(true);  // True for Full GST On Prepayment
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateAndPostPrepaymentSalesInvoice(
          SalesLine, GeneralPostingSetup."Gen. Bus. Posting Group", LibraryRandom.RandDec(50, 2), false, SalesLine.Type::Item,
          CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"), LibraryRandom.RandDec(20, 2));  // Random value used for Prepayment % and Line Discount %, False for Prices Including VAT.
        UpdatePrepmtPctOnSalesInvoiceAndPostPrepmt(SalesHeader, SalesLine);
        SalesLine.Find();
        PrepaymentLineAmount := SalesLine."Prepmt. Line Amount";

        // Exercise.
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);

        // [THEN] G/L entries of posted Sales Invoice.
        SalesLine.Find();
        VerifyGLEntriesOfSalesInvoice(
          GetPostedSalesPrepaymentCreditMemoNo(SalesLine."Sell-to Customer No."), GeneralPostingSetup."Sales Prepayments Account",
          PrepaymentLineAmount, SalesLine."Line Amount" * SalesLine."VAT %" / 100);

        // Tear Down.
        UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(OldFullGSTOnPrepayment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtAmtInclVATOnPurchInvWithPricesInclVATFalse()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
        OldFullGSTOnPrepayment: Boolean;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Prepayment Amount Including VAT on Purchase Line after posting 100 % Prepayment Purchase Invoice with Prices Including VAT False.

        // [GIVEN] Update General Ledger Setup and Create General Posting Setup.
        OldFullGSTOnPrepayment := UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(true);  // True for Full GST On Prepayment
        CreateGeneralPostingSetup(GeneralPostingSetup);

        // [WHEN] Create and Post Prepayment Invoice for Purchase Order.
        CreateAndPostPrepaymentPurchaseInvoice(PurchaseLine, GeneralPostingSetup, 100, false);  // Value 100 required for Prepayment % and False for Prices Including VAT

        // [THEN] Prepayment Amount Including VAT on Purchase Line.
        VerifyPrepmtAmtInclVATOnPurchaseLine(PurchaseLine, PurchaseLine."Amount Including VAT");

        // Tear Down.
        UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(OldFullGSTOnPrepayment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtAmtInclVATOnPurchInvWithPricesInclVATTrue()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
        OldFullGSTOnPrepayment: Boolean;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Prepayment Amount Including VAT on Purchase Line after posting 100 % Prepayment Purchase Invoice with Prices Including VAT True.

        // [GIVEN] Update General Ledger Setup and Create General Posting Setup.
        OldFullGSTOnPrepayment := UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(true);  // True for Full GST On Prepayment
        CreateGeneralPostingSetup(GeneralPostingSetup);

        // [WHEN] Create and Post Prepayment Invoice for Purchase Order.
        CreateAndPostPrepaymentPurchaseInvoice(PurchaseLine, GeneralPostingSetup, 100, true);  // Value 100 required for Prepayment % and True for Prices Including VAT

        // [THEN] Prepayment Amount Including VAT on Purchase Line.
        VerifyPrepmtAmtInclVATOnPurchaseLine(PurchaseLine, PurchaseLine."Line Amount");

        // Tear Down.
        UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(OldFullGSTOnPrepayment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmtInvWithFullGSTOnPrepaymentFalse()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OldFullGSTOnPrepayment: Boolean;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] G/L entries after posting Purchase Invoice of partial Prepayment Invoice with Prices Including VAT True and Full GST On Payment False.

        // [GIVEN] Update General Ledger Setup and Create General Posting Setup. Create and Post Prepayment Invoice for Purchase Order.
        OldFullGSTOnPrepayment := UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(false);  // False for Full GST On Prepayment
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateAndPostPrepaymentPurchaseInvoice(PurchaseLine, GeneralPostingSetup, LibraryRandom.RandDec(20, 2), true);  // Random value used for Prepayment % and True for Prices Including VAT
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        UpdateVendorInvoiceNo(PurchaseHeader);

        // Exercise, Verify and Tear Down: Post Purchase Invoice and verify G/L entries. Update Full GST on Prepayment on General Ledger Setup.
        PostPurchaseInvoiceAndVerifyGLEntries(
          PurchaseHeader, GeneralPostingSetup, -PurchaseLine.Amount * PurchaseLine."Prepayment %" / 100, PurchaseLine.Amount,
          -PurchaseLine.Amount * PurchaseLine."Prepayment %" * PurchaseLine."VAT %" / 10000, OldFullGSTOnPrepayment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialShipAndInvoiceWithFullSalesPrepmtInvoice()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OldFullGSTOnPrepayment: Boolean;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] G/L entries after posting partial Sales Invoice of full Prepayment Invoice.

        // [GIVEN] Update General Ledger Setup and Create General Posting Setup. Create and Post Prepayment Invoice for Sales Order. Update Qty. to Ship on Sales line and post Prepayment Invoice.
        OldFullGSTOnPrepayment := UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(true);  // True for Full GST On Prepayment
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateAndPostPrepaymentSalesInvoice(
          SalesLine, GeneralPostingSetup."Gen. Bus. Posting Group", 100, false, SalesLine.Type::Item,
          CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"), 0);  // Value 100 required for Prepayment %, 0 for Discount % and False for Prices Including VAT
        UpdateQuantityToShipOnSalesLine(SalesLine, SalesLine.Quantity / 2);  // Partial Quantity required for test
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Exercise, Verify and Tear Down: Post Sales Invoice and verify G/L entries. Update Full GST on Prepayment on General Ledger Setup.
        PostSalesInvoiceAndVerifyGLEntries(
          SalesHeader, GeneralPostingSetup, SalesLine.Amount / 2, SalesLine.Amount * SalesLine."VAT %" / 200, -SalesLine.Amount / 2,
          OldFullGSTOnPrepayment);  // Partial values required for test
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialReceiveAndInvoiceWithFullPurchPrepmtInv()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OldFullGSTOnPrepayment: Boolean;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] G/L entries after posting partial Purchase Invoice of full Prepayment Invoice.

        // [GIVEN] Update General Ledger Setup and Create General Posting Setup. Create and Post Prepayment Invoice for Purchase Order. Update Qty. to Receive on Purchase line and post Prepayment Invoice.
        OldFullGSTOnPrepayment := UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(true);  // True for Full GST On Prepayment
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateAndPostPrepaymentPurchaseInvoice(PurchaseLine, GeneralPostingSetup, 100, false);  // Value 100 required for Prepayment %, False for Prices Including VAT
        UpdateQuantityToReceiveOnPurchaseLine(PurchaseLine, PurchaseLine.Quantity / 2);  // Partial Quantity required for test
        PostPurchasePrepaymentInvoice(PurchaseHeader, PurchaseLine);

        // Exercise, Verify and Tear Down: Post Purchase Invoice and verify G/L entries. Update Full GST on Prepayment on General Ledger Setup.
        PostPurchaseInvoiceAndVerifyGLEntries(
          PurchaseHeader, GeneralPostingSetup, -PurchaseLine."Line Amount" / 2, PurchaseLine."Line Amount" / 2,
          -PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 200, OldFullGSTOnPrepayment);  // Partial values required for test
    end;

    local procedure CreateAndPostPrepaymentPurchaseInvoice(var PurchaseLine: Record "Purchase Line"; GeneralPostingSetup: Record "General Posting Setup"; PrepaymentPercent: Decimal; PricesIncludingVAT: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group"));
        PurchaseHeader.Validate("Prepayment %", PrepaymentPercent);
        PurchaseHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"),
          LibraryRandom.RandDecInRange(10, 20, 2)); // Use Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(50, 100, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
    end;

    local procedure CreateAndPostPrepaymentSalesInvoice(var SalesLine: Record "Sales Line"; GenBusPostingGroup: Code[20]; PrepaymentPercent: Decimal; PricesIncludingVAT: Boolean; Type: Enum "Sales Line Type"; No: Code[20]; LineDiscountPercent: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(GenBusPostingGroup));
        SalesHeader.Validate("Prepayment %", PrepaymentPercent);
        SalesHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, LibraryRandom.RandDecInRange(10, 20, 2));  // Use Random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(50, 100, 2));
        SalesLine.Validate("Prepayment VAT %", SalesLine."VAT %");
        SalesLine.Validate("Line Discount %", LineDiscountPercent);
        SalesLine.Modify(true);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
    end;

    local procedure CreateCustomer(GenBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralBusinessPostingGroup(DefVATBusinessPostingGroup: Code[20]): Code[20]
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        GenBusinessPostingGroup.Validate("Def. VAT Bus. Posting Group", DefVATBusinessPostingGroup);
        GenBusinessPostingGroup.Modify(true);
        exit(GenBusinessPostingGroup.Code);
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenBusPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GenBusPostingGroupCode := CreateGeneralBusinessPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        GenProdPostingGroupCode := CreateGeneralProductPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroupCode, GenProdPostingGroupCode);
        GeneralPostingSetup.Validate("Sales Account", CreateGLAccount(GenProdPostingGroupCode));
        GeneralPostingSetup.Validate("Sales Prepayments Account", CreateGLAccount(GenProdPostingGroupCode));
        GeneralPostingSetup.Validate("Purch. Account", CreateGLAccount(GenProdPostingGroupCode));
        GeneralPostingSetup.Validate("Purch. Prepayments Account", CreateGLAccount(GenProdPostingGroupCode));
        GeneralPostingSetup.Validate("COGS Account", CreateGLAccount(GenProdPostingGroupCode));
        GeneralPostingSetup.Validate("Direct Cost Applied Account", CreateGLAccount(GenProdPostingGroupCode));
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateGeneralProductPostingGroup(DefVATProdPostingGroup: Code[20]): Code[20]
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProdPostingGroup);
        GenProdPostingGroup.Validate("Def. VAT Prod. Posting Group", DefVATProdPostingGroup);
        GenProdPostingGroup.Modify(true);
        exit(GenProdPostingGroup.Code);
    end;

    local procedure CreateGLAccount(GenProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(GenProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateVendor(GenBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure GetPostedSalesPrepaymentCreditMemoNo(SellToCustomerNo: Code[20]): Code[20]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        SalesCrMemoHeader.FindFirst();
        exit(SalesCrMemoHeader."No.");
    end;

    local procedure PostPurchaseInvoiceAndVerifyGLEntries(PurchaseHeader: Record "Purchase Header"; GeneralPostingSetup: Record "General Posting Setup"; PrepaymentAmount: Decimal; Amount: Decimal; VATAmount: Decimal; OldFullGSTOnPrepayment: Boolean)
    var
        DocumentNo: Code[20];
    begin
        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice

        // [THEN] G/L entries of posted Purchase Invoice.
        VerifyGLEntriesOfPurchaseInvoice(GeneralPostingSetup, DocumentNo, PrepaymentAmount, Amount, VATAmount);

        // Tear Down.
        UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(OldFullGSTOnPrepayment);
    end;

    local procedure PostPurchasePrepaymentInvoice(var PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        UpdateVendorInvoiceNo(PurchaseHeader);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        UpdateVendorInvoiceNo(PurchaseHeader);
    end;

    local procedure PostSalesInvoiceAndVerifyGLEntries(SalesHeader: Record "Sales Header"; GeneralPostingSetup: Record "General Posting Setup"; PrepaymentAmount: Decimal; VATAmount: Decimal; Amount: Decimal; OldFullGSTOnPrepayment: Boolean)
    var
        DocumentNo: Code[20];
    begin
        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice

        // [THEN] G/L entries of posted Sales Invoice.
        VerifyGLEntriesOfSalesInvoice(DocumentNo, GeneralPostingSetup."Sales Prepayments Account", PrepaymentAmount, VATAmount);
        VerifyAmountOnGLEntry(DocumentNo, GeneralPostingSetup."Sales Account", Amount);

        // Tear Down.
        UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(OldFullGSTOnPrepayment);
    end;

    local procedure UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(NewFullGSTOnPrepayment: Boolean) OldFullGSTOnPrepayment: Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldFullGSTOnPrepayment := GeneralLedgerSetup."Full GST on Prepayment";
        GeneralLedgerSetup.Validate("Full GST on Prepayment", NewFullGSTOnPrepayment);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePrepmtPctOnSalesInvoiceAndPostPrepmt(var SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesHeader.Validate("Prepayment %", SalesHeader."Prepayment %" + LibraryRandom.RandDec(50, 2));  // Greater value required for Prepayment %
        SalesHeader.Modify(true);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
    end;

    local procedure UpdateQuantityToReceiveOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; QtyToReceive: Decimal)
    begin
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateQuantityToShipOnSalesLine(var SalesLine: Record "Sales Line"; QtyToShip: Decimal)
    begin
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
    end;

    local procedure UpdateVendorInvoiceNo(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure VerifyAmountOnGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindLast();
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntriesOfPurchaseInvoice(GeneralPostingSetup: Record "General Posting Setup"; DocumentNo: Code[20]; PrepaymentAmount: Decimal; Amount: Decimal; VATAmount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VerifyAmountOnGLEntry(DocumentNo, GeneralPostingSetup."Purch. Prepayments Account", PrepaymentAmount);
        VerifyAmountOnGLEntry(DocumentNo, GeneralPostingSetup."Purch. Account", Amount);
        VerifyAmountOnGLEntry(DocumentNo, VATPostingSetup."Purchase VAT Account", VATAmount);
    end;

    local procedure VerifyGLEntriesOfSalesInvoice(DocumentNo: Code[20]; PrepaymentAccountNo: Code[20]; PrepaymentAmount: Decimal; VATAmount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VerifyAmountOnGLEntry(DocumentNo, PrepaymentAccountNo, PrepaymentAmount);
        VerifyAmountOnGLEntry(DocumentNo, VATPostingSetup."Sales VAT Account", VATAmount);
    end;

    local procedure VerifyPrepmtAmtInclVATOnPurchaseLine(PurchaseLine: Record "Purchase Line"; PrepmtAmtInclAmt: Decimal)
    begin
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.TestField("Prepmt. Amt. Incl. VAT", PrepmtAmtInclAmt);
    end;
}

