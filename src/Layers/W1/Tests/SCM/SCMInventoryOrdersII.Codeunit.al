codeunit 137068 "SCM Inventory Orders-II"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        IsInitialized := false;
    end;

    var
        RevaluationItemJournalTemplate: Record "Item Journal Template";
        RevaluationItemJournalBatch: Record "Item Journal Batch";
        LocationSilver: Record Location;
        LocationSilver2: Record Location;
        LocationBlue: Record Location;
        LocationRed: Record Location;
        LocationInTransit: Record Location;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryErrorMessage: Codeunit "Library - Error Message";
        IsInitialized: Boolean;
        TrackingQuantity: Decimal;
        AssignLotNo: Boolean;
        DifferentExpirationDate: Boolean;
        NewExpirationDate: Date;
        ValidationErr: Label '%1 must be %2.', Locked = true;
        AmountErr: Label 'Amount is incorrect.';
        CannotChangeSellToCustErr: Label 'You cannot change Sell-to Customer No. because the order is associated with one or more sales orders.';
        TrackingMethod: Option "Serial No.",Lot;
        MultipleValueEntriesWithChargeMsg: Label 'More than one Item Charge is posted for each Item Ledger Entry.';
        PostedChargeCostAmountMsg: Label 'Wrong Cost Amount of posted Item Charge.';
        WrongNoOfOrdersPrintedErr: Label 'Two orders must be printed together';
        WrongValueOfPurchCodeErr: Label 'Wrong value of purchasing code';
        WrongNoOfOrdersCreatedErr: Label '%1 orders must be created.', Comment = '%1 = Number of order to be created (2 orders must be created.)';
        WrongLocationCodeOnLineErr: Label 'Location code on the line must not be equal to location code on the header.';
        CannotCreateDocPrivacyBlockerErr: Label 'You cannot create this type of document when Vendor %1 is blocked for privacy.',
            Comment = '%1 = Vendor No. (You cannot create this type of document when Vendor GU0000000001 is blocked for privacy.)';
        PurchaseOrderMustBeCreatedErr: Label 'Drop shipment purchase order must be created.';

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,PostedItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure TransferOrderWithSameExpirationDateAndLotNo()
    begin
        // Setup.
        Initialize();
        TransferOrderWithExpirationDateAndLotNo();  // Expiration Date values same on Item Tracking Lines.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,PostedItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure TransferOrderWithDifferentExpirationDateAndLotNo()
    begin
        // Setup.
        Initialize();
        DifferentExpirationDate := true;  // Expiration Date values different on Item Tracking Lines. Global variable required in PostedItemTrackingLinesPageHandler.
        TransferOrderWithExpirationDateAndLotNo();
    end;

    local procedure TransferOrderWithExpirationDateAndLotNo()
    var
        Item: Record Item;
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Create a Lot Tracked Item, Create and release Purchase Order.
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        CreateLotTrackedItem(Item);
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, Item."No.", PurchaseLine.Type::Item, LocationBlue.Code, LibraryRandom.RandDec(100, 2), 0);
        FindPurchaseLine(PurchaseLine, PurchaseHeader);

        // Assign values to Global variables, assign Lot No. on Purchase Order and Post Purchase Order.
        AssignLotNo := true;
        TrackingQuantity := PurchaseLine.Quantity;
        AssignTrackingOnPurchaseLine(PurchaseLine, ReservationEntry);
        NewExpirationDate := ReservationEntry."Expiration Date";
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // Create and release Transfer Order, update Bin Code and assign Tracking on it.
        CreateAndReleaseTransferOrder(TransferHeader, TransferLine, LocationBlue.Code, LocationSilver.Code, Item."No.", TrackingQuantity);
        UpdateBinCodeOnTransferLine(TransferLine, Bin.Code);
        AssignLotNo := false;  // Assign Lot - False, for Select Entries on Item Tracking summary page.
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);  // Assign Ship Tracking on Page Handler ItemTrackingPageHandler for Lot No.

        // Exercise: Post Transfer Order as Ship and Receive.
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);

        // Verify: Verify the entries on Transfer Receipt Line. Verify the Item Tracking applied in PostedItemTrackingLinesPageHandler.
        VerifyTransferReceiptLine(
          TransferLine."Document No.", Item."No.", TrackingQuantity, LocationSilver.Code, LocationBlue.Code, Bin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesOrderToQuoteWithBlankLastShippingNo()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Quantity: Decimal;
        StockoutWarning: Boolean;
        ItemNo: Code[20];
    begin
        // Setup: Create Item and create and post a Sales Order.
        Initialize();
        ItemNo := CreateItem();
        StockoutWarning := UpdateStockoutWarning(false);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleaseSalesOrder(SalesHeader, ItemNo, Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship Only.

        // Exercise: Copy the Sales Order to blank Sales Quote.
        CopySalesDocument(SalesHeader2, SalesHeader2."Document Type"::Quote, "Sales Document Type From"::Order, SalesHeader."No.");

        // Verify: Verify the Last Shipping No as blank on Sales Quote. Verify the values on Sales Quote.
        SalesHeader2.TestField("Last Shipping No.", '');
        VerifySalesLine(SalesHeader2, ItemNo, Quantity);

        // Tear Down: Set Stockout Warning to original state.
        UpdateStockoutWarning(StockoutWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesOrderToQuoteWithMakeOrderAndBlankLastShippingNo()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        StockoutWarning: Boolean;
        Quantity: Decimal;
        ItemNo: Code[20];
    begin
        // Setup: Create Item and create and post a Sales Order. Copy Sales Order to a Sales blank Quote
        Initialize();
        ItemNo := CreateItem();
        StockoutWarning := UpdateStockoutWarning(false);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleaseSalesOrder(SalesHeader, ItemNo, Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship only.
        CopySalesDocument(SalesHeader2, SalesHeader2."Document Type"::Quote, "Sales Document Type From"::Order, SalesHeader."No.");

        // Exercise: Make Sales Order from Sales Quote.
        LibrarySales.QuoteMakeOrder(SalesHeader2);

        // Verify: Verify the Last Shipping No as blank on Sales Order created from Sales Quote. Verify the values on Sales Order made from the Sales Quote.
        SelectSalesHeader(SalesHeader2, SalesHeader2."Sell-to Customer No.");
        SalesHeader2.TestField("Last Shipping No.", '');
        VerifySalesLine(SalesHeader2, ItemNo, Quantity);

        // Tear Down: Set Stockout Warning to original state.
        UpdateStockoutWarning(StockoutWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchaseOrderToQuoteWithBlankLastReceivingNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create Item, create release and post a Purchase Order.
        Initialize();
        ItemNo := CreateItem();
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, ItemNo, PurchaseLine.Type::Item, '', Quantity, 0);
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Receive only.

        // Exercise: Copy the Purchase Order to blank Purchase Quote.
        CopyPurchaseDocument(PurchaseHeader2, PurchaseHeader2."Document Type"::Quote, "Purchase Document Type From"::Order, PurchaseHeader."No.");

        // Verify: Verify the Last Receiving No as blank on Purchase Quote. Verify the values on Purchase Quote.
        PurchaseHeader2.TestField("Last Receiving No.", '');
        VerifyPurchaseLine(PurchaseHeader2, ItemNo, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchaseOrderToQuoteWithMakeOrderAndBlankLastReceivingNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create Item, create and release Purchase Order and post it. Copy Purchase Order to a Purchase Quote.
        Initialize();
        ItemNo := CreateItem();
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, ItemNo, PurchaseLine.Type::Item, '', Quantity, 0);
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Receive only.
        CopyPurchaseDocument(PurchaseHeader2, PurchaseHeader2."Document Type"::Quote, "Purchase Document Type From"::Order, PurchaseHeader."No.");

        // Exercise: Make Purchase Order from Purchase Quote.
        MakeOrderFromPurchaseQuote(PurchaseHeader2);

        // Verify: Verify the Last Receiving No as blank on Purchase Order created from Purchase Quote and verify the values on Purchase Order.
        SelectPurchaseHeader(PurchaseHeader2, PurchaseHeader2."Buy-from Vendor No.");
        PurchaseHeader2.TestField("Last Receiving No.", '');
        VerifyPurchaseLine(PurchaseHeader2, ItemNo, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryForTransferReceiptWithBin()
    var
        Item: Record Item;
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item, create and post Purchase Order. Create Transfer Order and update Bin on Transfer Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", PurchaseLine.Type::Item, LocationBlue.Code, Quantity, 0);
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.
        CreateAndReleaseTransferOrder(TransferHeader, TransferLine, LocationBlue.Code, LocationSilver.Code, Item."No.", Quantity);
        UpdateBinCodeOnTransferLine(TransferLine, Bin.Code);

        // Exercise: Post Transfer Order as Ship and Receive.
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);

        // Verify: Verify the Item Ledger Entry for Posted Transfer Receipt.
        VerifyItemLedgerEntry(Item."No.", -Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryWithAdjustCostItemEntry()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        InventorySetup: Record "Inventory Setup";
        DocumentNo: Code[20];
        Quantity: Decimal;
        UnitCost: Decimal;
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Purchase]
        // [SCENARIO] Check Quantity and Amount is not changed after Adjust Cost, if Item is purchased only.

        // [GIVEN] Prevent Automatic Cost Posting. Create and post Item Journal Line (purchase).
        Initialize();
        UpdateAutomaticCostSetup(InventorySetup);
        UnitCost := LibraryRandom.RandDec(100, 2);
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateItem(Item);
        DocumentNo := CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, Item."No.", Quantity, UnitCost);

        // [WHEN] Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Item Ledger Entry is correct after running Adjust Cost Item Entries.
        VerifyItemLedgerEntryForAdjustCost(DocumentNo, ItemJournalLine."Entry Type"::Purchase, Item."No.", Quantity, Quantity * UnitCost);

        // Tear down: Restore the values of Inventory Setup.
        RestoreInventorySetup(InventorySetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValueEntryForPurchaseOrderItemChargeAssignment()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item, create and release Purchase Order. Create Purchase Line for Item Charge and assign it to the Purchase Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", PurchaseLine.Type::Item, LocationBlue.Code, Quantity, 0);
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        AssignAndUpdateItemChargeOnPurchaseLine(PurchaseHeader);

        // Exercise: Post Purchase Order as Receive and Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify the Invoice quantity for Item Charge Assignment in Value Entry.
        VerifyValueEntry(Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseShippingDetailsWithDropShipmentForSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
    begin
        // Setup: Create Item.
        Initialize();
        ItemNo := CreateItem();

        // Create a Drop shipment Sales Order.
        CreateSalesOrderWithPurchasingCodeDropShipment(SalesHeader, ItemNo);

        // Exercise: Create Purchase Order and Get Sales Order from Drop Shipment.
        CreatePurchaseOrderAndGetDropShipment(SalesHeader);

        // Verify: Verify Purchase Order have same Ship to Address, Ship to Code as Sales Order.
        VerifyPurchaseShippingDetails(ItemNo, SalesHeader."Ship-to Code", SalesHeader."Ship-to Address");
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseShippingDetailsWithSpecialOrderForSalesOrder()
    var
        PurchHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        // Setup: Create Item.
        Initialize();

        // Create a Special Order Sales Order.
        CreateSalesOrderWithPurchasingCodeSpecialOrder(SalesHeader, CreateItem());

        // Exercise: Create Purchase Order and Get Sales Order from Special Order.
        CreatePurchaseOrderAndGetSpecialOrder(PurchHeader, SalesHeader, '');

        // Verify: Verify Purchase Order have same Ship to Address, Ship to Code as Sales Order.
        PurchHeader.TestField("Ship-to Address", LocationBlue.Address);
        PurchHeader.TestField("Ship-to Code", '');
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseShipmentMethodForSpecialSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        // Setup: Create Item.
        Initialize();

        // Create a Special Order Sales Order with Shipment Method Code.
        CreateSalesOrderWithPurchasingCodeSpecialOrder(SalesHeader, CreateItem());

        // Exercise: Create Purchase Order and Get Sales Order from Special Order.
        CreatePurchaseOrderAndGetSpecialOrder(PurchHeader, SalesHeader, '');

        // Verify: Verify Shipment Method Code of Purchase Order is copied from vendor (not from Sales Order).
        Vendor.Get(PurchHeader."Buy-from Vendor No.");
        PurchHeader.Find(); // Refresh Purchase Order.
        PurchHeader.TestField("Shipment Method Code", Vendor."Shipment Method Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RevaluationJournalAfterPostForDiffLocationsFRQItem()
    var
        Item: Record Item;
    begin
        // Setup: Create FRQ Item.
        Initialize();
        CreateFRQItem(Item);

        // Create and Post Purchase Order for Item at different locations.
        CreateAndPostPurchaseWithLocation(Item."No.", LocationBlue.Code);
        CreateAndPostPurchaseWithLocation(Item."No.", LocationRed.Code);

        // Create Revaluation Journal for Item at different locations. Update Unit Cost Revalued for Item at Location Blue.
        CreateRevaluationJournalForItem(Item."No.");
        CreateRevaluationJournalForItem(Item."No.");
        UpdateItemJournallineUnitCostRevalued(Item."No.", LocationBlue.Code);

        // Exercise: Post Revaluation Journal Line For Item at Location Blue only.
        PostItemJournalLine(Item."No.", LocationBlue.Code);

        // Verify: Verify after posting of Item on first Location, Item at other Location is still present on same Revaluation Journal Worksheet.
        VerifyItemJournalLineBatchAndTemplateForItem(
          Item."No.", LocationRed.Code, RevaluationItemJournalBatch."Journal Template Name", RevaluationItemJournalBatch.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJournalAfterPostForDiffLocationsFRQItem()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // Setup: Create FRQ Item.
        Initialize();
        CreateFRQItem(Item);

        // Create Item Journal Lines for Item at different locations.
        CreateItemJournalLineWithLocation(LocationBlue.Code, Item."No.", ItemJournalBatch);
        CreateItemJournalLineWithLocation(LocationRed.Code, Item."No.", ItemJournalBatch);

        // Exercise: Post Item Journal Line For Item at Location Blue only.
        PostItemJournalLine(Item."No.", LocationBlue.Code);

        // Verify: Verify after posting of Item on first Location, Item at other Location is still present on same Item Journal Worksheet.
        VerifyItemJournalLineBatchAndTemplateForItem(
          Item."No.", LocationRed.Code, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignementPurchPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithItemChargeAssignment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
    begin
        // Verify the GL Entry after post Purchase Order with Assign Item Charge Equally on multiple Purchase Lines.

        // Setup: Update Setups, create Purchase Order with multiple lines and Assign Charge Item Equally on Purchase Lines.
        Initialize();
        LibraryERM.SetInvRoundingPrecisionLCY(1);  // Required Invoice Rounding as 1.
        LibraryPurchase.SetInvoiceRounding(false);
        CreatePurchaseOrderWithMultiLine(PurchaseHeader);
        AssignChargeItemPurchEqually(PurchaseLine, PurchaseHeader);

        // Exercise: Post Purchase Order as Receive and Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify the GL Entry after post Purchase Order with Assign Item Charge Equally.
        PurchInvHeader.Get(PurchaseHeader."Last Posting No.");
        PurchInvHeader.CalcFields(Amount);
        VerifyGLEntry(
          GLEntry."Document Type"::Invoice, PurchaseHeader."Last Posting No.", PurchInvHeader.Amount,
          GLEntry."Gen. Posting Type"::Purchase);
        VerifyGLEntry(
          GLEntry."Document Type"::Invoice, PurchaseHeader."Last Posting No.", -PurchInvHeader.Amount, GLEntry."Gen. Posting Type"::" ");
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignementSalePageHandler,ItemChargeAssignMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithItemChargeAssignment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
    begin
        // Verify the GL Entry after post Sales Order with Assign Item Charge Equally on multiple Sales Lines.

        // Setup: Update Setups, create Sales Order with multiple lines and Assign Charge Item Equally on Sales Lines.
        Initialize();
        LibraryERM.SetInvRoundingPrecisionLCY(1);  // Required Invoice Rounding as 1.
        LibrarySales.SetInvoiceRounding(false);
        CreateSalesOrder(
          SalesHeader, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity and Unit Price.
        FindSalesLine(SalesLine, SalesHeader);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", SalesLine.Quantity, SalesLine."Unit Price");
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", SalesLine.Quantity, SalesLine."Unit Price");
        AssignChargeItemSaleEqually(SalesLine, SalesHeader);

        // Exercise: Post Sales Order as Receive and Invoice.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify the GL Entry after post Sales Order with Assign Item Charge Equally.
        SalesInvoiceHeader.Get(SalesHeader."Last Posting No.");
        SalesInvoiceHeader.CalcFields(Amount);
        VerifyGLEntry(
          GLEntry."Document Type"::Invoice, SalesHeader."Last Posting No.", -SalesInvoiceHeader.Amount, GLEntry."Gen. Posting Type"::Sale);
        VerifyGLEntry(
          GLEntry."Document Type"::Invoice, SalesHeader."Last Posting No.", SalesInvoiceHeader.Amount, GLEntry."Gen. Posting Type"::" ");
    end;

    [Test]
    [HandlerFunctions('GetSalesOrdersReportHandler')]
    [Scope('OnPrem')]
    procedure ShipmentMethodCodeAsOnVendorThroughRequisitionWorkSheet()
    var
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        RequisitionLine: Record "Requisition Line";
        GetSalesOrders: Report "Get Sales Orders";
    begin
        // Verify Shipment Method Code on Purchase Order with Shipment method code on Vendor when created through Requisition WorkSheet.

        // Setup: Create Item and create vendor with Shipment Method Code and Create Sales Order with Purchasing Code.
        Initialize();

        CreateSalesOrderWithPurchasingCodeSpecialOrder(SalesHeader, CreateItem());
        CreateVendorWithShipmentMethodCode(Vendor, SalesHeader."Shipment Method Code");
        CreateRequisitionLine(RequisitionLine);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        GetSalesOrders.SetReqWkshLine(RequisitionLine, 1); // Special Order.
        Commit();
        GetSalesOrders.RunModal();
        UpdateVendorOnRequisitionLine(RequisitionLine, SalesHeader."No.", Vendor."No.");

        // Exercise: For Carry Out Action Message.
        LibraryPlanning.CarryOutReqWksh(
          RequisitionLine, RequisitionLine."Expiration Date", RequisitionLine."Order Date", SalesHeader."Posting Date",
          SalesHeader."Posting Date", 'Anvvalue');

        // Verify: Verify Shipment Method Code of vendor is updated on Purchase Order.
        VerifyShipmentMethodCode(Vendor."No.", Vendor."Shipment Method Code");
    end;

    [Test]
    [HandlerFunctions('GetSalesOrdersReportHandler,ItemVendorCatalogModalHandler')]
    [Scope('OnPrem')]
    procedure VSTF324906()
    var
        ItemVendor: Record "Item Vendor";
        Vendor: Record Vendor;
        ReqWkshName: Record "Requisition Wksh. Name";
        ReqLine: Record "Requisition Line";
        ItemVariant: Record "Item Variant";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        GetSalesOrders: Report "Get Sales Orders";
        RetrieveDimFrom: Option Item,"Sales Line";
        ItemNo: Code[20];
    begin
        // Setup: Create Item with variant.
        Initialize();
        ItemNo := CreateItem();
        LibraryInventory.CreateItemVariant(ItemVariant, ItemNo);

        // Create a Special Order Sales Order.
        CreateSalesOrderWithPurchasingCodeSpecialOrder(SalesHeader, ItemNo);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate("Variant Code", ItemVariant.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Get Sales Orders for Special Orders in Req. Worksheet.
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        ReqWkshName.SetRange("Template Type", ReqWkshName."Template Type"::"Req.");
        ReqWkshName.FindFirst();
        LibraryPlanning.CreateRequisitionLine(ReqLine, ReqWkshName."Worksheet Template Name", ReqWkshName.Name);

        Commit();
        Clear(GetSalesOrders);
        GetSalesOrders.InitializeRequest(RetrieveDimFrom::Item);
        GetSalesOrders.SetReqWkshLine(ReqLine, 1);
        GetSalesOrders.RunModal();

        // Execute: Access Item Vendor Catalog for a Req. Line holding a Variant Code and create a new entry.
        Vendor.Init();
        ReqLine.SetRange(Type, ReqLine.Type::Item);
        ReqLine.SetRange("No.", ItemNo);
        ReqLine.FindFirst();
        ReqLine.LookupVendor(Vendor, true);

        // Verify: The Item Vendor record has the expected Variant Code.
        ItemVendor.SetRange("Item No.", ItemNo);
        ItemVendor.SetRange("Variant Code", ItemVariant.Code);
        Assert.AreEqual(
          1, ItemVendor.Count, 'Item Vendor entry was not created correctly for item ' + ItemNo + ', variant ' + ItemVariant.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotChangedLocationWhenEditVendorInReqLineForSalesLineWithDropShipm()
    var
        NewVendor: Record Vendor;
        ReqLine: Record "Requisition Line";
    begin
        // [FEATURE] [Requisition Worksheet] [Sales Order] [Drop Shipment]
        // [SCENARIO 378516] Location and Bin shouldn't be changed when modifying Vendor in Requisition Line for Sales Line with Drop Shipment.
        Initialize();

        // [GIVEN] Requisition Line with Drop Shipment, "Location Code" = "L1", "Bin Code" = Blank.
        CreateReqLineWithDropShipmentAndLocation(ReqLine, LocationSilver.Code);
        // [GIVEN] Vendor as "V".
        LibraryPurchase.CreateVendor(NewVendor);

        // [WHEN] Set Vendor On Requisition Line to "V".
        UpdateVendorOnRequisitionLine(ReqLine, ReqLine."Sales Order No.", NewVendor."No.");

        // [THEN] Requisition Line keeps "Location Code" = "L1", "Bin Code" = Blank.
        ReqLine.TestField("Location Code", LocationSilver.Code);
        ReqLine.TestField("Bin Code", '');
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure CannotChangeSellToCustInSpecPurchOrderWithLines()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        PurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Special Order]
        // [SCENARIO 361615] "Sell-to Customer No." in purchase order cannot be changed if the order has lines linked to a special sales order with a different "Customer No."
        // [GIVEN] Sales order with "Special Order" purchasing code
        CreateSalesOrderWithPurchasingCodeSpecialOrder(SalesHeader, CreateItem());

        // [GIVEN] Purchase order with one line copied from the sales order
        CreatePurchaseOrderAndGetSpecialOrder(PurchHeader, SalesHeader, '');
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Change the "Sell-to Customer No." in the purchase order
        asserterror PurchHeader.Validate("Sell-to Customer No.", Customer."No.");

        // [THEN] Error message prevents user from changing the customer
        Assert.ExpectedError(CannotChangeSellToCustErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanChangeSellToCustInPurchOrderWithoutLines()
    var
        Customer: Record Customer;
        PurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Special Order]
        // [SCENARIO 361615] "Sell-to Customer No." in purchase order can be changed if the order has no lines

        // [GIVEN] Purchase header without lines, but with "Sell-to Customer No." filled
        CreatePurchaseHeaderWithSellToCustomer(PurchHeader);

        // [WHEN] Change the "Sell-to Customer No." in the purchase order
        LibrarySales.CreateCustomer(Customer);
        PurchHeader.Validate("Sell-to Customer No.", Customer."No.");

        // [THEN] New value is accepted
        Assert.AreEqual(
          Customer."No.", PurchHeader."Sell-to Customer No.",
          StrSubstNo(ValidationErr, PurchHeader.FieldCaption("Sell-to Customer No."), Customer."No."));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure CopyDocumentDoesNotCopyItemTrackingFromPostedSalesInvoiceToQuote()
    var
        SalesHeader: Record "Sales Header";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Quote] [Invoice] [Copy Document] [Item Tracking]
        // [SCENARIO 376111] "Copy Document" does not copy item tracking lines from a posted sales invoice into a quote

        // [GIVEN] Post sales invoice with lot tracking
        Initialize();
        PostedInvoiceNo := CreateAndPostSalesOrderWithLotTracking();

        // [GIVEN] Create new sales quote
        // [WHEN] Run "Copy Document" to copy posted invoice into the new quote
        CopySalesDocument(
          SalesHeader, SalesHeader."Document Type"::Quote, "Sales Document Type From"::"Posted Invoice", PostedInvoiceNo);

        // [THEN] Sales quote does not have item tracking lines assigned
        VerifyReservationEntryIsEmpty(DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure CopyDocumentDoesNotCopyItemTrackingFromPostedPurchaseInvoiceToQuote()
    var
        PurchHeader: Record "Purchase Header";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Quote] [Invoice] [Copy Document] [Item Tracking]
        // [SCENARIO 376111] "Copy Document" does not copy item tracking lines from a posted purchase invoice into a quote

        // [GIVEN] Post purchase invoice with lot tracking
        Initialize();
        PostedInvoiceNo := CreateAndPostPurchaseOrderWithLotTracking();

        // [GIVEN] Create new purchase quote
        // [WHEN] Run "Copy Document" to copy posted invoice into the new quote
        CopyPurchaseDocument(
          PurchHeader, PurchHeader."Document Type"::Quote, "Purchase Document Type From"::"Posted Invoice", PostedInvoiceNo);

        // [THEN] Purchase quote does not have item tracking lines assigned
        VerifyReservationEntryIsEmpty(DATABASE::"Purchase Line", PurchHeader."Document Type".AsInteger(), PurchHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure CopyDocumentDoesNotCopyItemTrackingFromPostedSalesInvoiceToBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Blanket Order] [Invoice] [Copy Document] [Item Tracking]
        // [SCENARIO 376111] "Copy Document" does not copy item tracking lines from a posted sales invoice into a blanket order

        // [GIVEN] Post sales invoice with lot tracking
        Initialize();
        PostedInvoiceNo := CreateAndPostSalesOrderWithLotTracking();

        // [GIVEN] Create new blanket sales order
        // [WHEN] Run "Copy Document" to copy posted invoice into the new blanket order
        CopySalesDocument(
          SalesHeader, SalesHeader."Document Type"::"Blanket Order", "Sales Document Type From"::"Posted Invoice", PostedInvoiceNo);

        // [THEN] Blanket sales order does not have item tracking lines assigned
        VerifyReservationEntryIsEmpty(DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure CopyDocumentDoesNotCopyItemTrackingFromPostedPurchaseInvoiceToBlanketOrder()
    var
        PurchHeader: Record "Purchase Header";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Blanket Order] [Invoice] [Copy Document] [Item Tracking]
        // [SCENARIO 376111] "Copy Document" does not copy item tracking lines from a posted purchase invoice into a blanket order

        // [GIVEN] Post purchase invoice with lot tracking
        Initialize();
        PostedInvoiceNo := CreateAndPostPurchaseOrderWithLotTracking();

        // [GIVEN] Create new blanket purchase order
        // [WHEN] Run "Copy Document" to copy posted invoice into the new blanket order
        CopyPurchaseDocument(
          PurchHeader, PurchHeader."Document Type"::"Blanket Order", "Purchase Document Type From"::"Posted Invoice", PostedInvoiceNo);

        // [THEN] Blanket purchase order does not have item tracking lines assigned
        VerifyReservationEntryIsEmpty(DATABASE::"Purchase Line", PurchHeader."Document Type".AsInteger(), PurchHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValueEntryPurchOrderWithNegItemChargeAssignt()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemNo: Code[20];
        ItemChargeNo: Code[20];
        AmountSum: Decimal;
    begin
        // [FEATURE] [Item Charge] [Costing]
        // [SCENARIO 376009] Value entry Amounts for Posted Purchase Invoice equal to line Amounts when they are changed after shipping.

        // [GIVEN] Purchase Order with 2 lines: 1 - Item and 2 - negative Item Charge, assigned to Item, shipped.
        Initialize();
        CreatePurchaseDocumentWithAssignedItemCharge(PurchaseHeader, PurchaseHeader."Document Type"::Order, ItemNo, ItemChargeNo, -1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Reopen Purchase Order, Change Line Amounts for both lines.
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        AmountSum := UpdateLineAmounts(PurchaseHeader, LibraryRandom.RandDecInRange(10, 20, 2));

        // [WHEN] Invoice Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Value Entry Amounts contain last changed Amounts.
        VerifyCostAmountActualSum(ItemNo, AmountSum);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValueEntrySalesOrderWithNegItemChargeAssignt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        ItemChargeNo: Code[20];
        AmountSum: Decimal;
        ChargeQty: Decimal;
    begin
        // [FEATURE] [Item Charge] [Costing]
        // [SCENARIO 376009] Value entry Amounts for Posted Sales Invoice equal to line Amounts when they are changed after shipping.

        // [GIVEN] Sales Order with 2 lines: 1 - Item and 2 - negative Item Charge, assigned to Item, shipped.
        Initialize();
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        ItemNo := LibraryInventory.CreateItemNo();
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo,
          LibraryRandom.RandDecInRange(5, 10, 2), LibraryRandom.RandDecInRange(100, 200, 2));
        ItemChargeNo := LibraryInventory.CreateItemChargeNo();
        ChargeQty := -1; // Specific value needed for test
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", ItemChargeNo, ChargeQty,
          LibraryRandom.RandDecInRange(100, 200, 2));
        AssignItemChargeSales(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Reopen Sales Order, Change Line Amounts for both lines.
        LibrarySales.ReopenSalesDocument(SalesHeader);
        AmountSum := UpdateLineAmountsSales(SalesHeader, LibraryRandom.RandDecInRange(10, 20, 2));

        // [WHEN] Invoice Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Value Entry Amounts contain last changed Amounts.
        VerifySalesAmountActualSum(ItemNo, AmountSum);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseItemChargeNotPostedWhenQtyToInvoiceIsZero()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAmount: Decimal;
    begin
        // [FEATURE] [Item Charge] [Purchase]
        // [SCENARIO] Item charge is not posted when invoicing a purchase order if "Qty. to Invoice" = 0 on purchase line

        // [GIVEN] Create purchase order "PO1" and receive it without invoicing
        CreatePurchaseOrderPostReceipt(PurchRcptLine);

        // [GIVEN] Create purchase order "PO2"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        // [GIVEN] First purchase order line: type = item charge, unit cost = "X"
        AssignItemChargeToPostedReceiptLine(PurchaseHeader, 1, LibraryRandom.RandDec(100, 2), PurchRcptLine);

        // [GIVEN] Second purchase order line: type = item charge, unit cost = "Y"
        // [GIVEN] Assign both item charges to the posted purchase receipt
        ItemChargeAmount := LibraryRandom.RandDecInRange(101, 200, 2);
        AssignItemChargeToPostedReceiptLine(PurchaseHeader, 1, ItemChargeAmount, PurchRcptLine);

        // [GIVEN] Post purchase order "PO2" - receive only
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Reopen "PO2" and set "Quantity to Invoice" = 0 in the first line
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate("Qty. to Invoice", 0);
        PurchaseLine.Modify(true);

        // [WHEN] Invoice purchase order "PO2"
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] "Cost Amount (Actual)" = "Y" on the item ledger entry
        VerifyItemLedgEntryCostAmount(PurchRcptLine."No.", ItemChargeAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesItemChargeNotPostedWhenQtyToInvoiceIsZero()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        ItemChargeAmount: Decimal;
    begin
        // [FEATURE] [Item Charge] [Sales]
        // [SCENARIO] Item charge is not posted when invoicing a sales order if "Qty. to Invoice" = 0 on sales line

        // [GIVEN] Create sales order "SO1" and ship it without invoicing
        CreateSalesOrderPostShipment(SalesShipmentLine);

        // [GIVEN] Create sales order "SO2"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        // [GIVEN] First sales order line: type = item charge, unit price = "X"
        AssignItemChargeToPostedShipmentLine(SalesHeader, 1, LibraryRandom.RandDec(100, 2), SalesShipmentLine);

        // [GIVEN] Second sales order line: type = item charge, unit price = "Y"
        // [GIVEN] Assign both item charges to the posted sales shipment
        ItemChargeAmount := LibraryRandom.RandDecInRange(101, 200, 2);
        AssignItemChargeToPostedShipmentLine(SalesHeader, 1, ItemChargeAmount, SalesShipmentLine);

        // [GIVEN] Post sales order "SO2" - ship only
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Reopen "SO2" and set "Quantity to Invoice" = 0 in the first line
        LibrarySales.ReopenSalesDocument(SalesHeader);
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Qty. to Invoice", 0);
        SalesLine.Modify(true);

        // [WHEN] Invoice sales order "SO2"
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] "Sales Amount (Actual)" = "Y" on the item ledger entry
        VerifyItemLedgEntrySalesAmount(SalesShipmentLine."No.", '', ItemChargeAmount);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler2,ItemTrackingSummaryPageHandler,CreateInvtPutawayPickMvmtReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferOrderWithDifferentUOM()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // [FEATURE] [Item Tracking] [Transfer] [Inventory Put-away]
        // [SCENARIO 378627] Inventory Put-away line with correct Quantity created for Lot tracked Item Transfer order with different UOM.
        Initialize();

        // [GIVEN] Lot Tracked Item, create and release Purchase Order, assign Lot and receive.
        CreateLotTrackedItem(Item);
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, Item."No.", PurchaseLine.Type::Item, LocationBlue.Code, LibraryRandom.RandDec(100, 1), 0);
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        AssignLotNo := true;
        TrackingQuantity := PurchaseLine.Quantity;
        PurchaseLine.OpenItemTrackingLines(); // ItemTrackingPageHandler.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create Transfer Order to bin location for different UOM (Qty. per UOM < 1), assign Tracking, ship
        LibraryInventory.CreateItemUnitOfMeasureCode(
          ItemUnitOfMeasure, Item."No.", LibraryRandom.RandDecInDecimalRange(0.1, 0.9, 1));
        CreateAndReleaseTransferOrder(
          TransferHeader, TransferLine, LocationBlue.Code, LocationSilver2.Code, Item."No.", TrackingQuantity);
        TransferLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        TransferLine.Modify(true);
        AssignLotNo := false;
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound); // ItemTrackingPageHandler.
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [WHEN] Create Inventory Put-away
        TransferHeader.CreateInvtPutAwayPick();

        // [THEN] One Put-away line created with Transfer quantity
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField(Quantity, TrackingQuantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignSerialNoOrLotPageHandler,EnterQtyToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure OnePartiallyInvoicedPurchLineWithTrackingAndChargeAssignment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        ItemSNTracked: Record Item;
    begin
        // [FEATURE] [Purchase] [Item Tracking] [Item Charge] [Costing]
        // [SCENARIO 379405] Item Charge should be distributed equally to all Item Ledger Entries of Purchase Line with Serial No. tracking when the document is partially invoiced.
        Initialize();

        // [GIVEN] Item with Serial No. tracking.
        LibraryItemTracking.CreateSerialItem(ItemSNTracked);

        // [GIVEN] Tracked Purchase Line for the Item. "Qty. to Invoice" is set less than Quantity.
        LibraryPurchase.CreatePurchHeaderWithDocNo(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(), LibraryUtility.GenerateGUID());
        CreateAndTrackPurchaseLine(PurchaseHeader, PurchaseLine, ItemSNTracked."No.", TrackingMethod::"Serial No.");

        // [GIVEN] Purchase Line with Item Charge. The Charge is assigned to the line with Item.
        CreatePurchaseLineForItemCharge(PurchaseLineCharge, PurchaseHeader);
        InsertItemChargeAssignmentPurch(PurchaseLine, PurchaseLineCharge, PurchaseLineCharge.Quantity);

        // [WHEN] Post Purchase with "Receive and Invoice" option.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Item Charge is equally distributed to all Item Ledger Entries of posted Purchase.
        VerifyValueEntriesWithItemCharge(PurchaseLineCharge, ItemSNTracked."No.", 1); // 1 means 100% of charge is assigned to this line
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignSerialNoOrLotPageHandler,EnterQtyToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure TwoPartiallyInvoicedPurchLinesWithTrackingAndChargeAssignment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineSN: Record "Purchase Line";
        PurchaseLineLot: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        ItemSNTracked: Record Item;
        ItemLotTracked: Record Item;
        ChargeShareForLotTrackedLine: Decimal;
        ChargeShareForSNTrackedLine: Decimal;
    begin
        // [FEATURE] [Purchase] [Item Tracking] [Item Charge] [Costing]
        // [SCENARIO 379405] Item Charge should be distributed proportionally to Item Ledger Entries of two Purchase Lines with different tracking methods when the document is partially invoiced.
        Initialize();

        // [GIVEN] Items with Serial No. and Lot tracking.
        LibraryItemTracking.CreateSerialItem(ItemSNTracked);
        CreateLotTrackedItem(ItemLotTracked);

        // [GIVEN] Two tracked Purchase Lines ("L1" and "L2"), one for each Item. "Qty. to Invoice" is set less than Quantity for each line.
        // [GIVEN] (I.e. "L1" with 2 serial nos. "L1".Quantity = 2, "L1"."Qty. to Invoice" = 1;
        // [GIVEN] "L2" with a lot. "L2".Quantity = 5, L2."Qty. to Invoice" = 3.)
        LibraryPurchase.CreatePurchHeaderWithDocNo(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(), LibraryUtility.GenerateGUID());
        CreateAndTrackPurchaseLine(PurchaseHeader, PurchaseLineSN, ItemSNTracked."No.", TrackingMethod::"Serial No.");
        CreateAndTrackPurchaseLine(PurchaseHeader, PurchaseLineLot, ItemLotTracked."No.", TrackingMethod::Lot);

        // [GIVEN] Purchase Line with Item Charge (i.e. Amount = 100).
        CreatePurchaseLineForItemCharge(PurchaseLineCharge, PurchaseHeader);

        // [GIVEN] Assigned Item Charge to both Item lines in proportions (i.e. 40 to "L1" and 60 to "L2").
        ChargeShareForSNTrackedLine := LibraryRandom.RandInt(99) / 100; // maximum one line's share is 99%
        ChargeShareForLotTrackedLine := 1 - ChargeShareForSNTrackedLine;
        InsertItemChargeAssignmentPurch(PurchaseLineSN, PurchaseLineCharge, ChargeShareForSNTrackedLine);
        InsertItemChargeAssignmentPurch(PurchaseLineLot, PurchaseLineCharge, ChargeShareForLotTrackedLine);

        // [WHEN] Post Purchase with "Receive and Invoice" option.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Item Charge is distributed to Item Ledger Entries of both Purchase lines.
        // [THEN] Each Item Ledger Entry has a Value Entry with Item Charge.
        // [THEN] (I.e. "L1" has two Value Entries with Item Charge, each for 20;
        // [THEN] "L2" has one Value Entry with Item Charge for 60.)
        VerifyValueEntriesWithItemCharge(PurchaseLineCharge, ItemSNTracked."No.", ChargeShareForSNTrackedLine);
        VerifyValueEntriesWithItemCharge(PurchaseLineCharge, ItemLotTracked."No.", ChargeShareForLotTrackedLine);
    end;

    [Test]
    [HandlerFunctions('GetSalesOrdersReportHandler,OrderReportHandler,CarryOutActionMsgReqHandler')]
    [Scope('OnPrem')]
    procedure SpecialOrdersFromReqWkshPrintedTogether()
    var
        Purchasing: Record Purchasing;
        SalesHeader: array[2] of Record "Sales Header";
        Item: Record Item;
        Location: Record Location;
        SCMInventoryOrdersII: Codeunit "SCM Inventory Orders-II";
    begin
        // [FEATURE] [Special Order] [Requisition Worksheet]
        // [SCENARIO 365286] When several Purchase Orders are created for special Sales Orders via Requisition Worksheet, they are printed together.
        Initialize();

        // [GIVEN] Two Sales Orders for the same Customer, but on different locations
        CreatePurchasingCodeWithSpecialOrder(Purchasing);
        LibraryInventory.CreateItem(Item);
        CreateSalesOrderWithPurchasingCodeOnLocation(
          SalesHeader[1], SelectCustomer(), Item."No.", LibraryWarehouse.CreateLocation(Location), Purchasing.Code);

        CreateSalesOrderWithPurchasingCodeOnLocation(
          SalesHeader[2], SalesHeader[1]."Sell-to Customer No.", Item."No.", LibraryWarehouse.CreateLocation(Location), Purchasing.Code);

        // [GIVEN] Open Requisition Worksheet and run "Get Special Orders"
        OpenRequisitionWorksheetAndRunGetSpecialOrders(SalesHeader);

        // [WHEN] Carry out action messages
        BindSubscription(SCMInventoryOrdersII);
        CarryOutActionMessages(SalesHeader[1]."No." + '|' + SalesHeader[2]."No.", SalesHeader[1]."Posting Date");

        // [THEN] Two orders are printed together, it is check inside CheckTwoPurchaseOrdersOnBeforePrintDocument subscriber.
        // [THEN] Report for printing orders is run once.
        Assert.AreEqual(1, LibraryVariableStorage.Length(), WrongNoOfOrdersPrintedErr);
    end;

    [Test]
    [HandlerFunctions('GetSalesOrdersReportHandler,OrderReportHandler,CarryOutActionMsgReqHandler')]
    [Scope('OnPrem')]
    procedure SpecialOrdersFromReqWkshDiffPurchCodePrintedTogether()
    var
        Purchasing: array[2] of Record Purchasing;
        SalesHeader: array[2] of Record "Sales Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        Item: Record Item;
        Location: Record Location;
        SCMInventoryOrdersII: Codeunit "SCM Inventory Orders-II";
        LocationCode: Code[10];
    begin
        // [FEATURE] [Special Order] [Requisition Worksheet]
        // [SCENARIO 365286] When several Purchase Orders are created for special Sales Orders with different purchasing codes via Requisition Worksheet, they are printed together.
        Initialize();

        // [GIVEN] Two Sales Orders for the same Customer, on the same locations, but with different Purchasing Codes
        LocationCode := LibraryWarehouse.CreateLocation(Location);
        CreatePurchasingCodeWithSpecialOrder(Purchasing[1]);
        CreatePurchasingCodeWithSpecialOrder(Purchasing[2]);
        LibraryInventory.CreateItem(Item);
        CreateSalesOrderWithPurchasingCodeOnLocation(
          SalesHeader[1], SelectCustomer(), Item."No.", LocationCode, Purchasing[1].Code);

        CreateSalesOrderWithPurchasingCodeOnLocation(
          SalesHeader[2], SalesHeader[1]."Sell-to Customer No.", Item."No.", LocationCode, Purchasing[2].Code);

        // [GIVEN] Open Requisition Worksheet and run "Get Special Orders"
        OpenRequisitionWorksheetAndRunGetSpecialOrders(SalesHeader);

        // [WHEN] Carry out action messages
        BindSubscription(SCMInventoryOrdersII);
        CarryOutActionMessages(SalesHeader[1]."No." + '|' + SalesHeader[2]."No.", SalesHeader[1]."Posting Date");

        // [THEN] Two orders are printed together, it is check inside CheckTwoPurchaseOrdersOnBeforePrintDocument subscriber.
        // [THEN] Report for printing orders is run once.
        Assert.AreEqual(1, LibraryVariableStorage.Length(), WrongNoOfOrdersPrintedErr);

        // [THEN] Two purchase line exist, each related with own sales line
        FindPurchaseLineBySalesSpecialOrder(PurchaseLine[1], SalesHeader[1]);
        FindPurchaseLineBySalesSpecialOrder(PurchaseLine[2], SalesHeader[2]);

        // [THEN] Fields "Purchasing Code" of created purchasing lines are corresponding to "Purchasing Code" of sales lines.
        Assert.AreEqual(Purchasing[1].Code, PurchaseLine[1]."Purchasing Code", WrongValueOfPurchCodeErr);
        Assert.AreEqual(Purchasing[2].Code, PurchaseLine[2]."Purchasing Code", WrongValueOfPurchCodeErr);
    end;

    [Test]
    [HandlerFunctions('GetSalesOrdersReportHandler,OrderReportHandler,CarryOutActionMsgReqHandler')]
    [Scope('OnPrem')]
    procedure SpecialOrdersFromReqWkshCreatedPrintedMatchDiffLocationsInLines()
    var
        Purchasing: Record Purchasing;
        SalesHeader: array[2] of Record "Sales Header";
        Item: Record Item;
        Vendor: Record Vendor;
        RequisitionLine: Record "Requisition Line";
        Location: Record Location;
        GetSalesOrders: Report "Get Sales Orders";
        SCMInventoryOrdersII: Codeunit "SCM Inventory Orders-II";
        HeaderLocationCode: Code[10];
        Created: Integer;
        i: Integer;
    begin
        // [FEATURE] [Special Order] [Requisition Worksheet]
        // [SCENARIO 201608] When several Purchase Orders are created for special Sales Orders via Requisition Worksheet, the quantity of created and printed orders is the same.
        // [SCENARIO 365286] When several Purchase Orders are created for special Sales Orders via Requisition Worksheet, they are printed together.
        Initialize();

        // [GIVEN] Two Sales Orders for the same Customer, each with one line, with a same location in headers but with different locations in lines.
        CreatePurchasingCodeWithSpecialOrder(Purchasing);
        LibraryInventory.CreateItem(Item);
        HeaderLocationCode := LibraryWarehouse.CreateLocation(Location);
        CreateSalesOrderWithPurchasingCodeWithDiffLocationsInHeaderAndInLine(
          SalesHeader[1], SelectCustomer(), Item."No.", HeaderLocationCode, LibraryWarehouse.CreateLocation(Location), Purchasing.Code);

        CreateSalesOrderWithPurchasingCodeWithDiffLocationsInHeaderAndInLine(
          SalesHeader[2], SalesHeader[1]."Sell-to Customer No.", Item."No.",
          HeaderLocationCode, LibraryWarehouse.CreateLocation(Location), Purchasing.Code);

        // [GIVEN] Open Requisition Worksheet and run "Special Order - Get Sales Orders".
        CreateRequisitionLine(RequisitionLine);
        LibraryVariableStorage.Enqueue(SalesHeader[1]."No." + '|' + SalesHeader[2]."No.");
        GetSalesOrders.SetReqWkshLine(RequisitionLine, 1); // Special Order.
        Commit();
        GetSalesOrders.RunModal();

        CreateVendorWithShipmentMethodCode(Vendor, SalesHeader[1]."Shipment Method Code");
        for i := 1 to 2 do
            UpdateVendorOnRequisitionLine(RequisitionLine, SalesHeader[i]."No.", Vendor."No.");

        // [WHEN] Carry out action messages.
        BindSubscription(SCMInventoryOrdersII);
        UpdateReportSelection(REPORT::Order);
        RequisitionLine.SetFilter("Sales Order No.", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.");
        CarryOutReqWkshWithRequestPage(
          RequisitionLine, RequisitionLine."Expiration Date", RequisitionLine."Order Date",
          SalesHeader[1]."Posting Date", SalesHeader[1]."Posting Date");

        // [THEN] Two Purchase Orders are created.
        Created := CountPurchaseOrdersFromVendor(Vendor."No.");
        Assert.AreEqual(2, Created, '');

        // [THEN] These Orders are printed together, it is check inside CheckTwoPurchaseOrdersOnBeforePrintDocument subscriber.
        // [THEN] Report for printing orders is run once.
        Assert.AreEqual(1, LibraryVariableStorage.Length(), WrongNoOfOrdersPrintedErr);
    end;

    [Test]
    [HandlerFunctions('GetSalesOrdersReportHandler,OrderReportHandler,CarryOutActionMsgReqHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentFromReqWkshCreatedPrintedMatchDiffLocationsInLines()
    var
        Purchasing: Record Purchasing;
        SalesHeader: array[2] of Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        Vendor: Record Vendor;
        RequisitionLine: Record "Requisition Line";
        GetSalesOrders: Report "Get Sales Orders";
        SCMInventoryOrdersII: Codeunit "SCM Inventory Orders-II";
        Created: Integer;
        i: Integer;
    begin
        // [FEATURE] [Drop Shipment] [Requisition Worksheet]
        // [SCENARIO 201608] When several purchase orders are created for sales orders with drop shipment via requisition worksheet, the quantity of created and printed orders is the same.
        // [SCENARIO 365286] When several Purchase Orders are created for Sales Orders with drop shipment via Requisition Worksheet, Purchase Oreders are printed together.
        Initialize();

        // [GIVEN] Two sales orders "S1" and "S2" for the same customer, each with a single line with a same item, with a same Purchasing Code with Drop Shipment.
        CreatePurchasingCodeWithDropShipment(Purchasing);
        CreateCustomerWithAddress(Customer);
        LibraryInventory.CreateItem(Item);

        for i := 1 to 2 do
            CreateSalesOrderWithCustomerNoAndPurchasingCode(SalesHeader[i], Customer."No.", Item."No.", Purchasing.Code);

        // [GIVEN] "S2"."Ship-to Address 2" is different from "S1"
        ModifySalesHeaderWithMultipleAddress(SalesHeader[2]);

        // [GIVEN] Open Requisition Worksheet and run "Drop Shipment - Get Sales Orders".
        CreateRequisitionLine(RequisitionLine);
        LibraryVariableStorage.Enqueue(SalesHeader[1]."No." + '|' + SalesHeader[2]."No.");
        GetSalesOrders.SetReqWkshLine(RequisitionLine, 0); // No special Order.
        Commit();
        GetSalesOrders.RunModal();

        LibraryPurchase.CreateVendor(Vendor);
        for i := 1 to 2 do
            UpdateVendorOnRequisitionLine(RequisitionLine, SalesHeader[i]."No.", Vendor."No.");

        // [WHEN] Carry out action messages.
        BindSubscription(SCMInventoryOrdersII);
        UpdateReportSelection(REPORT::Order);
        RequisitionLine.SetFilter("Sales Order No.", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.");
        CarryOutReqWkshWithRequestPage(
          RequisitionLine, RequisitionLine."Expiration Date", RequisitionLine."Order Date",
          SalesHeader[1]."Posting Date", SalesHeader[1]."Posting Date");

        Created := CountPurchaseOrdersFromVendor(Vendor."No.");

        // [THEN] Two Purchase Orders are created.
        Assert.AreEqual(2, Created, StrSubstNo(WrongNoOfOrdersCreatedErr, 2));

        // [THEN] These Orders are printed together, it is check inside CheckTwoPurchaseOrdersOnBeforePrintDocument subscriber.
        // [THEN] Report for printing orders is run once.
        Assert.AreEqual(1, LibraryVariableStorage.Length(), WrongNoOfOrdersPrintedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemEntryCostOnPostingPurchInvoiceWithItemChargeReceivedInPurchOrder()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        ItemNo: Code[20];
        ItemChargeNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice] [Item Charge] [Get Receipt Lines]
        // [SCENARIO 211014] The cost of purchase should consist of the direct unit cost of purchase line and the cost of the item charge assigned to that line, if the purchase invoice is created via Get Receipt Lines function.
        Initialize();

        // [GIVEN] Purchase Order with a line of item type and a line of item charge type. Total amount of the purchase = "X".
        // [GIVEN] The item charge is assigned to the item line.
        // [GIVEN] The Purchase Order is received.
        CreatePurchaseDocumentWithAssignedItemCharge(
          PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, ItemNo, ItemChargeNo, LibraryRandom.RandInt(10));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // [GIVEN] Purchase Invoice is created and filled with received lines by Get Receipt Lines function.
        CreatePurchaseInvoiceViaGetReceiptLines(PurchaseHeaderInvoice, PurchaseHeaderOrder);

        // [WHEN] Post the Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true);

        // [THEN] The cost of the item entry representing the purchase = "X".
        PurchaseHeaderOrder.CalcFields(Amount);
        VerifyItemLedgEntryCostAmount(ItemNo, PurchaseHeaderOrder.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemEntryCostOnPostingPurchCrMemoWithItemChargeShippedInSalesReturnOrder()
    var
        PurchaseHeaderRetOrder: Record "Purchase Header";
        PurchaseHeaderCrMemo: Record "Purchase Header";
        ItemNo: Code[20];
        ItemChargeNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Item Charge] [Get Return Shipment Lines]
        // [SCENARIO 211014] The cost of purchase return should consist of the direct unit cost of purchase return line and the cost of the item charge assigned to that line, if the purchase credit memo is created via Get Return Shipment Lines function.
        Initialize();

        // [GIVEN] Purchase Return Order with a line of item type and a line of item charge type. Total amount of the purchase = "X".
        // [GIVEN] The item charge is assigned to the item line.
        // [GIVEN] The Purchase Return Order is shipped.
        CreatePurchaseDocumentWithAssignedItemCharge(
          PurchaseHeaderRetOrder, PurchaseHeaderRetOrder."Document Type"::"Return Order", ItemNo, ItemChargeNo, LibraryRandom.RandInt(10));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderRetOrder, true, false);

        // [GIVEN] Purchase Credit Memo is created and filled with shipped lines by Get Return Shipment Lines function.
        CreatePurchaseCreditMemoViaGetReturnShipmentLines(PurchaseHeaderCrMemo, PurchaseHeaderRetOrder);

        // [WHEN] Post the Purchase Credit Memo.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderCrMemo, true, true);

        // [THEN] The cost of the item entry representing the purchase return = "X".
        PurchaseHeaderRetOrder.CalcFields(Amount);
        VerifyItemLedgEntryCostAmount(ItemNo, -PurchaseHeaderRetOrder.Amount);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignSerialNoOrLotPageHandler,EnterQtyToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ItemEntryCostWithItemChargesRevertedByCrMemoCopiedFromPurchInvoice()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        InvoiceNo: Code[20];
        ReceiptNo: Code[20];
        i: Integer;
        UnitCost: Decimal;
        TotalChargeAmount: Decimal;
        ExpectedValueEntryCount: Integer;
    begin
        // [FEATURE] [Purchase] [Item Charge] [Copy Document] [Item Tracking]
        // [SCENARIO 288429] Credit Memo reverses multiple item charges without rounding errors
        Initialize();
        // [GIVEN] Item 'X' with serial number tracking
        LibraryItemTracking.CreateSerialItem(Item);
        // [GIVEN] posted Receipt 'R' from Purchase Order, where Item is 'X', Quantity is 3,
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLine(
          PurchaseHeader, Item."No.", PurchaseLine.Type::Item, '', 3, LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        // [GIVEN] assigned serial numbers "X1,X2,X3"
        LibraryVariableStorage.Enqueue(TrackingMethod::"Serial No.");
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(3);
        LibraryVariableStorage.Enqueue(3);
        PurchaseLine.OpenItemTrackingLines(); // handled by ItemTrackingAssignSerialNoOrLotPageHandler
        ReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        // [GIVEN] 3 Value Entries are posted
        ExpectedValueEntryCount := 3;
        ValueEntry.SetRange("Item No.", Item."No.");
        Assert.RecordCount(ValueEntry, ExpectedValueEntryCount);
        VerifyItemLedgEntriesAmount(Item."No.", 0, 0, true);

        // [GIVEN] posted Invoice 'I' to another vendor, where are three Item Charge lines:
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        // [GIVEN] Each Item charge line has "Quantity" = 1 is assigned to receipt line from 'R':"IC1" = 5, "IC2" = 10, "IC3" = 15
        PurchRcptLine.SetRange("Document No.", ReceiptNo);
        PurchRcptLine.FindFirst();
        for i := 1 to 3 do begin
            UnitCost := 5.0 * i;
            AssignItemChargeToPostedReceiptLine(PurchaseHeader, 1, UnitCost, PurchRcptLine);
            TotalChargeAmount += UnitCost;
        end;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [GIVEN] 9 Value Entries are posted, total "Cost Amount (Actual)" is 30
        ExpectedValueEntryCount += 9;
        Assert.RecordCount(ValueEntry, ExpectedValueEntryCount);
        VerifyItemLedgEntriesAmount(Item."No.", 0, TotalChargeAmount, true);

        // [WHEN] Posted Credit memo, that is created by "Copy Document" from posted invoice 'I'
        CopyPurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", "Purchase Document Type From"::"Posted Invoice", InvoiceNo);
        PurchaseHeader."Vendor Cr. Memo No." := LibraryUtility.GenerateGUID();
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] 9 Value Entries are posted that fully reversed cost amount of Value Entries posted by 'I'
        ExpectedValueEntryCount += 9;
        Assert.RecordCount(ValueEntry, ExpectedValueEntryCount);
        VerifyItemLedgEntriesAmount(Item."No.", 0, 0, true);
        // [THEN] Each of 3 Item Ledger Entries have "Cost Amount (Actual)" = 0
        VerifyItemLedgEntriesAmount(Item."No.", 0, 0, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignSerialNoOrLotPageHandler,EnterQtyToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ItemEntryCostWithItemChargesRevertedByCrMemoCopiedFromSalesInvoice()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        SalesShipmentLine: Record "Sales Shipment Line";
        InvoiceNo: Code[20];
        ShipmentNo: Code[20];
        i: Integer;
        UnitPrice: Decimal;
        TotalChargeAmount: Decimal;
        ExpectedValueEntryCount: Integer;
    begin
        // [FEATURE] [Sales] [Item Charge] [Copy Document] [Item Tracking]
        // [SCENARIO 288429] Credit Memo reverses multiple item charges without rounding errors
        Initialize();
        // [GIVEN] Item 'X' with serial number tracking
        LibraryItemTracking.CreateSerialItem(Item);
        // [GIVEN] Recieved Purchase Order, where Item is 'X', Quantity is 3,
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLine(
          PurchaseHeader, Item."No.", PurchaseLine.Type::Item, '', 3, LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        // [GIVEN] assigned serial numbers "X1,X2,X3"
        LibraryVariableStorage.Enqueue(TrackingMethod::"Serial No.");
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(3);
        LibraryVariableStorage.Enqueue(3);
        PurchaseLine.OpenItemTrackingLines(); // handled by ItemTrackingAssignSerialNoOrLotPageHandler
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        // [GIVEN] 3 Value Entries are posted
        ExpectedValueEntryCount := 3;
        ValueEntry.SetRange("Item No.", Item."No.");
        Assert.RecordCount(ValueEntry, ExpectedValueEntryCount);

        // [GIVEN] posted Shipment 'S' from Sales Order, where Item is 'X', Quantity is 3,
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 3, LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        // [GIVEN] assigned serial numbers "X1,X2,X3"
        LibraryVariableStorage.Enqueue(TrackingMethod::"Serial No.");
        LibraryVariableStorage.Enqueue(true);
        SalesLine.OpenItemTrackingLines(); // handled by ItemTrackingAssignSerialNoOrLotPageHandler
        ShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);
        // [GIVEN] 3 Value Entries are posted
        ExpectedValueEntryCount += 3;
        Assert.RecordCount(ValueEntry, ExpectedValueEntryCount);
        VerifyItemLedgEntriesAmount(Item."No.", 1, 0.0, true);

        // [GIVEN] posted Invoice 'I' to another vendor, where are three Item Charge lines:
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        // [GIVEN] Each Item charge line has "Quantity" = 1 is assigned to shipment line from 'S':"IC1" = 5, "IC2" = 10, "IC3" = 15
        SalesShipmentLine.SetRange("Document No.", ShipmentNo);
        SalesShipmentLine.FindFirst();
        for i := 1 to 3 do begin
            UnitPrice := 5.0 * i;
            AssignItemChargeToPostedShipmentLine(SalesHeader, 1, UnitPrice, SalesShipmentLine);
            TotalChargeAmount += UnitPrice;
        end;
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // [GIVEN] 9 Value Entries are posted, total "Sales Amount (Actual)" is 30
        ExpectedValueEntryCount += 9;
        Assert.RecordCount(ValueEntry, ExpectedValueEntryCount);
        VerifyItemLedgEntriesAmount(Item."No.", 1, TotalChargeAmount, true);

        // [WHEN] Posted Credit memo, that is created by "Copy Document" from posted invoice 'I'
        CopySalesDocument(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", "Purchase Document Type From"::"Posted Invoice", InvoiceNo);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] 9 Value Entries are posted that fully reversed sales amount of Value Entries posted by 'I'
        ExpectedValueEntryCount += 9;
        Assert.RecordCount(ValueEntry, ExpectedValueEntryCount);
        VerifyItemLedgEntriesAmount(Item."No.", 1, 0.0, true);
        // [THEN] Each of 3 Item Ledger Entries have "Sales Amount (Actual)" = 0
        VerifyItemLedgEntriesAmount(Item."No.", 1, 0.0, false);
    end;

    [Test]
    [HandlerFunctions('GetSalesOrdersReportHandler,OrderReportHandler,CarryOutActionMsgReqHandler')]
    [Scope('OnPrem')]
    procedure DropShptFromReqWkshWithDiffShipAddressInMultipleSalesOrders()
    var
        Vendor: Record Vendor;
        Purchasing: Record Purchasing;
        SalesHeader: array[3] of Record "Sales Header";
        PurchaseLine: array[3] of Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesOrderFilter: Text;
        ShipToAddress: array[2] of Text[100];
        i: Integer;
    begin
        // [FEATURE] [Drop Shipment] [Requisition Worksheet]
        // [SCENARIO 215292] Purchase Order created when Ship-To Address of Sales Drop Shipment is changed via Requisition Worksheet

        Initialize();

        // [GIVEN] Three sales orders with "Purchasing Code" = "Drop shipment", for the same customer - "SO1","SO2","SO3". "Ship-to Address" for "SO1" is "X", for "SO2" and "SO3" is "Y"
        CreatePurchasingCodeWithDropShipment(Purchasing);
        LibraryInventory.CreateItem(Item);
        for i := 1 to ArrayLen(ShipToAddress) do
            ShipToAddress[i] := LibraryUtility.GenerateGUID();
        CreateSalesOrderWithPurchCodeAndAddress(
          SalesHeader[1], SelectCustomer(), Item."No.", Purchasing.Code, ShipToAddress[1]);
        CreateSalesOrderWithPurchCodeAndAddress(
          SalesHeader[2], SalesHeader[1]."Sell-to Customer No.", Item."No.", Purchasing.Code, ShipToAddress[2]);
        CreateSalesOrderWithPurchCodeAndAddress(
          SalesHeader[3], SalesHeader[1]."Sell-to Customer No.", Item."No.", Purchasing.Code, ShipToAddress[2]);

        // [GIVEN] Open requisition worksheet and run "Get Sales Orders"
        SalesOrderFilter := SalesHeader[1]."No." + '|' + SalesHeader[2]."No." + '|' + SalesHeader[3]."No.";
        GetDropShipmentInReqWorksheet(RequisitionLine, SalesOrderFilter);
        CreateVendorWithShipmentMethodCode(Vendor, SalesHeader[1]."Shipment Method Code");
        for i := 1 to ArrayLen(SalesHeader) do
            UpdateVendorOnRequisitionLine(RequisitionLine, SalesHeader[i]."No.", Vendor."No.");

        // [WHEN] Carry out action messages
        CarryOutActionMessages(SalesOrderFilter, SalesHeader[1]."Posting Date");

        // [THEN] Two orders are created
        Assert.AreEqual(2, CountPurchaseOrdersFromVendor(Vendor."No."), StrSubstNo(WrongNoOfOrdersCreatedErr, 2));

        // [THEN] Three purchase line are created, each related to own sales line
        FindPurchaseLineBySalesDropShpment(PurchaseLine[1], SalesHeader[1]);
        FindPurchaseLineBySalesDropShpment(PurchaseLine[2], SalesHeader[2]);
        FindPurchaseLineBySalesDropShpment(PurchaseLine[3], SalesHeader[3]);

        // [THEN] Each Purchase Line has "Purchasing Code" = "Drop Shipment"
        for i := 1 to ArrayLen(PurchaseLine) do
            Assert.AreEqual(Purchasing.Code, PurchaseLine[i]."Purchasing Code", WrongValueOfPurchCodeErr);
    end;

    [Test]
    [HandlerFunctions('GetSalesOrdersReportHandler,OrderReportHandler')]
    [Scope('OnPrem')]
    procedure SpecialOrderFromReqWkshWithDiffShipAddressInMultipleSalesOrders()
    var
        Purchasing: Record Purchasing;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Special Order] [Requisition Worksheet] [Planning] [Purchase]
        // [SCENARIO 311897] Planning several lines for special order on one location results in a single purchase order.
        Initialize();

        // [GIVEN] Sales order with three lines - 1st line on location "BLUE", 2nd and 3rd line on location "RED".
        // [GIVEN] All lines are set up for special order.
        CreatePurchasingCodeWithSpecialOrder(Purchasing);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLineWithLocationCodeAndPurchasing(SalesLine, SalesHeader, LocationBlue.Code, Purchasing.Code);
        CreateSalesLineWithLocationCodeAndPurchasing(SalesLine, SalesHeader, LocationRed.Code, Purchasing.Code);
        CreateSalesLineWithLocationCodeAndPurchasing(SalesLine, SalesHeader, LocationRed.Code, Purchasing.Code);

        // [GIVEN] Open requisition worksheet and run "Special Order - Get Sales Orders".
        GetSpecialOrderInReqWorksheet(RequisitionLine, SalesHeader."No.");

        // [GIVEN] Set "Vendor No." on the planning lines.
        VendorNo := LibraryPurchase.CreateVendorNo();
        RequisitionLine.SetRange("Sales Order No.", SalesHeader."No.");
        RequisitionLine.ModifyAll("Vendor No.", VendorNo, true);

        // [WHEN] Carry out action messages.
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);

        // [THEN] Two orders are created.
        Assert.AreEqual(2, CountPurchaseOrdersFromVendor(VendorNo), '');

        // [THEN] The purchase order on location "BLUE" has one line.
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.SetRange("Location Code", LocationBlue.Code);
        PurchaseHeader.FindFirst();
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        Assert.RecordCount(PurchaseLine, 1);

        // [THEN] The purchase order on location "RED" has two lines.
        PurchaseHeader.SetRange("Location Code", LocationRed.Code);
        PurchaseHeader.FindFirst();
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        Assert.RecordCount(PurchaseLine, 2);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LocationCodeIsCopiedFromSalesToPurchaseWithSpecialOrder()
    var
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Special Order] [Location]
        // [SCENARIO 218068] Location code should be forwarded from sales order to purchase order populated with Special Order - Get Sales Order function.
        Initialize();

        // [GIVEN] Sales order "SO" set up for Special Order. Location code on the sales line = "X".
        CreateSalesOrderWithPurchasingCodeSpecialOrder(SalesHeader, CreateItem());

        // [GIVEN] Location code is updated to "Y" on "SO" header.
        LibraryWarehouse.CreateLocation(Location);
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);

        // [WHEN] Create purchase order "PO" from "SO" with Special Order - Get Sales Order function.
        CreatePurchaseOrderAndGetSpecialOrder(PurchaseHeader, SalesHeader, '');

        // [THEN] Location code on "PO" header is equal to "Y".
        PurchaseHeader.TestField("Location Code", SalesHeader."Location Code");

        // [THEN] Location code on "PO" line = location code on "SO" line = "X".
        FindSalesLine(SalesLine, SalesHeader);
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.TestField("Location Code", SalesLine."Location Code");

        // [THEN] "X" <> "Y".
        Assert.AreNotEqual(PurchaseLine."Location Code", PurchaseHeader."Location Code", WrongLocationCodeOnLineErr);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTranslationInPurchLineCreatedFromSalesWithSpecialOrder()
    var
        Item: Record Item;
        ItemTranslation: Record "Item Translation";
        Vendor: Record Vendor;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Special Order] [Item Translation]
        // [SCENARIO 218068] Purchase line descriptions should be taken from item translation when the purchase order is created with Special Order - Get Sales Order function.
        Initialize();

        // [GIVEN] Item with item translation into language "L".
        // [GIVEN] Description and "Description 2" in "L" are "DL1" and "DL2" respectively.
        LibraryInventory.CreateItem(Item);
        CreateItemTranslation(ItemTranslation, Item."No.");

        // [GIVEN] Vendor "V" with language code "L".
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Language Code", ItemTranslation."Language Code");
        Vendor.Modify(true);

        // [GIVEN] Sales order "SO" set up for Special Order.
        CreateSalesOrderWithPurchasingCodeSpecialOrder(SalesHeader, Item."No.");

        // [WHEN] Create purchase order with vendor "V" from sales order "SO" using Special Order - Get Sales Order function.
        CreatePurchaseOrderAndGetSpecialOrder(PurchaseHeader, SalesHeader, Vendor."No.");

        // [THEN] Description and "Description 2" on the purchase line are equal to "DL1" and "DL2" respectively.
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.TestField(Description, ItemTranslation.Description);
        PurchaseLine.TestField("Description 2", ItemTranslation."Description 2");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ItemInventoryValueZeroCOGSAndInventoryAdjmtAccountsBlank()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Item] [Inventory Value Zero] [COGS]
        // [SCENARIO 227359] When item has "Inventory Value Zero" on then "General Posting Setup" can have "COGS Account" and "Inventory Adjmt. Account" blank for posting
        Initialize();

        // [GIVEN] "Inventory Setup" has "Expected Cost Posting to G/L" on and "Automatic Cost Adjustment" = Always
        LibraryInventory.SetExpectedCostPosting(true);
        LibraryInventory.SetAutomaticCostAdjmtAlways();

        // [GIVEN] "General Posting Setup" has blank "COGS Account" and "Inventory Adjmt. Account"
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        GeneralPostingSetup.Validate("COGS Account", '');
        GeneralPostingSetup.Validate("Inventory Adjmt. Account", '');
        GeneralPostingSetup.Modify(true);

        SetupItemCustomerPostingGroups(Item, Customer, GeneralPostingSetup);

        // [GIVEN] Item "I" has "Inventory Value Zero" on and "Costing Method" = FIFO
        Item.Validate("Inventory Value Zero", true);
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Modify(true);

        // [GIVEN] Inventory of "I" is posted through positive adjustment with quantity "Q"
        Qty := LibraryRandom.RandInt(10);
        PostPositiveAdjustment(GeneralPostingSetup."Gen. Bus. Posting Group", Item."No.", Qty);

        // [GIVEN] Sales Order "S" of "I" with quantity "Q" is created and its shipment is posted
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", Item."No.", Qty, '', WorkDate());
        SalesLine.Validate(Amount, LibraryRandom.RandInt(200));
        SalesLine.Validate("Unit Cost", 10);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        SalesShipmentLine.SetRange("No.", Item."No.");
        SalesShipmentLine.FindFirst();

        // [WHEN] Undo sales shipment for "S"
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);

        // [THEN] in "S" "Qty. to Ship" = "Q"
        SalesLine.Find();
        SalesLine.TestField("Qty. to Ship", Qty);
    end;

    [Test]
    [HandlerFunctions('GetSalesOrdersReportHandler,OrderReportHandler,CarryOutActionMsgReqHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentFromReqWkshCreatedPrintedMatchDiffCustomersBlankAddressDetails()
    var
        Purchasing: Record Purchasing;
        SalesHeader: array[2] of Record "Sales Header";
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        GetSalesOrders: Report "Get Sales Orders";
        SCMInventoryOrdersII: Codeunit "SCM Inventory Orders-II";
        Created: Integer;
        i: Integer;
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 234009] Purchase Orders are created separately if they have different customers as source with drop shipment.
        // [SCENARIO 365286] All Purchase Orders are printed together.
        Initialize();

        // [GIVEN] Two sales orders "S1" and "S2" for different customers, each with a single line with a same item, with a same Purchasing Code with Drop Shipment, no address details
        CreatePurchasingCodeWithDropShipment(Purchasing);
        LibraryInventory.CreateItem(Item);

        for i := 1 to 2 do begin
            CreateSalesOrderWithCustomerNoAndPurchasingCode(SalesHeader[i], LibrarySales.CreateCustomerNo(), Item."No.", Purchasing.Code);
            ClearDropSipmentSalesOrderAddressDetails(SalesHeader[i]);
        end;

        // [GIVEN] Open requisition worksheet and run "Drop Shipment - Get Sales Orders".
        CreateRequisitionLine(RequisitionLine);
        LibraryVariableStorage.Enqueue(SalesHeader[1]."No." + '|' + SalesHeader[2]."No.");
        GetSalesOrders.SetReqWkshLine(RequisitionLine, 0); // No special Order.
        Commit();
        GetSalesOrders.RunModal();

        // [WHEN] Carry out action messages.
        BindSubscription(SCMInventoryOrdersII);
        Created := UpdateAndCarryOut(RequisitionLine, SalesHeader);

        // [THEN] Two orders are created.
        Assert.AreEqual(2, Created, StrSubstNo(WrongNoOfOrdersCreatedErr, 2));

        // [THEN] These Orders are printed together, it is check inside CheckTwoPurchaseOrdersOnBeforePrintDocument subscriber.
        // [THEN] Report for printing orders is run once.
        Assert.AreEqual(1, LibraryVariableStorage.Length(), WrongNoOfOrdersPrintedErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure NegativeItemChargeQtyOnSalesCrMemoLineGeneratesPositiveValueEntry()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        PostedInvoiceNo: Code[20];
        LotNos: array[2] of Code[20];
        Qty: Decimal;
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo] [Item Charge]
        // [SCENARIO 278165] Posting of a negative sales credit memo line for item charge results in a value entry with positive "Sales Amount (Actual)".
        Initialize();

        LotNos[1] := LibraryUtility.GenerateGUID();
        LotNos[2] := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandInt(10);
        UnitPrice := LibraryRandom.RandDecInRange(10, 20, 2);

        // [GIVEN] Lot-tracked item "I". Lot "L1" is in the inventory.
        LibraryItemTracking.CreateLotItem(Item);
        MakeTrackedItemStock(Item."No.", LotNos[1]);

        // [GIVEN] Sales order with two lines.
        // [GIVEN] 1st line is positive: Item No. = "I", Lot No. = "L1", Quantity = 10, Unit Price = 200 LCY.
        // [GIVEN] 2nd line is negative: Item No. = "I", Lot No. = "L2", Quantity = -10, Unit Price = 100 LCY.
        // [GIVEN] Post the sales order with ship and invoice.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLineAndAssignOneLotNo(SalesLine, SalesHeader, Item."No.", Qty, 2 * UnitPrice, LotNos[1]);
        CreateSalesLineAndAssignOneLotNo(SalesLine, SalesHeader, Item."No.", -Qty, UnitPrice, LotNos[2]);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Sales credit memo with two lines for item charges.
        // [GIVEN] 1st line is positive and the item charge is assigned to the 1st line of the posted shipment: Quantity = 10, Unit Price = 200 LCY.
        // [GIVEN] 2nd line is negative and the item charge is assigned to the 2nd line of the posted shipment: Quantity = -10, Unit Price = 100 LCY.
        // [GIVEN] The overall amount of the sales credit memo should be positive, hence the higher unit price on the first line.
        // [GIVEN] Otherwise, the sales credit memo cannot be posted.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        FindSalesShipmentLine(SalesShipmentLine, Item."No.");
        AssignItemChargeToPostedShipmentLine(SalesHeader, SalesShipmentLine.Quantity, SalesShipmentLine."Unit Price", SalesShipmentLine);
        SalesShipmentLine.Next();
        AssignItemChargeToPostedShipmentLine(SalesHeader, SalesShipmentLine.Quantity, SalesShipmentLine."Unit Price", SalesShipmentLine);

        // [WHEN] Post the sales credit memo.
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] A value entry with negative "Valued Quantity" = -10 and "Sales Amount (Actual)" = -200 LCY has been added to the sales of lot "L1".
        // [THEN] That makes the overall sales amount of lot "L1" = 0.
        VerifyValuedQtyAndSalesAmountOnValueEntry(PostedInvoiceNo, Item."No.", LotNos[1], -Qty, -2 * UnitPrice * Qty);

        // [THEN] A value entry with positive "Valued Quantity" = 10 and "Sales Amount (Actual)" = 100 LCY has been added to the sales of lot "L2".
        // [THEN] That makes the overall sales amount of lot "L2" = 0.
        VerifyValuedQtyAndSalesAmountOnValueEntry(PostedInvoiceNo, Item."No.", LotNos[2], Qty, UnitPrice * Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure NegItemChargeQtyOnSalesCrMemoLineGeneratesPosValueEntryToEveryILEInDistribution()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        PostedInvoiceNo: Code[20];
        LotNos: array[4] of Code[20];
        Qty: Decimal;
        QtyPerLot: Decimal;
        UnitPrice: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Sales] [Credit Memo] [Item Charge]
        // [SCENARIO 278165] Posting of a negative sales credit memo line for item charge results in a value entry with positive "Sales Amount (Actual)" for each sales item entry the charge is distributed into.
        Initialize();

        for i := 1 to ArrayLen(LotNos) do
            LotNos[i] := LibraryUtility.GenerateGUID();
        Qty := 2 * LibraryRandom.RandInt(5);
        UnitPrice := LibraryRandom.RandDecInRange(10, 20, 2);

        // [GIVEN] Lot-tracked item "I". Lots "L1", "L3" are in the inventory.
        LibraryItemTracking.CreateLotItem(Item);
        MakeTrackedItemStock(Item."No.", LotNos[1]);
        MakeTrackedItemStock(Item."No.", LotNos[3]);

        // [GIVEN] Sales order with two lines, each tracked with two lots. The quantity is distributed to the lots equally.
        // [GIVEN] 1st line is positive: Item No. = "I"; Lot Nos. = "L1" and "L3"; Quantity = 10, Unit Price = 200 LCY.
        // [GIVEN] 2nd line is negative: Item No. = "I", Lot Nos. = "L2" and "L4", Quantity = -10, Unit Price = 100 LCY.
        // [GIVEN] Post the sales order with ship and invoice.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLineAndAssignTwoLotNos(SalesLine, SalesHeader, Item."No.", Qty, 2 * UnitPrice, LotNos[1], LotNos[3]);
        CreateSalesLineAndAssignTwoLotNos(SalesLine, SalesHeader, Item."No.", -Qty, UnitPrice, LotNos[2], LotNos[4]);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Sales credit memo with two lines for item charges.
        // [GIVEN] 1st line is positive and the item charge is assigned to the 1st line of the posted shipment: Quantity = 10, Unit Price = 200 LCY.
        // [GIVEN] 2nd line is negative and the item charge is assigned to the 2nd line of the posted shipment: Quantity = -10, Unit Price = 100 LCY.
        // [GIVEN] The overall amount of the sales credit memo should be positive, hence the higher unit price on the first line.
        // [GIVEN] Otherwise, the sales credit memo cannot be posted.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        FindSalesShipmentLine(SalesShipmentLine, Item."No.");
        AssignItemChargeToPostedShipmentLine(SalesHeader, SalesShipmentLine.Quantity, SalesShipmentLine."Unit Price", SalesShipmentLine);
        SalesShipmentLine.Next();
        AssignItemChargeToPostedShipmentLine(SalesHeader, SalesShipmentLine.Quantity, SalesShipmentLine."Unit Price", SalesShipmentLine);

        // [WHEN] Post the sales credit memo.
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] A value entry with negative "Valued Quantity" = -5 and "Sales Amount (Actual)" = -100 LCY has been added to the sales of lot "L1".
        // [THEN] That makes the overall sales amount of lot "L1" = 0.
        // [THEN] A value entry with negative "Valued Quantity" = -5 and "Sales Amount (Actual)" = -100 LCY has been added to the sales of lot "L3".
        // [THEN] That makes the overall sales amount of lot "L1" = 0.
        QtyPerLot := Qty / 2;
        VerifyValuedQtyAndSalesAmountOnValueEntry(PostedInvoiceNo, Item."No.", LotNos[1], -QtyPerLot, -2 * UnitPrice * QtyPerLot);
        VerifyValuedQtyAndSalesAmountOnValueEntry(PostedInvoiceNo, Item."No.", LotNos[3], -QtyPerLot, -2 * UnitPrice * QtyPerLot);

        // [THEN] A value entry with positive "Valued Quantity" = 5 and "Sales Amount (Actual)" = 50 LCY has been added to the sales of lot "L2".
        // [THEN] That makes the overall sales amount of lot "L2" = 0.
        // [THEN] A value entry with positive "Valued Quantity" = 5 and "Sales Amount (Actual)" = 50 LCY has been added to the sales of lot "L4".
        // [THEN] That makes the overall sales amount of lot "L2" = 0.
        VerifyValuedQtyAndSalesAmountOnValueEntry(PostedInvoiceNo, Item."No.", LotNos[2], QtyPerLot, UnitPrice * QtyPerLot);
        VerifyValuedQtyAndSalesAmountOnValueEntry(PostedInvoiceNo, Item."No.", LotNos[4], QtyPerLot, UnitPrice * QtyPerLot);
    end;

    [Test]
    [HandlerFunctions('GetSalesOrdersReportHandler,CarryOutActionMsgReqHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderFromReqWkshWithDiffVendorThatIsBlocked()
    var
        Purchasing: Record Purchasing;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        Vendor: Record Vendor;
        i: Integer;
    begin
        // [FEATURE] [Special Order] [Requisition Worksheet]
        // [SCENARIO 215292] Requisition Worksheet Line is not deleted when one Purchase Order was created while the other was stopped by Vendor block for Special Order and Drop Shipment orders.
        Initialize();

        // [GIVEN] Item with Vendor "V1"
        CreateItemWithVendor(Item);

        // [GIVEN] Sales Order with Item in the two Sales Lines with "Purchasing Code" = "Special Order"
        CreatePurchasingCodeWithSpecialOrder(Purchasing);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        for i := 1 to 2 do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
            SalesLine.Validate("Purchasing Code", Purchasing.Code);
            SalesLine.Modify(true);
        end;

        // [GIVEN] Open requisition worksheet and run "Get Sales Orders"
        // [GIVEN] Two Requisition Lines created for two Sales Lines for "V1"
        GetSpecialOrderInReqWorksheet(RequisitionLine, SalesHeader."No.");

        // [GIVEN] Create Vendor "V2" and assign it to Requisition Line 1
        CreateVendorWithShipmentMethodCode(Vendor, SalesHeader."Shipment Method Code");
        UpdateVendorOnRequisitionLine(RequisitionLine, SalesHeader."No.", Vendor."No.");

        // [GIVEN] "V2" is blocked by privacy block
        Vendor.Validate("Privacy Blocked", true);
        Vendor.Modify(true);

        // [WHEN] Carry out action messages
        asserterror CarryOutActionMessages(SalesHeader."No.", SalesHeader."Posting Date");
        Assert.ExpectedError(StrSubstNo(CannotCreateDocPrivacyBlockerErr, Vendor."No."));

        // [THEN] One Purchase Order Created for "V1"
        Assert.AreEqual(1, CountPurchaseOrdersFromVendor(Item."Vendor No."), StrSubstNo(WrongNoOfOrdersCreatedErr, 1));

        // [THEN] Requisition Line 2 for "V1" was removed
        RequisitionLine.Reset();
        RequisitionLine.SetRange("Vendor No.", Item."Vendor No.");
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgReqWksht')]
    [Scope('OnPrem')]
    procedure ReqLinesWithTheSameVendorAndDifferentLocationCodesAreCombinedToOneOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Requisition Worksheet] [Purchase]
        // [SCENARIO 315410] Requisition worksheet lines with the same vendor and different locations are combined to one purchase order.
        Initialize();

        // [GIVEN] Item with vendor code and set up for planning.
        CreateItemWithVendor(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Modify(true);

        // [GIVEN] Sales order with two lines - on locations "BLUE" and "RED".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLineWithLocationCode(SalesLine, SalesHeader, Item."No.", LocationBlue.Code);
        CreateSalesLineWithLocationCode(SalesLine, SalesHeader, Item."No.", LocationRed.Code);

        // [WHEN] Calculate plan in requisition worksheet and carry out action in order to create purchase to fulfill the sales demand.
        Item.SetRecFilter();
        LibraryPlanning.CalcRequisitionPlanForReqWkshAndGetLines(RequisitionLine, Item, WorkDate(), WorkDate());
        CarryOutReqWkshWithRequestPage(
          RequisitionLine, RequisitionLine."Expiration Date", RequisitionLine."Order Date", WorkDate(), WorkDate());

        // [THEN] Only one purchase order is created.
        PurchaseHeader.SetRange("Buy-from Vendor No.", Item."Vendor No.");
        Assert.RecordCount(PurchaseHeader, 1);

        // [THEN] The purchase contains two lines - on locations "BLUE" and "RED".
        PurchaseHeader.FindFirst();
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.SetRange("Location Code", LocationBlue.Code);
        Assert.RecordCount(PurchaseLine, 1);

        PurchaseLine.SetRange("Location Code", LocationRed.Code);
        Assert.RecordCount(PurchaseLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasingCodeFromItemToSalesLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Purchasing: Record Purchasing;
    begin
        // [FEATURE] [Sales] [Purchasing Code] [UT]
        // [SCENARIO 277218] Purchasing code copied to sales line from item card
        Initialize();

        // [GIVEN] Item "I" with Purchasing Code = "PC"
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Code", Purchasing.Code);
        Item.Modify(true);

        // [GIVEN] Sales order 
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [WHEN] Item "I" is being selected in the sales line
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [THEN] Sales line has Purchasing Line = "PC"
        SalesLine.TestField("Purchasing Code", Item."Purchasing Code");
    end;

    [Test]
    procedure PurchasingCodeFromItemToSalesQuote()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Purchasing: Record Purchasing;
    begin
        // [FEATURE] [Sales] [Quote] [Purchasing Code] [UT]
        // [SCENARIO 414638] Purchasing code copied to sales quote line from item card.
        Initialize();

        // [GIVEN] Item "I" with Purchasing Code = "PC".
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Code", Purchasing.Code);
        Item.Modify(true);

        // [GIVEN] Sales quote. 
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, '');

        // [WHEN] Select the item "I" on the sales line.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [THEN] Sales line has Purchasing Line = "PC".
        SalesLine.TestField("Purchasing Code", Item."Purchasing Code");
    end;

    [Test]
    procedure PurchasingCodeFromItemToSalesInvoice()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Purchasing: Record Purchasing;
    begin
        // [FEATURE] [Sales] [Quote] [Purchasing Code] [UT]
        // [SCENARIO 414638] Purchasing code copied to sales quote line from item card.
        Initialize();

        // [GIVEN] Item "I" with Purchasing Code = "PC".
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Code", Purchasing.Code);
        Item.Modify(true);

        // [GIVEN] Sales quote. 
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');

        // [WHEN] Select the item "I" on the sales line.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [THEN] Sales line has Purchasing Line = "PC".
        SalesLine.TestField("Purchasing Code", '');
    end;

    [Test]
    procedure PurchasingCodeFromItemToSalesBlanketOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Purchasing: Record Purchasing;
    begin
        // [FEATURE] [Sales] [Quote] [Purchasing Code] [UT]
        // [SCENARIO 414638] Purchasing code copied to sales quote line from item card.
        Initialize();

        // [GIVEN] Item "I" with Purchasing Code = "PC".
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Code", Purchasing.Code);
        Item.Modify(true);

        // [GIVEN] Sales quote. 
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '');

        // [WHEN] Select the item "I" on the sales line.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [THEN] Sales line has Purchasing Line = "PC".
        SalesLine.TestField("Purchasing Code", Item."Purchasing Code");
    end;

    [Test]
    procedure PurchasingCodeDoesNotCopyFromItemToSalesReturnOrderLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Purchasing: Record Purchasing;
    begin
        // [FEATURE] [Sales] [Return Order] [Purchasing Code] [UT]
        // [SCENARIO 406324] Purchasing code is not copied to sales return order line from item card.
        Initialize();

        // [GIVEN] Item "I" with Purchasing Code.
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Code", Purchasing.Code);
        Item.Modify(true);

        // [GIVEN] Sales return order.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');

        // [WHEN] Select item "I" on the sales line.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [THEN] Sales line has Purchasing Code = <blank>.
        SalesLine.TestField("Purchasing Code", '');
    end;

    [Test]
    [HandlerFunctions('PostOrderStrMenuHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentErrorHandling()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Purchasing: Record Purchasing;
        NamedForwardLink: Record "Named Forward Link";
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
        SalesOrder: TestPage "Sales Order";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [FEATURE] [Sales] [Purchasing Code] [UT]
        // [SCENARIO 328639] Error message record about Posting drop shipment without link to purchase order has Context field name Purchasing Code and Support URL to "Make Drop Shipments" help topic
        Initialize();

        // [GIVEN] Item "I" with Purchasing Code = "PC" with "Drop Shipment" = Yes
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing."Drop Shipment" := true;
        Purchasing.Modify();
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Code", Purchasing.Code);
        Item.Modify(true);

        // [GIVEN] Sales order with item "I"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [WHEN] Sales order is being posted
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");
        LibraryVariableStorage.Enqueue(3); // ship and invoice
        LibraryErrorMessage.TrapErrorMessages();
        SalesOrder.Post.Invoke();

        // [THEN] Error Messages page has Context Field Name = "Purchasing Code"
        LibraryErrorMessage.GetTestPage(ErrorMessagesPage);
        ErrorMessagesPage."Context Field Name".AssertEquals(SalesLine.FieldName("Purchasing Code"));
        // [THEN] Error Messages page has Support URL = "https://go.microsoft.com/fwlink/?linkid=2104945"
        NamedForwardLink.Get(ForwardLinkMgt.GetHelpCodeForSalesLineDropShipmentErr());
        ErrorMessagesPage."Support Url".AssertEquals(NamedForwardLink.Link);
    end;


    [Test]
    [HandlerFunctions('GetSalesOrdersReportHandler')]
    procedure SpecialOrderReqLineUoMCopiedFromSalesLine()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Requisition Worksheet] [Special Order] [Get Sales Order]
        // [SCENARIO 384262] Requisition line created with "Get Sales Order" has the same UoM as the original Sales Line for the Special Orders
        Initialize();

        // [GIVEN] Item with base UoM "PCS" and additional UoM "PACK" = 10 "PCS"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(2, 10));

        // [GIVEN] Sales Order with Special Order Sales Line for 2 "PACK" of the Item
        CreateSalesOrderWithPurchasingCodeSpecialOrder(SalesHeader, Item."No.");
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        SalesLine.Modify(true);

        // [WHEN] Run "Get Sales Order" (Special Order) on the Requisition Worksheet
        GetSpecialOrderInReqWorksheet(RequisitionLine, SalesHeader."No.");

        // [THEN] Requisition Line created has same Quantity and UoM as the Sales Line
        RequisitionLine.SetRange("Sales Order No.", SalesHeader."No.");
        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Unit of Measure Code", SalesLine."Unit of Measure Code");
        RequisitionLine.TestField(Quantity, SalesLine.Quantity);
    end;

    [Test]
    procedure DistributionOfItemChargeToSeveralLotsForPurchaseLineInFCY()
    var
        Item: Record Item;
        Currency: Record Currency;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineItem: Record "Purchase Line";
        PurchaseLineItemCharge: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ReservationEntry: Record "Reservation Entry";
        ValueEntry: Record "Value Entry";
        ExchRate: Decimal;
        ItemChargeAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Item Charge] [Item Tracking] [Currency]
        // [SCENARIO 410063] Item charge amount in FCY is correctly distributed to several lots for purchase order line.
        Initialize();
        ExchRate := LibraryRandom.RandInt(100);
        ItemChargeAmount := LibraryRandom.RandIntInRange(5, 10) * ExchRate;

        // [GIVEN] Lot-tracked item.
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Currency "FCY", exchange rate 1 "LCY" = 4 "FCY".
        // [GIVEN] Vendor with the currency code "FCY".
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchRate, ExchRate));
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", Currency.Code);
        Vendor.Modify(true);

        // [GIVEN] Purchase order with two lines -
        // [GIVEN] Line 1: the lot-tracked item, quantity = 2 pcs, assign two lot nos., each for 1 pc.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineItem, PurchaseHeader, PurchaseLineItem.Type::Item, Item."No.", 2);
        PurchaseLineItem.Validate("Direct Unit Cost", 2 * LibraryRandom.RandDec(100, 2));
        PurchaseLineItem.Modify(true);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLineItem, '', LibraryUtility.GenerateGUID(), 1);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLineItem, '', LibraryUtility.GenerateGUID(), 1);

        // [GIVEN] Line 2: item charge, amount = 20 "FCY", assign item charge to the item line.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineItemCharge, PurchaseHeader, PurchaseLineItemCharge.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);
        PurchaseLineItemCharge.Validate("Direct Unit Cost", ItemChargeAmount);
        PurchaseLineItemCharge.Modify(true);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLineItemCharge,
          PurchaseLineItem."Document Type", PurchaseLineItem."Document No.", PurchaseLineItem."Line No.", PurchaseLineItem."No.");

        // [WHEN] Post the purchase order as received and invoiced.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Two value entries for item charge have been posted. Posted cost amount = 20 / 4 = 5 "LCY".
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.SetRange("Item Charge No.", PurchaseLineItemCharge."No.");
        Assert.RecordCount(ValueEntry, 2);
        ValueEntry.CalcSums("Cost Amount (Actual)");
        ValueEntry.TestField(
          "Cost Amount (Actual)", Round(ItemChargeAmount / ExchRate, LibraryERM.GetCurrencyAmountRoundingPrecision(Currency.Code)));
    end;

    [Test]
    procedure DistributionOfItemChargeToSeveralLotsForSalesLineInFCY()
    var
        Item: Record Item;
        Currency: Record Currency;
        Customer: Record Customer;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLineItem: Record "Sales Line";
        SalesLineItemCharge: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ReservationEntry: Record "Reservation Entry";
        ValueEntry: Record "Value Entry";
        LotNos: array[2] of Code[20];
        ExchRate: Decimal;
        ItemChargeAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Item Charge] [Item Tracking] [Currency]
        // [SCENARIO 410063] Item charge amount in FCY is correctly distributed to several lots for sales order line.
        Initialize();
        ExchRate := LibraryRandom.RandInt(100);
        ItemChargeAmount := LibraryRandom.RandIntInRange(5, 10) * ExchRate;
        LotNos[1] := LibraryUtility.GenerateGUID();
        LotNos[2] := LibraryUtility.GenerateGUID();

        // [GIVEN] Lot-tracked item.
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Currency "FCY", exchange rate 1 "LCY" = 4 "FCY".
        // [GIVEN] Customer with the currency code "FCY".
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchRate, ExchRate));
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", Currency.Code);
        Customer.Modify(true);

        // [GIVEN] Post 2 pcs to inventory, assign two lot nos., each for 1 pc.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 2);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNos[1], 1);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNos[2], 1);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order with two lines -
        // [GIVEN] Line 1: the lot-tracked item, quantity = 2 pcs, select the two lots.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLineItem, SalesHeader, SalesLineItem.Type::Item, Item."No.", 2);
        SalesLineItem.Validate("Unit Price", 2 * LibraryRandom.RandDec(100, 2));
        SalesLineItem.Modify(true);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLineItem, '', LotNos[1], 1);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLineItem, '', LotNos[2], 1);

        // [GIVEN] Line 2: item charge, amount = 20 "FCY", assign item charge to the item line.
        LibrarySales.CreateSalesLine(
          SalesLineItemCharge, SalesHeader, SalesLineItemCharge.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);
        SalesLineItemCharge.Validate("Unit Price", ItemChargeAmount);
        SalesLineItemCharge.Modify(true);
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLineItemCharge,
          SalesLineItem."Document Type", SalesLineItem."Document No.", SalesLineItem."Line No.", SalesLineItem."No.");

        // [WHEN] Post the sales order as shipped and invoiced.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Two value entries for item charge have been posted. Posted sales amount = 20 / 4 = 5 "LCY".
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Invoice");
        ValueEntry.SetRange("Item Charge No.", SalesLineItemCharge."No.");
        Assert.RecordCount(ValueEntry, 2);
        ValueEntry.CalcSums("Sales Amount (Actual)");
        ValueEntry.TestField(
          "Sales Amount (Actual)", Round(ItemChargeAmount / ExchRate, LibraryERM.GetCurrencyAmountRoundingPrecision(Currency.Code)));
    end;

    [Test]
    procedure LocationCodeFromShipToAddressInSalesOrder()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Ship-to Address] [Location] [Sales] [Order]
        // [SCENARIO 420781] Location Code in sales order is filled in from ship-to address.
        Initialize();

        LibrarySales.CreateCustomer(Customer);

        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        ShipToAddress.Validate("Location Code", LocationRed.Code);
        ShipToAddress.Modify(true);

        Customer.Validate("Ship-to Code", ShipToAddress.Code);
        Customer.Validate("Location Code", LocationBlue.Code);
        Customer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        SalesHeader.TestField("Location Code", LocationRed.Code);
    end;

    [Test]
    [HandlerFunctions('GetSalesOrdersReportHandler')]
    procedure LocationHasBinMandatoryAndDropShipmentPurchaseOrderCreated()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseOrderLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        SKU: Record "Stockkeeping Unit";
        GetSalesOrders: Report "Get Sales Orders";
        SalesOrderNo: Code[20];
    begin
        // [SCENARIO 574692] Verify when a location has 'Bin Mandatory' enabled, no error occurs and a Drop Shipment Purchase Order is created.
        Initialize();

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create loction with Bin Mandory & Bin Content.
        CreateLocationWithBinMandatory(Item, Location);

        // [GIVEN] Create SKU with Replenishment System Transfer.
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, Location.Code, Item."No.", '');
        SKU.Validate("Replenishment System", SKU."Replenishment System"::Transfer);
        SKU.Modify(true);

        // [GIVEN] Create a Drop shipment Sales Order.
        SalesOrderNo := CreateSalesOrderWithDropShipment(Location.Code, Item."No.");

        // [GIVEN] Assign template and batch to the requisition line.
        CreateRequisitionLine(RequisitionLine);
        Commit();

        // [GIVEN] Run Get Sales Order Report.
        LibraryVariableStorage.Enqueue(SalesOrderNo);
        GetSalesOrders.SetReqWkshLine(RequisitionLine, 0); // Drop Shipment
        GetSalesOrders.RunModal();
        Commit();

        // [GIVEN] Set "Vendor No." on the requisition lines.
        RequisitionLine.SetRange("Sales Order No.", SalesOrderNo);
        RequisitionLine.ModifyAll("Vendor No.", LibraryPurchase.CreateVendorNo(), true);

        // [WHEN] Run Carry Out Action from requisition worksheet.
        LibraryPlanning.CarryOutReqWksh(
          RequisitionLine, RequisitionLine."Expiration Date",
          RequisitionLine."Order Date", WorkDate(), WorkDate(), '');

        // [THEN] The 'Bin Mandatory' error did not occur, and a drop shipment purchase order was created.
        PurchaseOrderLine.SetRange(Type, PurchaseOrderLine.Type::Item);
        PurchaseOrderLine.SetRange("No.", Item."No.");
        Assert.IsFalse(PurchaseOrderLine.IsEmpty(), PurchaseOrderMustBeCreatedErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Orders-II");
        LibrarySetupStorage.Restore();
        Clear(TrackingQuantity);
        Clear(AssignLotNo);
        Clear(DifferentExpirationDate);
        Clear(NewExpirationDate);
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Orders-II");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        CreateLocationSetup();
        NoSeriesSetup();
        RevaluationJournalSetup();
        ItemJournalSetup();
        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Orders-II");
    end;

    local procedure AssignChargeItemPurchEqually(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    var
        PurchaseOrder: TestPage "Purchase Order";
        ItemChargeNo: Code[20];
    begin
        ItemChargeNo := LibraryInventory.CreateItemChargeNo();
        CreatePurchaseLine(
          PurchaseHeader, ItemChargeNo, PurchaseLine.Type::"Charge (Item)", '', 1, LibraryRandom.RandDec(100, 2));  // 1 Required for Charg Item Quantity and Using Random for Direct Unit Cost.
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.PurchLines.FILTER.SetFilter("No.", ItemChargeNo);
        PurchaseOrder.PurchLines.ItemChargeAssignment.Invoke();
    end;

    local procedure AssignChargeItemSaleEqually(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
        ItemChargeNo: Code[20];
    begin
        ItemChargeNo := LibraryInventory.CreateItemChargeNo();
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", ItemChargeNo, 1, LibraryRandom.RandDec(100, 2));  // 1 Required for Charg Item Quantity and Using Random for Unit Price.
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SalesLines.FILTER.SetFilter("No.", ItemChargeNo);
        LibraryVariableStorage.Enqueue(1);  // Enqueue ItemChargeAssignMenuHandler.
        SalesOrder.SalesLines."Item Charge &Assignment".Invoke();  // Item Charge & Assignment.
    end;

    local procedure AssignItemCharge(PurchaseHeader: Record "Purchase Header")
    var
        PurchLineCharge: Record "Purchase Line";
        PurchLineItem: Record "Purchase Line";
    begin
        FindPurchLine(PurchLineCharge, PurchaseHeader, PurchLineCharge.Type::"Charge (Item)");
        FindPurchLine(PurchLineItem, PurchaseHeader, PurchLineItem.Type::Item);
        LibraryCosting.AssignItemChargePurch(PurchLineCharge, PurchLineItem);
    end;

    local procedure AssignItemChargeSales(SalesHeader: Record "Sales Header")
    var
        SalesLineCharge: Record "Sales Line";
        SalesLineItem: Record "Sales Line";
    begin
        FindSalesLineType(SalesLineCharge, SalesHeader, SalesLineCharge.Type::"Charge (Item)");
        FindSalesLineType(SalesLineItem, SalesHeader, SalesLineItem.Type::Item);
        LibraryCosting.AssignItemChargeSales(SalesLineCharge, SalesLineItem);
    end;

    local procedure AssignItemChargeToPostedReceiptLine(PurchaseHeader: Record "Purchase Header"; Quantity: Decimal; UnitCost: Decimal; PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", '', Quantity);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);

        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
          PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."No.");
    end;

    local procedure AssignItemChargeToPostedShipmentLine(SalesHeader: Record "Sales Header"; Quantity: Decimal; UnitPrice: Decimal; SalesShipmentLine: Record "Sales Shipment Line")
    var
        SalesLine: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", '', Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);

        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLine, ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment,
          SalesShipmentLine."Document No.", SalesShipmentLine."Line No.", SalesShipmentLine."No.");
    end;

    local procedure InsertItemChargeAssignmentPurch(var PurchaseLine: Record "Purchase Line"; var PurchaseLineCharge: Record "Purchase Line"; QtyToAssign: Decimal)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLineCharge,
          PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.", PurchaseLine."No.");
        ItemChargeAssignmentPurch.Validate("Qty. to Assign", QtyToAssign);
        ItemChargeAssignmentPurch.Modify(true);
    end;

    local procedure FindSalesLineType(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LineType: Enum "Sales Line Type")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, LineType);
        SalesLine.FindFirst();
    end;

    local procedure UpdateLineAmountsSales(SalesHeader: Record "Sales Header"; AddAmount: Decimal) Result: Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        repeat
            SalesLine.Validate("Unit Price", SalesLine."Unit Price" + AddAmount);
            SalesLine.Modify(true);
            Result += SalesLine.Amount;
        until SalesLine.Next() = 0;
    end;

    local procedure FindPurchLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; LineType: Enum "Purchase Line Type")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, LineType);
        PurchaseLine.FindFirst();
    end;

    local procedure UpdateLineAmounts(PurchaseHeader: Record "Purchase Header"; AddAmount: Decimal) Result: Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
        repeat
            PurchaseLine.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost" + AddAmount);
            PurchaseLine.Modify(true);
            Result += PurchaseLine.Amount;
        until PurchaseLine.Next() = 0;
    end;

    local procedure CarryOutReqWkshWithRequestPage(var RequisitionLine: Record "Requisition Line"; ExpirationDate: Date; OrderDate: Date; PostingDate: Date; ExpectedReceiptDate: Date)
    var
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
    begin
        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.InitializeRequest(ExpirationDate, OrderDate, PostingDate, ExpectedReceiptDate, '');
        CarryOutActionMsgReq.UseRequestPage(true);
        Commit();
        CarryOutActionMsgReq.Run();
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; BinMandatory: Boolean; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Put-away", RequirePutAway);
        Location.Validate("Require Receive", RequireReceive);
        Location.Validate("Require Pick", RequirePick);
        Location.Validate("Require Shipment", RequireShipment);
        Location."Bin Mandatory" := BinMandatory;
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        CreateAndUpdateLocation(LocationBlue, false, false, false, false, false);
        CreateAndUpdateLocation(LocationSilver, true, false, false, false, false);
        CreateAndUpdateLocation(LocationSilver2, true, true, true, false, false);
        CreateAndUpdateLocation(LocationRed, false, true, true, false, false);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver.Code, false);
        LibraryWarehouse.CreateNumberOfBins(LocationSilver.Code, '', '', LibraryRandom.RandInt(3), false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver2.Code, false);
        LibraryWarehouse.CreateNumberOfBins(LocationSilver.Code, '', '', 1, false);
    end;

    local procedure CreatePurchaseOrderPostReceipt(var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptNo: Code[20];
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandInt(10));

        ReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchRcptLine.SetRange("Document No.", ReceiptNo);
        PurchRcptLine.FindFirst();
    end;

    local procedure CreateSalesOrderPostShipment(var SalesShipmentLine: Record "Sales Shipment Line")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ShipmentNo: Code[20];
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandInt(10));
        ShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        SalesShipmentLine.SetRange("Document No.", ShipmentNo);
        SalesShipmentLine.FindFirst();
    end;

    local procedure NoSeriesSetup()
    var
        InventorySetup: Record "Inventory Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        WarehouseSetup: Record "Warehouse Setup";
    begin
        LibraryInventory.NoSeriesSetup(InventorySetup);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Quote Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
    end;

    local procedure ItemJournalSetup()
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);
    end;

    local procedure RevaluationJournalSetup()
    begin
        RevaluationItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(RevaluationItemJournalTemplate, RevaluationItemJournalTemplate.Type::Revaluation);

        RevaluationItemJournalBatch.Init();
        LibraryInventory.CreateItemJournalBatch(RevaluationItemJournalBatch, RevaluationItemJournalTemplate.Name);
    end;

    local procedure AssignTrackingOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; var ReservationEntry: Record "Reservation Entry")
    begin
        PurchaseLine.OpenItemTrackingLines();  // Opens ItemTrackingPageHandler.
        UpdateReservationEntry(ReservationEntry, PurchaseLine."No.", WorkDate());
    end;

    local procedure AssignAndUpdateItemChargeOnPurchaseLine(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        ChargePurchaseLine: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        CreatePurchaseLine(
          PurchaseHeader, LibraryInventory.CreateItemChargeNo(), PurchaseLine.Type::"Charge (Item)",
          '', LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
        FindPurchaseLine(ChargePurchaseLine, PurchaseHeader);
        ChargePurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        ChargePurchaseLine.FindFirst();
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, ChargePurchaseLine, PurchaseLine."Document Type", PurchaseLine."Document No.",
          PurchaseLine."Line No.", PurchaseLine."No.");
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Type: Enum "Purchase Line Type"; LocationCode: Code[10]; Quantity: Decimal; DirectUnitCost: Decimal)
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(PurchaseHeader, ItemNo, Type, LocationCode, Quantity, DirectUnitCost);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateRequisitionLine(var RequisitionLine: Record "Requisition Line")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
    end;

    local procedure CreateLotTrackedItem(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(ItemTrackingCode);  // Item Tracking with Lot TRUE.
        CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
    end;

    local procedure CreateAndPostPurchaseOrderWithLotTracking(): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateLotTrackedItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));
        AssignLotNo := true;
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        exit(PurchaseHeader."Last Posting No.");
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostSalesOrderWithLotTracking(): Code[20]
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        ItemTrackingCode.Validate("Lot Sales Outbound Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));
        AssignLotNo := true;
        SalesLine.OpenItemTrackingLines();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        exit(SalesHeader."Last Posting No.");
    end;

    local procedure CreateAndReleaseSalesOrderWithDropShipmAndLocation(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrderWithPurchasingCodeDropShipment(SalesHeader, ItemNo);
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocation: Code[10]; ToLocation: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation, ToLocation, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateDefaultBinContent(Item: Record Item; LocationCode: Code[10])
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
    begin
        LibraryWarehouse.FindBin(Bin, LocationCode, '', 1);
        LibraryWarehouse.CreateBinContent(
          BinContent, LocationCode, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    begin
        exit(LibraryInventory.CreateItemNo());
    end;

    local procedure CreateCustomerWithAddress(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Address, LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Address)));
        Customer.Modify(true);
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item; ItemTrackingCode: Code[10])
    begin
        Item.Get(CreateItem());
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure CreateItemWithVendor(var Item: Record Item)
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify(true);
    end;

    local procedure CreateItemTranslation(var ItemTranslation: Record "Item Translation"; ItemNo: Code[20])
    begin
        ItemTranslation.Init();
        ItemTranslation.Validate("Item No.", ItemNo);
        ItemTranslation.Validate("Language Code", LibraryERM.GetAnyLanguageDifferentFromCurrent());
        ItemTranslation.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(ItemTranslation.Description)));
        ItemTranslation.Validate("Description 2", LibraryUtility.GenerateRandomText(MaxStrLen(ItemTranslation."Description 2")));
        ItemTranslation.Insert(true);
    end;

    local procedure CreatePurchaseHeaderWithSellToCustomer(var PurchHeader: Record "Purchase Header")
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type", Vendor."No.");
        PurchHeader.Validate("Sell-to Customer No.", Customer."No.");
        PurchHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Type: Enum "Purchase Line Type"; LocationCode: Code[10]; Quantity: Decimal; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndTrackPurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; TrackingOption: Integer)
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandIntInRange(11, 20));
        PurchaseLine.Validate("Qty. to Invoice", LibraryRandom.RandInt(10)); // less than Quantity
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);

        LibraryVariableStorage.Enqueue(TrackingOption);
        if TrackingOption = TrackingMethod::"Serial No." then
            LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(PurchaseLine."Quantity (Base)");
        LibraryVariableStorage.Enqueue(PurchaseLine."Quantity (Base)" - PurchaseLine."Qty. to Invoice (Base)");
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreatePurchaseLineForItemCharge(var PurchaseLineCharge: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header")
    var
        ItemCharge: Record "Item Charge";
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineCharge, PurchaseHeader, PurchaseLineCharge.Type::"Charge (Item)", ItemCharge."No.", 1);
        PurchaseLineCharge.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLineCharge.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithMultiLine(var PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(
          PurchaseHeader, LibraryInventory.CreateItem(Item), PurchaseLine.Type::Item, '', LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandDec(10, 2));
        CreatePurchaseLine(PurchaseHeader, Item."No.", PurchaseLine.Type::Item, '', PurchaseLine.Quantity, PurchaseLine."Direct Unit Cost");
        CreatePurchaseLine(PurchaseHeader, Item."No.", PurchaseLine.Type::Item, '', PurchaseLine.Quantity, PurchaseLine."Direct Unit Cost");
    end;

    local procedure CreatePurchaseDocumentWithAssignedItemCharge(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; var ItemNo: Code[20]; var ItemChargeNo: Code[20]; ChargeQty: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        ItemNo := LibraryInventory.CreateItemNo();
        CreatePurchaseLine(
          PurchaseHeader, ItemNo, PurchaseLine.Type::Item, '', LibraryRandom.RandDecInRange(5, 10, 2), LibraryRandom.RandDecInRange(100, 200, 2));
        ItemChargeNo := LibraryInventory.CreateItemChargeNo();
        CreatePurchaseLine(
          PurchaseHeader, ItemChargeNo, PurchaseLine.Type::"Charge (Item)", '', ChargeQty, LibraryRandom.RandDecInRange(10, 20, 2));
        AssignItemCharge(PurchaseHeader);
    end;

    local procedure CreatePurchaseInvoiceViaGetReceiptLines(var PurchaseHeaderInvoice: Record "Purchase Header"; PurchaseHeaderOrder: Record "Purchase Header")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, PurchaseHeaderOrder."Buy-from Vendor No.");
        PurchRcptLine.SetRange("Order No.", PurchaseHeaderOrder."No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeaderInvoice);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure CreatePurchaseCreditMemoViaGetReturnShipmentLines(var PurchaseHeaderCrMemo: Record "Purchase Header"; PurchaseHeaderRetOrder: Record "Purchase Header")
    var
        ReturnShipmentLine: Record "Return Shipment Line";
        PurchGetReturnShipments: Codeunit "Purch.-Get Return Shipments";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderCrMemo, PurchaseHeaderCrMemo."Document Type"::"Credit Memo", PurchaseHeaderRetOrder."Buy-from Vendor No.");
        ReturnShipmentLine.SetRange("Return Order No.", PurchaseHeaderRetOrder."No.");
        PurchGetReturnShipments.SetPurchHeader(PurchaseHeaderCrMemo);
        PurchGetReturnShipments.CreateInvLines(ReturnShipmentLine);
    end;

    local procedure CreateReqLineForSalesOrderWithDropShipm(SalesLine: Record "Sales Line"; var RequisitionLine: Record "Requisition Line")
    var
        RetrieveDimensionsFrom: Option Item,"Sales Line";
    begin
        CreateRequisitionLine(RequisitionLine);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, RetrieveDimensionsFrom::"Sales Line");
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", SalesLine."No.");
        RequisitionLine.FindFirst();
    end;

    local procedure CreateReqLineWithDropShipmentAndLocation(var ReqLine: Record "Requisition Line"; LocationCode: Code[10])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        CreateItemWithVendor(Item);
        CreateDefaultBinContent(Item, LocationCode);
        CreateAndReleaseSalesOrderWithDropShipmAndLocation(SalesLine, Item."No.", LocationCode);
        CreateReqLineForSalesOrderWithDropShipm(SalesLine, ReqLine);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, Quantity, '', 0D);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CopySalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; FromDocType: Enum "Sales Document Type From"; DocumentNo: Code[20])
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", DocumentType);
        SalesHeader.Insert(true);  // Creating empty Document for Copy function.
        LibrarySales.CopySalesDocument(SalesHeader, FromDocType, DocumentNo, true, false);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; ItemNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineAndAssignOneLotNo(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Qty: Decimal; UnitPrice: Decimal; LotNo: Code[50])
    begin
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty, UnitPrice);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreateSalesLineAndAssignTwoLotNos(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Qty: Decimal; UnitPrice: Decimal; LotNo1: Code[20]; LotNo2: Code[20])
    begin
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty, UnitPrice);
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue(LotNo1);
        LibraryVariableStorage.Enqueue(Qty / 2);
        LibraryVariableStorage.Enqueue(LotNo2);
        LibraryVariableStorage.Enqueue(Qty / 2);
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreateSalesLineWithLocationCodeAndPurchasing(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LocationCode: Code[10]; PurchasingCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithLocationCode(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CopyPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; FromDocType: Enum "Purchase Document Type From"; DocumentNo: Code[20])
    begin
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", DocumentType);
        PurchaseHeader.Insert(true);  // Creating empty Document for Copy function.
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, FromDocType, DocumentNo, true, false);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
    end;

    local procedure CreateVendorWithShipmentMethodCode(var Vendor: Record Vendor; ShipmentMethodCode: Code[10])
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.SetFilter(Code, '<>%1', ShipmentMethodCode);
        ShipmentMethod.FindFirst();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Shipment Method Code", ShipmentMethod.Code);
        Vendor.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLine(ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal; UnitAmount: Decimal): Code[20]
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        exit(ItemJournalLine."Document No.");
    end;

    local procedure PostPositiveAdjustment(GenBusPostingGroup: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);
        ItemJournalLine.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandInt(10));
        ItemJournalLine.Validate("Unit Amount", LibraryRandom.RandInt(10));
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure SetupItemCustomerPostingGroups(var Item: Record Item; var Customer: Record Customer; GeneralPostingSetup: Record "General Posting Setup")
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GeneralPostingSetup.Validate("Direct Cost Applied Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("COGS Account (Interim)", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
        GenBusinessPostingGroup.Get(GeneralPostingSetup."Gen. Bus. Posting Group");
        GenProductPostingGroup.Get(GeneralPostingSetup."Gen. Prod. Posting Group");

        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        GenBusinessPostingGroup.Validate("Def. VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", VATProductPostingGroup.Code);

        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 25);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure FindSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; ItemNo: Code[20])
    begin
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.SetRange("No.", ItemNo);
        SalesShipmentLine.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
    end;

    local procedure FindPurchaseLineBySpecialOrderSalesLine(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line")
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", SalesLine."No.");
        PurchaseLine.SetRange("Special Order Sales No.", SalesLine."Document No.");
        PurchaseLine.SetRange("Special Order Sales Line No.", SalesLine."Line No.");
        PurchaseLine.FindFirst();
    end;

    local procedure FindPurchaseLineBySalesSpecialOrder(var PurchaseLine: Record "Purchase Line"; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader);
        FindPurchaseLineBySpecialOrderSalesLine(PurchaseLine, SalesLine);
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; LotNo: Code[50])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindValueEntry(var ValueEntry: Record "Value Entry"; ItemLedgerEntryNo: Integer; DocumentNo: Code[20])
    begin
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.FindFirst();
    end;

    local procedure FindPurchaseLineBySalesDropShpment(var PurchaseLine: Record "Purchase Line"; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader);
        FindPurchaseLineByDropShpmtSalesLine(PurchaseLine, SalesLine);
    end;

    local procedure FindPurchaseLineByDropShpmtSalesLine(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line")
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", SalesLine."No.");
        PurchaseLine.SetRange("Sales Order No.", SalesLine."Document No.");
        PurchaseLine.SetRange("Sales Order Line No.", SalesLine."Line No.");
        PurchaseLine.FindFirst();
    end;

    local procedure MakeOrderFromPurchaseQuote(var PurchaseHeader: Record "Purchase Header")
    var
        PurchQuoteToOrder: Codeunit "Purch.-Quote to Order";
    begin
        Clear(PurchQuoteToOrder);
        PurchQuoteToOrder.Run(PurchaseHeader);
    end;

    local procedure RestoreInventorySetup(InventorySetup: Record "Inventory Setup")
    var
        InventorySetup2: Record "Inventory Setup";
    begin
        InventorySetup2.Get();
        InventorySetup2.Validate("Automatic Cost Posting", InventorySetup."Automatic Cost Posting");
        InventorySetup2.Validate("Automatic Cost Adjustment", InventorySetup."Automatic Cost Adjustment");
        InventorySetup2.Modify(true);
    end;

    local procedure SelectPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.SetRange(Status, PurchaseHeader.Status::Open);
        PurchaseHeader.FindFirst();
    end;

    local procedure SelectSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.SetRange(Status, SalesHeader.Status::Open);
        SalesHeader.FindFirst();
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure CountPurchaseOrdersFromVendor(VendorNo: Code[20]): Integer
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        exit(PurchaseHeader.Count);
    end;

    local procedure UpdateAutomaticCostSetup(var InventorySetup: Record "Inventory Setup")
    var
        InventorySetup2: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup2.Get();
        InventorySetup2.Validate("Automatic Cost Posting", false);
        InventorySetup2.Validate("Automatic Cost Adjustment", InventorySetup2."Automatic Cost Adjustment"::Never);
        InventorySetup2.Modify(true);
    end;

    local procedure UpdateReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20]; ExpirationDate: Date)
    var
        NoOfDays: Integer;
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindSet();
        NoOfDays := 0;
        repeat
            ReservationEntry.Validate("Expiration Date", CalcDate('<+' + Format(NoOfDays) + 'D>', ExpirationDate));
            ReservationEntry.Modify(true);
            if DifferentExpirationDate then
                NoOfDays += 1;
        until ReservationEntry.Next() = 0;
    end;

    local procedure UpdateBinCodeOnTransferLine(var TransferLine: Record "Transfer Line"; BinCode: Code[20])
    begin
        TransferLine.Validate("Transfer-To Bin Code", BinCode);
        TransferLine.Modify(true);
    end;

    local procedure UpdateStockoutWarning(NewStockoutWarning: Boolean) StockoutWarning: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        StockoutWarning := SalesReceivablesSetup."Stockout Warning";
        SalesReceivablesSetup.Validate("Stockout Warning", NewStockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure ModifySalesHeaderWithMultipleAddress(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Ship-to Address 2", LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Ship-to Address 2")));
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesOrderWithPurchasingCodeDropShipment(var SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        Purchasing: Record Purchasing;
    begin
        CreatePurchasingCodeWithDropShipment(Purchasing);
        CreateSalesOrderWithPurchasingCode(SalesHeader, ItemNo, Purchasing.Code);
    end;

    local procedure CreateSalesOrderWithPurchasingCodeSpecialOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        Purchasing: Record Purchasing;
    begin
        CreatePurchasingCodeWithSpecialOrder(Purchasing);
        CreateSalesOrderWithPurchasingCode(SalesHeader, ItemNo, Purchasing.Code);
    end;

    local procedure CreatePurchasingCodeWithDropShipment(var Purchasing: Record Purchasing)
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", true);
        Purchasing.Modify(true);
    end;

    local procedure CreatePurchasingCodeWithSpecialOrder(var Purchasing: Record Purchasing)
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Special Order", true);
        Purchasing.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SelectCustomer());
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity, UnitPrice);
    end;

    local procedure UpdateSellToCustomerOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; SellToCustomerNo: Code[20])
    begin
        PurchaseHeader.Validate("Sell-to Customer No.", SellToCustomerNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseOrderAndGetDropShipment(SalesHeader: Record "Sales Header")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Create Purchase Order. Update Sell to Customer on Purchase Header and Get Sales Order for Drop Shipment For Sales Order.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        UpdateSellToCustomerOnPurchaseHeader(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(SalesHeader."No.");  // Enqueue variable used in SalesListPageHandler.
        LibraryPurchase.GetDropShipment(PurchaseHeader);
    end;

    local procedure CreatePurchaseOrderAndGetSpecialOrder(var PurchHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header"; VendorNo: Code[20])
    var
        DistIntegration: Codeunit "Dist. Integration";
    begin
        // Create Purchase Order. Update Sell to Customer on Purchase Header and Get Sales Order for Special Order For Sales Order.
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        UpdateSellToCustomerOnPurchaseHeader(PurchHeader, SalesHeader."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(SalesHeader."No.");  // Enqueue variable used in SalesListPageHandler.
        DistIntegration.GetSpecialOrders(PurchHeader);
    end;

    local procedure SelectPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure CreateSalesOrderWithPurchasingCode(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; PurchasingCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, ItemNo, LibraryRandom.RandDec(10, 2), 0);
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithPurchasingCodeOnLocation(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; PurchasingCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateFCYSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CustomerNo, ItemNo, LibraryRandom.RandDec(10, 2), LocationCode,
          WorkDate(), '');
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithPurchasingCodeWithDiffLocationsInHeaderAndInLine(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; HeaderLocationCode: Code[10]; LineLocationCode: Code[10]; PurchasingCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrderWithDiffLocationsInHeaderAndInLine(
          SalesHeader, CustomerNo, ItemNo, LibraryRandom.RandDec(10, 2), 0, HeaderLocationCode, LineLocationCode);
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithCustomerNoAndPurchasingCode(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; PurchasingCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(100), LibraryRandom.RandInt(1000));
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithPurchCodeAndAddress(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; PurchasingCode: Code[10]; ShipToAddress: Text[100])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateFCYSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CustomerNo, ItemNo, LibraryRandom.RandDec(10, 2), '',
          WorkDate(), '');
        SalesHeader.Validate("Ship-to Address", ShipToAddress);
        SalesHeader.Modify(true);
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure SelectCustomer(): Code[20]
    var
        Customer: Record Customer;
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.FindFirst();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Location Code", LocationBlue.Code);
        Customer.Validate("Shipment Method Code", ShipmentMethod.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateFRQItem(var Item: Record Item)
    begin
        // Create Fixed Reorder Quantity Item.
        Item.Get(CreateItem());
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Safety Stock Quantity", LibraryRandom.RandDec(10, 2));
        Item.Validate("Reorder Quantity", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
    end;

    local procedure CreateRevaluationJournalForItem(ItemNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo);
        ItemJournalLine.Validate("Journal Template Name", RevaluationItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", RevaluationItemJournalBatch.Name);
        ItemJournalLine.Validate("Value Entry Type", ItemJournalLine."Value Entry Type"::Revaluation);
        LibraryCosting.CalculateInventoryValue(
          ItemJournalLine, Item, WorkDate(), LibraryUtility.GetGlobalNoSeriesCode(), "Inventory Value Calc. Per"::Item, true, false, false, "Inventory Value Calc. Base"::" ", false);
    end;

    local procedure CreatePurchaseOrderWithLocation(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, Quantity, LocationCode, 0D);
    end;

    local procedure CreateAndPostPurchaseWithLocation(ItemNo: Code[20]; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrderWithLocation(PurchaseHeader, ItemNo, LocationCode, LibraryRandom.RandDec(10, 2));
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateSalesOrderWithDiffLocationsInHeaderAndInLine(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal; HeaderLocationCode: Code[10]; LineLocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Location Code", HeaderLocationCode);
        SalesHeader.Modify(true);

        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity, UnitPrice);
        SalesLine.Validate("Location Code", LineLocationCode);
        SalesLine.Modify(true);
    end;

    local procedure SelectItemJournalLineForLocation(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.SetRange("Location Code", LocationCode);
        ItemJournalLine.FindFirst();
    end;

    local procedure UpdateItemJournallineUnitCostRevalued(ItemNo: Code[20]; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectItemJournalLineForLocation(ItemJournalLine, ItemNo, LocationCode);
        ItemJournalLine.Validate("Unit Cost (Revalued)", LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Modify(true);
    end;

    local procedure UpdateReportSelection(ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
        SavedReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"P.Order");
        // Purchase Order. Number is used instead of an option value to avoid codeunit localization
        ReportSelections.FindFirst();
        SavedReportSelections := ReportSelections;
        ReportSelections.DeleteAll();

        ReportSelections.Init();
        ReportSelections := SavedReportSelections;
        ReportSelections.Validate(Usage, ReportSelections.Usage::"P.Order");
        ReportSelections.Validate(Sequence, LibraryUtility.GenerateGUID());
        ReportSelections.Validate("Report ID", ReportID);
        ReportSelections.Insert(true);
    end;

    local procedure CreateItemJournalLineWithLocation(LocationCode: Code[10]; ItemNo: Code[20]; var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo,
          LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure PostItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectItemJournalLineForLocation(ItemJournalLine, ItemNo, LocationCode);
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
    end;

    local procedure MakeTrackedItemStock(ItemNo: Code[20]; LotNo: Code[50])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', LibraryRandom.RandIntInRange(50, 100));
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure UpdateVendorOnRequisitionLine(var RequisitionLine: Record "Requisition Line"; SalesOrderNo: Code[20]; VendorNo: Code[20])
    begin
        RequisitionLine.SetRange("Sales Order No.", SalesOrderNo);
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Vendor No.", VendorNo);
        RequisitionLine.Modify(true);
    end;

    local procedure UpdateAndCarryOut(var RequisitionLine: Record "Requisition Line"; var SalesHeader: array[2] of Record "Sales Header") Created: Integer
    var
        Vendor: Record Vendor;
        i: Integer;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        for i := 1 to 2 do
            UpdateVendorOnRequisitionLine(RequisitionLine, SalesHeader[i]."No.", Vendor."No.");

        UpdateReportSelection(REPORT::Order);
        RequisitionLine.SetFilter("Sales Order No.", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.");
        CarryOutReqWkshWithRequestPage(
          RequisitionLine, RequisitionLine."Expiration Date", RequisitionLine."Order Date",
          SalesHeader[1]."Posting Date", SalesHeader[1]."Posting Date");

        Created := CountPurchaseOrdersFromVendor(Vendor."No.");
    end;

    local procedure ClearDropSipmentSalesOrderAddressDetails(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Ship-to Name", '');
        SalesHeader.Validate("Ship-to Name 2", '');
        SalesHeader.Validate("Ship-to Address", '');
        SalesHeader.Validate("Ship-to Address 2", '');
        SalesHeader.Validate("Ship-to Post Code", '');
        SalesHeader.Validate("Ship-to City", '');
        SalesHeader.Validate("Ship-to Contact", '');
        SalesHeader.Modify(true);
    end;

    local procedure OpenRequisitionWorksheetAndRunGetSpecialOrders(var SalesHeader: array[2] of Record "Sales Header")
    var
        Vendor: Record Vendor;
        RequisitionLine: Record "Requisition Line";
    begin
        GetSpecialOrderInReqWorksheet(RequisitionLine, SalesHeader[1]."No." + '|' + SalesHeader[2]."No.");
        CreateVendorWithShipmentMethodCode(Vendor, SalesHeader[1]."Shipment Method Code");
        UpdateVendorOnRequisitionLine(RequisitionLine, SalesHeader[1]."No.", Vendor."No.");
        UpdateVendorOnRequisitionLine(RequisitionLine, SalesHeader[2]."No.", Vendor."No.");
    end;

    local procedure GetSpecialOrderInReqWorksheet(var RequisitionLine: Record "Requisition Line"; SalesOrderFilter: Text)
    begin
        GetSalesOrdersInReqWorksheet(RequisitionLine, 1, SalesOrderFilter);
    end;

    local procedure GetDropShipmentInReqWorksheet(var RequisitionLine: Record "Requisition Line"; SalesOrderFilter: Text)
    begin
        GetSalesOrdersInReqWorksheet(RequisitionLine, 0, SalesOrderFilter);
    end;

    local procedure GetSalesOrdersInReqWorksheet(var RequisitionLine: Record "Requisition Line"; SpecialOrder: Integer; SalesOrderFilter: Text)
    var
        GetSalesOrders: Report "Get Sales Orders";
    begin
        CreateRequisitionLine(RequisitionLine);
        LibraryVariableStorage.Enqueue(SalesOrderFilter);
        GetSalesOrders.SetReqWkshLine(RequisitionLine, SpecialOrder);
        Commit();
        GetSalesOrders.RunModal();
    end;

    local procedure CarryOutActionMessages(FilterText: Text; PostingDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        UpdateReportSelection(REPORT::Order);
        RequisitionLine.SetFilter("Sales Order No.", FilterText);
        RequisitionLine.FindFirst();
        CarryOutReqWkshWithRequestPage(
          RequisitionLine, RequisitionLine."Expiration Date", RequisitionLine."Order Date", PostingDate, PostingDate);
    end;

    local procedure VerifyGLEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Amount: Decimal; GenPostingType: Enum "General Posting Type")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Gen. Posting Type", GenPostingType);
        GLEntry.CalcSums(Amount);
        Assert.AreNearlyEqual(Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountErr);
    end;

    local procedure VerifySalesLine(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("No.", ItemNo);
        SalesLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPurchaseLine(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        PurchaseLine.TestField("No.", ItemNo);
        PurchaseLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyItemLedgEntryCostAmount(ItemNo: Code[20]; ExpectedAmount: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Cost Amount (Non-Invtbl.)");
        Assert.AreNearlyEqual(
          ExpectedAmount, ItemLedgerEntry."Cost Amount (Actual)" + ItemLedgerEntry."Cost Amount (Non-Invtbl.)", LibraryERM.GetAmountRoundingPrecision(), AmountErr);
    end;

    local procedure VerifyItemLedgEntrySalesAmount(ItemNo: Code[20]; LotNo: Code[50]; ExpectedAmount: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, ItemNo, LotNo);
        ItemLedgerEntry.CalcFields("Sales Amount (Actual)");
        ItemLedgerEntry.TestField("Sales Amount (Actual)", ExpectedAmount);
    end;

    local procedure VerifyItemLedgEntriesAmount(ItemNo: Code[20]; EntryType: Option Purchase,Sale; ExpectedAmount: Decimal; Total: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        TotalAmount: Decimal;
        WrongCostAmountErr: Label 'Wrong Cost/Sales Amount in Entry %1', Comment = '%1: Item Ledger Entry No.';
    begin
        ItemLedgerEntry.SetAutoCalcFields("Cost Amount (Actual)", "Sales Amount (Actual)");
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet();
        repeat
            if Total then
                TotalAmount += ItemLedgerEntry."Cost Amount (Actual)" + ItemLedgerEntry."Sales Amount (Actual)"
            else
                Assert.AreEqual(
                  ExpectedAmount, ItemLedgerEntry."Cost Amount (Actual)" + ItemLedgerEntry."Sales Amount (Actual)",
                  StrSubstNo(WrongCostAmountErr, ItemLedgerEntry."Entry No."));
        until ItemLedgerEntry.Next() = 0;
        if Total then
            Assert.AreEqual(ExpectedAmount, TotalAmount, AmountErr);
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Transfer Receipt");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Invoiced Quantity", Quantity);
    end;

    local procedure VerifyValueEntry(ItemNo: Code[20]; InvoicedQuantity: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.FindFirst();
        ValueEntry.TestField("Invoiced Quantity", InvoicedQuantity);
    end;

    local procedure VerifyValueEntriesWithItemCharge(PurchaseLineCharge: Record "Purchase Line"; ItemNo: Code[20]; ItemChargeShare: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PostedQty: Decimal;
    begin
        GeneralLedgerSetup.Get();

        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.CalcSums(Quantity);
        PostedQty := ItemLedgerEntry.Quantity;

        if ItemLedgerEntry.FindSet() then
            repeat
                ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
                ValueEntry.SetRange("Item Charge No.", PurchaseLineCharge."No.");
                ValueEntry.FindFirst();
                Assert.AreEqual(1, ValueEntry.Count, MultipleValueEntriesWithChargeMsg);
                Assert.AreNearlyEqual(
                  PurchaseLineCharge."Direct Unit Cost" * ItemChargeShare * ItemLedgerEntry.Quantity / PostedQty,
                  ValueEntry."Cost Amount (Actual)", GeneralLedgerSetup."Amount Rounding Precision" * ItemLedgerEntry.Count,
                  PostedChargeCostAmountMsg);
            until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyValuedQtyAndSalesAmountOnValueEntry(DocumentNo: Code[20]; ItemNo: Code[20]; LotNo: Code[50]; ValuedQty: Decimal; SalesAmount: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, ItemNo, LotNo);
        FindValueEntry(ValueEntry, ItemLedgerEntry."Entry No.", DocumentNo);
        ValueEntry.TestField("Valued Quantity", ValuedQty);
        ValueEntry.TestField("Sales Amount (Actual)", SalesAmount);
    end;

    local procedure VerifyCostAmountActualSum(ItemNo: Code[20]; ExpectedAmount: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.CalcSums("Cost Amount (Actual)");
        ValueEntry.TestField("Cost Amount (Actual)", ExpectedAmount);
    end;

    local procedure VerifySalesAmountActualSum(ItemNo: Code[20]; ExpectedAmount: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Invoice");
        ValueEntry.CalcSums("Sales Amount (Actual)");
        ValueEntry.TestField("Sales Amount (Actual)", ExpectedAmount);
    end;

    local procedure VerifyTransferReceiptLine(TransferOrderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; TransferToCode: Code[10]; TransferFromCode: Code[10]; TransferToBinCode: Code[20])
    var
        TransferReceiptLine: Record "Transfer Receipt Line";
    begin
        TransferReceiptLine.SetRange("Transfer Order No.", TransferOrderNo);
        TransferReceiptLine.FindFirst();
        TransferReceiptLine.TestField("Item No.", ItemNo);
        TransferReceiptLine.TestField(Quantity, Quantity);
        TransferReceiptLine.TestField("Transfer-to Code", TransferToCode);
        TransferReceiptLine.TestField("Transfer-from Code", TransferFromCode);
        TransferReceiptLine.TestField("Transfer-To Bin Code", TransferToBinCode);
        TransferReceiptLine.ShowItemTrackingLines();  // Verify the Posted Item Tracking Lines in PostedItemTrackingLinesHandler.
    end;

    local procedure VerifyItemLedgerEntryForAdjustCost(DocumentNo: Code[20]; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; InvoicedQuantity: Decimal; CostAmountActual: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Invoiced Quantity", InvoicedQuantity);
        Assert.AreNearlyEqual(
          CostAmountActual, ItemLedgerEntry."Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationErr, ItemLedgerEntry.FieldCaption("Cost Amount (Actual)"), CostAmountActual));
    end;

    local procedure VerifyPurchaseShippingDetails(ItemNo: Code[20]; ShipToCode: Code[10]; ShipToAddress: Text[100])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        SelectPurchaseOrderLine(PurchaseLine, ItemNo);
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeader.TestField("Ship-to Address", ShipToAddress);
        PurchaseHeader.TestField("Ship-to Code", ShipToCode);
    end;

    local procedure VerifyReservationEntryIsEmpty(SourceType: Integer; SourceSubtype: Option; SourceID: Code[20])
    var
        DummyReservationEntry: Record "Reservation Entry";
    begin
        DummyReservationEntry.SetRange("Source Type", SourceType);
        DummyReservationEntry.SetRange("Source Subtype", SourceSubtype);
        DummyReservationEntry.SetRange("Source ID", SourceID);
        Assert.RecordIsEmpty(DummyReservationEntry);
    end;

    local procedure VerifyShipmentMethodCode(VendorNo: Code[20]; ShipmentMethodCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.FindFirst();
        PurchaseHeader.TestField("Shipment Method Code", ShipmentMethodCode);
    end;

    local procedure VerifyItemJournalLineBatchAndTemplateForItem(ItemNo: Code[20]; LocationCode: Code[10]; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify Item is still present on same worksheet.
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.SetRange("Location Code", LocationCode);
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Journal Template Name", JournalTemplateName);
        ItemJournalLine.TestField("Journal Batch Name", JournalBatchName);
    end;

    local procedure CreateLocationWithBinMandatory(Item: Record Item; var Location: Record Location)
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);

        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Validate(Fixed, true);
        BinContent.Modify(true);
    end;

    local procedure CreateSalesOrderWithDropShipment(LocationCode: Code[20]; ItemNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        SalesLine.Validate("Drop Shipment", true);
        SalesLine.Modify(true);

        exit(SalesHeader."No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        if AssignLotNo then begin
            ItemTrackingLines."Assign Lot No.".Invoke();  // Assign Lot No.
            ItemTrackingLines."Quantity (Base)".SetValue(ItemTrackingLines."Quantity (Base)".AsDecimal() / 2);  // Partial Quantity.
            ItemTrackingLines."Assign Lot No.".Invoke();  // Assign Lot No for the new Line.
        end else
            ItemTrackingLines."Select Entries".Invoke();  // Open Item Tracking Summary Page for Selected Line.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler2(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        if AssignLotNo then
            ItemTrackingLines."Assign Lot No.".Invoke()
        else
            ItemTrackingLines."Select Entries".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingAssignSerialNoOrLotPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        QtyToBeHandled: Integer;
        QtyNotToBeInvoiced: Integer;
    begin
        TrackingMethod := LibraryVariableStorage.DequeueInteger();
        case TrackingMethod of
            TrackingMethod::"Serial No.":
                if LibraryVariableStorage.DequeueBoolean() then // Select Entries
                    ItemTrackingLines."Select Entries".Invoke()
                else begin
                    ItemTrackingLines."Assign Serial No.".Invoke();
                    QtyNotToBeInvoiced := LibraryVariableStorage.DequeueInteger();
                    ItemTrackingLines.First();
                    while QtyNotToBeInvoiced > 0 do begin
                        ItemTrackingLines."Qty. to Invoice (Base)".SetValue(0);
                        ItemTrackingLines.Next();
                        QtyNotToBeInvoiced -= 1;
                    end;
                end;
            TrackingMethod::Lot:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    QtyToBeHandled := LibraryVariableStorage.DequeueInteger();
                    QtyNotToBeInvoiced := LibraryVariableStorage.DequeueInteger();
                    ItemTrackingLines.First();
                    ItemTrackingLines."Qty. to Invoice (Base)".SetValue(QtyToBeHandled - QtyNotToBeInvoiced);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        NoOfLots: Integer;
        i: Integer;
    begin
        NoOfLots := LibraryVariableStorage.DequeueInteger();
        for i := 1 to NoOfLots do begin
            ItemTrackingLines.New();
            ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
            ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQtyToCreatePageHandler(var EnterQuantitytoCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantitytoCreate.QtyToCreate.SetValue(LibraryVariableStorage.DequeueInteger());
        EnterQuantitytoCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedItemTrackingLinesPageHandler(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    begin
        PostedItemTrackingLines.First();
        repeat
            PostedItemTrackingLines.Quantity.AssertEquals(TrackingQuantity / 2);  // Verify partial Quantity.
            PostedItemTrackingLines."Expiration Date".AssertEquals(WorkDate());
            if DifferentExpirationDate then begin
                PostedItemTrackingLines.Next();
                PostedItemTrackingLines."Expiration Date".AssertEquals(NewExpirationDate);  // Different Expiration Date on second Item Tracking Line.
            end;
        until PostedItemTrackingLines.Last();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListPageHandler(var SalesList: TestPage "Sales List")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        SalesList.FILTER.SetFilter("No.", DocumentNo);  // Apply Filter of Document No on Sales List Page.
        SalesList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignementPurchPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke();
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignementSalePageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        ItemChargeAssignmentSales.SuggestItemChargeAssignment.Invoke();
        ItemChargeAssignmentSales.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;  // Using 1 for Assign Equally Option.
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure PostOrderStrMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetSalesOrdersReportHandler(var GetSalesOrders: TestRequestPage "Get Sales Orders")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        GetSalesOrders."Sales Line".SetFilter("Document No.", DocumentNo);
        GetSalesOrders.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemVendorCatalogModalHandler(var ItemVendorCatalog: TestPage "Item Vendor Catalog")
    begin
        ItemVendorCatalog.New();
        ItemVendorCatalog."Vendor No.".SetValue(LibraryPurchase.CreateVendorNo());
        ItemVendorCatalog.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateInvtPutawayPickMvmtReportHandler(var CreateInvtPutawayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutawayPickMvmt.CreateInventorytPutAway.SetValue(true);
        CreateInvtPutawayPickMvmt.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure OrderReportHandler(var Order: Report "Order")
    begin
        LibraryVariableStorage.Enqueue(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgReqHandler(var CarryOutActionMsgReq: TestRequestPage "Carry Out Action Msg. - Req.")
    begin
        CarryOutActionMsgReq.PrintOrders.SetValue(true);
        CarryOutActionMsgReq.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgReqWksht(var CarryOutActionMsgReq: TestRequestPage "Carry Out Action Msg. - Req.")
    begin
        CarryOutActionMsgReq.PrintOrders.SetValue(false);
        CarryOutActionMsgReq.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnBeforePrintDocument', '', false, false)]
    local procedure CheckTwoPurchaseOrdersOnBeforePrintDocument(TempReportSelections: Record "Report Selections" temporary; IsGUI: Boolean; RecVarToPrint: Variant; var IsHandled: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        RecRef: RecordRef;
    begin
        Assert.RecordCount(RecVarToPrint, 2);
        RecRef := RecVarToPrint;
        RecRef.SetTable(PurchaseHeader);
        PurchaseHeader.FindSet();
        repeat
            Assert.AreEqual(PurchaseHeader."Document Type"::Order, PurchaseHeader."Document Type", '');
        until PurchaseHeader.Next() = 0;
        IsHandled := false;
    end;
}

