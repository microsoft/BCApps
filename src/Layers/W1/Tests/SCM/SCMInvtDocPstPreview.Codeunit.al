codeunit 134786 "SCM Invt. Doc. Pst Preview"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Post Preview] [Item Shipment] [Item Receipt] [Physical Inventory Order]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryNonDeductibleVAT: Codeunit "Library - NonDeductible VAT";
        IsInitialized: Boolean;
        WrongPostPreviewErr: Label 'Expected empty error from Preview. Actual error: ';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in %3', Comment = '%1 = Field Caption , %2 = Expected Value , %3 = Table Caption';
        ValueEntryCostAmountErr: Label 'Value entry - cost amount(actual) can not be 0';
        ItemTrackingAction: Option AssignSerialNo,SelectEntries,ManualSN;

    [Test]
    [Scope('OnPrem')]
    procedure TestInventoryShipmentPostPreview()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        Location: Record Location;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        InvtDocPostYesNo: Codeunit "Invt. Doc.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Inventory Shipment shows item ledger entries and value entries that will be generated when the document is posted.
        Initialize();

        // [GIVEN] Create an Inventory Shipment document
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror InvtDocPostYesNo.Preview(InvtDocumentHeader);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the journal is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);
        Assert.IsFalse(GLPostingPreview.Next(), 'No more entries should exist.');
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInventoryShipmentPostPreviewWithMultipleLines()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine1: Record "Invt. Document Line";
        InvtDocumentLine2: Record "Invt. Document Line";
        Item: Record Item;
        Location: Record Location;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        InvtDocPostYesNo: Codeunit "Invt. Doc.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Inventory Shipment shows item ledger entries and value entries that will be generated when the document is posted.
        Initialize();

        // [GIVEN] Create an Inventory Shipment document
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine1, Item."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine2, Item."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror InvtDocPostYesNo.Preview(InvtDocumentHeader);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the journal is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 2);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 2);
        Assert.IsFalse(GLPostingPreview.Next(), 'No more entries should exist.');
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInventoryShipmentPreviewWithBin()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Bin: Record Bin;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        WarehouesEntry: Record "Warehouse Entry";
        InvtDocPostYesNo: Codeunit "Invt. Doc.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Inventory Shipment shows item ledger entries and value entries that will be generated when the document is posted.
        Initialize();

        // [GIVEN] Create a Location with Bin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(
          Bin, Location.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');

        Location."Default Bin Code" := Bin.Code;
        Location.Modify();

        // [GIVEN] Create an Inventory Shipment document
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", Location.Code, Bin.Code, LibraryRandom.RandIntInRange(10, 20));
        LibraryInventory.PostItemJournalLine(
          ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));
        InvtDocumentLine.Validate("Bin Code", Bin.Code);
        InvtDocumentLine.Modify(true);

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror InvtDocPostYesNo.Preview(InvtDocumentHeader);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the journal is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, WarehouesEntry.TableCaption(), 1);
        Assert.IsFalse(GLPostingPreview.Next(), 'No more entries should exist.');
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQuantityToCreateModalPageHandler,ItemTrackingSummaryModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestInventoryShipmentPreviewWithSeriallyTrackedItem()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        InvtDocPostYesNo: Codeunit "Invt. Doc.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Inventory Shipment shows item ledger entries and value entries that will be generated when the document is posted.
        Initialize();

        // [GIVEN] Create a Location with serially tracked item in inventory
        LibraryItemTracking.CreateSerialItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItemJournalLineInItemTemplate(
         ItemJournalLine, Item."No.", Location.Code, '', LibraryRandom.RandIntInRange(10, 20));
        LibraryVariableStorage.Enqueue(ItemTrackingAction::AssignSerialNo);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(
          ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create an Inventory Shipment document
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));
        LibraryVariableStorage.Enqueue(ItemTrackingAction::SelectEntries);
        InvtDocumentLine.OpenItemTrackingLines();
        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror InvtDocPostYesNo.Preview(InvtDocumentHeader);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the journal is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), InvtDocumentLine.Quantity);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), InvtDocumentLine.Quantity);
        Assert.IsFalse(GLPostingPreview.Next(), 'No more entries should exist.');
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInventoryReceiptPostPreview()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        Location: Record Location;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        InvtDocPostYesNo: Codeunit "Invt. Doc.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Inventory Receipt shows item ledger entries and value entries that will be generated when the document is posted.
        Initialize();

        // [GIVEN] Create an Inventory Receipt document
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror InvtDocPostYesNo.Preview(InvtDocumentHeader);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the journal is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);
        Assert.IsFalse(GLPostingPreview.Next(), 'No more entries should exist.');
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInventoryReceiptPostPreviewWithMultipleLines()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine1: Record "Invt. Document Line";
        InvtDocumentLine2: Record "Invt. Document Line";
        Item: Record Item;
        Location: Record Location;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        InvtDocPostYesNo: Codeunit "Invt. Doc.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Inventory Receipt shows item ledger entries and value entries that will be generated when the document is posted.
        Initialize();

        // [GIVEN] Create an Inventory Receipt document
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine1, Item."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine2, Item."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror InvtDocPostYesNo.Preview(InvtDocumentHeader);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the journal is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 2);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 2);
        Assert.IsFalse(GLPostingPreview.Next(), 'No more entries should exist.');
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInventoryReceiptPreviewWithBin()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        WarehouesEntry: Record "Warehouse Entry";
        InvtDocPostYesNo: Codeunit "Invt. Doc.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Inventory Receipt shows item ledger entries and value entries that will be generated when the document is posted.
        Initialize();

        // [GIVEN] Create an item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Location with Bin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(
          Bin, Location.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');

        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
        Location."Default Bin Code" := Bin.Code;
        Location.Modify();

        // [GIVEN] Create an Inventory Receipt document
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));
        InvtDocumentLine.Validate("Bin Code", Bin.Code);
        InvtDocumentLine.Modify(true);

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror InvtDocPostYesNo.Preview(InvtDocumentHeader);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the journal is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, WarehouesEntry.TableCaption(), 1);
        Assert.IsFalse(GLPostingPreview.Next(), 'No more entries should exist.');
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQuantityToCreateModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestInventoryReceiptPreviewWithSeriallyTrackedItem()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        Location: Record Location;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        InvtDocPostYesNo: Codeunit "Invt. Doc.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Inventory Receipt shows item ledger entries and value entries that will be generated when the document is posted.
        Initialize();

        // [GIVEN] Create a Location and serially tracked item
        LibraryItemTracking.CreateSerialItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create an Inventory Receipt document
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));
        LibraryVariableStorage.Enqueue(ItemTrackingAction::AssignSerialNo);
        InvtDocumentLine.OpenItemTrackingLines();
        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror InvtDocPostYesNo.Preview(InvtDocumentHeader);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the journal is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), InvtDocumentLine.Quantity);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), InvtDocumentLine.Quantity);
        Assert.IsFalse(GLPostingPreview.Next(), 'No more entries should exist.');
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('CalcPhysOrderLinesRequestPageHandler,CalculateQuantityExpectedStrMenuHandler,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPhysInventoryOrderPostPreview()
    var
        Location: Record Location;
        Item: Record Item;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
        PhysInvtOrderPostYN: Codeunit "Phys. Invt. Order-Post (Y/N)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Phys. InventoryOrder shows item ledger entries and value entries that will be generated when the document is posted.
        Initialize();
        // [GIVEN] Phys. Inventory Order with for one Item (without item tracking), where "Qty. Expected (Base)" is 3.
        // [GIVEN] Finished Recording, where "Quantity" is 1.
        CreatePhysInventoryOrderWithFinishedRecording(PhysInvtOrderHeader, Item, Location, 3, 1);

        // [WHEN] Finish Phys. Inventory Order.
        Codeunit.Run(Codeunit::"Phys. Invt. Order-Finish (Y/N)", PhysInvtOrderHeader);
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        PhysInvtOrderLine.FindFirst();
        CreateGeneralPostingSetup(PhysInvtOrderLine."Gen. Bus. Posting Group", PhysInvtOrderLine."Gen. Prod. Posting Group");
        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror PhysInvtOrderPostYN.Preview(PhysInvtOrderHeader);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the journal is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, PhysInventoryLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);
        Assert.IsFalse(GLPostingPreview.Next(), 'No more entries should exist.');
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPostingNoSeriesonInventoryShipmentDocIsBlankDefaultFalse()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        Location: Record Location;
        InventorySetup: Record "Inventory Setup";
        NoSeries: Record "No. Series";
    begin
        // [SCENARIO 460231] Posting No. Series should be blank on Inventory Shipment when there is no default Posted Invt. Shipment No.
        Initialize();

        // [GIVEN] Create No. Series with Default as false and Manual as true
        LibraryUtility.CreateNoSeries(NoSeries, false, true, false);

        // [GIVEN] Update No. Series on "Posted Invt. Shipment Nos."
        InventorySetup.Get();
        InventorySetup."Posted Invt. Shipment Nos." := NoSeries.Code;
        InventorySetup.Modify();

        // [GIVEN] Create an Location with Inventory Posting Setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create an Inventory Shipment document
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment, Location.Code);

        // [VERIFY] Posting No. Series should be blank if Default as false
        Assert.AreEqual('', InvtDocumentHeader."Posting No. Series", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPostingNoSeriesonInventoryReceiptDocIsBlankDefaultFalse()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        Location: Record Location;
        InventorySetup: Record "Inventory Setup";
        NoSeries: Record "No. Series";
    begin
        // [SCENARIO 460231] Posting No. Series should be blank on Inventory Receipt when there is no default Posted Invt. Receipt No.
        Initialize();

        // [GIVEN] Create No. Series with Default as false and Manual as true
        LibraryUtility.CreateNoSeries(NoSeries, false, true, false);

        // [GIVEN] Update No. Series on "Posted Invt. Shipment Nos."
        InventorySetup.Get();
        InventorySetup."Posted Invt. Receipt Nos." := NoSeries.Code;
        InventorySetup.Modify();

        // [GIVEN] Create an Location with Inventory Posting Setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create an Inventory Shipment document
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);

        // [VERIFY] Posting No. Series should be blank if Default as false
        Assert.AreEqual('', InvtDocumentHeader."Posting No. Series", '');
    end;

    [Test]
    [HandlerFunctions('GLPostingPreviewPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostingPreviewShouldNotJumpToAnotherDocumentForInventoryReceipt()
    var
        Item: Record Item;
        Location: Record Location;
        InvtDocumentHeader: array[3] of Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        InvtReceipt: TestPage "Invt. Receipt";
    begin
        // [SCENARIO 477577] Verify that the posting preview should not jump to another document for inventory receipt.
        Initialize();

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create a multiple Inventory Receipt document.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader[1], InvtDocumentHeader[1]."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader[2], InvtDocumentHeader[2]."Document Type"::Receipt, Location.Code);


        // [GIVEN] Create another Inventory Receipt document.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader[3], InvtDocumentHeader[3]."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(
            InvtDocumentHeader[3],
            InvtDocumentLine,
            Item."No.",
            LibraryRandom.RandInt(100),
            LibraryRandom.RandInt(10));

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Open and Preview the Inventory Receipt document.
        InvtReceipt.OpenEdit();
        InvtReceipt.GoToRecord(InvtDocumentHeader[3]);
        InvtReceipt.PreviewPosting.Invoke();

        // [VERIFY] Verify that the posting preview should not jump to another document for inventory receipt. 
        Assert.AreEqual(
            InvtDocumentHeader[3]."No.",
            InvtReceipt."No.".Value(),
             StrSubstNo(
                ValueMustBeEqualErr,
                InvtDocumentHeader[3].FieldCaption("No."),
                InvtDocumentHeader[3]."No.",
                InvtDocumentHeader[3].TableCaption()));

        InvtReceipt.Close();
    end;

    [Test]
    [HandlerFunctions('GLPostingPreviewPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostingPreviewShouldNotJumpToAnotherDocumentForInventoryShipment()
    var
        Item: Record Item;
        Location: Record Location;
        InvtDocumentHeader: array[3] of Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        InvtShipment: TestPage "Invt. Shipment";
    begin
        // [SCENARIO 477577] Verify that the posting preview should not jump to another document for inventory Shipment.
        Initialize();

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create a multiple Inventory Shipment document.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader[1], InvtDocumentHeader[1]."Document Type"::Shipment, Location.Code);
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader[2], InvtDocumentHeader[2]."Document Type"::Shipment, Location.Code);


        // [GIVEN] Create another Inventory Shipment document.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader[3], InvtDocumentHeader[3]."Document Type"::Shipment, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(
            InvtDocumentHeader[3],
            InvtDocumentLine,
            Item."No.",
            LibraryRandom.RandInt(100),
            LibraryRandom.RandInt(10));

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Open and Preview the Inventory Shipment document.
        InvtShipment.OpenEdit();
        InvtShipment.GoToRecord(InvtDocumentHeader[3]);
        InvtShipment.PreviewPosting.Invoke();

        // [VERIFY] Verify that the posting preview should not jump to another document for inventory Shipment. 
        Assert.AreEqual(
            InvtDocumentHeader[3]."No.",
            InvtShipment."No.".Value(),
             StrSubstNo(
                ValueMustBeEqualErr,
                InvtDocumentHeader[3].FieldCaption("No."),
                InvtDocumentHeader[3]."No.",
                InvtDocumentHeader[3].TableCaption()));

        InvtShipment.Close();
    end;

    [Test]
    [HandlerFunctions('CalcPhysOrderLinesRequestPageHandler,CalculateQuantityExpectedStrMenuHandler,ConfirmHandlerTRUE,MessageHandler')]
    procedure PostingPhysicalInventoryOrderShouldNotCauseError()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        Item: Record Item;
        Location: Record Location;
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO 534167] Physical Inventory Order is deleted after posting.
        Initialize();

        // [GIVEN] Create Physical Inventory Order with for one Item without item tracking.
        CreatePhysInventoryOrderWithFinishedRecording(PhysInvtOrderHeader, Item, Location, LibraryRandom.RandIntInRange(3, 10), LibraryRandom.RandIntInRange(1, 3));

        // [GIVEN] Finish Phys. Inventory Order.
        Codeunit.Run(Codeunit::"Phys. Invt. Order-Finish (Y/N)", PhysInvtOrderHeader);

        // [GIVEN] Find the Physical Order Line.
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        PhysInvtOrderLine.FindFirst();

        // [GIVEN] Create General Posting Setup.
        CreateGeneralPostingSetup(PhysInvtOrderLine."Gen. Bus. Posting Group", PhysInvtOrderLine."Gen. Prod. Posting Group");

        //[GIVEN] Validate Inventory Adjmt. Account in General Posting Setup.
        GeneralPostingSetup.Get(PhysInvtOrderLine."Gen. Bus. Posting Group", PhysInvtOrderLine."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Inventory Adjmt. Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
        Commit();

        // [WHEN] Post Physical Inventory Order must be posted.
        Codeunit.Run(Codeunit::"Phys. Invt. Order-Post", PhysInvtOrderHeader);

        // [THEN] Physical Order must be deleted after posting.
        Assert.RecordIsEmpty(PhysInvtOrderHeader);
    end;

    [Test]
    procedure CheckCostAmountActualInValueEntryAfterInventoryReceiptPost()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        ItemReceiptHeader: Record "Invt. Receipt Header";
        Location: Record Location;
        ValueEntry: Record "Value Entry";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 565840] Inventory Receipt posts zero cost if VAT Setup is set to use Non-deductible VAT.
        Initialize();

        // [GIVEN] Create a Non Deductible VAT Posting Setup.
        CreateVATSetupForNonDeductible(VATPostingSetup);

        // [GIVEN] Create Location With Inventory Posting Setup.
        SetupForItemDocument(Location);

        // [GIVEN] Create Item With Validate Unit Cost.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandInt(100));
        Item.Modify(true);

        // [GIVEN] Create Inventory Receipt Document.
        CreateInvtDocumentWithLine(InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Receipt, Location.Code);

        // [WHEN] Post Inventory Receipt Document.
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [WHEN] Get Value Entry FOr Posted Inventory Receipt.
        GetItemReceiptHeaderAndValueEntry(InvtDocumentHeader."No.", ItemReceiptHeader, ValueEntry);

        // [THEN] Verify Value Entry Field "Cost Amount (Actual)" Must Have Value.
        Assert.AreNotEqual(0, ValueEntry."Cost Amount (Actual)", ValueEntryCostAmountErr);
    end;

    local procedure Initialize()
    var
        ItemJournalLine: Record "Item Journal Line";
        WarehouseSetup: Record "Warehouse Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Invt. Doc. Pst Preview");
        LibrarySetupStorage.Restore();
        ItemJournalLine.DeleteAll();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SCM Invt. Doc. Pst Preview");
        IsInitialized := true;

        LibraryERMCountryData.UpdatePrepaymentAccounts();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryPurchase.SetOrderNoSeriesInSetup();
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        LibrarySetupStorage.Save(Database::"Inventory Setup");
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SCM Invt. Doc. Pst Preview");
    end;

    local procedure VerifyGLPostingPreviewLine(GLPostingPreview: TestPage "G/L Posting Preview"; TableName: Text; ExpectedEntryCount: Integer)
    begin
        Assert.AreEqual(TableName, GLPostingPreview."Table Name".Value, StrSubstNo('A record for Table Name %1 was not found.', TableName));
        Assert.AreEqual(ExpectedEntryCount, GLPostingPreview."No. of Records".AsInteger(),
          StrSubstNo('Table Name %1 Unexpected number of records.', TableName));
    end;

    local procedure CreatePhysInventoryOrderWithFinishedRecording(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var Item: Record Item; var Location: Record Location; ExpectedQty: Decimal; RecordedQty: Decimal)
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateAndPostItemJournalLineWithoutTracking(Location.Code, Item."No.", '', ExpectedQty);
        CreatePhysInventoryOrderWithRecording(PhysInvtOrderHeader, Location.Code, Item."No.");
        FindAndUpdatePhysInvtRecordingLine(PhysInvtRecordLine, Item."No.", '', '', '', RecordedQty);
        FinishPhysInventoryRecording(PhysInvtRecordLine, PhysInvtOrderHeader."No.");  // Change Phys. Inventory Recording Status to Finished.
    end;

    local procedure CreateGeneralPostingSetup(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup) then
            LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup, GenProdPostingGroup);
    end;

    local procedure CreateAndPostItemJournalLineWithoutTracking(LocationCode: Code[10]; ItemNo: Code[20]; BinCode: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.DeleteAll();
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreatePhysInventoryOrderWithRecording(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; LocationCode: Code[10]; ItemNo: Code[20])
    var
        LibraryReportValidation: Codeunit "Library - Report Validation";
        ReportId: Integer;
    begin
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader, LocationCode);
        CalculatePhysInventoryLine(PhysInvtOrderHeader, LocationCode, ItemNo);
        ReportId := Report::"Make Phys. Invt. Recording";
        LibraryReportValidation.DeleteObjectOptions(ReportId);
        PhysInvtOrderHeader.SetRange("No.", PhysInvtOrderHeader."No.");
        Report.RunModal(Report::"Make Phys. Invt. Recording", false, false, PhysInvtOrderHeader);
    end;

    local procedure CreatePhysInventoryOrderHeader(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; LocationCode: Code[10])
    begin
        PhysInvtOrderHeader.Init();
        PhysInvtOrderHeader.Insert(true);
        PhysInvtOrderHeader.Validate("Location Code", LocationCode);
        PhysInvtOrderHeader.Modify(true);
    end;

    local procedure CalculatePhysInventoryLine(PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; LocationCode: Code[10]; ItemNo: Code[20])
    var
        PhysInventoryOrder: TestPage "Physical Inventory Order";
    begin
        Commit();  // Commit required for explicit commit used in CalculateLines - OnAction, Page 5005350 Phys. Inventory Order.
        // Enqueue value for use in CalcPhysOrderLinesRequestPageHandler.
        LibraryVariableStorage.Enqueue(LocationCode);
        LibraryVariableStorage.Enqueue(ItemNo);
        PhysInventoryOrder.OpenEdit();
        PhysInventoryOrder.Filter.SetFilter("No.", PhysInvtOrderHeader."No.");
        PhysInventoryOrder.CalculateLines.Invoke();  // Invokes CalcPhysOrderLinesRequestPageHandler.
        Codeunit.Run(Codeunit::"Phys. Invt.-Calc. Qty. All", PhysInvtOrderHeader);
    end;

    local procedure FindPhysInvtRecordingLine(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; ItemNo: Code[20]; BinCode: Code[20])
    begin
        PhysInvtRecordLine.SetRange("Item No.", ItemNo);
        PhysInvtRecordLine.SetRange("Bin Code", BinCode);
        PhysInvtRecordLine.FindFirst();
    end;

    local procedure FindAndUpdatePhysInvtRecordingLine(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; ItemNo: Code[20]; OldBinCode: Code[20]; NewBinCode: Code[20]; SN: Code[20]; Quantity: Decimal)
    begin
        FindPhysInvtRecordingLine(PhysInvtRecordLine, ItemNo, OldBinCode);
        UpdatePhysInvtRecordingLine(PhysInvtRecordLine, NewBinCode, SN, Quantity);
    end;

    local procedure UpdatePhysInvtRecordingLine(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; BinCode: Code[20]; SN: Code[20]; Quantity: Decimal)
    begin
        PhysInvtRecordLine.Validate("Bin Code", BinCode);
        PhysInvtRecordLine.Validate("Serial No.", SN);
        PhysInvtRecordLine.Validate(Quantity, Quantity);
        PhysInvtRecordLine.Modify(true);
    end;

    local procedure FinishPhysInventoryRecording(PhysInvtRecordLine: Record "Phys. Invt. Record Line"; PhysInventoryOrderHeaderNo: Code[20])
    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
    begin
        PhysInvtRecordHeader.Get(PhysInventoryOrderHeaderNo, PhysInvtRecordLine."Recording No.");
        Codeunit.Run(Codeunit::"Phys. Invt. Rec.-Finish (Y/N)", PhysInvtRecordHeader);
    end;

    local procedure CreateInvtDocumentWithLine(var InvtDocumentHeader: Record "Invt. Document Header"; var InvtDocumentLine: Record "Invt. Document Line"; Item: Record Item; DocumentType: Enum "Invt. Doc. Document Type"; LocationCode: Code[10])
    begin
        CreateInvtDocumentWithLine(InvtDocumentHeader, InvtDocumentLine, Item, DocumentType, LocationCode, LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateInvtDocumentWithLine(var InvtDocumentHeader: Record "Invt. Document Header"; var InvtDocumentLine: Record "Invt. Document Line"; Item: Record Item; DocumentType: Enum "Invt. Doc. Document Type"; LocationCode: Code[10]; Qty: Decimal)
    begin
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, DocumentType, LocationCode);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", LibraryRandom.RandInt(100), Qty);
    end;

    local procedure SetupForItemDocument(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
    end;

    local procedure GetItemReceiptHeaderAndValueEntry(No: Code[20]; var ItemReceiptHeader: Record "Invt. Receipt Header"; var ValueEntry: Record "Value Entry")
    begin
        ItemReceiptHeader.SetRange("Receipt No.", No);
        ItemReceiptHeader.FindFirst();

        ValueEntry.SetRange("Document No.", ItemReceiptHeader."No.");
        ValueEntry.FindFirst();
    end;

    local procedure CreateVATSetupForNonDeductible(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryNonDeductibleVAT.EnableNonDeductibleVAT();
        LibraryNonDeductibleVAT.SetUseForItemCost();
        LibraryNonDeductibleVAT.CreateVATPostingSetupWithNonDeductibleDetail(VATPostingSetup, 19, 100);
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingAction::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            ItemTrackingAction::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingAction::ManualSN:
                begin
                    ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(1);
                end;
        end;

        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EnterQuantityToCreateModalPageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingSummaryModalPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcPhysOrderLinesRequestPageHandler(var CalcPhysInvtOrderLines: TestRequestPage "Calc. Phys. Invt. Order Lines")
    var
        LocationFilter: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(LocationFilter);
        LibraryVariableStorage.Dequeue(No);
        CalcPhysInvtOrderLines.Item.SetFilter("Location Filter", LocationFilter);
        CalcPhysInvtOrderLines.Item.SetFilter("No.", No);
        CalcPhysInvtOrderLines.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CalculateQuantityExpectedStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;  // Used for All Order Lines.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLPostingPreviewPageHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    begin
        GLPostingPreview.OK().Invoke();
    end;
}