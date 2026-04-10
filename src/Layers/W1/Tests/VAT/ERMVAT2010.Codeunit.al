codeunit 134030 "ERM VAT 2010"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT] [EU Service]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EUService: Boolean;
    begin
        // [SCENARIO] Create an Invoice General Journal Line for Customer, Post and Validate VAT Ledger Entry
        // --------------------------------------------------------------------------------------------------------------------------

        // [GIVEN] Setup: Setup Demonstration Data
        Initialize();

        // [WHEN] Create and Post an Invoice General Journal Line for a Customer with Random Amount.
        EUService := CreatePostGeneralJournal(GenJournalLine, GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
            LibraryRandom.RandInt(10000), GenJournalLine."Bal. Gen. Posting Type"::Sale, true);

        // [THEN] Verify that VAT Entry has EU Service = Yes. Rollback VAT Posting Setup.
        ValidateVATEntry(GenJournalLine."Document No.", EUService);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EUService: Boolean;
    begin
        // [SCENARIO] Create an Credit Memo General Journal Line for Customer, Post and Validate VAT Ledger Entry
        // --------------------------------------------------------------------------------------------------------------------------

        // [GIVEN] Setup: Setup Demonstration Data and VAT Posting Setup
        Initialize();

        // [WHEN] Create and Post a Credit Memo General Journal Line for a Customer with Random Amount.
        EUService := CreatePostGeneralJournal(GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
            GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
            -LibraryRandom.RandInt(10000), GenJournalLine."Bal. Gen. Posting Type"::Sale, true);

        // [THEN] Verify that VAT Entry has EU Service = Yes. Rollback VAT Posting Setup.
        ValidateVATEntry(GenJournalLine."Document No.", EUService);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EUService: Boolean;
    begin
        // [SCENARIO] Create an Invoice General Journal Line for Vendor, Post and Validate VAT Ledger Entry
        // --------------------------------------------------------------------------------------------------------------------------

        // [GIVEN] Setup: Setup Demonstration Data and VAT Posting Setup
        Initialize();

        // [WHEN] Create an Invoice General Journal Line for a Vendor with Random Amount.
        EUService := CreatePostGeneralJournal(GenJournalLine, GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
            -LibraryRandom.RandInt(10000), GenJournalLine."Bal. Gen. Posting Type"::Purchase, true);

        // [THEN] Verify that VAT Entry has EU Service = Yes. Rollback VAT Posting Setup.
        ValidateVATEntry(GenJournalLine."Document No.", EUService);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EUService: Boolean;
    begin
        // [SCENARIO] Create an Credit Memo General Journal Line for Vendor, Post and Validate VAT Ledger Entry
        // --------------------------------------------------------------------------------------------------------------------------

        // [GIVEN] Setup: Setup Demonstration Data and VAT Posting Setup
        Initialize();

        // [WHEN] Create and Post a Credit Memo General Journal Line for a Vendor with Random Amount.
        EUService := CreatePostGeneralJournal(GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
            GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
            LibraryRandom.RandInt(10000), GenJournalLine."Bal. Gen. Posting Type"::Purchase, true);

        // [THEN] Verify that VAT Entry has EU Service = Yes. Rollback VAT Posting Setup.
        ValidateVATEntry(GenJournalLine."Document No.", EUService);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGLInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EUService: Boolean;
    begin
        // [SCENARIO] Create an Invoice General Journal Line for G/L Account, Post and Validate VAT Ledger Entry
        // --------------------------------------------------------------------------------------------------------------------------

        // [GIVEN] Setup: Setup Demonstration Data and VAT Posting Setup
        Initialize();

        // [WHEN] Create and Post an Invoice General Journal Line for a Vendor with Random Amount.
        EUService := CreatePostGeneralJournal(GenJournalLine, GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(),
            LibraryRandom.RandInt(10000), GenJournalLine."Bal. Gen. Posting Type"::Sale, true);

        // [THEN] Verify that VAT Entry has EU Service = Yes. Rollback VAT Posting Setup.
        ValidateVATEntry(GenJournalLine."Document No.", EUService);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGLCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EUService: Boolean;
    begin
        // [SCENARIO] Create an Credit Memo General Journal Line for G/L Account, Post and Validate VAT Ledger Entry
        // --------------------------------------------------------------------------------------------------------------------------

        // [GIVEN] Setup: Setup Demonstration Data and VAT Posting Setup
        Initialize();

        // [WHEN] Create an Invoice General Journal Line for a Vendor with Random Amount.
        EUService := CreatePostGeneralJournal(GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(),
            LibraryRandom.RandInt(10000), GenJournalLine."Bal. Gen. Posting Type"::Purchase, true);

        // [THEN] Verify that VAT Entry has EU Service = Yes. Rollback VAT Posting Setup.
        ValidateVATEntry(GenJournalLine."Document No.", EUService);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderEUService()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        VATPostingSetup: Record "VAT Posting Setup";
        EUService: Boolean;
    begin
        // [SCENARIO 145131] Check that value of EU Service Field is TRUE after Posting Service Order.

        // [GIVEN] Setup: Update VAT Posting Setup, Create Service Order, Service Item, Service Item Line for the Customer.
        Initialize();
        EUService := SetupAndCreateServiceHeader(ServiceHeader, VATPostingSetup, ServiceHeader."Document Type"::Order);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [WHEN] Post Service Order
        // [THEN] Verify VAT Entries. Roll back VAT Posting Setup.
        PostAndVerifyVATEntry(ServiceHeader, VATPostingSetup, EUService, ServiceItemLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoEUService()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceHeader: Record "Service Header";
        EUService: Boolean;
    begin
        // [SCENARIO 145132] Check that value of EU Service Field is TRUE after Posting Service Credit Memo.

        // [GIVEN] Setup:  Update VAT Posting Setup, Create Service Credit Memo.
        Initialize();
        EUService := SetupAndCreateServiceHeader(ServiceHeader, VATPostingSetup, ServiceHeader."Document Type"::"Credit Memo");

        // [WHEN] Post Service Credit Memo
        // [THEN] Verify VAT Entries. Roll back VAT Posting Setup.
        PostAndVerifyVATEntry(ServiceHeader, VATPostingSetup, EUService, 0);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM VAT 2010");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM VAT 2010");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM VAT 2010");
    end;

    local procedure CreateAndUpdateServiceLine(var ServiceHeader: Record "Service Header"; Type: Enum "Service Line Type"; ServiceItemLineNo: Integer; No: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, No);
        UpdateServiceLine(ServiceLine, ServiceItemLineNo);
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        CountryRegion: Record "Country/Region";
        Customer: Record Customer;
    begin
        CountryRegion.SetFilter("Intrastat Code", '<>''''');
        CountryRegion.FindFirst();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralJournal(var GenJournalLine: Record "Gen. Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; BalGenPostingType: Enum "General Posting Type"; EUService: Boolean) EUServiceOld: Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, JournalTemplateName, JournalBatchName, DocumentType, AccountType, AccountNo, Amount);

        // Setup EU Service VAT Posting Setup
        EUServiceOld := UpdateVATPostSetup(VATPostingSetup, EUService);

        // Set's the VAT Bus/Prod Posting Group from the EU Service VAT Posting Setup
        GenJournalLine.Validate("Bal. VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("Bal. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Validate("Bal. Gen. Posting Type", BalGenPostingType);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
        TariffNumber: Record "Tariff Number";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        TariffNumber.FindFirst();
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Tariff No.", TariffNumber."No.");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePostGeneralJournal(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; BalGenPostingType: Enum "General Posting Type"; EUService: Boolean) EUServiceOld: Boolean
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Select Journal Batch Name and Template Name.
        GenJournalBatch.Init();
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        // Create General Journal Line.
        EUServiceOld :=
              CreateGeneralJournal(
                GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount, BalGenPostingType, EUService);

        // Post General Journal Line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure FindVATLedgerEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20])
    begin
        // Finds the matching VAT Ledger Entry from a General Journal Line
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
    end;

    local procedure PostAndVerifyVATEntry(ServiceHeader: Record "Service Header"; VATPostingSetup: Record "VAT Posting Setup"; EUService: Boolean; LineNo: Integer)
    var
        GLAccount: Record "G/L Account";
        ServiceLine: Record "Service Line";
        NoSeries: Codeunit "No. Series";
        PostedDocumentNo: Code[20];
    begin
        // Store Posted Document No. and Create Service Lines of Item and GL Account Type.
        PostedDocumentNo := NoSeries.PeekNextNo(ServiceHeader."Posting No. Series");
        CreateAndUpdateServiceLine(
          ServiceHeader, ServiceLine.Type::Item, LineNo, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        CreateAndUpdateServiceLine(ServiceHeader, ServiceLine.Type::"G/L Account", LineNo,
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));

        // Exercise: Post the Service Document.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Verify: Check that value of EU Service Field = Yes in VAT Entry.
        ValidateVATEntry(PostedDocumentNo, EUService);
    end;

    local procedure SetupAndCreateServiceHeader(var ServiceHeader: Record "Service Header"; var VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Service Document Type") EUService: Boolean
    begin
        EUService := UpdateVATPostSetup(VATPostingSetup, true);
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
    end;

    local procedure UpdateServiceLine(ServiceLine: Record "Service Line"; ServiceItemLineNo: Integer)
    begin
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", 10 + LibraryRandom.RandInt(100));
        ServiceLine.Modify(true);
    end;

    local procedure UpdateVATPostSetup(var VATPostingSetup: Record "VAT Posting Setup"; EUService: Boolean) EUServiceOld: Boolean
    begin
        // Find a VAT Posting Setup combination that have VAT% >0 and VAT Calculation Type = Reverse Charge VAT
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        EUServiceOld := VATPostingSetup."EU Service";
        VATPostingSetup.Validate("EU Service", EUService);
        VATPostingSetup.Validate("Adjust for Payment Discount", false);
        VATPostingSetup.Modify(true);
    end;

    local procedure ValidateVATEntry(DocumentNo: Code[20]; EUService: Boolean)
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Find the last VAT LEdger Entry
        FindVATLedgerEntry(VATEntry, DocumentNo);

        // Validate that EU Service is = Yes
        Assert.IsTrue(VATEntry."EU Service", 'EU Service should be Yes on VAT Entry');

        // Tear Down: Roll back VAT Posting Setup.
        UpdateVATPostSetup(VATPostingSetup, EUService);
    end;
}

