codeunit 137140 "SCM Inventory Documents"
{
    // // [FEATURE] [SCM] [Inventory Documents]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        isInitialized: Boolean;
        ItemTrackingAction: Option AssignSerialNo,SelectEntries;
        RoundingTo0Err: Label 'Rounding of the field';
        RoundingErr: Label 'is of lower precision than expected';
        ItemNoErr: Label 'Item No. are not equal';
        UnitOfMeasureCodeErr: Label 'Unit of Measure Code are not equal';
        UnitCostErr: Label 'Unit Cost are not equal';
        DimensionErr: Label 'Expected dimension should be %1.', Comment = '%1=Value';
        SourceCodeErr: Label 'Source Code should not be blank in %1.', Comment = '%1=TableCaption()';
        DimensionValueErr: Label 'Dimension Value must match with %1', Comment = '%1= Dimension Value';
        ReorderingPolicyShouldBeVisibleErr: Label 'Reordering Policy should be visible.';
        SpecialEquipmentCodeShouldBeVisibleErr: Label 'Special Equipment Code should be visible.';
        DueDateBeforeWorkDateMsg: Label 'is before work date';
        TransferOrderErr: Label 'Transfer Order has not been posted successfully.';
        ReserveMustNotBeNeverErr: Label 'Reserve must not be Never';
        InventoryReceiptErr: Label 'Inventory Receipt has not been posted successfully.';

    [Test]
    [Scope('OnPrem')]
    procedure ItemReceiptWithDimension()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
    begin
        // Setup
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);

        // Execute
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        InvtDocumentHeader.Validate("Salesperson/Purchaser Code", SalespersonPurchaser.Code);
        InvtDocumentHeader.Modify(true);

        // Verify
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, InvtDocumentHeader."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReceiptWithDimensionLines()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        DimensionValueItem: Record "Dimension Value";
    begin
        // Setup
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        CreateItemWithDimension(Item, DimensionValueItem);

        // Execute
        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Receipt, Location.Code, SalespersonPurchaser.Code);

        // Verify
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, InvtDocumentLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemShipmentWithDimension()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
    begin
        // Setup
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);

        // Execute
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment, Location.Code);
        InvtDocumentHeader.Validate("Salesperson/Purchaser Code", SalespersonPurchaser.Code);
        InvtDocumentHeader.Modify(true);

        // Verify
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, InvtDocumentHeader."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemShipmentWithDimensionLines()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
    begin
        // Setup
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        CreateItemWithDimension(Item, DimensionValue);

        // Execute
        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Shipment, Location.Code, SalespersonPurchaser.Code);

        // Verify
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, InvtDocumentLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedItemReceiptWithDimension()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        DimensionValueItem: Record "Dimension Value";
        ItemReceiptHeader: Record "Invt. Receipt Header";
        ItemReceiptLine: Record "Invt. Receipt Line";
    begin
        // Setup
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        CreateItemWithDimension(Item, DimensionValueItem);

        // Execute
        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Receipt, Location.Code, SalespersonPurchaser.Code);
        InvtDocumentHeader."Posting No." := LibraryUtility.GenerateGUID();
        InvtDocumentHeader.Modify();
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // Verify
        ItemReceiptHeader.Get(InvtDocumentHeader."Posting No.");
        ItemReceiptHeader.TestField("Location Code", Location.Code);
        Assert.AreEqual(SalespersonPurchaser.Code, ItemReceiptHeader."Purchaser Code", 'Purchaser code should be same');
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, ItemReceiptHeader."Dimension Set ID");
        ItemReceiptLine.SetRange("Document No.", ItemReceiptHeader."No.");
        ItemReceiptLine.FindFirst();
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, ItemReceiptLine."Dimension Set ID");
        VerifyDimensionCode(DimensionValueItem."Dimension Code", DimensionValueItem.Code, ItemReceiptLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedItemShipmentWithDimension()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        DimensionValueItem: Record "Dimension Value";
        InvtShipmentHeader: Record "Invt. Shipment Header";
        InvtShipmentLine: Record "Invt. Shipment Line";
    begin
        // Setup
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        CreateItemWithDimension(Item, DimensionValueItem);

        // Execute
        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Shipment, Location.Code, SalespersonPurchaser.Code);
        InvtDocumentHeader."Posting No." := LibraryUtility.GenerateGUID();
        InvtDocumentHeader.Modify();
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // Verify
        InvtShipmentHeader.Get(InvtDocumentHeader."Posting No.");
        InvtShipmentHeader.TestField("Location Code", Location.Code);
        Assert.AreEqual(SalespersonPurchaser.Code, InvtShipmentHeader."Salesperson Code", 'Salesperson code should be same');
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, InvtShipmentHeader."Dimension Set ID");
        InvtShipmentLine.SetRange("Document No.", InvtShipmentHeader."No.");
        InvtShipmentLine.FindFirst();
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, InvtShipmentLine."Dimension Set ID");
        VerifyDimensionCode(DimensionValueItem."Dimension Code", DimensionValueItem.Code, InvtShipmentLine."Dimension Set ID");
    end;


    [Test]
    [Scope('OnPrem')]
    procedure PostedItemShipmentWithCopyCommentAutomatic()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
        Item: Record Item;
        InventoryCommentLine: Record "Inventory Comment Line";
        InvtShipmentHeader: Record "Invt. Shipment Header";
    begin
        // [SCENARIO] Create and post invt. shipment with comments and links.
        Initialize();
        SetCopyInvtDocComments();

        // [GIVEN] Create an Location and Item
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Invt. Document
        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Shipment, Location.Code, '');
        InvtDocumentHeader."Posting No." := LibraryUtility.GenerateGUID();
        InvtDocumentHeader.Modify();

        // [GIVEN] Add some comments and links
        CreateInvtComments(InvtDocumentHeader, 2);
        InvtDocumentHeader.AddLink(LibraryRandom.RandText(100), LibraryRandom.RandText(200));

        // [WHEN] Post Document
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [THEN] Links and comments are copied to posted Invt. Shipment Header
        InvtShipmentHeader.Get(InvtDocumentHeader."Posting No.");
        Assert.IsTrue(InvtShipmentHeader.HasLinks(), 'The Record Links must be copied.');
        InventoryCommentLine.SetRange("Document Type", InventoryCommentLine."Document Type"::"Posted Inventory Shipment");
        InventoryCommentLine.SetRange("No.", InvtShipmentHeader."No.");
        Assert.RecordCount(InventoryCommentLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedItemReceiptWithCopyCommentAutomatic()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
        Item: Record Item;
        InventoryCommentLine: Record "Inventory Comment Line";
        ItemReceiptHeader: Record "Invt. Receipt Header";
    begin
        // [SCENARIO] Create and post invt receipt with comments and links.
        Initialize();
        SetCopyInvtDocComments();

        // [GIVEN] Create an Location and Item
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Invt. Document
        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Receipt, Location.Code, '');
        InvtDocumentHeader."Posting No." := LibraryUtility.GenerateGUID();
        InvtDocumentHeader.Modify();

        // [GIVEN] Add some comments and links
        CreateInvtComments(InvtDocumentHeader, 3);
        InvtDocumentHeader.AddLink(LibraryRandom.RandText(100), LibraryRandom.RandText(200));

        // [WHEN] Post Document
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [THEN] Links and comments are copied to posted Invt. Receipt Header
        ItemReceiptHeader.Get(InvtDocumentHeader."Posting No.");
        Assert.IsTrue(ItemReceiptHeader.HasLinks(), 'The Record Links must be copied.');
        InventoryCommentLine.SetRange("Document Type", InventoryCommentLine."Document Type"::"Posted Inventory Receipt");
        InventoryCommentLine.SetRange("No.", ItemReceiptHeader."No.");
        Assert.RecordCount(InventoryCommentLine, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDirectTransferRequireReceive()
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        Bin: Record Bin;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Qty: Integer;
    begin
        // [FEATURE] [Location] [Warehouse] [Direct Transfer]
        // [SCENARIO 253751] Direct transfer to location with inbound warehouse handling should not be posted

        Initialize();

        // [GIVEN] Two locations: "A" without warehouse setup, and "B" with "Require Receipt" enabled
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWMS(ToLocation, true, false, false, true, false);
        LibraryWarehouse.CreateBin(Bin, ToLocation.Code, '', '', '');

        // [GIVEN] Item "I" with stock of 100 pcs on location "A"
        Qty := CreateAndPostItemJournalLine(Item."No.", FromLocation.Code, '');

        // [GIVEN] Create a direct transfer order from location "A" to location "B"
        CreateDirectTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Qty);
        TransferLine.Validate("Transfer-To Bin Code", Bin.Code);
        TransferLine.Modify(true);

        // [WHEN] Post the transfer using "Direct Transfer Posting" = "Direct Transfer"
        SetDirectTransferPosting(1);
        asserterror LibraryInventory.PostDirectTransferOrder(TransferHeader);
        SetDirectTransferPosting(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDirectTransferRequireShipment()
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        Bin: Record Bin;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseEntry: Record "Warehouse Entry";
        Qty: Integer;
    begin
        // [FEATURE] [Location] [Warehouse] [Direct Transfer]
        // [SCENARIO 253751] Direct transfer from location with outbound warehouse handling should be posted without warehouse shipment

        Initialize();

        // [GIVEN] Two locations: "A" with "Require Shipment" enabled, and "B" without warehouse setup
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(FromLocation, true, false, false, false, true);
        LibraryWarehouse.CreateBin(Bin, FromLocation.Code, '', '', '');
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);

        // [GIVEN] Item "I" with stock of 100 pcs on location "A"
        Qty := CreateAndPostItemJournalLine(Item."No.", FromLocation.Code, Bin.Code);

        // [GIVEN] Create a direct transfer order from location "A" to location "B"
        CreateDirectTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Qty);
        TransferLine.Validate("Transfer-from Bin Code", Bin.Code);
        TransferLine.Validate("Qty. to Ship", TransferLine.Quantity);
        TransferLine.Modify(true);

        // [WHEN] Post the transfer using "Direct Transfer Posting" = "Direct Transfer"
        SetDirectTransferPosting(1);
        LibraryInventory.PostDirectTransferOrder(TransferHeader);
        SetDirectTransferPosting(0);

        // [THEN] Item ledger shows 100 pcs of item "I" moved to location "B"
        VerifyItemInventory(Item, ToLocation.Code, Qty);

        // [THEN] Negative adjustment for -100 pcs of item "I" is posted on location "B"
        VerifyWarehouseEntry(FromLocation.Code, Item."No.", WarehouseEntry."Entry Type"::"Negative Adjmt.", -Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDirectTransferWithDirectedPutawayAndPickForToLocation()
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        Bin: Record Bin;
        TransferHeader: Record "Transfer Header";
        Qty: Integer;
    begin
        // [FEATURE] [Location] [Warehouse] [Direct Transfer]
        // [SCENARIO 449256] Direct transfer to location with directed put-away and pick cannot be posted

        Initialize();

        // [GIVEN] Two locations: "A" without warehouse setup, and "B" with "Directed Put-Away and Pick" enabled
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWMS(ToLocation, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, ToLocation.Code, '', '', '');
        ToLocation."Directed Put-away and Pick" := true;
        ToLocation.Modify();

        // [GIVEN] Item "I" with stock of 100 pcs on location "A"
        Qty := CreateAndPostItemJournalLine(Item."No.", FromLocation.Code, '');

        // [GIVEN] Create a direct transfer order from location "A" to location "B"
        asserterror CreateDirectTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQuantityToCreateModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemReceiptWithMultipleSerialNos()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // [FEATURE] [Item Receipt] [Item Tracking] [Warehouse]
        // [SCENARIO 307763] Posting item receipt with multiple serial nos. generates a separate warehouse entry for each serial no.
        Initialize();

        // [GIVEN] Location with a bin.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Serial no.-tracked item. "SN Warehouse Tracking" is enabled.
        CreateSNTrackedItem(Item);

        // [GIVEN] Create item receipt, assign 5 serial nos. to the line.
        CreateInvtDocumentWithItemTracking(
          InvtDocumentHeader, InvtDocumentLine, InvtDocumentHeader."Document Type"::Receipt,
          Item."No.", Location.Code, Bin.Code, LibraryRandom.RandIntInRange(5, 10), ItemTrackingAction::AssignSerialNo);

        // [WHEN] Post the item receipt.
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [THEN] 5 warehouse entries are created.
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::"Positive Adjmt.");
        Assert.RecordCount(WarehouseEntry, InvtDocumentLine.Quantity);

        // [THEN] Total quantity posted in the warehouse ledger = 5.
        WarehouseEntry.CalcSums(Quantity);
        Assert.AreEqual(InvtDocumentLine.Quantity, WarehouseEntry.Quantity, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQuantityToCreateModalPageHandler,ItemTrackingSummaryModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemShipmentWithMultipleSerialNos()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        ReceiptInvtDocumentHeader: Record "Invt. Document Header";
        ReceiptInvtDocumentLine: Record "Invt. Document Line";
        ShipmentInvtDocumentHeader: Record "Invt. Document Header";
        ShipmentInvtDocumentLine: Record "Invt. Document Line";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // [FEATURE] [Item Shipment] [Item Tracking] [Warehouse]
        // [SCENARIO 307763] Posting item shipment with multiple serial nos. generates a separate warehouse entry for each serial no.
        Initialize();

        // [GIVEN] Location with a bin.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Serial no.-tracked item. "SN Warehouse Tracking" is enabled.
        CreateSNTrackedItem(Item);

        // [GIVEN] Create item receipt, assign 5 serial nos. to the line and post it.
        CreateInvtDocumentWithItemTracking(
          ReceiptInvtDocumentHeader, ReceiptInvtDocumentLine, ReceiptInvtDocumentHeader."Document Type"::Receipt,
          Item."No.", Location.Code, Bin.Code, LibraryRandom.RandIntInRange(5, 10), ItemTrackingAction::AssignSerialNo);
        LibraryInventory.PostInvtDocument(ReceiptInvtDocumentHeader);

        // [GIVEN] Create item shipment, select received 5 serial nos.
        CreateInvtDocumentWithItemTracking(
          ShipmentInvtDocumentHeader, ShipmentInvtDocumentLine, ShipmentInvtDocumentHeader."Document Type"::Shipment,
          Item."No.", Location.Code, Bin.Code, ReceiptInvtDocumentLine.Quantity, ItemTrackingAction::SelectEntries);

        // [WHEN] Post the item shipment.
        LibraryInventory.PostInvtDocument(ShipmentInvtDocumentHeader);

        // [THEN] 5 warehouse entries are created.
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::"Negative Adjmt.");
        Assert.RecordCount(WarehouseEntry, ShipmentInvtDocumentLine.Quantity);

        // [THEN] Total quantity posted in the warehouse ledger by warehouse shipment = -5.
        WarehouseEntry.CalcSums(Quantity);
        Assert.AreEqual(-ShipmentInvtDocumentLine.Quantity, WarehouseEntry.Quantity, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReceiptWithNegativeQuantity()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
    begin
        // Setup
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        CreateItemWithDimension(Item, DimensionValue);

        // Execute
        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Receipt, Location.Code, SalespersonPurchaser.Code);

        // Verify
        asserterror InvtDocumentLine.Validate(Quantity, -1);
        Assert.ExpectedError('cannot be negative');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemShipmentWithNegativeQuantity()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
    begin
        // Setup
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        CreateItemWithDimension(Item, DimensionValue);

        // Execute
        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Shipment, Location.Code, SalespersonPurchaser.Code);

        // Verify
        asserterror InvtDocumentLine.Validate(Quantity, -1);
        Assert.ExpectedError('cannot be negative');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQuantityToCreateModalPageHandler')]
    [Scope('OnPrem')]
    procedure CopyInvReceiptFromPostedInvReceiptWithItemTrackedLines()
    var
        Location: Record Location;
        Item: Record Item;
        SNTrackedItem: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        InvtRcptHeader: Record "Invt. Receipt Header";
        CopyInvtDocMgt: Codeunit "Copy Invt. Document Mgt.";
    begin
        // [FEATURE] [Item Receipt] [Item Tracking] [Copy Document]
        // [SCENARIO 307763] Posting item receipt with multiple serial nos. generates a separate warehouse entry for each serial no.
        Initialize();

        // [GIVEN] Location
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Serial No. tracked item and item without tracking.
        CreateSNTrackedItem(SNTrackedItem);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create item receipt, with 2 lines, assign 5 serial nos. to the line with tracking.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, SNTrackedItem."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));
        LibraryVariableStorage.Enqueue(ItemTrackingAction::AssignSerialNo);
        InvtDocumentLine.OpenItemTrackingLines();

        // [GIVEN] Post the item receipt.
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [GIVEN] Find posted Inventory Receipt.
        InvtRcptHeader.SetRange("Receipt No.", InvtDocumentHeader."No.");
        InvtRcptHeader.FindLast();

        // [GIVEN] Init new Inventory Receipt.
        InvtDocumentHeader.Init();
        InvtDocumentHeader."Document Type" := InvtDocumentHeader."Document Type"::Receipt;
        InvtDocumentHeader.InitRecord();
        InvtDocumentHeader.Insert();

        // [WHEN] [THAN] Coping from posted Inventory Receipt with NewFillAppliesFields = true will be done without error
        CopyInvtDocMgt.SetProperties(true, false, false, false, true);
        CopyInvtDocMgt.CopyItemDoc(Enum::"Invt. Doc. Document Type From"::"Posted Receipt", InvtRcptHeader."No.", InvtDocumentHeader);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQuantityToCreateModalPageHandler')]
    [Scope('OnPrem')]
    procedure CopyCorrectionInvReceiptFromPostedInvReceiptWithItemTrackedLines()
    var
        Location: Record Location;
        Item: Record Item;
        SNTrackedItem: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        InvtRcptHeader: Record "Invt. Receipt Header";
        CopyInvtDocMgt: Codeunit "Copy Invt. Document Mgt.";
    begin
        // [FEATURE] [Inventory Receipt] [Item Tracking] [Copy Document]
        // [SCENARIO 474794] Posting correction inventory receipt with multiple serial nos. for posted inventory receipt

        Initialize();

        // [GIVEN] Location
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Serial No. tracked item and item without tracking.
        CreateSNTrackedItem(SNTrackedItem);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create item receipt, with 2 lines, assign 5 serial nos. to the line with tracking.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, SNTrackedItem."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));
        LibraryVariableStorage.Enqueue(ItemTrackingAction::AssignSerialNo);
        InvtDocumentLine.OpenItemTrackingLines();

        // [GIVEN] Post the item receipt.
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [GIVEN] Find posted Inventory Receipt.
        InvtRcptHeader.SetRange("Receipt No.", InvtDocumentHeader."No.");
        InvtRcptHeader.FindLast();

        // [GIVEN] Init new Inventory Receipt.
        InvtDocumentHeader.Init();
        InvtDocumentHeader."Document Type" := InvtDocumentHeader."Document Type"::Receipt;
        InvtDocumentHeader.InitRecord();
        InvtDocumentHeader.Insert(true);

        // [GIVEN] Update inventory receipt with location and correction.
        InvtDocumentHeader.Validate("Location Code", Location.Code);
        InvtDocumentHeader.Validate("Correction", true);
        InvtDocumentHeader.Modify();

        // [WHEN]  Coping lines from posted Inventory Receipt with item tracking data and apllies values
        CopyInvtDocMgt.SetProperties(false, true, false, false, true);
        CopyInvtDocMgt.SetCopyItemTracking(true);
        CopyInvtDocMgt.CopyItemDoc(Enum::"Invt. Doc. Document Type From"::"Posted Receipt", InvtRcptHeader."No.", InvtDocumentHeader);

        // [THEN] Posting should be done without error
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQuantityToCreateModalPageHandler')]
    [Scope('OnPrem')]
    procedure CopyInvShipmentFromPostedInvReceiptWithItemTrackedLines()
    var
        Location: Record Location;
        Item: Record Item;
        SNTrackedItem: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        InvtRcptHeader: Record "Invt. Receipt Header";
        CopyInvtDocMgt: Codeunit "Copy Invt. Document Mgt.";
    begin
        // [FEATURE] [Inventory Receipt] [Inventory Shipment] [Item Tracking] [Copy Document]
        // [SCENARIO 474794] Posting inventory receipt with multiple serial nos.

        Initialize();

        // [GIVEN] Location
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Serial No. tracked item and item without tracking.
        CreateSNTrackedItem(SNTrackedItem);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create item receipt, with 2 lines, assign 5 serial nos. to the line with tracking.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, SNTrackedItem."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));
        LibraryVariableStorage.Enqueue(ItemTrackingAction::AssignSerialNo);
        InvtDocumentLine.OpenItemTrackingLines();

        // [GIVEN] Post the item receipt.
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [GIVEN] Find posted Inventory Receipt.
        InvtRcptHeader.SetRange("Receipt No.", InvtDocumentHeader."No.");
        InvtRcptHeader.FindLast();

        // [GIVEN] Init new Inventory Receipt.
        InvtDocumentHeader.Init();
        InvtDocumentHeader."Document Type" := InvtDocumentHeader."Document Type"::Shipment;
        InvtDocumentHeader.InitRecord();
        InvtDocumentHeader.Insert(true);

        // [WHEN] Coping lines from posted Inventory Receipt with item tracking data and apllies values
        CopyInvtDocMgt.SetProperties(true, false, false, false, true);
        CopyInvtDocMgt.SetCopyItemTracking(true);
        CopyInvtDocMgt.CopyItemDoc(Enum::"Invt. Doc. Document Type From"::"Posted Receipt", InvtRcptHeader."No.", InvtDocumentHeader);

        // [THEN] Posting should be done without error
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NotCopiedAppliesValuesMessageHandler(Msg: Text[1024])
    var
        InvDocCopyIssue: Label 'Inventory Document copying issue.';
        LinesNotAppliedMsg: Label 'There is 1 document line(s) with Item Tracking which requires manual specify of apply to/from numbers within Item Tracking Lines';
    begin
        Assert.IsTrue(StrPos(Msg, LinesNotAppliedMsg) > 0, InvDocCopyIssue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseQtyIsRoundedTo0OnInvtDocumentLine()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Receipt, Location.Code, SalespersonPurchaser.Code, 0);
        InvtDocumentLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        InvtDocumentLine.Modify();

        asserterror InvtDocumentLine.Validate(Quantity, 0.01);
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenQtyIsRoundedTo0OnInvtDocumentLine()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Receipt, Location.Code, SalespersonPurchaser.Code, 0);
        InvtDocumentLine.Validate("Unit of Measure Code", BaseUOM.Code);
        InvtDocumentLine.Modify();
        asserterror InvtDocumentLine.Validate(Quantity, 0.01);
        Assert.ExpectedError(RoundingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionSpecifiedOnInvtDocumentLine()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateInvtDocumentWithLine(
            InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Receipt, Location.Code, SalespersonPurchaser.Code, 0);
        InvtDocumentLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        InvtDocumentLine.Validate(Quantity, 5.67);
        Assert.AreEqual(17.0, InvtDocumentLine."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionUnspecifiedOnInvtDocumentLine()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
    begin
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateInvtDocumentWithLine(
            InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Receipt, Location.Code, SalespersonPurchaser.Code, 0);
        InvtDocumentLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        InvtDocumentLine.Validate(Quantity, 5.6666666);
        Assert.AreEqual(17.00001, InvtDocumentLine."Quantity (Base)", 'Base qty. is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionOnInvtDocumentLine()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        NonBaseQtyPerUOM := 6;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateInvtDocumentWithLine(
            InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Receipt, Location.Code, SalespersonPurchaser.Code, 0);
        InvtDocumentLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        InvtDocumentLine.Validate(Quantity, 5 / 6);
        Assert.AreEqual(5, InvtDocumentLine."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReceiptWithNonInventoryItemError()
    var
        Item: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
    begin
        // [FEATURE 378558] [Item Receipt]
        // Create item document line with non-inventory item produce error
        Initialize();

        // [GIVEN] Create item receipt
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, "Invt. Doc. Document Type"::Receipt, Location.Code);

        LibraryInventory.CreateItem(Item);
        Item.Type := Item.Type::"Non-Inventory";
        Item.Modify();

        // [THEN] Create line
        asserterror LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", 0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShouldTransferRoundingPrecisionToInvtShipmentLine()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        Location: Record Location;
        InvtShipmentHeader: Record "Invt. Shipment Header";
        InvtShipmentLine: Record "Invt. Shipment Line";
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateInvtDocumentWithLine(
            InvtDocumentHeader, InvtDocumentLine, Item,
            InvtDocumentHeader."Document Type"::Shipment, Location.Code, '', 1
        );
        InvtDocumentLine.Validate("Unit of Measure Code", BaseUOM.Code);
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        InvtShipmentHeader.SetRange("Location Code", Location.Code);
        InvtShipmentHeader.FindFirst();
        InvtShipmentLine.SetRange("Document No.", InvtShipmentHeader."No.");
        InvtShipmentLine.FindFirst();

        Assert.AreEqual(
            InvtDocumentLine."Qty. Rounding Precision", InvtShipmentLine."Qty. Rounding Precision",
            'Expected Qty. Rounding Precision to be transferred.'
        );
        Assert.AreEqual(
            InvtDocumentLine."Qty. Rounding Precision (Base)", InvtShipmentLine."Qty. Rounding Precision (Base)",
            'Expected Qty. Rounding Precision (Base) to be transferred.'
        );
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShouldTransferRoundingPrecisionToInvtReceiptLine()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        Location: Record Location;
        InvtReceiptHeader: Record "Invt. Receipt Header";
        InvtReceiptLine: Record "Invt. Receipt Line";
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateInvtDocumentWithLine(
            InvtDocumentHeader, InvtDocumentLine, Item,
            InvtDocumentHeader."Document Type"::Receipt, Location.Code, '', 1
        );
        InvtDocumentLine.Validate("Unit of Measure Code", BaseUOM.Code);
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        InvtReceiptHeader.SetRange("Location Code", Location.Code);
        InvtReceiptHeader.FindFirst();
        InvtReceiptLine.SetRange("Document No.", InvtReceiptHeader."No.");
        InvtReceiptLine.FindFirst();

        Assert.AreEqual(
            InvtDocumentLine."Qty. Rounding Precision", InvtReceiptLine."Qty. Rounding Precision",
            'Expected Qty. Rounding Precision to be transferred.'
        );
        Assert.AreEqual(
            InvtDocumentLine."Qty. Rounding Precision (Base)", InvtReceiptLine."Qty. Rounding Precision (Base)",
            'Expected Qty. Rounding Precision (Base) to be transferred.'
        );
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationWithRequireReceiptAllowed()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        Item: Record Item;
        LocationReceipt: Record Location;
        LocationPutAwayAndPick: Record Location;
    begin
        // [SCENARIO] It is possible to use a location with require receipt for inventory receipt document but
        // not for directed put-away and pick.
        Initialize();

        // [GIVEN] An item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A location with require receipt and one with put-away and pick.
        LibraryWarehouse.CreateLocationWMS(LocationReceipt, false, false, false, true, false);
        LibraryWarehouse.CreateFullWMSLocation(LocationPutAwayAndPick, 1);

        // [WHEN] Creating an inventory receipt document for location with require receipt.
        LibraryInventory.CreateInvtDocument(
            InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, LocationReceipt.Code);

        // [THEN] No error is thrown.

        // [WHEN] Setting location with require put-away and pick.
        asserterror InvtDocumentHeader.Validate("Location Code", LocationPutAwayAndPick.Code);

        // [THEN] An error is thrown.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationWithRequireShipmentAllowed()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        Item: Record Item;
        LocationShipment: Record Location;
        LocationPutAwayAndPick: Record Location;
    begin
        // [SCENARIO] It is possible to use a location with require receipt for inventory shipment document but
        // not for directed put-away and pick.
        Initialize();

        // [GIVEN] An item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A location with require shipment and one with put-away and pick.
        LibraryWarehouse.CreateLocationWMS(LocationShipment, false, false, false, false, true);
        LibraryWarehouse.CreateFullWMSLocation(LocationPutAwayAndPick, 1);

        // [WHEN] Creating an inventory shipment document for location with require shipment.
        LibraryInventory.CreateInvtDocument(
            InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment, LocationShipment.Code);

        // [THEN] No error is thrown.

        // [WHEN] Setting location with require put-away and pick.
        asserterror InvtDocumentHeader.Validate("Location Code", LocationPutAwayAndPick.Code);

        // [THEN] An error is thrown.
    end;

    [Test]
    procedure AutoReserveSalesLineFromInventoryReceipt()
    var
        Item: Record Item;
        Location: Record Location;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Reservation]
        // [SCENARIO 426870] Auto reserve sales line from inventory receipt.
        Initialize();
        AllowInvtDocReservationInInventorySetup();

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItem(Item);

        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(
          InvtDocumentHeader, InvtDocumentLine, LibraryInventory.CreateItemNo(), 0, LibraryRandom.RandIntInRange(20, 40));
        LibraryInventory.CreateInvtDocumentLine(
          InvtDocumentHeader, InvtDocumentLine, Item."No.", 0, LibraryRandom.RandIntInRange(20, 40));

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          Item."No.", LibraryRandom.RandInt(10), Location.Code, WorkDate());

        LibrarySales.AutoReserveSalesLine(SalesLine);

        ReservationEntry.SetSourceFilter(
          Database::"Invt. Document Line", InvtDocumentLine."Document Type".AsInteger(), InvtDocumentLine."Document No.",
          InvtDocumentLine."Line No.", false);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Item No.", Item."No.");
        ReservationEntry.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive);
        ReservationEntry.TestField("Item No.", Item."No.");
        ReservationEntry.TestField("Source Type", Database::"Sales Line");
        ReservationEntry.TestField("Source ID", SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ReservationModalPageHandler,AvailableInvtDocLinesModalPageHandler')]
    procedure AutoReservePurchaseLineForInventoryShipment()
    var
        Item: Record Item;
        Location: Record Location;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Reservation]
        // [SCENARIO 426870] Auto reserve purchase line for inventory shipment.
        Initialize();
        AllowInvtDocReservationInInventorySetup();

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItem(Item);

        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(
          InvtDocumentHeader, InvtDocumentLine, LibraryInventory.CreateItemNo(), 0, LibraryRandom.RandIntInRange(20, 40));
        LibraryInventory.CreateInvtDocumentLine(
          InvtDocumentHeader, InvtDocumentLine, Item."No.", 0, LibraryRandom.RandInt(10));

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '',
          Item."No.", LibraryRandom.RandIntInRange(20, 40), Location.Code, WorkDate());

        PurchaseLine.ShowReservation();

        ReservationEntry.SetSourceFilter(
          Database::"Invt. Document Line", InvtDocumentLine."Document Type".AsInteger(), InvtDocumentLine."Document No.",
          InvtDocumentLine."Line No.", false);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Item No.", Item."No.");
        ReservationEntry.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive);
        ReservationEntry.TestField("Item No.", Item."No.");
        ReservationEntry.TestField("Source Type", Database::"Purchase Line");
        ReservationEntry.TestField("Source ID", PurchaseLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostInventoryReceiptWithUOM()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO 467540] Unit Cost is not updated as per Unit of Measure in Inventory Receipt line
        Initialize();

        // [GIVEN] Create Location with Inventory Posting Setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Item and one Item Unit of Measure Code
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 2);

        // [GIVEN] Create Inventory Receipt with Location Code and update Posting No. on Inventory Receipt Document.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        InvtDocumentHeader."Posting No." := LibraryUtility.GenerateGUID();
        InvtDocumentHeader.Modify();

        // [GIVEN] Create Inventory Receipt Line and update Unit of Measure Code other than Base Unit of Measure Code
        LibraryInventory.CreateInvtDocumentLine(
        InvtDocumentHeader, InvtDocumentLine, Item."No.", Item."Unit Cost", LibraryRandom.RandDec(10, 2));
        InvtDocumentLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        InvtDocumentLine.Modify();

        // [WHEN] Post the Inventory Receipt
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [VERIFY] Verify the Item Ledger Entry Created by last Inventory Receipt.
        ItemLedgerEntry.FindLast();
        Assert.AreEqual(Item."No.", ItemLedgerEntry."Item No.", ItemNoErr);
        Assert.AreEqual(ItemUnitOfMeasure.Code, ItemLedgerEntry."Unit of Measure Code", UnitOfMeasureCodeErr);
        Assert.AreEqual(Item."Unit Cost" * 2, ItemLedgerEntry."Cost Amount (Actual)", UnitCostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure ValidateDimensionUpdatedInInventoryShipmentDocumentLine()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        InvtShipment: TestPage "Invt. Shipment";
    begin
        // [SCENARIO 468226] Dimension is not update in the inventory shipment document
        Initialize();
        GeneralLedgerSetup.Get();

        // [GIVEN] Setup item document, create an item, and dimension
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        LibraryInventory.CreateItem(Item);
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 1 Code");

        // [GIVEN] Create Inventory Shipment Line for type item, with Location, and Salesperson/Purchaser
        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Shipment, Location.Code, SalespersonPurchaser.Code);

        // [WHEN] Open Inventory Shipment Page, and update Shortcut Dimension 1 Code field value
        InvtShipment.OpenEdit();
        InvtShipment.Filter.SetFilter("No.", InvtDocumentHeader."No.");
        InvtShipment."Shortcut Dimension 1 Code".SetValue(DimensionValue.Code);

        // [THEN] Find the first Inventory Shipment Line
        InvtShipment.ShipmentLines.First();

        // [VERIFY] Verify: The dimension on the Inventory Shipment line should be the same as its Inventory Shipment document dimension
        Assert.AreEqual(
            InvtShipment."Shortcut Dimension 1 Code".Value,
            InvtShipment.ShipmentLines."Shortcut Dimension 1 Code".Value,
            StrSubstNo(DimensionErr, InvtShipment."Shortcut Dimension 1 Code".Value));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyUnitCostWithDiffBaseUOM()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // [SCENARIO 469309] Unit cost is not populated when item no. is entered or Uom is changed in Inventory receipt lines
        Initialize();

        // [GIVEN] Create Location with Inventory Posting Setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Item and one Item Unit of Measure Code
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Add Unit cost in the Item
        Item."Unit Cost" := LibraryRandom.RandDec(10, 2);
        Item.Modify();

        // [GIVEN] Create New Unit of Measure Code.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Create new Item Unit of Measure Code.
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 2);

        // [GIVEN] Create Inventory Receipt with Location Code and update Posting No. on Inventory Receipt Document.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        InvtDocumentHeader."Posting No." := LibraryUtility.GenerateGUID();
        InvtDocumentHeader.Modify();

        // [GIVEN] Create Inventory Receipt Line and update Unit of Measure Code other than Base Unit of Measure Code
        LibraryInventory.CreateInvtDocumentLine(
        InvtDocumentHeader, InvtDocumentLine, Item."No.", Item."Unit Cost", LibraryRandom.RandDec(10, 2));
        InvtDocumentLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        InvtDocumentLine.Modify();

        // [VERIFY] Verify Unit Cost will update when Base Unit Of Measure Code is Change to new Unit of Measure Code.
        Assert.AreEqual(Item."Unit Cost" * ItemUnitOfMeasure."Qty. per Unit of Measure", InvtDocumentLine."Unit Cost", UnitCostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyUnitCostWhenUsingItemSKUAndChangingUOMInInventoryReceipt()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: array[2] of Record "Item Unit of Measure";
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        // [SCENARIO 473495] Unit Cost is not updated when using Item SKU and changing UoM in Inventory Receipt
        Initialize();

        // [GIVEN] Create Location with Inventory Posting Setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Item and Item Unit of Measure Code
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Add Unit cost in the Item
        Item."Unit Cost" := LibraryRandom.RandDec(10, 2);
        Item.Modify(true);

        // [GIVEN] Create Item Unit of Measure Code 1.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure[1], Item."No.", UnitOfMeasure.Code, 1);

        // [GIVEN] Create Item Unit of Measure Code 2.
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure[2], Item."No.", 2);

        // [GIVEN] Create Stock Keeping Unit for Item
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, Item."No.", '');

        // [GIVEN] Create Inventory Receipt with Location Code and update Posting No. on Inventory Receipt Document.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        InvtDocumentHeader."Posting No." := LibraryUtility.GenerateGUID();
        InvtDocumentHeader.Modify(true);

        // [GIVEN] Create Inventory Receipt Line and update Unit of Measure Code other than Base Unit of Measure Code
        LibraryInventory.CreateInvtDocumentLine(
        InvtDocumentHeader, InvtDocumentLine, Item."No.", Item."Unit Cost", LibraryRandom.RandDec(10, 2));
        InvtDocumentLine.Validate("Unit of Measure Code", ItemUnitOfMeasure[1].Code);
        InvtDocumentLine.Modify(true);

        // [VERIFY] Verify: Unit Cost will when Unit Of Measure Code 1 applied.
        Assert.AreEqual(Item."Unit Cost" * ItemUnitOfMeasure[1]."Qty. per Unit of Measure", InvtDocumentLine."Unit Cost", UnitCostErr);

        // [THEN] Update Unit of Measure Code on Inventory Receipt Line as 2.
        InvtDocumentLine.Validate("Unit of Measure Code", ItemUnitOfMeasure[2].Code);
        InvtDocumentLine.Modify(true);

        // [VERIFY] Verify: Unit Cost will update when Unit Of Measure Code 2 applied.
        Assert.AreEqual(Item."Unit Cost" * ItemUnitOfMeasure[2]."Qty. per Unit of Measure", InvtDocumentLine."Unit Cost", UnitCostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyShortcutDimensionOnPostedInventoryReceiptSubForm()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        InvtReceiptHeader: Record "Invt. Receipt Header";
        InvtReceiptLine: Record "Invt. Receipt Line";
        InvtReceiptSubform: TestPage "Invt. Receipt Subform";
        PostedInvtReceiptSubform: TestPage "Posted Invt. Receipt Subform";
        DimValue: Code[20];
    begin
        // [SCENARIO 482799] Shortcut dimension value does not appear on the column of Posted Inventory Shipment Line and Posted Inventory Receipt Line
        Initialize();

        // [GIVEN] Create Dimension with Values "V1"
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimValue := DimensionValue.Code;

        // [GIVEN] Set Dimension V1 as Shortcut Dimension 3 in General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Shortcut Dimension 3 Code", Dimension.Code);
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Create Setup for Item Document
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        LibraryInventory.CreateItem(Item);

        // [THEN] Create Inventory Receipt Document
        CreateInvtDocumentWithLine(
            InvtDocumentHeader,
            InvtDocumentLine,
            Item,
            InvtDocumentHeader."Document Type"::Receipt,
            Location.Code,
            SalespersonPurchaser.Code);

        InvtDocumentHeader."Posting No." := LibraryUtility.GenerateGUID();
        InvtDocumentHeader.Modify();

        // [GIVEN] Set ShortcutDimCode3 = "V1" in Invt. Shipment Subform Order Subform
        InvtReceiptSubform.OpenEdit();
        InvtReceiptSubform.GoToRecord(InvtDocumentLine);
        InvtReceiptSubform."ShortcutDimCode[3]".SetValue(DimValue);
        InvtReceiptSubform.Close();


        // [WHEN] Posted Inventory Shipment Document
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [THEN] Get Posted Invt. Shipment Document and Open Posted Invt. Shipment Subform
        InvtReceiptHeader.Get(InvtDocumentHeader."Posting No.");
        InvtReceiptLine.SetRange("Document No.", InvtReceiptHeader."No.");
        InvtReceiptLine.FindFirst();
        PostedInvtReceiptSubform.OpenView();
        PostedInvtReceiptSubform.GoToRecord(InvtReceiptLine);

        // [VERIFY] Verify: Shortcut Dimension 3 on Posted Invt. Shipment Subform
        PostedInvtReceiptSubform."ShortcutDimCode[3]".AssertEquals(DimValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyShortcutDimensionOnPostedInventoryShipmentSubForm()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        InvtShipmentHeader: Record "Invt. Shipment Header";
        InvtShipmentLine: Record "Invt. Shipment Line";
        InvtShipmentSubform: TestPage "Invt. Shipment Subform";
        PostedInvtShipmentSubform: TestPage "Posted Invt. Shipment Subform";
        DimValue: Code[20];
    begin
        // [SCENARIO 482799] Shortcut dimension value does not appear on the column of Posted Inventory Shipment Line and Posted Inventory Receipt Line
        Initialize();

        // [GIVEN] Create Dimension with Values "V1"
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimValue := DimensionValue.Code;

        // [GIVEN] Set Dimension V1 as Shortcut Dimension 3 in General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Shortcut Dimension 3 Code", Dimension.Code);
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Create Setup for Item Document
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        LibraryInventory.CreateItem(Item);

        // [THEN] Create Inventory Shipment Document
        CreateInvtDocumentWithLine(
            InvtDocumentHeader,
            InvtDocumentLine,
            Item,
            InvtDocumentHeader."Document Type"::Shipment,
            Location.Code,
            SalespersonPurchaser.Code);

        InvtDocumentHeader."Posting No." := LibraryUtility.GenerateGUID();
        InvtDocumentHeader.Modify();

        // [GIVEN] Set ShortcutDimCode3 = "V1" in Invt. Shipment Subform Order Subform
        InvtShipmentSubform.OpenEdit();
        InvtShipmentSubform.GoToRecord(InvtDocumentLine);
        InvtShipmentSubform."ShortcutDimCode[3]".SetValue(DimValue);
        InvtShipmentSubform.Close();


        // [WHEN] Posted Inventory Shipment Document
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [THEN] Get Posted Invt. Shipment Document and Open Posted Invt. Shipment Subform
        InvtShipmentHeader.Get(InvtDocumentHeader."Posting No.");
        InvtShipmentLine.SetRange("Document No.", InvtShipmentHeader."No.");
        InvtShipmentLine.FindFirst();
        PostedInvtShipmentSubform.OpenView();
        PostedInvtShipmentSubform.GoToRecord(InvtShipmentLine);

        // [VERIFY] Verify: Shortcut Dimension 3 on Posted Invt. Shipment Subform
        PostedInvtShipmentSubform."ShortcutDimCode[3]".AssertEquals(DimValue);
    end;

    [Test]
    procedure InventoryReceiptDoesNotRequireWarehouseHandling()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // [FEATURE] [Item Receipt] [Warehouse]
        // [SCENARIO 481855] Inventory Receipt does not require warehouse handling.
        Initialize();

        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, true, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", 0, 1);
        InvtDocumentLine.Validate("Bin Code", Bin.Code);
        InvtDocumentLine.Modify(true);
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        Item.CalcFields(Inventory);
        Item.TestField(Inventory, 1);

        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Bin Code", Bin.Code);
        WarehouseEntry.CalcSums("Qty. (Base)");
        WarehouseEntry.TestField("Qty. (Base)", 1);
    end;

    [Test]
    procedure InventoryShipmentDoesNotRequireWarehouseHandling()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        WarehouseEntry: Record "Warehouse Entry";
        QtyInStock: Decimal;
    begin
        // [FEATURE] [Item Shipment] [Warehouse]
        // [SCENARIO 481855] Inventory Shipment does not require warehouse handling.
        Initialize();

        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        QtyInStock := CreateAndPostItemJournalLine(Item."No.", Location.Code, Bin.Code);

        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", 0, 1);
        InvtDocumentLine.Validate("Bin Code", Bin.Code);
        InvtDocumentLine.Modify(true);
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        Item.Get(InvtDocumentLine."Item No.");
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, QtyInStock - 1);

        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Bin Code", Bin.Code);
        WarehouseEntry.CalcSums("Qty. (Base)");
        WarehouseEntry.TestField("Qty. (Base)", QtyInStock - 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure VerifyDimIsNotUpdatedOnLineAfterLocationCodeIsValidatedOnHeaderAndUserDontWantToUpdateDimOnLines()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        InvtShipment: TestPage "Invt. Shipment";
    begin
        // [SCENARIO 486635] Dimension is not updated on the inventory shipment line after location code is validated on the header and user don't want to update dimension on the lines
        Initialize();

        // [GIVEN] Create Dimension Value for Global Dimension 1
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Location with Inventory Posting Setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Default Dimension for Location
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, Database::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Create Inventory Shipment header without Location
        InvtDocumentHeader.Init();
        InvtDocumentHeader."Document Type" := InvtDocumentHeader."Document Type"::Shipment;
        InvtDocumentHeader.Insert(true);

        // [GIVEN] Create Inventory Shipment Line for Item type
        LibraryInventory.CreateInvtDocumentLine(
          InvtDocumentHeader, InvtDocumentLine, Item."No.", Item."Unit Cost", LibraryRandom.RandDec(10, 2));

        // [GIVEN] Open Inventory Shipment Page
        InvtShipment.OpenEdit();
        InvtShipment.Filter.SetFilter("No.", InvtDocumentHeader."No.");

        // [WHEN] Set Location Code on Inventory Shipment Page
        InvtShipment."Location Code".SetValue(Location.Code);

        // [THEN] Find the first Inventory Shipment Line
        InvtShipment.ShipmentLines.First();

        // [VERIFY] Verify: The dimension on the Inventory Shipment line should be empty
        Assert.AreEqual('', InvtShipment.ShipmentLines."Shortcut Dimension 1 Code".Value, StrSubstNo(DimensionErr, ''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySourceCodeOnInvDocLineWhenInventoryDocumentWithDefaultDimensionPriority()
    var
        SourceCode: Record "Source Code";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        Location: Record Location;
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
    begin
        // [SCENARIO 491906] Inventory documents - source code is not added to the document which results in wrong dimension.
        Initialize();

        // [GIVEN] Create Source Code.
        LibraryERM.CreateSourceCode(SourceCode);
        OpenSourceCodeSetupPage(SourceCode);

        // [GIVEN] Create Dimension Value for Global Dimension 1
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValue(DimensionValue2, LibraryERM.GetGlobalDimensionCode(1));

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Default Dimension for Location.
        LibraryDimension.CreateDefaultDimension(
            DefaultDimension, Database::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Create Default Dimension for Item.
        LibraryDimension.CreateDefaultDimension(
            DefaultDimension, Database::Item, Item."No.", DimensionValue2."Dimension Code", DimensionValue2.Code);

        // [GIVEN] Set Dimension Priority.
        SetupDimensionPriority(SourceCode.Code, LibraryRandom.RandIntInRange(1, 5), LibraryRandom.RandIntInRange(6, 10));

        // [GIVEN] Create Inventory Document Header.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);

        // [GIVEN] Create Inventory Document Line.
        LibraryInventory.CreateInvtDocumentLine(
            InvtDocumentHeader, InvtDocumentLine, Item."No.", Item."Unit Cost", LibraryRandom.RandInt(10));

        // [VERIFY] Verify: Source Code exists on the Invt Document Line Table.
        Assert.AreEqual(SourceCode.Code, InvtDocumentLine."Source Code", StrSubstNo(SourceCodeErr, InvtDocumentLine.TableCaption()));

        // [THEN] Post the document.
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [VERIFY] Verify: Source Code was not blank in Invt. Receipt Line Table.
        VerifySourceCodeNotBlankInInvtReceiptLine(InvtDocumentHeader, SourceCode);

        // [VERIFY] Verify: Source Code was not blank in Value Entry Table.
        VerifySourceCodeNotBlankInValueEntry(InvtDocumentHeader, SourceCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionAddedIntoTrackingItem()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        ItemNo: Code[20];
        InvtDocType: Enum "Invt. Doc. Document Type";
        Qty: Decimal;
    begin
        // [SCENARIO 497363]  Post the Inventory Document Receipt with Item has Item tracking Code and modify Dimension after updating the Tracking
        Initialize();

        // [GIVEN] Create Item Tracking Code
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);

        // [GIVEN]  Create Item with Item Tracking Code
        ItemNo := CreateItemWithItemTrackingCode(ItemTrackingCode.Code);

        // [GIVEN] Create Location with Inventory Posting Setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Invt. Document Receipt
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocType::Receipt, Location.Code);

        // [GIVEN] Let the quantity to be assign
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Create Invt. Document Line
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, ItemNo, LibraryRandom.RandDec(100, 2), Qty);

        // [GIVEN] Define Item Tracking on Invt Document Line
        LibraryItemTracking.CreateItemReceiptItemTracking(ReservationEntry, InvtDocumentLine, '', '', '', Qty);

        // [GIVEN] Create Dimension Value of Global Dimension 1
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));

        // [THEN] Assign the Dimension Value to Invt. Document Line
        InvtDocumentLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        InvtDocumentLine.Modify(true);

        // [THEN] Post the Invt. Document Receipt
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [VERIFY] Posted Invt. Document Line has Dimesnion Value same as defined.
        VerifyInvtDocumentLineWithDimensionValue(DimensionValue.Code, InvtDocumentHeader);
    end;

    [Test]
    procedure PlanningAndWarehouseTabsVisibleForTypeInventorySKUCardAfterItemInsert()
    var
        Item: Record Item;
        Location: Record Location;
        StocKkeepingUnitCard: TestPage "Stockkeeping Unit Card";
    begin
        // [SCENARIO 524116] When creating new stockkeeping unit card initially only General, Invoicing and Replenishment are visible, and Planning and Warehouse are not.
        Initialize();

        // [GIVEN] Create an Item and Validate Type as Inventory.
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::Inventory);
        Item.Modify(true);

        // [GIVEN] Create a Location.
        LibraryWarehouse.CreateLocation(Location);

        // [WHEN] Open Stockkeeping Unit Card page.
        StocKkeepingUnitCard.OpenNew();
        StocKkeepingUnitCard."Item No.".SetValue(Item."No.");
        StocKkeepingUnitCard."Location Code".SetValue(Location.Code);

        // [THEN] Verify Planning tab is visible.
        Assert.IsTrue(
            StocKkeepingUnitCard."Reordering Policy".Visible(),
            ReorderingPolicyShouldBeVisibleErr);

        // [THEN] Verify Warehouse tab is visible.
        Assert.IsTrue(
            StocKkeepingUnitCard."Special Equipment Code".Visible(),
            SpecialEquipmentCodeShouldBeVisibleErr);
    end;

    [Test]
    [HandlerFunctions('PickRegisteredMsgHandler')]
    procedure PostDirectTransferWithAssemblyOrder()
    var
        Item: Record Item;
        WhseSetup: Record "Warehouse Setup";
        NonWhseLocation: Record Location;
        WhseLocation: Record Location;
        PutAndPickBin: Record Bin;
        ShipBin: Record Bin;
        RcptBin: Record Bin;
        PutAndPickZone: Record Zone;
        ShipZone: Record Zone;
        RcptZone: Record Zone;
        CheckBinType: Record "Bin Type";
        PutAndPickBinType: Record "Bin Type";
        ShipBinType: Record "Bin Type";
        RcptBinType: Record "Bin Type";
        PutAndPickBinContent: Record "Bin Content";
        ShipBinContent: Record "Bin Content";
        RcptBinContent: Record "Bin Content";
        WarehouseEmployee: Record "Warehouse Employee";
        AssemblyHeader: Record "Assembly Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        AssemblyItem: Record Item;
        InventorySetup: Record "Inventory Setup";
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateLine: Record "Put-away Template Line";
        AssemblyLine: Record "Assembly Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
    begin
        // [Scenario 542854] When a Component of an Assembly Order is reserved against an inbound Transfer with Direct Posting
        Initialize();

        //[GIVEN] UpdateInventory setup with Direct Transfer Posting as Direct Transfer
        InventorySetup.Get();

        InventorySetup."Direct Transfer Posting" := InventorySetup."Direct Transfer Posting"::"Direct Transfer";
        InventorySetup.Modify();
        LibraryWarehouse.NoSeriesSetup(WhseSetup);

        // [GIVEN] Two locations: "A" without warehouse setup, and "B" with "Directed Put-Away and Pick" enabled
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(NonWhseLocation);
        LibraryWarehouse.CreateLocationWMS(WhseLocation, true, true, true, true, true);
        WhseLocation."Directed Put-away and Pick" := true;
        WhseLocation."Use Cross-Docking" := true;
        WhseLocation.Modify();

        // [GIVEN] Create Bin Types
        if FoundBinTypeWithCombination(false, false, true, true, CheckBinType) then
            PutAndPickBinType := CheckBinType
        else
            LibraryWarehouse.CreateBinType(PutAndPickBinType, false, false, true, true);

        if FoundBinTypeWithCombination(false, true, false, false, CheckBinType) then
            ShipBinType := CheckBinType
        else
            LibraryWarehouse.CreateBinType(ShipBinType, false, true, false, false);

        if FoundBinTypeWithCombination(true, false, false, false, CheckBinType) then
            RcptBinType := CheckBinType
        else
            LibraryWarehouse.CreateBinType(RcptBinType, true, false, false, false);

        //[GIVEN] Create Zones
        LibraryWarehouse.CreateZone(PutAndPickZone, PutAndPickBinType.Code, WhseLocation.Code, PutAndPickBinType.Code, '', '', 0, false);
        LibraryWarehouse.CreateZone(ShipZone, ShipBinType.Code, WhseLocation.Code, ShipBinType.Code, '', '', 0, false);
        LibraryWarehouse.CreateZone(RcptZone, RcptBinType.Code, WhseLocation.Code, RcptBinType.Code, '', '', 0, false);

        //[GIVEN] Create Bins
        LibraryWarehouse.CreateBin(
            PutAndPickBin,
            WhseLocation.Code,
            CopyStr(LibraryUtility.GenerateRandomCode(PutAndPickBin.FieldNo(Code), DATABASE::Bin), 1, LibraryUtility.GetFieldLength(DATABASE::Bin, PutAndPickBin.FieldNo(Code))),
            PutAndPickZone.Code,
            PutAndPickBinType.Code);

        LibraryWarehouse.CreateBin(
            ShipBin,
            WhseLocation.Code,
            CopyStr(LibraryUtility.GenerateRandomCode(ShipBin.FieldNo(Code), DATABASE::Bin), 1, LibraryUtility.GetFieldLength(DATABASE::Bin, ShipBin.FieldNo(Code))),
            ShipZone.Code,
            ShipBinType.Code);

        LibraryWarehouse.CreateBin(
            RcptBin,
            WhseLocation.Code,
            CopyStr(LibraryUtility.GenerateRandomCode(RcptBin.FieldNo(Code), DATABASE::Bin), 1, LibraryUtility.GetFieldLength(DATABASE::Bin, RcptBin.FieldNo(Code))),
            RcptZone.Code,
            RcptBinType.Code);

        //[GIVEN] Update Receipt and Ship Bin on Whse Location
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, true, false, true, true, true, false);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, true, false, true, true, false, false);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, false, true, true, true, false, false);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, false, true, true, false, false, false);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, false, true, false, false, false, true);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, false, true, false, false, false, false);

        WhseLocation.Validate("Receipt Bin Code", RcptBin.Code);
        WhseLocation.Validate("Shipment Bin Code", ShipBin.Code);
        WhseLocation.Validate("Put-away Bin Policy", WhseLocation."Put-away Bin Policy"::"Put-away Template");
        WhseLocation."Put-away Template Code" := PutAwayTemplateHeader.Code;
        WhseLocation."Always Create Put-away Line" := true;
        WhseLocation."Always Create Pick Line" := true;
        WhseLocation.Modify();

        //[GIVEN] Create Warehouse Employee with Default Location
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, WhseLocation.Code, true);

        //[GIVEN] Create and register Put Away from Warehouse Receipt Using Purchase Order
        LibraryInventory.CreateItem(Item);
        Item."Put-away Template Code" := PutAwayTemplateHeader.Code;
        Item."Put-away Unit of Measure Code" := Item."Put-away Unit of Measure Code";
        item.Modify();

        //[GIVEN] Create Bin Content
        LibraryWarehouse.CreateBinContent(PutAndPickBinContent, PutAndPickBin."Location Code", PutAndPickZone.code, PutAndPickBin.Code, Item."No.", '', Item."Base Unit of Measure");
        PutAndPickBinContent."Cross-Dock Bin" := true;
        PutAndPickBinContent.Modify();
        LibraryWarehouse.CreateBinContent(ShipBinContent, ShipBin."Location Code", ShipZone.Code, ShipBin.Code, Item."No.", '', Item."Base Unit of Measure");
        ShipBinContent."Cross-Dock Bin" := true;
        ShipBinContent.Modify();
        LibraryWarehouse.CreateBinContent(RcptBinContent, RcptBin."Location Code", RcptZone.Code, RcptBin.code, Item."No.", '', Item."Base Unit of Measure");
        RcptBinContent."Cross-Dock Bin" := true;
        RcptBinContent.Modify();
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", 10, WhseLocation.Code, false);

        //[GIVEN] Create Assembly Item with BOM Component
        CreateAssemblyItemWithBOM(AssemblyItem, Item);
        //[GIVEM] Create Assembly Order
        CreateAssemblyOrder(AssemblyHeader, AssemblyLine, AssemblyItem, Item, WorkDate(), 1, NonWhseLocation.Code);

        // [GIVEN] Create a direct transfer order from location "B" to location "A"
        CreateDirectTransferHeader(TransferHeader, WhseLocation.Code, NonWhseLocation.code);
        TransferHeader.Validate("Posting Date", WorkDate());
        TransferHeader.Modify(true);

        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, item."No.", 10);
        TransferHeader.PerformManualRelease();
        AssemblyLine.AutoReserve();

        //[GIVEN] Post Direct Transfer Order Shipment
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        //[GIVEN] Create and register pick
        FindWhseShptLine(
            WarehouseShipmentLine, TransferLine."Document No.");
        CreateRegisterWhsePick(WhseActivityHeader, WarehouseShipmentLine, TransferLine.Quantity);
        PostWhseShipmentFromTO(TransferHeader."No.");
        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
        //[WHEN] Post created assembly order
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        //[THEN] Assembly Order should be posted successfully.

    end;

    [Test]
    procedure PostDirectTransferOrderWithReservation()
    var
        DirectTransHeader: Record "Direct Trans. Header";
        Item: Record Item;
        LocationA: Record Location;
        LocationB: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        InventorySetup: Record "Inventory Setup";
        TransferOrderNo: Code[20];
    begin
        // [Scenario 565331] Verify Direct Transfer with reservation posted successfully.
        Initialize();

        // [GIVEN] Update Inventory setup with Direct Transfer Posting as Direct Transfer and Prevent Negative Inventory as TRUE
        InventorySetup.Get();
        InventorySetup."Prevent Negative Inventory" := true;
        InventorySetup."Direct Transfer Posting" := InventorySetup."Direct Transfer Posting"::"Direct Transfer";
        InventorySetup.Modify();

        // [GIVEN] Create Two locations: "A" and "B" without Warehouse Setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationA);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationB);

        // [GIVEN] Create an Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Post Item Journal Line
        CreateAndPostItemJournalLine(Item."No.", LocationA.Code, '');

        // [GIVEN] Create a Direct Transfer Order from Location "A" to location "B" and Reserve From Inventory
        CreateDirectTransferHeader(TransferHeader, LocationA.code, LocationB.Code);
        TransferHeader.Validate("Posting Date", WorkDate());
        TransferHeader.Modify(true);

        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);
        TransferLine.ReserveFromInventory(TransferLine);
        TransferHeader.PerformManualRelease();
        TransferOrderNo := TransferHeader."No.";

        // [WHEN] Post the Direct Transfer Order
        LibraryInventory.PostDirectTransferOrder(TransferHeader);

        // [THEN] Verify Direct TransferOrder Posted Successfully.
        DirectTransHeader.SetRange("Transfer Order No.", TransferOrderNo);
        Assert.IsTrue(DirectTransHeader.FindFirst(), TransferOrderErr);
    end;

    [Test]
    procedure PostDirectTransferOrderWithTwoReservation()
    var
        DirectTransHeader: Record "Direct Trans. Header";
        InventorySetup: Record "Inventory Setup";
        ItemA: Record Item;
        ItemB: Record Item;
        LocationA: Record Location;
        LocationB: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrderNo: Code[20];
    begin
        // [Scenario 565331] Verify Direct Transfer with two reservation posted successfully.
        Initialize();

        // [GIVEN] Update Inventory Setup with Direct Transfer Posting as Direct Transfer and Prevent Negative Inventory as TRUE
        InventorySetup.Get();
        InventorySetup."Prevent Negative Inventory" := true;
        InventorySetup."Direct Transfer Posting" := InventorySetup."Direct Transfer Posting"::"Direct Transfer";
        InventorySetup.Modify();

        // [GIVEN] Create Two locations: "A" and "B" without Warehouse Setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationA);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationB);

        // [GIVEN] Create two Item A and Item B.
        LibraryInventory.CreateItem(ItemA);
        LibraryInventory.CreateItem(ItemB);

        // [GIVEN] Create and Post Item Journal Line for Item A and Item B.
        CreateAndPostItemJournalLine(ItemA."No.", LocationA.Code, '');
        CreateAndPostItemJournalLine(ItemB."No.", LocationA.Code, '');

        // [GIVEN] Create a Direct Transfer Order from Location "A" to location "B" for Item A and Reserve From Inventory
        CreateDirectTransferHeader(TransferHeader, LocationA.code, LocationB.Code);
        TransferHeader.Validate("Posting Date", WorkDate());
        TransferHeader.Modify(true);

        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemA."No.", 5);
        TransferLine.ReserveFromInventory(TransferLine);
        TransferHeader.PerformManualRelease();

        // [GIVEN] Post the Direct Transfer Order
        LibraryInventory.PostDirectTransferOrder(TransferHeader);

        // [GIVEN] Create a Direct Transfer Order from Location "A" to location "B" for Item B and Reserve From Inventory
        CreateDirectTransferHeader(TransferHeader, LocationA.code, LocationB.Code);
        TransferHeader.Validate("Posting Date", WorkDate());
        TransferHeader.Modify(true);

        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemB."No.", 5);
        TransferLine.ReserveFromInventory(TransferLine);
        TransferHeader.PerformManualRelease();
        TransferOrderNo := TransferHeader."No.";

        // [WHEN] Post the Direct Transfer Order
        LibraryInventory.PostDirectTransferOrder(TransferHeader);

        // [THEN] Verify Direct TransferOrder Posted Successfully.
        DirectTransHeader.SetRange("Transfer Order No.", TransferOrderNo);
        Assert.IsTrue(DirectTransHeader.FindFirst(), TransferOrderErr);
    end;

    [Test]
    procedure ReservationShouldNotPossibleOnTransferOrderIfItemReserveSetAsNever()
    var
        Item: Record Item;
        LocationA: Record Location;
        LocationB: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        // [SCENARIO 578318] Reservation of an Item possible with in a Transfer order if the item is set to reserve=never
        Initialize();

        // [GIVEN] Create Two locations: "A" and "B" without Warehouse Setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationA);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationB);

        // [GIVEN] Create an Item with Reserve = Never
        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Never);
        Item.Modify();

        // [GIVEN] Create and Post Item Journal Line
        CreateAndPostItemJournalLine(Item."No.", LocationA.Code, '');

        // [GIVEN] Create a Direct Transfer Order from Location "A" to location "B" and Reserve From Inventory
        CreateDirectTransferHeader(TransferHeader, LocationA.code, LocationB.Code);
        TransferHeader.Validate("Posting Date", WorkDate());
        TransferHeader.Modify(true);

        // [WHEN] Create transfer line with Item with Reserve set as Never and Show Reservation
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);
        asserterror TransferLine.ShowReservation();

        // [THEN] Verify Reserve must not be Never error
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(ReserveMustNotBeNeverErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    procedure PostInvtReceiptWithNonBaseUOMAndMultipleTrackingEntries()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        ItemTrackingCode: Record "Item Tracking Code";
        InvtReceiptHeader: Record "Invt. Receipt Header";
        Location: Record Location;
        UnitOfMeasure: Record "Unit of Measure";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 591585] Post Inventory Receipt When Line Contains Item with Non-Base UoM and Multiple Tracking Entries.
        Initialize();

        // [GIVEN] Create Item and Item Unit of Measure with QtyperUoM as 0.01.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", UnitOfMeasure.code, 0.01);

        // [GIVEN] Create Item Tracking Code and assign it to Item.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        // [GIVEN] Create Inventory Receipt Document.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);

        // [GIVEN] Add Inventory Receipt line with non-base UOM, Quantity as 100.
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", LibraryRandom.RandDec(100, 2), 100);
        InvtDocumentLine.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        InvtDocumentLine.Modify(true);

        // [GIVEN] Assign two tracking lines with different quantities as 0.7 and 0.3.
        LibraryVariableStorage.Enqueue(0.7);
        LibraryVariableStorage.Enqueue(0.3);
        InvtDocumentLine.OpenItemTrackingLines();

        // [WHEN] Post the Inventory Receipt .
        DocumentNo := InvtDocumentHeader."No.";
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [THEN] Inventory Receipt should be posted successfully.
        InvtReceiptHeader.SetRange("Receipt No.", DocumentNo);
        Assert.IsTrue(InvtReceiptHeader.FindFirst(), InventoryReceiptErr);
    end;

    local procedure PostWhseShipmentFromTO(DocumentNo: Code[20])
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Outbound Transfer");
        WhseShipmentLine.SetRange("Source No.", DocumentNo);
        WhseShipmentLine.FindFirst();

        WarehouseShipmentHeader.Get(WhseShipmentLine."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);
    end;

    local procedure FindWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Outbound Transfer");
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    [ModalPageHandler]
    procedure ReservationFromCurrentLineHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.OK().Invoke();
    end;

    local procedure CreateAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; ParentItem: Record Item; ChildItem: Record Item; DueDate: Date; Qty: Decimal; LocationCode: Code[10])
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, DueDate, ParentItem."No.", LocationCode, Qty, '');
        AssemblyHeader.Validate("Due Date", WorkDate());
        AssemblyHeader."Starting Date" := WorkDate();
        AssemblyHeader."Ending Date" := WorkDate();
        AssemblyHeader.Modify(true);

        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ChildItem."No.", ChildItem."Base Unit of Measure", Qty, 1, '');
        AssemblyLine.Validate(Reserve, AssemblyLine.Reserve::Always);
        AssemblyLine.Modify(true);
    end;

    local procedure FoundBinTypeWithCombination(IsReceive: Boolean; IsShip: Boolean; IsPutAway: Boolean; IsPick: Boolean; var NewBinType: Record "Bin Type"): Boolean
    var
        BinType: Record "Bin Type";
    begin
        Clear(NewBinType);

        BinType.SetRange(Receive, IsReceive);
        BinType.SetRange(Ship, IsShip);
        BinType.SetRange("Put Away", IsPutAway);
        BinType.SetRange(Pick, IsPick);
        if BinType.FindFirst() then begin
            NewBinType := BinType;
            exit(true);
        end;
    end;

    local procedure CreateAssemblyItemWithBOM(var AssemblyItem: Record Item; var BomComponentItem: Record Item)
    begin
        LibraryInventory.CreateItem(AssemblyItem);
        AssemblyItem.Validate("Replenishment System", AssemblyItem."Replenishment System"::Assembly);
        AssemblyItem.Validate("Assembly Policy", Enum::"Assembly Policy"::"Assemble-to-Order");
        AssemblyItem.Modify(true);

        // Create Component Item and set as Assembly BOM
        CreateAssemblyBomComponent(BomComponentItem, AssemblyItem."No.");
        Commit();
    end;

    local procedure CreateAssemblyBomComponent(var Item: Record Item; ParentItemNo: Code[20])
    var
        BomComponent: Record "BOM Component";
        BomRecordRef: RecordRef;
    begin
        BomComponent.Init();
        BomComponent.Validate(BomComponent."Parent Item No.", ParentItemNo);
        BomRecordRef.GetTable(BomComponent);
        BomComponent.Validate(BomComponent."Line No.", LibraryUtility.GetNewLineNo(BomRecordRef, BomComponent.FieldNo(BomComponent."Line No.")));
        BomComponent.Validate(BomComponent.Type, BomComponent.Type::Item);
        BomComponent.Validate(BomComponent."No.", Item."No.");
        BomComponent.Validate(BomComponent."Quantity per", LibraryRandom.RandInt(10));
        BomComponent.Insert(true);
    end;

    local procedure CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; UseItemTracking: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, ItemNo, Quantity, LocationCode, UseItemTracking);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure CreateAndPostWarehouseReceiptFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; UseItemTracking: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", ItemNo, Quantity, LocationCode, UseItemTracking);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(PurchaseHeader."No.", ItemNo);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ItemTracking: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader."Location Code" := LocationCode;
        PurchaseHeader.Modify();
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, Quantity, LocationCode, ItemTracking);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; UseTracking: Boolean)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
        if UseTracking then
            PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure RegisterWarehouseActivity(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindSet();
    end;

    local procedure PostWarehouseReceipt(SourceNo: Code[20]; ItemNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceNo, ItemNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20]; ItemNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure CreateRegisterWhsePick(var WarehouseActivityHeader: Record "Warehouse Activity Header"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; QtyToPost: Decimal)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);
        ModifyWhsePick(WarehouseActivityLine, WarehouseShipmentHeader, QtyToPost);
        RegisterWhsePick(WarehouseActivityHeader, WarehouseActivityLine);
    end;

    local procedure ModifyWhsePick(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; QtyToSet: Decimal)
    begin
        FindWhseActivityLine(WarehouseActivityLine, WarehouseShipmentHeader);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToSet);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure FindWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        WarehouseActivityLine.SetRange("Whse. Document Type", WarehouseActivityLine."Whse. Document Type"::Shipment);
        WarehouseActivityLine.SetRange("Whse. Document No.", WarehouseShipmentHeader."No.");
        WarehouseActivityLine.FindSet();
    end;

    local procedure RegisterWhsePick(var WarehouseActivityHeader: Record "Warehouse Activity Header"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    [RequestPageHandler]
    procedure CreatePickFromWhseShowCalcSummaryShptReqHandler(var CreatePickFromWhseShptReqPage: TestRequestPage "Whse.-Shipment - Create Pick")
    begin
        CreatePickFromWhseShptReqPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DueDateBeforeWorkDateMsgHandler(Message: Text)
    begin
        Assert.IsTrue(StrPos(Message, DueDateBeforeWorkDateMsg) > 0, DueDateBeforeWorkDateMsg);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PickRegisteredMsgHandler(Message: Text)
    begin
        exit;
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Inventory Documents");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SCM Inventory Documents");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();

        SetupInvtDocumentsNoSeries();
        SetupPostedDirectTransfersNoSeries();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SCM Inventory Documents");
        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]): Integer
    var
        ItemJournalLine: Record "Item Journal Line";
        Qty: Integer;
    begin
        Qty := LibraryRandom.RandInt(100);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        exit(Qty);
    end;

    local procedure CreateDirectTransferHeader(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10])
    begin
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, '');
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify(true);
    end;

    local procedure CreateSNTrackedItem(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);
    end;

    local procedure CreateInvtDocumentWithLine(var InvtDocumentHeader: Record "Invt. Document Header"; var InvtDocumentLine: Record "Invt. Document Line"; Item: Record Item; DocumentType: Enum "Invt. Doc. Document Type"; LocationCode: Code[10]; SalespersonPurchaserCode: Code[20])
    begin
        CreateInvtDocumentWithLine(InvtDocumentHeader, InvtDocumentLine, Item, DocumentType, LocationCode, SalespersonPurchaserCode, LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateInvtDocumentWithLine(var InvtDocumentHeader: Record "Invt. Document Header"; var InvtDocumentLine: Record "Invt. Document Line"; Item: Record Item; DocumentType: Enum "Invt. Doc. Document Type"; LocationCode: Code[10]; SalespersonPurchaserCode: Code[20]; Qty: Decimal)
    begin
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, DocumentType, LocationCode);
        InvtDocumentHeader.Validate("Salesperson/Purchaser Code", SalespersonPurchaserCode);
        InvtDocumentHeader.Modify(true);
        LibraryInventory.CreateInvtDocumentLine(
          InvtDocumentHeader, InvtDocumentLine, Item."No.", Item."Unit Cost", Qty);
    end;

    local procedure CreateInvtDocumentWithItemTracking(var InvtDocumentHeader: Record "Invt. Document Header"; var InvtDocumentLine: Record "Invt. Document Line"; ItemDocumentType: Enum "Invt. Doc. Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal; ItemTrkgAction: Option)
    begin
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, ItemDocumentType, LocationCode);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, ItemNo, 0, Qty);
        InvtDocumentLine.Validate("Bin Code", BinCode);
        InvtDocumentLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrkgAction);
        InvtDocumentLine.OpenItemTrackingLines();
    end;

    local procedure CreateItemWithDimension(var Item: Record Item; var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        Clear(DimensionValue);
        LibraryInventory.CreateItem(Item);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Item, Item."No.", Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateSalespersonPurchaseWithDimension(var SalespersonPurchaser: Record "Salesperson/Purchaser"; var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Salesperson/Purchaser", SalespersonPurchaser.Code, Dimension.Code, DimensionValue.Code);
    end;

    local procedure SetupPostedDirectTransfersNoSeries()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Posted Direct Trans. Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        InventorySetup.Validate("Direct Transfer Posting", InventorySetup."Direct Transfer Posting"::"Direct Transfer");
        InventorySetup.Modify(true);
    end;

    local procedure SetupInvtDocumentsNoSeries()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        if InventorySetup."Invt. Receipt Nos." = '' then
            InventorySetup.Validate("Invt. Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if InventorySetup."Posted Invt. Receipt Nos." = '' then
            InventorySetup.Validate("Posted Invt. Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if InventorySetup."Invt. Shipment Nos." = '' then
            InventorySetup.Validate("Invt. Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if InventorySetup."Posted Invt. Shipment Nos." = '' then
            InventorySetup.Validate("Posted Invt. Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        InventorySetup.Modify(true);
    end;

    local procedure SetDirectTransferPosting(DirectTransferPosting: Option)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup."Direct Transfer Posting" := DirectTransferPosting;
        InventorySetup.Modify();
    end;

    local procedure AllowInvtDocReservationInInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup."Allow Invt. Doc. Reservation" := true;
        InventorySetup.Modify();
    end;

    local procedure SetCopyInvtDocComments()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup."Copy Comments to Invt. Doc." := true;
        InventorySetup.Modify();
    end;

    local procedure SetupForItemDocument(var SalespersonPurchaser: Record "Salesperson/Purchaser"; var Location: Record Location; var DimensionValue: Record "Dimension Value")
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateSalespersonPurchaseWithDimension(SalespersonPurchaser, DimensionValue);
    end;

    local procedure VerifyDimensionCode(DimensionCode: Code[20]; DimensionValueCode: Code[20]; DimSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, DimSetID);
        DimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(DimensionValueCode, DimensionSetEntry."Dimension Value Code", 'Dimension values should be equal');
    end;

    local procedure VerifyItemInventory(var Item: Record Item; LocationCode: Code[10]; ExpectedQty: Decimal)
    begin
        Item.SetRange("Location Filter", LocationCode);
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, ExpectedQty);
    end;

    local procedure VerifyWarehouseEntry(LocationCode: Code[10]; ItemNo: Code[20]; EntryType: Option; ExpectedQty: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Location Code", LocationCode);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField(Quantity, ExpectedQty);
    end;

    local procedure OpenSourceCodeSetupPage(SourceCode: Record "Source Code")
    var
        SourceCodeSetupPage: TestPage "Source Code Setup";
    begin
        SourceCodeSetupPage.OpenEdit();
        SourceCodeSetupPage."Invt. Receipt".SetValue(SourceCode.Code);
        SourceCodeSetupPage.Close();
    end;

    local procedure SetupDimensionPriority(SourceCode: Code[10]; ItemPriority: Integer; LocationPriority: Integer)
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        DefaultDimensionPriority.SetRange("Source Code", SourceCode);
        DefaultDimensionPriority.DeleteAll();

        DefaultDimensionPriority.Validate("Source Code", SourceCode);
        CreateDefaultDimPriority(DefaultDimensionPriority, Database::Item, ItemPriority);
        CreateDefaultDimPriority(DefaultDimensionPriority, Database::Location, LocationPriority);
    end;

    local procedure CreateDefaultDimPriority(var DefaultDimPriority: Record "Default Dimension Priority"; TableID: Integer; Priority: Integer)
    begin
        if (TableID = 0) or (Priority = 0) then
            exit;

        DefaultDimPriority.Validate("Table ID", TableID);
        DefaultDimPriority.Validate(Priority, Priority);
        DefaultDimPriority.Insert(true);
    end;

    local procedure VerifySourceCodeNotBlankInInvtReceiptLine(InvtDocumentHeader: Record "Invt. Document Header"; SourceCode: Record "Source Code")
    var
        InvtReceiptLine: Record "Invt. Receipt Line";
    begin
        InvtReceiptLine.SetRange("Receipt No.", InvtDocumentHeader."No.");
        InvtReceiptLine.FindFirst();
        Assert.AreEqual(SourceCode.Code, InvtReceiptLine."Source Code", StrSubstNo(SourceCodeErr, InvtReceiptLine.TableCaption()));
    end;

    local procedure VerifySourceCodeNotBlankInValueEntry(InvtDocumentHeader: Record "Invt. Document Header"; SourceCode: Record "Source Code")
    var
        ValueEntry: Record "Value Entry";
        InvtReceiptHeader: Record "Invt. Receipt Header";
    begin
        InvtReceiptHeader.SetRange("Receipt No.", InvtDocumentHeader."No.");
        InvtReceiptHeader.FindFirst();
        ValueEntry.SetRange("Document No.", InvtReceiptHeader."No.");
        ValueEntry.FindFirst();
        Assert.AreEqual(SourceCode.Code, ValueEntry."Source Code", StrSubstNo(SourceCodeErr, ValueEntry.TableCaption()));
    end;

    local procedure CreateItemWithItemTrackingCode(ItemTrackingCode: Code[10]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure VerifyInvtDocumentLineWithDimensionValue(DimensionValueCode: Code[20]; InvtDocumentHeader: Record "Invt. Document Header")
    var
        InvtReceiptLine: Record "Invt. Receipt Line";
    begin
        InvtReceiptLine.SetRange("Receipt No.", InvtDocumentHeader."No.");
        InvtReceiptLine.FindFirst();
        Assert.AreEqual(DimensionValueCode, InvtReceiptLine."Shortcut Dimension 1 Code", DimensionValueErr);
    end;

    local procedure CreateInvtComments(InvtDocumentHeader: Record "Invt. Document Header"; NoOfCommentsToCreate: Integer)
    var
        InventoryCommentLine: Record "Inventory Comment Line";
        NextLineNo: Integer;
    begin
        case InvtDocumentHeader."Document Type" of
            InvtDocumentHeader."Document Type"::Shipment:
                InventoryCommentLine.SetRange("Document Type", InventoryCommentLine."Document Type"::"Inventory Shipment");
            InvtDocumentHeader."Document Type"::Receipt:
                InventoryCommentLine.SetRange("Document Type", InventoryCommentLine."Document Type"::"Inventory Receipt");
        end;
        InventoryCommentLine.SetRange("No.", InvtDocumentHeader."No.");
        if InventoryCommentLine.FindLast() then
            NextLineNo := InventoryCommentLine."Line No.";

        while NoOfCommentsToCreate > 0 do begin
            NextLineNo += 10000;
            InventoryCommentLine.Init();
            case InvtDocumentHeader."Document Type" of
                InvtDocumentHeader."Document Type"::Shipment:
                    InventoryCommentLine."Document Type" := InventoryCommentLine."Document Type"::"Inventory Shipment";
                InvtDocumentHeader."Document Type"::Receipt:
                    InventoryCommentLine."Document Type" := InventoryCommentLine."Document Type"::"Inventory Receipt";
            end;
            InventoryCommentLine."No." := InvtDocumentHeader."No.";
            InventoryCommentLine."Line No." := NextLineNo;
            InventoryCommentLine.Date := WorkDate();
            InventoryCommentLine.Comment := LibraryRandom.RandText(MaxStrLen(InventoryCommentLine.Comment));
            InventoryCommentLine.Insert(true);
            NoOfCommentsToCreate -= 1;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingAction::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            ItemTrackingAction::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreateModalPageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryModalPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ReservationModalPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.AvailableToReserve.Invoke();
    end;

    [ModalPageHandler]
    procedure AvailableInvtDocLinesModalPageHandler(var AvailableInvtDocLines: TestPage "Available - Invt. Doc. Lines")
    begin
        AvailableInvtDocLines.Reserve.Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines.New();
        ItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.New();
        ItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}
