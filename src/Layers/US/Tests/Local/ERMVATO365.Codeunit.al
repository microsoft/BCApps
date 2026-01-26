codeunit 144023 "ERM VAT O365"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT] [O365]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        AmountErr: Label '%1 must be %2 in %3.', Comment = '%1 = Amount FieldCaption, %2 = Amount Value, %3 = Record TableCaption';
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    [Scope('OnPrem')]
    procedure VATEntriesAfterPostSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Test to validate Amount in G/L entry and VAT Entry after post Sales Order with VAT.

        // Setup & Excercise: Create Sales Order with VAT and Post
        DocumentNo := VATEntriesAfterPostSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
            VATPostingSetup);

        // Verify: Amount in G/L Entry and VAT Entry.
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyVATAmountOnGLEntry(
          DocumentNo, SalesLine."Document Type"::Invoice, GeneralPostingSetup."Sales Account",
          SalesLine.Quantity * SalesLine."Unit Price");
        VerifyVATAmountOnGLEntry(
          DocumentNo, SalesLine."Document Type"::Invoice, VATPostingSetup."Sales VAT Unreal. Account",
          SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100);
        VerifyVATEntry(DocumentNo, SalesLine."Document Type"::Invoice, 0, 0);  // Verify 0 value in Base and Amount field of VAT Entry for Posted Sales Order.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntriesAfterPostSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Test to validate Amount in G/L Entry and VAT Entry after post Sales Credit Memo with VAT.

        // Setup & Exercise : Create Sales Credit Memo with VAT abd Post.
        DocumentNo := VATEntriesAfterPostSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo",
            VATPostingSetup);

        // Verify:  Amount in G/L Entry and VAT Entry.
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyVATAmountOnGLEntry(
          DocumentNo, SalesLine."Document Type"::"Credit Memo", GeneralPostingSetup."Sales Account",
          -SalesLine.Quantity * SalesLine."Unit Price");
        VerifyVATAmountOnGLEntry(
          DocumentNo, SalesLine."Document Type"::"Credit Memo", VATPostingSetup."Sales VAT Unreal. Account",
          -SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100);
        VerifyVATEntry(DocumentNo, SalesLine."Document Type"::"Credit Memo", 0, 0);  // Verify 0 value in Base and Amount field of VAT Entry for Posted Sales Credit Memo.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntriesAfterPostSalesApplication()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        SourceCodeSetup: Record "Source Code Setup";
        GLEntry: Record "G/L Entry";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        VATAmount: Decimal;
    begin
        // Test to Amount in G/L entry and VAT Entry after post Sales application.

        // Create and Post Sales Order and Sales Credit Memo.
        Initialize();

        SourceCodeSetup.Get();
        CreateVatPostingSetup(VATPostingSetup);

        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");

        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CustomerNo, ItemNo);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CreateSalesDocument(SalesHeader, SalesLine2, SalesHeader."Document Type"::"Credit Memo", CustomerNo, ItemNo);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Apply and post Sales application.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddSalesDocsCreate();
        ApplyAndPostCustomerEntry(CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;

        // Verify: Amount in G/L Entry and VAT Entry.
        VerifyVATAmountForPostApplication(
          VATPostingSetup."Sales VAT Unreal. Account", GLEntry."Gen. Posting Type"::Sale, VATAmount,
          SourceCodeSetup."Sales Entry Application");
        VerifyVATAmountForPostApplication(
          VATPostingSetup."Sales VAT Unreal. Account", GLEntry."Gen. Posting Type", -VATAmount, SourceCodeSetup."Sales Entry Application");
        VerifyVATEntryForPostApplication(SalesLine.Quantity * SalesLine."Unit Price", VATAmount);
    end;

    local procedure VATEntriesAfterPostSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; var VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    begin
        // Test to validate Amount in G/L entry and VAT Entry after post Sales Order with VAT.

        // Setup: Create Sales Order with VAT.
        Initialize();
        CreateVatPostingSetup(VATPostingSetup);
        CreateSalesDocument(
          SalesHeader, SalesLine, DocumentType,
          CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"),
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"));

        // Exercise: Post Sales order.
        LibraryLowerPermissions.SetSalesDocsPost();
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TheVATStatementTemplatesPageIsVisibleWithFoundationSetup()
    var
        VATStatementTemplates: TestPage "VAT Statement Templates";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Open page 318 "VAT Statement Templates" and check visibility of Name and Description controls

        // [GIVEN] Enabled foundation setup   
        LibraryApplicationArea.EnableFoundationSetup();

        // [WHEN] Page "VAT Statement Templates" is opened
        VATStatementTemplates.OpenEdit();

        // [THEN] The controls Name and Description are visible
        Assert.IsTrue(VATStatementTemplates.Name.Visible(), '');
        Assert.IsTrue(VATStatementTemplates.Description.Visible(), '');
        VATStatementTemplates.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TheVATStatementTemplateListPageIsVisibleWithFoundationSetup()
    var
        VATStatementTemplateList: TestPage "VAT Statement Template List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Open page 319 "VAT Statement Template List" and check visibility of Name and Description controls

        // [GIVEN] Enabled foundation setup   
        LibraryApplicationArea.EnableFoundationSetup();

        // [WHEN] Page "VAT Statement Template List" is opened
        VATStatementTemplateList.OpenEdit();

        // [THEN] The controls Name and Description are visible
        Assert.IsTrue(VATStatementTemplateList.Name.Visible(), '');
        Assert.IsTrue(VATStatementTemplateList.Description.Visible(), '');
        VATStatementTemplateList.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TheVATStatementTemplatesPageIsVisibleWithVATSetup()
    var
        VATStatementTemplates: TestPage "VAT Statement Templates";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Open page 318 "VAT Statement Templates" and check visibility of Name and Description controls

        // [GIVEN] Enabled VAT setup   
        LibraryApplicationArea.EnableVATSetup();

        // [WHEN] Page "VAT Statement Templates" is opened
        VATStatementTemplates.OpenEdit();

        // [THEN] The controls Name and Description are visible
        Assert.IsTrue(VATStatementTemplates.Name.Visible(), '');
        Assert.IsTrue(VATStatementTemplates.Description.Visible(), '');
        VATStatementTemplates.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TheVATStatementTemplateListPageIsVisibleWithVATSetup()
    var
        VATStatementTemplateList: TestPage "VAT Statement Template List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Open page 319 "VAT Statement Template List" and check visibility of Name and Description controls

        // [GIVEN] Enabled VAT setup   
        LibraryApplicationArea.EnableVATSetup();

        // [WHEN] Page "VAT Statement Template List" is opened
        VATStatementTemplateList.OpenEdit();

        // [THEN] The controls Name and Description are visible
        Assert.IsTrue(VATStatementTemplateList.Name.Visible(), '');
        Assert.IsTrue(VATStatementTemplateList.Description.Visible(), '');
        VATStatementTemplateList.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    local procedure Initialize()
    begin
        LibraryApplicationArea.EnableFoundationSetup();
        UpdateGeneralLedgerSetup(true);
    end;

    local procedure ApplyCustomerEntry(var ApplyCustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLRegister: Record "G/L Register";
    begin
        LibraryERM.FindCustomerLedgerEntry(ApplyCustLedgerEntry, DocumentType, DocumentNo);
        ApplyCustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(ApplyCustLedgerEntry, ApplyCustLedgerEntry."Remaining Amount");
        GLRegister.FindLast();
        CustLedgerEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        CustLedgerEntry.SetRange("Applying Entry", false);
        CustLedgerEntry.FindFirst();
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry)
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        ApplyCustomerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
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

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(20, 2));  // Takes Random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Takes Random value for Unit Price.
        SalesLine.Modify(true);
    end;

    local procedure CreateVatPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        FindGLAccount(GLAccount);
        LibraryERM.CreateVATPostingSetupWithSalesAndPurchVATAccounts(VATPostingSetup, GLAccount);
    end;

    local procedure FindGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount.SetRange("Direct Posting", true);
        GLAccount.SetRange("Reconciliation Account", true);
        GLAccount.FindFirst();
    end;

    local procedure UpdateGeneralLedgerSetup(NewUnrealizedVAT: Boolean) OldUnrealizedVAT: Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldUnrealizedVAT := GeneralLedgerSetup."Unrealized VAT";
        GeneralLedgerSetup."Unrealized VAT" := NewUnrealizedVAT;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type"; Amount: Decimal; VATAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          VATEntry.Base, Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Base), Amount, VATEntry.TableCaption()));
        Assert.AreNearlyEqual(
          VATEntry.Amount, VATAmount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Amount), VATAmount, VATEntry.TableCaption()));
    end;

    local procedure VerifyVATAmountForPostApplication(GLAcountNo: Code[20]; GenPostingType: Enum "General Posting Type"; Amount: Decimal; SourceCode: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAcountNo);
        GLEntry.SetRange("Gen. Posting Type", GenPostingType);
        GLEntry.SetRange("Source Code", SourceCode);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          GLEntry.Amount, Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyVATEntryForPostApplication(Amount: Decimal; VATAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
    begin
        GLRegister.FindLast();
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        VATEntry.FindSet();
        Assert.AreNearlyEqual(
          VATEntry.Base, Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Base), Amount, VATEntry.TableCaption()));
        Assert.AreNearlyEqual(
          VATEntry.Amount, VATAmount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Amount), VATAmount, VATEntry.TableCaption()));
        VATEntry.Next();
        Assert.AreNearlyEqual(
          VATEntry.Base, -Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Base), -Amount, VATEntry.TableCaption()));
        Assert.AreNearlyEqual(
          VATEntry.Amount, -VATAmount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Amount), -VATAmount, VATEntry.TableCaption()));
    end;

    local procedure VerifyVATAmountOnGLEntry(DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type"; GLAcountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAcountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          GLEntry.Amount, -Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), -Amount, GLEntry.TableCaption()));
    end;
}

