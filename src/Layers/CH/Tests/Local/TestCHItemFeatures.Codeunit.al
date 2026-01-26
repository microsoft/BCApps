codeunit 144047 "Test CH Item Features"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryService: Codeunit "Library - Service";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryCH: Codeunit "Library - CH";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        PositionFieldErr: Label 'Position field values are different';

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test CH Item Features");
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test CH Item Features");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Invoice Rounding", false);
        SalesReceivablesSetup.Modify();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test CH Item Features");
    end;

    local procedure TransferFieldsFromSalesDocument(DocumentType: Enum "Sales Document Type")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ShipToAddress: Record "Ship-to Address";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Customer.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Customer.Modify(true);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));

        // Exercise.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify.
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindLast();
        ItemLedgerEntry.TestField("Customer No.", Customer."No.");
        ItemLedgerEntry.TestField("Ship-to Address Code", ShipToAddress.Code);
        ItemLedgerEntry.TestField("Customer Salesperson Code", SalespersonPurchaser.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferFieldsFromSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        TransferFieldsFromSalesDocument(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferFieldsFromSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        TransferFieldsFromSalesDocument(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferFieldsFromSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        TransferFieldsFromSalesDocument(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferFieldsFromSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        TransferFieldsFromSalesDocument(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferFieldsFromItemJournal()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Customer: Record Customer;
        Item: Record Item;
        ShipToAddress: Record "Ship-to Address";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Sale, Item."No.", LibraryRandom.RandDec(100, 2));
        ItemJournalLine.Validate("Customer No.", Customer."No.");
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        ItemJournalLine.Validate("Ship-to Address Code", ShipToAddress.Code);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        ItemJournalLine.Validate("Customer Salesperson Code", SalespersonPurchaser.Code);
        ItemJournalLine.Validate("Title No.", LibraryRandom.RandInt(10));
        ItemJournalLine.Modify(true);

        // Exercise.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // Verify.
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindLast();
        ItemLedgerEntry.TestField("Customer No.", Customer."No.");
        ItemLedgerEntry.TestField("Ship-to Address Code", ShipToAddress.Code);
        ItemLedgerEntry.TestField("Customer Salesperson Code", SalespersonPurchaser.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferFieldsFromServiceDocument()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Customer: Record Customer;
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ShipToAddress: Record "Ship-to Address";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        Initialize();

        // Setup.
        LibraryCH.CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT",
          '', '');
        LibrarySales.CreateCustomer(Customer);
        Customer."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        Customer.Validate("Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2)));
        Customer.Modify(true);

        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Customer.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Customer.Modify(true);
        LibraryInventory.CreateItem(Item);
        Item."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        Item.Modify(true);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        ServiceHeader.Validate("Ship-to Code", ShipToAddress.Code);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);

        // Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Verify.
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindLast();
        ItemLedgerEntry.TestField("Customer No.", Customer."No.");
        ItemLedgerEntry.TestField("Ship-to Address Code", ShipToAddress.Code);
        ItemLedgerEntry.TestField("Customer Salesperson Code", SalespersonPurchaser.Code);

        VATEntry.SetRange("Bill-to/Pay-to No.", Customer."No.");
        VATEntry.FindFirst();
        VATEntry.TestField("Base (FCY)", -ServiceLine.Amount);
        VATEntry.TestField("Currency Code", Customer."Currency Code");
        VATEntry.TestField("VAT %", VATPostingSetup."VAT %");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VerifyPostionFieldInSalesLine()
    var
        Customer: array[2] of Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Position: Integer;
    begin
        // [SCENARIO 474638] Position value will have a correct value after changing the Sell-to Customer No. on Sales Header
        Initialize();

        // [GIVEN] Create two Customers
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Sales Header of Document Type Order for first customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer[1]."No.");

        // [GIVEN] Create Sales Line for one Item
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [GIVEN] Save the Position field of Sales Line
        Position := SalesLine.Position;

        // [WHEN] Validate the Sel-to Customer No. field on Sales Header with new Customer 
        SalesHeader.Validate("Sell-to Customer No.", Customer[2]."No.");
        SalesHeader.Modify();

        // [VERIFY] Verify the Position field not be change to 0.
        Assert.AreEqual(Position, SalesLine.Position, PositionFieldErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

