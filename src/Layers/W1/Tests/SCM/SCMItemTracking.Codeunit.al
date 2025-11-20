codeunit 137405 "SCM Item Tracking"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Tracking] [SCM]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryJob: Codeunit "Library - Job";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        SalesMode: Boolean;
        BeforeExpirationDateError: Label 'Expiration Date  is before the posting date. in Item Ledger Entry Entry No.=''%1''.';
        UnknownError: Label 'Unknown Error.';
        AssignLotNo: Boolean;
        AssignSerialNo: Boolean;
        QtyToHandleMismatchErr: Label 'Quantity to handle in inbound and outbound entries does not match.';
        ItemTrackSpecNotFoundErr: Label 'Item tracking specification for transfer line is not found.';
        TrackingOptionStr: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotQty,VerifyLotQty;
        PostedWhseQuantityErr: Label 'Posted Warehouse Shipment must have same quantity as Warehouse Shipment';
        WrongExpDateErr: Label 'Wrong expiration date in %1 No. %2';
        ItemLedgEntryWithLotErr: Label 'Item Ledger Entry with Item and Lot not exists.';
        TrackedQuantityErr: Label 'The %1 does not match the quantity defined in item tracking for item %2.';
        LotNoRequiredErr: Label 'You must assign a lot number for item %1.', Comment = '%1 - Item No.';
        SerialNoRequiredErr: Label 'You must assign a serial number for item %1.', Comment = '%1 - Item No.';
        LineNoTxt: Label ' Line No. = ''%1''.', Comment = '%1 - Line No.';
        IncorrectErrorMessageErr: Label 'Incorrect error message';
        MultipleExpDateForLotErr: Label 'There are multiple expiration dates registered for lot %1.', Comment = '%1 = Lot No.';
        FieldVisibleErr: Label 'Field %1 should not be visible on page %2.', Comment = '%1: FieldCaption, %2: PageCaption';
        FieldEditableErr: Label 'Field %1 should not be editable on page %2.', Comment = '%1: FieldCaption, %2: PageCaption';
        AdjustTrackingErr: Label 'You must adjust the existing item tracking and then reenter the new quantity';
        NewSerialNoCannotBeChangedErr: Label 'Quantity (Base) must be -1, 0 or 1 when Serial No. is stated.';
        QtyAndQtyToHandleMismatchErr: Label 'Quantity and Quantity to Handle does not match.';
        QtyAndQtyOnWarehousePickMismatchErr: Label 'Quantity (%1) and Quantity to %3 (%2) does not match.';
        WrongNoOfTrackingSpecsErr: Label 'Wrong number of item tracking specifications';
        HandlingTypeStr: Option "Init Tracking","Double Quantities","Align Quantities","QtyToHandle < Qty";
        ItemTrackingOption: Option AssignLotNo,SelectEntries;
        FieldNotFoundErr: Label 'The field with ID';
        FieldNotFoundCodeErr: Label 'TestFieldNotFound';
        BeforeExpirationDateShortErr: Label 'Expiration Date is before the posting date';
        CannotChangeItemWhseEntriesExistErr: Label 'You cannot change %1 because there are one or more warehouse entries for this item.', Comment = '%1: Changed field name';
        CannotChangeITWhseEntriesExistErr: Label 'You cannot change %1 because there are one or more warehouse entries for item %2.', Comment = '%1: Changed field name; %2: Item No.';
        LotNoMustNotBeBlankErr: Label 'Lot No. must not be blank.';
        SerialNoMustNotBeBlankErr: Label 'Serial No. must not be blank.';
        WhseActivityLineMustBeFoundErr: Label 'Warehouse Activity Line must be found.';
        SerialNoAlreadyOnInventoryErr: Label 'Serial No. %1 is already on inventory.', Comment = '%1 - Serial No.';

    [Test]
    [HandlerFunctions('ItemTrackingAssignTrackingNoAndVerifyQuantityHandler,EnterQuantityToCreateHandler')]
    [Scope('OnPrem')]
    procedure E2EPurchaseAndSalesWithSerialNumberAndUOMWithBoxOf6()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WarehouseSetup: Record "Warehouse Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        I: Integer;
        Quantity: Integer;
        QTake: Decimal;
        QPlace: Decimal;
    begin
        // [Bug 408611] [[UoM] Warehouse Pick & SN: This will cause the quantity and base quantity fields to be out of balance.]
        Initialize();

        Quantity := 1;

        // [GIVEN] Warehouse setup where posting errors are not supressed
        WarehouseSetup.Get();
        WarehouseSetup.Validate("Receipt Posting Policy", WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        WarehouseSetup.Modify();

        // [GIVEN] Item with Serial Number Item Tracking Code with "SN Warehouse Tracking"
        CreateItem(
          Item, CreateItemTrackingCodeSerialSpecificWhseTracking(false, true), LibraryUtility.GetGlobalNoSeriesCode(), '');

        // [GIVEN] Location with "Require Receive"
        LibraryWarehouse.CreateFullWMSLocation(Location, 10);

        // [GIVEN] Second item unit of measure created for the item with Box of 6
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 6);

        // [GIVEN] Released Purchase Order with rounding precision on purchase line set to 0 and serial numbers assigned
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Item."No.", Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchaseLine.Modify(true);

        LibraryVariableStorage.Enqueue(TrackingOptionStr::AssignSerialNo);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Warehouse Receipt Lines creation is requested
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [THEN] Warehouse Receipt Lines are created
        WarehouseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        WarehouseReceiptLine.SetRange("Source Subtype", PurchaseLine."Document Type");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseLine."Document No.");
        Assert.RecordCount(WarehouseReceiptLine, 1);

        // [WHEN] Warehouse Receipt is posted
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");

        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] No error is raised and 1 posted receipt line is created
        PostedWhseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        PostedWhseReceiptLine.SetRange("Source Subtype", PurchaseLine."Document Type");
        PostedWhseReceiptLine.SetRange("Source No.", PurchaseLine."Document No.");
        Assert.RecordCount(PostedWhseReceiptLine, 1);

        // [THEN] Base quantity * 2 number of warehouse activity lines are created. * 2 to cover 1 take and 1 place
        WarehouseActivityLine.SetRange("Source Type", Database::"Purchase Line");
        WarehouseActivityLine.SetRange("Source Subtype", PurchaseLine."Document Type");
        WarehouseActivityLine.SetRange("Source No.", PurchaseLine."Document No.");
        Assert.RecordCount(WarehouseActivityLine, ItemUnitOfMeasure."Qty. per Unit of Measure" * 2);

        // No error is thrown when the activity is registered
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Sales Order is created to exhaust the items that was putaway
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", PurchaseLine.Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        SalesLine.Modify(true);

        // [GIVEN] Sales document is released
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN]  Warehouse shipment lines are created
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [THEN] 1 Warehouse shipment line is created
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseShipmentLine.SetRange("Source Subtype", SalesLine."Document Type");
        WarehouseShipmentLine.SetRange("Source No.", SalesLine."Document No.");
        Assert.RecordCount(WarehouseShipmentLine, 1);

        // [WHEN] Warehouse CreatePick is called
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");

        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [THEN] Warehouse activity lines are created
        WarehouseActivityLine.SetRange("Source Type", Database::"Sales Line");
        WarehouseActivityLine.SetRange("Source Subtype", SalesLine."Document Type");
        WarehouseActivityLine.SetRange("Source No.", SalesLine."Document No.");
        Assert.RecordCount(WarehouseActivityLine, ItemUnitOfMeasure."Qty. per Unit of Measure" * 2); // * 2 because there is one line for take and one for place

        WarehouseActivityLine.FindSet();
        for I := 1 to ItemUnitOfMeasure."Qty. per Unit of Measure" * 2 do begin
            case WarehouseActivityLine."Action Type" of
                WarehouseActivityLine."Action Type"::Place:
                    QPlace := QPlace + WarehouseActivityLine.Quantity;
                WarehouseActivityLine."Action Type"::Take:
                    QTake := QTake + WarehouseActivityLine.Quantity;
            end;
            WarehouseActivityLine.Next();
        end;

        // [THEN] Warehouse activity lines created should have the correct Place and Take quantities
        Assert.AreEqual(QPlace, Quantity, StrSubstNo(QtyAndQtyOnWarehousePickMismatchErr, QPlace, Quantity, 'Place'));
        Assert.AreEqual(QTake, Quantity, StrSubstNo(QtyAndQtyOnWarehousePickMismatchErr, QPlace, Quantity, 'Take'));

        // [WHEN/THEN] When serial numbers are assigned to the warehouse activity lines and are registered, then no errors are thrown
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetFilter("Serial No.", '<> %1', '');
        ItemLedgerEntry.FindSet();
        for I := 1 to ItemUnitOfMeasure."Qty. per Unit of Measure" do begin
            UpdateSerialNoOnWhseActivityLine(WarehouseShipmentHeader."No.", WarehouseActivityLine."Action Type"::Take, ItemLedgerEntry."Serial No.");
            UpdateSerialNoOnWhseActivityLine(WarehouseShipmentHeader."No.", WarehouseActivityLine."Action Type"::Place, ItemLedgerEntry."Serial No.");
            ItemLedgerEntry.Next();
        end;
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2ECreatePickOnItemWithUOMBoxOf16()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        BoxItemUnitOfMeasure: Record "Item Unit of Measure";
        WarehouseSetup: Record "Warehouse Setup";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        ActionType: Enum "Warehouse Action Type";
        WHSetupReceiptPostingBackUp: Option;
        QuantityPCS: Integer;
        QuantityBox: Integer;
        SplitQuantity: Integer;
    begin
        // [Bug 417763] [[UoM] Unexpected Quantity for Take line in Warehouse Pick when use specific UOM for Sales process and picking from the different bins.]
        Initialize();

        QuantityPCS := 128;
        QuantityBox := 8;
        SplitQuantity := 79;

        // [GIVEN] Warehouse setup where posting errors are not supressed
        WarehouseSetup.Get();
        WHSetupReceiptPostingBackUp := WarehouseSetup."Receipt Posting Policy";
        WarehouseSetup.Validate("Receipt Posting Policy", WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        WarehouseSetup.Modify();

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location with "Require Receive"
        LibraryWarehouse.CreateFullWMSLocation(Location, 10);

        // [GIVEN] Second item unit of measure created for the item with Box of 16
        LibraryInventory.CreateItemUnitOfMeasureCode(BoxItemUnitOfMeasure, Item."No.", 16);

        // [GIVEN] Set Sales Unit of Measure
        Item.Validate("Sales Unit of Measure", BoxItemUnitOfMeasure.Code);
        Item.Modify();

        // [GIVEN] Released Purchase Order with rounding precision on purchase line set to 0
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Item."No.", QuantityPCS);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Warehouse Receipt Lines creation is requested
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [THEN] Warehouse Receipt Lines are created
        WarehouseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        WarehouseReceiptLine.SetRange("Source Subtype", PurchaseLine."Document Type");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseLine."Document No.");
        Assert.RecordCount(WarehouseReceiptLine, 1);

        // [WHEN] Warehouse Receipt is posted
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");

        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] No error is raised and 1 posted receipt line is created
        PostedWhseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        PostedWhseReceiptLine.SetRange("Source Subtype", PurchaseLine."Document Type");
        PostedWhseReceiptLine.SetRange("Source No.", PurchaseLine."Document No.");
        Assert.RecordCount(PostedWhseReceiptLine, 1);

        // [THEN] Base quantity * 2 number of warehouse activity lines are created. * 2 to cover 1 take and 1 place
        WarehouseActivityLine.SetRange("Source Type", Database::"Purchase Line");
        WarehouseActivityLine.SetRange("Source Subtype", PurchaseLine."Document Type");
        WarehouseActivityLine.SetRange("Source No.", PurchaseLine."Document No.");
        Assert.RecordCount(WarehouseActivityLine, 2); //One each for Take and Place
        WarehouseActivityLine.SetRange("Action Type", 2);
        WarehouseActivityLine.FindFirst();

        // [THEN]  Changing Place Qty. To Handle and Split Lines
        WarehouseActivityLine.Validate("Qty. to Handle", SplitQuantity);
        WarehouseActivityLine.Modify();
        WarehouseActivityLine.SplitLine(WarehouseActivityLine);

        // [THEN] Update Bin and Zone Code and register activity
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'BINS1', WarehouseActivityLine."Zone Code", WarehouseActivityLine."Bin Type Code");
        UpdatePickLineZoneCodeAndBinCode(PurchaseHeader."No.", WarehouseActivityLine."Action Type", Bin."Zone Code", Bin.Code, QuantityPCS - SplitQuantity);
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Post Purchase Order
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Sales Order is created to exhaust the items that was putaway
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", QuantityBox);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Unit of Measure Code", BoxItemUnitOfMeasure.Code);
        SalesLine.Modify(true);

        // [GIVEN] Sales document is released
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN]  Warehouse shipment lines are created
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [THEN] 1 Warehouse shipment line is created
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseShipmentLine.SetRange("Source Subtype", SalesLine."Document Type");
        WarehouseShipmentLine.SetRange("Source No.", SalesLine."Document No.");
        Assert.RecordCount(WarehouseShipmentLine, 1);

        // [WHEN] Warehouse CreatePick is called
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");

        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [THEN] Warehouse activity lines are created
        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetRange("Source Type", Database::"Sales Line");
        WarehouseActivityLine.SetRange("Source Subtype", SalesLine."Document Type");
        WarehouseActivityLine.SetRange("Source No.", SalesLine."Document No.");
        Assert.RecordCount(WarehouseActivityLine, 4); // * 4 because there is 2 line for take and 2 for place

        // [THEN] Warehouse activity lines created should have the correct Place and Take quantities
        for ActionType := "Warehouse Action Type"::Take to "Warehouse Action Type"::Place do begin
            WarehouseActivityLine.SetRange("Action Type", ActionType);
            WarehouseActivityLine.CalcSums(Quantity, "Qty. to Handle");
            if (ActionType = "Warehouse Action Type"::Take) then begin
                WarehouseActivityLine.TestField(Quantity, QuantityPCS);
                WarehouseActivityLine.TestField("Qty. to Handle", QuantityPCS);
            end;
            if (ActionType = "Warehouse Action Type"::Place) then begin
                WarehouseActivityLine.TestField(Quantity, QuantityBox);
                WarehouseActivityLine.TestField("Qty. to Handle", QuantityBox);
            end;
        end;

        // [THEN] Then the warehouse activity lines are registered with no errors
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();

        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        WarehouseSetup.Validate("Receipt Posting Policy", WHSetupReceiptPostingBackUp);
        WarehouseSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2EPurchaseAndSalesWHPicksWithPartialDecimalQtyToHandle()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        BoxItemUnitOfMeasure: Record "Item Unit of Measure";
        WarehouseSetup: Record "Warehouse Setup";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        ActionType: Enum "Warehouse Action Type";
        WHSetupReceiptPostingBackUp: Option;
        PurchaseQty: Integer;
        SaleQty: integer;
    begin
        // [Bug 424108] When Pick is created for a partial decimal, we are not allowed to fill Qty. to Handle.
        Initialize();

        PurchaseQty := 23; //PCS
        SaleQty := 2; //Box

        // [GIVEN] Warehouse setup where posting errors are not supressed
        WarehouseSetup.Get();
        WHSetupReceiptPostingBackUp := WarehouseSetup."Receipt Posting Policy";
        WarehouseSetup.Validate("Receipt Posting Policy", WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        WarehouseSetup.Modify();

        // [GIVEN] Item with Lot Specific Tracking and Warehouse Tracking
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location
        LibraryWarehouse.CreateFullWMSLocation(Location, 10);

        // [GIVEN] Second item unit of measure created for the item with Box of 12
        LibraryInventory.CreateItemUnitOfMeasureCode(BoxItemUnitOfMeasure, Item."No.", 12);

        // [GIVEN] Released Purchase Order with 2 Purchase Line, 23 Qty of PC
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", PurchaseQty);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Warehouse Receipt Lines creation is requested
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [THEN] Warehouse Receipt Lines are created
        WarehouseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        WarehouseReceiptLine.SetRange("Source Subtype", PurchaseHeader."Document Type");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordCount(WarehouseReceiptLine, 1);
        WarehouseReceiptLine.FindFirst();

        // [WHEN] Warehouse Receipt is posted
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] No error is raised and 1 posted receipt line is created
        PostedWhseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        PostedWhseReceiptLine.SetRange("Source Subtype", "Purchase Document Type"::Order);
        PostedWhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordCount(PostedWhseReceiptLine, 1);

        // [THEN] Base quantity * 2 number of warehouse activity lines are created. * 2 to cover 1 take and 1 place
        WarehouseActivityLine.SetRange("Source Type", Database::"Purchase Line");
        WarehouseActivityLine.SetRange("Source Subtype", "Purchase Document Type"::Order);
        WarehouseActivityLine.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordCount(WarehouseActivityLine, 2);
        WarehouseActivityLine.FindFirst();

        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Post Purchase Order
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Sales Order is created to exhaust the items that was putaway plus 1
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", SaleQty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Unit of Measure Code", BoxItemUnitOfMeasure.Code);
        SalesLine.Modify(true);

        // [GIVEN] Sales document is released
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN]  Warehouse shipment lines are created
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [THEN] 1 Warehouse shipment line is created
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseShipmentLine.SetRange("Source Subtype", SalesLine."Document Type");
        WarehouseShipmentLine.SetRange("Source No.", SalesLine."Document No.");
        Assert.RecordCount(WarehouseShipmentLine, 1);

        // [WHEN] Warehouse CreatePick is called
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");

        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [THEN] Warehouse activity lines are created
        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetRange("Source Type", Database::"Sales Line");
        WarehouseActivityLine.SetRange("Source Subtype", SalesLine."Document Type");
        WarehouseActivityLine.SetRange("Source No.", SalesLine."Document No.");
        Assert.RecordCount(WarehouseActivityLine, 2);

        // [THEN] Warehouse activity lines created should have the correct Place and Take quantities
        // [THEN] Set Qty to handle for Take and Place to max Quantity
        for ActionType := "Warehouse Action Type"::Take to "Warehouse Action Type"::Place do begin
            WarehouseActivityLine.SetRange("Action Type", ActionType);
            WarehouseActivityLine.FindFirst();
            if (ActionType = "Warehouse Action Type"::Take) then
                WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine.Quantity);
            if (ActionType = "Warehouse Action Type"::Place) then
                WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine.Quantity);
        end;

        // [THEN] Then the warehouse activity lines are registered with no errors
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();

        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        WarehouseSetup.Validate("Receipt Posting Policy", WHSetupReceiptPostingBackUp);
        WarehouseSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2EPurchaseAndSalesWHPicksWithRoundDownQtyToHandle()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        BoxItemUnitOfMeasure: Record "Item Unit of Measure";
        WarehouseSetup: Record "Warehouse Setup";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        ActionType: Enum "Warehouse Action Type";
        WHSetupReceiptPostingBackUp: Option;
        PurchaseQty: Integer;
        SaleQty: integer;
    begin
        // [Bug 424108] When Pick is created for a partial decimal, we are not allowed to fill Qty. to Handle.
        Initialize();

        PurchaseQty := 2; //PCS
        SaleQty := 1; //Box

        // [GIVEN] Warehouse setup where posting errors are not supressed
        WarehouseSetup.Get();
        WHSetupReceiptPostingBackUp := WarehouseSetup."Receipt Posting Policy";
        WarehouseSetup.Validate("Receipt Posting Policy", WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        WarehouseSetup.Modify();

        // [GIVEN] Item with Lot Specific Tracking and Warehouse Tracking
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location
        LibraryWarehouse.CreateFullWMSLocation(Location, 10);

        // [GIVEN] Second item unit of measure created for the item with Box of 6
        LibraryInventory.CreateItemUnitOfMeasureCode(BoxItemUnitOfMeasure, Item."No.", 6);

        // [GIVEN] Released Purchase Order with Purchase Line, 2 Qty of PCS
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", PurchaseQty);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Warehouse Receipt Lines creation is requested
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [THEN] Warehouse Receipt Lines are created
        WarehouseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        WarehouseReceiptLine.SetRange("Source Subtype", PurchaseHeader."Document Type");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordCount(WarehouseReceiptLine, 1);
        WarehouseReceiptLine.FindFirst();

        // [WHEN] Warehouse Receipt is posted
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] No error is raised and 1 posted receipt line is created
        PostedWhseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        PostedWhseReceiptLine.SetRange("Source Subtype", "Purchase Document Type"::Order);
        PostedWhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordCount(PostedWhseReceiptLine, 1);

        // [THEN] Base quantity * 2 number of warehouse activity lines are created. * 2 to cover 1 take and 1 place
        WarehouseActivityLine.SetRange("Source Type", Database::"Purchase Line");
        WarehouseActivityLine.SetRange("Source Subtype", "Purchase Document Type"::Order);
        WarehouseActivityLine.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordCount(WarehouseActivityLine, 2);
        WarehouseActivityLine.FindFirst();

        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Post Purchase Order
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Sales Order is created to exhaust the items that was putaway
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", SaleQty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Unit of Measure Code", BoxItemUnitOfMeasure.Code);
        SalesLine.Modify(true);

        // [GIVEN] Sales document is released
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN]  Warehouse shipment lines are created
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [THEN] 1 Warehouse shipment line is created
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseShipmentLine.SetRange("Source Subtype", SalesLine."Document Type");
        WarehouseShipmentLine.SetRange("Source No.", SalesLine."Document No.");
        Assert.RecordCount(WarehouseShipmentLine, 1);

        // [WHEN] Warehouse CreatePick is called
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");

        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [THEN] Warehouse activity lines are created
        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetRange("Source Type", Database::"Sales Line");
        WarehouseActivityLine.SetRange("Source Subtype", SalesLine."Document Type");
        WarehouseActivityLine.SetRange("Source No.", SalesLine."Document No.");
        Assert.RecordCount(WarehouseActivityLine, 2);

        // [THEN] Warehouse activity lines created should have the correct Place and Take quantities
        // [THEN] Set Qty to handle for Take and Place to max Outstanding Quantity
        for ActionType := "Warehouse Action Type"::Take to "Warehouse Action Type"::Place do begin
            WarehouseActivityLine.SetRange("Action Type", ActionType);
            WarehouseActivityLine.FindFirst();
            if (ActionType = "Warehouse Action Type"::Take) then
                WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine."Qty. Outstanding");
            if (ActionType = "Warehouse Action Type"::Place) then
                WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine."Qty. Outstanding");
        end;

        // [THEN] Then the warehouse activity lines are registered with no errors
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();

        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        WarehouseSetup.Validate("Receipt Posting Policy", WHSetupReceiptPostingBackUp);
        WarehouseSetup.Modify();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandlerTrackingOption,ItemTrackingSummaryOkModalPageHandler')]
    [Scope('OnPrem')]
    procedure E2ECreatePickOnItemWithUOMCaseOf6()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        TempWhseActivLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        CASEItemUnitOfMeasure: Record "Item Unit of Measure";
        WarehouseSetup: Record "Warehouse Setup";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        ActionType: Enum "Warehouse Action Type";
        WHSetupReceiptPostingBackUp: Option;
        PurchaseQty: Integer;
        SaleQty: integer;
        SplitQuantity: Integer;
        BinCode: Code[20];
    begin
        // [Bug 424540] Escalated: Outbound pick Quantities are incorrect if pick is split with different UOM Codes
        Initialize();

        PurchaseQty := 728;
        SaleQty := 1450;
        SplitQuantity := 725;

        // [GIVEN] Warehouse setup where posting errors are not supressed
        WarehouseSetup.Get();
        WHSetupReceiptPostingBackUp := WarehouseSetup."Receipt Posting Policy";
        WarehouseSetup.Validate("Receipt Posting Policy", WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        WarehouseSetup.Modify();

        // [GIVEN] Item with Lot Specific Tracking and Warehouse Tracking
        Item.Get(CreateItemWithLotWarehouseTracking());

        // [GIVEN] Location
        LibraryWarehouse.CreateFullWMSLocation(Location, 10);

        // [GIVEN] Second item unit of measure created for the item with Case of 6
        LibraryInventory.CreateItemUnitOfMeasureCode(CASEItemUnitOfMeasure, Item."No.", 6);

        // [GIVEN] Set Sales Unit of Measure
        Item.Validate("Sales Unit of Measure", Item."Base Unit of Measure");
        Item.Validate("Purch. Unit of Measure", Item."Base Unit of Measure");
        Item.Validate("Put-away Unit of Measure Code", CASEItemUnitOfMeasure.Code);
        Item.Modify();

        // [GIVEN] Released Purchase Order with 2 Purchase Line, 728 Qty of cases each
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item."No.", PurchaseQty);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine1.Type::Item, Item."No.", PurchaseQty);

        PurchaseLine1.Validate("Location Code", Location.Code);
        PurchaseLine1.Validate("Unit of Measure Code", CASEItemUnitOfMeasure.Code);
        PurchaseLine1.Modify(true);

        PurchaseLine2.Validate("Location Code", Location.Code);
        PurchaseLine2.Validate("Unit of Measure Code", CASEItemUnitOfMeasure.Code);
        PurchaseLine2.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Warehouse Receipt Lines creation is requested
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [THEN] Warehouse Receipt Lines are created
        WarehouseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        WarehouseReceiptLine.SetRange("Source Subtype", PurchaseHeader."Document Type");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordCount(WarehouseReceiptLine, 2);

        if WarehouseReceiptLine.FindSet() then
            repeat
                WarehouseReceiptLine.Validate("Qty. to Receive", 725.5);
                WarehouseReceiptLine.Modify(true);
                LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignLotNo);
                LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
                LibraryVariableStorage.Enqueue(4353);
                WarehouseReceiptLine.OpenItemTrackingLines();
            until WarehouseReceiptLine.Next() = 0;

        // [WHEN] Warehouse Receipt is posted
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] No error is raised and 1 posted receipt line is created
        PostedWhseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        PostedWhseReceiptLine.SetRange("Source Subtype", "Purchase Document Type"::Order);
        PostedWhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordCount(PostedWhseReceiptLine, 2);

        // [THEN] Base quantity * 2 number of warehouse activity lines are created. * 2 to cover 1 take and 1 place
        WarehouseActivityLine.SetRange("Source Type", Database::"Purchase Line");
        WarehouseActivityLine.SetRange("Source Subtype", "Purchase Document Type"::Order);
        WarehouseActivityLine.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordCount(WarehouseActivityLine, 4);
        WarehouseActivityLine.SetRange("Action Type", 2);

        if WarehouseActivityLine.FindSet() then
            repeat
                if WarehouseActivityLine."Qty. to Handle" = 0.5 then begin
                    WarehouseActivityLine."Bin Code" := BinCode;
                    TempWhseActivLine := WarehouseActivityLine;
                    TempWhseActivLine."Unit of Measure Code" := Item."Base Unit of Measure";
                    TempWhseActivLine."Qty. per Unit of Measure" := 1;
                    TempWhseActivLine.Validate(Quantity, TempWhseActivLine."Qty. (Base)");
                    WarehouseActivityLine.ChangeUOMCode(WarehouseActivityLine, TempWhseActivLine);
                    WarehouseActivityLine.Modify();
                end else begin
                    // [THEN]  Changing Place Qty. To Handle and Split Lines
                    BinCode := WarehouseActivityLine."Bin Code";
                    WarehouseActivityLine.Validate("Qty. to Handle", SplitQuantity);
                    WarehouseActivityLine.Modify();
                    WarehouseActivityLine.SplitLine(WarehouseActivityLine);
                end;
            until WarehouseActivityLine.Next() = 0;

        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetRange("Source Type", Database::"Purchase Line");
        WarehouseActivityLine.SetRange("Source Subtype", "Purchase Document Type"::Order);
        WarehouseActivityLine.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordCount(WarehouseActivityLine, 6);

        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Post Purchase Order
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Sales Order is created to exhaust the items that was putaway
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", SaleQty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Unit of Measure Code", CASEItemUnitOfMeasure.Code);
        SalesLine.Modify(true);

        LibraryVariableStorage.Enqueue(ItemTrackingOption::SelectEntries);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Sales document is released
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN]  Warehouse shipment lines are created
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [THEN] 1 Warehouse shipment line is created
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseShipmentLine.SetRange("Source Subtype", SalesLine."Document Type");
        WarehouseShipmentLine.SetRange("Source No.", SalesLine."Document No.");
        Assert.RecordCount(WarehouseShipmentLine, 1);

        // [WHEN] Warehouse CreatePick is called
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");

        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [THEN] Warehouse activity lines are created
        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetRange("Source Type", Database::"Sales Line");
        WarehouseActivityLine.SetRange("Source Subtype", SalesLine."Document Type");
        WarehouseActivityLine.SetRange("Source No.", SalesLine."Document No.");
        Assert.RecordCount(WarehouseActivityLine, 6);

        // [THEN] Warehouse activity lines created should have the correct Place and Take quantities
        for ActionType := "Warehouse Action Type"::Take to "Warehouse Action Type"::Place do begin
            WarehouseActivityLine.SetRange("Action Type", ActionType);
            if (ActionType = "Warehouse Action Type"::Take) then begin
                WarehouseActivityLine.SetRange("Unit of Measure Code", Item."Base Unit of Measure");
                WarehouseActivityLine.CalcSums(Quantity);
                WarehouseActivityLine.TestField(Quantity, 3);

                WarehouseActivityLine.SetRange("Unit of Measure Code", CASEItemUnitOfMeasure.Code);
                WarehouseActivityLine.CalcSums(Quantity);
                WarehouseActivityLine.TestField(Quantity, SaleQty - 0.5);
            end;
            if (ActionType = "Warehouse Action Type"::Place) then begin
                WarehouseActivityLine.SetRange("Unit of Measure Code", CASEItemUnitOfMeasure.Code);
                WarehouseActivityLine.CalcSums(Quantity);
                WarehouseActivityLine.TestField(Quantity, SaleQty);
            end;
        end;

        // [THEN] Then the warehouse activity lines are registered with no errors
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();

        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        WarehouseSetup.Validate("Receipt Posting Policy", WHSetupReceiptPostingBackUp);
        WarehouseSetup.Modify();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,EnterQuantityToCreateHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithoutExpirationDate()
    var
        PurchaseLine: Record "Purchase Line";
        TrackingSpec: Record "Tracking Specification";
    begin
        // Test Item Tracking functionality on Purchase Order without Expiration Date.

        // Setup.
        Initialize();

        // Exercise: Create and post Purchase Order without Expiration Date.
        asserterror CreateAndPostPurchaseOrderWithItemTracking(PurchaseLine, 0D);

        // Verify: Verify Expiration Date must have a value in Tracking Specification error message.
        Assert.ExpectedTestFieldError(TrackingSpec.FieldCaption("Expiration Date"), '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,EnterQuantityToCreateHandler,ItemTrackingEntriesHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithExpirationDate()
    var
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        DummyItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingDocManagement: Codeunit "Item Tracking Doc. Management";
    begin
        // Test Item Tracking functionality on Purchase Order with Expiration Date.

        // Setup.
        Initialize();

        // Exercise: Create and post Purchase Order with Expiration Date.
        CreateAndPostPurchaseOrderWithItemTracking(PurchaseLine, WorkDate());

        // Verify: Verify Expiration Date on ItemTrackingEntries Handler.
        ItemTrackingDocManagement.ShowItemTrackingForEntity(
          ItemLedgerEntry."Source Type"::Vendor.AsInteger(), PurchaseLine."Buy-from Vendor No.", '', '', '',
          DummyItemTrackingSetup);  // Verification is done in ItemTrackingEntries Handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,EnterQuantityToCreateHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderAfterExpirationDate()
    var
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Test Item Tracking functionality on Sales Order with Posting Date as after Expiration Date.

        // Setup: Create and post Purchase Order with Expiration Date and find Item Ledger Entry.
        Initialize();
        ItemLedgerEntry.SetRange("Document No.", CreateAndPostPurchaseOrderWithItemTracking(PurchaseLine, WorkDate()));
        ItemLedgerEntry.FindFirst();

        // Exercise: Create and post Sales Order with Posting Date as after Expiration Date.
        asserterror CreateAndPostSalesOrderWithItemTracking(
            PurchaseLine."No.", PurchaseLine.Quantity, LibraryRandom.RandInt(5), '');

        // Verify: Verify Expiration Date is before the posting date error message.
        Assert.AreEqual(StrSubstNo(BeforeExpirationDateError, ItemLedgerEntry."Entry No."), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,EnterQuantityToCreateHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderBeforeExpirationDate()
    var
        PurchaseLine: Record "Purchase Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        DocumentNo: Code[20];
    begin
        // Test Item Tracking functionality on Sales Order with Posting Date as Expiration Date.

        // Setup: Create and post Purchase Order with Expiration Date.
        Initialize();
        CreateAndPostPurchaseOrderWithItemTracking(PurchaseLine, WorkDate());

        // Exercise: Create and post Sales Order with Posting Date as Expiration Date.
        DocumentNo := CreateAndPostSalesOrderWithItemTracking(PurchaseLine."No.", PurchaseLine.Quantity, 0, '');

        // Verify: Verify Sales Shipment.
        SalesShipmentHeader.Get(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderWithItemTrackingLines()
    var
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test Item Tracking functionality for Service Order.

        // Setup: Create and post Purchase Order for new Item. Create a Service Order for the same Item.
        Initialize();
        CreateAndPostPurchaseOrderWithLotNoInItemTracking(PurchaseLine);
        CreateServiceDocument(ServiceHeader, ServiceLine, ServiceHeader."Document Type"::Order, PurchaseLine."No.", PurchaseLine.Quantity);
        AssignLotNo := false;  // Use AssignLotNo as global variable for Handler. It is set to False as new Lot No was created as it was set to True while creating Purchase Order.
        SalesMode := true;  // Use SalesMode as global variable for Handler.

        // Exercise: Select Item Tracking Lines for Lot No.
        ServiceLine.OpenItemTrackingLines();

        // Verify: Lot No. exist on Reservation entry.
        VerifyLotNoExistOnReservationEntry(ServiceLine."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderPostWithItemTrackingLines()
    var
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test posting of Service Order with Item Tracking functionality.

        // Setup: Create and post Purchase Order for new Item. Create a Service Order for the same Item. Select Item Tracking Lines for Lot No..
        Initialize();
        CreateAndPostPurchaseOrderWithLotNoInItemTracking(PurchaseLine);
        CreateServiceDocument(ServiceHeader, ServiceLine, ServiceHeader."Document Type"::Order, PurchaseLine."No.", PurchaseLine.Quantity);
        AssignLotNo := false;  // Use AssignLotNo as global variable for Handler. It is set to False as new Lot No was created as it was set to True while creating Purchase Order.
        SalesMode := true;  // Use SalesMode as global variable for Handler.
        ServiceLine.OpenItemTrackingLines();

        // Exercise: Post the Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Verify: Service Order gets posted successfully with Item Tracking Lines.
        VerifyPostedServiceOrder(ServiceHeader, ServiceLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoWithItemTrackingLines()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test Item Tracking functionality for Service Credit Memo.

        // Setup: Create an Item with Lot specific code. Create a Service Credit Memo for the same Item.
        Initialize();
        CreateItem(Item, CreateItemTrackingCodeLotSpecific(false), '', LibraryUtility.GetGlobalNoSeriesCode());
        CreateServiceDocument(
          ServiceHeader, ServiceLine, ServiceHeader."Document Type"::"Credit Memo", Item."No.", LibraryRandom.RandInt(10));  // Taking Random Quantity.
        AssignLotNo := true;  // Use AssignLotNo as global variable for Handler.

        // Exercise: Assign Lot No on Item Tracking Lines.
        ServiceLine.OpenItemTrackingLines();

        // Verify: Lot No. exist on Reservation entry.
        VerifyLotNoExistOnReservationEntry(ServiceLine."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoPostWithItemTrackingLines()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test posting of Service Credit Memo with Item Tracking functionality.

        // Setup: Create an Item with Lot specific code. Create a Service Credit Memo for the same Item. Assign Lot No on Item Tracking Lines.
        Initialize();
        CreateItem(Item, CreateItemTrackingCodeLotSpecific(false), '', LibraryUtility.GetGlobalNoSeriesCode());
        CreateServiceDocument(
          ServiceHeader, ServiceLine, ServiceHeader."Document Type"::"Credit Memo", Item."No.", LibraryRandom.RandInt(10));  // Taking Random Quantity.
        AssignLotNo := true;  // Use AssignLotNo as global variable for Handler.
        ServiceLine.OpenItemTrackingLines();

        // Exercise: Post the Service Credit Memo.
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // Verify: Service Credit Memo gets posted successfully with Item Tracking Lines.
        VerifyPostedServiceCreditMemo(ServiceHeader, ServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B307197SalesLineIsInbound()
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine."Quantity (Base)" := 1;
        // Positive Qty
        VerifySalesLineIsInbound(SalesLine, SalesLine."Document Type"::Quote, false);
        VerifySalesLineIsInbound(SalesLine, SalesLine."Document Type"::Order, false);
        VerifySalesLineIsInbound(SalesLine, SalesLine."Document Type"::Invoice, false);
        VerifySalesLineIsInbound(SalesLine, SalesLine."Document Type"::"Blanket Order", false);
        VerifySalesLineIsInbound(SalesLine, SalesLine."Document Type"::"Return Order", true);
        VerifySalesLineIsInbound(SalesLine, SalesLine."Document Type"::"Credit Memo", true);

        SalesLine."Quantity (Base)" := -1;
        // Negative Qty
        VerifySalesLineIsInbound(SalesLine, SalesLine."Document Type"::Quote, true);
        VerifySalesLineIsInbound(SalesLine, SalesLine."Document Type"::Order, true);
        VerifySalesLineIsInbound(SalesLine, SalesLine."Document Type"::Invoice, true);
        VerifySalesLineIsInbound(SalesLine, SalesLine."Document Type"::"Blanket Order", true);
        VerifySalesLineIsInbound(SalesLine, SalesLine."Document Type"::"Return Order", false);
        VerifySalesLineIsInbound(SalesLine, SalesLine."Document Type"::"Credit Memo", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B307197PurchLineIsInbound()
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine."Quantity (Base)" := 1;
        // Positive Qty
        VerifyPurchLineIsInbound(PurchLine, PurchLine."Document Type"::Quote, true);
        VerifyPurchLineIsInbound(PurchLine, PurchLine."Document Type"::Order, true);
        VerifyPurchLineIsInbound(PurchLine, PurchLine."Document Type"::Invoice, true);
        VerifyPurchLineIsInbound(PurchLine, PurchLine."Document Type"::"Blanket Order", true);
        VerifyPurchLineIsInbound(PurchLine, PurchLine."Document Type"::"Return Order", false);
        VerifyPurchLineIsInbound(PurchLine, PurchLine."Document Type"::"Credit Memo", false);

        PurchLine."Quantity (Base)" := -1;
        // Negative Qty
        VerifyPurchLineIsInbound(PurchLine, PurchLine."Document Type"::Quote, false);
        VerifyPurchLineIsInbound(PurchLine, PurchLine."Document Type"::Order, false);
        VerifyPurchLineIsInbound(PurchLine, PurchLine."Document Type"::Invoice, false);
        VerifyPurchLineIsInbound(PurchLine, PurchLine."Document Type"::"Blanket Order", false);
        VerifyPurchLineIsInbound(PurchLine, PurchLine."Document Type"::"Return Order", true);
        VerifyPurchLineIsInbound(PurchLine, PurchLine."Document Type"::"Credit Memo", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B307197ItemJnlLineIsInbound()
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine."Quantity (Base)" := 1;
        // Positive Qty
        ItemJnlLine.Quantity := 1;
        VerifyItemJnlLineIsInbound(ItemJnlLine, ItemJnlLine."Entry Type"::Purchase, true);
        VerifyItemJnlLineIsInbound(ItemJnlLine, ItemJnlLine."Entry Type"::Output, true);
        VerifyItemJnlLineIsInbound(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", true);
        VerifyItemJnlLineIsInbound(ItemJnlLine, ItemJnlLine."Entry Type"::"Assembly Output", true);
        VerifyItemJnlLineIsInbound(ItemJnlLine, ItemJnlLine."Entry Type"::Sale, false);
        VerifyItemJnlLineIsInbound(ItemJnlLine, ItemJnlLine."Entry Type"::Consumption, false);
        VerifyItemJnlLineIsInbound(ItemJnlLine, ItemJnlLine."Entry Type"::"Negative Adjmt.", false);
        VerifyItemJnlLineIsInbound(ItemJnlLine, ItemJnlLine."Entry Type"::"Assembly Consumption", false);
        VerifyItemJnlLineIsInbound(ItemJnlLine, ItemJnlLine."Entry Type"::Transfer, false);

        ItemJnlLine."Quantity (Base)" := -1;
        // Negative Qty
        ItemJnlLine.Quantity := -1;
        VerifyItemJnlLineIsInbound(ItemJnlLine, ItemJnlLine."Entry Type"::Purchase, false);
        VerifyItemJnlLineIsInbound(ItemJnlLine, ItemJnlLine."Entry Type"::Output, false);
        VerifyItemJnlLineIsInbound(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", false);
        VerifyItemJnlLineIsInbound(ItemJnlLine, ItemJnlLine."Entry Type"::"Assembly Output", false);
        VerifyItemJnlLineIsInbound(ItemJnlLine, ItemJnlLine."Entry Type"::Sale, true);
        VerifyItemJnlLineIsInbound(ItemJnlLine, ItemJnlLine."Entry Type"::Consumption, true);
        VerifyItemJnlLineIsInbound(ItemJnlLine, ItemJnlLine."Entry Type"::"Negative Adjmt.", true);
        VerifyItemJnlLineIsInbound(ItemJnlLine, ItemJnlLine."Entry Type"::"Assembly Consumption", true);
        VerifyItemJnlLineIsInbound(ItemJnlLine, ItemJnlLine."Entry Type"::Transfer, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B307197TransferLineIsInbound()
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine."Quantity (Base)" := 1;
        // Positive Qty
        Assert.AreEqual(false, TransferLine.IsInbound(), StrSubstNo('%1 %2 %3', TransferLine.TableName, TransferLine.FieldName("Quantity (Base)"), TransferLine."Quantity (Base)"));

        TransferLine."Quantity (Base)" := -1;
        // Negative Qty
        Assert.AreEqual(true, TransferLine.IsInbound(), StrSubstNo('%1 %2 %3', TransferLine.TableName, TransferLine.FieldName("Quantity (Base)"), TransferLine."Quantity (Base)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B307197ProdOrderLineIsInbound()
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine."Quantity (Base)" := 1;
        // Positive Qty
        Assert.AreEqual(true, ProdOrderLine.IsInbound(), StrSubstNo('%1 %2 %3', ProdOrderLine.TableName, ProdOrderLine.FieldName("Quantity (Base)"), ProdOrderLine."Quantity (Base)"));

        ProdOrderLine."Quantity (Base)" := -1;
        // Negative Qty
        Assert.AreEqual(false, ProdOrderLine.IsInbound(), StrSubstNo('%1 %2 %3', ProdOrderLine.TableName, ProdOrderLine.FieldName("Quantity (Base)"), ProdOrderLine."Quantity (Base)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B307197ProdOrderComponentIsInbound()
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent."Quantity (Base)" := 1;
        // Positive Qty
        Assert.AreEqual(false, ProdOrderComponent.IsInbound(), StrSubstNo('%1 %2 %3', ProdOrderComponent.TableName, ProdOrderComponent.FieldName("Quantity (Base)"), ProdOrderComponent."Quantity (Base)"));

        ProdOrderComponent."Quantity (Base)" := -1;
        // Negative Qty
        Assert.AreEqual(true, ProdOrderComponent.IsInbound(), StrSubstNo('%1 %2 %3', ProdOrderComponent.TableName, ProdOrderComponent.FieldName("Quantity (Base)"), ProdOrderComponent."Quantity (Base)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B307197AsmHeaderIsInbound()
    var
        AsmHeader: Record "Assembly Header";
    begin
        AsmHeader."Quantity (Base)" := 1;
        // Always Positive Qty
        VerifyAsmHeaderIsInbound(AsmHeader, AsmHeader."Document Type"::Quote, true);
        VerifyAsmHeaderIsInbound(AsmHeader, AsmHeader."Document Type"::Order, true);
        VerifyAsmHeaderIsInbound(AsmHeader, AsmHeader."Document Type"::"Blanket Order", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B307197AsmLineIsInbound()
    var
        AsmLine: Record "Assembly Line";
    begin
        AsmLine."Quantity (Base)" := 1;
        // Always Positive Qty
        VerifyAsmLineIsInbound(AsmLine, AsmLine."Document Type"::Quote, false);
        VerifyAsmLineIsInbound(AsmLine, AsmLine."Document Type"::Order, false);
        VerifyAsmLineIsInbound(AsmLine, AsmLine."Document Type"::"Blanket Order", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B307197ServiceLineIsInbound()
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine."Quantity (Base)" := 1;
        // Positive Qty
        VerifyServiceLineIsInbound(ServiceLine, ServiceLine."Document Type"::Quote, false);
        VerifyServiceLineIsInbound(ServiceLine, ServiceLine."Document Type"::Order, false);
        VerifyServiceLineIsInbound(ServiceLine, ServiceLine."Document Type"::Invoice, false);
        VerifyServiceLineIsInbound(ServiceLine, ServiceLine."Document Type"::"Credit Memo", true);

        ServiceLine."Quantity (Base)" := -1;
        // Negative Qty
        VerifyServiceLineIsInbound(ServiceLine, ServiceLine."Document Type"::Quote, true);
        VerifyServiceLineIsInbound(ServiceLine, ServiceLine."Document Type"::Order, true);
        VerifyServiceLineIsInbound(ServiceLine, ServiceLine."Document Type"::Invoice, true);
        VerifyServiceLineIsInbound(ServiceLine, ServiceLine."Document Type"::"Credit Memo", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B307197JobJnlLineIsInbound()
    var
        JobJnlLine: Record "Job Journal Line";
    begin
        JobJnlLine."Quantity (Base)" := 1;
        // Positive Qty
        VerifyJobJnlLineIsInbound(JobJnlLine, JobJnlLine."Entry Type"::Sale, false);
        VerifyJobJnlLineIsInbound(JobJnlLine, JobJnlLine."Entry Type"::Usage, false);

        JobJnlLine."Quantity (Base)" := -1;
        // Negative Qty
        VerifyJobJnlLineIsInbound(JobJnlLine, JobJnlLine."Entry Type"::Sale, true);
        VerifyJobJnlLineIsInbound(JobJnlLine, JobJnlLine."Entry Type"::Usage, true);
    end;

    [Test]
    [HandlerFunctions('ReservationHandler,ItemTrackingSingleLineHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPartialPostingWithReservation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify that there's no error during the partial post of Sales Order
        // in case of reservation from PO and ILE and assigning one Item Tracking Serial No.
        Initialize();

        CreateSOWithPOAndILEReservationAndOneItemTracking(SalesHeader, SalesLine);

        PostSalesOrderPartialShip(SalesHeader, SalesLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrkgManualLotNoHandler')]
    [Scope('OnPrem')]
    procedure B345019DecreaseQtyToHandle()
    var
        TransferOrderPage: TestPage "Transfer Order";
        LotNo: Code[50];
        QtyToUpdate: Option Quantity,"Quantity to Handle","Quantity to Invoice";
        ItemQty: Integer;
    begin
        // Verify that quantity to handle in inbound and outbound reservation entries is correct
        // after quantity to handle in tracking specification is changed

        Initialize();
        SetupTransferOrderTracking(TransferOrderPage, LotNo, ItemQty);

        SetTrackingSpecification(TransferOrderPage, LotNo, QtyToUpdate::"Quantity to Handle", ItemQty div 2);

        Assert.AreEqual(0, CalcQtyToHandleInReservEntries(LotNo), QtyToHandleMismatchErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrkgManualLotNoHandler,ItemTrackingLinesConfirmHandler')]
    [Scope('OnPrem')]
    procedure B345019IncreaseQty()
    var
        TransferOrderPage: TestPage "Transfer Order";
        LotNo: Code[50];
        QtyToUpdate: Option Quantity,"Quantity to Handle","Quantity to Invoice";
        ItemQty: Integer;
    begin
        // Verify that quantity to handle in inbound and outbound reservation entries is correct
        // after quantity in tracking specification is changed

        Initialize();
        SetupTransferOrderTracking(TransferOrderPage, LotNo, ItemQty);

        SetTrackingSpecification(TransferOrderPage, LotNo, QtyToUpdate::Quantity, ItemQty + LibraryRandom.RandInt(ItemQty));

        Assert.AreEqual(0, CalcQtyToHandleInReservEntries(LotNo), QtyToHandleMismatchErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrkgManualLotNoHandler')]
    [Scope('OnPrem')]
    procedure TransferOrderWithTwoLines()
    var
        TransferHeader: Record "Transfer Header";
        LotNo: Code[50];
    begin
        // Verify that after post shipment item tracking data transfered to all lines
        // TC for CD Sicily 54927

        // setup
        InitTransferOrderTwoLinesScenario(TransferHeader, LotNo);

        // execute: post shipment for transfer order
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // verify that item tracking specification for second line has same lot number
        VerifySecondTransferLineLotNo(TransferHeader, LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,EnterQuantityToCreateHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptWithExpirationDate()
    var
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // Test undoing Purchase Receipt is allowed when Expiration Date on Item Tracking Line is earlier than WORKDATE.

        // Setup: Create and post Purchase Order with Expiration Date. The Expiration Date is earlier than WORKDATE.
        Initialize();
        CreateAndPostPurchaseOrderWithItemTracking(PurchaseLine, WorkDate() - LibraryRandom.RandInt(10));
        FindPurchRcptLine(PurchRcptLine, PurchaseLine);

        // Exercise and Verify: Undo Purchase Receipt on WORKDATE and Verify no error pops up.
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // Verify: Verify a Purchase Line with negative quantity is generated.
        PurchRcptLine.FindLast();
        PurchRcptLine.TestField(Quantity, -PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignTrackingNoAndVerifyQuantityHandler')]
    [Scope('OnPrem')]
    procedure PartialPostPurchaseOrderWithJobAndLotTracking()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Test Quantities on Item Tracking Lines are correct after posting partial receive for Purchase Order with Job No. and Item Tracking
        PartialPostPurchaseDocumentWithJobAndLotTracking(PurchaseLine."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignTrackingNoAndVerifyQuantityHandler')]
    [Scope('OnPrem')]
    procedure PartialPostPurchaseReturnOrderWithJobAndLotTracking()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Test Quantities on Item Tracking Lines are correct after posting partial return shipment for Purchase Return Order with Job No. and Item Tracking
        PartialPostPurchaseDocumentWithJobAndLotTracking(PurchaseLine."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignTrackingNoAndVerifyQuantityHandler')]
    [Scope('OnPrem')]
    procedure PartialPostPurchaseOrderWithJobAndMultipleLotTracking()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Test Quantities on Item Tracking Lines are correct after posting partial receive for Purchase Order with Job No. and multiple Lot Item Tracking
        PartialPostPurchaseDocumentWithJobAndMultipleLotTracking(PurchaseLine."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignTrackingNoAndVerifyQuantityHandler')]
    [Scope('OnPrem')]
    procedure PartialPostPurchaseReturnOrderWithJobAndMultipleLotTracking()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Test Quantities on Item Tracking Lines are correct after posting partial return shipment for Purchase Return Order with Job No. and multiple Lot Item Tracking
        PartialPostPurchaseDocumentWithJobAndMultipleLotTracking(PurchaseLine."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignTrackingNoAndVerifyQuantityHandler')]
    [Scope('OnPrem')]
    procedure PartialPostPurchaseOrderMultipleLinesWithJobAndLotTracking()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Job]
        // [SCENARIO 171749] Reservation entries after posting partial receipt on a purchase order with multiple lines, each having job task and lot no. assigned

        Initialize();

        // [GIVEN] Item "I" with lot tracking
        // [GIVEN] Purchase order with 2 lines. Item "I" with lot no. and  job task assigned to each line.
        CreateMultilinePurchaseOrderWithJobAndLotTracking(PurchaseHeader);

        // [GIVEN] Set quantities. 1st line: "Quantity" = "X1", "Qty. to Receive" = "Y1", 2nd line: "Quantity" = "X2", "Qty. to Receive" = "Y2"
        UpdateQtyToReceiveOnPurchaseLines(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // [WHEN] Post purchase receipt
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Tracked quantity in the 1st line is "X1" - "Y1", in the 2nd line - "X2" - "Y2"
        VerifyPurchaseOrderTrackingLines(PurchaseHeader."Document Type", PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignTrackingNoAndVerifyQuantityHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PartialPostAndUndoPurchaseOrderMultipleLinesWithJobAndLotTracking()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // [FEATURE] [Purchase] [Job] [Undo Receipt]
        // [SCENARIO 171749] Reservation entries after posting partial receipt and undo recipt on a purchase order with multiple lines, each having job task and lot no. assigned

        Initialize();

        // [GIVEN] Item "I" with lot tracking
        // [GIVEN] Purchase order with 2 lines. Item "I" with lot no. and  job task assigned to each line.
        CreateMultilinePurchaseOrderWithJobAndLotTracking(PurchaseHeader);

        // [GIVEN] Set quantities. 1st line: "Quantity" = "X1", "Qty. to Receive" = "Y1", 2nd line: "Quantity" = "X2", "Qty. to Receive" = "Y2"
        UpdateQtyToReceiveOnPurchaseLines(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // [GIVEN] Post purchase receipt
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Undo receipt
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.FindLast();
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [THEN] Tracked quantity in the purchase order is restored: "X1" in the 1st line, "X2" in the 2nd line
        VerifyPurchaseOrderTrackingLines(PurchaseHeader."Document Type", PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure FillJobNoOnPurchaseLineWithLotTracking()
    var
        PurchaseLine: Record "Purchase Line";
        JobTask: Record "Job Task";
    begin
        // Test Job No. can be filled on Purchase Line with Item Tracking assigned.

        // Setup: Create Purchase Order, assign Lot Item Tracking on Purchase Line. Create Job.
        Initialize();
        CreatePurchaseOrderWithLotNoInItemTracking(PurchaseLine);
        CreateJobWithJobTask(JobTask);

        // Exercise: Fill Job No. and Job Task No. on Purchase Line with Lot No. Tracking assigned
        UpdatePurchaseLineWithJobTask(PurchaseLine, JobTask);

        // Verify: The Job No. can be filled on Purchase Line
        PurchaseLine.TestField("Job No.", JobTask."Job No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OpenItemTrackingHandler,StrMenuHandler,CreatePickFromWhseShptReqHandler')]
    [Scope('OnPrem')]
    procedure RFH360214_CreateWhseShptWithModifyingRsvdQtyAndAssignedItemTracking()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [SCENARIO 360214] "Qty. to Handle (Base)" is not correctly maintained after a modifying reserved and assigned Item Tracking in a Warehouse Shipment.
        Initialize();

        // [GIVEN] Post Purchase Order then Create and Release Sales Order For Item With Item Tracking
        PostPurchaseOrderAndCreateReleasedSalesOrder(SalesHeader, SalesLine);

        // [GIVEN] Create Whse. Shipment and Register Pick and assign Lot No on Item Tracking Lines in Whse. Shipment
        CreateWhseShipWithItemTrackingLines(WhseShipmentLine, SalesHeader, SalesLine);

        // [WHEN] Post Whse Shipment Line
        PostWhseShptLine(WhseShipmentLine);

        // [THEN] Verify Reserve Entry Qty. To Handle (Base) is equal to Sales Line Quantity (Base)
        VerifyQuantityOnPostWhseShipLine(WhseShipmentLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrkgManualLotNoHandler')]
    [Scope('OnPrem')]
    procedure ReclassifiedLotExpirationDateInInboundILE()
    var
        Item: Record Item;
        LotNo: Code[50];
        Qty: Integer;
        NewExpirationDate: Date;
    begin
        // [SCENARIO 361348] After a lot expiration date is changed via reclassification journal, new expiration date is used for all inbounds with the same lot no.
        Initialize();

        // [GIVEN] Item with lot no. tracking and expiration date
        LotNo := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandInt(100);
        CreateItem(Item, CreateItemTrackingCodeLotSpecific(true), '', LibraryUtility.GetGlobalNoSeriesCode());

        // [GIVEN] One lot with expiration date = D1 on inventory
        PostPositiveAdjmtWithLotExpTracking(Item, Qty, LotNo, WorkDate());

        // [GIVEN] Post reclassification journal to change lot expiration date. New expiration date = D2
        NewExpirationDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());
        PostExpDateReclassification(Item, Qty, LotNo, NewExpirationDate);

        // [GIVEN] Post outbound item ledger entry, so that all item ledger entries are closed
        PostNegativeAdjmtWithLotNo(Item, LotNo, Qty);

        // [WHEN] New inbound entry is posted
        PostPositiveAdjmtWithLotNo(Item, LotNo, Qty);

        // [THEN] Expiration date in the last inbound Item Ledger Entry is D2
        VerifyExpirationDateOnItemLedgerEntry(Item."No.", true, NewExpirationDate);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSingleLineLotHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPartialTracking()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LotNo: Code[10];
    begin
        // [FEATURE] [Shipment] [Item Tracking]
        // [SCENARIO 122002] Partial Shipment for an Item with free entry tracking can be posted with tracking after a Shipment without tracking.

        // [GIVEN] Item with free entry Item Tracking.
        Initialize();
        CreateItem(Item, CreateItemTrackingCodeFreeEntry(), LibraryUtility.GetGlobalNoSeriesCode(), '');
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] Post the partial Shipment without assigning Lot No.
        PostSalesOrderPartialShip(SalesHeader, SalesLine);
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(LotNo);

        // [GIVEN] Assign Lot No in Sales Line.
        SalesLine.OpenItemTrackingLines();

        // [WHEN] Post the second Shipment with assigned Lot No. "X"
        SalesLine.Find();
        PostSalesOrderPartialShip(SalesHeader, SalesLine);

        // [THEN] Shipment is posted, created ILE where "Lot No." = "X"
        VerifyFreeEntryTrackingExists(Item."No.", LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSingleLineLotHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderPartialTracking()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        LotNo: Code[10];
    begin
        // [FEATURE] [Return Receipt] [Item Tracking]
        // [SCENARIO 122002] Partial Receipt for an Item with free entry tracking can be posted with tracking after a Receipt without tracking (Sales Return).

        // [GIVEN] Item with free entry Item Tracking.
        Initialize();
        CreateItem(Item, CreateItemTrackingCodeFreeEntry(), LibraryUtility.GetGlobalNoSeriesCode(), '');
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", Item."No.", LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] Post the partial Receipt without assigning Lot No.
        PostSalesReturnOrderPartialRcpt(SalesHeader, SalesLine);
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(LotNo);

        // [GIVEN] Assign Lot No in Sales Line.
        SalesLine.OpenItemTrackingLines();

        // [WHEN] Post the second Receipt with assigned Lot No. "X"
        SalesLine.Find();
        PostSalesReturnOrderPartialRcpt(SalesHeader, SalesLine);

        // [THEN] Receipt is posted, created ILE where "Lot No." = "X"
        VerifyFreeEntryTrackingExists(Item."No.", LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSingleLineLotHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderPartialTracking()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LotNo: Code[10];
    begin
        // [FEATURE] [Receipt] [Item Tracking]
        // [SCENARIO 122002] Partial Receipt for an Item with free entry tracking can be posted with tracking after a Receipt without tracking.

        // [GIVEN] Item with free entry Item Tracking.
        Initialize();
        CreateItem(Item, CreateItemTrackingCodeFreeEntry(), LibraryUtility.GetGlobalNoSeriesCode(), '');
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Item."No.",
          LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] Post the partial Receipt without assigning Lot No.
        PostPurchaseOrderPartialRcpt(PurchaseHeader, PurchaseLine);
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(LotNo);

        // [GIVEN] Assign Lot No in Purchase Line.
        PurchaseLine.OpenItemTrackingLines();

        // [WHEN] Post the second Receipt with assigned Lot No. "X"
        PurchaseLine.Find();
        PostPurchaseOrderPartialRcpt(PurchaseHeader, PurchaseLine);

        // [THEN] Receipt is posted, created ILE where "Lot No." = "X"
        VerifyFreeEntryTrackingExists(Item."No.", LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSingleLineLotHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderPartialTracking()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        LotNo: Code[10];
    begin
        // [FEATURE] [Return Shipment] [Item Tracking]
        // [SCENARIO 122002] Partial Shipment for an Item with free entry tracking can be posted with tracking after a Shipment without tracking (Purchase Return).

        // [GIVEN] Item with free entry Item Tracking.
        Initialize();
        CreateItem(Item, CreateItemTrackingCodeFreeEntry(), LibraryUtility.GetGlobalNoSeriesCode(), '');
        LotNo := LibraryUtility.GenerateGUID();
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order",
          Item."No.", LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] Post the partial Shipment without assigning Lot No.
        PostPurchaseReturnOrderPartialShip(PurchaseHeader, PurchaseLine);
        LibraryVariableStorage.Enqueue(LotNo);

        // [GIVEN] Assign Lot No in Purchase Line.
        PurchaseLine.OpenItemTrackingLines();

        // [WHEN] Post the second Shipment with assigned Lot No. "X"
        PurchaseLine.Find();
        PostPurchaseReturnOrderPartialShip(PurchaseHeader, PurchaseLine);

        // [THEN] Shipment is posted, created ILE where "Lot No." = "X"
        VerifyFreeEntryTrackingExists(Item."No.", LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSingleLineLotHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPartialTrackingError()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LotNo: Code[10];
    begin
        // [FEATURE] [Shipment] [Item Tracking]
        // [SCENARIO 122002] Verify partial Item Tracking posting error for free entry tracked Item, Sales Order, when Quantity <> tracked Quantity.

        // [GIVEN] Item with free entry Item Tracking, partially shipped Sales Order. Assign Lot No in Sales Line.
        Initialize();
        CreateItem(Item, CreateItemTrackingCodeFreeEntry(), LibraryUtility.GetGlobalNoSeriesCode(), '');
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandIntInRange(50, 100));
        PostSalesOrderPartialShip(SalesHeader, SalesLine);
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(LotNo);
        SalesLine.OpenItemTrackingLines();
        // [GIVEN] Sales Line quantity to ship is not equal to tracked quantity.
        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", 2);
        // 1(tracked quantity) + 1
        SalesLine.Modify(true);

        // [WHEN] Post Sales Order.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] The error "Quantity to Ship does not match tracked quantity".
        Assert.AreEqual(
          StrSubstNo(TrackedQuantityErr, SalesLine.FieldCaption("Qty. to Ship"), SalesLine."No."),
          GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSingleLineLotHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderPartialTrackingError()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LotNo: Code[10];
    begin
        // [FEATURE] [Receipt] [Item Tracking]
        // [SCENARIO 122002] Verify partial Item Tracking posting error for free entry tracked Item, Purchase Order, when Quantity <> tracked Quantity.

        // [GIVEN] Item with free entry Item Tracking, partially received Purchase Order. Assign Lot No in Purchase Line.
        Initialize();
        CreateItem(Item, CreateItemTrackingCodeFreeEntry(), LibraryUtility.GetGlobalNoSeriesCode(), '');
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Item."No.",
          LibraryRandom.RandIntInRange(50, 100));
        PostPurchaseOrderPartialRcpt(PurchaseHeader, PurchaseLine);
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(LotNo);
        PurchaseLine.OpenItemTrackingLines();
        // [GIVEN] Purchase Line quantity to receive is not equal to tracked quantity.
        PurchaseLine.Find();
        PurchaseLine.Validate("Qty. to Receive", 2);
        // 1(tracked quantity) + 1
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase Order.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] The error "Quantity to Receive does not match tracked quantity".
        Assert.AreEqual(
          StrSubstNo(TrackedQuantityErr, PurchaseLine.FieldCaption("Qty. to Receive"), PurchaseLine."No."),
          GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,EnterQuantityToCreateHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptContainsExpirationDate()
    var
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ExpirationDate: Date;
    begin
        // [FEATURE] [Undo Purchase Receipt] [Item Tracking] [Expiration Date]
        // [SCENARIO 363849] Item Ledger Entry for undo of Purchase Receipt with "Expiration Date" should contain "Expiration Date".

        // [GIVEN] Post Purchase Order where "Expiration Date" = "D"
        Initialize();
        ExpirationDate := WorkDate() + LibraryRandom.RandInt(10);
        CreateAndPostPurchaseOrderWithItemTracking(PurchaseLine, ExpirationDate);
        FindPurchRcptLine(PurchRcptLine, PurchaseLine);

        // [WHEN] Undo Purchase Receipt.
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [THEN] "Expiration Date" = "D" in undo Item Ledger Entry.
        ItemLedgerEntry.FindLast();
        ItemLedgerEntry.TestField("Expiration Date", ExpirationDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageWithLineNoShownWhenPostItemJnlLineWithoutLotNo()
    var
        Item: Record Item;
        LineNo: Integer;
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 378978] Error message with current "Line No." is shown when post Item Journal Line without "Lot No." assigned

        Initialize();

        // [GIVEN] Item "X" with "Lot Specific Tracking"
        CreateItemWithTrackingCode(Item, true, false);

        // [WHEN] Post Item Journal Line without "Lot No." assigned
        asserterror CreatePostItemJnlLine(LineNo, Item."No.");

        // [THEN] Error Message "Lot No. required. Line No. = '10000'" is shown
        Assert.AreEqual(
          GetLastErrorText, StrSubstNo(LotNoRequiredErr, Item."No.") + StrSubstNo(LineNoTxt, LineNo), IncorrectErrorMessageErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageWithLineNoShownWhenPostItemJnlLineWithoutSerialNo()
    var
        Item: Record Item;
        LineNo: Integer;
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 378978] Error message with current "Line No." is shown when post Item Journal Line without "Serial No." assigned

        Initialize();

        // [GIVEN] Item "X" with "SN Specific Tracking"
        CreateItemWithTrackingCode(Item, false, true);

        // [WHEN] Post Item Journal Line without "Serial No." assigned
        asserterror CreatePostItemJnlLine(LineNo, Item."No.");

        // [THEN] Error Message "Serial No. required. Line No. = '10000'" is shown
        Assert.AreEqual(
          GetLastErrorText, StrSubstNo(SerialNoRequiredErr, Item."No.") + StrSubstNo(LineNoTxt, LineNo), IncorrectErrorMessageErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LotNoRequiredErrorMessageShownWhenPostPurchOrderWithoutLotNo()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Tracking] [Purchase]
        // [SCENARIO 378978] Error message "Lot No. required" is shown when post Purchase Order without "Lot No." assigned

        Initialize();

        // [GIVEN] Item "X" with "Lot Specific Tracking"
        CreateItemWithTrackingCode(Item, true, false);

        // [GIVEN] Purchase Order with Item "X" without "Lot No." assigned
        CreatePurchaseOrder(PurchHeader, PurchLine, Item."No.");

        // [WHEN] Post Purchase Document
        asserterror LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] Error Message "Lot No. required." is shown
        Assert.AreEqual(
          GetLastErrorText, StrSubstNo(LotNoRequiredErr, Item."No."), IncorrectErrorMessageErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SerialNoRequiredErrorMessageShownWhenPostPurchOrderWithoutSerialNo()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Tracking] [Purchase]
        // [SCENARIO 378978] Error message "Serial No. required" is shown when post Purchase Order without "Lot No." assigned

        Initialize();

        // [GIVEN] Item "X" with "SN Specific Tracking"
        CreateItemWithTrackingCode(Item, false, true);

        // [GIVEN] Purchase Order with Item "X" without "Serial No." assigned
        CreatePurchaseOrder(PurchHeader, PurchLine, Item."No.");

        // [WHEN] Post Purchase Document
        asserterror LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] Error Message "Serial No. required." is shown
        Assert.AreEqual(
          GetLastErrorText, StrSubstNo(SerialNoRequiredErr, Item."No."), IncorrectErrorMessageErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrkgManualLotNoHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingIsCopiedFromJobPlanningLineToJobJournal()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        JobJournalLine: Record "Job Journal Line";
        JobTransferLine: Codeunit "Job Transfer Line";
        LotNo: Code[10];
    begin
        // [FEATURE] [Job] [Job Journal]
        // [SCENARIO 380627] Item Tracking should be copied from Job Planning Line to Job Journal Line.
        Initialize();

        // [GIVEN] Lot-tracked Item with "Reordering Policy" = Order.
        // [GIVEN] Job Planning Line for Item.
        // [GIVEN] Purchase Order created out of Requisition Worksheet to cover the planning demand.
        // [GIVEN] Purchase Order is tracked and posted with Receive option.
        CreateReservedJobPlanningLine(JobPlanningLine, LotNo);

        // [WHEN] Create Job Journal Line from Job Planning Line.
        JobTransferLine.FromPlanningLineToJnlLine(JobPlanningLine, WorkDate(), LibraryJob.GetJobJournalTemplate(JobJournalTemplate),
          LibraryJob.CreateJobJournalBatch(LibraryJob.GetJobJournalTemplate(JobJournalTemplate), JobJournalBatch), JobJournalLine);

        // [THEN] Item Tracking is transferred to Job Journal Line.
        VerifyJobJournalLineReservEntry(JobJournalLine, LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrkgManualLotNoHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure ItemPostedByJobJournalInheritsTrackingFromJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        JobJournalLine: Record "Job Journal Line";
        JobTransferLine: Codeunit "Job Transfer Line";
        LotNo: Code[10];
    begin
        // [FEATURE] [Job] [Job Journal]
        // [SCENARIO 380627] Item Ledger Entry which is created by posting of Job Journal Line with inherited Item Tracking contains Lot No. from Job Planning Line.
        Initialize();

        // [GIVEN] Lot-tracked Item "I" with "Reordering Policy" = Order.
        // [GIVEN] Job Planning Line for Item.
        // [GIVEN] Purchase Order created out of Requisition Worksheet to cover the planning demand.
        // [GIVEN] Lot "L" is assigned to Purchase Line.
        // [GIVEN] Purchase Order is posted with Receive option.
        CreateReservedJobPlanningLine(JobPlanningLine, LotNo);

        // [GIVEN] Job Journal Line is created from Job Planning Line.
        JobTransferLine.FromPlanningLineToJnlLine(JobPlanningLine, WorkDate(), LibraryJob.GetJobJournalTemplate(JobJournalTemplate),
          LibraryJob.CreateJobJournalBatch(LibraryJob.GetJobJournalTemplate(JobJournalTemplate), JobJournalBatch), JobJournalLine);

        // [WHEN] Post Job Journal Line.
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Item Ledger Entry with Item "I" and Lot "L" is created.
        VerifyItemLedgerEntryLotNo(JobJournalLine."Document No.", JobJournalLine."No.", LotNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExpirationDateWithLotAndSerialPositive()
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        LotNo: Code[50];
        I: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381065] Function TestExpDateOnTrackingSpec in codeunit 6500 should throw an error when two tracking lines with the same lot and different serial numbers have different expiration dates

        LotNo := LibraryUtility.GenerateRandomCode(TempTrackingSpecification.FieldNo("Lot No."), DATABASE::"Tracking Specification");

        for I := 1 to 2 do
            MockTrackingSpecification(
              TempTrackingSpecification, I, LotNo,
              LibraryUtility.GenerateRandomCode(TempTrackingSpecification.FieldNo("Serial No."), DATABASE::"Tracking Specification"),
              WorkDate() + I);

        asserterror ItemTrackingManagement.TestExpDateOnTrackingSpec(TempTrackingSpecification);
        Assert.ExpectedError(StrSubstNo(MultipleExpDateForLotErr, LotNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExpirationDateWithLotAndSerialNegative()
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        LotNo: Code[50];
        SerialNo: Code[50];
        I: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381065] Function TestExpDateOnTrackingSpec in codeunit 6500 should throw an error when two tracking lines with the same lot and serial number have different expiration dates

        LotNo := LibraryUtility.GenerateRandomCode(TempTrackingSpecification.FieldNo("Lot No."), DATABASE::"Tracking Specification");
        SerialNo :=
          LibraryUtility.GenerateRandomCode(TempTrackingSpecification.FieldNo("Serial No."), DATABASE::"Tracking Specification");

        for I := 1 to 2 do
            MockTrackingSpecification(TempTrackingSpecification, I, LotNo, SerialNo, WorkDate() + I);

        asserterror ItemTrackingManagement.TestExpDateOnTrackingSpec(TempTrackingSpecification);
        Assert.ExpectedError(StrSubstNo(MultipleExpDateForLotErr, LotNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExpirationDateWithNewLotAndNewSerialPositive()
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        LotNo: Code[50];
        I: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381065] Function TestExpDateOnTrackingSpec in codeunit 6500 should throw an error when two tracking lines with the same "New Lot No." and different "New serial nos." have different expiration dates

        LotNo := LibraryUtility.GenerateRandomCode(TempTrackingSpecification.FieldNo("New Lot No."), DATABASE::"Tracking Specification");

        for I := 1 to 2 do
            MockTrackingSpecification(
              TempTrackingSpecification, I, LotNo,
              LibraryUtility.GenerateRandomCode(TempTrackingSpecification.FieldNo("Serial No."), DATABASE::"Tracking Specification"),
              WorkDate() + I);

        asserterror ItemTrackingManagement.TestExpDateOnTrackingSpecNew(TempTrackingSpecification);
        Assert.ExpectedError(StrSubstNo(MultipleExpDateForLotErr, LotNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExpirationDateWithNewLotAndNewSerialNegative()
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        LotNo: Code[50];
        I: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381065] Function TestExpDateOnTrackingSpec in codeunit 6500 should throw an error when two tracking lines with the same "New Lot No." without serial numbers have different expiration dates

        LotNo := LibraryUtility.GenerateRandomCode(TempTrackingSpecification.FieldNo("New Lot No."), DATABASE::"Tracking Specification");

        for I := 1 to 2 do
            MockTrackingSpecification(TempTrackingSpecification, I, LotNo, '', WorkDate() + I);

        asserterror ItemTrackingManagement.TestExpDateOnTrackingSpecNew(TempTrackingSpecification);
        Assert.ExpectedError(StrSubstNo(MultipleExpDateForLotErr, LotNo));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignTrackingNoAndVerifyQuantityHandler,EnterQuantityToCreateHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnOrderForExpiredItemWithoutApplication()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Return Order] [Expiration Date]
        // [SCENARIO 209105] It should be possible to post a purchase return order with an expired item without item ledger application

        Initialize();
        // [GIVEN] Purchase item "I" with expiration date 01.03.YY
        LibraryVariableStorage.Enqueue(TrackingOptionStr::AssignSerialNo);
        CreateAndPostPurchaseOrderWithItemTracking(PurchaseLine, WorkDate());

        // [GIVEN] Create purchase return order for item "I" with posting date 02.03.YY. Select the serial no. from the posted purchase entry.
        CreatePurchaseDocumentWithPostingDate(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", PurchaseLine."Buy-from Vendor No.", WorkDate() + 1,
          PurchaseLine."No.", PurchaseLine.Quantity);

        // [WHEN] Post the purchase return order
        PostPurchaseDocumentWithTracking(PurchaseLine, TrackingOptionStr::SelectEntries);

        // [THEN] Purchase return entry is created with expiration date 01.03.YY
        VerifyExpirationDateOnItemLedgerEntry(PurchaseLine."No.", false, WorkDate());
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignTrackingNoAndVerifyQuantityHandler,EnterQuantityToCreateHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoForExpiredItem()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Expiration Date]
        // [SCENARIO 209105] It should be possible to post a purchase credit memo for an expired item

        Initialize();
        // [GIVEN] Purchase item "I" with expiration date 01.03.YY
        LibraryVariableStorage.Enqueue(TrackingOptionStr::AssignSerialNo);
        CreateAndPostPurchaseOrderWithItemTracking(PurchaseLine, WorkDate());

        // [GIVEN] Create purchase credit memo for item "I" with posting date 02.03.YY. Select the serial no. from the posted purchase entry.
        CreatePurchaseDocumentWithPostingDate(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", PurchaseLine."Buy-from Vendor No.", WorkDate() + 1,
          PurchaseLine."No.", PurchaseLine.Quantity);

        // [WHEN] Post the purchase credit memo
        PostPurchaseDocumentWithTracking(PurchaseLine, TrackingOptionStr::SelectEntries);

        // [THEN] Purchase return entry is created with expiration date 01.03.YY
        VerifyExpirationDateOnItemLedgerEntry(PurchaseLine."No.", false, WorkDate());
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignTrackingNoAndVerifyQuantityHandler,EnterQuantityToCreateHandler,GetPostedDocLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnOrderForExpiredItemWithApplication()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Return Order] [Expiration Date]
        // [SCENARIO 209105] It should be possible to post a purchase return order with an expired item with item ledger application

        Initialize();
        // [GIVEN] Purchase item "I" with expiration date 01.03.YY
        LibraryVariableStorage.Enqueue(TrackingOptionStr::AssignSerialNo);
        CreateAndPostPurchaseOrderWithItemTracking(PurchaseLine, WorkDate());

        ItemLedgerEntry.SetRange("Item No.", PurchaseLine."No.");
        ItemLedgerEntry.FindFirst();

        // [GIVEN] Create purchase return order for item "I" with posting date 02.03.YY.
        CreatePurchaseHeaderWithPostingDate(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", PurchaseLine."Buy-from Vendor No.", WorkDate() + 1);
        // [GIVEN] Run "Get Posted Document Lines to Reverse" to retrive lines from the posted purchase receipt
        PurchaseHeader.GetPstdDocLinesToReverse();

        // [WHEN] Post the purchase return order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Purchase return entry is created with expiration date 01.03.YY
        VerifyExpirationDateOnItemLedgerEntry(PurchaseLine."No.", false, WorkDate());
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,EnterQuantityToCreateHandler,ItemTrackingSummaryModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingSelectEntriesIsNotEditableWhenInvokedFromInboundLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 213204] Selected Quantity should neither be visible nor editable on Item Entry Summary page when it is invoked from Item Tracking of inbound document line.
        Initialize();

        // [GIVEN] Posted Purchase Order with a serial no. tracked item "X".
        CreateAndPostPurchaseOrderWithItemTracking(PurchaseLine, WorkDate());
        ItemNo := PurchaseLine."No.";

        // [GIVEN] Another Purchase Order with item "X".
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo);

        // [WHEN] Open Item Tracking Lines for the purchase line and click "Select Entries".
        SalesMode := true;
        PurchaseLine.OpenItemTrackingLines();

        // [THEN] Selected Quantity field is not visible on Item Tracking Summary page.
        // [THEN] Selected Quantity field is not editable on Item Tracking Summary page.
        // Verification is done in ItemTrackingSummaryModalPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesLotAndSerialHanlder')]
    [Scope('OnPrem')]
    procedure PickShipmentSNAndLotTrackedItemWithExpirationDate()
    var
        Item: Record Item;
        Location: array[2] of Record Location;
        Bin: Record Bin;
        TransferHeader: Record "Transfer Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        I: Integer;
        Qty: Integer;
        LotNo: Code[50];
        SerialNos: array[6] of Code[20];
        ExpirationDate: Date;
    begin
        // [FEATURE] [Transfer] [Expiration Date]
        // [SCENARIO 233962] It should be possible to post transfer shipment with expiration date when item is tracked by Lot No. and SN simultaniosly and lot is split into several parts

        Initialize();

        // [GIVEN] Item "I" tracked by both serial and lot nos.
        CreateItem(Item, CreateItemTrackingCodeLotSerial(), '', '');

        // [GIVEN] Location "L" with shipment and pick
        CreateLocationWithBins(Location[1], Bin);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);

        // [GIVEN] Post item stock for 1 pc of item "I", serial no. "S1", lot no. "L1", expiration date 01.01.2019
        // [GIVEN] Post item stock for 1 pc of item "I", serial no. "S2", lot no. "L1", expiration date 01.01.2019
        LotNo := LibraryUtility.GenerateGUID();
        ExpirationDate := LibraryRandom.RandDateFromInRange(WorkDate(), 10, 20);

        Qty := LibraryRandom.RandIntInRange(2, 6);
        for I := 1 to Qty do begin
            SerialNos[I] := LibraryUtility.GenerateGUID();
            PostItemJnlLineWithLotSerialExpDate(Item."No.", Location[1].Code, Bin.Code, LotNo, SerialNos[I], ExpirationDate);
        end;

        // [GIVEN] Create a transfer order, create a warehouse shipment and pick
        CreateAndReleaseTransferOrder(TransferHeader, Location[1].Code, Location[2].Code, Item."No.", Qty);
        CreateWhseShipmentAndPickFromTransferOrder(WarehouseShipmentHeader, TransferHeader);

        for I := 1 to Qty do begin
            UpdateSerialNoOnWhseActivityLine(WarehouseShipmentHeader."No.", WarehouseActivityLine."Action Type"::Take, SerialNos[I]);
            UpdateSerialNoOnWhseActivityLine(WarehouseShipmentHeader."No.", WarehouseActivityLine."Action Type"::Place, SerialNos[I]);
        end;

        // [GIVEN] Post the warehouse pick
        RegisterWhseActivity(WarehouseShipmentHeader."No.");

        // [WHEN] Post warehouse shipment
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Two pcs of item "I" are moved to transit
        Item.SetRange("Location Filter", TransferHeader."In-Transit Code");
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, Qty);
    end;

    [Test]
    [HandlerFunctions('OpenItemTrackingHandler')]
    [Scope('OnPrem')]
    procedure DecreaseLotTrackedPurchaseInvoice()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LotNo: Code[10];
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 253101] The error occurs when decrease quantity in lot tracked purchase invoice line.
        Initialize();

        LotNo := LibraryUtility.GenerateGUID();
        CreateItemWithTrackingCode(Item, true, false);

        // [GIVEN] Purchase invoice with lot tracked item
        CreatePurchaseDocumentWithLotTrackedItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, Item."No.", LibraryRandom.RandIntInRange(11, 20), LotNo);

        // [WHEN] Decrease quantity in the line
        // [THEN] The error 'You must adjust the existing item tracking and then reenter the new quantity' is raised
        asserterror PurchaseLine.Validate(Quantity, LibraryRandom.RandInt(10));
        Assert.ExpectedError(AdjustTrackingErr);
    end;

    [Test]
    [HandlerFunctions('OpenItemTrackingHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DecreaseLotTrackedSalesInvoice()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LotNo: Code[10];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 253101] The error occurs when decrease quantity in lot tracked sales invoice line.
        Initialize();

        LotNo := LibraryUtility.GenerateGUID();
        CreateItemWithTrackingCode(Item, true, false);

        CreateLotTrackedItemInventory(Item."No.", LibraryRandom.RandIntInRange(21, 30), LotNo);

        // [GIVEN] Sales invoice with lot tracked item
        CreateSalesDocumentWithLotTrackedItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Item."No.", LibraryRandom.RandIntInRange(11, 20), LotNo);

        // [WHEN] Decrease quantity in the line
        // [THEN] The error 'You must adjust the existing item tracking and then reenter the new quantity' is raised
        asserterror SalesLine.Validate(Quantity, LibraryRandom.RandInt(10));
        Assert.ExpectedError(AdjustTrackingErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesLotAndSerialHanlder')]
    [Scope('OnPrem')]
    procedure WhsPickShipmentSNAndLotTrackedItemWithExpirationDate()
    var
        Item: Record Item;
        Location: array[2] of Record Location;
        Bin: Record Bin;
        TransferHeader: Record "Transfer Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        I: Integer;
        Qty: Integer;
        LotNo: Code[50];
        SerialNos: array[10] of Code[20];
        ExpirationDate: Date;
    begin
        Initialize();

        // [GIVEN] Item "I" tracked by both serial and lot nos.
        CreateItem(Item, CreateItemTrackingCodeLotSerial(), '', '');

        // [GIVEN] Location "L1" with shipment and pick
        CreateLocationWithBins(Location[1], Bin);

        // [GIVEN] Location "L2" with base settings
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);

        // [GIVEN] Post item stock for x pcs of item "I", serial no. "S1", lot no. "L1", expiration date 
        LotNo := LibraryUtility.GenerateGUID();
        ExpirationDate := LibraryRandom.RandDateFromInRange(WorkDate(), 10, 20);

        Qty := LibraryRandom.RandIntInRange(5, 10);
        for I := 1 to Qty do begin
            SerialNos[I] := LibraryUtility.GenerateGUID();
            PostItemJnlLineWithLotSerialExpDate(Item."No.", Location[1].Code, Bin.Code, LotNo, SerialNos[I], ExpirationDate);
        end;

        // [GIVEN] Create a transfer order, create a warehouse shipment and pick
        CreateAndReleaseTransferOrder(TransferHeader, Location[1].Code, Location[2].Code, Item."No.", Qty);
        CreateWhseShipmentAndPickFromTransferOrder(WarehouseShipmentHeader, TransferHeader);

        // [GIVEN] Update pick lines with serial no.
        for I := 1 to Qty do begin
            UpdateSerialNoOnWhseActivityLine(WarehouseShipmentHeader."No.", WarehouseActivityLine."Action Type"::Take, SerialNos[I]);
            UpdateSerialNoOnWhseActivityLine(WarehouseShipmentHeader."No.", WarehouseActivityLine."Action Type"::Place, SerialNos[I]);
        end;

        // [WHEN] Post the warehouse pick
        RegisterWhseActivity(WarehouseShipmentHeader."No.");

        // [THEN] Post warehouse shipment is possible
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Transfer order receipt can be posted
        TransferHeader.Find();
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);
    end;

    [Test]
    [HandlerFunctions('OpenItemTrackingHandler')]
    [Scope('OnPrem')]
    procedure RetrieveDocumentItemTrackingFromPurchaseReceipt()
    var
        Item: array[2] of Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ItemTrackingDocManagement: Codeunit "Item Tracking Doc. Management";
        LotNos: array[2, 3] of Code[20];
        LotQtys: array[2, 3] of Decimal;
        TotalQty: array[2] of Decimal;
        I: Integer;
        J: Integer;
    begin
        // [FEATURE] [Purchase] [Receipt]
        // [SCENARIO 269088] Function RetrieveDocumentItemTracking in codeunit "Item Tracking Doc. Management" can retrieve item tracking specification from posted purchase receipts

        Initialize();

        // [GIVEN] Two lot tracked items: "I1" and "I2"
        for I := 1 to ArrayLen(Item) do
            for J := 1 to ArrayLen(LotNos[I]) do begin
                LotNos[I, J] := LibraryUtility.GenerateGUID();
                LotQtys[I, J] := LibraryRandom.RandDec(100, 2);
                TotalQty[I] += LotQtys[I, J];
            end;

        // [GIVEN] Purchase order with two lines - one line per item. Assign three different lot numbers to each line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        for I := 1 to ArrayLen(Item) do begin
            LibraryItemTracking.CreateLotItem(Item[I]);
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item[I]."No.", TotalQty[I]);

            LibraryVariableStorage.Enqueue(ArrayLen(LotNos[I]));
            for J := 1 to ArrayLen(LotNos[I]) do begin
                LibraryVariableStorage.Enqueue(LotNos[I, J]);
                LibraryVariableStorage.Enqueue(LotQtys[I, J]);
            end;
            PurchaseLine.OpenItemTrackingLines();
        end;

        // [GIVEN] Post receipt from the purchase order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Retrieve item tracking from the posted purchase receipt
        PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptHeader.FindFirst();
        Assert.AreEqual(
          ArrayLen(LotNos),
          ItemTrackingDocManagement.RetrieveDocumentItemTracking(
            TempTrackingSpecification, PurchRcptHeader."No.", DATABASE::"Purch. Rcpt. Header", 0), WrongNoOfTrackingSpecsErr);

        // [THEN] 6 item tracking specification records are returned, each containing a lot no. with respective quantity
        for I := 1 to ArrayLen(Item) do
            for J := 1 to ArrayLen(LotNos[I]) do begin
                TempTrackingSpecification.SetRange("Lot No.", LotNos[I, J]);
                TempTrackingSpecification.FindFirst();
                TempTrackingSpecification.TestField("Item No.", Item[I]."No.");
                TempTrackingSpecification.TestField("Quantity (Base)", LotQtys[I, J]);
            end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTrackingOnNewSalesLineExistsCheck()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 283200] Function ItemTrackingExistsOnDocumentLine in Codeunit 6500 checks if Item Tracking Lines exist on new sales line.
        Initialize();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLineSimple(SalesLine[1], SalesHeader);
        LibrarySales.CreateSalesLineSimple(SalesLine[2], SalesHeader);

        MockReservEntryForSalesLine(SalesLine[1], '', 0);
        MockReservEntryForSalesLine(SalesLine[2], LibraryUtility.GenerateGUID(), 0);

        Assert.IsFalse(
          ItemTrackingMgt.ItemTrackingExistsOnDocumentLine(
            DATABASE::"Sales Line", SalesLine[1]."Document Type".AsInteger(), SalesLine[1]."Document No.", SalesLine[1]."Line No."),
          'Item Tracking does not exist on the sales line.');

        Assert.IsTrue(
          ItemTrackingMgt.ItemTrackingExistsOnDocumentLine(
            DATABASE::"Sales Line", SalesLine[2]."Document Type".AsInteger(), SalesLine[2]."Document No.", SalesLine[2]."Line No."),
          'Item Tracking does not exist on the sales line.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTrackingOnShippedSalesLineExistsCheck()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 283200] Function ItemTrackingExistsOnDocumentLine in Codeunit 6500 checks if Item Tracking Lines exist on shipped sales line.
        Initialize();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLineSimple(SalesLine[1], SalesHeader);
        LibrarySales.CreateSalesLineSimple(SalesLine[2], SalesHeader);

        MockTrackingSpecificationForSalesLine(SalesLine[1], true);
        MockTrackingSpecificationForSalesLine(SalesLine[2], false);

        Assert.IsFalse(
          ItemTrackingMgt.ItemTrackingExistsOnDocumentLine(
            DATABASE::"Sales Line", SalesLine[1]."Document Type".AsInteger(), SalesLine[1]."Document No.", SalesLine[1]."Line No."),
          'Item Tracking does not exist on the sales line.');

        Assert.IsTrue(
          ItemTrackingMgt.ItemTrackingExistsOnDocumentLine(
            DATABASE::"Sales Line", SalesLine[2]."Document Type".AsInteger(), SalesLine[2]."Document No.", SalesLine[2]."Line No."),
          'Item Tracking does exist on the sales line.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculationOfQtyToHandleOnTrackedDocLineCheck()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        QtyToHandleBase: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 283200] Function CalcQtyToHandleForTrackedQtyOnDocumentLine in codeunit 6500 calculates "Qty. to Handle" in item tracking lines for a given document line.
        Initialize();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);

        QtyToHandleBase := LibraryRandom.RandInt(100);

        MockReservEntryForSalesLine(SalesLine, '', QtyToHandleBase);
        MockReservEntryForSalesLine(SalesLine, LibraryUtility.GenerateGUID(), QtyToHandleBase);
        MockReservEntryForSalesLine(SalesLine, LibraryUtility.GenerateGUID(), QtyToHandleBase);

        Assert.AreEqual(
          2 * QtyToHandleBase,
          ItemTrackingMgt.CalcQtyToHandleForTrackedQtyOnDocumentLine(
            DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No."),
          'Wrong Qty. to Handle in item tracking for the sales line.');
    end;

    [Test]
    [HandlerFunctions('MultipleItemTrackingModalPageHandler')]
    [Scope('OnPrem')]
    procedure QtyToHandleDistributionOnMultipleReservEntriesQtyFullCover()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservEntry: Record "Reservation Entry";
        LotNo1: Code[20];
        LotNo2: Code[20];
        Qty1: Decimal;
        Qty2: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Tracking Specification] [Item Tracking]
        // [SCENARIO 281757] "Qty. to Handle" must be distributed evenly when Item Tracking Lines page is closed for Transfer Orders, case when "Qty. to Handle" = Quantity in the end
        Initialize();

        // [GIVEN] Create single-line Transfer Order
        CreateTransferOrderOnNewItem(TransferHeader, TransferLine, LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] Create 2 lot ID's
        LotNo1 := LibraryUtility.GenerateGUID();
        LotNo2 := LibraryUtility.GenerateGUID();

        // [GIVEN] Create 2 quantities
        Qty1 := LibraryRandom.RandInt(5);
        Qty2 := LibraryRandom.RandInt(10);

        // [GIVEN] Create 2 entries on Item Tracking Page for 2 lots with nonzero Qty's and Qty. To Handle = 0
        InitialItemTrkgSetup(TransferLine, LotNo1, Qty1, 0, LotNo2, Qty2, 0);

        // [GIVEN] Double Qty for Lot #2, Qty. To Handle remains 0
        DoubleQtyOnItemTracking(TransferLine, 2);

        // [GIVEN] Double Qty for Lot #1, Qty. To Handle remains 0
        DoubleQtyOnItemTracking(TransferLine, 1);

        // [WHEN] Align quantities: Qty. To Handle := Quantity for both lots
        AlignQuantitiesForBothLots(TransferLine);

        // [THEN] Sums of Quantity and Qty. to Handle are equal for each lot
        for i := 0 to 1 do begin
            ReservEntry.SetRange("Source Subtype", i);

            ReservEntry.SetRange("Lot No.", LotNo1);
            Assert.AreEqual(Qty1 * 2, Abs(SumUpQtyToHandle(ReservEntry)), QtyAndQtyToHandleMismatchErr);

            ReservEntry.SetRange("Lot No.", LotNo2);
            Assert.AreEqual(Qty2 * 2, Abs(SumUpQtyToHandle(ReservEntry)), QtyAndQtyToHandleMismatchErr);
        end;

        // [THEN] Qty to Handle total are 0 for each lot
        Assert.AreEqual(0, CalcQtyToHandleInReservEntries(LotNo1), QtyToHandleMismatchErr);
        Assert.AreEqual(0, CalcQtyToHandleInReservEntries(LotNo2), QtyToHandleMismatchErr);
    end;

    [Test]
    [HandlerFunctions('MultipleItemTrackingModalPageHandler')]
    [Scope('OnPrem')]
    procedure QtyToHandleDistributionOnMultipleReservEntriesQtyPartialCover()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservEntry: Record "Reservation Entry";
        LotNo1: Code[20];
        LotNo2: Code[20];
        Qty1: Decimal;
        Qty2: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Tracking Specification] [Item Tracking]
        // [SCENARIO 281757] "Qty. to Handle" must be distributed evenly when Item Tracking Lines page is closed for Transfer Orders, case when "Qty. to Handle" < Quantity in the end
        Initialize();

        // [GIVEN] Create single-line Transfer Order
        CreateTransferOrderOnNewItem(TransferHeader, TransferLine, LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] Create 2 lot ID's
        LotNo1 := LibraryUtility.GenerateGUID();
        LotNo2 := LibraryUtility.GenerateGUID();

        // [GIVEN] Create 2 quantities
        Qty1 := LibraryRandom.RandInt(5);
        Qty2 := LibraryRandom.RandInt(10);

        // [GIVEN] Create 2 entries on Item Tracking Page for 2 lots with nonzero Qty's and Qty. To Handle = 0
        InitialItemTrkgSetup(TransferLine, LotNo1, Qty1, 0, LotNo2, Qty2, 0);

        // [GIVEN] Double Qty for Lot #2, Qty. To Handle remains 0
        DoubleQtyOnItemTracking(TransferLine, 2);

        // [GIVEN] Double Qty for Lot #1, Qty. To Handle remains 0
        DoubleQtyOnItemTracking(TransferLine, 1);

        // [WHEN] Set Qty. To Handle < Quantity for both lots
        SetQtyToHandleLessThanQuantityForBothLots(TransferLine);

        // [THEN] Sum of Quantity is twice as big as sum of Qty. to Handle for each lot
        for i := 0 to 1 do begin
            ReservEntry.SetRange("Source Subtype", i);

            ReservEntry.SetRange("Lot No.", LotNo1);
            Assert.AreEqual(Qty1, Abs(SumUpQtyToHandle(ReservEntry)), QtyAndQtyToHandleMismatchErr);

            ReservEntry.SetRange("Lot No.", LotNo2);
            Assert.AreEqual(Qty2, Abs(SumUpQtyToHandle(ReservEntry)), QtyAndQtyToHandleMismatchErr);
        end;

        // [THEN] Qty to Handle total are 0 for each lot
        Assert.AreEqual(0, CalcQtyToHandleInReservEntries(LotNo1), QtyToHandleMismatchErr);
        Assert.AreEqual(0, CalcQtyToHandleInReservEntries(LotNo2), QtyToHandleMismatchErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrkgManualLotNoHandler')]
    [Scope('OnPrem')]
    procedure QtyToHandleWhenTransferOrderWithMixedShipReceive()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[50];
        ItemStock: Integer;
        TotalQtyToShip: Decimal;
        QtyToShip1: Decimal;
        QtyToShip2: Decimal;
        QtyNotShipped: Decimal;
        QtyToReceive: Decimal;
    begin
        // [FEATURE] [Transfer] [Item Tracking Lines]
        // [SCENARIO 284534] Reservation Entry has correct entries when two posted Shipments are followed by Receipt and when Lot Tracking is specified
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        ItemStock := 2 * 3 * 4 * 5 * LibraryRandom.RandIntInRange(10, 20);
        QtyToShip1 := ItemStock / 5;
        QtyToShip2 := ItemStock / 4;
        QtyToReceive := ItemStock / 3;
        TotalQtyToShip := ItemStock / 2;
        QtyNotShipped := TotalQtyToShip - (QtyToShip1 + QtyToShip2);

        // [GIVEN] Item had Lot Tracking enabled and stock of 1000 pcs at Location, same Lot for all
        // [GIVEN] Transfer Order from Location with Quantity 500
        // [GIVEN] Opened page "Item Tracking Lines" for shipment and set Lot and Quantity (required to populate initial Reservation Entries)
        CreateItem(Item, CreateItemTrackingCodeTransferLotTracking(), '', '');
        CreateTransferOrderSimple(TransferHeader, TransferLine, Item, TotalQtyToShip);
        MakeLotTrackedItemStockAtLocation(Item, ItemStock, TransferHeader."Transfer-from Code", LotNo);
        InitItemTrackingForTransferLine(TransferLine, LotNo);

        // [GIVEN] Posted Transfer Shipment with Qty to Ship = 100 and Lot specified
        PrepareTransferLineWithLotAndQtyToHandle(TransferLine, LotNo, QtyToShip1, 0, QtyToShip1, "Transfer Direction"::Outbound);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [GIVEN] Posted Transfer Shipment with Qty to Ship = 200 and Lot specified
        TransferLine.Find();
        PrepareTransferLineWithLotAndQtyToHandle(TransferLine, LotNo, QtyToShip2, 0, QtyToShip2, "Transfer Direction"::Outbound);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [GIVEN] Opened page "Item Tracking Lines" for Receipt, set Qty to Handle = 250 and specified Lot
        TransferLine.Find();
        PrepareTransferLineWithLotAndQtyToHandle(
          TransferLine, LotNo, TransferLine.Quantity - TransferLine."Quantity Shipped", QtyToReceive, QtyToReceive, "Transfer Direction"::Inbound);

        // [WHEN] Close page "Item Tracking Lines"
        // done in ItemTrkgManualLotNoHandler

        // [THEN] Reservation Entry has 4 records for the specified Item Lot:
        ReservationEntry.SetRange("Item No.", Item."No.");
        ReservationEntry.SetRange("Lot No.", LotNo);
        Assert.RecordCount(ReservationEntry, 4);

        // [THEN] Receipt with Quantity = Qty. to Handle (Base) = 100
        ReservationEntry.FindSet();
        VerifyReservationEntrySubtypeAndQty(ReservationEntry, 1, QtyToShip1, QtyToShip1);

        // [THEN] Receipt with Quantity = 200 and Qty. to Handle (Base) = 150
        ReservationEntry.Next();
        VerifyReservationEntrySubtypeAndQty(ReservationEntry, 1, QtyToShip2, QtyToReceive - QtyToShip1);

        // [THEN] Shipment with Quantity = Qty. to Handle (Base) = -200 = -(500 - (100 + 200))
        ReservationEntry.Next();
        VerifyReservationEntrySubtypeAndQty(ReservationEntry, 0, -QtyNotShipped, -QtyNotShipped);

        // [THEN] Receipt with Quantity = Qty. to Handle (Base) = 200 = 500 - (100 + 200)
        ReservationEntry.Next();
        VerifyReservationEntrySubtypeAndQty(ReservationEntry, 1, QtyNotShipped, QtyNotShipped);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesLotSNWithDrilldownLotAvailabilityModalPageHandler,ItemTrackingSummaryModalPageHandlerWithEnqueueLotNoAndQtys')]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryForLotSNSpecificTracking()
    var
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TotalQty: Integer;
        QtyToReserve: Integer;
        QtyPackage1: Integer;
        QtyPackage2: Integer;
        LotNo: Code[50];
        SerialNo: Code[50];
        Package1: Code[50];
        Package2: Code[50];
        ItemTrackingCode: Code[10];
        LocationCode: Code[10];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 290182] Item Tracking Summary shows correct qtys when Stan reopens page Item Tracking Lines from Sales Line
        // [SCENARIO 290182] and drills down to "Availability, Lot No." in case Lot, SN and Package Specific tracking is used.
        Initialize();
        QtyPackage1 := 2;
        QtyPackage2 := 1;
        QtyToReserve := 1;
        TotalQty := QtyPackage1 + QtyPackage2;
        LotNo := LibraryUtility.GenerateGUID();
        SerialNo := LibraryUtility.GenerateGUID();
        Package1 := LibraryUtility.GenerateGUID();
        Package2 := LibraryUtility.GenerateGUID();

        // [GIVEN] Item Tracking Code with Lot, SN and Package Specific Tracking enabled
        CreateItemTrackingCodeWithLotSerialPackage(ItemTrackingCode, LocationCode);

        // [GIVEN] Posted Positive Adj. for Item with Qty = 3 with Item Tracking Lines specified as follows:
        // [GIVEN] Line 1, Line 2 and Line 3 have Serial Nos "S1","S2" and "S3" respectfully; Lot No = "L1" is same for all
        // [GIVEN] Line 1 and Line 2 have Package = "Package1", Line 3 has Package = "Package2"
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, CreateItemNo(ItemTrackingCode, '', ''), LocationCode, '', TotalQty);
        MockReservEntryForItemJournalLine(ItemJournalLine, SerialNo, LotNo, Package1, QtyToReserve);
        MockReservEntryForItemJournalLine(ItemJournalLine, LibraryUtility.GenerateGUID(), LotNo, Package1, QtyPackage1 - QtyToReserve);
        MockReservEntryForItemJournalLine(ItemJournalLine, LibraryUtility.GenerateGUID(), LotNo, Package2, QtyPackage2);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales Order with Item; Qty = 1
        CreateSalesOrder(SalesHeader, SalesLine, ItemJournalLine."Item No.", QtyToReserve);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);

        // [GIVEN] Stan opened page "Item Tracking Lines", specified Serial No "S1", Lot No "L1", CD No "CD1", Quantity(Base) = 1 and closed page
        EnqueueSNLotNoAndQtyToReserve(SerialNo, LotNo, Package1, QtyToReserve);
        SalesLine.OpenItemTrackingLines();
        VerifyValuesReceivedFromItemTrackingSummaryLine(LotNo, Package1, QtyPackage1, 0, QtyToReserve, QtyPackage1 - QtyToReserve);
        VerifyValuesReceivedFromItemTrackingSummaryLine(LotNo, Package2, QtyPackage2, 0, 0, QtyPackage2);

        // [GIVEN] Stan reopened the page "Item Tracking Lines"
        EnqueueSNLotNoAndQtyToReserve(SerialNo, LotNo, Package1, QtyToReserve);
        SalesLine.OpenItemTrackingLines();

        // [WHEN] Stan drills down to "Availability, Lot No." on page "Item Tracking Lines"
        // done in ItemTrackingLinesLotSNTwoLinesModalPageHandler

        // [THEN] Page "Item Tracking Summary" opens showing 2 lines for Lot "L1":
        // [THEN] First Line has Package = "Package1" with Total Quantity = 2, Total Requested Quantity = 1
        // [THEN] First Line has Current Pending Quantity = 0 and Total Available Quantity = 1
        // [THEN] Second Line has Package = "Package2" with Total Quantity = 1, Total Requested Quantity = 0
        // [THEN] Second Line has Current Pending Quantity = 0 and Total Available Quantity = 1
        VerifyValuesReceivedFromItemTrackingSummaryLine(LotNo, Package1, QtyPackage1, QtyToReserve, 0, QtyPackage1 - QtyToReserve);
        VerifyValuesReceivedFromItemTrackingSummaryLine(LotNo, Package2, QtyPackage2, 0, 0, QtyPackage2);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesLotSNQtyModalPageHandler,ReservationHandler,StrMenuHandlerWithDequeueChoice,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPickFromTransferWhenTwoSimilarLines()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: array[2] of Record "Transfer Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[50];
        ItemNo: Code[20];
        StockQty: Integer;
        DemandQty: array[2] of Integer;
        Pick1Qty: array[2] of Integer;
        Pick2Qty: array[2] of Integer;
        Index: Integer;
    begin
        // [FEATURE] [Reservation] [Transfer]
        // [SCENARIO 307331] Reservation Entry when patially post two Inventory Picks created from Transfer Order with two similar lines
        Initialize();
        StockQty := LibraryRandom.RandIntInRange(100, 200);
        for Index := 1 to ArrayLen(Pick1Qty) do begin
            ;
            Pick1Qty[Index] := LibraryRandom.RandIntInRange(10, 20);
            Pick2Qty[Index] := LibraryRandom.RandIntInRange(10, 20);
            DemandQty[Index] := Pick1Qty[Index] + Pick2Qty[Index];
        end;
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Location SILVER had Require Pick enabled
        CreateTransitLocations(FromLocation, ToLocation, InTransitLocation);
        FromLocation.Validate("Require Pick", true);
        FromLocation.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, FromLocation.Code, true);

        // [GIVEN] Item had stock of 100 PCS at location SILVER, all in same Bin and with same Lot "L1" (Item Ledger Entry was created)
        ItemNo := CreateItemWithLotWarehouseTracking();
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, FromLocation.Code, '', StockQty);
        EnqueueSNLotNoAndQtyToReserve('', LotNo, '', StockQty);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales Order in Location BLUE and two Lines with the Item: 15 PCS in the 1st Line and 20 PCS in the 2nd Line (line Nos are 10000 and 20000)
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Location Code", ToLocation.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader, SalesLine[1].Type::Item, ItemNo, DemandQty[1]);
        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader, SalesLine[2].Type::Item, ItemNo, DemandQty[2]);

        // [GIVEN] Released Transfer Order from SILVER to BLUE with the Item: 15 PCS in the 1st Line and 20 PCS in the 2nd Line (line Nos are 10000 and 20000)
        // [GIVEN] Each Transfer Line was fully Outbound and Inbound Reserved
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        for Index := 1 to ArrayLen(DemandQty) do begin
            LibraryInventory.CreateTransferLine(TransferHeader, TransferLine[Index], ItemNo, DemandQty[Index]);
            LibraryVariableStorage.Enqueue(1);
            TransferLine[Index].ShowReservation();
            LibraryVariableStorage.Enqueue(2);
            TransferLine[Index].ShowReservation();
        end;
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Created Inventory Pick from Transfer Order: set Lot "L1" in each Line and specified to handle 10 PCS in the 1st Line and 11 PCS in the 2nd Line
        // [GIVEN] Posted Inventory Pick
        CreateInvtPickOutboundTransfer(WarehouseActivityHeader, TransferHeader."No.");
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityHeader."Source Document");
        WarehouseActivityLine.SetRange("Source No.", TransferHeader."No.");
        WarehouseActivityLine.FindSet();
        Clear(Index);
        repeat
            Index += 1;
            UpdateWhseActivityLineQtyToHandleAndLotNo(WarehouseActivityLine, LotNo, Pick1Qty[Index]);
        until WarehouseActivityLine.Next() = 0;
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [GIVEN] Updated Inventory Pick: specified to handle 5 PCS in the 1st Line and 9 PCS in the 2nd Line
        WarehouseActivityLine.FindSet();
        Clear(Index);
        repeat
            Index += 1;
            UpdateWhseActivityLineQtyToHandleAndLotNo(WarehouseActivityLine, LotNo, Pick2Qty[Index]);
        until WarehouseActivityLine.Next() = 0;

        // [WHEN] Post Inventory Pick
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] 8 Reservation Entries for this Item each has Reservation Status = Reservation and Source Subtype = 1:
        ReservationEntry.SetRange("Item No.", ItemNo);
        Assert.RecordCount(ReservationEntry, 8);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetRange("Source Subtype", ReservationEntry."Source Subtype"::"1");
        Assert.RecordCount(ReservationEntry, 8);

        // [THEN] Pair of Reservation Entries for Sales with Source Ref No = 10000 and Transfer with Source Prod Order Line = 10000 with 10 PCS
        // [THEN] Pair of Reservation Entries for Sales with Source Ref No = 10000 and Transfer with Source Prod Order Line = 10000 with 5 PCS
        // [THEN] Pair of Reservation Entries for Sales with Source Ref No = 20000 and Transfer with Source Prod Order Line = 20000 with 11 PCS
        // [THEN] Pair of Reservation Entries for Sales with Source Ref No = 20000 and Transfer with Source Prod Order Line = 20000 with 9 PCS
        for Index := 1 to ArrayLen(SalesLine) do
            VerifyPairOfReservationEntriesSalesTransferInbound(
              ReservationEntry, SalesLine[Index]."Line No.", TransferLine[Index]."Line No.", Pick1Qty[Index], Pick2Qty[Index]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesLotSNQtyWithEnqueueLotModalPageHandler')]
    [Scope('OnPrem')]
    procedure ValidateLotWhenValidateSNItemTrackingWhenLotSNTracking()
    var
        Location: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        StockQty: Integer;
        SerialNo: Code[50];
        LotNo: Code[50];
    begin
        // [FEATURE] [UI] [Item Tracking Lines]
        // [SCENARIO 315298] When Stan sets Serial No for Item with LotSN Tracking then Lot is populated on Item Tracking Lines page
        Initialize();
        StockQty := 1;
        SerialNo := LibraryUtility.GenerateGUID();
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Item had stock of 1 PCS with Lot "L" and Serial No "S" assigned
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateItemWithTrackingCode(Item, true, true);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', StockQty);
        EnqueueSNLotNoAndQtyToReserve(SerialNo, LotNo, '', StockQty);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryVariableStorage.DequeueText();
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Stan opened Item Tracking Lines in Sales Order with 1 PCS of Item
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", StockQty);
        EnqueueSNLotNoAndQtyToReserve(SerialNo, LotNo, '', StockQty);
        SalesLine.OpenItemTrackingLines();

        // [WHEN] Stan sets Serial No = "S" on Item Tracking Lines page
        // done in ItemTrackingLinesLotSNQtyWithEnqueueLotModalPageHandler

        // [THEN] Lot No = "L" on Item Tracking Lines page
        Assert.AreEqual(LotNo, LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SNWarehouseTrackingOnItemTrackingCodeCardWhenEssentialExp()
    var
        ItemTrackingCodeCard: TestPage "Item Tracking Code Card";
    begin
        // [FEATURE] [UI] [UT] [Item Tracking Code]
        // [SCENARIO 316838] SN Warehouse Tracking field presents on the Item Tracking Code Card page for the Essential User Experience.
        Initialize();

        // [GIVEN] Essential experience was enabled
        LibraryApplicationArea.EnableEssentialSetup();

        // [WHEN] Open Item Tracking Code Card
        ItemTrackingCodeCard.OpenNew();

        // [THEN] Both Lot and SN Warehouse Tracking are visible
        Assert.IsTrue(ItemTrackingCodeCard."Lot Warehouse Tracking".Visible(), '');
        Assert.IsTrue(ItemTrackingCodeCard."SN Warehouse Tracking".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SNWarehouseTrackingOnItemTrackingCodeCardWhenBasicExp()
    var
        ItemTrackingCodeCard: TestPage "Item Tracking Code Card";
    begin
        // [FEATURE] [UI] [UT] [Item Tracking Code]
        // [SCENARIO 316838] SN Warehouse Tracking field does not present on the Item Tracking Code Card page for the Basic User Experience.
        Initialize();

        // [GIVEN] Basic experience was enabled
        LibraryApplicationArea.EnableBasicSetup();

        // [WHEN] Open Item Tracking Code Card
        ItemTrackingCodeCard.OpenNew();

        // [THEN] Both Lot and SN Warehouse Tracking are not visible
        asserterror Assert.IsTrue(ItemTrackingCodeCard."Lot Warehouse Tracking".Visible(), '');
        Assert.ExpectedError(FieldNotFoundErr);
        Assert.ExpectedErrorCode(FieldNotFoundCodeErr);
        asserterror Assert.IsTrue(ItemTrackingCodeCard."SN Warehouse Tracking".Visible(), '');
        Assert.ExpectedError(FieldNotFoundErr);
        Assert.ExpectedErrorCode(FieldNotFoundCodeErr);
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SettingNewExpirationDateOnItemTrackingLineUpdatesWholeLot()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        SerialNos: array[2] of Code[20];
        LotNos: array[2] of Code[20];
        NewDate: Date;
    begin
        // [FEATURE] [Lot] [Expiration Date] [UT]
        // [SCENARIO 330377] When a user first sets expiration date on an item tracking line, this sets the same date on other tracking lines with the same lot.
        Initialize();
        MockItemTracking(SerialNos, LotNos);
        NewDate := LibraryRandom.RandDate(10);

        // [GIVEN] Both serial no. and lot-tracked item.
        CreateItem(Item, CreateItemTrackingCodeLotSerial(), '', '');

        // [GIVEN] Item journal line.
        // [GIVEN] Open item tracking and set up two lines. Line 1: serial no. = "S1", lot no. = "L1"; Line 2: serial no. = "S2", lot no. = "L1".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 1);

        MockTrackingSpecificationForItemJnlLine(
          TempTrackingSpecification, ItemJournalLine, 0, SerialNos[1], LotNos[1], 0D);

        // [WHEN] Set Expiration Date = "EXP-1" on Line 2.
        MockTrackingSpecificationForItemJnlLine(
          TempTrackingSpecification, ItemJournalLine, 1, SerialNos[2], LotNos[1], NewDate);

        // [THEN] Expiration Date on Line 1 is set to "EXP-1".
        TempTrackingSpecification.SetRange("Serial No.", SerialNos[1]);
        TempTrackingSpecification.FindFirst();
        TempTrackingSpecification.TestField("Expiration Date", NewDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatingExpirationDateOnItemTrackingLineUpdatesWholeLot()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        SerialNos: array[2] of Code[20];
        LotNos: array[2] of Code[20];
        NewDate: Date;
    begin
        // [FEATURE] [Lot] [Expiration Date] [UT]
        // [SCENARIO 330377] When a user updates expiration date on an item tracking line, this updates the date on other tracking lines with the same lot.
        Initialize();
        MockItemTracking(SerialNos, LotNos);
        NewDate := LibraryRandom.RandDate(10);

        // [GIVEN] Both serial no. and lot-tracked item.
        CreateItem(Item, CreateItemTrackingCodeLotSerial(), '', '');

        // [GIVEN] Item journal line.
        // [GIVEN] Open item tracking and set up two lines. Line 1: serial no. = "S1", lot no. = "L1"; Line 2: serial no. = "S2", lot no. = "L1".
        // [GIVEN] Expiration date on Line 1 = "EXP-1".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 1);

        MockTrackingSpecificationForItemJnlLine(
          TempTrackingSpecification, ItemJournalLine, 0, SerialNos[1], LotNos[1], WorkDate());

        // [WHEN] Update Expiration Date = "EXP-2" on Line 2.
        MockTrackingSpecificationForItemJnlLine(
          TempTrackingSpecification, ItemJournalLine, 1, SerialNos[2], LotNos[1], NewDate);

        // [THEN] Expiration Date on Line 1 is updated to "EXP-2".
        TempTrackingSpecification.SetRange("Serial No.", SerialNos[1]);
        TempTrackingSpecification.FindFirst();
        TempTrackingSpecification.TestField("Expiration Date", NewDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatingExpirationDateOnItemTrackingLineDoesNotUpdateAnotherLot()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        SerialNos: array[2] of Code[20];
        LotNos: array[2] of Code[20];
        NewDate: Date;
    begin
        // [FEATURE] [Lot] [Expiration Date] [UT]
        // [SCENARIO 330377] When a user updates expiration date on an item tracking line, this does not update the date on other tracking lines with different lot.
        Initialize();
        MockItemTracking(SerialNos, LotNos);
        NewDate := LibraryRandom.RandDate(10);

        // [GIVEN] Both serial no. and lot-tracked item.
        CreateItem(Item, CreateItemTrackingCodeLotSerial(), '', '');

        // [GIVEN] Item journal line.
        // [GIVEN] Open item tracking and set up two lines. Line 1: serial no. = "S1", lot no. = "L1"; Line 2: serial no. = "S2", lot no. = "L2".
        // [GIVEN] Expiration date on Line 1 = "EXP-1".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 1);

        MockTrackingSpecificationForItemJnlLine(
          TempTrackingSpecification, ItemJournalLine, 0, SerialNos[1], LotNos[1], WorkDate());

        // [WHEN] Update Expiration Date = "EXP-2" on Line 2.
        MockTrackingSpecificationForItemJnlLine(
          TempTrackingSpecification, ItemJournalLine, 1, SerialNos[2], LotNos[2], NewDate);

        // [THEN] Expiration Date on Line 1 remains "EXP-1".
        TempTrackingSpecification.SetRange("Serial No.", SerialNos[1]);
        TempTrackingSpecification.FindFirst();
        TempTrackingSpecification.TestField("Expiration Date", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResettingExpirationDateOnItemTrackingLineResetsWholeLot()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        SerialNos: array[2] of Code[20];
        LotNos: array[2] of Code[20];
        NewDate: Date;
    begin
        // [FEATURE] [Lot] [Expiration Date] [UT]
        // [SCENARIO 330377] When a user clears expiration date on an item tracking line, this clears out the date on other tracking lines with the same lot.
        Initialize();
        MockItemTracking(SerialNos, LotNos);
        NewDate := LibraryRandom.RandDate(10);

        // [GIVEN] Both serial no. and lot-tracked item.
        CreateItem(Item, CreateItemTrackingCodeLotSerial(), '', '');

        // [GIVEN] Item journal line.
        // [GIVEN] Open item tracking and set up two lines. Line 1: serial no. = "S1", lot no. = "L1"; Line 2: serial no. = "S2", lot no. = "L1".
        // [GIVEN] Expiration date on Line 1 = "EXP-1".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 1);

        MockTrackingSpecificationForItemJnlLine(
          TempTrackingSpecification, ItemJournalLine, 0, SerialNos[1], LotNos[1], NewDate);

        // [WHEN] Clear Expiration Date on Line 2.
        MockTrackingSpecificationForItemJnlLine(
          TempTrackingSpecification, ItemJournalLine, 1, SerialNos[2], LotNos[1], 0D);

        // [THEN] Expiration Date on Line 1 is cleared out.
        TempTrackingSpecification.SetRange("Serial No.", SerialNos[1]);
        TempTrackingSpecification.FindFirst();
        TempTrackingSpecification.TestField("Expiration Date", 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillingInLotNoOnItemTrackingLinePullsExpirDateFromAnotherLine()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
        SerialNos: array[2] of Code[20];
        LotNos: array[2] of Code[20];
        NewDate: Date;
    begin
        // [FEATURE] [Lot] [Expiration Date] [UT]
        // [SCENARIO 330377] When a user validates lot no. on an item tracking line, the program pulls expiration date from other tracking lines with the same lot.
        Initialize();
        MockItemTracking(SerialNos, LotNos);
        NewDate := LibraryRandom.RandDate(10);

        // [GIVEN] Both serial no. and lot-tracked item.
        CreateItem(Item, CreateItemTrackingCodeLotSerial(), '', '');

        // [GIVEN] Item journal line.
        // [GIVEN] Open item tracking and set a line with serial no. = "S1", lot no. = "L1".
        // [GIVEN] Expiration date = "EXP-1".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 1);

        MockTrackingSpecificationForItemJnlLine(
          TempTrackingSpecification, ItemJournalLine, 0, SerialNos[1], LotNos[1], NewDate);
        // [WHEN] Create a second line in item tracking: serial no. = "S2", lot no. = "L1".
        ItemJnlLineReserve.InitFromItemJnlLine(TempTrackingSpecification, ItemJournalLine);
        TempTrackingSpecification."Entry No." := 1;
        TempTrackingSpecification.Validate("Serial No.", SerialNos[2]);
        TempTrackingSpecification.Validate("Lot No.", LotNos[1]);

        // [THEN] Expiration Date on the new line is copied from the first line and is now "EXP-1".
        TempTrackingSpecification.TestField("Expiration Date", NewDate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotUpdateExpirDateOnItemTrackingLineIfLotAlreadyPosted()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        SerialNos: array[2] of Code[20];
        LotNos: array[2] of Code[20];
        NewDate: Date;
    begin
        // [FEATURE] [Lot] [Expiration Date] [UT]
        // [SCENARIO 330377] A user cannot change expiration date on an item tracking line, if the lot has been posted with another expiration date.
        Initialize();
        MockItemTracking(SerialNos, LotNos);
        NewDate := LibraryRandom.RandDate(10);

        // [GIVEN] Both serial no. and lot-tracked item.
        CreateItem(Item, CreateItemTrackingCodeLotSerial(), '', '');

        // [GIVEN] Post inventory with serial no. = "S1", lot no. = "L1", expiration date = "EXP-1".
        MockItemEntryWithSerialAndLot(Item."No.", SerialNos[1], LotNos[1], WorkDate());

        // [GIVEN] Item journal line.
        // [GIVEN] Open item tracking and set a line with serial no. = "S1", lot no. = "L1".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 1);

        // [WHEN] Update expiration date on item tracking line to "EXP-2".
        MockTrackingSpecificationForItemJnlLine(
          TempTrackingSpecification, ItemJournalLine, 0, SerialNos[1], LotNos[1], NewDate);

        // [THEN] Expiration date is reset back to "EXP-1" because the lot no. has been already in use.
        TempTrackingSpecification.TestField("Expiration Date", WorkDate());
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,EnterQuantityToCreateHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPutAwayPostAfterExpirationDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Item: Record Item;
        Location: Record Location;
    begin
        // [FEATURE] [Inventory Put-Away] [Expiration Date]
        // [SCENARIO 340313] Posting Warehouse Activity Line with Expiration Date before the Posting Date fails
        Initialize();

        // [GIVEN] Item with Serial Number Item Tracking Code with "Strict Expiration Posting" and "SN Warehouse Tracking"
        CreateItem(
          Item, CreateItemTrackingCodeSerialSpecificWhseTracking(true, true), LibraryUtility.GetGlobalNoSeriesCode(), '');

        // [GIVEN] Location with "Require Put-Away"
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        // [GIVEN] Released Purchase Order with Expiration Date before the Posting Date
        CreatePurchOrderExpirationDateBeforePosting(PurchaseHeader, PurchaseLine, Item."No.", Location.Code);

        // [GIVEN] Inventory Put-Away created
        CreateInvtPutAwayPurchOrder(WarehouseActivityHeader, PurchaseHeader."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [WHEN] Post Inventory Put-Away
        asserterror LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Posting fails with a field error "Expiration Date is before the posting date..."
        Assert.ExpectedErrorCode('TableError');
        Assert.ExpectedError(BeforeExpirationDateShortErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,EnterQuantityToCreateHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FillQtyResetQtyActionOnInvtPutawaySubformTest()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        InventoryPutaway: TestPage "Inventory Put-away";
    begin
        // [FEATURE] [Inventory Put-Away]
        // [SCENARIO] 'FillQtyToHandle' and 'ResetQtyToHandle' actions work correctly for the Inventory Put-Away
        Initialize();

        // [GIVEN] Item with Serial Number Item Tracking Code with "Strict Expiration Posting" and "SN Warehouse Tracking"
        CreateItem(
          Item, CreateItemTrackingCodeSerialSpecificWhseTracking(true, true), LibraryUtility.GetGlobalNoSeriesCode(), '');

        // [GIVEN] Location with "Require Put-Away"
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Released Purchase Order with Expiration Date before the Posting Date
        CreatePurchOrderExpirationDateBeforePosting(PurchaseHeader, PurchaseLine, Item."No.", Location.Code);

        // [GIVEN] Inventory Put-Away created
        CreateInvtPutAwayPurchOrder(WarehouseActivityHeader, PurchaseHeader."No.");

        // [WHEN] Inventroy Put-away is opened
        InventoryPutaway.OpenEdit();
        InventoryPutaway.GoToRecord(WarehouseActivityHeader);
        InventoryPutaway.WhseActivityLines.First();

        // [THEN] 'Qty. to Handle' is 0
        InventoryPutaway.WhseActivityLines."Qty. to Handle".AssertEquals(0);

        // [WHEN] 'FillQtyToHandle' action is invoked
        InventoryPutaway.WhseActivityLines.FillQtyToHandle.Invoke();

        // [THEN] 'Qty. to Handle' is equal to 'Qty. Outstanding'
        InventoryPutaway.WhseActivityLines."Qty. to Handle".AssertEquals(InventoryPutaway.WhseActivityLines."Qty. Outstanding".AsDecimal());

        // [WHEN] 'ResetQtyToHandle' action is invoked
        InventoryPutaway.WhseActivityLines.ResetQtyToHandle.Invoke();

        // [THEN] 'Qty. to Handle' is 0
        InventoryPutaway.WhseActivityLines."Qty. to Handle".AssertEquals(0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePutAwayCreatesBaseQtyNumberOfWhseActivityLinesWhenSNRequired()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Item: Record Item;
        Location: Record Location;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // [FEATURE] [Inventory Put-Away] [Serial No.]
        // [SCENARIO] Number of Whse. Activity Lines created equals Base Quantity when serial number is required
        Initialize();

        // [GIVEN] Item with Serial Number Item Tracking Code with "SN Warehouse Tracking"
        CreateItem(
          Item, CreateItemTrackingCodeSerialSpecificWhseTracking(false, true), LibraryUtility.GetGlobalNoSeriesCode(), '');

        // [GIVEN] Location with "Require Put-Away"
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        // [GIVEN] Second item unit of measure created for the item
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Released Purchase Order with rounding precision on purchase line set to 1
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.");
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchaseLine.Validate("Qty. Rounding Precision (Base)", 1);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Inventory Put-Away created
        CreateInvtPutAwayPurchOrder(WarehouseActivityHeader, PurchaseHeader."No.");

        // [THEN] The number of warehouse activity lines created equals base quantity on the purchase line
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        Assert.RecordCount(WarehouseActivityLine, PurchaseLine."Quantity (Base)");

        // [THEN] Serial No. can be set on the warehouse activity lines
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Serial No.", LibraryUtility.GenerateRandomCode(WarehouseActivityLine.FieldNo("Serial No."), Database::"Warehouse Activity Line"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePutAwayWithSpecificQtyForWhseActivityLinesWhenSNRequired()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Item: Record Item;
        Location: Record Location;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        QtyPerUoM: Decimal;
        SumOfQty: Decimal;
        Counter: Integer;
    begin
        // [FEATURE] [Inventory Put-Away] [Serial No.]
        // [SCENARIO] Number of Whse. Activity Lines created equals Base Quantity when serial number is required
        Initialize();

        // [GIVEN] Item with Serial Number Item Tracking Code with "SN Warehouse Tracking"
        CreateItem(
          Item, CreateItemTrackingCodeSerialSpecificWhseTracking(false, true), LibraryUtility.GetGlobalNoSeriesCode(), '');

        // [GIVEN] Location with "Require Put-Away"
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        // [GIVEN] Second item unit of measure created for the item with Qty per unit of measure 3 and 6
        for Counter := 1 to 2 do begin
            QtyPerUoM := 3 * Counter;
            SumOfQty := 0;
            LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", QtyPerUoM);

            // [GIVEN] Released Purchase Order with rounding precision on purchase line set to 1
            CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.");
            PurchaseLine.Validate("Location Code", Location.Code);
            PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
            PurchaseLine.Validate("Qty. Rounding Precision (Base)", 1);
            PurchaseLine.Modify(true);
            LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

            // [WHEN] Inventory Put-Away created
            CreateInvtPutAwayPurchOrder(WarehouseActivityHeader, PurchaseHeader."No.");

            // [THEN] The number of warehouse activity lines created equals base quantity on the purchase line
            WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
            Assert.RecordCount(WarehouseActivityLine, PurchaseLine."Quantity (Base)");

            // [THEN] The sum of the quantities on warehouse activity lines should be equal to quantity on purchase line
            WarehouseActivityLine.Find('-');
            repeat
                SumOfQty += WarehouseActivityLine.Quantity;
            until WarehouseActivityLine.Next() <= 0;
            Assert.AreEqual(PurchaseLine.Quantity, SumOfQty, StrSubstNo(TrackedQuantityErr, SumOfQty, Item."No."));
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePickCreatesBaseQtyNumberOfWhseActivityLinesWhenSNRequired()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Item: Record Item;
        Location: Record Location;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemJnlQtyBase: Decimal;
        ItemJnlQty: Decimal;
        Counter: Integer;
    begin
        // [FEATURE] [Inventory Pick] [Serial No.]
        // [SCENARIO] Number of Whse. Activity Lines created equals Base Quantity when serial number is required
        Initialize();

        // [GIVEN] Item with Serial Number Item Tracking Code with "SN Warehouse Tracking"
        CreateItem(
          Item, CreateItemTrackingCodeSerialSpecificWhseTracking(false, true), LibraryUtility.GetGlobalNoSeriesCode(), '');

        // [GIVEN] Location with "Require Pick"
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        // [GIVEN] Second item unit of measure created for the item
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(10));

        ItemJnlQty := LibraryRandom.RandInt(20);
        ItemJnlQtyBase := ItemJnlQty * ItemUnitOfMeasure."Qty. per Unit of Measure";

        // [GIVEN] Post Item Journal Line with x quantities with base UoM
        for Counter := 1 to ItemJnlQtyBase do
            CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, '', LibraryUtility.GenerateGUID(), '');

        // [GIVEN] Sales Order is created to exhaust the posted items in item journal
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 0);
        SalesLine.Validate(Quantity, ItemJnlQty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        SalesLine.Modify(true);

        // [GIVEN] Sales document is released
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create inventory pick.
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // [THEN] The number of warehouse activity lines created equals base quantity on the sales line
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        Assert.RecordCount(WarehouseActivityLine, SalesLine."Quantity (Base)");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePickWithSpecificQtyForWhseActivityLinesWhenSNRequired()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Item: Record Item;
        Location: Record Location;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemJnlQtyBase: Decimal;
        ItemJnlQty: Decimal;
        CounterI: Integer;
        CounterJ: Integer;
        SumOfQty: Decimal;
    begin
        // [FEATURE] [Inventory Pick] [Serial No.]
        // [SCENARIO] Number of Whse. Activity Lines created equals Base Quantity when serial number is required and all the Whse. Activity Line Quantities add up to the quantity in Sales Line
        Initialize();

        // [GIVEN] Item with Serial Number Item Tracking Code with "SN Warehouse Tracking"
        CreateItem(
          Item, CreateItemTrackingCodeSerialSpecificWhseTracking(false, true), LibraryUtility.GetGlobalNoSeriesCode(), '');

        // [GIVEN] Location with "Require Pick"
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        // [GIVEN] Second item unit of measure created for the item with Qty per unit of measure 3 and 6
        for CounterI := 1 to 2 do begin
            SumOfQty := 0;
            LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 3 * CounterI);

            ItemJnlQty := LibraryRandom.RandInt(20);
            ItemJnlQtyBase := ItemJnlQty * ItemUnitOfMeasure."Qty. per Unit of Measure";

            // [GIVEN] Post Item Journal Line with x quantities with base UoM
            for CounterJ := 1 to ItemJnlQtyBase do
                CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, '', LibraryUtility.GenerateGUID(), '');

            // [GIVEN] Sales Order is created to exhaust the posted items in item journal
            CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 0);
            SalesLine.Validate(Quantity, ItemJnlQty);
            SalesLine.Validate("Location Code", Location.Code);
            SalesLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
            SalesLine.Modify(true);

            // [GIVEN] Sales document is released
            LibrarySales.ReleaseSalesDocument(SalesHeader);

            // [WHEN] Create inventory pick.
            LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

            // [THEN] The number of warehouse activity lines created equals base quantity on the sales line
            LibraryWarehouse.FindWhseActivityLineBySourceDoc(WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
            Assert.RecordCount(WarehouseActivityLine, SalesLine."Quantity (Base)");

            // [THEN] The sum of the quantities on warehouse activity lines should be equal to quantity on sales line
            WarehouseActivityLine.Find('-');
            repeat
                SumOfQty += WarehouseActivityLine.Quantity;
            until WarehouseActivityLine.Next() <= 0;
            Assert.AreEqual(SalesLine.Quantity, SumOfQty, StrSubstNo(TrackedQuantityErr, SumOfQty, Item."No."));
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePutAwayCreatesQtyNumberOfWhseActivityLinesWhenLotRequired()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Item: Record Item;
        Location: Record Location;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // [FEATURE] [Inventory Put-Away] [Serial No.]
        // [SCENARIO] Number of Whse. Activity Lines created equals Quantity when lot number is required
        Initialize();

        // [GIVEN] Item with Lot Number Item Tracking Code with "Lot Warehouse Tracking"
        CreateItem(
          Item, CreateItemTrackingCodeLotSpecificWhseTracking(true), LibraryUtility.GetGlobalNoSeriesCode(), '');

        // [GIVEN] Location with "Require Put-Away"
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        // [GIVEN] Second item unit of measure created for the item
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Released Purchase Order with rounding precision on purchase line set to 1
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.");
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchaseLine.Validate("Qty. Rounding Precision (Base)", 1);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Inventory Put-Away created
        CreateInvtPutAwayPurchOrder(WarehouseActivityHeader, PurchaseHeader."No.");

        // [THEN] The number of warehouse activity lines created equal to the number of lots
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        Assert.RecordCount(WarehouseActivityLine, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignTrackingNoAndVerifyQuantityHandler,EnterQuantityToCreateHandler')]
    [Scope('OnPrem')]
    procedure E2EPurchaseAndSalesWithSerialNumberAndUOM()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WarehouseSetup: Record "Warehouse Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        I: Integer;
    begin
        // [FEATURE] [Whse. Receipt] [Serial No.]
        // [SCENARIO] Error is not thrown when serial number is required and warehouse receipt is created and posted
        Initialize();

        // [GIVEN] Warehouse setup where posting errors are not supressed
        WarehouseSetup.Get();
        WarehouseSetup.Validate("Receipt Posting Policy", WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        WarehouseSetup.Modify();

        // [GIVEN] Item with Serial Number Item Tracking Code with "SN Warehouse Tracking"
        CreateItem(
          Item, CreateItemTrackingCodeSerialSpecificWhseTracking(false, true), LibraryUtility.GetGlobalNoSeriesCode(), '');

        // [GIVEN] Location with "Require Receive"
        LibraryWarehouse.CreateFullWMSLocation(Location, 10);

        // [GIVEN] Second item unit of measure created for the item
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Released Purchase Order with rounding precision on purchase line set to 0 and serial numbers assigned
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.");
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchaseLine.Modify(true);

        LibraryVariableStorage.Enqueue(TrackingOptionStr::AssignSerialNo);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Warehouse Receipt Lines creation is requested
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [THEN] Warehouse Receipt Lines are created
        WarehouseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        WarehouseReceiptLine.SetRange("Source Subtype", PurchaseLine."Document Type");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseLine."Document No.");
        Assert.RecordCount(WarehouseReceiptLine, 1);

        // [WHEN] Warehouse Receipt is posted
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");

        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] No error is raised and 1 posted receipt line is created
        PostedWhseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        PostedWhseReceiptLine.SetRange("Source Subtype", PurchaseLine."Document Type");
        PostedWhseReceiptLine.SetRange("Source No.", PurchaseLine."Document No.");
        Assert.RecordCount(PostedWhseReceiptLine, 1);

        // [THEN] Base quantity * 2 number of warehouse activity lines are created. * 2 to cover 1 take and 1 place
        WarehouseActivityLine.SetRange("Source Type", Database::"Purchase Line");
        WarehouseActivityLine.SetRange("Source Subtype", PurchaseLine."Document Type");
        WarehouseActivityLine.SetRange("Source No.", PurchaseLine."Document No.");
        Assert.RecordCount(WarehouseActivityLine, ItemUnitOfMeasure."Qty. per Unit of Measure" * PurchaseLine.Quantity * 2);

        // No error is thrown when the activity is registered
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Sales Order is created to exhaust the items that was putaway
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", PurchaseLine.Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        SalesLine.Modify(true);

        // [GIVEN] Sales document is released
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN]  Warehouse shipment lines are created
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [THEN] 1 Warehouse shipment line is created
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseShipmentLine.SetRange("Source Subtype", SalesLine."Document Type");
        WarehouseShipmentLine.SetRange("Source No.", SalesLine."Document No.");
        Assert.RecordCount(WarehouseShipmentLine, 1);

        // [WHEN] Warehouse CreatePick is called
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");

        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [THEN] Warehouse actibity lines are created
        WarehouseActivityLine.SetRange("Source Type", Database::"Sales Line");
        WarehouseActivityLine.SetRange("Source Subtype", SalesLine."Document Type");
        WarehouseActivityLine.SetRange("Source No.", SalesLine."Document No.");
        Assert.RecordCount(WarehouseActivityLine, ItemUnitOfMeasure."Qty. per Unit of Measure" * SalesLine.Quantity * 2); // * 2 because there is one line for take and one for place

        // [WHEN/THEN] When serial numbers are assigned to the warehouse activity lines and are registered, then no errors are thrown
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetFilter("Serial No.", '<> %1', '');
        ItemLedgerEntry.FindSet();
        for I := 1 to ItemUnitOfMeasure."Qty. per Unit of Measure" * SalesLine.Quantity do begin
            UpdateSerialNoOnWhseActivityLine(WarehouseShipmentHeader."No.", WarehouseActivityLine."Action Type"::Take, ItemLedgerEntry."Serial No.");
            UpdateSerialNoOnWhseActivityLine(WarehouseShipmentHeader."No.", WarehouseActivityLine."Action Type"::Place, ItemLedgerEntry."Serial No.");
            ItemLedgerEntry.Next();
        end;
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignTrackingNoAndVerifyQuantityHandler,EnterQuantityToCreateHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure E2EPurchaseAndSalesAssignSNBeforePickAndUOM()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WarehouseSetup: Record "Warehouse Setup";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        // [FEATURE] [Whse. Receipt] [Serial No.]
        // [SCENARIO] Error is not thrown when serial number is assigned and creating Pick for items to be shipped
        Initialize();

        // [GIVEN] Warehouse setup where posting errors are not suppressed
        WarehouseSetup.Get();
        WarehouseSetup.Validate("Receipt Posting Policy", WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        WarehouseSetup.Modify();

        // [GIVEN] Item with Serial Number Item Tracking Code with "SN Warehouse Tracking"
        CreateItem(
          Item, CreateItemTrackingCodeSerialSpecificWhseTracking(false, true), LibraryUtility.GetGlobalNoSeriesCode(), '');

        // [GIVEN] Location with "Require Receive"
        LibraryWarehouse.CreateFullWMSLocation(Location, 10);

        // [GIVEN] Second item unit of measure created for the item
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Released Purchase Order with rounding precision on purchase line set to 0 and serial numbers assigned
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.");
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchaseLine.Modify(true);

        LibraryVariableStorage.Enqueue(TrackingOptionStr::AssignSerialNo);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Warehouse Receipt Lines creation is requested
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [THEN] Warehouse Receipt Lines are created
        WarehouseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        WarehouseReceiptLine.SetRange("Source Subtype", PurchaseLine."Document Type");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseLine."Document No.");
        Assert.RecordCount(WarehouseReceiptLine, 1);

        // [WHEN] Warehouse Receipt is posted
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");

        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] No error is raised and 1 posted receipt line is created
        PostedWhseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        PostedWhseReceiptLine.SetRange("Source Subtype", PurchaseLine."Document Type");
        PostedWhseReceiptLine.SetRange("Source No.", PurchaseLine."Document No.");
        Assert.RecordCount(PostedWhseReceiptLine, 1);

        // [THEN] Base quantity * 2 number of warehouse activity lines are created. * 2 to cover 1 take and 1 place
        WarehouseActivityLine.SetRange("Source Type", Database::"Purchase Line");
        WarehouseActivityLine.SetRange("Source Subtype", PurchaseLine."Document Type");
        WarehouseActivityLine.SetRange("Source No.", PurchaseLine."Document No.");
        Assert.RecordCount(WarehouseActivityLine, ItemUnitOfMeasure."Qty. per Unit of Measure" * PurchaseLine.Quantity * 2);

        // No error is thrown when the activity is registered
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Sales Order is created with serial numbers assigned to exhaust the items that was put-away
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", PurchaseLine.Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        SalesLine.Modify(true);

        LibraryVariableStorage.Enqueue(TrackingOptionStr::SelectEntries);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Sales document is released
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN]  Warehouse shipment lines are created
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [THEN] 1 Warehouse shipment line is created
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseShipmentLine.SetRange("Source Subtype", SalesLine."Document Type");
        WarehouseShipmentLine.SetRange("Source No.", SalesLine."Document No.");
        Assert.RecordCount(WarehouseShipmentLine, 1);

        // [WHEN] Warehouse CreatePick is called
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");

        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [THEN] Warehouse activity lines are created
        WarehouseActivityLine.SetRange("Source Type", Database::"Sales Line");
        WarehouseActivityLine.SetRange("Source Subtype", SalesLine."Document Type");
        WarehouseActivityLine.SetRange("Source No.", SalesLine."Document No.");
        Assert.RecordCount(WarehouseActivityLine, ItemUnitOfMeasure."Qty. per Unit of Measure" * SalesLine.Quantity * 2); // * 2 because there is one line for take and one for place
    end;


    [Test]
    [HandlerFunctions('ItemTrackingAssignTrackingNoAndVerifyQuantityHandler,EnterQuantityToCreateHandler')]
    [Scope('OnPrem')]
    procedure ErrorNotThrownWhenCreateWhseReceiptAndPostWhenSNRequired()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        Item: Record Item;
        Location: Record Location;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WarehouseSetup: Record "Warehouse Setup";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        // [FEATURE] [Whse. Receipt] [Serial No.]
        // [SCENARIO] Error is not thrown when serial number is required and warehouse receipt is created and posted
        Initialize();

        // [GIVEN] Warehouse setup where posting errors are not supressed
        WarehouseSetup.Get();
        WarehouseSetup.Validate("Receipt Posting Policy", WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        WarehouseSetup.Modify();

        // [GIVEN] Item with Serial Number Item Tracking Code with "SN Warehouse Tracking"
        CreateItem(
          Item, CreateItemTrackingCodeSerialSpecificWhseTracking(false, true), LibraryUtility.GetGlobalNoSeriesCode(), '');

        // [GIVEN] Location with "Require Receive"
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);

        // [GIVEN] Second item unit of measure created for the item
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Released Purchase Order with rounding precision on purchase line set to 0 and serial numbers assigned
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.");
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchaseLine.Modify(true);

        LibraryVariableStorage.Enqueue(TrackingOptionStr::AssignSerialNo);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Warehouse Receipt Lines creation is requested
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [THEN] Warehouse Receipt Lines are created
        WarehouseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        WarehouseReceiptLine.SetRange("Source Subtype", PurchaseLine."Document Type");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseLine."Document No.");
        Assert.RecordCount(WarehouseReceiptLine, 1);

        // [WHEN] Warehouse Receipt is posted
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");

        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] No error is raised and posted receipt lines are created
        PostedWhseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        PostedWhseReceiptLine.SetRange("Source Subtype", PurchaseLine."Document Type");
        PostedWhseReceiptLine.SetRange("Source No.", PurchaseLine."Document No.");
        Assert.RecordCount(PostedWhseReceiptLine, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignTrackingNoAndVerifyQuantityHandler,EnterQuantityToCreateHandler')]
    [Scope('OnPrem')]
    procedure ErrorNotThrownWhenPostingWhseReceiptWhenSNRequiredAndBinRequired()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        Item: Record Item;
        Location: Record Location;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WarehouseSetup: Record "Warehouse Setup";
        ReceiptBin: Record Bin;
    begin
        // [FEATURE] [Whse. Receipt] [Bin Required] [Serial No.]
        // [SCENARIO] Error is not thrown when serial number is required and warehouse receipt is created and posted
        Initialize();

        // [GIVEN] Warehouse setup where posting errors are not supressed
        WarehouseSetup.Get();
        WarehouseSetup.Validate("Receipt Posting Policy", WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        WarehouseSetup.Modify();

        // [GIVEN] Item with Serial Number Item Tracking Code with "SN Warehouse Tracking"
        CreateItem(
          Item, CreateItemTrackingCodeSerialSpecificWhseTracking(false, true), LibraryUtility.GetGlobalNoSeriesCode(), '');

        // [GIVEN] Location with "Require Receive"
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, true, false);
        LibraryWarehouse.CreateBin(ReceiptBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("Receipt Bin Code", ReceiptBin.Code);
        Location.Modify(true);

        // [GIVEN] Second item unit of measure created for the item
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Released Purchase Order with rounding precision on purchase line set to 0 and serial numbers assigned
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.");
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchaseLine.Modify(true);

        LibraryVariableStorage.Enqueue(TrackingOptionStr::AssignSerialNo);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Warehouse Receipt Lines are created
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [THEN] Warehouse Receipt Lines are created
        WarehouseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        WarehouseReceiptLine.SetRange("Source Subtype", PurchaseLine."Document Type");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseLine."Document No.");
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");

        // [WHEN] Warehouse Receipt is posted
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] No error is raised
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignTrackingNoAndVerifyQuantityHandler,EnterQuantityToCreateHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayWithSNCreatesWhseActivityLinesWithQty1WhenRndingPrecIs1()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Location: Record Location;
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        WarehouseSetup: Record "Warehouse Setup";
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
    begin
        // [FEATURE] [Whse. Receipt] [Serial No.]
        // [SCENARIO] PutAway creates whse. activity lines with quantity base as 1 when quantity rounding precision on base UOM is 1
        Initialize();

        // [GIVEN] Warehouse setup where posting errors are not supressed
        WarehouseSetup.Get();
        WarehouseSetup.Validate("Receipt Posting Policy", WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        WarehouseSetup.Modify();

        // [GIVEN] Item with Serial Number Item Tracking Code with "SN Warehouse Tracking"
        CreateItem(
          Item, CreateItemTrackingCodeSerialSpecificWhseTracking(false, true), LibraryUtility.GetGlobalNoSeriesCode(), '');

        // [GIVEN] Location with "Require Put-Away"
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        // [GIVEN] Set the quantity rounding precision on the base UOM as 1
        BaseItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
        BaseItemUnitOfMeasure.Validate("Qty. Rounding Precision", 1);
        BaseItemUnitOfMeasure.Modify();

        // [GIVEN] Second item unit of measure created for the item
        LibraryInventory.CreateItemUnitOfMeasureCode(NonBaseItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Released Purchase Order with rounding precision on purchase line set to 0 and serial numbers assigned
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.");
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Unit of Measure Code", NonBaseItemUnitOfMeasure.Code);
        PurchaseLine.Modify(true);

        LibraryVariableStorage.Enqueue(TrackingOptionStr::AssignSerialNo);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Put-Away lines are created on the released PO
        CreateInvtPutPick(WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        // [THEN] One line is created for each base quantity.
        WhseActivityLine.SetRange("Source Document", WhseActivityLine."Source Document"::"Purchase Order");
        WhseActivityLine.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordCount(WhseActivityLine, PurchaseLine."Quantity (Base)");

        WhseActivityLine.FindFirst();
        WhseActivityLine.TestField("Qty. (Base)", 1);
        WhseActivityLine.TestField(Quantity, Round(1 / NonBaseItemUnitOfMeasure."Qty. per Unit of Measure", 0.00001));

        // [THEN] Post warehouse activity (Put-Away) does not throw any errors
        WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WhseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, false);
    end;

    local procedure CreateInvtPutPick(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WhseRequest: Record "Warehouse Request";
        CreateInvtPutAwayPickMvmt: Report "Create Invt Put-away/Pick/Mvmt";
    begin
        WhseRequest.Reset();
        WhseRequest.SetCurrentKey("Source Document", "Source No.");
        WhseRequest.SetRange("Source Document", SourceDocument);
        WhseRequest.SetRange("Source No.", SourceNo);
        CreateInvtPutAwayPickMvmt.InitializeRequest(true, false, false, false, false);
        CreateInvtPutAwayPickMvmt.SetTableView(WhseRequest);
        CreateInvtPutAwayPickMvmt.UseRequestPage := false;
        CreateInvtPutAwayPickMvmt.RunModal();
    end;

    [Test]
    [HandlerFunctions('OpenItemTrackingHandler')]
    [Scope('OnPrem')]
    procedure RetrieveDocumentItemTrackingPreservesVariantCode()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingDocManagement: Codeunit "Item Tracking Doc. Management";
        PurchRcptHeaderNo: Code[20];
        LotNo: Code[50];
        LotQty: Integer;
    begin
        // [FEATURE] [Purchase] [Receipt] [Item Variant] [UT]
        // [SCENARIO 359763] Function RetrieveDocumentItemTracking in codeunit "Item Tracking Doc. Management" preserves Variant Code of Item Variant used in tracking
        Initialize();

        // [GIVEN] Lot Tracked Item with Item Variant Code = "A"
        LotNo := LibraryUtility.GenerateGUID();
        LotQty := LibraryRandom.RandInt(10);
        LibraryItemTracking.CreateLotItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Purchase Order was created
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line was create for the Item with Variant Code = "A"
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LotQty);
        PurchaseLine.Validate("Variant Code", ItemVariant.Code);
        PurchaseLine.Modify();

        // [GIVEN] Item tracking was enabled with LotNo and LotQty
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(LotQty);
        PurchaseLine.OpenItemTrackingLines();
        // UI handled by OpenItemTrackingHandler

        // [GIVEN] Post Receipt from the purchase order
        PurchRcptHeaderNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Retrieve item tracking from Posted Purchase Receipt
        ItemTrackingDocManagement.RetrieveDocumentItemTracking(
          TempTrackingSpecification, PurchRcptHeaderNo, DATABASE::"Purch. Rcpt. Header", 0);

        // [THEN] Tracking Specification has Variant Code = "A"
        TempTrackingSpecification.SetRange("Lot No.", LotNo);
        TempTrackingSpecification.FindFirst();
        TempTrackingSpecification.TestField("Variant Code", ItemVariant.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotSelectNewItemTrackingCodeWithEnabledLotWhseTrkg()
    var
        ItemTrackingCodeWithoutWhse: Record "Item Tracking Code";
        ItemTrackingCodeWithWhse: Record "Item Tracking Code";
        Item: Record Item;
    begin
        // [FEATURE] [Warehouse Item Tracking] [Item] [UT]
        // [SCENARIO 368394] A user cannot change item tracking code on item when warehouse entries exist for the item and "Lot Warehouse Tracking" setting changes.
        Initialize();

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCodeWithoutWhse, false, true);
        ItemTrackingCodeWithoutWhse.Validate("Lot Warehouse Tracking", false);
        ItemTrackingCodeWithoutWhse.Modify(true);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCodeWithWhse, false, true);

        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCodeWithoutWhse.Code);
        MockWarehouseEntry(Item."No.");

        asserterror Item.Validate("Item Tracking Code", ItemTrackingCodeWithWhse.Code);

        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(CannotChangeItemWhseEntriesExistErr, Item.FieldCaption("Item Tracking Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotSelectNewItemTrackingCodeWithDisabledSNWhseTrkg()
    var
        ItemTrackingCodeWithoutWhse: Record "Item Tracking Code";
        ItemTrackingCodeWithWhse: Record "Item Tracking Code";
        Item: Record Item;
    begin
        // [FEATURE] [Warehouse Item Tracking] [Item] [UT]
        // [SCENARIO 368394] A user cannot change item tracking code on item when warehouse entries exist for the item and "SN Warehouse Tracking" setting changes.
        Initialize();

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCodeWithoutWhse, true, false);
        ItemTrackingCodeWithoutWhse.Validate("SN Warehouse Tracking", false);
        ItemTrackingCodeWithoutWhse.Modify(true);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCodeWithWhse, true, false);

        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCodeWithWhse.Code);
        MockWarehouseEntry(Item."No.");

        asserterror Item.Validate("Item Tracking Code", ItemTrackingCodeWithoutWhse.Code);

        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(CannotChangeItemWhseEntriesExistErr, Item.FieldCaption("Item Tracking Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanSelectNewItemTrackingCodeWhenNoWhseEntriesExist()
    var
        ItemTrackingCodeWithoutWhse: Record "Item Tracking Code";
        ItemTrackingCodeWithWhse: Record "Item Tracking Code";
        Item: Record Item;
    begin
        // [FEATURE] [Warehouse Item Tracking] [Item] [UT]
        // [SCENARIO 368394] A user can change item tracking code on item when warehouse entries do not exist.
        Initialize();

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCodeWithoutWhse, false, true);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCodeWithWhse, false, true);
        ItemTrackingCodeWithWhse.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCodeWithWhse.Modify(true);

        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCodeWithoutWhse.Code);

        Item.Validate("Item Tracking Code", ItemTrackingCodeWithWhse.Code);

        Item.TestField("Item Tracking Code", ItemTrackingCodeWithWhse.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanSelectNewItemTrackingCodeWithSameWhseSettings()
    var
        ItemTrackingCode: array[2] of Record "Item Tracking Code";
        Item: Record Item;
    begin
        // [FEATURE] [Warehouse Item Tracking] [Item] [UT]
        // [SCENARIO 368394] A user can change item tracking code on item when warehouse entries exist for the item and "Lot Warehouse Tracking" setting does not change.
        Initialize();

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode[1], false, true);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode[2], false, true);

        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode[1].Code);
        MockWarehouseEntry(Item."No.");

        Item.Validate("Item Tracking Code", ItemTrackingCode[2].Code);

        Item.TestField("Item Tracking Code", ItemTrackingCode[2].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotEnableLotWhseTrackingWhenItemWithWhseEntriesExists()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
    begin
        // [FEATURE] [Warehouse Item Tracking] [Item] [UT]
        // [SCENARIO 368394] A user cannot enable "Lot Warehouse Tracking" on item tracking code when there are items with warehouse entries.
        Initialize();

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);

        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        MockWarehouseEntry(Item."No.");

        asserterror ItemTrackingCode.Validate("Lot Warehouse Tracking", true);

        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
          StrSubstNo(CannotChangeITWhseEntriesExistErr, ItemTrackingCode.FieldCaption("Lot Warehouse Tracking"), Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotEnableSNWhseTrackingWhenItemWithWhseEntriesExists()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
    begin
        // [FEATURE] [Warehouse Item Tracking] [Item] [UT]
        // [SCENARIO 368394] A user cannot enable "SN Warehouse Tracking" on item tracking code when there are items with warehouse entries.
        Initialize();

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);

        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        MockWarehouseEntry(Item."No.");

        asserterror ItemTrackingCode.Validate("SN Warehouse Tracking", true);

        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
          StrSubstNo(CannotChangeITWhseEntriesExistErr, ItemTrackingCode.FieldCaption("SN Warehouse Tracking"), Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanEnableLotWhseTrackingWhenNoWhseEntriesExist()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
    begin
        // [FEATURE] [Warehouse Item Tracking] [Item] [UT]
        // [SCENARIO 368394] A user can enable "Lot Warehouse Tracking" on item tracking code when there aren't items with warehouse entries.
        Initialize();

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);

        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);

        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);

        ItemTrackingCode.TestField("Lot Warehouse Tracking", true);
    end;

    [Test]
    [HandlerFunctions('OpenItemTrackingHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure AllNonspecificReservationEntriesReleasedOnJobJournalPostedWithDifferentItemTracking()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        JobJournalLine: Record "Job Journal Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobTransferLine: Codeunit "Job Transfer Line";
        LotNo: array[4] of Code[10];
        Index: Integer;
        TotalQuantity: Integer;
    begin
        // [FEATURE] [Job] [Job Journal]
        // [SCENARIO 384083] All non-specific reservations for a job planning line are released, when job journal line is posted with item tracking for different tracking specifications
        Initialize();

        // [GIVEN] Lot-tracked Item "I" with lots "L1", "L2", "L3", "L4" in inventory each with Quantity = 1
        CreateItemWithTrackingCode(Item, true, false);
        TotalQuantity := ArrayLen(LotNo);
        LibraryVariableStorage.Enqueue(TotalQuantity);
        for Index := 1 to TotalQuantity do begin
            LotNo[Index] := LibraryUtility.GenerateGUID();
            LibraryVariableStorage.Enqueue(LotNo[Index]);
            LibraryVariableStorage.Enqueue(1);
        end;
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Item."No.", TotalQuantity);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Job Planning Line for Item "I" with Quantity = 2
        CreateJobPlanningLine(JobPlanningLine, Item."No.", TotalQuantity / 2);

        // [GIVEN] Job Planning Line has non-specific reservation to ILEs with lots "L1", "L2"
        JobPlanningLine.AutoReserve();

        // [GIVEN] Job Journal Line is created from Job Planning Line.
        JobTransferLine.FromPlanningLineToJnlLine(JobPlanningLine, WorkDate(), LibraryJob.GetJobJournalTemplate(JobJournalTemplate),
          LibraryJob.CreateJobJournalBatch(LibraryJob.GetJobJournalTemplate(JobJournalTemplate), JobJournalBatch), JobJournalLine);

        // [GIVEN] Lots "L3", "L4" selected on Item Tracking Lines for Job Journal Line
        LibraryVariableStorage.Enqueue(TotalQuantity / 2);
        for Index := (1 + TotalQuantity / 2) to TotalQuantity do begin
            LibraryVariableStorage.Enqueue(LotNo[Index]);
            LibraryVariableStorage.Enqueue(1);
        end;
        JobJournalLine.OpenItemTrackingLines(false);

        // [WHEN] Post Job Journal Line.
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] "Reserved Quantity" = 0 on Job Planning Line
        JobPlanningLine.CalcFields("Reserved Quantity");
        JobPlanningLine.TestField("Reserved Quantity", 0);
    end;

    [Test]
    [HandlerFunctions('OpenItemTrackingHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure NonspecificReservationEntriesReleasedOnPartialJobJournalPostedWithDifferentItemTracking()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        JobJournalLine: Record "Job Journal Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobTransferLine: Codeunit "Job Transfer Line";
        LotNo: array[6] of Code[10];
        Index: Integer;
        TotalQuantity: Integer;
        JobPlanningQuantity: Integer;
        JobJournalQuantity: Integer;
    begin
        // [FEATURE] [Job] [Job Journal]
        // [SCENARIO 384083] Correct number of non-specific reservations for a job planning line is released, when partial quantity on job journal line is posted with item tracking for different tracking specifications
        Initialize();

        // [GIVEN] Lot-tracked Item "I" with lots "L1" .. "L6" in inventory each with Quantity = 1
        CreateItemWithTrackingCode(Item, true, false);
        TotalQuantity := ArrayLen(LotNo);
        JobPlanningQuantity := TotalQuantity / 2;
        LibraryVariableStorage.Enqueue(TotalQuantity);
        for Index := 1 to TotalQuantity do begin
            LotNo[Index] := LibraryUtility.GenerateGUID();
            LibraryVariableStorage.Enqueue(LotNo[Index]);
            LibraryVariableStorage.Enqueue(1);
        end;
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Item."No.", TotalQuantity);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Job Planning Line for Item "I" with Quantity = 3
        CreateJobPlanningLine(JobPlanningLine, Item."No.", JobPlanningQuantity);

        // [GIVEN] Job Planning Line has non-specific reservation to ILEs with lots "L1".."L3"
        JobPlanningLine.AutoReserve();

        // [GIVEN] Job Journal Line is created from Job Planning Line with partial Quantity = 2;
        JobJournalQuantity := LibraryRandom.RandIntInRange(1, JobPlanningQuantity - 1);
        JobTransferLine.FromPlanningLineToJnlLine(JobPlanningLine, WorkDate(), LibraryJob.GetJobJournalTemplate(JobJournalTemplate),
          LibraryJob.CreateJobJournalBatch(LibraryJob.GetJobJournalTemplate(JobJournalTemplate), JobJournalBatch), JobJournalLine);
        JobJournalLine.Validate(Quantity, JobJournalQuantity);
        JobJournalLine.Modify(true);

        // [GIVEN] Lots "L5", "L6" selected on Item Tracking Lines for Job Journal Line
        LibraryVariableStorage.Enqueue(JobJournalQuantity);
        for Index := (TotalQuantity - JobJournalQuantity + 1) to TotalQuantity do begin
            LibraryVariableStorage.Enqueue(LotNo[Index]);
            LibraryVariableStorage.Enqueue(1);
        end;
        JobJournalLine.OpenItemTrackingLines(false);

        // [WHEN] Post Job Journal Line.
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] "Reserved Quantity" = 1 on Job Planning Line
        JobPlanningLine.CalcFields("Reserved Quantity");
        JobPlanningLine.TestField("Reserved Quantity", JobPlanningQuantity - JobJournalQuantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BlockedLotNoExcludedFromPickAtLocationWithoutBins()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[2] of Code[20];
    begin
        // [FEATURE] [Warehouse] [Pick] [Blocked]
        // [SCENARIO 396331] Blocked lot no. is excluded from inventory pick at location without bins.
        Initialize();
        LotNos[1] := LibraryUtility.GenerateGUID();
        LotNos[2] := LibraryUtility.GenerateGUID();

        // [GIVEN] Location with required pick and no bins.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Lot-tracked item.
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Post 1 pc of lots "L1" and "L2" to inventory.
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, LotNos[1], '', '');
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, LotNos[2], '', '');

        // [GIVEN] Create lot no. information. Lot "L2" is blocked.
        CreateLotNoInformation(Item."No.", LotNos[1], false);
        CreateLotNoInformation(Item."No.", LotNos[2], true);

        // [GIVEN] Sales order for 2 pcs.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 2, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create inventory pick.
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // [THEN] 1 pc has been suggested for picking.
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityLine.TestField(Quantity, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BlockedSerialNoExcludedFromPickAtLocationWithoutBins()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SerialNos: array[2] of Code[20];
    begin
        // [FEATURE] [Warehouse] [Pick] [Blocked]
        // [SCENARIO 396331] Blocked serial no. is excluded from inventory pick at location without bins.
        Initialize();
        SerialNos[1] := LibraryUtility.GenerateGUID();
        SerialNos[2] := LibraryUtility.GenerateGUID();

        // [GIVEN] Location with required pick and no bins.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Serial no.-tracked item.
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Post 1 pc of serial nos. "S1" and "S2" to inventory.
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, '', SerialNos[1], '');
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, '', SerialNos[2], '');

        // [GIVEN] Create serial no. information. Serial no. "S2" is blocked.
        CreateSerialNoInformation(Item."No.", SerialNos[1], false);
        CreateSerialNoInformation(Item."No.", SerialNos[2], true);

        // [GIVEN] Sales order for 2 pcs.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 2, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create inventory pick.
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // [THEN] 1 pc has been suggested for picking.
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityLine.TestField(Quantity, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BlockedLotAndSerialNoExcludedFromPickAtLocationWithoutBins()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[3] of Code[20];
        SerialNos: array[4] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Warehouse] [Pick] [Blocked]
        // [SCENARIO 396331] Blocked lot and serial no. are excluded from inventory pick at location without bins.
        Initialize();
        for i := 1 to ArrayLen(LotNos) do
            LotNos[i] := LibraryUtility.GenerateGUID();
        for i := 1 to ArrayLen(SerialNos) do
            SerialNos[i] := LibraryUtility.GenerateGUID();

        // [GIVEN] Location with required pick and no bins.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Both lot and serial no.-tracked item.
        CreateItem(Item, CreateItemTrackingCodeLotSerial(), '', '');

        // [GIVEN] Post 1 pc of lot "L1" and serial no. "S1" to inventory.
        // [GIVEN] Post 1 pc of lot "L2" and serial no. "S2" to inventory.
        // [GIVEN] Post 1 pc of lot "L3" and serial no. "S3" to inventory.
        // [GIVEN] Post 1 pc of lot "L3" and serial no. "S4" to inventory.
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, LotNos[1], SerialNos[1], '');
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, LotNos[2], SerialNos[2], '');
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, LotNos[3], SerialNos[3], '');
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, LotNos[3], SerialNos[4], '');

        // [GIVEN] Create lot no. information. Lot "L2" is blocked.
        CreateLotNoInformation(Item."No.", LotNos[1], false);
        CreateLotNoInformation(Item."No.", LotNos[2], true);
        CreateLotNoInformation(Item."No.", LotNos[3], false);

        // [GIVEN] Create serial no. information. Serial nos. "S1", "S2" and "S3" are blocked.
        CreateSerialNoInformation(Item."No.", SerialNos[1], true);
        CreateSerialNoInformation(Item."No.", SerialNos[2], true);
        CreateSerialNoInformation(Item."No.", SerialNos[3], true);
        CreateSerialNoInformation(Item."No.", SerialNos[4], false);

        // [GIVEN] Sales order for 4 pcs.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 4, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create inventory pick.
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // [THEN] 1 pc has been suggested for picking (the only combination of "L3" and "S4" is not blocked).
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityLine.TestField(Quantity, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BlockedPackageNoExcludedFromPickAtLocationWithoutBins()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ItemTrackingCode: Record "Item Tracking Code";
        PackageNoInformation: Record "Package No. Information";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PackageNos: array[2] of Code[20];
    begin
        // [FEATURE] [Warehouse] [Pick] [Blocked]
        // [SCENARIO 401329] Blocked package no. is excluded from inventory pick at location without bins.
        Initialize();
        PackageNos[1] := LibraryUtility.GenerateGUID();
        PackageNos[2] := LibraryUtility.GenerateGUID();

        // [GIVEN] Location with required pick and no bins.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Package-tracked item.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInformation, Item."No.", PackageNos[1]);
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInformation, Item."No.", PackageNos[2]);

        // [GIVEN] Post per 1 pc of packages "P1" and "P2" to inventory.
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, '', '', PackageNos[1]);
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, '', '', PackageNos[2]);

        // [GIVEN] Block package "P2".
        UpdatePackageNoInformation(Item."No.", PackageNos[2], true);

        // [GIVEN] Sales order for 2 pcs.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 2, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create inventory pick.
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // [THEN] 1 pc has been suggested for picking.
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.",
          SalesLine."Line No.");
        WarehouseActivityLine.TestField(Quantity, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BlockedPackageAndSerialNoExcludedFromPickAtLocationWithoutBins()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ItemTrackingCode: Record "Item Tracking Code";
        PackageNoInformation: Record "Package No. Information";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PackageNos: array[3] of Code[20];
        SerialNos: array[4] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Warehouse] [Pick] [Blocked]
        // [SCENARIO 401329] Blocked package and serial no. are excluded from inventory pick at location without bins.
        Initialize();
        for i := 1 to ArrayLen(PackageNos) do
            PackageNos[i] := LibraryUtility.GenerateGUID();
        for i := 1 to ArrayLen(SerialNos) do
            SerialNos[i] := LibraryUtility.GenerateGUID();

        // [GIVEN] Location with required pick and no bins.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Both package and serial no.-tracked item.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInformation, Item."No.", PackageNos[1]);
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInformation, Item."No.", PackageNos[2]);
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInformation, Item."No.", PackageNos[3]);

        // [GIVEN] Post 1 pc of package "P1" and serial no. "S1" to inventory.
        // [GIVEN] Post 1 pc of package "P2" and serial no. "S2" to inventory.
        // [GIVEN] Post 1 pc of package "P3" and serial no. "S3" to inventory.
        // [GIVEN] Post 1 pc of package "P3" and serial no. "S4" to inventory.
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, '', SerialNos[1], PackageNos[1]);
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, '', SerialNos[2], PackageNos[2]);
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, '', SerialNos[3], PackageNos[3]);
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, '', SerialNos[4], PackageNos[3]);

        // [GIVEN] Block package "P2".
        UpdatePackageNoInformation(Item."No.", PackageNos[2], true);

        // [GIVEN] Create serial no. information. Serial nos. "S1", "S2" and "S3" are blocked.
        CreateSerialNoInformation(Item."No.", SerialNos[1], true);
        CreateSerialNoInformation(Item."No.", SerialNos[2], true);
        CreateSerialNoInformation(Item."No.", SerialNos[3], true);
        CreateSerialNoInformation(Item."No.", SerialNos[4], false);

        // [GIVEN] Sales order for 4 pcs.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 4, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create inventory pick.
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // [THEN] 1 pc has been suggested for picking (the only combination of "P3" and "S4" is not blocked).
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityLine.TestField(Quantity, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BlockedPackageLotAndSerialNoExcludedFromPickAtLocationWithoutBins()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ItemTrackingCode: Record "Item Tracking Code";
        PackageNoInformation: Record "Package No. Information";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PackageNos: array[3] of Code[20];
        LotNos: array[4] of Code[20];
        SerialNos: array[8] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Warehouse] [Pick] [Blocked]
        // [SCENARIO 440061] Blocked package, lot and serial no. are excluded from inventory pick at location without bins.
        Initialize();
        for i := 1 to ArrayLen(PackageNos) do
            PackageNos[i] := LibraryUtility.GenerateGUID();
        for i := 1 to ArrayLen(SerialNos) do
            SerialNos[i] := LibraryUtility.GenerateGUID();
        for i := 1 to ArrayLen(LotNos) do
            LotNos[i] := LibraryUtility.GenerateGUID();

        // [GIVEN] Location with required pick and no bins.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Both package and serial no.-tracked item.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);
        ItemTrackingCode.Validate("SN Warehouse Tracking", false);
        ItemTrackingCode.Validate("Package Warehouse Tracking", false);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInformation, Item."No.", PackageNos[1]);
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInformation, Item."No.", PackageNos[2]);
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInformation, Item."No.", PackageNos[3]);

        // [GIVEN] Post package "P1-P3" and serial no. "S1-S8" and lot no. "L1-L4" to inventory.
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, LotNos[1], SerialNos[1], PackageNos[1]); //Blocked
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, LotNos[1], SerialNos[2], PackageNos[1]); //Blocked
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, LotNos[1], SerialNos[3], PackageNos[2]);
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, LotNos[1], SerialNos[4], PackageNos[2]);
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, LotNos[2], SerialNos[5], PackageNos[3]); //Blocked
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, LotNos[2], SerialNos[6], PackageNos[3]); //Blocked
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, LotNos[3], SerialNos[7], PackageNos[3]); //Blocked
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, LotNos[4], SerialNos[8], PackageNos[3]); //Blocked

        // [GIVEN] Block package "P3".
        UpdatePackageNoInformation(Item."No.", PackageNos[3], true);

        // [GIVEN] Create lot no. information. Lot nos. "L2","L4"  are blocked.
        CreateLotNoInformation(Item."No.", LotNos[1], false);
        CreateLotNoInformation(Item."No.", LotNos[2], true);
        CreateLotNoInformation(Item."No.", LotNos[3], false);
        CreateLotNoInformation(Item."No.", LotNos[4], true);

        // [GIVEN] Create serial no. information. Serial nos. "S1","S2","S8" are blocked.
        CreateSerialNoInformation(Item."No.", SerialNos[1], true);
        CreateSerialNoInformation(Item."No.", SerialNos[2], true);
        CreateSerialNoInformation(Item."No.", SerialNos[3], false);
        CreateSerialNoInformation(Item."No.", SerialNos[4], false);
        CreateSerialNoInformation(Item."No.", SerialNos[5], false);
        CreateSerialNoInformation(Item."No.", SerialNos[6], false);
        CreateSerialNoInformation(Item."No.", SerialNos[7], false);
        CreateSerialNoInformation(Item."No.", SerialNos[8], true);

        // [GIVEN] Sales order for 8 pcs.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 8, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create inventory pick.
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // [THEN] 2 pc has been suggested for picking
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityLine.TestField(Quantity, 2);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BlockedPackageAndLotNoExcludedFromPickAtLocationWithoutBins()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ItemTrackingCode: Record "Item Tracking Code";
        PackageNoInformation: Record "Package No. Information";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PackageNos: array[3] of Code[20];
        LotNos: array[4] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Warehouse] [Pick] [Blocked]
        // [SCENARIO 401329] Blocked package and lot no. are excluded from inventory pick at location without bins.
        Initialize();
        for i := 1 to ArrayLen(PackageNos) do
            PackageNos[i] := LibraryUtility.GenerateGUID();
        for i := 1 to ArrayLen(LotNos) do
            LotNos[i] := LibraryUtility.GenerateGUID();

        // [GIVEN] Location with required pick and no bins.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Both package and lot no.-tracked item.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, true);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInformation, Item."No.", PackageNos[1]);
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInformation, Item."No.", PackageNos[2]);
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInformation, Item."No.", PackageNos[3]);

        // [GIVEN] Post 1 pc of package "P1" and lot no. "L1" to inventory.
        // [GIVEN] Post 1 pc of package "P2" and lot no. "L2" to inventory.
        // [GIVEN] Post 1 pc of package "P3" and lot no. "L3" to inventory.
        // [GIVEN] Post 1 pc of package "P3" and lot no. "L4" to inventory.
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, LotNos[1], '', PackageNos[1]);
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, LotNos[2], '', PackageNos[2]);
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, LotNos[3], '', PackageNos[3]);
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, LotNos[4], '', PackageNos[3]);

        // [GIVEN] Block package "P2".
        UpdatePackageNoInformation(Item."No.", PackageNos[2], true);

        // [GIVEN] Create lot no. information. Lot nos. "L1", "L2" and "L3" are blocked.
        CreateLotNoInformation(Item."No.", LotNos[1], true);
        CreateLotNoInformation(Item."No.", LotNos[2], true);
        CreateLotNoInformation(Item."No.", LotNos[3], true);
        CreateLotNoInformation(Item."No.", LotNos[4], false);

        // [GIVEN] Sales order for 4 pcs.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 4, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create inventory pick.
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // [THEN] 1 pc has been suggested for picking (the only combination of "P3" and "L4" is not blocked).
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityLine.TestField(Quantity, 1);
    end;

    [Test]
    procedure LotNoInfoExpiredInventoryDoesNotIncludeItemEntriesWithNoExpirationDate()
    var
        LotNoInformation: Record "Lot No. Information";
        LotNoInformationCard: TestPage "Lot No. Information Card";
        ItemNo: Code[20];
        LotNo: array[2] of Code[20];
    begin
        // [FEATURE] [Lot No. Information] [UT]
        // [SCENARIO 414220] "Expired Inventory" in Lot No. Information does not include item entries without expiration date.
        Initialize();

        ItemNo := LibraryInventory.CreateItemNo();
        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();

        MockItemEntryWithSerialAndLot(ItemNo, '', LotNo[1], 0D);
        MockItemEntryWithSerialAndLot(ItemNo, '', LotNo[2], WorkDate() - 1);

        LibraryItemTracking.CreateLotNoInformation(LotNoInformation, ItemNo, '', LotNo[1]);
        LibraryItemTracking.CreateLotNoInformation(LotNoInformation, ItemNo, '', LotNo[2]);

        LotNoInformationCard.OpenView();
        LotNoInformationCard.FILTER.SetFilter("Lot No.", LotNo[1]);
        LotNoInformationCard."Expired Inventory".AssertEquals(0);
        LotNoInformationCard.FILTER.SetFilter("Lot No.", LotNo[2]);
        LotNoInformationCard."Expired Inventory".AssertEquals(LotNoInformationCard."Expired Inventory".AsDEcimal());
        LotNoInformationCard.Close();
    end;

    [Test]
    procedure SerialNoInfoExpiredInventoryDoesNotIncludeItemEntriesWithNoExpirationDate()
    var
        SerialNoInformation: Record "Serial No. Information";
        SerialNoInformationCard: TestPage "Serial No. Information Card";
        ItemNo: Code[20];
        SerialNo: array[2] of Code[20];
    begin
        // [FEATURE] [Serial No. Information] [UT]
        // [SCENARIO 414220] "Expired Inventory" in Serial No. Information does not include item entries without expiration date.
        Initialize();

        ItemNo := LibraryInventory.CreateItemNo();
        SerialNo[1] := LibraryUtility.GenerateGUID();
        SerialNo[2] := LibraryUtility.GenerateGUID();

        MockItemEntryWithSerialAndLot(ItemNo, SerialNo[1], '', 0D);
        MockItemEntryWithSerialAndLot(ItemNo, SerialNo[2], '', WorkDate() - 1);

        LibraryItemTracking.CreateSerialNoInformation(SerialNoInformation, ItemNo, '', SerialNo[1]);
        LibraryItemTracking.CreateSerialNoInformation(SerialNoInformation, ItemNo, '', SerialNo[2]);

        SerialNoInformationCard.OpenView();
        SerialNoInformationCard.FILTER.SetFilter("Serial No.", SerialNo[1]);
        SerialNoInformationCard."Expired Inventory".AssertEquals(0);
        SerialNoInformationCard.FILTER.SetFilter("Serial No.", SerialNo[2]);
        SerialNoInformationCard."Expired Inventory".AssertEquals(SerialNoInformationCard."Expired Inventory".AsDEcimal());
        SerialNoInformationCard.Close();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesGetAvailabilityModalPageHandler,ConfirmHandlerTrue')]
    procedure NoAvailWarningForNonSpecificLotTracking()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SerialNo: Code[20];
        LotNo: Code[20];
    begin
        // [SCENARIO 409128] No availability warning in item tracking lines for non-specific lot tracking.
        Initialize();
        SerialNo := LibraryUtility.GenerateGUID();
        LotNo := LibraryUtility.GenerateGUID();

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        ItemTrackingCode.Validate("Lot Sales Outbound Tracking", true);
        ItemTrackingCode.Modify(true);

        CreateItem(Item, ItemTrackingCode.Code, '', '');

        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 1);
        LibraryVariableStorage.Enqueue(SerialNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SalesLine."Quantity (Base)");
        SalesLine.OpenItemTrackingLines();

        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Serial No. must not be available.');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Lot No. must be available.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesGetAvailabilityModalPageHandler,ConfirmHandlerTrue')]
    procedure NoAvailWarningForNonSpecificSerialNoTracking()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SerialNo: Code[20];
        LotNo: Code[20];
    begin
        // [SCENARIO 409128] No availability warning in item tracking lines for non-specific serial no. tracking.
        Initialize();
        SerialNo := LibraryUtility.GenerateGUID();
        LotNo := LibraryUtility.GenerateGUID();

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("SN Sales Outbound Tracking", true);
        ItemTrackingCode.Modify(true);

        CreateItem(Item, ItemTrackingCode.Code, '', '');

        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 1);
        LibraryVariableStorage.Enqueue(SerialNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SalesLine."Quantity (Base)");
        SalesLine.OpenItemTrackingLines();

        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Serial No. must be available.');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Lot No. must not be available.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrkgManualLotNoHandler')]
    procedure CanPostInventoryIncreaseWithoutMandatoryExpirationDateIfAppliedFromEntry()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        SalesHeaderOrder: Record "Sales Header";
        SalesLineOrder: Record "Sales Line";
        SalesHeaderReturn: Record "Sales Header";
        SalesLineReturn: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNo: Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Expiration Date] [Applies-from Entry]
        // [SCENARIO 414300] Stan can post inventory increase without mandatory expiration date if "Applies-from Entry" is filled in.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Lot-tracked item, Require Expiration Date = FALSE.
        // [GIVEN] Post 10 pcs to inventory, assign lot "L".
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateItem(Item, ItemTrackingCode.Code, '', LibraryUtility.GetGlobalNoSeriesCode());
        PostPositiveAdjmtWithLotExpTracking(Item, Qty, LotNo, 0D);

        // [GIVEN] Sales order for 10 pcs, select lot "L", ship.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeaderOrder, SalesLineOrder, SalesHeaderOrder."Document Type"::Order, '', Item."No.", Qty, '', WorkDate());
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLineOrder, '', LotNo, Qty);
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        // [GIVEN] Note item ledger entry no. "X" for the sales shipment.
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange(Positive, false);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.FindFirst();

        // [GIVEN] Enable Require Expiration Date for the item tracking code.
        ItemTrackingCode.Find();
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN] Create sales return order, select lot "L" and "Applies-from Entry" = "X".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeaderReturn, SalesLineReturn, SalesHeaderReturn."Document Type"::"Return Order",
          SalesHeaderOrder."Sell-to Customer No.", Item."No.", Qty, '', WorkDate());
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLineReturn, '', LotNo, Qty);
        ReservationEntry.Validate("Appl.-from Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Modify(true);

        // [WHEN] Receive the sales return.
        LibrarySales.PostSalesDocument(SalesHeaderReturn, true, false);

        // [THEN] The sales return is successfully posted.
        SalesLineReturn.Find();
        SalesLineReturn.TestField("Return Qty. Received", Qty);
    end;


    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotUpdateNewSerialNoForLineWithQuanintyMoreThanOne()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        LotNo: Code[20];
    begin
        // [FEATURE] [UT] [Serial No]
        // [SCENARIO 455523] Assigning "New Serial No." is not possible for Item Tracking Lines with Quantity > 1
        Initialize();

        // [GIVEN] Prepare Item
        CreateItem(Item, CreateItemTrackingCodeLotSerial(), '', '');

        // [GIVEN] Post inventory for that item
        LotNo := LibraryUtility.GenerateGUID();
        MockItemEntryWithSerialAndLot(Item."No.", '', LotNo, WorkDate());

        // [GIVEN] Item journal line with quantity > 1
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandIntInRange(2, 20));

        // [GIVEN] Open item tracking to initialize the item tracking spec
        MockTrackingSpecificationForItemJnlLine(TempTrackingSpecification, ItemJournalLine, 0, '', LotNo, WorkDate());

        // [WHEN] Assigning "New Serial No.", error occurs
        asserterror TempTrackingSpecification.Validate("New Serial No.", LibraryUtility.GenerateGUID());

        // [THEN] The error states that quantity needs to be -1, 0 or 1
        Assert.ExpectedError(NewSerialNoCannotBeChangedErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignTrackingNoAndVerifyQuantityHandler,ItemTrackingSummaryOkModalPageHandler')]
    [Scope('OnPrem')]
    procedure ShouldBeAbleToAddLotNoInWhseShipmentWhenLocationIsSetAsRequirePutAway()
    var
        Item: Record Item;
        Location: Record Location;
        ItemTrackingCode: Record "Item Tracking Code";
        WarehouseEmployee: Record "Warehouse Employee";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO 491844] With the location Setup Require put away you are not able to add i[Atem tracking on the warehouse shipment without having require pick activated.
        Initialize();

        // [GIVEN] Create Lot Item Tracking Code.
        CreatelotItemTrackingCode(ItemTrackingCode);

        // [GIVEN] Create Item with Lot Item Tracking Code.
        CreateItemWithLotItemTrackingCode(Item, ItemTrackingCode);

        // [GIVEN] Create Location with Warehouse Employee Setup.
        CreateLocationWithWarehouseEmployeeSetup(Location, WarehouseEmployee);

        // [GIVEN] Create Purchase Order.
        CreatePurchaseOrder(PurchaseHeader, Item, Location);

        // [GIVEN] Find Purchase Line.
        FindPurchLine(PurchaseHeader, PurchaseLine);

        // [GIVEN] Open Item Tracking Lines page.
        LibraryVariableStorage.Enqueue(TrackingOptionStr::AssignLotNo);
        PurchaseLine.OpenItemTrackingLines();

        // [GIVEN] Post Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Validate Require Receive and Require Put-away in Location.
        Location.Validate("Require Receive", true);
        Location.Validate("Require Put-away", true);
        Location.Modify(true);

        // [GIVEN] Create and Release Sales Order.
        CreateAndReleaseSalesOrder(SalesHeader, Item, Location);

        // [GIVEN] Create Warehouse Shipment.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Find Warehouse Shipment Header and Line.
        FindWarehouseShipmentHeaderAndLine(WhseShipmentHeader, WhseShipmentLine, SalesHeader);

        // [GIVEN] Open Item Tracking Lines page.
        LibraryVariableStorage.Enqueue(TrackingOptionStr::SelectEntries);
        WhseShipmentLine.OpenItemTrackingLines();

        // [GIVEN] Create Pick.
        LibraryWarehouse.CreatePick(WhseShipmentHeader);

        // [WHEN] Find Warehouse Pick Line.
        WhseActivityLine.SetRange("Item No.", Item."No.");
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.FindFirst();

        // [VERIFY] Verify Lot No. is not blank.
        Assert.AreNotEqual('', WhseActivityLine."Lot No.", LotNoMustNotBeBlankErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSingleLineHandler,ItemTrackingLinesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ShouldBeAbleToAddSerialNoInWhseShipmentWhenLocationIsSetAsRequirePutAway()
    var
        Item: Record Item;
        Location: Record Location;
        ItemTrackingCode: Record "Item Tracking Code";
        WarehouseEmployee: Record "Warehouse Employee";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO 491844] With the location Setup Require put away you are not able to add i[Atem tracking on the warehouse shipment without having require pick activated.
        Initialize();

        // [GIVEN] Create Serial Item Tracking Code.
        CreateSerialItemTrackingCode(ItemTrackingCode);

        // [GIVEN] Create Item with Serial Item Tracking Code.
        CreateItemWithSerialItemTrackingCode(Item, ItemTrackingCode);

        // [GIVEN] Create Location with Warehouse Employee Setup.
        CreateLocationWithWarehouseEmployeeSetup(Location, WarehouseEmployee);

        // [GIVEN] Create Purchase Order.
        CreatePurchaseOrder(PurchaseHeader, Item, Location);

        // [GIVEN] Find Purchase Line.
        FindPurchLine(PurchaseHeader, PurchaseLine);

        // [GIVEN] Open Item Tracking Lines page.
        PurchaseLine.OpenItemTrackingLines();

        // [GIVEN] Post Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Validate Require Receive and Require Put-away in Location.
        Location.Validate("Require Receive", true);
        Location.Validate("Require Put-away", true);
        Location.Modify(true);

        // [GIVEN] Create and Release Sales Order.
        CreateAndReleaseSalesOrder(SalesHeader, Item, Location);

        // [GIVEN] Create Warehouse Shipment.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Find Warehouse Shipment Header and Line.
        FindWarehouseShipmentHeaderAndLine(WhseShipmentHeader, WhseShipmentLine, SalesHeader);

        // [GIVEN] Open Item Tracking Lines page.
        LibraryVariableStorage.Enqueue(TrackingOptionStr::SelectEntries);
        WhseShipmentLine.OpenItemTrackingLines();

        // [GIVEN] Create Pick.
        LibraryWarehouse.CreatePick(WhseShipmentHeader);

        // [WHEN] Find Warehouse Pick Line.
        WhseActivityLine.SetRange("Item No.", Item."No.");
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.FindFirst();

        // [VERIFY] Verify Serial No. is not blank.
        Assert.AreNotEqual('', WhseActivityLine."Serial No.", SerialNoMustNotBeBlankErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSerialNoHandler,WhseItemTrackingSerialNoHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure WhsePickIsCreatedForSrNoHavingExpDateAndNotForSrNoWithoutExpDateWhenStrictExpPostingIsTrueInItemTrkgCode()
    var
        Bin: array[5] of Record Bin;
        Item: Record Item;
        Location: Record Location;
        ItemTrackingCode: Record "Item Tracking Code";
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        SalesHeader: Record "Sales Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        SerialNo: array[4] of Code[50];
    begin
        // [SCENARIO 566894] Warehouse Pick for Serial No. having "Expiration Date" is created even if another
        // Serial No. is with "Expiration Date" when Create Pick from a Warehouse Shipment of Item whose Inventory
        // Movement is already created with other two Serial Nos.
        Initialize();

        // [GIVEN] Create Serial Item Tracking Code.
        CreateSerialItemTrackingCode(ItemTrackingCode);


        // [GIVEN] Create Item with Serial Item Tracking Code and
        // Validate "Use Expiration Dates" and "Strict Expiration Posting".
        CreateItemWithSerialItemTrackingCode(Item, ItemTrackingCode);
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Validate("Strict Expiration Posting", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN] Create Location with Warehouse Employee Setup.
        CreateLocationWithWarehouseEmployeeSetup(Location, WarehouseEmployee);

        // [GIVEN] Create five Bins.
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, Bin[1].Code, '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, Bin[2].Code, '', '');
        LibraryWarehouse.CreateBin(Bin[3], Location.Code, Bin[3].Code, '', '');
        LibraryWarehouse.CreateBin(Bin[4], Location.Code, Bin[4].Code, '', '');
        LibraryWarehouse.CreateBin(Bin[5], Location.Code, Bin[5].Code, '', '');

        // [GIVEN] Validate Location fields.
        ValidateLocationFields(Location, Bin[5]);

        // [GIVEN] Generate and save four Serial Nos. in a Variable.
        SerialNo[1] := Format(LibraryRandom.RandIntInRange(1, 1));
        SerialNo[2] := Format(LibraryRandom.RandIntInRange(2, 2));
        SerialNo[3] := Format(LibraryRandom.RandIntInRange(3, 3));
        SerialNo[4] := Format(LibraryRandom.RandIntInRange(4, 4));

        // [GIVEN] Create Positive Adjustment With Serial Nos.
        LibraryVariableStorage.Enqueue(SerialNo[1]);
        LibraryVariableStorage.Enqueue(SerialNo[2]);
        LibraryVariableStorage.Enqueue(SerialNo[3]);
        LibraryVariableStorage.Enqueue(SerialNo[4]);
        CreatePositivAdjWithSerialNos(Item."No.", Location.Code, Bin[1], LibraryRandom.RandIntInRange(4, 4), SerialNo[1], SerialNo[2], SerialNo[3], SerialNo[4]);

        // [GIVEN] Create Internal Movement Header.
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Location.Code, Bin[2].Code);

        // [GIVEN] Create Internal Movement Line.
        LibraryWarehouse.CreateInternalMovementLine(InternalMovementHeader, InternalMovementLine, Item."No.", Bin[1].Code, Bin[2].Code, LibraryRandom.RandIntInRange(2, 2));

        // [GIVEN] Open Item Tracking Lines.
        LibraryVariableStorage.Enqueue(SerialNo[1]);
        LibraryVariableStorage.Enqueue(SerialNo[2]);
        InternalMovementLine.OpenItemTrackingLines();

        // [GIVEN] Crate Inventory Movement from Internal Movement.
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);

        // [GIVEN] Create and Release Sales Order with Quantity.
        CreateAndReleaseSalesOrderWithQty(SalesHeader, Item, Location, LibraryRandom.RandIntInRange(2, 2));

        // [GIVEN] Create Warehouse Shipment.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Find Warehouse Shipment Header and Line.
        FindWarehouseShipmentHeaderAndLine(WhseShipmentHeader, WhseShipmentLine, SalesHeader);

        // [GIVEN] Create Pick.
        LibraryWarehouse.CreatePick(WhseShipmentHeader);

        // [WHEN] Find Warehouse Pick Line.
        WhseActivityLine.SetRange("Item No.", Item."No.");
        WhseActivityLine.SetRange("Serial No.", SerialNo[4]);
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.FindFirst();

        // [VERIFY] Warehouse Activity Lineis found.
        Assert.IsFalse(WhseActivityLine.IsEmpty(), WhseActivityLineMustBeFoundErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandlerTrackingOption,ItemTrackingSummaryOkModalPageHandler,ConfirmHandlerTrue')]
    procedure DuplicateSNNotAllowedAddedToStockWithSNSpecificTracking()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SerialNo: Code[20];
    begin
        // [SCENARIO 563235] A Duplicate SN is not allowed to be added to stock with SN Specific Tracking when Item Journal is posted followed by an Undo Shipment with the same SN.
        Initialize();

        // [GIVEN] Create Item with Serial Number Item Tracking Code
        CreateItem(
          Item, CreateItemTrackingCodeSerialSpecificWhseTracking(false, true), LibraryUtility.GetGlobalNoSeriesCode(), '');

        // [GIVEN] Location with Inventory Posting Setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Post item to inventory with Serial No.
        SerialNo := LibraryUtility.GenerateGUID();
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, '', SerialNo, '');

        // [GIVEN] Sales Order is created to exhaust the posted items in item journal
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 1);

        // [GIVEN] Update Location on Sales Line
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        // [GIVEN] Assign Serial No. to Sales Line
        LibraryVariableStorage.Enqueue(ItemTrackingOption::SelectEntries);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Release and Post Sales Order
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Post item to inventory with same Serial No.
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, '', SerialNo, '');

        // [WHEN] Undo Sales Shipment
        asserterror UndoSalesShipment(SalesLine);

        // [THEN] Error is thrown for duplicate Serial No.
        Assert.ExpectedError(StrSubstNo(SerialNoAlreadyOnInventoryErr, SerialNo));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Item Tracking");
        LibraryVariableStorage.Clear();
        // Clear global variables.
        Clear(SalesMode);
        Clear(AssignLotNo);
        Clear(AssignSerialNo);
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Item Tracking");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Item Tracking");
    end;

    local procedure PrepareTransferLineWithLotAndQtyToHandle(var TransferLine: Record "Transfer Line"; LotNo: Code[50]; QtyToShip: Decimal; QtyToReceive: Decimal; QtyToHandle: Decimal; Direction: Enum "Transfer Direction")
    var
        QtyToUpdate: Option Quantity,"Quantity to Handle","Quantity to Invoice";
    begin
        TransferLine.Validate("Qty. to Ship", QtyToShip);
        TransferLine.Validate("Qty. to Receive", QtyToReceive);
        TransferLine.Modify(true);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(QtyToUpdate::"Quantity to Handle");
        LibraryVariableStorage.Enqueue(QtyToHandle);
        TransferLine.OpenItemTrackingLines(Direction);
    end;

    local procedure CalcQtyToHandleInReservEntries(LotNo: Code[50]): Decimal
    var
        ReservEntry: Record "Reservation Entry";
        Qty: Decimal;
    begin
        ReservEntry.SetRange("Lot No.", LotNo);
        ReservEntry.FindSet();
        repeat
            Qty += ReservEntry."Qty. to Handle (Base)";
        until ReservEntry.Next() = 0;

        exit(Qty);
    end;

    local procedure CreateAndPostPurchaseOrderWithItemTracking(var PurchaseLine: Record "Purchase Line"; ExpirationDate: Date): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
    begin
        CreateItem(
          Item, CreateItemTrackingCodeSerialSpecific(true), LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode());
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.");
        AssignSerialNo := true;  // Use AssignSerialNo as global variable for Handler.
        PurchaseLine.OpenItemTrackingLines();
        UpdateReservationEntry(PurchaseLine."No.", ExpirationDate);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));  // Post Purchase Order as Receive.
    end;

    local procedure CreateAndPostPurchaseOrderWithLotNoInItemTracking(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrderWithLotNoInItemTracking(PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post Purchase Order as Receive.
    end;

    local procedure PostJrnlLineWithPurchaseOnThreeLotsAndCalcQtySale(Item: Record Item; LocationCode: Code[10]; var QtySale: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        LotCount: Integer;
        LotQty: array[3] of Decimal;
        QtyPurchase: Decimal;
        TempQty: Decimal;
        LotNo: array[3] of Code[10];
        iLot: Integer;
    begin
        LotCount := ArrayLen(LotQty);

        for iLot := 1 to LotCount do begin
            LotNo[iLot] := LibraryUtility.GenerateGUID();
            LotQty[iLot] := LibraryRandom.RandInt(10);
            TempQty += LotQty[iLot]; // LotQty[3] > SUM(LotQty[1 .. LotQty - 1])
        end;
        LotQty[LotCount] := TempQty;

        // QtyPurchase > QtySale > SUM(LotQty[1 .. LotQty - 1])
        QtySale := LotQty[LotCount];
        QtyPurchase := LotQty[1] + LotQty[2] + LotQty[3];

        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch, Item, LocationCode, '', WorkDate(), ItemJournalLine."Entry Type"::"Positive Adjmt.", QtyPurchase, 0);
        LibraryVariableStorage.Enqueue(LotCount);
        for iLot := 1 to LotCount do begin
            LibraryVariableStorage.Enqueue(LotNo[iLot]);
            LibraryVariableStorage.Enqueue(LotQty[iLot]);
        end;

        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateLocationWithPickAndShip(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Pick", true);
        Location.Validate("Require Shipment", true);
        Location.Modify(true);
    end;

    local procedure CreateItemWithTrackingCode(var Item: Record Item; LotSpecificTracking: Boolean; SNSpecificTracking: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Specific Tracking", LotSpecificTracking);
        if LotSpecificTracking then
            ItemTrackingCode.Validate("Lot Warehouse Tracking", not LotSpecificTracking);
        ItemTrackingCode.Validate("SN Specific Tracking", SNSpecificTracking);
        if SNSpecificTracking then
            ItemTrackingCode.Validate("SN Warehouse Tracking", not SNSpecificTracking);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Standard, LibraryPatterns.RandCost(Item));
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);
    end;

    local procedure CreateItemWithLotWarehouseTracking(): Code[20]
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateReleasedSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Item: Record Item; LocationCode: Code[10]; QtySale: Decimal)
    var
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
    begin
        LibrarySales.CreateSalesOrder(
          SalesHeader, SalesLine, Item, LocationCode, '', QtySale, WorkDate(), LibraryRandom.RandDec(1000, 2));
        ReservMgt.SetReservSource(SalesLine);
        ReservMgt.AutoReserve(FullAutoReservation, '', WorkDate(), QtySale, QtySale);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure PostWhseShptLine(WhseShipmentLine: Record "Warehouse Shipment Line")
    begin
        CODEUNIT.Run(CODEUNIT::"Whse.-Post Shipment (Yes/No)", WhseShipmentLine);
    end;

    local procedure PostPurchaseOrderAndCreateReleasedSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        QtySale: Decimal;
    begin
        CreateItemWithTrackingCode(Item, true, false);
        CreateLocationWithPickAndShip(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        PostJrnlLineWithPurchaseOnThreeLotsAndCalcQtySale(Item, Location.Code, QtySale);
        CreateReleasedSalesOrder(SalesHeader, SalesLine, Item, Location.Code, QtySale);
    end;

    local procedure CreateAndReleaseTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    var
        TransferLine: Record "Transfer Line";
        InTransitLocation: Record Location;
    begin
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Qty);
        LibraryInventory.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateWhseShipWithItemTrackingLines(var WhseShipmentLine: Record "Warehouse Shipment Line"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    var
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        ReservEntry: Record "Reservation Entry";
        WhseShptRlse: Codeunit "Whse.-Shipment Release";
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        FindWhseShipmentLineSalesSource(WhseShipmentLine, SalesHeader);
        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        WhseShptRlse.Release(WhseShipmentHeader);
        WhseShipmentLine.CreatePickDoc(WhseShipmentLine, WhseShipmentHeader);

        FindWhseActivityLine(WhseActivityLine, WhseShipmentHeader."No.");

        CODEUNIT.Run(CODEUNIT::"Whse.-Activity-Register", WhseActivityLine);

        ReservEntry.SetRange("Item No.", SalesLine."No.");
        ReservEntry.FindLast();

        LibraryVariableStorage.Enqueue(1);
        // number of Lot to create for Item Tracking Lines
        LibraryVariableStorage.Enqueue(ReservEntry."Lot No.");
        LibraryVariableStorage.Enqueue(SalesLine."Quantity (Base)");
        SalesLine.OpenItemTrackingLines(); // Create ItemTrackingLine for Lot3 Manually using OpenItemTrackingHandler Handler
    end;

    local procedure CreatePurchaseOrderWithLotNoInItemTracking(var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateItem(Item, CreateItemTrackingCodeLotSpecific(false), '', LibraryUtility.GetGlobalNoSeriesCode());
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.");
        AssignLotNo := true; // Use AssignLotNo as global variable for Handler.
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreatePurchaseOrderWithMultipleLotNoInItemTracking(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; var QuantityBase: array[2] of Decimal; var QtyToHandle: array[2] of Decimal)
    var
        i: Integer;
    begin
        CreatePurchaseDocumentWithJob(PurchaseLine, DocumentType);
        LibraryVariableStorage.Enqueue(TrackingOptionStr::SetLotQty);
        LibraryVariableStorage.Enqueue(ArrayLen(QuantityBase)); // Create 2 Item Tracking Line;
        QuantityBase[1] := PurchaseLine."Quantity (Base)" / LibraryRandom.RandIntInRange(3, 5);
        QuantityBase[2] := PurchaseLine."Quantity (Base)" - QuantityBase[1];
        for i := 1 to ArrayLen(QuantityBase) do begin
            QtyToHandle[i] := QuantityBase[i] / LibraryRandom.RandIntInRange(3, 5);
            LibraryVariableStorage.Enqueue(QuantityBase[i]); // Enqueue value for ItemTrackingLines."Quantity (Base)"
            LibraryVariableStorage.Enqueue(QtyToHandle[i]); // Enqueue value for ItemTrackingLines."Qty. to Handle (Base)"
        end;
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreateAndPostSalesOrderWithItemTracking(No: Code[20]; Quantity: Decimal; Days: Integer; LocationCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, No, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
        AssignSerialNo := false;  // Use AssignSerialNo as global variable for Handler.
        SalesMode := true;  // Use SalesMode as global variable for Handler.
        SalesLine.OpenItemTrackingLines();
        SalesHeader.Validate("Posting Date", CalcDate('<' + Format(Days) + 'D>', WorkDate()));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));  // Post Sales Order as Ship.
    end;

    local procedure CreateSOWithPOAndILEReservationAndOneItemTracking(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        ItemInventoryQty: Decimal;
    begin
        CreateItem(Item, CreateItemTrackingWithSalesSerialNos(), LibraryUtility.GetGlobalNoSeriesCode(), '');
        ItemInventoryQty := LibraryRandom.RandInt(100);
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', ItemInventoryQty, WorkDate(), Item."Unit Cost");

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.");
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", PurchaseLine.Quantity + ItemInventoryQty);
        SalesLine.ShowReservation();
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateItem(var Item: Record Item; ItemTrackingCode: Code[10]; SerialNos: Code[20]; LotNos: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Validate("Serial Nos.", SerialNos);
        Item.Validate("Lot Nos.", LotNos);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
    end;

    local procedure CreateItemNo(ItemTrackingCode: Code[10]; SerialNos: Code[20]; LotNos: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        CreateItem(Item, ItemTrackingCode, SerialNos, LotNos);
        exit(Item."No.");
    end;

    local procedure CreateLotTrackedItemForPlanning(var Item: Record Item)
    begin
        CreateItemWithTrackingCode(Item, true, false);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateLotNoInformation(ItemNo: Code[20]; LotNo: Code[20]; IsBlocked: Boolean)
    var
        LotNoInformation: Record "Lot No. Information";
    begin
        LibraryItemTracking.CreateLotNoInformation(LotNoInformation, ItemNo, '', LotNo);
        LotNoInformation.Validate(Blocked, IsBlocked);
        LotNoInformation.Modify(true);
    end;

    local procedure CreateSerialNoInformation(ItemNo: Code[20]; SerialNo: Code[20]; IsBlocked: Boolean)
    var
        SerialNoInformation: Record "Serial No. Information";
    begin
        LibraryItemTracking.CreateSerialNoInformation(SerialNoInformation, ItemNo, '', SerialNo);
        SerialNoInformation.Validate(Blocked, IsBlocked);
        SerialNoInformation.Modify(true);
    end;

    local procedure UpdatePackageNoInformation(ItemNo: Code[20]; PackageNo: Code[20]; IsBlocked: Boolean)
    var
        PackageNoInformation: Record "Package No. Information";
    begin
        PackageNoInformation.Get(ItemNo, '', PackageNo);
        PackageNoInformation.Validate(Blocked, IsBlocked);
        PackageNoInformation.Modify(true);
    end;

    local procedure CreateItemJournalLine(var ItemJnlLine: Record "Item Journal Line"; Item: Record Item; EntryType: Enum "Item Ledger Document Type"; Qty: Decimal; UnitAmount: Decimal)
    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJnlBatch, ItemJnlTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(ItemJnlLine, ItemJnlBatch, Item, '', '', WorkDate(), EntryType, Qty, UnitAmount);
    end;

    local procedure CreateItemTrackingCodeLotSerial(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Specific Tracking", true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Validate("SN Specific Tracking", true);
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Modify(true);

        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateItemTrackingCodeLotSpecific(ExpDateRequired: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        ItemTrackingCode.Validate("Lot Purchase Inbound Tracking", true);
        ItemTrackingCode.Validate("Lot Purchase Outbound Tracking", true);
        ItemTrackingCode.Validate("Lot Sales Inbound Tracking", true);
        ItemTrackingCode.Validate("Lot Sales Outbound Tracking", true);
        ItemTrackingCode.Validate("Lot Manuf. Inbound Tracking", true);
        ItemTrackingCode.Validate("Lot Manuf. Outbound Tracking", true);
        ItemTrackingCode.Validate("Use Expiration Dates", ExpDateRequired);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", ExpDateRequired);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateItemTrackingCodeTransferLotTracking(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        ItemTrackingCode.Validate("Lot Transfer Tracking", true);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateItemTrackingCodeSerialSpecific(StrictExpirationPosting: Boolean): Code[10]
    begin
        exit(CreateItemTrackingCodeSerialSpecificWhseTracking(StrictExpirationPosting, false));
    end;

    local procedure CreateItemTrackingCodeSerialSpecificWhseTracking(StrictExpirationPosting: Boolean; SNWarehouseTracking: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        ItemTrackingCode.Validate("Use Expiration Dates", StrictExpirationPosting);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", StrictExpirationPosting);
        ItemTrackingCode.Validate("Strict Expiration Posting", StrictExpirationPosting);
        ItemTrackingCode.Validate("SN Warehouse Tracking", SNWarehouseTracking);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateItemTrackingCodeLotSpecificWhseTracking(LotWarehouseTracking: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", LotWarehouseTracking);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateItemTrackingWithSalesSerialNos(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        ItemTrackingCode.Validate("SN Sales Inbound Tracking", true);
        ItemTrackingCode.Validate("SN Sales Outbound Tracking", true);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateItemTrackingCodeFreeEntry(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateItemTrackingCodeWithLotSerialPackage(var ItemTrCode: Code[10]; var LocationCode: Code[10])
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Location: Record Location;
    begin
        ItemTrackingCode.Get(CreateItemTrackingCodeLotSerial());
        ItemTrackingCode.Validate("Package Specific Tracking", true);
        ItemTrackingCode.Modify(true);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        ItemTrCode := ItemTrackingCode.Code;
        LocationCode := Location.Code;
    end;

    local procedure CreateLocationWithBins(var Location: Record Location; var Bin: Record Bin)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);

        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        Location.Validate("Shipment Bin Code", Bin.Code);
        Location.Modify(true);

        Bin.SetFilter(Code, '<>%1', Location."Shipment Bin Code");
        Bin.FindFirst();
    end;

    local procedure CreateMultilinePurchaseOrderWithJobAndLotTracking(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        JobTask: Record "Job Task";
    begin
        CreatePurchaseDocumentWithJobAndLotTracking(PurchaseLine, PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        JobTask.Get(PurchaseLine."Job No.", PurchaseLine."Job Task No.");

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchaseLine."No.", LibraryRandom.RandIntInRange(5, 10));
        UpdatePurchaseLineWithJobTask(PurchaseLine, JobTask);
        LibraryVariableStorage.Enqueue(TrackingOptionStr::AssignLotNo);
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; ItemNo: Code[20]; Qty: Decimal)
    var
        JobTask: Record "Job Task";
    begin
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate(Quantity, Qty);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateReservedJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; var LotNo: Code[10])
    var
        Item: Record Item;
    begin
        CreateLotTrackedItemForPlanning(Item);
        LotNo := LibraryUtility.GenerateGUID();

        CreateJobPlanningLine(JobPlanningLine, Item."No.", LibraryRandom.RandInt(10));
        CalculatePlanAndCarryOutReqWorksheet(Item);
        PostPurchaseOrderWithLotTracking(Item."Vendor No.", LotNo);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, ItemNo, LibraryRandom.RandInt(5));
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; ItemQty: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, ItemQty);
    end;

    local procedure CreatePurchaseDocumentWithLotTrackedItem(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; ItemQty: Decimal; LotNo: Code[10])
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, DocumentType, '', ItemNo, ItemQty, '', WorkDate());
        EnqueueItemLotNoAndQuantity(LotNo, ItemQty);
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreateSalesDocumentWithLotTrackedItem(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; ItemQty: Decimal; LotNo: Code[10])
    begin
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, DocumentType, '', ItemNo, ItemQty, '', WorkDate());
        EnqueueItemLotNoAndQuantity(LotNo, ItemQty);
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreateLotTrackedItemInventory(ItemNo: Code[20]; ItemQty: Decimal; LotNo: Code[10])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, ItemQty);
        EnqueueItemLotNoAndQuantity(LotNo, ItemQty);
        ItemJournalLine.OpenItemTrackingLines(false);
    end;

    local procedure EnqueueItemLotNoAndQuantity(LotNo: Code[10]; ItemQty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(1); // for OpenItemTrackingHandler
        LibraryVariableStorage.Enqueue(LotNo); // for OpenItemTrackingHandler
        LibraryVariableStorage.Enqueue(ItemQty); // for OpenItemTrackingHandler
    end;

    local procedure EnqueueSNLotNoAndQtyToReserve(SerialNo: Code[50]; LotNo: Code[50]; PackageNo: Code[50]; QtyToReserve: Integer)
    begin
        LibraryVariableStorage.Enqueue(SerialNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(PackageNo);
        LibraryVariableStorage.Enqueue(QtyToReserve);
    end;

    local procedure CreatePurchaseDocumentWithPostingDate(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; PostingDate: Date; ItemNo: Code[20]; Qty: Decimal)
    begin
        CreatePurchaseHeaderWithPostingDate(PurchaseHeader, DocumentType, VendorNo, PostingDate);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
    end;

    local procedure CreatePurchaseHeaderWithPostingDate(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; PostingDate: Date)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchOrderExpirationDateBeforePosting(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);

        AssignSerialNo := true;
        PurchaseLine.OpenItemTrackingLines();

        UpdateReservationEntry(ItemNo, CalcDate('<-1W>', WorkDate()));
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; ItemQty: Decimal)
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, ItemNo, ItemQty);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; ItemQty: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, ItemQty);
        SalesLine.Validate("Shipment Date", CalcDate('<1D>', WorkDate()));
        SalesLine.Modify(true);
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CreateCustomer());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        if DocumentType = ServiceHeader."Document Type"::Order then begin
            LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
            LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
            ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        end;
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Modify(true);
    end;

    local procedure CreateTransitLocations(var FromLocation: Record Location; var ToLocation: Record Location; var InTransitLocation: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
    end;

    local procedure CreateTransferOrderOnNewItem(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; Qty: Decimal)
    var
        Item: Record Item;
    begin
        CreateItem(Item, CreateItemTrackingCodeTransferLotTracking(), '', '');
        CreateTransferOrderSimple(TransferHeader, TransferLine, Item, Qty);
    end;

    local procedure CreateTransferOrderSimple(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; Item: Record Item; Qty: Decimal)
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
    begin
        CreateTransitLocations(FromLocation, ToLocation, InTransitLocation);
        LibraryInventory.CreateTransferOrder(
          TransferHeader, TransferLine, Item, FromLocation, ToLocation, InTransitLocation, '', Qty, WorkDate(), WorkDate());
    end;

    local procedure CreatePurchaseDocumentWithJobAndLotTracking(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    begin
        CreatePurchaseDocumentWithJob(PurchaseLine, DocumentType);
        LibraryVariableStorage.Enqueue(TrackingOptionStr::AssignLotNo);
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreatePurchaseDocumentWithJob(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        JobTask: Record "Job Task";
    begin
        CreateItem(Item, CreateItemTrackingCodeLotSpecific(false), '', LibraryUtility.GetGlobalNoSeriesCode());
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, DocumentType, Item."No.", LibraryRandom.RandIntInRange(5, 10));
        CreateJobWithJobTask(JobTask);
        UpdatePurchaseLineWithJobTask(PurchaseLine, JobTask);
    end;

    local procedure InitTransferOrderTwoLinesScenario(var TransferHeader: Record "Transfer Header"; var LotNo: Code[50])
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        TransferLine: Record "Transfer Line";
        TransferOrderPage: TestPage "Transfer Order";
        QtyToUpdate: Option Quantity,"Quantity to Handle","Quantity to Invoice";
        ItemTrackingCode: Code[10];
        Qty: Decimal;
    begin
        Initialize();

        // create item, make positive adjustment to FromLocation
        ItemTrackingCode := CreateItemTrackingCodeTransferLotTracking();
        CreateItem(Item, ItemTrackingCode, '', '');
        LotNo := LibraryUtility.GenerateGUID();

        CreateTransitLocations(FromLocation, ToLocation, InTransitLocation);

        Qty := LibraryRandom.RandInt(5);
        CreatePositivAdjWithLot(Item."No.", FromLocation.Code, Qty * 2, LotNo);

        // create transfer order with 2 lines
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Qty);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Qty);

        // add tracking specification for lines
        TransferOrderPage.OpenEdit();
        TransferOrderPage.GotoKey(TransferHeader."No.");
        SetTrackingSpecification(TransferOrderPage, LotNo, QtyToUpdate::Quantity, Qty);
        TransferOrderPage.TransferLines.Next();
        SetTrackingSpecification(TransferOrderPage, LotNo, QtyToUpdate::Quantity, Qty);
    end;

    local procedure CreatePositivAdjWithLot(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; LotNo: Code[50])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        QtyToUpdate: Option Quantity,"Quantity to Handle","Quantity to Invoice";
    begin
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        // add item tracking
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(QtyToUpdate::Quantity);
        LibraryVariableStorage.Enqueue(Quantity);

        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreatePostItemJnlLine(var LineNo: Integer; ItemNo: Code[20])
    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
    begin
        LibraryInventory.FindItemJournalTemplate(ItemJnlTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJnlBatch, ItemJnlTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandInt(100));
        LineNo := ItemJnlLine."Line No.";
        LibraryInventory.PostItemJournalLine(ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLineWithItemTracking(ItemNo: Code[20]; LocationCode: Code[10]; LotNo: Code[20]; SerialNo: Code[20]; PackageNo: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, 1);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);

        LibraryItemTracking.CreateItemJournalLineItemTracking(
          ReservationEntry, ItemJournalLine, SerialNo, LotNo, PackageNo, ItemJournalLine.Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateWhseShipmentAndPickFromTransferOrder(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var TransferHeader: Record "Transfer Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        FindWhseShipmentHeader(WarehouseShipmentHeader, DATABASE::"Transfer Line", 0, TransferHeader."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);
    end;

    local procedure CreateInvtPickOutboundTransfer(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20])
    begin
        CreateInvtPickPutAwayWithSourceDocument(WarehouseActivityHeader, SourceNo, WarehouseActivityHeader."Source Document"::"Outbound Transfer", false, true);
    end;

    local procedure CreateInvtPutAwayPurchOrder(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20])
    begin
        CreateInvtPickPutAwayWithSourceDocument(
            WarehouseActivityHeader, SourceNo, WarehouseActivityHeader."Source Document"::"Purchase Order", true, false);
    end;

    local procedure CreateInvtPickPutAwayWithSourceDocument(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; PutAway: Boolean; Pick: Boolean)
    begin
        LibraryWarehouse.CreateInvtPutPickMovement(
          SourceDocument, SourceNo, PutAway, Pick, false);
        WarehouseActivityHeader.SetRange("Source Document", SourceDocument);
        WarehouseActivityHeader.SetRange("Source No.", SourceNo);
        WarehouseActivityHeader.FindFirst();
    end;

    local procedure EnqueueLotTrackingSpec(LotNo: Code[50]; QtyToUpdate: Option; Quantity: Decimal)
    begin
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(QtyToUpdate);
        LibraryVariableStorage.Enqueue(Quantity);
    end;

    local procedure FindReservationForItemJournal(var ReservEntry: Record "Reservation Entry"; ItemNo: Code[20])
    begin
        ReservEntry.SetRange("Item No.", ItemNo);
        ReservEntry.SetRange("Source Type", DATABASE::"Item Journal Line");
        ReservEntry.FindFirst();
    end;

    local procedure FindWhseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWhseShipmentLine(WarehouseShipmentLine, SourceType, SourceSubtype, SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure FindWhseShipmentLine(var WhseShipmentLine: Record "Warehouse Shipment Line"; SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20])
    begin
        WhseShipmentLine.SetRange("Source Type", SourceType);
        WhseShipmentLine.SetRange("Source Subtype", SourceSubtype);
        WhseShipmentLine.SetRange("Source No.", SourceNo);
        WhseShipmentLine.FindFirst();
    end;

    local procedure FindWhseShipmentLineSalesSource(var WhseShipmentLine: Record "Warehouse Shipment Line"; SalesHeader: Record "Sales Header")
    begin
        FindWhseShipmentLine(WhseShipmentLine, DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
    end;

    local procedure FindWhseActivityLine(var WhseActivityLine: Record "Warehouse Activity Line"; WhseShptHdrNo: Code[20])
    begin
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.SetRange("Whse. Document Type", WhseActivityLine."Whse. Document Type"::Shipment);
        WhseActivityLine.SetRange("Whse. Document No.", WhseShptHdrNo);
        WhseActivityLine.FindFirst();
    end;

    local procedure FindPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLine: Record "Purchase Line")
    begin
        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();
    end;

    local procedure CalculatePlanAndCarryOutReqWorksheet(Item: Record Item)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CalculatePlanForReqWksh(Item, ReqWkshTemplate.Name, RequisitionWkshName.Name, WorkDate(), WorkDate());
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst();
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure SetQtyToHandleLessThanQuantityForBothLots(TransferLine: Record "Transfer Line")
    begin
        LibraryVariableStorage.Enqueue(HandlingTypeStr::"QtyToHandle < Qty");
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    local procedure AlignQuantitiesForBothLots(TransferLine: Record "Transfer Line")
    begin
        LibraryVariableStorage.Enqueue(HandlingTypeStr::"Align Quantities");
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    local procedure DoubleQtyOnItemTracking(TransferLine: Record "Transfer Line"; EntryNo: Integer)
    begin
        LibraryVariableStorage.Enqueue(HandlingTypeStr::"Double Quantities");
        LibraryVariableStorage.Enqueue(EntryNo);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    local procedure InitialItemTrkgSetup(TransferLine: Record "Transfer Line"; LotNo1: Code[20]; Qty1: Decimal; QtyToHandle1: Decimal; LotNo2: Code[20]; Qty2: Decimal; QtyToHandle2: Decimal)
    begin
        LibraryVariableStorage.Enqueue(HandlingTypeStr::"Init Tracking");
        LibraryVariableStorage.Enqueue(LotNo1);
        LibraryVariableStorage.Enqueue(Qty1);
        LibraryVariableStorage.Enqueue(QtyToHandle1);
        LibraryVariableStorage.Enqueue(LotNo2);
        LibraryVariableStorage.Enqueue(Qty2);
        LibraryVariableStorage.Enqueue(QtyToHandle2);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    local procedure InitItemTrackingForTransferLine(var TransferLine: Record "Transfer Line"; LotNo: Code[50])
    var
        QtyToUpdate: Option Quantity,"Quantity to Handle","Quantity to Invoice";
    begin
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(QtyToUpdate::Quantity);
        LibraryVariableStorage.Enqueue(TransferLine.Quantity);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    local procedure MockItemEntryWithSerialAndLot(ItemNo: Code[20]; SerialNo: Code[50]; LotNo: Code[50]; ExpirationDate: Date)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(ItemLedgerEntry, ItemLedgerEntry.FieldNo("Entry No."));
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry."Serial No." := SerialNo;
        ItemLedgerEntry."Lot No." := LotNo;
        ItemLedgerEntry.Quantity := LibraryRandom.RandInt(10);
        ItemLedgerEntry."Remaining Quantity" := ItemLedgerEntry.Quantity;
        ItemLedgerEntry.Open := true;
        ItemLedgerEntry.Positive := true;
        ItemLedgerEntry."Expiration Date" := ExpirationDate;
        ItemLedgerEntry.Insert();
    end;

    local procedure MockItemTracking(var SerialNos: array[2] of Code[20]; var LotNos: array[2] of Code[20])
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(SerialNos) do
            SerialNos[i] := LibraryUtility.GenerateGUID();

        for i := 1 to ArrayLen(LotNos) do
            LotNos[i] := LibraryUtility.GenerateGUID();
    end;

    local procedure MockTrackingSpecification(var TrackingSpecification: Record "Tracking Specification"; EntryNo: Integer; LotNo: Code[50]; SerialNo: Code[50]; ExpirationDate: Date)
    begin
        TrackingSpecification."Entry No." := EntryNo;
        TrackingSpecification."Item No." :=
          LibraryUtility.GenerateRandomCode(TrackingSpecification.FieldNo("Item No."), DATABASE::"Tracking Specification");
        TrackingSpecification."Serial No." := SerialNo;
        TrackingSpecification."Lot No." := LotNo;
        TrackingSpecification."New Serial No." := SerialNo;
        TrackingSpecification."New Lot No." := LotNo;
        TrackingSpecification."Expiration Date" := ExpirationDate;
        TrackingSpecification."New Expiration Date" := ExpirationDate;
        TrackingSpecification.Insert();
    end;

    local procedure MockTrackingSpecificationForSalesLine(SalesLine: Record "Sales Line"; IsCorrection: Boolean)
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        TrackingSpecification.Init();
        TrackingSpecification."Entry No." := LibraryUtility.GetNewRecNo(TrackingSpecification, TrackingSpecification.FieldNo("Entry No."));
        TrackingSpecification.SetSourceFromSalesLine(SalesLine);
        TrackingSpecification.Correction := IsCorrection;
        TrackingSpecification.Insert();
    end;

    local procedure MockTrackingSpecificationForItemJnlLine(var TrackingSpecification: Record "Tracking Specification"; ItemJnlLine: Record "Item Journal Line"; EntryNo: Integer; SerialNo: Code[50]; LotNo: Code[50]; ExpirationDate: Date)
    var
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
    begin
        ItemJnlLineReserve.InitFromItemJnlLine(TrackingSpecification, ItemJnlLine);
        TrackingSpecification."Entry No." := EntryNo;
        TrackingSpecification.Validate("Serial No.", SerialNo);
        TrackingSpecification.Validate("Lot No.", LotNo);
        TrackingSpecification.Validate("Expiration Date", ExpirationDate);
        TrackingSpecification.Insert(true);
    end;

    local procedure MockReservEntryForSalesLine(SalesLine: Record "Sales Line"; LotNo: Code[50]; QtyToHandleBase: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.Init();
        ReservationEntry."Entry No." := LibraryUtility.GetNewRecNo(ReservationEntry, ReservationEntry.FieldNo("Entry No."));
        ReservationEntry.SetSource(DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", '', 0);
        ReservationEntry."Lot No." := LotNo;
        ReservationEntry.UpdateItemTracking();
        ReservationEntry."Qty. to Handle (Base)" := QtyToHandleBase;
        ReservationEntry.Insert();
    end;

    local procedure MockReservEntryForItemJournalLine(ItemJournalLine: Record "Item Journal Line"; SerialNo: Code[50]; LotNo: Code[50]; PackageNo: Code[50]; Qty: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
        RecRef: RecordRef;
    begin
        ReservationEntry.Init();
        ReservationEntry.Positive := true;
        RecRef.GetTable(ReservationEntry);
        ReservationEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, ReservationEntry.FieldNo("Entry No."));
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Prospect;
        ReservationEntry.SetSource(
          DATABASE::"Item Journal Line", ItemJournalLine."Entry Type".AsInteger(), ItemJournalLine."Journal Template Name", ItemJournalLine."Line No.",
          ItemJournalLine."Journal Batch Name", 0);
        ReservationEntry."Item No." := ItemJournalLine."Item No.";
        ReservationEntry."Serial No." := SerialNo;
        ReservationEntry."Lot No." := LotNo;
        ReservationEntry."Package No." := PackageNo;
        ReservationEntry."Quantity (Base)" := Qty;
        ReservationEntry."Qty. per Unit of Measure" := Qty;
        ReservationEntry.Quantity := Qty;
        ReservationEntry."Qty. to Handle (Base)" := Qty;
        ReservationEntry."Qty. to Invoice (Base)" := Qty;
        ReservationEntry."Expected Receipt Date" := WorkDate();
        ReservationEntry.Insert();
    end;

    local procedure MockWarehouseEntry(ItemNo: Code[20])
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.Init();
        WarehouseEntry."Entry No." := LibraryUtility.GetNewRecNo(WarehouseEntry, WarehouseEntry.FieldNo("Entry No."));
        WarehouseEntry."Item No." := ItemNo;
        WarehouseEntry."Qty. (Base)" := LibraryRandom.RandInt(10);
        WarehouseEntry.Insert();
    end;

    local procedure PostSalesOrderPartialShip(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Qty. to Ship", 1);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure PostSalesReturnOrderPartialRcpt(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Return Qty. to Receive", 1);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure PostPurchaseDocumentWithTracking(var PurchaseLine: Record "Purchase Line"; TrackingOption: Option)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryVariableStorage.Enqueue(TrackingOption);
        PurchaseLine.OpenItemTrackingLines();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure PostPurchaseOrderPartialRcpt(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Qty. to Receive", 1);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure PostPurchaseReturnOrderPartialShip(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Return Qty. to Ship", 1);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure PartialPostPurchaseDocumentWithQty(PurchaseLine: Record "Purchase Line"; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        case PurchaseLine."Document Type" of
            PurchaseLine."Document Type"::Order:
                PurchaseLine.Validate("Qty. to Receive", Quantity);
            PurchaseLine."Document Type"::"Return Order":
                PurchaseLine.Validate("Return Qty. to Ship", Quantity);
        end;
        PurchaseLine.Modify(true);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure PartialPostPurchaseDocumentWithJobAndLotTracking(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create Purchase Order/Return Order, create Purchase Line with Job No., assign Item Tracking Lot No.
        Initialize();
        CreatePurchaseDocumentWithJobAndLotTracking(PurchaseLine, DocumentType);

        // Exercise: Post partial receive for Purchase Order./Post partial return shipment for Purchase Return Order
        PartialPostPurchaseDocumentWithQty(PurchaseLine, PurchaseLine.Quantity / LibraryRandom.RandIntInRange(3, 5));

        // Verify: Verify Qtys on Item Tracking Lines
        VerifyQuantityOnItemTrackingLines(PurchaseLine);
    end;

    local procedure PartialPostPurchaseDocumentWithJobAndMultipleLotTracking(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
        QuantityBase: array[2] of Decimal;
        QtyToHandle: array[2] of Decimal;
    begin
        // Setup: Create Purchase Order/Return Order, create Purchase Line with Job No., assign multiple Item Tracking Lot No.
        Initialize();
        CreatePurchaseOrderWithMultipleLotNoInItemTracking(PurchaseLine, DocumentType, QuantityBase, QtyToHandle);

        // Exercise: Post partial receive for Purchase Order./Post partial return shipment for Purchase Return Order
        PartialPostPurchaseDocumentWithQty(PurchaseLine, QtyToHandle[1] + QtyToHandle[2]);

        // Verify: Verify Qtys on Item Tracking Lines
        VerifyQuantityOnMultipleItemTrackingLines(PurchaseLine, QuantityBase, QtyToHandle);
    end;

    local procedure PostPurchaseOrderWithLotTracking(VendorNo: Code[20]; LotNo: Code[50])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QtyToUpdate: Option Quantity,"Quantity to Handle","Quantity to Invoice";
    begin
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.FindFirst();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        EnqueueLotTrackingSpec(LotNo, QtyToUpdate::Quantity, PurchaseLine.Quantity);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure PostExpDateReclassification(Item: Record Item; Quantity: Decimal; LotNo: Code[50]; NewExpirationDate: Date)
    var
        ItemJnlLine: Record "Item Journal Line";
        ReservEntry: Record "Reservation Entry";
        QtyToUpdate: Option Quantity,"Quantity to Handle","Quantity to Invoice";
    begin
        CreateItemJournalLine(ItemJnlLine, Item, ItemJnlLine."Entry Type"::Transfer, Quantity, 0);

        EnqueueLotTrackingSpec(LotNo, QtyToUpdate::Quantity, Quantity);
        ItemJnlLine.OpenItemTrackingLines(false);

        FindReservationForItemJournal(ReservEntry, Item."No.");
        ReservEntry.Validate("New Expiration Date", NewExpirationDate);
        ReservEntry.Validate("New Lot No.", ReservEntry."Lot No.");
        ReservEntry.Modify(true);

        PostItemJournalBatch(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
    end;

    local procedure PostItemJournalBatch(JnlTemplateName: Code[10]; JnlBatchName: Code[10])
    var
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        ItemJnlBatch.Get(JnlTemplateName, JnlBatchName);
        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);
    end;

    local procedure PostItemJnlLineWithLotNo(Item: Record Item; LotNo: Code[50]; Quantity: Integer; EntryType: Enum "Item Ledger Document Type")
    var
        ItemJnlLine: Record "Item Journal Line";
        QtyToUpdate: Option Quantity,"Quantity to Handle","Quantity to Invoice";
    begin
        CreateItemJournalLine(ItemJnlLine, Item, EntryType, Quantity, LibraryPatterns.RandCost(Item));
        EnqueueLotTrackingSpec(LotNo, QtyToUpdate::Quantity, Quantity);

        ItemJnlLine.OpenItemTrackingLines(false);

        PostItemJournalBatch(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
    end;

    local procedure PostItemJnlLineWithLotSerialExpDate(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; LotNo: Code[50]; SerialNo: Code[50]; ExpirationDate: Date)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, 1);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SerialNo);
        ItemJournalLine.OpenItemTrackingLines(false);

        UpdateExpirationDateOnReservEntry(ItemNo, ExpirationDate);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostPositiveAdjmtWithLotExpTracking(Item: Record Item; Quantity: Decimal; LotNo: Code[50]; ExpirationDate: Date)
    var
        ItemJnlLine: Record "Item Journal Line";
        QtyToUpdate: Option Quantity,"Quantity to Handle","Quantity to Invoice";
    begin
        CreateItemJournalLine(ItemJnlLine, Item, ItemJnlLine."Entry Type"::"Positive Adjmt.", Quantity, LibraryPatterns.RandCost(Item));

        EnqueueLotTrackingSpec(LotNo, QtyToUpdate::Quantity, Quantity);
        ItemJnlLine.OpenItemTrackingLines(false);

        UpdateExpirationDateOnReservEntry(Item."No.", ExpirationDate);

        PostItemJournalBatch(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
    end;

    local procedure PostPositiveAdjmtWithLotNo(Item: Record Item; LotNo: Code[50]; Quantity: Integer)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        PostItemJnlLineWithLotNo(Item, LotNo, Quantity, ItemJnlLine."Entry Type"::"Positive Adjmt.");
    end;

    local procedure PostNegativeAdjmtWithLotNo(Item: Record Item; LotNo: Code[50]; Quantity: Integer)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        PostItemJnlLineWithLotNo(Item, LotNo, Quantity, ItemJnlLine."Entry Type"::"Negative Adjmt.");
    end;

    local procedure MakeLotTrackedItemStockAtLocation(Item: Record Item; Quantity: Decimal; LocationCode: Code[10]; LotNo: Code[50])
    var
        ItemJournalLine: Record "Item Journal Line";
        QtyToUpdate: Option Quantity,"Quantity to Handle","Quantity to Invoice";
    begin
        CreateItemJournalLine(ItemJournalLine, Item, ItemJournalLine."Entry Type"::Purchase, Quantity, LibraryPatterns.RandCost(Item));
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);

        EnqueueLotTrackingSpec(LotNo, QtyToUpdate::Quantity, Quantity);
        ItemJournalLine.OpenItemTrackingLines(false);

        PostItemJournalBatch(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure RegisterWhseActivity(WhseShipmentNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(WarehouseActivityLine, WhseShipmentNo);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure SetTrackingSpecification(var TransferOrderPage: TestPage "Transfer Order"; LotNo: Code[50]; QtyToUpdate: Option Quantity,"Quantity to Handle","Quantity to Invoice"; Qty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(QtyToUpdate);
        LibraryVariableStorage.Enqueue(Qty);
        TransferOrderPage.TransferLines.Shipment.Invoke();  // Open page "Item Tracking Lines / Shipment"
    end;

    local procedure SetupTransferOrderTracking(var TransferOrderPage: TestPage "Transfer Order"; var LotNo: Code[50]; var Qty: Integer)
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        QtyToUpdate: Option Quantity,"Quantity to Handle","Quantity to Invoice";
    begin
        Qty := LibraryRandom.RandIntInRange(10, 100);

        CreateTransferOrderOnNewItem(TransferHeader, TransferLine, Qty);

        TransferOrderPage.OpenEdit();
        TransferOrderPage.GotoKey(TransferHeader."No.");

        LotNo := LibraryUtility.GenerateGUID();
        SetTrackingSpecification(TransferOrderPage, LotNo, QtyToUpdate::Quantity, Qty);
    end;

    local procedure SetValueOnItemTrackingLines(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        Quantity: Variant;
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Dequeue(Quantity);
        ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
        LibraryVariableStorage.Dequeue(Quantity);
        ItemTrackingLines."Qty. to Handle (Base)".SetValue(Quantity);
    end;

    local procedure SumUpQtyToHandle(var ReservEntry: Record "Reservation Entry"): Decimal
    begin
        ReservEntry.CalcSums("Qty. to Handle (Base)");
        exit(ReservEntry."Qty. to Handle (Base)");
    end;

    local procedure UpdateWhseActivityLineQtyToHandleAndLotNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; LotNo: Code[50]; QtyToHandle: Integer)
    begin
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Validate("Qty. to Handle (Base)", QtyToHandle);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateQtyToReceiveOnPurchaseLines(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindSet();
        repeat
            PurchaseLine.Validate("Qty. to Receive", LibraryRandom.RandInt(PurchaseLine."Qty. to Receive" - 1));
            PurchaseLine.Modify(true);
        until PurchaseLine.Next() = 0;
    end;

    local procedure UpdateReservationEntry(ItemNo: Code[20]; ExpirationDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.ModifyAll("Expiration Date", ExpirationDate, true);
    end;

    local procedure UpdatePurchaseLineWithJobTask(var PurchaseLine: Record "Purchase Line"; JobTask: Record "Job Task")
    begin
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Job Line Type", PurchaseLine."Job Line Type"::Budget);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateExpirationDateOnReservEntry(ItemNo: Code[20]; ExpirationDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        FindReservationForItemJournal(ReservationEntry, ItemNo);
        ReservationEntry.Validate("Expiration Date", ExpirationDate);
        ReservationEntry.Modify(true);
    end;

    local procedure UpdateSerialNoOnWhseActivityLine(WhseDocNo: Code[20]; ActionType: Enum "Warehouse Action Type"; NewSerialNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Whse. Document Type", WarehouseActivityLine."Whse. Document Type"::Shipment);
        WarehouseActivityLine.SetRange("Whse. Document No.", WhseDocNo);
        WarehouseActivityLine.SetRange("Serial No.", '');
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();

        WarehouseActivityLine.Validate("Serial No.", NewSerialNo);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure VerifyExpirationDateOnItemLedgerEntry(ItemNo: Code[20]; IsPositive: Boolean; ExpectedDate: Date)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange(Positive, IsPositive);
        ItemLedgEntry.FindLast();
        Assert.AreEqual(ExpectedDate, ItemLedgEntry."Expiration Date", StrSubstNo(WrongExpDateErr, ItemLedgEntry.TableCaption(), ItemLedgEntry."Entry No."));
    end;

    local procedure VerifyLotNoExistOnReservationEntry(ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Lot No.");
    end;

    local procedure VerifyPostedServiceCreditMemo(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line")
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceCrMemoHeader.FindFirst();
        ServiceCrMemoHeader.TestField("Customer No.", ServiceHeader."Customer No.");
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.FindFirst();
        ServiceCrMemoLine.TestField("No.", ServiceLine."No.");
        ServiceCrMemoLine.TestField(Quantity, ServiceLine.Quantity);
    end;

    local procedure VerifyPostedServiceOrder(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line")
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceHeader.TestField("Customer No.", ServiceHeader."Customer No.");
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindFirst();
        ServiceInvoiceLine.TestField("No.", ServiceLine."No.");
        ServiceInvoiceLine.TestField(Quantity, ServiceLine.Quantity);
    end;

    local procedure VerifySalesLineIsInbound(SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ExpectedResult: Boolean)
    begin
        SalesLine."Document Type" := DocumentType;
        Assert.AreEqual(
          ExpectedResult, SalesLine.IsInbound(),
          StrSubstNo('%1 %2 %3 %4', SalesLine.TableName, Format(SalesLine."Document Type"), SalesLine.FieldName("Quantity (Base)"), SalesLine."Quantity (Base)"));
    end;

    local procedure VerifyPurchLineIsInbound(PurchLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; ExpectedResult: Boolean)
    begin
        PurchLine."Document Type" := DocumentType;
        Assert.AreEqual(
          ExpectedResult, PurchLine.IsInbound(),
          StrSubstNo('%1 %2 %3 %4', PurchLine.TableName, Format(PurchLine."Document Type"), PurchLine.FieldName("Quantity (Base)"), PurchLine."Quantity (Base)"));
    end;

    local procedure VerifyItemJnlLineIsInbound(ItemJnlLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ExpectedResult: Boolean)
    begin
        ItemJnlLine."Entry Type" := EntryType;
        Assert.AreEqual(
          ExpectedResult, ItemJnlLine.IsInbound(),
          StrSubstNo('%1 %2 %3 %4', ItemJnlLine.TableName, Format(ItemJnlLine."Entry Type"), ItemJnlLine.FieldName("Quantity (Base)"), ItemJnlLine."Quantity (Base)"));
    end;

    local procedure VerifyAsmHeaderIsInbound(AsmHeader: Record "Assembly Header"; DocumentType: Enum "Assembly Document Type"; ExpectedResult: Boolean)
    begin
        AsmHeader."Document Type" := DocumentType;
        Assert.AreEqual(
          ExpectedResult, AsmHeader.IsInbound(),
          StrSubstNo('%1 %2 %3 %4', AsmHeader.TableName, Format(AsmHeader."Document Type"), AsmHeader.FieldName("Quantity (Base)"), AsmHeader."Quantity (Base)"));
    end;

    local procedure VerifyAsmLineIsInbound(AsmLine: Record "Assembly Line"; DocumentType: Enum "Assembly Document Type"; ExpectedResult: Boolean)
    begin
        AsmLine."Document Type" := DocumentType;
        Assert.AreEqual(
          ExpectedResult, AsmLine.IsInbound(),
          StrSubstNo('%1 %2 %3 %4', AsmLine.TableName, Format(AsmLine."Document Type"), AsmLine.FieldName("Quantity (Base)"), AsmLine."Quantity (Base)"));
    end;

    local procedure VerifyServiceLineIsInbound(ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; ExpectedResult: Boolean)
    begin
        ServiceLine."Document Type" := DocumentType;
        Assert.AreEqual(
          ExpectedResult, ServiceLine.IsInbound(),
          StrSubstNo('%1 %2 %3 %4', ServiceLine.TableName, Format(ServiceLine."Document Type"), ServiceLine.FieldName("Quantity (Base)"), ServiceLine."Quantity (Base)"));
    end;

    local procedure VerifyJobJnlLineIsInbound(JobJnlLine: Record "Job Journal Line"; EntryType: Enum "Job Journal Line Entry Type"; ExpectedResult: Boolean)
    begin
        JobJnlLine."Entry Type" := EntryType;
        Assert.AreEqual(
          ExpectedResult, JobJnlLine.IsInbound(),
          StrSubstNo('%1 %2 %3 %4', JobJnlLine.TableName, Format(JobJnlLine."Entry Type"), JobJnlLine.FieldName("Quantity (Base)"), JobJnlLine."Quantity (Base)"));
    end;

    local procedure VerifySecondTransferLineLotNo(TransferHeader: Record "Transfer Header"; LotNo: Code[50])
    var
        TransferLine: Record "Transfer Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindLast();
        ReservationEntry.SetRange("Item No.");
        ReservationEntry.SetRange("Location Code");
        ReservationEntry.SetRange("Source Type");
        ReservationEntry.SetRange("Source Ref. No.", TransferLine."Line No.");
        Assert.IsTrue(ReservationEntry.FindFirst(), ItemTrackSpecNotFoundErr);
        ReservationEntry.TestField("Lot No.", LotNo);
    end;

    local procedure VerifyQuantityOnItemTrackingLines(PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        LibraryVariableStorage.Enqueue(TrackingOptionStr::VerifyLotQty);
        LibraryVariableStorage.Enqueue(PurchaseLine."Quantity (Base)"); // Expected value for ItemTrackingLines."Quantity (Base)"
        LibraryVariableStorage.Enqueue(PurchaseLine."Outstanding Qty. (Base)"); // Expected value for ItemTrackingLines."Qty. to Handle (Base)"
        LibraryVariableStorage.Enqueue(PurchaseLine."Qty. to Invoice (Base)"); // Expected value for ItemTrackingLines."Qty. to Invoice (Base)"
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure VerifyQuantityOnMultipleItemTrackingLines(PurchaseLine: Record "Purchase Line"; QuantityBase: array[2] of Decimal; QtyHandled: array[2] of Decimal)
    var
        RoundingPrecision: Decimal;
        i: Integer;
    begin
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        LibraryVariableStorage.Enqueue(TrackingOptionStr::VerifyLotQty);
        RoundingPrecision := 0.00001; // Rounding precision used by all Quantity fields in item tracking lines
        for i := 1 to ArrayLen(QuantityBase) do begin
            LibraryVariableStorage.Enqueue(QuantityBase[i]); // Expected value for ItemTrackingLines."Quantity (Base)"
            LibraryVariableStorage.Enqueue(Round(QuantityBase[i], RoundingPrecision) - Round(QtyHandled[i], RoundingPrecision)); // Expected value for ItemTrackingLines."Qty. to Handle (Base)"
            LibraryVariableStorage.Enqueue(QuantityBase[i]); // Expected value for ItemTrackingLines."Qty. to Invoice (Base)"
        end;
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure VerifyFreeEntryTrackingExists(ItemNo: Code[20]; LotNo: Code[10])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Lot No.", LotNo);
        Assert.IsFalse(ItemLedgEntry.IsEmpty, ItemLedgEntryWithLotErr);
    end;

    local procedure VerifyItemTrackingLinesQty(ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        Quantity: Variant;
    begin
        LibraryVariableStorage.Dequeue(Quantity);
        ItemTrackingLines."Quantity (Base)".AssertEquals(Quantity);
        LibraryVariableStorage.Dequeue(Quantity);
        ItemTrackingLines."Qty. to Handle (Base)".AssertEquals(Quantity);
        LibraryVariableStorage.Dequeue(Quantity);
        ItemTrackingLines."Qty. to Invoice (Base)".AssertEquals(Quantity);
    end;

    local procedure VerifyPurchaseOrderTrackingLines(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindSet();
        repeat
            VerifyQuantityOnItemTrackingLines(PurchaseLine);
        until PurchaseLine.Next() = 0;
    end;

    local procedure VerifyQuantityOnPostWhseShipLine(WhseShipmentLine: Record "Warehouse Shipment Line")
    var
        PstdWhseShptLn: Record "Posted Whse. Shipment Line";
    begin
        PstdWhseShptLn.SetRange("Whse. Shipment No.", WhseShipmentLine."No.");
        PstdWhseShptLn.SetRange("Whse Shipment Line No.", WhseShipmentLine."Line No.");
        PstdWhseShptLn.FindFirst();
        Assert.AreEqual(WhseShipmentLine.Quantity, PstdWhseShptLn.Quantity, PostedWhseQuantityErr);
    end;

    local procedure VerifyJobJournalLineReservEntry(JobJournalLine: Record "Job Journal Line"; LotNo: Code[50])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", DATABASE::"Job Journal Line");
        ReservationEntry.SetRange("Source Subtype", JobJournalLine."Entry Type");
        ReservationEntry.SetRange("Source ID", JobJournalLine."Journal Template Name");
        ReservationEntry.SetRange("Source Batch Name", JobJournalLine."Journal Batch Name");
        ReservationEntry.SetRange("Source Ref. No.", JobJournalLine."Line No.");
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Item No.", JobJournalLine."No.");
        ReservationEntry.TestField("Lot No.", LotNo);
    end;

    local procedure VerifyItemLedgerEntryLotNo(DocumentNo: Code[20]; ItemNo: Code[20]; LotNo: Code[50])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Item No.", ItemNo);
        ItemLedgerEntry.TestField("Lot No.", LotNo);
    end;

    local procedure VerifyReservationEntrySubtypeAndQty(ReservationEntry: Record "Reservation Entry"; SourceSubtype: Integer; Quantity: Decimal; QtyToHandle: Decimal)
    begin
        ReservationEntry.TestField("Source Subtype", SourceSubtype);
        ReservationEntry.TestField(Quantity, Quantity);
        ReservationEntry.TestField("Qty. to Handle (Base)", QtyToHandle);
    end;

    local procedure VerifyValuesReceivedFromItemTrackingSummaryLine(LotNo: Code[50]; PackageNo: Code[50]; TotalQty: Integer; TotalRequestedQty: Integer; CurrentPendingQty: Integer; TotalAvailableQty: Integer)
    begin
        Assert.AreEqual(LotNo, LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(PackageNo, LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(TotalQty, LibraryVariableStorage.DequeueInteger(), '');
        Assert.AreEqual(TotalRequestedQty, LibraryVariableStorage.DequeueInteger(), '');
        Assert.AreEqual(CurrentPendingQty, LibraryVariableStorage.DequeueInteger(), '');
        Assert.AreEqual(TotalAvailableQty, LibraryVariableStorage.DequeueInteger(), '');
    end;

    local procedure VerifyPairOfReservationEntriesSalesTransferInbound(var ReservationEntry: Record "Reservation Entry"; SourceRefNoSales: Integer; SourceProdOrderLineTransfer: Integer; Qty1: Integer; Qty2: Integer)
    begin
        ReservationEntry.SetRange("Source Type", DATABASE::"Sales Line");
        ReservationEntry.SetRange("Source Ref. No.", SourceRefNoSales);
        ReservationEntry.SetRange("Source Prod. Order Line", 0);
        ReservationEntry.FindSet();
        VerifyReservationEntryQuantities(ReservationEntry, -Qty2);
        ReservationEntry.Next();
        VerifyReservationEntryQuantities(ReservationEntry, -Qty1);

        ReservationEntry.SetRange("Source Type", DATABASE::"Transfer Line");
        ReservationEntry.SetRange("Source Ref. No.");
        ReservationEntry.SetRange("Source Prod. Order Line", SourceProdOrderLineTransfer);
        ReservationEntry.FindSet();
        VerifyReservationEntryQuantities(ReservationEntry, Qty2);
        ReservationEntry.Next();
        VerifyReservationEntryQuantities(ReservationEntry, Qty1);
    end;

    local procedure VerifyReservationEntryQuantities(ReservationEntry: Record "Reservation Entry"; Qty: Integer)
    begin
        ReservationEntry.TestField(Quantity, Qty);
        ReservationEntry.TestField("Qty. to Handle (Base)", Qty);
        ReservationEntry.TestField("Qty. to Invoice (Base)", Qty);
    end;


    local procedure UpdatePickLineZoneCodeAndBinCode(SourceDocNo: Code[20]; ActionType: Enum "Warehouse Action Type"; ZoneCode: Code[10]; BinCode: Code[20]; Qty: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        WhseActivityLine.SetRange(Quantity, Qty);
        WhseActivityLine.SetRange("Action Type", ActionType);
        FindWarehouseActivityLine(WhseActivityLine, WhseActivityLine."Source Document"::"Purchase Order", SourceDocNo, WhseActivityLine."Activity Type"::"Put-away");
        WhseActivityLine.Validate("Qty. to Handle", 0);
        WhseActivityLine.Validate("Zone Code", ZoneCode);
        WhseActivityLine.Validate("Bin Code", BinCode);
        WhseActivityLine.Validate("Qty. to Handle", Qty);
        WhseActivityLine.Modify();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure CreateLotItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, false);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateSerialItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, false);
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateLocationWithWarehouseEmployeeSetup(
        var Location: Record Location;
        var WarehouseEmployee: Record "Warehouse Employee")
    begin
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure FindWarehouseShipmentHeaderAndLine(
        var WhseShipmentHeader: Record "Warehouse Shipment Header";
        var WhseShipmentLine: Record "Warehouse Shipment Line";
        var SalesHeader: Record "Sales Header")
    begin
        WhseShipmentHeader.Get(
            LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
                Database::"Sales Line",
                SalesHeader."Document Type".AsInteger(),
                SalesHeader."No."));

        WhseShipmentLine.SetRange("No.", WhseShipmentHeader."No.");
        WhseShipmentLine.FindFirst();
    end;

    local procedure CreateItemWithLotItemTrackingCode(
        var Item: Record Item;
        var ItemTrackingCode: Record "Item Tracking Code")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure CreateItemWithSerialItemTrackingCode(
        var Item: Record Item;
        var ItemTrackingCode: Record "Item Tracking Code")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; Item: Record Item; Location: Record Location)
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);

        LibrarySales.CreateSalesHeader(
            SalesHeader,
            SalesHeader."Document Type"::Order,
            Customer."No.");

        LibrarySales.CreateSalesLine(
            SalesLine,
            SalesHeader,
            SalesLine.Type::Item,
            Item."No.",
            LibraryRandom.RandInt(0));

        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; Item: Record Item; Location: Record Location)
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreateVendor(Vendor);

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader,
            PurchaseHeader."Document Type"::Order,
            Vendor."No.");

        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::Item,
            Item."No.",
            LibraryRandom.RandInt(0));

        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
    end;

    local procedure FindPurchLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
    end;

    local procedure UndoSalesShipment(SalesLine: Record "Sales Line")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        FindShipmentLine(SalesShipmentLine, SalesLine, 1);
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure FindShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; SalesLine: Record "Sales Line"; SignFactor: Integer)
    begin
        FilterForShipmentLine(SalesShipmentLine, SalesLine, SalesLine."No.");
        SalesShipmentLine.SetRange(Quantity, SignFactor * SalesLine.Quantity);
        SalesShipmentLine.FindFirst();
    end;

    local procedure FilterForShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; SalesLine: Record "Sales Line"; ItemNo: Code[20])
    begin
        SalesShipmentLine.SetRange("Order No.", SalesLine."Document No.");
        SalesShipmentLine.SetFilter("No.", '%1|%2', SalesLine."No.", ItemNo);
    end;

    local procedure ValidateLocationFields(var Location: Record Location; Bin: Record Bin)
    begin
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Shipment Bin Code", Bin.Code);
        Location.Validate("Always Create Pick Line", false);
        Location.Validate("Pick According to FEFO", false);
        Location.Modify(true);
    end;

    local procedure CreatePositivAdjWithSerialNos(ItemNo: Code[20]; LocationCode: Code[10]; Bin: Record Bin; Quantity: Decimal; SerialNo: Code[50]; SerialNo2: Code[50]; SerialNo3: Code[50]; SerialNo4: Code[50])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
            ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);

        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", Bin.Code);
        ItemJournalLine.Modify(true);

        LibraryVariableStorage.Enqueue(SerialNo);
        LibraryVariableStorage.Enqueue(SerialNo2);
        LibraryVariableStorage.Enqueue(SerialNo3);
        LibraryVariableStorage.Enqueue(SerialNo4);

        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndReleaseSalesOrderWithQty(var SalesHeader: Record "Sales Header"; Item: Record Item; Location: Record Location; Qty: Decimal)
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);

        LibrarySales.CreateSalesHeader(
            SalesHeader,
            SalesHeader."Document Type"::Order,
            Customer."No.");

        LibrarySales.CreateSalesLine(
            SalesLine,
            SalesHeader,
            SalesLine.Type::Item,
            Item."No.",
            Qty);

        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandlerTrackingOption(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingOption::AssignLotNo:
                begin
                    ItemTrackingLines.New();
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            ItemTrackingOption::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryOkModalPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        if AssignSerialNo then
            ItemTrackingLines."Assign Serial No.".Invoke();

        if AssignLotNo then
            ItemTrackingLines."Assign Lot No.".Invoke();

        if SalesMode then
            ItemTrackingLines."Select Entries".Invoke();

        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingAssignTrackingNoAndVerifyQuantityHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVar: Variant;
        TrackingOption: Option;
        i: Integer;
    begin
        LibraryVariableStorage.Dequeue(DequeueVar);
        TrackingOption := DequeueVar;
        case TrackingOption of
            TrackingOptionStr::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            TrackingOptionStr::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            TrackingOptionStr::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            TrackingOptionStr::SetLotQty:
                begin
                    LibraryVariableStorage.Dequeue(DequeueVar);
                    i := DequeueVar;
                    ItemTrackingLines.First();
                    while i > 0 do begin
                        SetValueOnItemTrackingLines(ItemTrackingLines);
                        ItemTrackingLines.Next();
                        i -= 1;
                    end;
                end;
            TrackingOptionStr::VerifyLotQty:
                begin
                    ItemTrackingLines.First();
                    while ItemTrackingLines."Lot No.".Value <> '' do begin
                        VerifyItemTrackingLinesQty(ItemTrackingLines);
                        ItemTrackingLines.Next();
                    end;
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSingleLineHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Serial No.".SetValue(LibraryUtility.GenerateGUID());
        ItemTrackingLines."Quantity (Base)".SetValue(1);
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSingleLineLotHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVar);
        ItemTrackingLines."Lot No.".SetValue(DequeueVar);
        ItemTrackingLines."Quantity (Base)".SetValue(1);
        ItemTrackingLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesLotAndSerialHanlder(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(1);
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesLotSNQtyModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Package No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesLotSNWithDrilldownLotAvailabilityModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Package No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.AvailabilityLotNo.DrillDown();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesLotSNQtyWithEnqueueLotModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        SerialNo: Text;
        LotNo: Text;
        PackageNo: Text;
        Qty: Decimal;
    begin
        SerialNo := LibraryVariableStorage.DequeueText();
        LotNo := LibraryVariableStorage.DequeueText();
        PackageNo := LibraryVariableStorage.DequeueText();
        Qty := LibraryVariableStorage.DequeueDecimal();
        ItemTrackingLines."Serial No.".SetValue(SerialNo);
        LibraryVariableStorage.Enqueue(Format(ItemTrackingLines."Lot No."));
        ItemTrackingLines."Lot No.".SetValue(LotNo);
        ItemTrackingLines."Package No.".SETVALUE(PackageNo);
        ItemTrackingLines."Quantity (Base)".SetValue(Qty);
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreateHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingEntriesHandler(var ItemTrackingEntries: TestPage "Item Tracking Entries")
    begin
        ItemTrackingEntries."Expiration Date".AssertEquals(WorkDate());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryModalPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        Assert.IsFalse(
          ItemTrackingSummary."Selected Quantity".Visible(),
          StrSubstNo(FieldVisibleErr, ItemTrackingSummary."Selected Quantity".Caption, ItemTrackingSummary.Caption));
        Assert.IsFalse(
          ItemTrackingSummary."Selected Quantity".Editable(),
          StrSubstNo(FieldEditableErr, ItemTrackingSummary."Selected Quantity".Caption, ItemTrackingSummary.Caption));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryModalPageHandlerWithEnqueueLotNoAndQtys(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.First();
        repeat
            LibraryVariableStorage.Enqueue(Format(ItemTrackingSummary."Lot No."));
            LibraryVariableStorage.Enqueue(Format(ItemTrackingSummary."Package No."));
            LibraryVariableStorage.Enqueue(ItemTrackingSummary."Total Quantity".AsInteger());
            LibraryVariableStorage.Enqueue(ItemTrackingSummary."Total Requested Quantity".AsInteger());
            LibraryVariableStorage.Enqueue(ItemTrackingSummary."Current Pending Quantity".AsInteger());
            LibraryVariableStorage.Enqueue(ItemTrackingSummary."Total Available Quantity".AsInteger());
        until ItemTrackingSummary.Next() = false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrkgManualLotNoHandler(var ItemTrkgLines: TestPage "Item Tracking Lines")
    var
        QueuedVar: Variant;
        LotNo: Code[50];
        QtyToUpdate: Option Quantity,"Quantity to Handle","Quantity to Invoice";
        Qty: Decimal;
    begin
        LibraryVariableStorage.Dequeue(QueuedVar);
        LotNo := QueuedVar;
        LibraryVariableStorage.Dequeue(QueuedVar);
        QtyToUpdate := QueuedVar;
        LibraryVariableStorage.Dequeue(QueuedVar);
        Qty := QueuedVar;

        if LotNo <> '' then
            ItemTrkgLines."Lot No.".SetValue(LotNo);

        case QtyToUpdate of
            QtyToUpdate::Quantity:
                ItemTrkgLines."Quantity (Base)".SetValue(Qty);
            QtyToUpdate::"Quantity to Handle":
                ItemTrkgLines."Qty. to Handle (Base)".SetValue(Qty);
            QtyToUpdate::"Quantity to Invoice":
                ItemTrkgLines."Qty. to Invoice (Base)".SetValue(Qty);
        end;

        ItemTrkgLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MultipleItemTrackingModalPageHandler(var ItemTrkgLines: TestPage "Item Tracking Lines")
    var
        Qty: Decimal;
        i: Integer;
        HandlingType: Option;
    begin
        HandlingType := LibraryVariableStorage.DequeueInteger();

        case HandlingType of
            HandlingTypeStr::"Init Tracking":
                for i := 1 to 2 do begin
                    ItemTrkgLines.New();
                    ItemTrkgLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrkgLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                    ItemTrkgLines."Qty. to Handle (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            HandlingTypeStr::"Double Quantities":
                begin
                    ItemTrkgLines.GotoKey(LibraryVariableStorage.DequeueInteger());
                    Evaluate(Qty, ItemTrkgLines."Quantity (Base)".Value);
                    ItemTrkgLines."Quantity (Base)".SetValue(Qty * 2);
                    ItemTrkgLines."Qty. to Handle (Base)".SetValue(0);
                end;
            HandlingTypeStr::"Align Quantities":
                for i := 1 to 2 do begin
                    ItemTrkgLines.GotoKey(i);
                    Evaluate(Qty, ItemTrkgLines."Quantity (Base)".Value);
                    ItemTrkgLines."Qty. to Handle (Base)".SetValue(Qty);
                end;
            HandlingTypeStr::"QtyToHandle < Qty":
                for i := 1 to 2 do begin
                    ItemTrkgLines.GotoKey(i);
                    Evaluate(Qty, ItemTrkgLines."Quantity (Base)".Value);
                    ItemTrkgLines."Qty. to Handle (Base)".SetValue(Qty / 2);
                end;
        end;

        ItemTrkgLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesGetAvailabilityModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        LibraryVariableStorage.Enqueue(ItemTrackingLines.AvailabilitySerialNo.AsBoolean());
        LibraryVariableStorage.Enqueue(ItemTrackingLines.AvailabilityLotNo.AsBoolean());

        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OpenItemTrackingHandler(var ItemTrkgLines: TestPage "Item Tracking Lines")
    var
        QueuedVar: Variant;
        Qty: Decimal;
        No: Code[10];
        LotCount: Integer;
        iLot: Integer;
    begin
        LibraryVariableStorage.Dequeue(QueuedVar);
        LotCount := QueuedVar;

        for iLot := 1 to LotCount do begin
            ItemTrkgLines.New();
            LibraryVariableStorage.Dequeue(QueuedVar);
            No := QueuedVar;
            ItemTrkgLines."Lot No.".SetValue(No);
            LibraryVariableStorage.Dequeue(QueuedVar);
            Qty := QueuedVar;
            ItemTrkgLines."Quantity (Base)".SetValue(Qty);
        end;

        ItemTrkgLines.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreatePickFromWhseShptReqHandler(var CreatePickFromWhseShptReqPage: TestRequestPage "Whse.-Shipment - Create Pick")
    begin
        CreatePickFromWhseShptReqPage.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandlerWithDequeueChoice(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetPostedDocLinesPageHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    var
        DocumentType: Option "Posted Receipts","Posted Invoices","Posted Return Shipments","Posted Cr. Memos";
    begin
        PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue(Format(DocumentType::"Posted Receipts"));
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSerialNoHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines.First();
        ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Expiration Date".SetValue(CalcDate('<CY-6M>', WorkDate()));
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryRandom.RandIntInRange(1, 1));
        ItemTrackingLines.Next();
        ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Expiration Date".SetValue(CalcDate('<CY-3M+6D>', WorkDate()));
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryRandom.RandIntInRange(1, 1));
        ItemTrackingLines.Next();
        ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryRandom.RandIntInRange(1, 1));
        ItemTrackingLines.Next();
        ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Expiration Date".SetValue(CalcDate('<CY>', WorkDate()));
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryRandom.RandIntInRange(1, 1));
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingSerialNoHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines.First();
        WhseItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryRandom.RandIntInRange(1, 1));
        WhseItemTrackingLines.Next();
        WhseItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryRandom.RandIntInRange(1, 1));
        WhseItemTrackingLines.OK().Invoke();
    end;
}
