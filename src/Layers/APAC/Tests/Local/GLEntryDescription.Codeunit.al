codeunit 141042 "G/L Entry Description"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Entry] [Description]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceMultipleLinesWithDescription()
    var
        DocumentNo: Code[20];
        Description: Text[50];
        Description2: Text[50];
    begin
        // [SCENARIO] after Posting Sales Invoice, Sales Line Description correctly populates on G/L Entry.

        // Setup.
        Description := LibraryUtility.GenerateGUID();
        Description2 := LibraryUtility.GenerateGUID();

        // [WHEN] Create and Post Sales Invoice with Multiple Line.
        DocumentNo := CreateAndPostSalesInvoiceWithMultipleLine(Description, Description2);

        // [THEN] Verify Posted Sales Invoice with multiple lines for the same G/L Account With Different Description, In G/L Entry - Description must be same as Description entered in the document.
        VerifyDescriptionOnMultipleGLEntry(DocumentNo, Description, Description2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceMultipleLinesWithDescription()
    var
        DocumentNo: Code[20];
        Description: Text[50];
        Description2: Text[50];
    begin
        // [SCENARIO] after Posting Purchase Invoice, Purchase Line Description correctly populates on G/L Entry.

        // Setup.
        Description := LibraryUtility.GenerateGUID();
        Description2 := LibraryUtility.GenerateGUID();

        // [WHEN] Create and Post Purchase Invoice with Multiple Line.
        DocumentNo := CreateAndPostPurchaseInvoiceWithMultipleLine(Description, Description2);

        // [THEN] Verify Posted Purchase Invoice with multiple lines for the same G/L Account With Different Description, In G/L Entry - Description must be same as Description entered in the document.
        VerifyDescriptionOnMultipleGLEntry(DocumentNo, Description, Description2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesJournalMultipleLinesWithDescription()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO] after Posting Sales Journal, Gen. Journal Line Description correctly populates on G/L Entry.

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        GeneralJournalLineWithAccountTypeDescription(
          GenJournalLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(10, 2));  // Random as Unit Price.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseJournalMultipleLinesWithDescription()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // [SCENARIO] after Posting Purchase Journal, Gen. Journal Line Description correctly populates on G/L Entry.

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        GeneralJournalLineWithAccountTypeDescription(
          GenJournalLine."Account Type"::Vendor, Vendor."No.", -LibraryRandom.RandDec(10, 2));  // Random as Direct Unit Cost.
    end;

    local procedure GeneralJournalLineWithAccountTypeDescription(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        Description: Text[50];
        Description2: Text[50];
        DocumentNo: Code[20];
    begin
        Description := LibraryUtility.GenerateGUID();
        Description2 := LibraryUtility.GenerateGUID();

        // [WHEN] Create and Post Multiple General Journal Line.
        DocumentNo := CreateAndPostGenJournalWithMultipleLine(AccountType, AccountNo, Amount, Description, Description2);

        // [THEN] Verify Posted General Journal Line with multiple lines for the same G/L Account With Different Description, In G/L Entry - Description must be same as Description entered in the document.
        VerifyDescriptionOnMultipleGLEntry(DocumentNo, Description, Description2);
    end;

    local procedure CreateAndPostGenJournalWithMultipleLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; Description: Text[50]; Description2: Text[50]) DocumentNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CreateGeneralJnlLine(GenJournalLine, GenJournalBatch, AccountType, AccountNo, Amount, '');  // Blank as Description.
        CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", Amount, Description);
        CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", Amount, Description2);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostSalesInvoiceWithMultipleLine(Description: Text[50]; Description2: Text[50]): Code[20]
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
    begin
        GLAccount.Get(CreateGLAccount());
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(GLAccount."VAT Bus. Posting Group"));
        CreateSalesLine(SalesHeader, GLAccount."No.", Description);
        CreateSalesLine(SalesHeader, GLAccount."No.", Description2);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseInvoiceWithMultipleLine(Description: Text[50]; Description2: Text[50]): Code[20]
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
    begin
        GLAccount.Get(CreateGLAccount());
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(GLAccount."VAT Bus. Posting Group"));
        CreatePurchaseLine(PurchaseHeader, GLAccount."No.", Description);
        CreatePurchaseLine(PurchaseHeader, GLAccount."No.", Description2);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
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

    local procedure CreateGeneralJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; GLAccountNo: Code[20]; Amount: Decimal; Description: Text[50])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          AccountType, GLAccountNo, Amount);
        GenJournalLine.Validate(Description, Description);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; Description: Text[50])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandDec(10, 2));  // Random as Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate(Description, Description);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; GLAccountNo: Code[20]; Description: Text[50])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandDec(10, 2));  // Random as Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate(Description, Description);
        SalesLine.Modify(true);
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

    local procedure VerifyDescriptionOnGLEntry(DocumentNo: Code[20]; Description: Text[50])
    var
        GLEntry: Record "G/L Entry";
    begin
        // Verify G/L Entry - Description must be same as Description entered in the Posted Document.
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::"G/L Account");
        GLEntry.SetRange(Description, Description);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount);
    end;

    local procedure VerifyDescriptionOnMultipleGLEntry(DocumentNo: Code[20]; Description: Text[50]; Description2: Text[50])
    begin
        VerifyDescriptionOnGLEntry(DocumentNo, Description);
        VerifyDescriptionOnGLEntry(DocumentNo, Description2);
    end;
}

