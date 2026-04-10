codeunit 134481 "ERM Dimension Archive Document"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension] [Archive]
        IsInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DimSalesOrderArchive()
    var
        SalesHeader: Record "Sales Header";
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
    begin
        // Verify Dimension on Archive Sales Order.

        // Create Customer with Default Dimension, Item, Sales Order.Archive Sales Order and Post it.
        Initialize();
        SalesOrderArchive(SalesHeader, TempDimensionSetEntry);

        // Verify Dimension on Archive Sales Order and Dimension Set Entry and Dimension on Sales Line successfully updated.
        VerifyDimOnSalesArchHeader(SalesHeader);
        VerifyDimOnSalesArchLine(SalesHeader);
        VerifyDimSetEntry(TempDimensionSetEntry, SalesHeader."Dimension Set ID");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DimSalesOrderArchiveDelete()
    var
        SalesHeader: Record "Sales Header";
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        // Verify Dimensions are deleted on deletion of Archived Purchase order.

        // Create Customer with Default Dimension, Item, Sales Order.Archive Sales Order and Post it.
        Initialize();
        SalesOrderArchive(SalesHeader, TempDimensionSetEntry);

        FindSalesDocumentArchive(SalesHeaderArchive, SalesHeader);
        SalesHeaderArchive.Delete(true);

        // Verify Dimension Set Entry and Dimension on Sales Line successfully updated.
        VerifyDimSetEntry(TempDimensionSetEntry, SalesHeader."Dimension Set ID");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DimPurchOrderArchive()
    var
        PurchaseHeader: Record "Purchase Header";
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
    begin
        // Verify Dimension on Archive Purchase Order.

        // Create Customer with Default Dimension, Item, Purchase Order.Archive Purchase Order and Post it.
        Initialize();
        PurchaseOrderArchive(PurchaseHeader, TempDimensionSetEntry);

        // Verify Dimension on Archive Purchase Order and Dimension Set Entry and Dimension on Purchase Line successfully updated.
        VerifyDimOnPurchArchHeader(PurchaseHeader);
        VerifyDimOnPurchArchLine(PurchaseHeader);
        VerifyDimSetEntry(TempDimensionSetEntry, PurchaseHeader."Dimension Set ID");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DimPurchOrderArchiveDelete()
    var
        PurchaseHeader: Record "Purchase Header";
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        PurchaseHeaderArchive: Record "Purchase Header Archive";
    begin
        // Verify Dimensions are deleted on deletion of Archived Sales order.

        // Create Customer with Default Dimension, Item, Purchase Order.Archive Purchase Order and Post it.
        Initialize();
        PurchaseOrderArchive(PurchaseHeader, TempDimensionSetEntry);
        FindPurchDocumentArchive(PurchaseHeaderArchive, PurchaseHeader);
        PurchaseHeaderArchive.Delete(true);

        // Verify Dimension Set Entry and Dimension on Purchase Line successfully updated.
        VerifyDimSetEntry(TempDimensionSetEntry, PurchaseHeader."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderArchiveWithPartialShip()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify Sales Header Archive and Sales Line Archive values.

        // Setup: Update Sales & Receivable setup, create and post Sales Order.
        Initialize();
        CreateAndPostSalesArchiveOrder(SalesLine);

        // Exercise.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Verify: Verify Sales Header Archive and Sales Line Archive values.
        VerifySalesOrderArchive(SalesHeader, SalesLine, 1);  // Used 1 for No. of Archived Verisons.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleSalesOrderArchive()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify Sales Header Archive and Sales Line Archive values with multiple Sales Order Archive.

        // Setup: Update Sales & Receivable setup, create and post Sales Order.
        Initialize();
        CreateAndPostSalesArchiveOrder(SalesLine);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity / 2);  // Taken partial Qty. to Ship.
        SalesLine.Modify(true);

        // Exercise.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Sales Header Archive and Sales Line Archive values with multiple Sales Order Archive.
        VerifySalesOrderArchive(SalesHeader, SalesLine, 2);  // Used 2 for No. of Archived Verisons.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderArchiveWithPartialReceive()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Purchase Header Archive and Purchase Line Archive values.

        // Setup: Update Purchases & Payables setup, create and post Purchase Order.
        Initialize();
        CreateAndPostPurchaseArchiveOrder(PurchaseLine);

        // Exercise.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Verify: Verify Purchase Header Archive and Purchase Line Archive values.
        VerifyPurchaseOrderArchive(PurchaseHeader, PurchaseLine, 1);  // Used 1 for No. of Archived Verisons.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiplePurchaseOrderArchive()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Purchase Header Archive and Purchase Line Archive values with multiple Purchase Order Archive .

        // Setup: Update Purchases & Payables setup, create and post Purchase Order.
        Initialize();
        CreateAndPostPurchaseArchiveOrder(PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity / 2);  // Taken partial Qty. to Receive.
        PurchaseLine.Modify(true);

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify: Verify Purchase Header Archive and Purchase Line Archive values with multiple Purchase Order Archive .
        VerifyPurchaseOrderArchive(PurchaseHeader, PurchaseLine, 2);  // Used 2 for No. of Archived Verisons.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchiveSalesOrderOnFinalInvoicing()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Order]
        // [SCENARIO 200401] System creates archive after posting final invoice when "Sales & Recievables Setup"."Archive Quotes and Orders" = TRUE

        // [GIVEN] Sales Order "SO" fully shipped and partially invoiced (1 archive exists)
        Initialize();
        LibrarySales.SetArchiveOrders(true);
        CreateSalesOrder(SalesHeader, SalesLine);
        SalesLine.Validate("Qty. to Invoice", SalesLine."Qty. to Invoice" / 2);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifySalesOrderArchive(SalesHeader, SalesLine, 1);

        // [WHEN] Post final invoice
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] 2nd archive created
        VerifySalesOrderArchive(SalesHeader, SalesLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchivePurchaseOrderOnFinalInvoicing()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Order]
        // [SCENARIO 200401] System creates archive after posting final invoice when "Purchases & Payables Setup"."Archive Quotes and Orders" = TRUE

        // [GIVEN] Purchase Order "PO" fully receipt and partially invoiced (1 archive exists)
        Initialize();
        LibraryPurchase.SetArchiveOrders(true);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine."Qty. to Invoice" / 2);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        VerifyPurchaseOrderArchive(PurchaseHeader, PurchaseLine, 1);

        // [WHEN] Post final invoice
        PurchaseHeader.Validate("Vendor Invoice No.", IncStr(PurchaseHeader."Vendor Invoice No."));
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] 2nd archive created
        VerifyPurchaseOrderArchive(PurchaseHeader, PurchaseLine, 2);
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ArchiveSalesOrderFullyInvoicedOnDelete()
    var
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLineOrder: Record "Sales Line";
        SalesLineInvoice: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Order] [Get Shipment Lines]
        // [SCENARIO 200401] System creates archive after delete invoiced sales order

        // [GIVEN] Sales Order "SO" fully shipped and not invoiced (1 archive exists)
        Initialize();
        LibrarySales.SetArchiveOrders(true);
        CreateSalesOrder(SalesHeaderOrder, SalesLineOrder);
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        VerifySalesOrderArchive(SalesHeaderOrder, SalesLineOrder, 1);

        // [GIVEN] Sales Invoice created from "SO" with "Get Shipment Lines" and fully invoiced
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeaderOrder."Sell-to Customer No.");
        SalesLineInvoice.Validate("Document Type", SalesHeaderInvoice."Document Type");
        SalesLineInvoice.Validate("Document No.", SalesHeaderInvoice."No.");
        LibrarySales.GetShipmentLines(SalesLineInvoice);
        LibrarySales.PostSalesDocument(SalesHeaderInvoice, true, true);

        // [WHEN] Delete "SO"
        SalesHeaderOrder.Find();
        SalesHeaderOrder.Delete(true);

        // [THEN] 2nd archive created
        VerifySalesOrderArchive(SalesHeaderOrder, SalesLineOrder, 2);
    end;

    [Test]
    [HandlerFunctions('GetReceiptLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ArchivePurchaseOrderFullyInvoicedOnDelete()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseLineInvoice: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Order] [Get Receipt Lines]
        // [SCENARIO 200401] System creates archive after delete invoiced purchase order

        // [GIVEN] Purchase Order "PO" fully receipt and not invoiced (1 archive exists)
        Initialize();
        LibraryPurchase.SetArchiveOrders(true);
        CreatePurchaseOrder(PurchaseHeaderOrder, PurchaseLineOrder);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        VerifyPurchaseOrderArchive(PurchaseHeaderOrder, PurchaseLineOrder, 1);

        // [GIVEN] Purchase Invoice created from "PO" with "Get Receipt Lines" and fully invoiced
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, PurchaseHeaderOrder."Buy-from Vendor No.");
        PurchaseLineInvoice.Validate("Document Type", PurchaseHeaderInvoice."Document Type");
        PurchaseLineInvoice.Validate("Document No.", PurchaseHeaderInvoice."No.");
        LibraryPurchase.GetPurchaseReceiptLine(PurchaseLineInvoice);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true);

        // [WHEN] Delete "PO"
        PurchaseHeaderOrder.Find();
        PurchaseHeaderOrder.Delete(true);

        // [THEN] 2nd archive created
        VerifyPurchaseOrderArchive(PurchaseHeaderOrder, PurchaseLineOrder, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchiveSalesQuoteOnDelete()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Quote]
        // [SCENARIO 200401] System creates archive when delete sales quote

        // [GIVEN] Sales Quote when the line
        Initialize();
        LibrarySales.SetArchiveOrders(true);
        LibrarySales.SetArchiveQuoteAlways();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));

        // [WHEN] When delete sales quote
        SalesHeader.Delete(true);

        // [THEN] The archive for sales quote is created
        VerifySalesOrderArchive(SalesHeader, SalesLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchivePurchaseQuoteOnDelete()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Quote]
        // [SCENARIO 200401] System creates archive when delete purchase quote

        // [GIVEN] Purchase Quote when the line
        Initialize();
        LibraryPurchase.SetArchiveOrders(true);
        LibraryPurchase.SetArchiveQuotesAlways();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));

        // [WHEN] When delete purchase quote
        PurchaseHeader.Delete(true);

        // [THEN] The archive for purchase quote is created
        VerifyPurchaseOrderArchive(PurchaseHeader, PurchaseLine, 1);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Dimension Archive Document");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Dimension Archive Document");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Dimension Archive Document");
    end;

    local procedure SalesOrderArchive(var SalesHeader: Record "Sales Header"; var TempDimensionSetEntry: Record "Dimension Set Entry" temporary)
    var
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // Setup: Create Customer with Default Dimension, Item, Sales Order.
        CreateSalesOrderWithDim(SalesHeader, TempDimensionSetEntry);

        // Exercise: Archive Sales Order and Post it.
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure PurchaseOrderArchive(var PurchaseHeader: Record "Purchase Header"; var TempDimensionSetEntry: Record "Dimension Set Entry" temporary)
    var
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // Setup: Create Customer with Default Dimension, Item, Purchase Order.
        CreatePurchOrderWithDim(PurchaseHeader, TempDimensionSetEntry);

        // Exercise: Archive Purchase Order and Post it.
        ArchiveManagement.ArchivePurchDocument(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesArchiveOrder(var SalesLine: Record "Sales Line")
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.SetArchiveOrders(true);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));  // Used Random value for Quantity.
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity / 2);  // Taken partial Qty. to Ship
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostPurchaseArchiveOrder(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.SetArchiveOrders(true);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));  // Used Random value for Quantity.
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity / 2);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Used Random value for Unit Price.
        Item.Modify(true);
        exit(Item."No.")
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerWithDim());

        // Use Random because value is not important.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemWithDim(), LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendorWithDim());

        // Use Random because value is not important.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItemWithDim(), LibraryRandom.RandDec(10, 2));
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateDimensionSetEntry(var DimensionSetID: Integer; ShortcutDimensionCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        Dimension: Record Dimension;
    begin
        Dimension.SetFilter(Code, '<>%1', ShortcutDimensionCode);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        DimensionSetID := LibraryDimension.CreateDimSet(DimensionSetID, DimensionValue."Dimension Code", DimensionValue.Code);

        LibraryDimension.FindDimensionValue(DimensionValue, ShortcutDimensionCode);
        DimensionSetID := LibraryDimension.CreateDimSet(DimensionSetID, ShortcutDimensionCode, DimensionValue.Code);
    end;

    local procedure UpdateDefaultDimension(DefaultDimension: Record "Default Dimension")
    begin
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::" ");
        DefaultDimension.Modify(true);
    end;

    local procedure CreateSalesDimSetEntryHeader(var SalesHeader: Record "Sales Header"; ShortcutDimensionCode: Code[20])
    var
        DimensionSetID: Integer;
    begin
        DimensionSetID := SalesHeader."Dimension Set ID";
        CreateDimensionSetEntry(DimensionSetID, ShortcutDimensionCode);
        SalesHeader.Validate("Dimension Set ID", DimensionSetID);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesDimSetEntryLine(var SalesLine: Record "Sales Line"; ShortcutDimensionCode: Code[20])
    var
        DimensionSetID: Integer;
    begin
        DimensionSetID := SalesLine."Dimension Set ID";
        CreateDimensionSetEntry(DimensionSetID, ShortcutDimensionCode);
        SalesLine.Validate("Dimension Set ID", DimensionSetID);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchDimSetEntryHeader(var PurchaseHeader: Record "Purchase Header"; ShortcutDimensionCode: Code[20])
    var
        DimensionSetID: Integer;
    begin
        DimensionSetID := PurchaseHeader."Dimension Set ID";
        CreateDimensionSetEntry(DimensionSetID, ShortcutDimensionCode);
        PurchaseHeader.Validate("Dimension Set ID", DimensionSetID);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchDimSetEntryLine(var PurchaseLine: Record "Purchase Line"; ShortcutDimensionCode: Code[20])
    var
        DimensionSetID: Integer;
    begin
        DimensionSetID := PurchaseLine."Dimension Set ID";
        CreateDimensionSetEntry(DimensionSetID, ShortcutDimensionCode);
        PurchaseLine.Validate("Dimension Set ID", DimensionSetID);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithDim(var SalesHeader: Record "Sales Header"; var TempDimensionSetEntry: Record "Dimension Set Entry" temporary)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionSetEntry: Record "Dimension Set Entry";
        SalesLine: Record "Sales Line";
        ShortcutDimensionCode: Code[20];
    begin
        // Create Customer, Item, Sales Header and Sales Line with Dimension.
        GeneralLedgerSetup.Get();
        ShortcutDimensionCode := GeneralLedgerSetup."Shortcut Dimension 1 Code";
        CreateSalesOrder(SalesHeader, SalesLine);
        CreateSalesDimSetEntryHeader(SalesHeader, ShortcutDimensionCode);
        CreateSalesDimSetEntryLine(SalesLine, ShortcutDimensionCode);

        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, SalesLine."Dimension Set ID");
        CopyDimSetEntry(TempDimensionSetEntry, DimensionSetEntry);
        TempDimensionSetEntry.SetFilter("Dimension Code", '<>%1', ShortcutDimensionCode);
        TempDimensionSetEntry.FindSet();
    end;

    local procedure CreatePurchOrderWithDim(var PurchaseHeader: Record "Purchase Header"; var TempDimensionSetEntry: Record "Dimension Set Entry" temporary)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionSetEntry: Record "Dimension Set Entry";
        PurchaseLine: Record "Purchase Line";
        ShortcutDimensionCode: Code[20];
    begin
        // Setup: Create Vendor, Item, Purchase Header and Purchase Line with Dimension.
        GeneralLedgerSetup.Get();
        ShortcutDimensionCode := GeneralLedgerSetup."Shortcut Dimension 1 Code";
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        CreatePurchDimSetEntryHeader(PurchaseHeader, ShortcutDimensionCode);
        CreatePurchDimSetEntryLine(PurchaseLine, ShortcutDimensionCode);

        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, PurchaseLine."Dimension Set ID");
        CopyDimSetEntry(TempDimensionSetEntry, DimensionSetEntry);
        TempDimensionSetEntry.SetFilter("Dimension Code", '<>%1', ShortcutDimensionCode);
        TempDimensionSetEntry.FindSet();
    end;

    local procedure CreateCustomerWithDim(): Code[20]
    var
        Customer: Record Customer;
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", Dimension.Code, '');
        UpdateDefaultDimension(DefaultDimension);
        exit(Customer."No.");
    end;

    local procedure CreateVendorWithDim(): Code[20]
    var
        Vendor: Record Vendor;
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, Vendor."No.", Dimension.Code, '');
        UpdateDefaultDimension(DefaultDimension);
        exit(Vendor."No.");
    end;

    local procedure CreateItemWithDim(): Code[20]
    var
        Item: Record Item;
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryInventory.CreateItem(Item);

        // Use Random because value is not important.
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", Dimension.Code, '');
        UpdateDefaultDimension(DefaultDimension);
        exit(Item."No.")
    end;

    local procedure CopyDimSetEntry(var TempDimensionSetEntry: Record "Dimension Set Entry" temporary; var DimensionSetEntry: Record "Dimension Set Entry")
    begin
        repeat
            TempDimensionSetEntry := DimensionSetEntry;
            TempDimensionSetEntry.Insert();
        until DimensionSetEntry.Next() = 0;
    end;

    local procedure FindSalesLineArchive(var SalesLineArchive: Record "Sales Line Archive"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLineArchive.SetRange("Document Type", DocumentType);
        SalesLineArchive.SetRange("Document No.", DocumentNo);
        SalesLineArchive.FindFirst();
    end;

    local procedure FindPurchaseLineArchive(var PurchaseLineArchive: Record "Purchase Line Archive"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        PurchaseLineArchive.SetRange("Document Type", DocumentType);
        PurchaseLineArchive.SetRange("Document No.", DocumentNo);
        PurchaseLineArchive.FindFirst();
    end;

    local procedure FindSalesDocumentArchive(var SalesHeaderArchive: Record "Sales Header Archive"; SalesHeader: Record "Sales Header")
    begin
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.FindFirst();
    end;

    local procedure FindPurchDocumentArchive(var PurchaseHeaderArchive: Record "Purchase Header Archive"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeaderArchive.FindFirst();
    end;

    local procedure VerifyDimOnSalesArchHeader(SalesHeader: Record "Sales Header")
    var
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        FindSalesDocumentArchive(SalesHeaderArchive, SalesHeader);
        SalesHeaderArchive.TestField("Dimension Set ID", SalesHeader."Dimension Set ID");
    end;

    local procedure VerifyDimOnSalesArchLine(SalesHeader: Record "Sales Header")
    var
        SalesLineArchive: Record "Sales Line Archive";
    begin
        FindSalesLineArchive(SalesLineArchive, SalesHeader."Document Type", SalesHeader."No.");
        SalesLineArchive.TestField("Dimension Set ID", SalesHeader."Dimension Set ID");
    end;

    local procedure VerifyDimOnPurchArchHeader(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
    begin
        FindPurchDocumentArchive(PurchaseHeaderArchive, PurchaseHeader);
        PurchaseHeaderArchive.TestField("Dimension Set ID", PurchaseHeader."Dimension Set ID");
    end;

    local procedure VerifyDimOnPurchArchLine(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLineArchive: Record "Purchase Line Archive";
    begin
        FindPurchaseLineArchive(PurchaseLineArchive, PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLineArchive.TestField("Dimension Set ID", PurchaseHeader."Dimension Set ID");
    end;

    local procedure VerifyDimSetEntry(var TempDimensionSetEntry: Record "Dimension Set Entry" temporary; DimensionSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        repeat
            DimensionSetEntry.SetRange("Dimension Code", TempDimensionSetEntry."Dimension Code");
            DimensionSetEntry.FindFirst();
            DimensionSetEntry.TestField("Dimension Value Code", TempDimensionSetEntry."Dimension Value Code");
        until TempDimensionSetEntry.Next() = 0;
    end;

    local procedure VerifyPurchaseOrderArchive(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; VersionNo: Integer)
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        PurchaseLineArchive: Record "Purchase Line Archive";
    begin
        FindPurchDocumentArchive(PurchaseHeaderArchive, PurchaseHeader);
        PurchaseHeaderArchive.SetRange("Version No.", VersionNo);
        PurchaseHeaderArchive.FindFirst();
        PurchaseHeaderArchive.TestField("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");

        FindPurchaseLineArchive(PurchaseLineArchive, PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLineArchive.TestField("No.", PurchaseLine."No.");
        PurchaseLineArchive.TestField("Qty. to Receive", PurchaseLine."Qty. to Receive");
        PurchaseLineArchive.TestField("Quantity Received", 0);  // Verifying Quantity Received should be zero.
    end;

    local procedure VerifySalesOrderArchive(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; VersionNo: Integer)
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        SalesLineArchive: Record "Sales Line Archive";
    begin
        FindSalesDocumentArchive(SalesHeaderArchive, SalesHeader);
        SalesHeaderArchive.SetRange("Version No.", VersionNo);
        SalesHeaderArchive.FindFirst();
        SalesHeaderArchive.TestField("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");

        FindSalesLineArchive(SalesLineArchive, SalesHeader."Document Type", SalesHeader."No.");
        SalesLineArchive.TestField("No.", SalesLine."No.");
        SalesLineArchive.TestField("Qty. to Ship", SalesLine."Qty. to Ship");
        SalesLineArchive.TestField("Quantity Shipped", 0);  // Quantity Shipped should be zero.
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
        // Just to Handle the Message.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesModalPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReceiptLinesModalPageHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    begin
        GetReceiptLines.OK().Invoke();
    end;
}

