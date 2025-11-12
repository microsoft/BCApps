namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

codeunit 137214 CameraBarcodeScanItemTrackTest
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Camera Barcode Scanning]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibrarytestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        ConfirmHandlerReply: Boolean;
        ExpTrueButFalseErr: Label 'The expected value is true but now is false!';
        ExpFalseButTrueErr: Label 'The expected value is false but now is true!';

    local procedure CreateItemTrackingLines(var ItemJournalLine: Record "Item Journal Line"; var ItemTrackingLines: Page "Item Tracking Lines")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
    begin
        ItemJnlLineReserve.InitFromItemJnlLine(TrackingSpecification, ItemJournalLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ItemJournalLine."Posting Date");
        ItemTrackingLines.SetInbound(ItemJournalLine.IsInbound());
        ItemTrackingLines.RunModal();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContinuousScanSerialNoInBoundTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Serial No]
        // Continuously scan the serial number, and all the quantity should be set to 1.
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Serial1
        ItemTrackingLines.ScanSerialNoInBound('Serial1');
        // [THEN] The qty of Serial1 is 1  
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 1);
        // [GIVEN] Scan Serial2
        ItemTrackingLines.ScanSerialNoInBound('Serial2');
        // [THEN] The qty of Serial2 is 1  
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 1);
        // [GIVEN] Scan Serial3
        ItemTrackingLines.ScanSerialNoInBound('Serial3');
        // [THEN] The qty of Serial3 is 1  
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 1);

        // [THEN] Now there are five lines in item tracking lines.
        Assert.AreEqual(3, ItemTrackingLines.CountLines(), 'After test, there should be five records inserted.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContinuousScanSerialNoInBoundWithDulplicatedSerialNoTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Serial No]
        // Continuously scan the serial number with dulpicalted serial number, throw new error message and all the quantity should be set to 1.
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in ItemTrackingLine
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Serial No. Serial1
        ItemTrackingLines.ScanSerialNoInBound('Serial1');

        // [THEN] Now the quantity of Serial1 is 1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 1);

        // [GIVEN] Scan Serial No. Serial2
        ItemTrackingLines.ScanSerialNoInBound('Serial2');

        // [THEN] Now the initial quantity of every line is 1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 1);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be two records inserted.');

        // [GIVEN] Scan 'Serial1' again 
        asserterror ItemTrackingLines.ScanSerialNoInBound('Serial2');

        // [THEN] Get error message. 
        Assert.ExpectedError('Serial No. SERIAL2 already exists.');

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be two records inserted.');

        // [THEN] Now the initial quantity of every line is 1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContinuousScanSerialNoInBoundMinusTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Serial No]
        // Continuously scan the serial number with a minus qty ItemJnlLine, and quantity should be set to -1.
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", -10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Serial1
        ItemTrackingLines.ScanSerialNoInBound('Serial1');
        // [THEN] Now the quantity of Serial1 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Serial2
        ItemTrackingLines.ScanSerialNoInBound('Serial2');
        // [THEN] Now the quantity of Serial2 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Serial3
        ItemTrackingLines.ScanSerialNoInBound('Serial3');
        // [THEN] Now the quantity of Serial3 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [THEN] Now there are 3 lines in item tracking lines.
        Assert.AreEqual(3, ItemTrackingLines.CountLines(), 'After test, there should be 3 records inserted.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContinuousScanSerialNoInBoundWithDulplicatedSerialNoMinusTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Serial No]
        // Continuously scan the serial number with dulpicalted serial number and minus qty itemtrackingline, throw new error message and all the quantity should be set to -1.
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", -10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Serial No. Serial1
        ItemTrackingLines.ScanSerialNoInBound('Serial1');
        // [THEN] Now the quantity of Serial1 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Serial No. Serial2
        ItemTrackingLines.ScanSerialNoInBound('Serial2');
        // [THEN] Now the quantity of Serial2 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Serial No. Serial3
        ItemTrackingLines.ScanSerialNoInBound('Serial3');
        // [THEN] Now the quantity of Serial3 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Try to Add Scan Serial No. Serial1 again
        asserterror ItemTrackingLines.ScanSerialNoInBound('Serial1');
        // [THEN] Get error message. 
        Assert.ExpectedError('Tracking specification with Serial No. SERIAL1 already exists.');
        // [THEN] Now the quantity of Serial1 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Try to Add Scan Serial No. Serial2 again
        asserterror ItemTrackingLines.ScanSerialNoInBound('Serial2');
        // [THEN] Get error message. 
        Assert.ExpectedError('Tracking specification with Serial No. SERIAL2 already exists.');
        // [THEN] Now the quantity of Serial2 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Try to Add Scan Serial No. Serial3 again
        asserterror ItemTrackingLines.ScanSerialNoInBound('Serial3');
        // [THEN] Get error message. 
        Assert.ExpectedError('Tracking specification with Serial No. SERIAL3 already exists.');
        // [THEN] Now the quantity of Serial3 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContinuousScanLotNoInBoundTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Lot No]
        // [SCENARIO] Continuously scan the lot number, and all the quantity should be set to 0.

        Initialize();

        // [GIVEN] Create 'Lot No' specific tracked item
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Now the quantity of Lot1 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [GIVEN] Scan Lot2
        ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Now the quantity of Lot2 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [GIVEN] Scan Lot3
        ItemTrackingLines.ScanLotNoInBound('Lot3');
        // [THEN] Now the quantity of Lot3 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [THEN] Now there are 3 lines in item tracking lines.
        Assert.AreEqual(3, ItemTrackingLines.CountLines(), 'After test, there should be 3 record inserted.');
    end;


    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContinuousScanLotNoInBoundWithDulplicatedLotNoTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Lot No]
        // [SCENARIO] Continuously scan the lot number with dulplicated lot numbers.
        // [SCENARIO] The rule is: for the first time scan, set qty as 0, for the second time, it should be set to 2, and then 3,4,5...

        Initialize();

        // [GIVEN] Create 'Lot No' specific tracked item
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Now the quantity of Lot1 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [GIVEN] Scan Lot2
        ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Now the quantity of Lot2 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be two records inserted.');

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Now the quantity of Lot1 is 2.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 2);

        // [GIVEN] Scan Lot2 
        ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Now the quantity of Lot2 is 2.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 2);

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Now the quantity of Lot1 is 3.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 3);

        // [GIVEN] Scan Lot2 
        ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Now the quantity of Lot2 is 3.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 3);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be 3 records inserted.');
    end;


    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContinuousScanLotNoInPOWithDulplicatedLotNoTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Lot No]
        // [SCENARIO] Continuously scan the lot number with dulplicated lot numbers.
        // [SCENARIO] The rule is: for the first time scan, set qty as 0, for the second time, it should be set to 2, and then 3,4,5...

        Initialize();

        // [GIVEN] Create 'Lot No' specific tracked item
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, WorkDate(), Item."No.", 10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Now the quantity of Lot1 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [GIVEN] Scan Lot2
        ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Now the quantity of Lot2 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be two records inserted.');

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Now the quantity of Lot1 is 2.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 2);

        // [GIVEN] Scan Lot2 
        ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Now the quantity of Lot2 is 2.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 2);

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Now the quantity of Lot1 is 3.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 3);

        // [GIVEN] Scan Lot2 
        ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Now the quantity of Lot2 is 3.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 3);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be 3 records inserted.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContinuousScanLotNoInBoundMinusTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Lot No]
        // [SCENARIO] Continuously scan the lot number with a minus qty ItemJnlLine, and quantity should be set to -1.
        Initialize();

        // [GIVEN] Create 'Lot No' specific tracked item
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", -10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Now the quantity of Lot1 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Lot2 
        ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Now the quantity of Lot2 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot3');
        // [THEN] Now the quantity of Lot3 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [THEN] Now there are 3 lines in item tracking lines.
        Assert.AreEqual(3, ItemTrackingLines.CountLines(), 'After test, there should be 3 record inserted.');
    end;


    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContinuousScanLotNoInBoundWithDulplicatedLotNoMinusTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Lot No]
        // [SCENARIO] Continuously scan the lot number with dulplicated lot number in minus qty itemTrackingLines.
        Initialize();

        // [GIVEN] Create 'Lot No' specific tracked item
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", -10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Now the quantity of Lot1 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Lot2 
        ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Now the quantity of Lot2 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be two records inserted.');

        // [GIVEN] Scan Lot1 
        asserterror ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Get error message. The error message contains Lot No. Lot1.
        Assert.ExpectedError('Lot No. LOT1');
        // [THEN] Now the quantity of Lot1 is still -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Lot2 
        asserterror ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Get error message. 
        Assert.ExpectedError('Lot No. LOT2');
        // [THEN] Now the quantity of Lot2 is still -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be 2 records inserted.');
    end;

    local procedure CheckQuantityInTrackingSpecification(ItemTrackingLines: Page "Item Tracking Lines"; TrackingSpecification: Record "Tracking Specification"; expectedQuantity: Integer)
    begin
        ItemTrackingLines.GetRecord(TrackingSpecification);
        Assert.AreEqual(expectedQuantity, TrackingSpecification."Quantity (Base)", 'The expected quantity is unequal to current quantity!');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContinuousScanPackageNoInBoundTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Lot No]
        // [SCENARIO] Continuously scan the lot number
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Add Scan Serial No. five times
        ItemTrackingLines.ScanPackageNoInBound('Pack1');
        // [THEN] Now the initial quantity of every line is 3.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        ItemTrackingLines.ScanPackageNoInBound('Pack2');
        // [THEN] Now the initial quantity of every line is 3.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be two records inserted.');
    end;


    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContinuousScanPackageNoInBoundWithDulplicatedPackageNoTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Package No]
        // [SCENARIO] Continuously scan the package number, and all the quantity should be set to 0.
        Initialize();

        // [GIVEN] Create item 
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Pack1
        ItemTrackingLines.ScanPackageNoInBound('Pack1');
        // [THEN] Now the quantity of Pack1 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [GIVEN] Scan Pack2
        ItemTrackingLines.ScanPackageNoInBound('Pack2');
        // [THEN] Now the quantity of Pack2 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [GIVEN] Scan Pack1
        ItemTrackingLines.ScanPackageNoInBound('Pack1');
        // [THEN] Now the quantity of Pack1 is 2.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 2);

        // [GIVEN] Scan Pack2
        ItemTrackingLines.ScanPackageNoInBound('Pack2');
        // [THEN] Now the quantity of Pack2 is 2.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 2);

        // [GIVEN] Scan Pack1
        ItemTrackingLines.ScanPackageNoInBound('Pack1');
        // [THEN] Now the quantity of Pack1 is 3.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 3);

        // [GIVEN] Scan Pack2
        ItemTrackingLines.ScanPackageNoInBound('Pack2');
        // [THEN] Now the quantity of Pack2 is 3.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 3);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be two records inserted.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContinuousScanPackageNoInBoundMinusTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [package No]
        // [SCENARIO] Continuously scan the package number with a minus qty ItemJnlLine, and quantity should be set to -1.
        Initialize();

        // [GIVEN] Create item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", -10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Pack1.
        ItemTrackingLines.ScanPackageNoInBound('Pack1');
        // [THEN] Now the quantity of Pack1 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Pack2.
        ItemTrackingLines.ScanPackageNoInBound('Pack2');
        // [THEN] Now the quantity of Pack2 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be two records inserted.');
    end;


    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContinuousScanPackageNoInBoundWithDulplicatedPackageNoMinusTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Package No]
        // [SCENARIO] Continuously scan the dulplicated package numbers with a minus qty ItemJnlLine, and quantity should be set to -1.
        Initialize();

        // [GIVEN] Create item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", -10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Pack1.
        ItemTrackingLines.ScanPackageNoInBound('Pack1');
        // [THEN] Now the quantity of Pack1 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Pack2.
        ItemTrackingLines.ScanPackageNoInBound('Pack2');
        // [THEN] Now the quantity of Pack2 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Pack1 again.
        asserterror ItemTrackingLines.ScanPackageNoInBound('Pack1');
        // [THEN] Get error message. 
        Assert.ExpectedError('Package PACK1');
        // [THEN] Now the quantity of Pack1 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Pack2 again.
        asserterror ItemTrackingLines.ScanPackageNoInBound('Pack2');
        // [THEN] Get error message. 
        Assert.ExpectedError('Package PACK2');
        // [THEN] Now the quantity of Pack2 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be two records inserted.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContinuousScanSerialNoOutBoundWithExistingItemTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [OutBound] [Serial No]
        // Continuously scan the serial number, and set the corresponding quantity to 1 if serial no has been post.
        // Set the quantity to 0 if it is not post.
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        CreateItemJournalLineWithItemTrackingOnLines(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);

        ItemJournalLine."Serial No." := 'Serial1';
        ItemJournalLine.Modify(true);

        // [GIVEN] Post this journal line
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Add items 
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", WorkDate(), Item."No.", 10, '');
        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        //[GIVEN] Scan Serial1
        ItemTrackingLines.ScanSerialNoOutBound('Serial1');
        // [THEN] Now the quantity of Serial1 is 1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 1);

        //[GIVEN] Scan Serial2
        ItemTrackingLines.ScanSerialNoOutBound('Serial2');
        // [THEN] Now the quantity of Serial1 is 2.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

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

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContinuousScanSerialNoOutBoundWithOutExistingItemTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [OutBound] [Serial No]
        // Continuously scan the serial number for out bound, the serail number doesn't exist, so init it with 0.
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Add items 
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", WorkDate(), Item."No.", 10, '');
        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [GIVEN] Scan Serial1.
        ItemTrackingLines.ScanSerialNoOutBound('Serial1');
        // [THEN] Now the quantity of Serial1 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [GIVEN] Scan Serial2.
        ItemTrackingLines.ScanSerialNoOutBound('Serial2');
        // [THEN] Now the quantity of Serial2 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContinuousScanLotNoOutBoundWithOutExistingItemTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [OutBound] [Lot No]
        // Continuously scan the serial number for out bound, the serail number doesn't exist, so init it with 0.
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Add items 
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", WorkDate(), Item."No.", 10, '');
        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [GIVEN] Scan Lot1.
        ItemTrackingLines.ScanLotNoOutBound('Lot1');
        // [THEN] Now the quantity of Lot1 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [GIVEN] Scan Lot2.
        ItemTrackingLines.ScanLotNoOutBound('Lot2');
        // [THEN] Now the quantity of Lot2 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContinuousScanPackageNoOutBoundWithOutExistingItemTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [OutBound] [Package No]
        // Continuously scan the serial number for out bound, the serail number doesn't exist, so init it with 0.
        Initialize();

        // [GIVEN] Create item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Add items 
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", WorkDate(), Item."No.", 10, '');
        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [GIVEN] Scan Pack1.
        ItemTrackingLines.ScanPackageNoOutBound('Pack1');
        // [THEN] Now the quantity of Pack1 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [GIVEN] Scan Pack2.
        ItemTrackingLines.ScanPackageNoOutBound('Pack2');
        // [THEN] Now the quantity of Pack1 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure CheckItemTrackingLineIsInBoundWithItemJournalTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner]
        // When open item tracking lines with item journal, the inbound or outbound status depends on the subtype of item journal.
        // Positive Adjmt and Purchase is inbound
        // Negative Adjmt and Sale is outbound 
        Initialize();

        // [GIVEN] Create item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Create ItemJnlLine with subtype Positive Adjmt
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, '');
        // [GIVEN] Create ItemJnlLine  
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);
        // [THEN] Is inbound Scenario
        Assert.IsTrue(ItemTrackingLines.CheckItemtrackingLineIsInBoundForBarcodeScanning(), ExpTrueButFalseErr);

        // [GIVEN] Create ItemJnlLine with subtype Purchase
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Purchase", WorkDate(), Item."No.", 10, '');
        // [GIVEN] Create ItemJnlLine  
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);
        // [THEN] Is inbound Scenario
        Assert.IsTrue(ItemTrackingLines.CheckItemtrackingLineIsInBoundForBarcodeScanning(), ExpTrueButFalseErr);

        // [GIVEN] Create ItemJnlLine with subtype Negative Adjmt
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", WorkDate(), Item."No.", 10, '');
        // [GIVEN] Create ItemJnlLine  
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);
        // [THEN] Is outBound Scenario
        Assert.IsFalse(ItemTrackingLines.CheckItemtrackingLineIsInBoundForBarcodeScanning(), ExpFalseButTrueErr);

        // [GIVEN] Create ItemJnlLine with subtype Sale
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Sale", WorkDate(), Item."No.", 10, '');
        // [GIVEN] Create ItemJnlLine  
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);
        // [THEN] Is outBound Scenario
        Assert.IsFalse(ItemTrackingLines.CheckItemtrackingLineIsInBoundForBarcodeScanning(), ExpFalseButTrueErr);

        // [GIVEN] Create ItemJnlLine with subtype Consumption
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::Consumption, WorkDate(), Item."No.", 10, '');
        // [GIVEN] Create ItemJnlLine  
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] Is outBound Scenario
        Assert.IsFalse(ItemTrackingLines.CheckItemtrackingLineIsInBoundForBarcodeScanning(), ExpFalseButTrueErr);

        // [GIVEN] Create ItemJnlLine with subtype Consumption
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::Output, WorkDate(), Item."No.", 10, '');
        // [GIVEN] Create ItemJnlLine  
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] Is inBound Scenario
        Assert.IsTrue(ItemTrackingLines.CheckItemtrackingLineIsInBoundForBarcodeScanning(), ExpFalseButTrueErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure CheckItemTrackingLineIsInBoundWithPurchaseLineTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner]
        // When open item tracking lines with purchase order, but it's subtype is not Order, error is not thrown
        Initialize();

        // [GIVEN] Create item 
        LibraryItemTracking.CreateSerialItem(Item);
        // [GIVEN] Init Purchase Header 
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        // [GIVEN] Init Purchase Line
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, "Purchase Document Type"::Invoice, Item."No.", 1);
        // [GIVEN] Init Item tracking Lines
        PurchLineReserve.InitFromPurchLine(TrackingSpecification, PurchaseLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ItemJournalLine."Posting Date");
        ItemTrackingLines.SetInbound(ItemJournalLine.IsInbound());
        ItemTrackingLines.RunModal();
        // [When] Run the page and check it is inbound or outbound
        ItemTrackingLines.CheckItemtrackingLineIsInBoundForBarcodeScanning();
        // [Then] Error is not thrown
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure CheckItemTrackingLineIsInBoundWithSalesLineTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner]
        // When open item tracking lines with sales order, it should be reckoned as outbound.
        Initialize();

        // [GIVEN] Create Sales Header
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        // [GIVEN] Create item 
        LibraryItemTracking.CreateSerialItem(Item);
        // [GIVEN] Create SalesLine
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        // [GIVEN] Init ItemTrackingLines
        SalesLineReserve.InitFromSalesLine(TrackingSpecification, SalesLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ItemJournalLine."Posting Date");
        ItemTrackingLines.SetInbound(ItemJournalLine.IsInbound());
        ItemTrackingLines.RunModal();
        //[Then] It is outbound scenario.
        Assert.IsFalse(ItemTrackingLines.CheckItemtrackingLineIsInBoundForBarcodeScanning(), ExpFalseButTrueErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalWithQtyZeroHandler,ExitingWithQtyZeroComfirmHandler')]
    procedure WarningOfBlankQtyLinesWhenExitingWithYesReplyTest()
    var
        Item: Record Item;
        TrackingSpecification: Record "Tracking Specification";
        ItemJournalLine: Record "Item Journal Line";
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO][DELIVERABLE 481052][Barcode Scanner] 
        // When user exits the page "Item Tracking Lines", if any line's qty is 0, inform user.
        Initialize();

        // [GIVEN] Create item
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Add items 
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, '');

        // [GIVEN] Init ItemTrackingLines
        ItemJnlLineReserve.InitFromItemJnlLine(TrackingSpecification, ItemJournalLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ItemJournalLine."Posting Date");
        ItemTrackingLines.SetInbound(ItemJournalLine.IsInbound());

        // [GIVEN] Choose 'yes' for ConfirmDialog 
        ConfirmHandlerReply := true;

        // [THEN] Open the Item Tracking Lines, and call the ItemTrackingLinePageModalWithQtyZeroHandler, an error will show up.
        ItemJournalLine.OpenItemTrackingLines(false);
    end;

    local procedure Initialize()
    begin
        LibrarytestInitialize.OnTestInitialize(Codeunit::"Item Tracking Test");
    end;

    [ConfirmHandler]
    procedure ExitingWithQtyZeroComfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := ConfirmHandlerReply;
        Assert.IsSubstring(Question, 'One or more lines have tracking specified, but Quantity (Base) is zero.');
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinePageModalWithQtyZeroHandler(var ItemTrackingLinesTestPage: TestPage "Item Tracking Lines")
    begin
        // [WHEN] User enters the three lot number with Qty=0
        ItemTrackingLinesTestPage.New();
        ItemTrackingLinesTestPage."Lot No.".SetValue('Lot1');
        ItemTrackingLinesTestPage."Quantity (Base)".SetValue(0);
        ItemTrackingLinesTestPage.New();
        ItemTrackingLinesTestPage."Lot No.".SetValue('Lot2');
        ItemTrackingLinesTestPage."Quantity (Base)".SetValue(0);
        ItemTrackingLinesTestPage.New();
        ItemTrackingLinesTestPage."Lot No.".SetValue('Lot3');
        ItemTrackingLinesTestPage."Quantity (Base)".SetValue(0);
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinePageModalHandler(var ItemTrackingLinesTestPage: TestPage "Item Tracking Lines")
    begin
    end;
}

