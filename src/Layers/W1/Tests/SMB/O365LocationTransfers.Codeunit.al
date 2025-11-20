codeunit 137281 "O365 Location Transfers"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    trigger OnRun()
    begin
        // [FEATURE] [O365] [Transfer Order]
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTemplates: Codeunit "Library - Templates";
        isInitialized: Boolean;
        WrongInventoryErr: Label 'The amount of inventory transfered is incorrect.';
        DirectTransferMustBeEditableErr: Label 'Direct Transfer must be editable.';

    [Test]
    [Scope('OnPrem')]
    procedure CreateAndPostTransferOrder()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        LocationFrom: Code[10];
        LocationTo: Code[10];
        LocationInTransit: Code[10];
        OriginalQuantity: Decimal;
        TransferQuantity: Decimal;
    begin
        Initialize();
        // Setup

        CreateLocations(LocationFrom, LocationTo, LocationInTransit);
        OriginalQuantity := LibraryRandom.RandDecInDecimalRange(1, 10, 2);
        CreateAndPostItem(Item, LocationFrom, OriginalQuantity);
        TransferQuantity := LibraryRandom.RandDecInDecimalRange(1, OriginalQuantity, 2);

        // Exercise
        LibraryLowerPermissions.SetO365INVCreate();
        Clear(TransferLine);
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom, LocationTo, LocationInTransit);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", TransferQuantity);
        LibraryLowerPermissions.AddO365INVPost();
        LibraryLowerPermissions.AddJobs();
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // Verify
        ValidateInventoryForLocation(Item, LocationTo, TransferQuantity);
        ValidateInventoryForLocation(Item, LocationFrom, OriginalQuantity - TransferQuantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAndPostTransferOrderMultipleLines()
    var
        TransferHeader: Record "Transfer Header";
        Item1: Record Item;
        Item2: Record Item;
        TransferLine: Record "Transfer Line";
        LocationFrom: Code[10];
        LocationInTransit: Code[10];
        LocationTo: Code[10];
        FirstOriginalQuantity: Decimal;
        FirstTransferQuantity: Decimal;
        SecondOriginalQuantity: Decimal;
        SecondTransferQuantity: Decimal;
    begin
        Initialize();
        // Setup
        CreateLocations(LocationFrom, LocationTo, LocationInTransit);

        FirstOriginalQuantity := LibraryRandom.RandDecInDecimalRange(1, 10, 2);
        CreateAndPostItem(Item1, LocationFrom, FirstOriginalQuantity);
        SecondOriginalQuantity := LibraryRandom.RandDecInDecimalRange(1, 10, 2);
        CreateAndPostItem(Item2, LocationFrom, SecondOriginalQuantity);

        FirstTransferQuantity := LibraryRandom.RandDecInDecimalRange(1, FirstOriginalQuantity, 2);
        SecondTransferQuantity := LibraryRandom.RandDecInDecimalRange(1, SecondOriginalQuantity, 2);

        // Exercise
        LibraryLowerPermissions.SetO365INVCreate();
        Clear(TransferLine);
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom, LocationTo, LocationInTransit);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item1."No.", FirstTransferQuantity);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item2."No.", SecondTransferQuantity);
        LibraryLowerPermissions.AddO365INVPost();
        LibraryLowerPermissions.AddJobs();
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // Verify
        ValidateInventoryForLocation(Item1, LocationTo, FirstTransferQuantity);
        ValidateInventoryForLocation(Item1, LocationFrom, FirstOriginalQuantity - FirstTransferQuantity);
        ValidateInventoryForLocation(Item2, LocationTo, SecondTransferQuantity);
        ValidateInventoryForLocation(Item2, LocationFrom, SecondOriginalQuantity - SecondTransferQuantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAndPostDirectTransferOrder()
    var
        TransferHeader: Record "Transfer Header";
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        LocationFrom: Code[10];
        LocationTo: Code[10];
        OriginalQuantity: Decimal;
        TransferQuantity: Decimal;
    begin
        Initialize();
        // Setup
        LocationFrom := CreateLocationWithInventoryPostingSetup(false);
        LocationTo := CreateLocationWithInventoryPostingSetup(false);

        OriginalQuantity := LibraryRandom.RandDecInDecimalRange(1, 10, 2);
        CreateAndPostItem(Item, LocationFrom, OriginalQuantity);
        TransferQuantity := LibraryRandom.RandDecInDecimalRange(1, OriginalQuantity, 2);

        // Exercise
        LibraryLowerPermissions.SetO365INVCreate();
        CreateDirectTransferHeader(TransferHeader, LocationFrom, LocationTo);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", TransferQuantity);
        LibraryLowerPermissions.AddO365INVPost();
        LibraryLowerPermissions.AddJobs();
        LibraryInventory.PostDirectTransferOrder(TransferHeader);

        // Verify
        ValidateInventoryForLocation(Item, LocationTo, TransferQuantity);
        ValidateInventoryForLocation(Item, LocationFrom, OriginalQuantity - TransferQuantity);
    end;

    [Test]
    [HandlerFunctions('NewItemStrMenuHandler,ItemTemplateModalPageHandler,ItemPageModalPageHandler')]
    [Scope('OnPrem')]
    procedure TransferOrderCreateNewItemOnNonExistingItemNo()
    var
        Item: Record Item;
        TransferOrder: TestPage "Transfer Order";
        FromLocation: Code[10];
        ToLocation: Code[10];
        InTransitLocation: Code[10];
        ItemNo: Code[20];
    begin
        // 1. Setup: Create three locations and a transfer order
        Initialize();
        CreateLocations(FromLocation, ToLocation, InTransitLocation);

        TransferOrder.OpenNew();
        TransferOrder."Transfer-from Code".SetValue(FromLocation);
        TransferOrder."Transfer-to Code".SetValue(ToLocation);
        TransferOrder."In-Transit Code".SetValue(InTransitLocation);

        // 2. Exercise: Set Item No. to a non-existent item no.
        LibraryLowerPermissions.SetO365INVCreate();
        LibraryLowerPermissions.AddItemCreate();
        ItemNo := LibraryUtility.GenerateGUID();
        TransferOrder.TransferLines."Item No.".SetValue(ItemNo);

        // 3. Verify: That the item was created
        Item.SetRange(Description, ItemNo);
        Assert.RecordCount(Item, 1);
        Item.FindFirst();
        TransferOrder.TransferLines.Description.AssertEquals(ItemNo);
        TransferOrder.TransferLines."Item No.".AssertEquals(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityToReceiveAutoSetInDirectTransfer()
    var
        TransferHeader: Record "Transfer Header";
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt";
        TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment";
        LocationFrom: Code[10];
        LocationTo: Code[10];
        OriginalQuantity: Decimal;
        TransferQuantity: Decimal;
    begin
        Initialize();
        // Setup
        LocationFrom := CreateLocationWithInventoryPostingSetup(false);
        LocationTo := CreateLocationWithInventoryPostingSetup(false);
        OriginalQuantity := LibraryRandom.RandDecInDecimalRange(2, 10, 2);
        CreateAndPostItem(Item, LocationFrom, OriginalQuantity);
        TransferQuantity := LibraryRandom.RandDecInDecimalRange(1, OriginalQuantity - 1, 2);
        CreateDirectTransferHeader(TransferHeader, LocationFrom, LocationTo);

        // Exercise
        LibraryLowerPermissions.SetO365INVCreate();
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", OriginalQuantity);

        // Verify
        TransferLine.TestField("Qty. to Ship", TransferLine.Quantity);
        TransferLine.TestField("Qty. to Receive", TransferLine."Qty. to Ship");

        // Exercise
        TransferLine.Validate("Qty. to Ship", TransferQuantity);

        // Verify
        TransferLine.TestField("Qty. to Receive", TransferQuantity);

        // Exercise
        TransferLine.Modify(true);
        LibraryLowerPermissions.AddO365INVPost();
        LibraryLowerPermissions.AddJobs();
        TransferOrderPostShipment.SetHideValidationDialog(true);
        TransferOrderPostShipment.Run(TransferHeader);

        // Verify
        TransferLine.TestField("Qty. to Receive", TransferQuantity);

        // Exercise
        TransferOrderPostReceipt.SetHideValidationDialog(true);
        TransferOrderPostReceipt.Run(TransferHeader);

        // Verify
        TransferLine.TestField("Qty. to Receive", TransferLine."Qty. to Ship");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferErrorWhenTransferFromLocationRequiresShipment()
    var
        TransferHeader: Record "Transfer Header";
        FromLocation: Record Location;
        ToLocation: Record Location;
    begin
        // [FEATURE] [Direct Transfer]
        // [SCENARIO 253751] Location with "Require Shipment" enabled should not be accepted in the "Transfer-from Code" of a direct transfer order

        Initialize();

        // [GIVEN] Location "L1" with "Require Shipment"
        LibraryWarehouse.CreateLocationWMS(FromLocation, false, false, false, false, true);
        // [GIVEN] Location "L2" without warehouse handling
        LibraryWarehouse.CreateLocation(ToLocation);

        LibraryLowerPermissions.SetO365INVCreate();

        // [GIVEN] Create transfer order from location "L1" to location "L2"
        // [WHEN] Enable "Direct Transfer" on the transfer order
        asserterror CreateDirectTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code);

        // [THEN] Error: "Require Shipment" must equal to 'No' in location
        Assert.ExpectedTestFieldError(FromLocation.FieldCaption("Require Shipment"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferErrorWhenTransferToLocationRequiresReceive()
    var
        TransferHeader: Record "Transfer Header";
        FromLocation: Record Location;
        ToLocation: Record Location;
    begin
        // [FEATURE] [Direct Transfer]
        // [SCENARIO 253751] Location with "Require Receive" enabled should not be accepted in the "Transfer-to Code" of a direct transfer order

        Initialize();

        // [GIVEN] Location "L1" without warehouse handling
        LibraryWarehouse.CreateLocation(FromLocation);
        // [GIVEN] Location "L2" with "Require Receive"
        LibraryWarehouse.CreateLocationWMS(ToLocation, false, false, false, true, false);

        LibraryLowerPermissions.SetO365INVCreate();

        // [GIVEN] Create transfer order from location "L1" to location "L2"
        // [WHEN] Enable "Direct Transfer" on the transfer order
        asserterror CreateDirectTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code);

        // [THEN] Error: "Require Receive" must equal to 'No' in location
        Assert.ExpectedTestFieldError(FromLocation.FieldCaption("Require Receive"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferErrorWhenTransferFromLocationRequiresPick()
    var
        TransferHeader: Record "Transfer Header";
        FromLocation: Record Location;
        ToLocation: Record Location;
    begin
        // [FEATURE] [Direct Transfer]
        // [SCENARIO 253751] Location with "Require Pick" enabled should not be accepted in the "Transfer-from Code" of a direct transfer order

        Initialize();

        // [GIVEN] Location "L1" with "Require Pick"
        LibraryWarehouse.CreateLocationWMS(FromLocation, false, false, true, false, false);
        // [GIVEN] Location "L2" without warehouse handling
        LibraryWarehouse.CreateLocation(ToLocation);

        LibraryLowerPermissions.SetO365INVCreate();

        // [GIVEN] Create transfer order from location "L1" to location "L2"
        // [WHEN] Enable "Direct Transfer" on the transfer order
        asserterror CreateDirectTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code);

        // [THEN] Error: "Require Pick" must equal to 'No' in location
        Assert.ExpectedTestFieldError(FromLocation.FieldCaption("Require Pick"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferErrorWhenTransferToLocationRequiresPutAway()
    var
        TransferHeader: Record "Transfer Header";
        FromLocation: Record Location;
        ToLocation: Record Location;
    begin
        // [FEATURE] [Direct Transfer]
        // [SCENARIO 253751] Location with "Require Put-away" enabled should not be accepted in the "Transfer-to Code" of a direct transfer order

        Initialize();

        // [GIVEN] Location "L1" without warehouse handling
        LibraryWarehouse.CreateLocation(FromLocation);
        // [GIVEN] Location "L2" with "Require Put-away"
        LibraryWarehouse.CreateLocationWMS(ToLocation, false, true, false, false, false);

        LibraryLowerPermissions.SetO365INVCreate();

        // [GIVEN] Create transfer order from location "L1" to location "L2"
        // [WHEN] Enable "Direct Transfer" on the transfer order
        asserterror CreateDirectTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code);

        // [THEN] Error: "Require Put-away" must equal to 'No' in location
        Assert.ExpectedTestFieldError(FromLocation.FieldCaption("Require Put-away"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferErrorWhenChangeTransferFromSimpleLocationToWhse()
    var
        Location: array[3] of Record Location;
        TransferHeader: Record "Transfer Header";
    begin
        // [FEATURE] [Direct Transfer]
        // [SCENARIO 253751] It should not be allowed to change transfer-from location to a location that requires outbound warehouse handling in a direct transfer order

        Initialize();

        // [GIVEN] Two locations "L1" and "L2" without warehouse handling
        LibraryWarehouse.CreateLocation(Location[1]);
        LibraryWarehouse.CreateLocation(Location[2]);
        // [GIVEN] Location "L3" with "Require Shipment" enabled
        LibraryWarehouse.CreateLocationWMS(Location[3], false, false, false, false, true);

        // [GIVEN] Create direct transfer from location "L1" to location "L2"
        LibraryLowerPermissions.SetO365INVCreate();
        CreateDirectTransferHeader(TransferHeader, Location[1].Code, Location[2].Code);

        // [WHEN] Change "Transfer-to Code" from "L1" to "L3"
        asserterror TransferHeader.Validate("Transfer-from Code", Location[3].Code);

        // [THEN] Error: "Require Shipment" must equal to 'No' in location
        Assert.ExpectedTestFieldError(Location[3].FieldCaption("Require Shipment"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferErrorWhenChangeTransferToSimpleLocationToWhse()
    var
        Location: array[3] of Record Location;
        TransferHeader: Record "Transfer Header";
    begin
        // [FEATURE] [Direct Transfer]
        // [SCENARIO 253751] It should not be allowed to change transfer-to location to a location that requires inbound warehouse handling in a direct transfer order

        Initialize();

        // [GIVEN] Two locations "L1" and "L2" without warehouse handling
        LibraryWarehouse.CreateLocation(Location[1]);
        LibraryWarehouse.CreateLocation(Location[2]);
        // [GIVEN] Location "L3" with "Require Receive" enabled
        LibraryWarehouse.CreateLocationWMS(Location[3], false, false, false, true, false);

        // [GIVEN] Create direct transfer from location "L1" to location "L2"
        LibraryLowerPermissions.SetO365INVCreate();
        CreateDirectTransferHeader(TransferHeader, Location[1].Code, Location[2].Code);

        // [WHEN] Change "Transfer-to Code" from "L1" to "L3"
        asserterror TransferHeader.Validate("Transfer-to Code", Location[3].Code);

        // [THEN] Error: "Require Receive" must equal to 'No' in location
        Assert.ExpectedTestFieldError(Location[3].FieldCaption("Require Receive"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseDirectTransferErrorTransferFromLocationRequiresShipment()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransferHeader: Record "Transfer Header";
    begin
        // [FEATURE] [Direct Transfer]
        // [SCENARIO 253751] It should not be allowed to post a direct transfer order if outbound warehouse handling was enabled on location after creating the order

        Initialize();

        // [GIVEN] Two locations "L1" and "L2" without warehouse handling
        LibraryWarehouse.CreateLocation(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);

        LibraryLowerPermissions.SetO365INVCreate();
        LibraryLowerPermissions.AddO365INVSetup();
        LibraryLowerPermissions.AddO365INVPost();
        // [GIVEN] Create direct transfer from location "L1" to location "L2"
        CreateDirectTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code);

        // [GIVEN] Enable "Require Shipment" in location "L1"
        FromLocation.Validate("Require Shipment", true);
        FromLocation.Modify(true);

        // [WHEN] Post the transfer order
        asserterror LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [THEN] Error: "Require Shipment" must equal to 'No' in location
        Assert.ExpectedTestFieldError(FromLocation.FieldCaption("Require Shipment"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseDirectTransferErrorTransferToLocationRequiresReceive()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransferHeader: Record "Transfer Header";
    begin
        // [FEATURE] [Direct Transfer]
        // [SCENARIO 253751] It should not be allowed to release a direct transfer order if inbound warehouse handling was enabled on location after creating the order

        Initialize();

        // [GIVEN] Two locations "L1" and "L2" without warehouse handling
        LibraryWarehouse.CreateLocation(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);

        LibraryLowerPermissions.SetO365INVCreate();
        LibraryLowerPermissions.AddO365INVPost();
        LibraryLowerPermissions.AddO365INVSetup();
        // [GIVEN] Create direct transfer from location "L1" to location "L2"
        CreateDirectTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code);

        // [GIVEN] Enable "Require Receive" in location "L2"
        ToLocation.Validate("Require Receive", true);
        ToLocation.Modify(true);

        // [WHEN] Release the transfer order
        asserterror LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [THEN] Error: "Require Receive" must equal to 'No' in location
        Assert.ExpectedTestFieldError(FromLocation.FieldCaption("Require Receive"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDirectTransferErrorTransferFromLocationChangedAfterRelease()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
    begin
        // [FEATURE] [Direct Transfer]
        // [SCENARIO 253751] It should not be allowed to post a direct transfer order if outbound warehouse handling was enabled on location after releasing the order

        Initialize();

        // [GIVEN] Two locations "L1" and "L2" without warehouse handling
        LibraryWarehouse.CreateLocation(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);
        LibraryInventory.CreateItem(Item);

        LibraryLowerPermissions.SetO365INVCreate();
        LibraryLowerPermissions.AddO365INVSetup();
        LibraryLowerPermissions.AddO365INVPost();
        // [GIVEN] Create and release direct transfer from location "L1" to location "L2"
        CreateDirectTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(100));
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Enable "Require Shipment" in location "L1"
        FromLocation.Validate("Require Shipment", true);
        FromLocation.Modify(true);

        // [WHEN] Post the transfer order
        asserterror LibraryInventory.PostDirectTransferOrder(TransferHeader);

        // [THEN] Error: "Require Shipment" must equal to 'No' in location
        Assert.ExpectedTestFieldError(FromLocation.FieldCaption("Require Shipment"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDirectTransferErrorTransferToLocationChangedAfterRelease()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
    begin
        // [FEATURE] [Direct Transfer]
        // [SCENARIO 253751] It should not be allowed to post a direct transfer order if inbound warehouse handling was enabled on location after releasing the order

        Initialize();

        // [GIVEN] Two locations "L1" and "L2" without warehouse handling
        LibraryWarehouse.CreateLocation(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);
        LibraryInventory.CreateItem(Item);

        LibraryLowerPermissions.SetO365INVCreate();
        LibraryLowerPermissions.AddO365INVPost();
        LibraryLowerPermissions.AddO365INVSetup();
        // [GIVEN] Create and release direct transfer from location "L1" to location "L2"
        CreateDirectTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(100));
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Enable "Require Receive" in location "L2"
        ToLocation.Validate("Require Receive", true);
        ToLocation.Modify(true);

        // [WHEN] Post the transfer order
        asserterror LibraryInventory.PostDirectTransferOrder(TransferHeader);

        // [THEN] Error: "Require Receive" must equal to 'No' in location
        Assert.ExpectedTestFieldError(FromLocation.FieldCaption("Require Receive"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDirectTransferSuccessTransferFromLocationRequiresInbHandling()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        TransferQty: Decimal;
    begin
        // [FEATURE] [Direct Transfer]
        // [SCENARIO 253751] Direct transfer order should be posted if the transfer-from location requires inbound warehouse handling, but not outbound

        Initialize();

        // [GIVEN] Location "L1" with "Require Receive" and "Require Put-away" enabled
        LibraryWarehouse.CreateLocationWMS(FromLocation, false, true, false, true, false);
        // [GIVEN] Location "L2" withount warehouse handling
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);

        TransferQty := LibraryRandom.RandDec(100, 2);
        CreateAndPostItem(Item, FromLocation.Code, TransferQty);

        LibraryLowerPermissions.SetO365INVCreate();
        LibraryLowerPermissions.AddO365INVPost();
        LibraryLowerPermissions.AddJobs();
        CreateDirectTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code);
        // [GIVEN] Create direct transfer order from location "L1" to location "L2"
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", TransferQty);

        // [WHEN] Post the transfer order
        LibraryInventory.PostDirectTransferOrder(TransferHeader);

        // [THEN] Item is transferred to location "L2"
        Item.SetRange("Location Filter", ToLocation.Code);
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, TransferQty);
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure PostDirectTransferSuccessTransferToLocationRequiresOutbHandling()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        TransferQty: Decimal;
    begin
        // [FEATURE] [Direct Transfer]
        // [SCENARIO 253751] Direct transfer order should be posted if the transfer-to location requires outbound warehouse handling, but not inbound

        Initialize();

        // [GIVEN] Location "L1" withount warehouse handling
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        // [GIVEN] Location "L2" with "Require Shipment" and "Require Put-Pick" enabled
        LibraryWarehouse.CreateLocationWMS(ToLocation, false, false, true, false, true);

        TransferQty := LibraryRandom.RandDec(100, 2);
        CreateAndPostItem(Item, FromLocation.Code, TransferQty);

        LibraryLowerPermissions.SetO365INVCreate();
        LibraryLowerPermissions.AddO365INVPost();
        LibraryLowerPermissions.AddJobs();
        CreateDirectTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code);
        // [GIVEN] Create direct transfer order from location "L1" to location "L2"
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", TransferQty);

        // [WHEN] Post the transfer order
        LibraryInventory.PostDirectTransferOrder(TransferHeader);

        // [THEN] Item is transferred to location "L2"
        Item.SetRange("Location Filter", ToLocation.Code);
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, TransferQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDirectTransferReceiptErrorShipmentRollBack()
    var
        Item: Record Item;
        LocationBlue: Record Location;
        LocationSilver: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        // [FEATURE] [Direct Transfer]
        // [SCENARIO 270430] If posting of the receipt side of a direct transfer order fails, posted shipment is rolled back
        Initialize();

        // [GIVEN] Two locations: BLUE with no warehouse settings, and SILVER with bin mandatory
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryWarehouse.CreateLocationWMS(LocationSilver, true, false, false, false, false);

        // [GIVEN] Item "I" with stock on BLUE location
        CreateAndPostItem(Item, LocationBlue.Code, LibraryRandom.RandIntInRange(100, 200));

        LibraryLowerPermissions.SetO365INVCreate();
        LibraryLowerPermissions.AddO365INVPost();
        LibraryLowerPermissions.AddO365WhseEdit();

        // [GIVEN] Direct transfer order for item "I" from BLUE to SILVER location. Bin code for the transfer receipt is not filled
        CreateDirectTransferHeader(TransferHeader, LocationBlue.Code, LocationSilver.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandDec(100, 2));

        // [WHEN] Post the transfer order
        asserterror LibraryInventory.PostDirectTransferOrder(TransferHeader);

        // [THEN] Posting fails
        // [THEN] Shipped quantity on the transfer line is 0
        TransferLine.Find();
        TransferLine.TestField("Qty. Shipped (Base)", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDirectTransferWithLocationMandatory()
    var
        Location: array[2] of Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        TransferReceiptHeader: Record "Transfer Receipt Header";
    begin
        // [FEATURE] [Direct Transfer]
        // [SCENARIO 278532] Direct transfer order can be posted with "Location Mandatory" enabled
        Initialize();

        // [GIVEN] "Location Mandatory" in inventory setup is enabled
        LibraryInventory.SetLocationMandatory(true);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);
        CreateAndPostItem(Item, Location[1].Code, LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Create direct transfer order
        CreateDirectTransferHeader(TransferHeader, Location[1].Code, Location[2].Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandDec(100, 2));

        LibraryLowerPermissions.SetO365INVCreate();
        LibraryLowerPermissions.AddO365INVPost();
        LibraryLowerPermissions.AddJobs();

        // [WHEN] Post the transfer order
        LibraryInventory.PostDirectTransferOrder(TransferHeader);

        // [THEN] Order is successfully posted
        TransferReceiptHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.RecordIsNotEmpty(TransferReceiptHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferWithLocationMandatoryCannotPostWithoutFromLocation()
    var
        Location: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Direct Transfer] [Item Journal]
        // [SCENARIO 278532] "Transfer Shipment" entry in item journal cannot be posted with blank "Location Code" when "Location Mandatory" is enabled in inventory setup

        Initialize();

        // [GIVEN] "Location Mandatory" in inventory setup is enabled
        LibraryInventory.SetLocationMandatory(true);

        // [GIVEN] Item journal line with document type = "Transfer Shipment", blank "Location Code", and filled "New Location Code"
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        CreateItemJournalLineDirectTransfer(
          ItemJournalLine, Item."No.", 1, '', Location.Code, ItemJournalLine."Document Type"::"Transfer Shipment");

        LibraryLowerPermissions.SetO365INVCreate();
        LibraryLowerPermissions.AddO365INVPost();

        // [WHEN] Post item journal line
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Error: Location Code must have a value
        Assert.ExpectedError('Location Code must have a value in Item Journal Line');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferWithLocationMandatoryCannotPostWithoutToLocation()
    var
        Location: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Direct Transfer] [Item Journal]
        // [SCENARIO 278532] "Transfer Receipt" entry in item journal cannot be posted with blank "New Location Code" when "Location Mandatory" is enabled in inventory setupInitialize();

        Initialize();

        // [GIVEN] "Location Mandatory" in inventory setup is enabled
        LibraryInventory.SetLocationMandatory(true);

        // [GIVEN] Item journal line with document type = "Transfer Receipt", filled "Location Code", and blank "New Location Code"
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        CreateItemJournalLineDirectTransfer(
          ItemJournalLine, Item."No.", 1, Location.Code, '', ItemJournalLine."Document Type"::"Transfer Receipt");

        LibraryLowerPermissions.SetO365INVCreate();
        LibraryLowerPermissions.AddO365INVPost();

        // [WHEN] Post item journal line
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Error: New Location Code must have a value
        Assert.ExpectedError('New Location Code must have a value in Item Journal Line');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeselectDirectTransferForNonPostedTransferOrder()
    var
        Location: array[2] of Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [FEATURE] [Direct Transfer] [UI]
        // [SCENARIO 292732] User is able to change Direct Transfer from Yes to No for transfer order with lines which are not posted
        Initialize();

        // [GIVEN] Prepare locations and item for direct transfer order
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);
        CreateAndPostItem(Item, Location[1].Code, LibraryRandom.RandIntInRange(100, 200));
        LibraryLowerPermissions.SetO365INVCreate();
        LibraryLowerPermissions.AddO365INVPost();
        LibraryLowerPermissions.AddJobs();

        // [GIVEN] Create direct transfer order with line
        CreateDirectTransferHeader(TransferHeader, Location[1].Code, Location[2].Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandDec(100, 2));

        // [WHEN] Open transfer order card
        TransferOrder.OpenEdit();
        TransferOrder.FILTER.SetFilter("No.", TransferHeader."No.");

        // [THEN] "Direct Transfer" is editable
        Assert.IsTrue(TransferOrder."Direct Transfer".Editable(), DirectTransferMustBeEditableErr);
        // [WHEN] "Direct Transfer" is being changed to No
        TransferOrder."Direct Transfer".SetValue(false);

        // [THEN] "Direct Transfer" is still editable
        Assert.IsTrue(TransferOrder."Direct Transfer".Editable(), DirectTransferMustBeEditableErr);

        // [THEN] Transfer order line has "Direct Transfer" = No
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindFirst();
        TransferLine.TestField("Direct Transfer", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeselectDirectTransferForPartlyPostedTransferOrder()
    var
        Location: array[2] of Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [FEATURE] [Direct Transfer] [UI]
        // [SCENARIO 292732] User is able to change Direct Transfer from Yes to No for transfer order with lines which are not posted
        Initialize();

        // [GIVEN] Prepare locations and item for direct transfer order
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);
        CreateAndPostItem(Item, Location[1].Code, LibraryRandom.RandIntInRange(100, 200));
        LibraryLowerPermissions.SetO365INVCreate();
        LibraryLowerPermissions.AddO365INVPost();
        LibraryLowerPermissions.AddJobs();

        // [GIVEN] Create direct transfer order "DTO" with line
        CreateDirectTransferHeader(TransferHeader, Location[1].Code, Location[2].Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandIntInRange(5, 10));

        // [GIVEN] Set Qty to Ship = 1 for partial shipment
        TransferLine.Validate("Qty. to Ship", 1);
        TransferLine.Modify();

        // [GIVEN] Post shipment
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [WHEN] Open transfer order card with partially posted order "DTO"
        TransferOrder.OpenEdit();
        TransferOrder.FILTER.SetFilter("No.", TransferHeader."No.");

        // [THEN] "Direct Transfer" is not editable
        Assert.IsFalse(TransferOrder."Direct Transfer".Editable(), 'Direct Transfer must not be editable');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemVariantKeptOnValidateDirectTransfer()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Location: array[3] of Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        // [FEATURE] [Direct Transfer] [Item Variant] [UT]
        // [SCENARIO 368548] Keep Variant Code on transfer line when validating Direct Transfer checkbox on the transfer header.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddO365INVCreate();

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        LibraryWarehouse.CreateTransferLocations(Location[1], Location[2], Location[3]);

        LibraryInventory.CreateTransferHeader(TransferHeader, Location[1].Code, Location[2].Code, Location[3].Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(10));
        TransferLine.Validate("Variant Code", ItemVariant.Code);
        TransferLine.Modify(true);

        TransferHeader.Validate("Direct Transfer", true);

        TransferLine.Find();
        TransferLine.TestField("Variant Code", ItemVariant.Code);
    end;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Location Transfers");
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableLocationsSetup();
        LibraryUtility.GetGlobalNoSeriesCode();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Location Transfers");

        LibraryUtility.GenerateGUID();

        UpdatePostedDirectTransfersNoSeries();

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibraryTemplates.EnableTemplatesFeature();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Location Transfers");
    end;

    local procedure CreateItemJournalLineDirectTransfer(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10]; NewLocationCode: Code[10]; DocumentType: Enum "Item Ledger Document Type")
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Transfer);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Transfer, ItemNo, Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("New Location Code", NewLocationCode);
        ItemJournalLine.Validate("Direct Transfer", true);
        ItemJournalLine.Validate("Document Type", DocumentType);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateLocationCodeAndName(var Location: Record Location): Code[10]
    begin
        Location.Init();
        Location.Validate(Code, LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), DATABASE::Location));
        Location.Validate(Name, Location.Code);
        Location.Insert(true);

        exit(Location.Code);
    end;

    local procedure CreateLocationWithInventoryPostingSetup(IsInTransit: Boolean): Code[10]
    var
        Location: Record Location;
    begin
        CreateLocationCodeAndName(Location);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
        if IsInTransit then begin
            Location.Validate("Use As In-Transit", true);
            Location.Modify(true)
        end;

        exit(Location.Code);
    end;

    local procedure CreateAndPostItem(var Item: Record Item; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibrarySmallBusiness.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", LocationCode, Quantity);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    [Scope('OnPrem')]
    local procedure CreateDirectTransferHeader(var TransferHeader: Record "Transfer Header"; FromLocation: Text[10]; ToLocation: Text[10])
    begin
        Clear(TransferHeader);
        TransferHeader.Init();
        TransferHeader.Insert(true);
        TransferHeader.Validate("Transfer-from Code", FromLocation);
        TransferHeader.Validate("Transfer-to Code", ToLocation);
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify(true);
    end;

    local procedure CreateLocations(var LocationFrom: Code[10]; var LocationTo: Code[10]; var LocationInTransit: Code[10])
    begin
        LocationFrom := CreateLocationWithInventoryPostingSetup(false);
        LocationTo := CreateLocationWithInventoryPostingSetup(false);
        LocationInTransit := CreateLocationWithInventoryPostingSetup(true);
    end;

    local procedure UpdatePostedDirectTransfersNoSeries()
    var
        InventorySetup: Record "Inventory Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, false, true);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');

        InventorySetup.Get();
        InventorySetup.Validate("Posted Direct Trans. Nos.", NoSeries.Code);
        InventorySetup.Validate("Direct Transfer Posting", InventorySetup."Direct Transfer Posting"::"Receipt and Shipment");
        InventorySetup.Modify(true);
    end;

    local procedure ValidateInventoryForLocation(Item: Record Item; LocationCode: Code[10]; ExpectedInventory: Decimal)
    begin
        Item.SetFilter("Location Filter", '%1', LocationCode);
        Item.CalcFields(Inventory);
        Assert.AreEqual(Item.Inventory, ExpectedInventory, WrongInventoryErr);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure NewItemStrMenuHandler(OptionString: Text[1024]; var OptionNumber: Integer; Instruction: Text[1024])
    begin
        Assert.ExpectedMessage('This item is not registered', Instruction);
        OptionNumber := 1;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTemplateModalPageHandler(var SelectItemTemplList: TestPage "Select Item Templ. List")
    begin
        SelectItemTemplList.First();
        SelectItemTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemPageModalPageHandler(var ItemCard: TestPage "Item Card")
    begin
    end;
}
