codeunit 137033 "SCM Item Journal"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Journal] [SCM]
        isInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        isInitialized: Boolean;
        ItemJournalAmountErr: Label 'Item Journal Amount must match.';
        ItemJournalUnitCostErr: Label 'Item Journal Unit Cost must match.';
        QuantityErr: Label 'Item Quantity must match.';
        TransferILEErr: Label 'Incorrect Item Ledger Entry created.';
        BlockMovementOutbErr: Label 'Block Movement must not be Outbound in Bin';
        BlockMovementInbErr: Label 'Block Movement must not be Inbound in Bin';
        BlockMovementAllErr: Label 'Block Movement must not be All in Bin';
        UnitCostCannotBeChangedErr: Label 'You cannot change Unit Cost when Costing Method is Standard.';
        FIELDERRORErr: Label '%1 must not be %2 in %3', Comment = '%1 : FIELDCAPTION; %2 : field value; %3 : TABLECAPTION';
        OneEntryExpectedErr: Label 'Only one Item Ledger Entry is expected.';
        MultipleEntriesExpectedErr: Label 'Two Item Ledger Entries expected.';
        RoundingTo0Err: Label 'Rounding of the field';
        BlockedBinContentErr: Label 'Block Movement must not be All in Bin Content Location Code=''%1'',Bin Code=''%2'',Item No.=''%3'',Variant Code=''%4'',Unit of Measure Code=''%5''.',
                              Comment = '%1= Location Code, %2= Bin Code, %3= Item No., %4= Varient Code, %5= Unit of Measure Code';
        ValueMustBeEqualErr: Label '%1 value must be equal to %2 in %3', Comment = '%1 = Field Name, %2= Expected Value, %3 = Table Name';
        ValueMustBeNegativeErr: Label '%1 Value must be negative', Comment = '%1=FieldName';
        ValueMustBePositiveErr: Label '%1 Value must be positive', Comment = '%1=FieldName';

    [Test]
    [Scope('OnPrem')]
    procedure GetStdJnlLines()
    var
        TempItemJournalLine: Record "Item Journal Line" temporary;
        ItemJournalBatch: Record "Item Journal Batch";
        StockoutWarning: Boolean;
        StandardItemJournalCode: Code[10];
    begin
        // Setup: Update Sales Receivables setup.
        // Create Item Journal Lines and run Save As Standard Journal report and clear Item Journal Lines.
        Initialize();
        StockoutWarning := UpdateSalesReceivableSetup(false);
        StandardItemJournalCode := CreateStdJournalSetup(TempItemJournalLine, ItemJournalBatch, 4, true);  // No of Items = 4.

        StdJournalLines(TempItemJournalLine, ItemJournalBatch, StandardItemJournalCode);

        // Update Stockout Warning to original value.
        UpdateSalesReceivableSetup(StockoutWarning);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestJournalLinesNotifications()
    var
        ItemJournalLine: Record "Item Journal Line";
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ItemJournalLines: TestPage "Item Journal Lines";
        StockoutWarning: Boolean;
        NbNotifs: Integer;
    begin
        Initialize();
        StockoutWarning := UpdateSalesReceivableSetup(true);
        CreateItemJournal(ItemJournalLine);
        // open the page
        ItemJournalLines.OpenEdit();
        Assert.IsTrue(
          ItemJournalLines.GotoKey(
            ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", ItemJournalLine."Line No."),
          'Unable to locate item journal line');
        ItemJournalLines."Entry Type".Value(Format(ItemJournalLine."Entry Type"::Sale)); // this will send a notification

        // WHEN we decrease the quantity so the item is available (0 items ordered)
        NotificationLifecycleMgt.GetTmpNotificationContext(TempNotificationContext);
        NbNotifs := TempNotificationContext.Count();
        ItemJournalLines.Quantity.Value(Format(0));

        // THEN the item availability notification is recalled
        Assert.AreEqual(NbNotifs - 1, TempNotificationContext.Count, 'Unexpected number of notifications after decreasing the Quantity.');

        // WHEN we change the type of item journal line to Purchase
        ItemJournalLines.Quantity.Value(Format(1));
        Assert.AreEqual(NbNotifs, TempNotificationContext.Count, 'Unexpected number of notifications after increasing the Quantity back.');
        ItemJournalLines."Entry Type".Value(Format(ItemJournalLine."Entry Type"::Purchase));

        // THEN the item availability notification is recalled
        Assert.AreEqual(
          NbNotifs - 1, TempNotificationContext.Count,
          'Unexpected number of notifications after updating the entry type from Sale to Purchase.');

        // Update Stockout Warning to original value.
        UpdateSalesReceivableSetup(StockoutWarning);
        ItemJournalLines.Close();
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ItemJournalConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeStdJnlLinesQty()
    var
        TempItemJournalLine: Record "Item Journal Line" temporary;
        TempItemJournalLine2: Record "Item Journal Line" temporary;
        ItemJournalBatch: Record "Item Journal Batch";
        StandardItemJournalCode: Code[10];
    begin
        // Setup: Create Item Journal Lines and run Save As Standard Journal report and clear Item Journal Lines.
        Initialize();
        StandardItemJournalCode := CreateStdJournalSetup(TempItemJournalLine, ItemJournalBatch, 3, true);  // No of Items = 3.
        CreateItemJnlFromStdJournal(ItemJournalBatch, StandardItemJournalCode);
        UpdateItemJournalLineQuantity(TempItemJournalLine2, ItemJournalBatch, StandardItemJournalCode);

        StdJournalLines(TempItemJournalLine2, ItemJournalBatch, StandardItemJournalCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetStdJnlLinesWithoutAmt()
    var
        TempItemJournalLine: Record "Item Journal Line" temporary;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        StandardItemJournalCode: Code[10];
    begin
        // Setup: Create Item Journal Lines and run Save As Standard Journal report and clear Item Journal Lines.
        Initialize();
        StandardItemJournalCode := CreateStdJournalSetup(TempItemJournalLine, ItemJournalBatch, 4, false);  // No of Items = 4.
        SelectItemJournalLine(ItemJournalLine, ItemJournalBatch);
        StandardItemJournalCode := SaveAsStandardJournal(ItemJournalBatch, ItemJournalLine, false, true, '');  // Unit Amount Not Saved.

        StdJournalLines(TempItemJournalLine, ItemJournalBatch, StandardItemJournalCode);
    end;

    [Normal]
    local procedure StdJournalLines(var TempItemJournalLine: Record "Item Journal Line" temporary; ItemJournalBatch: Record "Item Journal Batch"; StandardItemJournalCode: Code[10])
    begin
        Initialize();

        // Exercise: Populate Item Journal Lines from Standard Item Journal.
        CreateItemJnlFromStdJournal(ItemJournalBatch, StandardItemJournalCode);

        // Verify: Verify Item Journal Lines.
        VerifyItemJournalAmount(TempItemJournalLine, ItemJournalBatch);

        // Teardown.
        ItemJournalBatch.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePartialStdJnl()
    var
        TempItem: Record Item temporary;
        TempItemJournalLine: Record "Item Journal Line" temporary;
        TempItemJournalLine2: Record "Item Journal Line" temporary;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalBatch2: Record "Item Journal Batch";
        StandardItemJournal: Record "Standard Item Journal";
        StandardItemJournalCode: Code[10];
        StandardItemJournalCode2: Code[10];
    begin
        // Setup: Create Item Journal Lines and run Save As Standard Journal report and clear Item Journal Lines.
        Initialize();
        CreateItemsAndCopyToTemp(TempItem, 4);  // No of Items = 4.
        StandardItemJournalCode := CreateItemJournalAndCopyToTemp(TempItemJournalLine, TempItem, ItemJournalBatch, true);
        StandardItemJournalCode2 := CreateItemJournalAndCopyToTemp(TempItemJournalLine2, TempItem, ItemJournalBatch2, true);
        CreateItemJnlFromStdJournal(ItemJournalBatch2, StandardItemJournalCode2);

        // Exercise: Delete selected Standard Item Journal.
        SelectStandardItemJournal(StandardItemJournal, StandardItemJournalCode2, ItemJournalBatch2."Journal Template Name");
        StandardItemJournal.Delete(true);

        // Verify: Verify Standard Item Journal entry.
        VerifyStandardJournalEntry(ItemJournalBatch."Journal Template Name", StandardItemJournalCode);

        // Teardown.
        ItemJournalBatch.Delete(true);
        ItemJournalBatch2.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeItemCostRecalcUnitAmt()
    var
        TempItem: Record Item temporary;
        TempItemJournalLine: Record "Item Journal Line" temporary;
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        StandardItemJournalCode: Code[10];
    begin
        // Setup: Create Item Journal Line and run Save As Standard Journal report and clear Item Journal Line.
        Initialize();
        CreateItemWithoutCost(TempItem, Item);  // No of Item = 1.
        StandardItemJournalCode := CreateItemJournalAndCopyToTemp(TempItemJournalLine, TempItem, ItemJournalBatch, true);
        CreateItemJnlFromStdJournal(ItemJournalBatch, StandardItemJournalCode);
        UpdateItemCost(Item);

        // Exercise: Recalculate Unit Amount for Item on Item Journal Lines.
        RecalcUnitAmountItemJnlLine(ItemJournalLine, ItemJournalBatch);

        // Verify: Verify Item Journal Line after Recalculate Unit Amount.
        Assert.AreEqual(Item."Unit Price", ItemJournalLine."Unit Amount", ItemJournalAmountErr);
        Assert.AreEqual(Item."Unit Cost", ItemJournalLine."Unit Cost", ItemJournalUnitCostErr);

        // Teardown.
        ItemJournalBatch.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeItemJnlLineRecalcUnitAmt()
    var
        TempItemJournalLine: Record "Item Journal Line" temporary;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        StandardItemJournalCode: Code[10];
    begin
        // Setup: Create Item Journal Line and run Save As Standard Journal report and clear Item Journal Line.
        // Modify Unit Cost of Item on Item Journal Line.
        Initialize();
        StandardItemJournalCode := CreateStdJournalSetup(TempItemJournalLine, ItemJournalBatch, 1, true);  // No of Item = 1.
        CreateItemJnlFromStdJournal(ItemJournalBatch, StandardItemJournalCode);
        UpdateItemJournalUnitCost(ItemJournalLine, ItemJournalBatch);

        // Exercise: Recalculate Unit Amount for Item on Item Journal Line. Item Unit Cost reverts to original value.
        RecalcUnitAmountItemJnlLine(ItemJournalLine, ItemJournalBatch);

        // Verify: Verify Item Journal Line.
        Assert.AreEqual(TempItemJournalLine."Unit Cost", ItemJournalLine."Unit Cost", ItemJournalUnitCostErr);

        // Teardown.
        ItemJournalBatch.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetStdJnlLinesAndPost()
    var
        TempItemJournalLine: Record "Item Journal Line" temporary;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        StandardItemJournalCode: Code[10];
    begin
        // Setup: Create Item Journal Lines and run Save As Standard Journal report and clear Item Journal Lines.
        Initialize();
        StandardItemJournalCode := CreateStdJournalSetup(TempItemJournalLine, ItemJournalBatch, 4, true);  // No of Items = 4.
        CreateItemJnlFromStdJournal(ItemJournalBatch, StandardItemJournalCode);
        UpdateItemJournalDocumentNo(ItemJournalLine, ItemJournalBatch);

        // Exercise: Post Item Journal Lines.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // Verify: Verify Item Ledger Entry for the Items.
        VerifyItemLedgerEntry(TempItemJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostItemJournal()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Posting Item Journal and Verifying Item Ledger Entries.
        Initialize();

        // Setup: Create Item Journal with Entry Type Positive Adjustment.
        CreateItemJournal(ItemJournalLine);

        // Exercise: Post Item Journal.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Verify Item Ledger Entry.
        VerifyItemLedgerEntryForQty(ItemJournalLine);
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure PostItemJournalTransferLines()
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlTemplate: Record "Item Journal Template";
        Item: Record Item;
        OldLocation: Record Location;
        NewLocation: Record Location;
        OldBinCode: Code[20];
        NewBinCode: Code[20];
        ItemQty: Integer;
        DocumentNo: Code[20];
    begin
        // Complex scenario: create 2 Item Journal lines, 1st with transfer, 2nd - with Bin reclassification.
        // Verify Item Ledger Entries: they should be created only for 1st Jnl. Line

        Initialize();

        // Create 2 locations, 1st with Bin numbers, second - without
        CreateLocationWithBin(OldLocation, OldBinCode, NewBinCode);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(NewLocation);

        LibraryInventory.CreateItem(Item);

        ItemQty := LibraryRandom.RandInt(20);

        // Create Item Journal Template and Batch
        LibraryInventory.CreateItemJournalTemplate(ItemJnlTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJnlBatch, ItemJnlTemplate.Name);

        // Create Positive Adjmt. Journal Line
        CreatePositiveAdjmtLocationAndBin(
          ItemJnlTemplate.Name, ItemJnlBatch.Name, OldLocation.Code, OldBinCode, Item."No.", 2 * ItemQty);

        // Create Transfer line
        CreateItemReclassJournaLine(
          ItemJnlTemplate.Name, ItemJnlBatch.Name, Item."No.", OldLocation.Code, NewLocation.Code, OldBinCode, '', ItemQty);

        // Create Bin Reclassification line - no Item Ledger Entry should be created
        DocumentNo :=
          CreateItemReclassJournaLine(
            ItemJnlTemplate.Name, ItemJnlBatch.Name, Item."No.", OldLocation.Code, OldLocation.Code, OldBinCode, NewBinCode, ItemQty);

        // Post lines
        LibraryInventory.PostItemJournalLine(ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name);

        // Verify that no ledger entries for Bin Reclassification Line were created
        CheckNoItemLedgerEntries(DocumentNo);

        // Tear down.
        ItemJnlTemplate.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitAmountOnItemJournalLine()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        // [SCENARIO] Item Journal's Unit Amount field gets updated from the Unit Price value on item Card instead of Unit Cost when Entry Type=Sales.
        Initialize();

        // [GIVEN] Item with "A" with "Unit Price" = "X"
        CreateItem(Item);

        // [WHEN] Validate Item Journal with item "A" and "Entry Type" = Sale.
        SelectItemJournal(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Sale, Item."No.", LibraryRandom.RandDec(10, 2));

        // [THEN] Item Journal's "Unit Amount" = "X"
        ItemJournalLine.TestField("Unit Amount", Item."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReclassLineBlockMovementNewBinInbound()
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlTemplate: Record "Item Journal Template";
        Location: Record Location;
        OldBin: Record Bin;
        NewBin: Record Bin;
    begin
        // [FEATURE] [Item Journal] [Bin]
        // [SCENARIO 376316] Posting Item Reclassification Line should be prohibited for New Bin with Block Movement Inbound
        Initialize();

        // [GIVEN] Location "X" with two Bins: Bin1 without "Block Movement" and Bin2 with "Block Movement" = "Inbound"
        CreateLocationWithTwoBinsBlockMovement(Location, OldBin, OldBin."Block Movement"::" ", NewBin, NewBin."Block Movement"::Inbound);

        // [GIVEN] Item Reclassification Line with Bin = Bin1, New Bin = Bin2
        CreateItemReclassJournalLineWithNewBin(
          ItemJnlBatch, ItemJnlTemplate, Location.Code, OldBin.Code, NewBin.Code, LibraryRandom.RandInt(9));

        // [WHEN] Post Item Reclassification Line
        asserterror LibraryInventory.PostItemJournalLine(ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name);

        // [THEN] Error is thrown: "Block Movement must not be Inbound in Bin"
        Assert.ExpectedError(BlockMovementInbErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReclassLineBlockMovementBinOutbound()
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlTemplate: Record "Item Journal Template";
        Location: Record Location;
        OldBin: Record Bin;
        NewBin: Record Bin;
    begin
        // [FEATURE] [Item Journal] [Bin]
        // [SCENARIO 376316] Posting Item Reclassification Line should be prohibited for Bin with Block Movement Outbound
        Initialize();

        // [GIVEN] Location "X" with two Bins: Bin1 with "Block Movement" = "Outbound" and Bin2 without "Block Movement"
        CreateLocationWithTwoBinsBlockMovement(Location, OldBin, OldBin."Block Movement"::Outbound, NewBin, NewBin."Block Movement"::" ");

        // [GIVEN] Item Reclassification Line with Bin = Bin1, New Bin = Bin2
        CreateItemReclassJournalLineWithNewBin(
          ItemJnlBatch, ItemJnlTemplate, Location.Code, OldBin.Code, NewBin.Code, LibraryRandom.RandInt(9));

        // [WHEN] Post Item Reclassification Line
        asserterror LibraryInventory.PostItemJournalLine(ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name);

        // [THEN] Error is thrown: "Block Movement must not be Outbound in Bin"
        Assert.ExpectedError(BlockMovementOutbErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReclassLineBlockMovementNewBinAll()
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlTemplate: Record "Item Journal Template";
        Location: Record Location;
        OldBin: Record Bin;
        NewBin: Record Bin;
    begin
        // [FEATURE] [Item Journal] [Bin]
        // [SCENARIO 376316] Posting Item Reclassification Line should be prohibited for New Bin with Block Movement All
        Initialize();

        // [GIVEN] Location "X" with two Bins: Bin1 without "Block Movement" and Bin2 with "Block Movement" = "All"
        CreateLocationWithTwoBinsBlockMovement(Location, OldBin, OldBin."Block Movement"::" ", NewBin, NewBin."Block Movement"::All);

        // [GIVEN] Item Reclassification Line with Bin = Bin1, New Bin = Bin2
        CreateItemReclassJournalLineWithNewBin(
          ItemJnlBatch, ItemJnlTemplate, Location.Code, OldBin.Code, NewBin.Code, LibraryRandom.RandInt(9));

        // [WHEN] Post Item Reclassification Line
        asserterror LibraryInventory.PostItemJournalLine(ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name);

        // [THEN] Error is thrown: "Block Movement must not be All in Bin"
        Assert.ExpectedError(BlockMovementAllErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReclassLineBlockMovementBinAll()
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlTemplate: Record "Item Journal Template";
        Location: Record Location;
        OldBin: Record Bin;
        NewBin: Record Bin;
    begin
        // [FEATURE] [Item Journal] [Bin]
        // [SCENARIO 376316] Posting Item Reclassification Line should be prohibited for Bin with Block Movement All
        Initialize();

        // [GIVEN] Location "X" with two Bins: Bin1 with "Block Movement" = "All" and Bin2 without "Block Movement"
        CreateLocationWithTwoBinsBlockMovement(Location, OldBin, OldBin."Block Movement"::All, NewBin, NewBin."Block Movement"::" ");

        // [GIVEN] Item Reclassification Line with Bin = Bin1, New Bin = Bin2
        CreateItemReclassJournalLineWithNewBin(
          ItemJnlBatch, ItemJnlTemplate, Location.Code, OldBin.Code, NewBin.Code, LibraryRandom.RandInt(9));

        // [WHEN] Post Item Reclassification Line
        asserterror LibraryInventory.PostItemJournalLine(ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name);

        // [THEN] Error is thrown: "Block Movement must not be All in Bin"
        Assert.ExpectedError(BlockMovementAllErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJournalLineSalesBlockMovementBinOutbound()
    var
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Bin: Record Bin;
    begin
        // [FEATURE] [Item Journal] [Bin]
        // [SCENARIO 377504] Posting Item Journal Line with "Entry Type" = "Sales" should be prohibited for Bin with Block Movement Outbound
        Initialize();

        // [GIVEN] Bin "B" with "Block Movement" = "Outbound"
        CreateLocationWithBinBlockMovement(Location, Bin, Bin."Block Movement"::Outbound);

        // [GIVEN] Item Journal Line with Bin = "B" and "Entry Type" = "Sales"
        CreateItemJournalLineWithEntryType(ItemJournalLine, ItemJournalLine."Entry Type"::Sale, Location.Code, Bin.Code);

        // [WHEN] Post Item Jounal Line
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Error is thrown: "Block Movement must not be Outbound in Bin"
        Assert.ExpectedError(BlockMovementOutbErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJournalLineNegAdjmBlockMovementBinInbound()
    var
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Bin: Record Bin;
    begin
        // [FEATURE] [Item Journal] [Bin]
        // [SCENARIO 377504] Posting Item Journal Line with "Entry Type" = "Negative Adjmt." and negative Quantity should be prohibited for Bin with Block Movement Inbound
        Initialize();

        // [GIVEN] Bin "B" with "Block Movement" = "Inbound"
        CreateLocationWithBinBlockMovement(Location, Bin, Bin."Block Movement"::Inbound);

        // [GIVEN] Item Journal Line with Bin = "B" and "Entry Type" = "Negative Adjmt."
        CreateItemJournalLineWithEntryType(ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", Location.Code, Bin.Code);
        ItemJournalLine.Quantity := -ItemJournalLine.Quantity;
        ItemJournalLine.Modify();

        // [WHEN] Post Item Jounal Line
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Error is thrown: "Block Movement must not be Inbound in Bin"
        Assert.ExpectedError(BlockMovementInbErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJournalLineConsBlockMovementBinOutbound()
    var
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Bin: Record Bin;
    begin
        // [FEATURE] [Item Journal] [Bin]
        // [SCENARIO 377504] Posting Item Journal Line with "Entry Type" = "Consumption" should be prohibited for Bin with Block Movement Outbound
        Initialize();

        // [GIVEN] Bin "B" with "Block Movement" = "Outbound"
        CreateLocationWithBinBlockMovement(Location, Bin, Bin."Block Movement"::Outbound);

        // [GIVEN] Item Journal Line with Bin = "B" and "Entry Type" = "Consumption"
        CreateItemJournalLineWithEntryType(ItemJournalLine, ItemJournalLine."Entry Type"::Consumption, Location.Code, Bin.Code);

        // [WHEN] Post Item Jounal Line
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Error is thrown: "Block Movement must not be Outbound in Bin"
        Assert.ExpectedError(BlockMovementOutbErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJournalLineAsmblyConsBlockMovementBinInbound()
    var
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Bin: Record Bin;
    begin
        // [FEATURE] [Item Journal] [Bin]
        // [SCENARIO 377504] Posting Item Journal Line with "Entry Type" = "Assembly Consumption" and negative Quantity should be prohibited for Bin with Block Movement Inbound
        Initialize();

        // [GIVEN] Bin "B" with "Block Movement" = "Inbound"
        CreateLocationWithBinBlockMovement(Location, Bin, Bin."Block Movement"::Inbound);

        // [GIVEN] Item Journal Line with Bin = "B" and "Entry Type" = "Assembly Consumption"
        CreateItemJournalLineWithEntryType(ItemJournalLine, ItemJournalLine."Entry Type"::"Assembly Consumption", Location.Code, Bin.Code);
        ItemJournalLine.Quantity := -ItemJournalLine.Quantity;
        ItemJournalLine.Modify();

        // [WHEN] Post Item Jounal Line
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Error is thrown: "Block Movement must not be Inbound in Bin"
        Assert.ExpectedError(BlockMovementInbErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJournalLinePurchBlockMovementBinInbound()
    var
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Bin: Record Bin;
    begin
        // [FEATURE] [Item Journal] [Bin]
        // [SCENARIO 377504] Posting Item Journal Line with "Entry Type" = "Purchase" should be prohibited for Bin with Block Movement Inbound
        Initialize();

        // [GIVEN] Bin "B" with "Block Movement" = "Inbound"
        CreateLocationWithBinBlockMovement(Location, Bin, Bin."Block Movement"::Inbound);

        // [GIVEN] Item Journal Line with Bin = "B" and "Entry Type" = "Purchase"
        CreateItemJournalLineWithEntryType(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, Location.Code, Bin.Code);

        // [WHEN] Post Item Jounal Line
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Error is thrown: "Block Movement must not be Inbound in Bin"
        Assert.ExpectedError(BlockMovementInbErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJournalLinePosAdjmBlockMovementBinOutbound()
    var
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Bin: Record Bin;
    begin
        // [FEATURE] [Item Journal] [Bin]
        // [SCENARIO 377504] Posting Item Journal Line with "Entry Type" = "Positive Adjmt." and negative Quantity should be prohibited for Bin with Block Movement Outbound
        Initialize();

        // [GIVEN] Bin "B" with "Block Movement" = "Outbound"
        CreateLocationWithBinBlockMovement(Location, Bin, Bin."Block Movement"::Outbound);

        // [GIVEN] Item Journal Line with Bin = "B" and "Entry Type" = "Positive Adjmt."
        CreateItemJournalLineWithEntryType(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Location.Code, Bin.Code);
        ItemJournalLine.Quantity := -ItemJournalLine.Quantity;
        ItemJournalLine.Modify();

        // [WHEN] Post Item Jounal Line
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Error is thrown: "Block Movement must not be Outbound in Bin"
        Assert.ExpectedError(BlockMovementOutbErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJournalLineOutputBlockMovementBinInbound()
    var
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Bin: Record Bin;
    begin
        // [FEATURE] [Item Journal] [Bin]
        // [SCENARIO 377504] Posting Item Journal Line with "Entry Type" = "Output" should be prohibited for Bin with Block Movement Inbound
        Initialize();

        // [GIVEN] Bin "B" with "Block Movement" = "Inbound"
        CreateLocationWithBinBlockMovement(Location, Bin, Bin."Block Movement"::Inbound);

        // [GIVEN] Item Journal Line with Bin = "B" and "Entry Type" = "Output"
        CreateItemJournalLineWithEntryType(ItemJournalLine, ItemJournalLine."Entry Type"::Output, Location.Code, Bin.Code);
        ItemJournalLine.Validate("Output Quantity", 1);
        ItemJournalLine.Modify(true);

        // [WHEN] Post Item Jounal Line
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Error is thrown: "Block Movement must not be Inbound in Bin"
        Assert.ExpectedError(BlockMovementInbErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJournalLineAsmblyOutputBlockMovementBinOutbound()
    var
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Bin: Record Bin;
    begin
        // [FEATURE] [Item Journal] [Bin]
        // [SCENARIO 377504] Posting Item Journal Line with "Entry Type" = "Assembly Output" and negative Quantity should be prohibited for Bin with Block Movement Outbound
        Initialize();

        // [GIVEN] Bin "B" with "Block Movement" = "Outbound"
        CreateLocationWithBinBlockMovement(Location, Bin, Bin."Block Movement"::Outbound);

        // [GIVEN] Item Journal Line with Bin = "B" and "Entry Type" = "Assembly Output"
        CreateItemJournalLineWithEntryType(ItemJournalLine, ItemJournalLine."Entry Type"::"Assembly Output", Location.Code, Bin.Code);
        ItemJournalLine.Quantity := -ItemJournalLine.Quantity;
        ItemJournalLine.Modify();

        // [WHEN] Post Item Jounal Line
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Error is thrown: "Block Movement must not be Outbound in Bin"
        Assert.ExpectedError(BlockMovementOutbErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitAmountEqualsUnitCostOnJournalLineForPositiveAdjmtWhenQtyIsValidated()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO 202372] Unit Amount should be equal to Unit Cost on positive adjustment item journal line when Quantity is updated, and Costing Method of the item is other than Standard.
        Initialize();

        // [GIVEN] Item "I" with Costing Method = "FIFO" and Unit Cost = "X".
        CreateItemWithCostingMethod(Item, Item."Costing Method"::FIFO);

        // [GIVEN] Positive adjustment item journal line with quantity "Q1" of item "I".
        CreateItemJournalLine(ItemJournalLine, Item."No.");

        // [GIVEN] Unit Cost on the journal line is updated to "Y".
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDecInRange(20, 40, 2));

        // [WHEN] Update Quantity on the journal line to "Q2".
        ItemJournalLine.Validate(Quantity, LibraryRandom.RandIntInRange(20, 40));

        // [THEN] Unit Amount is equal to "Y".
        ItemJournalLine.TestField("Unit Amount", ItemJournalLine."Unit Cost");

        // [THEN] Amount is equal to "Q2" * "Y".
        ItemJournalLine.TestField(Amount, ItemJournalLine."Unit Cost" * ItemJournalLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitAmountEqualsUnitCostOnJournalLineForNegativeAdjmtWhenQtyIsValidated()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO 202372] Unit Amount should be equal to Unit Cost on negative adjustment item journal line when Quantity is updated, and Costing Method of the item is other than Standard.
        Initialize();

        // [GIVEN] Item "I" with Costing Method = "FIFO" and Unit Cost = "X".
        CreateItemWithCostingMethod(Item, Item."Costing Method"::FIFO);

        // [GIVEN] Negative adjustment item journal line with quantity "Q1" of item "I".
        CreateItemJournalLine(ItemJournalLine, Item."No.");
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::"Negative Adjmt.");

        // [GIVEN] Unit Cost on the journal line is updated to "Y".
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDecInRange(20, 40, 2));

        // [WHEN] Update Quantity on the journal line to "Q2".
        ItemJournalLine.Validate(Quantity, LibraryRandom.RandIntInRange(20, 40));

        // [THEN] Unit Amount is equal to "Y".
        ItemJournalLine.TestField("Unit Amount", ItemJournalLine."Unit Cost");

        // [THEN] Amount is equal to "Q2" * "Y".
        ItemJournalLine.TestField(Amount, ItemJournalLine."Unit Cost" * ItemJournalLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitAmountEqualsUnitCostOnJournalLineForPositiveAdjmtWhenUOMIsValidated()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO 222394] Unit Amount should be equal to Unit Cost on positive adjustment item journal line when Unit of Measure Code is updated, and Costing Method of the item is other than Standard.
        Initialize();

        // [GIVEN] Item with Costing Method = "FIFO" and Unit Cost = "X".
        CreateItemWithCostingMethod(Item, Item."Costing Method"::FIFO);

        // [GIVEN] Alternate unit of measure "UOM" for the item. Quantity per base unit of measure = "Q".
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Positive adjustment item journal line.
        CreateItemJournalLine(ItemJournalLine, Item."No.");

        // [WHEN] Update Unit of Measure on the journal line to "UOM".
        ItemJournalLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);

        // [THEN] Unit Cost is equal to "X" * "Q".
        ItemJournalLine.TestField("Unit Cost", Item."Unit Cost" * ItemUnitOfMeasure."Qty. per Unit of Measure");

        // [THEN] Unit Amount is equal to Unit Cost.
        ItemJournalLine.TestField("Unit Amount", ItemJournalLine."Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostCannotBeUpdatedOnJournalLineForItemWithStandardCost()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournal: TestPage "Item Journal";
    begin
        // [SCENARIO 202372] Unit Cost cannot be changed on item journal line for an item with Costing Method = Standard.
        Initialize();

        // [GIVEN] Item "I" with Costing Method = "Standard" and Unit Cost = "X".
        CreateItemWithCostingMethod(Item, Item."Costing Method"::Standard);

        // [GIVEN] Positive adjustment item journal line with quantity "Q1" of item "I".
        CreateItemJournalLine(ItemJournalLine, Item."No.");

        // [WHEN] Update Quantity on the journal line to "Q2".
        ItemJournal.OpenEdit();
        ItemJournal.GotoRecord(ItemJournalLine);
        asserterror ItemJournal."Unit Cost".SetValue(LibraryRandom.RandDecInRange(20, 40, 2));

        // [THEN] An error is thrown.
        Assert.ExpectedError(UnitCostCannotBeChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitAmountEqualsUnitCostOnItemCardWhenItemIsValidatedOnJournalLine()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO 202372] Unit Cost should be reset to Unit Cost on the item card if Item No. is re-validated on item journal line.
        Initialize();

        // [GIVEN] Item "I" with Costing Method = "FIFO" and Unit Cost = "X".
        CreateItemWithCostingMethod(Item, Item."Costing Method"::FIFO);
        // [GIVEN] Positive adjustment item journal line with quantity "Q1" of item "I".
        CreateItemJournalLine(ItemJournalLine, Item."No.");
        // [GIVEN] Unit Cost on the journal line is updated to "Y".
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDecInRange(20, 40, 2));
        // [WHEN] Item No. is re-validated on the item journal.
        ItemJournalLine.Validate("Item No.", Item."No.");
        // [THEN] Unit Amount is reset to "X".
        ItemJournalLine.TestField("Unit Amount", Item."Unit Cost");
        // [THEN] Amount is equal to "Q1" * "X".
        ItemJournalLine.TestField(Amount, Item."Unit Cost" * ItemJournalLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitAmountEqualsUnitCostOnStdJnlLineForPositiveAdjmtWhenQtyIsValidated()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        StandardItemJournalLine: Record "Standard Item Journal Line";
        StandardItemJournalCode: Code[10];
    begin
        // [FEATURE] [Standard Item Journal]
        // [SCENARIO 202372] Unit Amount should be equal to Unit Cost on positive adjustment standard item journal line when Quantity is updated, and Costing Method of the item is other than Standard.
        Initialize();

        // [GIVEN] Item "I" with Costing Method = "FIFO" and Unit Cost = "X".
        CreateItemWithCostingMethod(Item, Item."Costing Method"::FIFO);

        // [GIVEN] Positive adjustment item journal line with quantity "Q1" of item "I".
        CreateItemJournalLine(ItemJournalLine, Item."No.");

        // [GIVEN] The item journal line is saved as standard journal line.
        StandardItemJournalCode := SaveItemJournalLineAsNewStandardJournal(ItemJournalLine, true, true);
        FindStandardItemJournalLine(StandardItemJournalLine, StandardItemJournalCode, Item."No.");

        // [GIVEN] Unit Cost on the standard journal line is updated to "Y".
        StandardItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDecInRange(20, 40, 2));

        // [WHEN] Update Quantity on the standard journal line to "Q2".
        StandardItemJournalLine.Validate(Quantity, LibraryRandom.RandIntInRange(20, 40));

        // [THEN] Unit Amount is equal to "Y".
        StandardItemJournalLine.TestField("Unit Amount", StandardItemJournalLine."Unit Cost");

        // [THEN] Amount is equal to "Q2" * "Y".
        StandardItemJournalLine.TestField(Amount, StandardItemJournalLine."Unit Cost" * StandardItemJournalLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitAmountEqualsUnitCostOnStdJnlLineForNegativeAdjmtWhenQtyIsValidated()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        StandardItemJournalLine: Record "Standard Item Journal Line";
        StandardItemJournalCode: Code[10];
    begin
        // [FEATURE] [Standard Item Journal]
        // [SCENARIO 202372] Unit Amount should be equal to Unit Cost on negative adjustment standard item journal line when Quantity is updated, and Costing Method of the item is other than Standard.
        Initialize();

        // [GIVEN] Item "I" with Costing Method = "FIFO" and Unit Cost = "X".
        CreateItemWithCostingMethod(Item, Item."Costing Method"::FIFO);

        // [GIVEN] Negative adjustment item journal line with quantity "Q1" of item "I".
        CreateItemJournalLine(ItemJournalLine, Item."No.");
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::"Negative Adjmt.");
        ItemJournalLine.Modify(true);

        // [GIVEN] The item journal line is saved as standard journal line.
        StandardItemJournalCode := SaveItemJournalLineAsNewStandardJournal(ItemJournalLine, true, true);
        FindStandardItemJournalLine(StandardItemJournalLine, StandardItemJournalCode, Item."No.");

        // [GIVEN] Unit Cost on the standard journal line is updated to "Y".
        StandardItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDecInRange(20, 40, 2));

        // [WHEN] Update Quantity on the standard journal line to "Q2".
        StandardItemJournalLine.Validate(Quantity, LibraryRandom.RandIntInRange(20, 40));

        // [THEN] Amount is equal to "Q2" * "Y".
        StandardItemJournalLine.TestField(Amount, StandardItemJournalLine."Unit Cost" * StandardItemJournalLine.Quantity);

        // [THEN] Unit Amount is equal to "Y".
        StandardItemJournalLine.TestField("Unit Amount", StandardItemJournalLine."Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitAmountEqualsUnitCostOnStdJnlLineForPositiveAdjmtWhenUOMIsValidated()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemJournalLine: Record "Item Journal Line";
        StandardItemJournalLine: Record "Standard Item Journal Line";
        StandardItemJournalCode: Code[10];
    begin
        // [FEATURE] [Standard Item Journal]
        // [SCENARIO 222394] Unit Amount should be equal to Unit Cost on positive adjustment standard item journal line when Unit of Measure Code is updated, and Costing Method of the item is other than Standard.
        Initialize();

        // [GIVEN] Item with Costing Method = "FIFO" and Unit Cost = "X".
        CreateItemWithCostingMethod(Item, Item."Costing Method"::FIFO);

        // [GIVEN] Alternate unit of measure "UOM" for the item. Quantity per base unit of measure = "Q".
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Positive adjustment item journal line.
        CreateItemJournalLine(ItemJournalLine, Item."No.");

        // [GIVEN] The item journal line is saved as standard journal line.
        StandardItemJournalCode := SaveItemJournalLineAsNewStandardJournal(ItemJournalLine, true, true);
        FindStandardItemJournalLine(StandardItemJournalLine, StandardItemJournalCode, Item."No.");

        // [WHEN] Update Unit of Measure Code on the standard journal line to "UOM".
        StandardItemJournalLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);

        // [THEN] Unit Cost is equal to "X" * "Q".
        StandardItemJournalLine.TestField("Unit Cost", Item."Unit Cost" * ItemUnitOfMeasure."Qty. per Unit of Measure");

        // [THEN] Unit Amount is equal to Unit Cost.
        StandardItemJournalLine.TestField("Unit Amount", StandardItemJournalLine."Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostCannotBeUpdatedOnStdJnlLineForItemWithStandardCost()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        StandardItemJournalLine: Record "Standard Item Journal Line";
        StandardItemJournal: TestPage "Standard Item Journal";
        StandardItemJournalCode: Code[10];
    begin
        // [FEATURE] [Standard Item Journal]
        // [SCENARIO 202372] Unit Cost cannot be changed on standard item journal line for an item with Costing Method = Standard.
        Initialize();

        // [GIVEN] Item "I" with Costing Method = "Standard" and Unit Cost = "X".
        CreateItemWithCostingMethod(Item, Item."Costing Method"::Standard);

        // [GIVEN] Positive adjustment item journal line with quantity "Q1" of item "I".
        CreateItemJournalLine(ItemJournalLine, Item."No.");

        // [GIVEN] The item journal line is saved as standard journal line.
        StandardItemJournalCode := SaveItemJournalLineAsNewStandardJournal(ItemJournalLine, true, true);
        FindStandardItemJournalLine(StandardItemJournalLine, StandardItemJournalCode, Item."No.");

        // [WHEN] Update Quantity on the standard journal line to "Q2".
        StandardItemJournal.OpenEdit();
        StandardItemJournal.FILTER.SetFilter(Code, StandardItemJournalCode);
        StandardItemJournal.StdItemJnlLines.GotoRecord(StandardItemJournalLine);
        asserterror StandardItemJournal.StdItemJnlLines."Unit Cost".SetValue(LibraryRandom.RandDecInRange(20, 40, 2));

        // [THEN] An error is thrown.
        Assert.ExpectedError(UnitCostCannotBeChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitAmountEqualsUnitCostOnItemCardWhenItemIsValidatedOnStdJnlLine()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        StandardItemJournalLine: Record "Standard Item Journal Line";
        StandardItemJournalCode: Code[10];
    begin
        // [FEATURE] [Standard Item Journal]
        // [SCENARIO 202372] Unit Cost should be reset to Unit Cost on the item card if Item No. is re-validated on standard item journal line.
        Initialize();

        // [GIVEN] Item "I" with Costing Method = "FIFO" and Unit Cost = "X".
        CreateItemWithCostingMethod(Item, Item."Costing Method"::FIFO);

        // [GIVEN] Positive adjustment item journal line with quantity "Q1" of item "I".
        CreateItemJournalLine(ItemJournalLine, Item."No.");

        // [GIVEN] The item journal line is saved as standard journal line.
        StandardItemJournalCode := SaveItemJournalLineAsNewStandardJournal(ItemJournalLine, true, true);
        FindStandardItemJournalLine(StandardItemJournalLine, StandardItemJournalCode, Item."No.");

        // [GIVEN] Unit Cost on the standard journal line is updated to "Y".
        StandardItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDecInRange(20, 40, 2));

        // [WHEN] Item No. is re-validated on the standard item journal.
        StandardItemJournalLine.Validate("Item No.", Item."No.");

        // [THEN] Unit Amount is reset to "X".
        StandardItemJournalLine.TestField("Unit Amount", Item."Unit Cost");

        // [THEN] Amount is equal to "Q1" * "X".
        StandardItemJournalLine.TestField(Amount, Item."Unit Cost" * StandardItemJournalLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdJnlLinesZeroQuantity()
    var
        ItemJournalLine: Record "Item Journal Line";
        StandardItemJournalLine: Record "Standard Item Journal Line";
        StandardItemJournalCode: Code[10];
    begin
        // [SCENARIO 201724] "Quantity (Base)" and Amount in Standard Item Journal Line are zeroes if no check "Save Quantity" checkbox.
        // [FEATURE] [Standard Item Journal]
        Initialize();

        // [GIVEN] Item Journal Line "IJL" with populated Item "I" and some Quantity.
        CreateItemJournalLine(ItemJournalLine, LibraryInventory.CreateItemNo());

        // [WHEN] Save this "IJL" as Standard Item Journal through the report "Save as Standard Item Journal" and doesn't check the checkbox "Save Quantity"
        StandardItemJournalCode := SaveItemJournalLineAsNewStandardJournal(ItemJournalLine, false, false);

        // [THEN] Standard Item Journal Line "SIJL" is created for Item "I", fields Quantity, "Quantity (Base)" and Amount are zeroes.
        FindStandardItemJournalLine(StandardItemJournalLine, StandardItemJournalCode, ItemJournalLine."Item No.");
        StandardItemJournalLine.TestField(Quantity, 0);
        StandardItemJournalLine.TestField("Quantity (Base)", 0);
        StandardItemJournalLine.TestField(Amount, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RaiseBlockMovementErrorAll()
    var
        Bin: Record Bin;
    begin
        // [SCENARIO 209275] Bin Block Movement All raises error on inbound posting.
        // [FEATURE] [Transfer]
        Initialize();

        // [GIVEN] Location "FL", "Bin Mandatory" off;
        // [GIVEN] Location "TL", "Bin Mandatory" on, Bin "B" of "TL", "B"."Block Movement" = All;

        // [WHEN] Post Transfer "Item Journal Line" from "FL" to "TL", "New Bin Code" = "B"
        asserterror CreateAndPostTransferItemJournalLineToBlockedBin(Bin."Block Movement"::All);

        // [THEN] Error "Block Movement must not be All in Bin Location Code="TL",Code="B"." occurs.
        Assert.ExpectedError(
          StrSubstNo(FIELDERRORErr, Bin.FieldCaption("Block Movement"), Format(Bin."Block Movement"::All), Bin.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RaiseBlockMovementErrorInbound()
    var
        Bin: Record Bin;
    begin
        // [SCENARIO 209275] Bin Block Movement Inbound raises error on inbound posting.
        // [FEATURE] [Transfer]
        Initialize();

        // [GIVEN] Location "FL", "Bin Mandatory" off;
        // [GIVEN] Location "TL", "Bin Mandatory" on, Bin "B" of "TL", "B"."Block Movement" = Inbound;

        // [WHEN] Post Transfer "Item Journal Line" from "FL" to "TL", "New Bin Code" = "B"
        asserterror CreateAndPostTransferItemJournalLineToBlockedBin(Bin."Block Movement"::Inbound);

        // [THEN] Error "Block Movement must not be Inbound in Bin Location Code="TL",Code="B"." occurs.
        Assert.ExpectedError(
          StrSubstNo(FIELDERRORErr, Bin.FieldCaption("Block Movement"), Format(Bin."Block Movement"::Inbound), Bin.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CustomKeyIsResetInItemJournalBatchToPreventDoublePosting()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        LotNo: array[3] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 228096] Custom key is reset before posting item journal batch in order to prevent multiple posting of one line. This happens because a line can be split during posting, and NEXT function in a loop can find earlier posted line.
        Initialize();

        // [GIVEN] Lot-tracked item.
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Post item journal line for 30 pcs - 10 pcs per each lot "L1", "L2", "L3".
        SelectItemJournal(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 30);
        LibraryVariableStorage.Enqueue(3);
        for i := 1 to 3 do begin
            LotNo[i] := LibraryUtility.GenerateGUID();
            LibraryVariableStorage.Enqueue(LotNo[i]);
            LibraryVariableStorage.Enqueue(10);
        end;
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // [GIVEN] Item journal line for 10 pcs of lot "L1".
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", 10);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(LotNo[1]);
        LibraryVariableStorage.Enqueue(10);
        ItemJournalLine.OpenItemTrackingLines(false);

        // [GIVEN] Item journal line for 15 pcs - 10 pcs of lot "L2" and 5 pcs of lot "L3".
        // [GIVEN] This line will be split into two on posting according to the item tracking.
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", 15);
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue(LotNo[2]);
        LibraryVariableStorage.Enqueue(10);
        LibraryVariableStorage.Enqueue(LotNo[3]);
        LibraryVariableStorage.Enqueue(5);
        ItemJournalLine.OpenItemTrackingLines(false);

        // [WHEN] Sort item journal lines by quantity and post the batch.
        ItemJournalLine.SetCurrentKey(Quantity);
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);

        // [THEN] The item journal batch is posted. Resulting inventory - "L1" = 0, "L2" = 0, "L3" = 5 pcs.
        VerifyItemInventoryByLot(Item."No.", LotNo[1], 0);
        VerifyItemInventoryByLot(Item."No.", LotNo[2], 0);
        VerifyItemInventoryByLot(Item."No.", LotNo[3], 5);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure LookUpStandardItemJournalLineItemNo()
    var
        StandardItemJournal: Record "Standard Item Journal";
        StandardItemJournalPage: TestPage "Standard Item Journal";
        NonBlockedItemNo: Code[20];
    begin
        // [FEATURE] [UI] [Lookup] [Item] [Blocked] [Standard Item Journal]
        // [SCENARIO 278748] Stan doesn't see blocked items in Item List when he looks up Item No in Standard Item Journal
        Initialize();

        // [GIVEN] Two Items: Blocked and Non-Blocked
        NonBlockedItemNo := LibraryInventory.CreateItemNo();
        LibraryVariableStorage.Enqueue(StrSubstNo('%1|%2', CreateBlockedItem(), NonBlockedItemNo));
        LibraryVariableStorage.Enqueue(NonBlockedItemNo);

        // [GIVEN] Standard Item Journal
        CreateStandardItemJournal(StandardItemJournal);

        // [GIVEN] Stan opened page Standard Item Journal
        StandardItemJournalPage.OpenEdit();
        StandardItemJournalPage.GotoRecord(StandardItemJournal);

        // [WHEN] Stan Looks Up "Item No." in Standard Item Journal Subform
        StandardItemJournalPage.StdItemJnlLines."Item No.".Lookup();

        // [THEN] Page Item List opens
        // [THEN] Stan doesn't see Blocked Item on page Item List
        // [THEN] Stan sees Non-Blocked Item on page Item List
        // Verification is done in ItemListMPH
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJnlPostBatchResetsAutoCalcFields()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        SCMItemJournal: Codeunit "SCM Item Journal";
    begin
        // [FEATURE] [UT] [Batch] [Performance]
        // [SCENARIO 301026] COD 13 "Item Jnl.-Post Batch" resets auto calc fields
        Initialize();

        // [GIVEN] Item Journal Line with enabled auto calc fields for "Reserved Quantity" field
        SelectItemJournal(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", '', 0);
        ItemJournalLine.SetAutoCalcFields("Reserved Quantity");
        // [GIVEN] Linked "Reservation Entry" record with Quantity = 100
        MockReservationEntry(ReservationEntry, ItemJournalLine);
        // [GIVEN] Ensure "Item Journal Line"."Reserved Quantity" = 100 after FIND
        ItemJournalLine.Find();
        ItemJournalLine.TestField("Reserved Quantity");

        // [WHEN] Perform COD 13 "Item Jnl.-Post Batch".RUN()
        BindSubscription(SCMItemJournal);
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);

        // [THEN] Auto calc field is reset within COD23: "Reserved Quantity" = 0 after FIND
        // See [EventSubscriber] OnBeforeCode

        // Tear-down
        UnbindSubscription(SCMItemJournal);
        ReservationEntry.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcInvPhysInvWhenBlockedItem()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Calculate Inventory] [Blocked]
        // [SCENARIO 316985] Calculate Inventory report doesn't try to create lines for Blocked Items
        Initialize();

        // [GIVEN] Items "I1" and "I2" had stock
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandInt(10));
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", ItemJournalLine."Entry Type",
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Item "I1" was Blocked
        Item.Get(Item."No.");
        Item.Validate(Blocked, true);
        Item.Modify(true);
        Item.SetFilter("No.", '%1|%2', Item."No.", ItemJournalLine."Item No.");

        // [WHEN] Run report Calculate Inventory for both Items
        LibraryInventory.CalculateInventory(ItemJournalLine, Item, WorkDate(), false, false);

        // [THEN] Item Journal Line is created for Item "I2"
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
        ItemJournalLine.SetRange("Item No.", ItemJournalLine."Item No.");
        Assert.RecordCount(ItemJournalLine, 1);

        // [THEN] Item Journal Line is not created for Item "I1"
        ItemJournalLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(ItemJournalLine);
    end;

    [Test]
    procedure CalcInvPhysInvWhenBlockedItemVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Calculate Inventory] [Blocked]
        // [SCENARIO] Calculate Inventory report doesn't try to create lines for Blocked Item Variants
        Initialize();

        // [GIVEN] Items "I1" and "I2" had stock and item "I1" has variant "V1"
        LibraryInventory.CreateItemVariant(ItemVariant, LibraryInventory.CreateItem(Item));
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandInt(10));
        ItemJournalLine."Variant Code" := ItemVariant.Code;
        ItemJournalLine.Modify();

        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", ItemJournalLine."Entry Type",
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] ItemVariant "V1" is Blocked
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);
        Item.SetFilter("No.", '%1|%2', Item."No.", ItemJournalLine."Item No.");

        // [WHEN] Run report Calculate Inventory for both Items
        LibraryInventory.CalculateInventory(ItemJournalLine, Item, WorkDate(), false, false);

        // [THEN] Item Journal Line is created for Item "I2"
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
        ItemJournalLine.SetRange("Item No.", ItemJournalLine."Item No.");
        Assert.RecordCount(ItemJournalLine, 1);

        // [THEN] Item Journal Line is not created for Item "I1" and variant "V1"
        ItemJournalLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(ItemJournalLine);
    end;


    [Test]
    [HandlerFunctions('ItemLedgerEntriesLookupMultipleModalPageHandler')]
    [Scope('OnPrem')]
    procedure ShowPositiveEntriesOnApplyToEntryLookupWhenItemJournalLineQtyIsZero()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntryNo: Integer;
        NextValue: Boolean;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [UT] [UI] [Applies-to Entry]
        // [SCENARIO 338231] "Applies-to Entry" field lookup shows Item Ledger entries with no filter on "Positive" when Item Reclassification Journal line quantity is = 0
        Initialize();
        ItemLedgerEntry.DeleteAll();

        // [GIVEN] Item with inventory stock, e.g. "positive" and Open Item Ledger Entry
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateItemWithInventory(Item, Location.Code, LibraryRandom.RandIntInRange(15, 20));

        // [GIVEN] Item negative adjustment, e.g. "negative" and Open Item Ledger Entry
        MockNegativeOpenItemLedgerEntry(Item."No.", Location.Code, -LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Item Reclassification Journal line populated with Item and Location with Quantity = 0
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Transfer);
        DocumentNo :=
          CreateItemReclassJournaLine(
            ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, Item."No.", Location.Code, Location.Code, '', '', 0);

        // [WHEN] Lookup on "Applies-to Entry" in Item Reclassification Journal line
        Commit();
        ItemReclassJournalPageLookupAtAppliesToEntry(ItemJournalBatch.Name, DocumentNo, Item."No.");

        // [THEN] Item Ledger Entries lookup page shows "positive" and "negative" Item Ledger Entries
        ItemLedgerEntryNo := LibraryVariableStorage.DequeueInteger();
        VerifyItemLedgerEntryPositive(ItemLedgerEntryNo, false);

        NextValue := LibraryVariableStorage.DequeueBoolean();
        Assert.IsTrue(NextValue, MultipleEntriesExpectedErr);

        ItemLedgerEntryNo := LibraryVariableStorage.DequeueInteger();
        VerifyItemLedgerEntryPositive(ItemLedgerEntryNo, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemLedgerEntriesLookupSingleModalPageHandler')]
    [Scope('OnPrem')]
    procedure ShowPositiveEntriesOnApplyToEntryLookupWhenItemJournaLineQtyIsPositive()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntryNo: Integer;
        NextValue: Boolean;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [UT] [UI] [Applies-to Entry]
        // [SCENARIO 338231] "Applies-to Entry" field lookup shows Item Ledger entries with "Positive" = TRUE value when Item Reclassification Journal line quantity is positive
        Initialize();
        ItemLedgerEntry.DeleteAll();

        // [GIVEN] Item with inventory stock, e.g. "positive" and Open Item Ledger Entry
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateItemWithInventory(Item, Location.Code, LibraryRandom.RandIntInRange(15, 20));

        // [GIVEN] Item negative adjustment, e.g. "negative" and Open Item Ledger Entry
        MockNegativeOpenItemLedgerEntry(Item."No.", Location.Code, -LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Item Reclassification Journal line populated with Item and Location with Quantity = 3
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Transfer);
        DocumentNo :=
          CreateItemReclassJournaLine(
            ItemJournalBatch."Journal Template Name",
            ItemJournalBatch.Name, Item."No.",
            Location.Code, Location.Code, '', '', LibraryRandom.RandIntInRange(2, 3));

        // [WHEN] Lookup on "Applies-to Entry" in Item Reclassification Journal line
        Commit();
        ItemReclassJournalPageLookupAtAppliesToEntry(ItemJournalBatch.Name, DocumentNo, Item."No.");

        // [THEN] Item Ledger Entries lookup page shows "positive" Item Ledger Entry only
        ItemLedgerEntryNo := LibraryVariableStorage.DequeueInteger();
        VerifyItemLedgerEntryPositive(ItemLedgerEntryNo, true);

        NextValue := LibraryVariableStorage.DequeueBoolean();
        Assert.IsFalse(NextValue, OneEntryExpectedErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemLedgerEntriesLookupSingleModalPageHandler')]
    [Scope('OnPrem')]
    procedure ShowPositiveEntriesOnApplyToEntryLookupWhenItemJournaLineQtyIsNegative()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntryNo: Integer;
        NextValue: Boolean;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [UT] [UI] [Applies-to Entry]
        // [SCENARIO 338231] "Applies-to Entry" field lookup shows Item Ledger entries with "Positive" = FALSE value when Item Reclassification Journal line quantity is negative
        Initialize();
        ItemLedgerEntry.DeleteAll();

        // [GIVEN] Item with inventory stock, e.g. "positive" and Open Item Ledger Entry
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateItemWithInventory(Item, Location.Code, LibraryRandom.RandIntInRange(15, 20));

        // [GIVEN] Item negative adjustment, e.g. "negative" and Open Item Ledger Entry
        MockNegativeOpenItemLedgerEntry(Item."No.", Location.Code, -LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Item Reclassification Journal line populated with Item and Location with Quantity = -2
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Transfer);
        DocumentNo :=
          CreateItemReclassJournaLine(
            ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
            Item."No.", Location.Code, Location.Code, '', '', -LibraryRandom.RandIntInRange(2, 3));

        // [WHEN] Lookup on "Applies-to Entry" in Item Reclassification Journal line
        Commit();
        ItemReclassJournalPageLookupAtAppliesToEntry(ItemJournalBatch.Name, DocumentNo, Item."No.");

        // [THEN] Item Ledger Entries lookup page shows "negative" Item Ledger Entry only
        ItemLedgerEntryNo := LibraryVariableStorage.DequeueInteger();
        VerifyItemLedgerEntryPositive(ItemLedgerEntryNo, false);

        NextValue := LibraryVariableStorage.DequeueBoolean();
        Assert.IsFalse(NextValue, OneEntryExpectedErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EntryTypeOutputCannotBeUsedOnItemJournalTemplateTypeItem()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournal: TestPage "Item Journal";
    begin
        // [SCENARIO 202372] Unit Cost cannot be changed on item journal line for an item with Costing Method = Standard.
        Initialize();

        // prevent modal page handler requirement for some countries
        ItemJournalTemplate.SetRange(Type, "Item Journal Template Type"::Item);
        if ItemJournalTemplate.Count > 1 then
            exit;

        // [GIVEN] Item "I" with Costing Method = "Standard" and Unit Cost = "X".
        CreateItemWithCostingMethod(Item, Item."Costing Method"::Standard);

        // [GIVEN] Create output item journal line directly, as UI does not allow this entry type
        CreateItemJournalLine(ItemJournalLine, Item."No.");
        ItemJournalLine.Validate("Entry Type", "Item ledger Entry Type"::Output);
        ItemJournalLine.Modify();

        // [WHEN] Open Item Journal page and create new line
        ItemJournal.OpenEdit();
        ItemJournal.GotoRecord(ItemJournalLine);
        ItemJournal.New();

        // [THEN] Check if entry type in new line is Purchase
        Assert.AreEqual(ItemJournal."Entry Type".AsInteger(), "Item Journal Entry Type"::Purchase.AsInteger(), 'Entry type should be Purchase.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputJournalCanUseScrapCodeForMachineCenter()
    begin
        // [SCENARIO 453592] Scrap Code can be entered in Output Journal for Capacity Type = Machine Center
        ValidateScrapCodeForOutputJournal("Capacity Type Journal"::"Machine Center", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputJournalCanUseScrapCodeForWorkCenter()
    begin
        // [SCENARIO 453592] Scrap Code can be entered in Output Journal for Capacity Type = Work Center
        ValidateScrapCodeForOutputJournal("Capacity Type Journal"::"Work Center", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputJournalCanNotUseScrapCodeForResource()
    begin
        // [SCENARIO 453592] Scrap Code can be entered in Output Journal for Capacity Type = Resource
        ValidateScrapCodeForOutputJournal("Capacity Type Journal"::"Resource", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputJournalCanNotUseScrapCodeWithoutCapacityType()
    begin
        // [SCENARIO 453592] Scrap Code can be entered in Output Journal without Capacity Type
        ValidateScrapCodeForOutputJournal("Capacity Type Journal"::" ", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseQtyIsRoundedTo0OnItemJournalLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Item Journal - Rounding Precision]
        // [SCENARIO] Error is thrown when rounding precision causes the base quantity to be rounded to 0.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandIntInRange(2, 10), QtyRoundingPrecision);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, 1);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Item Journal Line where the unit of measure code is set to the non-base unit of measure.
        CreateItemJournalLine(ItemJournalLine, Item."No.");
        ItemJournalLine.Validate("Unit of Measure Code", NonBaseUOM.Code);

        // [WHEN] Quantity is set to a value that rounds the base quantity to 0
        asserterror ItemJournalLine.Validate(Quantity, 1 / LibraryRandom.RandIntInRange(300, 1000));

        // [THEN] Error is thrown
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionSpecifiedOnItemJournalLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
        QtyToSet: Decimal;
    begin
        // [FEATURE] [Item Journal - Rounding Precision]
        // [SCENARIO] Quantity (Base) is rounded with the specified rounding precision.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandIntInRange(2, 10), QtyRoundingPrecision);
        QtyToSet := LibraryRandom.RandDecInRange(2, 10, 2);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, 1);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Item Journal Line where the unit of measure code is set to the non-base unit of measure.
        CreateItemJournalLine(ItemJournalLine, Item."No.");
        ItemJournalLine.Validate("Unit of Measure Code", NonBaseUOM.Code);

        // [WHEN] Quantity is set to a value that rounds the base quantity to 0
        ItemJournalLine.Validate(Quantity, QtyToSet);

        // [THEN] Quantity (Base) is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, QtyRoundingPrecision), ItemJournalLine."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionUnspecifiedOnItemJournalLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyToSet: Decimal;
    begin
        // [FEATURE] [Item Journal - Rounding Precision]
        // [SCENARIO] Quantity (Base) is rounded with the default rounding precision when rounding precision is not specified.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        NonBaseQtyPerUOM := LibraryRandom.RandIntInRange(2, 10);
        QtyToSet := LibraryRandom.RandDecInRange(2, 10, 7);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, 1);
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Item Journal Line where the unit of measure code is set to the non-base unit of measure.
        CreateItemJournalLine(ItemJournalLine, Item."No.");
        ItemJournalLine.Validate("Unit of Measure Code", NonBaseUOM.Code);

        // [WHEN] Quantity is set to a value that rounds the base quantity to 0
        ItemJournalLine.Validate(Quantity, QtyToSet);

        // [THEN] Quantity (Base) is rounded with the default rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, 0.00001), ItemJournalLine."Quantity (Base)", 'Base qty. is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionOnItemJournalLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
        QtyToSet: Decimal;
    begin
        // [FEATURE] [Item Journal - Rounding Precision]
        // [SCENARIO] Quantity (Base) is rounded with the specified rounding precision.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandIntInRange(5, 10), QtyRoundingPrecision);
        QtyToSet := LibraryRandom.RandDecInRange(2, 10, 7);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, 1);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Item Journal Line where the unit of measure code is set to the non-base unit of measure.
        CreateItemJournalLine(ItemJournalLine, Item."No.");
        ItemJournalLine.Validate("Unit of Measure Code", NonBaseUOM.Code);

        // [WHEN] Quantity is set to a value that rounds the base quantity to 0
        ItemJournalLine.Validate(Quantity, (NonBaseQtyPerUOM - 1) / NonBaseQtyPerUOM);

        // [THEN] Quantity (Base) is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM - 1, QtyRoundingPrecision),
                        ItemJournalLine."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseQtyIsRoundedTo0OnStandardItemJournalLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        StandardItemJournalLine: Record "Standard Item Journal Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
        StandardItemJournalCode: Code[10];
    begin
        // [FEATURE] [Standard Item Journal - Rounding Precision]
        // [SCENARIO] Error is thrown when rounding precision causes the base quantity to be rounded to 0.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandIntInRange(2, 10), QtyRoundingPrecision);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, 1);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Item Journal Line where the unit of measure code is set to the non-base unit of measure.
        CreateItemJournalLine(ItemJournalLine, Item."No.");
        ItemJournalLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        ItemJournalLine.Modify(true);

        // [GIVEN] The item journal line is saved as standard journal line.
        StandardItemJournalCode := SaveItemJournalLineAsNewStandardJournal(ItemJournalLine, true, true);
        FindStandardItemJournalLine(StandardItemJournalLine, StandardItemJournalCode, Item."No.");

        // [WHEN] Quantity is set to a value that rounds the base quantity to 0
        asserterror StandardItemJournalLine.Validate(Quantity, 1 / LibraryRandom.RandIntInRange(300, 1000));

        // [THEN] Error is thrown
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionSpecifiedOnStandardItemJournalLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        StandardItemJournalLine: Record "Standard Item Journal Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
        QtyToSet: Decimal;
        StandardItemJournalCode: Code[10];
    begin
        // [FEATURE] [Standard Item Journal - Rounding Precision]
        // [SCENARIO] Quantity (Base) is rounded with the specified rounding precision.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandIntInRange(2, 10), QtyRoundingPrecision);
        QtyToSet := LibraryRandom.RandDecInRange(2, 10, 2);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, 1);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Item Journal Line where the unit of measure code is set to the non-base unit of measure.
        CreateItemJournalLine(ItemJournalLine, Item."No.");
        ItemJournalLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        ItemJournalLine.Modify(true);

        // [GIVEN] The item journal line is saved as standard journal line.
        StandardItemJournalCode := SaveItemJournalLineAsNewStandardJournal(ItemJournalLine, true, true);
        FindStandardItemJournalLine(StandardItemJournalLine, StandardItemJournalCode, Item."No.");

        // [WHEN] Quantity is set to a value that rounds the base quantity to 0
        StandardItemJournalLine.Validate(Quantity, QtyToSet);

        // [THEN] Quantity (Base) is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, QtyRoundingPrecision), StandardItemJournalLine."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionUnspecifiedOnStandardItemJournalLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        StandardItemJournalLine: Record "Standard Item Journal Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyToSet: Decimal;
        StandardItemJournalCode: Code[10];
    begin
        // [FEATURE] [Standard Item Journal - Rounding Precision]
        // [SCENARIO] Quantity (Base) is rounded with the default rounding precision when rounding precision is not specified.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        NonBaseQtyPerUOM := LibraryRandom.RandIntInRange(2, 10);
        QtyToSet := LibraryRandom.RandDecInRange(2, 10, 7);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, 1);
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Item Journal Line where the unit of measure code is set to the non-base unit of measure.
        CreateItemJournalLine(ItemJournalLine, Item."No.");
        ItemJournalLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        ItemJournalLine.Modify(true);

        // [GIVEN] The item journal line is saved as standard journal line.
        StandardItemJournalCode := SaveItemJournalLineAsNewStandardJournal(ItemJournalLine, true, true);
        FindStandardItemJournalLine(StandardItemJournalLine, StandardItemJournalCode, Item."No.");

        // [WHEN] Quantity is set to a value that rounds the base quantity to 0
        StandardItemJournalLine.Validate(Quantity, QtyToSet);

        // [THEN] Quantity is rounded with the default rounding precision
        Assert.AreEqual(Round(QtyToSet, 0.00001), StandardItemJournalLine.Quantity, 'Qty. is not rounded correctly.');

        // [THEN] Quantity (Base) is rounded with the default rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * StandardItemJournalLine.Quantity, 0.00001),
                        StandardItemJournalLine."Quantity (Base)", 'Base qty. is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionOnStandardItemJournalLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        StandardItemJournalLine: Record "Standard Item Journal Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
        StandardItemJournalCode: Code[10];
    begin
        // [FEATURE] [Standard Item Journal - Rounding Precision]
        // [SCENARIO] Quantity (Base) is rounded with the specified rounding precision.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandIntInRange(5, 10), QtyRoundingPrecision);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, 1);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Item Journal Line where the unit of measure code is set to the non-base unit of measure.
        CreateItemJournalLine(ItemJournalLine, Item."No.");
        ItemJournalLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        ItemJournalLine.Modify(true);

        // [GIVEN] The item journal line is saved as standard journal line.
        StandardItemJournalCode := SaveItemJournalLineAsNewStandardJournal(ItemJournalLine, true, true);
        FindStandardItemJournalLine(StandardItemJournalLine, StandardItemJournalCode, Item."No.");

        // [WHEN] Quantity is set to a value that rounds the base quantity to 0
        StandardItemJournalLine.Validate(Quantity, (NonBaseQtyPerUOM - 1) / NonBaseQtyPerUOM);


        // [THEN] Quantity (Base) is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM - 1, QtyRoundingPrecision),
                        StandardItemJournalLine."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    procedure ConsumptionJournalLocationForNonInventoryItemsAllowed()
    var
        Item: Record Item;
        Item2: Record Item;
        NonInventoryItem: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO]
        Initialize();

        // [GIVEN] A non-inventory item.
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        // [GIVEN] A location.
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A released production order.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", 1);
        LibraryManufacturing.CreateProdOrderLine(
            ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrder."No.", Item2."No.", '', Location.Code, 1);

        // [GIVEN] Consumptiom item journal line for the non-inventory item with location set.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(
            ItemJournalBatch, ItemJournalTemplate.Type::Consumption, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);

        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine,
          ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Consumption,
          NonInventoryItem."No.",
          1
        );
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("Order No.", ProductionOrder."No.");
        ItemJournalLine.Modify(true);

        // [WHEN] Posting the item journal line.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] An item ledger entry is created for non-inventory items with location set.
        ItemLedgerEntry.SetRange("Item No.", NonInventoryItem."No.");
        Assert.AreEqual(1, ItemLedgerEntry.Count, 'Expected only one ILE to be created.');
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(-1, ItemLedgerEntry.Quantity, 'Expected quantity to be -1.');
        Assert.AreEqual(Location.Code, ItemLedgerEntry."Location Code", 'Expected location to be set.');
    end;

    [Test]
    procedure ConsumptionJournalBinCodeNotAllowedForNonInventoryItems()
    var
        Item: Record Item;
        NonInventoryItem: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine1: Record "Item Journal Line";
        ItemJournalLine2: Record "Item Journal Line";
    begin
        // [SCENARIO]
        Initialize();

        // [GIVEN] A non-inventory item and item.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        // [GIVEN] A location with require bin and a default bin code.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        LibraryWarehouse.CreateBinContent(
            BinContent, Bin."Location Code", '', Bin.Code, Item."No.", '', Item."Base Unit of Measure"
        );
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
        Location.Validate("Default Bin Code", Bin.Code);
        Location.Modify(true);

        // [GIVEN] Consumptiom item journal line for the non-inventory item and item with location set.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(
            ItemJournalBatch, ItemJournalTemplate.Type::Consumption, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);

        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine1,
          ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name,
          ItemJournalLine1."Entry Type"::Consumption,
          NonInventoryItem."No.",
          LibraryRandom.RandInt(10)
        );
        ItemJournalLine1.Validate("Location Code", Location.Code);
        ItemJournalLine1.Modify(true);

        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine2,
          ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name,
          ItemJournalLine2."Entry Type"::Consumption,
          Item."No.",
          LibraryRandom.RandInt(10)
        );
        ItemJournalLine2.Validate("Location Code", Location.Code);
        ItemJournalLine2.Modify(true);

        // [THEN] Bin code is set for item.
        Assert.AreEqual('', ItemJournalLine1."Bin Code", 'Expected no bin code set');
        Assert.AreEqual(Bin.Code, ItemJournalLine2."Bin Code", 'Expected bin code to be set');

        // [WHEN] Setting bin code on non-inventory item.
        asserterror ItemJournalLine1.Validate("Bin Code", Bin.Code);

        // [THEN] An error is thrown.
    end;

    [Test]
    procedure CheckingForIncorrectQtyOnItemJournalWithSerialNoSpecified()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 459403] Check that abs(quantity) is not greater than 1 when serial no. is stated on item journal line.
        Initialize();

        LibraryItemTracking.CreateSerialItem(Item);
        CreateItemJournalLineWithItemTrackingOnLines(ItemJournalLine, Item."No.");
        ItemJournalLine.Validate(Quantity, 2);
        ItemJournalLine.Modify(true);
        Commit();

        asserterror ItemJournalLine.Validate("Serial No.", LibraryUtility.GenerateGUID());
        Assert.ExpectedError('-1');

        ItemJournalLine.Validate(Quantity, 1);
        ItemJournalLine.Validate("Serial No.", LibraryUtility.GenerateGUID());

        asserterror ItemJournalLine.Validate(Quantity, 2);
        Assert.ExpectedError('-1');
    end;

    [Test]
    procedure CannotUpdateItemTrackingOnLineWhenReservEntryExists()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 459403] Cannot update serial no., lot no., package no., expiration date or warranty date on item journal line if item tracking exists.
        Initialize();

        LibraryItemTracking.CreateLotItem(Item);
        CreateItemJournalLineWithItemTrackingOnLines(ItemJournalLine, Item."No.");
        LibraryItemTracking.CreateItemJournalLineItemTracking(
          ReservationEntry, ItemJournalLine, '', LibraryUtility.GenerateGUID(), ItemJournalLine.Quantity);
        Commit();

        asserterror ItemJournalLine.Validate("Lot No.", LibraryUtility.GenerateGUID());
        Assert.ExpectedError(ItemJournalLine.FieldCaption("Lot No."));

        asserterror ItemJournalLine.Validate("Serial No.", LibraryUtility.GenerateGUID());
        Assert.ExpectedError(ItemJournalLine.FieldCaption("Serial No."));

        asserterror ItemJournalLine.Validate("Package No.", LibraryUtility.GenerateGUID());
        Assert.ExpectedError(ItemJournalLine.FieldCaption("Package No."));

        asserterror ItemJournalLine.Validate("Expiration Date", LibraryRandom.RandDate(30));
        Assert.ExpectedError(ItemJournalLine.FieldCaption("Expiration Date"));

        asserterror ItemJournalLine.Validate("Warranty Date", LibraryRandom.RandDate(30));
        Assert.ExpectedError(ItemJournalLine.FieldCaption("Warranty Date"));
    end;

    [Test]
    procedure RecordLinkDeletedAfterPostingItemJnlLine()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RecordLink: Record "Record Link";
    begin
        // [FEATURE] [Record Link]
        // [SCENARIO] Record links are deleted after posting an item journal line

        Initialize();

        // [GIVEN] Item journal line
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.FindItemJournalBatch(ItemJournalBatch, ItemJournalTemplate);
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.",
            LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Assign a record link to the journal line
        LibraryUtility.CreateRecordLink(ItemJournalLine);

        // [WHEN] Post the journal
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);

        // [THEN] The record link is deleted
        RecordLink.SetRange("Record ID", ItemJournalLine.RecordId);
        Assert.RecordIsEmpty(RecordLink);
    end;

    [Test]
    procedure BinContentMovementBlockedThrowsErrorWhenPostingItemJournal()
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
    begin
        // [SCENARIO 538864] Bin Content Block Movement is considered when posting an Item Journal.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Location with require Bin and a Default Bin Code.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');

        // [GIVEN] Validate Default Bin Code in Location.
        Location.Validate("Default Bin Code", Bin.Code);
        Location.Modify(true);

        // [GIVEN] Select an Item Journal Template of Type Item.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);

        // [GIVEN] Select an Item Journal Batch.
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);

        // [GIVEN] Create an Item Journal Line
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine,
          ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Purchase,
          Item."No.",
          LibraryRandom.RandInt(10));

        // [GIVEN] Validate Location Code and Bin Code in Item Journal Line.
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("Bin Code", Bin.Code);
        ItemJournalLine.Modify(true);

        // [GIVEN] Post an Item Journal.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Find Bin Content and Validate Block Movement to All.
        BinContent.SetRange("Bin Code", Bin.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.FindFirst();
        BinContent.Validate("Block Movement", BinContent."Block Movement"::All);
        BinContent.Modify(true);

        // [GIVEN] Clear an Item Journal
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);

        // [GIVEN] Create an Item Journal and Validate Location Code.
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine,
          ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Purchase,
          Item."No.",
          LibraryRandom.RandInt(10));
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Modify(true);

        // [WHEN] Post an Item Journal.
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Error of Bin Content Movement blocked is raised.
        Assert.ExpectedError(StrSubstNo(BlockedBinContentErr, ItemJournalLine."Location Code", ItemJournalLine."Bin Code", ItemJournalLine."Item No.", ItemJournalLine."Variant Code", ItemJournalLine."Unit of Measure Code"));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    procedure ItemReclassGenerateNegativeAndPositiveWeightinSequenceInWshEntry()
    var
        Item: Record Item;
        Location: Record Location;
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJnlTemplate: Record "Item Journal Template";
        ItemUnitofMeasure: Record "Item Unit of Measure";
        BinCode: array[2] of Code[20];
        LotNo: Code[10];
        Qty: Integer;
    begin
        // [SCENARIO 557303] Item Reclass Journal generates negative and then positive weight in Warehouse Entry. 
        Initialize();

        // [GIVEN] Create a Location with two bin and "Bin Capacity Policy" = "Allow More Than Max. Capacity".
        CreateLocationWithBinAndCapicityPolicy(Location, 1, BinCode[1], BinCode[2]);

        // [GIVEN] Create an Item with lot No.
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Update the weight of Item Unit of Measure.
        ItemUnitofMeasure.Get(Item."No.", Item."Base Unit of Measure");
        ItemUnitofMeasure.Weight := LibraryRandom.RandInt(100);
        ItemUnitofMeasure.Modify(true);

        // [GIVEN] Create an Item Journal Template and Item Journal Batch.
        LibraryInventory.CreateItemJournalTemplate(ItemJnlTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJnlBatch, ItemJnlTemplate.Name);

        // [GIVEN] Set Qty and LotNo variables.
        Qty := LibraryRandom.RandInt(10);
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Create a Positive Adjustment for the Item using first bin code and location.
        CreateItemJnlWithLocationAndBin(
            ItemJournalLine, ItemJnlTemplate.Name, ItemJnlBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.",
            Location.Code, '', BinCode[1], '', Item."No.", Qty);

        // [GIVEN] Enqueue lotNo and Qty.
        EnqueItrLotQty(1, LotNo, Qty);

        // [GIVEN] Open item tracking line.
        ItemJournalLine.OpenItemTrackingLines(false);

        // [GIVEN] Post the Positive Adjustment Journal.
        LibraryInventory.PostItemJournalLine(ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name);

        // [GIVEN] Create Item Rclassification Journal using same Item, Quantity, location and "lot No." whereas "New Bin Code"= Bincode[2].
        CreateItemJnlWithLocationAndBin(
           ItemJournalLine, ItemJnlTemplate.Name, ItemJnlBatch.Name, ItemJournalLine."Entry Type"::Transfer,
           Location.Code, Location.Code, BinCode[1], BinCode[2], Item."No.", Qty);

        // [GIVEN] Enqueue LotNo and Qty.
        EnqueItrLotQty(1, LotNo, Qty);

        // [GIVEN] Open item tracking line for Item Reclassification Journal.
        ItemJournalLine.OpenItemTrackingLines(true);

        // [WHEN] Posting the Item Reclassification Journal.
        LibraryInventory.PostItemJournalLine(ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name);

        // [THEN] Verify that Item Reclassification Journal generates two warehouse entries, first with a negative weight and second with a positive. Also, the Quantity and Weight should have the same sign in the warehouse entry (Positive weight for a positive qty and negative weight for a negative qty).
        VerifyWshEntryforItemReclassJournal(Item."No.", LotNo, ItemUnitofMeasure.Weight);
    end;

    [Test]
    procedure InitValueOfTypeFieldOnItemJournalLine()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] Init value of the Type field on Item Journal Line is <blank>.
        Initialize();

        ItemJournalLine.Init();
        ItemJournalLine.TestField(Type, ItemJournalLine.Type::" ");
    end;

    [Test]
    procedure TestSequenceNumbers()
    var
        InventorySetup: Record "Inventory Setup";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ItemRegister: Record "Item Register";
        SequenceNoMgt: codeunit "Sequence No. Mgt.";
        CurrentItemLedgerEntryNo: Integer;
    begin
        if InventorySetup.UseLegacyPosting() then
            exit; // Test is not applicable for legacy posting.
        // Posting Item Journal and Verifying Item Ledger Entries.
        Initialize();

        // Setup: Create Item Journal with Entry Type Positive Adjustment.
        CreateItemJournal(ItemJournalLine);
        CurrentItemLedgerEntryNo := ItemLedgerEntry.GetLastEntryNo();

        // Exercise: Post Item Journal.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Verify Item Ledger Entry.
        Assert.IsTrue(SequenceNoMgt.GetCurrentSeqNo(Database::"Item Ledger Entry") > CurrentItemLedgerEntryNo, 'Item Ledger Entry Sequence No. is not updated.');
        ItemRegister.FindLast();
        ItemLedgerEntry.SetRange("Entry No.", CurrentItemLedgerEntryNo + 1, SequenceNoMgt.GetCurrentSeqNo(Database::"Item Ledger Entry"));
        if ItemLedgerEntry.FindSet() then
            repeat
                Assert.AreEqual(ItemRegister."No.", ItemLedgerEntry."Item Register No.", 'Item Ledger Entry is not created for the correct Register.');
                Assert.AreEqual(ItemRegister."No." mod 5, ItemLedgerEntry."SIFT Bucket No.", 'Sift Bucket is not created for the correct Register.');
            until ItemLedgerEntry.Next() = 0;

        ValueEntry.SetRange("Entry No.", ItemRegister."From Value Entry No.", ItemRegister."To Value Entry No.");
        if ValueEntry.FindSet() then
            repeat
                Assert.AreEqual(ItemRegister."No.", ValueEntry."Item Register No.", 'Value Entry is not created for the correct Register.');
                Assert.AreEqual(ItemRegister."No." mod 5, ValueEntry."SIFT Bucket No.", 'Value Entry.Sift Bucket is not created for the correct Register.');
            until ValueEntry.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ItemJournalConfirmHandler,MessageHandler')]
    procedure ItemJournalBatchPagePostWithInvalidLine()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalBatchEmpty: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplates: TestPage "Item Journal Templates";
        ItemJournalBatches: TestPage "Item Journal Batches";
    begin
        // [FEATURE] [Item Journal Batch]
        // [SCENARIO 557366] Posting item journal batch with an invalid line fails and sets the filter to the failed batch.
        Initialize();

        // [GIVEN] Two item journal batches - "A" and "B".
        // [GIVEN] Create an item journal line in batch "A" and leave the other empty.
        // [GIVEN] The item journal line cannot be posted because of the missing document no.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatchEmpty, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        ItemJournalLine.Validate("Document No.", '');
        ItemJournalLine.Modify(true);

        Commit();

        // [WHEN] Open the item journal batch page and post the batch "A".
        ItemJournalTemplates.OpenEdit();
        ItemJournalTemplates.GotoRecord(ItemJournalTemplate);
        ItemJournalBatches.Trap();
        ItemJournalTemplates.Batches.Invoke();

        ItemJournalBatches.GotoRecord(ItemJournalBatch);
        ItemJournalBatches."P&ost".Invoke();

        // [THEN] The posting fails and the filter is set to the batch "A" with error.
        // [THEN] The batch "B" is hidden now.
        Assert.IsTrue(ItemJournalBatches.GoToRecord(ItemJournalBatch), 'Item Journal Batch page is not filtered to the batch with error.');
        Assert.IsFalse(ItemJournalBatches.GoToRecord(ItemJournalBatchEmpty), 'Item Journal Batch page is not filtered to the batch with error.');

        // [THEN] The "Failed to Post On/Off" action clears the filter and the batch "B" becomes visible again.
        ItemJournalBatches.FailedToPostOnOff.Invoke();
        Assert.IsTrue(ItemJournalBatches.GoToRecord(ItemJournalBatch), 'Item Journal Batch filters are not reset.');
    end;

    [Test]
    [HandlerFunctions('ItemJournalConfirmHandler,MessageHandler')]
    procedure OnlySelectedItemJournalBatchIsPosted()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: array[2] of Record "Item Journal Batch";
        ItemJournalLine: array[2] of Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJournalTemplates: TestPage "Item Journal Templates";
        ItemJournalBatches: TestPage "Item Journal Batches";
        i: Integer;
    begin
        // [FEATURE] [Item Journal Batch]
        // [SCENARIO 557366] Post action on Item Journal Batch page posts only the selected batch.
        Initialize();

        // [GIVEN] Two item journal batches - "B1" and "B2".
        // [GIVEN] Create an item journal line in each batch.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        for i := 1 to 2 do begin
            LibraryInventory.CreateItemJournalBatch(ItemJournalBatch[i], ItemJournalTemplate.Name);
            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine[i], ItemJournalBatch[i]."Journal Template Name",
              ItemJournalBatch[i].Name, ItemJournalLine[i]."Entry Type"::"Positive Adjmt.", LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        end;

        Commit();

        // [WHEN] Open the item journal batch page and post the batch "A".
        ItemJournalTemplates.OpenEdit();
        ItemJournalTemplates.GotoRecord(ItemJournalTemplate);
        ItemJournalBatches.Trap();
        ItemJournalTemplates.Batches.Invoke();

        ItemJournalBatches.GotoRecord(ItemJournalBatch[1]);
        ItemJournalBatches."P&ost".Invoke();

        // [THEN] The posting succeeds so no batches are hidden.
        Assert.IsTrue(ItemJournalBatches.GoToRecord(ItemJournalBatch[1]), 'Unexpected filter on Item Journal Batch page.');
        Assert.IsTrue(ItemJournalBatches.GoToRecord(ItemJournalBatch[2]), 'Unexpected filter on Item Journal Batch page.');

        // [THEN] The item from batch "A" is posted.
        ItemLedgerEntry.SetRange("Item No.", ItemJournalLine[1]."Item No.");
        Assert.RecordIsNotEmpty(ItemLedgerEntry, '');

        // [THEN] The item from batch "B" is not posted.
        ItemLedgerEntry.SetRange("Item No.", ItemJournalLine[2]."Item No.");
        Assert.RecordIsEmpty(ItemLedgerEntry, '');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Item Journal");
        LibraryRandom.Init();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Item Journal");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Item Journal");
    end;

    local procedure CreateAndPostTransferItemJournalLineToBlockedBin(BlockMovement: Option)
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        Bin: Record Bin;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        CreateLocationWithBinBlockMovement(ToLocation, Bin, BlockMovement);
        Quantity := LibraryRandom.RandInt(100);
        CreateItemWithInventory(Item, FromLocation.Code, Quantity);
        CreateTransferItemJournalLine(ItemJournalLine, Item."No.", FromLocation.Code, '', ToLocation.Code, Bin.Code, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure UpdateSalesReceivableSetup(StockoutWarning: Boolean) OldStockoutWarning: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldStockoutWarning := SalesReceivablesSetup."Stockout Warning";
        SalesReceivablesSetup.Validate("Stockout Warning", StockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure SelectItemJournal(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure CreateStdJournalSetup(var TempItemJournalLine: Record "Item Journal Line" temporary; var ItemJournalBatch: Record "Item Journal Batch"; NoOfItems: Integer; SaveAsStandard: Boolean) StandardItemJournalCode: Code[10]
    var
        TempItem: Record Item temporary;
    begin
        // Create Items, Item Journal and Save Item Journal as Standard Journal.
        CreateItemsAndCopyToTemp(TempItem, NoOfItems);
        StandardItemJournalCode := CreateItemJournalAndCopyToTemp(TempItemJournalLine, TempItem, ItemJournalBatch, SaveAsStandard);
    end;

    local procedure CreateItemsAndCopyToTemp(var TempItem: Record Item temporary; NoOfItems: Integer)
    var
        Item: Record Item;
        Counter: Integer;
    begin
        for Counter := 1 to NoOfItems do begin
            Clear(Item);
            CreateItem(Item);
            TempItem := Item;
            TempItem.Insert();
        end;
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        UpdateItemCost(Item);
    end;

    local procedure CreateItemWithCostingMethod(var Item: Record Item; CostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, 0, LibraryRandom.RandDec(10, 2));
        Item.Validate("Costing Method", CostingMethod);
        Item.Modify(true);
    end;

    local procedure CreateItemWithInventory(var Item: Record Item; LocationCode: Code[10]; InventoryQuantity: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        UpdateInventory(Item."No.", LocationCode, InventoryQuantity);
    end;

    local procedure CreateBlockedItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Blocked, true);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateStandardItemJournal(var StandardItemJournal: Record "Standard Item Journal")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryERM.CreateStandardItemJournal(StandardItemJournal, ItemJournalTemplate.Name);
    end;

    local procedure CreateItemJournal(var ItemJournalLine: Record "Item Journal Line")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        CreateItemJournalLine(ItemJournalLine, Item."No.");
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectItemJournal(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreateItemJournalLineWithItemTrackingOnLines(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectItemJournal(ItemJournalBatch);
        ItemJournalBatch."Item Tracking on Lines" := true;
        ItemJournalBatch.Modify();
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreateItemJournalLineWithEntryType(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; LocationCode: Code[10]; BinCode: Code[20])
    begin
        CreateItemJournal(ItemJournalLine);
        ItemJournalLine.Validate("Entry Type", EntryType);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine."Bin Code" := BinCode;
        ItemJournalLine.Modify(true);
    end;

    local procedure CreatePositiveAdjmtItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateTransferItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; NewLocationCode: Code[10]; NewBinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Transfer);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Transfer, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Validate("New Location Code", NewLocationCode);
        ItemJournalLine.Validate("New Bin Code", NewBinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemJournalAndCopyToTemp(var TempItemJournalLine: Record "Item Journal Line" temporary; var TempItem: Record Item temporary; var ItemJournalBatch: Record "Item Journal Batch"; SaveAsStandard: Boolean) "Code": Code[10]
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        "Count": Integer;
    begin
        TempItem.FindSet();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        for Count := 1 to TempItem.Count do begin
            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine, ItemJournalBatch."Journal Template Name",
              ItemJournalBatch.Name, "Item Ledger Document Type".FromInteger(Count mod 4),
              TempItem."No.", LibraryRandom.RandInt(5));  // Random Item Quantity.
            TempItem.Next();
        end;
        CopyItemJournalLinesToTemp(TempItemJournalLine, ItemJournalLine);
        if SaveAsStandard then
            Code := SaveAsStandardJournal(ItemJournalBatch, ItemJournalLine, true, true, '');
    end;

    local procedure MockReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        ReservationEntry.Init();
        ReservationEntry."Source Type" := DATABASE::"Item Journal Line";
        ReservationEntry."Source ID" := ItemJournalLine."Journal Template Name";
        ReservationEntry."Source Batch Name" := ItemJournalLine."Journal Batch Name";
        ReservationEntry."Source Ref. No." := ItemJournalLine."Line No.";
        ReservationEntry."Source Subtype" := ItemJournalLine."Entry Type".AsInteger();
        ReservationEntry."Source Prod. Order Line" := 0;
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Reservation;
        ReservationEntry.Quantity := LibraryRandom.RandDecInRange(1000, 2000, 2);
        ReservationEntry.Insert();
    end;

    local procedure CopyItemJournalLinesToTemp(var TempItemJournalLine: Record "Item Journal Line" temporary; ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine.FindSet();
        repeat
            TempItemJournalLine := ItemJournalLine;
            TempItemJournalLine.Insert();
        until ItemJournalLine.Next() = 0;
    end;

    local procedure ItemReclassJournalPageLookupAtAppliesToEntry(JournalBatchName: Code[10]; DocumentNo: Code[20]; ItemNo: Code[20])
    var
        ItemReclassJournal: TestPage "Item Reclass. Journal";
    begin
        ItemReclassJournal.OpenEdit();
        ItemReclassJournal.CurrentJnlBatchName.SetValue(JournalBatchName);
        ItemReclassJournal.FILTER.SetFilter("Document No.", DocumentNo);
        ItemReclassJournal.FILTER.SetFilter("Item No.", ItemNo);
        ItemReclassJournal.First();
        ItemReclassJournal."Applies-to Entry".Lookup();
        ItemReclassJournal.Close();
    end;

    local procedure SaveAsStandardJournal(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; SaveUnitAmount: Boolean; SaveQuantity: Boolean; StandardItemJournalCode: Code[10]) "Code": Code[10]
    var
        StandardItemJournal: Record "Standard Item Journal";
        SaveAsStandardItemJournal: Report "Save as Standard Item Journal";
    begin
        // Random Code & Description values for Standard Item Journal.
        if StandardItemJournalCode = '' then
            StandardItemJournalCode :=
              CopyStr(LibraryUtility.GenerateRandomCode(StandardItemJournal.FieldNo(Code), DATABASE::"Standard Item Journal"), 1, 10);
        Code := StandardItemJournalCode;
        SaveAsStandardItemJournal.InitializeRequest(
          StandardItemJournalCode,
          CopyStr(LibraryUtility.GenerateRandomCode(StandardItemJournal.FieldNo(Description), DATABASE::"Standard Item Journal"), 1, 50),
          SaveUnitAmount, SaveQuantity);
        SaveAsStandardItemJournal.Initialise(ItemJournalLine, ItemJournalBatch);
        SaveAsStandardItemJournal.UseRequestPage(false);
        SaveAsStandardItemJournal.Run();
        ItemJournalLine.DeleteAll(true);
    end;

    local procedure SaveItemJournalLineAsNewStandardJournal(var ItemJournalLine: Record "Item Journal Line"; SaveUnitAmount: Boolean; SaveQuantity: Boolean) StandardItemJournalCode: Code[10]
    var
        StandardItemJournal: Record "Standard Item Journal";
        ItemJournalBatch: Record "Item Journal Batch";
        SaveAsStandardItemJournal: Report "Save as Standard Item Journal";
    begin
        // Random Code & Description values for Standard Item Journal.
        StandardItemJournalCode :=
          CopyStr(LibraryUtility.GenerateRandomCode(StandardItemJournal.FieldNo(Code), DATABASE::"Standard Item Journal"), 1, 10);
        SaveAsStandardItemJournal.InitializeRequest(
          StandardItemJournalCode,
          CopyStr(LibraryUtility.GenerateRandomCode(StandardItemJournal.FieldNo(Description), DATABASE::"Standard Item Journal"), 1, 50),
          SaveUnitAmount, SaveQuantity);
        ItemJournalBatch.Get(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetRange("Item No.", ItemJournalLine."Item No.");
        SaveAsStandardItemJournal.Initialise(ItemJournalLine, ItemJournalBatch);
        SaveAsStandardItemJournal.UseRequestPage(false);
        SaveAsStandardItemJournal.Run();
    end;

    local procedure CreateItemJnlFromStdJournal(ItemJournalBatch: Record "Item Journal Batch"; StandardItemJournalCode: Code[10])
    var
        StandardItemJournal: Record "Standard Item Journal";
    begin
        SelectStandardItemJournal(StandardItemJournal, StandardItemJournalCode, ItemJournalBatch."Journal Template Name");
        StandardItemJournal.CreateItemJnlFromStdJnl(StandardItemJournal, ItemJournalBatch.Name);
    end;

    local procedure SelectStandardItemJournal(var StandardItemJournal: Record "Standard Item Journal"; StandardItemJournalCode: Code[10]; JournalTemplateName: Code[10])
    begin
        StandardItemJournal.SetRange(Code, StandardItemJournalCode);
        StandardItemJournal.SetRange("Journal Template Name", JournalTemplateName);
        StandardItemJournal.FindFirst();
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; TemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, TemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure UpdateItemJournalLineQuantity(var TempItemJournalLine: Record "Item Journal Line" temporary; ItemJournalBatch: Record "Item Journal Batch"; StandardItemJournalCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Random Item Quantity greater than previous Quantity.
        SelectItemJournalLine(ItemJournalLine, ItemJournalBatch);
        repeat
            ItemJournalLine.Validate(Quantity, ItemJournalLine.Quantity + LibraryRandom.RandInt(5));
            ItemJournalLine.Modify(true);
        until ItemJournalLine.Next() = 0;
        CopyItemJournalLinesToTemp(TempItemJournalLine, ItemJournalLine);
        SaveAsStandardJournal(ItemJournalBatch, ItemJournalLine, true, true, StandardItemJournalCode);
    end;

    local procedure SelectItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch")
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindSet();
    end;

    local procedure CreateItemWithoutCost(var TempItem: Record Item temporary; var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        TempItem := Item;
        TempItem.Insert();
    end;

    local procedure UpdateItemCost(var Item: Record Item)
    begin
        // Random values not important for test.
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(10, 2));
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2) + 10);
        Item.Modify(true);
    end;

    local procedure MockNegativeOpenItemLedgerEntry(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(ItemLedgerEntry, ItemLedgerEntry.FieldNo("Entry No."));
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::"Negative Adjmt.";
        ItemLedgerEntry."Document Date" := WorkDate();
        ItemLedgerEntry."Posting Date" := WorkDate();
        ItemLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        ItemLedgerEntry."Location Code" := LocationCode;
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry.Quantity := Qty;
        ItemLedgerEntry."Remaining Quantity" := Qty;
        ItemLedgerEntry.Open := true;
        ItemLedgerEntry.Positive := false;
        ItemLedgerEntry.Insert();
    end;

    local procedure RecalcUnitAmountItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch")
    begin
        SelectItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalLine.RecalculateUnitAmount();
    end;

    local procedure UpdateItemJournalUnitCost(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch")
    begin
        // Random Unit Cost greater than previous Unit Cost.
        SelectItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalLine.Validate("Unit Cost", ItemJournalLine."Unit Cost" + LibraryRandom.RandInt(10));
        ItemJournalLine.Modify(true);
    end;

    local procedure UpdateItemJournalDocumentNo(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch")
    begin
        SelectItemJournalLine(ItemJournalLine, ItemJournalBatch);
        repeat
            ItemJournalLine.Validate(
              "Document No.", LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("Document No."), DATABASE::"Item Journal Line"));
            ItemJournalLine.Modify(true);
        until ItemJournalLine.Next() = 0;
    end;

    local procedure UpdateInventory(ItemNo: Code[20]; LocationCode: Code[10]; Quantuty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreatePositiveAdjmtItemJournalLine(ItemJournalLine, ItemNo, LocationCode, Quantuty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure FindStandardItemJournalLine(var StandardItemJournalLine: Record "Standard Item Journal Line"; StandardItemJournalCode: Code[10]; ItemNo: Code[20])
    begin
        StandardItemJournalLine.SetRange("Standard Journal Code", StandardItemJournalCode);
        StandardItemJournalLine.SetRange("Item No.", ItemNo);
        StandardItemJournalLine.FindFirst();
    end;

    local procedure VerifyItemJournalAmount(var TempItemJournalLine: Record "Item Journal Line" temporary; ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        TempItemJournalLine.FindSet();
        SelectItemJournalLine(ItemJournalLine, ItemJournalBatch);
        repeat
            Assert.AreEqual(TempItemJournalLine.Amount, ItemJournalLine.Amount, ItemJournalAmountErr);
            ItemJournalLine.Next();
        until TempItemJournalLine.Next() = 0;
    end;

    local procedure VerifyStandardJournalEntry(JournalTemplateName: Code[10]; StandardItemJournalCode: Code[10])
    var
        StandardItemJournal: Record "Standard Item Journal";
    begin
        // Verify Standard Item Journal line record exists.
        StandardItemJournal.SetRange(Code, StandardItemJournalCode);
        StandardItemJournal.SetRange("Journal Template Name", JournalTemplateName);
        StandardItemJournal.FindFirst();
    end;

    local procedure VerifyItemLedgerEntry(var TempItemJournalLine: Record "Item Journal Line" temporary)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        TempItemJournalLine.FindSet();
        repeat
            ItemLedgerEntry.SetRange("Item No.", TempItemJournalLine."Item No.");
            ItemLedgerEntry.SetRange("Entry Type", TempItemJournalLine."Entry Type");
            ItemLedgerEntry.FindFirst();
            Assert.AreEqual(TempItemJournalLine.Quantity, Abs(ItemLedgerEntry.Quantity), QuantityErr);
        until TempItemJournalLine.Next() = 0;
    end;

    local procedure VerifyItemLedgerEntryForQty(var ItemJournalLine: Record "Item Journal Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemJournalLine."Entry Type");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, ItemJournalLine.Quantity);
        ItemLedgerEntry.TestField("Invoiced Quantity", ItemJournalLine."Invoiced Quantity");
        ItemLedgerEntry.TestField("Remaining Quantity", ItemJournalLine.Quantity);
    end;

    local procedure VerifyItemInventoryByLot(ItemNo: Code[20]; LotNo: Code[50]; Qty: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.SetFilter("Lot No. Filter", LotNo);
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, Qty);
    end;

    local procedure VerifyItemLedgerEntryPositive(EntryNo: Integer; ExpectedValue: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Get(EntryNo);
        ItemLedgerEntry.TestField(Positive, ExpectedValue);
    end;

    local procedure CheckNoItemLedgerEntries(DocumentNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        Assert.IsTrue(ItemLedgerEntry.IsEmpty, TransferILEErr);
    end;

    local procedure CreateLocationWithBin(var Location: Record Location; var BinCode1: Code[20]; var BinCode2: Code[20])
    var
        Bin: Record Bin;
        Zone: Record Zone;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location."Bin Mandatory" := true;
        Location.Validate("Directed Put-away and Pick", true);
        Location.Validate("Use Cross-Docking", true);
        Location.Modify(true);

        LibraryWarehouse.CreateZone(Zone, '', Location.Code, LibraryWarehouse.SelectBinType(false, false, false, false), '', '', 0, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, Zone.Code, LibraryWarehouse.SelectBinType(false, false, false, false), 2, false);
        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 1);
        BinCode1 := Bin.Code;
        Location.Validate("Adjustment Bin Code", Bin.Code);
        Location.Modify(true);

        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 2);
        BinCode2 := Bin.Code;
    end;

    local procedure CreateLocationWithBinBlockMovement(var Location: Record Location; var Bin: Record Bin; BlockMovement: Option " ",Inbound,Outbound,All)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location."Bin Mandatory" := true;
        Location.Modify(true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        UpdateBlockMovementOnBin(Bin, Location.Code, 1, BlockMovement);
    end;

    local procedure CreateLocationWithTwoBinsBlockMovement(var Location: Record Location; var Bin1: Record Bin; BlockMovement1: Option " ",Inbound,Outbound,All; var Bin2: Record Bin; BlockMovement2: Option " ",Inbound,Outbound,All)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location."Bin Mandatory" := true;
        Location.Modify(true);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);
        UpdateBlockMovementOnBin(Bin1, Location.Code, 1, BlockMovement1);
        UpdateBlockMovementOnBin(Bin2, Location.Code, 2, BlockMovement2);
    end;

    local procedure CreateItemReclassJournaLine(TemplateName: Code[10]; BatchName: Code[10]; ItemNo: Code[20]; OldLocationCode: Code[10]; NewLocationCode: Code[10]; OldBinCode: Code[20]; NewBinCode: Code[20]; Qty: Integer): Code[10]
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, TemplateName, BatchName, ItemJournalLine."Entry Type"::Transfer, ItemNo, Qty);
        ItemJournalLine.Validate("Location Code", OldLocationCode);
        ItemJournalLine.Validate("New Location Code", NewLocationCode);
        ItemJournalLine."Bin Code" := OldBinCode;
        ItemJournalLine."New Bin Code" := NewBinCode;
        ItemJournalLine.Validate(Quantity, Qty);
        ItemJournalLine."Document No." := LibraryUtility.GenerateGUID();
        ItemJournalLine.Modify(true);

        exit(ItemJournalLine."Document No.");
    end;

    local procedure CreateItemReclassJournalLineWithNewBin(var ItemJnlBatch: Record "Item Journal Batch"; var ItemJnlTemplate: Record "Item Journal Template"; LocationCode: Code[10]; OldBinCode: Code[20]; NewBinCode: Code[20]; Qty: Decimal)
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalTemplate(ItemJnlTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJnlBatch, ItemJnlTemplate.Name);
        CreatePositiveAdjmtLocationAndBin(
          ItemJnlTemplate.Name, ItemJnlBatch.Name, LocationCode, OldBinCode, Item."No.", Qty);
        CreateItemReclassJournaLine(
          ItemJnlTemplate.Name, ItemJnlBatch.Name, Item."No.", LocationCode, LocationCode, OldBinCode, NewBinCode, Qty);
    end;

    local procedure CreatePositiveAdjmtLocationAndBin(ItemJnlTemplateName: Code[10]; ItemJnlBatchName: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; ItemQty: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJnlTemplateName, ItemJnlBatchName, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, ItemQty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine."Bin Code" := BinCode;
        ItemJournalLine.Modify(true);
    end;

    local procedure ValidateScrapCodeForOutputJournal(CapacityType: Enum "Capacity Type Journal"; ShouldAssertError: Boolean)
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Scrap: Record Scrap;
    begin
        Initialize();

        // [GIVEN] Item "I" with Costing Method = "Standard" and Unit Cost = "X".
        CreateItemWithCostingMethod(Item, Item."Costing Method"::Standard);

        // [GIVEN] Create output item journal line directly, as UI does not allow this entry type
        CreateItemJournalLine(ItemJournalLine, Item."No.");
        case CapacityType of
            CapacityType::"Machine Center",
            CapacityType::"Work Center",
            CapacityType::" ":
                ItemJournalLine.Validate("Entry Type", "Item ledger Entry Type"::Output);
            CapacityType::Resource:
                ItemJournalLine.Validate("Entry Type", "Item ledger Entry Type"::"Assembly Output")
        end;
        ItemJournalLine.Validate(Type, CapacityType);
        ItemJournalLine.Modify();

        Scrap.Init();
        Scrap.Validate(Code, LibraryUtility.GenerateRandomCode(Scrap.FieldNo(Code), DATABASE::"Scrap"));
        Scrap.Insert();

        // [THEN] Check if Scrap Code can be defined
        if ShouldAssertError then
            asserterror ItemJournalLine.Validate("Scrap Code", Scrap.Code)
        else
            ItemJournalLine.Validate("Scrap Code", Scrap.Code);
    end;

    local procedure CreateLocationWithBinAndCapicityPolicy(
        var Location: Record Location;
        BinCapacityPolicy: Option "Never Check Capacity","Allow More Than Max. Capacity","Prohibit More Than Max. Cap.";
        var BinCode: Code[20];
        var BinCode2: Code[20])
    var
        Bin: Record Bin;
        Zone: Record Zone;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Bin Capacity Policy", BinCapacityPolicy);
        Location.Modify(true);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);
        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 1);
        BinCode := Bin.Code;

        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 2);
        BinCode2 := Bin.Code;
    end;

    local procedure CreateItemJnlWithLocationAndBin(
        var ItemJournalLine: Record "Item Journal Line";
        ItemJnlTemplateName: Code[10];
        ItemJnlBatchName: Code[10];
        EntryType: Enum "Item Ledger Entry Type";
        LocationCode: Code[10];
        NewLocationCode: Code[10];
        BinCode: Code[20];
        NewBinCode: Code[20];
        ItemNo: Code[20];
        ItemQty: Integer)
    begin
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJnlTemplateName, ItemJnlBatchName, EntryType, ItemNo, ItemQty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine."Bin Code" := BinCode;
        if EntryType = EntryType::Transfer then begin
            ItemJournalLine.Validate("New Location Code", NewLocationCode);
            ItemJournalLine.Validate("New Bin Code", NewBinCode);
        end;
        ItemJournalLine.Modify(true);
    end;

    procedure EnqueItrLotQty(Iteration: Integer; LotNo: Code[10]; Qty: Integer)
    begin
        LibraryVariableStorage.Enqueue(Iteration);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
    end;

    procedure VerifyWshEntryforItemReclassJournal(ItemNo: Code[20]; LotNo: Code[10]; UOMWeight: Integer)
    var
        WarehouseEntry: Record "Warehouse Entry";
        i: Integer;
    begin
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Lot No.", LotNo);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        Assert.RecordCount(WarehouseEntry, 2);

        if WarehouseEntry.FindSet() then
            repeat
                i += 1;
                Assert.AreEqual(
                    UOMWeight * WarehouseEntry.Quantity,
                    WarehouseEntry.Weight,
                    StrSubstNo(ValueMustBeEqualErr, WarehouseEntry.FieldCaption(Weight), UOMWeight * WarehouseEntry.Quantity, WarehouseEntry.TableCaption));

                if i = 1 then
                    Assert.IsTrue(WarehouseEntry.weight < 0, StrSubstNo(ValueMustBeNegativeErr, WarehouseEntry.FieldCaption(Weight)));
                if i = 2 then
                    Assert.IsTrue(WarehouseEntry.weight > 0, StrSubstNo(ValueMustBePositiveErr, WarehouseEntry.FieldCaption(Weight)));

            until WarehouseEntry.Next() = 0;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    local procedure UpdateBlockMovementOnBin(var Bin: Record Bin; LocationCode: Code[10]; BinIndex: Integer; BlockMovement: Option " ",Inbound,Outbound,All)
    begin
        LibraryWarehouse.FindBin(Bin, LocationCode, '', BinIndex);
        Bin.Validate("Block Movement", BlockMovement);
        Bin.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        NoOfIterations: Integer;
        i: Integer;
    begin
        NoOfIterations := LibraryVariableStorage.DequeueInteger();
        for i := 1 to NoOfIterations do begin
            ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
            ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
            ItemTrackingLines.Next();
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ItemJournalConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Overwrite Item Journal Line confirm handler.
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemListModalPageHandler(var ItemList: TestPage "Item List")
    var
        FirstItemNo: Text;
    begin
        ItemList.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ItemList.First();
        FirstItemNo := ItemList."No.".Value();
        ItemList.Last();
        Assert.AreEqual(FirstItemNo, ItemList."No.".Value, '');
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ItemList."No.".Value, '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Batch", 'OnBeforeCode', '', false, false)]
    local procedure OnBeforeCode(var ItemJournalLine: Record "Item Journal Line")
    begin
        // Verify auto calc field is reset
        ItemJournalLine.TestField("Reserved Quantity");
        ItemJournalLine.Find();
        ItemJournalLine.TestField("Reserved Quantity", 0);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemLedgerEntriesLookupSingleModalPageHandler(var ItemLedgerEntries: TestPage "Item Ledger Entries")
    begin
        ItemLedgerEntries.First();
        LibraryVariableStorage.Enqueue(ItemLedgerEntries."Entry No.".Value);
        LibraryVariableStorage.Enqueue(ItemLedgerEntries.Next());
        ItemLedgerEntries.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemLedgerEntriesLookupMultipleModalPageHandler(var ItemLedgerEntries: TestPage "Item Ledger Entries")
    begin
        ItemLedgerEntries.First();
        LibraryVariableStorage.Enqueue(ItemLedgerEntries."Entry No.".Value);
        LibraryVariableStorage.Enqueue(ItemLedgerEntries.Next());
        LibraryVariableStorage.Enqueue(ItemLedgerEntries."Entry No.".Value);
        ItemLedgerEntries.Cancel().Invoke();
    end;
}

