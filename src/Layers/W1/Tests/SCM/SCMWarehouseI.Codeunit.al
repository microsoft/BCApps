codeunit 137047 "SCM Warehouse I"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        ErrInvalidDimensionTransfer: Label 'The dimensions that are used in transfer order %1, line no. %2 are not valid.';
        ErrNoRecord: Label 'There must not be any record within the filter. ';
        EmptyTableErr: Label 'There must be %1 records in %2 within the filter %3.';
        SortingOrderErr: Label 'Wrong sorting order in %1';
        NoWhseReceiptLinesCreatedErr: Label 'There are no warehouse receipt lines created.';
        NoWhseShipmentLinesCreatedErr: Label 'There are no warehouse shipment lines created.';
        CannotReclassifyLocationErr: Label 'You cannot reclassify location %1 because it is set up with Directed Put-away and Pick';
        CannotUseLocationErr: Label 'You cannot use a %1 because %2 %3 is set up with %4';
        ShipmentDateMustNotChangeErr: Label 'Shipment Date must not be changed when a Warehouse Shipment Line for this Sales Line exists';
        OrderToOrderBindingOnSalesLineQst: Label 'Registering the pick will remove the existing order-to-order reservation for the sales order.\Do you want to continue?';
        RegisterInterruptedErr: Label 'The action has been interrupted to respect the warning.';
        WrongMessageTextErr: Label 'Serial No must be avaliable.';
        SelectDimForCVErr: Label 'Select a Dimension Value Code for the Dimension Code AREA for %1 %2.';

    [Test]
    [Scope('OnPrem')]
    procedure ShowPostingErrorSalesOrder()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Customer: Record Customer;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Create setups, Item and Customer with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error",
          WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        CreateItem(Item);
        CreateLocationSetup(Location, false, true, true);
        UpdateItemInventory(Item."No.", Location.Code);
        CreateCustomer(Customer, Location.Code);

        // Create Sales Order Setup. Create Warehouse Shipment using Filters to get Source document.
        CreateSalesSetup(SalesHeader, SalesHeader2, SalesHeader."Document Type"::Order, Item."No.", Location.Code, Customer."No.");
        UseFiltersToGetSrcDocShipment(WarehouseShipmentHeader, Customer."No.", '', Location.Code, '');

        // Exercise: Post Warehouse Shipment.
        asserterror LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Error Message - Dimensions are invalid.
        Assert.ExpectedError(StrSubstNo(SelectDimForCVErr, Customer.TableCaption(), Customer."No."));

        // Verify that correct shipment line has been posted.
        VerifyPostedShipmentLinesSales(WarehouseShipmentHeader."No.", Item."No.", SalesHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [HandlerFunctions('StringMenuHandler,ShipLinesMessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorNotProcessedSalesOrder()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Customer: Record Customer;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Create setups, Item and Customer with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        CreateItem(Item);
        CreateLocationSetup(Location, false, true, true);
        UpdateItemInventory(Item."No.", Location.Code);
        CreateCustomer(Customer, Location.Code);

        // Create Sales Order Setup. Create Warehouse Shipment using Filters to get Source document.
        CreateSalesSetup(SalesHeader, SalesHeader2, SalesHeader."Document Type"::Order, Item."No.", Location.Code, Customer."No.");
        UseFiltersToGetSrcDocShipment(WarehouseShipmentHeader, Customer."No.", '', Location.Code, '');

        // Exercise: Post Warehouse Shipment such that it generates the posting confirmation message.
        LibraryWarehouse.PostWhseShptWithShipInvoiceMsg(WarehouseShipmentHeader."No.");

        // Verify: Check message inside Handler and verify that correct shipment line has been posted.
        VerifyPostedShipmentLinesSales(WarehouseShipmentHeader."No.", Item."No.", SalesHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowPostingErrorPurchRetOrder()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        Vendor: Record Vendor;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Create setups, Item and Vendor with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error",
          WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        CreateItem(Item);
        CreateLocationSetup(Location, false, true, true);
        UpdateItemInventory(Item."No.", Location.Code);
        CreateVendor(Vendor, Location.Code);

        // Create Purchase Return Order setup. Create Warehouse Shipment using Filters to get Source document.
        // False - Purchase Return Shipment.
        CreatePurchaseSetup(
          PurchaseHeader, PurchaseHeader2, PurchaseHeader."Document Type"::"Return Order", Item."No.", Location.Code, Vendor."No.");
        UseFiltersToGetSrcDocShipment(WarehouseShipmentHeader, '', Vendor."No.", Location.Code, '');

        // Exercise: Post Warehouse Shipment.
        asserterror LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Error Message - Dimensions are invalid.
        Assert.ExpectedError(StrSubstNo(SelectDimForCVErr, Vendor.TableCaption(), Vendor."No."));

        // Verify that correct shipment line has been posted.
        VerifyPostedShipmentLinesPurch(WarehouseShipmentHeader."No.", Item."No.", PurchaseHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [HandlerFunctions('StringMenuHandler,ShipLinesMessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorNotProcessedPurchRetOrder()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        Vendor: Record Vendor;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Create setups, Item and Vendor with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        CreateItem(Item);
        CreateLocationSetup(Location, false, true, true);
        UpdateItemInventory(Item."No.", Location.Code);
        CreateVendor(Vendor, Location.Code);

        // Create Purchase Return Order setup. Create Warehouse Shipment using Filters to get Source document.
        CreatePurchaseSetup(
          PurchaseHeader, PurchaseHeader2, PurchaseHeader."Document Type"::"Return Order", Item."No.", Location.Code, Vendor."No.");
        UseFiltersToGetSrcDocShipment(WarehouseShipmentHeader, '', Vendor."No.", Location.Code, '');

        // Exercise: Post Warehouse Shipment such that it generates the posting confirmation message.
        LibraryWarehouse.PostWhseShptWithShipInvoiceMsg(WarehouseShipmentHeader."No.");

        // Verify: Check message inside Handler and Verify that correct shipment line has been posted.
        VerifyPostedShipmentLinesPurch(WarehouseShipmentHeader."No.", Item."No.", PurchaseHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowPostingErrorTransferOrder()
    var
        WarehouseSetup: Record "Warehouse Setup";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferHeader2: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Create setups, Item and Transfer Locations.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error",
          WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        CreateItem(Item);
        CreateTransferLocations(LocationFrom, LocationTo, LocationInTransit);
        UpdateItemInventory(Item."No.", LocationFrom.Code);

        // Create Transfer Order setup. Create Warehouse Shipment using Filters to get Source document.
        CreateTransferOrderSetup(
          TransferHeader, TransferHeader2, Item."No.", LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        UseFiltersToGetSrcDocShipment(WarehouseShipmentHeader, '', '', LocationFrom.Code, LocationTo.Code);

        // Exercise: Post Warehouse Shipment.
        asserterror LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Error Message - Dimensions are invalid.
        TransferLine.SetRange("Document No.", TransferHeader2."No.");
        TransferLine.FindFirst();
        Assert.ExpectedError(StrSubstNo(ErrInvalidDimensionTransfer, TransferHeader2."No.", TransferLine."Line No."));

        // Verify that correct shipment line has been posted.
        VerifyPostedShipmentLinesTrans(WarehouseShipmentHeader."No.", Item."No.", TransferHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [HandlerFunctions('StringMenuHandler,ShipLinesMessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorNotProcessedTransferOrder()
    var
        WarehouseSetup: Record "Warehouse Setup";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferHeader2: Record "Transfer Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Create setups, Item and Transfer Locations.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        CreateItem(Item);
        CreateTransferLocations(LocationFrom, LocationTo, LocationInTransit);
        UpdateItemInventory(Item."No.", LocationFrom.Code);

        // Create Transfer Order Setup. Create Warehouse Shipment using Filters to get Source document.
        CreateTransferOrderSetup(
          TransferHeader, TransferHeader2, Item."No.", LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        UseFiltersToGetSrcDocShipment(WarehouseShipmentHeader, '', '', LocationFrom.Code, LocationTo.Code);

        // Exercise: Post Warehouse Shipment such that it generates the posting confirmation message.
        LibraryWarehouse.PostWhseShptWithShipInvoiceMsg(WarehouseShipmentHeader."No.");

        // Verify: Check message inside Handler and verify that correct shipment line has been posted.
        VerifyPostedShipmentLinesTrans(WarehouseShipmentHeader."No.", Item."No.", TransferHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowPostingErrorSalesRetOrder()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Customer: Record Customer;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        // Setup: Create setups, Item and Customer with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        CreateItem(Item);
        CreateLocationSetup(Location, false, true, true);
        UpdateItemInventory(Item."No.", Location.Code);
        CreateCustomer(Customer, Location.Code);

        // Create Sales Return Order setup. Create Warehouse Receipt using Filters to get Source document.
        CreateSalesSetup(
          SalesHeader, SalesHeader2, SalesHeader."Document Type"::"Return Order", Item."No.", Location.Code, Customer."No.");
        UseFiltersToGetSrcDocReceipt(WarehouseReceiptHeader, Customer."No.", '', Location.Code);

        // Exercise: Post Warehouse Receipt.
        asserterror LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify: Error Message - Dimensions are invalid.
        Assert.ExpectedError(StrSubstNo(SelectDimForCVErr, Customer.TableCaption(), Customer."No."));

        // Verify that correct receipt line has been posted.
        VerifyPostedReceiptLinesSales(WarehouseReceiptHeader."No.", Item."No.", SalesHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SourceDocMessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorNotProcessedSalesRetOrder()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Customer: Record Customer;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        // Setup: Create setups, Item and Customer with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        CreateItem(Item);
        CreateLocationSetup(Location, false, true, true);
        UpdateItemInventory(Item."No.", Location.Code);
        CreateCustomer(Customer, Location.Code);

        // Create Sales Return Order setup. Create Warehouse Receipt using Filters to get Source document.
        CreateSalesSetup(
          SalesHeader, SalesHeader2, SalesHeader."Document Type"::"Return Order", Item."No.", Location.Code, Customer."No.");
        UseFiltersToGetSrcDocReceipt(WarehouseReceiptHeader, Customer."No.", '', Location.Code);

        // Exercise: Post Warehouse Receipt such that it generates the posting confirmation message.
        LibraryWarehouse.PostWhseRcptWithConfirmMsg(WarehouseReceiptHeader."No.");

        // Verify: Check message inside Handler and verify that correct receipt line has been posted.
        VerifyPostedReceiptLinesSales(WarehouseReceiptHeader."No.", Item."No.", SalesHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowPostingErrorPurchaseOrder()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        Vendor: Record Vendor;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        // Setup: Create setups, Item and Vendor with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        CreateItem(Item);
        CreateLocationSetup(Location, false, true, true);
        UpdateItemInventory(Item."No.", Location.Code);
        CreateVendor(Vendor, Location.Code);

        // Create Purchase Order setup. Create Warehouse Receipt using Filters to get Source document.
        CreatePurchaseSetup(
          PurchaseHeader, PurchaseHeader2, PurchaseHeader."Document Type"::Order, Item."No.", Location.Code, Vendor."No.");
        UseFiltersToGetSrcDocReceipt(WarehouseReceiptHeader, '', Vendor."No.", Location.Code);

        // Exercise: Post Warehouse Receipt.
        asserterror LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify: Error Message - Dimensions are invalid.
        Assert.ExpectedError(StrSubstNo(SelectDimForCVErr, Vendor.TableCaption(), Vendor."No."));

        // Verify that correct receipt line has been posted.
        VerifyPostedReceiptLinesPurch(WarehouseReceiptHeader."No.", Item."No.", PurchaseHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SourceDocMessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorNotProcessedPurchaseOrder()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        Vendor: Record Vendor;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        // Setup: Create setups, Item and Vendor with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        CreateItem(Item);
        CreateLocationSetup(Location, false, true, true);
        UpdateItemInventory(Item."No.", Location.Code);
        CreateVendor(Vendor, Location.Code);

        // Create Purchase Order setup. Create Warehouse Receipt using Filters to get Source document.
        CreatePurchaseSetup(
          PurchaseHeader, PurchaseHeader2, PurchaseHeader."Document Type"::Order, Item."No.", Location.Code, Vendor."No.");
        UseFiltersToGetSrcDocReceipt(WarehouseReceiptHeader, '', Vendor."No.", Location.Code);

        // Exercise: Post Warehouse Receipt such that it generates the posting confirmation message.
        LibraryWarehouse.PostWhseRcptWithConfirmMsg(WarehouseReceiptHeader."No.");

        // Verify: Check message inside Handler and verify that correct receipt line has been posted.
        VerifyPostedReceiptLinesPurch(WarehouseReceiptHeader."No.", Item."No.", PurchaseHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowErrorSalesOrderBlocked()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Create setups, Item, Customer with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error",
          WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        CreateItem(Item);
        CreateLocationSetup(Location, false, true, true);
        CreateCustomer(Customer, Location.Code);

        // Create Sales Order. Create Warehouse Shipment using Filters to get Source document.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Item."No.", Location.Code, Customer."No.", true);
        UseFiltersToGetSrcDocShipment(WarehouseShipmentHeader, Customer."No.", '', Location.Code, '');
        BlockItemForPosting(Item."No.", true);

        // Exercise: Post Warehouse Shipment.
        asserterror LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Error Message - Blocked must be 'No' in Item.
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowErrorPurchReturnBlocked()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup: Create setups, Item, Customer and Vendor with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error",
          WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        CreateItem(Item);
        CreateItem(Item2);
        CreateLocationSetup(Location, false, true, true);
        CreateCustomer(Customer, Location.Code);
        CreateVendor(Vendor, Location.Code);

        // Create Sales Order and Purchase Return Order. Create Warehouse Shipment using Filters to get Source document.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Item."No.", Location.Code, Customer."No.", true);
        CreateAndReleasePurchDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Item2."No.", Location.Code, Vendor."No.", true);
        UseFiltersToGetSrcDocShipment(WarehouseShipmentHeader, Customer."No.", Vendor."No.", Location.Code, '');
        BlockItemForPosting(Item2."No.", true);

        // Exercise: Post Warehouse Shipment.
        asserterror LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Error Message - Blocked must be 'No' in Item, and posted Sales shipment.
        Assert.ExpectedTestFieldError(Item2.FieldCaption(Blocked), Format(false));
        VerifyPostedShipmentLinesSales(WarehouseShipmentHeader."No.", Item."No.", SalesHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowErrorSalesPurchRetBlocked()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
    begin
        // Setup: Create setups, Item, Customer, and Vendor with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error",
          WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        CreateItem(Item);
        CreateLocationSetup(Location, false, true, true);
        CreateCustomer(Customer, Location.Code);
        CreateVendor(Vendor, Location.Code);

        // Create Sales Order and Purchase Return Order. Create Warehouse Shipment using Filters to get Source document.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Item."No.", Location.Code, Customer."No.", true);
        CreateAndReleasePurchDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Item."No.", Location.Code, Vendor."No.", true);
        UseFiltersToGetSrcDocShipment(WarehouseShipmentHeader, Customer."No.", Vendor."No.", Location.Code, '');
        BlockItemForPosting(Item."No.", true);

        // Exercise: Post Warehouse Shipment.
        asserterror LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Error Message - Blocked must be 'No' in Item, and posted entries.
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));

        // Verify: Verify nothing is posted.
        PostedWhseShipmentLine.SetFilter("Whse. Shipment No.", '%1', WarehouseShipmentHeader."No.");
        Assert.AreEqual(0, PostedWhseShipmentLine.Count, ErrNoRecord);

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowErrorAndUnblockAllShipment()
    var
        WarehouseSetup: Record "Warehouse Setup";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
    begin
        // Setup: Create setups, Item, Customer and Vendor with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error",
          WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        CreateItem(Item);
        CreateTransferLocations(LocationFrom, LocationTo, LocationInTransit);
        UpdateItemInventory(Item."No.", LocationFrom.Code);
        CreateCustomer(Customer, LocationFrom.Code);
        CreateVendor(Vendor, LocationFrom.Code);

        // Create Sales Order, Purchase Return Order, and Transfer Order.
        // Create Warehouse Shipment using Filters to get Source document.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Item."No.", LocationFrom.Code, Customer."No.", true);
        CreateAndReleasePurchDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Item."No.", LocationFrom.Code, Vendor."No.", true);
        CreateAndReleaseTransferOrder(TransferHeader, Item."No.", LocationFrom.Code, LocationTo.Code, LocationInTransit.Code, true);
        UseFiltersToGetSrcDocShipment(WarehouseShipmentHeader, Customer."No.", Vendor."No.", LocationFrom.Code, LocationTo.Code);
        BlockItemForPosting(Item."No.", true);

        // Exercise: Post Warehouse Shipment.
        asserterror LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Error Message - Blocked must be 'No' in Item, and posted entries.
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));

        // Exercise: Unblock Item and Post successfully.
        BlockItemForPosting(Item."No.", false);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Verify posted shipment lines.
        VerifyPostedShipmentLinesSales(WarehouseShipmentHeader."No.", Item."No.", SalesHeader."No.");
        VerifyPostedShipmentLinesPurch(WarehouseShipmentHeader."No.", Item."No.", PurchaseHeader."No.");
        VerifyPostedShipmentLinesTrans(WarehouseShipmentHeader."No.", Item."No.", TransferHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [HandlerFunctions('ShipLinesMessageHandler,StringMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrNotProcessPostPurchRetTrans()
    var
        WarehouseSetup: Record "Warehouse Setup";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        Item: Record Item;
    begin
        // Setup: Create setups for Sales, Purchase Return and Transfer with Customer, Vendor Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        ShipmentSalesPurchRetTransfer(
          WarehouseShipmentHeader, SalesHeader, PurchaseHeader, TransferHeader, Item, false, true, true);  // Remove Dimensions in Sales Order.

        // Exercise: Post Warehouse Shipment.
        LibraryWarehouse.PostWhseShptWithShipInvoiceMsg(WarehouseShipmentHeader."No.");

        // Verify: Verify posted shipment lines.
        VerifyPostedShipmentLinesPurch(WarehouseShipmentHeader."No.", Item."No.", PurchaseHeader."No.");  // Purchase Return Order.
        VerifyPostedShipmentLinesTrans(WarehouseShipmentHeader."No.", Item."No.", TransferHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [HandlerFunctions('ShipLinesMessageHandler,StringMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrNotProcessPostSalesOrdTrans()
    var
        WarehouseSetup: Record "Warehouse Setup";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        Item: Record Item;
    begin
        // Setup: Create setups for Sales, Purchase Return and Transfer with Customer, Vendor Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        ShipmentSalesPurchRetTransfer(
          WarehouseShipmentHeader, SalesHeader, PurchaseHeader, TransferHeader, Item, true, false, true);
        // Remove Dimensions in Purchase Return.

        // Exercise: Post Warehouse Shipment.
        LibraryWarehouse.PostWhseShptWithShipInvoiceMsg(WarehouseShipmentHeader."No.");

        // Verify: Verify posted shipment lines.
        VerifyPostedShipmentLinesSales(WarehouseShipmentHeader."No.", Item."No.", SalesHeader."No.");
        VerifyPostedShipmentLinesTrans(WarehouseShipmentHeader."No.", Item."No.", TransferHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [HandlerFunctions('ShipLinesMessageHandler,StringMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrNotProcessPostSalesPurchRet()
    var
        WarehouseSetup: Record "Warehouse Setup";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        Item: Record Item;
    begin
        // Setup: Create setups for Sales, Purchase Return and Transfer with Customer, Vendor Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        ShipmentSalesPurchRetTransfer(
          WarehouseShipmentHeader, SalesHeader, PurchaseHeader, TransferHeader, Item, true, true, false);
        // Remove Dimensions in Transfer Order.

        // Exercise: Post Warehouse Shipment.
        LibraryWarehouse.PostWhseShptWithShipInvoiceMsg(WarehouseShipmentHeader."No.");

        // Verify: Verify posted shipment lines.
        VerifyPostedShipmentLinesSales(WarehouseShipmentHeader."No.", Item."No.", SalesHeader."No.");
        VerifyPostedShipmentLinesPurch(WarehouseShipmentHeader."No.", Item."No.", PurchaseHeader."No.");  // Purchase Return Order.

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowErrorPurchaseOrderBlocked()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        // Setup: Create setups, Item and Vendor with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        CreateItem(Item);
        CreateLocationSetup(Location, false, true, true);
        UpdateItemInventory(Item."No.", Location.Code);
        CreateVendor(Vendor, Location.Code);

        // Create Purchase Order setup. Create Warehouse Receipt using Filters to get Source document.
        CreateAndReleasePurchDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Item."No.", Location.Code, Vendor."No.", true);
        UseFiltersToGetSrcDocReceipt(WarehouseReceiptHeader, '', Vendor."No.", Location.Code);
        BlockItemForPosting(Item."No.", true);

        // Exercise: Post Warehouse Receipt.
        asserterror LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify: Error Message - Item blocked.
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowErrorUnblockSalesRetRcpt()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        // Setup: Create setups, Item and Customer with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        CreateItem(Item);
        CreateLocationSetup(Location, false, true, true);
        UpdateItemInventory(Item."No.", Location.Code);
        CreateCustomer(Customer, Location.Code);

        // Create Sales Return Order setup. Create Warehouse Receipt using Filters to get Source document.
        CreateAndReleaseSalesDocument(
          SalesHeader, SalesHeader."Document Type"::"Return Order", Item."No.", Location.Code, Customer."No.", true);
        UseFiltersToGetSrcDocReceipt(WarehouseReceiptHeader, Customer."No.", '', Location.Code);
        BlockItemForPosting(Item."No.", true);

        // Exercise: Post Warehouse Receipt.
        asserterror LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify: Error Message - Blocked must be 'No' in Item.
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));

        // Exercise: Unblock Item and Post Receipt.
        BlockItemForPosting(Item."No.", false);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify: Verify correct lines have been posted.
        VerifyPostedReceiptLinesSales(WarehouseReceiptHeader."No.", Item."No.", SalesHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowErrorPostSalesReturnOrder()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        Customer: Record Customer;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        // Setup: Create setups, Item, Customer and Vendor with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        CreateItem(Item);
        CreateItem(Item2);
        CreateLocationSetup(Location, false, true, true);
        UpdateItemInventory(Item."No.", Location.Code);
        CreateCustomer(Customer, Location.Code);
        CreateVendor(Vendor, Location.Code);

        // Create Purchase Order and Sales Return Order setup. Create Warehouse Receipt using Filters to get Source document.
        CreateAndReleasePurchDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Item."No.", Location.Code, Vendor."No.", true);
        CreateAndReleaseSalesDocument(
          SalesHeader, SalesHeader."Document Type"::"Return Order", Item2."No.", Location.Code, Customer."No.", true);
        UseFiltersToGetSrcDocReceipt(WarehouseReceiptHeader, Customer."No.", Vendor."No.", Location.Code);
        BlockItemForPosting(Item."No.", true);

        // Exercise: Post Warehouse Receipt.
        asserterror LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify: Error Message - Blocked must be 'No' in Item; and posted Sales Return receipt.
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));
        VerifyPostedReceiptLinesSales(WarehouseReceiptHeader."No.", Item2."No.", SalesHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowErrorPurchSalesRetBlocked()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        Customer: Record Customer;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        // Setup: Create setups, Item, Customer and Vendor with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        CreateItem(Item);
        CreateLocationSetup(Location, false, true, true);
        CreateCustomer(Customer, Location.Code);
        CreateVendor(Vendor, Location.Code);

        // Create Purchase Order and Sales Return Order setup. Create Warehouse Receipt using Filters to get Source document.
        CreateAndReleasePurchDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Item."No.", Location.Code, Vendor."No.", true);
        CreateAndReleaseSalesDocument(
          SalesHeader, SalesHeader."Document Type"::"Return Order", Item."No.", Location.Code, Customer."No.", true);
        UseFiltersToGetSrcDocReceipt(WarehouseReceiptHeader, Customer."No.", Vendor."No.", Location.Code);
        BlockItemForPosting(Item."No.", true);

        // Exercise: Post Warehouse Receipt.
        asserterror LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify: Error Message - Blocked must be 'No' in Item.
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));

        // Verify: Verify nothing is posted.
        VerifyRcptLineNotExist(WarehouseReceiptHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SourceDocMessageHandler')]
    [Scope('OnPrem')]
    procedure ErrNotProcessForPurchSalesRet()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        // Setup: Create setups, Item, Customer and Vendor with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        ReceiptPurchaseSalesReturn(WarehouseReceiptHeader, Item, SalesHeader, PurchaseHeader, false, false);
        // Dimensions removed from Headers.

        // Exercise: Post Warehouse Receipt.
        LibraryWarehouse.PostWhseRcptWithConfirmMsg(WarehouseReceiptHeader."No.");

        // Verify: Verify Message in handler and that nothing is posted.
        VerifyRcptLineNotExist(WarehouseReceiptHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SourceDocMessageHandler')]
    [Scope('OnPrem')]
    procedure ErrNotProcessPostPurchaseOrder()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        // Setup: Create setups, Item, Customer and Vendor with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        ReceiptPurchaseSalesReturn(WarehouseReceiptHeader, Item, SalesHeader, PurchaseHeader, true, false);  // Sales Dimension removed.

        // Exercise: Post Warehouse Receipt.
        LibraryWarehouse.PostWhseRcptWithConfirmMsg(WarehouseReceiptHeader."No.");

        // Verify: Verify Message in handler and Posted receipt.
        VerifyPostedReceiptLinesPurch(WarehouseReceiptHeader."No.", Item."No.", PurchaseHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SourceDocMessageHandler')]
    [Scope('OnPrem')]
    procedure ErrNotProcessPostSalesRetOrder()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        // Setup: Create setups, Item, Customer and Vendor with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        ReceiptPurchaseSalesReturn(WarehouseReceiptHeader, Item, SalesHeader, PurchaseHeader, false, true);  // Purchase Dimension removed.

        // Exercise: Post Warehouse Receipt.
        LibraryWarehouse.PostWhseRcptWithConfirmMsg(WarehouseReceiptHeader."No.");

        // Verify: Verify Message in handler and Posted receipt.
        VerifyPostedReceiptLinesSales(WarehouseReceiptHeader."No.", Item."No.", SalesHeader."No.");

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseShipmentLinesSorting()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        Vendor: Record Vendor;
        Customer: Record Customer;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Index: Integer;
        "Count": Integer;
    begin
        // Setup: Create setups, Item, Customer and Vendor with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        SetupSortingTestData(Item, Location, Customer, Vendor, Count);

        // Create Purchase Order and Sales Return Order setup. Create Warehouse Shipment using Filters to get Source document.
        for Index := 1 to Count do
            CreatePurchaseSetup(
              PurchaseHeader, PurchaseHeader2, PurchaseHeader."Document Type"::"Return Order", Item."No.", Location.Code, Vendor."No.");

        UseFiltersToGetSrcDocShipment(WarehouseShipmentHeader, Customer."No.", Vendor."No.", Location.Code, '');

        // Verify
        VerifyWhseShipmentLineSorting(Item."No.", Count * 2);

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseReceiptLinesSorting()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Customer: Record Customer;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        Index: Integer;
        "Count": Integer;
    begin
        // Setup: Create setups, Item, Customer and Vendor with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        SetupSortingTestData(Item, Location, Customer, Vendor, Count);

        // Create Purchase Order and Sales Return Order setup. Create Warehouse Receipt using Filters to get Source document.
        for Index := 1 to Count do
            CreateAndReleasePurchDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Item."No.", Location.Code, Vendor."No.", true);

        UseFiltersToGetSrcDocReceipt(WarehouseReceiptHeader, Customer."No.", Vendor."No.", Location.Code);

        // Verify
        VerifyWhseReceiptLineSorting(Item."No.", Count);

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseRcptFromPurchDocumentNotCreatedWithItemBlocked()
    var
        Item: Record Item;
        Location: Record Location;
        PurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Warehouse Receipt]
        // [SCENARIO 362752] Action "Create Warehouse Receipt" in purchase order fails if the item in purch. order is blocked

        Initialize();

        // [GIVEN] Create purchase order
        CreateItem(Item);
        CreateLocation(Location, false, false, true);
        CreateAndReleasePurchDocument(
          PurchHeader, PurchHeader."Document Type"::Order, Item."No.", Location.Code, LibraryPurchase.CreateVendorNo(), false);
        // [GIVEN] Set item to "Blocked"
        BlockItemForPosting(Item."No.", true);

        // [WHEN] "Create Warehouse Receipt" action is invoked
        asserterror LibraryWarehouse.CreateWhseReceiptFromPO(PurchHeader);

        // [THEN] Error message: "Blocked must be equal to "No" in Item"
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSourceDocsDoesNotCreateWhseRcptWithItemBlocked()
    var
        Item: Record Item;
        Location: Record Location;
        PurchHeader: Record "Purchase Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        // [FEATURE] [Warehouse Receipt] [Filters to Get Source Documents]
        // [SCENARIO 362752] "Use Filters to get Source Docs" throws error if the source purchase document contains only line with a blocked item

        Initialize();

        // [GIVEN] Create purchase order
        CreateItem(Item);
        CreateLocation(Location, false, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        CreateAndReleasePurchDocument(
          PurchHeader, PurchHeader."Document Type"::Order, Item."No.", Location.Code, LibraryPurchase.CreateVendorNo(), false);
        // [GIVEN] Set item to "Blocked"
        BlockItemForPosting(Item."No.", true);

        // [WHEN] "Filters to Get Source Docs" page is run to create warehouse receipt
        asserterror UseFiltersToGetSrcDocReceipt(WhseReceiptHeader, '', PurchHeader."Buy-from Vendor No.", Location.Code);

        // [THEN] Error message: "There are no Warehouse Receipt Lines created"
        Assert.ExpectedError(NoWhseReceiptLinesCreatedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSourceDocsCreatesWhseRcptWithOneItemBlockedAndOneActive()
    var
        Item: array[2] of Record Item;
        Location: Record Location;
        PurchHeader: Record "Purchase Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        // [FEATURE] [Warehouse Receipt] [Filters to Get Source Documents]
        // [SCENARIO 362752] "Use Filters to get Source Docs" creates warehouse receipt if the source purch. order has two line with different items, one of which is blocked

        Initialize();

        // [GIVEN] Create two items "I1" and "I2"
        CreateItem(Item[1]);
        CreateItem(Item[2]);
        CreateLocation(Location, false, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        // [GIVEN] Create purchase order with two lines, each for a different item
        CreatePurchaseDocument(
          PurchHeader, PurchHeader."Document Type"::Order, Item[1]."No.", Location.Code, LibraryPurchase.CreateVendorNo(), false);
        CreatePurchaseLine(PurchHeader, Item[2]."No.", Location.Code);
        LibraryPurchase.ReleasePurchaseDocument(PurchHeader);

        // [GIVEN] Set item "I2" to "Blocked"
        BlockItemForPosting(Item[2]."No.", true);

        // [WHEN] Run "Filters to Get Source Docs"
        UseFiltersToGetSrcDocReceipt(WhseReceiptHeader, '', PurchHeader."Buy-from Vendor No.", Location.Code);

        // [THEN] Warehouse receipt line for item "I1" is created, no whse. receipt for "I2"
        VerifyWhseReceiptLineCreated(WhseReceiptHeader."No.", Item[1]."No.");
        VerifyWhseReceiptLineNotCreated(WhseReceiptHeader."No.", Item[2]."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseShipFromSalesDocumentNotCreatedWithItemBlocked()
    var
        Item: Record Item;
        BlockedItem: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // [FEATURE] [Warehouse Shipment]
        // [SCENARIO 362752] Action "Create Warehouse Shipment" in sales order fails if at least one item in the sales order is blocked.

        Initialize();

        // [GIVEN] Create sales order with 2 items = "I1" and "I2".
        CreateItem(Item);
        CreateItem(BlockedItem);
        CreateLocation(Location, false, true, false);
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, Item."No.", Location.Code, LibrarySales.CreateCustomerNo(), false);
        CreateSalesLine(SalesHeader, BlockedItem."No.", Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Set item "I2" to "Blocked".
        BlockItemForPosting(BlockedItem."No.", true);

        // [WHEN] "Create Warehouse Shipment" action is invoked.
        Commit();
        asserterror LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [THEN] Error message: "Blocked must be equal to "No" in Item I2".
        Assert.ExpectedTestFieldError(BlockedItem.FieldCaption(Blocked), Format(false));

        // [THEN] Warehouse shipment is not created.
        WarehouseShipmentHeader.SetRange("Location Code", Location.Code);
        Assert.RecordIsEmpty(WarehouseShipmentHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSourceDocsDoesNotCreateWhseShipmentWithItemBlocked()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // [FEATURE] [Warehouse Shipment] [Filters to Get Source Documents]
        // [SCENARIO 362752] "Use Filters to get Source Docs" throws error if the source sales document contains only line with a blocked item

        Initialize();

        // [GIVEN] Create sales order
        CreateItem(Item);
        CreateLocation(Location, false, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        CreateAndReleaseSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, Item."No.", Location.Code, LibrarySales.CreateCustomerNo(), false);
        // [GIVEN] Set item to "Blocked"
        BlockItemForPosting(Item."No.", true);

        // [WHEN] "Filters to Get Source Docs" page is run to create warehouse shipment
        asserterror UseFiltersToGetSrcDocShipment(WhseShipmentHeader, SalesHeader."Sell-to Customer No.", '', Location.Code, '');

        // [THEN] Error message: "There are no Warehouse Shipment Lines created"
        Assert.ExpectedError(NoWhseShipmentLinesCreatedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSourceDocsCreatesWhseShipmentWithOneItemBlockedAndOneActive()
    var
        Item: array[2] of Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // [FEATURE] [Warehouse Shipment] [Filters to Get Source Documents]
        // [SCENARIO 362752] "Use Filters to get Source Docs" creates warehouse shipment if the source sales order has two line with different items, one of which is blocked

        Initialize();

        // [GIVEN] Create two items "I1" and "I2"
        CreateItem(Item[1]);
        CreateItem(Item[2]);
        CreateLocation(Location, false, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        // [GIVEN] Create sales order with two lines, each for a different item
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, Item[1]."No.", Location.Code, LibrarySales.CreateCustomerNo(), false);
        CreateSalesLine(SalesHeader, Item[2]."No.", Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Set item "I2" to "Blocked"
        BlockItemForPosting(Item[2]."No.", true);

        // [WHEN] Run "Filters to Get Source Docs"
        UseFiltersToGetSrcDocShipment(WhseShipmentHeader, SalesHeader."Sell-to Customer No.", '', Location.Code, '');

        // [THEN] Warehouse shipment line for item "I1" is created, no whse. shipment for "I2"
        VerifyWhseShipmentLineCreated(WhseShipmentHeader."No.", Item[1]."No.");
        VerifyWhseShipmentLineNotCreated(WhseShipmentHeader."No.", Item[2]."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdvancedLocationAcceptedInItemReclassJournalSameLocationCode()
    var
        Location: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        xItemJournalLine: Record "Item Journal Line";
        WMSManagement: Codeunit "WMS Management";
    begin
        // [FEATURE] [Item Reclassification]
        // [SCENARIO 377752] It should be possible to enter location with "Directed Put-Away and Pick" in item reclassification journal if "Location Code" = "New Location Code"

        Initialize();

        // [GIVEN] Create location "L" with "Directed Put-Away and Pick" = TRUE
        CreateDirectedPutAwayAndPickLocation(Location);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create item reclassification journal line
        CreateItemReclassificationJournalLine(ItemJournalLine, Item."No.", 0);

        // [GIVEN] Set "Location Code" = "L" in item reclassification journal
        ItemJournalLine.Validate("Location Code", Location.Code);

        // [WHEN] Set = "New Location Code" = "L" in item reclassification journal
        xItemJournalLine := ItemJournalLine;
        ItemJournalLine.Validate("New Location Code", Location.Code);
        WMSManagement.CheckItemJnlLineLocation(ItemJournalLine, xItemJournalLine);

        // [THEN] Value is accepted
        ItemJournalLine.TestField("New Location Code", Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdvancedLocationNotAcceptedInItemReclassJournalDifferentLocationCodes()
    var
        Location: array[2] of Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        xItemJournalLine: Record "Item Journal Line";
        WMSManagement: Codeunit "WMS Management";
    begin
        // [FEATURE] [Item Reclassification]
        // [SCENARIO 377752] It should not be allowed to enter location with "Directed Put-Away and Pick" in item reclassification journal if "Location Code" <> "New Location Code"

        Initialize();

        // [GIVEN] Create 2 locations ("L1" and "L2"), "Directed Put-Away and Pick" = TRUE in both
        CreateDirectedPutAwayAndPickLocation(Location[1]);
        CreateDirectedPutAwayAndPickLocation(Location[2]);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create item reclassification journal line
        CreateItemReclassificationJournalLine(ItemJournalLine, Item."No.", 0);

        // [GIVEN] Set "Location Code" = "L1" in item reclassification journal
        ItemJournalLine.Validate("Location Code", Location[1].Code);

        // [WHEN] Set "New Location Code" = "L2" in item reclassification journal
        xItemJournalLine := ItemJournalLine;
        ItemJournalLine.Validate("New Location Code", Location[2].Code);
        asserterror WMSManagement.CheckItemJnlLineLocation(ItemJournalLine, xItemJournalLine);

        // [THEN] Error is thrown
        Assert.ExpectedError(StrSubstNo(CannotReclassifyLocationErr, Location[1].Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBinErrorInItemReclassJournalAdvancedLocation()
    var
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        xItemJournalLine: Record "Item Journal Line";
        WMSManagement: Codeunit "WMS Management";
    begin
        // [FEATURE] [Item Reclassification] [Bin]
        // [SCENARIO 377752] It should not be allowed to enter bin code in item reclassification journal if location uses "Directed Put-Away and Pick"

        Initialize();

        // [GIVEN] Create location "L" with "Directed Put-Away and Pick" = TRUE
        // [GIVEN] Create item reclassification journal line for location "L"
        CreateReclassificationSetup(ItemJournalLine);
        Location.Get(ItemJournalLine."Location Code");

        // [WHEN] Try to set bin code in reclassification journal
        xItemJournalLine := ItemJournalLine;
        ItemJournalLine.Validate("Bin Code", Location."Receipt Bin Code");
        asserterror WMSManagement.CheckItemJnlLineFieldChange(ItemJournalLine, xItemJournalLine, ItemJournalLine.FieldCaption("Bin Code"));

        // [THEN] Error is thrown
        Assert.ExpectedError(
          StrSubstNo(
            CannotUseLocationErr, ItemJournalLine.FieldCaption("Bin Code"), LowerCase(Location.TableCaption()),
            Location.Code, Location.FieldCaption("Directed Put-away and Pick")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateNewBinErrorInItemReclassJournalAdvancedLocation()
    var
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        xItemJournalLine: Record "Item Journal Line";
        WMSManagement: Codeunit "WMS Management";
    begin
        // [FEATURE] [Item Reclassification] [Bin]
        // [SCENARIO 377752] It should not be allowed to enter new bin code in item reclassification journal if location uses "Directed Put-Away and Pick"

        Initialize();

        // [GIVEN] Create location "L" with "Directed Put-Away and Pick" = TRUE
        // [GIVEN] Create item reclassification journal line for location "L"
        CreateReclassificationSetup(ItemJournalLine);
        Location.Get(ItemJournalLine."Location Code");

        // [WHEN] Try to set new bin code in reclassification journal
        xItemJournalLine := ItemJournalLine;
        ItemJournalLine.Validate("New Bin Code", Location."Shipment Bin Code");
        asserterror
          WMSManagement.CheckItemJnlLineFieldChange(ItemJournalLine, xItemJournalLine, ItemJournalLine.FieldCaption("New Bin Code"));

        // [THEN] Error is thrown
        Assert.ExpectedError(
          StrSubstNo(
            CannotUseLocationErr, ItemJournalLine.FieldCaption("New Bin Code"), LowerCase(Location.TableCaption()),
            Location.Code, Location.FieldCaption("Directed Put-away and Pick")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionReclassifiedInItemReclassJournalOnAdvancedLocation()
    var
        Location: Record Location;
        Item: Record Item;
        GeneralLedgerSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
        DimensionValue: array[2] of Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Item Reclassification] [Dimension]
        // [SCENARIO 377752] It should be possible to reclassify item ledger entry on a "directed put-away and pick" location via item reclassification journal

        Initialize();

        // [GIVEN] Create location "L" with directed put-away and pick
        CreateFullWMSLocation(Location, 1);

        // [GIVEN] Create item "I" with defaul global dimension 1 value = "D1"
        LibraryInventory.CreateItem(Item);
        GeneralLedgerSetup.Get();
        Dimension.Get(GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue[1], Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], Dimension.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Item, Item."No.", Dimension.Code, DimensionValue[1].Code);

        // [GIVEN] Post positive adjustment of "X" pcs of item "I" on location "L".
        Quantity := LibraryRandom.RandInt(100);
        PostPositiveAdjustmentOnWarehouse(Location, Item, Quantity);

        // [GIVEN] Create item reclassification journal line. Item = "I", Location = "L", Shortcut Dimension 1 Code = "D1", New Shortcut Dimension 1 Code = "D2"
        CreateItemReclassificationJournalLine(ItemJournalLine, Item."No.", Quantity);
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        ItemJournalLine.Validate("New Shortcut Dimension 1 Code", DimensionValue[2].Code);
        ItemJournalLine.Modify(true);

        // [WHEN] Post item reclassification journal
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Item Inventory with dimension value "D1" = 0, Item Inventory with dimension value "D2" = "X"
        VerifyItemInventory(Item."No.", Location.Code, DimensionValue[1].Code, 0);
        VerifyItemInventory(Item."No.", Location.Code, DimensionValue[2].Code, Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure WhsePickReallocatedNonSpecificInventoryReservation()
    var
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: array[2] of Code[20];
        LotQty: Integer;
    begin
        // [FEATURE] [Item Tracking] [Reservation] [Late Binding] [Warehouse] [Pick]
        // [SCENARIO 378082] Non-specific reservation on inventory should be reallocated when posting warehouse pick

        Initialize();

        // [GIVEN] Item with lot warehouse tracking
        CreateShipPickLocation(Location);
        CreateItemWithLotWarehouseTracking(Item);

        // [GIVEN] Post inventory stock in two lots: "L1" and "L2", quantity in each lot is "X"
        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();
        LotQty := LibraryRandom.RandIntInRange(100, 200);
        CreateItemJournalLine(ItemJournalLine, Item."No.", Location.Code, LotQty * 2);
        AssignLotNoToItemJournalLine(ItemJournalLine, LotNo[1], LotQty);
        AssignLotNoToItemJournalLine(ItemJournalLine, LotNo[2], LotQty);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create sales order "S1", quantity = "X" and run autoreserve. Non-specific reservation created for lot "L1"
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LotQty, Location.Code);
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [GIVEN] Create second sales order "S2", quantity = "X"
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LotQty, Location.Code);

        // [GIVEN] Create warehouse pick from sales order "S2" and set Lot No. = "L1"
        CreateWhsePickFromSalesOrder(SalesHeader);
        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityLine.ModifyAll("Lot No.", LotNo[1]);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");

        // [WHEN] Post warehouse pick
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] "X" pcs are picked
        // [THEN] Reservation for sales order "S1" is reallocated - lot "L2" is reserved
        VerifyPickedQuantity(Item."No.", LotQty);
        VerifyReservedLotNo(Item."No.", LotNo[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotUpdateShipmentDateInSalesLineWhseShipmentExists()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Warehouse Shipment] [Shipment Date]
        // [SCENARIO 380672] Shipment date cannot be updated in a sales line if there is a warehouse shipment for this line

        Initialize();

        // [GIVEN] Location with "Require Shipment"
        // [GIVEN] Create sales order and warehouse shipment
        CreateSalesOrderWithWarehouseShipment(SalesHeader, SalesLine);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Modify shipment date in the sales line
        asserterror SalesLine.Validate("Shipment Date", SalesLine."Shipment Date" + LibraryRandom.RandInt(10));

        // [THEN] Error: Shipment date must not be changed when a warehouse shipment line exists
        Assert.ExpectedError(ShipmentDateMustNotChangeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanUpdateShipmentDateInSalesLineNoWhseShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NewShipmentDate: Date;
    begin
        // [FEATURE] [Warehouse Shipment] [Shipment Date]
        // [SCENARIO 380672] Shipment date in a sales line can be updated if there is no warehouse shipment for this line

        Initialize();

        // [GIVEN] Location with "Require Shipment"
        // [GIVEN] Create sales order without related warehouse shipment
        CreateSalesOrderWithWarehouseShipment(SalesHeader, SalesLine);

        // [WHEN] Modify shipment date in the sales line
        NewShipmentDate := SalesLine."Shipment Date" + LibraryRandom.RandInt(10);
        SalesLine.Validate("Shipment Date", NewShipmentDate);

        // [THEN] Shipment date is updated
        SalesLine.TestField("Shipment Date", NewShipmentDate);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesAssignSeveralLotsPageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayFromPostedWhseRcptTakesLotNoFromUnhandledTrackingLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        LotNos: array[2] of Code[20];
        LotQty: array[2] of Integer;
    begin
        // [FEATURE] [Item Tracking] [Put-Away]
        // [SCENARIO 277222] Put-away created from a posted warehouse receipt inherits lot no. from unhandled tracking line of the source document, when another posted receipt withe the same lot exists

        Initialize();

        // [GIVEN] Item "I" tracked by lot number
        CreateItemWithLotWarehouseTracking(Item);
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);

        LotNos[1] := LibraryUtility.GenerateGUID();
        LotNos[2] := LibraryUtility.GenerateGUID();
        LotQty[1] := LibraryRandom.RandInt(10);
        LotQty[2] := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Purchase order for 10 pcs of item "I" on a "directed put-away and pick" location.
        // [GIVEN] Assign two item tracking lines: 6 pcs with lot "L1", and 4 pcs - lot "L2", post warehouse receipt
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue(LotNos[1]);
        LibraryVariableStorage.Enqueue(LotQty[1]);
        LibraryVariableStorage.Enqueue(LotNos[2]);
        LibraryVariableStorage.Enqueue(LotQty[2]);
        CreateTrackedPurchOrderPostWhseReceipt(PurchaseHeader, PurchaseLine, Location.Code, Item."No.", LotQty[1] + LotQty[2]);
        FindPostedWhseReceiptLine(PostedWhseReceiptLine, PurchaseLine);

        // [GIVEN] Put away 6 pcs with lot "L1", do not handle lot "L2".
        SetQtyToHandleOnWhseActivityLine(
          DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", LotNos[1], LotQty[1]);
        SetQtyToHandleOnWhseActivityLine(DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", LotNos[2], 0);
        LibraryWarehouse.FindWhseActivityBySourceDoc(
          WarehouseActivityHeader, DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", PurchaseLine."Line No.");

        // [GIVEN] Delete the partially posted put-away document.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        WarehouseActivityHeader.Find();
        WarehouseActivityHeader.Delete(true);

        // [GIVEN] Create and put-away another purchase order for 10 pcs of item "I" with the same lot no. "L1"
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(LotNos[1]);
        LibraryVariableStorage.Enqueue(LotQty[1]);
        CreateTrackedPurchOrderPostWhseReceipt(PurchaseHeader, PurchaseLine, Location.Code, Item."No.", LotQty[1]);

        // [WHEN] Create put-away from the posted warehouse receipt
        CreatePutAwayFromPostedWhseRcpt(WarehouseActivityLine, PostedWhseReceiptLine);

        // [THEN] Put-away line created for 4 pcs of lot "L2"
        WarehouseActivityLine.TestField("Lot No.", LotNos[2]);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesAssignLotPageHandler')]
    [Scope('OnPrem')]
    procedure LotTrackedAndNonTrackedItemsPickedInOneWarehousePick()
    var
        Location: Record Location;
        Item: Record Item;
        TrackedItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Code[50];
        StockQty: Integer;
    begin
        // [FEATURE] [Item Tracking] [Bin Content]
        // [SCENARIO 269846] Lot tracked item and item without tracking can be picked in one warehouse pick
        Initialize();

        CreateFullWMSLocation(Location, 2);

        // [GIVEN] Two items: "I1" tracked by lot no., and "I2" without item tracking
        CreateItemWithLotWarehouseTracking(TrackedItem);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] 10 pcs of each item on WHITE location
        StockQty := 10;
        LotNo := LibraryUtility.GenerateGUID();
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(Item."No.", Location.Code, StockQty, false);
        UpdateInventoryOnDirectedPutAwayPickLocationTrackedItem(TrackedItem."No.", Location.Code, StockQty, LotNo);

        // [GIVEN] Sales order with 2 lines: first for 5 pcs of item "I1", second - 5 pcs of item "I2"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLine(SalesHeader, TrackedItem."No.", Location.Code);
        CreateSalesLine(SalesHeader, Item."No.", Location.Code);

        // [GIVEN] Create warehouse shipment and pick from the sales order
        CreateWhsePickFromSalesOrder(SalesHeader);
        SelectSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", TrackedItem."No.");
        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityLine.ModifyAll("Lot No.", LotNo);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");

        // [WHEN] Register warehouse pick
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Both items are successfully picked
        VerifyWhseShipmentCompletelyPicked(SalesHeader."Document Type".AsInteger(), SalesHeader."No.", Item."No.");
        VerifyWhseShipmentCompletelyPicked(SalesHeader."Document Type".AsInteger(), SalesHeader."No.", TrackedItem."No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesAssignSeveralLotsPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        NoOfLots: Integer;
        I: Integer;
    begin
        NoOfLots := LibraryVariableStorage.DequeueInteger();
        for I := 1 to NoOfLots do begin
            ItemTrackingLines.New();
            ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
            ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesAssignSerialNoPageHandler')]
    [Scope('OnPrem')]
    procedure SNTrackedAndNonTrackedItemsPickedInOneWarehousePick()
    var
        Location: Record Location;
        Item: Record Item;
        TrackedItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SerialNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Bin Content]
        // [SCENARIO 269846] Serial No. tracked item and item without tracking can be picked in one warehouse pick

        Initialize();

        CreateFullWMSLocation(Location, 2);

        // [GIVEN] Two items: "I1" tracked by serial no., and "I2" without item tracking
        CreateItemWithSNWarehouseTracking(TrackedItem);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Both items are in stock on WHITE location
        SerialNo := LibraryUtility.GenerateGUID();
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(Item."No.", Location.Code, 1, false);
        UpdateInventoryOnDirectedPutAwayPickLocationTrackedItem(TrackedItem."No.", Location.Code, 1, SerialNo);

        // [GIVEN] Sales order with 2 lines: first for item "I1", second for item "I2"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader, SalesLine[1].Type::Item, TrackedItem."No.", 1);
        SalesLine[1].Validate("Location Code", Location.Code);
        SalesLine[1].Modify(true);

        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader, SalesLine[2].Type::Item, Item."No.", 1);
        SalesLine[2].Validate("Location Code", Location.Code);
        SalesLine[2].Modify(true);

        // [GIVEN] Create warehouse shipment and pick from the sales order
        CreateWhsePickFromSalesOrder(SalesHeader);
        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesLine[1]."Document Type".AsInteger(), SalesLine[1]."Document No.", SalesLine[1]."Line No.");
        WarehouseActivityLine.ModifyAll("Serial No.", SerialNo);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");

        // [WHEN] Register warehouse pick
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Both items are successfully picked
        VerifyWhseShipmentCompletelyPicked(SalesHeader."Document Type".AsInteger(), SalesHeader."No.", Item."No.");
        VerifyWhseShipmentCompletelyPicked(SalesHeader."Document Type".AsInteger(), SalesHeader."No.", TrackedItem."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandlerWithMessageVerification')]
    [Scope('OnPrem')]
    procedure OrderToOrderBindingIsRemovedWhenRegisterPickFromInventory()
    var
        Location: Record Location;
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: array[4] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Reservation] [Item Tracking] [Pick] [Binding] [Sales]
        // [SCENARIO 275280] Order-to-order reservation between sales order and its supply is deleted, when a user sets item tracking for a sales line directly on the warehouse pick and registers it.
        Initialize();

        // [GIVEN] Location set up for required shipment and pick.
        // [GIVEN] Lot-tracked item "I" with reordering policy = "Order".
        CreateShipPickLocation(Location);
        CreateLotTrackedItemWithOrderReorderingPolicy(Item);
        for i := 1 to 4 do
            LotNo[i] := LibraryUtility.GenerateGUID();

        // [GIVEN] Post the inventory adjustment for 100 PCS of lots "L1" and "L2".
        for i := 1 to 2 do
            CreateItemStockWithLot(Location.Code, Item."No.", LotNo[i], LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Sales order with 2 lines - each for 50 PCS of item "I".
        CreateSalesOrderWithTwoLines(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandIntInRange(50, 100), Location.Code);

        // [GIVEN] Create a warehouse shipment and a warehouse pick from the sales order.
        // [GIVEN] Set Lot No. = "L1" on the first pick line and Lot No. = "L2" on the second pick line.
        CreateWhsePickFromSalesOrder(SalesHeader);
        for i := 1 to 2 do begin
            FindWarehouseActivityLine(
              WarehouseActivityLine,
              DATABASE::"Sales Line", SalesLine[i]."Document Type".AsInteger(), SalesLine[i]."Document No.", SalesLine[i]."Line No.");
            WarehouseActivityLine.ModifyAll("Lot No.", LotNo[i]);
        end;
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");

        // [GIVEN] Calculate plan on requisition worksheet for item "I".
        // [GIVEN] Set item tracking on the requisition lines - lot nos. "L3" and "L4".
        // [GIVEN] Carry out action in order to create a supplying purchase order for the sales order.
        // [GIVEN] An order-to-order binding is now established between the sales and the purchase.
        LibraryPlanning.CalcRequisitionPlanForReqWkshAndGetLines(RequisitionLine, Item, WorkDate(), WorkDate());
        for i := 3 to 4 do begin
            LibraryVariableStorage.Enqueue(LotNo[i]);
            LibraryVariableStorage.Enqueue(RequisitionLine.Quantity);
            RequisitionLine.OpenItemTrackingLines();
            RequisitionLine.Next();
        end;
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');

        // [WHEN] Register the warehouse pick with earlier defined item tracking.
        for i := 1 to 2 do begin
            LibraryVariableStorage.Enqueue(OrderToOrderBindingOnSalesLineQst);
            LibraryVariableStorage.Enqueue(true);
        end;
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] A confirmation message that warns of an order-to-order binding being removed is raised.

        // [THEN] Despite two lines in the sales order, the confirmation is raised only once.
        Assert.AreEqual(
          OrderToOrderBindingOnSalesLineQst, LibraryVariableStorage.DequeueText(), 'A confirmation message has not been raised only once.');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'A confirmation message has not been raised only once.');

        // [THEN] The sales order lines are now reserved from the inventory. Lot nos. = "L1" and "L2".
        for i := 1 to 2 do
            VerifySalesReservationFromInventory(SalesLine[i], LotNo[i]);

        // [THEN] Lots "L3" and "L4" are now in a surplus for the purchase.
        PurchaseLine.SetRange("No.", Item."No.");
        PurchaseLine.FindSet();
        for i := 3 to 4 do begin
            VerifyPurchaseSurplusReservEntry(PurchaseLine, LotNo[i]);
            PurchaseLine.Next();
        end;

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandlerWithMessageVerification')]
    [Scope('OnPrem')]
    procedure RegisteringPickInterruptedWhenRemovingBindingIsNotConfirmed()
    var
        Location: Record Location;
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        LotNo: array[2] of Code[20];
    begin
        // [FEATURE] [Reservation] [Item Tracking] [Pick] [Binding] [Sales]
        // [SCENARIO 275280] Registering of warehouse pick for sales order is interrupted, when a user chooses not to break existing order-to-order binding on registering the pick.
        Initialize();

        // [GIVEN] Location set up for required shipment and pick.
        // [GIVEN] Lot-tracked item "I" with reordering policy = "Order".
        CreateShipPickLocation(Location);
        CreateLotTrackedItemWithOrderReorderingPolicy(Item);
        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();

        // [GIVEN] Post the inventory adjustment for 100 PCS of lot "L1".
        CreateItemStockWithLot(Location.Code, Item."No.", LotNo[1], LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Sales order for 50 PCS of item "I".
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandIntInRange(50, 100), Location.Code);

        // [GIVEN] Create a warehouse shipment and a warehouse pick from the sales order.
        // [GIVEN] Set Lot No. = "L1" on the pick line.
        CreateWhsePickFromSalesOrder(SalesHeader);
        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityLine.ModifyAll("Lot No.", LotNo[1]);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");

        // [GIVEN] Calculate plan on requisition worksheet for item "I".
        // [GIVEN] Set item tracking on the requisition lines - lot no. "L2".
        // [GIVEN] Carry out action in order to create a supplying purchase order for the sales order.
        // [GIVEN] An order-to-order binding is now established between the sales and the purchase.
        LibraryPlanning.CalcRequisitionPlanForReqWkshAndGetLines(RequisitionLine, Item, WorkDate(), WorkDate());
        LibraryVariableStorage.Enqueue(LotNo[2]);
        LibraryVariableStorage.Enqueue(RequisitionLine.Quantity);
        RequisitionLine.OpenItemTrackingLines();
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');

        // [WHEN] Register the warehouse pick but do not confirm deleting the reservation between the sales and the purchase.
        Commit();
        LibraryVariableStorage.Enqueue(OrderToOrderBindingOnSalesLineQst);
        LibraryVariableStorage.Enqueue(false);
        asserterror LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] An error message reads that the registering pick is interrupted.
        Assert.ExpectedError(RegisterInterruptedErr);

        // [THEN] Nothing is picked.
        VerifyPickedQuantity(Item."No.", 0);

        // [THEN] No registered pick is created.
        RegisteredWhseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(RegisteredWhseActivityLine);

        // [THEN] "Qty. Handled" on the outstanding pick line is equal to 0.
        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityLine.TestField("Qty. Handled", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesSetLotNoAndSerialNoPageHandler')]
    [Scope('OnPrem')]
    procedure NoAvailabilityWarningsAppearWhenRefreshingAvailability()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        LotNo: Code[50];
        SerialNo: array[2] of Code[50];
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Serial No.] [Lot No.] [Avail. - Item Tracking Lines] [Sales]
        // [SCENARIO 285817] No avaliability warnings appear when invoke Refresh Avaliability on Item Tracking Page and specific serial is avaliable
        Initialize();

        // [GIVEN] Create Location
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Item Tracking Code
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, true);

        // [GIVEN] Create Item and with created before Item Tracking Code
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        // [GIVEN] Create 2pcs stock for the Item: single lot and 2 serial numbers
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', 2);
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(ArrayLen(SerialNo));
        for i := 1 to ArrayLen(SerialNo) do begin
            LibraryVariableStorage.Enqueue(LotNo);
            SerialNo[i] := LibraryUtility.GenerateGUID();
            LibraryVariableStorage.Enqueue(SerialNo[i]);
        end;
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create another sales order for Item, Qty = 1
        CreateSalesDocumentWithLine(SalesLine, Item."No.", Location.Code, 1);

        // [WHEN] Open Item Tracking Page, create a new line with serial #1
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SerialNo[1]);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Create another sales order for Item, Qty = 1
        CreateSalesDocumentWithLine(SalesLine, Item."No.", Location.Code, 1);

        // [WHEN] Open Item Tracking Page, create a new line with serial #2
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SerialNo[2]);
        SalesLine.OpenItemTrackingLines();

        // [THEN] Serial #2 is avaliable.
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), WrongMessageTextErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure OrderToOrderReservFromInventoryNotDeletedOnRegisterPick()
    var
        Location: Record Location;
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Reservation] [Item Tracking] [Pick] [Binding] [Sales]
        // [SCENARIO 337082] Registering of warehouse pick for sales order is not interrupted when the item being picked is order-to-order reserved from inventory.
        Initialize();

        // [GIVEN] Location set up for required shipment and pick.
        // [GIVEN] Lot-tracked item with reordering policy = "Order".
        CreateShipPickLocation(Location);
        CreateLotTrackedItemWithOrderReorderingPolicy(Item);

        // [GIVEN] Sales order for 50 PCS.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandIntInRange(50, 100), Location.Code);

        // [GIVEN] Calculate plan on requisition worksheet.
        // [GIVEN] Set item tracking on the requisition line.
        // [GIVEN] Carry out action in order to create a supplying purchase order for the sales order.
        // [GIVEN] An order-to-order binding is now established between the sales and the purchase.
        LibraryPlanning.CalcRequisitionPlanForReqWkshAndGetLines(RequisitionLine, Item, WorkDate(), WorkDate());
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(RequisitionLine.Quantity);
        RequisitionLine.OpenItemTrackingLines();
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');

        // [GIVEN] Post the newly created purchase order.
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", Item."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create a warehouse shipment and a warehouse pick from the sales order.
        CreateWhsePickFromSalesOrder(SalesHeader);
        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");

        // [WHEN] Post the warehouse pick.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] 50 PCS have been picked without any confirmation message.
        VerifyPickedQuantity(Item."No.", SalesLine.Quantity);

        // [THEN] The warehouse shipment can be successfully posted.
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
            DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesAssignLotPageHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure ReallocationReservAccordingToItemTrackingDefinedInPick()
    var
        Location: Record Location;
        Zone: Record Zone;
        Bin: array[3] of Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        LotNos: array[3] of Code[20];
    begin
        // [FEATURE] [Late Binding] [Item Tracking] [Reservation] [Pick] [Cross-Dock] [Order Tracking]
        // [SCENARIO 357411] Reservation is reallocated according to item tracking defined in pick for item with enabled Order Tracking.
        Initialize();
        LotNos[1] := LibraryUtility.GenerateGUID();
        LotNos[2] := LibraryUtility.GenerateGUID();
        LotNos[3] := LibraryUtility.GenerateGUID();

        // [GIVEN] Location set up for directed put-away and pick.
        CreateFullWMSLocation(Location, 2);

        // [GIVEN] Lot-tracked item with enabled Order Tracking.
        CreateItemWithLotWarehouseTracking(Item);
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);

        // [GIVEN] Post 12 pcs of lot "L1" to bin "B1". Resulting item ledger entry "ILE1".
        // [GIVEN] Post 28 pcs of lot "L2" to cross-dock bin "B2". Resulting item ledger entry "ILE2".
        // [GIVEN] Post 10 pcs of lot "L3" to bin "B3". Resulting item ledger entry "ILE3".
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin[1], Location.Code, Zone.Code, 1);
        Bin[2].Get(Location.Code, Location."Cross-Dock Bin Code");
        LibraryWarehouse.FindBin(Bin[3], Location.Code, Zone.Code, 2);
        UpdateInventoryOnBinAtDirectedPutAwayPickLocationTrackedItem(Bin[1], Item."No.", 12, LotNos[1]);
        UpdateInventoryOnBinAtDirectedPutAwayPickLocationTrackedItem(Bin[2], Item."No.", 28, LotNos[2]);
        UpdateInventoryOnBinAtDirectedPutAwayPickLocationTrackedItem(Bin[3], Item."No.", 10, LotNos[3]);

        // [GIVEN] Sales order with three lines.
        // [GIVEN] Line 1: 10 pcs, reserved from item entry "ILE1".
        // [GIVEN] Line 2: 10 pcs of which 2 pcs reserved from "ILE1", 8 pcs reserved from "ILE2".
        // [GIVEN] Line 3: 28 pcs of which 20 pcs reserved from "ILE2", 8 pcs reserved from "ILE3".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 28);
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [GIVEN] Create shipment and pick from the sales order.
        CreateWhsePickFromSalesOrder(SalesHeader);

        // [GIVEN] Since quantity in the cross-dock bin "B2" must be picked first, assign the item tracking as follows:
        // [GIVEN] 28 pcs of lot "L2" (stored in the cross-dock bin) must be reserved for lines 1, 2 of the sales order and partially for line 3.
        // [GIVEN] 10 pcs of lot "L1" must be reserved for line 3.
        // [GIVEN] 10 pcs of lot "L3" must be reserved for line 3.
        UpdateItemTrackingOnWarehouseActivityLines(Item."No.", Bin[1].Code, LotNos[1]);
        UpdateItemTrackingOnWarehouseActivityLines(Item."No.", Bin[2].Code, LotNos[2]);
        UpdateItemTrackingOnWarehouseActivityLines(Item."No.", Bin[3].Code, LotNos[3]);

        // [GIVEN] Autofill qty. to handle in the pick.
        LibraryWarehouse.FindWhseActivityBySourceDoc(
          WarehouseActivityHeader, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [WHEN] Register the warehouse pick.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Lots "L2" and "L3" are fully reserved; lot "L1" is reserved for 10 pcs and tracked for 2 pcs (order tracking is on).
        VerifyReservationEntryLotQty(DATABASE::"Item Ledger Entry", LotNos[1], 12);
        VerifyReservationEntryLotQty(DATABASE::"Item Ledger Entry", LotNos[2], 28);
        VerifyReservationEntryLotQty(DATABASE::"Item Ledger Entry", LotNos[3], 10);

        // [THEN] All three sales lines are reserved.
        VerifyReservationEntryLotQty(DATABASE::"Sales Line", LotNos[1], -10);
        VerifyReservationEntryLotQty(DATABASE::"Sales Line", LotNos[2], -28);
        VerifyReservationEntryLotQty(DATABASE::"Sales Line", LotNos[3], -10);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReallocateNonSpecificReservEntriesToAvailableItemLedgEntries()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LotNos: array[3] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Late Binding] [Item Tracking] [Reservation]
        // [SCENARIO 367069] Reallocate non-specific reservation entries to available item ledger entries.
        Initialize();
        LotNos[1] := LibraryUtility.GenerateGUID();
        LotNos[2] := LibraryUtility.GenerateGUID();
        LotNos[3] := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Lot-tracked item.
        // [GIVEN] Post three lots "L1", "L2", "L3" to inventory. Quantity of each lot = 1 pc.
        LibraryItemTracking.CreateLotItem(Item);
        CreateItemStockWithLot('', Item."No.", LotNos[1], Qty);
        CreateItemStockWithLot('', Item."No.", LotNos[2], Qty);
        CreateItemStockWithLot('', Item."No.", LotNos[3], Qty);

        // [GIVEN] Create and auto-reserve sales order for 2 pcs.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 2 * Qty, '');
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [GIVEN] Lots "L1" and "L2" are reserved from inventory.
        VerifyReservationEntryLotQty(DATABASE::"Item Ledger Entry", LotNos[1], Qty);
        VerifyReservationEntryLotQty(DATABASE::"Item Ledger Entry", LotNos[2], Qty);

        // [GIVEN] Create second sales order for 1 pc.
        // [GIVEN] Assign lot no. "L1" to the sales line.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Qty, '');
        LibraryVariableStorage.Enqueue(LotNos[1]);
        LibraryVariableStorage.Enqueue(Qty);
        SalesLine.OpenItemTrackingLines();

        // [WHEN] Post the second sales order.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] The sales order is shipped.
        SalesLine.Find();
        SalesLine.TestField("Quantity Shipped", Qty);

        // [THEN] The reservation is reallocated - now lots "L2" and "L3" are reserved from inventory.
        VerifyReservationEntryLotQty(DATABASE::"Item Ledger Entry", LotNos[2], Qty);
        VerifyReservationEntryLotQty(DATABASE::"Item Ledger Entry", LotNos[3], Qty);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesAssignLotPageHandler,ConfirmHandlerTrue')]
    procedure FailedAttemptToReallocateReservEntriesLocatesIssue()
    var
        Location: Record Location;
        BinContent: Record "Bin Content";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Reservation] [Item Tracking] [Late Binding] [Pick]
        // [SCENARIO 406879] Failed attempt to reallocate reservation entries must provide specifics to locate the issue.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Location set up for directed put-away and pick.
        CreateFullWMSLocation(Location, 2);

        // [GIVEN] Lot-tracked item.
        CreateItemWithLotWarehouseTracking(Item);

        // [GIVEN] Post 80 pcs to the location, assign lot no. "L".
        UpdateInventoryOnDirectedPutAwayPickLocationTrackedItem(Item."No.", Location.Code, 4 * Qty, LotNo);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.FindFirst();

        // [GIVEN] Sales order "1" for 40 pcs, reserve.
        CreateSalesDocumentWithLine(SalesLine, Item."No.", Location.Code, 2 * Qty);
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [GIVEN] Sales order "2" for 20 pcs, reserve.
        // [GIVEN] Create warehouse shipment and pick from the sales order.
        CreateSalesDocumentWithLine(SalesLine, Item."No.", Location.Code, Qty);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.AutoReserveSalesLine(SalesLine);
        CreateWhsePickFromSalesOrder(SalesHeader);

        // [GIVEN] Register negative adjustment for 60 pcs from the location using warehouse journal.
        // [GIVEN] Note the warning of disrupted reservation entries.
        PostNegativeAdjustmentOnWarehouse(Location.Code, BinContent."Bin Code", Item."No.", LotNo, 3 * Qty);

        // [GIVEN] Locate the warehouse pick for the sales order "2", select lot "L" on the lines.
        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityLine.ModifyAll("Lot No.", LotNo);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");

        // [WHEN] Try to register the pick.
        asserterror LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] An error message is thrown reading that lot "L" is not available on inventory.
        Assert.ExpectedError(
          StrSubstNo(
            'Lot No. %1 is not available on inventory or it has already been reserved for another document.', LotNo));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesAssignSerialNoPageHandler')]
    [Scope('OnPrem')]
    procedure ValidateSerialNoAsBarcodeOnWarehousePick()
    var
        Location: Record Location;
        TrackedItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ScanWarehouseActivityLine: Codeunit "Scan Warehouse Activity Line";
        SerialNo: Code[10];
    begin
        // [FEATURE] [Item Tracking] [Validate Barcode] [Warehouse Pick]
        // [SCENARIO] Validating Serial No. tracked item and item without tracking can be picked in one warehouse pick

        Initialize();

        CreateFullWMSLocation(Location, 2);

        // [GIVEN] Items "I1" tracked by serial no.
        CreateItemWithSNWarehouseTracking(TrackedItem);

        // [GIVEN] Item is in stock on WHITE location
        SerialNo := LibraryUtility.GenerateGUID();
        UpdateInventoryOnDirectedPutAwayPickLocationTrackedItem(TrackedItem."No.", Location.Code, 1, SerialNo);

        // [GIVEN] Sales order with 1 line for item "I1"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, TrackedItem."No.", 1);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        // [GIVEN] Create warehouse shipment and pick from the sales order
        CreateWhsePickFromSalesOrder(SalesHeader);
        FindWarehouseActivityLine(WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityLine.ModifyAll("Qty. to Handle", 0);
        WarehouseActivityLine.FindSet();

        // [GIVEN] Ensure Serial No. is set to empty and "Qty. to Handle" is 0
        WarehouseActivityLine.TestField("Serial No.", '');
        WarehouseActivityLine.TestField("Qty. to Handle", 0);

        // [WHEN] SerialNo is passed to the ValidateBarcode method
        ScanWarehouseActivityLine.ValidateBarcode(WarehouseActivityLine, SerialNo);

        // [THEN] SerialNo is validated as barcode
        WarehouseActivityLine.TestField("Serial No.", SerialNo);
        // [THEN] "Qty. to Handle" field is incremented by 1
        WarehouseActivityLine.TestField("Qty. to Handle", 1);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesAssignLotPageHandler')]
    [Scope('OnPrem')]
    procedure ValidateLotNoAsBarcodeOnWarehousePick()
    var
        Location: Record Location;
        TrackedItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ScanWarehouseActivityLine: Codeunit "Scan Warehouse Activity Line";
        LotNo: Code[10];
    begin
        // [FEATURE] [Item Tracking] [Validate Barcode] [Warehouse Pick]
        // [SCENARIO] Validating Lot No. tracked item and item without tracking can be picked in one warehouse pick

        Initialize();

        CreateFullWMSLocation(Location, 2);

        // [GIVEN] Item "I1" tracked by lot no.
        CreateItemWithLotWarehouseTracking(TrackedItem);

        // [GIVEN] Both items are in stock on WHITE location
        LotNo := LibraryUtility.GenerateGUID();
        UpdateInventoryOnDirectedPutAwayPickLocationTrackedItem(TrackedItem."No.", Location.Code, 5, LotNo);

        // [GIVEN] Sales order with 1 line for item "I1"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, TrackedItem."No.", 5);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        // [GIVEN] Create warehouse shipment and pick from the sales order
        CreateWhsePickFromSalesOrder(SalesHeader);
        FindWarehouseActivityLine(WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityLine.ModifyAll("Qty. to Handle", 0);
        WarehouseActivityLine.FindSet();

        // [GIVEN] Ensure Lot No. is set to empty and "Qty. to Handle" is 0
        WarehouseActivityLine.TestField("Lot No.", '');
        WarehouseActivityLine.TestField("Qty. to Handle", 0);

        // [WHEN] LotNo is passed to the ValidateBarcode method
        ScanWarehouseActivityLine.ValidateBarcode(WarehouseActivityLine, LotNo);

        // [THEN] LotNo is validated as barcode
        WarehouseActivityLine.TestField("Lot No.", LotNo);
        // [THEN] "Qty. to Handle" field is incremented by 1
        WarehouseActivityLine.TestField("Qty. to Handle", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateGTINAsBarcodeOnWarehousePick()
    var
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ScanWarehouseActivityLine: Codeunit "Scan Warehouse Activity Line";
        GTIN: Code[10];
    begin
        // [FEATURE] [Item Tracking] [Validate Barcode] [Warehouse Pick]
        // [SCENARIO] Validating GTIN to pick in warehouse pick
        Initialize();

        CreateFullWMSLocation(Location, 2);

        // [GIVEN] Item "I1" without item tracking
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Set GTIN on the item
        GTIN := LibraryUtility.GenerateGUID();
        Item.Validate(GTIN, GTIN);
        Item.Modify(true);

        // [GIVEN] Item is in stock on WHITE location
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(Item."No.", Location.Code, 5, false);

        // [GIVEN] Sales order with 1 line for item "I1"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 5);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        // [GIVEN] Create warehouse shipment and pick from the sales order
        CreateWhsePickFromSalesOrder(SalesHeader);
        FindWarehouseActivityLine(WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityLine.ModifyAll("Qty. to Handle", 0);
        WarehouseActivityLine.FindSet();

        // [GIVEN] Ensure "Qty. to Handle" is 0
        WarehouseActivityLine.TestField("Qty. to Handle", 0);

        // [WHEN] GTIN is passed to the ValidateBarcode method
        ScanWarehouseActivityLine.ValidateBarcode(WarehouseActivityLine, GTIN);

        // [THEN] "Qty. to Handle" field is incremented by 1
        WarehouseActivityLine.TestField("Qty. to Handle", 1);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesAssignMultipleSerialNoPageHandler')]
    [Scope('OnPrem')]
    procedure ScanningSetsNextUnfulfilledAsTheCurrentRecordAfterASuccessfulScan()
    var
        Location: Record Location;
        TrackedItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ScanWarehouseActivityLine: Codeunit "Scan Warehouse Activity Line";
        SerialNos: Array[5] of Code[10];
        SkippedLines: Array[4] of Integer;
        NeedsRefresh: Boolean;
        AllLinesAreDone: Boolean;
    begin
        // [FEATURE] [Item Tracking] [Validate Barcode] [Warehouse Pick]
        // [SCENARIO] Scanning sets next unfulfilled as the current record after a successful scan

        Initialize();

        CreateFullWMSLocation(Location, 2);

        // [GIVEN] Item "I1" tracked by Serial No.
        CreateItemWithSNWarehouseTracking(TrackedItem);

        // [GIVEN] Both items are in stock on WHITE location. 
        SerialNos[1] := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(SerialNos[1]);
        LibraryVariableStorage.Enqueue(1);
        SerialNos[2] := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(SerialNos[2]);
        LibraryVariableStorage.Enqueue(1);
        SerialNos[3] := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(SerialNos[3]);
        LibraryVariableStorage.Enqueue(1);
        SerialNos[4] := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(SerialNos[4]);
        LibraryVariableStorage.Enqueue(1);
        SerialNos[5] := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(SerialNos[5]);
        LibraryVariableStorage.Enqueue(1);
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(TrackedItem."No.", Location.Code, 5, true);

        // Sales order with 1 line for item "I1"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, TrackedItem."No.", 4);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        // Create warehouse shipment and pick from the sales order
        CreateWhsePickFromSalesOrder(SalesHeader);
        FindWarehouseActivityLine(WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityLine.ModifyAll("Qty. to Handle", 0);

        // Lines are sorted by Action Type so that all Take lines are before all Place lines
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        WarehouseActivityHeader.Validate("Sorting Method", WarehouseActivityHeader."Sorting Method"::"Action Type");
        WarehouseActivityHeader.Modify(true);
        WarehouseActivityHeader.SortWhseDoc();

        WarehouseActivityLine.SetCurrentKey("Sorting Sequence No.");
        WarehouseActivityLine.FindSet();

        // Ensure Serial No. is set to empty and "Qty. to Handle" is 0
        WarehouseActivityLine.TestField("Serial No.", '');
        WarehouseActivityLine.TestField("Qty. to Handle", 0);

        // Serial No. is passed to the CheckAndSetBarcode method and is set on the firs tline
        Clear(NeedsRefresh);
        Clear(AllLinesAreDone);
        ScanWarehouseActivityLine.CheckAndSetBarcode(WarehouseActivityLine, SerialNos[1], NeedsRefresh, AllLinesAreDone); // First Take line is set
        // Serial No. is validated as barcode, NeedsRefresh is true, AllLinesAreDone is false so that WarehouseActivityLine moved by one and the page is refreshed
        Assert.IsTrue(NeedsRefresh, 'NeedsRefresh should be true');
        Assert.IsFalse(AllLinesAreDone, 'AllLinesAreDone should be false');

        // Ship next 2 lines, so that we set first and last take lines
        SkippedLines[1] := WarehouseActivityLine."Line No.";
        WarehouseActivityLine.Next(); // Second Take line is skipped

        SkippedLines[2] := WarehouseActivityLine."Line No.";
        WarehouseActivityLine.Next(); // Third Take line is skipped

        // Serial No. is passed to the CheckAndSetBarcode method and is set on the fourth line
        Clear(NeedsRefresh);
        Clear(AllLinesAreDone);
        ScanWarehouseActivityLine.CheckAndSetBarcode(WarehouseActivityLine, SerialNos[4], NeedsRefresh, AllLinesAreDone); // Fourth Take line is set
        Assert.IsTrue(NeedsRefresh, 'NeedsRefresh should be true');
        Assert.IsFalse(AllLinesAreDone, 'AllLinesAreDone should be false');

        // Serial No. is passed to the CheckAndSetBarcode method and is set on the first place line
        Clear(NeedsRefresh);
        Clear(AllLinesAreDone);
        ScanWarehouseActivityLine.CheckAndSetBarcode(WarehouseActivityLine, SerialNos[1], NeedsRefresh, AllLinesAreDone); // First Place line is set
        Assert.IsTrue(NeedsRefresh, 'NeedsRefresh should be true');
        Assert.IsFalse(AllLinesAreDone, 'AllLinesAreDone should be false');

        // Serial No. is passed to the CheckAndSetBarcode method and is set on the second place line
        Clear(NeedsRefresh);
        Clear(AllLinesAreDone);
        ScanWarehouseActivityLine.CheckAndSetBarcode(WarehouseActivityLine, SerialNos[4], NeedsRefresh, AllLinesAreDone); // Second Place line is set
        Assert.IsTrue(NeedsRefresh, 'NeedsRefresh should be true');
        Assert.IsFalse(AllLinesAreDone, 'AllLinesAreDone should be false');

        // Third and fourth place lines are skipped
        SkippedLines[3] := WarehouseActivityLine."Line No.";
        WarehouseActivityLine.Next(); // Third Place line is skipped

        SkippedLines[4] := WarehouseActivityLine."Line No.";
        WarehouseActivityLine.Next(); // Fourth Place line is skipped

        // Reset and move to second line
        WarehouseActivityLine.FindSet();
        WarehouseActivityLine.Next(); // Goto second line

        // Fill in second take line
        Clear(NeedsRefresh);
        Clear(AllLinesAreDone);
        ScanWarehouseActivityLine.CheckAndSetBarcode(WarehouseActivityLine, SerialNos[2], NeedsRefresh, AllLinesAreDone); // Second Take line is set
        Assert.IsTrue(NeedsRefresh, 'NeedsRefresh should be true');
        Assert.IsFalse(AllLinesAreDone, 'AllLinesAreDone should be false');
        Assert.AreEqual(WarehouseActivityLine."Line No.", SkippedLines[2], 'Second skipped line should be selected');

        // Fill in third take line
        Clear(NeedsRefresh);
        Clear(AllLinesAreDone);
        ScanWarehouseActivityLine.CheckAndSetBarcode(WarehouseActivityLine, SerialNos[3], NeedsRefresh, AllLinesAreDone); // Third Take line is set
        Assert.IsTrue(NeedsRefresh, 'NeedsRefresh should be true');
        Assert.IsFalse(AllLinesAreDone, 'AllLinesAreDone should be false');
        Assert.AreEqual(WarehouseActivityLine."Line No.", SkippedLines[3], 'Second skipped line should be selected');

        // Fill in Third place line
        Clear(NeedsRefresh);
        Clear(AllLinesAreDone);
        ScanWarehouseActivityLine.CheckAndSetBarcode(WarehouseActivityLine, SerialNos[2], NeedsRefresh, AllLinesAreDone); // Second Place line is set
        Assert.IsTrue(NeedsRefresh, 'NeedsRefresh should be true');
        Assert.IsFalse(AllLinesAreDone, 'AllLinesAreDone should be false');
        Assert.AreEqual(WarehouseActivityLine."Line No.", SkippedLines[4], 'Second skipped line should be selected');

        // Fill in the fourth and last place line
        Clear(NeedsRefresh);
        Clear(AllLinesAreDone);
        ScanWarehouseActivityLine.CheckAndSetBarcode(WarehouseActivityLine, SerialNos[3], NeedsRefresh, AllLinesAreDone); // Second Place line is set
        // After the last line is filled, needsRefresh is false and AllLinesAreDone is true enabling the code to finish the scanning process
        Assert.IsFalse(NeedsRefresh, 'NeedsRefresh should be false');
        Assert.IsTrue(AllLinesAreDone, 'AllLinesAreDone should be true');
    end;

    [Test]
    procedure GetBinContent()
    var
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        BinCode: Code[20];
        Quantity: Decimal;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Get Bin Content] [Item Journal]
        // [SCENARIO] Get Bin Content in the item journal creates item journal line with the bin content
        Initialize();

        // [GIVEN] Item "I".
        ItemNo := LibraryInventory.CreateItemNo();

        // [GIVEN] WMS location with bin "B".
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        BinCode := AddBin(Location.Code);

        // [GIVEN] Gets a quantity "X"
        Quantity := LibraryRandom.RandInt(10);

        // [GIVEN] Post positive inventory adjustment of item "I" of "X" pieces into bin "B".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, Location.Code, BinCode, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Open the new batch in the item journal and run "Get Bin Content" filtered by bin "B".
        // [WHEN] This will create a negative adjustment item journal line with "X" pieces of item "I".
        GetBinContentFromItemJournalLine(ItemJournalBatch, Location.Code, BinCode, ItemNo);

        // [THEN] Verifies that the negative adjustment journal line with "X" pieces of item "I" has been created.
        VerifyGetBinContentInItemJournal(ItemJournalBatch, ItemNo, Location.Code, BinCode, Quantity);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse I");
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse I");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        NoSeriesSetup();
        ItemJournalSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse I");
    end;

    local procedure AddBin(LocationCode: Code[10]): Code[20]
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateBin(Bin, LocationCode, CopyStr(LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), Database::Bin), 1, LibraryUtility.GetFieldLength(Database::Bin, Bin.FieldNo(Code))), '', '');
        exit(Bin.Code);
    end;

    local procedure AssignLotNoToItemJournalLine(ItemJournalLine: Record "Item Journal Line"; LotNo: Code[50]; Qty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        ItemJournalLine.OpenItemTrackingLines(false);
    end;

    local procedure SetupSortingTestData(var Item: Record Item; var Location: Record Location; var Customer: Record Customer; var Vendor: Record Vendor; var "Count": Integer)
    begin
        CreateItem(Item);
        CreateLocationSetup(Location, false, true, true);
        CreateCustomer(Customer, Location.Code);
        CreateVendor(Vendor, Location.Code);
        Count := LibraryRandom.RandIntInRange(5, 10);
    end;

    local procedure NoSeriesSetup()
    var
        InventorySetup: Record "Inventory Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        WarehouseSetup: Record "Warehouse Setup";
    begin
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        SalesSetup.Get();
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure ItemJournalSetup()
    begin
        Clear(ItemJournalTemplate);
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        Clear(ItemJournalBatch);
        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateDirectedPutAwayAndPickLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
    end;

    local procedure CreateFullWMSLocation(var Location: Record Location; BinsPerZone: Integer)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, BinsPerZone);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemWithLotWarehouseTracking(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateLotItem(Item);
        ItemTrackingCode.Get(Item."Item Tracking Code");
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemWithSNWarehouseTracking(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateSerialItem(Item);
        ItemTrackingCode.Get(Item."Item Tracking Code");
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateLocationSetup(var Location: Record Location; UseAsInTransit: Boolean; RequireShipment: Boolean; RequireReceive: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        CreateLocation(Location, UseAsInTransit, RequireShipment, RequireReceive);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateLocation(var Location: Record Location; UseAsInTransit: Boolean; RequireShipment: Boolean; RequireReceive: Boolean)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Use As In-Transit", UseAsInTransit);
        Location.Validate("Require Shipment", RequireShipment);
        Location.Validate("Require Receive", RequireReceive);
        Location.Modify(true);
    end;

    local procedure CreateReclassificationSetup(var ItemJournalLine: Record "Item Journal Line")
    var
        Location: Record Location;
        Item: Record Item;
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryInventory.CreateItem(Item);
        CreateItemReclassificationJournalLine(ItemJournalLine, Item."No.", 0);
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithLine(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithTwoLines(var SalesHeader: Record "Sales Header"; var SalesLine: array[2] of Record "Sales Line"; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10])
    var
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        for i := 1 to 2 do begin
            LibrarySales.CreateSalesLine(SalesLine[i], SalesHeader, SalesLine[i].Type::Item, ItemNo, Qty);
            SalesLine[i].Validate("Location Code", LocationCode);
            SalesLine[i].Modify(true);
        end;
    end;

    local procedure CreateSalesOrderWithWarehouseShipment(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        Location: Record Location;
    begin
        LibraryInventory.CreateItem(Item);
        CreateLocation(Location, false, true, false);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandInt(100), Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateItemStockWithLot(LocationCode: Code[10]; ItemNo: Code[20]; LotNo: Code[50]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Qty);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure FindPostedWhseReceiptLine(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; PurchaseLine: Record "Purchase Line")
    begin
        PostedWhseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        PostedWhseReceiptLine.SetRange("Source Subtype", PurchaseLine."Document Type");
        PostedWhseReceiptLine.SetRange("Source No.", PurchaseLine."Document No.");
        PostedWhseReceiptLine.SetRange("Source Line No.", PurchaseLine."Line No.");
        PostedWhseReceiptLine.FindFirst();
    end;

    local procedure UpdateItemInventory(ItemNo: Code[20]; LocationCode: Code[10])
    begin
        UpdateItemInventoryFixedQty(ItemNo, LocationCode, LibraryRandom.RandDec(10, 2) + 1000);
    end;

    local procedure UpdateItemInventoryFixedQty(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, LocationCode, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateWarehouseSetup(ShipmentPostingPolicy: Option; ReceiptPostingPolicy: Option)
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        WarehouseSetup.Get();
        WarehouseSetup.Validate("Shipment Posting Policy", ShipmentPostingPolicy);
        WarehouseSetup.Validate("Receipt Posting Policy", ReceiptPostingPolicy);
        WarehouseSetup.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        CreateDefaultDimensionForItem(Item."No.");
    end;

    local procedure CreateLotTrackedItemWithOrderReorderingPolicy(var Item: Record Item)
    begin
        CreateItemWithLotWarehouseTracking(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateDefaultDimensionForItem(ItemNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, ItemNo, Dimension.Code, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);
    end;

    local procedure CreateCustomer(var Customer: Record Customer; LocationCode: Code[10])
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateDefaultDimensionCustomer(Customer."No.");
        Customer.Validate("Location Code", LocationCode);
        Customer.Modify(true);
    end;

    local procedure CreateDefaultDimensionCustomer(CustomerNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        SelectDimensionValue(Dimension, DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustomerNo, Dimension.Code, DimensionValue.Code);
        UpdateDefaultDimension(DefaultDimension);
    end;

    local procedure SelectDimensionValue(var Dimension: Record Dimension; var DimensionValue: Record "Dimension Value")
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure UpdateDefaultDimension(DefaultDimension: Record "Default Dimension")
    begin
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);
    end;

    local procedure CreateSalesSetup(var SalesHeader: Record "Sales Header"; var SalesHeader2: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; CustomerNo: Code[20])
    begin
        // Create and Release Sales Document with and without Dimensions.
        CreateAndReleaseSalesDocument(SalesHeader, DocumentType, ItemNo, LocationCode, CustomerNo, true);
        CreateAndReleaseSalesDocument(SalesHeader2, DocumentType, ItemNo, LocationCode, CustomerNo, false);
    end;

    local procedure CreateAndReleaseSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; CustomerNo: Code[20]; DimensionSetEntryRequired: Boolean)
    begin
        CreateSalesDocument(SalesHeader, DocumentType, ItemNo, LocationCode, CustomerNo, DimensionSetEntryRequired);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateItemReclassificationJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Transfer);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Transfer, ItemNo, Quantity);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; CustomerNo: Code[20]; DimensionSetEntryRequired: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        UpdateSalesHeader(SalesHeader, DimensionSetEntryRequired);
        CreateSalesLine(SalesHeader, ItemNo, LocationCode);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure UpdateSalesHeader(var SalesHeader: Record "Sales Header"; DimensionSetEntryRequired: Boolean)
    begin
        if not DimensionSetEntryRequired then begin
            SalesHeader.Validate("Dimension Set ID", 0);
            SalesHeader.Modify(true);
        end;
    end;

    local procedure CreateWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", LocationCode);
        WarehouseShipmentHeader.Modify(true);
    end;

    local procedure CreateWarehouseReceiptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        WarehouseReceiptHeader.Validate("Location Code", LocationCode);
        WarehouseReceiptHeader.Modify(true);
    end;

    local procedure CreatePutAwayFromPostedWhseRcpt(var WarehouseActivityLine: Record "Warehouse Activity Line"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        WhseSourceCreateDocument: Report "Whse.-Source - Create Document";
    begin
        WhseSourceCreateDocument.SetPostedWhseReceiptLine(PostedWhseReceiptLine, '');
        WhseSourceCreateDocument.SetHideValidationDialog(true);
        WhseSourceCreateDocument.UseRequestPage(false);
        WhseSourceCreateDocument.RunModal();

        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, PostedWhseReceiptLine."Source Type", PostedWhseReceiptLine."Source Subtype",
          PostedWhseReceiptLine."Source No.", PostedWhseReceiptLine."Source Line No.");
    end;

    local procedure UseFiltersToGetSrcDocShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SellToCustomerNo: Code[20]; BuyFromVendorNo: Code[20]; TransferFrom: Code[10]; TransferTo: Code[10])
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        CreateWarehouseShipmentHeader(WarehouseShipmentHeader, TransferFrom);
        LibraryWarehouse.CreateWarehouseSourceFilter(WarehouseSourceFilter, WarehouseSourceFilter.Type::Outbound);
        UpdateSourceFilterSales(WarehouseSourceFilter, SellToCustomerNo);
        UpdateSourceFilterPurchase(WarehouseSourceFilter, BuyFromVendorNo);
        UpdateSourceFilterTransfer(WarehouseSourceFilter, TransferFrom, TransferTo);
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, TransferFrom);
    end;

    local procedure UseFiltersToGetSrcDocReceipt(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SellToCustomerNo: Code[20]; BuyFromVendorNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        CreateWarehouseReceiptHeader(WarehouseReceiptHeader, LocationCode);
        LibraryWarehouse.CreateWarehouseSourceFilter(WarehouseSourceFilter, WarehouseSourceFilter.Type::Inbound);
        UpdateSourceFilterPurchase(WarehouseSourceFilter, BuyFromVendorNo);
        UpdateSourceFilterSales(WarehouseSourceFilter, SellToCustomerNo);
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, LocationCode);
    end;

    local procedure UpdateSourceFilterSales(var WarehouseSourceFilter: Record "Warehouse Source Filter"; SellToCustomerNoFilter: Code[20])
    begin
        WarehouseSourceFilter.Validate("Sell-to Customer No. Filter", SellToCustomerNoFilter);
        WarehouseSourceFilter.Modify(true);
    end;

    local procedure UpdateSourceFilterPurchase(var WarehouseSourceFilter: Record "Warehouse Source Filter"; BuyFromVendorNoFilter: Code[20])
    begin
        WarehouseSourceFilter.Validate("Buy-from Vendor No. Filter", BuyFromVendorNoFilter);
        WarehouseSourceFilter.Modify(true);
    end;

    local procedure UpdateSourceFilterTransfer(var WarehouseSourceFilter: Record "Warehouse Source Filter"; TransferFromCodeFilter: Code[10]; TransferToCodeFilter: Code[10])
    begin
        WarehouseSourceFilter.Validate("Transfer-from Code Filter", TransferFromCodeFilter);
        WarehouseSourceFilter.Validate("Transfer-to Code Filter", TransferToCodeFilter);
        WarehouseSourceFilter.Modify(true);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; LocationCode: Code[10])
    var
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreateDefaultDimensionVendor(Vendor."No.");
        Vendor.Validate("Location Code", LocationCode);
        Vendor.Modify(true);
    end;

    local procedure CreateDefaultDimensionVendor(VendorNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        SelectDimensionValue(Dimension, DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, VendorNo, Dimension.Code, DimensionValue.Code);
        UpdateDefaultDimension(DefaultDimension);
    end;

    local procedure CreatePurchaseSetup(var PurchaseHeader: Record "Purchase Header"; var PurchaseHeader2: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; VendorNo: Code[20])
    begin
        // Create and Release Purchase Document with and without Dimensions.
        CreateAndReleasePurchDocument(PurchaseHeader, DocumentType, ItemNo, LocationCode, VendorNo, true);
        CreateAndReleasePurchDocument(PurchaseHeader2, DocumentType, ItemNo, LocationCode, VendorNo, false);
    end;

    local procedure CreateAndReleasePurchDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; VendorNo: Code[20]; DimensionSetEntryRequired: Boolean)
    begin
        CreatePurchaseDocument(PurchaseHeader, DocumentType, ItemNo, LocationCode, VendorNo, DimensionSetEntryRequired);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; VendorNo: Code[20]; DimensionSetEntryRequired: Boolean)
    begin
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        UpdatePurchaseHeader(PurchaseHeader, DimensionSetEntryRequired);
        CreatePurchaseLine(PurchaseHeader, ItemNo, LocationCode);
    end;

    local procedure UpdatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DimensionSetEntryRequired: Boolean)
    begin
        if not DimensionSetEntryRequired then begin
            PurchaseHeader.Validate("Dimension Set ID", 0);
            PurchaseHeader.Modify(true);
        end;
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateTransferLocations(var LocationFrom: Record Location; var LocationTo: Record Location; var LocationInTransit: Record Location)
    begin
        CreateLocationSetup(LocationFrom, false, true, true);  // Booleans: In Transit, Require Shipment, Require Receive.
        CreateLocationSetup(LocationTo, false, true, true);
        CreateLocationSetup(LocationInTransit, true, false, false);
    end;

    local procedure CreateTransferOrderSetup(var TransferHeader: Record "Transfer Header"; var TransferHeader2: Record "Transfer Header"; ItemNo: Code[20]; LocationFrom: Code[10]; LocationTo: Code[10]; LocationInTransit: Code[10])
    begin
        // Create and Release Transfer Order with and without Dimensions.
        CreateAndReleaseTransferOrder(TransferHeader, ItemNo, LocationFrom, LocationTo, LocationInTransit, true);
        CreateAndReleaseTransferOrder(TransferHeader2, ItemNo, LocationFrom, LocationTo, LocationInTransit, false);
    end;

    local procedure CreateAndReleaseTransferOrder(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; LocationFrom: Code[10]; LocationTo: Code[10]; LocationInTransit: Code[10]; DimensionSetEntryRequired: Boolean)
    begin
        CreateTransferOrder(TransferHeader, ItemNo, LocationFrom, LocationTo, LocationInTransit, DimensionSetEntryRequired);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateShipPickLocation(var Location: Record Location)
    begin
        CreateLocation(Location, false, true, false);
        Location.Validate("Require Pick", true);
        Location.Modify(true);
    end;

    local procedure CreateTrackedPurchOrderPostWhseReceipt(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
          LibraryPurchase.CreateVendorNo(), ItemNo, Qty, LocationCode, WorkDate());

        PurchaseLine.OpenItemTrackingLines();

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WarehouseReceiptHeader.Get(
          LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
            DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; LocationFrom: Code[10]; LocationTo: Code[10]; LocationInTransit: Code[10]; DimensionSetEntryRequired: Boolean)
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationFrom, LocationTo, LocationInTransit);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, LibraryRandom.RandDec(10, 2));
        UpdateTransferLine(TransferLine, DimensionSetEntryRequired);
    end;

    local procedure CreateWhseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, LocationCode);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, '',
          BinCode, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
    end;

    local procedure CreateWhsePickFromSalesOrder(var SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure GetBinContentFromItemJournalLine(ItemJournalBatch: Record "Item Journal Batch"; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20])
    var
        BinContent: Record "Bin Content";
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.Validate("Posting Date", WorkDate());
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", ItemNo);
        LibraryWarehouse.WhseGetBinContentFromItemJournalLine(BinContent, ItemJournalLine);
    end;

    local procedure PostPositiveAdjustmentOnWarehouse(Location: Record Location; Item: Record Item; Quantity: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        CreateWhseJournalLine(WarehouseJournalLine, Location.Code, Location."Receipt Bin Code", Item."No.", Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Location.Code, true);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure PostNegativeAdjustmentOnWarehouse(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; LotNo: Code[20]; Qty: Decimal)
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, LocationCode);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, '', '',
          WarehouseJournalLine."Entry Type"::"Negative Adjmt.", ItemNo, -Qty);
        WarehouseJournalLine.Validate("Bin Code", BinCode);
        WarehouseJournalLine.Modify(true);

        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        WarehouseJournalLine.OpenItemTrackingLines();

        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationCode, true);
    end;

    local procedure UpdateTransferLine(var TransferLine: Record "Transfer Line"; DimensionSetEntryRequired: Boolean)
    begin
        if not DimensionSetEntryRequired then begin
            TransferLine.Validate("Dimension Set ID", 0);
            TransferLine.Modify(true);
        end;
    end;

    local procedure SelectPostedWhseShipmentLine(var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; WhseShipmentNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; ItemNo: Code[20])
    begin
        PostedWhseShipmentLine.SetRange("Whse. Shipment No.", WhseShipmentNo);
        PostedWhseShipmentLine.SetRange("Source Document", SourceDocument);
        PostedWhseShipmentLine.SetRange("Item No.", ItemNo);
        PostedWhseShipmentLine.FindFirst();
    end;

    local procedure SelectSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; No: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst();
    end;

    local procedure SelectPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure SetQtyToHandleOnWhseActivityLine(SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20]; LotNo: Code[50]; QtyToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source Type", SourceType);
        WarehouseActivityLine.SetRange("Source Subtype", SourceSubtype);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Lot No.", LotNo);
        WarehouseActivityLine.FindSet();
        repeat
            ;
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure BlockItemForPosting(ItemNo: Code[20]; Blocked: Boolean)
    var
        Item: Record Item;
    begin
        // Block and Unblock Item.
        Item.Get(ItemNo);
        Item.Validate(Blocked, Blocked);
        Item.Modify(true);
    end;

    local procedure ShipmentSalesPurchRetTransfer(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var SalesHeader: Record "Sales Header"; var PurchaseHeader: Record "Purchase Header"; var TransferHeader: Record "Transfer Header"; var Item: Record Item; SalesDimension: Boolean; PurchaseReturnDimension: Boolean; TransferDimension: Boolean)
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        CreateItem(Item);
        CreateTransferLocations(LocationFrom, LocationTo, LocationInTransit);
        UpdateItemInventory(Item."No.", LocationFrom.Code);
        CreateCustomer(Customer, LocationFrom.Code);
        CreateVendor(Vendor, LocationFrom.Code);

        // Create Sales Order, Purchase Return Order, and Transfer Order.
        // Create Warehouse Shipment using Filters to get Source document.
        CreateAndReleaseSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, Item."No.", LocationFrom.Code, Customer."No.", SalesDimension);
        CreateAndReleasePurchDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Item."No.", LocationFrom.Code, Vendor."No.",
          PurchaseReturnDimension);
        CreateAndReleaseTransferOrder(
          TransferHeader, Item."No.", LocationFrom.Code, LocationTo.Code, LocationInTransit.Code, TransferDimension);
        UseFiltersToGetSrcDocShipment(WarehouseShipmentHeader, Customer."No.", Vendor."No.", LocationFrom.Code, LocationTo.Code);
    end;

    local procedure ReceiptPurchaseSalesReturn(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var Item: Record Item; var SalesHeader: Record "Sales Header"; var PurchaseHeader: Record "Purchase Header"; PurchaseDimension: Boolean; SalesReturnDimension: Boolean)
    var
        Location: Record Location;
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        CreateItem(Item);
        CreateLocationSetup(Location, false, true, true);
        UpdateItemInventory(Item."No.", Location.Code);
        CreateCustomer(Customer, Location.Code);
        CreateVendor(Vendor, Location.Code);

        // Create Purchase Order and Sales Return Order setup without Dimensions.
        // Create Warehouse Receipt using Filters to get Source document.
        CreateAndReleasePurchDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, Item."No.", Location.Code, Vendor."No.", PurchaseDimension);
        CreateAndReleaseSalesDocument(
          SalesHeader, SalesHeader."Document Type"::"Return Order", Item."No.", Location.Code, Customer."No.", SalesReturnDimension);
        UseFiltersToGetSrcDocReceipt(WarehouseReceiptHeader, Customer."No.", Vendor."No.", Location.Code);
    end;

    local procedure FilterWhseReceiptLines(var WhseReceiptLine: Record "Warehouse Receipt Line"; DocumentNo: Code[20]; ItemNo: Code[20])
    begin
        WhseReceiptLine.SetRange("No.", DocumentNo);
        WhseReceiptLine.SetRange("Item No.", ItemNo);
    end;

    local procedure FilterWhseShipmentLines(var WhseShipmentLine: Record "Warehouse Shipment Line"; DocumentNo: Code[20]; ItemNo: Code[20])
    begin
        WhseShipmentLine.SetRange("No.", DocumentNo);
        WhseShipmentLine.SetRange("Item No.", ItemNo);
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20]; SourceLineNo: Integer)
    begin
        WarehouseActivityLine.SetRange("Source Type", SourceType);
        WarehouseActivityLine.SetRange("Source Subtype", SourceSubtype);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Source Line No.", SourceLineNo);
        WarehouseActivityLine.FindSet();
    end;

    local procedure UpdateInventoryOnDirectedPutAwayPickLocationTrackedItem(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; ItemTrackingNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingNo);
        LibraryVariableStorage.Enqueue(Qty);
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(ItemNo, LocationCode, Qty, true);
    end;

    local procedure UpdateInventoryOnBinAtDirectedPutAwayPickLocationTrackedItem(Bin: Record Bin; ItemNo: Code[20]; Qty: Decimal; ItemTrackingNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingNo);
        LibraryVariableStorage.Enqueue(Qty);
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(Bin, ItemNo, Qty, true);
    end;

    local procedure UpdateItemTrackingOnWarehouseActivityLines(ItemNo: Code[20]; BinCode: Code[20]; LotNo: Code[50])
    var
        WarehouseActivityLineTake: Record "Warehouse Activity Line";
        WarehouseActivityLinePlace: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLineTake.SetRange("Item No.", ItemNo);
        WarehouseActivityLineTake.SetRange("Bin Code", BinCode);
        WarehouseActivityLineTake.FindSet();

        repeat
            WarehouseActivityLineTake.TestField("Action Type", WarehouseActivityLineTake."Action Type"::Take);
            WarehouseActivityLineTake.Validate("Lot No.", LotNo);
            WarehouseActivityLineTake.Modify(true);

            WarehouseActivityLinePlace.Get(
              WarehouseActivityLineTake."Activity Type", WarehouseActivityLineTake."No.", WarehouseActivityLineTake."Line No.");
            WarehouseActivityLinePlace.Next();
            WarehouseActivityLinePlace.TestField("Action Type", WarehouseActivityLinePlace."Action Type"::Place);
            WarehouseActivityLinePlace.Validate("Lot No.", LotNo);
            WarehouseActivityLinePlace.Modify(true);
        until WarehouseActivityLineTake.Next() = 0;
    end;

    local procedure VerifyItemInventory(ItemNo: Code[20]; LocationCode: Code[10]; GlobalDimension1Code: Code[20]; ExpectedQuantity: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.SetRange("Location Filter", LocationCode);
        Item.SetRange("Global Dimension 1 Filter", GlobalDimension1Code);
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, ExpectedQuantity);
    end;

    local procedure VerifyPickedQuantity(ItemNo: Code[20]; QtyPicked: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Item No.", ItemNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.TestField("Qty. Picked", QtyPicked);
    end;

    local procedure VerifyPostedShipmentLinesSales(WhseShipmentNo: Code[20]; ItemNo: Code[20]; DocumentNo: Code[20])
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        SalesLine: Record "Sales Line";
    begin
        SelectPostedWhseShipmentLine(
          PostedWhseShipmentLine, WhseShipmentNo, PostedWhseShipmentLine."Source Document"::"Sales Order", ItemNo);
        SelectSalesLine(SalesLine, SalesLine."Document Type"::Order, DocumentNo, ItemNo);
        PostedWhseShipmentLine.TestField(Quantity, SalesLine.Quantity);
    end;

    local procedure VerifyPostedShipmentLinesPurch(WhseShipmentNo: Code[20]; ItemNo: Code[20]; DocumentNo: Code[20])
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        PurchaseLine: Record "Purchase Line";
    begin
        SelectPostedWhseShipmentLine(
          PostedWhseShipmentLine, WhseShipmentNo, PostedWhseShipmentLine."Source Document"::"Purchase Return Order", ItemNo);
        SelectPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::"Return Order", DocumentNo, ItemNo);
        PostedWhseShipmentLine.TestField(Quantity, PurchaseLine.Quantity);
    end;

    local procedure VerifyPostedShipmentLinesTrans(WhseShipmentNo: Code[20]; ItemNo: Code[20]; DocumentNo: Code[20])
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        TransferLine: Record "Transfer Line";
    begin
        SelectPostedWhseShipmentLine(
          PostedWhseShipmentLine, WhseShipmentNo, PostedWhseShipmentLine."Source Document"::"Outbound Transfer", ItemNo);
        TransferLine.SetRange("Document No.", DocumentNo);
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.FindFirst();
        PostedWhseShipmentLine.TestField(Quantity, TransferLine.Quantity);
    end;

    local procedure SelectPostedWhseReceiptLine(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseReceiptNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; ItemNo: Code[20])
    begin
        PostedWhseReceiptLine.SetRange("Whse. Receipt No.", WhseReceiptNo);
        PostedWhseReceiptLine.SetRange("Source Document", SourceDocument);
        PostedWhseReceiptLine.SetRange("Item No.", ItemNo);
        PostedWhseReceiptLine.FindFirst();
    end;

    local procedure VerifyPostedReceiptLinesSales(WhseReceiptNo: Code[20]; ItemNo: Code[20]; DocumentNo: Code[20])
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        SalesLine: Record "Sales Line";
    begin
        SelectPostedWhseReceiptLine(
          PostedWhseReceiptLine, WhseReceiptNo, PostedWhseReceiptLine."Source Document"::"Sales Return Order", ItemNo);
        SelectSalesLine(SalesLine, SalesLine."Document Type"::"Return Order", DocumentNo, ItemNo);
        PostedWhseReceiptLine.TestField(Quantity, SalesLine.Quantity);
    end;

    local procedure VerifyPostedReceiptLinesPurch(WhseReceiptNo: Code[20]; ItemNo: Code[20]; DocumentNo: Code[20])
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        PurchaseLine: Record "Purchase Line";
    begin
        SelectPostedWhseReceiptLine(
          PostedWhseReceiptLine, WhseReceiptNo, PostedWhseReceiptLine."Source Document"::"Purchase Order", ItemNo);
        SelectPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::Order, DocumentNo, ItemNo);
        PostedWhseReceiptLine.TestField(Quantity, PurchaseLine.Quantity);
    end;

    local procedure VerifyRcptLineNotExist(WhseReceiptNo: Code[20])
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        PostedWhseReceiptLine.SetFilter("Whse. Receipt No.", '%1', WhseReceiptNo);
        Assert.AreEqual(0, PostedWhseReceiptLine.Count, ErrNoRecord);
    end;

    local procedure VerifyReservedLotNo(ItemNo: Code[20]; LotNo: Code[50])
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.SetRange("Item No.", ItemNo);
        ReservEntry.SetRange("Source Type", DATABASE::"Item Ledger Entry");
        ReservEntry.FindFirst();
        ReservEntry.TestField("Lot No.", LotNo);
    end;

    local procedure VerifyReservationEntryLotQty(SourceType: Integer; LotNo: Code[50]; Qty: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.CalcSums(Quantity);
        ReservationEntry.TestField(Quantity, Qty);
    end;

    local procedure VerifySalesReservationFromInventory(SalesLine: Record "Sales Line"; LotNo: Code[50])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetSourceFilter(DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", false);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.TestField("Lot No.", LotNo);
        ReservationEntry.Reset();
        ReservationEntry.SetRange("Entry No.", ReservationEntry."Entry No.");
        ReservationEntry.SetRange(Positive, not ReservationEntry.Positive);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Source Type", DATABASE::"Item Ledger Entry");
        ReservationEntry.TestField("Lot No.", LotNo);
    end;

    local procedure VerifyPurchaseSurplusReservEntry(PurchaseLine: Record "Purchase Line"; LotNo: Code[50])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetSourceFilter(
          DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", false);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.TestField("Lot No.", LotNo);
    end;

    local procedure VerifyGetBinContentInItemJournal(ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.SetRange("Location Code", LocationCode);
        ItemJournalLine.SetRange("Bin Code", BinCode);
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Entry Type", ItemJournalLine."Entry Type"::"Negative Adjmt.");
        ItemJournalLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWhseShipmentLineSorting(ItemNo: Code[20]; DocCount: Integer)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        SortingSequenceNo: Integer;
    begin
        WarehouseShipmentLine.SetRange("Item No.", ItemNo);
        WarehouseShipmentLine.SetFilter("Sorting Sequence No.", '<>%1', 0);
        Assert.AreEqual(
          DocCount,
          WarehouseShipmentLine.Count,
          StrSubstNo(EmptyTableErr, DocCount, WarehouseShipmentLine.TableCaption(), WarehouseShipmentLine.GetFilters));
        WarehouseShipmentLine.FindSet();
        SortingSequenceNo := WarehouseShipmentLine."Sorting Sequence No.";
        while WarehouseShipmentLine.Next() <> 0 do begin
            Assert.IsTrue(WarehouseShipmentLine."Sorting Sequence No." > SortingSequenceNo, StrSubstNo(SortingOrderErr, WarehouseShipmentLine.TableCaption));
            SortingSequenceNo := WarehouseShipmentLine."Sorting Sequence No.";
        end;
    end;

    local procedure VerifyWhseReceiptLineSorting(ItemNo: Code[20]; DocCount: Integer)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        SortingSequenceNo: Integer;
    begin
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        WarehouseReceiptLine.SetFilter("Sorting Sequence No.", '<>%1', 0);
        Assert.AreEqual(
          DocCount,
          WarehouseReceiptLine.Count,
          StrSubstNo(EmptyTableErr, DocCount, WarehouseReceiptLine.TableCaption(), WarehouseReceiptLine.GetFilters));
        WarehouseReceiptLine.FindSet();
        SortingSequenceNo := WarehouseReceiptLine."Sorting Sequence No.";
        while WarehouseReceiptLine.Next() <> 0 do begin
            Assert.IsTrue(WarehouseReceiptLine."Sorting Sequence No." > SortingSequenceNo, StrSubstNo(SortingOrderErr, WarehouseReceiptLine.TableCaption));
            SortingSequenceNo := WarehouseReceiptLine."Sorting Sequence No.";
        end;
    end;

    local procedure VerifyWhseReceiptLineCreated(DocumentNo: Code[20]; ItemNo: Code[20])
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FilterWhseReceiptLines(WhseReceiptLine, DocumentNo, ItemNo);
        Assert.IsFalse(WhseReceiptLine.IsEmpty, StrSubstNo(EmptyTableErr, 1, WhseReceiptLine.TableCaption(), WhseReceiptLine.GetFilter("No.")));
    end;

    local procedure VerifyWhseReceiptLineNotCreated(DocumentNo: Code[20]; ItemNo: Code[20])
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FilterWhseReceiptLines(WhseReceiptLine, DocumentNo, ItemNo);
        Assert.IsTrue(WhseReceiptLine.IsEmpty, ErrNoRecord);
    end;

    local procedure VerifyWhseShipmentLineCreated(DocumentNo: Code[20]; ItemNo: Code[20])
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FilterWhseShipmentLines(WhseShipmentLine, DocumentNo, ItemNo);
        Assert.IsFalse(WhseShipmentLine.IsEmpty, StrSubstNo(EmptyTableErr, 1, WhseShipmentLine.TableCaption(), WhseShipmentLine.GetFilter("No.")));
    end;

    local procedure VerifyWhseShipmentLineNotCreated(DocumentNo: Code[20]; ItemNo: Code[20])
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FilterWhseShipmentLines(WhseShipmentLine, DocumentNo, ItemNo);
        Assert.IsTrue(WhseShipmentLine.IsEmpty, ErrNoRecord);
    end;

    local procedure VerifyWhseShipmentCompletelyPicked(SalesDocType: Option; SalesDocNo: Code[20]; ItemNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseShipmentLine.SetRange("Source Subtype", SalesDocType);
        WarehouseShipmentLine.SetRange("Source No.", SalesDocNo);
        WarehouseShipmentLine.SetRange("Item No.", ItemNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.TestField("Qty. Picked", WarehouseShipmentLine.Quantity);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StringMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 1;  // Ship Only.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, 'Do you want to post the receipt?') > 0, Question);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerWithMessageVerification(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ConfirmMessageText: Text;
    begin
        ConfirmMessageText := LibraryVariableStorage.DequeueText();
        Assert.IsTrue(StrPos(ConfirmMessage, ConfirmMessageText) > 0, ConfirmMessage);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ShipLinesMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, 'Ship lines have been posted.') > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SourceDocMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, 'Number of source documents posted:') > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure GenericMessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines.New();
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesSetLotNoAndSerialNoPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        i: Integer;
        CheckAvaliable: Boolean;
    begin
        CheckAvaliable := LibraryVariableStorage.DequeueBoolean();

        for i := 1 to LibraryVariableStorage.DequeueInteger() do begin
            ItemTrackingLines.New();
            ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
            ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
            ItemTrackingLines."Quantity (Base)".SetValue(1);
        end;

        if CheckAvaliable then
            LibraryVariableStorage.Enqueue(ItemTrackingLines.AvailabilitySerialNo.AsBoolean());

        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesAssignLotPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesAssignSerialNoPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesAssignMultipleSerialNoPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        while LibraryVariableStorage.Length() > 0 do begin
            WhseItemTrackingLines.New();
            WhseItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
            WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
        end;
        WhseItemTrackingLines.OK().Invoke();
    end;
}

