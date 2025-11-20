codeunit 137061 "SCM Purchases & Payables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        Initialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemReference: Codeunit "Library - Item Reference";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        MessageCounter: Integer;
        Initialized: Boolean;
        IncorrectMessageErr: Label 'Incorrect error message : %1', Comment = '%1: Message text';
        CostAmountExpectedErr: Label 'Cost Amount (Expected) must be same.';
        CostAmountActualErr: Label 'Cost Amount (Actual) must be same.';
        SalesAmountExpectedErr: Label 'Sales Amount (Expected) must be same.';
        SalesAmountActualErr: Label 'Sales Amount (Actual) must be same.';
        DropshipmentMsg: Label 'A drop shipment from a purchase order cannot be received and invoiced at the same time.';
        ChangedOnSalesLineErr: Label 'Location Code gets changed on sales line.';
        ChangedOnPurchaseLineErr: Label 'Location Code gets changed on purchase line.';
        ChangedOnReservationEntryErr: Label 'Location Code gets changed on Reservation Entry for sales & purchases.';
        OrdersDeletedErr: Label 'Orders must be deleted.';
        ReturnOrdersDeletedErr: Label 'Return Orders must be deleted.';
        SelltoCustomerBlankErr: Label 'The Sell-to Customer No. field must have a value.';
        PostDocConfirmQst: Label 'Do you want to post the %1?', Comment = '%1 = Document Type';
        ShipConfirmQst: Label 'Do you want to post the shipment?';
        ShipInvoiceConfirmQst: Label 'Do you want to post the shipment and invoice?';
        ReceiveConfirmQst: Label 'Do you want to post the receipt?';
        ReceiveInvoiceConfirmQst: Label 'Do you want to post the receipt and invoice?';
        CannotPostInvoiceErr: Label 'You cannot post the invoice';
        ReadyToPostQst: Label 'The number of orders that will be posted is %1. \Do you want to continue?', Comment = '%1 - selected count';
        CalcRemainingInvValueErr: Label 'Calculation of the remaining inventory value must include only one value entry';

    [Test]
    [Scope('OnPrem')]
    procedure B32914_DateInPurchaseLine()
    var
        Item: Record Item;
        ItemVendor: Record "Item Vendor";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        Vendor: Record Vendor;
    begin
        // Create Purchase Order with line and verify Date in line.
        // Setup: Update Manufacturing Setup.
        Initialize();
        LibraryPlanning.SetDefaultSafetyLeadTime('<' + Format(LibraryRandom.RandInt(5)) + 'M>');

        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryWarehouse.CreateLocation(Location);
        CreateItemVendor(ItemVendor, Vendor."No.", Item."No.");

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Validate("Requested Receipt Date", WorkDate());
        PurchaseHeader.Modify(true);

        // Exercise: Create Purchase Line.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader,
          PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        PurchaseHeader.Validate("Promised Receipt Date", WorkDate());
        PurchaseHeader.Modify(true);

        // Verify: Verify Expected Receipt Date and Promised Receipt Date in Purchase line.
        VerifyPurchLine(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B32625_ItemRefNoInPurchLine()
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // Create Purchase Order with line and Item Reference No in line.
        // Setup.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);

        LibraryItemReference.CreateItemReference(
            ItemReference, Item."No.", ItemReference."Reference Type"::Vendor, Vendor."No.");

        // Exercise: Create Purchase Order.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Verify: Verify Item Reference No in Purchase line.
        PurchaseLine.Validate("Item Reference No.", ItemReference."Reference No.");
        PurchaseLine.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B36070_SalesOrderShipOnly()
    begin
        // Processing a drop shipment sales order - ship sales Only.
        Initialize();
        DropShipmentFromSalesOrder(true, false); // Ship,Invoice.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B36070_SalesOrderInvoice()
    begin
        // Processing a drop shipment sales order - ship & invoice sales.
        Initialize();
        DropShipmentFromSalesOrder(true, true);
    end;

    local procedure DropShipmentFromSalesOrder(Ship: Boolean; Invoice: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Purchasing: Record Purchasing;
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup.
        CreateItem(Item);

        // Processing a drop shipment sales order.
        CreatePurchasingCode(Purchasing);

        // Exercise: Create a drop shipment Sales Order line and related Purchase Order.
        CreateDropShipOrders(Item, SalesHeader, PurchaseHeader, Purchasing, '');

        // Post Ship and Invoice Sales order.
        LibrarySales.PostSalesDocument(SalesHeader, Ship, Invoice);

        // Verify: verify the Amounts in Item Ledger Entry.
        if Invoice then
            VerifySalesEntry(Item."No.", SalesHeader."No.", 0, 0, Item."Unit Price", 0, Item."Unit Cost")
        else
            VerifySalesEntry(Item."No.", SalesHeader."No.", 0, Item."Unit Price", 0, Item."Unit Cost", 0);
        VerifyPurchEntry(Item."No.", PurchaseHeader."No.", 0, Item."Unit Cost", 0); // purch. not invoiced
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B36070_DropShipPurchReceive()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Purchasing: Record Purchasing;
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
    begin
        // Processing a drop shipment sales order - only receive purchase.
        // Setup.
        Initialize();
        CreateItem(Item);
        CreatePurchasingCode(Purchasing);

        // Exercise: Create a drop shipment Sales Order line and related Purchase Order.
        CreateDropShipOrders(Item, SalesHeader, PurchaseHeader, Purchasing, '');

        // Post receipt of the created Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify: verify the amounts in Item Ledger Entry.
        VerifySalesEntry(Item."No.", SalesHeader."No.", 0, Item."Unit Price", 0, Item."Unit Cost", 0);
        VerifyPurchEntry(Item."No.", PurchaseHeader."No.", 0, Item."Unit Cost", 0);

        // Exercise: Post Invoice of the purchase order.
        PurchaseHeader.Validate("Vendor Invoice No.",
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Verify that the Posted Purchase Invoice has been created.
        PurchaseInvoiceHeader.SetRange("Order No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(PurchaseInvoiceHeader);

        // Exercise: Post Sales Invoice.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Verify: verify the amounts in Item Ledger Entry.
        VerifySalesEntry(Item."No.", SalesHeader."No.", 0, 0, Item."Unit Price", 0, Item."Unit Cost");
        VerifyPurchEntry(Item."No.", PurchaseHeader."No.", 0, 0, Item."Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B36070_DropShipPurchInvoice()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Purchasing: Record Purchasing;
        PurchaseHeader: Record "Purchase Header";
    begin
        // Processing a drop shipment sales order - receive & invoice purchase.
        // Setup.
        Initialize();
        CreateItem(Item);
        CreatePurchasingCode(Purchasing);

        // Exercise: Create a drop shipment Sales Order line and related Purchase Order.
        CreateDropShipOrders(Item, SalesHeader, PurchaseHeader, Purchasing, '');
        PurchaseHeader.Validate("Vendor Invoice No.",
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);

        // Post receipt of the created Purchase Order.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: verify error msg.
        Assert.IsTrue(
          StrPos(GetLastErrorText, DropshipmentMsg) > 0, GetLastErrorText);
        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ChangeLocationConfirm')]
    [Scope('OnPrem')]
    procedure B44782_LocationInSalesLine()
    var
        Item: Record Item;
        Customer: Record Customer;
        Customer2: Record Customer;
        Location: Record Location;
        Location2: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Verify that the location code has changed on the Sales line.
        // Setup:
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());

        // Create item with Order Tracking.
        CreateItemWithTracking(Item);

        // Create two Customers with different default location codes.
        LibraryWarehouse.CreateLocation(Location);
        CreateCustomerWithLocation(Customer, Location.Code);

        LibraryWarehouse.CreateLocation(Location2);
        CreateCustomerWithLocation(Customer2, Location2.Code);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // Exercise: Create sales Line.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Change the Sell-to Customer No.
        SalesHeader.Validate("Sell-to Customer No.", Customer2."No.");
        SalesHeader.Modify(true);

        // Verify: verify that the location code has changed on the Sales line.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(Location2.Code, SalesLine."Location Code", ChangedOnSalesLineErr);

        // Verify that the location code has also changed in the Reservation Entry for the tracking entries.
        ReservationEntry.SetRange("Item No.", Item."No.");
        ReservationEntry.FindSet();
        repeat
            Assert.AreEqual(
              Location2.Code, ReservationEntry."Location Code", ChangedOnReservationEntryErr);
        until ReservationEntry.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ChangeLocationConfirm')]
    [Scope('OnPrem')]
    procedure B44782_LocationInPurchaseLine()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        Location: Record Location;
        Location2: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Verify that the location code has changed on the Purchase line.
        // Setup.
        Initialize();

        // Create Item with Order Tracking
        CreateItemWithTracking(Item);
        // Create two Vendors with different default location codes.
        LibraryWarehouse.CreateLocation(Location);
        CreateVendorWithLocation(Vendor, Location.Code);
        LibraryWarehouse.CreateLocation(Location2);
        CreateVendorWithLocation(Vendor2, Location2.Code);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // Exercise: Create purchase Line.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Change the Buy-from Vendor No.
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor2."No.");
        PurchaseHeader.Modify(true);

        // Verify: verify that the location code has changed on the Purchase line.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(Location2.Code, PurchaseLine."Location Code", ChangedOnPurchaseLineErr);

        // Verify that the location code has also changed in the Reservation Entry for the tracking entries.
        ReservationEntry.SetRange("Item No.", Item."No.");
        ReservationEntry.FindSet();
        repeat
            Assert.AreEqual(
              Location2.Code, ReservationEntry."Location Code", ChangedOnReservationEntryErr);
        until ReservationEntry.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B29201_AverageItemCostOnLedger()
    var
        InventorySetup: Record "Inventory Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        Quantity2: Decimal;
        Quantity3: Decimal;
        Quantity4: Decimal;
        UnitCost: Decimal;
        UnitCost2: Decimal;
        AvgUnitCost: Decimal;
        ExternalDocNo: Code[35];
        ExternalDocNo2: Code[35];
        ExternalDocNo3: Code[35];
        ExternalDocNo4: Code[35];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Cost Average]
        // [SCENARIO] Verify correct values in ILEs and in Item after Cost Adjustment (Average Costing Method), when multiple Item Journal lines posted with different Quantities and Unit Costs.

        // [GIVEN] Average Cost Period = Day, Automatic Cost Adjustment = Never, Item with Costing Method = Average.
        Initialize();
        GeneralLedgerSetup.Get();
        InventorySetup.Get();
        ModifyInventorySetup(InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Period"::Day);
        CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify(true);

        // Using multiple Quanity and Unit Cost values for Item Journal line.
        Quantity := 10 * LibraryRandom.RandInt(10);
        Quantity2 := LibraryRandom.RandInt(5);
        Quantity3 := Quantity2 + LibraryRandom.RandInt(5);
        Quantity4 := Quantity3 + LibraryRandom.RandInt(5);
        UnitCost := LibraryRandom.RandDec(10, 2);
        UnitCost2 := UnitCost + LibraryRandom.RandDec(10, 2);
        CreateExternalDocumentNo(ExternalDocNo, ExternalDocNo2, ExternalDocNo3, ExternalDocNo4);

        // Calculation for Average cost.
        AvgUnitCost :=
          Round(
            ((Quantity * UnitCost) + (Quantity2 * UnitCost2)) / (Quantity + Quantity2),
            GeneralLedgerSetup."Unit-Amount Rounding Precision");

        // [GIVEN] Post multiple Item Journal Line with different Quanity and Unit Cost values.
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity, UnitCost, ExternalDocNo);
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity2, UnitCost2, ExternalDocNo2);
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", Quantity3, 0, ExternalDocNo3);
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", Quantity4, 0, ExternalDocNo4);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [WHEN] Run Adjust cost.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Verify Item Ledger Entry: Cost Amount is correct, Negative Quantity for Negative Adjustment.
        VerifyCostAmountLedgerEntry(
          Item."No.", Round(Quantity * UnitCost, GeneralLedgerSetup."Amount Rounding Precision"), ExternalDocNo);
        VerifyCostAmountLedgerEntry(
          Item."No.", Round(Quantity2 * UnitCost2, GeneralLedgerSetup."Amount Rounding Precision"), ExternalDocNo2);

        VerifyCostAmountLedgerEntry(
          Item."No.", -Round(Quantity3 * AvgUnitCost, GeneralLedgerSetup."Amount Rounding Precision"), ExternalDocNo3);
        VerifyCostAmountLedgerEntry(
          Item."No.", -Round(Quantity4 * AvgUnitCost, GeneralLedgerSetup."Amount Rounding Precision"), ExternalDocNo4);

        // [THEN] Item Unit Cost is correct.
        Item.Get(Item."No.");
        Assert.AreNearlyEqual(AvgUnitCost, Item."Unit Cost", GeneralLedgerSetup."Amount Rounding Precision", '');

        // TearDown.
        ModifyInventorySetup(InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Period");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B24114_DelInvoicedPurchOrders()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseReceiptNo: Code[20];
        PurchaseReceiptNo2: Code[20];
    begin
        // Post Invoice and delete Invoiced Purchase Orders.
        // 1. Setup.
        Initialize();
        CreateItem(Item);

        // Create and Post Purchase orders and combine Purchase Receipts and post Invoice.
        CombinePurchaseReceiptsSetup(Vendor, Item, PurchaseReceiptNo, PurchaseReceiptNo2);

        // 2. Exercise: Delete the Invoiced Purchase Orders.
        PurchaseHeader2.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader2.SetRange("Buy-from Vendor No.", Vendor."No.");
        LibraryPurchase.DeleteInvoicedPurchOrders(PurchaseHeader2);

        // 3. Verify: verify Old Purchase Orders have been deleted.
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("No.", Vendor."No.");
        Assert.AreEqual(0, PurchaseHeader.Count, OrdersDeletedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B24114_DelInvdPurchRetOrders()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseReceiptNo: Code[20];
        PurchaseReceiptNo2: Code[20];
    begin
        // Post Credit Memo and delete Invoiced Purchase Return Orders.
        // 1. Setup.
        Initialize();
        CreateItem(Item);

        // Create and Post Purchase Orders and combine Purchase Receipts and post Invoice.
        CombinePurchaseReceiptsSetup(Vendor, Item, PurchaseReceiptNo, PurchaseReceiptNo2);

        // Create and Post Shipment of the Return orders for the Purchase made and combine the Receipts to a Credit Memo and post it.
        CombineForPurchMemoSetup(Vendor, PurchaseReceiptNo, PurchaseReceiptNo2);

        // 2. Exercise: Delete the Invoiced Purchase Return Orders.
        PurchaseHeader2.SetRange("Document Type", PurchaseHeader2."Document Type"::"Return Order");
        PurchaseHeader2.SetRange("Buy-from Vendor No.", Vendor."No.");
        LibraryPurchase.DeleteInvoicedPurchOrders(PurchaseHeader2);

        // 3. Verify: verify old Purchase Return orders have been deleted.
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Return Order");
        PurchaseHeader.SetRange("No.", Vendor."No.");
        Assert.AreEqual(0, PurchaseHeader.Count, ReturnOrdersDeletedErr);
    end;

    [Test]
    [HandlerFunctions('CombinedMessageHandler')]
    [Scope('OnPrem')]
    procedure B24114_DelInvoicedSalesOrders()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader2: Record "Sales Header";
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesShipmentNo: Code[20];
        SalesShipmentNo2: Code[20];
    begin
        // Post Invoice and delete Invoiced Sales Orders.
        // 1. Setup.
        Initialize();
        SalesReceivablesSetup.Get();
        LibrarySales.SetStockoutWarning(false);
        CreateItem(Item);

        // Create and Post Sales Orders.Combine Sales Shipments and Post Invoice.
        CombineSalesShipmentsSetup(Customer, Item, SalesShipmentNo, SalesShipmentNo2);

        // 2. Exercise: Delete the Invoiced Sales Orders.
        SalesHeader2.SetRange("Document Type", SalesHeader2."Document Type"::Order);
        SalesHeader2.SetRange("Sell-to Customer No.", Customer."No.");
        LibrarySales.DeleteInvoicedSalesOrders(SalesHeader2);

        // 3. Verify: verify that old Sales Orders have been deleted.
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", Customer."No.");
        Assert.AreEqual(0, SalesHeader.Count, OrdersDeletedErr);

        // 4. Teardown: Rollback Stockout Warning to default value on Sales & Receivables Setup.
        LibrarySales.SetStockoutWarning(SalesReceivablesSetup."Stockout Warning");
    end;

    [Test]
    [HandlerFunctions('CombinedMessageHandler,CombineReturnReceiptsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure B24114_DelInvdSalesRetOrders()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader2: Record "Sales Header";
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesShipmentNo: Code[20];
        SalesShipmentNo2: Code[20];
    begin
        // Post Credit Memo and delete Invoiced Sales Return Orders.
        // 1. Setup.
        Initialize();
        SalesReceivablesSetup.Get();
        LibrarySales.SetStockoutWarning(false);
        CreateItem(Item);

        // Create and Post Sales Orders.Combine Sales Shipments and Post Invoice.
        CombineSalesShipmentsSetup(Customer, Item, SalesShipmentNo, SalesShipmentNo2);

        // Create and Post Receipt of the Return Orders for the sales.Combine the Receipts to a Credit Memo and Post it.
        CombineForSalesMemoSetup(Customer, SalesShipmentNo, SalesShipmentNo2);

        // 2. Exercise: Delete the Invoiced Sales Return Orders.
        SalesHeader2.SetRange("Document Type", SalesHeader2."Document Type"::"Return Order");
        SalesHeader2.SetRange("Sell-to Customer No.", Customer."No.");
        LibrarySales.DeleteInvoicedSalesReturnOrders(SalesHeader2);

        // 3. Verify: verify that old Sales Return Orders have been deleted.
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
        SalesHeader.SetRange("No.", Customer."No.");
        Assert.AreEqual(0, SalesHeader.Count, ReturnOrdersDeletedErr);  // Value is important for Test.

        // 4. Teardown: Rollback Stockout Warning to default value on Sales & Receivables Setup.
        LibrarySales.SetStockoutWarning(SalesReceivablesSetup."Stockout Warning");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlannedReceiptDateOnPurchaseLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LeadTimeCalculation: DateFormula;
    begin
        // Setup: Create Item. Create and Release a Purchase Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", LibraryRandom.RandDec(100, 2));

        // Exercise: Update Lead Time Calculation on the Purchase Line.
        UpdateLeadTimeCalculationOnPurchaseLine(PurchaseLine, LeadTimeCalculation);

        // Verify: Verify the Planned Receipt Date calculated from Lead Time Calculation on Purchase Line.
        PurchaseLine.Find();
        PurchaseLine.TestField("Planned Receipt Date", CalcDate(LeadTimeCalculation, WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DropShipmentUpdatesSKUDirectCost()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Purchasing: Record Purchasing;
        SKU: Record "Stockkeeping Unit";
        Location: Record Location;
        ExpectedDirectCost: Decimal;
    begin
        // [FEATURE] [Drop Shipment] [SKU] [Last Direct Cost]
        // [SCENARIO] "Last Direct Cost" should be updated for SKU when Drop Shipment Purchase is Invoiced.

        // [GIVEN] Item with SKU for Location "L", "Last Direct Cost" set to "LDC".
        Initialize();
        CreateItem(Item);
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false); // Create per Location
        Location.FindFirst();

        // [GIVEN] Create Drop Shipment Sales-Purchase orders using Location "L".
        CreatePurchasingCode(Purchasing);
        CreateDropShipOrders(Item, SalesHeader, PurchaseHeader, Purchasing, Location.Code);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        ExpectedDirectCost := Item."Last Direct Cost" * 2;

        // [GIVEN] Update "Direct Unit Cost" in Purchase Line to "UDC" <> "LDC"
        FindPurchaseLine(PurchaseLine, PurchaseHeader, Item."No.");
        PurchaseLine.Validate("Direct Unit Cost", ExpectedDirectCost);
        PurchaseLine.Modify(true);

        // [WHEN] Receive Purchase, Post Sales, Invoice Purchase
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        SalesHeader.Find();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] SKU for Location "L" "Last Direct Cost" equals to "UDC"
        SKU.Get(Location.Code, Item."No.", '');
        SKU.TestField("Last Direct Cost", ExpectedDirectCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ThrowErrorOnDropShipmentWhenCustomerIsNotSet()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Drop Shipment] [UT]
        // [SCENARIO 201666] System throws error when codeunit "Purch.-Get Drop Shpt." invoked without specified "Sell-to Customer No." in passed purchase header
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        asserterror CODEUNIT.Run(CODEUNIT::"Purch.-Get Drop Shpt.", PurchaseHeader);

        Assert.ExpectedError(SelltoCustomerBlankErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositiveIndirectCost()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        IndirectCostPercent: Decimal;
    begin
        // [FEATURE] [Purchase] [Indirect Cost]
        // [SCENARIO 219461] "Indirect Cost %" is populated successfully when "Unit Cost (LCY)" is populated by value greater than "Direct Unit Cost"
        Initialize();

        // [GIVEN] Purchase Line with populated "Direct Unit Cost" = 10
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
          LibraryPurchase.CreateVendorNo(), LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100), '', WorkDate());
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(20, 50));

        // [WHEN] In the "Unit Cost (LCY)" field, enter a value = 15 exceeding "Direct Unit Cost"
        PurchaseLine.Validate("Unit Cost (LCY)", PurchaseLine."Direct Unit Cost" + LibraryRandom.RandIntInRange(20, 50));

        // [THEN] "Indirect Cost %" = (15 - 10) / 10 * 100 = 50
        IndirectCostPercent := Round((PurchaseLine."Unit Cost (LCY)" - PurchaseLine."Direct Unit Cost") / PurchaseLine."Direct Unit Cost" * 100, 0.00001);
        PurchaseLine.TestField("Indirect Cost %", IndirectCostPercent);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeIndirectCost()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Indirect Cost]
        // [SCENARIO 219461] "Indirect Cost %" = 0 when "Unit Cost (LCY)" is populated by value less than "Direct Unit Cost".
        Initialize();

        // [GIVEN] Purchase Line PL with populated "Direct Unit Cost"
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
          LibraryPurchase.CreateVendorNo(), LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100), '', WorkDate());
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(20, 50));

        // [WHEN] VALIDATE PL."Unit Cost (LCY)" with value less than "Direct Unit Cost"
        PurchaseLine.Validate("Unit Cost (LCY)", LibraryRandom.RandInt(PurchaseLine."Direct Unit Cost" - 1));

        // [THEN] "Indirect Cost %" = 0.
        PurchaseLine.TestField("Indirect Cost %", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostLessThanDirectUnitCostForItemWithStandardCostingMethod()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Standard Cost]
        // [SCENARIO 255923] Item with standard costing method can be purchased with "Direct Unit Cost" greater than "Unit Cost". The difference is posted as variance.
        Initialize();

        // [GIVEN] Item with Costing Method = "Standard". Item."Unit Cost" = "X".
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);

        // [GIVEN] Purchase order for the "Q" pcs of the item. "Direct Unit Cost" on the purchase line = "Y", that is greater than "X".
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
          LibraryPurchase.CreateVendorNo(), Item."No.", LibraryRandom.RandInt(10), '', WorkDate());
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(20, 40, 2));
        PurchaseLine.Modify(true);

        // [WHEN] Post the purchase order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] "Direct Cost"-typed value entry is created. "Cost Amount (Actual)" = "Y" * "Q".
        VerifyValueEntry(
          ValueEntry."Entry Type"::"Direct Cost",
          DocumentNo, Item."No.", PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity);

        // [THEN] "Variance"-typed value entry is created. "Cost Amount (Actual)" = ("X" - "Y") * "Q".
        VerifyValueEntry(
          ValueEntry."Entry Type"::Variance,
          DocumentNo, Item."No.", (Item."Unit Cost" - PurchaseLine."Direct Unit Cost") * PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ReceivingInvoicingPurchaseOrderWithPostingPolicy()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Posting Selection] [Order]
        // [SCENARIO 461826] Receiving and invoicing purchase order with "Prohibited" and "Mandatory" settings of invoice posting policy.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), Qty, '', WorkDate());

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Prohibited);

        LibraryVariableStorage.Enqueue(ReceiveConfirmQst);
        PostPurchaseDocument(PurchaseHeader);

        VerifyQtyOnPurchaseOrderLine(PurchaseLine, Qty, 0);

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Mandatory);

        LibraryVariableStorage.Enqueue(ReceiveInvoiceConfirmQst);
        PostPurchaseDocument(PurchaseHeader);

        PurchaseLine.SetRecFilter();
        Assert.RecordIsEmpty(PurchaseLine);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ReceivingInvoicingSeveralPurchaseOrderWithPostingPolicyFromList()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
        i: Integer;
        OrderCount: Integer;
        NoFilter: Text;
    begin
        // [FEATURE] [Posting Selection] [Order] [Invoice Posting Policy]
        // [SCENARIO 537525] Purchase order posting form PO list should respect User setting Purchase invoice Posting Policy
        Initialize();

        // [GIVEN] Several Purchase Orders with random quantity.
        OrderCount := Random(5) + 1;
        for i := 1 to OrderCount do begin
            Qty := LibraryRandom.RandInt(10);
            LibraryPurchase.CreatePurchaseDocumentWithItem(
              PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '',
              LibraryInventory.CreateItemNo(), Qty, '', WorkDate());
            NoFilter += '|' + PurchaseHeader."No.";
        end;

        NoFilter := DelChr(NoFilter, '<>', '|');
        LibraryVariableStorage.Enqueue(StrSubstNo(ReadyToPostQst, OrderCount));

        // [GIVEN] User setting Purchase invoice Posting Policy = "Prohibited"
        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Prohibited);

        // [WHEN] Post Purchase Orders
        PurchaseHeader.Reset();
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetFilter("No.", NoFilter);
        PurchaseHeader.FindSet();
        PostPurchaseDocuments(PurchaseHeader);

        // [THEN] Verify that Purchase Lines are only received and not invoiced    
        FilterPurchaseLines(PurchaseLine, PurchaseLine."Document Type"::Order, NoFilter);
        PurchaseLine.FindSet();
        repeat
            VerifyQtyOnPurchaseOrderLine(PurchaseLine, PurchaseLine.Quantity, 0);
        until PurchaseLine.Next() = 0;

        // [GIVEN] User setting Purchase invoice Posting Policy = "Mandatory"
        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Allowed);
        LibraryVariableStorage.Enqueue(StrSubstNo(ReadyToPostQst, OrderCount));

        // [WHEN] Post Purchase Orders
        PostPurchaseDocuments(PurchaseHeader);

        // [THEN] Verify that Purchase Lines are received and invoiced - not exist anymore
        FilterPurchaseLines(PurchaseLine, PurchaseLine."Document Type"::Order, NoFilter);
        Assert.RecordIsEmpty(PurchaseLine);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ReceivingInvoicingPurchaseReturnOrderWithPostingPolicy()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Posting Selection] [Return Order]
        // [SCENARIO 461826] Shipping and invoicing purchase return order with "Prohibited" and "Mandatory" settings of invoice posting policy.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", '',
          LibraryInventory.CreateItemNo(), Qty, '', WorkDate());

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Prohibited);

        LibraryVariableStorage.Enqueue(ShipConfirmQst);
        PostPurchaseDocument(PurchaseHeader);

        VerifyQtyOnPurchaseReturnOrderLine(PurchaseLine, Qty, 0);

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Mandatory);

        LibraryVariableStorage.Enqueue(ShipInvoiceConfirmQst);
        PostPurchaseDocument(PurchaseHeader);

        PurchaseLine.SetRecFilter();
        Assert.RecordIsEmpty(PurchaseLine);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,GenericMessageHandler')]
    procedure ReceivingInvoicingInventoryPutawayWithPostingPolicy()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Posting Selection] [Order] [Inventory Put-away]
        // [SCENARIO 461826] Receiving and invoicing inventory put-away with "Prohibited" and "Mandatory" settings of invoice posting policy.
        Initialize();
        Qty := 2 * LibraryRandom.RandInt(10);

        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), Qty, Location.Code, WorkDate());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        LibraryWarehouse.CreateInvtPutPickPurchaseOrder(PurchaseHeader);

        WarehouseActivityLine.SetRange("Item No.", PurchaseLine."No.");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Qty. to Handle", Qty / 2);
        WarehouseActivityLine.Modify(true);

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Prohibited);
        LibraryVariableStorage.Enqueue(ReceiveConfirmQst);
        CODEUNIT.Run(CODEUNIT::"Whse.-Act.-Post (Yes/No)", WarehouseActivityLine);

        VerifyQtyOnPurchaseOrderLine(PurchaseLine, Qty / 2, 0);

        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Qty. to Handle", Qty / 2);
        WarehouseActivityLine.Modify(true);

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Mandatory);
        LibraryVariableStorage.Enqueue(ReceiveInvoiceConfirmQst);
        CODEUNIT.Run(CODEUNIT::"Whse.-Act.-Post (Yes/No)", WarehouseActivityLine);

        VerifyQtyOnPurchaseOrderLine(PurchaseLine, Qty, Qty / 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CannotPostPurchaseInvoiceWithProhibitedPostingPolicy()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Posting Selection] [Invoice]
        // [SCENARIO 461826] Cannot post purchase invoice with "Prohibited" invoice posting policy.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, '',
          LibraryInventory.CreateItemNo(), Qty, '', WorkDate());

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Prohibited);

        Commit();

        asserterror PostPurchaseDocument(PurchaseHeader);
        Assert.ExpectedError(CannotPostInvoiceErr);

        VerifyQtyOnPurchaseOrderLine(PurchaseLine, 0, 0);

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Mandatory);

        LibraryVariableStorage.Enqueue(StrSubstNo(PostDocConfirmQst, LowerCase(Format(PurchaseHeader."Document Type"))));
        PostPurchaseDocument(PurchaseHeader);

        PurchaseLine.SetRecFilter();
        Assert.RecordIsEmpty(PurchaseLine);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure CalcRemInventoryValueNoValuationDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        Item: Record Item;
    begin
        // [SCENARIO] CalculateRemInventoryValue with no valuation date must filter value on the posting date

        Initialize();

        // [GIVEN] Item I with unit cost X
        CreateItem(Item);

        // [GIVEN] Create a purchase order for the item I, quantity = Y, posting date = workdate
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Post receipt without invoicing
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Change the posting date to WorkDate() + 1 and set quantity to invoice in the purchase line to Y / 2
        PurchaseHeader.Validate("Posting Date", WorkDate() + 1);
        PurchaseHeader.Modify(true);

        PurchaseLine.Find();
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity / 2);
        PurchaseLine.Modify(true);

        // [GIVEN] Post the partial invoicing. Posting date in the created value entry is WorkDate() + 1, valuation date is set to Workdate
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Change the posting date to WorkDate() + 2 and invoice the remaining quantity
        PurchaseHeader.Validate("Posting Date", WorkDate() + 2);
        PurchaseHeader.Validate("Vendor Invoice No.", IncStr(PurchaseHeader."Vendor Invoice No."));
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindLast();

        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Expected Cost", false);
        ValueEntry.FindFirst();

        // [WHEN] Call CalculateRemInventoryValue for the purchase item ledger entry on WorkDate() + 1, including only actual cost
        // [THEN] Inventory value is X * Y / 2
        Assert.AreEqual(
            ValueEntry."Cost Amount (Actual)",
            ItemLedgerEntry.CalculateRemInventoryValue(ItemLedgerEntry."Entry No.", ItemLedgerEntry.Quantity, ItemLedgerEntry.Quantity, false, WorkDate() + 1),
            CalcRemainingInvValueErr);
    end;

    local procedure Initialize()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Purchases & Payables");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        MessageCounter := 0;
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());
        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Allowed);

        if Initialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Purchases & Payables");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        NoSeriesSetup();
        ItemJournalSetup();
        LibrarySetupStorage.SaveInventorySetup();

        Initialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Purchases & Payables");
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

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

    local procedure ModifyInventorySetup(AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type"; AverageCostPeriod: Enum "Average Cost Period Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Adjustment", AutomaticCostAdjustment);
        InventorySetup.Validate("Average Cost Period", AverageCostPeriod);
        InventorySetup.Modify(true);
    end;

    local procedure CreatePurchasingCode(var Purchasing: Record Purchasing)
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", true);
        Purchasing.Modify(true);
    end;

    local procedure CreateDropShipOrders(Item: Record Item; var SalesHeader: Record "Sales Header"; var PurchaseHeader: Record "Purchase Header"; Purchasing: Record Purchasing; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Customer: Record Customer;
        RetrieveDimensionsFrom: Option Item,"Sales Line";
    begin
        // Create drop ship sales order.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Run get sales order on the requisition worksheet.
        GetSalesOrder(SalesLine, RetrieveDimensionsFrom::Item);

        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);

        // Select created Purchase Header.
        PurchaseHeader.SetRange("Sell-to Customer No.", Customer."No.");
        PurchaseHeader.FindLast();
    end;

    local procedure GetSalesOrder(var SalesLine: Record "Sales Line"; RetrieveDimensionsFrom: Option)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        Commit();
        RequisitionLine.Init();
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        RequisitionWkshName.SetRange("Worksheet Template Name", ReqWkshTemplate.Name);
        RequisitionWkshName.FindFirst();
        RequisitionLine.Validate("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.Validate("Journal Batch Name", RequisitionWkshName.Name);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, RetrieveDimensionsFrom);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Validate("Last Direct Cost", Item."Unit Cost");
        Item.Modify(true);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal; UnitCost: Decimal; ExternalDocumentNo: Code[35])
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Validate("Posting Date", WorkDate());
        ItemJournalLine.Validate("External Document No.", ExternalDocumentNo);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateCustomerWithLocation(var Customer: Record Customer; LocationCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Location Code", LocationCode);
        Customer.Modify(true);
    end;

    local procedure PostPurchaseDocuments(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        LinesInstructionMgt: Codeunit "Lines Instruction Mgt.";
    begin
        LinesInstructionMgt.PurchaseCheckAllLinesHaveQuantityAssigned(PurchaseHeader);
        BatchProcessingMgt.SetParametersForPageID(Page::"Purchase Order List");
        PurchaseBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        PurchaseBatchPostMgt.RunWithUI(PurchaseHeader, PurchaseHeader.Count(), ReadyToPostQst);
    end;

    local procedure FilterPurchaseLines(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNoFilter: Text)
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetFilter("Document No.", DocumentNoFilter);
    end;

    local procedure CreateExternalDocumentNo(var ExternalDocNo: Code[35]; var ExternalDocNo2: Code[35]; var ExternalDocNo3: Code[35]; var ExternalDocNo4: Code[35])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ExternalDocNo :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("External Document No."), DATABASE::"Item Journal Line"), 1, 20);
        ExternalDocNo2 :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("External Document No."), DATABASE::"Item Journal Line"), 1, 20);
        ExternalDocNo3 :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("External Document No."), DATABASE::"Item Journal Line"), 1, 20);
        ExternalDocNo4 :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("External Document No."), DATABASE::"Item Journal Line"), 1, 20);
    end;

    local procedure CreateVendorWithLocation(var Vendor: Record Vendor; LocationCode: Code[10])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Location Code", LocationCode);
        Vendor.Modify(true);
    end;

    local procedure CreateItemVendor(var ItemVendor: Record "Item Vendor"; VendorNo: Code[20]; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemVendor(ItemVendor, VendorNo, ItemNo);
        Evaluate(ItemVendor."Lead Time Calculation", '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        ItemVendor.Modify(true);
    end;

    local procedure CreateItemWithTracking(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking & Action Msg.");
        Item.Modify(true);
    end;

    local procedure CreateAndPostSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreatePurchaseInvoiceHeader(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CombinePurchaseReceiptsSetup(var Vendor: Record Vendor; Item: Record Item; var PurchaseReceiptNo: Code[20]; var PurchaseReceiptNo2: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptHeader2: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        // Create and Post Purchase Orders.
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostPurchaseOrder(PurchaseHeader, Vendor."No.", Item."No.");
        FindPurchRcptHeader(PurchRcptHeader, PurchaseHeader."No.");
        PurchaseReceiptNo := PurchRcptHeader."No.";
        Clear(PurchaseHeader);
        CreateAndPostPurchaseOrder(PurchaseHeader, Vendor."No.", Item."No.");
        FindPurchRcptHeader(PurchRcptHeader2, PurchaseHeader."No.");
        PurchaseReceiptNo2 := PurchRcptHeader2."No.";

        // Combine Purchase Receipts and Post Invoice.
        CreatePurchaseInvoiceHeader(PurchaseHeader, Vendor."No.");
        PurchRcptLine.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchRcptLine.FindFirst();

        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure CombineForPurchMemoSetup(Vendor: Record Vendor; PurchaseReceiptNo: Code[20]; PurchaseReceiptNo2: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        ReturnShipmentLine: Record "Return Shipment Line";
        PurchGetReturnShipments: Codeunit "Purch.-Get Return Shipments";
    begin
        // Create and Post Shipment of the Return Orders for the Purchase made.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");
        LibraryPurchase.CopyPurchaseDocument(
            PurchaseHeader, "Purchase Document Type From"::"Posted Receipt", PurchaseReceiptNo, true, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");
        LibraryPurchase.CopyPurchaseDocument(
            PurchaseHeader, "Purchase Document Type From"::"Posted Receipt", PurchaseReceiptNo2, true, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Combine the Receipts to a Credit Memo and Post it.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        ReturnShipmentLine.SetRange("Buy-from Vendor No.", Vendor."No.");
        ReturnShipmentLine.FindFirst();

        PurchGetReturnShipments.SetPurchHeader(PurchaseHeader);
        PurchGetReturnShipments.CreateInvLines(ReturnShipmentLine);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure CombineSalesShipmentsSetup(var Customer: Record Customer; Item: Record Item; var SalesShipmentNo: Code[20]; var SalesShipmentNo2: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentHeader2: Record "Sales Shipment Header";
        SalesShipmentHeader3: Record "Sales Shipment Header";
        SalesHeader2: Record "Sales Header";
    begin
        // Post two Sales Orders.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Combine Shipments", true);
        Customer.Modify(true);

        CreateAndPostSalesOrder(SalesHeader, Customer."No.", Item."No.");
        FindSalesShipmentHeader(SalesShipmentHeader, SalesHeader."No.");
        SalesShipmentNo := SalesShipmentHeader."No.";
        Clear(SalesHeader);
        CreateAndPostSalesOrder(SalesHeader, Customer."No.", Item."No.");
        FindSalesShipmentHeader(SalesShipmentHeader2, SalesHeader."No.");
        SalesShipmentNo2 := SalesShipmentHeader2."No.";

        // Combine Sales Shipments and Post Invoice.
        SalesHeader2.SetRange("Sell-to Customer No.", Customer."No.");
        SalesShipmentHeader3.SetRange("Sell-to Customer No.", Customer."No.");
        LibrarySales.CombineShipments(SalesHeader2, SalesShipmentHeader3, WorkDate(), WorkDate(), false, true, false, false);
    end;

    local procedure CombineForSalesMemoSetup(Customer: Record Customer; SalesShipmentNo: Code[20]; SalesShipmentNo2: Code[20])
    var
        SalesHeader: Record "Sales Header";
        CombineReturnReceipts: Report "Combine Return Receipts";
    begin
        // create and post receipt of the return orders for the sales made
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", Customer."No.");
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Shipment", SalesShipmentNo, true, false);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", Customer."No.");
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Shipment", SalesShipmentNo2, true, false);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // combine the receipts to a credit memo and post it.
        LibraryVariableStorage.Enqueue(SalesHeader."Sell-to Customer No.");
        Clear(CombineReturnReceipts);
        CombineReturnReceipts.Run();
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateUserSetupWithPostingPolicy(InvoicePostingPolicy: Enum "Invoice Posting Policy")
    var
        UserSetup: Record "User Setup";
    begin
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup.Validate("Purch. Invoice Posting Policy", InvoicePostingPolicy);
        UserSetup.Modify(true);
    end;

    local procedure FindPurchRcptHeader(var PurchRcptHeader: Record "Purch. Rcpt. Header"; OrderNo: Code[20])
    begin
        PurchRcptHeader.SetRange("Order No.", OrderNo);
        PurchRcptHeader.FindFirst();
    end;

    local procedure FindSalesShipmentHeader(var SalesShipmentHeader: Record "Sales Shipment Header"; OrderNo: Code[20])
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst();
    end;

    local procedure UpdateLeadTimeCalculationOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; var LeadTimeCalculation: DateFormula)
    begin
        Evaluate(LeadTimeCalculation, '<' + Format(LibraryRandom.RandInt(10)) + 'M>');
        PurchaseLine.Validate("Lead Time Calculation", LeadTimeCalculation);
        PurchaseLine.Modify(true);
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
    end;

    local procedure PostPurchaseDocument(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Find();
        Codeunit.Run(Codeunit::"Purch.-Post (Yes/No)", PurchaseHeader);
    end;

    local procedure VerifySalesEntry(ItemNo: Code[20]; SalesOrderNo: Code[20]; VerifyLineType: Option Shipment,Invoice; SalesExpectedAmount: Decimal; SalesActualAmount: Decimal; CostExpectedAmount: Decimal; CostActualAmount: Decimal)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Sale);
        case VerifyLineType of
            VerifyLineType::Shipment:
                begin
                    SalesShipmentHeader.SetRange("Order No.", SalesOrderNo);
                    SalesShipmentHeader.FindFirst();
                    ItemLedgEntry.SetRange("Document No.", SalesShipmentHeader."No.");
                end;
            VerifyLineType::Invoice:
                begin
                    SalesInvoiceHeader.SetRange("Order No.", SalesOrderNo);
                    SalesInvoiceHeader.FindFirst();
                    ItemLedgEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
                end;
        end;
        ItemLedgEntry.FindFirst();
        ItemLedgEntry.CalcFields("Sales Amount (Expected)", "Cost Amount (Expected)", "Sales Amount (Actual)", "Cost Amount (Actual)");
        Assert.AreEqual(SalesExpectedAmount, ItemLedgEntry."Sales Amount (Expected)", SalesAmountExpectedErr);
        Assert.AreEqual(SalesActualAmount, ItemLedgEntry."Sales Amount (Actual)", SalesAmountActualErr);
        Assert.AreEqual(-1 * CostExpectedAmount, ItemLedgEntry."Cost Amount (Expected)", CostAmountExpectedErr);
        Assert.AreEqual(-1 * CostActualAmount, ItemLedgEntry."Cost Amount (Actual)", CostAmountActualErr);
    end;

    local procedure VerifyPurchEntry(ItemNo: Code[20]; PurchOrderNo: Code[20]; VerifyLineType: Option Receipt,Invoice; CostExpectedAmount: Decimal; CostActualAmount: Decimal)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Purchase);
        case VerifyLineType of
            VerifyLineType::Receipt:
                begin
                    PurchRcptHeader.SetRange("Order No.", PurchOrderNo);
                    PurchRcptHeader.FindFirst();
                    ItemLedgEntry.SetRange("Document No.", PurchRcptHeader."No.");
                end;
            VerifyLineType::Invoice:
                begin
                    PurchInvHeader.SetRange("Order No.", PurchOrderNo);
                    PurchInvHeader.FindFirst();
                    ItemLedgEntry.SetRange("Document No.", PurchInvHeader."No.");
                end;
        end;
        ItemLedgEntry.FindFirst();
        ItemLedgEntry.CalcFields("Cost Amount (Expected)", "Cost Amount (Actual)");
        Assert.AreEqual(CostExpectedAmount, ItemLedgEntry."Cost Amount (Expected)", CostAmountExpectedErr);
        Assert.AreEqual(CostActualAmount, ItemLedgEntry."Cost Amount (Actual)", CostAmountActualErr);
    end;

    local procedure VerifyPurchLine(ItemNo: Code[20])
    var
        InventorySetup: Record "Inventory Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        InventorySetup.Get();
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Expected Receipt Date", CalcDate(InventorySetup."Default Safety Lead Time", WorkDate()));
        PurchaseLine.TestField("Promised Receipt Date", WorkDate());
    end;

    local procedure VerifyCostAmountLedgerEntry(ItemNo: Code[20]; CostAmountAct: Decimal; ExternalDocumentNo: Code[35])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        GeneralLedgerSetup.Get();
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("External Document No.", ExternalDocumentNo);
        ItemLedgerEntry.FindFirst();

        ItemLedgerEntry.CalcFields("Cost Amount (Expected)", "Cost Amount (Actual)");
        Assert.AreNearlyEqual(
          0, ItemLedgerEntry."Cost Amount (Expected)", GeneralLedgerSetup."Amount Rounding Precision", CostAmountExpectedErr);
        Assert.AreNearlyEqual(
          CostAmountAct, ItemLedgerEntry."Cost Amount (Actual)", GeneralLedgerSetup."Amount Rounding Precision", CostAmountActualErr);
    end;

    local procedure VerifyQtyOnPurchaseOrderLine(PurchaseLine: Record "Purchase Line"; QtyReceived: Decimal; QtyInvoiced: Decimal)
    begin
        PurchaseLine.Find();
        PurchaseLine.TestField("Quantity Received", QtyReceived);
        PurchaseLine.TestField("Quantity Invoiced", QtyInvoiced);
    end;

    local procedure VerifyQtyOnPurchaseReturnOrderLine(PurchaseLine: Record "Purchase Line"; QtyReturned: Decimal; QtyInvoiced: Decimal)
    begin
        PurchaseLine.Find();
        PurchaseLine.TestField("Return Qty. Shipped", QtyReturned);
        PurchaseLine.TestField("Quantity Invoiced", QtyInvoiced);
    end;

    local procedure VerifyValueEntry(EntryType: Enum "Cost Entry Type"; DocumentNo: Code[20]; ItemNo: Code[20]; CostAmt: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Entry Type", EntryType);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Cost Amount (Actual)", CostAmt);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(
          StrPos(Message, 'The change will not affect existing entries.') > 0, StrSubstNo(IncorrectMessageErr, Message));
    end;

    [MessageHandler]
    procedure GenericMessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ChangeLocationConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Message: Text[1024]; var Response: Boolean)
    begin
        Assert.ExpectedConfirm(LibraryVariableStorage.DequeueText(), Message);
        Response := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CombinedMessageHandler(Message: Text[1024])
    begin
        MessageCounter += 1;
        case MessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, 'The shipments are now combined and the number of invoices created is 1.') > 0, Message);
            2:
                Assert.IsTrue(
                  StrPos(Message, 'The return receipts are now combined and the number of credit memos created is 1.') > 0, Message);
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CombineReturnReceiptsRequestPageHandler(var CombineReturnReceipts: TestRequestPage "Combine Return Receipts")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        CombineReturnReceipts.PostingDateReq.SetValue(WorkDate());
        CombineReturnReceipts.DocDateReq.SetValue(WorkDate());
        CombineReturnReceipts.SalesOrderHeader.SetFilter("Sell-to Customer No.", DequeueVariable);
        CombineReturnReceipts.OK().Invoke();
    end;
}

