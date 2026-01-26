codeunit 137263 "SCM Tracking Package Base"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        PostedItemDocumentShowTrackingErr: Label 'Can''t show Posted Item Tracking Page.';
        UnitAmountErr: Label '%1 is should be modifiable in Inventory Receipt with Item Tracking.', Comment = '%1 = Field Name';

    [Test]
    [Scope('OnPrem')]
    procedure TestPositiveAdjustment()
    var
        Location: Record Location;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJnlLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemTrackingSetup: array[2] of Record "Item Tracking Setup";
        PackageNo: array[2] of Code[50];
    begin
        // scenario for positive adjustment with item journal
        // one item journal line with 2 different Package numbers

        Initialize();
        InitScenarioOneItemTwoPackages(Location, Item, PackageNo);
        ItemTrackingSetup[1]."Package No." := PackageNo[1];
        ItemTrackingSetup[2]."Package No." := PackageNo[2];
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 20);

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, Location.Code);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo[1], 6);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo[2], 4);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', PackageNo[1], 6);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', PackageNo[2], 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrder()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Vendor: Record Vendor;
        PackageNo: array[2, 2] of Code[50];
        Qty: array[2, 2] of Decimal;
        i: Integer;
        j: Integer;
    begin
        // scenario for purchase order
        // 2 items with 2 different package numbers are purchased

        Initialize();
        PurchaseOrderScenario(Vendor, Location, Item, PackageNo, Qty);
        for i := 1 to ArrayLen(Qty, 1) do
            for j := 1 to ArrayLen(Qty, 2) do
                LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[i]."No.", Location.Code, '', '', PackageNo[i, j], Qty[i, j]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseCreditMemo()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        Qty: array[2, 2] of Decimal;
        PackageNo: array[2, 2] of Code[50];
        i: Integer;
        j: Integer;
    begin
        // scenario for purchase credit memo
        // 2 items with 2 different package numbers are purchased
        // after that, credit memo is created and posted

        Initialize();
        PurchaseOrderScenario(Vendor, Location, Item, PackageNo, Qty);

        for i := 1 to ArrayLen(Qty, 1) do begin
            LibraryPurchase.CreatePurchaseCreditMemoWithLocation(PurchaseHeader[i], Vendor."No.", Location.Code);
            for j := 1 to ArrayLen(Qty, 2) do
                CreatePurchLineWithTracking(
                  PurchaseHeader[i], Item[i]."No.", PackageNo[i, j], LibraryRandom.RandDec(100, 2), Qty[i, j]);
            LibrarySmallBusiness.UpdatePurchHeaderDocTotal(PurchaseHeader[i]);
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader[i], true, true);
            for j := 1 to ArrayLen(Qty, 2) do
                LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[i]."No.", Location.Code, '', '', PackageNo[i, j], -Qty[i, j]);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrder()
    var
        Location: Record Location;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        PackageNo: array[2] of Code[50];
        TotalQty: Decimal;
        Qty: array[2] of Decimal;
        i: Integer;
    begin
        // scenario for sales order
        // 1. positive adjustment
        // 2. sales order

        Initialize();
        InitScenarioOneItemTwoPackages(Location, Item, PackageNo);
        InitQty(TotalQty, Qty);
        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", TotalQty, Location.Code);
        for i := 1 to ArrayLen(Qty) do
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo[i], Qty[i]);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, Customer."No.", Location.Code);
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine, SalesHeader, Item."No.", LibraryRandom.RandDec(100, 2), TotalQty);
        for i := 1 to ArrayLen(Qty) do
            LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', '', PackageNo[i], Qty[i]);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        for i := 1 to ArrayLen(Qty) do
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', PackageNo[i], -Qty[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderReservation()
    var
        Location: Record Location;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNo: array[2] of Code[50];
        TotalQty: Decimal;
        Qty: array[2] of Decimal;
        i: Integer;
    begin
        // scenario for sales order reservation
        // 1. positive adjustment
        // 2. sales order
        // instead of direct setup of item tracking following schema is used:
        // a. Creating reservation for sales line
        // b. Transfer reservation to item tracking by using function
        // "Create Tracking From Reservation"

        Initialize();
        InitScenarioOneItemTwoPackages(Location, Item, PackageNo);
        InitQty(TotalQty, Qty);
        LibraryInventory.CreateItemJnlLine(
          ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", TotalQty, Location.Code);
        for i := 1 to ArrayLen(Qty) do
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo[i], Qty[i]);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, Customer."No.", Location.Code);
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine, SalesHeader, Item."No.", LibraryRandom.RandDec(100, 2), TotalQty);
        SalesLine.AutoReserve();
        LibraryItemTracking.CreateSalesTrackingFromReservation(SalesHeader, true);

        for i := 1 to ArrayLen(Qty) do
            LibraryItemTracking.CheckSalesReservationEntry(
              SalesLine, '', '', PackageNo[i], -Qty[i], ReservationEntry."Reservation Status"::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesCopyDocument()
    var
        Location: Record Location;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        CopySalesDocument: Report "Copy Sales Document";
        PackageNo: array[2] of Code[50];
        TotalQty: Decimal;
        Qty: array[2] of Decimal;
        i: Integer;
    begin
        // scenario for copy sales document function
        // 1. positive adjustment
        // 2. sales order
        // 3. sales return order copied from posted sales invoice

        Initialize();
        InitScenarioOneItemTwoPackages(Location, Item, PackageNo);
        InitQty(TotalQty, Qty);
        LibraryInventory.CreateItemJnlLine(
          ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", TotalQty, Location.Code);

        for i := 1 to ArrayLen(Qty) do
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo[i], Qty[i]);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, Customer."No.", Location.Code);
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine, SalesHeader, Item."No.", LibraryRandom.RandDec(100, 2), TotalQty);
        for i := 1 to ArrayLen(Qty) do
            LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', '', PackageNo[i], Qty[i]);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CreateSalesReturnOrder(SalesHeader, Customer."No.", Location.Code);
        CopySalesDocument.SetSalesHeader(SalesHeader);
        CopySalesDocument.SetParameters("Sales Document Type From"::"Posted Invoice", FindLastPostedSalesInvoiceNo(Customer."No."), true, true);
        CopySalesDocument.UseRequestPage(false);
        CopySalesDocument.Run();

        FindFirstSalesLine(SalesLine, SalesHeader, Item."No.");
        for i := 1 to ArrayLen(Qty) do
            LibraryItemTracking.CheckSalesReservationEntry(
              SalesLine, '', '', PackageNo[i], Qty[i], ReservationEntry."Reservation Status"::Surplus);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTransferOrder()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: array[2] of Code[50];
        TotalQty: Decimal;
        Qty: array[2] of Decimal;
        i: Integer;
    begin
        // scenario for transfer order
        // 1. positive adjustment
        // 2. transfer order

        Initialize();
        InitQty(TotalQty, Qty);
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        for i := 1 to ArrayLen(Qty) do begin
            PackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[i]);
        end;

        LibraryInventory.CreateItemJnlLine(
          ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", TotalQty, LocationFrom.Code);
        for i := 1 to ArrayLen(Qty) do
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo[i], Qty[i]);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(
          TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", TotalQty);
        for i := 1 to ArrayLen(Qty) do
            LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', '', PackageNo[i], Qty[i]);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        for i := 1 to ArrayLen(Qty) do
            LibraryItemTracking.CheckLastItemLedgerEntry(
              ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', PackageNo[i], Qty[i]);
    end;


    [Test]
    [Scope('OnPrem')]
    procedure TestItemDocuments()
    var
        Location: Record Location;
        Item: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        PackageNo: array[2] of Code[50];
        TotalQty: Decimal;
        Qty: array[2] of Decimal;
    begin
        Initialize();
        InitScenarioOneItemTwoPackages(Location, Item, PackageNo);
        InitQty(TotalQty, Qty);

        TestItemDocument(
          InvtDocumentHeader."Document Type"::Receipt, Location.Code, Item."No.", PackageNo, TotalQty, Qty);
        TestItemDocument(
          InvtDocumentHeader."Document Type"::Shipment, Location.Code, Item."No.", PackageNo, TotalQty, Qty);
    end;

    [Test]
    [HandlerFunctions('PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure PostedItemTrackingLinesShowOnPostedItemDocuments()
    var
        Location: Record Location;
        Item: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtReceiptHeader: Record "Invt. Receipt Header";
        InvtReceiptLine: Record "Invt. Receipt Line";
        InvtShipmentHeader: Record "Invt. Shipment Header";
        InvtShipmentLine: Record "Invt. Shipment Line";
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        ReceiptNo: Code[20];
        ShipmentNo: Code[20];
        PackageNo: array[2] of Code[50];
        TotalQty: Decimal;
        Qty: array[2] of Decimal;
    begin
        // [FEATURE] [Item Document]
        // [SCENARIO 379460] On pages Posted Item Receipt and Shipment Subform an action Item Tracking Lines shows tracking info
        Initialize();
        InitScenarioOneItemTwoPackages(Location, Item, PackageNo);
        InitQty(TotalQty, Qty);

        // [WHEN] Posted Item Receipt and Shipment with package tracking on lines
        ReceiptNo := TestItemDocument(InvtDocumentHeader."Document Type"::Receipt, Location.Code, Item."No.", PackageNo, TotalQty, Qty);
        ShipmentNo := TestItemDocument(InvtDocumentHeader."Document Type"::Shipment, Location.Code, Item."No.", PackageNo, TotalQty, Qty);

        // [THEN] ItemTrackingDocMgt.ShowItemTrackingForInvoiceLine is true on receipt line
        InvtReceiptHeader.SetRange("Receipt No.", ReceiptNo);
        InvtReceiptHeader.FindFirst();
        InvtReceiptLine.SetRange("Document No.", InvtReceiptHeader."No.");
        InvtReceiptLine.FindFirst();

        Assert.IsTrue(ItemTrackingDocMgt.ShowItemTrackingForInvoiceLine(InvtReceiptLine.RowID1()), PostedItemDocumentShowTrackingErr);

        // [THEN] ItemTrackingDocMgt.ShowItemTrackingForInvoiceLine is true on shipment line
        InvtShipmentHeader.SetRange("Shipment No.", ShipmentNo);
        InvtShipmentHeader.FindFirst();
        InvtShipmentLine.SetRange("Document No.", InvtShipmentHeader."No.");
        InvtShipmentLine.FindFirst();

        Assert.IsTrue(ItemTrackingDocMgt.ShowItemTrackingForInvoiceLine(InvtShipmentLine.RowID1()), PostedItemDocumentShowTrackingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnableItemTrackingCodeWithPackageSpecificShouldBeAllowed()
    var
        Location: Record Location;
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        // [FEATURE] [Package Tracking]
        // [SCENARIO] Package Specific Tracking can be enabled for the Item with item tracking code and 
        // without item ledger entries
        Initialize();

        // [THEN] Create new Item with Lot Tracking
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ItemTrackingSetup."Lot No. Required" := true;
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, ItemTrackingSetup);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        // [WHEN] Package Specific Tracking can be enabled for Item Tracking Code
        ItemTrackingCode.Validate("Package Specific Tracking", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnableItemTrackingCodeWithPackageSpecificShouldNotBeAllowed()
    var
        Location: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Package Tracking]
        // [SCENARIO] Package Specific Tracking cannot be enabled for the Item with item tracking code and existing item ledger entries
        Initialize();

        // [THEN] Create Item with Lot Tracking
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ItemTrackingSetup."Lot No. Required" := true;
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, ItemTrackingSetup);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        // [THEN] Post positive adjustment quantity with lot tracking
        LibraryInventory.CreateItemJnlLine(
          ItemJournalLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, Location.Code);
        ItemTrackingSetup."Lot No." := 'LOT1';
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, ItemTrackingSetup, 10);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJournalLine);

        // [WHEN] Package Specific Tracking cannot be enabled for Item Tracking Code
        asserterror ItemTrackingCode.Validate("Package Specific Tracking", true);
    end;

    [Test]
    procedure IsWarehouseTrackingChecksForPackageWhseTrackingSetting()
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 424706] IsWarehouseTracking() function in Item Tracking Code table returns Package Warehouse Tracking value.
        Initialize();

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        Assert.IsTrue(ItemTrackingCode.IsWarehouseTracking(), '');

        ItemTrackingCode."Package Warehouse Tracking" := false;
        Assert.IsFalse(ItemTrackingCode.IsWarehouseTracking(), '')
    end;

    [Test]
    procedure UnitAmountModifiableInInventoryReceiptWithItemTracking()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        Location: Record Location;
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        InvtReceiptSubform: TestPage "Invt. Receipt Subform";
        InvtDocType: Enum "Invt. Doc. Document Type";
        Qty: Decimal;
        UnitAmount: Decimal;
    begin
        // [SCENARIO 592752] In Inventory Receipts with an Item Tracked Item, adjusting the Unit Amount is allowed.
        Initialize();

        // [GIVEN] Create Item Tracking Code.
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("SN Specific Tracking", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN]  Create Item with Item Tracking Code.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);

        // [GIVEN] Create Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Invt. Document Receipt.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocType::Receipt, Location.Code);

        // [GIVEN] Create Quantity for Invt. Document Line.
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Create Invt. Document Line.
        LibraryInventory.CreateInvtDocumentLine(
            InvtDocumentHeader,
            InvtDocumentLine,
            Item."No.",
            LibraryRandom.RandDec(100, 2),
            Qty);

        // [GIVEN] Create Item Receipt Item Tracking.
        LibraryItemTracking.CreateItemReceiptItemTracking(ReservationEntry, InvtDocumentLine, LibraryUtility.GenerateGUID(), '', '', LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Store the Unit Amount to be assigned.
        UnitAmount := LibraryRandom.RandDecInDecimalRange(500, 1000, 2);

        // [WHEN] Assign the Dimension Value to Invt. Document Line
        InvtReceiptSubform.OpenEdit();
        InvtReceiptSubform.GoToRecord(InvtDocumentLine);
        InvtReceiptSubform."Unit Amount".SetValue(UnitAmount);

        // [THEN] Unit Amount should be modifiable in Inventory Receipt with Item Tracking.
        Assert.AreEqual(
            UnitAmount,
            InvtReceiptSubform."Unit Amount".AsDecimal(),
            StrSubstNo(
                UnitAmountErr,
                InvtDocumentLine.FieldCaption("Unit Amount")));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Tracking Package Base");
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Tracking Package Base");
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateLocalData();

        SetupInvtDocNosInInvSetup();
        SetupTransferNosInInvSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Tracking Package Base");
    end;

    local procedure SetupTransferNosInInvSetup()
    var
        InvSetup: Record "Inventory Setup";
    begin
        InvSetup.Get();
        if InvSetup."Transfer Order Nos." = '' then
            InvSetup.Validate("Transfer Order Nos.", CreateNoSeries());
        if InvSetup."Posted Transfer Shpt. Nos." = '' then
            InvSetup.Validate("Posted Transfer Shpt. Nos.", CreateNoSeries());
        if InvSetup."Posted Transfer Rcpt. Nos." = '' then
            InvSetup.Validate("Posted Transfer Rcpt. Nos.", CreateNoSeries());
        InvSetup.Modify(true);
    end;

    local procedure SetupInvtDocNosInInvSetup()
    var
        InvSetup: Record "Inventory Setup";
    begin
        InvSetup.Get();
        if InvSetup."Invt. Receipt Nos." = '' then
            InvSetup.Validate("Invt. Receipt Nos.", CreateNoSeries());
        if InvSetup."Posted Invt. Receipt Nos." = '' then
            InvSetup.Validate("Posted Invt. Receipt Nos.", CreateNoSeries());
        if InvSetup."Invt. Shipment Nos." = '' then
            InvSetup.Validate("Invt. Shipment Nos.", CreateNoSeries());
        if InvSetup."Posted Invt. Shipment Nos." = '' then
            InvSetup.Validate("Posted Invt. Shipment Nos.", CreateNoSeries());
        InvSetup.Modify(true);
    end;

    local procedure InitQty(var TotalQty: Decimal; var Qty: array[2] of Decimal)
    begin
        TotalQty := 3 + LibraryRandom.RandInt(10);
        Qty[1] := Round(TotalQty / 3, 1);
        Qty[2] := TotalQty - Qty[1];
    end;

    local procedure InitScenarioOneItemTwoPackages(var Location: Record Location; var Item: Record Item; var PackageNo: array[2] of Code[50])
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
        PackageNoInfo: Record "Package No. Information";
        i: Integer;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ItemTrackingSetup."Package No. Required" := true;
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, ItemTrackingSetup);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        for i := 1 to ArrayLen(PackageNo) do begin
            PackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[i]);
        end;
    end;

    local procedure PurchaseOrderScenario(var Vendor: Record Vendor; var Location: Record Location; var Item: array[2] of Record Item; var PackageNo: array[2, 2] of Code[50]; var Qty: array[2, 2] of Decimal)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: array[2] of Record "Purchase Header";
        PackageNoInfo: Record "Package No. Information";
        i: Integer;
        j: Integer;
    begin
        // scenario for purchase order
        // 2 items with 2 different package numbers are purchased

        LibraryPurchase.CreateVendor(Vendor);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        for i := 1 to ArrayLen(Item) do begin
            LibraryItemTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode);
            LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader[i], Vendor."No.", Location.Code);
            for j := 1 to 2 do begin
                PackageNo[i, j] := LibraryUtility.GenerateGUID();
                LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item[i]."No.", PackageNo[i, j]);
                Qty[i, j] := LibraryRandom.RandInt(100);
                CreatePurchLineWithTracking(
                  PurchaseHeader[i], Item[i]."No.", PackageNo[i, j], LibraryRandom.RandDec(100, 2), Qty[i, j]);
            end;
            LibrarySmallBusiness.UpdatePurchHeaderDocTotal(PurchaseHeader[i]);
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader[i], true, true);
        end;
    end;

    local procedure TestItemDocument(InvtDocType: Enum "Invt. Doc. Document Type"; LocationCode: Code[10]; ItemNo: Code[20]; PackageNo: array[2] of Code[50]; TotalQty: Decimal; Qty: array[2] of Decimal): Code[20]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        ReservationEntry: Record "Reservation Entry";
        i: Integer;
    begin
        // scenario for item documents
        // one item 2 different package numbers

        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocType, LocationCode);
        LibraryInventory.CreateInvtDocumentLine(
          InvtDocumentHeader, InvtDocumentLine, ItemNo, LibraryRandom.RandDec(100, 2), TotalQty);
        for i := 1 to ArrayLen(Qty) do
            LibraryItemTracking.CreateItemReceiptItemTracking(ReservationEntry, InvtDocumentLine, '', '', PackageNo[i], Qty[i]);
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);
        for i := 1 to ArrayLen(Qty) do
            LibraryItemTracking.CheckLastItemLedgerEntry(
              ItemLedgerEntry, ItemNo, LocationCode, '', '', PackageNo[i], GetItemDocSign(InvtDocType) * Qty[i]);
        exit(InvtDocumentHeader."No.");
    end;

    local procedure CreatePurchLineWithTracking(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; PackageNo: Code[50]; UnitCost: Decimal; Qty: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, ItemNo, UnitCost, Qty);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo, Qty);
    end;

    procedure CreateSalesReturnOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CustomerNo);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify();
    end;

    local procedure CreateNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        exit(NoSeries.Code);
    end;

    local procedure GetitemDocSign(InvtDocType: Enum "Invt. Doc. Document Type"): Integer
    var
        InvtDocumentHeader: Record "Invt. Document Header";
    begin
        case InvtDocType of
            InvtDocumentHeader."Document Type"::Receipt:
                exit(1);
            InvtDocumentHeader."Document Type"::Shipment:
                exit(-1);
        end;
    end;

    local procedure FindLastPostedSalesInvoiceNo(CustNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetCurrentKey("Sell-to Customer No.");
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", CustNo);
        SalesInvoiceHeader.FindLast();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure FindFirstSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, "Sales Line Type"::Item);
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindFirst();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedItemTrackingLinesHandler(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    begin
    end;
}

