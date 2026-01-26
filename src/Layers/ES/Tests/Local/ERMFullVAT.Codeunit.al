codeunit 144051 "ERM Full VAT"
{
    // 1.  Test to verify error when create Sales Invoice with invalid G/L Account No.
    // 2.  Test to verify error when create Sales Credit Memo with invalid G/L Account No.
    // 3.  Test to verify G/L Entry after post Sales Invoice with Full VAT and valid G/L Account No.
    // 4.  Test to verify G/L Entry after post Sales Credit Memo with Full VAT and valid G/L Account No.
    // 5.  Test to verify Amount after post Sales Order without Currency Code and with VAT Rounding Type as Up.
    // 6.  Test to verify Amount after post Sales Order with Currency Code and VAT Rounding Type as Up.
    // 7.  Test to verify Amount after post Sales Order without Currency Code and with VAT Rounding Type as Nearest.
    // 8.  Test to verify Amount after post Sales Order with Currency Code and VAT Rounding Type as Nearest.
    // 9.  Test to verify Amount after post Sales Order without Currency Code and with VAT Rounding Type as Down.
    // 10. Test to verify Amount after post Sales Order with Currency Code and VAT Rounding Type as Down.
    // 11. Test to verify Amount after post Purchase Order without Currency Code and with VAT Rounding Type as Up.
    // 12. Test to verify Amount after post Purchase Order with Currency Code and VAT Rounding Type as Up.
    // 13. Test to verify Amount after post Purchase Order without Currency Code and with VAT Rounding Type as Nearest.
    // 14. Test to verify Amount after post Purchase Order with Currency Code and VAT Rounding Type as Nearest.
    // 15. Test to verify Amount after post Purchase Order without Currency Code and with VAT Rounding Type as Down.
    // 16. Test to verify Amount after post Purchase Order with Currency Code and VAT Rounding Type as Down.
    // 
    // Covers Test Cases for WI - 351285
    // ---------------------------------------------------------
    // Test Function Name                                 TFS ID
    // ---------------------------------------------------------
    // SalesInvoiceWithInvalidGLAccountNoError            177686
    // SalesCreditMemoWithInvalidGLAccountNoError         177684
    // PostedSalesInvoiceWithFullVAT                      177685
    // PostedSalesCreditMemoWithFullVAT                   177683
    // 
    // Covers Test Cases for WI - 351279
    // ----------------------------------------------------------------
    // Test Function Name                                        TFS ID
    // ----------------------------------------------------------------
    // PostedSalesOrderWithVatRoundingTypeAsUp                   177692
    // PostedSalesOrderWithCurrencyAndVatRndgTypeAsUp            177693
    // PostedSalesOrderWithVatRoundingTypeAsNearest              177701
    // PostedSalesOrderWithCurrAndVatRndgTypeAsNearest           177700
    // PostedSalesOrderWithVatRoundingTypeAsDown                 177696
    // PostedSalesOrderWithCurrencyAndVatRndgTypeAsDown          177697
    // PostedPurchaseOrderWithVatRoundingTypeAsUp                177690
    // PostedPurchaseOrderWithCurrAndVatRndgTypeAsUp             177691
    // PostedPurchaseOrderWithVatRoundingTypeAsNearest           177699
    // PostedPurchOrderWithCurrAndVatRndgTypeAsNearest           177698
    // PostedPurchaseOrderWithVatRoundingTypeAsDown              177694
    // PostedPurchaseOrderWithCurrAndVatRndgTypeAsDown           177695

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
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        EqualToTxt: Label '=';
        GreaterThanTxt: Label '>';
        LessThanTxt: Label '<';
        ValueMustBeEqualMsg: Label 'Value must be equal.';
        VATEntryNotFoundErr: Label 'VAT Entry with Generated Autodocument = %1 not found';
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithInvalidGLAccountNoError()
    var
        SalesLine: Record "Sales Line";
    begin
        // Test to verify error when create Sales Invoice with invalid G/L Account No.
        SalesDocumentWithInvalidGLAccountNoError(SalesLine."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithInvalidGLAccountNoError()
    var
        SalesLine: Record "Sales Line";
    begin
        // Test to verify error when create Sales Credit Memo with invalid G/L Account No.
        SalesDocumentWithInvalidGLAccountNoError(SalesLine."Document Type"::"Credit Memo");
    end;

    local procedure SalesDocumentWithInvalidGLAccountNoError(DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccountNo: Code[20];
    begin
        // Setup: Create VAT Posting Setup and G/L Account.
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT");
        GLAccountNo := CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group");

        // Exercise.
        asserterror
          CreateSalesDocument(
            SalesLine, DocumentType, SalesLine.Type::"G/L Account", '', VATPostingSetup."VAT Bus. Posting Group", GLAccountNo);  // Currency Code as blank.

        // Verify.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("No."), VATPostingSetup."Sales VAT Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceWithFullVAT()
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Test to verify G/L Entry after post Sales Invoice with Full VAT and valid G/L Account No.

        // Setup: Create VAT Posting Setup and Sales Invoice.
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT");
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Invoice, SalesLine.Type::"G/L Account", '', VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."Sales VAT Account");  // Currency Code as blank.

        // Exercise and Verify.
        PostSalesDocumentAndVerifyGLEntry(SalesLine, -SalesLine."Amount Including VAT", SalesLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesCreditMemoWithFullVAT()
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Test to verify G/L Entry after post Sales Credit Memo with Full VAT and valid G/L Account No.

        // Setup: Create VAT Posting Setup and Sales Credit Memo.
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT");
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::"Credit Memo", SalesLine.Type::"G/L Account", '', VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."Sales VAT Account");  // Currency Code as blank.

        // Exercise and Verify.
        PostSalesDocumentAndVerifyGLEntry(SalesLine, SalesLine."Amount Including VAT", -SalesLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesOrderWithVatRoundingTypeAsUp()
    var
        Currency: Record Currency;
    begin
        // Test to verify Amount after post Sales Order without Currency Code and with VAT Rounding Type as Up.
        PostedSalesOrderWithVATRoundingType(Currency."VAT Rounding Type"::Up, '', GreaterThanTxt);  // Currency Code as blank.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesOrderWithCurrencyAndVatRndgTypeAsUp()
    var
        Currency: Record Currency;
    begin
        // Test to verify Amount after post Sales Order with Currency Code and VAT Rounding Type as Up.
        PostedSalesOrderWithVATRoundingType(
          Currency."VAT Rounding Type"::Up, CreateCurrencyWithExchangeRate(Currency."VAT Rounding Type"::Up), GreaterThanTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesOrderWithVatRoundingTypeAsNearest()
    var
        Currency: Record Currency;
    begin
        // Test to verify Amount after post Sales Order without Currency Code and with VAT Rounding Type as Nearest.
        PostedSalesOrderWithVATRoundingType(Currency."VAT Rounding Type"::Nearest, '', EqualToTxt);  // Currency Code as blank.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesOrderWithCurrAndVatRndgTypeAsNearest()
    var
        Currency: Record Currency;
    begin
        // Test to verify Amount after post Sales Order with Currency Code and VAT Rounding Type as Nearest.
        PostedSalesOrderWithVATRoundingType(
          Currency."VAT Rounding Type"::Nearest, CreateCurrencyWithExchangeRate(Currency."VAT Rounding Type"::Nearest), EqualToTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesOrderWithVatRoundingTypeAsDown()
    var
        Currency: Record Currency;
    begin
        // Test to verify Amount after post Sales Order without Currency Code and with VAT Rounding Type as Down.
        PostedSalesOrderWithVATRoundingType(Currency."VAT Rounding Type"::Down, '', LessThanTxt);  // Currency Code as blank.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesOrderWithCurrencyAndVatRndgTypeAsDown()
    var
        Currency: Record Currency;
    begin
        // Test to verify Amount after post Sales Order with Currency Code and VAT Rounding Type as Down.
        PostedSalesOrderWithVATRoundingType(
          Currency."VAT Rounding Type"::Down, CreateCurrencyWithExchangeRate(Currency."VAT Rounding Type"::Down), LessThanTxt);
    end;

    local procedure PostedSalesOrderWithVATRoundingType(VATRoundingType: Option; CurrencyCode: Code[10]; Direction: Text)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Setup: Create VAT Posting Setup, create Sales order and update VAT Product Posting Group on G/L Account.
        GeneralLedgerSetup.Get();
        UpdateVATRoundingTypeOnGeneralLedgerSetup(VATRoundingType);
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, SalesLine.Type::Item, CurrencyCode, VATPostingSetup."VAT Bus. Posting Group",
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        FindCustomerPostingGroup(CustomerPostingGroup, SalesLine."Sell-to Customer No.");
        UpdateVATProdPostingGroupOnGLAccount(CustomerPostingGroup."Invoice Rounding Account", VATPostingSetup."VAT Prod. Posting Group");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify.
        VerifyPostedSalesInvoice(
          DocumentNo, SalesLine.Amount, Round(
            SalesLine.Amount + SalesLine.Amount * VATPostingSetup."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision(), Direction));

        // Tear Down: Set Default Value in General Ledger Setup.
        UpdateVATRoundingTypeOnGeneralLedgerSetup(GeneralLedgerSetup."VAT Rounding Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseOrderWithVatRoundingTypeAsUp()
    var
        Currency: Record Currency;
    begin
        // Test to verify Amount after post Purchase Order without Currency Code and with VAT Rounding Type as Up.
        PostedPurchaseOrderWithVATRoundingType(Currency."VAT Rounding Type"::Up, '', GreaterThanTxt);  // Currency Code as blank.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseOrderWithCurrAndVatRndgTypeAsUp()
    var
        Currency: Record Currency;
    begin
        // Test to verify Amount after post Purchase Order with Currency Code and VAT Rounding Type as Up.
        PostedPurchaseOrderWithVATRoundingType(
          Currency."VAT Rounding Type"::Up, CreateCurrencyWithExchangeRate(Currency."VAT Rounding Type"::Up), GreaterThanTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseOrderWithVatRoundingTypeAsNearest()
    var
        Currency: Record Currency;
    begin
        // Test to verify Amount after post Purchase Order without Currency Code and with VAT Rounding Type as Nearest.
        PostedPurchaseOrderWithVATRoundingType(Currency."VAT Rounding Type"::Nearest, '', EqualToTxt);  // Currency Code as blank.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchOrderWithCurrAndVatRndgTypeAsNearest()
    var
        Currency: Record Currency;
    begin
        // Test to verify Amount after post Purchase Order with Currency Code and VAT Rounding Type as Nearest.
        PostedPurchaseOrderWithVATRoundingType(
          Currency."VAT Rounding Type"::Nearest, CreateCurrencyWithExchangeRate(Currency."VAT Rounding Type"::Nearest), EqualToTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseOrderWithVatRoundingTypeAsDown()
    var
        Currency: Record Currency;
    begin
        // Test to verify Amount Including VAT after post Purchase Order without Currency Code and with VAT Rounding Type as Down.
        PostedPurchaseOrderWithVATRoundingType(Currency."VAT Rounding Type"::Down, '', LessThanTxt);  // Currency Code as blank.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseOrderWithCurrAndVatRndgTypeAsDown()
    var
        Currency: Record Currency;
    begin
        // Test to verify Amount Including VAT after post Purchase Order with Currency Code and VAT Rounding Type as Down.
        PostedPurchaseOrderWithVATRoundingType(
          Currency."VAT Rounding Type"::Down, CreateCurrencyWithExchangeRate(Currency."VAT Rounding Type"::Down), LessThanTxt);
    end;

    local procedure PostedPurchaseOrderWithVATRoundingType(VATRoundingType: Option; CurrencyCode: Code[10]; Direction: Text)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        DocumentNo: Code[20];
    begin
        // Setup: Create VAT Posting Setup, create Purchase order and update VAT Product Posting Group on G/L Account.
        GeneralLedgerSetup.Get();
        UpdateVATRoundingTypeOnGeneralLedgerSetup(VATRoundingType);
        CreatePurchaseOrder(PurchaseLine, CurrencyCode);
        Vendor.Get(PurchaseLine."Buy-from Vendor No.");
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        UpdateVATProdPostingGroupOnGLAccount(VendorPostingGroup."Invoice Rounding Account", PurchaseLine."VAT Prod. Posting Group");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // Verify.
        VerifyPostedPurchaseInvoice(
          DocumentNo, PurchaseLine.Amount, Round(
            PurchaseLine.Amount + PurchaseLine.Amount * PurchaseLine."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision(), Direction));

        // Tear Down: Set Default Value in General Ledger Setup.
        UpdateVATRoundingTypeOnGeneralLedgerSetup(GeneralLedgerSetup."VAT Rounding Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseChargeVATGeneratedAutodocument()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DocumentNo: Code[20];
    begin
        // Test to verify VAT Entry with VAT Calc. Type = Reverse Charge VAT has Generated Autodocument = TRUE
        // otherwise Generated Autodocument = FALSE
        // Setup: Create 2 VAT Posting Setup, for VAT Calc. Types - Normal VAT(Unrealized) and Reverse Charge VAT
        GeneralLedgerSetup.Get();
        SetUnrealizedVATGLSetup(true);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        CreateVATPostingSetupFromVATBusPostGroup(
          VATBusinessPostingGroup.Code, VATPostingSetup1,
          VATPostingSetup1."VAT Calculation Type"::"Reverse Charge VAT");
        CreateVATPostingSetupFromVATBusPostGroup(
          VATBusinessPostingGroup.Code, VATPostingSetup2,
          VATPostingSetup2."VAT Calculation Type"::"Normal VAT");

        // Post Purchase Invoice with 2 lines and different VAT Prod. Posting Groups
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          CreateVendor('', VATPostingSetup1."VAT Bus. Posting Group"));
        CreatePurchLine(
          PurchaseHeader, PurchaseLine, PurchaseLine.Type::"G/L Account",
          CreateGLAccount(VATPostingSetup1."VAT Prod. Posting Group"));
        CreatePurchLine(
          PurchaseHeader, PurchaseLine, PurchaseLine.Type::"G/L Account",
          CreateGLAccount(VATPostingSetup2."VAT Prod. Posting Group"));

        PurchInvHeader.Get(
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // Verify Reverse Charge VAT VAT Entry has Generated Autodocument = TRUE,
        // Normal VAT (unrealized) has Generated Autodocument = FALSE
        VerifyVATEntryGeneratedAutodocument(
          PurchInvHeader."No.", VATPostingSetup1."VAT Prod. Posting Group", true);
        VerifyVATEntryGeneratedAutodocument(
          PurchInvHeader."No.", VATPostingSetup2."VAT Prod. Posting Group", false);

        // Post payment applied to Posted Vnvoice
        DocumentNo := CreatePostPaymentApplyPurchDoc(PurchInvHeader);

        // Verify Payment generated VAT Entry with Generated Autodocument = FALSE
        VerifyVATEntryGeneratedAutodocument(
          DocumentNo, VATPostingSetup2."VAT Prod. Posting Group", false);

        VATPostingSetup1.Delete();
        VATPostingSetup2.Delete();
        SetUnrealizedVATGLSetup(GeneralLedgerSetup."Unrealized VAT");
    end;

    local procedure CreateCurrencyWithExchangeRate(VATRoundingType: Option): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("VAT Rounding Type", VATRoundingType);
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(CurrencyCode: Code[10]; VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGLAccount(VATProdPostingGroup: Code[20]): Code[20]
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
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

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; CurrencyCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(CurrencyCode, VATPostingSetup."VAT Bus. Posting Group"));
        CreatePurchLine(
          PurchaseHeader, PurchaseLine,
          PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
    end;

    local procedure CreatePurchLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; No: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; CurrencyCode: Code[10]; VATBusPostingGroup: Code[20]; No: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(CurrencyCode, VATBusPostingGroup));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Take random Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.Validate("Sales VAT Account", CreateGLAccount(VATProductPostingGroup.Code));
        VATPostingSetup.Validate("Purchase VAT Account", CreateGLAccount(VATProductPostingGroup.Code));
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDec(10, 2));
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVATPostingSetupFromVATBusPostGroup(VATBusinessPostingGroupCode: Code[20]; var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATCalculationType);
        if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Normal VAT" then begin
            VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
            VATPostingSetup.Validate("Purch. VAT Unreal. Account", CreateGLAccount(VATProductPostingGroup.Code));
        end;
        VATPostingSetup.Validate("Purchase VAT Account", CreateGLAccount(VATProductPostingGroup.Code));
        VATPostingSetup.Validate("VAT Identifier", LibraryUtility.GenerateRandomCode20(VATPostingSetup.FieldNo("VAT Identifier"), DATABASE::"VAT Posting Setup"));
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDec(10, 2));
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", CreateGLAccount(VATProductPostingGroup.Code));
        VATPostingSetup.Validate("Reverse Chrg. VAT Unreal. Acc.", CreateGLAccount(VATProductPostingGroup.Code));
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVendor(CurrencyCode: Code[10]; VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePostPaymentApplyPurchDoc(PurchInvHeader: Record "Purch. Inv. Header"): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        PurchInvHeader.CalcFields("Amount Including VAT");
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJnlLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJnlLine."Document Type"::Payment,
            GenJnlLine."Account Type"::Vendor, PurchInvHeader."Buy-from Vendor No.",
            GenJnlLine."Bal. Account Type"::"G/L Account", GLAccount."No.",
            PurchInvHeader."Amount Including VAT");
        GenJnlLine.Validate("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::Invoice);
        GenJnlLine.Validate("Applies-to Doc. No.", PurchInvHeader."No.");
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(GenJnlLine."Document No.");
    end;

    local procedure FindCustomerPostingGroup(var CustomerPostingGroup: Record "Customer Posting Group"; No: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(No);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
    end;

    local procedure PostSalesDocumentAndVerifyGLEntry(SalesLine: Record "Sales Line"; Amount: Decimal; Amount2: Decimal)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        FindCustomerPostingGroup(CustomerPostingGroup, SalesLine."Sell-to Customer No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify.
        VerifyGLEntry(DocumentNo, SalesLine."No.", GLEntry."Gen. Posting Type"::Sale, 0);  // 0 for Amount.
        VerifyGLEntry(DocumentNo, SalesLine."No.", GLEntry."Gen. Posting Type", Amount);
        VerifyGLEntry(DocumentNo, CustomerPostingGroup."Receivables Account", GLEntry."Gen. Posting Type", Amount2);
    end;

    local procedure UpdateVATProdPostingGroupOnGLAccount(No: Code[20]; VATProdPostingGroup: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(No);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
    end;

    local procedure UpdateVATRoundingTypeOnGeneralLedgerSetup(VATRoundingType: Option)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Rounding Type", VATRoundingType);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure SetUnrealizedVATGLSetup(UnrealizedVAT: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; GenPostingType: Enum "General Posting Type"; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Gen. Posting Type", GenPostingType);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
    end;

    local procedure VerifyPostedPurchaseInvoice(DocumentNo: Code[20]; Amount: Decimal; AmountIncludingVAT: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField(Amount, Amount);
        PurchInvLine.TestField("Amount Including VAT", AmountIncludingVAT);
    end;

    local procedure VerifyPostedSalesInvoice(DocumentNo: Code[20]; Amount: Decimal; AmountIncludingVAT: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField(Amount, Amount);
        SalesInvoiceLine.TestField("Amount Including VAT", AmountIncludingVAT);
    end;

    local procedure VerifyVATEntryGeneratedAutodocument(DocumentNo: Code[20]; VATProdPostingGroupCode: Code[20]; GeneratedAutoDocument: Boolean)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroupCode);
        VATEntry.SetRange("Generated Autodocument", GeneratedAutoDocument);
        Assert.IsFalse(VATEntry.IsEmpty, StrSubstNo(VATEntryNotFoundErr, GeneratedAutoDocument));
    end;
}

