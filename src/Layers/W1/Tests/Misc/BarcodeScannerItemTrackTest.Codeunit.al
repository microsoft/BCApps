namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using System.TestLibraries.Utilities;


codeunit 137213 BarcodeScannerItemTrackTest
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Barcode scanning item tracking with ]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibrarytestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        ScanQtyExceedMaximumMsg: Label 'Item tracking is successfully defined for quantity';


    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler,ItemTrackingTypeStrMenuHandler,ContinuousScanningTestPageModalHandler')]
    procedure OpenContinuousItemTrackingForSNTrackingAndClose()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [Serial No]
        // "Scan Multiple" -> Serial No -> Close
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 2, '');

        // The Stored value is used to select 'Serial No' on StrMenu
        LibraryVariableStorage.Enqueue('Serial No');
        LibraryVariableStorage.Enqueue('stop');

        // Test value of Continuous scanning page
        LibraryVariableStorage.Enqueue(2);
        // Test value of item tracking line  page
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(2);

        // [GIVEN] Init ItemTrackingLines, and run modal
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler,ItemTrackingTypeStrMenuHandler,ContinuousScanningTestPageModalHandler')]
    procedure OpenContinuousItemTrackingForLotTrackingAndClose()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [Lot No]
        // "Scan Multiple" -> Lot No -> Close
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 2, '');

        // The Stored value is used to select 'Lot No' on StrMenu
        LibraryVariableStorage.Enqueue('Lot No');
        LibraryVariableStorage.Enqueue('stop');

        // Test value of Continuous scanning page
        LibraryVariableStorage.Enqueue(2);
        // Test value of item tracking line  page
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(2);


        // [GIVEN] Init ItemTrackingLines, and run modal
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler,ItemTrackingTypeStrMenuHandler,ContinuousScanningTestPageModalHandler')]
    procedure OpenContinuousItemTrackingForPackageTrackingAndClose()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Serial No]
        // "Scan Multiple" -> Package No -> Close
        Initialize();
        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);
        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 2, '');

        // The Stored value is used to select 'Serial No' on StrMenu
        LibraryVariableStorage.Enqueue('Package No');
        LibraryVariableStorage.Enqueue('stop');

        // Test value of Continuous scanning page
        LibraryVariableStorage.Enqueue(2);
        // Test value of item tracking line page
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(2);

        // [GIVEN] Init ItemTrackingLines, and run modal
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler,ItemTrackingTypeStrMenuHandler,ContinuousScanningTestPageModalHandler')]
    procedure ContinuousScanSerialNoInBoundTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Serial No]
        // Continuously scan the serial number, and all the quantity should be set to 1.
        Initialize();
        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);
        // [GIVEN] Positive adjustment Item journal line for the item, but with minus Qty
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, '');

        // [GIVEN] The Stored value is used to select 'Serial No' on StrMenu
        LibraryVariableStorage.Enqueue('Serial No');
        // [GIVEN] Scan 3 Serial No
        LibraryVariableStorage.Enqueue('SN1');
        LibraryVariableStorage.Enqueue('SN2');
        LibraryVariableStorage.Enqueue('SN3');
        LibraryVariableStorage.Enqueue('stop');

        // [GIVEN] Test value of continuous Scanning page
        LibraryVariableStorage.Enqueue('SN1');
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue('SN2');
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue('SN3');
        LibraryVariableStorage.Enqueue(1);

        LibraryVariableStorage.Enqueue(7);

        // [GIVEN] Test value of Item tracking page
        LibraryVariableStorage.Enqueue('SN1');
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue('SN2');
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue('SN3');
        LibraryVariableStorage.Enqueue(1);

        LibraryVariableStorage.Enqueue(3);
        LibraryVariableStorage.Enqueue(7);

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines, true);

        // [Then] All page model will be handled
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler,ItemTrackingTypeStrMenuHandler,ContinuousScanningTestPageModalHandler')]
    procedure ContinuousScanSerialNoInBoundReachMaximumQtyTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Serial No]
        // Continuously scan the serial number, and all the quantity should be set to 1.
        // Reach the maximum qty, an message thrown.
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 3, '');

        // [GIVEN] The Stored value is used to select 'Serial No' on StrMenu
        LibraryVariableStorage.Enqueue('Serial No');
        // [GIVEN] Scan 3 Serial No
        LibraryVariableStorage.Enqueue('SN1');
        LibraryVariableStorage.Enqueue('SN2');
        LibraryVariableStorage.Enqueue('SN3');

        // [GIVEN] Init ItemTrackingLines 
        asserterror CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines, true);

        // [Then] An error thrown
        Assert.ExpectedError(ScanQtyExceedMaximumMsg);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler,ItemTrackingTypeStrMenuHandler,ContinuousScanningTestPageModalHandler')]
    procedure ContinuousScanSerialNoInBoundMinusTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Serial No]
        // Continuously scan the serial number, and all the quantity should be set to 1.
        Initialize();
        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);
        // [GIVEN] Positive adjustment Item journal line for the item, but with minus Qty
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", WorkDate(), Item."No.", -10, '');

        // [GIVEN] The Stored value is used to select 'Serial No' on StrMenu
        LibraryVariableStorage.Enqueue('Serial No');
        // [GIVEN] Scan 3 Serial No
        LibraryVariableStorage.Enqueue('SN1');
        LibraryVariableStorage.Enqueue('SN2');
        LibraryVariableStorage.Enqueue('SN3');
        LibraryVariableStorage.Enqueue('stop');

        // [GIVEN] Test value of continuous Scanning page
        LibraryVariableStorage.Enqueue('SN1');
        LibraryVariableStorage.Enqueue(-1);
        LibraryVariableStorage.Enqueue('SN2');
        LibraryVariableStorage.Enqueue(-1);
        LibraryVariableStorage.Enqueue('SN3');
        LibraryVariableStorage.Enqueue(-1);

        LibraryVariableStorage.Enqueue(-7);

        // [GIVEN] Test value of Item tracking page
        LibraryVariableStorage.Enqueue('SN1');
        LibraryVariableStorage.Enqueue(-1);
        LibraryVariableStorage.Enqueue('SN2');
        LibraryVariableStorage.Enqueue(-1);
        LibraryVariableStorage.Enqueue('SN3');
        LibraryVariableStorage.Enqueue(-1);

        LibraryVariableStorage.Enqueue(-3);
        LibraryVariableStorage.Enqueue(-7);

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines, true);

        // [Then] All page model will be handled
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler,ItemTrackingTypeStrMenuHandler,ContinuousScanningTestPageModalHandler,ConfirmHandler')]
    procedure ContinuousScanSerialNoOutBoundWithExistingItemTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [OutBound] [Serial No]
        // Continuously scan the serial number, and set the corresponding quantity to 1 if serial no has been post.
        // Set the quantity to 0 if it is not post.
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        CreateItemJournalLineWithItemTrackingOnLines(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);

        ItemJournalLine."Serial No." := 'SN1';
        ItemJournalLine.Modify(true);

        // [GIVEN] Post this journal line
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Add items 
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", WorkDate(), Item."No.", 10, '');

        // [GIVEN] The Stored value is used to select 'Serial No' on StrMenu
        LibraryVariableStorage.Enqueue('Serial No');
        // [GIVEN] Scan 3 Serial No
        LibraryVariableStorage.Enqueue('SN1');
        LibraryVariableStorage.Enqueue('SN2');
        LibraryVariableStorage.Enqueue('SN3');
        LibraryVariableStorage.Enqueue('stop');

        // [GIVEN] Test value of continuous Scanning page
        LibraryVariableStorage.Enqueue('SN1');
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue('SN2');
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue('SN3');
        LibraryVariableStorage.Enqueue('');

        LibraryVariableStorage.Enqueue(9);

        // [GIVEN] Test value of Item tracking page
        LibraryVariableStorage.Enqueue('SN1');
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue('SN2');
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue('SN3');
        LibraryVariableStorage.Enqueue('');

        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(9);

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler,ItemTrackingTypeStrMenuHandler,ContinuousScanningTestPageModalHandler,ConfirmHandler')]
    procedure ContinuousScanLotNoInBoundTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Lot No]
        // Continuously scan the serial number, and all the quantity should be set to 1.
        Initialize();
        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateLotItem(Item);
        // [GIVEN] Positive adjustment Item journal line for the item, but with minus Qty
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 11, '');

        // [GIVEN] The Stored value is used to select 'Lot No' on StrMenu
        LibraryVariableStorage.Enqueue('Lot No');
        // [GIVEN] Scan 3 Lot No
        LibraryVariableStorage.Enqueue('LOT1');
        LibraryVariableStorage.Enqueue('LOT1');
        LibraryVariableStorage.Enqueue('LOT2');
        LibraryVariableStorage.Enqueue('LOT2');
        LibraryVariableStorage.Enqueue('LOT2');
        LibraryVariableStorage.Enqueue('LOT3');
        LibraryVariableStorage.Enqueue('stop');

        // [GIVEN] Test value of continuous Scanning page
        LibraryVariableStorage.Enqueue('LOT1');
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue('LOT2');
        LibraryVariableStorage.Enqueue(3);
        LibraryVariableStorage.Enqueue('LOT3');
        LibraryVariableStorage.Enqueue('');// Here the qty is 0, so set it as empty string

        LibraryVariableStorage.Enqueue(6);

        // [GIVEN] Test value of Item tracking page
        LibraryVariableStorage.Enqueue('LOT1');
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue('LOT2');
        LibraryVariableStorage.Enqueue(3);
        LibraryVariableStorage.Enqueue('LOT3');
        LibraryVariableStorage.Enqueue('');// Here the qty is 0, so set it as empty string

        LibraryVariableStorage.Enqueue(5);
        LibraryVariableStorage.Enqueue(6);

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines, true);

        // [Then] All page model will be handled
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler,ItemTrackingTypeStrMenuHandler,ContinuousScanningTestPageModalHandler')]
    procedure ContinuousScanLotNoInBoundReachMaxQtyTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Lot No]
        // Continuously scan the Lot number, and reach the max qty
        Initialize();
        // [GIVEN] Create Lot specific tracked item
        LibraryItemTracking.CreateLotItem(Item);
        // [GIVEN] Positive adjustment Item journal line for the item, but with minus Qty
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 5, '');

        // [GIVEN] The Stored value is used to select 'Serial No' on StrMenu
        LibraryVariableStorage.Enqueue('Lot No');
        // [GIVEN] Scan 3 Serial No
        LibraryVariableStorage.Enqueue('LOT1');
        LibraryVariableStorage.Enqueue('LOT1');
        LibraryVariableStorage.Enqueue('LOT2');
        LibraryVariableStorage.Enqueue('LOT2');
        LibraryVariableStorage.Enqueue('LOT2');

        // [GIVEN] Init ItemTrackingLines 
        asserterror CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines, true);

        // [Then] An error thrown
        Assert.ExpectedError(ScanQtyExceedMaximumMsg);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler,ItemTrackingTypeStrMenuHandler,ContinuousScanningTestPageModalHandler')]
    procedure ContinuousScanLotNoInBoundReachMinusMaxQtyTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Lot No]
        // Continuously scan the Lot number with minus qty, and reach the max qty
        Initialize();
        // [GIVEN] Create Lot specific tracked item
        LibraryItemTracking.CreateLotItem(Item);
        // [GIVEN] Positive adjustment Item journal line for the item, but with minus Qty
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", WorkDate(), Item."No.", -5, '');

        // [GIVEN] The Stored value is used to select 'Lot No' on StrMenu
        LibraryVariableStorage.Enqueue('Lot No');
        // [GIVEN] Scan 3 Serial No
        LibraryVariableStorage.Enqueue('LOT1');
        LibraryVariableStorage.Enqueue('LOT2');
        LibraryVariableStorage.Enqueue('LOT3');
        LibraryVariableStorage.Enqueue('LOT4');
        LibraryVariableStorage.Enqueue('LOT5');

        // [GIVEN] Init ItemTrackingLines 
        asserterror CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines, true);

        // [Then] An error thrown
        Assert.ExpectedError(ScanQtyExceedMaximumMsg);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler,ItemTrackingTypeStrMenuHandler,ContinuousScanningTestPageModalHandler')]
    procedure ContinuousScanDulpicatedLotNoInBoundMinusQtyTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Lot No]
        // Continuously scan the Lot number with minus qty, and reach the max qty
        Initialize();
        // [GIVEN] Create Lot specific tracked item
        LibraryItemTracking.CreateLotItem(Item);
        // [GIVEN] Positive adjustment Item journal line for the item, but with minus Qty
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", -5, '');

        // [GIVEN] The Stored value is used to select 'Lot No' on StrMenu
        LibraryVariableStorage.Enqueue('Lot No');
        // [GIVEN] Scan 3 Serial No
        LibraryVariableStorage.Enqueue('LOT1');
        LibraryVariableStorage.Enqueue('Lot1');

        // [GIVEN] Init ItemTrackingLines 
        asserterror CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines, true);

        // [Then] An error thrown
        Assert.ExpectedError('already exists');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler,ItemTrackingTypeStrMenuHandler,ContinuousScanningTestPageModalHandler,ConfirmHandler')]
    procedure ContinuousScanPackageNoInBoundTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Serial No]
        // Continuously scan the serial number, and all the quantity should be set to 1.
        Initialize();
        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateLotItem(Item);
        // [GIVEN] Positive adjustment Item journal line for the item, but with minus Qty
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 11, '');

        // [GIVEN] The Stored value is used to select 'Package No' on StrMenu
        LibraryVariableStorage.Enqueue('Package No');
        // [GIVEN] Scan 3 Serial No
        LibraryVariableStorage.Enqueue('PACK1');
        LibraryVariableStorage.Enqueue('PACK1');
        LibraryVariableStorage.Enqueue('PACK2');
        LibraryVariableStorage.Enqueue('PACK2');
        LibraryVariableStorage.Enqueue('PACK2');
        LibraryVariableStorage.Enqueue('PACK3');
        LibraryVariableStorage.Enqueue('stop');

        // [GIVEN] Test value of continuous Scanning page
        LibraryVariableStorage.Enqueue('PACK1');
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue('PACK2');
        LibraryVariableStorage.Enqueue(3);
        LibraryVariableStorage.Enqueue('PACK3');
        LibraryVariableStorage.Enqueue('');// Here the qty is 0, so set it as empty string

        LibraryVariableStorage.Enqueue(6);

        // [GIVEN] Test value of Item tracking page
        LibraryVariableStorage.Enqueue('PACK1');
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue('PACK2');
        LibraryVariableStorage.Enqueue(3);
        LibraryVariableStorage.Enqueue('PACK3');
        LibraryVariableStorage.Enqueue('');// Here the qty is 0, so set it as empty string

        LibraryVariableStorage.Enqueue(5);
        LibraryVariableStorage.Enqueue(6);

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines, true);

        // [Then] All page model will be handled
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler,ItemTrackingTypeStrMenuHandler,ContinuousScanningTestPageModalHandler')]
    procedure ContinuousScanPackageNoInBoundReachMaxQtyTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Package No]
        // Continuously scan the Lot number, and reach the max qty
        Initialize();
        // [GIVEN] Create Lot specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);
        // [GIVEN] Positive adjustment Item journal line for the item, but with minus Qty
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 5, '');

        // [GIVEN] The Stored value is used to select 'Serial No' on StrMenu
        LibraryVariableStorage.Enqueue('Package No');
        // [GIVEN] Scan 3 Serial No
        LibraryVariableStorage.Enqueue('PACK1');
        LibraryVariableStorage.Enqueue('PACK1');
        LibraryVariableStorage.Enqueue('PACK1');
        LibraryVariableStorage.Enqueue('PACK1');
        LibraryVariableStorage.Enqueue('PACK1');

        // [GIVEN] Init ItemTrackingLines 
        asserterror CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines, true);

        // [Then] An error thrown
        Assert.ExpectedError(ScanQtyExceedMaximumMsg);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler,ItemTrackingTypeStrMenuHandler,ContinuousScanningTestPageModalHandler')]
    procedure ContinuousScanPackageNoInBoundReachMinusMaxQtyTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Package No]
        // Continuously scan the Lot number with minus qty, and reach the max qty
        Initialize();
        // [GIVEN] Create Lot specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);
        // [GIVEN] Positive adjustment Item journal line for the item, but with minus Qty
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", WorkDate(), Item."No.", -5, '');

        // [GIVEN] The Stored value is used to select 'Serial No' on StrMenu
        LibraryVariableStorage.Enqueue('Package No');
        // [GIVEN] Scan 3 Package No
        LibraryVariableStorage.Enqueue('PACK1');
        LibraryVariableStorage.Enqueue('PACK2');
        LibraryVariableStorage.Enqueue('PACK3');
        LibraryVariableStorage.Enqueue('PACK4');
        LibraryVariableStorage.Enqueue('PACK5');

        // [GIVEN] Init ItemTrackingLines 
        asserterror CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines, true);

        // [Then] An error thrown
        Assert.ExpectedError(ScanQtyExceedMaximumMsg);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler,ItemTrackingTypeStrMenuHandler,ContinuousScanningTestPageModalHandler')]
    procedure ContinuousScanDulpicatedPackageNoInBoundMinusQtyTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Package No]
        // Continuously scan the Lot number with minus qty, and scanned two dulplicated Lot
        Initialize();
        // [GIVEN] Create Lot specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);
        // [GIVEN] Positive adjustment Item journal line for the item, but with minus Qty
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", -5, '');

        // [GIVEN] The Stored value is used to select 'Serial No' on StrMenu
        LibraryVariableStorage.Enqueue('Package No');
        // [GIVEN] Scan 3 Serial No
        LibraryVariableStorage.Enqueue('PACK1');
        LibraryVariableStorage.Enqueue('PACK1');

        // [GIVEN] Init ItemTrackingLines 
        asserterror CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines, true);

        // [Then] An error thrown
        Assert.ExpectedError('already exists');
    end;

    local procedure Initialize()
    begin
        LibrarytestInitialize.OnTestInitialize(Codeunit::"Item Tracking Test");
        LibraryVariableStorage.Clear();
    end;

    procedure CreateItemTrackingLines(var ItemJournalLine: Record "Item Journal Line"; var ItemTrackingLines: Page Microsoft.Inventory.Tracking."Item Tracking Lines"; DestMode: Boolean)
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
    begin
        ItemJnlLineReserve.InitFromItemJnlLine(TrackingSpecification, ItemJournalLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ItemJournalLine."Posting Date");
        ItemTrackingLines.SetInbound(ItemJournalLine.IsInbound());
        ItemTrackingLines.SetContinuousScanningMode(DestMode);
        ItemTrackingLines.RunModal();
    end;

    local procedure CreateItemJournalLineWithItemTrackingOnLines(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Qty: Integer)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectItemJournal(ItemJournalBatch);
        ItemJournalBatch."Item Tracking on Lines" := true;
        ItemJournalBatch.Modify();
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, EntryType, ItemNo, Qty);
    end;

    local procedure SelectItemJournal(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    // Check the content of ItemTrackingLine.
    // If it satisfies the data in storage, return true
    // Otherwise returns false.
    local procedure CheckContentOfItemTrackingLine(var ItemTrackingLinesTestPage: TestPage "Item Tracking Lines"): Boolean
    begin
        if ItemTrackingLinesTestPage.First() then
            repeat
                if ItemTrackingLinesTestPage."Serial No.".Value() <> '' then
                    Assert.AreEqual(LibraryVariableStorage.DequeueText(), ItemTrackingLinesTestPage."Serial No.".Value(), 'Serial No are not the same.')
                else
                    if ItemTrackingLinesTestPage."Lot No.".Value() <> '' then
                        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ItemTrackingLinesTestPage."Lot No.".Value(), 'Lot No are not the same.')
                    else
                        if ItemTrackingLinesTestPage."Package No.".Value() <> '' then
                            Assert.AreEqual(LibraryVariableStorage.DequeueText(), ItemTrackingLinesTestPage."Package No.".Value(), 'Package No are not the same.')
                        else
                            break;
                Assert.AreEqual(LibraryVariableStorage.DequeueText(), ItemTrackingLinesTestPage."Quantity (Base)".Value(), 'Qty are not the same.');
            until not ItemTrackingLinesTestPage.Next();

        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ItemTrackingLinesTestPage.Quantity_ItemTracking.Value(), 'Quantity_ItemTracking is incorrect.');
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ItemTrackingLinesTestPage.Quantity3.Value(), 'Quantity3 is incorrect.');
    end;

    local procedure CheckContentOfContinuousScanningTestPage(var ContinuousItemTracking: TestPage "Continuous Item Tracking"): Boolean
    begin
        if ContinuousItemTracking.Result.First() then
            repeat
                if ContinuousItemTracking.Result."Serial No.".Visible() then
                    Assert.AreEqual(LibraryVariableStorage.DequeueText(), ContinuousItemTracking.Result."Serial No.".Value(), 'Serial No are not the same.');
                if ContinuousItemTracking.Result."Lot No.".Visible() then
                    Assert.AreEqual(LibraryVariableStorage.DequeueText(), ContinuousItemTracking.Result."Lot No.".Value(), 'Lot No are not the same.');
                if ContinuousItemTracking.Result."Package No.".Visible() then
                    Assert.AreEqual(LibraryVariableStorage.DequeueText(), ContinuousItemTracking.Result."Package No.".Value(), 'Package No are not the same.');

                Assert.AreEqual(LibraryVariableStorage.DequeueText(), ContinuousItemTracking.Result."Quantity (Base)".Value(), 'Qty are not the same.');
            until not ContinuousItemTracking.Result.Next();

        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ContinuousItemTracking."Available Qty.".Value(), 'Available Qty is incorrect.');
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinePageModalHandler(var ItemTrackingLinesTestPage: TestPage "Item Tracking Lines")
    begin
        Assert.IsTrue(ItemTrackingLinesTestPage."Scan multiple".Visible(), 'The button should be visible!');
        ItemTrackingLinesTestPage."Scan multiple".Invoke();
        CheckContentOfItemTrackingLine(ItemTrackingLinesTestPage);
    end;

    [StrMenuHandler]
    procedure ItemTrackingTypeStrMenuHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        case LibraryVariableStorage.DequeueText() of
            'Serial No':
                Choice := 1;
            'Lot No':
                Choice := 2;
            'Package No':
                Choice := 3;
        end;
    end;

    [MessageHandler]
    procedure MessageHandler(Msg: Text[1024])
    begin
        Assert.AreEqual(Msg, 'Tracking specification with Serial No. 1 already exists', 'Error Msg is not correct!');
    end;

    [MessageHandler]
    procedure ReachMaximumQtyMessageHandler(Msg: Text[1024])
    begin
        Assert.IsSubstring(Msg, 'Item tracking is successfully defined for quantity');
    end;


    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        if (Question.Contains('Confirm You do not have enough inventory to meet the demand for items in one or more lines.')) then
            Reply := true
        else
            if (Question.Contains('Confirm One or more lines have tracking specified, but Quantity (Base) is zero. If you continue, data on these lines will be lost. Do you want to close the page?')) then
                Reply := true;
    end;

    [ModalPageHandler]
    procedure ContinuousScanningTestPageModalHandler(var ContinuousScanningPage: TestPage "Continuous Item Tracking")
    var
        temp: Text;
    begin
        temp := LibraryVariableStorage.DequeueText();
        if temp <> 'stop' then
            ContinuousScanningPage."Scanning Area".SetValue(temp)
        else
            CheckContentOfContinuousScanningTestPage(ContinuousScanningPage);
        ContinuousScanningPage.Ok().Invoke();
    end;
}

